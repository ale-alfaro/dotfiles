# NCS / Zephyr BLE application code — detailed reference (nRF5340 & nRF52840)

Heading conventions (kept for grepability): **Rules** = normative, **Prefer** =
positive patterns, **Avoid** = anti-patterns, **Allow** = conditional exceptions,
**Review checks** = reviewer triggers, **Examples** = in-tree references.


---


---

## Protocol-Specific Guidance

### BLE Application Patterns

#### GATT service declaration

Use `BT_GATT_SERVICE_DEFINE()` for static service registration. This is the standard NCS pattern:

```c
BT_GATT_SERVICE_DEFINE(my_svc,
    BT_GATT_PRIMARY_SERVICE(BT_UUID_MY_SERVICE),
    BT_GATT_CHARACTERISTIC(BT_UUID_MY_CHAR,
                           BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                           BT_GATT_PERM_READ,
                           read_cb, NULL, NULL),
    BT_GATT_CCC(ccc_cfg_changed,
                 BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
);
```

#### Threading model

- GATT read and write callbacks execute **directly in the Bluetooth RX thread**. Do not block, do not perform heavy computation, do not call `k_sleep()` in these callbacks.
- Defer long work from GATT callbacks to a workqueue or dedicated thread.
- Connection callbacks (`bt_conn_cb`) also run in the RX thread context.
- The BLE stack shares the CPU with every other thread. A high-priority data path that holds the CPU for long stretches starves the RX thread and the host's TX path, which presents as stalled notifications or dropped transfers rather than as a fault.

#### Rules

- Define UUIDs as 128-bit custom UUIDs using `BT_UUID_DECLARE_128(...)`. Do not reuse the Bluetooth SIG base UUID range.
- Separate BLE service code from application logic. Service module exposes typed init and update functions; application module calls them.
- Use a callback struct pattern (function pointers) to decouple the service from hardware control, following the LBS pattern.
- Track notification state via CCCD change callbacks. Do not send notifications when CCCD is not enabled.
- Validate write data length and content before processing: check `len`, `offset`, and value ranges.
- Use `bt_gatt_notify()` for notifications, `bt_gatt_indicate()` for indications.
- Register connection callbacks to manage per-connection state.

#### Advertising

- Construct advertising data with `BT_DATA_BYTES()` and `BT_DATA()` macros.
- Include service UUIDs in the advertising or scan response data so clients can discover services.
- Use `bt_le_adv_start()` with appropriate parameters for connectable or non-connectable advertising.

#### Avoid

- Block in GATT read/write callbacks.
- Send notifications without checking CCCD state.
- Use `printk()` inside GATT callbacks in production.
- Hard-code connection parameters without considering the use case.
- Access `bt_conn` pointers after disconnect without reference counting (`bt_conn_ref()` / `bt_conn_unref()`).

#### Representative Examples

- `nrf/subsys/bluetooth/services/lbs.c` — LED Button Service pattern
- `zephyr/samples/bluetooth/peripheral_hr/` — Heart Rate peripheral
- `zephyr/samples/bluetooth/peripheral/` — basic peripheral pattern

## BLE application patterns

Static service registration via `BT_GATT_SERVICE_DEFINE()`:

```c
BT_GATT_SERVICE_DEFINE(my_svc,
    BT_GATT_PRIMARY_SERVICE(BT_UUID_MY_SERVICE),
    BT_GATT_CHARACTERISTIC(BT_UUID_MY_CHAR,
                           BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                           BT_GATT_PERM_READ,
                           read_cb, NULL, NULL),
    BT_GATT_CCC(ccc_cfg_changed, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE),
);
```

**Threading model (the single most important BLE rule):** GATT read/write callbacks
and connection callbacks (`bt_conn_cb`) run **directly in the Bluetooth RX thread**.
Do not block, do heavy computation, or `k_sleep()` there — defer long work to a
workqueue or dedicated thread (post an event via zbus/sem/msgq). This holds
identically on the nRF52840 and the nRF5340 app core; the Host runs on the app core
in both cases.

**Rules**
- Define custom UUIDs as 128-bit via `BT_UUID_DECLARE_128(...)`; don't reuse the
  SIG base range.
- Separate BLE service code from app logic: the service exposes typed init/update
  functions; use a callback-struct (function pointers) to decouple it from hardware
  control (the LBS pattern — `nrf/subsys/bluetooth/services/lbs.c`).
- Track notification state via CCCD change callbacks; **don't notify when CCCD is
  disabled**. Use `bt_gatt_notify()` for notifications, `bt_gatt_indicate()` for
  indications.
- Validate write `len`/`offset`/value ranges before processing. Register connection
  callbacks for per-connection state.
- Build advertising data with `BT_DATA_BYTES()`/`BT_DATA()`; include service UUIDs
  so clients can discover services. Choose connection/advertising intervals for the
  power profile, not the demo default.

**`bt_conn` lifetime**
- A `bt_conn *` handed to a callback is only valid within well-defined bounds. If
  you store it (e.g. to notify later), take a reference with `bt_conn_ref()` and
  release it with `bt_conn_unref()` on disconnect. Accessing a stale `bt_conn` after
  disconnect without reference counting is a common, hard-to-debug fault.

**Avoid:** blocking in GATT/connection callbacks; notifying without a CCCD check;
`printk()` in callbacks in production; hard-coded connection parameters without
justification; unreferenced `bt_conn` access after disconnect.

**Examples:** `nrf/subsys/bluetooth/services/lbs.c` (LED Button Service pattern),
`zephyr/samples/bluetooth/peripheral_hr/` (Heart Rate peripheral),
`zephyr/samples/bluetooth/peripheral/` (basic peripheral).

---
## BLE security

**Input validation**
- Bounds-check and validate all external data (BLE characteristic writes, UART,
  incoming packets) before use. Validate length before copying:
  `if (offset + len > sizeof(buf)) { return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN); }`.
- Don't trust offset/index values from external sources. Don't pass external data
  as `LOG_*` format strings (format-string risk).

**BLE security**
- Set appropriate GATT permission levels: `BT_GATT_PERM_*_ENCRYPT` for encrypted,
  `BT_GATT_PERM_*_AUTHEN` for authenticated access — don't leave sensitive
  characteristics at plain `BT_GATT_PERM_READ`/`WRITE`.
- Enable bonding (`CONFIG_BT_SETTINGS`) and store bonds via Settings. Consider LE
  Secure Connections only (`CONFIG_BT_SMP_SC_ONLY`) for production. Use
  `BT_LE_ADV_OPT_USE_IDENTITY` only when appropriate.


**Stack protection**
- Both the nRF52840 and nRF5340 have an ARM MPU — enable
  `CONFIG_HW_STACK_PROTECTION` (read-only guard region before each stack, fatal on
  overflow). `CONFIG_STACK_CANARIES` (GCC frame canaries) is an additional layer.

**Avoid:** shipping default MCUboot signing keys; `CONFIG_BT_SMP_ALLOW_UNAUTH_OVERWRITE`
in production; logging credentials/keys/sensitive identifiers; disabling stack
protection in release builds.


---

## nRF5340 dual-core BLE architecture

This is the biggest structural difference from the nRF52840. **On the nRF52840 the
whole BLE stack (Controller + Host) and the application run on one core.** On the
nRF5340 the stack is *split*:

- **Network core** runs the **Bluetooth LE Controller** (link layer + radio timing).
  The **SoftDevice Controller** is the default and the only Nordic-*supported*
  controller (it carries the per-release QDID). The Zephyr LE Controller can be
  selected but is not supported for production.
- **Application core** runs the **BLE Host** (upper stack) and the application logic.
- The two cores communicate over **HCI transported on RPMsg/OpenAMP** (shared memory
  + IPC), so application/Host code is written exactly as it would be on a single-core
  part — the split is transparent above HCI.

**The net-core image is a sysbuild child image and must be selected**, or a BLE app
silently produces a non-working build. In `sysbuild.conf` (or, to avoid warnings on
single-core boards, in `Kconfig.sysbuild`), select one of:

- `SB_CONFIG_NETCORE_IPC_RADIO=y` + `SB_CONFIG_NETCORE_IPC_RADIO_BT_HCI_IPC=y` —
  the **ipc_radio** firmware; what most NCS BLE samples use.
- `SB_CONFIG_NETCORE_HCI_IPC=y` — Zephyr's **hci_ipc** sample as the net-core image.
- `SB_CONFIG_NETCORE_APP_UPDATE=y` — additionally enables **net-core image update**
  through MCUboot (needed if DFU must update the controller).

**Rules**
- A BLE application for `nrf5340dk/nrf5340/cpuapp` **must** select a net-core BLE
  image in sysbuild. Omitting it builds an app that links but cannot use the radio.
- Keep this selection in sysbuild config (`sysbuild.conf` / `Kconfig.sysbuild`), not
  in application `#ifdef`s. Guarding it on multi-core support keeps the same tree
  building for the single-core nRF52840.
- Don't write application code against the controller directly; it lives behind HCI
  on the other core. Application-visible APIs are the same Host APIs as on the 52840.
- For DFU that must also update the controller, plan the net-core update path
  (`SB_CONFIG_NETCORE_APP_UPDATE`) — see DFU below.

---

## DFU & MCUboot

- `CONFIG_BOOTLOADER_MCUBOOT=y` adds MCUboot as a child image (primary/secondary
  slots). All production images must be signed (the build invokes `imgtool.py`).
- **Never ship default signing keys** — generate project-specific keys.
- App code must not write outside its partition. Define partitions in devicetree.
  Use `CONFIG_SINGLE_APPLICATION_SLOT` for non-swapping single-slot where appropriate.
- DFU transport via MCUmgr over BLE (`CONFIG_MCUMGR_TRANSPORT_BT`) or UART
  (`CONFIG_MCUMGR_TRANSPORT_UART`); the SMP server runs alongside the app.
- Upgrade modes: **test** (swapped for one boot, reverts if not confirmed — the app
  calls `boot_write_img_confirmed()` after validating) vs **confirm** (permanent).
  Test DFU on every release build; consider rollback protection with security
  counters.
- **nRF5340:** a full firmware update may need to update *both* the app-core image
  and the net-core controller image. Use sysbuild for the multi-image layout and
  enable net-core update support (`SB_CONFIG_NETCORE_APP_UPDATE`) so MCUboot can
  stage the network-core image.

---
