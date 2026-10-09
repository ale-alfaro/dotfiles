# Zephyr Application Development (for driver samples/tests)

## Application structure

A minimal app typically contains:

```
<app>/
├── CMakeLists.txt
├── prj.conf
├── app.overlay
└── src/
    └── main.c
```

- `CMakeLists.txt` links the app to Zephyr’s build system.
- `prj.conf` provides Kconfig options for the app.
- `app.overlay` customizes devicetree for the target board.
- `src/main.c` contains app code.

## Create an app (by hand)

1. Create an app directory (avoid spaces in path).
2. Add `src/main.c`.
3. Create `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr)
project(my_zephyr_app)

target_sources(app PRIVATE src/main.c)
```

4. Create `prj.conf` (can be empty if no options).
5. Add `app.overlay` if devicetree changes are needed.

## Build and run

- Build with west (example):
```sh
west build -b native_sim <app>
```

- Run the native_sim executable:
```sh
./build/zephyr/zephyr.exe
```

## Using reference apps

- Zephyr samples can be used as a starting point.
- The `example-application` repo is a reference workspace app that includes custom drivers, devicetree bindings, and CI scaffolding.
