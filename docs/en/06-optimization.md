# 06 · Optimization (latency)

[← Back to README](../../README.md)

Our first replies took ~5 s. Here's how we diagnosed and cut it — and where the floor is.

## Measure first

Watch timestamped logs during one interaction:

```bash
docker logs -f --tail 5 xiaozhi-esp32-server
# then RESET the device and ask ONE question
```

Read the key lines:
| Log line | Meaning |
|---|---|
| `conn - Headers` | device connected |
| `识别文本` (recognized text) | ASR finished |
| `大模型收到用户消息` (LLM received) | prompt sent to brain |
| `发送第一段语音` (sending first segment) | **first audio out** — the wait ends here |

## The hidden 5-second killer: `whois.pconline.com.cn`

**Symptom:** the **first** request after each restart is ~5 s slower than the rest.
**Cause:** on connect, the server resolves the client's city via a Chinese geo-IP service (`whois.pconline.com.cn`) to put a location in the prompt. Your device is on a **private LAN IP**, so the lookup is pointless and **hangs until its 5 s timeout**. The (empty) result is then cached in memory, so later requests are fast — until the next restart clears the cache.

**Fix:** make the lookup return instantly. The code is **baked into the Docker image** (only `data/` is mounted), so patch it **inside the container**:

```bash
# confirm the function & path
docker exec xiaozhi-esp32-server grep -n "def get_ip_info" \
  /opt/xiaozhi-esp32-server/core/utils/util.py

# make it return early (run ONCE)
docker exec xiaozhi-esp32-server sed -i \
  '/^def get_ip_info(ip_addr, logger):$/a\    return {}' \
  /opt/xiaozhi-esp32-server/core/utils/util.py

docker restart xiaozhi-esp32-server
```

Verify:
```bash
docker exec xiaozhi-esp32-server sed -n '124,126p' \
  /opt/xiaozhi-esp32-server/core/utils/util.py
# ->  def get_ip_info(ip_addr, logger):
#         return {}
#         try:
```

> This survives `docker restart` but is **lost if you recreate the container** (e.g. image upgrade) — just re-run it. The `whois ... Read timed out` warning disappears from the logs when it works.

## TTS streaming

Set `streaming: true` in the Fish block ([05-voice](05-voice.md)) so audio starts playing sooner. Minor but free; revert to `false` if it ever sounds chopped.

## What's left: the LLM

After the above, a cold first reply is ~4 s, warm replies less. The breakdown:

| Stage | ~Time | Lever |
|---|---|---|
| ASR (Groq) | ~1 s | already fast |
| **LLM (your brain)** | **~3 s** | the real bottleneck |
| TTS (Fish) | ~0.5–1 s | streaming |

The "first slower than the rest" that remains is **LLM prompt caching** — the first call processes the whole system prompt (cache miss); later calls reuse the cached prefix. It resets each restart.

To push below ~3 s:
1. **Shorter replies** — tighten the prompt (e.g. "1 short sentence unless asked for more"). Less generation = less TTS.
2. **A faster LLM** — the big win. A Groq-hosted model (you already use Groq for ASR) returns first tokens in well under a second. This is a change to your *brain*, not the server.

For a self-hosted home assistant, **~4 s cold / faster warm is a usable result**; going lower means swapping the LLM.

➡️ Next: [07 · Troubleshooting](07-troubleshooting.md)
