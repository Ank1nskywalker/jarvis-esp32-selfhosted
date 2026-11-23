# 02 · Server (Raspberry Pi + brain)

[← Back to README](../../README.md)

The device does **no AI itself** — it streams audio to a server and plays back the reply. That server is [`xiaozhi-esp32-server`](https://github.com/xinnan-tech/xiaozhi-esp32-server), which we run in Docker on a **Raspberry Pi 5**.

## Components

| Role | What we used | Notes |
|---|---|---|
| Orchestrator | `xiaozhi-esp32-server` (Docker) | WebSocket `:8000`, OTA/HTTP `:8003` |
| VAD | SileroVAD | voice-activity detection |
| ASR | **GroqASR** (Whisper large-v3-turbo) | very fast speech-to-text |
| LLM / brain | your own agent | any OpenAI-compatible `/v1` endpoint |
| TTS | EdgeTTS → **Fish Audio** | see [05-voice](05-voice.md) |
| Memory / Intent | `nomem` / `nointent` | `nointent` = no function-calling = lower latency |

> The **brain** is the one piece that's entirely yours. Ours runs on a VPS and is reached over a **Tailscale** private IP, so nothing is exposed to the internet. Any OpenAI-compatible endpoint works (a local Ollama, a hosted model, your own agent).

## Install (high level)

Follow the upstream deploy docs, then run the container. A typical run looks like:

```bash
docker run -d --name xiaozhi-esp32-server --restart unless-stopped \
  -p 8000:8000 -p 8003:8003 \
  -v $(pwd)/data:/opt/xiaozhi-esp32-server/data \
  <xiaozhi-server-image>
```

Key points we learned:
- Only `data/` is mounted; the **code lives inside the image**. That matters for the latency patch in [06-optimization](06-optimization.md).
- Your overrides go in **`data/.config.yaml`**, which merges on top of the image's base `config.yaml`. See [`config/config.yaml.example`](../../config/config.yaml.example).
- `--restart unless-stopped` keeps it alive across reboots.

## Configure

Copy [`config/config.yaml.example`](../../config/config.yaml.example) to `data/.config.yaml` and fill in your values:
- `selected_module` — pick VAD/ASR/LLM/TTS/Memory/Intent.
- `prompt` — the assistant's personality (ours is a Spanish-only "Jarvis").
- Provider blocks — Groq key, your LLM endpoint, TTS.

Apply changes with:
```bash
docker restart xiaozhi-esp32-server
docker logs -f --tail 30 xiaozhi-esp32-server   # watch it boot; Ctrl+C to stop
```

## Pointing the device at this server

The device discovers the server via its **OTA URL**. Two ways:
1. **Bake it into the firmware** (recommended, survives NVS wipes) — `CONFIG_OTA_URL` in `sdkconfig.defaults`. See [03-firmware](03-firmware.md).
2. Set it at runtime via the device's NVS / captive portal.

> After `docker restart`, the device's WebSocket drops and does **not** auto-reconnect — **RESET the device** so it re-runs OTA and reconnects.
