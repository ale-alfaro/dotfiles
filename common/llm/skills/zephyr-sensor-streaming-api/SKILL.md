---
name: zephyr-sensor-streaming-api
description: Use when implementing or modifying a Zephyr sensor driver to support the async/RTIO sensor API (`sensor_read`, `sensor_read_async_mempool`, `sensor_stream`). Triggers include adding FIFO/watermark streaming to an existing fetch-and-get driver, wiring a new driver's `submit` and `get_decoder`, writing a `*_decoder.c`, or designing the encoded buffer layout the consumer's mempool will hold.
metadata:
  type: reference
---

# Zephyr Sensor Streaming API (driver author reference)

## Overview

Zephyr's async sensor API is a thin layer on **RTIO**. The driver author's job is to plug two function pointers into `struct sensor_driver_api`:

- `submit` — accepts an `rtio_iodev_sqe` and eventually completes it with data in a caller-supplied or mempool buffer.
- `get_decoder` — returns a `sensor_decoder_api` that turns those raw bytes into q31 fixed-point readings.

The framework (`drivers/sensor/default_rtio_sensor.c`) supplies the `rtio_iodev_api` (`__sensor_iodev_api`) that the `SENSOR_DT_*_IODEV` macros bind to, plus a fallback decoder. You do **not** implement an `rtio_iodev_api` yourself.

The high-level shape (consumer ↔ driver):

```
sensor_stream() / sensor_read_async_mempool()
  → rtio_submit → __sensor_iodev_api.submit
  → sensor_iodev_submit (framework)
  → YOUR api->submit(dev, iodev_sqe)
       ├── one-shot: fill buffer, rtio_iodev_sqe_ok()
       └── streaming: stash sqe, arm IRQ, return.
           IRQ fires → chained rtio_sqe's (bus I/O via I2C_RTIO/SPI_RTIO)
                    → final callback writes header+payload into mempool buffer
                    → rtio_iodev_sqe_ok(stashed_sqe, n)
```

## When to use

- Adding streaming/FIFO to a fetch-and-get sensor driver.
- Writing a new sensor driver that should support `sensor_stream` or `sensor_read*`.
- Writing a sensor decoder (`*_decoder.c`).
- Designing the on-the-wire (encoded) buffer format.

When **not** to use: pure consumer code (apps calling `sensor_read`/`sensor_stream`) — see `doc/hardware/peripherals/sensor/read_and_decode.rst` in the Zephyr tree.

## File layout (canonical, per driver)

```
drivers/sensor/<vendor>/<chip>/
  <chip>.c              # init + legacy attr/trigger/fetch/get API + driver_api with submit/get_decoder
  <chip>.h              # data/config structs; rtio ctx; stashed sqe; timestamp; FIFO state
  <chip>_rtio.c         # api->submit dispatcher; one-shot path
  <chip>_stream.c       # streaming submit + chained RTIO callbacks + ISR handler  (gated CONFIG_<CHIP>_STREAM)
  <chip>_decoder.[ch]   # SENSOR_DECODER_API_DT_DEFINE() + wire-format header structs
  <chip>_trigger.c      # GPIO callback; on IRQ, calls <chip>_stream_irq_handler()
```

Canonical examples to copy from: `drivers/sensor/adi/adxl345/` (small, clean) and `drivers/sensor/bosch/bma4xx/` (larger, more features).

## Modernizing a fetch-and-get driver

The legacy API (`sample_fetch` + `channel_get`) and the async API (`submit` + `get_decoder`) live on the **same `struct sensor_driver_api`**. They coexist — adding the new API does not break existing consumers. Migrate incrementally:

1. **Add a decoder skeleton.** Create `<chip>_decoder.c` with `SENSOR_DECODER_API_DT_DEFINE()` and a `<chip>_get_decoder` function. The encoded buffer struct can be small at first — just enough fields to round-trip one channel. Decoder callbacks may return `-ENOTSUP` for unimplemented channels.

2. **Add the one-shot `submit`** (file: `<chip>_rtio.c`). Use `rtio_work_req_alloc` + `rtio_work_req_submit` to offload to the work queue — this reuses your existing blocking bus code as-is. **No need to convert the bus driver to RTIO yet.** Wire `.submit` and `.get_decoder` into `sensor_driver_api`. Add `select RTIO_WORKQ if SENSOR_ASYNC_API` and gate the new sources on `CONFIG_SENSOR_ASYNC_API` in CMake.

3. **Verify** with `sensor_read_async_mempool` from a sample app. Both legacy and async paths now work. Many drivers stop here if they don't need FIFO streaming.

4. **Add streaming** (file: `<chip>_stream.c`, `<chip>_trigger.c`). This step **does** require an RTIO-native bus (`I2C_RTIO` or `SPI_RTIO`) because the IRQ-driven callback chain runs sqe's through the bus iodev. Gate with `CONFIG_<CHIP>_STREAM` (a Kconfig that `depends on (I2C_RTIO || SPI_RTIO)`). Add the `is_fifo`-discriminated streaming buffer variant to the wire format and extend the decoder to dispatch on it.

5. **Migrate consumers, then retire the legacy API.** Once all in-tree users have moved to `sensor_read`/`sensor_stream`, you can delete `sample_fetch`, `channel_get`, and `trigger_set` from the driver. Don't rush this — the legacy API costs almost nothing to keep, and out-of-tree users may still depend on it.

The reordering rule: **decoder before submit, one-shot before streaming, legacy stays until consumers move.**

## The `submit` contract

```c
void mychip_submit(const struct device *dev, struct rtio_iodev_sqe *iodev_sqe)
{
    const struct sensor_read_config *cfg = iodev_sqe->sqe.iodev->data;

    if (!cfg->is_streaming) {
        /* one-shot: cfg->channels[], cfg->count */
        ...
    } else if (IS_ENABLED(CONFIG_<CHIP>_STREAM)) {
        /* streaming: cfg->triggers[], cfg->count */
        mychip_submit_stream(dev, iodev_sqe);
    } else {
        rtio_iodev_sqe_err(iodev_sqe, -ENOTSUP);
    }
}
```

**Iron rule:** _Every path through `submit` must eventually call `rtio_iodev_sqe_ok()` or `rtio_iodev_sqe_err()` on the SQE._ A returned-but-uncompleted SQE leaks RTIO pool entries and hangs the consumer.

### One-shot, bus is not RTIO-native

Offload to the work queue:

```c
struct rtio_work_req *req = rtio_work_req_alloc();   /* never NULL if pool sized right */
rtio_work_req_submit(req, iodev_sqe, mychip_fetch_blocking);
/* mychip_fetch_blocking() runs in workqueue context, ends with rtio_iodev_sqe_ok/_err */
```

Requires `select RTIO_WORKQ`.

### Streaming

1. Walk `cfg->triggers[i]` — accept only triggers your chip supports (`SENSOR_TRIG_FIFO_WATERMARK`, `SENSOR_TRIG_FIFO_FULL`, etc.); `-ENOTSUP` the rest.
2. If trigger config changed from current state, reprogram FIFO/INT registers (blocking I2C/SPI is fine here — submit runs in thread context).
3. **Stash the sqe** in driver data (`data->streaming_sqe = iodev_sqe`).
4. Arm the GPIO IRQ.
5. **Return without completing** the SQE — completion happens in the chained-callback chain that the IRQ kicks off.

`sensor_stream()` uses a multishot SQE under the hood, so the framework re-issues the same logical request after each completion. The RTIO executor serializes this: your driver will never have two concurrent stashed sqe's at once. After `rtio_iodev_sqe_ok()`, clear `data->streaming_sqe = NULL` and re-arm the GPIO IRQ; the next submit will arrive in the normal way and set the slot again.

**Coexistence with a legacy DRDY `trigger_set` callback** sharing the same INT GPIO: take exclusive ownership of the IRQ while `data->streaming_sqe != NULL`. The classic GPIO callback should branch: if streaming is active, route to `<chip>_stream_irq_handler`; else invoke the user's `sensor_trigger_handler_t`. Some drivers force legacy and streaming to be mutually exclusive at config time — simpler and less error-prone.

## ISR path — no bus I/O in ISR

The GPIO callback **must not** do blocking bus reads. The pattern:

```c
void mychip_stream_irq_handler(const struct device *dev)
{
    /* 1. Timestamp HERE — earliest sane moment. */
    uint64_t cycles;
    sensor_clock_get_cycles(&cycles);
    data->timestamp = sensor_clock_cycles_to_ns(cycles);

    /* 2. Chain RTIO sqe's that the bus driver (I2C_RTIO/SPI_RTIO) will service:
     *    tiny_write(STATUS_REG) → read(int_status) → callback(process_status_cb)
     * Each step uses RTIO_SQE_TRANSACTION/CHAINED and (for I2C) RTIO_IODEV_I2C_STOP|RESTART. */
    ...
    rtio_submit(data->rtio_ctx, 0);
}
```

Subsequent callbacks read FIFO length, allocate the consumer buffer with `rtio_sqe_rx_buf(sqe, min, ideal, &buf, &len)`, burst-read FIFO data into `buf + sizeof(header)`, then `rtio_iodev_sqe_ok()`.

### `rtio_sqe_rx_buf` semantics

```c
rtio_sqe_rx_buf(iodev_sqe, min_size, ideal_size, &buf, &buf_len);
```

- `min_size` = smallest acceptable buffer (you'll truncate the payload to fit). Pick `sizeof(header)` so a header-only buffer is always acceptable.
- `ideal_size` = `sizeof(header) + fifo_bytes` — what you'd take if available.
- Returns `-ENOMEM` if even `min_size` can't be allocated. Treat as a fatal error: `rtio_iodev_sqe_err(sqe, -ENOMEM)`.
- On success, `buf_len` is **the actual allocation** (between `min` and `ideal`). The driver must compute `fifo_byte_count = min(buf_len - sizeof(header), fifo_bytes_available)`.

### Canonical I2C-RTIO register-read pattern

The pattern most stream drivers use to read a register then burst-read N bytes (one bus transaction, two sqe's):

```c
struct rtio_sqe *write = rtio_sqe_acquire(ctx);
struct rtio_sqe *read  = rtio_sqe_acquire(ctx);
struct rtio_sqe *cb    = rtio_sqe_acquire(ctx);

uint8_t reg = REG_FIFO_DATA;
rtio_sqe_prep_tiny_write(write, bus_iodev, RTIO_PRIO_NORM, &reg, 1, NULL);
write->flags |= RTIO_SQE_TRANSACTION;     /* glue next sqe to same I2C txn */

rtio_sqe_prep_read(read, bus_iodev, RTIO_PRIO_NORM, buf, n, sqe_userdata);
read->flags |= RTIO_SQE_CHAINED;          /* run callback after this completes */
read->iodev_flags |= RTIO_IODEV_I2C_STOP | RTIO_IODEV_I2C_RESTART;

rtio_sqe_prep_callback(cb, my_done_cb, dev, NULL);
rtio_submit(ctx, 0);
```

`TRANSACTION` glues two sqe's into one bus transaction (register address then burst). `CHAINED` makes the callback wait for completion. For SPI, drop the `iodev_flags` line.

The bus iodev (`bus_iodev` above) is declared statically with `I2C_DT_IODEV_DEFINE(name, DT_DRV_INST(0))` (or `SPI_DT_IODEV_DEFINE`) — typically once per driver instance in `<chip>.c`, with the pointer stashed in `data->bus_iodev`.

**Use `sensor_clock_get_cycles` / `sensor_clock_cycles_to_ns`** — not `k_uptime_*`. The sensor subsystem allows an external high-precision clock source via Kconfig.

## Encoded buffer (wire format)

The driver decides the layout. **Required**: a discriminator the decoder can use to tell streaming vs one-shot buffers apart. Convention:

```c
struct mychip_decoder_header {
    uint64_t timestamp;     /* ns, from sensor_clock_cycles_to_ns */
    uint8_t  is_fifo  : 1;  /* discriminator */
    uint8_t  range   : 3;   /* whatever the decoder needs to scale */
    uint8_t  odr     : 4;
} __packed;

struct mychip_fifo_data {          /* streaming */
    struct mychip_decoder_header header;
    uint8_t  int_status;            /* raw IRQ source bits for has_trigger() */
    uint16_t fifo_byte_count;       /* payload bytes that follow */
    /* Followed by N raw frames in chip-native format. */
};

struct mychip_sample {             /* one-shot */
    struct mychip_decoder_header header;
    uint8_t  xyz_raw[6];
};
```

**The decoder runs on bytes alone** — it must not consult the driver's runtime state. Anything the decoder needs (range, ODR, timestamp, sample count, IRQ status) must be embedded in the buffer.

## The decoder

```c
#define DT_DRV_COMPAT vendor_mychip   /* REQUIRED — SENSOR_DECODER_API_DT_DEFINE depends on it */

SENSOR_DECODER_API_DT_DEFINE() = {
    .get_frame_count = mychip_get_frame_count,
    .get_size_info   = mychip_get_size_info,
    .decode          = mychip_decode,
    .has_trigger     = mychip_has_trigger,
};

int mychip_get_decoder(const struct device *dev, const struct sensor_decoder_api **api)
{
    ARG_UNUSED(dev);
    *api = &SENSOR_DECODER_NAME();
    return 0;
}
```

The decoder is normally per-compatible (one instance shared across all device instances of that compatible). Per-instance decoders are only needed for chips with runtime-detected variants whose decode logic differs across instances — rare; you can ignore the case unless you specifically have it.

### Callback contracts (subtle!)

| Function                                  | What it returns                                                                                                                                                                                                      |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `get_frame_count(buf, chan, *out)`        | Number of frames available for `chan` in `buf`. Return `0` with `*out = 0` for "empty trigger event" (NOP/DROP path). `-ENOTSUP` if `chan` not supported.                                                            |
| `get_size_info(chan, *base, *frame)`      | Bytes in the **decoded** output for `chan` (e.g. `sizeof(struct sensor_three_axis_data)` + per-frame `sensor_three_axis_sample_data`). **Not** the encoded buffer size.                                              |
| `decode(buf, chan, *fit, max_count, out)` | Decode up to `max_count` frames. `*fit` is an opaque iterator the decoder owns (commonly the byte offset of the next undecoded frame, cast through `uintptr_t`). Return the number of frames decoded; `0` when done. |
| `has_trigger(buf, trig)`                  | True if the streaming buffer was produced by trigger `trig`. Inspect `int_status` in the header.                                                                                                                     |

Output is q31 fixed-point: `struct sensor_three_axis_data`, `struct sensor_q31_data`, etc. (see `include/zephyr/drivers/sensor_data_types.h`). Set `.header.base_timestamp_ns` and per-frame `.timestamp_delta`.

## `SENSOR_STREAM_DATA_*` options

The consumer attaches one of these to each trigger in `SENSOR_DT_STREAM_IODEV`. Your IRQ chain inspects `cfg->triggers[i].opt` after deciding which trigger fired:

| Option                       | Value | Driver behavior                                                                                           |
| ---------------------------- | ----- | --------------------------------------------------------------------------------------------------------- |
| `SENSOR_STREAM_DATA_INCLUDE` | 0     | Drain FIFO into the mempool buffer (header + payload), complete SQE.                                      |
| `SENSOR_STREAM_DATA_NOP`     | 1     | Allocate a buffer sized **just for the header**, set `fifo_byte_count = 0`, complete SQE. FIFO untouched. |
| `SENSOR_STREAM_DATA_DROP`    | 2     | Same as NOP, **plus** flush the FIFO on-chip (bypass+restore or explicit flush register).                 |

If multiple triggers fire at once, take `MIN(opt_a, opt_b)` so the strongest-include option wins (INCLUDE=0 < NOP=1 < DROP=2).

## Kconfig pattern

```
config <CHIP>
    bool "<chip> sensor"
    default y
    depends on DT_HAS_<COMPAT>_ENABLED
    select I2C if $(dt_compat_on_bus,$(DT_COMPAT_<COMPAT>),i2c)
    select SPI if $(dt_compat_on_bus,$(DT_COMPAT_<COMPAT>),spi)
    select RTIO_WORKQ if SENSOR_ASYNC_API   # for one-shot fallback

if <CHIP>

config <CHIP>_STREAM
    bool "Use FIFO to stream data"
    select <CHIP>_TRIGGER
    depends on (SPI_RTIO || I2C_RTIO)
    depends on SENSOR_ASYNC_API
    help
      Stream sensor data via RTIO on FIFO interrupts.

endif
```

- **`SENSOR_ASYNC_API`** is the top-level Kconfig that compiles the entire async/decoder path into the framework. Streaming requires it; do _not_ let the whole driver `depend on` it (legacy users still build).
- Streaming `depends on` the bus's RTIO variant (`I2C_RTIO` / `SPI_RTIO`) because the IRQ-driven chain runs sqe's through that bus.

## CMake pattern

```cmake
zephyr_library_sources(<chip>.c)
zephyr_library_sources_ifdef(CONFIG_<CHIP>_TRIGGER       <chip>_trigger.c)
zephyr_library_sources_ifdef(CONFIG_SENSOR_ASYNC_API     <chip>_rtio.c <chip>_decoder.c)
zephyr_library_sources_ifdef(CONFIG_<CHIP>_STREAM        <chip>_stream.c)
```

The rtio dispatcher and decoder compile in whenever the async API is on, even without streaming (one-shot reads still work). Streaming source is gated separately.

## Scaffold script

A `scaffold.py` next to this skill generates a starting-point driver tree with all the patterns above already wired up. Templates live in `templates/` (Jinja2). The script is dispatched via `uv run --script` (PEP 723 inline metadata), so `jinja2` is fetched on first run — no global install needed.

```bash
~/.claude/skills/zephyr-sensor-streaming-api/scaffold.py \
    --vendor acme --chip acme3 --bus i2c \
    --channels accel,gyro,q31:temp:SENSOR_CHAN_AMBIENT_TEMP \
    --out <workspace_root>
```

Channel spec:

| Token                         | Generates                                                 |
| ----------------------------- | --------------------------------------------------------- |
| `accel`                       | `SENSOR_CHAN_ACCEL_XYZ` → `struct sensor_three_axis_data` |
| `gyro`                        | `SENSOR_CHAN_GYRO_XYZ` → `struct sensor_three_axis_data`  |
| `q31:<label>:<SENSOR_CHAN_*>` | the named channel → `struct sensor_q31_data`              |

Useful flags: `--no-stream` (one-shot only), `--no-sample` (skip the sample app), `--dry-run`, `--force`.

### Generating only specific files

If you already have parts of the driver and just want one or two files (e.g. you're modernizing an existing driver and only need the decoder + binding), use `--only`:

```bash
scaffold.py ... --list-targets               # enumerate names
scaffold.py ... --only chip_decoder.c,chip.h
scaffold.py ... --only binding.yaml
scaffold.py ... --only chip_stream.c,chip_trigger.c   # add streaming to an existing driver
```

Names refer to template stems (the rendered output filename has `chip` replaced with your `--chip` argument).

Files written (under `--out`):

```
drivers/sensor/<vendor>/<chip>/{<chip>.c,.h, <chip>_rtio.c, <chip>_decoder.c,
                               <chip>_stream.c, <chip>_trigger.c,
                               Kconfig, CMakeLists.txt}
dts/bindings/sensor/<vendor>,<chip>.yaml
samples/sensor/<chip>/{src/main.c, prj.conf, sample.yaml,
                      CMakeLists.txt, boards/<chip>.overlay}
```

The generated code compiles in shape but contains `TODO:` markers at every chip-specific decision: register addresses, scaling math, FIFO frame layout, attribute handling. After running the scaffold, walk the **completion checklist** above and fill in the TODOs.

## Consumer-side reminder (for testing your driver)

Streaming consumers need a mempool-backed RTIO context:

```c
RTIO_DEFINE_WITH_MEMPOOL(ctx, SQ_SIZE, CQ_SIZE, BLK_COUNT, BLK_SIZE, BLK_ALIGN);
SENSOR_DT_STREAM_IODEV(my_stream, DT_ALIAS(accel),
    {SENSOR_TRIG_FIFO_WATERMARK, SENSOR_STREAM_DATA_INCLUDE});
sensor_stream(&my_stream, &ctx, NULL, &handle);
```

If `BLK_SIZE` is smaller than your worst-case `sizeof(header) + fifo_bytes`, `rtio_sqe_rx_buf` returns the largest available block and you must truncate the FIFO read accordingly (don't error — the caller chose the budget).

## Completion checklist

Walk this before declaring the driver done. Skipping items is how bugs ship.

### `submit` handler

- [ ] Every code path in `submit` and every RTIO callback ends in `rtio_iodev_sqe_ok()` or `rtio_iodev_sqe_err()`. No silent returns.
- [ ] Branches on `cfg->is_streaming`. Streaming-disabled builds return `-ENOTSUP`, not a crash.
- [ ] One-shot path uses `rtio_work_req_alloc/_submit` when the bus driver isn't RTIO-native (or directly uses bus iodev when it is).
- [ ] Streaming path stashes `iodev_sqe` to `data->streaming_sqe` before returning. Clears it on completion.
- [ ] GPIO IRQ is disabled while the bus chain is in flight; re-armed only after the SQE is completed.

### Encoded buffer

- [ ] Header has a discriminator (`is_fifo` bit or equivalent) so the decoder can distinguish one-shot from streaming buffers.
- [ ] Header carries everything the decoder needs: timestamp (ns), range/scale, ODR (for `timestamp_delta`), and the IRQ status bits (for `has_trigger`).
- [ ] Sample count is stored as a byte count or frame count — be explicit; don't infer from buffer length.
- [ ] Layout is `__packed` if any field would otherwise be padded across the wire.

### Decoder

- [ ] `DT_DRV_COMPAT` is `#define`d before `SENSOR_DECODER_API_DT_DEFINE()` in the decoder source.
- [ ] Decoder reads only the buffer — no `dev->data`, no globals, no driver-private symbols.
- [ ] `get_size_info` returns the **decoded** output struct sizes (e.g. `sizeof(struct sensor_three_axis_data)`), not the encoded buffer size.
- [ ] `get_frame_count` returns 0 with `*frame_count = 0` for empty-event buffers (NOP/DROP); `-ENOTSUP` only when the channel isn't supported.
- [ ] `decode` advances `*fit` monotonically and returns 0 when exhausted.
- [ ] `has_trigger` inspects header bits, not driver state.

### ISR / streaming chain

- [ ] No blocking bus I/O from the GPIO callback.
- [ ] Timestamp captured via `sensor_clock_get_cycles` + `sensor_clock_cycles_to_ns` at the earliest possible moment (in the ISR handler, before any chained sqe's).
- [ ] Register-read sqe pattern uses `RTIO_SQE_TRANSACTION` on the address write and `RTIO_SQE_CHAINED` on the data read; I2C also sets `RTIO_IODEV_I2C_STOP|RESTART`.
- [ ] All three `SENSOR_STREAM_DATA_*` options are handled: INCLUDE drains FIFO; NOP allocates header-only and completes; DROP additionally flushes the FIFO on-chip.

### Kconfig / CMake

- [ ] Top-level driver does **not** `depend on SENSOR_ASYNC_API` (legacy must still build).
- [ ] `select RTIO_WORKQ if SENSOR_ASYNC_API`.
- [ ] Streaming option `depends on (I2C_RTIO || SPI_RTIO) && SENSOR_ASYNC_API`.
- [ ] CMake gates `<chip>_rtio.c` + `<chip>_decoder.c` on `CONFIG_SENSOR_ASYNC_API`; gates `<chip>_stream.c` + `<chip>_trigger.c` on `CONFIG_<CHIP>_STREAM`.

### Devicetree binding

- [ ] Bus-appropriate base (`i2c-device.yaml` or `spi-device.yaml`) included.
- [ ] `int-gpios` property declared if streaming is supported.
- [ ] Any chip-specific properties documented in the binding (ODR, FS range, FIFO watermark default).

### Sample / test

- [ ] Sample exercises **both** one-shot (`sensor_read_async_mempool`) and, if implemented, streaming (`sensor_stream` with `RTIO_DEFINE_WITH_MEMPOOL`).
- [ ] Sample is added to twister manifest so CI builds it.
- [ ] A unit test for the decoder exists (encoded byte vector in → expected q31 out) — the decoder is the most-tested-per-LOC component because it's pure.

## Common mistakes

| Mistake                                                                     | Fix                                                                                                  |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Forgetting to complete the SQE on an error path                             | Audit every return in `submit` and every callback for `rtio_iodev_sqe_ok/_err`.                      |
| Doing bus I/O in the GPIO ISR                                               | Build an RTIO sqe chain; let `I2C_RTIO`/`SPI_RTIO` service it.                                       |
| Using `k_uptime_*` for timestamps                                           | Use `sensor_clock_get_cycles` + `sensor_clock_cycles_to_ns`.                                         |
| `get_size_info` returning encoded buffer size                               | It must return **decoded** output sizes (the q31 struct sizes).                                      |
| Decoder reading driver state (range, ODR) from `dev->data`                  | Embed everything in the buffer header. Decoder is stateless w.r.t. the driver.                       |
| No `is_fifo` discriminator in the header                                    | Add one. Decoder needs to dispatch one-shot vs streaming buffers.                                    |
| Forgetting `DT_DRV_COMPAT` before `SENSOR_DECODER_API_DT_DEFINE()`          | The macro `UTIL_CAT`s it; without it you get a confusing build error.                                |
| Whole driver `depends on SENSOR_ASYNC_API`                                  | Only the streaming option should. Legacy fetch-and-get must still build.                             |
| `RTIO_DEFINE` (no mempool) for streaming                                    | Streaming needs `RTIO_DEFINE_WITH_MEMPOOL`.                                                          |
| Not handling `SENSOR_STREAM_DATA_NOP`                                       | Allocate header-only buffer and complete the SQE — don't silently drop the event.                    |
| Re-arming GPIO IRQ before SQE completion                                    | Re-enable only after `rtio_iodev_sqe_ok`, otherwise you'll clobber the stashed sqe.                  |
| Routing the GPIO callback to both legacy DRDY and streaming unconditionally | Branch on `data->streaming_sqe != NULL`. Streaming owns the IRQ while active.                        |
| Forgetting `RTIO_SQE_TRANSACTION` on the register-address write             | The chip won't see a single I2C/SPI transaction and the burst read will read from the wrong address. |

## Quick reference (file/symbol map)

| Looking for                                                                          | Path                                                                       |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Consumer API (`sensor_read`, `sensor_stream`, iodev macros)                          | `include/zephyr/drivers/sensor.h`                                          |
| `struct sensor_driver_api`, `submit`, `get_decoder`                                  | `include/zephyr/drivers/sensor.h` (`__subsystem struct sensor_driver_api`) |
| `struct sensor_decoder_api`, `SENSOR_DECODER_API_DT_DEFINE`                          | `include/zephyr/drivers/sensor.h`                                          |
| `enum sensor_stream_data_opt`, `struct sensor_stream_trigger`                        | `include/zephyr/drivers/sensor.h`                                          |
| Decoded q31 structs (`sensor_three_axis_data`, …)                                    | `include/zephyr/drivers/sensor_data_types.h`                               |
| Framework glue (`__sensor_iodev_api`, fallback decoder)                              | `drivers/sensor/default_rtio_sensor.c`                                     |
| Timestamp helpers                                                                    | `include/zephyr/drivers/sensor_clock.h`                                    |
| RTIO sqe primitives (`rtio_sqe_rx_buf`, `rtio_iodev_sqe_ok/_err`, `rtio_work_req_*`) | `include/zephyr/rtio/rtio.h`, `include/zephyr/rtio/work.h`                 |
| Bus iodev macros (`I2C_DT_IODEV_DEFINE`, `SPI_DT_IODEV_DEFINE`)                      | `include/zephyr/drivers/i2c/rtio.h`, `include/zephyr/drivers/spi/rtio.h`   |
| Small canonical example                                                              | `drivers/sensor/adi/adxl345/`                                              |
| Larger canonical example                                                             | `drivers/sensor/bosch/bma4xx/`                                             |
| Consumer-side docs                                                                   | `doc/hardware/peripherals/sensor/read_and_decode.rst`                      |
