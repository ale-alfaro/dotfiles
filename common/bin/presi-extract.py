#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "docling>=2.0",
#   "pyyaml>=6.0",
#   "rich>=13.0",
#   "mdformat>=0.7",
#   "mdformat-gfm>=0.4",
#   "Pillow",
#   "attrs",
#   "cyclopts",
# ]
# ///
"""
Extract a technical-presentation PDF into a single Obsidian markdown file.

Pipeline: Convert (docling) -> Segment (one Slide per page) -> Filter
(drop branding/agenda/thanks, dedupe build-up runs) -> Render (markdown
with code-block detection, embedded PNG diagrams, YAML frontmatter).
"""

from __future__ import annotations

import hashlib
import logging
import math
import os
import re
import shutil
import time
import unicodedata
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import TYPE_CHECKING, Annotated

import attrs
import cyclopts
import mdformat
import yaml
from docling.backend.pypdfium2_backend import PyPdfiumDocumentBackend
from docling.datamodel.accelerator_options import AcceleratorDevice, AcceleratorOptions
from docling.datamodel.base_models import ConversionStatus, InputFormat
from docling.datamodel.pipeline_options import (
    PdfPipelineOptions,
    RapidOcrOptions,
    TableFormerMode,
    TableStructureOptions,
)
from docling.document_converter import DocumentConverter, PdfFormatOption
from docling_core.types.doc import (
    DocItem,
    DoclingDocument,
    ListItem,
    PictureItem,
    SectionHeaderItem,
    TableItem,
    TextItem,
    TitleItem,
)
from rich.console import Console
from rich.logging import RichHandler
from rich.markup import escape as rich_escape

if TYPE_CHECKING:
    from docling.datamodel.document import ConversionResult

console = Console()
log = logging.getLogger("presi-extract")


# ---------------------------------------------------------------------------
# Page-range parsing (shared with ds-extract style)
# ---------------------------------------------------------------------------
@cyclopts.Parameter(converter="parse_page")
@attrs.frozen
class PageRange:
    start: int
    end: int

    @cyclopts.Parameter(n_tokens=1, accepts_keys=False)
    @classmethod
    def parse_page(cls, tokens):
        if tokens[0] and (raw := tokens[0].value):
            delim = "," if "," in raw else "-"
            a, b = raw.split(delim, 1)
            start, end = int(a), int(b)
            if start < 1 or end < start:
                msg = f"invalid range: {start}-{end}"
                raise cyclopts.CoercionError(msg)
            return cls(start, end)
        raise ValueError("Not enough tokens")


def parse_page_list(spec: str) -> set[int]:
    """Parse '5,7-9,12' into {5, 7, 8, 9, 12}."""
    out: set[int] = set()
    for raw in spec.split(","):
        piece = raw.strip()
        if not piece:
            continue
        if "-" in piece:
            a, b = piece.split("-", 1)
            out.update(range(int(a), int(b) + 1))
        else:
            out.add(int(piece))
    return out


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------
@dataclass
class Slide:
    page: int
    title: str | None = None
    items: list[DocItem] = field(default_factory=list)
    pictures: list[PictureItem] = field(default_factory=list)
    text_blob: str = ""  # lowercased, whitespace-collapsed concat of all text
    raw_text_parts: list[str] = field(default_factory=list)


@dataclass
class ConfidenceInfo:
    mean_score: float = float("nan")
    mean_grade: str = "UNSPECIFIED"


# ---------------------------------------------------------------------------
# Pipeline (ported from ds-extract.py; generate_picture_images=True is the
# key difference so we can write PictureItems to PNG)
# ---------------------------------------------------------------------------
def build_pipeline_options(
    *, fast: bool = False, ocr: bool = False, cuda: bool = True
) -> PdfPipelineOptions:
    accel = AcceleratorOptions()
    if cuda:
        accel = AcceleratorOptions(device=AcceleratorDevice.CUDA)

    return PdfPipelineOptions(
        accelerator_options=accel,
        do_table_structure=True,
        table_structure_options=TableStructureOptions(
            mode=TableFormerMode.FAST if fast else TableFormerMode.ACCURATE,
            do_cell_matching=True,
        ),
        do_ocr=ocr,
        ocr_options=RapidOcrOptions(
            lang=["english"], backend="torch", force_full_page_ocr=ocr
        ),
        do_picture_description=False,
        do_picture_classification=False,
        generate_picture_images=True,
        generate_page_images=ocr,
        enable_remote_services=False,
        table_batch_size=8 if cuda else 4,
        layout_batch_size=16 if cuda else 4,
        document_timeout=600.0,
    )


def create_converter(
    opts: PdfPipelineOptions, *, backend: type | None = None
) -> DocumentConverter:
    fmt_kw: dict = {"pipeline_options": opts}
    if backend is not None:
        fmt_kw["backend"] = backend
    conv = DocumentConverter(
        allowed_formats=[InputFormat.PDF],
        format_options={InputFormat.PDF: PdfFormatOption(**fmt_kw)},
    )
    conv.initialize_pipeline(InputFormat.PDF)
    return conv


def _try_convert(
    converter: DocumentConverter,
    source: Path,
    page_range: PageRange | None,
) -> ConversionResult | None:
    try:
        kwargs = {}
        if page_range is not None:
            kwargs["page_range"] = attrs.astuple(page_range)
        result = converter.convert(source, **kwargs)
    except Exception as exc:  # noqa: BLE001
        console.log(f"[red bold]✗[/] Conversion failed: {rich_escape(str(exc))}")
        return None

    if result.status not in {
        ConversionStatus.SUCCESS,
        ConversionStatus.PARTIAL_SUCCESS,
    }:
        return None

    if result.status == ConversionStatus.PARTIAL_SUCCESS:
        for e in result.errors:
            console.log(
                f"[yellow]  ⚠ {rich_escape(e.module_name)}: "
                f"{rich_escape(e.error_message)}[/]"
            )
    return result


def convert_full(
    converter: DocumentConverter,
    source: Path,
    *,
    pipeline_opts: PdfPipelineOptions | None = None,
) -> ConversionResult | None:
    """Convert entire PDF with fallback chain (default -> PyPdfium -> OCR)."""
    result = _try_convert(converter, source, None)
    if result is not None:
        return result

    if pipeline_opts is None:
        return None

    console.log("[yellow]  Retrying with PyPdfium backend...[/]")
    try:
        fb = create_converter(pipeline_opts, backend=PyPdfiumDocumentBackend)
        result = _try_convert(fb, source, None)
        if result is not None:
            return result
    except Exception as exc:  # noqa: BLE001
        console.log(f"[yellow]  PyPdfium fallback failed: {rich_escape(str(exc))}[/]")

    console.log("[yellow]  Retrying with full-page OCR...[/]")
    try:
        ocr_opts = PdfPipelineOptions(
            **{
                k: v
                for k, v in pipeline_opts.__dict__.items()
                if k not in {"ocr_options", "do_ocr", "generate_page_images"}
            },
            do_ocr=True,
            generate_page_images=True,
            ocr_options=RapidOcrOptions(
                lang=["english"], backend="torch", force_full_page_ocr=True
            ),
        )
        fb = create_converter(ocr_opts, backend=PyPdfiumDocumentBackend)
        result = _try_convert(fb, source, None)
        if result is not None:
            return result
    except Exception as exc:  # noqa: BLE001
        console.log(f"[yellow]  OCR fallback failed: {rich_escape(str(exc))}[/]")

    console.log("[red bold]✗[/] All conversion attempts failed")
    return None


def extract_confidence(result: ConversionResult) -> ConfidenceInfo:
    info = ConfidenceInfo()
    conf = result.confidence
    if conf is None:
        return info
    score = conf.mean_score
    if score is not None and not (isinstance(score, float) and math.isnan(score)):
        info.mean_score = float(score)
    grade = conf.mean_grade
    if grade is not None:
        info.mean_grade = str(grade.value) if hasattr(grade, "value") else str(grade)
    return info


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_TEMPLATE_HEADER_RE = re.compile(
    r"\b(zephyr\s*project|developer\s*summit|#embeddedossummit)\b", re.IGNORECASE
)


def _is_template_header(text: str) -> bool:
    return bool(_TEMPLATE_HEADER_RE.search(text or ""))


# Bullet glyphs the PDF renders inline into list-item text.
_BULLET_GLYPH_RE = re.compile(r"^[•●○◦▪▫·‣⁃\-\*]+\s*")  # noqa: RUF001 — these glyphs are all valid bullets in PDF text


def _norm_ws(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip())


def _strip_bullet_glyph(text: str) -> str:
    """Strip a leading bullet glyph (●, ○, •, ·) so markdown's '-' is the only marker."""
    return _BULLET_GLYPH_RE.sub("", text or "")


def make_slug(title: str) -> str:
    """Sanitize a title into a kebab-case slug."""
    s = unicodedata.normalize("NFKD", title or "")
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def _get_text(item: DocItem) -> str:
    """Prefer .orig (preserves source whitespace) over .text, fall back to ''."""
    orig = getattr(item, "orig", None)
    if orig:
        return orig
    return getattr(item, "text", "") or ""


# Pictures smaller than this many points in either dimension are treated as
# slide-template chrome (logos, decorative banners) and stripped from segments.
_MIN_PICTURE_DIM_PT = 200


def _picture_is_chrome(pic: PictureItem) -> bool:
    """True if the picture is too small / oddly-shaped to be a real diagram."""
    if not pic.prov:
        return False
    bbox = pic.prov[0].bbox
    width = abs(bbox.r - bbox.l)
    height = abs(bbox.t - bbox.b)
    return width < _MIN_PICTURE_DIM_PT or height < _MIN_PICTURE_DIM_PT


def _page_of(item: DocItem) -> int | None:
    if getattr(item, "prov", None):
        return item.prov[0].page_no
    return None


# ---------------------------------------------------------------------------
# Phase 2 — Segment
# ---------------------------------------------------------------------------
def segment_slides(doc: DoclingDocument) -> list[Slide]:
    """Partition doc.iterate_items() into one Slide per 1-based page."""
    slides: dict[int, Slide] = {}

    for item, _level in doc.iterate_items():
        if not isinstance(item, DocItem):
            continue
        page = _page_of(item)
        if page is None:
            continue
        slide = slides.setdefault(page, Slide(page=page))

        text = _get_text(item)
        if text:
            slide.raw_text_parts.append(text)

        # Template chrome is captured in text_blob (Rule 1 uses it) but is not
        # appended to items[] and does not become the slide title.
        if isinstance(item, (TitleItem, SectionHeaderItem)) and _is_template_header(
            text
        ):
            continue

        # First non-template TitleItem / SectionHeaderItem becomes the title.
        if isinstance(item, (TitleItem, SectionHeaderItem)) and slide.title is None:
            slide.title = _norm_ws(text)
            # The title itself is rendered separately; don't duplicate it.
            continue

        if isinstance(item, PictureItem):
            if _picture_is_chrome(item):
                continue  # slide-template logo/banner — drop entirely
            slide.pictures.append(item)

        slide.items.append(item)

    for slide in slides.values():
        slide.text_blob = _norm_ws(" ".join(slide.raw_text_parts)).lower()

    return [slides[p] for p in sorted(slides)]


# ---------------------------------------------------------------------------
# Phase 3 — Filter
# ---------------------------------------------------------------------------
# Heuristic thresholds — tuned empirically against the OSS2023 sample.
_MAX_BRANDING_PAGE = 2          # slides 1-2 are usually branding/title
_MAX_TITLE_SLIDE_PAGE = 3       # look for the human-readable title in slides 1-3
_MAX_CONTACT_CARD_CHARS = 80    # short body w/ email/handle => contact card
_MAX_PICTURE_HEAVY_CHARS = 120  # mostly-image slide threshold
_MIN_CONTENT_CHARS = 25         # below this w/o title/code/table/image -> empty

_AGENDA_RE = re.compile(
    r"^(agenda|outline|overview|contents|table of contents)\s*$", re.IGNORECASE
)
_THANKS_RE = re.compile(
    r"^(thanks?|thank you|questions\??|q\s*&\s*a)\s*$", re.IGNORECASE
)
_KEEP_TITLE_RE = re.compile(
    r"^(references|citations|bibliography|further reading|links|resources)\s*$",
    re.IGNORECASE,
)
_BRANDING_TITLE_RE = re.compile(
    r"^(zephyr\s*project|developer summit|#embeddedossummit)\b", re.IGNORECASE
)
_CONTACT_RE = re.compile(r"@|\bgithub:|\bdiscord:|https?://", re.IGNORECASE)


def _body_text_len(slide: Slide) -> int:
    """Total chars across body text items (excludes template chrome)."""
    parts = []
    for item in slide.items:
        if isinstance(item, (TextItem, ListItem, SectionHeaderItem)):
            parts.append(_get_text(item))
    return sum(len(_norm_ws(p)) for p in parts)


def _has_content(slide: Slide) -> bool:
    has_code = any(
        isinstance(it, (TextItem, ListItem)) and _is_code_textitem(it)
        for it in slide.items
    )
    has_table = any(isinstance(it, TableItem) for it in slide.items)
    return bool(slide.title) or has_code or has_table or bool(slide.pictures)


def _rule_drop_branding(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped = []
    kept = []
    for s in slides:
        body_len = _body_text_len(s)
        body_text = _norm_ws(" ".join(_get_text(it) for it in s.items))
        title = s.title or ""

        first_two = s.page <= _MAX_BRANDING_PAGE
        is_branding_title = bool(_BRANDING_TITLE_RE.match(title))
        has_contact = bool(_CONTACT_RE.search(body_text))
        is_contact_card = body_len < _MAX_CONTACT_CARD_CHARS and has_contact
        # Title-page heuristic: on the first two pages, any slide whose body
        # is dominated by contact info (email/handle/URL) is a title page,
        # even if the body itself runs slightly long.
        is_title_page = first_two and has_contact

        looks_brand = first_two or is_branding_title or is_contact_card

        high_picture_low_text = (
            bool(s.pictures) and body_len <= _MAX_PICTURE_HEAVY_CHARS
        )
        page1_empty = s.page == 1 and not _has_content(s)

        if is_title_page or (
            looks_brand and (high_picture_low_text or page1_empty)
        ):
            dropped.append(s.page)
        else:
            kept.append(s)
    return kept, dropped


def _rule_drop_agenda(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped = []
    kept = []
    for s in slides:
        title = s.title or ""
        if _AGENDA_RE.match(title.strip()):
            # Body should be just bullets / short text — no code, no pictures.
            no_code = not any(
                isinstance(it, (TextItem, ListItem)) and _is_code_textitem(it)
                for it in s.items
            )
            no_pics = not s.pictures
            if no_code and no_pics:
                dropped.append(s.page)
                continue
        kept.append(s)
    return kept, dropped


def _rule_drop_thanks(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped = []
    kept = []
    for s in slides:
        title = (s.title or "").strip()
        body = _norm_ws(" ".join(_get_text(it) for it in s.items))
        # References / citations slides MUST survive.
        if _KEEP_TITLE_RE.match(title):
            kept.append(s)
            continue
        if _THANKS_RE.match(title) or _THANKS_RE.match(body):
            dropped.append(s.page)
            continue
        kept.append(s)
    return kept, dropped


def _rule_drop_low_content(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped = []
    kept = []
    for s in slides:
        body_len = _body_text_len(s)
        if (
            not s.title
            and not s.pictures
            and not any(isinstance(it, TableItem) for it in s.items)
            and not any(
                isinstance(it, (TextItem, ListItem)) and _is_code_textitem(it)
                for it in s.items
            )
            and body_len < _MIN_CONTENT_CHARS
        ):
            dropped.append(s.page)
            continue
        kept.append(s)
    return kept, dropped


def _picture_fingerprint(p: PictureItem) -> str:
    """
    Compare-by identifier for build-up dedup.

    Build-ups have visually identical diagrams across adjacent pages, but
    docling assigns each occurrence a distinct `self_ref`. So we hash the
    pixel content first; only fall back to `self_ref` / id() when the
    image data is unavailable.
    """
    try:
        pil = p.image.pil_image if p.image else None
        if pil is not None:
            # Dimensions + content bytes; same diagram across pages collides.
            sig = f"{pil.size}|".encode() + pil.tobytes()
            return "px:" + hashlib.md5(sig, usedforsecurity=False).hexdigest()
    except Exception:  # noqa: BLE001, S110 — fingerprint best-effort
        pass
    self_ref = getattr(p, "self_ref", None)
    if self_ref:
        return f"ref:{self_ref}"
    return f"id:{id(p)}"


def _text_fragments(slide: Slide) -> set[str]:
    """Set of normalized text fragments — for prefix/subset comparison."""
    frags: set[str] = set()
    for it in slide.items:
        if isinstance(it, (TextItem, ListItem)):
            t = _norm_ws(_get_text(it)).lower()
            if t:
                frags.add(t)
    return frags


def _is_buildup_pair(a: Slide, b: Slide) -> bool:
    same_title = (a.title or "").lower() == (b.title or "").lower()
    if not same_title:
        return False

    a_pics = sorted(_picture_fingerprint(p) for p in a.pictures)
    b_pics = sorted(_picture_fingerprint(p) for p in b.pictures)
    if a_pics != b_pics:
        return False

    a_frags = _text_fragments(a)
    b_frags = _text_fragments(b)
    if not a_frags:
        # No body to compare; identical picture+title means b extends a trivially.
        return True
    # Subset: every fragment in a appears in b.
    return a_frags.issubset(b_frags)


def _rule_dedupe_buildup(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped: list[int] = []
    work = list(slides)
    while True:
        new: list[Slide] = []
        skipped_any = False
        i = 0
        while i < len(work):
            if i + 1 < len(work) and _is_buildup_pair(work[i], work[i + 1]):
                dropped.append(work[i].page)
                skipped_any = True
                i += 1  # skip i, keep i+1 for further comparison
                continue
            new.append(work[i])
            i += 1
        work = new
        if not skipped_any:
            break
    return work, dropped


def _rule_final_tidy(slides: list[Slide]) -> tuple[list[Slide], list[int]]:
    dropped = []
    kept = []
    for s in slides:
        if _has_content(s):
            kept.append(s)
        else:
            dropped.append(s.page)
    return kept, dropped


@dataclass
class FilterReport:
    initial: int
    final: int
    branding: list[int] = field(default_factory=list)
    agenda: list[int] = field(default_factory=list)
    thanks: list[int] = field(default_factory=list)
    low_content: list[int] = field(default_factory=list)
    buildup: list[int] = field(default_factory=list)
    tidy: list[int] = field(default_factory=list)
    forced_keep: list[int] = field(default_factory=list)
    forced_drop: list[int] = field(default_factory=list)


def filter_slides(
    slides: list[Slide],
    *,
    keep_pages: set[int] | None = None,
    drop_pages: set[int] | None = None,
) -> tuple[list[Slide], FilterReport]:
    report = FilterReport(initial=len(slides), final=0)
    keep_pages = keep_pages or set()
    drop_pages = drop_pages or set()

    # Separate forced-keep so they survive every rule.
    forced_keep_slides = [s for s in slides if s.page in keep_pages]
    candidates = [s for s in slides if s.page not in keep_pages]

    candidates, report.branding = _rule_drop_branding(candidates)
    candidates, report.agenda = _rule_drop_agenda(candidates)
    candidates, report.thanks = _rule_drop_thanks(candidates)
    candidates, report.low_content = _rule_drop_low_content(candidates)
    candidates, report.buildup = _rule_dedupe_buildup(candidates)
    candidates, report.tidy = _rule_final_tidy(candidates)

    kept = sorted(
        [*candidates, *forced_keep_slides], key=lambda s: s.page
    )
    if drop_pages:
        before = {s.page for s in kept}
        kept = [s for s in kept if s.page not in drop_pages]
        report.forced_drop = sorted(before & drop_pages)

    if keep_pages:
        report.forced_keep = sorted(keep_pages)

    report.final = len(kept)
    return kept, report


# ---------------------------------------------------------------------------
# Code-block detection
# ---------------------------------------------------------------------------
_KCONFIG_PREFIX_RE = re.compile(r"^\s*#\s*Add these.*$|^\s*CONFIG_[A-Z0-9_]+\s*=", re.MULTILINE)
_C_HINT_RE = re.compile(
    r"\b(#define|#include|int\s+\w|void\s+\w|struct\s+\w|static\s+\w|"
    r"return\s+\w|if\s*\(|for\s*\(|while\s*\(|LOG_[A-Z_]+\s*\(|"
    r"RTIO_[A-Z_]+|SENSOR_[A-Z_]+|DT_[A-Z_]+)\b"
)
_PUNCT_CHARS = set("{};()=*&|<>[]")
_MIN_CODE_TEXT_LEN = 8
_MIN_CODE_DENSITY_LEN = 40
_MIN_CODE_PUNCT_RATIO = 0.10
_MIN_SEMICOLONS_FOR_CODE = 2


def _is_code_textitem(item: DocItem) -> bool:
    text = _get_text(item)
    if not text or len(text) < _MIN_CODE_TEXT_LEN:
        return False

    if _KCONFIG_PREFIX_RE.search(text):
        return True
    if _C_HINT_RE.search(text):
        return True

    # Density check — code has lots of punctuation.
    if len(text) >= _MIN_CODE_DENSITY_LEN:
        punct = sum(1 for c in text if c in _PUNCT_CHARS)
        if punct / len(text) >= _MIN_CODE_PUNCT_RATIO and (
            "\n" in text or text.count(";") >= _MIN_SEMICOLONS_FOR_CODE
        ):
            return True
    return False


def _reflow_code(text: str, lang: str) -> str:
    """
    Recover newlines docling collapsed into spaces inside a code block.

    PDF text extraction joins visually-broken lines with spaces and keeps
    alignment padding intact. We use a few syntax-specific rules to put
    line breaks back where they almost certainly belonged in source.
    """
    s = text
    if lang == "kconfig":
        # Break before another '#'-comment or a 'CONFIG_' assignment.
        s = re.sub(r"\s+(?=(#\s|CONFIG_[A-Z0-9_]+\s*=))", "\n", s)
    elif lang == "c":
        # End-of-statement / brace boundaries — any whitespace counts.
        s = re.sub(r";[ \t]+", ";\n", s)
        s = re.sub(r"\{[ \t]+", "{\n", s)
        s = re.sub(r"}[ \t]+", "}\n", s)
        # Inside a `// comment ...`, the comment ends at end-of-source-line.
        # When we see a single space followed by an identifier-with-( (a
        # macro/function call) or `);` / `8,`-style numeric arg, that's the
        # next code line that docling joined onto the comment — break before
        # it.
        s = re.sub(
            r"(//[^\n]+?)[ \t](?=[A-Za-z_][A-Za-z0-9_]*\s*\(|\)\s*;|[0-9]+,)",
            r"\1\n",
            s,
        )
    # Collapse runs of 3+ spaces (artifacts of alignment) down to 1.
    s = re.sub(r"[ \t]{3,}", " ", s)
    return s.strip()


def _guess_code_language(text: str) -> str:
    if _KCONFIG_PREFIX_RE.search(text):
        return "kconfig"
    if (
        _C_HINT_RE.search(text)
        or text.count(";") >= _MIN_SEMICOLONS_FOR_CODE
        or "{" in text
    ):
        return "c"
    return ""


# ---------------------------------------------------------------------------
# Phase 4 — Render
# ---------------------------------------------------------------------------
def _save_picture(
    pic: PictureItem,
    slide_page: int,
    idx: int,
    images_dir: Path,
) -> str | None:
    """Save a PictureItem as PNG; return the relative path or None on failure."""
    pil = pic.image.pil_image if pic.image else None
    if pil is None:
        return None
    try:
        images_dir.mkdir(parents=True, exist_ok=True)
        fname = f"slide-{slide_page:02d}-{idx}.png"
        pil.save(images_dir / fname, format="PNG")
    except Exception as exc:  # noqa: BLE001
        log.warning("Image extraction failed on slide %d: %s", slide_page, exc)
        return None
    return f"images/{fname}"


def _is_list_like(item: DocItem) -> bool:
    if isinstance(item, ListItem):
        return True
    label = getattr(item, "label", None)
    return str(label).lower().endswith("list_item")


def _render_table(item: TableItem) -> str:
    try:
        return item.export_to_markdown()
    except Exception:  # noqa: BLE001
        return "_[table extraction failed]_"


def _render_picture(
    item: PictureItem, slide_page: int, pic_idx: int, images_dir: Path
) -> str:
    rel = _save_picture(item, slide_page, pic_idx, images_dir)
    if rel:
        return f"![]({rel})"
    return f"> [Diagram on slide {slide_page}]"


def _render_text(item: TextItem | ListItem) -> str:
    text = _strip_bullet_glyph(_norm_ws(_get_text(item)))
    if _is_list_like(item):
        return f"- {text}"
    return text


def _flush_code(buf: list[str], chunks: list[str]) -> None:
    if not buf:
        return
    joined = "\n".join(buf).rstrip()
    lang = _guess_code_language(joined)
    body = _reflow_code(joined, lang)
    chunks.append(f"```{lang}\n{body}\n```")
    buf.clear()


def _render_items(
    items: list[DocItem],
    slide_page: int,
    images_dir: Path,
) -> str:
    """Render a flat list of items, grouping consecutive code TextItems into one fence."""
    chunks: list[str] = []
    code_buf: list[str] = []
    pic_idx = 0

    for item in items:
        if isinstance(item, PictureItem):
            _flush_code(code_buf, chunks)
            chunks.append(_render_picture(item, slide_page, pic_idx, images_dir))
            pic_idx += 1
        elif isinstance(item, TableItem):
            _flush_code(code_buf, chunks)
            chunks.append(_render_table(item))
        elif isinstance(item, SectionHeaderItem):
            _flush_code(code_buf, chunks)
            text = _norm_ws(_get_text(item))
            if text:
                chunks.append(f"### {text}")
        elif isinstance(item, (TextItem, ListItem)):
            text = _get_text(item)
            if not text or not text.strip():
                continue
            if _is_code_textitem(item):
                code_buf.append(text.rstrip())
            else:
                _flush_code(code_buf, chunks)
                chunks.append(_render_text(item))

    _flush_code(code_buf, chunks)
    return "\n\n".join(chunks)


def render_slide(slide: Slide, images_dir: Path) -> str:
    heading = slide.title or f"Slide {slide.page}"
    body = _render_items(slide.items, slide.page, images_dir)
    return f"## {heading} <!-- slide {slide.page} -->\n\n{body}".rstrip()


# ---------------------------------------------------------------------------
# Frontmatter
# ---------------------------------------------------------------------------
SCRIPT_DERIVED_KEYS = {"aliases", "created"}


def _pick_human_title(slides: list[Slide], pdf_stem: str) -> str:
    """First non-template title in slides 1-3, else the PDF stem."""
    for s in slides:
        if s.page > _MAX_TITLE_SLIDE_PAGE:
            break
        if s.title and not _is_template_header(s.title):
            return s.title
    return pdf_stem


def build_frontmatter(  # noqa: PLR0913
    *,
    human_title: str,
    pdf_stem: str,
    extra_categories: list[str],
    extra_tags: list[str],
    url: str | None,
    overlay: dict,
) -> str:
    base: dict = {
        "categories": [],
        "aliases": [human_title],
        "created": datetime.now(tz=UTC).date().isoformat(),
        "type": "reference",
        "tags": ["presentation", "talk"],
        "source": f"[[{pdf_stem}]]",
    }
    if url:
        base["url"] = url

    # CLI flag appends
    if extra_categories:
        base["categories"] = list(base["categories"]) + list(extra_categories)
    if extra_tags:
        base["tags"] = list(base["tags"]) + list(extra_tags)

    # YAML overlay
    if overlay:
        for k, v in overlay.items():
            if k in SCRIPT_DERIVED_KEYS:
                log.warning(
                    "Ignoring user-provided '%s' from --frontmatter-yaml "
                    "(always script-derived)",
                    k,
                )
                continue
            if (
                k in base
                and isinstance(base[k], list)
                and isinstance(v, list)
            ):
                base[k] = list(base[k]) + list(v)
            else:
                base[k] = v

    yaml_body = yaml.safe_dump(base, sort_keys=False, allow_unicode=True).rstrip()
    return f"---\n{yaml_body}\n---\n"


# ---------------------------------------------------------------------------
# Render document
# ---------------------------------------------------------------------------
def render_document(
    slides: list[Slide],
    frontmatter: str,
    images_dir: Path,
) -> str:
    body_sections = [render_slide(s, images_dir) for s in slides]
    body = "\n\n".join(body_sections).strip() + "\n"

    try:
        body = mdformat.text(body, extensions={"tables", "gfm"})
    except Exception as exc:  # noqa: BLE001
        log.warning("mdformat failed (%s); writing unformatted body", exc)

    return frontmatter + "\n" + body


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------
def process_pdf(  # noqa: PLR0913, PLR0914, PLR0915, C901
    converter: DocumentConverter,
    source: Path,
    out_dir: Path,
    *,
    pipeline_opts: PdfPipelineOptions,
    extra_categories: list[str],
    extra_tags: list[str],
    url: str | None,
    overlay: dict,
    keep_pages: set[int],
    drop_pages: set[int],
    copy_to: Path | None,
) -> int:
    pdf_stem = source.stem
    console.rule(f"[bold]{pdf_stem}[/]")
    t0 = time.perf_counter()

    # Phase 1 — Convert
    console.log("[bold]Phase 1 — Convert[/]")
    result = convert_full(converter, source, pipeline_opts=pipeline_opts)
    if result is None:
        return 1
    info = extract_confidence(result)
    score = f"{info.mean_score:.2f}" if not math.isnan(info.mean_score) else "N/A"
    console.log(f"  Confidence: mean={score} ({info.mean_grade})")
    doc = result.document

    # Phase 2 — Segment
    console.log("[bold]Phase 2 — Segment[/]")
    slides = segment_slides(doc)
    console.log(f"  {len(slides)} slides indexed")

    # Phase 3 — Filter
    console.log("[bold]Phase 3 — Filter[/]")
    kept, report = filter_slides(
        slides, keep_pages=keep_pages, drop_pages=drop_pages
    )
    if report.branding:
        console.log(f"  dropped {len(report.branding)} branding (slides {report.branding})")
    if report.agenda:
        console.log(f"  dropped {len(report.agenda)} agenda (slides {report.agenda})")
    if report.thanks:
        console.log(f"  dropped {len(report.thanks)} thanks/Q&A (slides {report.thanks})")
    if report.low_content:
        console.log(f"  dropped {len(report.low_content)} low-content (slides {report.low_content})")
    if report.buildup:
        console.log(f"  collapsed {len(report.buildup)} build-up frames (slides {report.buildup})")
    if report.tidy:
        console.log(f"  dropped {len(report.tidy)} empty-after-filter (slides {report.tidy})")
    if report.forced_keep:
        console.log(f"  forced keep: {report.forced_keep}")
    if report.forced_drop:
        console.log(f"  forced drop: {report.forced_drop}")
    console.log(f"  {report.final} slides kept")

    # Phase 4 — Render
    console.log("[bold]Phase 4 — Render[/]")
    human_title = _pick_human_title(slides, pdf_stem)
    slug = make_slug(human_title) or make_slug(pdf_stem) or "presentation"

    pres_dir = out_dir / slug
    # Clean previous output so stale images don't accumulate across re-runs.
    if pres_dir.exists():
        shutil.rmtree(pres_dir)
    images_dir = pres_dir / "images"
    pres_dir.mkdir(parents=True, exist_ok=True)

    frontmatter = build_frontmatter(
        human_title=human_title,
        pdf_stem=pdf_stem,
        extra_categories=extra_categories,
        extra_tags=extra_tags,
        url=url,
        overlay=overlay,
    )
    doc_text = render_document(kept, frontmatter, images_dir)
    md_path = pres_dir / f"{slug}.md"
    md_path.write_text(doc_text, encoding="utf-8")

    n_images = len(list(images_dir.glob("*.png"))) if images_dir.exists() else 0
    n_code = doc_text.count("\n```")  # rough — counts opening fences
    console.log(
        f"  → {md_path.name} ({len(kept)} sections, {n_images} images, "
        f"{n_code // 2} code blocks)"
    )

    if copy_to is not None:
        target = copy_to / slug
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(pres_dir, target)
        console.log(f"  copied to {target}")

    elapsed = time.perf_counter() - t0
    console.log(f"[green bold]✓[/] {pdf_stem} done in {elapsed:.1f}s")
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
app = cyclopts.App(
    help="Extract a technical-presentation PDF into a single Obsidian markdown file.",
)


@app.default
def main(  # noqa: PLR0913
    input_pdf: Path,
    *,
    output: Annotated[
        Path | None,
        cyclopts.Parameter(["-o", "--output"], help="output directory  [./out/<slug>/]"),
    ] = None,
    copy_to: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["--copy-to"],
            help="copy the produced <slug>/ directory under this path",
        ),
    ] = None,
    url: Annotated[
        str | None,
        cyclopts.Parameter(["--url"], help="value for the frontmatter 'url' key"),
    ] = None,
    category: Annotated[
        list[str] | None,
        cyclopts.Parameter(
            ["--category"],
            help="append to frontmatter 'categories'; repeatable",
        ),
    ] = None,
    tag: Annotated[
        list[str] | None,
        cyclopts.Parameter(
            ["--tag"],
            help="append to frontmatter 'tags'; repeatable",
        ),
    ] = None,
    frontmatter_yaml: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["--frontmatter-yaml"],
            help="YAML file whose top-level keys are merged into frontmatter",
        ),
    ] = None,
    keep: Annotated[
        str | None,
        cyclopts.Parameter(
            ["--keep"], help="comma/range page list to force-keep (e.g. '5,7-9')"
        ),
    ] = None,
    drop: Annotated[
        str | None,
        cyclopts.Parameter(
            ["--drop"], help="comma/range page list to force-drop"
        ),
    ] = None,
    ocr: Annotated[
        bool, cyclopts.Parameter(["--ocr"], negative="", help="force full-page OCR")
    ] = False,
    verbose: Annotated[
        bool,
        cyclopts.Parameter(
            ["-v", "--verbose"], negative="", help="enable docling debug logging"
        ),
    ] = False,
) -> None:
    """
    Extract a presentation PDF into a single Obsidian markdown file.

    Examples:
        ./presi-extract.py inputs/presi_sample/oss2023.pdf
        ./presi-extract.py talk.pdf --category zephyr --tag rtio \
            --copy-to ~/Documents/Obsidian/Techie/reference

    """
    logging.basicConfig(
        level="DEBUG" if verbose else "INFO",
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(rich_tracebacks=True, tracebacks_show_locals=False)],
    )
    if not verbose:
        logging.getLogger("docling").setLevel(logging.WARNING)

    source = input_pdf.resolve()
    if not source.is_file() or source.suffix.lower() != ".pdf":
        console.print(f"[red]Not a PDF file: {source}[/]")
        raise SystemExit(1)

    out_dir = output or (Path(__file__).parent / "out")
    out_dir.mkdir(parents=True, exist_ok=True)

    overlay: dict = {}
    if frontmatter_yaml is not None:
        if not frontmatter_yaml.is_file():
            console.print(f"[red]YAML overlay not found: {frontmatter_yaml}[/]")
            raise SystemExit(1)
        with frontmatter_yaml.open("r", encoding="utf-8") as f:
            loaded = yaml.safe_load(f) or {}
        if not isinstance(loaded, dict):
            console.print(
                f"[red]YAML overlay must be a mapping at top level: {frontmatter_yaml}[/]"
            )
            raise SystemExit(1)
        overlay = loaded

    keep_pages = parse_page_list(keep) if keep else set()
    drop_pages = parse_page_list(drop) if drop else set()

    use_cuda = not bool(os.environ.get("DS_EXTRACTOR_CPU_MODE"))
    if not use_cuda:
        log.warning("Using CPU instead of CUDA")

    console.log(f"Input:   {source}")
    console.log(f"Output:  {out_dir}")

    t_init = time.perf_counter()
    opts = build_pipeline_options(
        fast=bool(os.environ.get("DS_EXTRACTOR_FAST_MODE")),
        ocr=ocr,
        cuda=use_cuda,
    )
    converter = create_converter(opts)
    console.log(f"Pipeline ready in {time.perf_counter() - t_init:.1f}s")

    rc = process_pdf(
        converter,
        source,
        out_dir,
        pipeline_opts=opts,
        extra_categories=list(category or []),
        extra_tags=list(tag or []),
        url=url,
        overlay=overlay,
        keep_pages=keep_pages,
        drop_pages=drop_pages,
        copy_to=copy_to,
    )
    if rc:
        raise SystemExit(rc)


if __name__ == "__main__":
    app()
