# 03 · Firmware (build, mic fix, wake word, touch-to-wake)

[← Back to README](../../README.md)

Firmware is [`xiaozhi-esp32`](https://github.com/78/xiaozhi-esp32) (PROJECT_VER 2.6.0), built with **ESP-IDF v6.x**.

> We build **on the Raspberry Pi** (open network) and flash from the Mac, because the Pi can reach the Espressif component registry while some sandboxes can't. Any machine with ESP-IDF works.

## Toolchain

```bash
# one-time: install ESP-IDF v6.x, then per-shell:
. ~/esp/esp-idf/export.sh
```

## Build & flash cycle

```bash
cd ~/xiaozhi-esp32
idf.py build && idf.py merge-bin      # output: build/merged-binary.bin
```

Flash the single merged image at `0x0` (device connected by USB to the Mac):

```bash
# find the port
ls /dev/cu.usb*
# flash (esptool: brew install esptool)
esptool --chip esp32s3 -b 460800 --before default-reset --after hard-reset \
  write-flash 0x0 merged-binary.bin
```

> **A full flash wipes NVS**, which erases Wi-Fi *and* the saved OTA URL. After every full flash, reconnect Wi-Fi via the **`Xiaozhi-XXXX` captive portal**. Baking `CONFIG_OTA_URL` into the firmware (below) means it still finds your server afterwards.

See [`config/sdkconfig.defaults.example`](../../config/sdkconfig.defaults.example) for all the lines referenced here. After editing `sdkconfig.defaults`, regenerate config:

```bash
rm -f sdkconfig && idf.py build
```

---

## The microphone fix (AEC)

**Symptom:** wake word never triggers; mic seems dead.
**Cause:** `AUDIO_INPUT_REFERENCE = true` turns on AEC with a 2-channel (mic + reference) input. WakeNet then never sees a clean mic signal.
**Fix:** in the board config, set it to **false** (1-channel mic → VAD → WakeNet):

```c
// main/boards/waveshare/esp32-s3-touch-lcd-1.85c/config.h
#define AUDIO_INPUT_REFERENCE false   // was true
```

After rebuilding, the boot log shows the pipeline change to `[input] -> VAD -> WakeNet` and `1 microphone, 0 playback`. The mic was fine all along.

---

## Wake word "Jarvis"

Enable AFE wake word + the pre-trained **WN9 "Jarvis"** model in `sdkconfig.defaults`:

```ini
CONFIG_USE_AFE_WAKE_WORD=y
CONFIG_SR_WN_WN9_JARVIS_TTS=y
# CONFIG_SR_WN_WN9_NIHAOXIAOZHI_TTS is not set
```

> **Pronunciation gotcha:** the "Jarvis" model is trained on the **English** pronunciation (≈ "JAR-vis" with a hard English J). A Spanish "YAR-vis" won't trigger it reliably. That's exactly why we added **touch-to-wake** (below) as a backup.

---

## Point the device at your server (baked OTA URL)

So the device still finds your Pi after an NVS wipe:

```ini
CONFIG_OTA_URL="http://<YOUR_PI_IP>:8003/xiaozhi/ota/"
```

---

## Touch-to-wake

The English "Jarvis" is awkward to say for a Spanish speaker, so we added **tap-the-screen-to-wake** using the CST816 touch interrupt on **GPIO4**.

The change (in `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/esp32-s3-touch-lcd-1.85c.cc`):
- Add includes: `driver/gpio.h`, FreeRTOS `semphr.h`/`task.h`.
- Add a `TouchWakeTask` that waits on a semaphore, debounces ~800 ms, and calls `Application::GetInstance().ToggleChatState()` (unless the device is still starting).
- Add `InitializeTouchWake()` that configures **GPIO4** as a NEGEDGE interrupt (pull-up), installs the ISR service, and starts the task. A tiny non-capturing ISR lambda gives the semaphore.
- Call `InitializeTouchWake();` in the constructor, right after `InitializeButtons();`.

After flashing, a tap on the round screen wakes the assistant — a reliable backup when the wake word is hard to pronounce.

---

## Result

A build that: connects to **your** server, wakes on **"Jarvis"** *or* a **tap**, stays dormant otherwise, and (next doc) shows **animated eyes**.

➡️ Next: [04 · Animated eyes](04-animated-eyes.md)
