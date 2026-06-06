---
title: Clients
tags:
  - llm
  - api
  - tailscale
  - neovim
---

# Connecting clients

Once the stack is up (see [[operations]]), the same URL works from every device on your tailnet — home, coffee shop, hotel WiFi, anywhere.

## URL forms

| Form | When to use |
|---|---|
| `http://llama-cpp:8080` | Default. Any tailnet device with "Use Tailscale DNS" on (MagicDNS). |
| `http://llama-cpp.tail5a0932.ts.net:8080` | FQDN. Works even when MagicDNS is disabled on the client. |
| `http://100.93.6.30:8080` | Raw tailnet IP. Bypasses DNS entirely. |

> [!tip]
> Export `LLAMA_URL=http://llama-cpp:8080` in your shell config so curl, scripts, and editor plugins all share one source of truth. Bump the URL once if the host's tailnet name changes.

## Tailscale on a new device

1. Install Tailscale: <https://tailscale.com/download>
2. Sign in with the same identity you used on `dingolai` (`ale-alfaro@github`).
3. The device joins the existing `dingolai` / `ipad` / `iphone15` mesh.
4. Hit `http://llama-cpp:8080` — done. Traffic goes direct UDP when NAT traversal succeeds; falls back to Tailscale's DERP relays otherwise.

> [!warning] Mobile DNS caveat
> iOS/Android Tailscale apps have a separate "Use Tailscale DNS" toggle. If off, MagicDNS short names won't resolve — fall back to the FQDN. Toggle it on under the app's settings.

## Web UI

llama.cpp ships a chat UI at the root path. Open the URL in any browser on the tailnet.

> [!info] Chat persistence
> The UI is a client-side SPA. Chat history lives in **browser localStorage**, not on the server.
>
> - ✅ Survives reload, container recreate, model swap.
> - ❌ Not shared across browsers or devices.
> - ❌ Wiped if you clear site data or use a private window.
> - ❌ Not backed up — copy important conversations out by hand.

For cross-device chat history with a real database, front llama-server with [Open WebUI](https://github.com/open-webui/open-webui) or [LibreChat](https://github.com/danny-avila/LibreChat). Both speak the OpenAI API, so they plug into the existing endpoint with zero llama.cpp changes.

## curl / OpenAI-compatible API

The server speaks OpenAI's chat-completions API plus several llama.cpp-native endpoints.

### Chat completion

```bash
curl -s "$LLAMA_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL",
    "messages": [{"role":"user","content":"say hi"}],
    "temperature": 0.7,
    "top_p": 0.8,
    "stream": false
  }' | jq -r '.choices[0].message.content'
```

### Streaming chat (SSE)

```bash
curl -sN "$LLAMA_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model":"...","messages":[...],"stream":true}' \
  | sed 's/^data: //' | jq -r '.choices[0].delta.content // empty'
```

### Useful endpoints

| Path | Purpose |
|---|---|
| `/health` | `{"status":"ok"}` when model is loaded |
| `/v1/models` | Loaded model id + capabilities + ctx |
| `/v1/chat/completions` | OpenAI chat |
| `/v1/completions` | OpenAI text completion |
| `/v1/embeddings` | Embeddings (only if model supports) |
| `/v1/messages` | Anthropic-compatible Messages API |
| `/completion` | Native llama.cpp completion (richer options) |
| `/tokenize`, `/detokenize` | Token utilities |
| `/props` | Server-side props (chat template, modalities, ctx) |
| `/slots` | Per-slot state (active prompts, sampling) |
| `/apply-template` | Format messages with the model's chat template without inference |

## Neovim

The API is OpenAI-compatible, so any plugin that takes a base URL + model works.

### CodeCompanion

```lua
require("codecompanion").setup({
  adapters = {
    llama = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        env = { url = "http://llama-cpp:8080" },
        schema = {
          model = { default = "unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL" },
          temperature = { default = 0.7 },
          top_p = { default = 0.8 },
        },
      })
    end,
  },
  strategies = {
    chat   = { adapter = "llama" },
    inline = { adapter = "llama" },
  },
})
```

### Avante

```lua
require("avante").setup({
  provider = "openai",
  openai = {
    endpoint = "http://llama-cpp:8080/v1",
    model = "unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL",
    api_key_name = "DUMMY",  -- llama-server doesn't require a key
  },
})
```

> [!tip]
> Inline completion (ghost text) is a different workflow than chat — `minuet-ai.nvim` handles it well against an OpenAI-compatible backend.

## Obsidian Web Clipper

The Web Clipper extension's [Interpreter](https://obsidian.md/help/web-clipper/interpreter) feature lets clipped pages run through an LLM before landing in your vault. To use this stack:

### Add provider

| Field | Value |
|---|---|
| Name | `Local llama.cpp` |
| Base URL | `http://llama-cpp.tail5a0932.ts.net:8080/v1/chat/completions` |
| API key | `no-key` (the field is required; the value isn't validated server-side) |

> [!info] Use the FQDN, not the short name
> Browser extensions sometimes bypass the OS resolver (DNS-over-HTTPS, fetch-internal resolver, etc.), so MagicDNS short names can intermittently fail. The FQDN is a public DNS record and always resolves.

### Add model

| Field | Value |
|---|---|
| Provider | `Local llama.cpp` |
| Display name | `Qwen 3.6 27B` |
| Model ID | `unsloth/Qwen3.6-27B-GGUF:UD-Q4_K_XL` |

==The model ID is effectively a label — llama-server in single-model mode ignores the request's `model` field and serves whatever's currently loaded.==

### Recommended template settings

- **Context**: scope it. Default is the full page HTML (20k+ tokens of nav/footer); for most templates `{{selectorHtml:main, article, [role=main], #content}}` or `{{contentHtml|strip_tags}}` cuts that to 1–3k.
- **Prompts**: keep them terse and specific. `{{"one-line summary"}}` runs in seconds; vague longform prompts run in tens of seconds.
- **Formatting**: use filters (`|blockquote`, `|markdown_links`) instead of asking the model to format. Cheaper and more reliable.

A ready-made template lives at `clipper-templates/youtube-summary.json` — import it in Web Clipper settings → Templates → Import.

### Why reasoning is off

`model.vars` has `LLAMA_ARG_REASONING=off` specifically because Web Clipper / summarisation tasks don't benefit from chain-of-thought, and the latency tax is real. If you want thinking back on for a specific request (e.g., from CodeCompanion), send `"reasoning": "on"` in the JSON body — that overrides the server default per-request.

## Sharing with non-tailnet users (Funnel)

> [!danger]
> An unauthenticated llama-server on the public internet lets anyone with the URL burn your GPU and consume your bandwidth. Add `--api-key SOMETHING` (or `LLAMA_API_KEY` env) **before** enabling Funnel, and have clients send `Authorization: Bearer SOMETHING`.

If you really need it:

1. Admin console → DNS → enable **HTTPS Certificates**.
2. Flip `"AllowFunnel"` to `true` in the `serve.json` config inside `llm-service.yaml`.
3. Restart the stack. Tailscale provisions a cert and exposes `https://llama-cpp.tail5a0932.ts.net` on 443.
4. Verify only authenticated requests get past llama-server.

For your own travel use, plain Tailscale on the laptop is the correct answer — no Funnel needed.

## See also

- [[operations]] — running the stack, changing config
- [[troubleshooting]] — when something doesn't work
- [[README]] — system overview
