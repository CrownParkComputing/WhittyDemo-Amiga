/* demo_core.h -- WhittyDemo: pure-C old-school demo intro renderer.
 *
 * OS-free chunky renderer in the family shared-core style: the same code runs
 * on the Linux host harness (PPM validation) and inside the Amiga exe. The
 * host binds a w*h 8-bit chunky framebuffer; demo_frame() is a pure function
 * of the tick so host and Amiga render byte-identical frames.
 *
 * Effects (demos gone by): copper-gradient backdrop + bouncing rainbow raster
 * bars, parallax starfield, a filled flat-shaded 3D ring (torus) spinning
 * around the centrepiece with solid isometric shapes (cube / octahedron /
 * tetrahedron) orbiting it, a picture painted piece by piece inside a rainbow
 * frame, a wavy rainbow title and a big rainbow sine scroller.
 */
#ifndef DEMO_CORE_H
#define DEMO_CORE_H

/* 256-entry RGB palette the presenter must upload (LoadRGB32 / PPM). */
extern unsigned char demo_pal[256][3];

/* One-time init: builds palette, gradient, reveal permutation. */
void demo_init(int w, int h);

/* Render one frame into fb (w*h pens). Pure function of tick. */
void demo_frame(unsigned char *fb, int tick);

#endif
