# zbus reference — API, Kconfig, citations (Zephyr 4.4.0)

Source paths are relative to the Zephyr checkout
(`external/zephyr/` in this workspace). Line numbers are from Zephyr **4.4.0** and
may drift across versions — re-check against the tree if in doubt.

- Implementation: `subsys/zbus/zbus.c`
- Runtime observers: `subsys/zbus/zbus_runtime_observers.c`
- Public API: `include/zephyr/zbus/zbus.h`
- Kconfig: `subsys/zbus/Kconfig`
- Docs: `doc/services/zbus/index.rst`
- Sample: `samples/subsys/zbus/hello_world/src/main.c`

## VDED / execution context (the crux)

`doc/services/zbus/index.rst` (~L147-160): *"The VDED execution always happens in
the publisher's context. It can be a thread or an ISR. The channel lock is
acquired; the channel receives the new message via direct copy (raw memcpy); the
event dispatcher executes the listeners, sends a copy of the message to the
message subscribers, and pushes the channel's reference to the subscribers'
notification message queue, in the same sequence they appear on the channel
observers' list. The listeners can perform non-copy quick access to the constant
message reference (via `zbus_chan_const_msg`) since the channel is still locked."*

`zbus_chan_pub()` body (`zbus.c` ~L455-493):

```c
err = chan_lock(chan, timeout, &context_priority);  // take chan->data->sem (+ HLP boost)
memcpy(chan->message, msg, chan->message_size);      // copy user msg into channel
err = _zbus_vded_exec(chan, end_time);               // dispatch ALL observers, under lock
chan_unlock(chan, context_priority);                 // give sem (+ restore priority)
```

`_zbus_vded_exec` dispatch per observer type (`zbus.c` ~L185-227):

```c
case ZBUS_OBSERVER_LISTENER_TYPE:      obs->callback(chan);                       // sync, here
case ZBUS_OBSERVER_SUBSCRIBER_TYPE:    k_msgq_put(obs->queue, &chan, ...);        // ref only
case ZBUS_OBSERVER_MSG_SUBSCRIBER_TYPE: net_buf_clone(buf,...); k_fifo_put(...);  // msg copy
case ZBUS_OBSERVER_ASYNC_LISTENER_TYPE: net_buf_clone(...); k_work_submit_to_queue(...);
```

ISR guard (`zbus.c` ~L461): inside an ISR the timeout **must** be `K_NO_WAIT`.

Channel lock is a `struct k_sem` (`zbus.h` ~L44-47). HLP priority boost in
`chan_lock` (`zbus.c` ~L401-439): raises the caller to
`highest_observer_priority - 1` while publishing; **runtime observers are not
counted** (`index.rst` ~L315-317).

## API signatures (`include/zephyr/zbus/zbus.h`)

```c
/* Publish / notify */
int zbus_chan_pub(const struct zbus_channel *chan, const void *msg, k_timeout_t timeout);
int zbus_chan_notify(const struct zbus_channel *chan, k_timeout_t timeout);   // run VDED w/o new msg

/* Read (from a subscriber thread; locks-copies-unlocks) */
int zbus_chan_read(const struct zbus_channel *chan, void *msg, k_timeout_t timeout);

/* Manual lock window */
int zbus_chan_claim(const struct zbus_channel *chan, k_timeout_t timeout);
int zbus_chan_finish(const struct zbus_channel *chan);   // only action allowed while claimed

/* Message access — ONLY valid while the channel is locked (listener or claim window) */
void       *zbus_chan_msg(const struct zbus_channel *chan);        // mutable
const void *zbus_chan_const_msg(const struct zbus_channel *chan);  // const, for listeners
uint16_t    zbus_chan_msg_size(const struct zbus_channel *chan);
void       *zbus_chan_user_data(const struct zbus_channel *chan);

/* Subscriber waits (block in the observer's own thread) */
int zbus_sub_wait(const struct zbus_observer *sub, const struct zbus_channel **chan, k_timeout_t timeout);
int zbus_sub_wait_msg(const struct zbus_observer *sub, const struct zbus_channel **chan,
                      void *msg, k_timeout_t timeout);   // message subscriber only

/* Observer enable / per-channel mute */
int zbus_obs_set_enable(const struct zbus_observer *obs, bool enabled);
int zbus_obs_is_enabled(const struct zbus_observer *obs, bool *enable);
int zbus_obs_set_chan_notification_mask(const struct zbus_observer *obs,
                                        const struct zbus_channel *chan, bool masked);
int zbus_obs_is_chan_notification_masked(const struct zbus_observer *obs,
                                         const struct zbus_channel *chan, bool *masked);

/* Runtime observers (CONFIG_ZBUS_RUNTIME_OBSERVERS) */
int zbus_chan_add_obs(const struct zbus_channel *chan, const struct zbus_observer *obs, k_timeout_t timeout);
int zbus_chan_rm_obs (const struct zbus_channel *chan, const struct zbus_observer *obs, k_timeout_t timeout);

/* HLP: attach an observer's priority to the calling thread */
int zbus_obs_attach_to_thread(const struct zbus_observer *obs);
int zbus_obs_detach_from_thread(const struct zbus_observer *obs);

/* Lookup / iteration */
const struct zbus_channel *zbus_chan_from_name(const char *name);   // CONFIG_ZBUS_CHANNEL_NAME
const struct zbus_channel *zbus_chan_from_id(uint32_t id);          // CONFIG_ZBUS_CHANNEL_ID
bool zbus_iterate_over_channels(bool (*fn)(const struct zbus_channel *));
bool zbus_iterate_over_observers(bool (*fn)(const struct zbus_observer *));
```

Common return codes: `0` ok, `-EBUSY`/`-EAGAIN` (lock/timeout), `-ENOMSG`
(invalid / validator rejected), `-ENOMEM` (net_buf pool exhausted, msg
subscribers), `-EFAULT` (bad params when `CONFIG_ZBUS_ASSERT_MOCK`), `-ENODATA`
(runtime obs not found), `-EEXIST`/`-EALREADY` (already an observer).

## Definition macros

```c
ZBUS_CHAN_DEFINE(name, type, validator_fn, user_data, observers, initial_val);
ZBUS_CHAN_DECLARE(chan1, chan2, ...);           // in a consumer TU

ZBUS_LISTENER_DEFINE(name, cb [, enable]);      // cb: void(*)(const struct zbus_channel *)
ZBUS_SUBSCRIBER_DEFINE(name, queue_size [, enable]);       // k_msgq of channel refs
ZBUS_MSG_SUBSCRIBER_DEFINE(name [, enable]);               // needs CONFIG_ZBUS_MSG_SUBSCRIBER
ZBUS_ASYNC_LISTENER_DEFINE(name, cb [, enable]);           // needs CONFIG_ZBUS_ASYNC_LISTENER

ZBUS_CHAN_ADD_OBS(chan, obs, prio);             // static observation; prio orders dispatch
```

`ZBUS_CHAN_ADD_OBS`'s `prio` sets the observation's sequence within the channel's
observer list (lower value = earlier). Observers are stored in iterable linker
sections.

## Kconfig (`subsys/zbus/Kconfig`)

| Option | Default | Purpose |
| --- | --- | --- |
| `CONFIG_ZBUS` | — | Enable the subsystem |
| `CONFIG_ZBUS_CHANNELS_SYS_INIT_PRIORITY` | 5 | SYS_INIT priority for channel/observation init |
| `CONFIG_ZBUS_CHANNEL_NAME` | n | Store channel names (logging / `zbus_chan_from_name`) |
| `CONFIG_ZBUS_CHANNEL_ID` | n | Numeric channel IDs (`zbus_chan_from_id`) |
| `CONFIG_ZBUS_OBSERVER_NAME` | n | Store observer names |
| `CONFIG_ZBUS_CHANNEL_PUBLISH_STATS` | n | Track per-channel publish count / timestamp |
| `CONFIG_ZBUS_MSG_SUBSCRIBER` | n | Enable message-subscriber observers (net_buf copies) |
| `CONFIG_ZBUS_MSG_SUBSCRIBER_BUF_ALLOC_DYNAMIC` / `_STATIC` | dyn if `PREFER_DYNAMIC` | net_buf pool from heap vs fixed |
| `CONFIG_ZBUS_MSG_SUBSCRIBER_NET_BUF_POOL_SIZE` | 16 | net_bufs available simultaneously |
| `CONFIG_ZBUS_MSG_SUBSCRIBER_NET_BUF_STATIC_DATA_SIZE` | — | per-net_buf size (static alloc) |
| `CONFIG_ZBUS_MSG_SUBSCRIBER_NET_BUF_POOL_ISOLATION` | n | per-channel pools vs one global pool |
| `CONFIG_ZBUS_ASYNC_LISTENER` | n | Enable async-listener observers (system workqueue) |
| `CONFIG_ZBUS_ASYNC_LISTENER_EXEC_TIMEOUT` | 200ms | FIFO get timeout for async listener |
| `CONFIG_ZBUS_RUNTIME_OBSERVERS` | n | Enable `zbus_chan_add_obs` / `rm_obs` |
| `CONFIG_ZBUS_RUNTIME_OBSERVERS_NODE_ALLOC_*` | dyn/static/none | Where runtime obs nodes come from |
| `CONFIG_ZBUS_RUNTIME_OBSERVERS_NODE_POOL_SIZE` | 8 | node pool size (static alloc) |
| `CONFIG_ZBUS_PRIORITY_BOOST` | **y** | HLP publisher priority boost (bounds inversion) |
| `CONFIG_ZBUS_ASSERT_MOCK` | n | Return `-EFAULT` instead of asserting (unit tests) |
| `CONFIG_ZBUS_PREFER_DYNAMIC_ALLOCATION` | y | Default heap for msg-sub / runtime-obs pools |
| `CONFIG_HEAP_MEM_POOL_ADD_SIZE_ZBUS` | derived | Heap reserved for zbus |

## Gotcha citations (`doc/services/zbus/index.rst`)

- Not a byte-stream transport → use Pipe: ~L383-386.
- Listeners quick as ISRs, offload heavy work: ~L396-399.
- Subscriber loss on double-publish: ~L413-417.
- `zbus_chan_read` timeout after `zbus_sub_wait` (K_NO_WAIT risky w/ >1 sub): ~L604-610.
- net_buf pool sizing for msg subscribers / async listeners: ~L402-411.
- Priority boost ignores runtime observers: ~L315-317.
- claim → edit `zbus_chan_msg` → finish → explicit `zbus_chan_notify`: ~L864-873.
- VDED copies internally, stack messages are fine: ~L577.
- **net_buf per publish when MSG_SUBSCRIBER/ASYNC_LISTENER is on:** `_zbus_vded_exec`
  calls `_zbus_create_net_buf(pool, zbus_chan_msg_size(chan), …)` unconditionally
  under `#if defined(CONFIG_ZBUS_MSG_SUBSCRIBER)` (`zbus.c` ~L244-258), before the
  observer loop, then `net_buf_unref` at the end. So enabling either thread-based
  observer makes *every* publish on *every* channel allocate a net_buf sized to
  that channel's message; a message larger than the net_buf pool/heap asserts
  ("net_buf zbus_msg_subscribers_pool is unavailable or heap is full").
  `ZBUS_ASYNC_LISTENER` `select`s `ZBUS_MSG_SUBSCRIBER` (`subsys/zbus/Kconfig` ~L70).
