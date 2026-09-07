#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "docling>=2.0",
#   "pandas>=2.0",
#   "rich>=13.0",
#   "tabulate>=0.9",
#   "mdformat>=0.7",
#   "mdformat-gfm>=0.4",
#   "attrs",
#   "cyclopts",
# ]
# ///

from __future__ import annotations

import logging
import math
import os
import re
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Annotated

import attrs
import cyclopts
import mdformat
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
    import pandas as pd
    from docling.datamodel.document import ConversionResult

console = Console()
log = logging.getLogger("ds-extract")


@cyclopts.Parameter(converter="parse_page")
@attrs.frozen
class PageRange:
    start: int
    end: int

    @cyclopts.Parameter(n_tokens=1, accepts_keys=False)
    @classmethod
    def parse_page(cls, tokens):
        """Parse a coordinate string like '10,20' into a Point."""
        if tokens[0] and (input_tok := tokens[0].value):
            delimeter = "," if "," in input_tok else "-"
            a, b = input_tok.split(delimeter, 1)
            start = int(a)
            end = int(b)
            if start < 1 or end < start:
                msg = f"invalid range: {start}-{end}"
                raise cyclopts.CoercionError(msg)
            return cls(start, end)
        raise ValueError("Not enough tokens")


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------
@dataclass
class RegisterEntry:
    """A single register parsed from the register map."""

    address: int
    name: str
    default: int | None = None
    access: str = ""
    comment: str = ""
    section: str = ""


@dataclass
class ConfidenceInfo:
    """Collected confidence metrics from a conversion."""

    mean_score: float = float("nan")
    mean_grade: str = "UNSPECIFIED"
    page_scores: dict[int, float] = field(default_factory=dict)


# ---------------------------------------------------------------------------
# Pipeline configuration (kept from original)
# ---------------------------------------------------------------------------
def build_pipeline_options(
    *,
    fast: bool = False,
    ocr: bool = False,
    cuda: bool = True,
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
        generate_picture_images=False,
        generate_page_images=ocr,
        enable_remote_services=False,
        table_batch_size=8 if cuda else 4,
        layout_batch_size=16 if cuda else 4,
        document_timeout=600.0,
    )


def create_converter(
    opts: PdfPipelineOptions,
    *,
    backend: type | None = None,
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


# ---------------------------------------------------------------------------
# Extraction helpers
# ---------------------------------------------------------------------------
def _try_convert(
    converter: DocumentConverter,
    source: Path,
    page_range: PageRange,
) -> ConversionResult | None:
    """Single conversion attempt. Returns result or None."""
    prange: tuple[int, int] = attrs.astuple(page_range)
    try:
        result = converter.convert(source, page_range=prange)
    except Exception as exc:  # ruff: ignore[blind-except] — docling can raise arbitrary exceptions
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
                f"[yellow]  ⚠ {rich_escape(e.module_name)}: {rich_escape(e.error_message)}[/]"
            )

    return result


def convert_pages(
    converter: DocumentConverter,
    source: Path,
    page_range: PageRange,
    *,
    pipeline_opts: PdfPipelineOptions | None = None,
) -> ConversionResult | None:
    """Convert with automatic fallback: default → PyPdfium backend → full-page OCR."""
    # Attempt 1: default converter
    result = _try_convert(converter, source, page_range)
    if result is not None:
        return result

    if pipeline_opts is None:
        console.log("[red]  No fallback available (pipeline_opts not provided)[/]")
        return None

    # Attempt 2: PyPdfium backend (handles subsetted/glyph fonts better)
    console.log("[yellow]  Retrying with PyPdfium backend...[/]")
    try:
        fallback = create_converter(pipeline_opts, backend=PyPdfiumDocumentBackend)
        result = _try_convert(fallback, source, page_range)
        if result is not None:
            return result
    except Exception as exc:  # ruff: ignore[blind-except]
        console.log(f"[yellow]  PyPdfium fallback failed: {rich_escape(str(exc))}[/]")

    # Attempt 3: force full-page OCR
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
        fallback = create_converter(ocr_opts, backend=PyPdfiumDocumentBackend)
        result = _try_convert(fallback, source, page_range)
        if result is not None:
            return result
    except Exception as exc:  # ruff: ignore[blind-except]
        console.log(f"[yellow]  OCR fallback failed: {rich_escape(str(exc))}[/]")

    console.log("[red bold]✗[/] All conversion attempts failed")
    return None


def get_page(item: DocItem) -> int | None:
    """Extract 1-based page number from a DocItem's provenance."""
    if item.prov:
        return item.prov[0].page_no
    return None


def extract_confidence(result: ConversionResult) -> ConfidenceInfo:
    """Pull confidence metrics from a ConversionResult."""
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
    if hasattr(conf, "pages") and conf.pages:
        for pg_no, pg_conf in conf.pages.items():
            pg_score = pg_conf.mean_score
            if pg_score is not None and not (
                isinstance(pg_score, float) and math.isnan(pg_score)
            ):
                info.page_scores[int(pg_no)] = float(pg_score)
    return info


def log_confidence(label: str, result: ConversionResult) -> ConfidenceInfo:
    """Extract and log confidence to console. Returns ConfidenceInfo."""
    info = extract_confidence(result)
    score_str = f"{info.mean_score:.2f}" if not math.isnan(info.mean_score) else "N/A"
    console.log(f"  [bold]{label}:[/] mean={score_str} ({info.mean_grade})")
    return info


# ---------------------------------------------------------------------------
# Register map detection and parsing
# ---------------------------------------------------------------------------
_HEX_RE = re.compile(r"^(?:0x)?[0-9a-fA-F]{1,4}h?$")
_BINARY_RE = re.compile(r"^[01]{4,16}$")
_BINARY_PREFIXED_RE = re.compile(r"^0b[01]+$")
_MAJOR_SECTION_RE = re.compile(r"^\d+(\.\d+)?\s+")
_MIN_TABLE_ROWS = 2


def _find_address_column(
    df: pd.DataFrame,
    cols: list[str],
) -> str | None:
    """Find the address column by header keyword or hex-value heuristic."""
    for i, col in enumerate(cols):
        if any(kw in col for kw in ("address", "hex", "addr")):
            return str(df.columns[i])
    for orig_col in df.columns:
        sample = df[orig_col].dropna().astype(str).head(10)
        hex_count = sum(1 for v in sample if _HEX_RE.match(v.strip()))
        if hex_count >= max(_MIN_TABLE_ROWS, len(sample) // 3):
            return str(orig_col)
    return None


def _find_name_column(
    df: pd.DataFrame,
    cols: list[str],
    *,
    exclude: str | None = None,
) -> str | None:
    """Find the register name column by header keyword or identifier heuristic."""
    for i, col in enumerate(cols):
        orig = str(df.columns[i])
        if (
            any(kw in col for kw in ("name", "register", "mnemonic"))
            and orig != exclude
        ):
            return orig
    for orig_col in df.columns:
        if str(orig_col) == exclude:
            continue
        sample = df[orig_col].dropna().astype(str).head(10)
        id_count = sum(1 for v in sample if re.match(r"^[A-Z][A-Z0-9_]+$", v.strip()))
        if id_count >= max(_MIN_TABLE_ROWS, len(sample) // 3):
            return str(orig_col)
    return None


def _find_optional_columns(
    cols: list[str],
    df: pd.DataFrame,
    mapping: dict[str, str],
) -> None:
    """Populate optional columns (default, access, comment) into *mapping*."""
    for i, col in enumerate(cols):
        orig = str(df.columns[i])
        if orig in mapping.values():
            continue
        if "default" in col or "reset" in col:
            mapping.setdefault("default", orig)
        elif "access" in col or "type" in col or "r/w" in col:
            mapping.setdefault("access", orig)
        elif "description" in col or "comment" in col:
            mapping.setdefault("comment", orig)


def detect_register_columns(df: pd.DataFrame) -> dict[str, str] | None:
    """
    Detect if a DataFrame looks like a register map table.

    Returns a mapping of semantic role -> column name, or None if not a register map.
    """
    cols = [str(c).strip().lower() for c in df.columns]
    mapping: dict[str, str] = {}

    addr_col = _find_address_column(df, cols)
    if addr_col is None:
        return None
    mapping["address"] = addr_col

    name_col = _find_name_column(df, cols, exclude=addr_col)
    if name_col is None:
        return None
    mapping["name"] = name_col

    _find_optional_columns(cols, df, mapping)
    return mapping


def find_register_map_tables(doc: DoclingDocument) -> list[pd.DataFrame]:
    """Find all register-map-looking tables in a document."""
    dfs: list[pd.DataFrame] = []
    for table in doc.tables:
        try:
            df = table.export_to_dataframe(doc=doc)
        except Exception:  # ruff: ignore[blind-except]
            log.debug("Skipping table that failed to export as DataFrame")
            continue
        if len(df) < _MIN_TABLE_ROWS:
            continue
        if detect_register_columns(df) is not None:
            dfs.append(df)
    return dfs


_MAX_CELL_LEN = 60


def _truncate(s: str, limit: int = _MAX_CELL_LEN) -> str:
    """Truncate a cell value, adding ellipsis if it exceeds *limit* chars."""
    s = s.strip()
    if len(s) <= limit:
        return s
    return s[:limit].rstrip() + "…"


def normalize_register_name(raw: str) -> str:
    """Clean up a register name for use in C defines."""
    # Take only the first word-group to avoid OCR run-on garbage
    name = raw.strip().split("\n")[0]
    name = _truncate(name, 40)
    # Remove parenthetical suffixes like "(r)" or "(rw)"
    name = re.sub(r"\s*\([^)]*\)\s*$", "", name)
    # Replace non-identifier chars with underscore
    name = re.sub(r"[^A-Za-z0-9_]", "_", name)
    # Collapse multiple underscores
    name = re.sub(r"_+", "_", name).strip("_")
    return name.upper()


def binary_to_hex(binary_str: str) -> str | None:
    """Convert a binary string like '00001001' or '0b00001001' to hex '0x09'."""
    s = binary_str.strip()
    if _BINARY_PREFIXED_RE.match(s):
        val = int(s, 2)
        return f"0x{val:02X}"
    if _BINARY_RE.match(s):
        val = int(s, 2)
        return f"0x{val:02X}"
    return None


def _parse_address(raw: str) -> int | None:
    """Parse a hex address string like '0x0F', '0Fh', '15' into int."""
    s = raw.strip()
    if not s:
        return None
    # Build (value, base) candidates based on format
    sl = s.lower()
    if sl.startswith("0x"):
        candidates = [(s, 16)]
    elif sl.endswith("h"):
        candidates = [(s[:-1], 16)]
    else:
        candidates = [(s, 16), (s, 10)]
    for val, base in candidates:
        try:
            return int(val, base)
        except ValueError:
            continue
    return None


def _parse_default(raw: str) -> int | None:
    """Parse a default value — could be binary, hex, or decimal."""
    s = raw.strip()
    if not s or s.lower() in {"", "-", "n/a", "na", "reserved"}:
        return None
    hex_str = binary_to_hex(s)
    if hex_str:
        return int(hex_str, 16)
    if s.lower().startswith("0x"):
        try:
            return int(s, 16)
        except ValueError:
            return None
    try:
        return int(s)
    except ValueError:
        return None


def _parse_row(
    row: pd.Series,
    col_map: dict[str, str],
) -> RegisterEntry | None:
    """Parse a single DataFrame row into a RegisterEntry, or None if invalid."""
    raw_addr = str(row.get(col_map["address"], "")).strip()
    addr = _parse_address(raw_addr)
    if addr is None:
        return None

    name = normalize_register_name(str(row.get(col_map["name"], "")).strip())
    if not name or name == "RESERVED" or re.fullmatch(r"[0-9_]+", name):
        return None

    default_val = None
    if default_col := col_map.get("default"):
        default_val = _parse_default(str(row.get(default_col, "")))

    access = ""
    if access_col := col_map.get("access"):
        access = _truncate(str(row.get(access_col, "")), 10)

    comment = ""
    if comment_col := col_map.get("comment"):
        comment = _truncate(str(row.get(comment_col, "")))

    return RegisterEntry(
        address=addr,
        name=name,
        default=default_val,
        access=access,
        comment=comment,
    )


def parse_register_entries(dfs: list[pd.DataFrame]) -> list[RegisterEntry]:
    """Parse register map DataFrames into RegisterEntry objects."""
    entries: list[RegisterEntry] = []
    seen_addrs: set[int] = set()

    for df in dfs:
        col_map = detect_register_columns(df)
        if col_map is None:
            continue
        for _, row in df.iterrows():
            entry = _parse_row(row, col_map)
            if entry is None or entry.address in seen_addrs:
                continue
            seen_addrs.add(entry.address)
            entries.append(entry)

    entries.sort(key=lambda e: e.address)
    return entries


# ---------------------------------------------------------------------------
# Markdown formatting
# ---------------------------------------------------------------------------
def format_md(content: str) -> str:
    """Format markdown through mdformat if available."""
    return mdformat.text(content, extensions={"tables"})


def _escape_pipe(s: str) -> str:
    return s.replace("|", "\\|")


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------
def _collect_sections(
    doc: DoclingDocument,
) -> tuple[list[str], dict[str, list[str]]]:
    """Walk doc items and group text/tables by major section header."""
    current_section = "general"
    section_content: dict[str, list[str]] = {}
    section_order: list[str] = []

    for item, _level in doc.iterate_items():
        if isinstance(item, (TitleItem, SectionHeaderItem)):
            text = item.text if hasattr(item, "text") else ""
            if _MAJOR_SECTION_RE.match(text):
                current_section = text.strip()
                if current_section not in section_content:
                    section_content[current_section] = []
                    section_order.append(current_section)

        elif isinstance(item, TextItem):
            text = getattr(item, "text", "")
            if current_section in section_content:
                section_content[current_section].append(text)

        elif isinstance(item, TableItem):
            try:
                md = item.export_to_markdown(doc=doc)
            except Exception:  # ruff: ignore[blind-except]
                log.debug("Skipping table that failed to export as Markdown")
                continue
            if current_section not in section_content:
                section_content[current_section] = []
                section_order.append(current_section)
            page = get_page(item)
            page_ref = f" (p. {page})" if page else ""
            section_content[current_section].append(f"\n{md}\n{page_ref}\n")

    return section_order, section_content


def write_register_tables(
    doc: DoclingDocument,
    out_dir: Path,
) -> None:
    """Write register tables grouped by major datasheet section."""
    reg_dir = out_dir / "registers"
    reg_dir.mkdir(parents=True, exist_ok=True)

    section_order, section_content = _collect_sections(doc)

    for idx, section_name in enumerate(section_order, start=1):
        parts = section_content[section_name]
        if not parts:
            continue
        slug = re.sub(r"[^a-z0-9]+", "_", section_name.lower()).strip("_")[:50]
        filename = f"{idx:02d}_{slug}.md"
        content = f"# {section_name}\n\n" + "\n\n".join(parts) + "\n"
        (reg_dir / filename).write_text(format_md(content), encoding="utf-8")

    console.log(f"  [dim]→[/] registers/  ({len(section_order)} sections)")


def write_functionality(doc: DoclingDocument, out_dir: Path) -> None:
    """Write functionality.md from text pages — headings, text, inline tables."""
    parts: list[str] = ["# Functionality\n"]

    for item, level in doc.iterate_items():
        if not isinstance(item, DocItem):
            continue
        page = get_page(item)
        page_ref = f" (p. {page})" if page else ""

        if isinstance(item, TitleItem):
            text = getattr(item, "text", "")
            parts.append(f"\n## {text}{page_ref}\n")

        elif isinstance(item, SectionHeaderItem):
            text = getattr(item, "text", "")
            depth = min(getattr(item, "level", level), 5) + 1
            hashes = "#" * depth
            parts.append(f"\n{hashes} {text}{page_ref}\n")

        elif isinstance(item, TextItem):
            text = getattr(item, "text", "")
            # Skip page-number-only lines
            if re.match(r"^\d{1,4}$", text.strip()):
                continue
            parts.append(f"{text}\n")

        elif isinstance(item, TableItem):
            try:
                md = item.export_to_markdown(doc=doc)
                parts.append(f"\n{md}\n")
            except Exception:  # ruff: ignore[blind-except]
                log.debug("Skipping table that failed to export as Markdown")

        elif isinstance(item, PictureItem):
            # Skip images
            continue

    content = "\n".join(parts) + "\n"
    (out_dir / "functionality.md").write_text(format_md(content), encoding="utf-8")
    console.log(f"  [dim]→[/] functionality.md ({len(parts)} items)")


def write_overview(
    name: str,
    entries: list[RegisterEntry],
    reg_confidence: ConfidenceInfo | None,
    text_confidence: ConfidenceInfo | None,
    out_dir: Path,
) -> None:
    """Write overview.md with register quick-ref, confidence summary, file index."""
    parts: list[str] = [f"# {name} — Overview\n"]

    # Device ID (WHO_AM_I register)
    who_am_i = next(
        (e for e in entries if "WHO_AM_I" in e.name or "DEVICE_ID" in e.name),
        None,
    )
    if who_am_i:
        parts.append(
            f"**Device ID:** `0x{who_am_i.default:02X}`"
            f" (register `0x{who_am_i.address:02X}` — {who_am_i.name})\n"
            if who_am_i.default is not None
            else f"**Device ID register:** `0x{who_am_i.address:02X}` — {who_am_i.name}\n"
        )

    # Register quick-reference table
    if entries:
        parts.extend((
            "\n## Register Quick Reference\n",
            "| Address | Name | Default | Access |",
            "| --- | --- | --- | --- |",
        ))
        for e in entries:
            addr = f"0x{e.address:02X}"
            default = f"0x{e.default:02X}" if e.default is not None else "—"
            parts.append(f"| {addr} | {e.name} | {default} | {e.access} |")
        parts.append("")

    # Confidence summary
    parts.extend((
        "\n## Extraction Confidence\n",
        "| Phase | Mean Score | Grade |",
        "| --- | --- | --- |",
    ))
    if reg_confidence:
        score = (
            f"{reg_confidence.mean_score:.2f}"
            if not math.isnan(reg_confidence.mean_score)
            else "N/A"
        )
        parts.append(f"| Registers | {score} | {reg_confidence.mean_grade} |")
    if text_confidence:
        score = (
            f"{text_confidence.mean_score:.2f}"
            if not math.isnan(text_confidence.mean_score)
            else "N/A"
        )
        parts.append(f"| Text | {score} | {text_confidence.mean_grade} |")
    if not reg_confidence and not text_confidence:
        parts.append("| (all pages) | — | — |")
    parts.extend(("", "\n## Output Files\n"))
    for p in sorted(out_dir.rglob("*")):
        if p.is_file() and p.name != "overview.md":
            rel = p.relative_to(out_dir)
            parts.append(f"- `{rel}`")
    parts.append("")

    content = "\n".join(parts) + "\n"
    (out_dir / "overview.md").write_text(format_md(content), encoding="utf-8")
    console.log(f"  [dim]→[/] overview.md ({len(entries)} registers)")


def generate_c_header(
    name: str,
    entries: list[RegisterEntry],
    out_dir: Path,
) -> None:
    """Generate a C header with register address defines."""
    inc_dir = out_dir / "include"
    inc_dir.mkdir(parents=True, exist_ok=True)

    prefix = re.sub(r"[^A-Z0-9]", "_", name.upper())
    guard = f"{prefix}_REGS_H"
    header_file = inc_dir / f"{name.lower()}_regs.h"

    lines: list[str] = [
        f"/* {name} register definitions — auto-generated by ds-extract */",
        f"#ifndef {guard}",
        f"#define {guard}",
        "",
    ]

    # Device ID
    who_am_i = next(
        (e for e in entries if "WHO_AM_I" in e.name or "DEVICE_ID" in e.name),
        None,
    )
    if who_am_i and who_am_i.default is not None:
        lines.extend((f"#define {prefix}_DEVICE_ID  0x{who_am_i.default:02X}u", ""))

    # Group by comment/section if available, otherwise flat
    current_section = ""
    max_name_len = max((len(f"{prefix}_{e.name}") for e in entries), default=0)

    for entry in entries:
        if entry.section and entry.section != current_section:
            current_section = entry.section
            lines.append(f"\n/* {current_section} */")

        define_name = f"{prefix}_{entry.name}"
        padding = " " * max(1, max_name_len - len(define_name) + 1)

        comment_parts: list[str] = []
        if entry.default is not None:
            comment_parts.append(f"default: 0x{entry.default:02X}")
        if entry.access:
            comment_parts.append(entry.access.lower())
        comment = f"  /* {', '.join(comment_parts)} */" if comment_parts else ""

        lines.append(f"#define {define_name}{padding}0x{entry.address:02X}u{comment}")

    lines.extend(["", f"#endif /* {guard} */", ""])

    header_file.write_text("\n".join(lines), encoding="utf-8")
    console.log(f"  [dim]→[/] include/{header_file.name} ({len(entries)} defines)")


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------
def process_pdf(  # ruff: ignore[too-many-arguments]
    converter: DocumentConverter,
    source: Path,
    out_dir: Path,
    *,
    registers_range: PageRange | None = None,
    text_range: PageRange | None = None,
    pipeline_opts: PdfPipelineOptions | None = None,
) -> int:
    """Run the full extraction pipeline for one PDF."""
    name = source.stem
    doc_out = out_dir / name
    doc_out.mkdir(parents=True, exist_ok=True)

    console.rule(f"[bold]{name}[/]")
    t0 = time.perf_counter()

    all_entries: list[RegisterEntry] = []
    reg_confidence: ConfidenceInfo | None = None
    text_confidence: ConfidenceInfo | None = None

    # --- Phase 1: Register extraction ---
    if reg_pages := registers_range:
        label = f"pages {reg_pages.start}-{reg_pages.end}"
        console.log(f"[bold]Phase 1 — Registers[/] ({label})")

        result = convert_pages(
            converter, source, reg_pages, pipeline_opts=pipeline_opts
        )
        if result:
            reg_confidence = log_confidence("Registers", result)
            doc = result.document

            register_dfs = find_register_map_tables(doc)
            console.log(f"  Found {len(register_dfs)} register map table(s)")

            all_entries = parse_register_entries(register_dfs)
            console.log(f"  Parsed {len(all_entries)} register entries")

            write_register_tables(doc, doc_out)

    # --- Phase 2: Text extraction ---
    if description_pages := text_range:
        label = (
            f"pages {description_pages.start}-{description_pages.end}"
            if description_pages
            else "all pages"
        )
        console.log(f"[bold]Phase 2 — Text[/] ({label})")

        result = convert_pages(
            converter, source, description_pages, pipeline_opts=pipeline_opts
        )
        if result:
            text_confidence = log_confidence("Text", result)
            write_functionality(result.document, doc_out)

    # --- Phase 3: Post-processing ---
    console.log("[bold]Phase 3 — Post-processing[/]")

    if all_entries:
        generate_c_header(name, all_entries, doc_out)

    # Write overview last so file index is complete
    write_overview(name, all_entries, reg_confidence, text_confidence, doc_out)

    elapsed = time.perf_counter() - t0
    console.log(
        f"[green bold]✓[/] {name} done in {elapsed:.1f}s — "
        f"{len(all_entries)} registers, "
        f"{sum(1 for _ in doc_out.rglob('*') if _.is_file())} files"
    )
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


app = cyclopts.App(
    help="Extract register maps & text from datasheets for driver generation.",
)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


class AtLeastOne:
    """At least 1 argument in the group must be supplied a value."""

    def __call__(self, argument_collection: cyclopts.ArgumentCollection) -> None:
        argument_collection = argument_collection.filter_by(value_set=True)
        n_arguments = len(argument_collection)

        if n_arguments > 0:
            return  # Happy path

        offenders = "{" + ", ".join(a.name for a in argument_collection) + "}"
        msg = f"At least one of these arguments: {offenders}"
        raise ValueError(msg)


page_ranges = cyclopts.Group(
    "Page ranges (one must be selected)",
    default_parameter=cyclopts.Parameter(negative=""),  # Disable "--no-" flags
    validator=AtLeastOne(),  # Mutually Exclusive Options
)


@app.default
def main(  # ruff: ignore[too-many-arguments]
    input_pdf: Path,
    *,
    text: Annotated[PageRange | None, cyclopts.Parameter(group=page_ranges)] = None,
    registers: Annotated[PageRange | None, cyclopts.Parameter(group=page_ranges)] = None,
    output: Annotated[
        Path | None,
        cyclopts.Parameter(
            ["-o", "--output"],
            help="output directory  [./out/<name>]",
        ),
    ] = None,
    ocr: Annotated[
        bool,
        cyclopts.Parameter(
            ["--ocr"],
            negative="",
            help="enable OCR",
        ),
    ] = False,
    verbose: Annotated[
        bool,
        cyclopts.Parameter(
            ["-v", "--verbose"],
            negative="",
            help="debug logging",
        ),
    ] = False,
) -> None:
    """
    Datasheet → driver-generation-ready extractor.

    Extracts register maps and functionality text from hardware datasheets (PDF)
    into organized Markdown, CSV, and C header files suitable for AI-assisted
    driver development.

    Output structure:
        out/<name>/
            overview.md            Device ID, register quick-ref, confidence summary
            functionality.md       Text descriptions with (p. N) refs
            registers/
                00_register_map.md Main address map table
                01_<section>.md    Tables grouped by datasheet section
            include/
                <name>_regs.h      #define PREFIX_REG_NAME 0xXXu


    Examples:
        ./ds-extract.py inputs/datasheet_sample/lsm6dsl.pdf --registers 48,107
        ./ds-extract.py inputs/datasheet_sample/lsm6dsl.pdf --registers 48,107 --text 15,47
        ./ds-extract.py inputs/datasheet_sample/lsm6dsl.pdf  # all pages

    """
    logging.basicConfig(
        level="DEBUG" if verbose else "INFO",
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(rich_tracebacks=True, tracebacks_show_locals=True)],
    )
    if not verbose:
        logging.getLogger("docling").setLevel(logging.WARNING)

    source = input_pdf.resolve()
    if not source.is_file() or source.suffix.lower() != ".pdf":
        console.print(f"[red]Not a PDF file: {source}[/]")
        raise SystemExit(1)

    out_dir = output or (Path.cwd() / "out")
    out_dir.mkdir(parents=True, exist_ok=True)
    use_cuda = True
    if os.environ.get("DS_EXTRACTOR_CPU_MODE"):
        use_cuda = False
        log.warning("Using CPU instead of CUDA")
    console.log(f"Input:   {source}")
    console.log(f"Output:  {out_dir / source.stem}")

    # Init pipeline
    t_init = time.perf_counter()
    opts = build_pipeline_options(
        fast=bool(os.environ.get("DS_EXTRACTOR_FAST_MODE")), ocr=ocr, cuda=use_cuda
    )
    converter = create_converter(opts)
    console.log(f"Pipeline ready in {time.perf_counter() - t_init:.1f}s")

    rc = process_pdf(
        converter,
        source,
        out_dir,
        registers_range=registers,
        text_range=text,
        pipeline_opts=opts,
    )
    if rc:
        raise SystemExit(rc)


if __name__ == "__main__":
    app()
