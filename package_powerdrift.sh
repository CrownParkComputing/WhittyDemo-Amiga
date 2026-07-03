#!/bin/bash
# Package the Power Drift + WhittyDemo combined boot HDF:
#   boot -> WhittyDemo intro (Power Drift picture + mod) -> FIRE starts Power
#   Drift -> game exit drops back to the intro -> ESC in the intro quits Amiberry.
# Produces:
#   dist/PowerDriftDemo_RTG.hdf   (RTG_boot_template + PD-flavoured WhittyDemo + PowerDriftLive)
#   dist/PowerDriftDemo-RTG.uae   (PowerDrift-RTG.uae clone repointed at the HDF)
# Installs both into ~/Amiberry (HardDrives + Configurations).
#
# The WhittyDemo binary bakes its picture in at compile time, so this builds a
# Power-Drift-specific WhittyDemo (PIC_SRC=pic_powerdrift.png + -DGAME_PDRIFT for
# the Power Drift scroller). demo_pic.c / demo_sintab.h are tracked (Chase H.Q.
# by default) -- they are regenerated for this build then restored so the working
# tree stays on the Chase H.Q. default.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
BASE_HDF="/home/jon/Amiberry/HardDrives/RTG_boot_template.hdf"
PD_EXE="/home/jon/PowerDrift-Amiga/PowerDriftLive"
TEMPLATE_UAE="/home/jon/PowerDrift-Amiga/dist/PowerDrift-RTG.uae"
PD_PIC="$HERE/assets/pic_powerdrift.png"
INST_HDF="/home/jon/Amiberry/HardDrives/PowerDriftDemo_RTG.hdf"
INST_UAE="/home/jon/Amiberry/Configurations/PowerDriftDemo-RTG.uae"
. "$HERE/hdf_safety.sh"

[ -f "$BASE_HDF" ]     || { echo "missing base hdf: $BASE_HDF" >&2; exit 1; }
[ -f "$PD_EXE" ]       || { echo "missing Power Drift exe: $PD_EXE" >&2; exit 1; }
[ -f "$TEMPLATE_UAE" ] || { echo "missing template uae: $TEMPLATE_UAE" >&2; exit 1; }
[ -f "$PD_PIC" ]       || { echo "missing PD picture: $PD_PIC" >&2; exit 1; }

# --- build the Power Drift-flavoured WhittyDemo, then restore tracked defaults ---
restore_tracked() { git -C "$HERE" checkout -- demo_pic.c demo_sintab.h >/dev/null 2>&1 || true; }
trap restore_tracked EXIT
PIC_SRC="$PD_PIC" EXTRA_CFLAGS="-DGAME_PDRIFT" FORCE_ASSETS=1 "$HERE/build.sh"
[ -f "$HERE/WhittyDemo" ] || { echo "build failed: no WhittyDemo produced" >&2; exit 1; }

mkdir -p "$HERE/dist"

# xdftool detects image type by EXTENSION -- temp name must end in .hdf
BUILD="$HERE/dist/building_$$_PowerDriftDemo_RTG.hdf"
cp -f "$BASE_HDF" "$BUILD"
xdftool "$BUILD" delete WhittyDemo >/dev/null 2>&1 || true
xdftool "$BUILD" delete PowerDriftLive >/dev/null 2>&1 || true
xdftool "$BUILD" delete S/startup-sequence >/dev/null 2>&1 || true
xdftool "$BUILD" write "$HERE/WhittyDemo" WhittyDemo
xdftool "$BUILD" write "$PD_EXE" PowerDriftLive

SS="$(mktemp --suffix=.txt)"
cat > "$SS" <<'EOF'
; Power Drift + WhittyDemo boot: intro first, FIRE starts the game, game exit
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
Echo "Power Drift - Whitty Arcade"
Stack 200000

Lab intro
SYS:WhittyDemo GAME
IF WARN
  C:UAEquit
  EndCLI >NIL:
EndIF
SYS:PowerDriftLive
Skip intro BACK
EOF
xdftool "$BUILD" write "$SS" S/startup-sequence
rm -f "$SS"

hdf_install_verified "$BUILD" "$HERE/dist/PowerDriftDemo_RTG.hdf" "$INST_HDF"
rm -f "$BUILD"

sed \
  -e "1s|.*|; Power Drift + WhittyDemo intro config for Amiberry.|" \
  -e "2s|.*|; Boots the demo intro, FIRE starts Power Drift, ESC quits.|" \
  -e "s|^config_description=.*|config_description=Power Drift RTG with WhittyDemo boot intro|" \
  -e "s|^hardfile2=.*|hardfile2=rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^uaehf0=.*|uaehf0=hdf,rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  "$TEMPLATE_UAE" > "$HERE/dist/PowerDriftDemo-RTG.uae"
grep -q "^log_file=" "$HERE/dist/PowerDriftDemo-RTG.uae" \
  && sed -i "s|^log_file=.*|log_file=/tmp/amiberry-powerdriftdemo-rtg.log|" "$HERE/dist/PowerDriftDemo-RTG.uae" \
  || printf 'log_file=/tmp/amiberry-powerdriftdemo-rtg.log\n' >> "$HERE/dist/PowerDriftDemo-RTG.uae"
cp -f "$HERE/dist/PowerDriftDemo-RTG.uae" "$INST_UAE"

echo "installed: $INST_HDF"
echo "installed: $INST_UAE"
