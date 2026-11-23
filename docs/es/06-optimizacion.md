# 06 · Optimización (latencia)

[← Volver al README](../../README.es.md)

Nuestras primeras respuestas tardaban ~5 s. Así las diagnosticamos y bajamos — y dónde está el piso.

## Medir primero

Mirá los logs con timestamp durante una interacción:

```bash
docker logs -f --tail 5 xiaozhi-esp32-server
# después RESET al dispositivo y hacé UNA pregunta
```

Leé las líneas clave:
| Línea del log | Significa |
|---|---|
| `conn - Headers` | dispositivo conectado |
| `识别文本` (texto reconocido) | ASR terminó |
| `大模型收到用户消息` (LLM recibió) | prompt enviado al cerebro |
| `发送第一段语音` (envía primer segmento) | **primer audio** — acá termina la espera |

## El asesino oculto de 5 segundos: `whois.pconline.com.cn`

**Síntoma:** la **primera** pregunta después de cada restart es ~5 s más lenta que el resto.
**Causa:** al conectar, el servidor resuelve la ciudad del cliente vía un servicio chino de geo-IP (`whois.pconline.com.cn`) para meter una ubicación en el prompt. Tu dispositivo está en una **IP privada de la LAN**, así que el lookup no tiene sentido y **se cuelga hasta su timeout de 5 s**. El resultado (vacío) queda cacheado en memoria, por eso las siguientes son rápidas — hasta que el próximo restart limpia el cache.

**Fix:** que el lookup devuelva al instante. El código está **horneado en la imagen Docker** (solo se monta `data/`), así que se parchea **dentro del contenedor**:

```bash
# confirmá la función y la ruta
docker exec xiaozhi-esp32-server grep -n "def get_ip_info" \
  /opt/xiaozhi-esp32-server/core/utils/util.py

# que retorne temprano (correr UNA sola vez)
docker exec xiaozhi-esp32-server sed -i \
  '/^def get_ip_info(ip_addr, logger):$/a\    return {}' \
  /opt/xiaozhi-esp32-server/core/utils/util.py

docker restart xiaozhi-esp32-server
```

Verificá:
```bash
docker exec xiaozhi-esp32-server sed -n '124,126p' \
  /opt/xiaozhi-esp32-server/core/utils/util.py
# ->  def get_ip_info(ip_addr, logger):
#         return {}
#         try:
```

> Esto sobrevive a `docker restart` pero se **pierde si recreás el contenedor** (ej. actualizar la imagen) — lo volvés a correr. El warning `whois ... Read timed out` desaparece del log cuando funciona.

## Streaming de TTS

Poné `streaming: true` en el bloque de Fish ([05-voz](05-voz.md)) para que el audio empiece a reproducirse antes. Menor pero gratis; volvé a `false` si alguna vez suena cortado.

## Lo que queda: el LLM

Tras lo anterior, una primera respuesta en frío es ~4 s, las "en caliente" menos. El desglose:

| Etapa | ~Tiempo | Palanca |
|---|---|---|
| ASR (Groq) | ~1 s | ya es rápido |
| **LLM (tu cerebro)** | **~3 s** | el cuello real |
| TTS (Fish) | ~0.5–1 s | streaming |

El "primera más lenta que el resto" que queda es el **cache de prompt del LLM** — la primera llamada procesa todo el prompt de sistema (cache miss); las siguientes reusan el prefijo cacheado. Se resetea en cada restart.

Para bajar de ~3 s:
1. **Respuestas más cortas** — endurecé el prompt (ej. "1 oración corta salvo que pidan más"). Menos generación = menos TTS.
2. **Un LLM más rápido** — el win grosso. Un modelo servido por Groq (ya usás Groq para ASR) devuelve los primeros tokens en bastante menos de un segundo. Es un cambio en tu *cerebro*, no en el servidor.

Para un asistente casero self-hosted, **~4 s en frío / más rápido en caliente es un resultado usable**; bajar más implica cambiar el LLM.

➡️ Siguiente: [07 · Troubleshooting](07-troubleshooting.md)
