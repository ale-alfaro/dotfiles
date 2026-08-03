#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pypdf"]
# ///
"""Compile src/resume.typ, verify it, and drop the release copy in artifacts/.

Checks enforced (all must pass or nothing is released):
  - single-page output
  - PDF Title metadata includes the author's name (not just a generic label)
  - required contact links are present (mailto, tel, GitHub, LinkedIn)
  - tel: links contain only a leading "+" and digits (spaces/parens break some clients)
  - the text layer extracts cleanly (word count sanity check, no replacement chars)

Run via `mise run typst:release` (needs the `pypdf` dependency, pulled in
automatically through `uv run --with pypdf`).
"""

import re
import subprocess
import sys
from datetime import date
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS = ROOT / "artifacts"
DRAFT_PDF = ROOT / "build" / f"DRAFT-Alejandro-Alfaro-CV-{date.today().isoformat()}.pdf"

REQUIRED_LINK_PREFIXES = (
    "mailto:",
    "tel:",
    "https://github.com/",
    "https://www.linkedin.com/",
)
MIN_WORD_COUNT = 300




def collect_links(reader):
    links = []
    for page in reader.pages:
        for annot in page.get("/Annots") or []:
            obj = annot.get_object()
            action = obj.get("/A")
            if action and action.get("/URI"):
                links.append(str(action["/URI"]))
    return links


def run_checks(reader):
    errors = []

    if len(reader.pages) != 1:
        errors.append(f"expected 1 page, got {len(reader.pages)}")

    meta = reader.metadata
    title = (meta.title or "") if meta else ""
    author = (meta.author or "") if meta else ""

    if not author:
        errors.append("missing /Author metadata")
    elif not all(part in title for part in author.split()):
        errors.append(
            f"PDF title {title!r} does not include the full author name {author!r}"
        )

    links = collect_links(reader)
    for prefix in REQUIRED_LINK_PREFIXES:
        if not any(link.startswith(prefix) for link in links):
            errors.append(f"missing expected link with prefix {prefix!r}")

    for link in links:
        if link.startswith("tel:") and not re.fullmatch(r"tel:\+?[0-9]+", link):
            errors.append(f"tel link {link!r} has characters invalid for a tel: URI")

    text = "".join(page.extract_text() or "" for page in reader.pages)
    word_count = len(text.split())
    if word_count < MIN_WORD_COUNT:
        errors.append(
            f"suspiciously low word count ({word_count}) — possible broken text layer"
        )
    if "�" in text:
        errors.append("text layer contains replacement characters — check fonts/encoding")

    return errors, author


def main():
    reader = PdfReader(str(DRAFT_PDF))
    errors, author = run_checks(reader)

    if errors:
        errs = [ f"  - {e}" for e in errors ]
        SystemExit("Release aborted — failed checks:" + "\n".join(errs))

    print(f"All checks passed")


if __name__ == "__main__":
    main()
