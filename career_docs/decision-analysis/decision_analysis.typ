#import "@preview/polylux:0.4.0": *
#import "@preview/helios-polylux:0.1.0": *
#import "ev_model.typ" as ev_model

#show: setup.with(
  text-font: "Fira Sans",
  math-font: "Fira Sans",
  code-font: "Fira Sans",
)

#set text(font: "Fira Sans")
#set document(
  title: "Zephyr Rollout Decision Analysis",
  author: "Sibel",
)

#let divider() = line(length: 100%, stroke: 0.6pt + rgb("d6d6d6"))

#let breakdown_table(best) = {
  let name_of_best = best.at(0)
  let s = ev_model.STRATEGIES.at(name_of_best)
  let rows = ev_model.outcome_rows5(name_of_best, s)
  let ev = ev_model.ev_for(name_of_best, s)
  let pts(x) = str(calc.round(x * 10.0) / 10.0)

  block[
    #ev_model.nice_table(
      columns: (1fr, 1fr, auto, auto, auto),
      align: (left, left, right, right, right),
      [*Release outcome*],
      [*Long-term outcome*],
      [*Prob*],
      [*Payoff (pts)*],
      [*EV contribution*],
      ..rows
        .map(r => (
          [#ev_model.RELEASE_LABELS.at(r.at(0))],
          [#ev_model.READINESS_LABELS.at(r.at(1))],
          [#r.at(2)],
          [#r.at(3)],
          [#r.at(4)],
        ))
        .flatten(),
    )

    #v(6pt)
    #text(weight: "bold")[Total EV: #pts(ev) points]
  ]
}

#slide[
  #set page(header: none, footer: none)
  #show: pad.with(top: 10%, left: 6%, bottom: 10%, right: 6%)

  #text(size: 1.7em, weight: "bold")[
    Zephyr Rollout Decision Analysis
  ]
  #text(size: 1.0em, weight: "medium")[
    Timing, scope, and product coverage for this year’s clinical releases
  ]

  #v(4fr)
  #text(size: 0.75em)[
    Clinical Solution 2.0 · Limb Sensor Rev K · Aria Scratch Sensor
  ]
]

#slide[
  = Decision Overview
  #divider()

  The decision concerns the *timing, scope, and product coverage* of Zephyr
  firmware adoption during this year's *clinical* releases. The Aria Maruho
  release is intentionally left out of the clinical product line decision
  because it follows a different regulatory strategy and already runs Zephyr,
  but the firmware differs significantly from the clinical target. Aria still
  provides an opportunity to test the clinical Zephyr firmware and can
  influence the decision below.

  == Key Releases Impacted
  - *Clinical Solution 2.0* — new feature set; scope/timeline TBD (Nov release).
  - *Limb Sensor Rev K (stretch goal)* — new HW revision with MFG/verification/regulatory work.
  - *Aria Scratch Sensor (target)* — Q3 2026; Zephyr FW feature‑complete, needs refinement.

  Additional minor releases are planned for clinical as well as other products.
]

#slide[
  = Value & Risk Summary
  #divider()

  *Value Added by Zephyr*
  - Platform consolidation, reuse, and tooling gains.
  - Forward‑looking alignment with vendor roadmap.
  - Potential improvements in development speed and quality.

  *Key Uncertainties*
  - Regulatory verification may still be per‑platform.
  - Legacy devices may prevent full harmonization.
  - Multi‑core SoCs increase complexity and instability risk.

  *Notable Risks*
  - Schedule compression (testing/MFG integration excluded).
  - Migration/OTA constraints with dual‑stack maintenance.
  - Team and ecosystem maturity risk.
]

#slide[
  = Influence Diagram
  #divider()

  #align(center)[
    #image(
      "res/influence_diagram.pdf",
      width: 90%,
      height: 70%,
      fit: "contain",
      format: "pdf",
    )
  ]
]

#slide[
  = Decision Nodes
  #divider()

  #ev_model.nice_table(
    columns: (1.2fr, 1.2fr, 3fr),
    [*Code*], [*Strategy*], [*Description*],
    [*SAFE_ROLL*],
    [Conservative Rollout],
    [No clinical Zephyr rollout this year (clinical release remains on legacy FW). Aria decision is separate.],

    [*LKWARM_ROLL*],
    [Lukewarm Rollout],
    [Clinical Zephyr rollout on new sensor HW only (Dragonfly).],

    [*AGGR_ROLL*],
    [Aggressive Rollout],
    [Clinical Zephyr rollout on current clinical line plus new HW (Chest RevK + Limb RevJ/K + Dragonfly as applicable).],
  )
]

#slide[
  = Uncertainty Model (Short‑Term & Readiness)
  #divider()

  #grid(columns: (1fr, 1fr), gutter: 1.2em)[
    #ev_model.nice_table(
      columns: (1.2fr, 0.7fr, 0.7fr),
      [*Strategy*], [*OK_REL*], [*BAD_REL*],
      [SAFE_ROLL], [1.0], [0.0],
      [LKWARM_ROLL], [0.5], [0.5],
      [AGGR_ROLL], [0.3], [0.7],
    )
  ][
    #ev_model.nice_table(
      columns: (2.2fr, 0.7fr, 0.7fr),
      [*Condition*], [*READY*], [*NOT_READY*],
      [SAFE_ROLL (no clinical Zephyr)], [0.7], [0.3],
      [LKWARM_ROLL + REL_OK], [0.8], [0.2],
      [LKWARM_ROLL + REL_BAD], [0.2], [0.8],
      [AGGR_ROLL + REL_OK], [0.8], [0.2],
      [AGGR_ROLL + REL_BAD], [0.1], [0.9],
    )
  ]
]

#slide[
  = Payoff Model (Summary)
  #divider()

  Payoff = Strategy planned cost + (release support cost if BAD_REL) + (long‑term readiness value)

  #ev_model.nice_table(
    columns: (1.2fr, 1fr, 2.6fr),
    [*Strategy*], [*Planned Cost*], [*Rationale*],
    [SAFE_ROLL], [-5], [Minimal Zephyr clinical work; preserves capacity for long‑term and maintenance.],
    [LKWARM_ROLL], [-15], [Limited Zephyr clinical scope (Dragonfly only).],
    [AGGR_ROLL], [-25], [Broad clinical Zephyr scope (largest verification and integration effort).],
  )
]

#slide[
  = Expected Value Analysis
  #divider()

  #ev_model.ev_summary_table(
    order: ("AGGR_ROLL", "LKWARM_ROLL", "SAFE_ROLL"),
  )

  #v(6pt)
  #ev_model.ev_bar_chart()
]

#slide[
  = Decision Tree
  #divider()

  #align(center)[
    #image(
      "res/decision_tree.pdf",
      width: 90%,
      height: 70%,
      fit: "contain",
      format: "pdf",
    )
  ]
]

#slide[
  = Outcome Breakdown (Best Strategy)
  #divider()

  #breakdown_table(ev_model.strategy_summaries().at(0))
]
