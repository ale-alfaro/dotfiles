
#import "@preview/touying:0.6.1": *
#import themes.simple: *

#set page(margin: (top: 1.0in, bottom: 1.0in, left: 1.0in, right: 1.0in))
#set text(font: "Noto Sans", size: 10.5pt)
#set heading(numbering: "1.")
// -----------------------------
// 0) MODE + STYLE
// -----------------------------


// Simple formatting helpers
#let pct(x) = str(calc.round(x * 100.0)) + "%"
#let usd(x) = "$" + str(calc.round(x))
#let pts(x) = str(calc.round(x * 10.0) / 10.0)

// -----------------------------
// 1) CONSTANTS (from your model.py)
// -----------------------------
#let READY_VALUE_PTS = 25.0
#let NOT_READY_VALUE_PTS = -25.0

#let OK_REL_INCREMENTAL_PENALTY_PTS = 0.0
#let BAD_REL_INCREMENTAL_PENALTY_PTS = -70.0

#let CUSTOMER_LONG_TERM_UPSIDE_PTS = 0.0

#let USD_PER_POINT = 10000.0

#let SALARY_FW_DEV_USD = 100000.0
#let SALARY_FW_CONTRACTOR_USD = 40000.0
#let SALARY_VV_USD = 70000.0

#let EXPECTED_NEW_SENSORS = 1.0

#let NEW_SENSOR_SAVED_FW_DEV_FTE_YR = 2.0
#let NEW_SENSOR_SAVED_FW_CONTRACTOR_FTE_YR = 1.0
#let NEW_SENSOR_SAVED_VV_FTE_YR = 0.0

// Labels (from your model.py)
#let STRATEGY_LABELS = (
  SAFE_ROLL: "SAFE: No clinical Zephyr this year",
  LKWARM_ROLL: "LUKEWARM: Clinical Zephyr on Dragonfly only",
  AGGR_ROLL: "AGGRESSIVE: Clinical Zephyr multi-platform",
)

#let RELEASE_LABELS = (
  NO_CLIN_ZEPHYR: "No clinical Zephyr release",
  OK_REL: "Clinical release goes OK",
  BAD_REL: "Clinical release goes BAD",
)

#let READINESS_LABELS = (
  READY: "Zephyr is ready long-term",
  NOT_READY: "Zephyr is NOT ready long-term",
)

// -----------------------------
// 2) STRATEGIES (from your model.py)
// -----------------------------
// Strategy objects are dictionaries in Typst.
#let STRATEGIES = (
  SAFE_ROLL: (
    kind: "no_release",
    delta_fw_dev: 0.0,
    delta_fw_contractor: 0.0,
    delta_vv: 0.0,
    p_ready: 0.70,
    p_ok: none,
    p_ready_given_ok: none,
    p_ready_given_bad: none,
  ),
  LKWARM_ROLL: (
    kind: "release",
    delta_fw_dev: 0.0,
    delta_fw_contractor: 1.0,
    delta_vv: 1.0,
    p_ready: none,
    p_ok: 0.50,
    p_ready_given_ok: 0.80,
    p_ready_given_bad: 0.20,
  ),
  AGGR_ROLL: (
    kind: "release",
    delta_fw_dev: 1.0,
    delta_fw_contractor: 1.0,
    delta_vv: 2.0,
    p_ready: none,
    p_ok: 0.30,
    p_ready_given_ok: 0.80,
    p_ready_given_bad: 0.10,
  ),
)

// -----------------------------
// 3) MODEL FUNCTIONS
// -----------------------------
#let new_sensor_savings_usd_per_sensor() = (
  NEW_SENSOR_SAVED_FW_DEV_FTE_YR * SALARY_FW_DEV_USD
    + NEW_SENSOR_SAVED_FW_CONTRACTOR_FTE_YR * SALARY_FW_CONTRACTOR_USD
    + NEW_SENSOR_SAVED_VV_FTE_YR * SALARY_VV_USD
)

#let readiness_internal_savings_points() = (
  (EXPECTED_NEW_SENSORS * new_sensor_savings_usd_per_sensor()) / USD_PER_POINT
)

#let incremental_planned_cost_usd(s) = (
  s.delta_fw_dev * SALARY_FW_DEV_USD
    + s.delta_fw_contractor * SALARY_FW_CONTRACTOR_USD
    + s.delta_vv * SALARY_VV_USD
)

#let incremental_planned_cost_pts(s) = {
  -(incremental_planned_cost_usd(s) / USD_PER_POINT)
}

#let release_penalty_pts(rel) = (
  if rel == "OK_REL" { OK_REL_INCREMENTAL_PENALTY_PTS } else if rel
    == "BAD_REL" { BAD_REL_INCREMENTAL_PENALTY_PTS } else { 0.0 }
)

#let readiness_value_pts(rd) = (
  if rd == "READY" {
    (
      READY_VALUE_PTS
        + CUSTOMER_LONG_TERM_UPSIDE_PTS
        + readiness_internal_savings_points()
    )
  } else {
    NOT_READY_VALUE_PTS
  }
)

#let terminal_payoff_pts(s, rel, rd) = (
  incremental_planned_cost_pts(s)
    + release_penalty_pts(rel)
    + readiness_value_pts(rd)
)

// outcome rows (without contribution):
// each row = (release_state, readiness_state, joint_prob, payoff_pts)
#let outcome_rows4(name, s) = if s.kind == "no_release" {
  let pr = s.p_ready
  (
    (
      "NO_CLIN_ZEPHYR",
      "READY",
      pr,
      terminal_payoff_pts(s, "NO_CLIN_ZEPHYR", "READY"),
    ),
    (
      "NO_CLIN_ZEPHYR",
      "NOT_READY",
      1.0 - pr,
      terminal_payoff_pts(s, "NO_CLIN_ZEPHYR", "NOT_READY"),
    ),
  )
} else {
  let p_ok = s.p_ok
  let p_bad = 1.0 - p_ok

  let pr_ok = s.p_ready_given_ok
  let pr_bad = s.p_ready_given_bad

  (
    (
      "OK_REL",
      "READY",
      p_ok * pr_ok,
      terminal_payoff_pts(s, "OK_REL", "READY"),
    ),
    (
      "OK_REL",
      "NOT_READY",
      p_ok * (1.0 - pr_ok),
      terminal_payoff_pts(s, "OK_REL", "NOT_READY"),
    ),
    (
      "BAD_REL",
      "READY",
      p_bad * pr_bad,
      terminal_payoff_pts(s, "BAD_REL", "READY"),
    ),
    (
      "BAD_REL",
      "NOT_READY",
      p_bad * (1.0 - pr_bad),
      terminal_payoff_pts(s, "BAD_REL", "NOT_READY"),
    ),
  )
}

// add contribution:
// each row = (release_state, readiness_state, joint_prob, payoff_pts, contribution)
#let outcome_rows5(name, s) = outcome_rows4(name, s).map(r => (
  r.at(0),
  r.at(1),
  r.at(2),
  r.at(3),
  r.at(2) * r.at(3),
))

#let ev_for(name, s) = outcome_rows5(name, s).map(r => r.at(4)).sum()

#let strategy_summaries() = {
  let items = ()
  for (name, s) in STRATEGIES.pairs() {
    items.push((
      name,
      STRATEGY_LABELS.at(name, default: name),
      ev_for(name, s),
      incremental_planned_cost_usd(s),
      incremental_planned_cost_pts(s),
      s.kind,
      s.p_ok,
      s.p_ready,
      s.p_ready_given_ok,
      s.p_ready_given_bad,
    ))
  }
  // sort by EV desc
  items.sorted(key: it => -it.at(2))
}

// A small utility to get max(abs(x)) without relying on newer helpers.
#let max_abs(values) = {
  let m = 0.0
  for v in values {
    let a = calc.abs(v)
    if a > m { m = a }
  }
  m
}

// -----------------------------
// 4) RENDERING HELPERS
// -----------------------------

#let assumptions = (
  header: ([*Item*], [*Value*], [*Meaning*]),
  content: (
    (
      [READY value (pts)],
      [#READY_VALUE_PTS],
      [Internal/platform value if Zephyr becomes reusable],
    ),
    (
      [NOT READY value (pts)],
      [#NOT_READY_VALUE_PTS],
      [Internal/platform downside if Zephyr is not ready],
    ),
    (
      [BAD release penalty (pts)],
      [#BAD_REL_INCREMENTAL_PENALTY_PTS],
      [Short-term customer + org pain if clinical release goes badly],
    ),
    (
      [OK release penalty (pts)],
      [#OK_REL_INCREMENTAL_PENALTY_PTS],
      [Baseline incremental penalty if release goes OK],
    ),
    (
      [USD per point],
      [#USD_PER_POINT],
      [Conversion between dollars and utility points],
    ),
    (
      [Expected new sensors],
      [#EXPECTED_NEW_SENSORS],
      [Assumed new sensors in horizon],
    ),
    (
      [Savings per new sensor (USD)],
      [#new_sensor_savings_usd_per_sensor()],
      [Dev/contractor cost avoided if READY],
    ),
    (
      [Internal READY bonus (pts)],
      [#readiness_internal_savings_points()],
      [Added to READY payoff only],
    ),
    (
      [Customer long-term upside (pts)],
      [#CUSTOMER_LONG_TERM_UPSIDE_PTS],
      [Unknown/speculative; kept at 0],
    ),
  ),
)

#let assumptions_cells() = {
  let cells = ()
  for row in assumptions.content {
    for cell in row { cells.push(cell) }
  }
  cells
}

// -----------------------------
// 5) TABLE RENDERING (standalone)
// -----------------------------
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

#let assumptions_table() = nice_table(
  columns: (1.4fr, 0.7fr, 2.2fr),
  align: (left, right, left),
  ..assumptions.header,
  ..assumptions_cells(),
)

#let ev_summary_table(order: none) = {
  let rows = if order == none {
    strategy_summaries()
  } else {
    order.map(name => {
      let s = STRATEGIES.at(name)
      (
        name,
        STRATEGY_LABELS.at(name, default: name),
        ev_for(name, s),
      )
    })
  }
  let pts(x) = str(calc.round(x * 10.0) / 10.0)
  nice_table(
    columns: (2.2fr, 0.8fr),
    align: (left, right),
    [*Strategy*],
    [*Expected Value (pts)*],
    ..rows
      .map(it => (
        [#it.at(1)],
        [
          #if it.at(2) > 0 {
            text(fill: green.darken(25%), weight: "bold")[#pts(it.at(2))]
          } else if it.at(2) < 0 {
            text(fill: red.darken(10%), weight: "bold")[#pts(it.at(2))]
          } else {
            text(weight: "bold")[#pts(it.at(2))]
          }
        ],
      ))
      .flatten(),
  )
}

// // Simple diverging EV bars (Typst-native)
#let ev_bar_chart(label_w: 78mm, bar_w: 80mm, value_w: 18mm, bar_h: 6mm) = {
  let rows = strategy_summaries()
  let evs = rows.map(it => it.at(2))
  let maxv = if max_abs(evs) == 0.0 { 1.0 } else { max_abs(evs) }
  let pts(x) = str(calc.round(x * 10.0) / 10.0)

  stack(
    spacing: 2mm,
    ..rows.map(it => {
      let label = it.at(1)
      let ev = it.at(2)
      let half = bar_w / 2
      let barw = (calc.abs(ev) / maxv) * half

      let neg_bar = if ev < 0 {
        rect(width: barw, height: bar_h, fill: red.lighten(10%))
      } else { rect(width: 0pt, height: bar_h) }
      let pos_bar = if ev > 0 {
        rect(width: barw, height: bar_h, fill: green.lighten(10%))
      } else { rect(width: 0pt, height: bar_h) }
      let axis = rect(width: 0.8pt, height: bar_h, fill: gray.darken(20%))

      grid(
        columns: (label_w, bar_w, value_w),
        column-gutter: 3mm,
        align: (left, center, right),
        [#label],
        [
          #grid(
            columns: (1fr, auto, 1fr),
            column-gutter: 0pt,
            align: (right, center, left),
            [#neg_bar], [#axis], [#pos_bar],
          )
        ],
        [#text(weight: "bold")[#pts(ev)]],
      )
    }),
  )
}

