#!/bin/bash
# Script to generate man pages for all west subcommands

VERSION_STRING="1.4.0"       # Replace with actual version from 'west --version'
OUTPUT_DIR="./west_manpages" # Directory to save man pages
mkdir -p "$OUTPUT_DIR"

# Get list of subcommands from west --help (parse the output)
SUBCOMMANDS=$(
    west --help | grep -A 100 "positional arguments" | grep -E
    "^  [a-z]+" | awk '{print $1}' | tr '\n' ' '
)

for CMD in $SUBCOMMANDS; do
    echo "Generating man page for west $CMD..."
    help2man --name="West $CMD - Zephyr Tool" \
        --section=1 \
        --output="$OUTPUT_DIR/west_$CMD.1" \
        --manual="Zephyr Project" \
        --source="Zephyr" \
        --version-string="$VERSION_STRING" \
        "west $CMD" 2>/dev/null || echo "Failed for $CMD"
done

echo "Man pages generated in $OUTPUT_DIR"
