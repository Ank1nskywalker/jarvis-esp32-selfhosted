# 01 · Hardware

[← Back to README](../../README.md)

## The board

**Waveshare ESP32-S3-Touch-LCD-1.85C-BOX (V2)** — a round-screen smart-speaker dev kit, well suited to a desktop voice assistant.

Product page: <https://www.waveshare.com/esp32-s3-touch-lcd-1.85c.htm>

### Key specs

| Component | Detail |
|---|---|
| MCU | ESP32-S3R8 (dual-core, Wi-Fi + BLE) |
| PSRAM | 8 MB octal |
| Flash | 16 MB |
| Display | 1.85" round **360×360** ST77916, QSPI |
| Touch | CST816 capacitive (INT on **GPIO4**) |
| Audio out | ES8311 DAC + speaker |
| Audio in | ES7210 4-channel ADC + **two analog mics** (soldered) |
| IO expander | TCA9554 |
| Buttons | BOOT on **GPIO0** |

### Pinout used by the firmware (for reference)

```
BOOT_BUTTON_GPIO = GPIO_NUM_0
TP_PIN_NUM_INT   = GPIO_NUM_4     # touch interrupt (used for touch-to-wake)
AUDIO_I2S_MCLK   = 2
AUDIO_I2S_BCLK   = 48
AUDIO_I2S_WS     = 38
AUDIO_I2S_DIN    = 39
AUDIO_I2S_DOUT   = 47
PA_PIN           = 15
I2C_SCL = 10 / I2C_SDA = 11
```

## What you need

- The Waveshare board above (with built-in mics, speaker and battery).
- A **USB-C cable** for flashing (data-capable, not charge-only).
- A **computer** to flash from (macOS/Linux/Windows). The board enumerates as native **USB-CDC**.
- A **Raspberry Pi** (we used a Pi 5) — or any always-on Linux box — to run the server. See [02-server](02-server.md).
- Optional: a **VPS** if your "brain" / LLM runs off-site; a [Tailscale](https://tailscale.com/) tunnel keeps it private.

## A note on the "broken" microphone

Out of the box you may conclude the mic is dead — the wake word never triggers. **It almost certainly isn't broken.** On this board the default firmware enables acoustic echo cancellation (AEC) using a 2-channel mic+reference input, which starves WakeNet of the plain mic signal. One flag fixes it — see [03-firmware → The microphone fix](03-firmware.md#the-microphone-fix-aec). We nearly filed an RMA for nothing.
