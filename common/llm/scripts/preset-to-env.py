#!/usr/bin/env python3
"""Print env-var assignments for a presets.ini section.

Reads ../presets.ini, merges the [*] defaults with the named section, and
prints KEY=value lines for each llama-server flag that has an env-var
binding (LLAMA_ARG_*). Designed for `docker compose --env-file`.

Sampling parameters (temp, top-p, ...) are intentionally skipped — llama-server
does not expose them as env vars, so they must be set per-request by the
client. They can stay in presets.ini as documentation.

Usage:
    preset-to-env.py SECTION > /tmp/env
    docker compose --env-file /tmp/env -f llm-service.yaml up -d
"""
import configparser
import sys
from pathlib import Path

KEY_MAP = {
    "hf-repo":      "HF_REPO",
    "ctx-size":     "LLAMA_ARG_CTX_SIZE",
    "n-gpu-layers": "LLAMA_ARG_N_GPU_LAYERS",
    "flash-attn":   "LLAMA_ARG_FLASH_ATTN",
    "cache-type-k": "LLAMA_ARG_CACHE_TYPE_K",
    "cache-type-v": "LLAMA_ARG_CACHE_TYPE_V",
    "jinja":        "LLAMA_ARG_JINJA",
    "batch-size":   "LLAMA_ARG_BATCH",
    "ubatch-size":  "LLAMA_ARG_UBATCH",
    "n-cpu-moe":    "LLAMA_ARG_N_CPU_MOE",
    "parallel":     "LLAMA_ARG_N_PARALLEL",
    "reasoning":    "LLAMA_ARG_REASONING",
}

# Negation flags: setting LLAMA_ARG_NO_X to any value disables X.
NEGATION_MAP = {"no-mmap": "LLAMA_ARG_NO_MMAP"}

# Client-only knobs: warn and skip.
SAMPLING_KEYS = {"temp", "top-p", "top-k", "min-p",
                 "presence-penalty", "repeat-penalty", "frequency-penalty"}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: preset-to-env.py SECTION", file=sys.stderr)
        return 2

    section = sys.argv[1]
    ini = Path(__file__).resolve().parent.parent / "presets.ini"
    if not ini.exists():
        print(f"presets.ini not found at {ini}", file=sys.stderr)
        return 1

    # Strip any pre-section preamble (e.g. `version = 1`) before parsing.
    lines = ini.read_text().splitlines()
    start = next((i for i, ln in enumerate(lines) if ln.lstrip().startswith("[")), 0)
    cp = configparser.ConfigParser()
    cp.read_string("\n".join(lines[start:]))

    if section not in cp:
        avail = ", ".join(s for s in cp.sections() if s != "*")
        print(f"section [{section}] not found (available: {avail})", file=sys.stderr)
        return 1

    merged: dict[str, str] = {}
    if "*" in cp:
        merged.update(cp["*"])
    merged.update(cp[section])

    for k, v in merged.items():
        v = v.strip()
        if k in KEY_MAP:
            print(f"{KEY_MAP[k]}={v}")
        elif k in NEGATION_MAP and v.lower() in ("true", "1", "on", "yes"):
            print(f"{NEGATION_MAP[k]}=1")
        elif k in SAMPLING_KEYS:
            print(f"skipped '{k}' (sampling — client-side only)", file=sys.stderr)
        else:
            print(f"warning: unknown key '{k}'", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
