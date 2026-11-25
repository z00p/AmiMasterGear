; AutoTest.asm: test builds only (-DAUTOTEST=1), never in a release.
;
;	AmiMasterGear <ROM path>
;
; Loads the ROM through the menu's own loader, powers on and runs flat out. On the frames in
; AutoStops it sends "@F<frame>" on the serial port and holds the picture until the PC answers
; with a byte, then carries on; after the last one it leaves as Esc does. Loader errors go to
; the serial port as "@ERR <text>". tools/score.py is the PC side.

	SECTION	AutoTestCode,CODE

AUTO_SERPER=30				; 115200 baud

; A0/D0 = the command line
AutoArgs:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	IFD	AUTOCYCLE
; Several cartridges on the command line: the first now, the rest by AutoNextRom from the menu
	LEA	AutoCmd,A1
	MOVE.W	#AUTOCMDMAX-2,D1
.cc:	SUBQ.L	#1,D0
	BMI.S	.ce
	MOVE.B	(A0)+,(A1)+
	DBF	D1,.cc
.ce:	CLR.B	(A1)
	MOVE.L	#AutoCmd,AutoCmdPtr
	BSR	AutoNextRom
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
	ENDC
	LEA	FileNom,A1
	MOVE.W	#$100-2,D1
.copy:
	SUBQ.L	#1,D0
	BMI.S	.end
	MOVE.B	(A0)+,D2
	CMP.B	#" ",D2
	BLS.S	.end
	MOVE.B	D2,(A1)+
	DBF	D1,.copy
.end:
	CLR.B	(A1)
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS

; A0 = text. All registers kept.
AutoPuts:
	MOVEM.L	D0-D1/A0/A6,-(SP)
	LEA	$DFF000,A6
	MOVE.W	#AUTO_SERPER,$032(A6)
.next:
	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	BEQ.S	.done
.wait:
	MOVE.W	$018(A6),D1		; SERDATR
	BTST	#13,D1			; transmit buffer empty?
	BEQ.S	.wait
	OR.W	#$0100,D0		; stop bit
	MOVE.W	D0,$030(A6)
	BRA.S	.next
.done:
	MOVEM.L	(SP)+,D0-D1/A0/A6
	RTS

; A0 = the menu's error text
AutoError:
	MOVE.L	A0,-(SP)
	ST	AutoFailed
	LEA	AutoErrText,A0
	BSR	AutoPuts
	MOVE.L	(SP)+,A0
	BSR	AutoPuts
	LEA	AutoNL,A0
	BSR	AutoPuts
	RTS

; After each emulated frame. The caller has saved the registers.
AutoFrame:
	ADDQ.L	#1,AutoFrames
	MOVE.L	AutoFrames,D0
	IFD	AUTOPAD
; Pad 1 buttons held over set frames (as tools/mesen_trace.lua's input=), through the keyboard
; state that VDPEmul ANDs into the pad each vblank, and straight into the pad for this frame.
	LEA	AutoPadPlan,A0
	MOVEQ	#-1,D1
.pad:	MOVE.L	(A0)+,D2
	BEQ.S	.padset
	MOVE.L	(A0)+,D3
	MOVE.L	(A0)+,D4
	CMP.L	D2,D0
	BCS.S	.pad
	CMP.L	D3,D0
	BHI.S	.pad
	NOT.B	D4
	AND.B	D4,D1
	BRA.S	.pad
.padset:
	LEA	Regs,A0
	MOVE.B	D1,KeyX(A0)
	AND.B	D1,JoyX(A0)
	IFD	AUTOOASIS
	MOVE.L	D0,D2			; Game Gear Start (Enter, KeyX+2 bit 7) at 4500-4505 and 4600-4605
	SUB.L	#4500,D2
	CMP.L	#6,D2
	BCS.S	.start
	SUB.L	#100,D2
	CMP.L	#6,D2
	BCC.S	.nostart
.start:	BCLR	#7,KeyX+2(A0)
	BRA.S	.startok
.nostart:
	BSET	#7,KeyX+2(A0)		; released again: a press is an edge, as Enter gives
.startok:
	ENDC
	ENDC
	MOVE.L	AutoNext,A0
	CMP.L	(A0),D0
	BNE.S	.ret
	ADDQ.L	#4,A0
	MOVE.L	A0,AutoNext
	IFD	AUTOSPEED
	BSR	AutoSpdLine		; "@R SPD": frames and the Amiga's frame count, no pause
	TST.L	(A0)
	BEQ.S	.spdlast		; the last stop grabs and leaves
	RTS
.spdlast:
	ENDC

	LEA	AutoDigits+4,A1
	MOVEQ	#4-1,D1
.digit:
	DIVUL.L	#10,D2:D0
	ADD.B	#"0",D2
	MOVE.B	D2,-(A1)
	DBF	D1,.digit

	LEA	$DFF000,A6
	MOVE.W	#$0800,$09C(A6)		; forget bytes already received
	LEA	AutoMark,A0
	BSR	AutoPuts
	IFD	AUTODUMP
	BSR	AutoRegDump
	ENDC
	IFD	AUTODEL
	BSR	AutoDelLine
	ENDC
	IFD	AUTOSCR
	BSR	AutoScrLine
	ENDC
	IFD	AUTOBLANK
	BSR	AutoBlankLine
	ENDC
	IFD	AUTOPREFS
	BSR	AutoPrefsLine
	ENDC
.hold:
	MOVE.W	$018(A6),D0
	BTST	#14,D0			; receive buffer full = the PC has its picture
	BEQ.S	.hold
	MOVE.W	#$0800,$09C(A6)

	MOVE.L	AutoNext,A0
	TST.L	(A0)
	BNE.S	.ret
	ST	Regs+SalirMenu		; as Esc
.ret:
	RTS

	IFD	AUTODUMP
; "@R <A5> <PagRead 0-3> <VDP registers 0-10> <IFF> <Estado> <irqs> <status reads> <with bit 7>
; <palette RAM 64> <VRAM sums 16> <RAM sums 8> <D1> <IX> <IY> <D0> <D4> <A6> <A3> <A7> <Restas words 0-3>": where the Z80 is and the VDP's state.
; A5 = Z80 PC + PagRead[page]; the PC side works out the PC.
AutoRegDump:
	MOVEM.L	D0-D3/A0-A3,-(SP)
	LEA	Regs,A3
	LEA	AutoLine+3,A1
	MOVE.L	Bufer+13*4(A3),D0	; A5 as MiraInter193 saved it
	BSR	.long
	LEA	PagRead(A3),A2
	MOVEQ	#4-1,D3
.pages:	MOVE.L	(A2)+,D0
	IFD	AMG_RAMMIRROR
	ADDQ.W	#4,A2			; 8K pages: the first of each 16K slot
	ENDC
	BSR	.long
	DBF	D3,.pages
	LEA	VDPRegs,A2
	MOVEQ	#11-1,D3
.vdp:	MOVE.B	(A2)+,D0
	BSR	.byte
	DBF	D3,.vdp
	MOVE.B	$489(A3),D0
	BSR	.byte
	MOVE.B	Estado(A3),D0
	BSR	.byte
	MOVE.L	AutoIrqs,D0		; since the last grab
	BSR	.long
	MOVE.L	AutoStatRd,D0
	BSR	.long
	MOVE.L	AutoStat7,D0
	BSR	.long
	LEA	VPAL,A2			; the palette RAM, 64 bytes (SMS uses the first 32)
	MOVEQ	#64-1,D3
.pal:	MOVE.B	(A2)+,D0
	BSR	.byte
	DBF	D3,.pal
	LEA	VRAM,A2			; VRAM as 16 sums, one per 1K (bytes added, mod $10000)
	MOVEQ	#16-1,D3
.vsum:	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.W	#1024-1,D2
.vadd:	MOVE.B	(A2)+,D1
	ADD.W	D1,D0
	DBF	D2,.vadd
	BSR	.word
	MOVE.B	#" ",(A1)+
	DBF	D3,.vsum
	LEA	IRAM,A2			; work RAM $C000-$DFFF as 8 sums, one per 1K
	MOVEQ	#8-1,D3
.rsum:	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.W	#1024-1,D2
.radd:	MOVE.B	(A2)+,D1
	ADD.W	D1,D0
	DBF	D2,.radd
	BSR	.word
	MOVE.B	#" ",(A1)+
	DBF	D3,.rsum
	MOVE.L	Bufer+1*4(A3),D0	; D1, IX (A0) and IY (A1) as MiraInter193 saved them
	BSR	.long
	MOVE.L	Bufer+8*4(A3),D0
	BSR	.long
	MOVE.L	Bufer+9*4(A3),D0
	BSR	.long
	MOVE.L	Bufer+0*4(A3),D0	; D0 (SP), D4 (HL), A6 (SP in Amiga memory), A3
	BSR	.long
	MOVE.L	Bufer+4*4(A3),D0
	BSR	.long
	MOVE.L	Bufer+14*4(A3),D0
	BSR	.long
	MOVE.L	Bufer+11*4(A3),D0
	BSR	.long
	MOVE.L	Bufer+15*4(A3),D0	; A7 (the page pointer) and the four Restas words
	BSR	.long
	MOVE.W	Restas+0(A3),D0
	BSR	.word
	MOVE.B	#" ",(A1)+
	MOVE.W	Restas+8(A3),D0
	BSR	.word
	MOVE.B	#" ",(A1)+
	MOVE.W	Restas+16(A3),D0
	BSR	.word
	MOVE.B	#" ",(A1)+
	MOVE.W	Restas+24(A3),D0
	BSR	.word
	MOVE.B	#" ",(A1)+
	CLR.L	AutoIrqs
	CLR.L	AutoStatRd
	CLR.L	AutoStat7
	MOVE.B	#10,-1(A1)
	CLR.B	(A1)
	LEA	AutoLine,A0
	BSR	AutoPuts
	IFD	AUTORAM
; "@M <RAM $C000-$FFFF in hex>" on one line, sent 128 bytes at a time. v0.8 keeps $E000-$FFFF
; apart from $C000-$DFFF, so all 16K.
	LEA	AutoRamMark,A0
	BSR	AutoPuts
	IFD	AUTOVRAM
	LEA	VRAM,A2			; AUTOVRAM: the 16K of VRAM instead
	ELSE
	LEA	IRAM,A2
	ENDC
	MOVEQ	#128-1,D3
.mchunk:
	LEA	AutoLine+3,A1
	MOVEQ	#128-1,D1
.mbyte:	MOVE.B	(A2)+,D0
	MOVE.W	D1,-(SP)
	BSR.S	.hex2
	MOVE.W	(SP)+,D1
	DBF	D1,.mbyte
	CLR.B	(A1)
	LEA	AutoLine+3,A0
	BSR	AutoPuts
	DBF	D3,.mchunk
	LEA	AutoNL,A0
	BSR	AutoPuts
	ENDC
	MOVEM.L	(SP)+,D0-D3/A0-A3
	RTS
.long:	SWAP	D0
	BSR.S	.word
	SWAP	D0
	BSR.S	.word
	MOVE.B	#" ",(A1)+
	RTS
.word:	MOVE.W	D0,-(SP)
	LSR.W	#8,D0
	BSR.S	.hex2
	MOVE.W	(SP)+,D0
	BRA.S	.hex2
.byte:	BSR.S	.hex2
	MOVE.B	#" ",(A1)+
	RTS
.hex2:	MOVE.W	D0,D2
	LSR.B	#4,D2
	BSR.S	.nib
	MOVE.W	D0,D2
.nib:	AND.W	#$F,D2
	MOVE.B	.digits(PC,D2.W),(A1)+
	RTS
.digits:	DC.B	"0123456789ABCDEF"
	ENDC

	IFD	AUTOHELP
; Test builds: "@F<D0>" on the serial port, then wait for the PC's byte (it has grabbed the
; screen). For the menu and help page grabs (AmiMasterGear_Menu.asm). All registers kept.
AutoGrab:
	MOVEM.L	D0-D2/A0-A1/A6,-(SP)
	LEA	AutoDigits+4,A1
	MOVEQ	#4-1,D1
.digit:	DIVUL.L	#10,D2:D0
	ADD.B	#"0",D2
	MOVE.B	D2,-(A1)
	DBF	D1,.digit
	LEA	$DFF000,A6
	MOVE.W	#$0800,$09C(A6)
	LEA	AutoMark,A0
	BSR	AutoPuts
.hold:	MOVE.W	$018(A6),D0
	BTST	#14,D0
	BEQ.S	.hold
	MOVE.W	#$0800,$09C(A6)
	MOVEM.L	(SP)+,D0-D2/A0-A1/A6
	RTS
	ENDC

	IFD	AUTODEL
; Del (the keyboard's Pause) pressed on the 300th VDPEmul and released on the 330th, as MiraTeclado
; does it (key down clears KeyX+3 bit 0, key up sets it), before VDPEmul ANDs KeyX into the pad.
; Called from VDPEmul with the registers saved. The stops print "@R NMI <n> VBL <n>" (hex):
; the Pause NMIs taken so far and VDPEmul's count.
AutoDelKey:
	ADDQ.L	#1,AutoVbls
	CMP.L	#300,AutoVbls
	BNE.S	.up
	BCLR	#0,Regs+KeyX+3
.up:	CMP.L	#330,AutoVbls
	BNE.S	.ret
	BSET	#0,Regs+KeyX+3
.ret:	RTS
AutoDelLine:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	LEA	AutoDelText+7,A1
	MOVE.L	AutoNmis,D0
	BSR.S	.hex
	LEA	AutoDelText+20,A1
	MOVE.L	AutoVbls,D0
	BSR.S	.hex
	LEA	AutoDelText,A0
	BSR	AutoPuts
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
.hex:	MOVEQ	#8-1,D1
.h:	ROL.L	#4,D0
	MOVE.W	D0,D2
	AND.W	#$F,D2
	MOVE.B	.dig(PC,D2.W),(A1)+
	DBF	D1,.h
	RTS
.dig:	DC.B	"0123456789ABCDEF"
AutoDelText:	DC.B	"@R NMI 00000000 VBL 00000000",10,0
	CNOP	0,4
AutoNmis:	DC.L	0
AutoVbls:	DC.L	0
	ENDC

	IFD	AUTOSPEED
; Speed runs: "@R SPD <emulated frames> <CIA-A TOD>" at each stop, all in hex. CIA-A's TOD
; counts the Amiga's vertical syncs, real time in a real-time WinUAE config: the emulated
; frames between two stops over the TOD ticks between them is the share of full speed (60 or
; 50 frames a second, as the Amiga screen). No pause between stops; the last one grabs.
AutoSpdLine:
	MOVEM.L	D0-D2/A0-A1,-(SP)
	LEA	AutoSpdText+7,A1
	BSR.S	.hex
	MOVEQ	#0,D0
	MOVE.B	$BFEA01,D0		; TOD high: latches the count until the low byte is read
	LSL.L	#8,D0
	MOVE.B	$BFE901,D0
	LSL.L	#8,D0
	MOVE.B	$BFE801,D0
	LEA	AutoSpdText+16,A1
	BSR.S	.hex
	LEA	AutoSpdText,A0
	BSR	AutoPuts
	MOVEM.L	(SP)+,D0-D2/A0-A1
	RTS
.hex:	MOVEQ	#8-1,D1
.h:	ROL.L	#4,D0
	MOVE.W	D0,D2
	AND.W	#$F,D2
	MOVE.B	.dig(PC,D2.W),(A1)+
	DBF	D1,.h
	RTS
.dig:	DC.B	"0123456789ABCDEF"
AutoSpdText:	DC.B	"@R SPD 00000000 00000000",10,0
	CNOP	0,4
	ENDC

	IFD	AUTOCYCLE
; The next cartridge name from the command line into FileNom, and the stops from the start, so
; that the menu loads it as Insert does and powers on again in the same session (black-screen
; hunt). Z clear: one found; Z set: none left.
AUTOCMDMAX=1024
AutoNextRom:
	MOVEM.L	D1-D2/A0-A1,-(SP)
	MOVE.L	AutoCmdPtr,A0
.sk:	MOVE.B	(A0)+,D2
	BEQ.S	.none
	CMP.B	#" ",D2
	BLS.S	.sk
	SUBQ.L	#1,A0
	LEA	FileNom,A1
	MOVE.W	#$100-2,D1
.cp:	MOVE.B	(A0)+,D2
	CMP.B	#" ",D2
	BLS.S	.end
	MOVE.B	D2,(A1)+
	DBF	D1,.cp
.end:	CLR.B	(A1)
	SUBQ.L	#1,A0
	MOVE.L	A0,AutoCmdPtr
	CLR.L	AutoFrames
	MOVE.L	#AutoStops,AutoNext
	MOVEQ	#1,D0
	BRA.S	.ret
.none:	SUBQ.L	#1,A0
	MOVE.L	A0,AutoCmdPtr
	MOVEQ	#0,D0
.ret:	MOVEM.L	(SP)+,D1-D2/A0-A1
	TST.L	D0
	RTS
AutoCmdPtr:	DC.L	0
AutoCmd:	DS.B	AUTOCMDMAX
	CNOP	0,4
	ENDC

	IFD	AUTOSCR
; Display state at each stop (black-screen hunt): "@R SCR" then, in hex, DMACONR, INTENAR,
; VPOSR+VHPOSR, copper interrupts taken (VDPEmul), vertical blanks (IntFpsConta), and sums of
; the copper list's header, the colours, both line lists, the line options and the bitplanes,
; then VDP registers 0-3 and 4-7.
AutoScrLine:
	MOVEM.L	D0-D3/A0-A1,-(SP)
	LEA	AutoScrText+6,A1
	MOVEQ	#0,D0
	MOVE.W	$DFF002,D0		; DMACONR
	BSR	.hex
	MOVE.W	$DFF01C,D0		; INTENAR
	BSR	.hex
	MOVE.L	$DFF004,D0		; VPOSR, VHPOSR
	BSR	.hex
	MOVE.L	AutoCopers,D0
	BSR	.hex
	MOVEQ	#0,D0
	MOVE.W	IntFpsConta,D0
	BSR	.hex
	LEA	MasterCopper,A0
	MOVE.L	#(CopperLine0-MasterCopper)/4,D1
	BSR	.sum
	LEA	Color0,A0
	MOVEQ	#32,D1
	BSR	.sum
	LEA	CopperLine0,A0
	MOVE.L	#(CopperLine1-CopperLine0)/4,D1
	BSR	.sum
	LEA	CopperLine1,A0
	MOVE.L	#(CopperLine1-CopperLine0)/4,D1
	BSR	.sum
	LEA	CopperOpts0,A0
	MOVE.L	#(CopperOpts1-CopperOpts0)*2/4,D1
	BSR	.sum
	LEA	PantGfx,A0
	MOVE.L	#(Plano5-PantGfx)*2/4,D1
	BSR	.sum
	MOVE.L	VDPRegs,D0
	BSR	.hex
	MOVE.L	VDPRegs+4,D0
	BSR	.hex
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AutoScrText,A0
	BSR	AutoPuts
	MOVEM.L	(SP)+,D0-D3/A0-A1
	RTS
; A0 = start, D1 = longs: an order-sensitive sum into D0, printed
.sum:	MOVEQ	#0,D0
.s:	ROL.L	#1,D0
	ADD.L	(A0)+,D0
	SUBQ.L	#1,D1
	BNE.S	.s
.hex:	MOVE.B	#" ",(A1)+
	MOVEQ	#8-1,D2
.h:	ROL.L	#4,D0
	MOVE.W	D0,D3
	AND.W	#$F,D3
	MOVE.B	.dig(PC,D3.W),(A1)+
	DBF	D2,.h
	RTS
.dig:	DC.B	"0123456789ABCDEF"
AutoScrText:	DC.B	"@R SCR"
	DS.B	14*9+2
	CNOP	0,4
AutoCopers:	DC.L	0
	ENDC

	IFD	AUTOBLANK
; Frames whose picture starts with the display off (VDP register 1 bit 6 clear when
; MiraInterFin sets the palette; v0.8 then shows the whole frame black): "@R BLK" then, in
; hex, all such frames, those from frame 600 on, and the last one's frame number.
AutoBlankCount:
	BTST	#6,VDPRegs+1
	BNE.S	.on
	ADDQ.L	#1,AutoBlanks
	CMP.L	#600,AutoFrames
	BCS.S	.early
	ADDQ.L	#1,AutoBlanks+4
.early:	MOVE.L	AutoFrames,AutoBlanks+8
.on:	RTS
AutoBlankLine:
	MOVEM.L	D0-D3/A0-A2,-(SP)
	LEA	AutoBlankText+6,A1
	LEA	AutoBlanks,A2
	MOVEQ	#3-1,D3
.l:	MOVE.L	(A2)+,D0
	MOVE.B	#" ",(A1)+
	MOVEQ	#8-1,D2
.h:	ROL.L	#4,D0
	MOVE.W	D0,D1
	AND.W	#$F,D1
	MOVE.B	.dig(PC,D1.W),(A1)+
	DBF	D2,.h
	DBF	D3,.l
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AutoBlankText,A0
	BSR	AutoPuts
	MOVEM.L	(SP)+,D0-D3/A0-A2
	RTS
.dig:	DC.B	"0123456789ABCDEF"
AutoBlankText:	DC.B	"@R BLK"
	DS.B	3*9+2
	CNOP	0,4
AutoBlanks:	DC.L	0,0,0
	ENDC

	IFD	AUTOPREFS
; Prefs checks: "@R PRF" and DirPrefs $08-$0B, $0C-$0F, $1C-$1F, $1F8-$1FB, $1FC-$1FF in hex,
; at every stop (the prefs as the program uses them after LoadPrefs).
AutoPrefsLine:
	MOVEM.L	D0-D3/A0-A2,-(SP)
	LEA	AutoPrefsText+6,A1
	LEA	.offs(PC),A2
	MOVEQ	#5-1,D3
.l:	MOVE.W	(A2)+,D0
	LEA	DirPrefs,A0
	MOVE.L	(A0,D0.W),D0
	MOVE.B	#" ",(A1)+
	MOVEQ	#8-1,D2
.h:	ROL.L	#4,D0
	MOVE.W	D0,D1
	AND.W	#$F,D1
	MOVE.B	.dig(PC,D1.W),(A1)+
	DBF	D2,.h
	DBF	D3,.l
	MOVE.B	#10,(A1)+
	CLR.B	(A1)
	LEA	AutoPrefsText,A0
	BSR	AutoPuts
	MOVEM.L	(SP)+,D0-D3/A0-A2
	RTS
.offs:	DC.W	$08,$0C,$1C,$1F8,$1FC
.dig:	DC.B	"0123456789ABCDEF"
AutoPrefsText:	DC.B	"@R PRF"
	DS.B	5*9+2
	CNOP	0,4
	ENDC

AutoFrames:	DC.L	0
AutoNext:	DC.L	AutoStops
	IFD	AUTOPREFS
AutoStops:	DC.L	100,0			; prefs checks: one stop
	ELSE
	IFD	AUTOSCR
AutoStops:	DC.L	300,900,0		; black-screen hunt: two grabs a run
	ELSE
	IFD	AUTOOASIS
; Defenders of Oasis (GG) with a battery save next to the cartridge
; "cl" in Mesen: Start twice, Continue, Game 1, walk left into the town, button 2 (search) so
; the message box comes up over the man in white.
AutoStops:	DC.L	4800,5160,5220,5280,5340,5400,0
	ELSE
	IFD	AUTOSPEED
AutoStops:	DC.L	1500,2250,3000,0
	ELSE
	IFD	AUTOMM
; Micro Machines into a race, as scratchpad mmrace.lua does in Mesen: from frame 400 every 90
; frames Left for 4 frames and button 1 (with Start) at 45-48; from 1800 button 1 held.
AutoStops:	DC.L	150,300,450,600,750,900,1050,1200,1350,1500,1650,1800,1950,2100,2250
		DC.L	2400,2550,2700,2850,3000,3150,3300,3450,3600,0
	ELSE
	IFD	AUTODEL
AutoStops:	DC.L	200,400,600,800,1000,1200,0
	ELSE
	IFD	AUTOEARLY
AutoStops:	DC.L	1,2,3,4,8,12,14,16,20,40,80,160,300,0	; start-up traces
	ELSE
AutoStops:	DC.L	300,600,1200,1800,0
	ENDC
	ENDC
	ENDC
	ENDC
	ENDC
	ENDC
	ENDC
	IFD	AUTOPAD
; from, to (frames), bits of port $DC pressed: bit 4 button 1, bit 5 button 2
	IFD	AUTOOASIS
AutoPadPlan:	DC.L	4800,4805,$20, 4900,4905,$20, 5000,5120,$04, 5130,5135,$20, 5250,5255,$20
		DC.L	5350,5355,$20, 0
	ELSE
	IFD	AUTOMM
	IFD	AUTOMM2
; Micro Machines 2 (GG) into a race, as build/mm2 plan b in Mesen: AUTOMM's presses to the
; "Change name?" question, Right (with button 1) for NO, then button 1 every 90 frames and
; held from 1800.
AutoPadPlan:
		DC.L	400,403,$04, 445,448,$10, 490,493,$04, 535,538,$10, 580,583,$04, 625,628,$10
		DC.L	670,673,$04, 715,718,$10, 760,763,$04, 805,808,$10, 850,853,$04, 895,898,$10
		DC.L	940,943,$04, 985,988,$10, 1030,1033,$04, 1075,1078,$18, 1120,1123,$10, 1210,1213,$10
		DC.L	1300,1303,$10, 1390,1393,$10, 1480,1483,$10, 1570,1573,$10, 1660,1663,$10, 1750,1753,$10
		DC.L	1800,99999,$10
		DC.L	0
	ELSE
AutoPadPlan:
		DC.L	400,403,$04, 445,448,$10, 490,493,$04, 535,538,$10, 580,583,$04, 625,628,$10
		DC.L	670,673,$04, 715,718,$10, 760,763,$04, 805,808,$10, 850,853,$04, 895,898,$10
		DC.L	940,943,$04, 985,988,$10, 1030,1033,$04, 1075,1078,$10, 1120,1123,$04, 1165,1168,$10
		DC.L	1210,1213,$04, 1255,1258,$10, 1300,1303,$04, 1345,1348,$10, 1390,1393,$04, 1435,1438,$10
		DC.L	1480,1483,$04, 1525,1528,$10, 1570,1573,$04, 1615,1618,$10, 1660,1663,$04, 1705,1708,$10
		DC.L	1750,1753,$04, 1795,1798,$10, 1800,99999,$10
		DC.L	0
	ENDC
	ELSE
AutoPadPlan:	DC.L	320,330,$20, 700,710,$10, 0
	ENDC
	ENDC
	ENDC
AutoMark:	DC.B	"@F"
AutoDigits:	DC.B	"0000",10,0
AutoStartText:	DC.B	"@START",10,0
AutoEndText:	DC.B	"@END",10,0
AutoErrText:	DC.B	"@ERR ",0
AutoNL:		DC.B	10,0
	IFD	AUTODUMP
AutoIrqs:	DC.L	0
AutoStatRd:	DC.L	0
AutoStat7:	DC.L	0
	IFD	AUTORAM
AutoRamMark:	DC.B	"@M ",0
	ENDC
AutoLine:	DC.B	"@R "
	DS.B	512
	ENDC
AutoFailed:	DC.B	0
	CNOP	0,4
