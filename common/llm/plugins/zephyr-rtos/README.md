# zephyr-rtos

Deterministic code navigation for Zephyr west workspaces.

- **clangd LSP** via `scripts/clangd-west`: runs from the workspace top (the
  directory holding `.west/`) with `--compile-commands-dir` set to it, so it
  uses the `compile_commands.json` symlinked there. Outside a west workspace it
  is plain clangd. `--query-driver` lets clangd find the Zephyr SDK compiler's
  system headers.
- **semcode MCP** (`semcode-mcp` on `PATH`).
- **Skill** `zephyr-sources`: use LSP / semcode / build outputs over memory.
- **Agents** `zephyr-tester` and `zephyr-reviewer` (read-only). They preload the
  user-level skills `zephyr-unit-testing`, `zephyr-bsim-testing`,
  `zephyr-native-sim-shell`, `zephyr-west-running-cmds` and
  `ncs-embedded-code-review`.

Disable `clangd-lsp@claude-plugins-official` while this is enabled; both claim
`.c`/`.h`.

```sh
claude --plugin-dir ~/dotfiles/common/llm/plugins/zephyr-rtos
```
