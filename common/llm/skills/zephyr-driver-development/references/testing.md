# Testing Drivers with native_sim and Bus Emulators

## native_sim overview

- `native_sim` builds Zephyr as a POSIX executable.
- Run with `./build/zephyr/zephyr.exe`.
- Application tests using `ztest` will exit automatically.
- Deterministic execution makes debugging and instrumentation easier.
- Enable `CONFIG_NO_OPTIMIZATIONS` for easier debugging.
- Sanitizers:
  - `CONFIG_ASAN` for AddressSanitizer
  - `CONFIG_UBSAN` for Undefined Behavior Sanitizer

Basic build/run:
```sh
west build -b native_sim samples/hello_world
./build/zephyr/zephyr.exe
```

## Bus driver emulators

- Emulators test peripheral drivers without real hardware.
- Emulators reuse the same devicetree node as the real driver.
- Set `DT_DRV_COMPAT` in emulator to match the real driver compat.

Example:
```c
#define DT_DRV_COMPAT bosch_bmi160
```

Create an emulator instance with:
- `EMUL_DT_DEFINE()` or `EMUL_DT_INST_DEFINE()`

Emulator APIs:
- `bus_api` (required) for upstream bus connection (I2C/SPI/eSPI/MSPI).
- `_backend_api` (optional) for test control hooks.

Use emulator backends to trigger conditions (faults, calibration missing, etc.)
and validate driver behavior.

## I2C emulation forwarding

You can forward address traffic between emulated controllers to test both ends:

```dts
i2c0: i2c@100 {
    compatible = "zephyr,i2c-emul-controller";
    #address-cells = <1>;
    #size-cells = <0>;
    #forward-cells = <1>;
    forwards = <&i2c1 0x20>;
};
```

## In-tree example tests

- BMI160 sensor driver on native_sim:
```sh
west build -b native_sim tests/drivers/sensor/bmi160
```

- EEPROM API test with emulator overlay:
```sh
west build -b native_sim tests/drivers/eeprom/api -- -DDTC_OVERLAY_FILE=at2x_emul.overlay -DEXTRA_CONF_FILE=at2x_emul.conf
```
