---
name: designing-zephyr-state-machines
description: Use when designing, writing, or reviewing a Zephyr SMF state machine — SMF_CREATE_STATE state tables, smf_set_initial / smf_run_state / smf_set_state / smf_set_terminate, flat FSM vs hierarchical HSM, deciding what deserves to be a state, splitting or nesting machines, or the zbus events and delayed work that drive smf_run_state. Also for debugging a transition that ran the wrong entry/exit actions, an event that propagated (or failed to propagate) to a parent state, or a fault on transition. Grounded in the SMF source in this tree.
metadata:
  type: reference
---

# Designing Zephyr SMF state machines

SMF (`CONFIG_SMF`, `<zephyr/smf.h>`) gives you states with **entry / run / exit**
actions, a **state table**, and transitions. It gives you **no event system and no
thread** — those are yours to build, and most design mistakes live there rather
than in the SMF calls.

## Diagram before code

Write the state diagram, show it to the user, and get their agreement **before**
writing any state table or action. A diagram is minutes of work and exposes the
mistakes that are expensive in C: a state with no way out, an event handled at
two levels of the hierarchy, an orthogonal concern that should have been its own
machine.

Use mermaid `stateDiagram-v2`, with every transition labelled by the event that
causes it:

```mermaid
stateDiagram-v2
    [*] --> idle
    state root {
        idle --> measuring: EVT_START
        measuring --> idle: EVT_STOP
        measuring --> idle: EVT_TIMEOUT
    }
    root --> error: EVT_FAULT
    error --> [*]: manual reset
```

Hand it over as a ```` ```mermaid ```` block inside a markdown doc — the user
renders it in Obsidian. Do not render it to an image. Keep that doc next to the
`.c` file it describes and update the block when states change; the diagram is
the artefact the user reviews, so it stays live, not a one-off.

## Check the API version first

This tree's SMF is **0.2.0**, which broke the API found in most blog posts and
older code:

- A run action returns `enum smf_state_result` — **`SMF_EVENT_HANDLED`** (stop
  propagation) or **`SMF_EVENT_PROPAGATE`** (let ancestors run). Entry and exit
  still return `void`.
- **`smf_set_handled()` no longer exists.** Return `SMF_EVENT_HANDLED` instead.

`rg 'smf_state_result' $ZEPHYR_BASE/include/zephyr/smf.h` decides it in one
command. If that enum is absent you are on the old API (`void` run actions +
`smf_set_handled()`) — everything else in this skill still holds.

## Skeleton

```c
#include <zephyr/smf.h>

typedef struct {
    struct smf_ctx ctx;   /* MUST be first — SMF casts the object to this */
    uint32_t event;       /* your data: the only way to get values into actions */
} my_sm_t;

typedef enum { S1, S2 } my_state_t;

static void s1_entry(void *data) { ... }

static enum smf_state_result s1_run(void *data)
{
    my_sm_t *sm = data;   /* the void * is your object, ctx being its first member */

    if (sm->event == EVT_GO) {
        smf_set_state(SMF_CTX(sm), &states[S2]);
        return SMF_EVENT_HANDLED;   /* transition already happened — do no more work */
    }
    return SMF_EVENT_PROPAGATE;
}

static const struct smf_state states[] = {
    [S1] = SMF_CREATE_STATE(s1_entry, s1_run, s1_exit, NULL, NULL),
    [S2] = SMF_CREATE_STATE(s2_entry, s2_run, s2_exit, NULL, NULL),
};

smf_set_initial(SMF_CTX(&sm), &states[S1]);
while (smf_run_state(SMF_CTX(&sm)) == 0) { /* pump events */ }
```

Rules that this skeleton encodes:

- **`struct smf_ctx` first, always.** `SMF_CTX(o)` is a raw cast.
- **Transitions are immediate, not queued.** By the time `smf_set_state()`
  returns, the exit and entry actions have already run. Return right after it so
  no stale-state logic executes.
- **Every enum value needs a state-table row.** An enumerator you forgot to
  populate transitions into a table of NULL function pointers and faults.
- **`smf_run_state()` returns non-zero only after `smf_set_terminate(ctx, val)`**
  — that value is the return. A plain run action returning `SMF_EVENT_HANDLED`
  does not stop the machine.
- **Never call `smf_set_state()` from an exit action** — SMF logs an error and
  ignores it; you are already mid-transition.

Kconfig: `CONFIG_SMF=y`, plus `CONFIG_SMF_ANCESTOR_SUPPORT=y` for parent states
and `CONFIG_SMF_INITIAL_TRANSITION=y` for a parent that auto-descends into a
default child. Both default `n`. `CONFIG_SMF_INSTRUMENTATION=y` adds
`smf_set_hooks()` — transition / action / error callbacks, which is the cheapest
way to assert transition sequences in a `native_sim` test.

Hierarchy semantics — parent ordering, which exit/entry actions a transition
runs, initial transitions, and `executing` vs `current` — are in
[`hsm.md`](hsm.md). Read it before writing any state with a non-NULL parent or
debugging a transition that ran the wrong actions.

## Design rules

### A state must be able to sit still

A state represents a condition the device is in for a non-zero amount of time,
with a run action that waits for an event. An "entry action then immediately
transition away" state is a function call wearing a costume — write the function.

### Comment blocks over diagrams

State diagrams rot. Put a banner above each state's actions naming the state in
path form and what it does:

```c
/* ==================================================================== */
/* root/mode_1/idle: waiting for a start event.                         */
/* ==================================================================== */
```

### A root state for what applies everywhere

Give the machine a `root` parent when some event must be handled from any state
(errors, shutdown). Watch the re-entry trap: with `ERROR` handled at `root`, an
`ERROR` arriving while already in the error state re-enters it. Handle `ERROR` in
the error state and return `SMF_EVENT_HANDLED` to stop propagation.

### Split orthogonal concerns into separate machines

Two independent things in one machine multiplies states: two lights modelled as
one machine needs `LIGHT_2_ON`/`OFF` under *both* `LIGHT_1_ON` and `LIGHT_1_OFF`.
One machine per concern, coordinated by events, stays additive.

### Nest to hide implementation details

A parent machine can own, initialize, and forward events to a child machine that
callers never see. This is how you keep a machine small without leaking its
internals — the split above's counterpart for concerns that genuinely are
sub-steps rather than peers.

## Driving the machine

`smf_run_state()` runs exactly one iteration; something must call it. Polling it
on a `k_msleep()` trades responsiveness against burnt CPU — drive it from events
instead. In this workspace that means a **zbus message subscriber**: the machine
owns a thread that blocks on its event channel, copies the message into the
machine object, and runs one iteration.

```c
ZBUS_MSG_SUBSCRIBER_DEFINE(foo_sm_sub);

while (true) {
    const struct zbus_channel *chan;

    zbus_sub_wait_msg(&foo_sm_sub, &chan, &sm.event, K_FOREVER);
    smf_run_state(SMF_CTX(&sm));   /* sm.event is the only channel into the actions */
}
```

A message subscriber — not a plain subscriber — because a state machine must see
**every** event in order; a plain subscriber silently collapses two publishes
into the latest value. Delays are `k_work_delayable` on a workqueue, publishing a
timeout event; reach for `k_timer` only when something must happen in ISR context.

Observer choice, thread layout, and the delayed-work cancellation race are in
[`event-loop.md`](event-loop.md). For zbus itself — channel definition, observer
semantics, which context a callback runs in — use the `zephyr-zbus` skill.
