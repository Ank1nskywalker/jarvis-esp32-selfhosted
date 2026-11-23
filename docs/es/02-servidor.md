# 02 · Servidor (Raspberry Pi + cerebro)

[← Volver al README](../../README.es.md)

El dispositivo **no hace IA por sí mismo** — manda el audio a un servidor y reproduce la respuesta. Ese servidor es [`xiaozhi-esp32-server`](https://github.com/xinnan-tech/xiaozhi-esp32-server), que corremos en Docker en una **Raspberry Pi 5**.

## Componentes

| Rol | Qué usamos | Notas |
|---|---|---|
| Orquestador | `xiaozhi-esp32-server` (Docker) | WebSocket `:8000`, OTA/HTTP `:8003` |
| VAD | SileroVAD | detección de actividad de voz |
| ASR | **GroqASR** (Whisper large-v3-turbo) | speech-to-text muy rápido |
| LLM / cerebro | tu propio agente | cualquier endpoint `/v1` compatible con OpenAI |
| TTS | EdgeTTS → **Fish Audio** | ver [05-voz](05-voz.md) |
| Memory / Intent | `nomem` / `nointent` | `nointent` = sin function-calling = menos latencia |

> El **cerebro** es la única pieza 100% tuya. El nuestro corre en un VPS y se accede por una IP privada de **Tailscale**, así que nada queda expuesto a internet. Sirve cualquier endpoint compatible con OpenAI (un Ollama local, un modelo hosteado, tu propio agente).

## Instalación (a grandes rasgos)

Seguí la doc de deploy del proyecto y después corré el contenedor. Un run típico:

```bash
docker run -d --name xiaozhi-esp32-server --restart unless-stopped \
  -p 8000:8000 -p 8003:8003 \
  -v $(pwd)/data:/opt/xiaozhi-esp32-server/data \
  <imagen-xiaozhi-server>
```

Lo que aprendimos:
- Solo se monta `data/`; el **código vive dentro de la imagen**. Eso importa para el patch de latencia en [06-optimizacion](06-optimizacion.md).
- Tus overrides van en **`data/.config.yaml`**, que se mergea sobre el `config.yaml` base de la imagen. Ver [`config/config.yaml.example`](../../config/config.yaml.example).
- `--restart unless-stopped` lo mantiene vivo entre reinicios.

## Configurar

Copiá [`config/config.yaml.example`](../../config/config.yaml.example) a `data/.config.yaml` y completá tus valores:
- `selected_module` — elegí VAD/ASR/LLM/TTS/Memory/Intent.
- `prompt` — la personalidad del asistente (el nuestro es un "Jarvis" solo en español).
- Bloques de proveedores — key de Groq, tu endpoint LLM, TTS.

Aplicá cambios con:
```bash
docker restart xiaozhi-esp32-server
docker logs -f --tail 30 xiaozhi-esp32-server   # mirá cómo bootea; Ctrl+C para cortar
```

## Apuntar el dispositivo a este servidor

El dispositivo descubre el servidor por su **OTA URL**. Dos formas:
1. **Hornearla en el firmware** (recomendado, sobrevive al wipe de NVS) — `CONFIG_OTA_URL` en `sdkconfig.defaults`. Ver [03-firmware](03-firmware.md).
2. Setearla en runtime vía la NVS / portal cautivo del dispositivo.

> Después de `docker restart`, el WebSocket del dispositivo se cae y **no** reconecta solo — **reseteá el dispositivo** para que vuelva a hacer OTA y reconecte.
