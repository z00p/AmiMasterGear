"""AmiMasterGear big RTG menu (AMG_BIGMENU): Juan's logo redrawn at the screen's resolution.

    python -I tools/bigmenu_art.py [PREVIEW_DIR]

Writes src/data/hires_amglogo_1080.bin and _720.bin: the logo (325x51, 3 planes, his 8 pens)
at the size the menu kit would make by blocks (2 x 4 screen pixels a pixel of his at 1920x1080,
1 x 2 at 1280x720), as planar data (planes one after the other, rows of whole words, as an
Image's ImageData). PREVIEW_DIR (default build/art) gets a .png of each.

Drawn as AmiGameBoy 2.5's big menu logo (rtg-framework tools/agbart/logo.py, z00p): the wordmark
is Juan's own pixels (white letters, their black surround, the red dot) at screen size with the
corners rounded (a blur of the block shape cut at half: straight edges stay put, his 1-pixel
steps become curves); the oval line is drawn again as a stadium of even width through the middle
of his line, and kept only where his line is (his dashes beside "ami" and "gear", the gaps).
The four Joy type pictures are the same as AmiGameBoy's (Juan drew them once for both), so the
redrawn ones are AmiGameBoy 2.5's (src/data/hires_<name>_<size>.bin, tools/agbart/ctrl.py).
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "src", "data")
PAL = [(170, 170, 170), (0, 0, 0), (255, 255, 255), (102, 136, 187), (187, 68, 85), (85, 221, 85),
       (0, 68, 221), (136, 34, 204)]
GREY, K, W, LB, RED = range(5)
LW, LH = 325, 51
SIZES = {"1080": (2, 4), "720": (1, 2)}


def planar_in(path, w, h, d=3):
    b = open(path, "rb").read()
    bpr = (w + 15) // 16 * 2
    idx = np.zeros((h, w), np.uint8)
    for p in range(d):
        for y in range(h):
            row = b[(p * h + y) * bpr:(p * h + y + 1) * bpr]
            for x in range(w):
                if row[x >> 3] >> (7 - (x & 7)) & 1:
                    idx[y, x] |= 1 << p
    return idx


def planar_out(px, depth=3):
    h, w = px.shape
    bpr = (w + 15) // 16 * 2
    out = bytearray(bpr * h * depth)
    for p in range(depth):
        for y in range(h):
            base = (p * h + y) * bpr
            for x in range(w):
                if px[y, x] >> p & 1:
                    out[base + (x >> 3)] |= 0x80 >> (x & 7)
    return bytes(out)


def blur(a, s):
    r = int(s * 3) + 1
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / s) ** 2)
    k /= k.sum()
    a = np.apply_along_axis(lambda v: np.convolve(np.pad(v, r, mode="edge"), k, "valid"), 0, a)
    a = np.apply_along_axis(lambda v: np.convolve(np.pad(v, r, mode="edge"), k, "valid"), 1, a)
    return a


class Canvas:
    def __init__(self, w, h, sx, sy, bg):
        self.sx, self.sy = sx, sy
        self.px = np.full((h * sy, w * sx), bg, np.uint8)
        ys, xs = np.mgrid[0:h * sy, 0:w * sx]
        self.x = (xs + 0.5) / sx          # screen pixel centres in Juan's units
        self.y = (ys + 0.5) / sy

    def m_rect(self, x0, y0, x1, y1):
        return (self.x >= x0) & (self.x < x1) & (self.y >= y0) & (self.y < y1)

    def m_bitmap(self, mask, smooth):
        m = np.repeat(np.repeat(np.asarray(mask, float), self.sy, 0), self.sx, 1)
        if smooth > 0:
            m = blur(m, smooth) >= 0.5
        return m.astype(bool)

    def put(self, m, pen):
        self.px[m] = pen

    def image(self):
        h, w = self.px.shape
        im = Image.new("RGB", (w, h))
        im.putdata([PAL[v] for v in self.px.flatten()])
        return im


def logo(sx, sy):
    idx = planar_in(os.path.join(DATA, "AmiMasterGear_Logo.raw"), LW, LH)
    bg = int(np.bincount(idx.flatten()).argmax())          # his background pen
    c = Canvas(LW, LH, sx, sy, bg)
    line = max(2, sx * 2)                                    # the oval's width, screen pixels
    smooth = sx * 0.9
    white, red, black = idx == W, idx == RED, idx == K
    # the wordmark: the letters grown by his outline (4 across, 2 down); the black in that
    lett = white | red
    g = lett.copy()
    for _ in range(4):
        g[:, 1:] |= g[:, :-1].copy()
        g[:, :-1] |= g[:, 1:].copy()
    for _ in range(2):
        g[1:, :] |= g[:-1, :].copy()
        g[:-1, :] |= g[1:, :].copy()
    word = black & g
    oval = black & ~g
    # the oval's centre line: his top and bottom rows, left and right ends
    ys, xs = np.nonzero(oval)
    top, bot = ys.min(), ys.max()
    left, right = xs.min(), xs.max()
    cy = (top + bot + 1) / 2
    ry = (bot - top) / 2
    # the straight parts end where his curves start: the outermost columns of his top or bottom row
    rows = np.nonzero(oval[top] | oval[bot])[0]
    x0, x1 = rows.min() + 0.5, rows.max() + 0.5
    rx0 = x0 - (left + 0.5)
    rx1 = (right + 0.5) - x1
    X, Y = c.x, c.y
    hw = line / 2

    def inside(ox, oy):
        m = c.m_rect(x0, cy - ry - oy, x1, cy + ry + oy)
        m |= ((X - x0) / (rx0 + ox)) ** 2 + ((Y - cy) / (ry + oy)) ** 2 <= 1
        m |= ((X - x1) / (rx1 + ox)) ** 2 + ((Y - cy) / (ry + oy)) ** 2 <= 1
        return m
    ring = inside(hw / sx, hw / sy) & ~inside(-hw / sx, -hw / sy)
    # kept where his line is: on the straight parts a column of his top (bottom) row with no line
    # pixel within a row of it is a gap (his dashes, the breaks)
    have_t = np.zeros(LW, bool)
    have_b = np.zeros(LW, bool)
    for dy in (-1, 0, 1):
        if 0 <= top + dy < LH:
            have_t |= oval[top + dy]
        if 0 <= bot + dy < LH:
            have_b |= oval[bot + dy]
    col = np.clip(X.astype(int), 0, LW - 1)
    straight = (X >= x0) & (X < x1)
    gap = straight & (((Y < cy) & ~have_t[col]) | ((Y >= cy) & ~have_b[col]))
    ring &= ~gap
    c.put(ring, K)
    c.put(c.m_bitmap(word | lett, smooth), K)
    c.put(c.m_bitmap(white, smooth), W)
    c.put(c.m_bitmap(red, smooth * 0.5), RED)
    return c


def main():
    prev = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "art")
    os.makedirs(prev, exist_ok=True)
    for n, (sx, sy) in SIZES.items():
        c = logo(sx, sy)
        assert c.px.shape == (LH * sy, LW * sx) and c.px.max() < 8
        f = os.path.join(DATA, "hires_amglogo_%s.bin" % n)
        open(f, "wb").write(planar_out(c.px))
        c.image().save(os.path.join(prev, "hires_amglogo_%s.png" % n))
        print(f, c.px.shape[1], "x", c.px.shape[0])


if __name__ == "__main__":
    main()
