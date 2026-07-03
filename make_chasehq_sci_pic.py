#!/usr/bin/env python3
"""make_chasehq_sci_pic.py -- build the Chase H.Q. + S.C.I. selector composite.

The WhittyDemo two-game selector (demo_core.c draw_selector, text_variant 2)
expects a 2S x S "two square" picture: the left S x S square is the Chase H.Q.
flyer, the right S x S square is the S.C.I. flyer. Each panel is unveiled
independently, so they must be square and side by side with no gap in the
baked image (the gap is added at render time).

Sources (vendored under assets/src so the repo is self-contained):
  assets/src/src_chasehq.png   Taito Chase H.Q. flyer art
  assets/src/src_sci.png       Taito S.C.I. flyer art
Output:
  assets/pic_chasehq_sci_sq.png   (2S x S, fed to gen_assets.py with PIC_W=2S PIC_H=S)

Chase H.Q. is cropped hard-left so its full "CHASE H.Q." title survives; S.C.I.
is centre-cropped (title + detective are central).
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
S = 275  # square side; composite is 2S x S = 550 x 275 (both multiples of BLOCK=25)


def square(path, bias):
    """Crop the largest square from path (bias 0=left .. 1=right) and resize to SxS."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    side = min(w, h)
    left = int(round((w - side) * bias))
    top = (h - side) // 2
    return im.crop((left, top, left + side, top + side)).resize((S, S), Image.LANCZOS)


chq = square(os.path.join(HERE, "assets", "src", "src_chasehq.png"), bias=0.0)
sci = square(os.path.join(HERE, "assets", "src", "src_sci.png"), bias=0.5)

comp = Image.new("RGB", (2 * S, S))
comp.paste(chq, (0, 0))
comp.paste(sci, (S, 0))
out = os.path.join(HERE, "assets", "pic_chasehq_sci_sq.png")
comp.save(out)
print("wrote %s (%dx%d)" % (out, comp.size[0], comp.size[1]))
