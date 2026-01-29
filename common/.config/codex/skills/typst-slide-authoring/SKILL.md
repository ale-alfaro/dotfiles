---
name: typst-slide-authoring
description: Creates and refines Typst slide decks using Polylux/Helios, including consistent table styles, diagram embedding, and export workflows. Use when building or editing Typst presentations, especially when integrating Mermaid diagrams or EV model tables.
---

# Typst Slide Authoring

## Scope

Use this skill to build or refactor Typst slide decks with Polylux/Helios, standardize tables and diagrams, and keep decks concise and readable.

## Quick start

1. Use Polylux + Helios theme setup.
2. Define a single table style helper and reuse it everywhere.
3. Keep slides <= 10 when asked to condense.
4. Export Mermaid diagrams to PDF and embed with `#image(..., format: "pdf", fit: "contain")`.

## Slide deck baseline

```typst
#import "@preview/polylux:0.4.0": *
#import "@preview/helios-polylux:0.1.0": *

#show: setup.with(
  text-font: "Fira Sans",
  math-font: "Fira Sans",
  code-font: "Fira Sans",
)

#set text(font: "Fira Sans")
#set document(title: "...", author: "...")

#slide[= Title]
```

## Table style helper

```typst
#let nice_table(
  columns: (),
  align: (),
  ..cells,
) = table(
  columns: columns,
  align: align,
  inset: (x: 6pt, y: 4pt),
  column-gutter: 8pt,
  row-gutter: 2pt,
  stroke: 0.6pt + rgb("cfcfcf"),
  fill: (x, y) => {
    if y == 0 { rgb("f2f2f2") } else if calc.rem(y, 2) == 0 {
      rgb("fbfbfb")
    } else { none }
  },
  ..cells
)
```

## Diagram embedding (PDF)

```typst
#align(center)[
  #image(
    "res/diagram.pdf",
    width: 90%,
    height: 70%,
    fit: "contain",
    format: "pdf",
  )
]
```

## Mermaid CLI export (PDF, stdin)

**Always** export as PDF and include `--pdfFit`.

```bash
cat <<'EOF' | mmdc --input - -o res/influence_diagram.pdf --pdfFit -t neutral -b transparent -w 1400 -H 900 -s 2
<PASTE MERMAID CODE HERE>
EOF
```

## Layout & slide density

- Prefer 6–10 slides for executive review.
- Merge related sections and remove redundant tables when condensing.
- Keep one main visual per slide when possible.

## References

- For syntax, examples, and commands used in this project, see:
  - [references/typst-notes.md](references/typst-notes.md)
