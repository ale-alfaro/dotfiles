---
name: zephyr-zbus
description: Use when working with Zephyr's zbus message bus — defining channels or observers, choosing between listener / subscriber / message-subscriber / async-listener, reasoning about execution context (which thread a callback runs in), locking, message copy vs reference, or message loss, and deciding whether zbus even fits a data path (vs k_pipe / k_msgq). Triggers include ZBUS_CHAN_DEFINE, ZBUS_LISTENER_DEFINE, ZBUS_SUBSCRIBER_DEFINE, ZBUS_MSG_SUBSCRIBER_DEFINE, ZBUS_CHAN_ADD_OBS, zbus_chan_pub/read/claim/notify, or debugging a pub/sub deadlock, priority inversion, or dropped message. Grounded in Zephyr 4.4.0 source.
metadata:
  type: reference
---

# Zephyr zbus (message bus) reference

zbus is a **publish/subscribe message bus** over typed **channels**. Threads (or
ISRs) publish a message to a channel; the channel's **observers** are notified.
The dispatcher that runs on every publish is the **VDED** (Virtual Distributed
Event Dispatcher).

The single most important — and most misremembered — fact:

> **The VDED runs in the *publisher's* context, and listener callbacks execute
> synchronously there, with the channel's semaphore held for the whole dispatch.**

"Who runs the callback?" is decided by **who called `zbus_chan_pub()`**, never by
which module owns the data. Get this wrong and you will design a blocking
operation into a path that must not block.

## When to use this skill

- Defining a channel or wiring an observer.
- Choosing an observer type (the table below is the whole decision).
- Reasoning about *which thread* a callback runs in, or a lock/priority issue.
- Deciding whether zbus is the right transport at all for a data path.
- Debugging: a publish that deadlocks, a dropped/duplicated message, a priority
  inversion, or a `-EBUSY`/`-EAGAIN`/`-ENOMEM` from a zbus call.

## Mental model

- **Channel** = a typed message buffer + an ordered observer list + an access
  **semaphore**. `ZBUS_CHAN_DEFINE(name, type, validator, user_data, observers,
  init)`.
- **Observer** = a listener / subscriber / message-subscriber / async-listener.
- **Publish** (`zbus_chan_pub`): lock the channel → **`memcpy` the message into
  the channel** → run the VDED (notify every observer in order) → unlock.
- Because the message is copied in, **publishing a stack-allocated message is
  fine** — zbus owns its copy after `pub` returns.

## Observer decision guide

This table *is* the design decision. Pick by "which thread must run it?" and "can
it block?" and "can I afford to miss a message?".

| Observer | Runs in | Gets | Loss model | May block? | Config |
| --- | --- | --- | --- | --- | --- |
| **Listener** | **publisher's context, under the channel lock** | const *reference* to the channel message (`zbus_chan_const_msg`) | never misses (synchronous) | **NO — treat it like an ISR** | always on |
| **Async listener** | system workqueue thread | a *copy* (net_buf) | guaranteed delivery | yes | `CONFIG_ZBUS_ASYNC_LISTENER` |
| **Subscriber** | its own thread (wakes on a `k_msgq` of channel *refs*) | a channel *reference*; you then `zbus_chan_read` | **may lose data**: two pubs before you read → you see only the latest, but get two notifications | yes | always on |
| **Message subscriber** | its own thread (wakes on a `k_fifo` of net_bufs) | a *copy* of each message (`zbus_sub_wait_msg`) | guaranteed: every message queued | yes | `CONFIG_ZBUS_MSG_SUBSCRIBER` |

Rule of thumb (from the Zephyr docs): *"Use subscribers for scenarios that can
tolerate message losses and duplications; when they cannot, use message
subscribers (if you need a thread) or listeners (if you need to be lean and
fast)."*

> **The thread-based observers tax the whole bus.** Enabling *message
> subscribers* or *async listeners* selects `CONFIG_ZBUS_MSG_SUBSCRIBER`, and then
> **every `zbus_chan_pub()` on every channel** clones the message into a net_buf —
> `_zbus_vded_exec` allocates it unconditionally, at the top of the dispatch,
> before it even looks at the observer list (`subsys/zbus/zbus.c`). Consequences:
> (1) one async listener anywhere imposes a per-publish heap/pool alloc on *all*
> channels, including hot paths; (2) the biggest message on *any* channel must fit
> the net_buf pool/heap (`CONFIG_ZBUS_MSG_SUBSCRIBER_NET_BUF_*` /
> `CONFIG_HEAP_MEM_POOL_ADD_SIZE_ZBUS`, default 2 KB) or the publish **asserts and
> panics** — e.g. publishing a 2 KB page blows the default heap. If you only need
> to run work off the publisher's context, a plain listener that submits a
> `k_work` is far lighter: no net_buf, no `MSG_SUBSCRIBER`, same "not in the
> publisher's context" result.

## Hard rules (violating these causes deadlocks / inversions / drops)

1. **A listener must not block.** It runs under the channel semaphore in the
   publisher's thread. No `k_sleep`, no waiting `k_msgq_put`/`k_sem_take`, no slow
   I/O. Docs: *"Keep the listeners as quick as possible (deal with them as ISRs).
   If time-consuming processing is required, offload … to a work queue using async
   listeners."*
2. **A listener must not `zbus_chan_pub()` (or claim) the same channel** — the
   semaphore is already held → deadlock.
3. **`zbus_chan_const_msg()` / `zbus_chan_msg()` are only valid while the channel
   is locked** — i.e. inside a listener, or between `zbus_chan_claim()` and
   `zbus_chan_finish()`. From a subscriber thread use **`zbus_chan_read()`**
   (it locks, copies, unlocks).
4. **After `zbus_sub_wait()` the channel is NOT locked.** Choose the `zbus_chan_read`
   timeout with care: `K_NO_WAIT` is likely to return a timeout error if there is
   more than one subscriber (the channel is unavailable during VDED). Prefer a
   real timeout.
5. **`claim`/`finish` blocks the channel for everything but `finish`.** To mutate
   in place: `claim` → edit via `zbus_chan_msg()` → `finish` → **explicit
   `zbus_chan_notify()`** (claim/finish alone do NOT run the VDED).
6. **Publishing from an ISR requires `K_NO_WAIT`**, and the VDED (all listeners)
   then runs in ISR context — so those listeners must be ISR-safe and instant.
7. **Priority boost (HLP)** is on by default (`CONFIG_ZBUS_PRIORITY_BOOST`): during
   pub the publisher is temporarily raised to just below the highest-priority
   observer to bound inversion. It **ignores runtime observers** in that
   calculation — a reason to prefer static observers for priority-sensitive paths.

## When NOT to use zbus

- **High-rate byte streams between threads.** Docs, verbatim: *"based on the zbus
  benchmark, it would not be well suited to a high-speed stream of bytes between
  threads. The **Pipe** kernel object solves this kind of need."* Reach for
  `k_pipe` (byte stream), `k_msgq` (fixed-size items), or a ring buffer instead.
- **Heavy per-message work in a listener.** Offload to a workqueue, or make the
  observer an async-listener / (message-)subscriber that runs in its own thread.
- **Large message payloads copied on every pub.** `pub` memcpys the whole message.
  If it's large, pass it **by reference** (next section) or don't use zbus.

## Pass-by-reference pattern (zero-copy through a synchronous listener)

Because a listener runs synchronously during `pub` and can read the message, you
can embed a **pointer to an external buffer** inside the (small) message struct;
the listener touches that buffer *during the publish call*. This is how this
workspace's SHRD logger ingests frames — `struct shrd_frame_batch_msg` carries a
`struct sys_ringq *` and the logger's listener drains it before `pub` returns
(`modules/lib/shrd/lib/zbus/messages.h`, `lib/shrd/shrd_logger.c:frames_listener_cb`).

Constraints that make it safe:
- The pointed-to buffer must stay valid for the duration of the publish (trivially
  true: the listener runs before `pub` returns).
- The listener **still must not block** — so this works for a bounded `memcpy`/
  drain, **not** for slow/blocking I/O (e.g. a NAND page read). If the work can
  block, it does not belong in a listener — use a direct call from the consumer's
  own thread, or a thread-based observer.

## This workspace's conventions

Worked example: `modules/lib/shrd/lib/zbus/`.

- **Split the interface**: message *types* in `messages.h` (pure data, no
  channel/kernel deps), channel *definitions* in `channels.c` (`ZBUS_CHAN_DEFINE`,
  one owner each). A consumer `#include`s `messages.h` and `ZBUS_CHAN_DECLARE`s
  only the channels it uses.
- **Static observers only** — `ZBUS_LISTENER_DEFINE` + `ZBUS_CHAN_ADD_OBS(chan,
  obs, prio)`; **no `CONFIG_ZBUS_RUNTIME_OBSERVERS`**.
- **Channel roles** mirror the observer semantics: a *level* channel (e.g.
  `chan_shrd_logger_state`) is read-with-delay/loss-tolerant; an *event* channel
  (e.g. `chan_shrd_logger_error`) is published **only** when something happened
  (notify-only); an *ingress* channel (e.g. `chan_shrd_frames`) uses the
  synchronous-listener + pass-by-reference pattern above.

## Full API, Kconfig, and source citations

See `reference.md` in this skill directory — signatures for every `zbus_*` call,
the complete Kconfig table, and file:line pointers into the Zephyr 4.4.0 tree
(`external/zephyr/subsys/zbus/`, `include/zephyr/zbus/zbus.h`,
`doc/services/zbus/index.rst`).
