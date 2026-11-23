# 01 · Hardware

[← Volver al README](../../README.es.md)

## La placa

**Waveshare ESP32-S3-Touch-LCD-1.85C-BOX (V2)** — un kit de desarrollo tipo parlante inteligente con pantalla redonda, ideal para un asistente de voz de escritorio.

Página del producto: <https://www.waveshare.com/esp32-s3-touch-lcd-1.85c.htm>

### Specs clave

| Componente | Detalle |
|---|---|
| MCU | ESP32-S3R8 (doble núcleo, Wi-Fi + BLE) |
| PSRAM | 8 MB octal |
| Flash | 16 MB |
| Pantalla | 1.85" redonda **360×360** ST77916, QSPI |
| Touch | CST816 capacitivo (INT en **GPIO4**) |
| Audio out | DAC ES8311 + parlante |
| Audio in | ADC ES7210 de 4 canales + **dos micrófonos analógicos** (soldados) |
| Expansor IO | TCA9554 |
| Botones | BOOT en **GPIO0** |

### Pinout que usa el firmware (referencia)

```
BOOT_BUTTON_GPIO = GPIO_NUM_0
TP_PIN_NUM_INT   = GPIO_NUM_4     # interrupción del touch (usado para touch-to-wake)
AUDIO_I2S_MCLK   = 2
AUDIO_I2S_BCLK   = 48
AUDIO_I2S_WS     = 38
AUDIO_I2S_DIN    = 39
AUDIO_I2S_DOUT   = 47
PA_PIN           = 15
I2C_SCL = 10 / I2C_SDA = 11
```

## Qué necesitás

- La placa Waveshare de arriba (trae micrófonos, parlante y batería).
- Un **cable USB-C** para flashear (con datos, no solo carga).
- Una **computadora** para flashear (macOS/Linux/Windows). La placa se enumera como **USB-CDC** nativo.
- Una **Raspberry Pi** (usamos una Pi 5) — o cualquier Linux siempre encendido — para el servidor. Ver [02-servidor](02-servidor.md).
- Opcional: un **VPS** si tu "cerebro" / LLM corre afuera; un túnel [Tailscale](https://tailscale.com/) lo mantiene privado.

## Nota sobre el micrófono "roto"

De fábrica podés concluir que el mic está muerto — el wake word nunca dispara. **Casi seguro NO está roto.** En esta placa el firmware por defecto activa cancelación de eco (AEC) con una entrada de 2 canales (mic + referencia), que deja a WakeNet sin la señal limpia del mic. Un solo flag lo arregla — ver [03-firmware → El fix del micrófono](03-firmware.md#el-fix-del-micrófono-aec). Casi hacemos una RMA al pedo.
