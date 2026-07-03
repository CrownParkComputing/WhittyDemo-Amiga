# WhittyDemo — Amiga RTG Demo Intro

An old-school Amiga demo intro (Red Sector / Kefrens vibe) for the Whitty
Arcade family. Runs as a native Amiga RTG application — 864x486 8-bit chunky
via Picasso96, presented with WriteChunkyPixels, ProTracker house tune on
Paula via ptplayer.

## What It Does

All effects render simultaneously on screen:

- **Rainbow sine scroller** — per-scanline colour-cycled stripes with shadow
- **Filled 3D ring** — 16x6 quad torus spinning around the centrepiece,
  passing behind its top and in front of its bottom, with three solid
  isometric shapes (gold cube, red octahedron, green tetrahedron) orbiting
  while self-spinning
- **Picture reveal** — box art built up in 25px blocks in shuffled order with
  white flash per block, held, dissolved, rebuilt on a 14.4s cycle inside a
  colour-cycling frame
- **Copper-gradient backdrop** — two bouncing full-width rainbow raster bars,
  parallax starfield
- **Wavy rainbow title** — WHITTY ARCADE in animated rainbow text

ESC / joystick fire / left mouse button exits cleanly (music stopped, screen
closed).

## Architecture

This is a native Amiga application, not an emulator port. The demo renderer
(`demo_core.c/h`) is OS-free — a pure function of tick that produces identical
pixels on both the Linux host harness and the Amiga. The Amiga driver
(`demo_main.c`) opens a Picasso96 RTG screen, loads a 256-colour palette via
LoadRGB32, plays a ProTracker module through Paula via ptplayer, and presents
each frame with WriteChunkyPixels at WaitTOF pace.

## Files

- `demo_core.c/h` — OS-free renderer (pure function of tick)
- `demo_main.c` — Amiga host (Picasso96 screen, ptplayer music, input)
- `host_demo.c` — Linux host harness for validation frame output
- `demo_pic.c` — Generated picture data (from `assets/pic_src.png`)
- `demo_sintab.h` — Generated sine lookup table
- `gen_assets.py` — Regenerates `demo_pic.c` and `demo_sintab.h`
- `intro_mod.s` — Embeds the ProTracker module as data
- `ptplayer/` — Vendored ptplayer, glue code, and house `.mod`
- `build.sh` — Build script (host + Amiga)
- `package.sh` — Packages into bootable RTG HDF + Amiberry config
- `hdf_safety.sh` — Shared HDF packaging guardrails

## Controls

- ESC / joystick fire / left mouse button — exit

## License

MIT (Crown Park Computing Ltd 2026)
