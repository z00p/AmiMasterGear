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
	ENDC
	MOVE.L	AutoNext,A0
	CMP.L	(A0),D0
	BNE.S	.ret
	ADDQ.L	#4,A0
	MOVE.L	A0,AutoNext

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
	LEA	IRAM,A2
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

AutoFrames:	DC.L	0
AutoNext:	DC.L	AutoStops
	IFD	AUTOEARLY
AutoStops:	DC.L	1,2,3,4,8,12,14,16,20,40,80,160,300,0	; start-up traces
	ELSE
AutoStops:	DC.L	300,600,1200,1800,0
	ENDC
	IFD	AUTOPAD
; from, to (frames), bits of port $DC pressed: bit 4 button 1, bit 5 button 2
AutoPadPlan:	DC.L	320,330,$20, 700,710,$10, 0
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
