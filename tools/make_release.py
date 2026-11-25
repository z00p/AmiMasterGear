"""Stage the AmiMasterGear release drawer (the archive itself is made with the Amiga's own LhA).

  python tools/make_release.py [--version 1.2] [--draft]   -> build/release/

Builds the program (`sh build.sh rel`) and the pad test cartridges (tools/padtest_sms.py, needs
sjasmplus) and stages:

  build/release/AmiMasterGear.info          the drawer's icon
  build/release/AmiMasterGear/
    AmiMasterGear, AmiMasterGear.info       the program, its icon (release/icons, positions cleared)
    ReadMe.txt, AmiMasterGear.guide         docs/package/ReadMe.txt, and a guide made from it
    CHANGES.txt, NOTICE.txt                 from CHANGES.md and NOTICE.md (ASCII, 79 columns)
    Cartridges/ (+ .info)                   PadTest.sms, PadTest.gg and a note (no icons)
    Frozen/ (+ .info)                       a note (no icon)

No games: the script stops if any cartridge image other than the pad tests, byte for byte as
built here, is staged. Every icon is left without a position (NO_ICON_POSITION), so Workbench
places them. The drawer and page icons are drawn here (the same drawings as AmiPCEngine's).
Needs Pillow.
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import textwrap

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "release")
PKG = os.path.join(OUT, "AmiMasterGear")
ROM_EXT = {".sms", ".gg", ".sg", ".sc", ".mv", ".sav", ".zip", ".lha", ".lzx", ".rom", ".bin"}
NOPOS = struct.pack(">ii", -0x80000000, -0x80000000)
CART_NOTE = ("Put your cartridge images (.sms and .gg files) here, or browse to them\n"
             "anywhere else: AmiMasterGear's Insert requester opens this drawer.\n"
             "PadTest.sms and PadTest.gg are the pad test (see ReadMe.txt).\n")
FROZEN_NOTE = ("Load Frozen and Save Frozen open this drawer. A frozen game is the whole\n"
               "state of a running game, saved as a .Frozen file.\n")


# ---- text for the Amiga -----------------------------------------------------

ASCII = {"‘": "'", "’": "'", "“": '"', "”": '"', "–": "-", "—": "-",
         "…": "...", "→": "->", "\xf3": "o", "\xe1": "a", "\xe9": "e", "\xed": "i",
         "\xfa": "u", "\xf1": "n", "\xd3": "O", "\xc1": "A"}


def amiga_text(src, version, wrap=0, markdown=False):
    """LF line ends, ASCII, @VERSION@ filled in, at most 79 columns."""
    t = open(src, "rb").read().decode("utf-8").replace("\r\n", "\n")
    for a, b in ASCII.items():
        t = t.replace(a, b)
    t = t.replace("@VERSION@", version)
    if markdown:
        t = re.sub(r"`([^`\n]+)`", r"\1", t).replace("**", "")   # inline code; fences stay
        t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", t)
    if wrap:   # Markdown: join each paragraph or list item, then wrap it, keeping the list indent
        joined, pre = [], False
        for line in t.split("\n"):
            if line.startswith("```"):
                pre = not pre
                joined.append(line)
            elif (not pre and joined and line.strip() and joined[-1].strip()
                  and not re.match(r"\s*(?:[-*] |\d+\. |#|\|)", line) and not joined[-1].startswith("#")):
                joined[-1] += " " + line.strip()
            else:
                joined.append(line)
        out, pre = [], False
        for line in joined:
            if line.startswith("```"):
                pre = not pre
                continue
            if pre:
                out.append(line)
                continue
            ind = " " * len(re.match(r"\s*(?:[-*] |\d+\. )?", line).group(0))
            out += textwrap.wrap(line, wrap, subsequent_indent=ind, break_long_words=False,
                                 break_on_hyphens=False) or [""]
        t = "\n".join(out)
    bad = [c for c in t if ord(c) > 126 or (ord(c) < 32 and c != "\n")]
    if bad:
        sys.exit("%s: non-ASCII or control character %r" % (src, bad[0]))
    for n, line in enumerate(t.split("\n"), 1):
        if len(line) > 79:
            sys.exit("%s:%d: %d columns" % (src, n, len(line)))
    return t


def guide(readme, version):
    """AmigaGuide from the ReadMe: the text before the first section is the main node."""
    body = readme.split("\n", 2)[2]                       # without the title lines
    parts = re.split(r"\n([^\n]+)\n-{3,}\n", "\n" + body)
    intro, secs = parts[0].strip("\n"), list(zip(parts[1::2], parts[2::2]))
    esc = lambda s: s.replace("\\", "\\\\").replace("@", "\\@")
    out = ["@database AmiMasterGear.guide",
           "@$VER: AmiMasterGear.guide %s (25.11.2026)" % version,
           "@author Juan Antonio Gomez Galvez and z00p",
           '@node MAIN "AmiMasterGear %s"' % version, "", esc(intro), ""]
    for i, (title, _) in enumerate(secs):
        out.append('    @{" %-20s " link S%d}' % (title, i))
    out += ["", "@endnode"]
    for i, (title, body) in enumerate(secs):
        out += ["", '@node S%d "%s"' % (i, title), "", title, "-" * len(title), "",
                esc(body.strip("\n")), "", "@endnode"]
    return "\n".join(out) + "\n"


# ---- icons (drawings as AmiPCEngine's tools/make_release.py) ----------------

def lstr(s):
    s = s.encode("latin-1") + b"\0"
    return struct.pack(">I", len(s)) + s


W = H = 46
PENS = [(170, 170, 170), (0, 0, 0), (255, 255, 255), (102, 136, 187)]   # Workbench 1.x/2.x pens


def draw_drawer():
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (W, H), (255, 0, 255))
    d = ImageDraw.Draw(im)
    out, base, lite, dark, shade = (24, 32, 56), (66, 106, 172), (104, 144, 206), (40, 66, 124), (60, 60, 70)
    top, mid, bot = 11, 25, 39

    def lid_x(y):
        t = (y - top) / (mid - top)
        return round(10 - 4 * t), round(36 + 4 * t)
    for y in range(top, mid):
        a, b = lid_x(y)
        for x in range(a, b + 1):
            d.point((x, y), fill=lite if (x + y) % 2 == 0 and y < mid - 3 else base)
        d.point((a, y), fill=out); d.point((b, y), fill=out)
        d.point((b + 1, y + 1), fill=shade)
    d.line([12, top, 34, top], fill=out)
    d.point((11, top + 1), fill=out); d.point((35, top + 1), fill=out)
    d.line([7, mid - 1, 39, mid - 1], fill=(150, 180, 226))
    d.rectangle([6, mid, 40, bot], fill=base, outline=out)
    for y in range(mid + 1, mid + 5):
        for x in range(7, 40):
            if (x + y) % 2 == 0:
                d.point((x, y), fill=lite)
    d.line([39, mid + 1, 39, bot - 1], fill=dark)
    d.line([7, bot - 1, 39, bot - 1], fill=dark)
    d.line([41, mid + 1, 41, bot + 1], fill=shade); d.line([7, bot + 1, 41, bot + 1], fill=shade)
    d.rounded_rectangle([15, bot - 7, 31, bot - 3], radius=2, fill=(240, 240, 240), outline=out)
    d.line([17, bot - 4, 29, bot - 4], fill=(150, 150, 160))
    return im


def draw_page():
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (W, H), (255, 0, 255))
    d = ImageDraw.Draw(im)
    out, paper, fold, line, shade = (24, 32, 56), (250, 250, 250), (200, 206, 218), (150, 150, 160), (60, 60, 70)
    l, t, r, b, c = 11, 5, 34, 40, 7
    d.polygon([(l, t), (r - c, t), (r, t + c), (r, b), (l, b)], fill=paper, outline=out)
    d.polygon([(r - c, t), (r - c, t + c), (r, t + c)], fill=fold, outline=out)
    for y in range(t + 10, b - 3, 4):
        d.line([l + 4, y, r - 4 - (7 if y % 12 == 3 else 0), y], fill=line)
    d.line([r + 1, t + c + 1, r + 1, b + 1], fill=shade); d.line([l + 1, b + 1, r + 1, b + 1], fill=shade)
    return im


def planar(im):
    rows = (W + 15) // 16 * 2
    planes = [bytearray(rows * H) for _ in range(2)]
    px = im.load()
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            pen = 0 if c == (255, 0, 255) else min(range(4), key=lambda k: sum((a - b) ** 2 for a, b in zip(c, PENS[k])))
            for p in range(2):
                if pen >> p & 1:
                    planes[p][y * rows + x // 8] |= 0x80 >> (x & 7)
    return struct.pack(">hhhhhIBBI", 0, 0, W, H, 2, 1, 3, 0, 0) + bytes(planes[0]) + bytes(planes[1])


def glow(im):
    from PIL import Image
    q = im.convert("P", palette=Image.ADAPTIVE, colors=63)
    pal = q.getpalette()[:63 * 3]
    src, qp = im.load(), q.load()
    pixels = bytearray()
    for y in range(H):
        for x in range(W):
            pixels.append(0 if src[x, y] == (255, 0, 255) else qp[x, y] + 1)
    palette = bytes([0, 0, 0]) + bytes(pal)
    ncol = len(palette) // 3

    def chunk(tag, data):
        return tag + struct.pack(">I", len(data)) + data + (b"\0" if len(data) & 1 else b"")
    face = struct.pack(">BBBBH", W - 1, H - 1, 1, 0x11, len(palette) - 1)
    imag = struct.pack(">BBBBBBHH", 0, ncol - 1, 3, 0, 0, 8, len(pixels) - 1, len(palette) - 1)
    form = b"ICON" + chunk(b"FACE", face) + chunk(b"IMAG", imag + bytes(pixels) + palette)
    return b"FORM" + struct.pack(">I", len(form)) + form


def project_icon(im, default_tool):
    gadget = struct.pack(">IhhhhHHHIIIIIHI", 0, 0, 0, W, H + 1, 4, 3, 1, 1, 0, 0, 0, 0, 0, 1)
    head = struct.pack(">HH", 0xE310, 1) + gadget + struct.pack(
        ">BBIIiiIII", 4, 0, 1, 0, -0x80000000, -0x80000000, 0, 0, 4096)   # WBPROJECT, no position
    assert len(head) == 78, len(head)
    return head + planar(im) + lstr(default_tool) + glow(im)


def drawer_icon(im, w=420, h=200):
    gadget = struct.pack(">IhhhhHHHIIIIIHI", 0, 0, 0, W, H + 1, 4, 3, 1, 1, 0, 0, 0, 0, 0, 1)
    head = struct.pack(">HH", 0xE310, 1) + gadget + struct.pack(
        ">BBIIiiIII", 2, 0, 0, 0, -0x80000000, -0x80000000, 1, 0, 4096)   # WBDRAWER, DrawerData
    assert len(head) == 78, len(head)
    nw = struct.pack(">hhhhBBIIIIIIIhhHHH", 60, 40, w, h, 255, 255, 0, 0, 0, 0, 0, 0, 0, 90, 40, 0xFFFF, 0xFFFF, 1)
    dd = nw + struct.pack(">ii", 0, 0)
    assert len(dd) == 56, len(dd)
    return head + dd + planar(im) + struct.pack(">IH", 0, 0) + glow(im)


def no_position(icon):
    icon = bytearray(icon)
    assert icon[:2] == b"\xe3\x10", "not an icon"
    icon[58:66] = NOPOS                                                # NO_ICON_POSITION
    return bytes(icon)


# ---- staging ----------------------------------------------------------------

def put(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(data if isinstance(data, bytes) else data.encode("ascii"))


def build_program(version):
    if subprocess.run(["sh", "build.sh", "rel"], cwd=ROOT).returncode:
        sys.exit("sh build.sh rel failed")
    exe = os.path.join(ROOT, "build", "rel", "AmiMasterGear")
    d = open(exe, "rb").read()
    if struct.unpack(">I", d[:4])[0] != 0x3F3:
        sys.exit("not an Amiga executable")
    if b"$VER: AmiMasterGear %s " % version.encode() not in d:
        sys.exit("the program's $VER is not %s" % version)
    for bad in (b"@ERR ", b"@START", b"@END"):
        if bad in d:
            sys.exit("test code in the program ('%s')" % bad.decode())
    return exe, d


def pad_tests():
    with tempfile.TemporaryDirectory() as t:
        subprocess.run([sys.executable, "-I", os.path.join(ROOT, "tools", "padtest_sms.py"), t],
                       check=True, capture_output=True)
        return {n: open(os.path.join(t, n), "rb").read() for n in ("PadTest.sms", "PadTest.gg")}


def unfinished(texts):
    """Placeholders left in the texts: "PENDING" or an @NAME@ still to fill in."""
    return sorted({m for t in texts for m in re.findall(r"PENDING|@[A-Z0-9]+@", t)})


def stage(version, draft=False):
    exe, prog = build_program(version)
    pads = pad_tests()
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(PKG)
    shutil.copy(exe, os.path.join(PKG, "AmiMasterGear"))
    put(os.path.join(PKG, "AmiMasterGear.info"),
        no_position(open(os.path.join(ROOT, "release", "icons", "AmiMasterGear.info"), "rb").read()))
    readme = amiga_text(os.path.join(ROOT, "docs", "package", "ReadMe.txt"), version)
    put(os.path.join(PKG, "ReadMe.txt"), readme)
    put(os.path.join(PKG, "AmiMasterGear.guide"), guide(readme, version))
    put(os.path.join(PKG, "CHANGES.txt"), amiga_text(os.path.join(ROOT, "CHANGES.md"), version, 76, True))
    put(os.path.join(PKG, "NOTICE.txt"), amiga_text(os.path.join(ROOT, "NOTICE.md"), version, 76, True))
    left = unfinished(open(os.path.join(PKG, f), encoding="ascii").read()
                      for f in ("ReadMe.txt", "CHANGES.txt", "NOTICE.txt"))
    if left:
        print("unfinished text: " + ", ".join(left))
        if not draft:
            sys.exit("not a release: fill these in, or stage with --draft")
    page = project_icon(draw_page(), "SYS:Utilities/MultiView")
    for f in ("ReadMe.txt", "AmiMasterGear.guide", "CHANGES.txt", "NOTICE.txt"):
        put(os.path.join(PKG, f + ".info"), page)
    di = drawer_icon(draw_drawer())
    put(os.path.join(OUT, "AmiMasterGear.info"), drawer_icon(draw_drawer(), 460, 220))
    for name, fname, note in (("Cartridges", "Put cartridges here.txt", CART_NOTE),
                              ("Frozen", "Frozen games go here.txt", FROZEN_NOTE)):
        put(os.path.join(PKG, name + ".info"), di)
        put(os.path.join(PKG, name, fname), note)
    for n, data in pads.items():
        put(os.path.join(PKG, "Cartridges", n), data)
    # checks
    files = []
    for root, _, names in os.walk(OUT):
        for f in sorted(names):
            p = os.path.join(root, f)
            rel = os.path.relpath(p, OUT).replace(os.sep, "/")
            if os.path.splitext(f)[1].lower() in ROM_EXT and pads.get(f) != open(p, "rb").read():
                sys.exit("cartridge-like file staged: " + rel)
            if len(f) > 30:
                sys.exit("name over 30 characters: " + rel)
            if f.endswith(".info") and open(p, "rb").read()[58:66] != NOPOS:
                sys.exit("icon with a position: " + rel)
            if f != "AmiMasterGear" and os.path.getsize(p) > 100000:
                sys.exit("unexpected large file: " + rel)
            files.append((rel, os.path.getsize(p)))
    for rel, size in files:
        print("%9d  %s" % (size, rel))
    print("%d files in %s" % (len(files), OUT))


if __name__ == "__main__":
    a = sys.argv[1:]
    stage(a[a.index("--version") + 1] if "--version" in a else "1.2", "--draft" in a)
