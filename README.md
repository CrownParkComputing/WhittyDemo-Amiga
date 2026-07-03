# WhittyDemo — old-school Amiga demo intro

A classic "demos gone by" intro (Red Sector / Kefrens vibe) for the Whitty
Arcade family: RTG 864x486 8-bit chunky, presented with WriteChunkyPixels at
WaitTOF pace, ProTracker house tune on Paula via the shared ptplayer.

Effects, all on screen at once:
- **Big rainbow sine scroller** (per-scanline colour-cycled stripes + shadow)
- **Filled flat-shaded 3D ring** (16x6 quad torus) spinning around the
  centrepiece, passing behind its top and in front of its bottom, with three
  **solid isometric shapes** (gold cube, red octahedron, green tetrahedron)
  self-spinning while they orbit the ring
- **Picture painted piece by piece**: Chase H.Q. box art (375x300, 160-colour
  median-cut) built up in 25px blocks in a shuffled order with a white flash
  per block, held, dissolved, and rebuilt on a 14.4s cycle, inside a
  colour-cycling frame
- Copper-gradient backdrop, two bouncing full-width rainbow raster bars,
  parallax starfield
- Wavy rainbow **WHITTY ARCADE** title

ESC / joystick fire / left mouse button exits cleanly (music stopped, screen
closed).

## Layout
- `demo_core.c/h` — OS-free renderer (pure function of tick); identical pixels
  on the Linux host harness and the Amiga
- `demo_main.c` — Amiga host (Picasso96 screen, 256-colour LoadRGB32,
  ptplayer music, input)
- `host_demo.c` — host harness: dumps validation frames as PPM
- `gen_assets.py` — regenerates `demo_pic.c` (from `assets/pic_src.png`) and
  `demo_sintab.h`
- `ptplayer/` — vendored copies of the shared ptplayer, glue and the house
  `.mod` (self-contained on purpose; original lives in
  `AmigaArcadePorts/ArcadeIntro`)
- `intro_mod.s` — embeds the module as `ai_default_mod`

## Build
```sh
./build.sh                # host harness + Amiga exe (WhittyDemo)
./build.sh host 0 60 300  # render validation frames to build/frames/
```
Toolchain: bebbo m68k-amigaos-gcc (/home/jon/amiga-amigaos/bin) + vasm.

## Deploy
Copied to BOTH AGS SHARED mirrors (`~/Amiberry/AGS_UAE/SHARED`,
`~/AGS_UAE/SHARED`):
- `SHARED/Whitty Demo` (+ `.info`) — standalone, launch straight from AGS
- `SHARED/WhittyArcade/Games/WhittyDemo/WhittyDemo` + a `Whitty Demo` entry in
  `WhittyArcade/S/ArcadeLauncher.cfg` — launch from the Whitty Arcade frontend

To change the picture: replace `assets/pic_src.png`, run `./build.sh`.
To change the tune: replace `ptplayer/intro_default.mod` (4-channel PT mod).
