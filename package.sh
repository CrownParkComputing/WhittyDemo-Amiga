#!/bin/bash
# Package WhittyDemo for Amiberry:
#   - dist/WhittyDemo_RTG.hdf  (clean RTG_boot_template + exe + startup)
#   - dist/WhittyDemo-RTG.uae  (SkyKid-RTG.uae clone repointed at the HDF)
# Installs both into ~/Amiberry (HardDrives + Configurations).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
BASE_HDF="/home/jon/Amiberry/HardDrives/RTG_boot_template.hdf"
TEMPLATE_UAE="/home/jon/Amiberry/Configurations/SkyKid-RTG.uae"
INST_HDF="/home/jon/Amiberry/HardDrives/WhittyDemo_RTG.hdf"
INST_UAE="/home/jon/Amiberry/Configurations/WhittyDemo-RTG.uae"
. /home/jon/AmigaArcadePorts/tools/hdf_safety.sh

[ -f "$HERE/WhittyDemo" ] || { echo "run ./build.sh first" >&2; exit 1; }
mkdir -p "$HERE/dist"

# xdftool detects image type by EXTENSION -- temp name must end in .hdf
BUILD="$HERE/dist/building_$$_WhittyDemo_RTG.hdf"
cp -f "$BASE_HDF" "$BUILD"
xdftool "$BUILD" delete WhittyDemo >/dev/null 2>&1 || true
xdftool "$BUILD" delete S/startup-sequence >/dev/null 2>&1 || true
xdftool "$BUILD" write "$HERE/WhittyDemo" WhittyDemo

SS="$(mktemp --suffix=.txt)"
cat > "$SS" <<'EOF'
; Whitty Demo RTG direct boot, based on the supplied RTG/Picasso96 boot disk.

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
Echo "Whitty Demo RTG"
Stack 65536
SYS:WhittyDemo
C:UAEquit
EndCLI >NIL:
EOF
xdftool "$BUILD" write "$SS" S/startup-sequence
rm -f "$SS"

hdf_install_verified "$BUILD" "$HERE/dist/WhittyDemo_RTG.hdf" "$INST_HDF"
rm -f "$BUILD"

sed \
  -e "1s/.*/; Whitty Demo RTG config for Amiberry./" \
  -e "2s/.*/; Boots the Picasso96-derived HDF directly into the demo intro./" \
  -e "s|^config_description=.*|config_description=Whitty Demo RTG INTRO|" \
  -e "s|^hardfile2=.*|hardfile2=rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^uaehf0=.*|uaehf0=hdf,rw,DH0:$INST_HDF,32,1,2,512,0,,uae0,0|" \
  -e "s|^log_file=.*|log_file=/tmp/amiberry-whittydemo-rtg.log|" \
  "$TEMPLATE_UAE" > "$HERE/dist/WhittyDemo-RTG.uae"
cp -f "$HERE/dist/WhittyDemo-RTG.uae" "$INST_UAE"

echo "installed: $INST_HDF"
echo "installed: $INST_UAE"
