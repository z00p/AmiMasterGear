"""Build a Master System / Game Gear pad test cartridge: for each input its name, the Amiga button
that drives it in AmiMasterGear, and a box that fills while the console sees it held. Player 1
(Amiga port 2) and player 2 (Amiga port 1) from ports $DC/$DD, Pause (an NMI count and a box that
stays lit for 30 frames after each NMI) and the Game Gear's Start (port $00 bit 7). Everything
that matters sits in the Game Gear's 20x18 window; the raw port bytes are under it, SMS only.
Our own cartridge: own font, own code, no third-party data.

  python -I tools/padtest_sms.py [OUTDIR]    -> OUTDIR/PadTest.sms and PadTest.gg (default build/)

One Z80 source (written to OUTDIR/padtest/padtest.asm) assembled twice with sjasmplus, the second
time with -DGG=1 (Game Gear CRAM: 12-bit colour, two bytes per entry). Header "TMR SEGA" at $7FF0
with the checksum of $0000-$7FEF; region 4 (SMS export) for .sms, 7 (GG international) for .gg.
tools/padtest_mesen.lua drives the pads in Mesen 2 and grabs the screen.
sjasmplus (1.24 tested): set SJASMPLUS to its path, or have it on the PATH.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SJASM = os.environ.get("SJASMPLUS") or shutil.which("sjasmplus") or "sjasmplus"

FONT = {   # 5x7, top row first
    '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
    '1': ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    '2': ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
    '3': ['####.', '....#', '....#', '.###.', '....#', '....#', '####.'],
    '4': ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
    '5': ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
    '6': ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
    '7': ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
    '8': ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
    '9': ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..'],
    'A': ['.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'B': ['####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'],
    'C': ['.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.'],
    'D': ['####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'],
    'E': ['#####', '#....', '#....', '####.', '#....', '#....', '#####'],
    'F': ['#####', '#....', '#....', '####.', '#....', '#....', '#....'],
    'G': ['.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.###.'],
    'H': ['#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'],
    'I': ['.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.'],
    'K': ['#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'],
    'L': ['#....', '#....', '#....', '#....', '#....', '#....', '#####'],
    'M': ['#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#'],
    'N': ['#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'],
    'O': ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'P': ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
    'R': ['####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'],
    'S': ['.###.', '#...#', '#....', '.###.', '....#', '#...#', '.###.'],
    'T': ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
    'U': ['#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
    'V': ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
    'W': ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '##.##', '#...#'],
    'Y': ['#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'],
    '/': ['....#', '....#', '...#.', '..#..', '.#...', '#....', '#....'],
}
BLANK, EMPTY, FULL = 0, 1, 2          # tile numbers; the font follows
chars = sorted(FONT)
TILE = {c: 3 + i for i, c in enumerate(chars)}
TILE[' '] = BLANK

# colours as 4-bit R, G, B; palette 0 for names, palette 1 (attribute bit 3) for the hints.
# Palette 1 colour 0 is also the border (VDP R7 = 0 picks from the second palette).
NAVY, WHITE, GREEN, GREY, YELLOW = (0, 0, 5), (15, 15, 15), (2, 15, 2), (9, 9, 9), (15, 14, 4)
PALETTE = [NAVY, WHITE, GREEN, GREY] + [NAVY] * 12 + [NAVY, YELLOW, GREEN, GREY] + [NAVY] * 12


def tile4(rows):
    """8 rows of 8 colour digits ('.' = 0) -> 32 bytes of mode 4 tile (4 planes per row)."""
    out = bytearray()
    for r in rows:
        px = [0 if c == '.' else int(c) for c in r]
        for plane in range(4):
            out.append(sum(((p >> plane) & 1) << (7 - x) for x, p in enumerate(px)))
    return out


tiles = bytearray(32)                                                      # 0 blank
tiles += tile4(['........', '3333333.'] + ['3.....3.'] * 5 + ['3333333.'])  # 1 box, empty
tiles += tile4(['........', '3333333.'] + ['3222223.'] * 5 + ['3333333.'])  # 2 box, held
for c in chars:                         # a blank top row: the GG window's first line stays clear
    tiles += tile4(['........'] + ['.' + r.replace('#', '1') + '..' for r in FONT[c]])

# ---- screen: 32x28 name table entries; the Game Gear shows columns 6-25, rows 3-20
X0, Y0 = 6, 3
screen = [[(BLANK, 0)] * 32 for _ in range(28)]


def text(row, col, s, pal=0):
    for i, ch in enumerate(s):
        screen[Y0 + row][X0 + col + i] = (TILE[ch], pal)


def at(row, col):
    """VDP command word for a VRAM write to the name table entry at (row, col) in the GG window."""
    return 0x4000 | (0x3800 + ((Y0 + row) * 32 + X0 + col) * 2)


# (name, row, col of the name, port variable, bit); the box is 7 columns right of the name
BOXES = []
text(0, 6, 'PAD TEST')
text(1, 0, 'P1 PORT2  P2 PORT1', 1)
for i, name in enumerate(['UP', 'DOWN', 'LEFT', 'RIGHT', '1 RED', '2 BLUE']):
    text(3 + i, 0, name)
    BOXES.append((3 + i, 7, 'padDC', i))
    text(3 + i, 10, name)
    BOXES.append((3 + i, 17, 'padDC' if i < 2 else 'padDD', 6 + i if i < 2 else i - 2))
text(10, 0, 'PAUSE')
BOXES.append((10, 7, 'pauseLit', 0))
text(10, 10, 'NMIS')
NMI_AT = at(10, 15)
text(11, 1, 'GREEN OR PLAY', 1)
text(13, 0, 'START')
BOXES.append((13, 7, 'padGG', 7))
text(13, 10, 'GG ONLY')
text(14, 1, 'YELLOW OR PLAY', 1)
text(16, 0, 'KEYS 1 SPACE ALT', 1)
text(17, 0, 'KEYS 2 SHIFT AMIGA', 1)
# below the GG window (SMS only): the raw port bytes
screen[22][6:28] = [(BLANK, 0)] * 22
for i, ch in enumerate('PORTS DC    DD    00'):
    screen[22][6 + i] = (TILE[ch], 0)
RAW_AT = [0x4000 | (0x3800 + (22 * 32 + 6 + c) * 2) for c in (9, 15, 21)]
for row, col, var, bit in BOXES:
    screen[Y0 + row][X0 + col] = (EMPTY, 0)

ASM = r"""; PadTest: Master System / Game Gear pad test (generated by tools/padtest_sms.py; edit that)
VDPD	equ	$BE
VDPC	equ	$BF
vbflag	equ	$C000
nmicnt	equ	$C001
nmilit	equ	$C002
padDC	equ	$C003
padDD	equ	$C004
padGG	equ	$C005
pauseLit equ	$C006

	org	0
	di
	im	1
	ld	sp,$DFF0
	jp	start
	ds	$38-$,$FF
irq:	push	af			; frame interrupt: acknowledge, flag the main loop
	in	a,(VDPC)
	ld	a,1
	ld	(vbflag),a
	pop	af
	ei
	reti
	ds	$66-$,$FF
nmi:	push	af			; Pause: count, light the box for 30 frames
	ld	a,(nmicnt)
	inc	a
	ld	(nmicnt),a
	ld	a,30
	ld	(nmilit),a
	pop	af
	retn

start:	ld	hl,$C000
	ld	de,$C001
	ld	bc,$0FF
	ld	(hl),0
	ldir
	in	a,(VDPC)		; reset the control latch
	ld	hl,vdpregs
	ld	b,vdpregs_end-vdpregs
	ld	c,VDPC
	otir
	xor	a			; clear VRAM
	out	(VDPC),a
	ld	a,$40
	out	(VDPC),a
	ld	de,$4000
.clr:	xor	a
	out	(VDPD),a
	dec	de
	ld	a,d
	or	e
	jr	nz,.clr
	xor	a			; palette
	out	(VDPC),a
	ld	a,$C0
	out	(VDPC),a
	ld	hl,palette
	ld	b,palette_end-palette
	ld	c,VDPD
	otir
	xor	a			; tiles at $0000
	out	(VDPC),a
	ld	a,$40
	out	(VDPC),a
	ld	hl,tiles
	ld	de,tiles_end-tiles
	call	copy
	xor	a			; name table at $3800
	out	(VDPC),a
	ld	a,$78
	out	(VDPC),a
	ld	hl,screen
	ld	de,screen_end-screen
	call	copy
	xor	a			; no sprites
	out	(VDPC),a
	ld	a,$7F
	out	(VDPC),a
	ld	a,$D0
	out	(VDPD),a
	ld	a,$E0			; display on, frame interrupt on
	out	(VDPC),a
	ld	a,$81
	out	(VDPC),a
	ei

main:	ld	a,(vbflag)
	or	a
	jr	z,main
	xor	a
	ld	(vbflag),a
	in	a,($DC)
	ld	(padDC),a
	in	a,($DD)
	ld	(padDD),a
	in	a,($00)
	ld	(padGG),a
	ld	a,(nmilit)		; Pause box: "held" (bit 0 clear) while the NMI light is on
	or	a
	ld	b,$FF
	jr	z,.dark
	dec	a
	ld	(nmilit),a
	ld	b,$FE
.dark:	ld	a,b
	ld	(pauseLit),a
	ld	hl,boxes
	ld	b,NBOX
.box:	ld	a,(hl)			; VDP address
	out	(VDPC),a
	inc	hl
	ld	a,(hl)
	out	(VDPC),a
	inc	hl
	ld	e,(hl)			; variable
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,(de)
	and	(hl)			; 0 = held
	inc	hl
	ld	a,FULL
	jr	z,.put
	ld	a,EMPTY
.put:	out	(VDPD),a
	djnz	.box
	ld	de,NMI_AT		; NMI count in hex
	ld	a,(nmicnt)
	call	hex
	ld	de,RAW_DC		; raw port bytes (below the GG window)
	ld	a,(padDC)
	call	hex
	ld	de,RAW_DD
	ld	a,(padDD)
	call	hex
	ld	de,RAW_00
	ld	a,(padGG)
	call	hex
	jp	main

; DE = VDP address, A = byte: two hex digits
hex:	ld	c,a
	ld	a,e
	out	(VDPC),a
	ld	a,d
	out	(VDPC),a
	ld	a,c
	rrca
	rrca
	rrca
	rrca
	call	digit
	xor	a			; attribute of the first digit
	out	(VDPD),a
	ld	a,c
digit:	and	$0F
	ld	hl,hextab
	add	a,l
	ld	l,a
	adc	a,h
	sub	l
	ld	h,a
	ld	a,(hl)
	out	(VDPD),a
	ret

; HL = source, DE = byte count -> VDP data port
copy:	ld	a,(hl)
	out	(VDPD),a
	inc	hl
	dec	de
	ld	a,d
	or	e
	jr	nz,copy
	ret

vdpregs:
	db	$04,$80			; R0: mode 4
	db	$80,$81			; R1: display off for now
	db	$FF,$82			; R2: name table $3800
	db	$FF,$83,$FF,$84
	db	$FF,$85			; R5: sprite table $3F00
	db	$FB,$86			; R6: sprite tiles $0000
	db	$00,$87			; R7: border = sprite palette colour 0
	db	$00,$88,$00,$89		; no scroll
	db	$FF,$8A			; no line interrupt
vdpregs_end:

palette:
	IFDEF	GG
@GGPAL@
	ELSE
@SMSPAL@
	ENDIF
palette_end:
"""


def db(data, per=16):
    return "\n".join("\tdb\t" + ",".join("$%02X" % b for b in data[i:i + per])
                     for i in range(0, len(data), per))


def build(outdir):
    work = os.path.join(outdir, "padtest")
    os.makedirs(work, exist_ok=True)
    sms_pal = bytes((r >> 2) | (g >> 2) << 2 | (b >> 2) << 4 for r, g, b in PALETTE)
    gg_pal = bytes(x for r, g, b in PALETTE for x in (g << 4 | r, b))
    name = bytes(x for row in screen for t, p in row for x in (t, 8 if p else 0))
    src = ASM.replace("@GGPAL@", db(gg_pal)).replace("@SMSPAL@", db(sms_pal))
    src += "boxes:\n" + "".join("\tdw\t$%04X,%s\n\tdb\t$%02X\n" % (at(r, c), v, 1 << b)
                                for r, c, v, b in BOXES) + "boxes_end:\n"
    src += "hextab:\n" + db([TILE[c] for c in "0123456789ABCDEF"]) + "\n"
    src += "tiles:\n" + db(tiles) + "\ntiles_end:\n"
    src += "screen:\n" + db(name) + "\nscreen_end:\n"
    src += "\tASSERT\t$ <= $7FF0\n"
    defs = "EMPTY\tequ\t%d\nFULL\tequ\t%d\nNMI_AT\tequ\t$%04X\nRAW_DC\tequ\t$%04X\nRAW_DD\tequ\t$%04X\nRAW_00\tequ\t$%04X\nNBOX\tequ\t%d\n" % (
        EMPTY, FULL, NMI_AT, *RAW_AT, len(BOXES))
    asm = os.path.join(work, "padtest.asm").replace("\\", "/")
    with open(asm, "w", newline="\n") as fh:
        fh.write(defs + src)
    for ext, defines, region in (("sms", [], 0x4), ("gg", ["-DGG=1"], 0x7)):
        raw = os.path.join(work, "padtest-%s.bin" % ext).replace("\\", "/")
        r = subprocess.run([SJASM, "--nologo", "--msg=war", *defines, "--raw=" + raw, asm],
                           capture_output=True, text=True)
        if r.returncode:
            sys.exit(r.stdout + r.stderr)
        code = open(raw, "rb").read()
        rom = bytearray(b"\xFF" * 0x8000)
        rom[:len(code)] = code
        rom[0x7FF0:0x7FF8] = b"TMR SEGA"
        rom[0x7FF8:0x7FFA] = b"\0\0"
        s = sum(rom[:0x7FF0]) & 0xFFFF
        rom[0x7FFA:0x7FFC] = bytes([s & 255, s >> 8])
        rom[0x7FFC:0x7FFF] = b"\0\0\0"      # product code 0, version 0
        rom[0x7FFF] = region << 4 | 0xC        # $C = 32K, checksum over $0000-$7FEF
        path = os.path.join(outdir, "PadTest." + ext)
        with open(path, "wb") as fh:
            fh.write(rom)
        print("%s: code+data %d bytes, checksum $%04X" % (path, len(code), s))


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build"))
