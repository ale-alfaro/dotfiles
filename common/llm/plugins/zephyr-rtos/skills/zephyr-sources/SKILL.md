---
name: zephyr-sources
description: Where to get ground truth about Zephyr code in a west workspace — clangd LSP, semcode, and the build's generated Kconfig/devicetree — instead of memory. Use before answering what a Zephyr API, macro, CONFIG_* or DT_* resolves to, who calls a function, or why something is or isn't compiled in.
---

Zephyr's APIs change between releases and NCS patches them. Answer from the tree
that is checked out, not from memory.

Sources, most trusted first:

1. **LSP (clangd)**: `goToDefinition`, `findReferences`, `hover`, `incomingCalls`,
   `outgoingCalls`. Resolves macros, `CONFIG_*` and `DT_*` as the compiler sees
   them for the current build.
   - clangd runs from the west workspace top and reads the
     `compile_commands.json` there. If LSP returns nothing or reports missing
     headers, that build is stale or for another app: run `west build` first.
2. **semcode MCP**: call graphs and symbol lookup across the whole workspace,
   including code outside the current build.
3. **Build outputs**: `zephyr/.config` (final Kconfig), `zephyr/zephyr.dts`
   (final devicetree), `zephyr/include/generated/`.
4. `west grep` / `rg` for plain text.

Say which source an answer came from. If none confirm it, say so.
