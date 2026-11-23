#!/usr/bin/env bash
#
# apply_hud_theme.sh
# ------------------
# Cambia la cara del device de "ojos" al tema HUD / arc-reactor (Jarvis).
# Requiere que los .eaf ya esten en:
#   main/boards/waveshare/esp32-s3-touch-lcd-1.85c/emoji/
#     jarvis_idle.eaf  jarvis_listening.eaf  jarvis_thinking.eaf  jarvis_speaking.eaf
#
# Correr DESDE la raiz del firmware:   cd ~/xiaozhi-esp32 && bash apply_hud_theme.sh
#
set -euo pipefail

BOARD="main/boards/waveshare/esp32-s3-touch-lcd-1.85c"
EMOTE="$BOARD/assets/360_360/emote.json"
EMOJI="$BOARD/emoji"
CMAKE="main/CMakeLists.txt"

echo ">> Verificando archivos..."
for f in "$EMOTE" "$CMAKE"; do
  [ -f "$f" ] || { echo "ERROR: no encuentro $f  -- corre esto desde ~/xiaozhi-esp32"; exit 1; }
done
for e in jarvis_idle jarvis_listening jarvis_thinking jarvis_speaking; do
  [ -f "$EMOJI/$e.eaf" ] || { echo "ERROR: falta $EMOJI/$e.eaf  (convertí y copiá los 4 .eaf primero)"; exit 1; }
done

TS="$(date +%Y%m%d-%H%M%S)"; BK="_hud_backup_$TS"; mkdir -p "$BK"
cp "$EMOTE" "$BK/emote.json.bak"
cp "$CMAKE" "$BK/CMakeLists.txt.bak"
echo ">> Backup en $BK/"

# 1) Nuevo emote.json: mapea los estados al HUD
cat > "$EMOTE" <<'JSON'
[
    {"emote": "happy", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "laughing", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "funny", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "loving", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "embarrassed", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "confident", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "delicious", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "sad", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "crying", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "sleepy", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "silly", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "angry", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "surprised", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "shocked", "src": "jarvis_speaking.eaf", "loop": true, "fps": 20},
    {"emote": "thinking", "src": "jarvis_thinking.eaf", "loop": true, "fps": 20},
    {"emote": "winking", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "relaxed", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "confused", "src": "jarvis_thinking.eaf", "loop": true, "fps": 20},
    {"emote": "neutral", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "idle", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "robot_2", "src": "jarvis_idle.eaf", "loop": true, "fps": 20},
    {"emote": "low_battery", "src": "low_battery.eaf", "loop": false, "fps": 20},
    {"emote": "battery_connected", "src": "battery_connected.eaf", "loop": false, "fps": 20}
]
JSON
python3 -I -c "import json;json.load(open('$EMOTE'));print('   emote.json OK (JSON valido)')"

# 2) CMake: copiar TODO el dir emoji/ (incluye los jarvis_*.eaf), no solo las de bateria
python3 -I - "$CMAKE" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
new='        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/boards/${BOARD_DIR}/emoji/"\n             DESTINATION "${ESP_VOCAT_ASSETS_STAGING}/emoji_large")'
if 'boards/${BOARD_DIR}/emoji/"\n             DESTINATION' in s:
    print("   CMake: ya estaba (copia el dir completo)"); sys.exit(0)
old=('        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/boards/${BOARD_DIR}/emoji/low_battery.eaf"\n'
     '             DESTINATION "${ESP_VOCAT_ASSETS_STAGING}/emoji_large")\n'
     '        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/boards/${BOARD_DIR}/emoji/battery_connected.eaf"\n'
     '             DESTINATION "${ESP_VOCAT_ASSETS_STAGING}/emoji_large")')
assert s.count(old)==1, f"anchor CMake no encontrado ({s.count(old)}) -- tree distinto?"
s=s.replace(old,new)
io.open(p,"w",encoding="utf-8").write(s)
print("   CMake: ahora copia el dir emoji/ completo (bateria + jarvis)")
PY

echo ""
echo "=================================================================="
echo " LISTO. Ahora compila y flashea:"
echo ""
echo "   . ~/esp/esp-idf/export.sh"
echo "   idf.py build && idf.py merge-bin"
echo ""
echo " (restaurar: cp $BK/emote.json.bak $EMOTE ; cp $BK/CMakeLists.txt.bak $CMAKE)"
echo "=================================================================="
