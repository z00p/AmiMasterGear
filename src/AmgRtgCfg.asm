; AmgRtgCfg.asm: the RTG program's game-screen options (AMG_RTGCFG), read once at start, before
; Juan's prefs: from the menu's start-up just after the Workbench message is taken (no DOS call may
; come before that), so the menu can show them and AmgRtgOpen uses them at every Power ON.
;
; PROGDIR:AmiMasterGear.config, plain text, one "Key = Value" a line (case does not matter; any
; other line, e.g. one starting with ";", is left alone; AmiGameBoy 2.5's bm_config model):
;   Screen    = Sharp | Bigger        Sharp: 960x540 (half of 1080p, x2); Bigger: the P96 mode the
;                                     picture fills best (AmgRtgFind's best fit; the board scales it)
;   Scanlines = Off | On              scanlines at scale 2 and up (AmgRtgScan), in the style below
;               (Arnold's words too: off | 25 | 50 | 75 | blendlight | blend | blendstrong, also
;               hard25 | hard50 | hard75 and 0: a style word is On in that style; the old Black is
;               On in Hard 75%, as Arnold has no 100%)
;   ScanlineStyle = 25 | 50 | 75 | blendlight | blend | blendstrong (also hard25 .. hard75)
;                                     Hard n%: the lower half of each console line's screen rows
;                                     n% darker; Blended: those rows the line and the line below
;                                     averaged, 25% (light), 50% or 75% (strong) darker. Default 50
;   Buffering = Single | Double       Double: drawn into a hidden page, shown at the board's blank
;                                     ("Plain", tests only: the hidden page shown at once, as AmiGameBoy)
; Then the program icon's ToolTypes RTGSCREEN=, SCANLINES=, SCANLINESTYLE=, BUFFERING= (same values),
; which win:
; the icon is the choice for one launch. No file, no line or a value not listed: the default
; (the first value of each list; the style: Hard 50%; Buffering: Double with AMG_DBUFDEF, chosen
; 28 Nov 2026 after Micro Machines at NTSC 60 Hz on the A1200). The menu writes the config's lines; it reads
; and sets the bytes AmgCfgScreen, AmgCfgScan, AmgCfgStyle and AmgCfgBuf (AmgCfgTab: the value's
; place in its list, or through the option's map: see there).

	IFND	AMG_RTG
	FAIL	"AMG_RTGCFG needs AMG_RTG"
	ENDC

AMGC_TXTSZ	= 4096		; the config read, at most

	SECTION	AmgRtgCfgCode,CODE

; ---- the menu's start-up, OS alive, after the Workbench message (MENSWB) is taken and Juan's
; CurrentDir to the program's drawer. Keeps every register.
AmgCfgRead:
	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	_DosBase,D0
	BEQ	.tt
	MOVE.L	D0,A6
	MOVE.L	#AmgCfgName,D1
	MOVE.L	#1005,D2		; MODE_OLDFILE
	JSR	-30(A6)			; Open
	MOVE.L	D0,D4
	BEQ	.tt
	MOVE.L	D4,D1
	MOVE.L	#AmgCfgTxt,D2
	MOVE.L	#AMGC_TXTSZ-1,D3
	JSR	-42(A6)			; Read
	MOVE.L	D0,D3
	MOVE.L	D4,D1
	JSR	-36(A6)			; Close
	TST.L	D3
	BLE	.tt
	LEA	AmgCfgTxt,A0
	CLR.B	(A0,D3.L)		; the end
.line:	MOVE.B	(A0),D0			; a line: blanks, the key, blanks, "=", blanks, the value
	BEQ	.tt
	CMP.B	#" ",D0
	BEQ.S	.sk
	CMP.B	#9,D0
	BEQ.S	.sk
	LEA	AmgCfgTab,A3
.key:	MOVE.L	(A3),D0
	BEQ.S	.next			; none of ours
	MOVE.L	A0,A2
	MOVE.L	D0,A1
	BSR	AmgCfgKey
	BNE.S	.val
	MOVE.L	A2,A0
	LEA	20(A3),A3
	BRA.S	.key
.val:	MOVE.L	12(A3),A1
	BSR	AmgCfgVal
	BMI.S	.next
	BSR	AmgCfgSet
.next:	MOVE.B	(A0)+,D0		; to the next line
	BEQ.S	.tt
	CMP.B	#10,D0
	BNE.S	.next
	BRA.S	.line
.sk:	ADDQ.L	#1,A0
	BRA.S	.line
; the ToolTypes of the program's own icon (Workbench starts only)
.tt:	MOVE.L	MENSWB,D0
	BEQ	.x
	MOVE.L	D0,A2
	MOVE.L	$24(A2),D0		; sm_ArgList
	BEQ	.x
	MOVE.L	D0,A2
	MOVE.L	4.W,A6
	LEA	AmgCfgIconN(PC),A1
	MOVEQ	#36,D0
	JSR	-552(A6)		; OpenLibrary
	TST.L	D0
	BEQ	.x
	MOVE.L	D0,A6
	MOVE.L	4(A2),A0		; wa_Name, in the current directory (wa_Lock)
	JSR	-78(A6)			; GetDiskObject
	MOVE.L	D0,D6
	BEQ.S	.cl
	MOVE.L	D6,A0
	MOVE.L	$36(A0),D5		; do_ToolTypes
	BEQ.S	.fr
	LEA	AmgCfgTab,A3
.tk:	TST.L	(A3)
	BEQ.S	.fr
	MOVE.L	D5,A0
	MOVE.L	4(A3),A1		; the ToolType's name
	JSR	-96(A6)			; FindToolType
	TST.L	D0
	BEQ.S	.tn
	MOVE.L	D0,A0
	MOVE.L	12(A3),A1
	BSR	AmgCfgVal
	BMI.S	.tn
	BSR	AmgCfgSet
.tn:	LEA	20(A3),A3
	BRA.S	.tk
.fr:	MOVE.L	D6,A0
	JSR	-90(A6)			; FreeDiskObject
.cl:	MOVE.L	A6,A1
	MOVE.L	4.W,A6
	JSR	-414(A6)		; CloseLibrary
.x:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

; D0.L = the value's place in the list of option A3 (AmgCfgTab) -> its byte set. With a map (the
; Scanlines words): the map's byte; its low 4 bits to the option's byte and, bit 7 set, bits 4-6
; to AmgCfgStyle (a style word). Keeps every register.
AmgCfgSet:
	MOVEM.L	D0-D1/A1,-(SP)
	MOVE.L	16(A3),D1
	BEQ.S	.put
	MOVE.L	D1,A1
	MOVE.B	(A1,D0.L),D0
	BPL.S	.put
	MOVE.B	D0,D1
	LSR.B	#4,D1
	AND.B	#7,D1
	MOVE.B	D1,AmgCfgStyle
	AND.B	#15,D0
.put:	MOVE.L	8(A3),A1
	MOVE.B	D0,(A1)
	MOVEM.L	(SP)+,D0-D1/A1
	RTS

; A0 at a line's first word, A1 = a key (lower case) -> NE: it is the key, A0 after "=" and the
; blanks. EQ: not it (A0 moved). D0-D1 used.
AmgCfgKey:
	MOVE.B	(A1)+,D1
	BEQ.S	.end
	MOVE.B	(A0)+,D0
	OR.B	#$20,D0
	CMP.B	D1,D0
	BEQ.S	AmgCfgKey
.no:	MOVEQ	#0,D0
	RTS
.end:	BSR.S	.blank
	CMP.B	#"=",(A0)
	BNE.S	.no
	ADDQ.L	#1,A0
	BSR.S	.blank
	MOVEQ	#1,D0
	RTS
.blank:	CMP.B	#" ",(A0)
	BEQ.S	.b1
	CMP.B	#9,(A0)
	BNE.S	.b2
.b1:	ADDQ.L	#1,A0
	BRA.S	.blank
.b2:	RTS

; A0 = a value's text, A1 = the value words (lower case, each 0-ended, an empty one last) ->
; D0.L = the matching word's place, -1 (MI) for none. A whole word must match, in any case. A0 kept.
AmgCfgVal:
	MOVEM.L	D1-D2/A1-A2,-(SP)
	MOVEQ	#0,D2
.wd:	TST.B	(A1)
	BEQ.S	.none
	MOVE.L	A0,A2
.ch:	MOVE.B	(A1)+,D1
	BEQ.S	.end
	MOVE.B	(A2)+,D0
	OR.B	#$20,D0
	CMP.B	D1,D0
	BEQ.S	.ch
.skip:	TST.B	(A1)+			; not this word: to the next
	BNE.S	.skip
	ADDQ.W	#1,D2
	BRA.S	.wd
.end:	MOVE.B	(A2),D0			; the text's word must end here (no letter or digit next)
	CMP.B	#"0",D0
	BCS.S	.yes
	CMP.B	#"9",D0
	BLS.S	.long
	OR.B	#$20,D0
	CMP.B	#"a",D0
	BCS.S	.yes
	CMP.B	#"z",D0
	BHI.S	.yes
.long:	ADDQ.W	#1,D2			; a longer word
	BRA.S	.wd
.yes:	MOVE.L	D2,D0
	BRA.S	.r
.none:	MOVEQ	#-1,D0
.r:	MOVEM.L	(SP)+,D1-D2/A1-A2
	TST.L	D0
	RTS

AmgCfgIconN:	DC.B	"icon.library",0
	EVEN

	SECTION	AmgRtgCfgData,DATA
; per option: the config key (lower case), the ToolType, the byte set, the values in order, the
; map (0: the value's place itself)
AmgCfgTab:
	DC.L	AmgCfgKScr,AmgCfgTScr,AmgCfgScreen,AmgCfgVScr,0
	DC.L	AmgCfgKScan,AmgCfgTScan,AmgCfgScan,AmgCfgVScan,AmgCfgMScan
	DC.L	AmgCfgKSty,AmgCfgTSty,AmgCfgStyle,AmgCfgVSty,AmgCfgMSty
	DC.L	AmgCfgKBuf,AmgCfgTBuf,AmgCfgBuf,AmgCfgVBuf,0
	DC.L	0
AmgCfgScreen:	DC.B	0		; 0 Sharp (Half 1080), 1 Bigger (best fit)
AmgCfgScan:	DC.B	0		; 0 Off, 1 On
AmgCfgStyle:	DC.B	1		; 0-2 Hard 25/50/75%, 3-5 Blended light / Blended / strong
	IFD	AMG_DBUFDEF
AmgCfgBuf:	DC.B	1		; 0 Single, 1 Double (the default: AMG_DBUFDEF), 2 Plain (test: flipped at once)
	ELSE
AmgCfgBuf:	DC.B	0		; 0 Single, 1 Double, 2 Plain (test: flipped at once)
	ENDC
AmgCfgName:	DC.B	"PROGDIR:AmiMasterGear.config",0
AmgCfgKScr:	DC.B	"screen",0
AmgCfgKScan:	DC.B	"scanlines",0
AmgCfgKSty:	DC.B	"scanlinestyle",0
AmgCfgKBuf:	DC.B	"buffering",0
AmgCfgTScr:	DC.B	"RTGSCREEN",0
AmgCfgTScan:	DC.B	"SCANLINES",0
AmgCfgTSty:	DC.B	"SCANLINESTYLE",0
AmgCfgTBuf:	DC.B	"BUFFERING",0
AmgCfgVScr:	DC.B	"sharp",0,"bigger",0,0
AmgCfgVScan:	DC.B	"off",0,"on",0,"black",0,"0",0	; (runs on into the style words)
AmgCfgVSty:	DC.B	"25",0,"50",0,"75",0,"hard25",0,"hard50",0,"hard75",0
		DC.B	"blendlight",0,"blend",0,"blendstrong",0,0
AmgCfgVBuf:	DC.B	"single",0,"double",0,"plain",0,0
; Scanlines: off, on, black (On, Hard 75%), 0, then the style words: On in that style
AmgCfgMScan:	DC.B	$00,$01,$A1,$00,$81,$91,$A1,$81,$91,$A1,$B1,$C1,$D1
AmgCfgMSty:	DC.B	0,1,2,0,1,2,3,4,5
	EVEN

	SECTION	AmgRtgCfgBss,BSS
AmgCfgTxt:	DS.B	AMGC_TXTSZ
