# 07 · Troubleshooting

[← Back to README](../../README.md)

Every wall we hit, and the fix.

| Symptom | Cause | Fix |
|---|---|---|
| **Wake word never triggers / mic seems dead** | AEC uses a 2-ch mic+reference input, starving WakeNet | Set `AUDIO_INPUT_REFERENCE false` in the board `config.h`, rebuild → [03](03-firmware.md#the-microphone-fix-aec) |
| **"Jarvis" only triggers with an English accent** | The WN9 model is trained on English "JAR-vis" | Use the English pronunciation, or rely on **touch-to-wake** → [03](03-firmware.md#touch-to-wake) |
| **Device won't reconnect after `docker restart`** | The WebSocket drops and doesn't auto-reconnect | **RESET the device** so it re-runs OTA |
| **Wi-Fi gone after flashing** | A full flash wipes NVS (Wi-Fi + OTA URL) | Reconnect via the `Xiaozhi-XXXX` captive portal; bake `CONFIG_OTA_URL` so it still finds the server → [03](03-firmware.md) |
| **Build error: `cannot convert 'emote::EmoteDisplay*' to 'LcdDisplay*'`** | `EmoteDisplay` derives from base `Display`, member is typed `LcdDisplay*` | Change the member to `Display* display_;` → [04](04-animated-eyes.md#one-extra-fix-important) |
| **First reply ~5 s slower than the rest** | `whois.pconline.com.cn` geo-IP lookup times out (5 s), then caches | Patch `get_ip_info` to return early, inside the container → [06](06-optimization.md#the-hidden-5-second-killer-whoispconlinecomcn) |
| **`get_weather ... HTTP 401` in logs** | Shared/default weather API key is invalid; under `nointent` it's not in the response path | Harmless, instant — it's cosmetic log noise, not latency. Leave it, or edit the base config inside the image |
| **`whois ... Read timed out` keeps appearing** | The `get_ip_info` patch didn't take, or the container was recreated | Re-apply the patch and `docker restart` → [06](06-optimization.md) |
| **Heredoc/paste gets cut off (`>` prompt)** | Long multi-line pastes truncate over SSH | `Ctrl+C`, then use a single-line `sed`/`python3 -c` form instead |
| **`esptool: No module named esptool`** | Not installed for your Python | `brew install esptool` (macOS) or `pip3 install esptool --break-system-packages` |
| **`scp ... Could not resolve hostname`** | The Pi's local hostname isn't DNS-resolvable from your Mac | Use the Pi's IP (`user@<PI_IP>`) or `<host>.local` via mDNS |
| **Screen is black on boot** | Normal during early boot / before UI init | Wait for boot to finish; check the serial log with `scripts/esp32log.py` |

## Handy: watch the serial log across resets

The board uses native USB-CDC, so a RESET drops the port and `screen` dies. Use the auto-reconnecting monitor:

```bash
pip install pyserial
python3 scripts/esp32log.py            # auto-detects the port, logs to esp32_boot.log
```

## Handy: watch the server across one interaction

```bash
docker logs -f --tail 5 xiaozhi-esp32-server    # Ctrl+C to stop
```

[← Back to README](../../README.md)
