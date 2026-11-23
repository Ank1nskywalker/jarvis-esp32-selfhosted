# 03 · Firmware (compilar, fix del mic, wake word, touch-to-wake)

[← Volver al README](../../README.es.md)

El firmware es [`xiaozhi-esp32`](https://github.com/78/xiaozhi-esp32) (PROJECT_VER 2.6.0), compilado con **ESP-IDF v6.x**.

> Nosotros compilamos **en la Raspberry Pi** (red abierta) y flasheamos desde la Mac, porque la Pi llega al registro de componentes de Espressif y algunos entornos no. Cualquier máquina con ESP-IDF sirve.

## Toolchain

```bash
# una vez: instalá ESP-IDF v6.x, después por cada shell:
. ~/esp/esp-idf/export.sh
```

## Ciclo compilar y flashear

```bash
cd ~/xiaozhi-esp32
idf.py build && idf.py merge-bin      # salida: build/merged-binary.bin
```

Flasheá la imagen combinada en `0x0` (dispositivo conectado por USB a la Mac):

```bash
# buscá el puerto
ls /dev/cu.usb*
# flasheá (esptool: brew install esptool)
esptool --chip esp32s3 -b 460800 --before default-reset --after hard-reset \
  write-flash 0x0 merged-binary.bin
```

> **Un flasheo completo borra la NVS**, lo que elimina el Wi-Fi *y* la OTA URL guardada. Después de cada flasheo completo, reconectá el Wi-Fi por el **portal cautivo `Xiaozhi-XXXX`**. Hornear `CONFIG_OTA_URL` en el firmware (abajo) hace que igual encuentre tu servidor.

Ver [`config/sdkconfig.defaults.example`](../../config/sdkconfig.defaults.example) para todas las líneas que se mencionan acá. Después de editar `sdkconfig.defaults`, regenerá la config:

```bash
rm -f sdkconfig && idf.py build
```

---

## El fix del micrófono (AEC)

**Síntoma:** el wake word nunca dispara; el mic parece muerto.
**Causa:** `AUDIO_INPUT_REFERENCE = true` prende el AEC con una entrada de 2 canales (mic + referencia). WakeNet nunca ve una señal limpia del mic.
**Fix:** en la config de la placa, ponelo en **false** (mic de 1 canal → VAD → WakeNet):

```c
// main/boards/waveshare/esp32-s3-touch-lcd-1.85c/config.h
#define AUDIO_INPUT_REFERENCE false   // era true
```

Tras recompilar, el log de boot muestra el pipeline cambiado a `[input] -> VAD -> WakeNet` y `1 microphone, 0 playback`. El mic siempre estuvo bien.

---

## Wake word "Jarvis"

Activá el AFE wake word + el modelo pre-entrenado **WN9 "Jarvis"** en `sdkconfig.defaults`:

```ini
CONFIG_USE_AFE_WAKE_WORD=y
CONFIG_SR_WN_WN9_JARVIS_TTS=y
# CONFIG_SR_WN_WN9_NIHAOXIAOZHI_TTS is not set
```

> **Detalle de pronunciación:** el modelo "Jarvis" está entrenado con la pronunciación **inglesa** (≈ "YÁR-vis" con J inglesa fuerte). Un "YARVIS" en español no lo dispara confiable. Por eso agregamos el **touch-to-wake** (abajo) como respaldo.

---

## Apuntar el dispositivo a tu servidor (OTA URL horneada)

Para que el dispositivo igual encuentre tu Pi tras un wipe de NVS:

```ini
CONFIG_OTA_URL="http://<IP_DE_TU_PI>:8003/xiaozhi/ota/"
```

---

## Touch-to-wake

La "Jarvis" inglesa cuesta decirla, así que agregamos **tocar la pantalla para despertar** usando la interrupción del touch CST816 en **GPIO4**.

El cambio (en `main/boards/waveshare/esp32-s3-touch-lcd-1.85c/esp32-s3-touch-lcd-1.85c.cc`):
- Agregar includes: `driver/gpio.h`, FreeRTOS `semphr.h`/`task.h`.
- Agregar una `TouchWakeTask` que espera en un semáforo, hace debounce ~800 ms y llama a `Application::GetInstance().ToggleChatState()` (salvo que el dispositivo esté arrancando).
- Agregar `InitializeTouchWake()` que configura **GPIO4** como interrupción NEGEDGE (pull-up), instala el ISR service y arranca la task. Un pequeño lambda ISR (no capturante) da el semáforo.
- Llamar `InitializeTouchWake();` en el constructor, justo después de `InitializeButtons();`.

Tras flashear, un toque en la pantalla redonda despierta el asistente — un respaldo confiable cuando el wake word cuesta pronunciar.

---

## Resultado

Un build que: conecta a **tu** servidor, despierta con **"Jarvis"** *o* con un **toque**, queda dormido el resto del tiempo y (próximo doc) muestra **ojos animados**.

➡️ Siguiente: [04 · Ojos animados](04-ojos-animados.md)
