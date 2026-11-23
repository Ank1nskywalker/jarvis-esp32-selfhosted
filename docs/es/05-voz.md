# 05 · Voz (TTS)

[← Volver al README](../../README.es.md)

El servidor tiene 15+ proveedores de TTS. Nosotros pasamos de **EdgeTTS** (gratis) a **Fish Audio** (premium, elegís la voz).

## Opción A — EdgeTTS (gratis, cero setup)

Genial para empezar. Una opción rioplatense sólida:

```yaml
selected_module:
  TTS: EdgeTTS
TTS:
  EdgeTTS:
    type: edge
    voice: es-AR-TomasNeural
    rate: "15"          # un poco más rápido; Tomas por defecto es medio pausado
```

Las voces masculinas argentinas en EdgeTTS son limitadas (básicamente Tomas). Si querés más opciones o un personaje específico, usá Fish Audio.

## Opción B — Fish Audio (premium, cualquier voz)

El proveedor **`fishspeech`** del servidor ya habla el protocolo de la **nube** de Fish Audio (msgpack, auth Bearer, `reference_id`). Solo lo apuntás a la nube:

```yaml
selected_module:
  TTS: FishSpeech
TTS:
  FishSpeech:
    type: fishspeech
    api_url: https://api.fish.audio/v1/tts
    api_key: <TU_FISH_API_KEY>
    reference_id: <TU_FISH_VOICE_ID>
    response_format: mp3
    reference_audio: []     # vacío -> usa el modelo de voz, no un clip de referencia
    reference_text: []
    streaming: true
```

### Elegir una voz

1. Explorá voces en <https://fish.audio> (buscá `español`, `latino`, `argentino`, etc.).
2. **Probala en el navegador** antes de decidir.
3. El **ID del modelo está en la URL**: `fish.audio/m/<reference_id>`. Copiá eso en `reference_id`.

Voces que probamos (públicas):
- `9427e10242274460bba061aa6a4b8df7` — una voz comunitaria "Jarvis (Español latino)".
- `664e713e3a22478f904720e9ecb5aaee` — la que elegimos finalmente.

> La voz real del JARVIS de la película **no** está a la venta (derechos). Estas son voces comunitarias que evocan el estilo.

### Sacar la API key

- Creá una cuenta **gratis** en fish.audio. Los planes de suscripción (Free/Plus/Pro) son para la **app web**; la **API es aparte, pay-as-you-go**.
- Andá a **Developer → API Keys → Create API Key**, copiá el secret (se muestra una vez).
- Cargá un **saldo** chico en **Billing** (unos dólares duran meses a volumen de asistente casero).
- Ignorá el producto "Agente" por minuto — es un pipeline de voz completo que no necesitás; vos solo querés la **API de TTS** cruda.

### Realidad del costo (asistente casero)

- Precio API: **$15 por 1M de bytes UTF-8** (≈ `$1` compra ~48 min de audio / cientos de respuestas).
- Un asistente casero genera solo unos minutos de audio/día → realista **~$3–8/mes**, o el free-tier para pruebas livianas.
- (Ojo con las tablas de "$/mes" que se olvidan de multiplicar por los días — unos minutos **por día** es ~30× unos minutos una sola vez.)

## Elegir: Fish vs ElevenLabs (por qué Fish, para este build)

- **Soporte nativo**: el servidor tiene proveedor `fishspeech`, **no** tiene ElevenLabs — Fish es enchufar y listo, ElevenLabs necesitaría código custom.
- **Precio**: Fish es ~4–11× más barato en la API.
- **Calidad**: prácticamente a la par en tests ciegos.
- **Escape self-host**: Fish es open-weight (lo corrés en tu propia GPU más adelante); ElevenLabs es solo nube.

➡️ Siguiente: [06 · Optimización](06-optimizacion.md)
