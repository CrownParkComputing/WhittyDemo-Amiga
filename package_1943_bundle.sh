#!/bin/bash
# Package a combined 1943 + 1943 Kai HDF with WhittyDemo as the boot selector.
# Selector return codes:
#   0  -> launch 1943
#   5  -> launch 1943 Kai
#   10 -> quit Amiberry
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
BASE_HDF="/home/jon/Amiberry/HardDrives/RTG_boot_template.hdf"
TEMPLATE_UAE="/home/jon/Amiberry/Configurations/1943-RTG.uae"
CAP="/home/jon/AmigaArcadePorts/Capcom_Z80_Dual_YM2203"
INST_HDF="/home/jon/Amiberry/HardDrives/1943Bundle_RTG.hdf"
INST_UAE="/home/jon/Amiberry/Configurations/1943Bundle-RTG.uae"
. "$HERE/hdf_safety.sh"

[ -f "$HERE/WhittyDemo" ] || { echo "run ./build.sh first" >&2; exit 1; }
[ -f "$BASE_HDF" ] || { echo "missing base HDF: $BASE_HDF" >&2; exit 1; }
[ -f "$TEMPLATE_UAE" ] || { echo "missing template UAE: $TEMPLATE_UAE" >&2; exit 1; }
mkdir -p "$HERE/dist"

TMP="$HERE/dist/1943_bundle_extract_$$"
mkdir -p "$TMP"
cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

pick_or_extract() {
    local plain="$1"
    local hdf="$2"
    local hdf_path="$3"
    local out="$4"

    if [ -f "$plain" ]; then
        cp -f "$plain" "$out"
    else
        [ -f "$hdf" ] || { echo "missing executable and fallback HDF: $plain / $hdf" >&2; exit 1; }
        xdftool "$hdf" read "$hdf_path" "$out"
    fi
}

pick_or_extract "${EXE_1943:-$CAP/1943/1943}" \
    "/home/jon/Amiberry/HardDrives/1943_RTG.hdf" \
    "1943" \
    "$TMP/1943"
pick_or_extract "${EXE_1943KAI:-$CAP/1943_Kai/1943 Kai}" \
    "/home/jon/Amiberry/HardDrives/1943Kai_RTG.hdf" \
    "1943Kai" \
    "$TMP/1943Kai"

BUILD="$HERE/dist/building_$$_1943Bundle_RTG.hdf"
cp -f "$BASE_HDF" "$BUILD"
xdftool "$BUILD" delete WhittyDemo >/dev/null 2>&1 || true
xdftool "$BUILD" delete S/startup-sequence >/dev/null 2>&1 || true
xdftool "$BUILD" delete Games >/dev/null 2>&1 || true
xdftool "$BUILD" makedir Games
xdftool "$BUILD" makedir Games/1943
xdftool "$BUILD" makedir Games/1943Kai
xdftool "$BUILD" write "$HERE/WhittyDemo" WhittyDemo
xdftool "$BUILD" write "$TMP/1943" Games/1943/1943
xdftool "$BUILD" write "$TMP/1943Kai" Games/1943Kai/1943Kai
if [ -f "$CAP/1943/assets/1943.info" ]; then
    xdftool "$BUILD" write "$CAP/1943/assets/1943.info" Games/1943/1943.info
fi
if [ -f "$CAP/1943_Kai/assets/1943 Kai.info" ]; then
    xdftool "$BUILD" write "$CAP/1943_Kai/assets/1943 Kai.info" Games/1943Kai/1943Kai.info
fi

SS="$(mktemp --suffix=.txt)"
cat > "$SS" <<'EOF'
; 1943 double bundle: WhittyDemo selector boots first.
; 0 = 1943, WARN = 1943 Kai, ERROR = quit.

C:SetPatch QUIET
C:Version >NIL:
FailAt 21

C:MakeDir RAM:T RAM:Clipboards RAM:ENV RAM:ENV/Sys
C:Copy >NIL: ENVARC: RAM:ENV ALL NOREQ

Resident >NIL: C:Assign PURE
Resident >NIL: C:Execute PURE

Assign >NIL: ENV: RAM:ENV
Assign >NIL: T: RAM:T
Assign >NIL: CLIPS: RAM:Clipboards
Assign >NIL: REXX: S:
Assign >NIL: PRINTERS: DEVS:Printers
Assign >NIL: KEYMAPS: DEVS:Keymaps
Assign >NIL: LOCALE: SYS:Locale
Assign >NIL: LIBS: SYS:Classes ADD

BindDrivers
C:Mount >NIL: DEVS:DOSDrivers/~(#?.info)

IF EXISTS DEVS:Monitors
  IF EXISTS DEVS:Monitors/VGAOnly
    DEVS:Monitors/VGAOnly
  EndIF
  IF EXISTS DEVS:Monitors/uaegfx
    DEVS:Monitors/uaegfx
  ELSE
    IF EXISTS DEVS:Monitors/more/uaegfx
      DEVS:Monitors/more/uaegfx
    EndIF
  EndIF
  C:List >NIL: DEVS:Monitors/~(#?.info|VGAOnly|uaegfx) TO T:M LFORMAT "DEVS:Monitors/%s"
  Execute T:M
  C:Delete >NIL: T:M
EndIF

C:AddDataTypes REFRESH QUIET
C:IPrefs
C:ConClip
C:Wait 2 SECS

Path >NIL: RAM: C: SYS:Utilities SYS:System S: SYS:Prefs SYS:WBStartup SYS:Tools
Echo "1943 / 1943 Kai - Whitty Arcade"
Stack 65536
Echo >ENV:WHITTY_NO_GAME_LOADER "1" NOLINE

Lab selector
SYS:WhittyDemo SELECT
IF ERROR
  C:UAEquit
  EndCLI >NIL:
EndIF
IF WARN
  CD SYS:Games/1943Kai
  1943Kai
  CD SYS:
  Skip selector BACK
EndIF
CD SYS:Games/1943
1943
CD SYS:
Skip selector BACK
EOF
xdftool "$BUILD" write "$SS" S/startup-sequence
rm -f "$SS"

hdf_install_verified "$BUILD" "$HERE/dist/1943Bundle_RTG.hdf" "$INST_HDF"
rm -f "$BUILD"

sed \
  -e "1s|.*|; 1943 + 1943 Kai WhittyDemo selector config for Amiberry.|" \
  -e "2s|.*|; Boots WhittyDemo as a two-game selector.|" \
  -e "s|^config_description=.*|config_description=1943 + 1943 Kai Whitty selector|" \
  -e "s|^hardfile2=.*|hardfile2=rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^uaehf0=.*|uaehf0=hdf,rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^log_file=.*|log_file=/tmp/amiberry-1943bundle-rtg.log|" \
  "$TEMPLATE_UAE" > "$HERE/dist/1943Bundle-RTG.uae"
cp -f "$HERE/dist/1943Bundle-RTG.uae" "$INST_UAE"

echo "installed: $INST_HDF"
echo "installed: $INST_UAE"
