---
name: zephyr-sources
description: Where to get ground truth about Zephyr code in a west workspace — clangd LSP, semcode, and the build's generated Kconfig/devicetree — instead of memory. Use before answering what a Zephyr API, macro, CONFIG_* or DT_* resolves to, who calls a function, or why something is or isn't compiled in.
---


## Finding things

- Subsystems: `subsys/`; drivers: `drivers/<class>/`; public API headers: `include/zephyr/` and
  the APIs defined under `lib/` (a subsystem's own `include/zephyr/`, such as ztest's, is not
  public API); kernel: `kernel/`; boards: `boards/<vendor>/`; SoCs: `soc/`; devicetree: `dts/`;
  tests: `tests/`; samples: `samples/`; tooling: `scripts/`.
- `MAINTAINERS.yml` maps paths to areas and people. The recent history of a path is the best
  guide to its local conventions: `git log --oneline -20 -- <path>`.
- The documentation source is `doc/`, published at https://docs.zephyrproject.org/latest/. The
  published docs, the source tree and the last six months of issues and PRs are also searchable
  through the project's MCP server, `https://zephyrproject.mcp.kapa.ai`
  (`doc/develop/tools/kapa_ai.rst`); its answers are generated and must be verified against the
  tree.

