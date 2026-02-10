# Typst notes for this project

## Key syntax and features we used

- **Imports**
  - `#import "@preview/polylux:0.4.0": *`
  - `#import "@preview/helios-polylux:0.1.0": *`
  - `#import "ev_model.typ" as ev_model`
- **Macros and helpers**
  - `#let name(args) = ...` defines reusable helpers.
  - `#let divider() = line(...)` used for consistent section separators.
- **Theme setup (Polylux/Helios)**
  - `#show: setup.with(text-font: "Fira Sans", math-font: "Fira Sans", code-font: "Fira Sans")`
- **Document metadata**
  - `#set document(title: "...", author: "...")`
- **Slides (Polylux)**
  - `#slide[ ... ]` for each slide.
  - Slide title with `= Title`.
- **Section divider helper**
  - `#let divider() = line(length: 100%, stroke: 0.6pt + rgb("d6d6d6"))`
- **Tables (custom style)**
  - `#let nice_table(...)= table(...)` wrapper with consistent gutters, fill, stroke.
  - Usage: `#ev_model.nice_table(...)` with rows and column specs.
- **Reusable helpers (from ev_model.typ)**
  - `#ev_model.ev_summary_table(order: (...))`
  - `#ev_model.ev_bar_chart()`
  - `#ev_model.assumptions_table()`
- **Grids and layout**
  - `#grid(columns: (...), gutter: ...)` for side‑by‑side content.
  - `#align(center)[ ... ]` for centering figures and tables.
- **Figures and images**
  - `#image("res/influence_diagram.pdf", width: 90%, height: 70%, fit: "contain", format: "pdf")`
  - `#align(center)[ ... ]` to center diagrams.
- **Typography / inline emphasis**
  - `*italic*`, `**bold**`
- **Spacing**
  - `#v(6pt)` for vertical spacing.
- **Math & code**
  - `#set text(font: "...")` sets text font globally.
  - Polylux uses `code-font` for monospace snippets (set to Fira Sans here).

## How to learn more

- Typst docs: https://typst.app/docs/
- Image function reference: https://typst.app/docs/reference/visualize/image/
- Polylux (slides): https://typst.app/universe/package/polylux/
- Helios Polylux theme: https://typst.app/universe/package/helios-polylux/
- Typst table reference: https://typst.app/docs/reference/model/table/
- Typst layout reference: https://typst.app/docs/reference/layout/

## Templates referenced

- `template/helios-polylux/presentation.typ`
  - Used as the base for the slide deck structure and theme setup.

## Commands used in this project

- Compile slide deck:
  - `typst c decision_analysis.typ`
- Compile EV model helpers (optional sanity check):
  - `typst c ev_model.typ`

## Mermaid CLI (diagram export)

**Important:** Export diagrams as **PDF** (not SVG) and include `--pdfFit` so they embed cleanly in Typst.\n

Example (stdin input):\n

```bash
cat <<'EOF' | mmdc --input - -o res/influence_diagram.pdf --pdfFit -t neutral -b transparent -w 1400 -H 900 -s 2
<PASTE MERMAID CODE HERE>
EOF
```

Repeat for the decision tree:

```bash
cat <<'EOF' | mmdc --input - -o res/decision_tree.pdf --pdfFit -t neutral -b transparent -w 1400 -H 900 -s 2
<PASTE MERMAID CODE HERE>
EOF
```

## Future improvements / fixes

- **Consolidate data sources**
  - Keep all EV math and table helpers in `ev_model.typ`, and only render in the slide deck.
- **Diagram export quality**
  - Prefer PDF output from Mermaid (`--pdfFit`) to avoid SVG font/foreignObject issues.
  - Consider a small script to re‑render both diagrams reliably.
- **Font availability**
  - If Fira Mono or Fira Math are installed, re‑enable them for code/math styling.
- **Slide density**
  - If content grows, split large tables across two slides for legibility.
- **Accessibility**
  - Add `alt:` descriptions for figures if exporting to formats that use them.
- **Consistent layout spacing**
  - Standardize `#v(...)` spacing around tables and diagrams to keep visual rhythm.
