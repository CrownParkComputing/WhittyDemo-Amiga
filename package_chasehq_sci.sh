#!/bin/bash
# Package the Chase H.Q. + S.C.I. "Taito Z Double Bill" as ONE boot volume with
# WhittyDemo as the two-game selector:
#
#   boot -> WhittyDemo SELECT (combined CHASE H.Q. | S.C.I. picture, LEFT/RIGHT
#           pick, the chosen half is framed + named, FIRE/RETURN launches it)
#     -> Chase H.Q. (rc 0) or S.C.I. (rc 5) runs, its exit drops back to the
#        selector; ESC in the selector (rc 10) quits Amiberry.
#
# The two game exes are ~10MB each (ROM/gfx .incbin'd in), which overflows the
# 24MB RTG_boot_template.hdf -- so the bundle ships as a HOST-DIRECTORY boot
# volume (uaehf0=dir) unpacked from that template. No fixed size, both fit.
#
# The WhittyDemo binary bakes its picture in at compile time, so this builds a
# selector-flavoured WhittyDemo (the 550x275 two-square composite via PIC_SRC +
# PIC_W/PIC_H). demo_pic.c / demo_sintab.h are tracked (Chase H.Q. by default)
# -- regenerated for this build then restored so the tree stays on the default.
#
# Produces (and installs into ~/Amiberry):
#   ~/Amiberry/HardDrives/ChaseHQ_SCI_RTG_HD/   (boot volume: WhittyDemo + games)
#   ~/Amiberry/Configurations/ChaseHQ_SCI-RTG.uae
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
TZ="/home/jon/TaitoZ-Amiga"
BASE_HDF="/home/jon/Amiberry/HardDrives/RTG_boot_template.hdf"
CHQ_EXE="$TZ/dist/Chase HQ v2"          # 8-bit pen8 build w/ bezel + F10 DIP editor
SCI_EXE="$TZ/dist/S.C.I. v2"            # S.C.I. RTG native (640x480)
CHQ_SCI_PIC="$HERE/assets/pic_chasehq_sci_sq.png"   # 550x275 two-square composite (make_chasehq_sci_pic.py)
TEMPLATE_UAE="/home/jon/Amiberry/Configurations/ChaseHQDemo-RTG.uae"  # runs the 864x486 selector already
INST_DIR="/home/jon/Amiberry/HardDrives/ChaseHQ_SCI_RTG_HD"
INST_UAE="/home/jon/Amiberry/Configurations/ChaseHQ_SCI-RTG.uae"
# ChaseHQDemo template was removed on this setup -> fall back to our own config
[ -f "$TEMPLATE_UAE" ] || TEMPLATE_UAE="$INST_UAE"

[ -f "$BASE_HDF" ]     || { echo "missing base hdf: $BASE_HDF" >&2; exit 1; }
[ -f "$CHQ_EXE" ]      || { echo "missing Chase H.Q. exe: $CHQ_EXE" >&2; exit 1; }
[ -f "$SCI_EXE" ]      || { echo "missing S.C.I. exe: $SCI_EXE" >&2; exit 1; }
[ -f "$CHQ_SCI_PIC" ]  || { echo "missing combined picture: $CHQ_SCI_PIC" >&2; exit 1; }
[ -f "$TEMPLATE_UAE" ] || { echo "missing template uae: $TEMPLATE_UAE" >&2; exit 1; }

mkdir -p "$HERE/dist"
BUILD="$HERE/dist/building_$$_ChaseHQ_SCI_RTG_HD"

# --- build the selector-flavoured WhittyDemo, restore tracked defaults + clean up ---
cleanup() {
    git -C "$HERE" checkout -- demo_pic.c demo_sintab.h >/dev/null 2>&1 || true
    rm -rf "$BUILD" "$BUILD.blkdev" "$BUILD.bootcode" "$BUILD.xdfmeta"
}
trap cleanup EXIT

PIC_SRC="$CHQ_SCI_PIC" PIC_W=550 PIC_H=275 FORCE_ASSETS=1 "$HERE/build.sh"
[ -f "$HERE/WhittyDemo" ] || { echo "build failed: no WhittyDemo produced" >&2; exit 1; }

# --- assemble the boot volume as a host directory (unpack the RTG template) ---
rm -rf "$BUILD" "$BUILD.blkdev" "$BUILD.bootcode" "$BUILD.xdfmeta"
xdftool "$BASE_HDF" unpack "$BUILD"

# start from a clean payload
rm -f  "$BUILD/WhittyDemo" "$BUILD/SCI" "$BUILD/Chase HQ" "$BUILD/ChaseHQ" \
       "$BUILD/PowerDriftLive"
rm -rf "$BUILD/Games"
mkdir -p "$BUILD/S" "$BUILD/Games/ChaseHQ" "$BUILD/Games/SCI"

cp -f "$HERE/WhittyDemo" "$BUILD/WhittyDemo"
cp -f "$CHQ_EXE"         "$BUILD/Games/ChaseHQ/ChaseHQ"
cp -f "$SCI_EXE"         "$BUILD/Games/SCI/SCI"

# --- selector startup-sequence (rc 0 = Chase H.Q., 5 = S.C.I., 10 = quit) ---
cat > "$BUILD/S/startup-sequence" <<'EOF'
; Taito Z Double Bill: WhittyDemo boots first as a two-game selector.
;   rc 0     -> Chase H.Q.
;   rc 5 WARN -> S.C.I.
;   rc 10 ERROR -> quit Amiberry
; Each game's exit returns to the selector.

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
Echo "Chase H.Q. / S.C.I. - Whitty Arcade"
Stack 200000

; the WhittyDemo selector IS the loader -- suppress each game's own splash
Echo >ENV:WHITTY_NO_GAME_LOADER "1" NOLINE

Lab selector
SYS:WhittyDemo SELECT
IF ERROR
  C:UAEquit
  EndCLI >NIL:
EndIF
IF WARN
  CD SYS:Games/SCI
  SCI
  CD SYS:
  Skip selector BACK
EndIF
CD SYS:Games/ChaseHQ
ChaseHQ
CD SYS:
Skip selector BACK
EOF

# --- install the boot volume (dist copy + Amiberry HardDrives) ---
rm -rf "$HERE/dist/ChaseHQ_SCI_RTG_HD"
cp -a "$BUILD" "$HERE/dist/ChaseHQ_SCI_RTG_HD"
rm -rf "$INST_DIR"
cp -a "$BUILD" "$INST_DIR"

# --- UAE config: ChaseHQDemo (proven 864x486 selector) -> directory mount ---
# - sound_auto=false so the ptplayer mod in the loader always plays.
# - RTG FULLSCREEN: fill the monitor (uaegfx scales the 864x486 / 640x480 RTG
#   screens up, aspect kept). Exclusive fullscreen MUST target a real monitor
#   mode or it black-screens -- so gfx_*_fullscreen is set to the detected
#   native desktop resolution, not the RTG size.
FS_RES="$(cat /sys/class/drm/*/modes 2>/dev/null | grep -m1 -E '^[0-9]+x[0-9]+' || echo '1920x1080')"
FS_W="${FS_RES%x*}"; FS_H="${FS_RES#*x}"
CFG="$HERE/dist/ChaseHQ_SCI-RTG.uae"
sed \
  -e "1s|.*|; Chase H.Q. + S.C.I. Taito Z Double Bill -- WhittyDemo selector config.|" \
  -e "2s|.*|; Boots the selector; LEFT/RIGHT + FIRE picks a game, ESC quits.|" \
  -e "s|^config_description=.*|config_description=Chase HQ + SCI Whitty selector (RTG)|" \
  -e "s|^hardfile2=.*|filesystem2=rw,DH0:CHQSCI:$INST_DIR,1|" \
  -e "s|^uaehf0=.*|uaehf0=dir,rw,DH0:CHQSCI:$INST_DIR,1|" \
  -e "s|^sound_auto=.*|sound_auto=false|" \
  -e "s|^gfx_fullscreen=.*|gfx_fullscreen=1|" \
  -e "s|^gfx_fullscreen_picasso=.*|gfx_fullscreen_picasso=true|" \
  -e "s|^gfx_width_fullscreen=.*|gfx_width_fullscreen=$FS_W|" \
  -e "s|^gfx_height_fullscreen=.*|gfx_height_fullscreen=$FS_H|" \
  -e "s|^log_file=.*|log_file=/tmp/amiberry-chqsci-rtg.log|" \
  "$TEMPLATE_UAE" > "$CFG"
grep -q "^log_file=" "$CFG"               || printf 'log_file=/tmp/amiberry-chqsci-rtg.log\n' >> "$CFG"
grep -q "^sound_auto=" "$CFG"             || printf 'sound_auto=false\n' >> "$CFG"
grep -q "^gfx_fullscreen=" "$CFG"         || printf 'gfx_fullscreen=1\n' >> "$CFG"
grep -q "^gfx_fullscreen_picasso=" "$CFG" || printf 'gfx_fullscreen_picasso=true\n' >> "$CFG"
cp -f "$CFG" "$INST_UAE"

echo "installed: $INST_DIR"
echo "installed: $INST_UAE"
