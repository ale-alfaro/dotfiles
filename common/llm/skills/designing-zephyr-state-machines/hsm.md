# Hierarchical state machines

Needs `CONFIG_SMF_ANCESTOR_SUPPORT=y`. Hierarchy exists to remove duplication:
an event handled once in a parent applies to every child that does not handle it
itself.

```c
static const struct smf_state states[] = {
    [ROOT] = SMF_CREATE_STATE(root_entry, root_run, root_exit, NULL,           NULL),
    [S1]   = SMF_CREATE_STATE(s1_entry,   s1_run,   s1_exit,   &states[ROOT],  NULL),
    [S1A]  = SMF_CREATE_STATE(s1a_entry,  s1a_run,  s1a_exit,  &states[S1],    NULL),
    [S1B]  = SMF_CREATE_STATE(s1b_entry,  s1b_run,  s1b_exit,  &states[S1],    NULL),
    [S2]   = SMF_CREATE_STATE(s2_entry,   s2_run,   s2_exit,   &states[ROOT],  NULL),
};
```

## Action ordering

- **Entry**: outermost first — parent entry runs *before* child entry.
- **Run**: innermost first — child run runs, then parents outward.
- **Exit**: innermost first — child exit runs *before* parent exit.

## Which actions a transition runs

A transition runs exit actions from the source **up to but excluding** the lowest
common ancestor (LCA), then entry actions from below the LCA **down to** the
target. The LCA's own exit and entry never run — that is the whole point of
grouping states under it.

Using the table above:

| Transition | Actions run |
| --- | --- |
| initial → `S1` | `root_entry`, `s1_entry` |
| `S1` → `S1A` (into a child) | `s1a_entry` |
| `S1A` → `S1B` (sibling) | `s1a_exit`, `s1b_entry` |
| `S1B` → `S2` (other branch) | `s1b_exit`, `s1_exit`, `s2_entry` |

A transition to the state you are already in is a **self-transition**: its exit
*and* entry both run.

## Propagation

`smf_run_state()` runs the current state's run action, then walks up the parent
chain running each ancestor's run action. The walk stops as soon as a run action
either returns `SMF_EVENT_HANDLED` or calls `smf_set_state()`. Returning
`SMF_EVENT_PROPAGATE` from every level means the event reaches `root`.

## `executing` vs `current` — the HSM trap

`ctx->current` is the leaf state; `ctx->executing` is the state whose run action
is on the stack right now, which during propagation is an **ancestor**, not the
leaf. `smf_set_state()` computes the LCA from `executing`, so the same call means
different things depending on which level made it: a transition issued from a
parent's run action exits only from that parent downward as if the parent were
the source.

Read them with `smf_get_current_leaf_state()` and
`smf_get_current_executing_state()` rather than touching the struct.

## Initial transitions

With `CONFIG_SMF_INITIAL_TRANSITION=y`, the 5th `SMF_CREATE_STATE()` argument
names a parent's default child. Both `smf_set_initial()` and `smf_set_state()`
then follow the `initial` chain down to a leaf, so targeting a parent lands you
in a real leaf state. Without it, targeting a parent leaves the machine sitting
*on* the parent — which is what `smf_get_current_leaf_state()` returning a parent
means.

## Same event, different transitions

Reusing one event across states is normal and often the whole design: which
transition fires is decided by the state that handles it, not by the event id.
Do not mint an event per arrow.
