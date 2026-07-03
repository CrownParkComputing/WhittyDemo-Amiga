#!/bin/bash
# Package the Chase H.Q. + WhittyDemo combined boot HDF:
#   boot -> WhittyDemo intro (mod playing) -> FIRE starts Chase H.Q.
#   -> game exit drops back to the intro -> ESC in the intro quits Amiberry.
# Produces:
#   dist/ChaseHQDemo_RTG.hdf   (RTG_boot_template + WhittyDemo + ChaseHQ/)
#   dist/ChaseHQDemo-RTG.uae   (Chase HQ.uae clone repointed at the HDF)
# Installs both into ~/Amiberry (HardDrives + Configurations).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
BASE_HDF="/home/jon/Amiberry/HardDrives/RTG_boot_template.hdf"
CHASEHQ_EXE="/home/jon/AmigaArcadePorts/Taito_Z_System/Chase_HQ/dist/WhittyArcade_HD/Games/ChaseHQ/Chase HQ"
TEMPLATE_UAE="/home/jon/AmigaArcadePorts/Taito_Z_System/Chase_HQ/dist/Chase HQ.uae"
INST_HDF="/home/jon/Amiberry/HardDrives/ChaseHQDemo_RTG.hdf"
INST_UAE="/home/jon/Amiberry/Configurations/ChaseHQDemo-RTG.uae"
. "$HERE/hdf_safety.sh"

[ -f "$HERE/WhittyDemo" ]  || { echo "run ./build.sh first" >&2; exit 1; }
[ -f "$CHASEHQ_EXE" ]      || { echo "missing Chase HQ exe: $CHASEHQ_EXE" >&2; exit 1; }
[ -f "$TEMPLATE_UAE" ]     || { echo "missing template uae: $TEMPLATE_UAE" >&2; exit 1; }
mkdir -p "$HERE/dist"

# xdftool detects image type by EXTENSION -- temp name must end in .hdf
BUILD="$HERE/dist/building_$$_ChaseHQDemo_RTG.hdf"
cp -f "$BASE_HDF" "$BUILD"
xdftool "$BUILD" delete WhittyDemo >/dev/null 2>&1 || true
xdftool "$BUILD" delete S/startup-sequence >/dev/null 2>&1 || true
xdftool "$BUILD" write "$HERE/WhittyDemo" WhittyDemo
xdftool "$BUILD" makedir ChaseHQ
xdftool "$BUILD" write "$CHASEHQ_EXE" "ChaseHQ/Chase HQ"

SS="$(mktemp --suffix=.txt)"
cat > "$SS" <<'EOF'
; Chase H.Q. + WhittyDemo boot: intro first, FIRE starts the game, game exit
; returns to the intro, ESC in the intro quits the emulator.

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
Echo "Chase H.Q. - Whitty Arcade"
Stack 65536

; the WhittyDemo intro IS the loader -- suppress the game's own splash
; (cc_rtg_main.c: whitty_no_game_loader() skips run_loader() when set)
Echo >ENV:WHITTY_NO_GAME_LOADER "1" NOLINE

Lab intro
SYS:WhittyDemo GAME
IF WARN
  C:UAEquit
  EndCLI >NIL:
EndIF
CD SYS:ChaseHQ
"Chase HQ"
CD SYS:
Skip intro BACK
EOF
xdftool "$BUILD" write "$SS" S/startup-sequence
rm -f "$SS"

hdf_install_verified "$BUILD" "$HERE/dist/ChaseHQDemo_RTG.hdf" "$INST_HDF"
rm -f "$BUILD"

sed \
  -e "1s|.*|; Chase H.Q. + WhittyDemo intro config for Amiberry.|" \
  -e "2s|.*|; Boots the demo intro, FIRE starts Chase H.Q., ESC quits.|" \
  -e "s|^config_description=.*|config_description=Chase HQ RTG with WhittyDemo boot intro|" \
  -e "s|^filesystem2=.*|hardfile2=rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^uaehf0=.*|uaehf0=hdf,rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^log_file=.*|log_file=/tmp/amiberry-chasehqdemo-rtg.log|" \
  "$TEMPLATE_UAE" > "$HERE/dist/ChaseHQDemo-RTG.uae"
cp -f "$HERE/dist/ChaseHQDemo-RTG.uae" "$INST_UAE"

echo "installed: $INST_HDF"
echo "installed: $INST_UAE"
