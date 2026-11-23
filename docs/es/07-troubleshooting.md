# 07 · Troubleshooting

[← Volver al README](../../README.es.md)

Cada pared que chocamos, y el arreglo.

| Síntoma | Causa | Fix |
|---|---|---|
| **El wake word nunca dispara / el mic parece muerto** | El AEC usa una entrada de 2 canales (mic + referencia), dejando a WakeNet sin señal | Poné `AUDIO_INPUT_REFERENCE false` en el `config.h` de la placa, recompilá → [03](03-firmware.md#el-fix-del-micrófono-aec) |
| **"Jarvis" solo dispara con acento inglés** | El modelo WN9 está entrenado con la "YÁR-vis" inglesa | Usá la pronunciación inglesa, o apoyate en el **touch-to-wake** → [03](03-firmware.md#touch-to-wake) |
| **El dispositivo no reconecta tras `docker restart`** | El WebSocket se cae y no reconecta solo | **Reseteá el dispositivo** para que rehaga OTA |
| **Se perdió el Wi-Fi tras flashear** | Un flasheo completo borra la NVS (Wi-Fi + OTA URL) | Reconectá por el portal cautivo `Xiaozhi-XXXX`; horneá `CONFIG_OTA_URL` para que igual encuentre el servidor → [03](03-firmware.md) |
| **Error de build: `cannot convert 'emote::EmoteDisplay*' to 'LcdDisplay*'`** | `EmoteDisplay` deriva del `Display` base, el miembro es `LcdDisplay*` | Cambiá el miembro a `Display* display_;` → [04](04-ojos-animados.md#un-fix-extra-importante) |
| **La primera respuesta ~5 s más lenta que el resto** | El lookup geo-IP `whois.pconline.com.cn` timeoutea (5 s), después cachea | Parcheá `get_ip_info` para que retorne temprano, dentro del contenedor → [06](06-optimizacion.md#el-asesino-oculto-de-5-segundos-whoispconlinecomcn) |
| **`get_weather ... HTTP 401` en los logs** | La API key de clima compartida/por defecto es inválida; con `nointent` no está en el camino de respuesta | Inofensivo, instantáneo — es ruido cosmético en el log, no latencia. Dejalo, o editá la config base dentro de la imagen |
| **`whois ... Read timed out` sigue apareciendo** | El patch de `get_ip_info` no tomó, o recrearon el contenedor | Reaplicá el patch y `docker restart` → [06](06-optimizacion.md) |
| **El heredoc/pegado se corta (prompt `>`)** | Pegados multilínea largos se truncan por SSH | `Ctrl+C`, y usá una forma de una línea con `sed`/`python3 -c` |
| **`esptool: No module named esptool`** | No está instalado para tu Python | `brew install esptool` (macOS) o `pip3 install esptool --break-system-packages` |
| **`scp ... Could not resolve hostname`** | El hostname local de la Pi no resuelve por DNS desde la Mac | Usá la IP de la Pi (`user@<IP_PI>`) o `<host>.local` por mDNS |
| **La pantalla está negra al arrancar** | Normal durante el boot temprano / antes del init de la UI | Esperá a que termine el boot; mirá el log serial con `scripts/esp32log.py` |

## Útil: mirar el log serial a través de los resets

La placa usa USB-CDC nativo, así que un RESET tira el puerto y `screen` muere. Usá el monitor auto-reconectable:

```bash
pip install pyserial
python3 scripts/esp32log.py            # auto-detecta el puerto, loguea a esp32_boot.log
```

## Útil: mirar el servidor durante una interacción

```bash
docker logs -f --tail 5 xiaozhi-esp32-server    # Ctrl+C para cortar
```

[← Volver al README](../../README.es.md)
