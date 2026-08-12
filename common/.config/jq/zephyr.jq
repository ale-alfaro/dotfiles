# Create Devicetree Language Server configuration from build_info.yml.
# Run: jq -L ~/.config/jq -f zephyr.jq build/build_info.yml
[
    .cmake.devicetree as $dt
    | {
        "board": .cmake.board.name,
        "dtsFile": ($dt.files[] | select(. == "*.dts")),
        "overlays": ($dt.files[] | select(. == "*.overlay")),
        "includePaths": $dt.include-dirs,
        "zephyrBindings": $dt.bindings-dirs
    }
]


