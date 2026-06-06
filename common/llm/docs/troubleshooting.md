---
title: Troubleshooting
tags:
  - llm
  - troubleshooting
  - debugging
---

# Troubleshooting

First step for any failure:

```bash
mise run debug
```

It prints compose state, container exit codes, recent logs from both sides, GPU info, HF cache size, and disk free. That's usually enough to identify the failure class. Sections below map symptoms → causes → fixes for the issues this stack has hit historically.

## Tailscale unhealthy / `/healthz` returns 503

> [!bug] Symptom
> `mise run status` shows `tailscale-llama-cpp` as `unhealthy` or stuck `starting`. `mise run logs:ts` shows tailscaled cycling through `NeedsLogin → warming-up`. `app-llama-cpp` never starts because `depends_on: tailscale: condition: service_healthy` blocks it.

**Cause**: invalid, placeholder, or already-consumed `TS_AUTHKEY` in `.env`.

**Fix**:

1. Generate a new **reusable** auth key at <https://login.tailscale.com/admin/settings/keys>. Tag it with `tag:llm-server` to skip device approval.
2. Paste it into `.env`:
   ```
   TS_AUTHKEY=tskey-auth-...
   ```
3. `mise run down && mise run qwen27b`.

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
mise run down && mise run qwen27b
```

Verify with `docker info | grep -i runtimes` — you should see `nvidia` listed.

## llama-server crashes on `--flash-attn`

> [!bug] Symptom
> `mise run logs` shows:
> ```
> error while handling argument "--flash-attn": error: unknown value for --flash-attn: '...'
> ```

**Cause**: recent llama.cpp builds require `--flash-attn on|off|auto` — a bare `--flash-attn` followed by another flag gets the next flag parsed as the value.

**Fix**: in `model.vars`, ensure `LLAMA_ARG_FLASH_ATTN=on` (not bare). If you copied an older config snippet, fix it.

## Edited `model.vars` but the change didn't take effect

> [!bug] Symptom
> You changed a value in `model.vars`, ran `mise run qwen27b`, but `mise run status` or `docker exec app-llama-cpp env` still shows the old value.

**Cause**: `docker compose up -d` only recreates a container when its config hash changes. Bare-passthrough env vars (`- LLAMA_ARG_*`) don't always show up in compose's hash, so it can decide "no change" and skip the recreate.

**Fix**: bring it down first, which guarantees a fresh start:

```bash
mise run down && mise run qwen27b
```

Confirm with:

```bash
docker exec app-llama-cpp env | grep LLAMA_ARG_
```

## CUDA OOM despite plenty of VRAM free

> [!bug] Symptom
> ```
> cudaMalloc failed: out of memory
> alloc_tensor_range: failed to allocate CUDA0 buffer of size 902804096
> ```
> while `nvidia-smi` shows the GPU mostly idle.

**Cause**: usually a crash-loop where each restart leaves CUDA state behind before fully releasing — VRAM ends up fragmented across orphaned contexts. ==Especially likely when switching between models with different memory profiles.==

**Fix**: bring everything down cleanly before retrying.

```bash
mise run down
mise run qwen27b
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
2. `mise run down && mise run qwen27b` so tailscaled re-reads the serve config.
3. Verify with `docker exec tailscale-llama-cpp tailscale serve status` — should now list the proxy on `:443`.

## Container "healthy" but `/v1/chat/completions` 404s or hangs

> [!bug] Symptom
> Healthcheck passes (`pgrep -f llama-server` succeeds), but API calls error or hang.

**Cause**: the healthcheck only checks the **process** exists, not that the model is loaded and serving. While the model is downloading or mmap-loading, the process exists but the HTTP server isn't accepting connections.

**Diagnostic**:

```bash
mise run status   # shows the actual model state, not just the process
mise run logs     # watch for "server is listening on http://0.0.0.0:8080"
```

First-time loads of an uncached HF repo take ~5 min (download 17 GB). Subsequent boots are ~10–15 s.

## `mise run qwen27b` errors with "HF_REPO not set" or similar

> [!bug] Symptom
> ```
> HF_REPO is required but not set
> ```
> or `docker compose` fails to interpolate `${HF_REPO}`.

**Cause**: `model.vars` is missing, empty, or not being loaded by mise. Most commonly: the file was renamed or moved.

**Fix**:

```bash
test -f model.vars && cat model.vars     # should print HF_REPO=... etc.
grep -A1 "_.file" mise.toml              # confirm mise points at it
```

The mise.toml `[env]` block should have:

```toml
'_'.file = [".env", "model.vars"]
```

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

- [[operations]] — task reference, changing config
- [[clients]] — connection methods
- [[README]] — system overview + mermaid diagram
