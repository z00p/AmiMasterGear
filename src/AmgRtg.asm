; AmgRtg.asm: AmiMasterGear 2.0's RTG program (AMG_RTG): the picture on a 16-bit Picasso96 screen
; of the size that fits the console's picture best (AmgRtgFind), at the largest whole-number scale
; that fits; the board's scaler (VideoCore, MiSTer) takes it to the display. Design: docs/rtg-design.md.
;
; As AmiGameBoy 2.5's RTG program (gbc_rtg.s): the screen is opened and its bitmap address read with
; the OS alive (AmgRtgOpen, from the menu's PowerON just before MasterGearEmul); in play the emulator
; has the machine and the bitmap is written directly, with no OS or Picasso96 call.
;  - Juan's display has no picture buffer (the AGA chipset puts the background bitmap, the sprite
;    overlay and the copper's palette and scroll changes together), so this file draws its own:
;    a Mode 4 line renderer (AmgRtgLine) called as the emulated beam leaves each picture line
;    (AmgRtgMI, from MiraInter), from VRAM, VDPRegs and the palette RAM as they are then. Changes
;    made during a line show on that line, as the copper shows them in the AGA program.
;  - At the frame's end (AmgRtgFrame, from Emula1Frame) the lines that differ from the last copy
;    go to the screen, each pixel s x s; none of the AGA drawing runs.
;  - Pacing: a CIA-B timer from ciab.resource, run as a free counter (its interrupt stays off: Juan's
;    takeover never reads the CIA interrupt registers, so the OS's own CIA-B flags are left alone),
;    read against the console's frame time (59.92 Hz NTSC or 49.70 Hz PAL, the Screen setting).
;    Never the RTG refresh.
; No P96 mode in a format of AmgRtgFmts that holds the picture, or a screen that does not open:
; AmgRtgOn stays clear and the program runs as the AGA program.
; Not drawn yet: the TMS9918 (SG-1000) modes (a black line).
;
; Game-screen options (test feedback, 26 Nov 2026), set in AmgRtgCfg.asm (AMG_RTGCFG: AmiMasterGear.config
; and ToolTypes): Screen = Sharp | Bigger (AmgRtgFind), Scanlines (AMG_RTGSCAN, AmgRtgCopyS) and
; Buffering = Double (AMG_RTGDBUF): the screen opens two pages tall, each frame goes to the hidden
; page and a ScrollVPort shows it. The Emu68 VideoCore's ScrollVPort spins until the display's
; vertical blank (rtg-framework BENCH-RESULTS.md, 27 Oct 2026: ~9.5 ms on average, to the start of
; the blank), so the pan is not made at the frame's end but just before the next blank: its time
; and period are measured with the OS alive at open (AmgRtgVbCal, pans to the two black pages, as
; rtgfw's RTG_F_VBLANK) and every pan's return is a new anchor. The pan waits for its moment in
; the E-clock wait (AmgRtgFrame) or, while the next frame runs, every AMGR_POLLN lines (AmgRtgMI).
; A frame ready before the last one was shown replaces it in the hidden page (60 Hz games on a
; 50 Hz display drop one in six, never slow down). A board whose pan returns at once (uaegfx) or
; gives no steady period: the pan at the frame's end. The pacing stays on the E clock.

AMGR_MAXS	= 8		; largest scale
AMGR_FITS	= 3		; largest scale AmgRtgFind counts: a low mode, the board scales the rest
AMGR_MENUH2	= 270		; menu mode height tried first: 4 x 270 = 1080, a clean 4x on a 1080p scaler
AMGR_RTG_W	= 256		; the frame in fast RAM: 256 x 224 words, the screen's pixel format
AMGR_RTG_H	= 224
	IFD	AMG_RTGDBUF
	IFND	AMG_RTGCFG
	FAIL	"AMG_RTGDBUF needs AMG_RTGCFG"
	ENDC
	IFND	AMGR_LEAD		; (tests: -DAMGR_LEAD=n)
AMGR_LEAD	= 3547		; E clocks (5 ms): the pan is started this long before the blank
	ENDC
AMGR_LONG	= 1773		; a pan longer than 2.5 ms waited past its blank (counted)
AMGR_GAP	= 1419		; calibration: 2 ms after a pan's return, so the next waits a whole refresh
AMGR_PMIN	= 5675		; a display period of 8-25 ms, or the pans give no steady blank
AMGR_PMAX	= 17734
AMGR_PTOL	= 284		; 400 us
AMGR_POLLN	= 8		; lines between the pan checks in the line loop
	ENDC
	IFD	AMG_RTGSCAN
	IFND	AMG_RTGCFG
	FAIL	"AMG_RTGSCAN needs AMG_RTGCFG"
	ENDC
	ENDC

	IFD	AMG_SYNCLOG
	IFND	AMG_RTGDBUF
	FAIL	"AMG_SYNCLOG needs AMG_RTGDBUF"
	ENDC
; test builds: one sync-log event (AmgSyncLog), type \1, info \2; keeps every register (not CCR)
SYNCEV	MACRO
	MOVEM.L	D1-D2,-(SP)
	MOVEQ	#\1,D1
	MOVE.W	\2,D2
	BSR	AmgSyncLog
	MOVEM.L	(SP)+,D1-D2
	ENDM
	ENDC

	SECTION	AmgRtgCode,CODE

; ---- PowerON, before MasterGearEmul: OS alive. Keeps every register.
AmgRtgOpen:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	SF	AmgRtgOn
	SF	AmgRtgDraw
	BSR	AmgRtgTables
	MOVE.L	4.W,A6
	LEA	AmgRtgGfxN(PC),A1
	MOVEQ	#39,D0
	JSR	-552(A6)		; OpenLibrary
	MOVE.L	D0,AmgRtgGfx
	BEQ	.fail
	LEA	AmgRtgIntN(PC),A1
	MOVEQ	#39,D0
	JSR	-552(A6)
	MOVE.L	D0,AmgRtgInt
	BEQ	.fail
	LEA	AmgRtgP96N(PC),A1
	MOVEQ	#2,D0
	JSR	-552(A6)
	MOVE.L	D0,AmgRtgP96
	BEQ	.fail
	BSR	AmgRtgFind		; D0 = ModeID, 0 = none
	TST.L	D0
	BEQ	.fail
	MOVE.L	D0,AmgRtgTagM+4
	IFD	AMG_RTGDBUF
	SF	AmgRtgDbl
	SF	AmgRtgFlipPend
	CLR.L	AmgRtgPgOff
	CLR.L	AmgRtgVper
	CLR.B	AmgRtgPg
	CLR.B	AmgRtgLastPg
	TST.B	AmgCfgBuf		; "Buffering = Double": the screen two pages tall
	BEQ.S	.one
	MOVE.L	AmgRtgTagH+4,D0
	ADD.L	D0,AmgRtgTagH+4
	SUB.L	A0,A0
	LEA	AmgRtgTags,A1
	MOVE.L	AmgRtgInt,A6
	JSR	-612(A6)		; OpenScreenTagList
	MOVE.L	D0,AmgRtgScr
	BEQ.S	.half
	ST	AmgRtgDbl
	BRA.S	.opened
.half:	MOVE.L	AmgRtgTagH+4,D0		; it does not open: one page
	LSR.L	#1,D0
	MOVE.L	D0,AmgRtgTagH+4
.one:
	ENDC
	SUB.L	A0,A0
	LEA	AmgRtgTags,A1
	MOVE.L	AmgRtgInt,A6
	JSR	-612(A6)		; OpenScreenTagList
	MOVE.L	D0,AmgRtgScr
	BEQ	.fail
	IFD	AMG_RTGDBUF
.opened:
	ENDC
	BSR	AmgRtgPtrOn		; no mouse pointer on the game screen
	MOVE.L	AmgRtgGfx,A6
	JSR	-270(A6)		; WaitTOF
	JSR	-270(A6)
	IFD	AMG_RTGWAIT
; test switch (26 Nov 2026, black screen on the A1200 PiStorm): AMG_RTGWAIT more frames with the
; OS alive, in case the board's switch from the AGA menu to this RTG screen finishes after the
; two WaitTOFs and the takeover then stops it half way (AmiGameBoy's and AmiPCEngine's menus are
; on RTG already, so they never switch here).
	MOVE.W	#AMG_RTGWAIT-1,D7
.wt:	JSR	-270(A6)
	DBF	D7,.wt
	ENDC
	MOVE.L	AmgRtgScr,A0
	MOVE.L	$58(A0),A0		; sc_RastPort.rp_BitMap
	MOVE.L	A0,AmgRtgBm
	LEA	AmgRtgRI,A1
	MOVEQ	#12,D0
	MOVE.L	AmgRtgP96,A6
	JSR	-48(A6)			; p96LockBitMap
	MOVE.L	D0,D7
	BEQ	.fail
	MOVE.L	AmgRtgRI,AmgRtgMem
	MOVEQ	#0,D0
	MOVE.W	AmgRtgRI+4,D0
	MOVE.L	D0,AmgRtgBpr
	MOVE.L	AmgRtgRI+8,D6		; RGBFormat
	MOVE.L	AmgRtgBm,A0
	MOVE.L	D7,D0
	JSR	-54(A6)			; p96UnlockBitMap (not held across the play)
	MOVE.L	D6,D0
	BSR	AmgRtgFmtFlags
	TST.W	D0
	BMI	.fail
	MOVE.B	D0,AmgRtgPix
	BSR	AmgRtgLuts		; the colours in this format
	SF	AmgRtgPalV		; (so the line colours are made again)
	IFD	AMG_RTGSCAN
	BSR	AmgRtgScPrep		; the scanline table for this style and format
	ENDC
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgDbl
	BEQ.S	.pg
	MOVE.L	AmgRtgBpr,D0		; page 1: the lower half
	MULU	AmgRtgScrH,D0
	MOVE.L	D0,AmgRtgPgOff
	MOVE.B	#1,AmgRtgPg		; drawn into page 1 first, page 0 shown
.pg:
	ENDC
	BSR	AmgRtgClear		; the whole screen black
	BSR	AmgRtgTimerOn		; the pacing clock
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgDbl
	BEQ.S	.nc
	CMP.B	#1,AmgCfgBuf		; "Double": the pans timed to the blank, if it is steady
	BNE.S	.nc
	BSR	AmgRtgVbCal
.nc:
	ENDC
	CLR.W	AmgRtgH			; the layout at the first frame
	ST	AmgRtgDrawNext
	IFD	AMG_SYNCLOG
	CLR.L	AmgSyncI		; a new log for this play
	CLR.L	AmgSyncCnt
	ENDC
	ST	AmgRtgOn
	BRA.S	.x
.fail:	BSR	AmgRtgShut		; no RTG: the AGA picture
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; ---- PowerON, after MasterGearEmul: OS alive. Keeps every register.
AmgRtgClose:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFD	AMG_SYNCLOG
	BSR	AmgSyncWrite		; the play's sync log to PROGDIR:
	ENDC
	BSR	AmgRtgShut
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

AmgRtgShut:
	SF	AmgRtgOn
	SF	AmgRtgDraw
	IFD	AMG_RTGDBUF
	SF	AmgRtgFlipPend
	ENDC
	BSR	AmgRtgTimerOff
	BSR	AmgRtgPtrOff
	MOVE.L	AmgRtgScr,D0
	BEQ.S	.ns
	CLR.L	AmgRtgScr
	MOVE.L	D0,A0
	MOVE.L	AmgRtgInt,A6
	JSR	-66(A6)			; CloseScreen
.ns:	MOVE.L	4.W,A6
	LEA	AmgRtgGfx,A2
	MOVEQ	#3-1,D2
.cl:	MOVE.L	(A2),D0
	BEQ.S	.n
	CLR.L	(A2)
	MOVE.L	D0,A1
	JSR	-414(A6)		; CloseLibrary
.n:	ADDQ.L	#4,A2
	DBF	D2,.cl
	RTS

; ---- the play mode: the P96 mode in one of our formats that the console's picture fills best
; (test feedback, 26 Nov 2026: a low mode near the console's own size, as the other RTG programs; the board
; scales it to the display). For each mode: the picture at the largest whole-number scale that fits
; (AMGR_FITS at most, so a big mode scores no better than a small one), scored by the share of the mode's height it fills; Master System scores the
; 192-line and the 224-line picture together, as one screen serves both (a game can switch in play).
; The highest score wins, a smaller mode on a tie. Modes wider than 16:9 are left out (the scaler
; would letterbox them). AMG_RTGHALF: 960x540 first (an exact half of 1080p), then 640x480, then
; the best fit (AmiGameBoy's and AmiPCEngine's order).
; OS alive. Out: D0 = ModeID or 0; AmgRtgScrW/H and the screen tags set.
AmgRtgFind:
	MOVEM.L	D1-D7/A0-A6,-(SP)
	MOVE.W	#256,AmgRtgFW		; Master System: 256 wide, 192 and 224 lines
	MOVE.W	#192,AmgRtgFH1
	MOVE.W	#224,AmgRtgFH2
	TST.B	DirPrefs+$16		; the console of this run (MasterGearEmul copies it to Consola)
	BEQ.S	.ms
	MOVE.W	#160,AmgRtgFW		; Game Gear: the 160x144 LCD
	MOVE.W	#144,AmgRtgFH1
	MOVE.W	#144,AmgRtgFH2
.ms:	MOVEQ	#0,D6			; best score so far (higher is better)
	MOVEQ	#0,D5			; its ModeID
	MOVEQ	#0,D7			; its area
	MOVEQ	#-1,D4
.next:	MOVE.L	D4,D0
	MOVE.L	AmgRtgGfx,A6
	JSR	-732(A6)		; NextDisplayInfo
	MOVE.L	D0,D4
	CMP.L	#-1,D4
	BEQ	.done
	MOVEQ	#6,D1			; P96IDA_ISP96
	BSR	.attr
	TST.L	D0
	BEQ.S	.next
	MOVEQ	#5,D1			; P96IDA_RGBFORMAT
	BSR	.attr
	BSR	AmgRtgFmtFlags
	TST.W	D0
	BMI.S	.next
	MOVEQ	#0,D1			; width
	BSR	.attr
	MOVE.L	D0,D2
	MOVEQ	#1,D1			; height
	BSR	.attr
	MOVE.L	D0,D3
	MOVE.L	D3,D0			; wider than 16:9 (W 9 > H 16): left out
	LSL.L	#4,D0
	MOVE.L	D2,D1
	MULU	#9,D1
	CMP.L	D0,D1
	BHI	.next
	MOVE.W	AmgRtgFH2,D1		; the taller picture must fit, at 1x at least
	BSR	AmgRtgFitH
	TST.L	D0
	BEQ	.next
	MOVE.L	D0,-(SP)
	MOVE.W	AmgRtgFH1,D1
	BSR	AmgRtgFitH
	ADD.L	(SP)+,D0		; lines shown, both pictures
	LSL.L	#8,D0
	LSL.L	#2,D0
	DIVU	D3,D0			; / H: the share of the height, x 1024 (x 2048 at most)
	AND.L	#$FFFF,D0
	IFD	AMG_RTGHALF
	IFD	AMG_RTGCFG
	TST.B	AmgCfgScreen		; "Screen = Bigger": the best fit only
	BNE.S	.h2
	ENDC
	CMP.L	#960,D2
	BNE.S	.h1
	CMP.L	#540,D3
	BNE.S	.h1
	MOVE.L	#$30000,D0		; above any fit
.h1:	CMP.L	#640,D2
	BNE.S	.h2
	CMP.L	#480,D3
	BNE.S	.h2
	MOVE.L	#$20000,D0
.h2:
	ENDC
	MOVE.L	D2,D1			; D1 = the area
	MULU	D3,D1
	CMP.L	D6,D0
	BHI.S	.tk
	BNE	.next
	CMP.L	D7,D1			; the same score: the smaller mode
	BCC	.next
.tk:	MOVE.L	D0,D6
	MOVE.L	D1,D7
	MOVE.L	D4,D5
	BRA	.next
.done:	MOVE.L	D5,D4
	BEQ.S	.x
	MOVEQ	#0,D1
	BSR	.attr
	MOVE.W	D0,AmgRtgScrW
	MOVE.L	D0,AmgRtgTagW+4
	MOVEQ	#1,D1
	BSR	.attr
	MOVE.W	D0,AmgRtgScrH
	MOVE.L	D0,AmgRtgTagH+4
	MOVEQ	#2,D1			; depth
	BSR	.attr
	MOVE.L	D0,AmgRtgTagD+4
.x:	MOVE.L	D5,D0
	MOVEM.L	(SP)+,D1-D7/A0-A6
	RTS
.attr:	MOVE.L	D4,D0			; p96GetModeIDAttr(D0 = ModeID, D1 = attribute)
	MOVE.L	A6,-(SP)
	MOVE.L	AmgRtgP96,A6
	JSR	-84(A6)
	MOVE.L	(SP)+,A6
	RTS

	IFD	AMG_RTGMENU
; ---- the menu on the RTG board too (test feedback, 26 Nov 2026: switching the TV between the AGA menu
; and the RTG game is a pain), as AmiGameBoy's GBC_RTGMENU: once, before Juan's SetupScreen.
; His ScreenTags ask for PAL hires ($29000, the 9th tag); a Picasso96 ModeID goes there instead:
; 640x270 first where the machine has it (exactly a quarter of 1080p, so a 1080p scaler draws
; clean 3x4 blocks; on the A1200 640x256 looks soft, as AmiGameBoy's GBC_RTGMH2), then
; 640x256 (the PAL hires shape, so the board's scaler keeps his tall pixels), else the
; smallest P96 mode of at least 640x212. His 640x212 depth-3 screen opens on it (an 8-bit CLUT
; screen). No P96 or no such mode: the tags stay as they are (the AGA menu, as before).
; OS alive. Keeps every register.
AmgRtgMenuMode:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	CMP.L	#$80000032,ScreenTags+64	; SA_DisplayID where expected?
	BNE	.x
	SUB.L	A5,A5			; graphics
	SUB.L	A4,A4			; P96
	MOVE.L	4.W,A6
	LEA	AmgRtgGfxN(PC),A1
	MOVEQ	#39,D0
	JSR	-552(A6)		; OpenLibrary
	MOVE.L	D0,A5
	TST.L	D0
	BEQ	.close
	LEA	AmgRtgP96N(PC),A1
	MOVEQ	#2,D0
	JSR	-552(A6)
	MOVE.L	D0,A4
	TST.L	D0
	BEQ	.close
	MOVEQ	#-1,D6			; best rank (lower is better)
	MOVEQ	#-1,D5			; its ModeID
	MOVEQ	#-1,D4
.next:	MOVE.L	D4,D0
	MOVE.L	A5,A6
	JSR	-732(A6)		; NextDisplayInfo
	MOVE.L	D0,D4
	CMP.L	#-1,D4
	BEQ.S	.done
	MOVEQ	#6,D1			; P96IDA_ISP96
	BSR.S	.attr
	TST.L	D0
	BEQ.S	.next
	MOVEQ	#0,D1			; width
	BSR.S	.attr
	MOVE.L	D0,D2
	MOVEQ	#1,D1			; height
	BSR.S	.attr
	MOVE.L	D0,D3
	CMP.L	#640,D2
	BCS.S	.next
	CMP.L	#212,D3
	BCS.S	.next
	MOVEQ	#0,D0			; rank 0: 640x270
	CMP.L	#640,D2
	BNE.S	.area
	CMP.L	#AMGR_MENUH2,D3
	BEQ.S	.rk
	MOVEQ	#1,D0			; rank 1: 640x256
	CMP.L	#256,D3
	BEQ.S	.rk
.area:	MOVE.L	D2,D0			; then the smallest area
	MULU.W	D3,D0
.rk:	CMP.L	D6,D0
	BCC.S	.next
	MOVE.L	D0,D6
	MOVE.L	D4,D5
	BRA.S	.next
.done:	CMP.L	#-1,D5
	BEQ.S	.close
	MOVE.L	D5,ScreenTags+68
.close:	MOVE.L	4.W,A6
	MOVE.L	A4,D0
	BEQ.S	.c1
	MOVE.L	A4,A1
	JSR	-414(A6)		; CloseLibrary
.c1:	MOVE.L	A5,D0
	BEQ.S	.x
	MOVE.L	A5,A1
	JSR	-414(A6)
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
.attr:	MOVE.L	D4,D0			; p96GetModeIDAttr(D4, D1)
	MOVE.L	A4,A6
	JMP	-84(A6)
	ENDC

; D2.L = mode width, D3.L = height, D1.W = picture lines -> D0.L = s x lines, s the largest
; whole scale with AmgRtgFW s x lines s inside the mode (AMGR_FITS at most; 0: it does not fit).
AmgRtgFitH:
	MOVEM.L	D1-D2,-(SP)
	MOVE.L	D2,D0
	DIVU	AmgRtgFW,D0
	AND.L	#$FFFF,D0
	MOVE.L	D3,D2
	DIVU	D1,D2
	AND.L	#$FFFF,D2
	CMP.L	D0,D2
	BCC.S	.a
	MOVE.L	D2,D0
.a:	CMP.L	#AMGR_FITS,D0
	BLS.S	.b
	MOVEQ	#AMGR_FITS,D0
.b:	MULU	D1,D0
	MOVEM.L	(SP)+,D1-D2
	RTS

; D0.L = P96 RGBFormat -> D0.W = AmgRtgPix flags (bit 0 PC byte order, bit 1 5-5-5, bit 2 BGR),
; or -1 when it is not one of ours.
AmgRtgFmtFlags:
	MOVE.L	A0,-(SP)
	LEA	AmgRtgFmts,A0
.f:	TST.B	(A0)
	BMI.S	.no
	CMP.B	(A0),D0
	BEQ.S	.y
	ADDQ.L	#2,A0
	BRA.S	.f
.y:	MOVEQ	#0,D0
	MOVE.B	1(A0),D0
	MOVE.L	(SP)+,A0
	RTS
.no:	MOVEQ	#-1,D0
	MOVE.L	(SP)+,A0
	RTS

; ---- D0 = red, D1 = green, D2 = blue (0-255) -> D0.W the pixel in the screen's format. D1-D2 used.
AmgRtgRGB:
	BTST	#2,AmgRtgPix		; BGR: blue in the top bits
	BEQ.S	.rgb
	EXG	D0,D2
.rgb:	LSR.W	#3,D0
	LSR.W	#3,D2
	BTST	#1,AmgRtgPix
	BNE.S	.c555
	LSR.W	#2,D1			; 5-6-5
	LSL.W	#5,D1
	LSL.W	#8,D0
	LSL.W	#3,D0
	BRA.S	.cm
.c555:	LSR.W	#3,D1			; 5-5-5
	LSL.W	#5,D1
	LSL.W	#8,D0
	LSL.W	#2,D0
.cm:	OR.W	D1,D0
	OR.W	D2,D0
	BTST	#0,AmgRtgPix		; PC byte order
	BEQ.S	.be
	ROR.W	#8,D0
.be:	RTS

; ---- the colour lookups: Master System (64: BBGGRR, each 0-3 x 85) and Game Gear (4096, key
; B<<8 | G<<4 | R, each 0-15 x 17). OS alive.
AmgRtgLuts:
	LEA	AmgRtgLutMS,A0
	MOVEQ	#0,D3
.ms:	MOVEQ	#3,D0
	AND.W	D3,D0
	MULU	#85,D0
	MOVE.W	D3,D1
	LSR.W	#2,D1
	AND.W	#3,D1
	MULU	#85,D1
	MOVE.W	D3,D2
	LSR.W	#4,D2
	AND.W	#3,D2
	MULU	#85,D2
	BSR	AmgRtgRGB
	MOVE.W	D0,(A0)+
	ADDQ.W	#1,D3
	CMP.W	#64,D3
	BNE.S	.ms
	LEA	AmgRtgLutGG,A0
	MOVEQ	#0,D3
.gg:	MOVEQ	#15,D0
	AND.W	D3,D0
	MULU	#17,D0
	MOVE.W	D3,D1
	LSR.W	#4,D1
	AND.W	#15,D1
	MULU	#17,D1
	MOVE.W	D3,D2
	LSR.W	#8,D2
	AND.W	#15,D2
	MULU	#17,D2
	BSR	AmgRtgRGB
	MOVE.W	D0,(A0)+
	ADDQ.W	#1,D3
	CMP.W	#4096,D3
	BNE.S	.gg
	RTS

; ---- the tile decoder, once: four tables (planes 0-3) of 256 x 8 bytes, the 8 pixels of a
; plane byte (leftmost = bit 7) as bytes of 0 or 1 << plane. Keeps every register.
AmgRtgTables:
	TST.B	AmgRtgTabOK
	BNE.S	.r
	MOVEM.L	D0-D5/A0,-(SP)
	LEA	AmgRtgDec,A0
	MOVEQ	#0,D2			; plane
.p:	MOVEQ	#0,D0			; byte
.b:	MOVEQ	#7,D5			; bit
.k:	MOVEQ	#0,D1
	BTST	D5,D0
	BEQ.S	.z
	MOVEQ	#1,D1
	LSL.B	D2,D1
.z:	MOVE.B	D1,(A0)+
	DBF	D5,.k
	ADDQ.W	#1,D0
	CMP.W	#256,D0
	BNE.S	.b
	ADDQ.W	#1,D2
	CMP.W	#4,D2
	BNE.S	.p
	ST	AmgRtgTabOK
	MOVEM.L	(SP)+,D0-D5/A0
.r:	RTS

; ---- the whole bitmap black (0 in every format of ours). OS alive or frozen. D0/A0 used.
AmgRtgClear:
	MOVE.L	AmgRtgMem,A0
	MOVE.L	AmgRtgBpr,D0
	MULU	AmgRtgScrH,D0
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgDbl
	BEQ.S	.c1
	ADD.L	D0,D0			; both pages
.c1:
	ENDC
	LSR.L	#4,D0
	BRA.S	.e
.c:	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.L	(A0)+
.e:	SUBQ.L	#1,D0
	BPL.S	.c
	RTS

; ---- no mouse pointer on the game screen (AmiGameBoy's gbc_rptr_on): a borderless backdrop
; window, active, with a blank pointer. OS alive.
AmgRtgPtrOn:
	MOVEM.L	D0-D3/A0-A1/A6,-(SP)
	MOVE.L	AmgRtgInt,A6
	MOVE.L	$34(A6),AmgRtgPrevW	; IntuitionBase->ActiveWindow
	MOVE.L	AmgRtgScr,AmgRtgWScr+4
	MOVEQ	#0,D0
	MOVE.W	AmgRtgScrW,D0
	MOVE.L	D0,AmgRtgWW+4
	MOVE.W	AmgRtgScrH,D0
	MOVE.L	D0,AmgRtgWH+4
	SUB.L	A0,A0
	LEA	AmgRtgWTags,A1
	JSR	-606(A6)		; OpenWindowTagList
	MOVE.L	D0,AmgRtgWin
	BEQ.S	.x
	MOVE.L	D0,A0
	LEA	AmgRtgBlank,A1
	MOVEQ	#1,D0			; height
	MOVEQ	#16,D1			; width
	MOVEQ	#0,D2
	MOVEQ	#0,D3
	JSR	-270(A6)		; SetPointer
.x:	MOVEM.L	(SP)+,D0-D3/A0-A1/A6
	RTS
AmgRtgPtrOff:
	MOVE.L	AmgRtgWin,D0
	BEQ.S	.x
	CLR.L	AmgRtgWin
	MOVE.L	D0,A0
	MOVE.L	AmgRtgInt,A6
	JSR	-72(A6)			; CloseWindow
	MOVE.L	AmgRtgPrevW,D0		; the menu's window active again
	BEQ.S	.x
	CLR.L	AmgRtgPrevW
	MOVE.L	D0,A0
	JSR	-450(A6)		; ActivateWindow
.x:	RTS

; ---- the pacing clock: a CIA-B timer (A, else B) taken from ciab.resource, its interrupt kept
; off, run continuously from $FFFF on the E clock. OS alive. D0-D2/A0-A1/A6 used.
AmgRtgTimerOn:
	CLR.L	AmgRtgCia
	MOVE.L	4.W,A6
	LEA	AmgRtgCiabN(PC),A1
	JSR	-498(A6)		; OpenResource
	MOVE.L	D0,AmgRtgCiab
	BEQ	.x
	MOVE.L	D0,A6
	LEA	AmgRtgIcr,A1
	MOVEQ	#0,D0			; timer A
	JSR	-6(A6)			; AddICRVector
	TST.L	D0
	BEQ.S	.a
	LEA	AmgRtgIcr,A1
	MOVEQ	#1,D0			; timer B
	JSR	-6(A6)
	TST.L	D0
	BNE	.x
	MOVE.L	#$BFD600,AmgRtgCia	; TBLO (TBHI at +$100), CRB at $BFDF00
	MOVE.B	#1,AmgRtgTBit
	BRA.S	.got
.a:	MOVE.L	#$BFD400,AmgRtgCia	; TALO, CRA at $BFDE00
	CLR.B	AmgRtgTBit
.got:	MOVEQ	#1,D0
	MOVE.B	AmgRtgTBit,D1
	LSL.B	D1,D0
	JSR	-18(A6)			; AbleICR: its interrupt off (the counter is read)
	MOVE.L	AmgRtgCia,A0
	MOVEQ	#0,D0
	MOVE.B	AmgRtgTBit,D0
	LEA	$BFDE00,A1
	ADD.L	D0,A1			; CRA or CRB
	AND.B	#$C0,(A1)		; stopped, continuous, E clock (CRA keeps SPMODE, CRB ALARM/INMODE6)
	TST.B	AmgRtgTBit
	BEQ.S	.ca
	AND.B	#$80,(A1)		; CRB: INMODE 00 (E clock)
.ca:	MOVE.B	#$FF,(A0)		; latch $FFFF
	MOVE.B	#$FF,$100(A0)
	OR.B	#$11,(A1)		; load, start
	MOVE.W	#$FFFF,AmgRtgPrev
	CLR.L	AmgRtgClock
	MOVE.L	4.W,A0
	MOVE.L	$238(A0),D0		; ExecBase->ex_EClockFrequency (709379 PAL, 715909 NTSC)
	MULU.L	#1000,D0
	MOVE.L	#59923,D1		; NTSC console: 3579545 / (228 x 262) Hz, in mHz
	TST.B	DirPrefs+$0F		; Screen mode: 1 NTSC
	BNE.S	.r
	MOVE.L	#49701,D1		; PAL: 3546893 / (228 x 313)
.r:	DIVU.L	D1,D0
	MOVE.L	D0,AmgRtgPer		; E clocks a frame
	ST	AmgRtgSync
.x:	RTS

AmgRtgTimerOff:
	MOVE.L	AmgRtgCia,D0
	BEQ.S	.x
	CLR.L	AmgRtgCia
	MOVEQ	#0,D0
	MOVE.B	AmgRtgTBit,D0
	LEA	$BFDE00,A1
	ADD.L	D0,A1
	AND.B	#$FE,(A1)		; stop
	MOVE.L	AmgRtgCiab,A6
	MOVEQ	#1,D0
	MOVE.B	AmgRtgTBit,D1
	LSL.B	D1,D0
	JSR	-24(A6)			; SetICR: its flag cleared
	LEA	AmgRtgIcr,A1
	MOVEQ	#0,D0
	MOVE.B	AmgRtgTBit,D0
	JSR	-12(A6)			; RemICRVector
.x:	RTS

; the ICR handler the OS would call: never, as the interrupt is kept off
AmgRtgIcrCode:
	MOVEQ	#0,D0
	RTS

; ---- D0.L = E clocks since AmgRtgTimerOn (the counter read every < 92 ms). No OS. Keeps the rest.
AmgRtgNow:
	MOVEM.L	D1-D2/A0,-(SP)
	MOVE.L	AmgRtgCia,A0
	MOVE.L	A0,D0
	BEQ.S	.no
.rd:	MOVE.B	$100(A0),D1		; high, low, high again
	MOVE.B	(A0),D0
	CMP.B	$100(A0),D1
	BNE.S	.rd
	LSL.W	#8,D1
	MOVE.B	D0,D1
	MOVE.W	AmgRtgPrev,D2
	MOVE.W	D1,AmgRtgPrev
	SUB.W	D1,D2			; it counts down
	MOVEQ	#0,D0
	MOVE.W	D2,D0
	ADD.L	AmgRtgClock,D0
	MOVE.L	D0,AmgRtgClock
.no:	MOVEM.L	(SP)+,D1-D2/A0
	RTS

; ---- MiraInterFin, at every frame's start (the registers saved, A7 = BufBasura). The height
; (AmgM224On), the vertical scroll for the frame (latched, as the VDP does) and the lines to draw.
; Keeps every register.
AmgRtgFrame0:
	TST.B	AmgRtgOn
	BEQ.S	.x
	MOVEM.L	D0-D1,-(SP)
	MOVE.W	#192,D0
	IFD	AMG_M224
	TST.B	AmgM224On
	BEQ.S	.h
	MOVE.W	#224,D0
.h:
	ENDC
	CMP.W	AmgRtgH,D0
	BEQ.S	.same
	MOVE.W	D0,AmgRtgH
	ST	AmgRtgLay		; new height: the screen laid out again at the copy
.same:	MOVEQ	#1,D1			; CurLine as the first line drawn ends
	TST.B	Regs+Consola
	BEQ.S	.sms
	MOVEQ	#24+1,D1		; Game Gear: only the LCD's 144 lines (24-167, or 40-183 of 224)
	CMP.W	#224,D0
	BNE.S	.gg
	MOVEQ	#40+1,D1
.gg:	MOVE.W	D1,AmgRtgNext
	ADD.W	#144-1,D1
	MOVE.W	D1,AmgRtgLast
	BRA.S	.v
.sms:	MOVE.W	D1,AmgRtgNext
	MOVE.W	D0,AmgRtgLast
.v:	MOVE.B	VDPRegs+9,AmgRtgVS
	MOVE.B	AmgRtgDrawNext,AmgRtgDraw
	MOVEM.L	(SP)+,D0-D1
.x:	RTS

; ---- MiraInter (JMP): D1.W = CurLine just advanced, A3 = Regs, every register the Z80's. The
; line that ended drawn, when it is one of this frame's; then on to Juan's line table.
AmgRtgMI:
	TST.B	AmgRtgDraw
	BEQ.S	.go
	CMP.W	AmgRtgNext,D1
	BNE.S	.go
	MOVEM.L	D0-D7/A0-A7,AmgRtgSave	; A7 is the Z80 page pointer: a stack of our own
	LEA	AmgRtgStk,A7
	IFD	AMG_RTGCOST
	BSR	AmgRtgNow
	MOVE.L	D0,-(SP)
	ENDC
	MOVE.W	D1,D0
	SUBQ.W	#1,D0
	IFND	AMGR_P_NOLINE		; (profiling builds only)
	BSR	AmgRtgLine
	ENDC
	IFD	AMG_RTGCOST
	BSR	AmgRtgNow
	SUB.L	(SP)+,D0
	ADD.L	D0,AmgRtgCostL
	ADDQ.L	#1,AmgRtgCostN
	ENDC
	MOVEM.L	AmgRtgSave,D0-D7/A0-A7
	CMP.W	AmgRtgLast,D1
	BCS.S	.more
	MOVE.W	#$7FFF,AmgRtgNext	; the frame's last line done
	BRA.S	.go
.more:	ADDQ.W	#1,AmgRtgNext
.go:
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgFlipPend		; a hidden page waits for the blank: checked every AMGR_POLLN lines
	BNE.S	.fp
.go2:
	ENDC
	JMP	([JumpCurLine,D1.W*4])
	IFD	AMG_RTGDBUF
.fp:	SUBQ.B	#1,AmgRtgPollN
	BNE.S	.go2
	MOVE.B	#AMGR_POLLN,AmgRtgPollN
	MOVEM.L	D0-D7/A0-A7,AmgRtgSave
	LEA	AmgRtgStk,A7
	BSR	AmgRtgFlipPoll
	MOVEM.L	AmgRtgSave,D0-D7/A0-A7
	BRA.S	.go2
	ENDC

; ---- one picture line. D0.W = the line. Every register used (AmgRtgMI keeps the Z80's).
AmgRtgLine:
	MOVE.W	D0,D7
	LEA	VDPRegs,A6
	BSR	AmgRtgPal		; the 32 colours as they are now
	BTST	#2,(A6)			; M4: Mode 4
	BEQ	.black			; TMS9918 modes: not drawn yet
	BTST	#6,1(A6)		; display on?
	BEQ	.blank
	BSR	AmgRtgBg
	IFND	AMGR_P_NOSPR
	BSR	AmgRtgSpr
	ENDC
	BTST	#5,(A6)			; left column blank: the backdrop colour (sprite palette)
	BEQ.S	.nlb
	MOVEQ	#15,D0
	AND.B	7(A6),D0
	OR.B	#$10,D0
	MOVE.B	D0,D1
	LSL.W	#8,D1
	MOVE.B	D0,D1
	MOVE.W	D1,D0
	SWAP	D1
	MOVE.W	D0,D1
	LEA	AmgRtgIdx,A1
	MOVE.L	D1,(A1)
	MOVE.L	D1,4(A1)
.nlb:	BSR	.dst
	LEA	AmgRtgIdx,A1
	LEA	AmgRtgP16,A4
	MOVEQ	#256/8-1,D1
	TST.B	Regs+Consola
	BEQ.S	.cv
	LEA	48(A1),A1		; Game Gear: columns 48-207
	LEA	48*2(A5),A5
	MOVEQ	#160/8-1,D1
.cv:	MOVEQ	#0,D0
.c8:
	REPT	8
	MOVE.B	(A1)+,D0
	MOVE.W	(A4,D0.W*2),(A5)+
	ENDR
	DBF	D1,.c8
	RTS
.black:	MOVEQ	#0,D0
	BRA.S	.fill
.blank:	MOVEQ	#15,D0			; display off: the backdrop colour
	AND.B	7(A6),D0
	LEA	AmgRtgP16+32,A4
	MOVE.W	(A4,D0.W*2),D0
.fill:	BSR	.dst
	MOVE.W	D0,D1
	SWAP	D0
	MOVE.W	D1,D0
	MOVEQ	#256/8-1,D1
.f:	MOVE.L	D0,(A5)+
	MOVE.L	D0,(A5)+
	MOVE.L	D0,(A5)+
	MOVE.L	D0,(A5)+
	DBF	D1,.f
	RTS
.dst:	LEA	AmgRtgFB,A5		; A5 = the line in the frame
	MOVEQ	#0,D2
	MOVE.W	D7,D2
	LSL.L	#8,D2
	ADD.L	D2,D2
	ADD.L	D2,A5
	RTS

; ---- the 32 colours from the palette RAM (VPAL) into AmgRtgP16 (entries 0-31, and 128-159 for
; background pixels marked with priority). D0-D2/A0-A2 used.
AmgRtgPal:
	LEA	VPAL,A0			; the same as the last line's? (32 or 64 bytes)
	LEA	AmgRtgPalC,A1
	MOVEQ	#32/4-1,D1
	TST.B	Regs+Consola
	BEQ.S	.n
	MOVEQ	#64/4-1,D1
.n:	TST.B	AmgRtgPalV
	BEQ.S	.new
.cmp:	CMPM.L	(A0)+,(A1)+
	DBNE	D1,.cmp
	BNE.S	.new
	RTS
.new:	LEA	VPAL,A0			; keep it, then the 32 colours
	LEA	AmgRtgPalC,A1
	MOVEQ	#64/4-1,D1
.k:	MOVE.L	(A0)+,(A1)+
	DBF	D1,.k
	ST	AmgRtgPalV
	LEA	VPAL,A0
	LEA	AmgRtgP16,A1
	MOVEQ	#32-1,D1
	TST.B	Regs+Consola
	BNE.S	.gg
	LEA	AmgRtgLutMS,A2
	MOVEQ	#0,D0
.ms:	MOVE.B	(A0)+,D0
	AND.B	#63,D0
	MOVE.W	(A2,D0.W*2),D2
	MOVE.W	D2,256(A1)
	MOVE.W	D2,(A1)+
	DBF	D1,.ms
	RTS
.gg:	LEA	AmgRtgLutGG,A2		; two bytes a colour: GGGGRRRR, ----BBBB
.g:	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	MOVEQ	#15,D2
	AND.B	(A0)+,D2
	LSL.W	#8,D2
	OR.W	D2,D0
	MOVE.W	(A2,D0.W*2),D2
	MOVE.W	D2,256(A1)
	MOVE.W	D2,(A1)+
	DBF	D1,.g
	RTS

; ---- the background of line D7 into AmgRtgIdx (a byte a pixel: palette index 0-31, bit 7 set
; for a priority tile's non-zero pixel). A6 = VDPRegs. D7 kept; D0-D6/A0-A5 used.
AmgRtgBg:
	MOVE.W	D7,-(SP)
	LEA	VRAM,A0
	LEA	AmgRtgIdx,A1
	LEA	AmgRtgDec,A4
	MOVEQ	#0,D6			; horizontal scroll
	MOVE.B	8(A6),D6
	BTST	#6,(A6)			; top two rows not scrolled
	BEQ.S	.sx
	CMP.W	#16,D7
	BCC.S	.sx
	MOVEQ	#0,D6
.sx:	MOVEQ	#0,D0			; name table
	MOVE.B	2(A6),D0
	CMP.W	#224,AmgRtgH
	BEQ.S	.n224
	AND.W	#$0E,D0
	LSL.W	#8,D0
	LSL.W	#2,D0
	BRA.S	.nb
.n224:	AND.W	#$0C,D0			; 224 lines: $0700, $1700, $2700 or $3700
	LSL.W	#8,D0
	LSL.W	#2,D0
	ADD.W	#$0700,D0
.nb:	MOVEQ	#0,D1			; the scrolled line in the name table
	MOVE.B	AmgRtgVS,D1
	ADD.W	D7,D1
	CMP.W	#224,AmgRtgH
	BEQ.S	.y224
	CMP.W	#224,D1			; 28 rows: wraps at 224
	BCS.S	.y
	SUB.W	#224,D1
	CMP.W	#224,D1
	BCS.S	.y
	SUB.W	#224,D1
	BRA.S	.y
.y224:	AND.W	#255,D1			; 32 rows
.y:	MOVE.W	D1,D2
	LSR.W	#3,D2
	LSL.W	#6,D2
	ADD.W	D0,D2
	LEA	(A0,D2.W),A2		; A2 = the scrolled row, D4 = its fine line x 4
	MOVEQ	#7,D4
	AND.W	D1,D4
	LSL.W	#2,D4
	MOVE.W	D7,D2			; columns 24-31 with register 0 bit 7: not scrolled
	LSR.W	#3,D2
	LSL.W	#6,D2
	ADD.W	D0,D2
	LEA	(A0,D2.W),A5		; A5 = that row, D5 = its fine line x 4
	MOVEQ	#7,D5
	AND.W	D7,D5
	LSL.W	#2,D5
	SUB.L	A3,A3			; A3 = name table column x 2, D6 = its first pixel on the line
.t:	MOVE.W	(A2,A3.W),D3		; the cell (little endian)
	MOVE.W	D4,D2
	TST.B	(A6)
	BPL.S	.nl
	CMP.W	#192,D6
	BCS.S	.nl
	MOVE.W	(A5,A3.W),D3
	MOVE.W	D5,D2
.nl:	ROR.W	#8,D3			; tile 0-8, flips 9-10, palette 11, priority 12
	BTST	#10,D3
	BEQ.S	.nv
	EOR.W	#28,D2			; vertical flip: line 7 - n
.nv:	MOVE.W	D3,D0
	AND.W	#$1FF,D0
	LSL.W	#5,D0
	ADD.W	D2,D0
	MOVE.L	(A0,D0.W),D2		; the four plane bytes, plane 0 on top
	MOVEQ	#0,D0
	BTST	#9,D3
	BEQ.S	.nh
	REPT	4			; horizontal flip: each byte reversed
	ROL.L	#8,D2
	MOVE.B	D2,D0
	MOVE.B	(TablaFlipX,D0.W),D2
	ENDR
.nh:	ROL.L	#8,D2
	MOVE.B	D2,D0
	MOVE.L	(A4,D0.W*8),D1
	MOVE.L	4(A4,D0.W*8),D7
	ROL.L	#8,D2
	MOVE.B	D2,D0
	OR.L	2048(A4,D0.W*8),D1
	OR.L	2048+4(A4,D0.W*8),D7
	ROL.L	#8,D2
	MOVE.B	D2,D0
	OR.L	4096(A4,D0.W*8),D1
	OR.L	4096+4(A4,D0.W*8),D7
	ROL.L	#8,D2
	MOVE.B	D2,D0
	OR.L	6144(A4,D0.W*8),D1
	OR.L	6144+4(A4,D0.W*8),D7
	BTST	#12,D3			; priority: bit 7 on the non-zero pixels
	BEQ.S	.np
	MOVE.L	D1,D0
	LSR.L	#1,D0
	OR.L	D1,D0
	MOVE.L	D0,D2
	LSR.L	#2,D2
	OR.L	D2,D0
	AND.L	#$01010101,D0
	LSL.L	#7,D0
	OR.L	D0,D1
	MOVE.L	D7,D0
	LSR.L	#1,D0
	OR.L	D7,D0
	MOVE.L	D0,D2
	LSR.L	#2,D2
	OR.L	D2,D0
	AND.L	#$01010101,D0
	LSL.L	#7,D0
	OR.L	D0,D7
.np:	BTST	#11,D3			; second palette
	BEQ.S	.wr
	OR.L	#$10101010,D1
	OR.L	#$10101010,D7
.wr:	MOVE.L	D1,(A1,D6.W)
	MOVE.L	D7,4(A1,D6.W)
	ADDQ.W	#8,D6
	AND.W	#255,D6
	ADDQ.W	#2,A3
	CMP.W	#64,A3
	BNE	.t
	MOVEQ	#7,D0			; the cell cut by the right edge: its left part at x 0
	AND.W	D6,D0
	BEQ.S	.nw
	SUBQ.W	#1,D0
	LEA	256(A1),A2
	MOVE.L	A1,A3
.cw:	MOVE.B	(A2)+,(A3)+
	DBF	D0,.cw
.nw:	MOVE.W	(SP)+,D7
	RTS

; ---- the sprites of line D7 over AmgRtgIdx: the first 8 on the line in table order, the earlier
; one in front, behind priority tiles; 8x8 or 8x16, zoom, shift left 8; $D0 ends the table in
; 192-line mode. A6 = VDPRegs, A0 = VRAM, A1 = AmgRtgIdx, A4 = AmgRtgDec (from AmgRtgBg).
; D7 kept; D0-D6/A2-A3/A5 used.
AmgRtgSpr:
	MOVEQ	#0,D0
	MOVE.B	5(A6),D0
	AND.W	#$7E,D0
	LSL.W	#7,D0
	LEA	(A0,D0.W),A2		; sprite attribute table
	MOVEQ	#8,D5			; height on the screen
	BTST	#1,1(A6)
	BEQ.S	.h
	MOVEQ	#16,D5
.h:	BTST	#0,1(A6)		; zoom: twice as tall (and wide, below)
	BEQ.S	.z
	ADD.W	D5,D5
.z:	MOVE.W	#$D0,D3			; the end mark, a word: $100 never matches (224 lines)
	CMP.W	#224,AmgRtgH
	BNE.S	.e
	MOVE.W	#$100,D3
.e:	MOVE.W	D7,D2			; line - 1: the VDP compares Y + 1
	SUBQ.W	#1,D2
	MOVEQ	#8,D6			; sprites still allowed on the line
	MOVE.L	A2,A3			; A3 = the table, A2 = the next Y
	MOVEQ	#64-1,D4
	MOVEQ	#0,D0			; bits 8-15 stay clear: the Y as a word
.s:	MOVE.B	(A2)+,D0		; Y
	CMP.W	D3,D0
	BEQ	.done
	MOVE.B	D2,D1			; the line in the sprite, as the VDP's 8-bit compare
	SUB.B	D0,D1
	CMP.B	D5,D1
	BCS.S	.hit
.nx:	DBF	D4,.s
	RTS
.hit:	TST.W	D6
	BEQ	.done			; a ninth: not drawn
	CMP.W	#8,D6
	BNE.S	.oc
	LEA	AmgRtgOcc,A5		; the line's first sprite: no pixel taken yet
	MOVEQ	#256/16-1,D0
.ocl:	CLR.L	(A5)+
	CLR.L	(A5)+
	CLR.L	(A5)+
	CLR.L	(A5)+
	DBF	D0,.ocl
.oc:	SUBQ.W	#1,D6
	MOVEM.L	D2-D5/A2,-(SP)
	AND.W	#255,D1
	MOVE.L	A2,D0			; the sprite number = A2 - table - 1
	SUB.L	A3,D0
	SUBQ.W	#1,D0
	ADD.W	D0,D0
	ADD.W	#$80,D0
	MOVEQ	#0,D2
	MOVE.B	(A3,D0.W),D2		; X
	MOVEQ	#0,D3
	MOVE.B	1(A3,D0.W),D3		; tile
	MOVEQ	#0,D4			; zoom: 0 or 1
	BTST	#0,1(A6)
	BEQ.S	.zz
	MOVEQ	#1,D4
.zz:
	BTST	#3,(A6)
	BEQ.S	.x8
	SUBQ.W	#8,D2
.x8:	LSR.W	D4,D1			; the pattern line
	BTST	#1,1(A6)
	BEQ.S	.t8
	AND.W	#$FE,D3			; 8x16: an even tile, then the next
.t8:	MOVE.W	D1,D0
	LSR.W	#3,D0
	ADD.W	D0,D3
	BTST	#2,6(A6)		; patterns from $2000
	BEQ.S	.pb
	ADD.W	#256,D3
.pb:	LSL.W	#5,D3
	AND.W	#7,D1
	LSL.W	#2,D1
	ADD.W	D1,D3
	AND.W	#$3FFF,D3
	MOVE.L	(A0,D3.W),D3		; the four plane bytes
	MOVEQ	#0,D0
	LEA	AmgRtgSp8,A5		; its 8 pixels
	ROL.L	#8,D3
	MOVE.B	D3,D0
	MOVE.L	(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	2048(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	4096(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	6144(A4,D0.W*8),D1
	MOVE.L	D1,(A5)
	ROL.L	#8,D3
	MOVE.B	D3,D0
	MOVE.L	4(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	2048+4(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	4096+4(A4,D0.W*8),D1
	ROL.L	#8,D3
	MOVE.B	D3,D0
	OR.L	6144+4(A4,D0.W*8),D1
	MOVE.L	D1,4(A5)
	MOVEQ	#8-1,D1
.px:	MOVE.B	(A5)+,D0
	BEQ.S	.pn			; colour 0: see-through
	OR.B	#$10,D0			; sprite palette
	BSR.S	.put
	TST.W	D4
	BEQ.S	.pn
	ADDQ.W	#1,D2
	BSR.S	.put
	SUBQ.W	#1,D2
.pn:	ADDQ.W	#1,D2
	ADD.W	D4,D2
	DBF	D1,.px
	MOVEM.L	(SP)+,D2-D5/A2
	MOVEQ	#0,D0
	BRA	.nx
.done:	RTS
.put:	CMP.W	#256,D2			; off the line (negative as unsigned too)
	BCC.S	.r
	TST.B	(AmgRtgOcc,D2.W)
	BNE.S	.r			; an earlier sprite's pixel
	ST	(AmgRtgOcc,D2.W)
	TST.B	(A1,D2.W)
	BMI.S	.r			; a priority tile's pixel
	MOVE.B	D0,(A1,D2.W)
.r:	RTS

; ---- Emula1Frame (JMP, RTG on): the frame to the screen, the next frame's drawing decided, the
; pacing, the sound. Returns to MiraInter193 (the registers saved there, A7 = BufBasura).
AmgRtgFrame:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	IFD	AMG_SYNCLOG		; 1: the frame emulated (info: 1 drawn, 2 two pages, 4 a page waits)
	MOVEQ	#0,D2
	TST.B	AmgRtgDraw
	BEQ.S	.s0
	BSET	#0,D2
.s0:	TST.B	AmgRtgDbl
	BEQ.S	.s1
	BSET	#1,D2
	TST.B	AmgRtgFlipPend
	BEQ.S	.s1
	BSET	#2,D2
.s1:	MOVEQ	#1,D1
	BSR	AmgSyncLog
	ENDC
	TST.B	AmgRtgDraw
	BEQ	.nc
	IFD	AMG_RTGCOST
	BSR	AmgRtgNow
	MOVE.L	D0,-(SP)
	ENDC
	IFND	AMGR_P_NOCOPY
	BSR	AmgRtgCopy
	ENDC
	IFD	AMG_SYNCLOG
	SYNCEV	2,#0			; 2: copied to the screen
	ENDC
	IFD	AMG_RTGCOST
	BSR	AmgRtgNow
	SUB.L	(SP)+,D0
	ADD.L	D0,AmgRtgCostC
	ADDQ.L	#1,AmgRtgCostF
	ENDC
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgDbl
	BEQ.S	.nc
	BSR	AmgRtgFlipQ		; the hidden page to be shown
	ENDC
.nc:	BSR	AmgRtgNow		; D0 = now
	TST.B	AmgRtgSync
	BEQ.S	.syn
	SF	AmgRtgSync		; the first frame: on time from now
	MOVE.L	D0,AmgRtgDue
.syn:	MOVE.L	D0,D1
	SUB.L	AmgRtgDue,D1		; D1 = now - due: negative = on time
; the next frame drawn? Juan's Gfx Refresh: 0-3 frames left out between two drawn, 4 Auto
; (drawn when on time, at least one frame in four)
	MOVE.B	DirPrefs+$10,D2
	CMP.B	#4,D2
	BNE.S	.fix
	TST.L	D1
	BMI.S	.yes
	ADDQ.B	#1,AmgRtgSkip
	CMP.B	#4,AmgRtgSkip
	BCC.S	.yes
	BRA.S	.no
.fix:	ADDQ.B	#1,AmgRtgSkip
	CMP.B	AmgRtgSkip,D2
	BCC.S	.no
.yes:	CLR.B	AmgRtgSkip
	ST	AmgRtgDrawNext
	BRA.S	.dn
.no:	SF	AmgRtgDrawNext
.dn:
	IFD	AUTOOPT			; test builds: no drawing before AUTOOPT - 50 (AutoTest.asm)
	CMP.L	#AUTOOPT-50,AutoFrames
	BCC.S	.ff
	SF	AmgRtgDrawNext
.ff:
	ENDC
	IFD	AUTOTEST
	IFND	AUTOSYNC
	BRA.S	.nw			; test builds run as fast as they can
	ENDC
	ENDC
	CMP.B	#2,DirPrefs+$13		; Turbo: no wait
	IFD	AMG_SYNCLOG
	BEQ	.nw
	ELSE
	BEQ.S	.nw
	ENDC
	TST.L	AmgRtgCia
	IFD	AMG_SYNCLOG
	BEQ	.nw
	ELSE
	BEQ.S	.nw			; no timer: no wait
	ENDC
	TST.L	D1
	IFD	AMG_SYNCLOG		; 6: late (info: E clocks / 16, at most $FFFF)
	BMI.S	.w
	MOVEM.L	D1-D2,-(SP)
	MOVE.L	D1,D2
	LSR.L	#4,D2
	CMP.L	#$FFFF,D2
	BLS.S	.lc
	MOVE.L	#$FFFF,D2
.lc:	MOVEQ	#6,D1
	BSR	AmgSyncLog
	MOVEM.L	(SP)+,D1-D2
	BRA	.late
	ELSE
	BPL.S	.late
	ENDC
.w:
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgFlipPend		; the hidden page shown when its blank comes
	BEQ.S	.w0
	BSR	AmgRtgFlipPoll
.w0:
	ENDC
	BSR	AmgRtgNow		; on time: wait for the frame's time
	MOVE.L	D0,D1
	SUB.L	AmgRtgDue,D1
	BMI.S	.w
.late:	MOVE.L	AmgRtgDue,D3		; the next frame's time: the first one after now
	MOVE.L	AmgRtgPer,D4
	MOVEQ	#8,D5
.adv:	ADD.L	D4,D3
	MOVE.L	D0,D1
	SUB.L	D3,D1
	BMI.S	.ok
	SUBQ.W	#1,D5
	BNE.S	.adv
	MOVE.L	D0,D3			; far behind: start again from now
	ADD.L	D4,D3
.ok:	MOVE.L	D3,AmgRtgDue
	IFD	AMG_SYNCLOG
	SYNCEV	7,#0			; 7: the wait over, the next frame starts
	ENDC
.nw:	MOVE.B	#1,Regs+fps60Dat	; as Wait60fps leaves it (Fast CPU reads it)
	JSR	TocaPSG			; the sound, once a frame, as Wait60fps
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; ---- the screen laid out for the console and height: the scale, the picture's place, the whole
; screen cleared. OS frozen.
AmgRtgLayout:
	SF	AmgRtgLay
	ST	AmgRtgFull
	IFD	AMG_RTGDBUF
	ST	AmgRtgFullP		; each page's next copy: every line
	ST	AmgRtgFullP+1
	ENDC
	MOVE.W	#256,D2			; Master System: the whole picture
	MOVE.W	AmgRtgH,D3
	MOVEQ	#0,D4			; first line
	MOVEQ	#0,D5			; first column
	TST.B	Regs+Consola
	BEQ.S	.ms
	MOVE.W	#160,D2			; Game Gear: the LCD
	MOVE.W	#144,D3
	MOVEQ	#24,D4
	CMP.W	#224,AmgRtgH
	BNE.S	.g
	MOVEQ	#40,D4
.g:	MOVEQ	#48,D5
.ms:	MOVE.W	D2,AmgRtgPW
	MOVE.W	D3,AmgRtgPH
	MOVE.W	D4,AmgRtgPT
	MOVE.W	D5,AmgRtgPL
	MOVEQ	#0,D0			; scale: the largest that fits
	MOVE.W	AmgRtgScrW,D0
	DIVU	D2,D0
	MOVEQ	#0,D1
	MOVE.W	AmgRtgScrH,D1
	DIVU	D3,D1
	CMP.W	D0,D1
	BCC.S	.s1
	MOVE.W	D1,D0
.s1:	CMP.W	#AMGR_MAXS,D0
	BLS.S	.s2
	MOVEQ	#AMGR_MAXS,D0
.s2:	TST.W	D0
	BNE.S	.s3
	MOVEQ	#1,D0
.s3:	MOVE.W	D0,AmgRtgScale
	IFD	AMG_RTGSCAN
	SF	AmgRtgScanOn		; scanlines at scale 2 and up only
	CMP.W	#2,D0
	BCS.S	.sc
	TST.B	AmgCfgScan
	BEQ.S	.sc
	MOVE.B	AmgCfgStyle,D1		; 1-6: Hard 25/50/75%, Blended light / Blended / strong
	ADDQ.B	#1,D1
	MOVE.B	D1,AmgRtgScanOn
	MOVE.W	D0,D1			; the lower half of a line's s rows (s / 2) the scanline
	LSR.W	#1,D1
	MOVE.W	D1,AmgRtgScNd
	NEG.W	D1
	ADD.W	D0,D1
	MOVE.W	D1,AmgRtgScNr
	MULU	AmgRtgBpr+2,D1
	MOVE.L	D1,AmgRtgScOff
.sc:
	ENDC
	MOVE.W	D0,D1			; left = (W - w s) / 2
	MULU	D2,D1
	MOVE.W	AmgRtgScrW,D6
	SUB.W	D1,D6
	ASR.W	#1,D6
	BPL.S	.l
	MOVEQ	#0,D6
.l:	MOVE.W	D0,D1			; top = (H - h s) / 2
	MULU	D3,D1
	MOVE.W	AmgRtgScrH,D7
	SUB.W	D1,D7
	ASR.W	#1,D7
	BPL.S	.t
	MOVEQ	#0,D7
.t:	MOVE.L	AmgRtgBpr,D1
	MULU	D7,D1
	AND.L	#$FFFF,D6
	ADD.L	D6,D6
	ADD.L	D6,D1
	ADD.L	AmgRtgMem,D1
	MOVE.L	D1,AmgRtgOrg
	MULU	D2,D0			; longs in a scaled row, / 8
	LSR.W	#4,D0
	SUBQ.W	#1,D0
	MOVE.W	D0,AmgRtgRowL
	BSR	AmgRtgClear
	RTS

; ---- the frame's changed lines to the screen, each pixel s x s. OS frozen. Every register used.
AmgRtgCopy:
	TST.B	AmgRtgLay
	BEQ.S	.go
	BSR	AmgRtgLayout
.go:	MOVE.L	AmgRtgOrg,A1
	MOVE.L	AmgRtgBpr,D6
	MOVE.W	AmgRtgScale,D5
	MOVE.W	AmgRtgPW,D4
	MOVEQ	#0,D0
	MOVE.W	AmgRtgPT,D0
	LSL.L	#8,D0
	ADD.L	D0,D0
	MOVEQ	#0,D1
	MOVE.W	AmgRtgPL,D1
	ADD.L	D1,D1
	ADD.L	D1,D0
	LEA	AmgRtgFB,A0
	ADD.L	D0,A0
	LEA	AmgRtgOld,A4
	ADD.L	D0,A4
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgDbl		; two pages: into the hidden one, against its own last copy
	BEQ.S	.p0
	MOVEQ	#0,D0
	MOVE.B	AmgRtgPg,D0
	LEA	AmgRtgFullP,A2
	TST.B	(A2,D0.W)
	BEQ.S	.pf
	ST	AmgRtgFull
.pf:	SF	(A2,D0.W)
	TST.B	D0
	BEQ.S	.p0
	ADD.L	AmgRtgPgOff,A1
	ADD.L	#AmgRtgOld1-AmgRtgOld,A4
.p0:
	ENDC
	MOVE.W	AmgRtgPH,D7
	SUBQ.W	#1,D7
	MOVE.W	D4,D3			; longs in a line, less 1
	LSR.W	#1,D3
	SUBQ.W	#1,D3
	IFD	AMG_RTGSCAN
	TST.B	AmgRtgScanOn
	BNE	AmgRtgCopyS
	ENDC
.ln:	TST.B	AmgRtgFull
	BNE.S	.chg
	MOVE.L	A0,A2			; changed since the last copy?
	MOVE.L	A4,A3
	MOVE.W	D3,D0
.cmp:	CMP.L	(A2)+,(A3)+
	DBNE	D0,.cmp
	BEQ.S	.same
.chg:	MOVE.L	A0,A2			; keep it
	MOVE.L	A4,A3
	MOVE.W	D3,D0
.cp:	MOVE.L	(A2)+,(A3)+
	DBF	D0,.cp
	IFD	AMG_RTGCOST
	ADDQ.L	#1,AmgRtgCostY
	ENDC
	MOVE.L	A0,A2			; the scaled row
	LEA	AmgRtgRow,A3
	MOVE.W	D4,D0
	SUBQ.W	#1,D0
.ex:	MOVE.W	(A2)+,D1
	MOVE.W	D5,D2
	SUBQ.W	#1,D2
.ew:	MOVE.W	D1,(A3)+
	DBF	D2,.ew
	DBF	D0,.ex
	MOVE.L	A1,A5			; s times on the screen
	MOVE.W	D5,D2
	SUBQ.W	#1,D2
.wr:	LEA	AmgRtgRow,A2
	MOVE.L	A5,A3
	MOVE.W	AmgRtgRowL,D0
.wl:	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	DBF	D0,.wl
	ADD.L	D6,A5
	DBF	D2,.wr
.same:	LEA	AMGR_RTG_W*2(A0),A0
	LEA	AMGR_RTG_W*2(A4),A4
	MOVE.W	D5,D0
.adv:	ADD.L	D6,A1
	SUBQ.W	#1,D0
	BNE.S	.adv
	DBF	D7,.ln
	SF	AmgRtgFull
	RTS

	IFD	AMG_RTGDBUF
; ---- AmgRtgFrame: a frame is in the hidden page (AmgRtgPg), to be shown: with a steady blank
; (AmgRtgVper) by a pan started AMGR_LEAD before the next one, else now. OS frozen. Keeps every
; register.
AmgRtgFlipQ:
	MOVEM.L	D0-D1,-(SP)
	IFD	AMG_SYNCLOG		; 3: the waiting page replaced, never shown
	TST.B	AmgRtgFlipPend
	BEQ.S	.sq
	SYNCEV	3,#0
.sq:
	ENDC
	IFD	AMG_RTGCOST
	TST.B	AmgRtgFlipPend		; the last one never shown (replaced in the hidden page)
	BEQ.S	.nd
	ADDQ.L	#1,AmgRtgCostSD
.nd:
	ENDC
	MOVE.B	AmgRtgPg,AmgRtgFlipPg
	MOVE.B	AmgRtgPg,AmgRtgLastPg
	ST	AmgRtgFlipPend
	MOVE.B	#1,AmgRtgPollN		; checked from the next line
	TST.L	AmgRtgVper
	BNE.S	.t
	BSR	AmgRtgShow		; no steady blank: shown now
	BRA.S	.x
.t:	BSR	AmgRtgNow
	BSR	AmgRtgNextVb
	SUB.L	#AMGR_LEAD,D0
	MOVE.L	D0,AmgRtgFlipAt
	BSR	AmgRtgFlipPoll		; maybe due now
.x:	MOVEM.L	(SP)+,D0-D1
	RTS

; ---- a page waits (AmgRtgFlipPend): shown when the clock is in the AMGR_LEAD before its blank;
; when that blank has gone by, the next one is waited for. OS frozen. Keeps every register.
AmgRtgFlipPoll:
	MOVEM.L	D0-D2,-(SP)
	TST.L	AmgRtgVper
	BEQ.S	.go
	BSR	AmgRtgNow
	MOVE.L	D0,D2
	MOVE.L	D0,D1
	SUB.L	AmgRtgFlipAt,D1
	BMI.S	.x			; not yet
	CMP.L	#AMGR_LEAD,D1
	BLS.S	.go
	BSR	AmgRtgNextVb		; its blank has gone by: the next one
	SUB.L	#AMGR_LEAD,D0
	MOVE.L	D0,AmgRtgFlipAt
	SUB.L	D0,D2
	BMI.S	.x
.go:	BSR	AmgRtgShow
.x:	MOVEM.L	(SP)+,D0-D2
	RTS

; ---- the waiting page (AmgRtgFlipPg) shown; with a steady blank the pan's return (a blank's
; start) is the new anchor. OS frozen. Keeps every register.
AmgRtgShow:
	MOVEM.L	D0-D2,-(SP)
	IFD	AMG_SYNCLOG		; 4: a pan started (info: the page)
	MOVEQ	#0,D2
	MOVE.B	AmgRtgFlipPg,D2
	MOVEQ	#4,D1
	BSR	AmgSyncLog
	ENDC
	BSR	AmgRtgNow
	MOVE.L	D0,D2
	BSR	AmgRtgPan		; D0 = the clock at its return
	IFD	AMG_SYNCLOG
	SYNCEV	5,#0			; 5: its return
	ENDC
	TST.L	AmgRtgVper
	BEQ.S	.na
	MOVE.L	D0,AmgRtgVb
.na:
	IFD	AMG_RTGCOST
	MOVE.L	D0,D1
	SUB.L	D2,D1
	ADD.L	D1,AmgRtgCostS
	ADDQ.L	#1,AmgRtgCostSN
	CMP.L	#AMGR_LONG,D1
	BLS.S	.nl
	ADDQ.L	#1,AmgRtgCostSL
.nl:
	ENDC
	MOVE.B	AmgRtgFlipPg,D0		; the other page is drawn into next
	EOR.B	#1,D0
	MOVE.B	D0,AmgRtgPg
	SF	AmgRtgFlipPend
	MOVEM.L	(SP)+,D0-D2
	RTS

; ---- page AmgRtgFlipPg shown: RasInfo RyOffset, graphics ScrollVPort (P96 pans the board), on a
; stack of its own. OS alive or frozen (AmiGameBoy 2.5 pans the same way with the OS frozen).
; Out: D0 = the clock at its return. Keeps the rest.
AmgRtgPan:
	MOVEM.L	D1/A0-A1/A6,-(SP)
	MOVE.L	AmgRtgScr,A0
	LEA	$2C(A0),A0		; sc_ViewPort
	MOVE.L	36(A0),A1		; vp_RasInfo
	MOVEQ	#0,D0
	TST.B	AmgRtgFlipPg
	BEQ.S	.p
	MOVE.W	AmgRtgScrH,D0
.p:	MOVE.W	D0,10(A1)		; ri_RyOffset
	MOVE.L	AmgRtgGfx,A6
	MOVE.L	SP,AmgRtgPanSP
	LEA	AmgRtgPanStk,SP
	JSR	-588(A6)		; ScrollVPort
	MOVE.L	AmgRtgPanSP,SP
	MOVEM.L	(SP)+,D1/A0-A1/A6
	BRA	AmgRtgNow

; ---- D0 = a clock reading -> D0 = the first predicted blank start at or after it (AmgRtgVb + k
; periods). Over 4 M E clocks (~6 s) after the anchor: D0 as it is (the pan then finds the blank
; and anchors again). Keeps the rest.
AmgRtgNextVb:
	MOVEM.L	D1-D2,-(SP)
	MOVE.L	D0,D1
	SUB.L	AmgRtgVb,D1
	BPL.S	.a
	MOVE.L	AmgRtgVb,D0
	BRA.S	.x
.a:	CMP.L	#$400000,D1
	BCC.S	.x
	LSL.L	#8,D1
	MOVE.L	AmgRtgVper,D2
	ADD.L	D2,D1
	SUBQ.L	#1,D1
	DIVU.L	D2,D1			; whole periods, rounded up
	MULU.L	D2,D1
	LSR.L	#8,D1
	ADD.L	AmgRtgVb,D1
	MOVE.L	D1,D0
.x:	MOVEM.L	(SP)+,D1-D2
	RTS

; ---- the display's blank (AmgRtgOpen; OS alive, both pages black, the clock running): ten pans,
; to page 1, 0, 1 .. ending on 0, each AMGR_GAP after the last one's return so that it waits for
; the next blank. The first settles; the eight steps after it must be whole periods (1-3) of
; 8-25 ms, within 400 us (rtgfw's vt_calibrate). Out: AmgRtgVper (the period x 256) and AmgRtgVb
; (the last return), or AmgRtgVper 0 (a board whose pan returns at once, e.g. uaegfx: pans at
; the frame's end). Keeps every register.
AmgRtgVbCal:
	MOVEM.L	D0-D7/A0-A1/A6,-(SP)
	CLR.L	AmgRtgVper
	TST.L	AmgRtgCia
	BEQ	.x
	MOVE.L	4.W,A6
	JSR	-132(A6)		; Forbid
	LEA	AmgRtgCal,A0
	MOVEQ	#10-1,D7
	MOVEQ	#1,D6			; the page
.pan:	MOVE.B	D6,AmgRtgFlipPg
	BSR	AmgRtgPan
	MOVE.L	D0,(A0)+
	MOVE.L	D0,D1
.gap:	BSR	AmgRtgNow
	MOVE.L	D0,D2
	SUB.L	D1,D2
	CMP.L	#AMGR_GAP,D2
	BCS.S	.gap
	EOR.B	#1,D6
	DBF	D7,.pan
	MOVE.L	4.W,A6
	JSR	-138(A6)		; Permit
	LEA	AmgRtgCal+4,A0		; the shortest of the eight steps
	MOVE.L	#$7FFFFFFF,D5
	MOVEQ	#8-1,D7
.mn:	MOVE.L	4(A0),D0
	SUB.L	(A0)+,D0
	CMP.L	D5,D0
	BCC.S	.mn1
	MOVE.L	D0,D5
.mn1:	DBF	D7,.mn
	CMP.L	#AMGR_PMIN,D5
	BCS	.x
	CMP.L	#AMGR_PMAX,D5
	BHI	.x
	LEA	AmgRtgCal+4,A0		; each a whole number of it
	MOVEQ	#0,D4			; periods in all
	MOVEQ	#8-1,D7
.st:	MOVE.L	4(A0),D0
	SUB.L	(A0)+,D0
	MOVE.L	D5,D1
	LSR.L	#1,D1
	ADD.L	D0,D1
	DIVU.L	D5,D1			; k = (step + shortest / 2) / shortest
	CMP.L	#3,D1
	BHI	.x
	ADD.L	D1,D4
	MULU.L	D5,D1
	SUB.L	D0,D1
	BPL.S	.ab
	NEG.L	D1
.ab:	CMP.L	#AMGR_PTOL,D1
	BHI	.x
	DBF	D7,.st
	MOVE.L	AmgRtgCal+36,D0		; (the last - the second) x 256 / periods
	MOVE.L	D0,AmgRtgVb
	SUB.L	AmgRtgCal+4,D0
	LSL.L	#8,D0
	DIVU.L	D4,D0
	MOVE.L	D0,AmgRtgVper
.x:	MOVE.B	#1,AmgRtgPg		; page 0 shown, 1 drawn into
	MOVEM.L	(SP)+,D0-D7/A0-A1/A6
	RTS
	ENDC

	IFD	AMG_RTGSCAN
; ---- Scanlines (AMG_RTGSCAN; 27 Nov 2026: Arnold's seven settings, the same in every
; emulator). AmgRtgScanOn 1-6 = AmgCfgStyle + 1 when "Scanlines = On" and the scale is 2 or more.
; Of each console line's s screen rows the upper s - s / 2 are the line, the lower s / 2 the
; scanline (Arnold, rtgfw: the lower half), per channel in the screen's own bits:
;   Hard n%:  the line, each channel c x (100 - n) / 100            (n = 25, 50, 75)
;   Blended:  h(the line) + h(the line below), h(c) = c x (100 - n) / 200 (light 25, 50, strong 75)
;             the last line with itself; the two halves add with no carry out of a channel.
; Integer division, rounded down, as Arnold's rtgfw. AmgRtgScT holds, for every 16-bit screen pixel
; p (signed index from the table's middle), its scanline value in both words of a long: Hard in the
; screen's byte order; Blended h(p) in native order, the sum's bytes swapped back for PC formats.
; Made at Power ON (OS alive) when the style or the format changed.

; ---- AmgRtgOpen, after AmgRtgPix. Keeps every register.
AmgRtgScPrep:
	MOVEM.L	D0-D7/A0-A2,-(SP)
	TST.B	AmgCfgScan
	BEQ	.x
	MOVEQ	#0,D0
	MOVE.B	AmgCfgStyle,D0
	CMP.B	#5,D0
	BLS.S	.st
	MOVEQ	#1,D0			; not a style: Hard 50%
	MOVE.B	D0,AmgCfgStyle
.st:	SF	AmgRtgScBl
	MOVE.L	D0,D1			; D1 = 0-2: 25, 50, 75%
	CMP.B	#3,D0
	BCS.S	.hd
	ST	AmgRtgScBl
	SUBQ.B	#3,D1
.hd:	SF	AmgRtgScRol
	BTST	#0,AmgRtgPix
	BEQ.S	.be
	MOVE.B	#8,AmgRtgScRol
.be:	MOVE.B	AmgRtgPix,D2		; made already for this style and format?
	LSL.B	#4,D2
	OR.B	D0,D2
	CMP.B	AmgRtgScBK,D2
	BEQ	.x
	MOVE.B	D2,AmgRtgScBK
	MOVEQ	#0,D2			; D2 = 100 - n
	MOVE.B	.f(PC,D1.W),D2
	MOVEQ	#100,D3			; D3 = 100 (Hard) or 200 (Blended)
	TST.B	AmgRtgScBl
	BEQ.S	.dv
	MOVE.W	#200,D3
.dv:	LEA	AmgRtgScF,A1		; per channel value (5 or 6 bits): c x (100 - n) / D3
	MOVEQ	#0,D4
.cv:	MOVE.W	D4,D5
	MULU	D2,D5
	DIVU	D3,D5
	MOVE.B	D5,(A1,D4.W)
	ADDQ.W	#1,D4
	CMP.W	#64,D4
	BNE.S	.cv
	LEA	AmgRtgScT,A2
	MOVEQ	#0,D7			; every pixel u = 0-65535 as stored
.u:	MOVE.W	D7,D1
	TST.B	AmgRtgScRol
	BEQ.S	.nat
	ROL.W	#8,D1			; D1 = the pixel in native order
.nat:	MOVEQ	#0,D4
	MOVEQ	#0,D5
	BTST	#1,AmgRtgPix
	BNE.S	.c555
	MOVE.W	D1,D5			; 5-6-5
	LSR.W	#8,D5
	LSR.W	#3,D5
	MOVE.B	(A1,D5.W),D4
	LSL.W	#6,D4
	MOVE.W	D1,D5
	LSR.W	#5,D5
	AND.W	#63,D5
	BRA.S	.lo
.c555:	MOVE.W	D1,D5			; 5-5-5 (the top bit left 0)
	LSR.W	#8,D5
	LSR.W	#2,D5
	AND.W	#31,D5
	MOVE.B	(A1,D5.W),D4
	LSL.W	#5,D4
	MOVE.W	D1,D5
	LSR.W	#5,D5
	AND.W	#31,D5
.lo:	OR.B	(A1,D5.W),D4
	LSL.W	#5,D4
	MOVE.W	D1,D5
	AND.W	#31,D5
	OR.B	(A1,D5.W),D4
	TST.B	AmgRtgScBl		; Hard: back to the screen's byte order
	BNE.S	.put
	TST.B	AmgRtgScRol
	BEQ.S	.put
	ROL.W	#8,D4
.put:	MOVE.W	D4,D5			; both words
	SWAP	D4
	MOVE.W	D5,D4
	MOVE.W	D7,D5			; at (u EOR $8000): the signed index from the middle
	EOR.W	#$8000,D5
	MOVE.L	D4,(A2,D5.L*4)
	ADDQ.L	#1,D7
	CMP.L	#65536,D7
	BNE	.u
.x:	MOVEM.L	(SP)+,D0-D7/A0-A2
	RTS
.f:	DC.B	75,50,25
	EVEN

; ---- AmgRtgCopy with scanlines on (AmgRtgScanOn): A0 the frame's first line, A4 its last copy
; (this page's), A1 its first screen row, D3 longs in a line less 1, D4 pixels in a line, D5 the
; scale, D6 bytes a screen row, D7 lines less 1. A line that changed: its upper rows and its
; scanline rows. Blended also needs the line below: a line whose next line changed gets its
; scanline rows again (the changes found one line ahead, AmgRtgScC). Every register used.
AmgRtgCopyS:
	SF	AmgRtgScC
	TST.B	AmgRtgScBl
	BEQ.S	.ln
	MOVE.L	A0,A2			; Blended: line 0's change first
	MOVE.L	A4,A3
	BSR	AmgRtgCmpL
	SNE	AmgRtgScC
.ln:	TST.B	AmgRtgScBl
	BNE.S	.bl
	MOVE.L	A0,A2			; Hard: changed since this page's last copy?
	MOVE.L	A4,A3
	BSR	AmgRtgCmpL
	BEQ	.same
	BRA.S	.draw
.bl:	MOVE.B	AmgRtgScC,D2		; this line changed (found at the line above)
	SF	AmgRtgScC
	TST.W	D7
	BEQ.S	.bl1			; the last line blends with itself
	LEA	AMGR_RTG_W*2(A0),A2	; the next line changed?
	LEA	AMGR_RTG_W*2(A4),A3
	BSR	AmgRtgCmpL
	SNE	AmgRtgScC
.bl1:	TST.B	D2
	BNE.S	.draw
	TST.B	AmgRtgScC
	BEQ	.same
	BRA	.dark			; only the scanline rows are new
.draw:	MOVE.L	A0,A2			; keep it
	MOVE.L	A4,A3
	MOVE.W	D3,D0
.cp:	MOVE.L	(A2)+,(A3)+
	DBF	D0,.cp
	IFD	AMG_RTGCOST
	ADDQ.L	#1,AmgRtgCostY
	ENDC
	MOVE.L	A0,A2			; the scaled row
	LEA	AmgRtgRow,A3
	MOVE.W	D4,D0
	SUBQ.W	#1,D0
.ex:	MOVE.W	(A2)+,D1
	MOVE.W	D5,D2
	SUBQ.W	#1,D2
.ew:	MOVE.W	D1,(A3)+
	DBF	D2,.ew
	DBF	D0,.ex
	MOVE.L	A1,A5			; the upper rows
	MOVE.W	AmgRtgScNr,D2
	SUBQ.W	#1,D2
.wr:	LEA	AmgRtgRow,A2
	MOVE.L	A5,A3
	MOVE.W	AmgRtgRowL,D0
.wl:	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	DBF	D0,.wl
	ADD.L	D6,A5
	DBF	D2,.wr
.dark:	MOVE.L	A0,A2			; the scanline rows: from the line (and the next)
	MOVE.L	A0,A3
	TST.W	D7
	BEQ.S	.dk
	LEA	AMGR_RTG_W*2(A0),A3
.dk:	MOVE.L	A1,A5
	ADD.L	AmgRtgScOff,A5
	CMP.W	#1,AmgRtgScNd
	BNE.S	.dn
	BSR	AmgRtgScRow		; one row (scales 2, 3): straight to the screen
	BRA.S	.same
.dn:	MOVE.L	A5,-(SP)		; more: made once, copied
	LEA	AmgRtgRowD,A5
	BSR	AmgRtgScRow
	MOVE.L	(SP)+,A5
	MOVE.W	AmgRtgScNd,D2
	SUBQ.W	#1,D2
.dr:	LEA	AmgRtgRowD,A2
	MOVE.L	A5,A3
	MOVE.W	AmgRtgRowL,D0
.dl:	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	MOVE.L	(A2)+,(A3)+
	DBF	D0,.dl
	ADD.L	D6,A5
	DBF	D2,.dr
.same:	LEA	AMGR_RTG_W*2(A0),A0
	LEA	AMGR_RTG_W*2(A4),A4
	MOVE.W	D5,D0
.adv:	ADD.L	D6,A1
	SUBQ.W	#1,D0
	BNE.S	.adv
	DBF	D7,.ln
	SF	AmgRtgFull
	RTS

; A2 = a frame line, A3 = its last copy, D3 = longs in a line less 1 -> NE: changed (or every line
; wanted, AmgRtgFull). D0, A2, A3 used.
AmgRtgCmpL:
	TST.B	AmgRtgFull
	BNE.S	.x
	MOVE.W	D3,D0
.c:	CMP.L	(A2)+,(A3)+
	DBNE	D0,.c
.x:	RTS

; A2 = a frame line, A3 = the line below (Blended), A5 = where its scanline row goes, D4 = pixels in
; a line (even), D5 = the scale. One scaled row, two pixels a pass. Keeps every register.
AmgRtgScRow:
	MOVEM.L	D0-D2/D7/A2-A3/A5-A6,-(SP)
	LEA	AmgRtgScT+65536*2,A6
	MOVE.W	D4,D7
	LSR.W	#1,D7
	SUBQ.W	#1,D7
	TST.B	AmgRtgScBl
	BNE.S	.bl
	CMP.W	#2,D5
	BNE.S	.hg
.h2:	MOVE.W	(A2)+,D0		; Hard x2: a long from the table, as it is
	MOVE.L	(A6,D0.W*4),(A5)+
	MOVE.W	(A2)+,D0
	MOVE.L	(A6,D0.W*4),(A5)+
	DBF	D7,.h2
	BRA	.x
.hg:	MOVE.W	(A2)+,D0		; Hard x3 and up
	MOVE.L	(A6,D0.W*4),D0
	MOVE.W	(A2)+,D1
	MOVE.L	(A6,D1.W*4),D1
	BSR	.put
	DBF	D7,.hg
	BRA	.x
.bl:	TST.B	AmgRtgScRol
	BNE.S	.blp
	CMP.W	#2,D5
	BNE.S	.bg
.b2:	MOVE.W	(A2)+,D0		; Blended x2: h(upper) + h(lower), both words at once
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D0.W*4),D1
	ADD.L	(A6,D2.W*4),D1
	MOVE.L	D1,(A5)+
	MOVE.W	(A2)+,D0
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D0.W*4),D1
	ADD.L	(A6,D2.W*4),D1
	MOVE.L	D1,(A5)+
	DBF	D7,.b2
	BRA.S	.x
.blp:	CMP.W	#2,D5
	BNE.S	.bg
.bp2:	MOVE.W	(A2)+,D0		; PC byte order: the sum's bytes swapped back
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D0.W*4),D1
	ADD.L	(A6,D2.W*4),D1
	ROL.W	#8,D1
	SWAP	D1
	ROL.W	#8,D1
	MOVE.L	D1,(A5)+
	MOVE.W	(A2)+,D0
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D0.W*4),D1
	ADD.L	(A6,D2.W*4),D1
	ROL.W	#8,D1
	SWAP	D1
	ROL.W	#8,D1
	MOVE.L	D1,(A5)+
	DBF	D7,.bp2
	BRA.S	.x
.bg:	MOVE.W	(A2)+,D0		; Blended x3 and up
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D0.W*4),D0
	ADD.L	(A6,D2.W*4),D0
	MOVE.W	(A2)+,D1
	MOVE.W	(A3)+,D2
	MOVE.L	(A6,D1.W*4),D1
	ADD.L	(A6,D2.W*4),D1
	TST.B	AmgRtgScRol
	BEQ.S	.bg1
	ROL.W	#8,D0
	ROL.W	#8,D1
.bg1:	BSR.S	.put
	DBF	D7,.bg
.x:	MOVEM.L	(SP)+,D0-D2/D7/A2-A3/A5-A6
	RTS
.put:	MOVE.W	D5,D2			; D0.W s times, then D1.W s times
	SUBQ.W	#1,D2
.p0:	MOVE.W	D0,(A5)+
	DBF	D2,.p0
	MOVE.W	D5,D2
	SUBQ.W	#1,D2
.p1:	MOVE.W	D1,(A5)+
	DBF	D2,.p1
	RTS
	ENDC

	IFD	AMG_SYNCLOG
; ---- test builds (AMG_SYNCLOG, 26 Nov 2026: "refresh issues" seen in Micro Machines, single and
; double buffered, NTSC and PAL): the pacing and the pans timed on the E clock, no camera needed.
; A ring of AMGS_N events of 8 bytes (E clock long, type word, info word), types:
;   1 frame emulated (info: 1 drawn, 2 two pages, 4 a page still waits)   2 copied to the screen
;   3 the waiting page replaced (never shown)   4 pan started (info: page)   5 pan returned
;   6 late (info: E clocks late / 16)   7 the E-clock wait over (the next frame starts)
; AmgSyncWrite (Power OFF, OS alive) writes PROGDIR:SyncLog1.bin .. SyncLog9.bin in turn: a
; 64-byte header (see tools/synclog.py), then the events oldest first. tools/synclog.py reads it.
AMGS_N	= 32768			; ~2 minutes at about 4 events a frame
; D1.W type, D2.W info. OS alive or frozen. Keeps every register (not CCR).
AmgSyncLog:
	MOVEM.L	D0/D3/A0,-(SP)
	MOVEQ	#0,D0
	BSR	AmgRtgNow		; D0 = now (0 with no timer)
	MOVE.L	AmgSyncI,D3
	LEA	AmgSyncBuf,A0
	LSL.L	#3,D3
	ADD.L	D3,A0
	MOVE.L	D0,(A0)+
	MOVE.W	D1,(A0)+
	MOVE.W	D2,(A0)
	MOVE.L	AmgSyncI,D3
	ADDQ.L	#1,D3
	AND.L	#AMGS_N-1,D3
	MOVE.L	D3,AmgSyncI
	ADDQ.L	#1,AmgSyncCnt
	MOVEM.L	(SP)+,D0/D3/A0
	RTS

; ---- the log to PROGDIR:SyncLog<n>.bin. OS alive, the screen still open. Keeps every register.
AmgSyncWrite:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.L	AmgSyncCnt
	BEQ	.x
	LEA	AmgSyncHdr,A0		; the header
	MOVE.L	#"AMGS",(A0)+
	MOVE.L	#1,(A0)+		; version
	MOVE.L	AmgSyncCnt,(A0)+	; events in all (the ring keeps the last AMGS_N)
	MOVE.L	#AMGS_N,(A0)+
	MOVE.L	AmgRtgPer,(A0)+		; E clocks a console frame
	MOVE.L	AmgRtgVper,(A0)+	; the display's period x 256, 0 = none found
	MOVE.L	AmgRtgVb,(A0)+
	MOVE.L	4.W,A1
	MOVE.L	$238(A1),(A0)+		; E clock Hz
	MOVE.B	AmgRtgDbl,(A0)+		; two pages
	MOVE.B	AmgCfgBuf,(A0)+		; 0 Single, 1 Double, 2 Plain
	MOVE.B	DirPrefs+$0F,(A0)+	; Screen mode: 1 NTSC, 0 PAL
	MOVE.B	DirPrefs+$10,(A0)+	; Gfx Refresh
	MOVE.B	DirPrefs+$13,(A0)+	; 2 Turbo
	MOVE.B	AmgCfgScreen,(A0)+
	MOVE.W	AmgRtgScale,(A0)+
	MOVE.L	AmgRtgTagM+4,(A0)+	; ModeID
	MOVE.W	AmgRtgScrW,(A0)+
	MOVE.W	AmgRtgScrH,(A0)+
	MOVE.W	AmgRtgH,(A0)+
	MOVE.W	#AMGR_LEAD,(A0)+
	MOVE.L	AmgRtgClock,(A0)+	; the clock now
	; (64 bytes: the rest stays 0)
	MOVE.B	AmgSyncNo,D0		; the name: 1 .. 9 in turn
	ADDQ.B	#1,D0
	CMP.B	#"9",D0
	BLS.S	.nm
	MOVE.B	#"1",D0
.nm:	MOVE.B	D0,AmgSyncNo
	MOVE.B	D0,AmgSyncDig
	MOVE.L	4.W,A6
	LEA	AmgSyncDos(PC),A1
	MOVEQ	#36,D0
	JSR	-552(A6)		; OpenLibrary
	TST.L	D0
	BEQ	.x
	MOVE.L	D0,A6
	MOVE.L	#AmgSyncName,D1
	MOVE.L	#1006,D2		; MODE_NEWFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D7
	BEQ.S	.cl
	MOVE.L	D7,D1
	MOVE.L	#AmgSyncHdr,D2
	MOVEQ	#64,D3
	JSR	-48(A6)			; Write
	MOVE.L	AmgSyncCnt,D4
	CMP.L	#AMGS_N,D4
	BLS.S	.one
	MOVE.L	D7,D1			; the ring wrapped: the oldest (from AmgSyncI) first
	MOVE.L	AmgSyncI,D3
	LSL.L	#3,D3
	MOVE.L	#AmgSyncBuf,D2
	ADD.L	D3,D2
	NEG.L	D3
	ADD.L	#AMGS_N*8,D3
	JSR	-48(A6)
.one:	MOVE.L	D7,D1			; then from the start to AmgSyncI
	MOVE.L	#AmgSyncBuf,D2
	MOVE.L	AmgSyncI,D3
	LSL.L	#3,D3
	BEQ.S	.c
	JSR	-48(A6)
.c:	MOVE.L	D7,D1
	JSR	-36(A6)			; Close
.cl:	MOVE.L	A6,A1
	MOVE.L	4.W,A6
	JSR	-414(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
AmgSyncDos:	DC.B	"dos.library",0
	EVEN
	ENDC

	IFD	AUTOTEST
; ---- test builds, at each AutoTest stop (registers kept): "@C <frames drawn> <E clocks drawing
; lines> <lines drawn> <E clocks copying> <lines copied> <E clock Hz> <scale> <screen w> <h>" with
; AMG_RTGCOST; with AMG_RTGSHOT the shown picture as "@P <w> <h> <format flags>", then its pixels
; in hex, a line of text per picture line, then "@E". tools/rtgrun.py reads both.
AmgRtgAuto:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	AmgRtgOn
	BEQ	.x
	IFD	AMG_RTGCOST
	LEA	AmgRtgTxt,A1
	MOVE.B	#"@",(A1)+
	MOVE.B	#"C",(A1)+
	MOVE.L	AmgRtgCostF,D0
	BSR	.dec
	MOVE.L	AmgRtgCostL,D0
	BSR	.dec
	MOVE.L	AmgRtgCostN,D0
	BSR	.dec
	MOVE.L	AmgRtgCostC,D0
	BSR	.dec
	MOVE.L	AmgRtgCostY,D0
	BSR	.dec
	MOVE.L	4.W,A0
	MOVE.L	$238(A0),D0
	BSR	.dec
	MOVEQ	#0,D0
	MOVE.W	AmgRtgScale,D0
	BSR	.dec
	MOVE.W	AmgRtgScrW,D0
	BSR	.dec
	MOVE.W	AmgRtgScrH,D0
	BSR	.dec
	IFD	AMG_RTGDBUF		; then: pages (1/2), the blank period found (E clocks, 0 none),
	MOVEQ	#1,D0			; pans, E clocks in pans, pans over 2.5 ms, frames never shown,
	TST.B	AmgRtgDbl		; scanlines (0-2), screen option (0-1)
	BEQ.S	.d1
	MOVEQ	#2,D0
.d1:	BSR	.dec
	MOVE.L	AmgRtgVper,D0
	LSR.L	#8,D0
	BSR	.dec
	MOVE.L	AmgRtgCostSN,D0
	BSR	.dec
	MOVE.L	AmgRtgCostS,D0
	BSR	.dec
	MOVE.L	AmgRtgCostSL,D0
	BSR	.dec
	MOVE.L	AmgRtgCostSD,D0
	BSR	.dec
	MOVEQ	#0,D0
	IFD	AMG_RTGSCAN
	MOVE.B	AmgRtgScanOn,D0
	ENDC
	BSR	.dec
	MOVEQ	#0,D0
	MOVE.B	AmgCfgScreen,D0
	BSR	.dec
	CLR.L	AmgRtgCostSN
	CLR.L	AmgRtgCostS
	CLR.L	AmgRtgCostSL
	CLR.L	AmgRtgCostSD
	ENDC
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	CLR.L	AmgRtgCostF
	CLR.L	AmgRtgCostL
	CLR.L	AmgRtgCostN
	CLR.L	AmgRtgCostC
	CLR.L	AmgRtgCostY
	ENDC
	IFD	AMG_RTGSHOT
	LEA	AmgRtgTxt,A1
	MOVE.B	#"@",(A1)+
	MOVE.B	#"P",(A1)+
	MOVEQ	#0,D0
	MOVE.W	AmgRtgPW,D0
	BSR	.dec
	MOVE.W	AmgRtgPH,D0
	BSR	.dec
	MOVE.B	AmgRtgPix,D0
	BSR	.dec
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	MOVEQ	#0,D0			; the shown lines, from the copy kept (AmgRtgOld)
	MOVE.W	AmgRtgPT,D0
	LSL.L	#8,D0
	ADD.L	D0,D0
	MOVEQ	#0,D1
	MOVE.W	AmgRtgPL,D1
	ADD.L	D1,D1
	ADD.L	D1,D0
	LEA	AmgRtgOld,A2
	ADD.L	D0,A2
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgLastPg		; two pages: the one copied last
	BEQ.S	.s0
	ADD.L	#AmgRtgOld1-AmgRtgOld,A2
.s0:
	ENDC
	MOVE.W	AmgRtgPH,D7
	SUBQ.W	#1,D7
	LEA	.hex(PC),A4
.pl:	LEA	AmgRtgTxt,A1
	MOVE.L	A2,A3
	MOVE.W	AmgRtgPW,D6
	SUBQ.W	#1,D6
.pw:	MOVE.W	(A3)+,D0
	MOVEQ	#4-1,D2
.nib:	ROL.W	#4,D0
	MOVEQ	#15,D1
	AND.W	D0,D1
	MOVE.B	(A4,D1.W),(A1)+
	DBF	D2,.nib
	DBF	D6,.pw
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	LEA	AMGR_RTG_W*2(A2),A2
	DBF	D7,.pl
	IFD	AMG_RTGSHOTQ		; and the screen itself: "@Q <w> <h> <format flags> <scale>
	LEA	AmgRtgTxt,A1		; <scanline setting>", then the picture's screen rows in hex
	MOVE.B	#"@",(A1)+		; (the page copied last), for the scanline checks
	MOVE.B	#"Q",(A1)+		; (tools/scancheck.py)
	MOVEQ	#0,D0
	MOVE.W	AmgRtgPW,D0
	MULU	AmgRtgScale,D0
	BSR	.dec
	MOVEQ	#0,D0
	MOVE.W	AmgRtgPH,D0
	MULU	AmgRtgScale,D0
	BSR	.dec
	MOVEQ	#0,D0
	MOVE.B	AmgRtgPix,D0
	BSR	.dec
	MOVEQ	#0,D0
	MOVE.W	AmgRtgScale,D0
	BSR	.dec
	MOVEQ	#0,D0
	IFD	AMG_RTGSCAN
	MOVE.B	AmgRtgScanOn,D0
	ENDC
	BSR	.dec
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	MOVE.L	AmgRtgOrg,A2
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgLastPg
	BEQ.S	.q0
	ADD.L	AmgRtgPgOff,A2
.q0:
	ENDC
	MOVE.W	AmgRtgPH,D7
	MULU	AmgRtgScale,D7
	SUBQ.W	#1,D7
.ql:	LEA	AmgRtgTxt,A1
	MOVE.L	A2,A3
	MOVE.W	AmgRtgPW,D6
	MULU	AmgRtgScale,D6
	SUBQ.W	#1,D6
.qw:	MOVE.W	(A3)+,D0
	MOVEQ	#4-1,D2
.qn:	ROL.W	#4,D0
	MOVEQ	#15,D1
	AND.W	D0,D1
	MOVE.B	(A4,D1.W),(A1)+
	DBF	D2,.qn
	DBF	D6,.qw
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	ADD.L	AmgRtgBpr,A2
	DBF	D7,.ql
	ENDC
	LEA	AmgRtgEnd(PC),A0
	JSR	AutoPuts
	ENDC
	IFD	AMGR_T_SCR		; (tests) "@S <row>: " + 32 pixels of the screen itself, 4 rows
	MOVE.L	AmgRtgOrg,A2		; from the picture's top left + 512 bytes, the page shown
	IFD	AMG_RTGDBUF
	TST.B	AmgRtgLastPg
	BEQ.S	.t0
	ADD.L	AmgRtgPgOff,A2
.t0:
	ENDC
	LEA	512(A2),A2
	LEA	.hex(PC),A4
	MOVEQ	#4-1,D7
.tr:	LEA	AmgRtgTxt,A1
	MOVE.B	#"@",(A1)+
	MOVE.B	#"S",(A1)+
	MOVE.B	#" ",(A1)+
	MOVE.L	A2,A3
	MOVEQ	#32-1,D6
.tw:	MOVE.W	(A3)+,D0
	MOVEQ	#4-1,D2
.tn:	ROL.W	#4,D0
	MOVEQ	#15,D1
	AND.W	D0,D1
	MOVE.B	(A4,D1.W),(A1)+
	DBF	D2,.tn
	MOVE.B	#" ",(A1)+
	DBF	D6,.tw
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AmgRtgTxt,A0
	JSR	AutoPuts
	ADD.L	AmgRtgBpr,A2
	DBF	D7,.tr
	ENDC
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS
.hex:	DC.B	"0123456789ABCDEF"
; " <D0 in decimal>" at A1
.dec:	MOVE.B	#" ",(A1)+
	LEA	12(A1),A0
	MOVE.L	A0,D3
	MOVEQ	#0,D2
.d:	DIVUL.L	#10,D1:D0
	ADD.B	#"0",D1
	MOVE.B	D1,-(A0)
	ADDQ.W	#1,D2
	TST.L	D0
	BNE.S	.d
	SUBQ.W	#1,D2
.dm:	MOVE.B	(A0)+,(A1)+
	DBF	D2,.dm
	RTS
AmgRtgEnd:	DC.B	"@E",10,0
	EVEN
	ENDC

AmgRtgGfxN:	DC.B	"graphics.library",0
AmgRtgIntN:	DC.B	"intuition.library",0
AmgRtgP96N:	DC.B	"Picasso96API.library",0
AmgRtgCiabN:	DC.B	"ciab.resource",0
	EVEN

	SECTION	AmgRtgData,DATA
AmgRtgTags:
AmgRtgTagW:	DC.L	$80000023,0	; SA_Width
AmgRtgTagH:	DC.L	$80000024,0	; SA_Height
AmgRtgTagD:	DC.L	$80000025,0	; SA_Depth
AmgRtgTagM:	DC.L	$80000032,0	; SA_DisplayID
		DC.L	$80000038,1	; SA_Quiet
		DC.L	$80000036,0	; SA_ShowTitle
		DC.L	$8000002D,$000F	; SA_Type: CUSTOMSCREEN
		DC.L	$8000003E,0	; SA_Draggable
		DC.L	$8000003F,1	; SA_Exclusive
		DC.L	0
AmgRtgWTags:
AmgRtgWScr:	DC.L	$80000070,0	; WA_CustomScreen
		DC.L	$80000064,0	; WA_Left
		DC.L	$80000065,0	; WA_Top
AmgRtgWW:	DC.L	$80000066,0	; WA_Width
AmgRtgWH:	DC.L	$80000067,0	; WA_Height
		DC.L	$80000085,1	; WA_Backdrop
		DC.L	$80000088,1	; WA_Borderless
		DC.L	$8000008C,1	; WA_SimpleRefresh
		DC.L	$80000087,1	; WA_NoCareRefresh
		DC.L	$8000008A,1	; WA_RMBTrap
		DC.L	$80000089,1	; WA_Activate
		DC.L	0
AmgRtgIcr:	DC.L	0,0		; ln_Succ, ln_Pred
		DC.B	2,0		; ln_Type NT_INTERRUPT, ln_Pri
		DC.L	AmgRtgIcrName	; ln_Name
		DC.L	0,AmgRtgIcrCode	; is_Data, is_Code
AmgRtgIcrName:	DC.B	"AmiMasterGear pacing",0
; P96 RGBFormat, AmgRtgPix flags (bit 0 PC byte order, bit 1 5-5-5, bit 2 BGR)
AmgRtgFmts:	DC.B	10,0		; R5G6B5
		DC.B	4,1		; R5G6B5PC (uaegfx)
		DC.B	11,2		; R5G5B5
		DC.B	5,3		; R5G5B5PC
		DC.B	12,5		; B5G6R5PC
		DC.B	13,7		; B5G5R5PC
		DC.B	-1,-1
	EVEN
AmgRtgGfx:	DC.L	0		; (AmgRtgShut closes these three)
AmgRtgInt:	DC.L	0
AmgRtgP96:	DC.L	0
AmgRtgScr:	DC.L	0
AmgRtgWin:	DC.L	0
AmgRtgPrevW:	DC.L	0
AmgRtgBm:	DC.L	0
AmgRtgMem:	DC.L	0
AmgRtgBpr:	DC.L	0
AmgRtgOrg:	DC.L	0		; the picture's top left on the screen
AmgRtgRI:	DC.L	0,0,0		; RenderInfo: Memory, BytesPerRow (word) + pad, RGBFormat
AmgRtgCiab:	DC.L	0
AmgRtgCia:	DC.L	0		; the timer's low byte register, 0 = no timer
AmgRtgPer:	DC.L	11838		; E clocks a frame
AmgRtgDue:	DC.L	0		; the next frame's time
AmgRtgClock:	DC.L	0
	IFD	AMG_RTGCOST
AmgRtgCostF:	DC.L	0		; frames copied
AmgRtgCostL:	DC.L	0		; E clocks in AmgRtgLine
AmgRtgCostN:	DC.L	0		; lines drawn
AmgRtgCostC:	DC.L	0		; E clocks in AmgRtgCopy
AmgRtgCostY:	DC.L	0		; lines copied
	ENDC
AmgRtgPrev:	DC.W	$FFFF
AmgRtgScrW:	DC.W	0
AmgRtgScrH:	DC.W	0
AmgRtgFW:	DC.W	256		; AmgRtgFind: the picture's width and its two heights
AmgRtgFH1:	DC.W	192
AmgRtgFH2:	DC.W	224
AmgRtgH:	DC.W	0		; picture lines (192 or 224), 0 = laid out at the next frame
AmgRtgNext:	DC.W	$7FFF		; CurLine at which the next line is drawn
AmgRtgLast:	DC.W	0		; CurLine of the frame's last line drawn
AmgRtgScale:	DC.W	1
AmgRtgPW:	DC.W	256		; the picture shown: width, height, first line, first column
AmgRtgPH:	DC.W	192
AmgRtgPT:	DC.W	0
AmgRtgPL:	DC.W	0
AmgRtgRowL:	DC.W	0		; longs in a scaled row / 8, less 1
AmgRtgOn:	DC.B	0		; the RTG screen is up
AmgRtgDraw:	DC.B	0		; this frame is drawn
AmgRtgDrawNext:	DC.B	0
AmgRtgLay:	DC.B	0
AmgRtgFull:	DC.B	0		; every line at the next copy
AmgRtgSkip:	DC.B	0
AmgRtgSync:	DC.B	0
AmgRtgVS:	DC.B	0		; the frame's vertical scroll
AmgRtgPix:	DC.B	0		; pixel format flags
AmgRtgTBit:	DC.B	0		; 0 timer A, 1 timer B
AmgRtgTabOK:	DC.B	0
AmgRtgPalV:	DC.B	0		; AmgRtgPalC holds the palette RAM AmgRtgP16 was made from
	EVEN
	IFD	AMG_RTGDBUF
AmgRtgPgOff:	DC.L	0		; page 1 in the bitmap (bytes)
AmgRtgVper:	DC.L	0		; the display's period x 256 (E clocks), 0 = no steady blank
AmgRtgVb:	DC.L	0		; a blank's start (the last pan's return)
AmgRtgFlipAt:	DC.L	0		; when the waiting page's pan starts
AmgRtgPanSP:	DC.L	0
	IFD	AMG_RTGCOST
AmgRtgCostS:	DC.L	0		; E clocks in pans
AmgRtgCostSN:	DC.L	0		; pans
AmgRtgCostSL:	DC.L	0		; pans over AMGR_LONG
AmgRtgCostSD:	DC.L	0		; frames replaced before they were shown
	ENDC
AmgRtgDbl:	DC.B	0		; two pages
AmgRtgPg:	DC.B	0		; the page drawn into (hidden)
AmgRtgFlipPg:	DC.B	0		; the page to show
AmgRtgFlipPend:	DC.B	0		; a page waits for its blank
AmgRtgLastPg:	DC.B	0		; the page copied last (test pictures)
AmgRtgPollN:	DC.B	1		; lines to the next check
AmgRtgFullP:	DC.B	0,0		; every line at the page's next copy
	EVEN
	ENDC
	IFD	AMG_RTGSCAN
AmgRtgScanOn:	DC.B	0		; 0 off, 1-3 Hard 25/50/75%, 4-6 Blended light/-/strong (at
					; scale 2 and up; Arnold's order)
AmgRtgScBl:	DC.B	0		; the style is Blended
AmgRtgScRol:	DC.B	0		; 8: PC byte order (the Blended sum's bytes swapped back)
AmgRtgScC:	DC.B	0		; (AmgRtgCopyS) the next line changed
AmgRtgScBK:	DC.B	-1		; the table's style + format x 16 (-1: none made)
	EVEN
AmgRtgScNr:	DC.W	0		; of a line's s screen rows: the upper ones (s - s / 2)
AmgRtgScNd:	DC.W	0		; the scanline rows below them (s / 2)
AmgRtgScOff:	DC.L	0		; bytes from a line's first row to its first scanline row
AmgRtgScF:	DS.B	64		; a channel value 0-63 -> its scanline value (AmgRtgScPrep)
	ENDC
	IFD	AMG_SYNCLOG
AmgSyncI:	DC.L	0		; the next event's place in the ring
AmgSyncCnt:	DC.L	0		; events this play
AmgSyncName:	DC.B	"PROGDIR:SyncLog"
AmgSyncDig:	DC.B	"1.bin",0
AmgSyncNo:	DC.B	"0"		; the last file's digit
	EVEN
	ENDC

	SECTION	AmgRtgChip,DATA_C
AmgRtgBlank:	DC.W	0,0,0,0,0,0	; a blank pointer sprite

	SECTION	AmgRtgBss,BSS
AmgRtgSave:	DS.L	16		; the Z80's registers while a line is drawn
		DS.L	256
AmgRtgStk:				; (its stack grows down from here)
		DS.L	2
AmgRtgP16:	DS.W	256		; the colours now, screen format (0-31, 128-159)
AmgRtgPalC:	DS.L	16		; the palette RAM at the last colours made
AmgRtgLutMS:	DS.W	64
AmgRtgLutGG:	DS.W	4096
AmgRtgDec:	DS.B	4*256*8
AmgRtgIdx:	DS.B	256+16		; a line of palette indices (+ the cell past the right edge)
AmgRtgOcc:	DS.B	256		; sprite pixels taken on the line
AmgRtgSp8:	DS.B	8
AmgRtgFB:	DS.W	AMGR_RTG_W*AMGR_RTG_H	; the frame
AmgRtgOld:	DS.W	AMGR_RTG_W*AMGR_RTG_H	; as last copied to the screen
AmgRtgRow:	DS.W	AMGR_RTG_W*AMGR_MAXS	; one scaled row
	IFD	AMG_RTGDBUF
AmgRtgOld1:	DS.W	AMGR_RTG_W*AMGR_RTG_H	; page 1 as last copied
AmgRtgCal:	DS.L	10			; the calibration pans' returns
		DS.L	2048
AmgRtgPanStk:					; ScrollVPort's stack
		DS.L	2
	ENDC
	IFD	AMG_RTGSCAN
AmgRtgRowD:	DS.W	AMGR_RTG_W*AMGR_MAXS	; a scaled scanline row (scales 4 and up)
AmgRtgScT:	DS.L	65536			; screen pixel -> its scanline pixel twice (AmgRtgScPrep)
	ENDC
	IFD	AUTOTEST
AmgRtgTxt:	DS.B	AMGR_RTG_W*AMGR_MAXS*4+64	; (a screen row in hex: AMG_RTGSHOTQ)
	ENDC
	IFD	AMG_SYNCLOG
AmgSyncHdr:	DS.B	64
AmgSyncBuf:	DS.B	AMGS_N*8
	ENDC

	IFD	AMG_RTGCFG
	INCLUDE	"AmgRtgCfg.asm"		; the options: AmiMasterGear.config and ToolTypes
	ENDC
