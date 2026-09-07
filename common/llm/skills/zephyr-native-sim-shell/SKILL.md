---
name: native-sim-shell
description: Run and script native_sim samples through the Zephyr shell — PTY vs --uart_stdinout, piping printf commands into the exe, the shell-log-backend flush trap that makes twister console harnesses capture nothing, and writing sample.yaml console regexes. Use when driving a native_sim binary interactively, automating a shell-driven scenario, or debugging an empty handler.log / "Unknown Error" from a console-harness twister run.
---

# Driving native_sim samples through the shell

A sample with `CONFIG_SHELL=y` on `native_sim` is a scriptable simulator: pipe
shell commands into the executable and read the log stream back. The reference
example is `samples/subsys/sysadmin` (`sim`/`app` shell commands over a stub
platform adapter).

## Where the shell lives: PTY by default, stdinout on demand

`native_sim`'s UART (`zephyr,native-pty-uart`, node name `uart`) connects to a
new pseudo-terminal by default. Pick per run — do NOT bake it into prj.conf:

- **Interactive**: `zephyr.exe -attach_uart` — spawns a terminal (xterm+screen)
  on the PTY. The shell gets the raw terminal it wants; logs stay in the
  launching terminal.
- **Scripted**: `zephyr.exe --uart_stdinout` — the UART becomes the process's
  stdin/stdout, so piped bytes arrive as if typed:

  ```sh
  ( sleep 2; printf 'sim dock on\n'; sleep 1; printf 'app ship\n'; sleep 7 ) |
      timeout 12 build/<sample>/zephyr/zephyr.exe --uart_stdinout
  ```

  The `sleep`s pace real-time windows (debounces, commit windows).
  `CONFIG_UART_NATIVE_PTY_0_ON_STDINOUT=y` forces the same at build time;
  prefer the runtime flag so one binary serves both uses.

`native_sim` never exits on its own — always wrap in `timeout N`. "Stopped at
X s" on the way out is the SIGTERM handler, not an error.

## The log-backend trap (empty handler.log, "Unknown Error")

With `CONFIG_SHELL=y` two log backends are on: native-posix (plain stdout) and
the shell's. Two consequences:

1. Both on at once prints every line twice.
2. **The shell backend only starts flushing once something arrives on stdin.**
   A silent run — which is exactly what a twister console harness is — then
   captures nothing: empty `handler.log`, `FAILED Unknown Error` after the
   60 s timeout.

So keep the native-posix backend and drop the shell's:

```
CONFIG_SHELL_LOG_BACKEND=n
```

Logs then reach stdout regardless of where the shell's UART points, which is
also why twister works with the UART on its default PTY.

## Twister console harnesses over these samples

`sample.yaml` regexes match the log lines on stdout:

```yaml
harness: console
harness_config:
  type: multi_line
  ordered: true
  regex:
    - "manager: system ready"
    - "state: standby"
```

Match on log payloads (`state: standby`), never on shell prompts or ANSI.

Minimal quiet invocation (or the `west test.sim` alias):

```sh
west twister --clobber-output --no-detailed-test-id -p native_sim/native -T samples/<path>
```

`--clobber-output` replaces `twister-out/` instead of archiving another
`twister-out.N/`. Do NOT pass `--simulation=nsim` — that is the ARC simulator,
so twister only BUILDS the sample and reports the configuration as passed while
the test case ends "without a status" (the `None status detected` warning is
the tell). native_sim executes natively with no `--simulation` flag. Read the
**test cases** passed line, not the configurations line. Still cheapest first:
a direct `timeout 3 zephyr.exe </dev/null` is the twister-shaped silent run.

## Hardware corollary: `--device-serial-pty`

The same trick pointed at real boards: `west twister --device-testing
--device-serial-pty <script>` spawns the script and treats its stdin/stdout as
the device's serial terminal. Anything wrappable in a program becomes the
console — an RTT bridge (`JLinkRTTLogger`/`rtt` script), BLE-serial, a socat
relay — so the identical `harness: console` regexes run against hardware whose
console is not a plain `/dev/tty`. A shell-driven scenario proven on native_sim
via `--uart_stdinout` ports to the bench by swapping which side of the pipe
twister owns.

## Scenario scripts are regression tests waiting to happen

A `(printf ...; sleep ...) | zephyr.exe --uart_stdinout` scenario plus a regex
over its output is the same thing a pytest/console harness does. When a
hand-driven scenario proves a behaviour (an abort window, a debounce count),
fold it into the sample's `testcase`/`sample.yaml` or a pytest harness instead
of re-typing it next session.
