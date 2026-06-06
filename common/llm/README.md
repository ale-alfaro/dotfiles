---
title: Local LLM Stack
tags:
  - llm
  - docker
  - tailscale
  - homelab
aliases:
  - llama-cpp stack
  - dingolai llm
---

# Local LLM Stack

A tailnet-exposed [llama.cpp](https://github.com/ggml-org/llama.cpp) server running on `dingolai`'s GPU (RTX 3090 Ti), with config split across `.env` (secrets) and `model.vars` (runtime knobs).

> [!summary]
> Two containers — a **tailscale sidecar** and **llama-server** — share a network namespace so the llama API is reachable on the tailnet host `llama-cpp.tail5a0932.ts.net:8080`. ==Mise loads `.env` + `model.vars` into the task shell; `docker compose` interpolates them into the container.== Sampling defaults stay on the client.

## High-level architecture

```mermaid
flowchart TB
    subgraph host["🖥️ dingolai (host) — RTX 3090 Ti"]
        direction TB
        envs[(".env<br/>secrets")]
        vars[("model.vars<br/>HF_REPO + LLAMA_ARG_*")]
        mise["mise.toml<br/>loads both files"]
        cache[("~/.cache/huggingface<br/>GGUF cache")]

        subgraph stack["docker compose (llm-service.yaml)"]
            direction LR
            ts["tailscale-llama-cpp<br/>(sidecar, owns netns)"]
            llama["app-llama-cpp<br/>llama-server + CUDA"]
            ts -. "shared network namespace" .- llama
        end

        envs --> mise
        vars --> mise
        mise -->|exported env| stack
        cache -->|bind mount| llama
    end

    subgraph mesh["🌐 Tailscale tailnet — tail5a0932.ts.net"]
        magicdns["MagicDNS: llama-cpp:8080"]
    end

    ts <==>|wireguard mesh| mesh

    laptop["💻 laptop<br/>CodeCompanion / curl"]
    phone["📱 phone / iPad<br/>browser, Web Clipper"]
    other["any tailnet device"]

    mesh --- laptop
    mesh --- phone
    mesh --- other
```

## Quick start

```bash
mise run qwen27b             # bring up llama.cpp with model.vars config
mise run status              # one-line state check
mise run logs                # follow llama-cpp logs
mise run down                # tear it all down
```

Point any OpenAI-compatible client at `http://llama-cpp:8080/v1`.

## Files at a glance

| Path | Purpose |
|---|---|
| `llm-service.yaml` | Docker compose: tailscale sidecar + llama-server |
| `.env` | ==Secrets — gitignored.== `TS_AUTHKEY`, `SERVICE`. |
| `model.vars` | Tracked — `HF_REPO` + `LLAMA_ARG_*` runtime knobs. |
| `mise.toml` | Task wrappers (`qwen27b`, `down`, `status`, `debug`, `logs`, `logs:ts`) |
| `clipper-templates/` | Obsidian Web Clipper templates that target this server |
| `config/` | Tailscale serve config (mounted into sidecar) |
| `ts/state/` | Tailscale node state — persists auth across recreates |

## Read next

- [[operations]] — every mise task, how config flows, changing the model
- [[clients]] — URL forms, web UI, curl, Neovim plugins, mobile, sharing with non-tailnet users
- [[troubleshooting]] — common boot-time failures and exact remedies
