#!/usr/bin/env bash
#
# apply_emote_eyes.sh
# -------------------
# Habilita los "ojos animados" (EmoteDisplay) en la Waveshare ESP32-S3-Touch-LCD-1.85C,
# calcando lo que la placa esp-vocat (del mismo arbol xiaozhi-esp32) ya hace.
#
# Correr DESDE la raiz del firmware en la Pi:   cd ~/xiaozhi-esp32 && bash apply_emote_eyes.sh
#
# No baja nada: los .eaf de los ojos los trae el componente esp_emote_assets al compilar,
# y los .eaf de bateria los copia de la propia esp-vocat de tu arbol.
#
set -euo pipefail

ROOT="$(pwd)"
BOARD="main/boards/waveshare/esp32-s3-touch-lcd-1.85c"
VOCAT="main/boards/espressif/esp-vocat"
CC="$BOARD/esp32-s3-touch-lcd-1.85c.cc"
KCONFIG="main/Kconfig.projbuild"
CMAKE="main/CMakeLists.txt"
CONFJSON="$BOARD/config.json"
SDKDEF="sdkconfig.defaults"

echo ">> Verificando que estamos en la raiz del firmware..."
for f in "$CC" "$KCONFIG" "$CMAKE" "$CONFJSON" "$SDKDEF" "$VOCAT/emoji/low_battery.eaf"; do
  [ -f "$f" ] || { echo "ERROR: no encuentro $f  -- corre esto desde ~/xiaozhi-esp32"; exit 1; }
done

TS="$(date +%Y%m%d-%H%M%S)"
BK="_emote_backup_$TS"
mkdir -p "$BK"
echo ">> Backup de archivos a editar en: $BK/"
for f in "$CC" "$KCONFIG" "$CMAKE" "$CONFJSON" "$SDKDEF"; do
  mkdir -p "$BK/$(dirname "$f")"; cp "$f" "$BK/$f"
done

# ---------- edits de texto, precisos e idempotentes (Python) ----------
python3 -I - "$CC" "$KCONFIG" "$CMAKE" "$CONFJSON" "$SDKDEF" <<'PYEOF'
import io, sys, json
cc, kconfig, cmake, confjson, sdkdef = sys.argv[1:6]

def read(p):
    with io.open(p, encoding="utf-8") as f: return f.read()
def write(p, s):
    with io.open(p, "w", encoding="utf-8") as f: f.write(s)
def must(cond, msg):
    if not cond: sys.exit("ERROR: " + msg)

# ---- A) Kconfig: sumar la 1.85c al depends de USE_EMOTE_MESSAGE_STYLE ----
k = read(kconfig)
if "BOARD_TYPE_WAVESHARE_ESP32_S3_TOUCH_LCD_1_85C" not in k.split("config USE_EMOTE_MESSAGE_STYLE")[1].split("endchoice")[0]:
    anchor = "            || BOARD_TYPE_ESP_SENSAIRSHUTTLE || BOARD_TYPE_STACKCHAN"
    must(k.count(anchor) == 1, "anchor Kconfig depends no encontrado (tree distinto?)")
    k = k.replace(anchor, anchor + " \\\n            || BOARD_TYPE_WAVESHARE_ESP32_S3_TOUCH_LCD_1_85C")
    write(kconfig, k); print("[A] Kconfig: 1.85c agregada al depends de USE_EMOTE_MESSAGE_STYLE")
else:
    print("[A] Kconfig: ya estaba")

# ---- B) board .cc: include guardado de emote_display.h ----
c = read(cc)
if '#include "display/emote_display.h"' not in c:
    anchor = '#include "display/lcd_display.h"'
    must(c.count(anchor) == 1, "anchor include lcd_display.h no encontrado")
    c = c.replace(anchor,
        anchor + '\n#if CONFIG_USE_EMOTE_MESSAGE_STYLE\n#include "display/emote_display.h"\n#endif')
    print("[B] board.cc: include emote_display.h agregado")
else:
    print("[B] board.cc: include ya estaba")

# ---- C) board .cc: instanciar EmoteDisplay en vez de SpiLcdDisplay ----
if "new emote::EmoteDisplay(" not in c:
    old = ('        display_ = new SpiLcdDisplay(panel_io, panel,\n'
           '                                    DISPLAY_WIDTH, DISPLAY_HEIGHT, DISPLAY_OFFSET_X, DISPLAY_OFFSET_Y, DISPLAY_MIRROR_X, DISPLAY_MIRROR_Y, DISPLAY_SWAP_XY);')
    must(c.count(old) == 1, "anchor SpiLcdDisplay no encontrado (revisar el .cc)")
    new = ('#if CONFIG_USE_EMOTE_MESSAGE_STYLE\n'
           '        display_ = new emote::EmoteDisplay(panel, panel_io, DISPLAY_WIDTH, DISPLAY_HEIGHT);\n'
           '#else\n' + old + '\n#endif')
    c = c.replace(old, new)
    print("[C] board.cc: branch EmoteDisplay/SpiLcdDisplay agregado")
else:
    print("[C] board.cc: EmoteDisplay ya estaba")
write(cc, c)

# ---- D) CMake: setear EMOTE_RESOLUTION/staging/external path en la rama de la 1.85c ----
m = read(cmake)
if 'set(EMOTE_RESOLUTION "360_360")' not in m.split("WAVESHARE_ESP32_S3_TOUCH_LCD_1_85C)")[1].split("elseif")[0]:
    anchor = ('elseif(CONFIG_BOARD_TYPE_WAVESHARE_ESP32_S3_TOUCH_LCD_1_85C)\n'
              '    set(BOARD_DIR "waveshare/esp32-s3-touch-lcd-1.85c")\n'
              '    set(BUILTIN_TEXT_FONT font_noto_sans_basic_16_4)\n'
              '    set(BUILTIN_ICON_FONT font_material_symbols_16_4)\n'
              '    set(DEFAULT_EMOJI_COLLECTION noto-color-emoji_64)')
    must(m.count(anchor) == 1, "anchor rama CMake 1.85c no encontrado")
    add = ('\n    set(EMOTE_RESOLUTION "360_360")'
           '\n    set(ESP_VOCAT_ASSETS_STAGING "${CMAKE_BINARY_DIR}/esp-vocat-assets")'
           '\n    set(EMOTE_EXTERNAL_PATH "${ESP_VOCAT_ASSETS_STAGING}")')
    m = m.replace(anchor, anchor + add)
    print("[D] CMake: rama 1.85c con EMOTE_RESOLUTION/staging")
else:
    print("[D] CMake: rama 1.85c ya estaba")

# ---- E) CMake: sumar la 1.85c a la condicion de copia de emote assets + generalizar paths a BOARD_DIR ----
cond_old = "if(CONFIG_BOARD_TYPE_ESP_VOCAT OR CONFIG_BOARD_TYPE_CYBERAI_VOCAT_V2_0 OR CONFIG_BOARD_TYPE_CYBERAI_VOCAT_V2_1)"
cond_new = "if(CONFIG_BOARD_TYPE_ESP_VOCAT OR CONFIG_BOARD_TYPE_CYBERAI_VOCAT_V2_0 OR CONFIG_BOARD_TYPE_CYBERAI_VOCAT_V2_1 OR CONFIG_BOARD_TYPE_WAVESHARE_ESP32_S3_TOUCH_LCD_1_85C)"
if cond_new not in m:
    must(m.count(cond_old) == 1, "anchor condicion emote-assets no encontrado")
    m = m.replace(cond_old, cond_new)
    # generalizar las 3 rutas hardcodeadas de esp-vocat a ${BOARD_DIR} (equivalente para vocat)
    m = m.replace("boards/espressif/esp-vocat/assets/360_360/emote.json",
                  "boards/${BOARD_DIR}/assets/360_360/emote.json")
    m = m.replace("boards/espressif/esp-vocat/emoji/low_battery.eaf",
                  "boards/${BOARD_DIR}/emoji/low_battery.eaf")
    m = m.replace("boards/espressif/esp-vocat/emoji/battery_connected.eaf",
                  "boards/${BOARD_DIR}/emoji/battery_connected.eaf")
    print("[E] CMake: 1.85c en copia de emote assets + rutas por BOARD_DIR")
else:
    print("[E] CMake: condicion ya incluia la 1.85c")
write(cmake, m)

# ---- F) board config.json: sdkconfig_append con los flags de emote ----
cj = json.loads(read(confjson))
ap = cj["builds"][0].setdefault("sdkconfig_append", [])
for flag in ["CONFIG_USE_EMOTE_MESSAGE_STYLE=y",
             "CONFIG_MMAP_FILE_NAME_LENGTH=32",
             "CONFIG_FLASH_EXPRESSION_ASSETS=y"]:
    if flag not in ap: ap.append(flag)
write(confjson, json.dumps(cj, indent=4) + "\n")
print("[F] config.json: sdkconfig_append actualizado")

# ---- G) sdkconfig.defaults: mismos flags (para build manual con idf.py) ----
s = read(sdkdef)
need = [("CONFIG_USE_EMOTE_MESSAGE_STYLE=y", "CONFIG_USE_EMOTE_MESSAGE_STYLE"),
        ("CONFIG_MMAP_FILE_NAME_LENGTH=32", "CONFIG_MMAP_FILE_NAME_LENGTH"),
        ("CONFIG_FLASH_EXPRESSION_ASSETS=y", "CONFIG_FLASH_EXPRESSION_ASSETS")]
add = [line for line, key in need if key not in s]
if add:
    s = s.rstrip() + "\n\n# --- Ojos animados (EmoteDisplay) ---\n" + "\n".join(add) + "\n"
    write(sdkdef, s); print("[G] sdkconfig.defaults: flags de emote agregados")
else:
    print("[G] sdkconfig.defaults: ya tenia los flags")
PYEOF

# ---------- archivos de assets de la placa ----------
echo ">> Creando assets de la placa (emote.json + .eaf de bateria)..."
mkdir -p "$BOARD/assets/360_360" "$BOARD/emoji"

# emote.json: calcado de esp-vocat (mapea emociones -> animaciones de ojos)
cp "$VOCAT/assets/360_360/emote.json" "$BOARD/assets/360_360/emote.json"
# .eaf de bateria (los de los ojos los trae el componente esp_emote_assets)
cp "$VOCAT/emoji/low_battery.eaf"       "$BOARD/emoji/low_battery.eaf"
cp "$VOCAT/emoji/battery_connected.eaf" "$BOARD/emoji/battery_connected.eaf"
echo "   OK: $BOARD/assets/360_360/emote.json"
echo "   OK: $BOARD/emoji/{low_battery,battery_connected}.eaf"

# ---------- regenerar sdkconfig para que tome los flags nuevos ----------
if [ -f sdkconfig ]; then
  cp sdkconfig "$BK/sdkconfig"
  rm -f sdkconfig
  echo ">> sdkconfig viejo respaldado en $BK/ y borrado (se regenera de sdkconfig.defaults)."
fi

echo ""
echo "=================================================================="
echo " LISTO. Cambios aplicados. Ahora compila y flashea:"
echo ""
echo "   . ~/esp/esp-idf/export.sh"
echo "   idf.py build && idf.py merge-bin"
echo ""
echo " (si algo sale mal, restaura con:  cp -r $BK/* . )"
echo "=================================================================="
