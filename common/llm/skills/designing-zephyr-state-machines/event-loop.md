# Events, threading, and delays

SMF ships no event system. In this workspace that gap is filled by **zbus**, not
by a hand-rolled `k_msgq`. See the `zephyr-zbus` skill for zbus itself; this file
is only the state-machine side of the wiring.

## Feed the machine with a message subscriber

`CONFIG_ZBUS_MSG_SUBSCRIBER=y`. The machine owns a thread that blocks on
`zbus_sub_wait_msg()` and runs one iteration per message.

```c
ZBUS_MSG_SUBSCRIBER_DEFINE(foo_sm_sub);
ZBUS_CHAN_ADD_OBS(foo_evt_chan, foo_sm_sub, 3);

static void foo_sm_thread(void *a, void *b, void *c)
{
    const struct zbus_channel *chan;

    smf_set_initial(SMF_CTX(&sm), &states[IDLE]);

    while (zbus_sub_wait_msg(&foo_sm_sub, &chan, &sm.event, K_FOREVER) == 0) {
        if (smf_run_state(SMF_CTX(&sm)) != 0) {
            break;
        }
    }
}
```

Why a **message** subscriber specifically:

- A plain `ZBUS_SUBSCRIBER` hands you a channel *reference*. Two publishes before
  you read means you see the latest value twice — a state machine that misses an
  `EVT_STOP` because an `EVT_START` overwrote it is silently wrong.
- A `ZBUS_LISTENER` runs **in the publisher's context under the channel lock**,
  so the whole state machine — every entry, run, and exit action — would execute
  inside whoever called `zbus_chan_pub()`, including an ISR. Never run
  `smf_run_state()` from a listener.

Actions take only the object pointer, so `zbus_sub_wait_msg()` copies into
`sm.event` (or a wider payload struct) before the iteration: that field is the
machine's entire input.

Actions publish with `zbus_chan_pub()` to talk to other machines. That publish
runs the receiving machines' listeners synchronously in *your* thread — with
message subscribers on both ends, it just queues, which is why this shape
composes.

## Thread layout

One thread per machine is the default here: each blocks on its own message
subscriber, and zbus already decoupled them, so there is nothing left to share.

Machines that must observe the same channel just both subscribe to it — this is
where zbus beats a single dispatch loop, which had to fan an event out by hand
and ran every machine at one priority. Keep a shared thread only for machines
that are genuinely one concern split for readability (a nested machine driven by
its parent, for instance).

Slow work still does not belong in an action. Offload it to a workqueue and let
it publish a completion event; an action that blocks stalls every event queued
behind it.

## Delays: `k_work_delayable`, not `k_timer`

Timeouts, retries, and blink rates are `k_work_delayable` items whose handler
publishes an event:

```c
static void timeout_work_handler(struct k_work *work)
{
    struct foo_evt evt = { .id = EVT_TIMEOUT, .token = atomic_get(&timeout_token) };

    zbus_chan_pub(&foo_evt_chan, &evt, K_MSEC(10));
}
static K_WORK_DELAYABLE_DEFINE(timeout_work, timeout_work_handler);

/* in an entry action */
k_work_reschedule(&timeout_work, K_SECONDS(5));
```

`k_timer` expiry runs in the **system clock ISR**, where it cannot block and
cannot publish with a timeout. A delayed work handler runs in a workqueue thread:
it may block, it may log, and it can be cancelled synchronously. Reserve
`k_timer` for the rare deadline that genuinely must be serviced in ISR context.

`k_work_reschedule()` rather than `k_work_schedule()` when re-arming — the latter
leaves an already-pending deadline alone, which silently ignores your new one.

### The cancellation race survives the switch

Cancelling a delay does not unpublish a timeout event already in flight. Between
the handler publishing and your thread dequeuing, a state transition can make
that event stale.

- `k_work_cancel_delayable_sync()` waits for a running handler to finish, so
  after it returns no *new* event will be published — but one already on the
  channel is still coming.
- So make stale timeouts identifiable: bump a token when you arm the delay, stamp
  it into the event, and drop a `EVT_TIMEOUT` whose token does not match. The
  state machine then cannot act on a timeout it already cancelled.

Never call `k_work_cancel_delayable_sync()` from inside the workqueue thread that
runs the handler — it deadlocks. Cancel from the state machine's thread.
