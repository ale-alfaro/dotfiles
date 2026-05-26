---
title: Troubleshooting
tags:
  - llm
  - troubleshooting
  - debugging
---

# Troubleshooting

When something breaks, your first move is:

```bash
mise run debug
```

It prints compose state, container exit codes, recent logs from both sides, GPU info, HF cache size, and disk free. That's usually enough to identify the failure class. The sections below map symptoms → causes → fixes for the issues this stack has hit historically.

## Tailscale unhealthy / `/healthz` returns 503

> [!bug] Symptom
> `mise run status` shows `tailscale-llama-cpp` as `unhealthy` or `starting` indefinitely. `mise run logs:ts` shows tailscaled stuck cycling through `NeedsLogin → warming-up`. The `app-llama-cpp` container never starts because `depends_on: tailscale: condition: service_healthy` blocks it.

**Cause**: invalid, placeholder, or already-consumed `TS_AUTHKEY` in `.env`.

**Fix**:

1. Generate a new **reusable** auth key at <https://login.tailscale.com/admin/settings/keys>. Tag it with `tag:llm-server` to skip device approval.
2. Paste it into `.env`:
   ```
   TS_AUTHKEY=tskey-auth-...
   ```
3. `mise run down && mise run <variant>`.

> [!info] Why reusable, not ephemeral
> Ephemeral keys remove the node from the tailnet shortly after disconnect — defeats the purpose of a stable `llama-cpp.tail5a0932.ts.net` host. Reusable + non-ephemeral + 90-day expiry is the right combination.

## "could not select device driver nvidia"

> [!bug] Symptom
> `mise run debug` shows `app-llama-cpp` stuck in `Created` state with exit code 128 and error `could not select device driver "nvidia" with capabilities: [[gpu]]`.

**Cause**: NVIDIA Container Toolkit not installed or not configured for Docker.

**Fix** (Arch host):

```bash
sudo pacman -S nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
mise run down && mise run <variant>
```

Verify with `docker info | grep -i runtimes` — you should see `nvidia` listed.

## llama-server crashes on `--flash-attn`

> [!bug] Symptom
> `mise run logs` shows:
> ```
> error while handling argument "--flash-attn": error: unknown value for --flash-attn: '...'
> ```

**Cause**: recent llama.cpp builds require `--flash-attn on|off|auto` — a bare `--flash-attn` followed by another flag gets the next flag parsed as the value.

**Fix**: in `presets.ini`, the `[*]` section should have `flash-attn = on` (already the case in this repo's checked-in config). If you copied an older config, fix it.

## Wrong model loaded

> [!bug] Symptom
> `mise run status` shows a different model than the variant you just ran. `docker inspect app-llama-cpp --format '{{.Config.Cmd}}'` shows the wrong `-hf` argument.

**Cause**: stale `HF_REPO` (or `LLAMA_ARG_*`) in your shell env was overriding the preset's value during compose interpolation. This can happen if an earlier `mise activate` loaded a now-stale `.env` value into your interactive shell.

**Fix**: the `service:up` template already `unset`s these vars before sourcing the preset, so a fresh `mise run <variant>` should always win. To verify your shell is clean:

```bash
echo "HF_REPO='${HF_REPO:-<unset>}'"
```

Should print `<unset>` outside of an in-flight `mise run`.

## CUDA OOM despite plenty of VRAM free

> [!bug] Symptom
> ```
> cudaMalloc failed: out of memory
> alloc_tensor_range: failed to allocate CUDA0 buffer of size 902804096
> ```
> while `nvidia-smi` shows the GPU mostly idle.

**Cause**: usually a crash-loop where each restart attempt leaves CUDA state behind before fully releasing. Container restart fragmenting VRAM. ==Especially likely when switching between models with different memory profiles.==

**Fix**: bring everything down cleanly before retrying.

```bash
mise run down
mise run <variant>
```

If that doesn't help, check what else holds VRAM:

```bash
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
```

## HTTPS endpoint inert (`tailscale serve status` says "No serve config")

> [!info] Not a bug
> The `[serve.json]` in `llm-service.yaml` expects HTTPS Certificates to be enabled on the tailnet. Until you toggle that in the admin console (DNS → "Enable HTTPS"), tailscaled silently rejects the serve config and port 443 stays inert.
>
> The non-HTTPS port 8080 access works regardless — `http://llama-cpp:8080` and `http://llama-cpp.tail5a0932.ts.net:8080` are independent of serve.

To enable HTTPS:

1. Admin console → DNS → **Enable HTTPS**.
2. `mise run down && mise run <variant>` so tailscaled re-reads the serve config.
3. Verify with `docker exec tailscale-llama-cpp tailscale serve status` — should now list the proxy on `:443`.

## Container "healthy" but `/v1/chat/completions` 404s

> [!bug] Symptom
> Healthcheck passes (`pgrep -f llama-server` succeeds), but actual API calls return errors or hang.

**Cause**: the healthcheck only checks the **process** exists, not that the model is loaded and serving. While the model is downloading or mmap-loading, the process exists but the HTTP server isn't accepting connections.

**Diagnostic**:

```bash
mise run status   # shows the actual model state, not just the process
mise run logs     # watch for "server is listening on http://0.0.0.0:8080"
```

First-time loads of an uncached HF repo take ~5 min (download 17 GB). Subsequent boots are ~10–15 s.

## "command not found" or task fails silently

> [!bug] Symptom
> `mise run <variant>` returns in milliseconds without recreating anything, OR `mise tasks ls` doesn't list your variant.

**Cause**: probably a `presets.ini` / `mise.toml` mismatch — the variant references a section that doesn't exist (or vice versa).

**Fix**:

```bash
mise tasks ls                    # confirm task exists
python3 scripts/preset-to-env.py qwen27b-balanced   # dry-run the adapter
```

If the script errors with `section [...] not found`, fix the section name in either `presets.ini` or the `env.preset` value in `mise.toml`.

## Disk full

> [!warning]
> A single 27B-Q4 GGUF is ~17 GB. The 35B-Q4_K_M is similar. The HF cache grows fast if you experiment with many models.

**Diagnostic**:

```bash
du -sh ~/.cache/huggingface
df -h ~
```

**Cleanup**:

```bash
# Remove a specific model
rm -rf ~/.cache/huggingface/hub/models--unsloth--Qwen3.6-XX-GGUF

# Nuclear option (re-download next time)
rm -rf ~/.cache/huggingface
```

## See also

- [[operations]] — task reference, adding variants
- [[clients]] — connection methods
- [[README]] — system overview + mermaid diagram
