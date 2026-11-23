# 05 · Voice (TTS)

[← Back to README](../../README.md)

The server has 15+ TTS providers. We went from **EdgeTTS** (free) to **Fish Audio** (premium, pick any voice).

## Option A — EdgeTTS (free, zero setup)

Great for getting started. A solid Rioplatense option:

```yaml
selected_module:
  TTS: EdgeTTS
TTS:
  EdgeTTS:
    type: edge
    voice: es-AR-TomasNeural
    rate: "15"          # a bit faster; EdgeTTS Tomas is a little slow by default
```

Male Argentine voices on EdgeTTS are limited (basically Tomas). If you want more choice or a specific character, use Fish Audio.

## Option B — Fish Audio (premium, any voice)

The server's **`fishspeech`** provider already speaks the Fish Audio **cloud** protocol (msgpack, Bearer auth, `reference_id`). You just point it at the cloud:

```yaml
selected_module:
  TTS: FishSpeech
TTS:
  FishSpeech:
    type: fishspeech
    api_url: https://api.fish.audio/v1/tts
    api_key: <YOUR_FISH_API_KEY>
    reference_id: <YOUR_FISH_VOICE_ID>
    response_format: mp3
    reference_audio: []     # empty -> use the voice model, not a reference clip
    reference_text: []
    streaming: true
```

### Choosing a voice

1. Browse voices at <https://fish.audio> (search `español`, `latino`, `argentino`, etc.).
2. **Preview it in the browser** before committing.
3. The voice's **model ID is in its URL**: `fish.audio/m/<reference_id>`. Copy that into `reference_id`.

Example voices we tried (public):
- `9427e10242274460bba061aa6a4b8df7` — a community "Jarvis (Español latino)" voice.
- `664e713e3a22478f904720e9ecb5aaee` — the one we settled on.

> The real movie-JARVIS voice is **not** for sale (rights). These are community voices that evoke the style.

### Getting the API key

- Create a **free** account at fish.audio. The subscription plans (Free/Plus/Pro) are for the **web app**; the **API is separate, pay-as-you-go**.
- Go to **Developer → API Keys → Create API Key**, copy the secret (shown once).
- Add a small **balance** under **Billing** (a few dollars lasts months at home-assistant volume).
- Ignore the "Agent" per-minute product — that's a full voice-agent pipeline you don't need; you only want the raw **TTS API**.

### Cost reality (home assistant)

- API price: **$15 per 1M UTF-8 bytes** (≈ `$1` buys ~48 min of audio / hundreds of replies).
- A home assistant generates only a few minutes of audio/day → realistically **~$3–8/month**, or free-tier for light testing.
- (Beware: naive "$/month" tables that forget to multiply by days — a few minutes **per day** is ~30× a one-off few minutes.)

## Picking: Fish vs ElevenLabs (why Fish, for this build)

- **Native support**: the server has a `fishspeech` provider, **no ElevenLabs** provider — Fish is plug-and-play, ElevenLabs would need custom code.
- **Price**: Fish is ~4–11× cheaper on the API.
- **Quality**: roughly on par in blind tests.
- **Self-host escape hatch**: Fish is open-weight (run it on your own GPU later); ElevenLabs is cloud-only.

➡️ Next: [06 · Optimization](06-optimization.md)
