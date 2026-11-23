; Amg10.asm: AmiMasterGear 1.1 additions to Juan's v0.8. Each part is behind its own switch;
; with none of them set this file assembles to nothing.

; Writes that v0.8 did not pass to the mapper come here once the byte is stored, with A4 on it
; and A4 >= IRAM+$3FFC: LD (IX/IY+d),r and LD (IX/IY+d),n (AMG_IXMAP, 19 cycles), SET/RES b,(HL)
; (AMG_BITMAP, 15) and SET/RES b,(IX/IY+d) (AMG_BITMAP, 23). The mapper sees the write, as on the
; console. SRAM follows IRAM, so check the top end too. Same stack depth as v0.8's Mapper.
AmgIxMapM:	MACRO
AmgIxMap\1:
	CMP.L	#IRAM+$4000,A4
	BCC.S	AmgIxMapNo\1
	MOVE.B	(A4),D1
	SUB.L	#IRAM+$3FFC,A4
	ADD.L	A4,A4
	ADD.L	A4,A4
	ADD.L	#MapperROM,A4
	MOVE.L	(A4),A4
	JSR	(A4)
AmgIxMapNo\1:
	Otra	\1
	ENDM

	IFND	AMG_RAMMIRROR
	IFD	AMG_IXMAP
	AmgIxMapM 19
	ENDC
	IFD	AMG_BITMAP
	AmgIxMapM 15
	AmgIxMapM 23
	ENDC
	ENDC

	IFD	AMG_RAMMIRROR
; With AMG_RAMMIRROR $FFFC-$FFFF are RAM at IRAM+$1FFC, the same bytes as $DFFC-$DFFF, so the
; caller has checked the Z80 address (>= $FFFC) and only the mapper is left to do.
AmgIxMapRM:	MACRO
AmgIxMapR\1:
	MOVE.B	(A4),D1
	SUB.L	#IRAM+$1FFC,A4
	ADD.L	A4,A4
	ADD.L	A4,A4
	ADD.L	#MapperROM,A4
	MOVE.L	(A4),A4
	JSR	(A4)
	Otra	\1
	ENDM

	IFD	AMG_IXMAP
	AmgIxMapRM 19
; LD (IX/IY+d),r (d the byte before A5) and LD (IX/IY+d),n (two before): the Z80 address
AmgIxMapDM:	MACRO
AmgIxMapR19D\1\2:
	MOVE.B	-\1(A5),D1
	EXT.W	D1
	ADD.W	\2,D1
	CMP.W	#$FFFC,D1
	BCC	AmgIxMapR19
	Otra	19
	ENDM
	AmgIxMapDM 1,A0
	AmgIxMapDM 1,A1
	AmgIxMapDM 2,A0
	AmgIxMapDM 2,A1
	ENDC
	IFD	AMG_BITMAP
	AmgIxMapRM 15
	AmgIxMapRM 23
	ENDC
	ENDC

	IFD	AMG_CODIES
	SECTION	AmgCodies,CODE

; The Codemasters mapper (Micro Machines, Micro Machines 2 and others). A write to $0000, $4000 or
; $8000 selects the 16K bank in that slot; the whole of slot 0 switches (no fixed first 1K) and
; $FFFC-$FFFF are plain RAM. Found by the cartridge's Codemasters header: the word at $7FE6 is a
; checksum and the word at $7FE8 its negative.
;
; The bank writes are caught in the instructions that store A: LD (nn),A, LD (HL),A, LD (BC),A and
; LD (DE),A, which is how these games write the mapper. A bank write from any other instruction
; would go unseen.

; At power on, A3 = Regs. Puts the Codemasters handlers in or takes them out.
AmgCmInstall:
	MOVEM.L	D0-D1/A0-A2,-(SP)
	MOVE.L	DirCart,A0
	ADD.L	#$80+$4080+$3FE6,A0	; $7FE6 in bank 1
	MOVEQ	#0,D0
	MOVE.B	1(A0),D0
	LSL.W	#8,D0
	MOVE.B	(A0),D0
	MOVEQ	#0,D1
	MOVE.B	3(A0),D1
	LSL.W	#8,D1
	MOVE.B	2(A0),D1
	SF	AmgCodies
	TST.W	D0
	BEQ.S	.chosen
	ADD.W	D1,D0
	BNE.S	.chosen
	ST	AmgCodies
.chosen:
	LEA	AmgCmOps,A0
	LEA	Instr,A1
.op:	MOVE.W	(A0)+,D0
	BMI.S	.mapper
	MOVE.L	(A0)+,D1		; Codemasters handler
	MOVE.L	(A0)+,A2		; v0.8's
	TST.B	AmgCodies
	BNE.S	.put
	MOVE.L	A2,D1
.put:	MOVE.L	D1,(A1,D0.W*8)
	MOVE.L	D1,4(A1,D0.W*8)
	BRA.S	.op
.mapper:
	LEA	MapperROM,A1
	LEA	AmgCmSega,A0
	TST.B	AmgCodies
	BEQ.S	.regs
	LEA	AmgCmNone,A0
.regs:	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVEM.L	(SP)+,D0-D1/A0-A2
	RTS

; The handlers. D7 = A, D4 = HL, D5 = BC, D6 = DE; D2's high byte must be kept (dispatch).
	CNOP	0,4
AmgCmLDMA:				; LD (nn),A
	MOVE.W	(A5),D1
	ROR.W	#8,D1
	BSR	AmgCmWhich
	BEQ.S	AmgCmLDMANo
	ADDQ.W	#2,A5
	BSR	AmgCmBank
	Otra	13
AmgCmLDMANo:	JMP	LDMA

	CNOP	0,4
AmgCmLDHLA:				; LD (HL),A
	MOVE.W	D4,D1
	BSR	AmgCmWhich
	BEQ.S	AmgCmLDHLANo
	BSR	AmgCmBank
	Otra	7
AmgCmLDHLANo:	JMP	LDHLA

	CNOP	0,4
AmgCmLDBCA:				; LD (BC),A
	MOVE.W	D5,D1
	BSR	AmgCmWhich
	BEQ.S	AmgCmLDBCANo
	BSR	AmgCmBank
	Otra	7
AmgCmLDBCANo:	JMP	LDBCA

	CNOP	0,4
AmgCmLDDEA:				; LD (DE),A
	MOVE.W	D6,D1
	BSR	AmgCmWhich
	BEQ.S	AmgCmLDDEANo
	BSR	AmgCmBank
	Otra	7
AmgCmLDDEANo:	JMP	LDDEA

; D1.W = address. Out: Z clear and AmgCmSlot = 1, 2 or 3 for $0000, $4000, $8000; Z set otherwise.
AmgCmWhich:
	TST.W	D1
	BEQ.S	.s0
	CMP.W	#$4000,D1
	BEQ.S	.s1
	CMP.W	#$8000,D1
	BEQ.S	.s2
	CLR.B	AmgCmSlot
	RTS
.s0:	MOVE.B	#1,AmgCmSlot
	RTS
.s1:	MOVE.B	#2,AmgCmSlot
	RTS
.s2:	MOVE.B	#3,AmgCmSlot
	RTS

; The bank in D7 into slot AmgCmSlot-1. Reached with A7 on the current page's Restas entry, as
; v0.8's FFFD/FFFE/FFFF are: they work out the Z80 PC from 4(A7) after the JSR, and so do these.
AmgCmBank:
	MOVEQ	#0,D1
	MOVE.B	D7,D1
	CMP.B	#2,AmgCmSlot
	IFD	AMG_RAMMIRROR
	BCS	AmgCmSlot0
	BEQ	AmgCmSlot1
	BRA	AmgCmSlot2
	ELSE
	BCS.S	AmgCmSlot0
	BEQ.S	AmgCmSlot1
	BRA.S	AmgCmSlot2
	ENDC

AmgCmSlot0:				; as FFFD, without the RAM copy at $DFFD
	SUB.W	4(A7),A5		; one return address on the stack, as in FFFD
	AND.W	MaskROM(A3),D1
	MULU	#$4080,D1
	ADD.L	MapROMBase(A3),D1
	ADD.L	#$4000,D1
	IFD	AMG_RAMMIRROR
	AmgPag8	0
	ELSE
	MOVE.L	D1,PagRead+$0(A3)
	MOVE.W	D1,Restas+($0*2)(A3)
	ADDQ.L	#$0001,D1
	MOVE.L	D1,Restas+Desbor+($0)(A3)
	ADD.L	#$3FFF,D1
	MOVE.L	D1,Restas+Desbor+($4)(A3)
	ENDC
	IFD	AMG_RAMMIRROR
	BRA	AmgCmPC
	ELSE
	BRA.S	AmgCmPC
	ENDC

AmgCmSlot1:				; as FFFE
	SUB.W	4(A7),A5
	AND.W	MaskROM(A3),D1
	MULU	#$4080,D1
	ADD.L	MapROMBase(A3),D1
	IFD	AMG_RAMMIRROR
	AmgPag8	1
	ELSE
	MOVE.L	D1,PagRead+$4(A3)
	MOVE.W	D1,Restas+($4*2)(A3)
	ADD.L	#$4001,D1
	MOVE.L	D1,Restas+Desbor+($08)(A3)
	ADD.L	#$3FFF,D1
	MOVE.L	D1,Restas+Desbor+($0C)(A3)
	ENDC
	IFD	AMG_RAMMIRROR
	BRA	AmgCmPC
	ELSE
	BRA.S	AmgCmPC
	ENDC

AmgCmSlot2:				; as FFFF, no cartridge RAM
	SUB.W	4(A7),A5
	AND.W	MaskROM(A3),D1
	MULU	#$4080,D1
	ADD.L	MapROMBase(A3),D1
	SUB.L	#$4000,D1
	IFD	AMG_RAMMIRROR
	AmgPag8	2
	ELSE
	MOVE.L	D1,PagRead+$8(A3)
	MOVE.W	D1,Restas+($8*2)(A3)
	ADD.L	#$8001,D1
	MOVE.L	D1,Restas+Desbor+($10)(A3)
	ADD.L	#$3FFF,D1
	MOVE.L	D1,Restas+Desbor+($14)(A3)
	ENDC
; A5 back to host memory, and A7 on the same page's Restas entry, keeping the return address on
; top (as v0.8's OUT00 does). The page can change here: at power on v0.8 runs the byte at $FFFF
; first ($02, LD (BC),A, a bank write to $0000 on these carts) and the PC wraps to $0000.
AmgCmPC:
	MOVEQ	#0,D1
	MOVE.W	A5,D1
	CogePag	D1,A5
	MOVE.L	(A7),A4			; the return address
	LEA	Restas-4(A3,D1.W*8),A7
	MOVE.L	A4,(A7)
	RTS

	CNOP	0,4
AmgCmOps:
	DC.W	$32
	DC.L	AmgCmLDMA,LDMA
	DC.W	$77
	DC.L	AmgCmLDHLA,LDHLA
	DC.W	$02
	DC.L	AmgCmLDBCA,LDBCA
	DC.W	$12
	DC.L	AmgCmLDDEA,LDDEA
	DC.W	-1
AmgCmSega:	DC.L	FFFC,FFFD,FFFE,FFFF
AmgCmNone:	DC.L	MapRET,MapRET,MapRET,MapRET
AmgCodies:	DC.B	0
AmgCmSlot:	DC.B	0
	CNOP	0,4
	ENDC

	IFD	AMG_TITLES
	SECTION	AmgTitles,CODE

; Window title, screen title, the credit box on the main window and the About box: Juan's
; IntuiTexts and tags re-pointed at start, before his Centrar call lines up the About box. Credits
; Juan and z00p equally. Called from the menu's start-up, all registers kept.
AmgTitles:
	MOVEM.L	D0-D2/A0-A2,-(SP)
	MOVE.L	#AmgWTitle,MainMenuWG+12
	MOVE.L	#AmgSTitle,MainMenuWG+20
	CMP.L	#$80000028,ScreenTags+80	; SA_Title, the screen's own title
	BNE.S	.notag
	MOVE.L	#AmgScrTitle,ScreenTags+84
.notag:
	LEA	AmgTxList(PC),A0
.n:	MOVE.L	(A0)+,D0
	BEQ.S	.pos
	MOVE.L	D0,A1
	MOVE.L	(A0)+,12(A1)		; it_IText
	BRA.S	.n
; the main window's credit box: four lines 11 pixels apart, each centred on x 488
.pos:	MOVE.W	#11,MainMenuText3+6
	MOVE.W	#22,MainMenuText0+6
	MOVE.W	#34,MainMenuText2+6
	MOVE.W	#45,MainMenuText5+6
	MOVE.B	MainMenuText2,MainMenuText5	; same pen as the first name (Juan's red was for "(freeware)")
	LEA	AmgBoxList(PC),A0
	JSR	Centrar
	MOVEM.L	(SP)+,D0-D2/A0-A2
	RTS

	CNOP	0,4
AmgTxList:
	DC.L	MainMenuText3,AmgBox0
	DC.L	MainMenuText5,AmgBox3
	DC.L	AboutText0,AmgAb0
	DC.L	AboutText1,AmgAb1
	DC.L	AboutText2,AmgAb2
	DC.L	AboutText3,AmgAb3
	DC.L	0
AmgBoxList:				; Centrar: x = (976 - width) / 2, so centred on 488
	DC.L	MainMenuText3,976
	DC.L	MainMenuText0,976
	DC.L	MainMenuText2,976
	DC.L	MainMenuText5,976
	DC.L	0,0

AmgWTitle:	DC.B	"AmiMasterGear 1.1",0
AmgSTitle:	DC.B	"AmiMasterGear 1.1.  ",$A9," 1997-2026 Juan Antonio G",$F3,"mez G",$E1,"lvez and z00p",0
AmgBox0:	DC.B	"AmiMasterGear 1.1",0
AmgScrTitle:	DC.B	"AmiMasterGear 1.1 Screen.",0
AmgBox3:	DC.B	"and z00p",0
AmgAb0:		DC.B	"AmiMasterGear 1.1",0
AmgAb1:		DC.B	"(November 2026)",0
AmgAb2:		DC.B	"Program and emulation:",0
AmgAb3:		DC.B	"Juan Antonio G",$F3,"mez G",$E1,"lvez and z00p",0
	CNOP	0,4
	ENDC

	IFD	AMG_DRAWERS
	SECTION	AmgDrawers,CODE

; The Insert and Load Frozen requesters start in the drawers named in the prefs ("Cartridges" and
; "Frozen" by default, next to the program). When a drawer isn't there, ASL showed the volume list;
; now it starts in the program's own drawer (PROGDIR:) instead. Battery and frozen files are saved
; beside the cartridge, so nothing is written here. Called before the requesters are made.
AmgDrawers:
	MOVEM.L	D0-D2/A0-A1/A6,-(SP)
	LEA	DirPrefs+$20,A0
	BSR.S	.one
	LEA	DirPrefs+$200,A0
	BSR.S	.one
	MOVEM.L	(SP)+,D0-D2/A0-A1/A6
	RTS
.one:	MOVE.L	A0,-(SP)
	MOVE.L	A0,D1
	MOVEQ	#-2,D2			; ACCESS_READ
	MOVE.L	_DosBase,A6
	JSR	-$54(A6)		; Lock
	MOVE.L	(SP)+,A0
	MOVE.L	D0,D1
	BEQ.S	.none
	JSR	-$5A(A6)		; UnLock
	RTS
.none:	LEA	AmgProgDir(PC),A1
.c:	MOVE.B	(A1)+,(A0)+
	BNE.S	.c
	RTS
AmgProgDir:	DC.B	"PROGDIR:",0
	CNOP	0,4
	ENDC

	IFD	AMG_PADS
	SECTION	AmgPads,CODE

; CD32 pads, as in the other emulators (emu-dev-docs chapter 05, kits/cd32pad/cd32read.s: the
; kit's reader and FAmiga's "low clock", latch wait 200, once a frame, interrupts off around it).
; "CD32 Joypad" reads with the kit's reader (KTRL CD32, PlayStation adapter); the fourth setting,
; v0.8's "Standard Joypad" (the same read as Amiga JoyStick), becomes "KTRL CD32+": the low clock,
; for the KTRL CD32+ and a Mega Multi adapter with a Mega Drive pad. A plain joystick (all seven
; buttons at once) reads as none. The forward shoulder (the Mega Drive pad's C: the adapter keeps
; Start for its own menu) is Pause and Start; Juan's other buttons are as they were.
AmgPad1Kit:	SF	AmgPadLow
	JMP	LeeCD32Joypad
AmgPad1Low:	ST	AmgPadLow
	JMP	LeeCD32Joypad
AmgPad2Kit:	SF	AmgPadLow+1
	JMP	LeeCD32Joypad2
AmgPad2Low:	ST	AmgPadLow+1
	JMP	LeeCD32Joypad2

; In place of v0.8's ReadCD32: D7 = 7 for Amiga port 2 (player 1), 6 for port 1 (player 2).
; Out: D0 in ReadCD32's layout (bit 1 play, 2 reverse, 3 forward, 4 green, 5 yellow, 6 red,
; 7 blue; 1 = pressed). Every other register kept.
AmgReadCD32:
	MOVEM.L	D1-D6/A0-A1/A6,-(SP)
	MOVEQ	#0,D1
	CMP.B	#7,D7
	BNE.S	.p1
	MOVEQ	#2,D0			; port 2
	TST.B	AmgPadLow
	BRA.S	.p
.p1:	MOVEQ	#1,D0			; port 1
	TST.B	AmgPadLow+1
.p:	BEQ.S	.k
	MOVE.L	D0,D1			; this port on the low clock
.k:	MOVE.L	D0,D5
	MOVE.L	$4.W,A6
	IFND	AMG_PADNODIS
	JSR	-120(A6)		; Disable
	ENDC
	BSR	AmgCd32read
	MOVE.L	D0,D2
	MOVE.L	D1,D3
	IFND	AMG_PADNODIS
	JSR	-126(A6)		; Enable
	ENDC
	MOVE.L	D2,D0
	CMP.B	#2,D5
	BEQ.S	.got
	MOVE.L	D3,D0
.got:
	IFD	AMG_PADDBG
	MOVE.W	D0,AmgPadRaw		; test: the raw nine bits, for port $00
	ENDC
	AND.W	#$7F,D0
	CMP.B	#$7F,D0			; all seven at once: a plain joystick
	BNE.S	.conv
	MOVEQ	#0,D0
.conv:	MOVEQ	#0,D1			; the kit's order (blue first, in bit 0) reversed into ReadCD32's
	MOVEQ	#7-1,D2
.b:	LSR.B	#1,D0
	ROXL.B	#1,D1
	DBF	D2,.b
	ADD.B	D1,D1
	MOVE.L	D1,D0
	MOVEM.L	(SP)+,D1-D6/A0-A1/A6
	RTS

; cd32read from emu-dev-docs kits/cd32pad (z00p's ReadCD32Pads with FAmiga 1.02's changes by
; Afrotechmods: the image clock, the waits in memory, nine bits, the low clock). In: D0.B ports
; (bit 1 port 2, bit 0 port 1), D1.B those on the low clock. Out: D0.L port 2, D1.L port 1, nine
; bits each (blue, red, yellow, green, forward, reverse, play, two ID bits), 1 = pressed.
AmgCd32read:
	MOVEM.L	D2-D6,-(SP)
	MOVEQ	#0,D3
	MOVEQ	#0,D6
	MOVE.W	#$FF00,D4
	BTST	#1,D0
	BEQ.S	.no2
	MOVE.B	#$80,D3
	AND.W	#$6FFF,D4
	BTST	#1,D1
	BEQ.S	.no2
	MOVE.B	#$80,D6
.no2:	BTST	#0,D0
	BEQ.S	.no1
	OR.B	#$40,D3
	AND.W	#$F6FF,D4
	BTST	#0,D1
	BEQ.S	.no1
	OR.B	#$40,D6
.no1:	MOVEQ	#0,D0
	MOVEQ	#0,D1
	TST.B	D3
	BEQ	.done
	MOVE.B	$BFE001,D2
	OR.B	D3,D2
	EOR.B	D6,D2
	MOVE.B	D2,$BFE001
	OR.B	D3,$BFE201
	MOVE.B	D2,$BFE001
	MOVE.W	D4,$DFF034
	MOVE.B	D2,D4
	MOVE.W	AmgCd32Latch,D2
	SUBQ.W	#1,D2
.latch:	TST.B	$BFE001
	DBF	D2,.latch
	MOVEQ	#9-1,D2
.bit:	LSR.W	#1,D0
	BTST	#6,$DFF016
	BEQ.S	.lo2
	BSET	#8,D0
.lo2:	LSR.W	#1,D1
	BTST	#2,$DFF016
	BEQ.S	.lo1
	BSET	#8,D1
.lo1:	EOR.B	D3,D4
	MOVE.B	D4,$BFE001
	MOVE.W	AmgCd32Clock,D5
	SUBQ.W	#1,D5
.wlo:	TST.B	$BFE001
	DBF	D5,.wlo
	EOR.B	D3,D4
	MOVE.B	D4,$BFE001
	MOVE.W	AmgCd32Clock,D5
	SUBQ.W	#1,D5
.whi:	TST.B	$BFE001
	DBF	D5,.whi
	DBF	D2,.bit
	MOVE.W	#$FF00,$DFF034
	NOT.B	D3
	AND.B	D3,$BFE201
	NOT.W	D0
	AND.L	#$1FF,D0
	NOT.W	D1
	AND.L	#$1FF,D1
	NOT.B	D3
	BTST	#7,D3
	BNE.S	.r2
	MOVEQ	#0,D0
.r2:	BTST	#6,D3
	BNE.S	.done
	MOVEQ	#0,D1
.done:	MOVEM.L	(SP)+,D2-D6
	RTS

	IFD	AMG_PADLATCH		; test: other waits
AmgCd32Latch:	DC.W	AMG_PADLATCH
AmgCd32Clock:	DC.W	AMG_PADCLOCK
	ELSE
AmgCd32Latch:	DC.W	200
AmgCd32Clock:	DC.W	3
	ENDC
AmgPadLow:	DC.B	0,0
AmgPadLab3:	DC.B	"KTRL CD32+",0
	IFD	AMG_PADDBG
; Test build only: IN from port $00 gives the last CD32 read shifted down one bit: bit 0 red, 1 yellow,
; 2 green, 3 right shoulder, 4 left shoulder, 5 play, 6 and 7 the pad's ID bits (a CD32 pad sends
; bit 6 = 0, bit 7 = 1, so $80 with nothing pressed; a pad left in joystick mode reads $00).
	CNOP	0,4
AmgIn00Dbg:
	CMP.L	Desbor+4+4(A7),A5
	BLE.S	.v
	JMP	IN0C
.v:	MOVE.W	AmgPadRaw,D1
	LSR.W	#1,D1
	RTS
AmgPadRaw:	DC.W	$1DC			; shows EE until the first read
	ENDC
	CNOP	0,4
	ENDC

	IFD	AMG_PAUSEEDGE
	SECTION	AmgPause,CODE
; The console's Pause button gives one NMI per press. v0.8 wrote the pad's Pause bit into JoyX+3
; every frame and its NMI check (Main, NoNMI2) sets the bit once it has taken an NMI, so a held
; button raised an NMI on every frame: games paused and unpaused at the frame rate. Here bit 0 is
; cleared only on the frame the button goes down; the NMI check sets it again as before.
; In: D2.B = v0.8's byte for JoyX+3 (bit 0 clear = Pause held), A3 = Regs. D0 is free.
AmgPauseEdge:
	MOVE.B	AmgPausePrev,D0
	MOVE.B	D2,AmgPausePrev
	NOT.B	D0			; bit 0 set: it was held last frame
	OR.B	D2,D0
	BTST	#0,D0
	BNE.S	.no			; released, or still held from before
	BCLR	#0,JoyX+3(A3)		; just pressed: one NMI
.no:	RTS
AmgPausePrev:	DC.B	$FF
	CNOP	0,4
	ENDC

	IFD	AMG_PADMAP
	IFND	AMG_PAUSEEDGE
	FAIL	AMG_PADMAP needs AMG_PAUSEEDGE
	ENDC
	SECTION	AmgPadMap,CODE
; CD32 pad buttons (23 Nov 2026): red = button 1, blue = button 2, green = Pause, yellow =
; Start (Game Gear), Play = Pause and Start, either shoulder = back to the menu. On "KTRL CD32+"
; (the Mega Multi's setting) the forward shoulder is the Mega Drive pad's C and that adapter never
; sends Start, so there it stays Pause and Start and only the left shoulder leaves.
; v0.8 had Play = back to the menu and the shoulders as buttons 1 and 2.
; In: D0.B = AmgReadCD32's byte (bit 1 play, 2 reverse, 3 forward, 4 green, 5 yellow, 6 red,
; 7 blue; 1 = pressed), D3.B = the directions as v0.8 builds them, A3 = Regs.
; Out: D1.B for JoyX+2 (bit 7 clear = Start), D2.B for JoyX+3 (bit 0 clear = Pause), D3.B with
; bit 4 (button 1) and bit 5 (button 2) cleared when pressed. D0 is used.
AmgPadMapP1:
	MOVE.L	D4,-(SP)
	MOVE.B	AmgPadLow,D4
	BSR.S	AmgPadMap
	MOVE.L	(SP)+,D4
	RTS
; Player 2 (the mouse port): v0.8 never passed its Pause on; here its Play and green pause too,
; once per press like player 1's (AmgPauseEdge).
AmgPadMapP2:
	MOVE.L	D4,-(SP)
	MOVE.B	AmgPadLow+1,D4
	BSR.S	AmgPadMap
	MOVE.B	AmgPausePrev2,D0
	MOVE.B	D2,AmgPausePrev2
	NOT.B	D0
	OR.B	D2,D0
	BTST	#0,D0
	BNE.S	.no
	BCLR	#0,JoyX+3(A3)
.no:	MOVE.L	(SP)+,D4
	RTS
AmgPadMap:
	MOVEQ	#-1,D1
	MOVEQ	#-1,D2
	BTST	#6,D0			; red: button 1
	BEQ.S	.r
	BCLR	#4,D3
.r:	BTST	#7,D0			; blue: button 2
	BEQ.S	.b
	BCLR	#5,D3
.b:	BTST	#4,D0			; green: Pause
	BEQ.S	.g
	BCLR	#0,D2
.g:	BTST	#5,D0			; yellow: Start
	BEQ.S	.y
	BCLR	#7,D1
.y:	BTST	#1,D0			; Play: Pause and Start
	BEQ.S	.p
	BCLR	#0,D2
	BCLR	#7,D1
.p:	BTST	#2,D0			; left shoulder: back to the menu
	BEQ.S	.l
	ST	SalirMenu(A3)
.l:	BTST	#3,D0			; forward shoulder
	BEQ.S	.f
	TST.B	D4
	BNE.S	.c
	ST	SalirMenu(A3)		; CD32 Joypad: back to the menu
	RTS
.c:	BCLR	#0,D2			; KTRL CD32+ (Mega Multi C): Pause and Start
	BCLR	#7,D1
.f:	RTS
AmgPausePrev2:	DC.B	$FF
	CNOP	0,4
	ENDC

	IFD	AMG_PORTLABELS
	SECTION	AmgPortLabels,DATA
; The Joy-Control radio buttons pick the setting for the emulated pad 1 (low nibble of DirPrefs $08,
; read from the Amiga joystick port) and pad 2 (high nibble, the mouse port). v0.8 named them after
; the console's ports, "Port 1" and "Port 2", which reads backwards next to the Amiga's numbering.
AmgPortLabP2:	DC.B	"Port 2",0
AmgPortLabP1:	DC.B	"Port 1",0
	CNOP	0,4
	ENDC

	IFD	AMG_PORTMIRROR
	SECTION	AmgPorts,CODE

; The console decodes only a few address lines on the I/O ports, so each port answers over a
; range: $40-$7F writes go to the PSG and even reads give the V counter, $80-$BF are the VDP
; (even data, odd control), and $C0-$FF reads are the pads (even $DC, odd $DD). v0.8 answered
; only $7E/$7F, $BD/$BE/$BF, $C0/$C1 and $DC/$DD. Black Sea Treasure Hunters (an MSX port) writes
; its patterns to port $98, the MSX VDP's data port; Mesen 2 takes them into VRAM. $00-$3F
; (memory and I/O control, the Game Gear's own ports) and the odd reads of $40-$7F (H counter)
; stay as v0.8 has them. At power on, A3 = Regs.
AmgPortMirror:
	MOVEM.L	D0/A0-A1,-(SP)
	LEA	Ins+($40*4),A0
	LEA	Outs+($40*4),A1
	MOVEQ	#$40,D0
.p:	CMP.B	#$80,D0
	BCC.S	.vdp
	MOVE.L	#OUT7F,(A1)		; $40-$7F: PSG
	BTST	#0,D0
	BNE.S	.n
	MOVE.L	#IN7E,(A0)
	BRA.S	.n
.vdp:	CMP.B	#$C0,D0
	BCC.S	.pads
	CMP.B	#$BE,D0
	BEQ.S	.n			; v0.8's own: switched as VRAM or CRAM is addressed
	BTST	#0,D0
	BNE.S	.ctl
	MOVE.L	#AmgInData,(A0)		; $80-$BF even: data
	MOVE.L	#AmgOutData,(A1)
	BRA.S	.n
.ctl:	MOVE.L	#INBF,(A0)		; odd: control and status
	MOVE.L	#OUTBF,(A1)
	BRA.S	.n
.pads:	MOVE.L	#INJ0,(A0)		; $C0-$FF reads: pads
	BTST	#0,D0
	BEQ.S	.n
	MOVE.L	#INJ1,(A0)
.n:	ADDQ.W	#4,A0
	ADDQ.W	#4,A1
	ADDQ.B	#1,D0
	BNE.S	.p
	MOVEM.L	(SP)+,D0/A0-A1
	RTS

; the data port's mirrors go through port $BE's entry, whatever it is now; no stack used (A7 is
; v0.8's page pointer)
AmgInData:	JMP	([Ins+($BE*4)])
AmgOutData:	JMP	([Outs+($BE*4)])
	CNOP	0,4
	ENDC

	IFD	AMG_TMSMODES
	SECTION	AmgTms,CODE

; The VDP's TMS9918 modes (register 0 bit 2, M4, clear), which v0.8 drew as mode 4: text (M1)
; and Graphic II (M3) with the TMS sprites, in the VDP's fixed palette (CRAM is not used in these
; modes). Black Sea Treasure Hunters (an MSX port) has its start-up menu in text mode and its
; title and game in Graphic II with 16x16 sprites. Graphic I, multicolour and the undocumented
; mixes stay with v0.8's mode 4 drawing, as before.
;
; Drawn into v0.8's own buffers, so every later stage is v0.8's: the background as colour
; numbers 0-15 in PantGfxFast's four planes (ImprimeGfx2 copies the groups flagged in TabBorGfx),
; the sprites into PantSprFast (PrintSprChip copies them to the Amiga sprites), and the colours
; into the copper list. Colour 0 (transparent) is Amiga colour 0, which holds the backdrop
; (register 7), so a backdrop change needs no redraw. The whole 256x192 picture is drawn: on the
; Game Gear the LCD shows its middle 160x144, as in mode 4 (checked in Mesen 2).
;
; Mode 4 costs one test per frame in each of ImprimeGfx, EscribeSpr and PonePaletaMS.

; D0.B: 1 text, 2 Graphic II, 0 anything else (mode 4, or a TMS mode left to v0.8). D1 used.
AmgTmsWhich:
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+0,D1
	BTST	#2,D1			; M4
	BNE.S	.none
	MOVE.B	VDPRegs+1,D0
	AND.B	#$18,D0			; M1 (bit 4), M2 (bit 3)
	BTST	#1,D1			; M3
	BEQ.S	.m3off
	TST.B	D0
	BNE.S	.none
	MOVEQ	#2,D0
	RTS
.m3off:	CMP.B	#$10,D0
	BNE.S	.none
	MOVEQ	#1,D0
	RTS
.none:	MOVEQ	#0,D0
	RTS

; ----------------------------------------------------------------- background
; From ImprimeGfx's start, in a TMS mode or when one was on screen.
AmgTmsGfx:
	BSR	AmgTmsWhich
	TST.B	D0
	BNE.S	.ours
	TST.B	AmgTmsOn
	BEQ.S	.v08
	BSR	AmgTmsLeave
.v08:	JMP	AmgTmsH1		; v0.8's ImprimeGfx
.ours:	MOVE.B	D0,D7
	TST.B	AmgTmsOn
	BNE.S	.on
	BSR	AmgTmsEnter
.on:
; CRAM writes made during the frame don't colour these modes: drop them before ActCopperLine
	MOVE.L	#TabRasRGB,TabRasRGBcnt
; the registers the picture depends on: a change redraws all of it
	MOVE.B	VDPRegs+0,D0
	AND.B	#$06,D0
	LSL.L	#8,D0
	MOVE.B	VDPRegs+1,D0
	AND.B	#$18,D0
	LSL.L	#8,D0
	MOVE.B	VDPRegs+2,D0
	LSL.L	#8,D0
	MOVE.B	VDPRegs+3,D0
	MOVE.B	VDPRegs+4,D1
	LSL.W	#8,D1
	CMP.B	#1,D7
	BNE.S	.nor7
	MOVE.B	VDPRegs+7,D1		; text colours
.nor7:	CMP.L	AmgTmsSnap,D0
	BNE.S	.full
	CMP.W	AmgTmsSnap+4,D1
	BEQ.S	.same
.full:	MOVE.L	D0,AmgTmsSnap
	MOVE.W	D1,AmgTmsSnap+4
	ST	AmgTmsFull
.same:	CMP.B	#1,D7
	BEQ	AmgTmsText
	BRA	AmgTmsG2

; Into a TMS mode: v0.8's second-palette plane (Plano5) and its record of it (Pant32) cleared,
; no background cell hides sprites (TabHideSpr, for the background priority setting), and the
; whole picture drawn.
AmgTmsEnter:
	ST	AmgTmsOn
	ST	AmgTmsFull
	LEA	Plano5,A0
	MOVE.W	#256-1,D0
.p5:	REPT	16
	CLR.L	(A0)+
	ENDR
	ADD.W	#256-64,A0
	DBF	D0,.p5
	LEA	Pant32,A0
	MOVE.W	#(32*32*2/4)-1,D0
.p32:	CLR.L	(A0)+
	DBF	D0,.p32
	LEA	TabHideSpr,A0
	MOVE.W	#(32*32/4)-1,D0
.hs:	MOVE.L	#-1,(A0)+
	DBF	D0,.hs
	RTS

; Back to mode 4 (or to a TMS mode v0.8 draws): every cell of v0.8's record of the name table
; made to differ from VRAM, so ImprimeGfx draws all of it again, as v0.8 does at power on.
AmgTmsLeave:
	SF	AmgTmsOn
	LEA	VRAM,A0
	MOVE.B	VDPRegs+2,D0
	AND.W	#$000E,D0
	LSL.W	#8,D0
	LSL.W	#2,D0
	ADD.W	D0,A0
	LEA	PantAnt,A1
	MOVE.W	#(32*28)-1,D0
.l:	MOVE.W	(A0)+,D1
	NOT.W	D1
	MOVE.W	D1,(A1)+
	DBF	D0,.l
	RTS

; D0.L = VRAM offset, D1.W = bytes. Out: Z clear if any 32-byte block of it was written since
; the last drawing (v0.8's TabRedef), or AmgTmsFull is set.
AmgTmsDirty:
	TST.B	AmgTmsFull
	BNE.S	.yes
	LEA	Regs+TabRedef,A0
	ADD.W	D0,D1
	SUBQ.W	#1,D1
	LSR.W	#5,D0
	LSR.W	#5,D1
	SUB.W	D0,D1
	ADD.W	D0,A0
.t:	TST.B	(A0)+
	DBNE	D1,.t
	RTS
.yes:	MOVEQ	#1,D0
	RTS

; Text mode: 40x24 characters of 6x8 pixels (the top six bits of each pattern row), the text in
; register 7's high nibble and the background in its low one, in a 240-pixel strip with 8 pixels
; of backdrop either side. Redrawn whole when its name table or patterns change.
AmgTmsText:
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+2,D0
	AND.B	#$0F,D0
	LSL.W	#8,D0
	LSL.W	#2,D0
	MOVE.L	D0,D5			; name table
	MOVE.W	#960,D1
	BSR	AmgTmsDirty
	BNE.S	.draw
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+4,D0
	AND.B	#$07,D0
	LSL.W	#8,D0
	LSL.W	#3,D0
	MOVE.W	#$800,D1
	BSR	AmgTmsDirty
	BNE.S	.draw
	RTS
.draw:	SF	AmgTmsFull
; one plane each: 0 none, 1 background only, 2 text only, 3 both
	MOVE.B	VDPRegs+7,D0
	LEA	AmgTmsOps,A0
	MOVEQ	#4-1,D1
.op:	MOVEQ	#0,D2
	BTST	#4,D0
	BEQ.S	.nf
	MOVEQ	#2,D2
.nf:	BTST	#0,D0
	BEQ.S	.nb
	ADDQ.B	#1,D2
.nb:	MOVE.B	D2,(A0)+
	LSR.B	#1,D0
	DBF	D1,.op

	LEA	VRAM,A1
	ADD.L	D5,A1			; A1 = name table
	LEA	VRAM,A3
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+4,D0
	AND.B	#$07,D0
	LSL.W	#8,D0
	LSL.W	#3,D0
	ADD.L	D0,A3			; A3 = pattern generator
	LEA	PantGfxFast,A2
	LEA	AmgTmsBits,A4
	MOVEQ	#0,D7			; pixel line 0-191
.line:	CLR.L	(A4)
	CLR.L	4(A4)
	CLR.L	8(A4)
	CLR.L	12(A4)
	CLR.L	16(A4)
	CLR.L	20(A4)
	CLR.L	24(A4)
	CLR.L	28(A4)
	MOVE.W	D7,D0
	LSR.W	#3,D0
	MULU	#40,D0
	LEA	(A1,D0.L),A5		; this row's names
	MOVEQ	#7,D6
	AND.W	D7,D6			; line in the character
	MOVEQ	#8,D3			; bit offset: after the left border
	MOVEQ	#40-1,D4
.ch:	MOVEQ	#0,D0
	MOVE.B	(A5)+,D0
	LSL.W	#3,D0
	ADD.W	D6,D0
	MOVE.B	(A3,D0.L),D0
	LSR.B	#2,D0
	BFINS	D0,(A4){D3:6}
	ADDQ.W	#6,D3
	DBF	D4,.ch
; the four planes from the bits
	LEA	AmgTmsOps,A0
	MOVE.L	A2,A6
	MOVEQ	#4-1,D4
.pl:	MOVE.B	(A0)+,D0
	BEQ.S	.zero
	SUBQ.B	#2,D0
	BEQ.S	.text
	BMI.S	.back
	MOVE.L	#$00FFFFFF,(A6)		; both: the whole strip
	MOVEQ	#-1,D1
	MOVE.L	D1,4(A6)
	MOVE.L	D1,8(A6)
	MOVE.L	D1,12(A6)
	MOVE.L	D1,16(A6)
	MOVE.L	D1,20(A6)
	MOVE.L	D1,24(A6)
	MOVE.L	#$FFFFFF00,28(A6)
	BRA	.next
.zero:	CLR.L	(A6)
	CLR.L	4(A6)
	CLR.L	8(A6)
	CLR.L	12(A6)
	CLR.L	16(A6)
	CLR.L	20(A6)
	CLR.L	24(A6)
	CLR.L	28(A6)
	BRA	.next
.text:	MOVE.L	(A4),(A6)
	MOVE.L	4(A4),4(A6)
	MOVE.L	8(A4),8(A6)
	MOVE.L	12(A4),12(A6)
	MOVE.L	16(A4),16(A6)
	MOVE.L	20(A4),20(A6)
	MOVE.L	24(A4),24(A6)
	MOVE.L	28(A4),28(A6)
	BRA.S	.next
.back:	MOVE.L	(A4),D1			; background only: the strip less the text
	NOT.L	D1
	AND.L	#$00FFFFFF,D1
	MOVE.L	D1,(A6)
	MOVE.L	4(A4),D1
	NOT.L	D1
	MOVE.L	D1,4(A6)
	MOVE.L	8(A4),D1
	NOT.L	D1
	MOVE.L	D1,8(A6)
	MOVE.L	12(A4),D1
	NOT.L	D1
	MOVE.L	D1,12(A6)
	MOVE.L	16(A4),D1
	NOT.L	D1
	MOVE.L	D1,16(A6)
	MOVE.L	20(A4),D1
	NOT.L	D1
	MOVE.L	D1,20(A6)
	MOVE.L	24(A4),D1
	NOT.L	D1
	MOVE.L	D1,24(A6)
	MOVE.L	28(A4),D1
	NOT.L	D1
	AND.L	#$FFFFFF00,D1
	MOVE.L	D1,28(A6)
.next:	ADD.W	#64,A6
	DBF	D4,.pl
	ADD.W	#256,A2
	ADDQ.W	#1,D7
	CMP.W	#192,D7
	BCS	.line
	LEA	TabBorGfx,A0
	MOVEQ	#24-1,D0
.bor:	ST	(A0)+
	DBF	D0,.bor
	RTS

; Graphic II: 32x24 cells of 8x8; the screen in thirds, each with its own 256 patterns and colour
; rows (one colour byte per pattern row: high nibble for set bits, low for clear), with the
; table masks in registers 3 and 4. A cell is drawn again when its name, pattern or colour row is
; written, or after a register change.
AmgTmsG2:
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+4,D0
	MOVE.L	D0,D1
	AND.W	#$04,D0
	LSL.W	#8,D0
	LSL.W	#3,D0
	MOVE.L	D0,AmgTmsPatB		; pattern base: $0000 or $2000
	AND.W	#$03,D1
	LSL.W	#8,D1
	LSL.W	#3,D1
	OR.W	#$07FF,D1
	MOVE.W	D1,AmgTmsPatM		; and the mask on the third
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+3,D0
	MOVE.L	D0,D1
	AND.W	#$80,D0
	LSL.W	#6,D0
	MOVE.L	D0,AmgTmsColB		; colour base: $0000 or $2000
	AND.W	#$7F,D1
	LSL.W	#6,D1
	OR.W	#$003F,D1
	MOVE.W	D1,AmgTmsColM		; and the mask on pattern and third
	MOVEQ	#0,D0
	MOVE.B	VDPRegs+2,D0
	AND.B	#$0F,D0
	LSL.W	#8,D0
	LSL.W	#2,D0
	MOVE.L	D0,D5			; name table offset

	LEA	PantGfxFast,A2
	LEA	TabBorGfx,A6
	MOVEQ	#0,D7			; row 0-23
.row:	MOVEQ	#0,D0			; are this row's names new?
	TST.B	AmgTmsFull
	BNE.S	.rnew
	MOVE.L	D5,D1
	LSR.W	#5,D1
	ADD.W	D7,D1
	LEA	Regs+TabRedef,A0
	MOVE.B	(A0,D1.W),D0
.rnew:	MOVE.B	D0,AmgTmsRowD
	MOVE.W	D7,D0
	LSR.W	#3,D0
	LSL.W	#8,D0			; the third's first pattern
	MOVE.W	D0,AmgTmsThird
	LEA	VRAM,A1
	ADD.L	D5,A1
	MOVE.W	D7,D0
	LSL.W	#5,D0
	ADD.W	D0,A1			; A1 = this row's names
	MOVEQ	#0,D6			; flags for TabBorGfx
	MOVEQ	#0,D4			; column 0-31
.cell:	MOVEQ	#0,D0
	MOVE.B	(A1)+,D0
	ADD.W	AmgTmsThird,D0
	LSL.W	#3,D0			; pattern number * 8
	MOVE.L	D0,D1
	AND.W	AmgTmsPatM,D0
	ADD.L	AmgTmsPatB,D0
	AND.W	AmgTmsColM,D1
	ADD.L	AmgTmsColB,D1
	TST.B	AmgTmsRowD
	BNE.S	.draw
	LEA	Regs+TabRedef,A0
	MOVE.W	D0,D2
	LSR.W	#5,D2
	TST.B	(A0,D2.W)
	BNE.S	.draw
	MOVE.W	D1,D2
	LSR.W	#5,D2
	TST.B	(A0,D2.W)
	BEQ	.skip
.draw:	LEA	VRAM,A3
	LEA	(A3,D1.L),A4		; colour rows
	ADD.L	D0,A3			; pattern rows
	LEA	AmgTmsRep,A0
	LEA	AmgTmsXY,A5
	MOVE.L	A2,D3
AmgTmsRowM:	MACRO
	MOVEQ	#0,D0
	MOVE.B	(A3)+,D0
	MOVE.L	(A0,D0.W*4),D2		; the pattern row in all four bytes
	MOVE.B	(A4)+,D0
	AND.L	(A5,D0.W*8),D2
	MOVE.L	4(A5,D0.W*8),D1
	EOR.L	D1,D2			; byte n = plane n of the eight pixels
	ROL.L	#8,D2
	MOVE.B	D2,\1(A2)
	ROL.L	#8,D2
	MOVE.B	D2,\1+64(A2)
	ROL.L	#8,D2
	MOVE.B	D2,\1+128(A2)
	ROL.L	#8,D2
	MOVE.B	D2,\1+192(A2)
	ENDM
	AmgTmsRowM	0
	AmgTmsRowM	256
	AmgTmsRowM	512
	AmgTmsRowM	768
	AmgTmsRowM	1024
	AmgTmsRowM	1280
	AmgTmsRowM	1536
	AmgTmsRowM	1792
	MOVE.L	D3,A2
	MOVE.W	D4,D0
	LSR.W	#2,D0
	MOVE.B	#$80,D1
	LSR.B	D0,D1
	OR.B	D1,D6
.skip:	ADDQ.W	#1,A2
	ADDQ.W	#1,D4
	CMP.W	#32,D4
	BCS	.cell
	OR.B	D6,(A6)+
	ADD.W	#(256*8)-32,A2
	ADDQ.W	#1,D7
	CMP.W	#24,D7
	BCS	.row
	SF	AmgTmsFull
	RTS

; ----------------------------------------------------------------- sprites
; From EscribeSpr's start when M4 is clear. TMS sprites: 32 in the table at register 5, ended by
; Y = $D0; drawn at Y+1 (Y from $E0 up is above the top), X less 32 with the early clock bit;
; 8x8 or 16x16 (register 1 bit 1), magnified to double (bit 0); one colour each (0 = not drawn);
; the lower number in front; only the first four on a line are shown. Into v0.8's PantSprFast
; (36 bytes a line, line = screen line + 15) and its TabBorSprA/B flags (bit 7 = x 0-31).
; The status register's fifth-sprite and collision flags are not modelled (as in v0.8's mode 4).
AmgTmsSpr:
	BSR	AmgTmsWhich
	CMP.B	#2,D0
	BEQ.S	.g2
	TST.B	D0
	BNE.S	.none			; text mode has no sprites
	JMP	AmgTmsS1		; v0.8's EscribeSpr
.none:	RTS
.g2:	MOVEQ	#8,D0
	BTST	#1,VDPRegs+1
	BEQ.S	.s8
	MOVEQ	#16,D0
.s8:	MOVE.W	D0,AmgSprW		; width and pattern rows
	MOVE.W	D0,AmgSprH
	BTST	#0,VDPRegs+1
	BEQ.S	.m1
	ADD.W	D0,AmgSprW		; magnified
	ADD.W	D0,AmgSprH
.m1:	LEA	VRAM,A1
	MOVEQ	#$7F,D0
	AND.B	VDPRegs+5,D0
	LSL.W	#7,D0
	ADD.L	D0,A1			; A1 = the sprite table
	LEA	AmgSprCount,A0
	MOVEQ	#(192/4)-1,D0
.clr:	CLR.L	(A0)+
	DBF	D0,.clr

; first pass, in priority order: which lines of each sprite are past the fourth on that line
	LEA	AmgSprCount,A0
	LEA	AmgSprHide,A2
	MOVEQ	#0,D7
.p1:	CMP.B	#$D0,(A1,D7.W*4)
	BEQ.S	.p1end			; Y = $D0 ends the table
	BSR	AmgSprTop
	MOVEQ	#0,D1
	MOVE.W	AmgSprH,D2
	SUBQ.W	#1,D2
	MOVEQ	#0,D3
.p1r:	MOVE.W	D0,D4
	ADD.W	D3,D4
	CMP.W	#192,D4
	BCC.S	.p1n
	ADDQ.B	#1,(A0,D4.W)
	CMP.B	#4,(A0,D4.W)
	BLS.S	.p1n
	BSET	D3,D1
.p1n:	ADDQ.W	#1,D3
	DBF	D2,.p1r
	MOVE.L	D1,(A2,D7.W*4)
	ADDQ.W	#1,D7
	CMP.W	#32,D7
	BCS.S	.p1
.p1end:
; second pass, last to first, each over the ones behind it
	MOVEQ	#$07,D0
	AND.B	VDPRegs+6,D0
	LSL.W	#8,D0
	LSL.W	#3,D0
	MOVE.L	D0,AmgSprPat
	LEA	AmgTmsDbl,A0
.p2:	SUBQ.W	#1,D7
	BMI	.done
	LEA	(A1,D7.W*4),A3
	MOVEQ	#$0F,D0
	AND.B	3(A3),D0
	BEQ.S	.p2			; colour 0: nothing drawn
	MOVE.B	D0,AmgSprCol
	MOVEQ	#0,D5
	MOVE.B	1(A3),D5		; X
	TST.B	3(A3)
	BPL.S	.ec
	SUB.L	#32,D5			; early clock
.ec:	MOVE.L	D5,D2			; the flags for the 32-pixel columns it covers
	ADD.W	AmgSprW,D2
	SUBQ.W	#1,D2
	BMI.S	.p2			; all of it left of the screen
	CMP.W	#255,D2
	BLE.S	.x1
	MOVE.W	#255,D2
.x1:	MOVE.W	D5,D1
	BPL.S	.x0
	MOVEQ	#0,D1
.x0:	LSR.W	#5,D1
	LSR.W	#5,D2
	MOVE.B	#$FF,D0
	LSR.B	D1,D0
	MOVE.B	#$FF,D1
	SUBQ.W	#7,D2
	NEG.W	D2
	LSL.B	D2,D1
	AND.B	D1,D0
	MOVE.B	D0,AmgSprFlg
	MOVEQ	#0,D0
	MOVE.B	2(A3),D0		; pattern
	BTST	#1,VDPRegs+1
	BEQ.S	.p8
	AND.B	#$FC,D0			; 16x16: four patterns from a multiple of 4
.p8:	LSL.W	#3,D0
	ADD.L	AmgSprPat,D0
	LEA	VRAM,A4
	ADD.L	D0,A4			; A4 = its pattern
	MOVE.L	(A2,D7.W*4),D6		; lines past the fourth
	MOVE.W	D7,AmgSprNum
	BSR	AmgSprTop
	MOVE.W	D0,D7			; top line
	MOVEQ	#0,D3			; row of the sprite on screen
.row:	MOVE.W	D7,D4
	ADD.W	D3,D4
	CMP.W	#192,D4
	BCC	.rnext
	BTST	D3,D6
	BNE	.rnext
	MOVE.W	D3,D0			; row of the pattern
	BTST	#0,VDPRegs+1
	BEQ.S	.r1
	LSR.W	#1,D0			; magnified: each row twice
.r1:	MOVEQ	#0,D1
	MOVE.B	(A4,D0.W),D1
	LSL.W	#8,D1
	BTST	#1,VDPRegs+1
	BEQ.S	.r8
	MOVE.B	16(A4,D0.W),D1		; right half of a 16x16
.r8:	BTST	#0,VDPRegs+1
	BNE.S	.r2
	SWAP	D1			; the pixels from bit 31 down
	BRA.S	.r3
.r2:	MOVEQ	#0,D0			; magnified: each pixel twice
	MOVE.B	D1,D0
	MOVE.W	(A0,D0.W*2),D2
	LSR.W	#8,D1
	MOVE.W	(A0,D1.W*2),D1
	SWAP	D1
	MOVE.W	D2,D1
.r3:	ADD.W	#15,D4
	LEA	TabBorSprA,A5
	MOVE.B	AmgSprFlg,D0
	OR.B	D0,(A5,D4.W)
	OR.B	D0,TabBorSprBuc(A5,D4.W)
	MULU	#36,D4
	LEA	PantSprFast,A5
	ADD.L	D4,A5
	MOVE.B	AmgSprCol,D0
	MOVEQ	#4-1,D2
.pl:	BFEXTU	(A5){D5:32},D4
	LSR.B	#1,D0
	BCC.S	.pclr
	OR.L	D1,D4
	BRA.S	.pput
.pclr:	NOT.L	D1
	AND.L	D1,D4
	NOT.L	D1
.pput:	BFINS	D4,(A5){D5:32}
	ADD.L	#36*256,A5
	DBF	D2,.pl
.rnext:	ADDQ.W	#1,D3
	CMP.W	AmgSprH,D3
	BCS	.row
	MOVE.W	AmgSprNum,D7
	BRA	.p2
.done:	RTS

; D7.W = sprite number, A1 = the table. Out: D0.W = its top line, -31 to 224 (Y from $E0 up is
; above the top of the screen).
AmgSprTop:
	MOVEQ	#0,D0
	MOVE.B	(A1,D7.W*4),D0
	ADDQ.W	#1,D0
	CMP.W	#$E1,D0
	BCS.S	.ok
	SUB.W	#256,D0
.ok:	RTS

; doubled pixels for magnified sprites: byte -> word
AmgTmsDbl:
AmgDblN	SET	0
	REPT	256
	DC.W	((AmgDblN&$80)*$180)|((AmgDblN&$40)*$C0)|((AmgDblN&$20)*$60)|((AmgDblN&$10)*$30)|((AmgDblN&$08)*$18)|((AmgDblN&$04)*$0C)|((AmgDblN&$02)*$06)|((AmgDblN&$01)*$03)
AmgDblN	SET	AmgDblN+1
	ENDR

; ----------------------------------------------------------------- palette
; From PonePaletaMS's start when M4 is clear. The VDP's fixed colours for the TMS modes
; (Mesen 2 shows the same on the Game Gear), in v0.8's SMS levels. Colour 0 and the border are
; the backdrop (register 7, low nibble); with the display off (register 1 bit 6) all is backdrop.
AmgTmsPal:
	IFD	AMG_VDPSTATUS
	BSR	AmgTmsStatus		; once a frame, at the end of the picture
	ENDC
	BSR	AmgTmsWhich
	TST.B	D0
	BNE.S	.ours
	JMP	AmgTmsP1		; v0.8's PonePaletaMS
.ours:	LEA	AmgTmsRGB,A0
	LEA	Color0+2,A1
	MOVEQ	#$0F,D0
	AND.B	VDPRegs+7,D0
	MOVE.W	(A0,D0.W*2),D1		; backdrop
	BTST	#6,VDPRegs+1
	BNE.S	.on
	MOVEQ	#32-1,D0
.off:	MOVE.W	D1,(A1)
	ADDQ.W	#4,A1
	DBF	D0,.off
	RTS
.on:	MOVEQ	#2-1,D2			; background 0-15, then sprites 16-31
.half:	MOVE.W	D1,(A1)
	ADDQ.W	#4,A1
	MOVEQ	#1,D0
.c:	MOVE.W	(A0,D0.W*2),(A1)
	ADDQ.W	#4,A1
	ADDQ.W	#1,D0
	CMP.W	#16,D0
	BCS.S	.c
	DBF	D2,.half
	RTS

; The SMS VDP's TMS colours as SMS colour bytes (--BBGGRR), checked in Mesen 2 against Black Sea
; (all but 8, medium red), turned into Amiga RGB as PonePaletaMS does (with AMG_PALFULL too).
AmgTmsRGBM:	MACRO
	IFD	AMG_PALFULL
	DC.W	((\1&3)*5)<<8|(((\1>>2)&3)*5)<<4|(((\1>>4)&3)*5)
	ELSE
	DC.W	((\1&3)*4)<<8|(((\1>>2)&3)*4)<<4|(((\1>>4)&3)*4)
	ENDC
	ENDM
AmgTmsRGB:
	AmgTmsRGBM	$00		; 0 transparent
	AmgTmsRGBM	$00		; 1 black
	AmgTmsRGBM	$08		; 2 medium green
	AmgTmsRGBM	$0C		; 3 light green
	AmgTmsRGBM	$10		; 4 dark blue
	AmgTmsRGBM	$30		; 5 light blue
	AmgTmsRGBM	$01		; 6 dark red
	AmgTmsRGBM	$3C		; 7 cyan
	AmgTmsRGBM	$02		; 8 medium red
	AmgTmsRGBM	$03		; 9 light red
	AmgTmsRGBM	$05		; 10 dark yellow
	AmgTmsRGBM	$0F		; 11 light yellow
	AmgTmsRGBM	$04		; 12 dark green
	AmgTmsRGBM	$33		; 13 magenta
	AmgTmsRGBM	$15		; 14 grey
	AmgTmsRGBM	$3F		; 15 white

; ----------------------------------------------------------------- tables
	CNOP	0,4
; a byte in all four bytes of a long
AmgTmsRep:
AmgTmsN	SET	0
	REPT	256
	DC.B	AmgTmsN,AmgTmsN,AmgTmsN,AmgTmsN
AmgTmsN	SET	AmgTmsN+1
	ENDR
; for each colour byte (set bits in the high nibble, clear in the low): plane n of a pattern row
; P (in every byte) = (P AND X) EOR Y, byte n of X and Y, X = fore EOR back, Y = back
AmgTmsXY:
AmgTmsN	SET	0
	REPT	256
	DC.B	(((AmgTmsN>>4)^AmgTmsN)&1)*$FF,(((AmgTmsN>>5)^(AmgTmsN>>1))&1)*$FF
	DC.B	(((AmgTmsN>>6)^(AmgTmsN>>2))&1)*$FF,(((AmgTmsN>>7)^(AmgTmsN>>3))&1)*$FF
	DC.B	(AmgTmsN&1)*$FF,((AmgTmsN>>1)&1)*$FF,((AmgTmsN>>2)&1)*$FF,((AmgTmsN>>3)&1)*$FF
AmgTmsN	SET	AmgTmsN+1
	ENDR

AmgTmsBits:	DS.L	8		; a text line's pixels, 256 bits
AmgTmsSnap:	DC.L	-1
		DC.W	-1
AmgTmsPatB:	DC.L	0
AmgTmsColB:	DC.L	0
AmgSprPat:	DC.L	0
AmgSprHide:	DS.L	32
AmgSprCount:	DS.B	192
AmgTmsPatM:	DC.W	0
AmgTmsColM:	DC.W	0
AmgTmsThird:	DC.W	0
AmgSprW:	DC.W	0
AmgSprH:	DC.W	0
AmgSprNum:	DC.W	0
AmgTmsOps:	DS.B	4
AmgTmsOn:	DC.B	0
AmgTmsFull:	DC.B	0
AmgTmsRowD:	DC.B	0
AmgSprCol:	DC.B	0
AmgSprFlg:	DC.B	0
	CNOP	0,4

	IFD	AMG_VDPSTATUS
; The status register's sprite bits in the TMS9918 modes, as the VDP sets them while it draws the
; picture: bit 6 when a line has a fifth sprite (only four are shown), bit 5 when two shown sprites
; have a pixel on the same spot (whatever their colours; pixels off the screen don't count). Both
; stay set until the status is read (AmgVdpStatRd). Worked out once a frame from the sprite table,
; for every mode with M4 clear but text (no sprites there), with the picture on.
AmgTmsStatus:
	BTST	#4,VDPRegs+1		; M1: text
	BNE	.ret
	BTST	#6,VDPRegs+1		; picture off: no sprites
	BEQ	.ret
	MOVEM.L	D3-D7/A2-A5,-(SP)
	MOVEQ	#8,D6			; rows on screen
	BTST	#1,VDPRegs+1
	BEQ.S	.s8
	MOVEQ	#16,D6
.s8:	BTST	#0,VDPRegs+1
	BEQ.S	.m1
	ADD.W	D6,D6			; magnified
.m1:	LEA	VRAM,A1
	MOVEQ	#$7F,D0
	AND.B	VDPRegs+5,D0
	LSL.W	#7,D0
	ADD.L	D0,A1			; A1 = the sprite table
	LEA	AmgStCnt,A0
	MOVEQ	#(192/4)-1,D0
.clr:	CLR.L	(A0)+
	DBF	D0,.clr
	LEA	AmgStCnt,A0
	LEA	AmgStIdx,A2
	MOVEQ	#0,D5			; the bits found
	MOVE.W	#192,D4			; the first line with a fifth sprite
; in priority order: the shown sprites of each line (four at most) and the fifth
	MOVEQ	#0,D7
.p1:	CMP.B	#$D0,(A1,D7.W*4)
	BEQ.S	.p1end			; Y = $D0 ends the table
	BSR	AmgSprTop
	MOVE.W	D6,D2
	SUBQ.W	#1,D2
.p1r:	TST.W	D0
	BMI.S	.p1n
	CMP.W	#192,D0
	BCC.S	.p1n
	MOVEQ	#0,D1
	MOVE.B	(A0,D0.W),D1
	CMP.B	#4,D1
	BCC.S	.p1f
	LEA	(A2,D0.W*4),A3
	MOVE.B	D7,(A3,D1.W)
	ADDQ.B	#1,(A0,D0.W)
	BRA.S	.p1n
.p1f:	BHI.S	.p1n			; this line's fifth is already known
	MOVE.B	#5,(A0,D0.W)
	CMP.W	D4,D0
	BCC.S	.p1n
	MOVE.W	D0,D4
.p1n:	ADDQ.W	#1,D0
	DBF	D2,.p1r
	ADDQ.W	#1,D7
	CMP.W	#32,D7
	BCS.S	.p1
.p1end:	CMP.W	#192,D4
	BCC.S	.no5
	BSET	#6,D5
.no5:
; each line with two or more shown sprites: their pixels into a line of bits, from x = -32
	MOVEQ	#$07,D0
	AND.B	VDPRegs+6,D0
	LSL.W	#8,D0
	LSL.W	#3,D0
	LEA	VRAM,A4
	ADD.L	D0,A4			; A4 = the sprite patterns
	LEA	AmgStBuf,A5
	MOVEQ	#0,D4
.line:	MOVEQ	#0,D3
	MOVE.B	(A0,D4.W),D3
	CMP.B	#2,D3
	BCS	.lnext
	CMP.B	#4,D3
	BLS.S	.n4
	MOVEQ	#4,D3
.n4:	MOVEQ	#0,D0
	MOVE.L	D0,(A5)
	MOVE.L	D0,4(A5)
	MOVE.L	D0,8(A5)
	MOVE.L	D0,12(A5)
	MOVE.L	D0,16(A5)
	MOVE.L	D0,20(A5)
	MOVE.L	D0,24(A5)
	MOVE.L	D0,28(A5)
	MOVE.L	D0,32(A5)
	MOVE.L	D0,36(A5)
	SUBQ.W	#1,D3
	LEA	(A2,D4.W*4),A3
.spr:	MOVEQ	#0,D7
	MOVE.B	(A3)+,D7
	BSR	AmgSprTop
	MOVE.W	D4,D2
	SUB.W	D0,D2			; row of the sprite on screen
	BTST	#0,VDPRegs+1
	BEQ.S	.r1
	LSR.W	#1,D2			; magnified: each row twice
.r1:	MOVEQ	#0,D0
	MOVE.B	2(A1,D7.W*4),D0		; pattern
	BTST	#1,VDPRegs+1
	BEQ.S	.r8
	AND.B	#$FC,D0
.r8:	LSL.W	#3,D0
	ADD.W	D2,D0
	MOVEQ	#0,D1
	MOVE.B	(A4,D0.W),D1
	LSL.W	#8,D1
	BTST	#1,VDPRegs+1
	BEQ.S	.w8
	MOVE.B	16(A4,D0.W),D1		; right half of a 16x16
.w8:	BTST	#0,VDPRegs+1
	BNE.S	.mag
	SWAP	D1			; the pixels from bit 31 down
	BRA.S	.x
.mag:	MOVEQ	#0,D0
	MOVE.B	D1,D0
	MOVE.W	(AmgTmsDbl,PC,D0.W*2),D2
	LSR.W	#8,D1
	MOVE.W	(AmgTmsDbl,PC,D1.W*2),D1
	SWAP	D1
	MOVE.W	D2,D1
.x:	MOVEQ	#0,D0
	MOVE.B	1(A1,D7.W*4),D0		; X
	TST.B	3(A1,D7.W*4)
	BPL.S	.ec
	SUB.W	#32,D0			; early clock
	BPL.S	.ec
	MOVE.W	D0,D2			; left of the screen: those pixels don't count
	NEG.W	D2
	LSL.L	D2,D1
	LSR.L	D2,D1
.ec:	CMP.W	#256-32,D0
	BLE.S	.in
	MOVE.W	D0,D2			; right of the screen: nor those
	SUB.W	#256-32,D2
	LSR.L	D2,D1
	LSL.L	D2,D1
.in:	ADD.W	#32,D0
	BFEXTU	(A5){D0:32},D6
	MOVE.L	D6,D2
	AND.L	D1,D2
	BNE.S	.hit
	OR.L	D1,D6
	BFINS	D6,(A5){D0:32}
	DBF	D3,.spr
.lnext:	ADDQ.W	#1,D4
	CMP.W	#192,D4
	BCS	.line
	BRA.S	.end
.hit:	BSET	#5,D5
.end:	OR.B	D5,AmgVdpSpr
	MOVEM.L	(SP)+,D3-D7/A2-A5
.ret:	RTS

AmgStBuf:	DS.L	10		; a line of sprite pixels, x = -32 to 287
AmgStIdx:	DS.B	192*4		; the shown sprites of each line
AmgStCnt:	DS.B	192		; sprites on each line (5 = a fifth was there)
	CNOP	0,4
	ENDC
	ENDC

	IFD	AMG_VDPSTATUS
	SECTION	AmgStatus,CODE

; Reading the VDP status (v0.8's INBF comes here with D1 = its Estado byte and returns from here;
; no stack used beyond the caller's return address, as v0.8's I/O handlers). The console's bits
; are 7 frame interrupt, 6 sprite overflow, 5 sprite collision. v0.8 keeps its line interrupt
; pending in Estado bit 6 and toggles bit 5 at every read: the line interrupt never shows in the
; status, so bit 6 is cleared here in every mode. In the TMS9918 modes bits 6 and 5 are the real
; ones (AmgTmsStatus, with AMG_TMSMODES); in mode 4 bit 5 stays v0.8's toggle (no mode 4 sprite
; collision is worked out).
AmgVdpStatRd:
	BTST	#2,VDPRegs		; M4
	BEQ.S	.tms
	AND.B	#$BF,D1
	BRA.S	.done
.tms:	AND.B	#$80,D1
	OR.B	AmgVdpSpr,D1
	CLR.B	AmgVdpSpr		; read: cleared, as the frame interrupt is
.done:	AND.B	#$3F,Estado(A3)
	BCHG	#5,Estado(A3)
	RTS

AmgVdpSpr:	DC.B	0		; bits 6 and 5 since the last read (TMS9918 modes)
	CNOP	0,4
	ENDC

	IFD	AMG_PSG
	SECTION	AmgPsg,CODE

; The SN76489 sound chip (port $7F, and $40-$7F with AMG_PORTMIRROR). A byte with bit 7 set
; latches a register (bits 6-4: tone 0, volume 0, tone 1, volume 1, tone 2, volume 2, noise,
; volume 3) and writes its low 4 bits; a byte with bit 7 clear writes the latched register:
; a tone's high 6 bits, or a volume or the noise control again. v0.8 waited for a second byte
; after every tone latch, so a latch on its own (PSGlib sends one when only the low bits change)
; took the next command as its data and the notes and the noise went wrong.
; PSG_Tab (16 bytes, saved in frozen states): tone 0-2 as words at 0, 4, 8; volumes 0-3 in the
; bytes at 2, 6, 10, 14 (v0.8's start-up $FF there = silent); noise control in the byte at 12.
; In: D1.B the byte. D0 and D2 kept (v0.8's handler only changed D1 and D2's low byte). No stack:
; in the I/O handlers A7 is v0.8's Z80 page pointer, so the registers go to a save area.
AmgPsgOut:
	MOVEM.L	D0/D2,AmgPsgSave
	MOVEQ	#0,D2
	TST.B	D1
	BPL.S	.data
	MOVE.B	D1,D2
	LSR.B	#4,D2
	AND.B	#7,D2
	MOVE.B	D2,AmgPsgLatch
	MOVEQ	#$0F,D0
	AND.B	D1,D0
	BTST	#0,D2
	BNE.S	.byte			; volume
	CMP.B	#6,D2
	BEQ.S	.byte			; noise
	AND.W	#$3F0,(PSG_Tab.L,D2.W*2) ; tone: the low 4 bits
	OR.W	D0,(PSG_Tab.L,D2.W*2)
	BRA.S	.done
.data:	MOVE.B	AmgPsgLatch,D2
	MOVEQ	#$0F,D0
	AND.B	D1,D0
	BTST	#0,D2
	BNE.S	.byte
	CMP.B	#6,D2
	BEQ.S	.byte
	MOVEQ	#$3F,D0			; tone: the high 6 bits
	AND.B	D1,D0
	LSL.W	#4,D0
	AND.W	#$00F,(PSG_Tab.L,D2.W*2)
	OR.W	D0,(PSG_Tab.L,D2.W*2)
	BRA.S	.done
.byte:	MOVE.B	D0,(PSG_Tab.L,D2.W*2)
.done:	MOVEM.L	AmgPsgSave,D0/D2
	RTS

; Once a frame, in place of v0.8's TocaPSG (same registers changed: D0, D1, A6 = $DFF000).
; Tones: Paula plays v0.8's two-byte square (ONDA) at period 16N, which is the chip's
; clock/(32N) Hz when Paula's clock and the console's are the same (a PAL Amiga and a PAL
; console, both 3546895). An NTSC console (3579545, the 60 Hz screen and the Game Gear) on a PAL
; Amiga is 0.9% faster, so the periods are scaled by AmgPsgK (and the other way on an NTSC Amiga).
; N below 8 is above 14 kHz and Paula can't go that fast: silent.
; Volume: the chip's steps are 2 dB each (15 = off), v0.8 made them a straight line.
; Noise: the shift register steps at clock/(32N), N = $10, $20, $40 or tone 2's N (control
; bits 1-0 = 3); Paula takes one sample a step, period 32N (scaled as the tones). White noise (bit 2 set) plays the
; chip's own 16-bit sequence (taps 0 and 3), periodic noise a one-in-sixteen pulse. v0.8 played a
; recorded noise at tone 2's pitch whatever the control said, and periodic noise as white.
AmgPsgPlay:
	MOVEM.L	D2-D3/A0-A2,AmgPsgSave2
	LEA	$DFF000,A6
	TST.B	AmgPsgReady
	BNE.S	.ready
	BSR	AmgPsgMakeWhite		; once (the frame code's stack holds a return address)
.ready:	MOVEQ	#0,D0
	TST.B	DirPrefs+$0F		; screen: 0 PAL, else NTSC
	BNE.S	.ntsc
	TST.B	Regs+Consola		; the Game Gear is always NTSC
	BEQ.S	.pal
.ntsc:	MOVEQ	#1,D0
.pal:	OR.B	AmgPsgAmiga,D0
	MOVE.W	(AmgPsgK.L,D0.W*2),AmgPsgKNow
	LEA	PSG_Tab,A0
	LEA	AmgPsgVol(PC),A1
	LEA	$A0(A6),A2
	MOVEQ	#3-1,D3
.tone:	MOVE.W	(A0)+,D0
	AND.W	#$3FF,D0
	MOVEQ	#$0F,D1
	AND.B	(A0),D1
	ADDQ.L	#2,A0
	MOVE.B	(A1,D1.W),D1
	CMP.W	#8,D0
	BCC.S	.audible
	MOVEQ	#0,D1
	MOVEQ	#8,D0
.audible:
	MULU.W	AmgPsgKNow,D0		; 16N, scaled
	LSR.L	#8,D0
	MOVE.W	D0,6(A2)		; period
	MOVE.W	D1,8(A2)		; volume
	LEA	$10(A2),A2
	DBF	D3,.tone
; noise: A0 = PSG_Tab+12
	MOVEQ	#$0F,D1
	AND.B	2(A0),D1
	MOVE.B	(A1,D1.W),D1
	MOVE.W	D1,$D8(A6)
	MOVEQ	#7,D2
	AND.B	(A0),D2			; noise control
	MOVEQ	#3,D1
	AND.W	D2,D1
	CMP.W	#3,D1
	BNE.S	.fixed
	MOVE.W	PSG_Tab+8,D1		; tone 2's N
	AND.W	#$3FF,D1
	BRA.S	.rate
.fixed:	MOVEQ	#$10,D0
	LSL.W	D1,D0
	MOVE.W	D0,D1
.rate:	MULU.W	AmgPsgKNow,D1		; 32N, scaled
	LSR.L	#7,D1
	CMP.L	#124,D1
	BCC.S	.per
	MOVEQ	#124,D1			; Paula's fastest
.per:	MOVE.W	D1,$D6(A6)
; white or periodic: Paula takes a new sample only at the end of a loop (the white one is long),
; so the channel is stopped and started again with it. Paula notices the stop at the end of the
; sample it is playing: wait the old period (227 colour clocks a line) plus two lines, at most 40.
; The chip restarts its shift register when the noise control is written, so starting the
; sample from its beginning is right too.
	AND.B	#4,D2
	CMP.B	AmgPsgMode,D2
	BEQ.S	.keep
	MOVE.B	D2,AmgPsgMode
	MOVE.W	#$0008,$96(A6)		; AUD3 off
	TST.B	D2
	BEQ.S	.pulse
	MOVE.L	#AmgPsgWhite,$D0(A6)
	MOVE.W	#AMG_PSGWHITE/2,$D4(A6)
	BRA.S	.wait
.pulse:	MOVE.L	#AmgPsgPulse,$D0(A6)
	MOVE.W	#16/2,$D4(A6)
.wait:	MOVEQ	#0,D0
	MOVE.W	AmgPsgPer,D0
	DIVU.W	#227,D0
	ADDQ.W	#2,D0
	CMP.W	#40,D0
	BLS.S	.lines
	MOVEQ	#40,D0
.lines:	MOVE.B	$06(A6),D2		; VHPOSR: the line
.line:	CMP.B	$06(A6),D2
	BEQ.S	.line
	DBF	D0,.lines
	MOVE.W	#$8008,$96(A6)		; AUD3 on: the new sample from its start
.keep:	MOVE.W	D1,AmgPsgPer
.out:	MOVEM.L	AmgPsgSave2,D2-D3/A0-A2
	RTS

; The chip's white noise: 16-bit shift register from $8000, bit 0 out, bit 0 xor bit 3 in at
; bit 15 (the Sega chip's taps). Made once, into chip RAM.
AmgPsgMakeWhite:
	MOVE.L	4.W,A0
	CMP.L	#712000,568(A0)		; ex_EClockFrequency: 709379 PAL, 715909 NTSC
	BCS.S	.palam
	MOVE.B	#2,AmgPsgAmiga
.palam:	LEA	AmgPsgWhite,A0
	MOVE.W	#$8000,D0
	MOVE.W	#AMG_PSGWHITE-1,D3
.g:	MOVE.W	D0,D1
	LSR.W	#3,D1
	EOR.W	D0,D1
	AND.W	#1,D1			; feedback
	BTST	#0,D0
	SNE	D2
	EOR.B	#$80,D2			; bit 0: 1 = +127, 0 = -128
	MOVE.B	D2,(A0)+
	LSR.W	#1,D0
	ROR.W	#1,D1
	OR.W	D1,D0
	DBF	D3,.g
	ST	AmgPsgReady
	RTS

; attenuation 0-15 (2 dB a step, 15 off) to Paula volume, full scale 64
AmgPsgSave:	DS.L	2
AmgPsgPer:	DC.W	5000		; the noise period playing (v0.8 started it at 5000)
AmgPsgSave2:	DS.L	5
; period scale * 256 by Amiga (0 PAL, 2 NTSC) + console (0 PAL, 1 NTSC): 4096 = same clock,
; 4096*3546895/3579545 and 4096*3579545/3546895
AmgPsgK:	DC.W	4096,4059,4134,4096
AmgPsgKNow:	DC.W	4096
AmgPsgVol:	DC.B	64,51,40,32,25,20,16,13,10,8,6,5,4,3,3,0
AmgPsgLatch:	DC.B	0
AmgPsgAmiga:	DC.B	0		; 2: an NTSC Amiga (Paula at 3579545)
AmgPsgReady:	DC.B	0
AmgPsgMode:	DC.B	$FF		; noise sample on Paula: 4 white, 0 periodic, $FF none yet
	CNOP	0,4

AMG_PSGWHITE	EQU	16384
	SECTION	AmgPsgChip,DATA_C
; one step high in sixteen, centred on zero: the uncentred 127/-128 pulse is mostly DC, which
; thumps every time the volume or the sample changes (the chip's output is AC-coupled). Centred,
; its swing is about half a tone's (-5 dB).
AmgPsgPulse:	DC.B	127,-9,-9,-9,-9,-9,-9,-9
		DC.B	-9,-9,-9,-9,-9,-9,-9,-9
	SECTION	AmgPsgWhiteBuf,BSS_C
AmgPsgWhite:	DS.B	AMG_PSGWHITE
	ENDC
