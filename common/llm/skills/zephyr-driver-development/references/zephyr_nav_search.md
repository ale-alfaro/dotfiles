# Zephyr Tree Drivers: Search and Navigation

## Overview

Start here as way to get a top level view of the drivers in the Zephyr repo and select a couple folders to do a search on. Couple things to do always:

- Use environment variable `$ZEPHYR_BASE` as the base directory of the search. Do not use hardcoded paths or relative ones as their multiple workspaces with multiple clones of the Zephyr repo. You want the one set for your project
- Always starts with the drivers folder and move to the samples and test folder search once the driver is implemented
- Use `fd` to find files quickly. Here's couple commands:

### Find C files with the keyword

```sh
~$ fd '<KEYWORD>' $ZEPHYR_BASE/drivers --extension=c
```

### Use Globs for finding C source and header files with the same device class

```sh
~$ fd --glob '**/drivers/<DEVICE_CLASS>/*.[ch]' $ZEPHYR_BASE/drivers
```

### Find recent files with the keyword

```sh
~$ fd '<KEYWORD>' $ZEPHYR_BASE/drivers --changed-within=1y
```

## References

### Driver Sources

```sh zephyr/drivers
├── adc
├── audio
├── auxdisplay
├── bbram
├── bluetooth
├── cache
├── can
├── charger
├── clock_control
├── CMakeLists.txt
├── comparator
├── console
├── coredump
├── counter
├── crc
├── crypto
├── dac
├── dai
├── debug
├── disk
├── display
├── dma
├── dp
├── edac
├── eeprom
├── entropy
├── espi
├── ethernet
├── firmware
├── flash
├── fpga
├── fuel_gauge
├── gnss
├── gpio
├── haptics
├── hdlc_rcp_if
├── hwinfo
├── hwspinlock
├── i2c
├── i2s
├── i3c
├── ieee802154
├── input
├── interrupt_controller
├── ipm
├── Kconfig
├── led
├── led_strip
├── lora
├── mbox
├── mdio
├── memc
├── mfd
├── mipi_dbi
├── mipi_dsi
├── misc
├── mm
├── modem
├── mspi
├── net
├── opamp
├── pcie
├── peci
├── pinctrl
├── pm_cpu_ops
├── power_domain
├── ps2
├── psi5
├── ptp_clock
├── pwm
├── regulator
├── reset
├── retained_mem
├── rtc
├── sdhc
├── sensor
├── sent
├── serial
├── sip_svc
├── smbus
├── spi
├── stepper
├── syscon
├── tee
├── timer
├── usb
├── usb_c
├── video
├── virtio
├── virtualization
├── w1
├── watchdog
├── wifi
└── xen
```

## Samples

```sh zephyr/samples/drivers
├── adc
├── audio
├── auxdisplay
├── auxdisplay_digits
├── can
├── charger
├── clock_control_litex
├── clock_control_xec
├── counter
├── crc
├── crypto
├── dac
├── display
├── drivers.rst
├── eeprom
├── espi
├── ethernet
├── flash_shell
├── fpga
├── fuel_gauge
├── gnss
├── haptics
├── ht16k33
├── i2c
├── i2s
├── ipm
├── jesd216
├── lcd_cyclonev_socdk
├── lcd_hd44780
├── led
├── lora
├── mbox
├── mbox_data
├── memc
├── misc
├── modem
├── mspi
├── opamp
├── peci
├── ps2
├── psi5
├── pwm
├── rtc
├── sent
├── smbus
├── soc_flash_nand
├── soc_flash_nrf
├── spi_bitbang
├── spi_flash
├── spi_flash_at45
├── spi_fujitsu_fram
├── stepper
├── uart
├── video
├── virtualization
├── w1
└── watchdog
```

## Tests

```sh zephyr/samples/drivers
/home/alealfaro/zephyrproject/zephyr/tests/drivers
├── adc
├── audio
├── bbram
├── build_all
├── can
├── charger
├── clock_control
├── comparator
├── console
├── console_switching
├── coredump
├── counter
├── crc
├── dac
├── disk
├── display
├── dma
├── eeprom
├── entropy
├── espi
├── ethernet
├── flash
├── flash_api
├── flash_simulator
├── fuel_gauge
├── gnss
├── gpio
├── hwinfo
├── i2c
├── i2s
├── input
├── interrupt_controller
├── ipm
├── led
├── mbox
├── memc
├── mipi_dsi
├── mm
├── modem
├── mspi
├── opamp
├── pinctrl
├── power
├── psi5
├── pwm
├── regulator
├── reset
├── retained_mem
├── rtc
├── sdhc
├── sensor
├── sent
├── smbus
├── spi
├── stepper
├── syscon
├── tee
├── timer
├── tisci
├── uart
├── udc
├── usb
├── video
├── virtualization
├── w1
├── watchdog
└── wifi
```
