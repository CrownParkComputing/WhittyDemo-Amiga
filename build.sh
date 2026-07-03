#!/bin/bash
# Build WhittyDemo: old-school Amiga demo intro (RTG 864x486 8-bit).
#   build.sh          -> host harness + Amiga exe
#   build.sh host t.. -> host harness only + validation frames at given ticks
set -e
export PATH="/home/jon/amiga-amigaos/bin:$HOME/.local/bin:$PATH"

HERE="$(cd "$(dirname "$0")" && pwd)"
PT="$HERE/ptplayer"
OBJ="$HERE/build"
GCC="m68k-amigaos-gcc -m68030 -noixemul -O2 -fomit-frame-pointer -DNDEBUG -I $HERE"
AS="m68k-amigaos-as -m68020"
VASM="vasmm68k_mot -I $HERE -m68020 -phxass -nowarn=62 -Fhunk"

mkdir -p "$OBJ"

# regenerate picture + sine table if missing or source newer
if [ ! -f "$HERE/demo_pic.c" ] || [ "$HERE/assets/pic_src.png" -nt "$HERE/demo_pic.c" ]; then
    python3 "$HERE/gen_assets.py"
fi

echo "=== host harness ==="
cc -O2 -Wall -Wextra -I "$HERE" -o "$OBJ/host_demo" \
    "$HERE/host_demo.c" "$HERE/demo_core.c" "$HERE/demo_pic.c"

if [ "$1" = "host" ]; then
    mkdir -p "$OBJ/frames"
    "$OBJ/host_demo" "$OBJ/frames" "${@:2}"
    exit 0
fi

echo "=== Amiga exe ==="
$GCC -c "$HERE/demo_core.c" -o "$OBJ/demo_core.o"
$GCC -c "$HERE/demo_pic.c"  -o "$OBJ/demo_pic.o"
$GCC -c "$HERE/demo_main.c" -o "$OBJ/demo_main.o"
$AS "$PT/arcade_intro_glue.s" -o "$OBJ/arcade_intro_glue.o"
$AS "$PT/tc_ptplayer.68k"     -o "$OBJ/tc_ptplayer.o"
$AS "$PT/tc_ptplayer_glue.s"  -o "$OBJ/tc_ptplayer_glue.o"
$VASM -o "$OBJ/intro_mod.o" "$HERE/intro_mod.s"

$GCC -o "$HERE/WhittyDemo" \
    "$OBJ/demo_main.o" "$OBJ/demo_core.o" "$OBJ/demo_pic.o" \
    "$OBJ/arcade_intro_glue.o" "$OBJ/tc_ptplayer.o" "$OBJ/tc_ptplayer_glue.o" \
    "$OBJ/intro_mod.o" \
    -Wl,--start-group -lamiga -lgcc -Wl,--end-group

ls -la "$HERE/WhittyDemo"
echo "=== done ==="
