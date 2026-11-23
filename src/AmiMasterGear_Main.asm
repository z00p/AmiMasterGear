
;	----------------------
;	AmiMasterGear Emulator	(Diseño Basado en AmiMSX2 Emulator)
;	----------------------

;	Diseñado y Programado por: Juan Antonio Gómez Gálvez
;	1997 © RED Soft S.L.  Barcelona, Spain
;	(Martes 28 de Enero de 1997) => (???)


FFFF_ON=0		; Si que se usa.
INISPR2=$3B
FINSPR2=INISPR2

;	------------------------
	SECTION	MasterGear,CODE
;	------------------------

HPeriod=215
VPeriod=313

ShowFps=0
ColorDebug=1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

;;	MOVEM.L	DEBUG,D0-D7/A0-A6

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	IFD	AUTOTEST
	JSR	AutoArgs		; test builds: the ROM is the command line
	ENDC
	JSR	InitSistema

	BRA.S	Vamos
	IFD	AMG_TITLES
	DC.B	"$VER: AmiMasterGear 1.1 (23.11.2026)",0,0
	ELSE
	DC.B	"$VER:AmiMasterGear Emulator v0.8 (12.12.99)",0,0
	ENDC
	DC.B	"By: Juan Antonio Gómez Gálvez.",0,0
	CNOP	0,8
Vamos:

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
GG_Menu:INCLUDE	"AmiMasterGear_Menu.asm"

	LEA	KeyBase(PC),A6
	ADDQ.L	#8,A4
	MOVE.L	A4,(A6)

	MOVE.L	#NADA,DirContinua
	TST.L	D7
	BMI.S	EsContinuar
	MOVE.L	#Bucle,DirContinua
	CLR.W	DirFlags
EsContinuar:

; -=-=-
	LEA	DirPrefs,A5
	MOVE.B	$08(A5),D0
	AND.W	#$0003,D0
	MOVE.L	(JoyControlPrg.W,PC,D0.W*4),JoyControlRut

	MOVE.L	#LeeNoJoy2,JoyControlRut2
	TST.B	DirPrefs+$15		; ¿Emular Joy 2?
	BEQ.S	EsJoyGameGear
	TST.B	DirPrefs+$16		; ¿Es Game Gear? entonces 1 solo Joy.
	BNE.S	EsJoyGameGear
	MOVE.B	$08(A5),D0
	LSR.B	#4,D0
	AND.W	#$0003,D0
	MOVE.L	(JoyControlPrg2.W,PC,D0.W*4),JoyControlRut2
EsJoyGameGear:
; -=-=-
	MOVE.W	#$1A0,BkBor
	MOVE.B	$09(A5),D0		; ¿Black Border?
	BFINS	D0,BpCon3{$1A:1}
	AND.W	#$0020,D0
	SUB.W	D0,BkBor
; -=-=-

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	LEA	Regs,A3
	BSR	CreaTablaFlags

; ---------------------------------------=> Parches Según consola.

	MOVE.L	#$3BA1FBA1,D0
;	MOVE.L	#PantSpr-8,D1
	TST.B	DirPrefs+$16
	BEQ.S	EsMastSys
	MOVE.L	#$53D1E371,D0
;	MOVE.L	#PantSpr+($18*32)-8,D1
EsMastSys:
	MOVE.W	D0,Bordes+6
	SWAP	D0
	MOVE.W	D0,Bordes+2
;;	MOVE.L	D1,DiPaSp+4
; ---------------------------------------<=

; ---------------------------------------=> Clear Caches.
	MOVE.L	$4.W,A6
	JSR	-$27C(A6)	; ClearCacheU
; ---------------------------------------<=

; ---------------------------------------=> Parche para MC68060.
	TST.B	EsUn060
	BEQ.S	NoMC060
	MOVE.L	#NOP060,Regs+$800
	MOVE.L	#NOP060,Regs+$804
NoMC060:
; ---------------------------------------<=

; ---------------------------------------=> Modo Show fps.
	MOVE.W	#$01A0,CopShoFps
	TST.B	DirPrefs+$12
	BEQ.S	NoShowfps
	MOVE.W	#$0100,CopShoFps
NoShowfps
; ---------------------------------------<=

; ---------------------------------------=> Pone Real Time Scroll ON/OFF
	MOVE.L	#VDP8,VDPRuts+($8*4)
	MOVE.L	#VDP9,VDPRuts+($9*4)
	TST.B	DirPrefs+$1E
	BNE.S	SiRealScoll
	MOVE.L	#VDPx,VDPRuts+($8*4)
	MOVE.L	#VDPx,VDPRuts+($9*4)
SiRealScoll:
; ---------------------------------------<=

	JSR	CongelaAMIGA

; ---------------------------------------=> Arregla Tabla Instr.
	LEA	Instr,A0
	MOVE.W	#256-1,D0
BucRelen0:
	MOVE.L	4(A0,D0.W*8),D1
	MOVE.L	D1,(A0,D0.W*8)
	DBF	D0,BucRelen0
; ---------------------------------------<=

	BSR	InitPSG
	MOVE.L	SP,PILA
	BRA	Z80A

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
JoyControlPrg:
	DC.L	LeeJoyStick
	DC.L	LeeTeclado
	IFD	AMG_PADS
	DC.L	AmgPad1Kit
	DC.L	AmgPad1Low
	ELSE
	DC.L	LeeCD32Joypad
	DC.L	LeeJoypad
	ENDC

	CNOP	0,8
JoyControlPrg2:
	DC.L	LeeJoyStick2
	DC.L	LeeTeclado2
	IFD	AMG_PADS
	DC.L	AmgPad2Kit
	DC.L	AmgPad2Low
	ELSE
	DC.L	LeeCD32Joypad2
	DC.L	LeeJoypad2
	ENDC

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

InitSistema:
	BSR	ArrTabInst
	JSR	CreaCoorSprits
	BSR	CreaCoppLine

	BSR	CreaTabFlip
	BSR	CreaTabSpr

	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
CreaTabFlip:
	LEA	TablaFlipX,A0
;	LEA	TablaFlipY,A1

	MOVEQ	#0,D1
	MOVEQ	#0,D3
	MOVE.W	#($100)-1,D0
CrTaFlipBuc:
	MOVE.W	D1,D2
;;	MOVE.B	D2,(A1)+
	REPT	8
	LSR.B	#1,D2
	ADDX.B	D3,D3
	ENDR
	MOVE.B	D3,(A0)+
	ADDQ.B	#1,D1
	DBF	D0,CrTaFlipBuc
	RTS
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
CoppLineSize=$10
	CNOP	0,8
CreaCoppLine:
	MOVE.L	#$3AC1FFFE,D1
	LEA	CopperLine0,A0
	LEA	CopperLine1,A1
	MOVE.L	#CopperRet,D3
	MOVE.W	#($C0)-1,D0
CrCoLiBuc:
	MOVE.L	D1,(A0)+		; $00 - Wait
	MOVE.L	D1,(A1)+		; $00 - Wait

	MOVE.W	#$0084,(A0)+		; $04 - CoppJump
	MOVE.W	#$0084,(A1)+		; $04 - CoppJump
	SWAP	D3
	MOVE.W	D3,(A0)+
	MOVE.W	D3,(A1)+
	MOVE.W	#$0086,(A0)+
	MOVE.W	#$0086,(A1)+
	SWAP	D3
	MOVE.W	D3,(A0)+
	MOVE.W	D3,(A1)+

	MOVE.L	#$00FE0000,(A0)+	; $0C - ExeCoppJump
	MOVE.L	#$00FE0000,(A1)+	; $0C - ExeCoppJump

	ADD.L	#$01000000,D1
	DBF	D0,CrCoLiBuc
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
CreaTabSpr:
	LEA	TablaGfxSpr,A0
	MOVEQ	#0,D2
	MOVE.W	#8-1,D4
CrTaSpBuc1:
	MOVEQ	#0,D0
	MOVE.W	#256-1,D3
CrTaSpBuc0:
	MOVE.W	D0,D1
	LSR.W	D2,D1
	MOVE.W	D1,(A0)+
	ADD.W	#$0100,D0
	DBF	D3,CrTaSpBuc0
	ADDQ.B	#1,D2
	DBF	D4,CrTaSpBuc1
	RTS
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	CNOP	0,8
CreaCoorSprits:
	MOVE.W	#INISPR2*$100+$50,Sprit0
	MOVE.W	#FINSPR2*$100+$02,Sprit0+8

	MOVE.W	#INISPR2*$100+$50,Sprit1
	MOVE.W	#FINSPR2*$100+$82,Sprit1+8

	MOVE.W	#INISPR2*$100+$70,Sprit2
	MOVE.W	#FINSPR2*$100+$02,Sprit2+8

	MOVE.W	#INISPR2*$100+$70,Sprit3
	MOVE.W	#FINSPR2*$100+$82,Sprit3+8

	MOVE.W	#INISPR2*$100+$90,Sprit4
	MOVE.W	#FINSPR2*$100+$02,Sprit4+8

	MOVE.W	#INISPR2*$100+$90,Sprit5
	MOVE.W	#FINSPR2*$100+$82,Sprit5+8

	MOVE.W	#INISPR2*$100+$B0,Sprit6
	MOVE.W	#FINSPR2*$100+$02,Sprit6+8

	MOVE.W	#INISPR2*$100+$B0,Sprit7
	MOVE.W	#FINSPR2*$100+$82,Sprit7+8
	RTS
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; -----------------------------------------------------------------------


ANA=$488
IFF=$489
HaltDat=$482

IFF0=$F
I=2
R=3
PEXX=4
ModoTraza=-$4C
ModoInt=$C

MaskROM=$72
MapROMBase=$74
Consola=$78
PSG_Old=$79
Estado=$7A
SalirMenu=$7B

DirVRAM=$A
MaskVPAL=-$4A
JoyX=-$48
KeyX=-$44
Bufer=-$40

TAB_Flags=$7C
Flags_Par=$7C
Flags_Push=$7D
Flags_Pop=$7E
Flags_DAA=$7F

TabRedef=$1000

RasterInt=$D
PetIntMG=$E
TipoInt=$70
LineInt=$71
IntMGAnt=-$50

UltCoorY=-$52
UltCoorX=-$51

Contador1=-$58
PalCopy=-$54

IO7F=$480
IOBF=$481
MapperIO=$484

GfxReCont=-$5A
SprReCont=-$59

CurLine=-$5C
HorLine=-$56

fps60Dat=-$53
VLines=-$5E


; -----------------------------------------------------------------------

; ------------------------------------<

; ------------------------------------> Borra memoria. (A0=Dir.MEM) D0.w=(x/4)-1
	CNOP	0,4
BorraMem:
	CLR.L	(A0)+
	DBF	D0,BorraMem
	RTS
; ------------------------------------<

; ------------------------------------> Inicializa PSG
InitPSG:
	LEA	$DFF000,A6
	BSET	#1,$BFE001		; Datos Musica.

	MOVE.L	#ONDA,$A0(A6)	; wave
	MOVE.L	#ONDA,$B0(A6)
	MOVE.L	#ONDA,$C0(A6)
	MOVE.L	#Ruido,$D0(A6)

	MOVE.W	#1,$A4(A6)	; Size
	MOVE.W	#1,$B4(A6)
	MOVE.W	#1,$C4(A6)
	MOVE.W	#5000,$D4(A6)

	MOVE.W	#0,$A8(A6)	; Volumen
	MOVE.W	#0,$B8(A6)
	MOVE.W	#0,$C8(A6)
	MOVE.W	#0,$D8(A6)

	MOVE.W	#$800F,$96(A6)
	RTS
; ------------------------------------<

; ------------------------------------> Crea Tablas de Paginación.
	CNOP	0,4
CreaTabPag:
	IFD	AMG_RAMMIRROR
	LEA	PagRead(A3),A0		; eight 8K pages
	LEA	Restas(A3),A1
	LEA	Desbor(A1),A2
	MOVEQ	#0,D1
	MOVEQ	#(8-1),D0
AmgCreaTabPag8:
	MOVE.L	(A0)+,D2
	MOVE.W	D2,(A1)+
	ADDQ	#$6,A1
	ADD.L	D1,D2
	ADDQ.L	#$1,D2
	MOVE.L	D2,(A2)+
	ADD.L	#$1FFF,D2
	MOVE.L	D2,(A2)+
	ADD.L	#$2000,D1
	DBF	D0,AmgCreaTabPag8
	RTS
	ENDC
	LEA	PagRead(A3),A0
	LEA	Restas(A3),A1
	LEA	Desbor(A1),A2	; (CUIDADO: Según Puntero "Restas")
	MOVEQ	#0,D1
	MOVEQ	#(4-1),D0
CreaTabPagBuc:
	MOVE.L	(A0)+,D2	; Punteros de Restas.
	MOVE.W	D2,(A1)+
	ADDQ	#$6,A1

;;;	MOVE.L	(A0)+,D2	; Punteros de Desbordamiento.
	ADD.L	D1,D2
	ADDQ.L	#$1,D2
	MOVE.L	D2,(A2)+
	ADD.L	#$3FFF,D2
	MOVE.L	D2,(A2)+

	ADD.L	#$4000,D1
	DBF	D0,CreaTabPagBuc
	RTS
; ------------------------------------<


; ------------------------------------> Arregla Tabla de Instrucciones Z-80.
	CNOP	0,4
ArrTabInst:
	LEA	Instr,A0
	MOVE.W	#256-1,D0
INSTBUC:
	MOVE.L	(A0,D0.W*4),(A0,D0.W*8)
	MOVE.L	(A0,D0.W*4),4(A0,D0.W*8)
	DBF	D0,INSTBUC
	RTS
; ------------------------------------<

; ------------------------------------> Crea Tablas para Flags.

CreaTablaFlags:
PONP:	MACRO
	MOVEQ	#8-1,D1
	MOVE.B	#9,D2
\@:
	ROR.B	#1,D7
	DBCS	D2,\@2
\@2:	DBF	D1,\@
	BFINS	D2,D3{30:1}
	ENDM


	LEA	TAB_Flags(A3),A0
	MOVE.W	#256-1,D6
	MOVEQ	#0,D0
FLAGSBUC:
	MOVEQ	#0,D7
	OR.B	D0,D7
	MOVE.W	CCR,D3
	PONP
	MOVE.B	D3,(A0)+
;	----
	MOVE.B	D0,D1
	MOVEQ	#0,D2
	BFINS	D1,D2{31:1}	; C	(Ami-b0 => MSX-b0)
	LSR.B	#1,D1
	BFINS	D1,D2{29:1}	; P/V	(Ami-b1 => MSX-b2)
	LSR.B	#1,D1
	BFINS	D1,D2{25:1}	; Z	(Ami-b2 => MSX-b6)
	LSR.B	#1,D1
	BFINS	D1,D2{24:1}	; S	(Ami-b3 => MSX-b7)
;	---
	LSR.B	#1,D1
	BFINS	D1,D2{30:1}	; 	(Ami-b4 => MSX-b1)
	LSR.B	#1,D1
	BFINS	D1,D2{28:1}	; 	(Ami-b5 => MSX-b3)
	LSR.B	#1,D1
	BFINS	D1,D2{27:1}	; 	(Ami-b6 => MSX-b4)
	LSR.B	#1,D1
	BFINS	D1,D2{26:1}	; 	(Ami-b7 => MSX-b5)
;	---
	MOVE.B	D2,(A0)+
;	----
	MOVE.B	D0,D1
	MOVEQ	#0,D2
	BFEXTU	D1{24:1},D3	; S	(MSX-b7 => Ami-b3)
	BFINS	D3,D2{28:1}
	BFEXTU	D1{25:1},D3	; Z	(MSX-b6 => Ami-b2)
	BFINS	D3,D2{29:1}
	BFEXTU	D1{29:1},D3	; P/V	(MSX-b2 => Ami-b1)
	BFINS	D3,D2{30:1}
	BFINS	D1,D2{31:1}	; C	(MSX-b0 => Ami-b0)
;	---
	BFEXTU	D1{26:1},D3	; 	(MSX-b5 => Ami-b7)
	BFINS	D3,D2{24:1}
	BFEXTU	D1{27:1},D3	; 	(MSX-b4 => Ami-b6)
	BFINS	D3,D2{25:1}
	BFEXTU	D1{28:1},D3	; 	(MSX-b3 => Ami-b5)
	BFINS	D3,D2{26:1}
	BFEXTU	D1{30:1},D3	; 	(MSX-b1 => Ami-b4)
	BFINS	D3,D2{27:1}
;	---
	MOVE.B	D2,(A0)+
;	----
	MOVE.B	D0,(A0)+
;	----
	ADDQ.B	#1,D0
	DBF	D6,FLAGSBUC
	RTS
; ------------------------------------<


; ------------------------------------=>
CogePag:MACRO
	MOVE.L	\1,\2
	IFC	"D1","\1"
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ELSEIF
	IFD	AMG_RAMMIRROR
	BFEXTU	\1{16:3},D1
	ELSE
	BFEXTU	\1{16:2},D1
	ENDC
	ENDC
	ADD.L	PagRead(A3,D1.W*4),\2
	ENDM

CogePag2:MACRO
	IFC	"D1","\1"
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ELSEIF
	IFD	AMG_RAMMIRROR
	BFEXTU	\1{16:3},D1
	ELSE
	BFEXTU	\1{16:2},D1
	ENDC
	ENDC
	ADD.L	PagRead(A3,D1.W*4),\2
	ENDM

CogePagI:MACRO
	ADD.W	\1,D1
	MOVE.L	D1,\2
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ADD.L	PagRead(A3,D1.W*4),\2
	ENDM

CogePagE:MACRO
	MOVE.L	\1,\2
	IFC	"D1","\1"
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ELSEIF
	IFD	AMG_RAMMIRROR
	BFEXTU	\1{16:3},D1
	ELSE
	BFEXTU	\1{16:2},D1
	ENDC
	ENDC
	ADD.L	PagWrite(A3,D1.W*4),\2
	ENDM

CogePagE2:MACRO
	IFC	"D1","\1"
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ELSEIF
	IFD	AMG_RAMMIRROR
	BFEXTU	\1{16:3},D1
	ELSE
	BFEXTU	\1{16:2},D1
	ENDC
	ENDC
	ADD.L	PagWrite(A3,D1.W*4),\2
	ENDM

CogePagIE:MACRO
	ADD.W	\1,D1
	MOVE.L	D1,\2
	LSR.W	#8,D1
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D1
	ELSE
	LSR.B	#6,D1
	ENDC
	ADD.L	PagWrite(A3,D1.W*4),\2
	ENDM
	IFD	AMG_RAMMIRROR
; AMG_RAMMIRROR: a 16K slot (\1 = 0-2) is two 8K pages with the same base (D1, used up): read
; pointers, the words that give the Z80 PC and the run-off bounds, as CreaTabPag makes them.
AmgPag8:	MACRO
	MOVE.L	D1,PagRead+(\1*8)(A3)
	MOVE.L	D1,PagRead+(\1*8)+4(A3)
	MOVE.W	D1,Restas+(\1*16)(A3)
	MOVE.W	D1,Restas+(\1*16)+8(A3)
	ADD.L	#(\1*$4000)+1,D1
	MOVE.L	D1,Restas+Desbor+(\1*16)(A3)
	ADD.L	#$1FFF,D1
	MOVE.L	D1,Restas+Desbor+(\1*16)+4(A3)
	ADDQ.L	#1,D1
	MOVE.L	D1,Restas+Desbor+(\1*16)+8(A3)
	ADD.L	#$1FFF,D1
	MOVE.L	D1,Restas+Desbor+(\1*16)+12(A3)
	ENDM
	ENDC
; ------------------------------------<=



;	/------------------------\
;	|  MM   MM  SSSSS X   X  |
;	|  M M M M SS      X X   |  	-*  Emulador  Z-80A  *-
;	|  M  M  M  SSSS    X    |
;	|  M     M     SS  X X   |  Por  Juan Antonio Gómez Gálvez.
;	|  M     M SSSSS  X   X  |
;	\------------------------/

;		-*(  Ejecutar bajo MC68020 o superior. )*-

;	Datos de etiquetas:

;	D0 = Pila y uso en PUN=>BPL.	A0 = IX.
;	D1 = Uso libre en .l		A1 = IY.
;	D2 = $01xx.w (Usar en .b)	A2 = VPC (VRAM)
;	D3 = CCF de Amiga. (F y F')	A3 = Datos y Punteros.
;	D4 = HL	(.w)			A4 = Uso libre.
;	D5 = BC	(.w)			A5 = PC (Actual)
;	D6 = DE	(.w)			A6 = SP (Actual)
;	D7 = A y A' (Swap) (.b)		A7 = Punteros paginación.


; ---------------------------------------=> Power ON  Zilog Z-80 Processor.
	CNOP	0,8
Z80A:
	LEA	Regs,A3
;	-=-=-=-=-=-=-=-=-=-=-=-

	CMP.L	#Bucle,DirContinua
	BNE	EsContinue

;	-=-=-=-=-=-=-=-=-=-=-=-		; Borra tabla base de datos.
	MOVE.L	A3,A0
	MOVE.W	#($7C/4)-1,D0
	BSR	BorraMem

	LEA	$480(A3),A0
	MOVE.W	#($380/4)-1,D0
	BSR	BorraMem
;	-=-=-=-=-=-=-=-=-=-=-=-
;	-=-=-=-=-=-=-=-=-=-=-=-		; Inicializa Datos en tabla base.
	MOVE.L	#-1,JoyX(A3)
	MOVE.L	#-1,KeyX(A3)

	MOVE.L	#TabRasRGB,TabRasRGBcnt

	MOVE.W	DirPrefs+$128,D0	; VPeriod
	SUB.W	#256,D0
	BCC.S	VlinCon1
	MOVEQ	#0,D0
VlinCon1:
	CMP.W	#$7F,D0
	BCS.S	VlinCon
	MOVE.W	#$7F,D0
VlinCon:
	AND.W	#$007F,D0
	ADDQ.W	#1,D0
	MULU	#HPeriod,D0
	MOVE.W	D0,VLines(A3)

	ST	HorLine(A3)

	CLR.B	GfxReCont(A3)
	CLR.B	SprReCont(A3)

	MOVE.L	#OUTBEa,Outs+($BE*4)
	MOVE.L	#INBE,Ins+($BE*4)

	MOVE.W	#$1F,MaskVPAL(A3)
	MOVE.B	DirPrefs+$16,Consola(A3)
	BEQ.S	EsMastSys2
	MOVE.W	#$3F,MaskVPAL(A3)
EsMastSys2:

	LEA	PSG_Tab,A0
	MOVE.W	#(16/4)-1,D0
	BSR	BorraMem
	ST	PSG_Tab+2
	ST	PSG_Tab+6
	ST	PSG_Tab+10
	ST	PSG_Tab+14
;	-=-=-=-=-=-=-=-=-=-=-=-
;	-=-=-=-=-=-=-=-=-=-=-=-
	MOVE.W	PagCart,D0		; Numero de Páginas del Cartucho.
	SUBQ.W	#1,D0
	MOVE.W	#$01FF,D1
MaskROMBuc:
	LSR.W	#1,D1
	LSL.B	#1,D0
	BCC.S	MaskROMBuc
	MOVE.W	D1,MaskROM(A3)
;	-=-=-=-=-=-=-=-=-=-=-=-
;	-=-=-=-=-=-=-=-=-=-=-=-		; Borra Todas las RAMs.
	LEA	VDPRegs,A0
	MOVE.W	#($80/4)-1,D0
	BSR	BorraMem
	LEA	VPAL,A0
	MOVE.W	#(32/4)-1,D0
	BSR	BorraMem
	LEA	VRAM,A0
	MOVE.W	#($4080/4)-1,D0
	BSR	BorraMem
	LEA	IRAM,A0
	MOVE.W	#($4080/4)-1,D0
	BSR	BorraMem

	LEA	PantGfx,A0
	MOVE.W	#((32*256*4*2)/4)-1,D0
	BSR	BorraMem
;	LEA	PantSpr,A0
;	MOVE.W	#((32*256*4)/4)-1,D0
;	BSR	BorraMem
;	-=-=-=-=-=-=-=-=-=-=-=-
; ----------------------------------
	LEA	Regs,A3
	MOVE.L	#$00000102,MapperIO(A3)
	MOVE.L	#$00000102,IRAM+$1FFC
; ----------------------------------

;	-=-=-=-=-=-=-=-=-=-=-=-

EsContinue:

;	-=-=-=-=-=-=-=-=-=-=-=-		; Reinicializa datos.

;	-=-=-=-=-=-=-=-=-=-=-=-		; Inicializa Sistema de Paginación
	MOVE.L	DirCart,A0

	ADD.W	#$0080,A0
	MOVE.L	A0,PagRead+$0(A3)
	ADD.W	#$0080,A0
	MOVE.L	A0,PagRead+$4(A3)
	MOVE.L	A0,PagRead+$8(A3)
	SUB.W	#$4080,A0
	MOVE.L	A0,MapROMBase(A3)

;	-=-=-=-=-=-=-=-=-=-=-=-		; Inicializa Mascaras de ROM y RAM.
	MOVE.L	#-1,JoyX(A3)
	MOVE.L	#-1,KeyX(A3)

	MOVE.B	DirPrefs+$1F,PalCopy(A3)	; Para Realtime Pal Refresh.

	MOVE.L	#NoRAM-$0000,PagWrite+$0(A3)
	MOVE.L	#NoRAM-$4000,PagWrite+$4(A3)
	MOVE.L	#NoRAM-$8000,PagWrite+$8(A3)
	MOVE.L	#IRAM-$C000,PagWrite+$C(A3)

	MOVE.L	#IRAM-$C000,PagRead+$C(A3)
	IFD	AMG_RAMMIRROR
	MOVE.L	#NoRAM-$0000,PagWrite+$04(A3)	; 8K pages; the mapper sets the ROM read pages
	MOVE.L	#NoRAM-$4000,PagWrite+$08(A3)
	MOVE.L	#NoRAM-$4000,PagWrite+$0C(A3)
	MOVE.L	#NoRAM-$8000,PagWrite+$10(A3)
	MOVE.L	#NoRAM-$8000,PagWrite+$14(A3)
	MOVE.L	#IRAM-$C000,PagWrite+$18(A3)	; $C000-$DFFF
	MOVE.L	#IRAM-$E000,PagWrite+$1C(A3)	; $E000-$FFFF: the same 8K, as on the console
	MOVE.L	#IRAM-$C000,PagRead+$18(A3)
	MOVE.L	#IRAM-$E000,PagRead+$1C(A3)
	ENDC
;	-=-=-=-=-=-=-=-=-=-=-=-

; ----------------------------------	; Refresca Gráficos.
	LEA	PantAnt,A0
	MOVE.W	#(32*32)-1,D0
ClrPanBuc:
	NOT.W	(A0)+
	DBF	D0,ClrPanBuc
	IFD	AMG_TMSMODES
	SF	AmgTmsOn		; a TMS mode picture is drawn whole too
	ENDC

	JSR	ImprimeGfx
	JSR	ImprimeGfx2

	JSR	ActualizaGFX

	JSR	PonePaletaMS
; ----------------------------------

; ----------------------------------
	LEA	Regs,A3
	MOVE.L	MapperIO(A3),IRAM+$3FFC
	IFD	AMG_CODIES
	JSR	AmgCmInstall		; Codemasters or Sega mapper, from the header
	ENDC
	IFD	AMG_PORTMIRROR
	JSR	AmgPortMirror		; the ports' mirrors, as the console decodes them
	ENDC
	JSR	MapperInit
	BSR	CreaTabPag
; ----------------------------------

	LEA	Debug,A0
	MOVEM.L	(A0),D0-D7/A0-A4

	LEA	Regs,A3
	MOVEQ	#0,D1
	MOVE.W	PCReg,D1
	CogePag	D1,A5			; Refresca PC
	LEA	Restas(A3,D1.W*8),A7

	MOVE.W	#$0100,D2
	MOVE.B	(A5)+,D2

	CogePagE D0,A6			; Refresca SP

	CMP.L	#Bucle,DirContinua
	BNE	EsContinue2

	LEA	VRAM,A2		;  VPC=0000 (VRAM)

	LEA	Regs,A3
	LEA	Restas(A3),A7
	CLR.W	PCReg		;  PC=0000
	MOVE.L	PagRead(A3),A5	;  PC=0000
	LEA	NoRAM,A6	;  SP=0000
	MOVEQ	#0,D0		;  SP Pila
	MOVEQ	#0,D1		;  (Usar solo en .w)
	MOVEQ	#0,D2		;  (Usar solo en .b)
	MOVE.L	#$0100,D2	;  (Truco para DEC/DJNZ)
	MOVEQ	#0,D3		;  F=00   (Flags/CCR)
	MOVEQ	#0,D4		;  HL=0000
	MOVEQ	#0,D5		;  BC=0000
	MOVEQ	#0,D6		;  DE=0000
	MOVEQ	#0,D7		;  A=00   (Acumulador)
	SUB.L	A0,A0		;  IX=0000
	SUB.L	A1,A1		;  IY=0000
	SUB.L	A4,A4		;  (Uso libre)

EsContinue2:

; ----------------------------------
	MOVE.W	#$7FFF,$DFF09C
	NOP
	NOP
EsperaInt0:
	BTST	#$05,$DFF01F
	BEQ.S	EsperaInt0
	NOP
	MOVE.W	#$7FFF,$DFF09C
	NOP
	NOP
EsperaInt1:
	BTST	#$05,$DFF01F
	BEQ.S	EsperaInt1
	NOP
	MOVE.W	#$7FFF,$DFF09C
	NOP
	NOP
EsperaInt2:
	BTST	#$05,$DFF01F
	BEQ.S	EsperaInt2
	NOP
	NOP
	MOVE.W	#$7FFF,$DFF09C
	NOP
	NOP
; ----------------------------------
	MOVEM.L	D1/D2,ClrKeyBuf

	MOVE.W	#4,D1
	OR.B	#$40,$BFEE01		; CIAA Libre
TRETARDO0:
	MOVE.B	$DFF006,D2
TRETARDOB0:
	CMP.B	$DFF006,D2
	BEQ.S	TRETARDOB0
	DBF	D1,TRETARDO0
	AND.B	#$BF,$BFEE01		; CIAA Libre

	MOVEM.L	ClrKeyBuf(PC),D1/D2

	NOP
	NOP
	SF	$BFEC01
	NOP
	NOP
; ----------------------------------

	MOVE.W	#$C030,$DFF09A		; EI
BUC:	BRA.S	BUC			; JR $FE  (je,je,je)

; ----------------------------------
	CNOP	0,8
ClrKeyBuf:	DS.L	3
; ----------------------------------

; ---------------------------------------=>
KeyBase:	DC.L	0
; ---------------------------------------<=


; -----------------------------------------


; ------------------------------------------------ ;


;	/------------------------------------------------------\
;	|  Z-80A & R-800  Macros v4.0  Por Juan Antonio Gómez  |
;	\------------------------------------------------------/

;	D0 = Pila y Gfx.		A0 = IX.
;	D1 = Uso libre en .w		A1 = IY.
;	D2 = $01xx.w (Usar en .b)	A2 = VPC (VRAM)
;	D3 = CCF de Amiga. (F y F')	A3 = Datos y Punteros.
;	D4 = HL	(.w)			A4 = Uso libre.
;	D5 = BC	(.w)			A5 = PC (Actual)
;	D6 = DE	(.w)			A6 = SP (Actual)
;	D7 = A y A' (Swap) (.b)		A7 = Punteros paginación.



PARDAAS:MACRO
	MOVE.B	D7,ANA(A3)
	ENDM

PARDAAR:MACRO
	MOVE.B	D7,ANA(A3)
	ENDM


Otra:	MACRO
	MOVE.B	(A5)+,D2
	IFNE	\1>(8)
	SUB.W	#\1,(A3)			; * Resta Cycles *
	ELSEIF
	SUBQ.W	#\1,(A3)			; * Resta Cycles *
	ENDC
	BMI.S	\@Buc
	JMP	([A3,D2.W*8])
\@Buc:	JMP	(MiraInter-Regs.W,A3)
	CNOP	0,4
	ENDM

Otra2:	MACRO
	MOVE.B	(A5)+,D2
	JMP	([A3,D2.W*8])
	CNOP	0,4
	ENDM

OtraEI:	MACRO
	MOVE.B	(A5)+,D2
	SUBQ.W	#\1,(A3)			; * Resta Cycles *
	JMP	([A3,D2.W*8])
	CNOP	0,4
	ENDM


OtraT:	MACRO
	MOVE.W	CCR,D3
	Otra	\1
	ENDM

OtraC:	MACRO
	ROXL.B	#1,D3
	Otra	\1
	ENDM

OtraC2:	MACRO
	BCC.S	\@
	OR.B	#$01,D3
	Otra	\1
\@:
	AND.B	#$FE,D3
	Otra	\1
	ENDM

OtraP:	MACRO
	MOVE.B	Flags_Par(A3,D7.W*4),D3
	Otra	\1
	ENDM

OtraV:	MACRO
	BNE.S	\@
	AND.B	#$FD,D3
	Otra	\1
\@:
	OR.B	#$02,D3
	Otra	\1
	ENDM

OtraZ:	MACRO
	BEQ.S	\@
	AND.B	#$FB,D3
	Otra	\1
\@:
	OR.B	#$04,D3
	Otra	\1
	ENDM

PONF:	MACRO
	IFC	"S","\1"
	MOVE.B	D3,D1
	ELSEIF
	IFC	"X","\2"
	LSR.B	#1,D3
	OR.B	#$04,CCR
	ELSEIF
	IFC	"C","\1"
	LSR.B	#1,D3
	ENDC
	ENDC
	ENDC
	ENDM

PONS:	MACRO
	MOVE.W	CCR,D3
	BFINS	D1,D3{31:1}
	ENDM

OtraS:	MACRO
	PONS
	Otra	\1
	ENDM

SUBBZ:	MACRO
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	\@
	AND.B	#$FB,D3
	BRA.S	\@2
	CNOP	0,4
\@:	OR.B	#$04,D3
\@2:
	MOVE.B	D2,D5
	ENDM

PonCCR:	MACRO
	IFC	"N","\1"
	Otra	\2		; NO guarda flags.
	ENDC
	IFC	"T","\1"
	OtraT	\2		; Guarda todos los flags.
	ENDC
	IFC	"S","\1"
	OtraS	\2		; Guarda flags SZV.
	ENDC
	IFC	"C","\1"
	OtraC	\2		; Guarda flag C.
	ENDC
	IFC	"Z","\1"
	OtraZ	\2		; Guarda flag Z.
	ENDC
	IFC	"P","\1"
	OtraP	\2		; Guarda flag P y demás.
	ENDC
	ENDM


CheckB:	MACRO
	CMP.L	Desbor+4(A7),A5
	BLE.S	\@NO
	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,\1
\@NO:
	ENDM


CheckW:	MACRO
	CMP.L	Desbor+4(A7),A5
	BLE.S	\@NO
	ROR.W	#8,\1
	MOVE.B	\1,D2
	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	TST.B	D1
	BEQ.S	\@M2
	SUBQ.W	#1,D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.W	(A5)+,\1
	BRA.S	\@NO
	CNOP	0,4
\@M2:
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	D2,\1
	LSL.W	#8,\1
	MOVE.B	(A5)+,\1
\@NO:
	ENDM



; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

;;		  \1    \2      \3    \4   \5     \6
;;	MIns	Instr,Destino,Origen,Modo,Flags,Ini.Flags

MIns:	MACRO

	IFC	"0","\4"		; Todo con registro bajos.
	PONF	\5,\6
	\1	\3,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"0B","\4"		; Todo con registro bajos.
	PONF	\5,\6
	\1	\3,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"1","\4"		; Registro alto con registro bajo.
	MOVE.W	\3,D1
	LSR.W	#8,D1
	PONF	\5,\6
	\1	D1,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"2","\4"		; Todo con registros (HL,DE,BC)
	PONF	\5,\6
	\1	\3,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"2I","\4"		; Todo con registros (IX,IY) 
	MOVE.W	\2,D1
	PONF	\5,\6			; * No modificar D1 *
	\1	\3,D1
	MOVE.L	D1,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"3","\4"		; Registro (HL) con registro A.
	CogePag	\3,A4
	\1	(A4),\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"4","\4"		; Registros (IX,IY) con registro A.
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagI \3,A4
	\1	(A4),\2
	PonCCR	\5,\7			; Recoge Flags.
\@M:	CheckB	D1
	EXT.W	D1
	CogePagI \3,A4
	\1	(A4),\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"7","\4"		; Ins. DEC. registros Altos.
	MOVE.B	D3,D1
	MOVE.B	\2,D2
	\1	D2,\2
	MOVE.W	CCR,D3
	BFINS	D1,D3{31:1}
	MOVE.B	D2,\2
	Otra	\7
 	ENDC

	IFC	"7B","\4"		; Ins. INC registros Altos.
	MOVE.B	D3,D1
	\1	#$100,\2
	MOVE.W	CCR,D3
	BFINS	D3,D3{29:1}
	BFINS	D1,D3{31:1}
	Otra	\7
 	ENDC

	IFC	"8","\4"		; Para Ins. destino (HL)
	CogePagE \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"8I","\4"		; Para Ins. destino (HL)
	CogePagE \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	IFD	AMG_BITMAP
	IFC	"N","\5"		; SET/RES: a write; $FFFC-$FFFF reach the mapper
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4
	BCS.S	\@B
	CMP.W	#$FFFC,\2		; HL
	BCS.S	\@B
	JMP	AmgIxMapR15
	ELSE
	CMP.L	#IRAM+$3FFC,A4
	BCS.S	\@B
	JMP	AmgIxMap15		; SET/RES (HL): 15 cycles
	ENDC
\@B:
	ENDC
	ENDC
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"8Y","\4"		; Para Ins. destino (HL) Leer
	CogePag \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"9","\4"		; Para Ins. destino (IX,IY)
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagIE \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	PonCCR	\5,\7			; Recoge Flags.
\@M:	CheckB	D1
	EXT.W	D1
	CogePagIE \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"9I","\4"		; Para Ins.de bits con destino (IX,IY)
	CogePagIE \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	IFD	AMG_BITMAP
	IFC	"N","\5"		; SET/RES: a write; $FFFC-$FFFF reach the mapper
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4
	BCS.S	\@B
	MOVE.B	-2(A5),D1		; DD CB d op
	EXT.W	D1
	ADD.W	\2,D1
	CMP.W	#$FFFC,D1
	BCS.S	\@B
	JMP	AmgIxMapR23
	ELSE
	CMP.L	#IRAM+$3FFC,A4
	BCS.S	\@B
	JMP	AmgIxMap23		; SET/RES (IX/IY+d): 23 cycles
	ENDC
\@B:
	ENDC
	ENDC
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"9Y","\4"		; Para Ins.de bits con destino (IX,IY) Leer
	CogePagI \2,A4
	PONF	\5,\6
	\1	\3,(A4)
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"10","\4"		; Operación de (N) en registro A.
	MOVE.B	(A5)+,D2
	BEQ.S	\@M
	PONF	\5,\6
	\1	D2,\2
	PonCCR	\5,\7			; Recoge Flags.
\@M:	CheckB	D2
	PONF	\5,\6
	\1	D2,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"11","\4"		; (Modo no soportado de "3")
	CogePag	\3,A4			; Registro (HL) con registro A.
	MOVE.B	(A4),D2
	PONF	\5,\6
	\1	D2,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	IFC	"12","\4"		; (Modo no soportado de "4")
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagI \3,A4
	MOVE.B	(A4),D2
	PONF	\5,\6
	\1	D2,\2
	PonCCR	\5,\7			; Recoge Flags.
\@M:	CheckB	D1
	EXT.W	D1
	CogePagI \3,A4
	MOVE.B	(A4),D2
	PONF	\5,\6
	\1	D2,\2
	PonCCR	\5,\7			; Recoge Flags.
	ENDC

	ENDM


; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------


MROT:	MACRO
	IFC	"2","\4"		; Rotación con (HL)
	CogePagE \2,A4
	MOVE.B	(A4),D2
	IFC	"S","\3"
	OR.B	#$10,CCR
	ENDC
	IFC	"X","\3"
	LSR.B	#1,D3
	ENDC
	\1	#1,D2
	MOVE.W	CCR,D3
	MOVE.B	D2,(A4)
	ENDC

	IFC	"2I","\4"		; Rotación con (IX,IY)
	CogePagIE \2,A4
	MOVE.B	(A4),D2
	IFC	"S","\3"
	OR.B	#$10,CCR
	ENDC
	IFC	"X","\3"
	LSR.B	#1,D3
	ENDC
	\1	#1,D2
	MOVE.W	CCR,D3
	MOVE.B	D2,(A4)
	ENDC

	IFC	"0","\4"		; Rotación en registros bajos.
	IFC	"S","\3"
	OR.B	#$10,CCR
	ENDC
	IFC	"X","\3"
	LSR.B	#1,D3
	ENDC
	\1	#1,\2
	MOVE.W	CCR,D3
	ENDC

	IFC	"1","\4"		; Rotación en registros altos.
	ROR.W	#8,\2
	IFC	"S","\3"
	OR.B	#$10,CCR
	ENDC
	IFC	"X","\3"
	LSR.B	#1,D3
	ENDC
	\1	#1,\2
	MOVE.W	CCR,D3
	ROR.W	#8,\2
	ENDC
; ---------------------------
	Otra	\5			; Recoge Flags.
; ---------------------------
	ENDM


; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------


MLDRR:	MACRO

	IFC	"0","\3"	; Mover registros bajos.
	MOVE.B	\2,\1
	Otra	\4
	ENDC


	IFC	"0A","\3"	; Mover de (N) a registro bajo.
	CogePag	\2,A4
	MOVE.B	(A4),\1
	Otra	\4
	ENDC


	IFC	"0B","\3"	; Mover de (N) a registro alto.
	MOVE.B	\1,D2
	CogePag	\2,A4
	MOVE.W	(A4),\1
	MOVE.B	D2,\1
	Otra	\4
	ENDC


	IFC	"1","\3"	; Mover registros altos.
	MOVE.W	\2,D1
	MOVE.B	\1,D1
	MOVE.W	D1,\1
	Otra	\4
	ENDC


	IFC	"2","\3"	; Mover registro bajo a alto de reg. de 16bits.
	MOVE.B	\1,D1
	LSL.W	#8,\2
	MOVE.B	D1,\1
	Otra	\4
	ENDC


	IFC	"3","\3"	; Mover registro alto a bajo de reg. de 16bits.
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,\1
	Otra	\4
	ENDC


	IFC	"4","\3"	; Mover registro bajo a alto.
	BFINS	\2,\1{16:8}
	Otra	\4
	ENDC


	IFC	"5","\3"	; Mover registro alto a bajo.
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,\1
	Otra	\4
	ENDC


	IFC	"6","\3"	; Mover de (IX,IY) a registro bajo.
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagI \2,A4
	MOVE.B	(A4),\1
	Otra	\4
\@M:	CheckB	D1
	EXT.W	D1
	CogePagI \2,A4
	MOVE.B	(A4),\1
	Otra	\4
	ENDC


	IFC	"6B","\3"	; Mover de (IX,IY) a registro alto.
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagI \2,A4
	MOVE.B	\1,D2
	MOVE.W	(A4),\1
	MOVE.B	D2,\1
	Otra	\4
\@M:	CheckB	D1
	EXT.W	D1
	CogePagI \2,A4
	MOVE.B	\1,D2
	MOVE.W	(A4),\1
	MOVE.B	D2,\1
	Otra	\4
	ENDC


	IFC	"7","\3"	; Mover registro alto a registro A.
	MOVE.W	\2,\1
	LSR.W	#8,\1
	Otra	\4
	ENDC


	IFC	"8","\3"	; Mover de (NN) a registros HL,BC,DE.
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),\1
	ROR.W	#8,\1
	Otra	\4
\@M:	CheckW	D1
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),\1
	ROR.W	#8,\1
	Otra	\4
\@D:
	SWAP	D0
	MOVE.W	A4,D1
	MOVE.W	D1,D0
	ADDQ.W	#1,D1
	CogePag D1,A4
	MOVE.W	(A4),\1
	MOVE.W	D0,D1
	CogePag	D1,A4
	MOVE.B	(A4),\1
	SWAP	D0
	Otra	\4
	ENDC


	IFC	"8I","\3"	; Mover de (NN) a registros IX,IY.
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	MOVE.L	D1,\1
	Otra	\4
\@D:
	SWAP	D0
	MOVE.W	A4,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePag D1,A4
	MOVE.W	D0,D1
	MOVE.W	(A4),D0
	CogePag	D1,A4
	MOVE.W	D0,D1
	MOVE.B	(A4),D1
	MOVE.L	D1,\1
	SWAP	D0
	Otra	\4
\@M:	CheckW	D1
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	MOVE.L	D1,\1
	Otra	\4
	ENDC


	IFC	"8S","\3"	; Mover de (NN) a registro SP.
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),D0
	ROR.W	#8,D0
	MOVE.W	D0,D1
	CogePagE D1,\1
	Otra	\4
\@D:
	MOVE.W	A4,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePag D1,A4
	MOVE.W	D0,D1
	MOVE.W	(A4),D0
	CogePag	D1,A4
	MOVE.B	(A4),D0
	MOVE.W	D0,D1
	CogePagE D1,\1
	Otra	\4
\@M:
	CheckW	D1
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.B	#1,D1
	BEQ.S	\@D
	CogePag2 D1,A4
	MOVE.W	(A4),D0
	ROR.W	#8,D0
	MOVE.W	D0,D1
	CogePagE D1,\1
	Otra	\4
	ENDC


	IFC	"9","\3"	; Mover de HL,BC,DE,IX,IY a (NN)
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	D1,A4
	ADDQ.W	#4,D1
	BCS.S	\@LD9F
	SUBQ.W	#4,D1
	CogePagE2 D1,A4
	MOVE.W	\1,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A4)
	Otra	\4
\@LD9F:	SUBQ.W	#4,D1
	CogePagE2 D1,A4
	MOVE.W	\1,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A4)
	JMP	Mapper2
	CNOP	0,4
\@M:	CheckW	D1
	ROR.W	#8,D1
	CogePagE D1,A4
	MOVE.W	\1,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A4)
	Otra	\4
	ENDC


	IFC	"10","\3"	; Mover registros bajos a (HL,DE,BC)
	CogePagE \1,A4
	MOVE.B	\2,(A4)
	Otra	\4
	ENDC


	IFC	"11","\3"	; Mover registros altos a (HL,DE,BC)
	CogePagE \1,A4
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,(A4)
	Otra	\4
	ENDC


	IFC	"10F","\3"	; Mover registros bajos a (HL,DE,BC) con (FFFF)
	CogePagE \1,A4
	MOVE.B	\2,(A4)
	ADDQ.W	#4,\1
	BCS.S	\@LD10F
	SUBQ.W	#4,\1
	Otra	\4
\@LD10F:SUBQ.W	#4,\1
	JMP	Mapper
	CNOP	0,4
	ENDC


	IFC	"11F","\3"	; Mover registros bajos a (HL,DE,BC) con (FFFF)
	CogePagE \1,A4
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,(A4)
	ADDQ.W	#4,\1
	BCS.S	\@LD11F
	SUBQ.W	#4,\1
	Otra	\4
\@LD11F:SUBQ.W	#4,\1
	JMP	Mapper
	CNOP	0,4
	ENDC


	IFC	"12","\3"	; Mover registros bajos a (IX.IY)
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.B	\2,(A4)
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X0
	JMP	AmgIxMapR\4D1\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X0
	JMP	AmgIxMap\4
	ENDC
\@X0:
	ENDC
	Otra	\4
\@M:	CheckB	D1
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.B	\2,(A4)
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X1
	JMP	AmgIxMapR\4D1\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X1
	JMP	AmgIxMap\4
	ENDC
\@X1:
	ENDC
	Otra	\4
	ENDC


	IFC	"13","\3"	; Mover registros altos a (IX.IY)
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,(A4)
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X0
	JMP	AmgIxMapR\4D1\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X0
	JMP	AmgIxMap\4
	ENDC
\@X0:
	ENDC
	Otra	\4
\@M:	CheckB	D1
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.W	\2,D1
	LSR.W	#8,D1
	MOVE.B	D1,(A4)
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X1
	JMP	AmgIxMapR\4D1\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X1
	JMP	AmgIxMap\4
	ENDC
\@X1:
	ENDC
	Otra	\4
	ENDC


	IFC	"12N","\3"	; Mover (N) a (IX.IY)
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.B	(A5)+,(A4)
	BEQ.S	\@M2
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X0
	JMP	AmgIxMapR\4D2\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X0
	JMP	AmgIxMap\4
	ENDC
\@X0:
	ENDC
	Otra	\4
\@M:	CheckB	D1
	EXT.W	D1
	CogePagIE \1,A4
	MOVE.B	(A5)+,(A4)
	BEQ.S	\@M2
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X1
	JMP	AmgIxMapR\4D2\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X1
	JMP	AmgIxMap\4
	ENDC
\@X1:
	ENDC
	Otra	\4
\@M2:	CheckB	(A4)
	IFD	AMG_IXMAP
	IFD	AMG_RAMMIRROR
	CMP.L	#IRAM+$1FFC,A4		; $xFFC-$xFFF: the mapper if $FFFC-$FFFF
	BCS.S	\@X2
	JMP	AmgIxMapR\4D2\1
	ELSE
	CMP.L	#IRAM+$3FFC,A4		; $FFFC-$FFFF: the mapper too
	BCS.S	\@X2
	JMP	AmgIxMap\4
	ENDC
\@X2:
	ENDC
	Otra	\4
	ENDC


	IFC	"14","\3"		; LD.b \1,N  Altos
	MOVE.B	\1,D2
	MOVE.B	(A5)+,\1
	BEQ.S	\@M
	LSL.W	#8,\1
	MOVE.B	D2,\1
	Otra	\4
\@M:	CheckB	\1
	LSL.W	#8,\1
	MOVE.B	D2,\1
	Otra	\4
	ENDC


	IFC	"15","\3"		; LD.b \1,N  Bajos
	MOVE.B	(A5)+,\1
	BEQ.S	\@M
	Otra	\4
\@M:	CheckB	\1
	Otra	\4
	ENDC


	IFC	"16","\3"		; LD.w \1,NN
	MOVE.W	(A5)+,\1
	TST.B	\1
	BEQ.S	\@M
	ROR.W	#8,\1
	Otra	\4
\@M:	CheckW	\1
	ROR.W	#8,\1
	Otra	\4
	ENDC


	IFC	"17I","\3"		; LD.w \1,NN  Indexados
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	D1,\1
	Otra	\4
\@M:	CheckW	D1
	ROR.W	#8,D1
	MOVE.L	D1,\1
	Otra	\4
	ENDC


	IFC	"17S","\3"		; LD.w \1,NN  SP
	MOVE.W	(A5)+,D0
	TST.B	D0
	BEQ.S	\@M
	ROR.W	#8,D0
	MOVE.W	D0,D1
	CogePagE D1,\1
	Otra	\4
\@M:	CheckW	D0
	ROR.W	#8,D0
	MOVE.W	D0,D1
	CogePag	D1,\1
	Otra	\4
	ENDC

	ENDM


; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------


MJR:	MACRO
	MOVE.B	(A5)+,D1
	BEQ.S	\@M
	EXT.W	D1
	ADD.W	D1,A5
	Otra	\1
\@M:	CheckB	D1
	EXT.W	D1
	ADD.W	D1,A5
	Otra	\1
	ENDM

MJRC:	MACRO
	MOVE.W	D3,CCR
	B\1.S	\@
	ADDQ.W	#1,A5
	Otra	\3
\@:	MJR	\2
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MJP:	MACRO
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	\1
\@M:	CheckW	D1
	ROR.W	#8,D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	\1
	ENDM

MJPC:	MACRO
	MOVE.W	D3,CCR
	B\1.S	\@
	ADDQ.W	#2,A5
	Otra	\2
\@:	MJP	\2
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MCALL:	MACRO
	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	\@M
	ROR.W	#8,D1
	MOVE.L	A5,A4
	SUB.W	(A7),A4
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	SUBQ.B	#2,D0
	BCS.S	\@D
	MOVE.W	A4,D1
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	Otra	\1
\@D:
	SUB.W	#$100,D0		; Esta Parte esta dos veces.
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A6
	MOVE.W	A4,D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	MOVE.B	D1,(A6)
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	D2,(A6)
	Otra	\1
\@M:
	CheckW	D1
	ROR.W	#8,D1
	MOVE.L	A5,A4
	SUB.W	(A7),A4
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	SUBQ.B	#2,D0
	BCS.S	\@D2
	MOVE.W	A4,D1
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	Otra	\1
\@D2:
	SUB.W	#$100,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A6
	MOVE.W	A4,D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	MOVE.B	D1,(A6)
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	D2,(A6)
	Otra	\1
	ENDM

MCALLC:	MACRO
	MOVE.W	D3,CCR
	B\1.S	\@
	ADDQ.W	#2,A5
	Otra	\3
\@:	MCALL	\2
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MRST:	MACRO
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	LEA	Restas(A3),A7
	MOVE.L	PagRead(A3),A4
	LEA	\1(A4),A5
	SUBQ.B	#2,D0
	BCS.S	\@D
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	Otra	\2
\@D:
	MOVE.W	D1,A4
	SUB.W	#$100,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A6
	MOVE.W	A4,D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	MOVE.B	D1,(A6)
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	D2,(A6)
	Otra	\2
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MPUSH:	MACRO
	IFC	"AF","\1"
	BFEXTU	D0{23:8},D1
	MOVE.B	ANA(A3),Flags_DAA(A3,D1.W*4)
	ENDC

	SUBQ.B	#2,D0
	BCS.S	\@D
	IFNC	"AF","\1"
	MOVE.W	\1,D1
	ROR.W	#8,D1
	MOVE.W	D1,-(A6)
	Otra	\2
\@D:
	SUB.W	#$100,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A6
	MOVE.W	\1,D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	MOVE.B	D1,(A6)
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	D2,(A6)
	Otra	\2

	ELSEIF
	MOVE.B	D7,-(A6)
	MOVE.B	Flags_Push(A3,D3.W*4),-(A6)
	Otra	\2
\@D:
	SUB.W	#$100,D0
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A6
	MOVE.B	D7,(A6)
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	Flags_Push(A3,D3.W*4),(A6)
	Otra	\2
	ENDC
	ENDM


MPOP:	MACRO
	ADDQ.B	#2,D0
	BCS.S	\@D
	IFC	"0","\2"
	MOVE.W	(A6)+,\1
	ROR.W	#8,\1
	Otra	\3
\@D:	ADD.W	#$100,D0
	MOVE.W	D0,D1
	SUBQ.W	#1,D1
	CogePagE D1,A4
	MOVE.W	(A4),\1
	MOVE.B	(A6),\1
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	\3

	ELSEIF
	IFNC	"AF","\1"
	MOVE.W	(A6)+,D1
	ROR.W	#8,D1
	MOVE.L	D1,\1
	Otra	\3
\@D:
	ADD.W	#$100,D0
	MOVE.W	D0,D1
	SUBQ.W	#1,D1
	CogePagE D1,A4
	MOVE.W	(A4),D1
	MOVE.B	(A6),D1
	MOVE.L	D1,\1
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	\3

	ELSEIF
	MOVE.B	(A6)+,D3
	MOVE.B	(A6)+,D7
	MOVE.B	Flags_Pop(A3,D3.W*4),D3
	BFEXTU	D0{23:8},D1
	MOVE.B	Flags_DAA(A3,D1.W*4),ANA(A3)
	Otra	\3
\@D:	ADD.W	#$100,D0
	MOVE.W	D0,D1
	SUBQ.W	#1,D1
	MOVE.B	(A6),D3
	CogePagE D1,A6
	MOVE.B	(A6),D7
	MOVE.B	Flags_Pop(A3,D3.W*4),D3
	MOVE.W	D0,D1
	CogePagE D1,A6
	BFEXTU	D0{23:8},D1
	MOVE.B	Flags_DAA(A3,D1.W*4),ANA(A3)
	Otra	\3
	ENDC
	ENDC
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MRET:	MACRO
	ADDQ.B	#2,D0
	BCS.S	\@D
	MOVE.W	(A6)+,D1
\@2:	ROR.W	#8,D1
\@3:	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	\1
\@D:
	ADD.W	#$100,D0
	MOVE.W	D0,D1
	SUBQ.W	#1,D1
	CogePagE D1,A4
	MOVE.W	(A4),D1
	MOVE.B	(A6),D1
	MOVE.W	D1,A4
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.W	A4,D1
	BRA.S	\@3
	CNOP	0,4
	ENDM

MRETC:	MACRO
	MOVE.W	D3,CCR
	B\1.S	\@
	Otra	\3
\@:	MRET	\2
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

MINC:	MACRO
	MOVE.B	D5,D2
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D3,D2
	IFC	"1","\2"
	LSL.W	#8,D1
	MOVE.W	CCR,D3
	MOVE.B	\1,D1
	MOVE.W	D1,\1
	ELSEIF
	MOVE.B	D1,\1
	MOVE.W	CCR,D3
	ENDC
	BFINS	D2,D3{31:1}
	Otra	\3
	ENDM


MOUTC:	MACRO
	MOVE.B	D5,D2
	IFC	"1","\2"
	MOVE.W	\1,D1
	LSR.W	#8,D1
	ELSEIF
	MOVE.B	\1,D1
	ENDC
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	\3
	CNOP	0,4
	ENDM

; ---------------------------------------------------------------------
; *********************************************************************
; ---------------------------------------------------------------------

	CNOP	0,4
Bucle:	Otra2

	CNOP	0,4
NADA:	Otra2

; -----------------------  ADD / SUB  ---------------
ADCAA:	PARDAAS
	MIns	ADDX.B,D7,D7,0,T,X,4
ADDAA:	PARDAAS
	MIns	ADD.B,D7,D7,0,T,N,4
ADCAB:	PARDAAS
	MIns	ADDX.B,D7,D5,1,T,X,4
ADDAB:	PARDAAS
	MIns	ADD.B,D7,D5,1,T,N,4
ADCAC:	PARDAAS
	MIns	ADDX.B,D7,D5,0,T,X,4
ADDAC:	PARDAAS
	MIns	ADD.B,D7,D5,0,T,N,4
ADCAD:	PARDAAS
	MIns	ADDX.B,D7,D6,1,T,X,4
ADDAD:	PARDAAS
	MIns	ADD.B,D7,D6,1,T,N,4
ADCAE:	PARDAAS
	MIns	ADDX.B,D7,D6,0,T,X,4
ADDAE:	PARDAAS
	MIns	ADD.B,D7,D6,0,T,N,4
ADCAH:	PARDAAS
	MIns	ADDX.B,D7,D4,1,T,X,4
ADDAH:	PARDAAS
	MIns	ADD.B,D7,D4,1,T,N,4
ADCAL:	PARDAAS
	MIns	ADDX.B,D7,D4,0,T,X,4
ADDAL:	PARDAAS
	MIns	ADD.B,D7,D4,0,T,N,4
ADCAN:	PARDAAS
	MIns	ADDX.B,D7,N,10,T,X,7
ADDAN:	PARDAAS
	MIns	ADD.B,D7,N,10,T,N,7
ADCAHL:	PARDAAS
	MIns	ADDX.B,D7,D4,11,T,X,7
ADDAHL:	PARDAAS
	MIns	ADD.B,D7,D4,3,T,N,7

ADCAIX:	PARDAAS
	MIns	ADDX.B,D7,A0,12,T,X,19
ADDAIX:	PARDAAS
	MIns	ADD.B,D7,A0,4,T,N,19
ADCAIY:	PARDAAS
	MIns	ADDX.B,D7,A1,12,T,X,19
ADDAIY:	PARDAAS
	MIns	ADD.B,D7,A1,4,T,N,19

ADCHLHL:MIns	ADDX.W,D4,D4,2,T,X,15
ADDHLHL:MIns	ADD.W,D4,D4,2,C,N,11
ADCHLBC:MIns	ADDX.W,D4,D5,2,T,X,15
ADDHLBC:MIns	ADD.W,D4,D5,2,C,N,11
ADCHLDE:MIns	ADDX.W,D4,D6,2,T,X,15
ADDHLDE:MIns	ADD.W,D4,D6,2,C,N,11
ADCHLSP:MIns	ADDX.W,D4,D0,2,T,X,15
ADDHLSP:MIns	ADD.W,D4,D0,2,C,N,11

ADDIXIX:MIns	ADD.W,A0,A0,2I,C,N,15
ADDIXBC:MIns	ADD.W,A0,D5,2I,C,N,15
ADDIXDE:MIns	ADD.W,A0,D6,2I,C,N,15
ADDIXSP:MIns	ADD.W,A0,D0,2I,C,N,15

ADDIYIY:MIns	ADD.W,A1,A1,2I,C,N,15
ADDIYBC:MIns	ADD.W,A1,D5,2I,C,N,15
ADDIYDE:MIns	ADD.W,A1,D6,2I,C,N,15
ADDIYSP:MIns	ADD.W,A1,D0,2I,C,N,15

SBCA:	PARDAAR
	MIns	SUBX.B,D7,D7,0,T,X,4
SUBA:	PARDAAR
	MIns	SUB.B,D7,D7,0,T,N,4
SBCB:	PARDAAR
	MIns	SUBX.B,D7,D5,1,T,X,4
SUBB:	PARDAAR
	MIns	SUB.B,D7,D5,1,T,N,4
SBCC:	PARDAAR
	MIns	SUBX.B,D7,D5,0,T,X,4
SUBC:	PARDAAR
	MIns	SUB.B,D7,D5,0,T,N,4
SBCD:	PARDAAR
	MIns	SUBX.B,D7,D6,1,T,X,4
SUBD:	PARDAAR
	MIns	SUB.B,D7,D6,1,T,N,4
SBCE:	PARDAAR
	MIns	SUBX.B,D7,D6,0,T,X,4
SUBE:	PARDAAR
	MIns	SUB.B,D7,D6,0,T,N,4
SBCH:	PARDAAR
	MIns	SUBX.B,D7,D4,1,T,X,4
SUBH:	PARDAAR
	MIns	SUB.B,D7,D4,1,T,N,4
SBCL:	PARDAAR
	MIns	SUBX.B,D7,D4,0,T,X,4
SUBL:	PARDAAR
	MIns	SUB.B,D7,D4,0,T,N,4
SBCN:	PARDAAR
	MIns	SUBX.B,D7,N,10,T,X,7
SUBN:	PARDAAR
	MIns	SUB.B,D7,N,10,T,N,7
SBCHL:	PARDAAR
	MIns	SUBX.B,D7,D4,11,T,X,7
SUBHL:	PARDAAR
	MIns	SUB.B,D7,D4,3,T,N,7

SBCIX:	PARDAAR
	MIns	SUBX.B,D7,A0,12,T,X,19
SUBIX:	PARDAAR
	MIns	SUB.B,D7,A0,4,T,N,19
SBCIY:	PARDAAR
	MIns	SUBX.B,D7,A1,12,T,X,19
SUBIY:	PARDAAR
	MIns	SUB.B,D7,A1,4,T,N,19

SBCHLHL:MIns	SUBX.W,D4,D4,2,T,X,15
SBCHLBC:MIns	SUBX.W,D4,D5,2,T,X,15
SBCHLDE:MIns	SUBX.W,D4,D6,2,T,X,15
SBCHLSP:MIns	SUBX.W,D4,D0,2,T,X,15

; -------------------  INC / DEC  ---------------

INCA:	PARDAAS
	MIns	ADDQ.B,D7,#1,0,S,N,4
INCH:	MIns	ADDI.W,D4,#0,7B,S,N,4
INCL:	MIns	ADDQ.B,D4,#1,0,S,N,4
INCB:	MIns	ADDI.W,D5,#0,7B,S,N,4
INCC:	MIns	ADDQ.B,D5,#1,0,S,N,4
INCD:	MIns	ADDI.W,D6,#0,7B,S,N,4
INCE:	MIns	ADDQ.B,D6,#1,0,S,N,4

INCHLM:	MIns	ADDQ.B,D4,#1,8,S,N,11
INCIXM:	MIns	ADDQ.B,A0,#1,9,S,N,23
INCIYM:	MIns	ADDQ.B,A1,#1,9,S,N,23

INCHL:	MIns	ADDQ.W,D4,#1,2,N,N,6
INCBC:	MIns	ADDQ.W,D5,#1,2,N,N,6
INCDE:	MIns	ADDQ.W,D6,#1,2,N,N,6
INCIX:	MIns	ADDQ.W,A0,#1,2,N,N,10
INCIY:	MIns	ADDQ.W,A1,#1,2,N,N,10
INCSP:
	ADDQ.W	#1,D0
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	6


DECA:	PARDAAR
	MIns	SUBQ.B,D7,#1,0,S,N,4
DECH:	MIns	SUB.W,D4,#0,7,S,N,4
DECL:	MIns	SUBQ.B,D4,#1,0,S,N,4
DECB:	MIns	SUB.W,D5,#0,7,S,N,4
DECC:	MIns	SUBQ.B,D5,#1,0,S,N,4
DECD:	MIns	SUB.W,D6,#0,7,S,N,4
DECE:	MIns	SUBQ.B,D6,#1,0,S,N,4

DECHLM:	MIns	SUBQ.B,D4,#1,8,S,N,11
DECIXM:	MIns	SUBQ.B,A0,#1,9,S,N,23
DECIYM:	MIns	SUBQ.B,A1,#1,9,S,N,23

DECHL:	MIns	SUBQ.W,D4,#1,2,N,N,6
DECBC:	MIns	SUBQ.W,D5,#1,2,N,N,6
DECDE:	MIns	SUBQ.W,D6,#1,2,N,N,6
DECIX:	MIns	SUBQ.W,A0,#1,2,N,N,10
DECIY:	MIns	SUBQ.W,A1,#1,2,N,N,10
DECSP:
	SUBQ.W	#1,D0
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	6

; -----------------------  AND  ---------------

ANDA:	MIns	AND.B,D7,D7,0,P,N,4
ANDH:	MIns	AND.B,D7,D4,1,P,N,4
ANDL:	MIns	AND.B,D7,D4,0,P,N,4
ANDB:	MIns	AND.B,D7,D5,1,P,N,4
ANDC:	MIns	AND.B,D7,D5,0,P,N,4
ANDD:	MIns	AND.B,D7,D6,1,P,N,4
ANDE:	MIns	AND.B,D7,D6,0,P,N,4
ANDN:	MIns	AND.B,D7,N,10,P,N,7

ANDHL:	MIns	AND.B,D7,D4,3,P,N,7
ANDIX:	MIns	AND.B,D7,A0,4,P,N,19
ANDIY:	MIns	AND.B,D7,A1,4,P,N,19

; -----------------------  OR  ---------------

ORA:	MIns	OR.B,D7,D7,0,P,N,4
ORH:	MIns	OR.B,D7,D4,1,P,N,4
ORL:	MIns	OR.B,D7,D4,0,P,N,4
ORB:	MIns	OR.B,D7,D5,1,P,N,4
ORC:	MIns	OR.B,D7,D5,0,P,N,4
ORD:	MIns	OR.B,D7,D6,1,P,N,4
ORE:	MIns	OR.B,D7,D6,0,P,N,4
ORN:	MIns	OR.B,D7,N,10,P,N,7

ORHL:	MIns	OR.B,D7,D4,3,P,N,7
ORIX:	MIns	OR.B,D7,A0,4,P,N,19
ORIY:	MIns	OR.B,D7,A1,4,P,N,19

; -----------------------  CP  ---------------

CPA:	MIns	CMP.B,D7,D7,0,T,N,4
CPH:	MIns	CMP.B,D7,D4,1,T,N,4
CPL:	MIns	CMP.B,D7,D4,0,T,N,4
CPB:	MIns	CMP.B,D7,D5,1,T,N,4
CPC:	MIns	CMP.B,D7,D5,0,T,N,4
CPD:	MIns	CMP.B,D7,D6,1,T,N,4
CPE:	MIns	CMP.B,D7,D6,0,T,N,4
CPN:	MIns	CMP.B,D7,N,10,T,N,7

CPHL:	MIns	CMP.B,D7,D4,3,T,N,7
CPIX:	MIns	CMP.B,D7,A0,4,T,N,19
CPIY:	MIns	CMP.B,D7,A1,4,T,N,19

; -----------------------  XOR  ---------------

XORA:	MIns	EOR.B,D7,D7,0,P,N,4
XORH:	MIns	EOR.B,D7,D4,1,P,N,4
XORL:	MIns	EOR.B,D7,D4,0,P,N,4
XORB:	MIns	EOR.B,D7,D5,1,P,N,4
XORC:	MIns	EOR.B,D7,D5,0,P,N,4
XORD:	MIns	EOR.B,D7,D6,1,P,N,4
XORE:	MIns	EOR.B,D7,D6,0,P,N,4
XORN:	MIns	EOR.B,D7,N,10,P,N,7

XORHL:	MIns	EOR.B,D7,D4,11,P,N,7
XORIX:	MIns	EOR.B,D7,A0,12,P,N,19
XORIY:	MIns	EOR.B,D7,A1,12,P,N,19

; ---------------------  LD  ---------------------

LDBB:	Otra	4
LDBC:	MLDRR	D5,D5,2,4
LDBD:	MLDRR	D5,D6,1,4
LDBE:	MLDRR	D5,D6,4,4
LDBH:	MLDRR	D5,D4,1,4
LDBL:	MLDRR	D5,D4,4,4
LDBHL:	MLDRR	D5,D4,0B,7
LDBIX:	MLDRR	D5,A0,6B,19
LDBIY:	MLDRR	D5,A1,6B,19
LDBA:	MLDRR	D5,D7,4,4
; ---------------------	; $48 ; ---------------- ;
LDCB:	MLDRR	D5,D5,3,4
LDCC:	Otra	4
LDCD:	MLDRR	D5,D6,5,4
LDCE:	MLDRR	D5,D6,0,4
LDCH:	MLDRR	D5,D4,5,4
LDCL:	MLDRR	D5,D4,0,4
LDCHL:	MLDRR	D5,D4,0A,7
LDCIX:	MLDRR	D5,A0,6,19
LDCIY:	MLDRR	D5,A1,6,19
LDCA:	MLDRR	D5,D7,0,4
; ---------------------	; $50 ; ---------------- ;
LDDB:	MLDRR	D6,D5,1,4
LDDC:	MLDRR	D6,D5,4,4
LDDD:	Otra	4
LDDE:	MLDRR	D6,D6,2,4
LDDH:	MLDRR	D6,D4,1,4
LDDL:	MLDRR	D6,D4,4,4
LDDHL:	MLDRR	D6,D4,0B,7
LDDIX:	MLDRR	D6,A0,6B,19
LDDIY:	MLDRR	D6,A1,6B,19
LDDA:	MLDRR	D6,D7,4,4
; ---------------------	; $58 ; ---------------- ;
LDEB:	MLDRR	D6,D5,5,4
LDEC:	MLDRR	D6,D5,0,4
LDED:	MLDRR	D6,D6,3,4
LDEE:	Otra	4
LDEH:	MLDRR	D6,D4,5,4
LDEL:	MLDRR	D6,D4,0,4
LDEHL:	MLDRR	D6,D4,0A,7
LDEIX:	MLDRR	D6,A0,6,19
LDEIY:	MLDRR	D6,A1,6,19
LDEA:	MLDRR	D6,D7,0,4
; ---------------------	; $60 ; ---------------- ;
LDHB:	MLDRR	D4,D5,1,4
LDHC:	MLDRR	D4,D5,4,4
LDHD:	MLDRR	D4,D6,1,4
LDHE:	MLDRR	D4,D6,4,4
LDHH:	Otra	4
LDHL:	MLDRR	D4,D4,2,4
LDHHL:	MLDRR	D4,D4,0B,7
LDHIX:	MLDRR	D4,A0,6B,19
LDHIY:	MLDRR	D4,A1,6B,19
LDHA:	MLDRR	D4,D7,4,4
; ---------------------	; $68 ; ---------------- ;
LDLB:	MLDRR	D4,D5,5,4
LDLC:	MLDRR	D4,D5,0,4
LDLD:	MLDRR	D4,D6,5,4
LDLE:	MLDRR	D4,D6,0,4
LDLH:	MLDRR	D4,D4,3,4
LDLL:	Otra	4
LDLHL:	MLDRR	D4,D4,0A,7
LDLIX:	MLDRR	D4,A0,6,19
LDLIY:	MLDRR	D4,A1,6,19
LDLA:	MLDRR	D4,D7,0,4
; ---------------------	; $70 ; ---------------- ;

	IFNE	FFFF_ON
LDHLB:	MLDRR	D4,D5,11,7
LDHLC:	MLDRR	D4,D5,10,7
LDHLD:	MLDRR	D4,D6,11,7
LDHLE:	MLDRR	D4,D6,10,7
LDHLH:	MLDRR	D4,D4,11,7
LDHLL:	MLDRR	D4,D4,10,7
	ELSEIF
LDHLB:	MLDRR	D4,D5,11F,7
LDHLC:	MLDRR	D4,D5,10F,7
LDHLD:	MLDRR	D4,D6,11F,7
LDHLE:	MLDRR	D4,D6,10F,7
LDHLH:	MLDRR	D4,D4,11F,7
LDHLL:	MLDRR	D4,D4,10F,7
	ENDC


HALT:
	ST	HaltDat(A3)
	CLR.W	(A3)			; * Resta Cycles *
	JMP	MiraInter
	CNOP	0,4


	IFNE	FFFF_ON

LDHLMN:	CogePagE D4,A4
	MOVE.B	(A5)+,(A4)
	BEQ.S	LDHLMN0
	Otra	10
LDHLMN0:CheckB	(A4)
	Otra	10

LDHLA:	MLDRR	D4,D7,10,7
LDBCA:	MLDRR	D5,D7,10,7
LDDEA:	MLDRR	D6,D7,10,7

	ELSEIF

LDHLMN:	CogePagE D4,A4
	MOVE.B	(A5)+,(A4)
	BEQ.S	LDHLMN0
	ADDQ.W	#4,D4
	BCS.S	LDHLMNF
	SUBQ.W	#4,D4
	Otra	10
LDHLMNF:SUBQ.W	#4,D4
	JMP	Mapper
LDHLMN0:CheckB	(A4)
	ADDQ.W	#4,D4
	BCS.S	LDHLMNF
	SUBQ.W	#4,D4
	Otra	10

LDHLA:	MLDRR	D4,D7,10F,7
LDBCA:	MLDRR	D5,D7,10F,7
LDDEA:	MLDRR	D6,D7,10F,7

	ENDC

; ---------------------	; $70 ; ---------------- ;
LDIXB:	MLDRR	A0,D5,13,19
LDIXC:	MLDRR	A0,D5,12,19
LDIXD:	MLDRR	A0,D6,13,19
LDIXE:	MLDRR	A0,D6,12,19
LDIXH:	MLDRR	A0,D4,13,19
LDIXL:	MLDRR	A0,D4,12,19
LDIXA:	MLDRR	A0,D7,12,19
LDIXMN:	MLDRR	A0,MN,12N,19
; ---------------------	; $70 ; ---------------- ;
LDIYB:	MLDRR	A1,D5,13,19
LDIYC:	MLDRR	A1,D5,12,19
LDIYD:	MLDRR	A1,D6,13,19
LDIYE:	MLDRR	A1,D6,12,19
LDIYH:	MLDRR	A1,D4,13,19
LDIYL:	MLDRR	A1,D4,12,19
LDIYA:	MLDRR	A1,D7,12,19
LDIYMN:	MLDRR	A1,MN,12N,19
; ---------------------	; $78 ; ---------------- ;
LDSPHL:	MOVE.L	D4,D0
	CogePagE D0,A6
	Otra	6
LDSPIX:
	MOVE.W	A0,D0
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	10
LDSPIY:
	MOVE.W	A1,D0
	MOVE.W	D0,D1
	CogePagE D1,A6
	Otra	10
; ---------------------	; $78 ; ---------------- ;
LDAB:	MLDRR	D7,D5,7,4
LDAC:	MLDRR	D7,D5,0,4
LDAD:	MLDRR	D7,D6,7,4
LDAE:	MLDRR	D7,D6,0,4
LDAH:	MLDRR	D7,D4,7,4
LDAL:	MLDRR	D7,D4,0,4
LDAHL:	MLDRR	D7,D4,0A,7
LDABC:	MLDRR	D7,D5,0A,7
LDADE:	MLDRR	D7,D6,0A,7
LDAIX:	MLDRR	D7,A0,6,19
LDAIY:	MLDRR	D7,A1,6,19
LDAA:	Otra	4

LDAM:	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	LDAMM
	ROR.W	#8,D1
	CogePag	D1,A4
	MOVE.B	(A4),D7
	Otra	13
LDAMM:	CheckW	D1
	ROR.W	#8,D1
	CogePag	D1,A4
	MOVE.B	(A4),D7
	Otra	13

LDAI:
	MOVE.B	D3,D1
	MOVE.B	I(A3),D7
	MOVE.W	CCR,D3
	BFINS	D1,D3{31:1}
	MOVE.B	IFF(A3),D1
	BFINS	D1,D3{30:1}
	Otra	9
LDAR:
	MOVE.B	D3,D1
	MOVE.B	$DFF007,D7
	AND.B	#$7F,D7
	OR.B	R(A3),D7
	MOVE.W	CCR,D3
	BFINS	D1,D3{31:1}
	MOVE.B	IFF(A3),D1
	BFINS	D1,D3{30:1}
	Otra	9
; ---------------------------------------------- ;
LDIA:	MOVE.B	D7,I(A3)
	Otra	9
LDRA:
	MOVE.B	D7,R(A3)
	AND.B	#$80,R(A3)
	Otra	9
; ---------------------	; $78 ; ---------------- ;
LDHLM:	MLDRR	D4,M,8,16
LDBCM:	MLDRR	D5,M,8,20
LDDEM:	MLDRR	D6,M,8,20
LDIXM:	MLDRR	A0,M,8I,20
LDIYM:	MLDRR	A1,M,8I,20
LDSPM:	MLDRR	A6,M,8S,20


	IFNE	FFFF_ON
LDMA:	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	LDMAM
	ROR.W	#8,D1
	CogePagE D1,A4
	MOVE.B	D7,(A4)
	Otra	13
LDMAM:	CheckW	D1
	ROR.W	#8,D1
	CogePagE D1,A4
	MOVE.B	D7,(A4)
	Otra	13

	ELSEIF

LDMA:	MOVE.W	(A5)+,D1
	TST.B	D1
	BEQ.S	LDMAM
	ROR.W	#8,D1
	ADDQ.W	#4,D1
	BCS.S	LDMAF
	SUBQ.W	#4,D1
	CogePagE D1,A4
	MOVE.B	D7,(A4)
	Otra	13
LDMAF:
	SUBQ.W	#4,D1
	CogePagE D1,A4
	MOVE.B	D7,(A4)
	JMP	Mapper
	CNOP	0,4
LDMAM:	CheckW	D1
	ROR.W	#8,D1
	ADDQ.W	#4,D1
	BCS.S	LDMAF
	SUBQ.W	#4,D1
	CogePagE D1,A4
	MOVE.B	D7,(A4)
	Otra	13
	ENDC


LDMHL:	MLDRR	D4,M,9,16
LDMBC:	MLDRR	D5,M,9,20
LDMDE:	MLDRR	D6,M,9,20
LDMIX:	MLDRR	A0,M,9,20
LDMIY:	MLDRR	A1,M,9,20
LDMSP:	MLDRR	D0,M,9,20

LDAN:	MLDRR	D7,N,15,7
LDHN:	MLDRR	D4,N,14,7
LDLN:	MLDRR	D4,N,15,7
LDBN:	MLDRR	D5,N,14,7
LDCN:	MLDRR	D5,N,15,7
LDDN:	MLDRR	D6,N,14,7
LDEN:	MLDRR	D6,N,15,7

LDHLN:	MLDRR	D4,N,16,10
LDBCN:	MLDRR	D5,N,16,10
LDDEN:	MLDRR	D6,N,16,10
LDIXN:	MLDRR	A0,N,17I,14
LDIYN:	MLDRR	A1,N,17I,14
LDSPN:	MLDRR	A6,N,17S,10



; -----------------------   InsCB   ---------------

	CNOP	0,4
RLCB0:
	CMP.L	Desbor+4(A7),A5
	BLE.S	RLCB
	MOVE.B	D1,D2
	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,D2
	JMP	([InsCB-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4

MInsCB2:MACRO
\1B:	MROT	\2.B,D5,\3,1,8
\1C:	MROT	\2.B,D5,\3,0,8
\1D:	MROT	\2.B,D6,\3,1,8
\1E:	MROT	\2.B,D6,\3,0,8
\1H:	MROT	\2.B,D4,\3,1,8
\1L:	MROT	\2.B,D4,\3,0,8
\1HL:	MROT	\2.B,D4,\3,2,15
\1A:	MROT	\2.B,D7,\3,0,8
\1IX:	MROT	\2.B,A0,\3,2I,23
\1IY:	MROT	\2.B,A1,\3,2I,23
	ENDM

	MInsCB2	RLC,ROL,N	; CB  0 0xxx
	MInsCB2	RRC,ROR,N	; CB  0 1xxx
	MInsCB2	RL,ROXL,X	; CB  1 0xxx
	MInsCB2	RR,ROXR,X	; CB  1 1xxx
	MInsCB2	SLA,ASL,N	; CB  2 0xxx
	MInsCB2	SRA,ASR,N	; CB  2 1xxx
	MInsCB2	SRR,ROXL,S	; CB  3 0xxx
	MInsCB2	SRL,LSR,N	; CB  3 1xxx

MInsCB:	MACRO
\5\2A:	MIns	\1,D7,#\2,0B,\3,N,8
\5\2H:	MIns	\1,D4,#\2+8,0B,\3,N,8
\5\2L:	MIns	\1,D4,#\2,0B,\3,N,8
\5\2B:	MIns	\1,D5,#\2+8,0B,\3,N,8
\5\2C:	MIns	\1,D5,#\2,0B,\3,N,8
\5\2D:	MIns	\1,D6,#\2+8,0B,\3,N,8
\5\2E:	MIns	\1,D6,#\2,0B,\3,N,8
\5\2HL:	MIns	\1,D4,#\2,8\4,\3,N,12+\6
\5\2IX:	MIns	\1,A0,#\2,9\4,\3,N,20+\6
\5\2IY:	MIns	\1,A1,#\2,9\4,\3,N,20+\6
	ENDM

	MInsCB	BTST,0,Z,Y,BIT,0	; CB  4 0xxx
	MInsCB	BTST,1,Z,Y,BIT,0	; CB  4 1xxx
	MInsCB	BTST,2,Z,Y,BIT,0	; CB  5 0xxx
	MInsCB	BTST,3,Z,Y,BIT,0	; CB  5 1xxx
	MInsCB	BTST,4,Z,Y,BIT,0	; CB  6 0xxx
	MInsCB	BTST,5,Z,Y,BIT,0	; CB  6 1xxx
	MInsCB	BTST,6,Z,Y,BIT,0	; CB  7 0xxx
	MInsCB	BTST,7,Z,Y,BIT,0	; CB  7 1xxx

	MInsCB	BCLR,0,N,I,RES,3	; CB  8 0xxx
	MInsCB	BCLR,1,N,I,RES,3	; CB  8 1xxx
	MInsCB	BCLR,2,N,I,RES,3	; CB  9 0xxx
	MInsCB	BCLR,3,N,I,RES,3	; CB  9 1xxx
	MInsCB	BCLR,4,N,I,RES,3	; CB  A 0xxx
	MInsCB	BCLR,5,N,I,RES,3	; CB  A 1xxx
	MInsCB	BCLR,6,N,I,RES,3	; CB  B 0xxx
	MInsCB	BCLR,7,N,I,RES,3	; CB  B 1xxx

	MInsCB	BSET,0,N,I,SET,3	; CB  C 0xxx
	MInsCB	BSET,1,N,I,SET,3	; CB  C 1xxx
	MInsCB	BSET,2,N,I,SET,3	; CB  D 0xxx
	MInsCB	BSET,3,N,I,SET,3	; CB  D 1xxx
	MInsCB	BSET,4,N,I,SET,3	; CB  E 0xxx
	MInsCB	BSET,5,N,I,SET,3	; CB  E 1xxx
	MInsCB	BSET,6,N,I,SET,3	; CB  F 0xxx
	MInsCB	BSET,7,N,I,SET,3	; CB  F 1xxx

; -----------------------  FIN InsCB ---------------

NOP:
	CMP2.L	Desbor(A7),A5
	BCS.S	DESNOP
	Otra	4
DESNOP:
	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	4
NOP060:
	CMP.L	Desbor+4(A7),A5
	BGT.S	DESNOP
	CMP.L	Desbor(A7),A5
	BLT.S	DESNOP
	Otra	4


DAA:
	MOVE.B	ANA(A3),D2
	BEQ	MIRAC
	SF	ANA(A3)
CONTD:
	SUB.B	D2,D7
	BCS.S	RESTA
	MOVE.W	D3,CCR
	BCS.S	RESTAB
SUMA:
	MOVE.W	#04,CCR
	ABCD.B	D2,D7
	OtraT	4
RESTA:
	MOVE.W	D3,CCR
	BCS.S	SUMA
RESTAB:
	NEG.B	D7
	MOVE.B	D2,D1
	MOVE.B	D7,D2
	MOVE.B	D1,D7
	MOVE.W	#04,CCR
	SBCD.B	D2,D7
	OtraT	4
MIRAC:
	MOVE.W	D3,CCR
	BCC	CONTD
	MOVE.B	D7,D2
	NEG.B	D2
	SF	D7
	MOVE.W	#04,CCR
	SBCD.B	D2,D7
	OtraT	4

SCF:	BSET	#0,D3
	Otra	4
CCF:	BCHG	#0,D3
	Otra	4

ICPL:	NOT.B	D7
	Otra	4

NEG:	NEG.B	D7
	BEQ.S	ERA0
	MOVE.W	CCR,D3
	AND.B	#$7E,D3
	OR.B	#$02,D3
	Otra	8
ERA0:	MOVE.W	CCR,D3
	AND.B	#$7D,D3
	OR.B	#$01,D3
	Otra	8

IRLA:	LSR.B	#1,D3
	ROXL.B	#1,D7
	ROXL.B	#1,D3
	Otra	4
IRRA:	LSR.B	#1,D3
	ROXR.B	#1,D7
	ROXL.B	#1,D3
	Otra	4
IRLCA:	ROL.B	#1,D7
	OtraC2	4
IRRCA:	ROR.B	#1,D7
	OtraC2	4


DI:	SF	IFF(A3)
	Otra	4

EI:
	ST	IFF(A3)

	TST.B	PetIntMG(A3)
	BEQ.S	EICon

	ADDQ.W	#1,A5

	BTST	#6,Estado(A3)		; Interrupción Horizontal
	BNE	InterHorEI

	SUBQ.W	#1,A5

;	BTST	#7,Estado(A3)		; Interrupción Vertical
;	BNE	InterVerEI

EICon:

	OtraEI	4


EXAF:	SWAP	D7
	SWAP	D3
	Otra	4
EXX:	MOVE.W	PEXX(A3),D1
	MOVE.W	D4,PEXX(A3)
	MOVE.W	D1,D4
	MOVE.W	PEXX+2(A3),D1
	MOVE.W	D5,PEXX+2(A3)
	MOVE.W	D1,D5
	MOVE.W	PEXX+4(A3),D1
	MOVE.W	D6,PEXX+4(A3)
	MOVE.W	D1,D6
	Otra	4
EXSPHL:	MOVE.W	(A6),D1
	ROR.W	#8,D1
	EXG.L	D4,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A6)
	Otra	4
EXDEHL:	EXG.L	D6,D4
	Otra	4
EXSPMIX:MOVE.W	(A6),D1
	ROR.W	#8,D1
	EXG.L	A0,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D1
	Otra	23
EXSPMIY:MOVE.W	(A6),D1
	ROR.W	#8,D1
	EXG.L	A1,D1
	ROR.W	#8,D1
	MOVE.W	D1,(A6)
	MOVEQ	#0,D1
	Otra	23

DJNZ:	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	NODJNZ
	MOVE.B	D2,D5
	MJR	13
NODJNZ:	MOVE.B	D2,D5
	ADDQ.W	#1,A5
	Otra	8

JR:	MJR	12
JRNZ:	MJRC	NE,12,7
JRZ:	MJRC	EQ,12,7
JRNC:	MJRC	CC,12,7
JRC:	MJRC	CS,12,7

JP:	MJP	10
JPNZ:	MJPC	NE,10
JPZ:	MJPC	EQ,10
JPNC:	MJPC	CC,10
JPC:	MJPC	CS,10
JPP:	MJPC	PL,10
JPM:	MJPC	MI,10
JPPO:	MJPC	VC,10
JPPE:	MJPC	VS,10

JPHL:
	MOVE.W	D4,D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	4
JPIX:
	MOVE.W	A0,D1
	CogePag D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	8
JPIY:
	MOVE.W	A1,D1
	CogePag D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra	8

CALL:	MCALL	17
CALLNZ:	MCALLC	NE,17,10
CALLZ:	MCALLC	EQ,17,10
CALLNC:	MCALLC	CC,17,10
CALLC:	MCALLC	CS,17,10
CALLP:	MCALLC	PL,17,10
CALLM:	MCALLC	MI,17,10
CALLPO:	MCALLC	VC,17,10
CALLPE:	MCALLC	VS,17,10

IRET:	MRET	10
RETNZ:	MRETC	NE,11,5
RETZ:	MRETC	EQ,11,5
RETNC:	MRETC	CC,11,5
RETC:	MRETC	CS,11,5
RETP:	MRETC	PL,11,5
RETM:	MRETC	MI,11,5
RETPO:	MRETC	VC,11,5
RETPE:	MRETC	VS,11,5

RETN:	MOVE.B	IFF0(A3),IFF(A3)
	MRET	14

RETI:	ST	IFF(A3)
	MRET	14


RST0:	MRST	$00,11
RST8:	MRST	$08,11
RST10:	MRST	$10,11
RST18:	MRST	$18,11
RST20:	MRST	$20,11
RST28:	MRST	$28,11
RST30:	MRST	$30,11
RST38:	MRST	$38,11

PUSHAF:	MPUSH	AF,11
PUSHHL:	MPUSH	D4,11
PUSHBC:	MPUSH	D5,11
PUSHDE:	MPUSH	D6,11
PUSHIX:	MPUSH	A0,15
PUSHIY:	MPUSH	A1,15

POPAF:	MPOP	AF,1,10
POPHL:	MPOP	D4,0,10
POPBC:	MPOP	D5,0,10
POPDE:	MPOP	D6,0,10
POPIX:	MPOP	A0,1,14
POPIY:	MPOP	A1,1,14


INBC:	MINC	D5,1,12
IINCC:	MINC	D5,0,12
INDC:	MINC	D6,1,12
INEC:	MINC	D6,0,12
INHC:	MINC	D4,1,12
INLC:	MINC	D4,0,12
INAC:	MINC	D7,0,12
INAN:	MOVE.B	(A5)+,D2
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D1,D7
	Otra	11

OUTCB:	MOUTC	D5,1,12
OUTCC:	MOUTC	D5,0,12
OUTCD:	MOUTC	D6,1,12
OUTCE:	MOUTC	D6,0,12
OUTCH:	MOUTC	D4,1,12
OUTCL:	MOUTC	D4,0,12
OUTCA:	MOUTC	D7,0,12
OUTNA:	MOVE.B	(A5)+,D2
	MOVE.B	D7,D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	11


IM0:	MOVE.B	#$7F,ModoInt(A3)
	Otra	8
IM1:	SF	ModoInt(A3)
	Otra	8
IM2:	ST	ModoInt(A3)
	Otra	8


;	-----------------------
;	Instrucciones Secretas.
;	-----------------------
INCHX:
	MOVE.W	A0,D1
	ROR.W	#8,D1
	MOVE.B	D3,D2
	ADDQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
INCLX:
	MOVE.W	A0,D1
	MOVE.B	D3,D2
	ADDQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	MOVE.L	D1,A0
	Otra	9
DECHX:
	MOVE.W	A0,D1
	ROR.W	#8,D1
	MOVE.B	D3,D2
	SUBQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
DECLX:
	MOVE.W	A0,D1
	MOVE.B	D3,D2
	SUBQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	MOVE.L	D1,A0
	Otra	9
LDHXN:
	MOVE.W	A0,D1
	LSL.W	#8,D1
	MOVE.B	(A5)+,D1
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
LDLXN:
	MOVE.W	A0,D1
	MOVE.B	(A5)+,D1
	MOVE.L	D1,A0
	Otra	9
LDAHX:
	MOVE.W	A0,D7
	LSR.W	#8,D7
	Otra	9
LDALX:
	MOVE.W	A0,D1
	MOVE.B	D1,D7
	Otra	9
LDLHX:
	MOVE.W	A0,D1
	LSR.W	#8,D1
	MOVE.B	D1,D4
	Otra	9
LDLLX:
	MOVE.W	A0,D1
	MOVE.B	D1,D4
	Otra	9
LDCHX:
	MOVE.W	A0,D1
	LSR.W	#8,D1
	MOVE.B	D1,D5
	Otra	9
LDCLX:
	MOVE.W	A0,D1
	MOVE.B	D1,D5
	Otra	9
LDEHX:
	MOVE.W	A0,D1
	LSR.W	#8,D1
	MOVE.B	D1,D6
	Otra	9
LDELX:
	MOVE.W	A0,D1
	MOVE.B	D1,D6
	Otra	9
LDHHX:
	MOVE.W	A0,D1
	MOVE.B	D4,D1
	MOVE.W	D1,D4
	Otra	9
LDHLX:
	MOVE.W	A0,D1
	LSL.W	#8,D1
	MOVE.B	D4,D1
	MOVE.W	D1,D4
	Otra	9
LDBHX:
	MOVE.W	A0,D1
	MOVE.B	D5,D1
	MOVE.W	D1,D5
	Otra	9
LDBLX:
	MOVE.W	A0,D1
	LSL.W	#8,D1
	MOVE.B	D5,D1
	MOVE.W	D1,D5
	Otra	9
LDDHX:
	MOVE.W	A0,D1
	MOVE.B	D6,D1
	MOVE.W	D1,D6
	Otra	9
LDDLX:
	MOVE.W	A0,D1
	LSL.W	#8,D1
	MOVE.B	D6,D1
	MOVE.W	D1,D6
	Otra	9
LDLXA:
	MOVE.W	A0,D1
	MOVE.B	D7,D1
	MOVE.L	D1,A0
	Otra	9
LDLXC:
	MOVE.W	A0,D1
	MOVE.B	D5,D1
	MOVE.L	D1,A0
	Otra	9
LDLXE:
	MOVE.W	A0,D1
	MOVE.B	D6,D1
	MOVE.L	D1,A0
	Otra	9
LDLXL:
	MOVE.W	A0,D1
	MOVE.B	D4,D1
	MOVE.L	D1,A0
	Otra	9
LDLXB:
	MOVE.W	A0,D1
	ROR.W	#8,D5
	MOVE.B	D5,D1
	ROR.W	#8,D5
	MOVE.L	D1,A0
	Otra	9
LDLXD:
	MOVE.W	A0,D1
	ROR.W	#8,D6
	MOVE.B	D6,D1
	ROR.W	#8,D6
	MOVE.L	D1,A0
	Otra	9
LDLXH:
	MOVE.W	A0,D1
	LSR.W	#8,D1
	MOVE.B	D1,D2
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A0
	Otra	9
LDHXL:
	MOVE.W	A0,D1
	MOVE.B	D1,D2
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A0
	Otra	9
LDHXA:
	MOVE.W	A0,D1
	ROR.W	#8,D1
	MOVE.B	D7,D1
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
LDHXC:
	MOVE.W	A0,D1
	ROR.W	#8,D1
	MOVE.B	D5,D1
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
LDHXE:
	MOVE.W	A0,D1
	ROR.W	#8,D1
	MOVE.B	D6,D1
	ROR.W	#8,D1
	MOVE.L	D1,A0
	Otra	9
LDHXB:
	MOVE.W	A0,D1
	MOVE.B	D1,D2
	MOVE.W	D5,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A0
	Otra	9
LDHXD:
	MOVE.W	A0,D1
	MOVE.B	D1,D2
	MOVE.W	D6,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A0
	Otra	9
LDHXH:
	MOVE.W	A0,D1
	MOVE.B	D1,D2
	MOVE.W	D4,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A0
	Otra	9

ADCAHX:	PARDAAS
	MIns	ADDX.B,D7,A0,1,T,X,4
ADDAHX:	PARDAAS
	MIns	ADD.B,D7,A0,1,T,N,4
SBCHX:	PARDAAR
	MIns	SUBX.B,D7,A0,1,T,X,4
SUBHX:	PARDAAR
	MIns	SUB.B,D7,A0,1,T,N,4
ADCALX:	PARDAAS
	MOVE.W	A0,D1
	MIns	ADDX.B,D7,D1,0,T,X,4
ADDALX:	PARDAAS
	MOVE.W	A0,D1
	MIns	ADD.B,D7,D1,0,T,N,4
SBCLX:	PARDAAR
	MOVE.W	A0,D1
	MIns	SUBX.B,D7,D1,0,T,X,4
SUBLX:	PARDAAR
	MOVE.W	A0,D1
	MIns	SUB.B,D7,D1,0,T,N,4
ANDHX:	MIns	AND.B,D7,A0,1,P,N,4
ANDLX:	MOVE.W	A0,D1
	MIns	AND.B,D7,D1,0,P,N,4
ORHX:	MIns	OR.B,D7,A0,1,P,N,4
ORLX:	MOVE.W	A0,D1
	MIns	OR.B,D7,D1,0,P,N,4
XORHX:	MIns	EOR.B,D7,A0,1,P,N,4
XORLX:	MOVE.W	A0,D1
	MIns	EOR.B,D7,D1,0,P,N,4
CPHX:	MIns	CMP.B,D7,A0,1,T,N,4
CPLX:	MOVE.W	A0,D1
	MIns	CMP.B,D7,D1,0,T,N,4


INCHY:
	MOVE.W	A1,D1
	ROR.W	#8,D1
	MOVE.B	D3,D2
	ADDQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
INCLY:
	MOVE.W	A1,D1
	MOVE.B	D3,D2
	ADDQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	MOVE.L	D1,A1
	Otra	9
DECHY:
	MOVE.W	A1,D1
	ROR.W	#8,D1
	MOVE.B	D3,D2
	SUBQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
DECLY:
	MOVE.W	A1,D1
	MOVE.B	D3,D2
	SUBQ.B	#1,D1
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	MOVE.L	D1,A1
	Otra	9
LDHYN:
	MOVE.W	A1,D1
	LSL.W	#8,D1
	MOVE.B	(A5)+,D1
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
LDLYN:
	MOVE.W	A1,D1
	MOVE.B	(A5)+,D1
	MOVE.L	D1,A1
	Otra	9
LDAHY:
	MOVE.W	A1,D7
	LSR.W	#8,D7
	Otra	9
LDALY:
	MOVE.W	A1,D1
	MOVE.B	D1,D7
	Otra	9
LDLHY:
	MOVE.W	A1,D1
	LSR.W	#8,D1
	MOVE.B	D1,D4
	Otra	9
LDLLY:
	MOVE.W	A1,D1
	MOVE.B	D1,D4
	Otra	9
LDCHY:
	MOVE.W	A1,D1
	LSR.W	#8,D1
	MOVE.B	D1,D5
	Otra	9
LDCLY:
	MOVE.W	A1,D1
	MOVE.B	D1,D5
	Otra	9
LDEHY:
	MOVE.W	A1,D1
	LSR.W	#8,D1
	MOVE.B	D1,D6
	Otra	9
LDELY:
	MOVE.W	A1,D1
	MOVE.B	D1,D6
	Otra	9
LDHHY:
	MOVE.W	A1,D1
	MOVE.B	D4,D1
	MOVE.W	D1,D4
	Otra	9
LDHLY:
	MOVE.W	A1,D1
	LSL.W	#8,D1
	MOVE.B	D4,D1
	MOVE.W	D1,D4
	Otra	9
LDBHY:
	MOVE.W	A1,D1
	MOVE.B	D5,D1
	MOVE.W	D1,D5
	Otra	9
LDBLY:
	MOVE.W	A1,D1
	LSL.W	#8,D1
	MOVE.B	D5,D1
	MOVE.W	D1,D5
	Otra	9
LDDHY:
	MOVE.W	A1,D1
	MOVE.B	D6,D1
	MOVE.W	D1,D6
	Otra	9
LDDLY:
	MOVE.W	A1,D1
	LSL.W	#8,D1
	MOVE.B	D6,D1
	MOVE.W	D1,D6
	Otra	9
LDLYA:
	MOVE.W	A1,D1
	MOVE.B	D7,D1
	MOVE.L	D1,A1
	Otra	9
LDLYC:
	MOVE.W	A1,D1
	MOVE.B	D5,D1
	MOVE.L	D1,A1
	Otra	9
LDLYE:
	MOVE.W	A1,D1
	MOVE.B	D6,D1
	MOVE.L	D1,A1
	Otra	9
LDLYL:
	MOVE.W	A1,D1
	MOVE.B	D4,D1
	MOVE.L	D1,A1
	Otra	9
LDLYB:
	MOVE.W	A1,D1
	ROR.W	#8,D5
	MOVE.B	D5,D1
	ROR.W	#8,D5
	MOVE.L	D1,A1
	Otra	9
LDLYD:
	MOVE.W	A1,D1
	ROR.W	#8,D6
	MOVE.B	D6,D1
	ROR.W	#8,D6
	MOVE.L	D1,A1
	Otra	9
LDLYH:
	MOVE.W	A1,D1
	LSR.W	#8,D1
	MOVE.B	D1,D2
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A1
	Otra	9
LDHYL:
	MOVE.W	A1,D1
	MOVE.B	D1,D2
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A1
	Otra	9
LDHYA:
	MOVE.W	A1,D1
	ROR.W	#8,D1
	MOVE.B	D7,D1
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
LDHYC:
	MOVE.W	A1,D1
	ROR.W	#8,D1
	MOVE.B	D5,D1
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
LDHYE:
	MOVE.W	A1,D1
	ROR.W	#8,D1
	MOVE.B	D6,D1
	ROR.W	#8,D1
	MOVE.L	D1,A1
	Otra	9
LDHYB:
	MOVE.W	A1,D1
	MOVE.B	D1,D2
	MOVE.W	D5,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A1
	Otra	9
LDHYD:
	MOVE.W	A1,D1
	MOVE.B	D1,D2
	MOVE.W	D6,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A1
	Otra	9
LDHYH:
	MOVE.W	A1,D1
	MOVE.B	D1,D2
	MOVE.W	D4,D1
	MOVE.B	D2,D1
	MOVE.L	D1,A1
	Otra	9

ADCAHY:	PARDAAS
	MIns	ADDX.B,D7,A1,1,T,X,4
ADDAHY:	PARDAAS
	MIns	ADD.B,D7,A1,1,T,N,4
SBCHY:	PARDAAR
	MIns	SUBX.B,D7,A1,1,T,X,4
SUBHY:	PARDAAR
	MIns	SUB.B,D7,A1,1,T,N,4
ADCALY:	PARDAAS
	MOVE.W	A1,D1
	MIns	ADDX.B,D7,D1,0,T,X,4
ADDALY:	PARDAAS
	MOVE.W	A1,D1
	MIns	ADD.B,D7,D1,0,T,N,4
SBCLY:	PARDAAR
	MOVE.W	A1,D1
	MIns	SUBX.B,D7,D1,0,T,X,4
SUBLY:	PARDAAR
	MOVE.W	A1,D1
	MIns	SUB.B,D7,D1,0,T,N,4
ANDHY:	MIns	AND.B,D7,A1,1,P,N,4
ANDLY:	MOVE.W	A1,D1
	MIns	AND.B,D7,D1,0,P,N,4
ORHY:	MIns	OR.B,D7,A1,1,P,N,4
ORLY:	MOVE.W	A1,D1
	MIns	OR.B,D7,D1,0,P,N,4
XORHY:	MIns	EOR.B,D7,A1,1,P,N,4
XORLY:	MOVE.W	A1,D1
	MIns	EOR.B,D7,D1,0,P,N,4
CPHY:	MIns	CMP.B,D7,A1,1,T,N,4
CPLY:	MOVE.W	A1,D1
	MIns	CMP.B,D7,D1,0,T,N,4

; --------------------------------------------------------------
LDMHL2:	MLDRR	D4,M,9,20
LDHLM2:	MLDRR	D4,M,8,20
; --------------------------------------------------------------

;	-------------------
;	Instrucciones R-800
;	-------------------

MULUBAB:
	MOVE.W	D5,D4
	LSR.W	#8,D4
	MULU	D7,D4
	OtraT	8

MULUBAC:
	MOVEQ	#0,D4
	MOVE.B	D5,D4
	MULU	D7,D4
	OtraT	8

MULUBAD:
	MOVE.W	D6,D4
	LSR.W	#8,D4
	MULU	D7,D4
	OtraT	8

MULUBAE:
	MOVEQ	#0,D4
	MOVE.B	D6,D4
	MULU	D7,D4
	OtraT	8

MULUWHLBC:
	MULU	D5,D4
	MOVE.W	CCR,D3
	SWAP	D4
	MOVE.W	D4,D6
	CLR.W	D4
	SWAP	D4
	Otra	8

MULUWHLSP:
	MULU	D0,D4
	MOVE.W	CCR,D3
	SWAP	D4
	MOVE.W	D4,D6
	CLR.W	D4
	SWAP	D4
	Otra	8

IINFC:	MINC	D1,0,12

; --------------------------------------------------------------

; --------------------------------------------------------------

RInsCB:	MOVE.B	(A5)+,D2
	JMP	([InsCB-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
CB00:
	CMP.L	Desbor+4(A7),A5
	BGT.S	CB00C
	Otra	4
CB00C:	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,D2
	JMP	([InsCB-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
RInsDD:	MOVE.B	(A5)+,D2
	JMP	([InsDD-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
DD00:
	CMP.L	Desbor+4(A7),A5
	BGT.S	DD00C
	Otra	4
DD00C:	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,D2
	JMP	([InsDD-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
RInsED:	MOVE.B	(A5)+,D2
	JMP	([InsED-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
ED00:
	CMP.L	Desbor+4(A7),A5
	BGT.S	ED00C
	Otra	4
ED00C:	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,D2
	JMP	([InsED-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
RInsFD:	MOVE.B	(A5)+,D2
	JMP	([InsFD-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
FD00:
	CMP.L	Desbor+4(A7),A5
	BGT.S	FD00C
	Otra	4
FD00C:	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	(A7),D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	MOVE.B	(A5)+,D2
	JMP	([InsFD-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
RInsCBIX:
	MOVE.B	(A5)+,D1
	EXT.W	D1
	MOVE.B	(A5)+,D2
	JMP	([InsCBIX-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
CBX0:
	CMP.L	Desbor+4(A7),A5
	BGT.S	CBX0C
	Otra	4
CBX0C:
	LSL.W	#8,D1
	MOVE.B	D2,D1
	CheckW	D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	EXT.W	D1
	JMP	([InsCBIX-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
RInsCBIY:
	MOVE.B	(A5)+,D1
	EXT.W	D1
	MOVE.B	(A5)+,D2
	JMP	([InsCBIY-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	CNOP	0,4
CBY0:
	CMP.L	Desbor+4(A7),A5
	BGT.S	CBY0C
	Otra	4
CBY0C:
	LSL.W	#8,D1
	MOVE.B	D2,D1
	CheckW	D1
	MOVE.B	D1,D2
	LSR.W	#8,D1
	EXT.W	D1
	JMP	([InsCBIY-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


	CNOP	0,4
IRRD:
	CogePagE D4,A4
	MOVE.B	D7,D1
	LSL.W	#8,D1
	MOVE.B	D3,D2		; Flag S
	MOVE.B	(A4),D1
	AND.W	#$0FFF,D1
	ROR.W	#4,D1
	MOVE.B	D1,(A4)
	SF	D1
	ROL.W	#4,D1
	AND.B	#$F0,D7
	OR.B	D1,D7
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	Otra	12

IRLD:
	CogePagE D4,A4
	MOVEQ	#0,D1
	MOVE.B	(A4),D1
	MOVE.B	D3,D2		; Flag S
	MOVE.B	D7,(A4)
	AND.B	#$0F,(A4)
	LSL.W	#4,D1
	OR.B	D1,(A4)
	LSR.W	#8,D1
	AND.B	#$F0,D7
	OR.B	D1,D7
	MOVE.W	CCR,D3
	BFINS	D2,D3{31:1}
	Otra	12


INI:
	MOVE.B	D5,D2
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D1,D2
	CogePagE D4,A4
	MOVE.B	D2,(A4)
	ADDQ.W	#1,D4
	SUBBZ	2
	Otra	16

IND:
	MOVE.B	D5,D2
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D1,D2
	CogePagE D4,A4
	MOVE.B	D2,(A4)
	SUBQ.W	#1,D4
	SUBBZ	2
	Otra	16

OUTI:
	CogePag	D4,A4
	ADDQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	OUTIfZ
	AND.B	#$FB,D3
	MOVE.B	D2,D5
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	16
OUTIfZ:
	OR.B	#$04,D3
	MOVE.B	D2,D5
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	16

OUTD:
	CogePag	D4,A4
	SUBQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	OUTDfZ
	AND.B	#$FB,D3
	MOVE.B	D2,D5
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	16
OUTDfZ:
	OR.B	#$04,D3
	MOVE.B	D2,D5
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	Otra	16

INIR:
	MOVE.W	D5,D1
	LSR.W	#8,D1
	LSL.W	#4,D1
	SUB.W	D1,(A3)

	MOVE.B	D5,D2
INIRB:
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D1,D2
	CogePagE D4,A4
	MOVE.B	D2,(A4)
	ADDQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	INIRF
	MOVE.B	D2,D5
	BRA.S	INIRB
INIRF:	MOVE.B	D2,D5
	OR.B	#$04,D3		; Flag Z a 'ON'
	Otra	5

INDR:
	MOVE.W	D5,D1
	LSR.W	#8,D1
	LSL.W	#4,D1
	SUB.W	D1,(A3)

	MOVE.B	D5,D2
INDRB:
	JSR	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	MOVE.B	D1,D2
	CogePagE D4,A4
	MOVE.B	D2,(A4)
	SUBQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BEQ.S	INDRF
	MOVE.B	D2,D5
	BRA.S	INDRB
INDRF:	MOVE.B	D2,D5
	OR.B	#$04,D3		; Flag Z a 'ON'
	Otra	5


OTIR:
	MOVE.W	D5,D1
	LSR.W	#8,D1
	LSL.W	#4,D1
	SUB.W	D1,(A3)

	MOVE.B	D5,D2
OTIRCon:
	MOVE.B	D2,D5
	CogePag	D4,A4
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	ADDQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BNE.S	OTIRCon
	OR.B	#$04,D3		; Flag Z a 'ON'
	MOVE.B	D2,D5
	Otra	5

OTDR:
	MOVE.W	D5,D1
	LSR.W	#8,D1
	LSL.W	#4,D1
	SUB.W	D1,(A3)

	MOVE.B	D5,D2
OTDRCon:
	MOVE.B	D2,D5
	CogePag	D4,A4
	MOVE.B	(A4),D1
	JSR	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	SUBQ.W	#1,D4
	MOVE.B	D5,D2
	SUB.W	D2,D5
	BNE.S	OTDRCon
	OR.B	#$04,D3		; Flag Z a 'ON'
	MOVE.B	D2,D5
	Otra	5


LDI:
	CogePag	D4,A4
	MOVE.B	(A4),D2
	CogePagE D6,A4
	MOVE.B	D2,(A4)
	ADDQ.W	#1,D4
	ADDQ.W	#1,D6
	SUBQ.W	#1,D5
	OtraV	16

LDD:
	CogePag	D4,A4
	MOVE.B	(A4),D2
	CogePagE D6,A4
	MOVE.B	D2,(A4)
	SUBQ.W	#1,D4
	SUBQ.W	#1,D6
	SUBQ.W	#1,D5
	OtraV	16


LDIR:
	MOVE.W	D5,D1
;	LSL.W	#4,D1
	AND.W	#$0FFF,D1
	SUB.W	D1,(A3)

	MOVE.L	A0,-(SP)
	SUBQ.W	#1,D5
	CogePag	D4,A0
	CogePagE D6,A4
LDIRBUC:MOVE.B	(A0)+,(A4)+
	ADDQ.B	#1,D4
	BCS.S	LDIRD0
LDIRC0:	ADDQ.B	#1,D6
	DBCS	D5,LDIRBUC
	CMPI.W	#-1,D5
	BEQ.S	LDIRC1
	ADDI.W	#$100,D6
	CogePagE D6,A4
	DBF	D5,LDIRBUC
LDIRC1:	MOVEQ	#0,D5
	MOVE.L	(SP)+,A0
	AND.B	#$FD,D3		; Flag V a 'OFF'
	Otra	5
LDIRD0:	ADDI.W	#$100,D4
	CogePag	D4,A0
	BRA.S	LDIRC0
	CNOP	0,4


LDDR:
	MOVE.W	D5,D1
;	LSL.W	#4,D1
	AND.W	#$0FFF,D1
	SUB.W	D1,(A3)

	MOVE.L	A0,-(SP)
	SUBQ.W	#1,D5
	CogePag	D4,A0
	ADDQ.W	#1,A0
	CogePagE D6,A4
	ADDQ.W	#1,A4
LDDRBUC:MOVE.B	-(A0),-(A4)
	SUBQ.B	#1,D4
	BCS.S	LDDRD0
LDDRC0:	SUBQ.B	#1,D6
	DBCS	D5,LDDRBUC
	CMPI.W	#-1,D5
	BEQ.S	LDDRC1
	SUBI.W	#$100,D6
	CogePagE D6,A4
	ADDQ.W	#1,A4
	DBF	D5,LDDRBUC
LDDRC1:	MOVEQ	#0,D5
	MOVE.L	(SP)+,A0
	AND.B	#$FD,D3		; Flag V a 'OFF'
	Otra	5
LDDRD0:	SUBI.W	#$100,D4
	CogePag	D4,A0
	ADDQ.W	#1,A0
	BRA.S	LDDRC0
	CNOP	0,4



CPIR:
	SUBQ.W	#1,D5
CPIRB:
	CogePag	D4,A4
	CMP.B	(A4),D7
	BEQ.S	CPIR0
	ADDQ.W	#1,D4
	DBF	D5,CPIRB
	MOVEQ	#0,D5
	AND.B	#$F9,D3
	Otra	16
CPIR0:	OR.B	#$06,D3
	ADDQ.W	#1,D4
	Otra	16

CPI:
	CogePag	D4,A4
	CMP.B	(A4),D7
	BEQ.S	CPI0
	AND.B	#$FB,D3
	ADDQ.W	#1,D4
	SUBQ.W	#1,D5
	OtraV	16
CPI0:	OR.B	#$04,D3
	ADDQ.W	#1,D4
	SUBQ.W	#1,D5
	OtraV	16

CPDR:
	SUBQ.W	#1,D5
CPDRB:
	CogePag	D4,A4
	CMP.B	(A4),D7
	BEQ.S	CPDR0
	SUBQ.W	#1,D4
	DBF	D5,CPDRB
	MOVEQ	#0,D5
	AND.B	#$F9,D3
	Otra	16
CPDR0:	OR.B	#$06,D3
	SUBQ.W	#1,D4
	Otra	16

ICPD:
	CogePag	D4,A4
	CMP.B	(A4),D7
	BEQ.S	CPD0
	AND.B	#$FB,D3
	SUBQ.W	#1,D4
	SUBQ.W	#1,D5
	OtraV	16
CPD0:	OR.B	#$04,D3
	SUBQ.W	#1,D4
	SUBQ.W	#1,D5
	OtraV	16

; ------------------------------------------------------------------

; -========================================================-
; -========================================================-
; -========================================================-
; -========================================================-
; -========================================================-
; -========================================================-
; -========================================================-

; ------------------------------------------------------------------

	CNOP	0,8
InsCB:
	DC.L	RLCB0,RLCC,RLCD,RLCE,RLCH,RLCL,RLCHL,RLCA	; 00
	DC.L	RRCB,RRCC,RRCD,RRCE,RRCH,RRCL,RRCHL,RRCA	; 08
	DC.L	RLB,RLC,RLD,RLE,RLH,RLL,RLHL,RLA		; 10
	DC.L	RRB,RRC,RRD,RRE,RRH,RRL,RRHL,RRA		; 18
	DC.L	SLAB,SLAC,SLAD,SLAE,SLAH,SLAL,SLAHL,SLAA	; 20
	DC.L	SRAB,SRAC,SRAD,SRAE,SRAH,SRAL,SRAHL,SRAA	; 28
	DC.L	SRRB,SRRC,SRRD,SRRE,SRRH,SRRL,SRRHL,SRRA	; 30
	DC.L	SRLB,SRLC,SRLD,SRLE,SRLH,SRLL,SRLHL,SRLA	; 38
	DC.L	BIT0B,BIT0C,BIT0D,BIT0E,BIT0H,BIT0L,BIT0HL,BIT0A; 40
	DC.L	BIT1B,BIT1C,BIT1D,BIT1E,BIT1H,BIT1L,BIT1HL,BIT1A; 48
	DC.L	BIT2B,BIT2C,BIT2D,BIT2E,BIT2H,BIT2L,BIT2HL,BIT2A; 50
	DC.L	BIT3B,BIT3C,BIT3D,BIT3E,BIT3H,BIT3L,BIT3HL,BIT3A; 58
	DC.L	BIT4B,BIT4C,BIT4D,BIT4E,BIT4H,BIT4L,BIT4HL,BIT4A; 60
	DC.L	BIT5B,BIT5C,BIT5D,BIT5E,BIT5H,BIT5L,BIT5HL,BIT5A; 68
	DC.L	BIT6B,BIT6C,BIT6D,BIT6E,BIT6H,BIT6L,BIT6HL,BIT6A; 70
	DC.L	BIT7B,BIT7C,BIT7D,BIT7E,BIT7H,BIT7L,BIT7HL,BIT7A; 78
	DC.L	RES0B,RES0C,RES0D,RES0E,RES0H,RES0L,RES0HL,RES0A; 80
	DC.L	RES1B,RES1C,RES1D,RES1E,RES1H,RES1L,RES1HL,RES1A; 88
	DC.L	RES2B,RES2C,RES2D,RES2E,RES2H,RES2L,RES2HL,RES2A; 90
	DC.L	RES3B,RES3C,RES3D,RES3E,RES3H,RES3L,RES3HL,RES3A; 98
	DC.L	RES4B,RES4C,RES4D,RES4E,RES4H,RES4L,RES4HL,RES4A; A0
	DC.L	RES5B,RES5C,RES5D,RES5E,RES5H,RES5L,RES5HL,RES5A; A8
	DC.L	RES6B,RES6C,RES6D,RES6E,RES6H,RES6L,RES6HL,RES6A; B0
	DC.L	RES7B,RES7C,RES7D,RES7E,RES7H,RES7L,RES7HL,RES7A; B8
	DC.L	SET0B,SET0C,SET0D,SET0E,SET0H,SET0L,SET0HL,SET0A; C0
	DC.L	SET1B,SET1C,SET1D,SET1E,SET1H,SET1L,SET1HL,SET1A; C8
	DC.L	SET2B,SET2C,SET2D,SET2E,SET2H,SET2L,SET2HL,SET2A; D0
	DC.L	SET3B,SET3C,SET3D,SET3E,SET3H,SET3L,SET3HL,SET3A; D8
	DC.L	SET4B,SET4C,SET4D,SET4E,SET4H,SET4L,SET4HL,SET4A; E0
	DC.L	SET5B,SET5C,SET5D,SET5E,SET5H,SET5L,SET5HL,SET5A; E8
	DC.L	SET6B,SET6C,SET6D,SET6E,SET6H,SET6L,SET6HL,SET6A; F0
	DC.L	SET7B,SET7C,SET7D,SET7E,SET7H,SET7L,SET7HL,SET7A; F8

InsCBIX:
	DC.L	CBX0,NADA,NADA,NADA,NADA,NADA,RLCIX,NADA	; 00
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RRCIX,NADA	; 08
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RLIX,NADA		; 10
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RRIX,NADA		; 18
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SLAIX,NADA	; 20
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRAIX,NADA	; 28
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRRIX,NADA	; 30
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRLIX,NADA	; 38
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT0IX,NADA	; 40
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT1IX,NADA	; 48
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT2IX,NADA	; 50
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT3IX,NADA	; 58
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT4IX,NADA	; 60
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT5IX,NADA	; 68
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT6IX,NADA	; 70
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT7IX,NADA	; 78
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES0IX,NADA	; 80
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES1IX,NADA	; 88
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES2IX,NADA	; 90
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES3IX,NADA	; 98
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES4IX,NADA	; A0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES5IX,NADA	; A8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES6IX,NADA	; B0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES7IX,NADA	; B8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET0IX,NADA	; C0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET1IX,NADA	; C8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET2IX,NADA	; D0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET3IX,NADA	; D8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET4IX,NADA	; E0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET5IX,NADA	; E8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET6IX,NADA	; F0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET7IX,NADA	; F8

InsCBIY:
	DC.L	CBY0,NADA,NADA,NADA,NADA,NADA,RLCIY,NADA	; 00
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RRCIY,NADA	; 08
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RLIY,NADA		; 10
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RRIY,NADA		; 18
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SLAIY,NADA	; 20
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRAIY,NADA	; 28
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRRIY,NADA	; 30
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SRLIY,NADA	; 38
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT0IY,NADA	; 40
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT1IY,NADA	; 48
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT2IY,NADA	; 50
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT3IY,NADA	; 58
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT4IY,NADA	; 60
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT5IY,NADA	; 68
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT6IY,NADA	; 70
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,BIT7IY,NADA	; 78
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES0IY,NADA	; 80
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES1IY,NADA	; 88
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES2IY,NADA	; 90
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES3IY,NADA	; 98
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES4IY,NADA	; A0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES5IY,NADA	; A8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES6IY,NADA	; B0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,RES7IY,NADA	; B8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET0IY,NADA	; C0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET1IY,NADA	; C8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET2IY,NADA	; D0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET3IY,NADA	; D8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET4IY,NADA	; E0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET5IY,NADA	; E8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET6IY,NADA	; F0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,SET7IY,NADA	; F8

InsDD:
	DC.L	DD00,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 00
	DC.L	NADA,ADDIXBC,NADA,NADA,NADA,NADA,NADA,NADA	; 08
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 10
	DC.L	NADA,ADDIXDE,NADA,NADA,NADA,NADA,NADA,NADA	; 18
	DC.L	NADA,LDIXN,LDMIX,INCIX,INCHX,DECHX,LDHXN,NADA	; 20
	DC.L	NADA,ADDIXIX,LDIXM,DECIX,INCLX,DECLX,LDLXN,NADA	; 28
	DC.L	NADA,NADA,NADA,NADA,INCIXM,DECIXM,LDIXMN,NADA	; 30
	DC.L	NADA,ADDIXSP,NADA,NADA,NADA,NADA,NADA,NADA	; 38
	DC.L	LDBB,LDBC,LDBD,LDBE,LDBHX,LDBLX,LDBIX,LDBA	; 40
	DC.L	LDCB,LDCC,LDCD,LDCE,LDCHX,LDCLX,LDCIX,LDCA	; 48
	DC.L	LDDB,LDDC,LDDD,LDDE,LDDHX,LDDLX,LDDIX,LDDA	; 50
	DC.L	LDEB,LDEC,LDED,LDEE,LDEHX,LDELX,LDEIX,LDEA	; 58
	DC.L	LDHXB,LDHXC,LDHXD,LDHXE,LDHXH,LDHXL,LDHIX,LDHXA	; 60
	DC.L	LDLXB,LDLXC,LDLXD,LDLXE,LDLXH,LDLXL,LDLIX,LDLXA	; 68
	DC.L	LDIXB,LDIXC,LDIXD,LDIXE,LDIXH,LDIXL,NADA,LDIXA	; 70
	DC.L	LDAB,LDAC,LDAD,LDAE,LDAHX,LDALX,LDAIX,LDAA	; 78
	DC.L	NADA,NADA,NADA,NADA,ADDAHX,ADDALX,ADDAIX,NADA	; 80
	DC.L	NADA,NADA,NADA,NADA,ADCAHX,ADCALX,ADCAIX,NADA	; 88
	DC.L	NADA,NADA,NADA,NADA,SUBHX,SUBLX,SUBIX,NADA	; 90
	DC.L	NADA,NADA,NADA,NADA,SBCHX,SBCLX,SBCIX,NADA	; 98
	DC.L	NADA,NADA,NADA,NADA,ANDHX,ANDLX,ANDIX,NADA	; A0
	DC.L	NADA,NADA,NADA,NADA,XORHX,XORLX,XORIX,NADA	; A8
	DC.L	NADA,NADA,NADA,NADA,ORHX,ORLX,ORIX,NADA		; B0
	DC.L	NADA,NADA,NADA,NADA,CPHX,CPLX,CPIX,NADA		; B8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; C0
	DC.L	NADA,NADA,NADA,RInsCBIX,NADA,NADA,NADA,NADA	; C8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; D0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; D8
	DC.L	NADA,POPIX,NADA,EXSPMIX,NADA,PUSHIX,NADA,NADA	; E0
	DC.L	NADA,JPIX,NADA,NADA,NADA,NADA,NADA,NADA		; E8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; F0
	DC.L	NADA,LDSPIX,NADA,NADA,NADA,NADA,NADA,NADA	; F8

InsED:
	DC.L	ED00,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 00
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 08
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 10
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 18
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 20
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 28
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 30
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 38
	DC.L	INBC,OUTCB,SBCHLBC,LDMBC,NEG,RETN,IM0,LDIA	; 40
	DC.L	IINCC,OUTCC,ADCHLBC,LDBCM,NADA,RETI,NADA,LDRA	; 48
	DC.L	INDC,OUTCD,SBCHLDE,LDMDE,NADA,NADA,IM1,LDAI	; 50
	DC.L	INEC,OUTCE,ADCHLDE,LDDEM,NADA,NADA,IM2,LDAR	; 58
	DC.L	INHC,OUTCH,SBCHLHL,LDMHL2,NADA,NADA,NADA,IRRD	; 60
	DC.L	INLC,OUTCL,ADCHLHL,LDHLM2,NADA,NADA,NADA,IRLD	; 68
	DC.L	IINFC,NADA,SBCHLSP,LDMSP,NADA,NADA,NADA,NADA	; 70
	DC.L	INAC,OUTCA,ADCHLSP,LDSPM,NADA,NADA,NADA,NADA	; 78
	DC.L	NADA,NADA,NADA,OTIR,NADA,NADA,NADA,NADA		; 80
	DC.L	NADA,NADA,NADA,OTDR,NADA,NADA,NADA,NADA		; 88
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 90
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 98
	DC.L	LDI,CPI,INI,OUTI,NADA,NADA,NADA,NADA		; A0
	DC.L	LDD,ICPD,IND,OUTD,NADA,NADA,NADA,NADA		; A8
	DC.L	LDIR,CPIR,INIR,OTIR,NADA,NADA,NADA,NADA		; B0
	DC.L	LDDR,CPDR,INDR,OTDR,NADA,NADA,NADA,NADA		; B8
	DC.L	NADA,MULUBAB,NADA,MULUWHLBC,MULUBAB,NADA,NADA,NADA	; C0
	DC.L	NADA,MULUBAC,NADA,NADA,NADA,MULUBAC,NADA,NADA	; C8
	DC.L	NADA,MULUBAD,NADA,NADA,NADA,MULUBAD,NADA,NADA	; D0
	DC.L	NADA,MULUBAE,NADA,NADA,NADA,MULUBAE,NADA,NADA	; D8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; E0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; E8
	DC.L	NADA,NADA,NADA,MULUWHLSP,NADA,NADA,NADA,NADA	; F0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; F8

InsFD:
	DC.L	FD00,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 00
	DC.L	NADA,ADDIYBC,NADA,NADA,NADA,NADA,NADA,NADA	; 08
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; 10
	DC.L	NADA,ADDIYDE,NADA,NADA,NADA,NADA,NADA,NADA	; 18
	DC.L	NADA,LDIYN,LDMIY,INCIY,INCHY,DECHY,LDHYN,NADA	; 20
	DC.L	NADA,ADDIYIY,LDIYM,DECIY,INCLY,DECLY,LDLYN,NADA	; 28
	DC.L	NADA,NADA,NADA,NADA,INCIYM,DECIYM,LDIYMN,NADA	; 30
	DC.L	NADA,ADDIYSP,NADA,NADA,NADA,NADA,NADA,NADA	; 38
	DC.L	LDBB,LDBC,LDBD,LDBE,LDBHY,LDBLY,LDBIY,LDBA	; 40
	DC.L	LDCB,LDCC,LDCD,LDCE,LDCHY,LDCLY,LDCIY,LDCA	; 48
	DC.L	LDDB,LDDC,LDDD,LDDE,LDDHY,LDDLY,LDDIY,LDDA	; 50
	DC.L	LDEB,LDEC,LDED,LDEE,LDEHY,LDELY,LDEIY,LDEA	; 58
	DC.L	LDHYB,LDHYC,LDHYD,LDHYE,LDHYH,LDHYL,LDHIY,LDHYA	; 60
	DC.L	LDLYB,LDLYC,LDLYD,LDLYE,LDLYH,LDLYL,LDLIY,LDLYA	; 68
	DC.L	LDIYB,LDIYC,LDIYD,LDIYE,LDIYH,LDIYL,NADA,LDIYA	; 70
	DC.L	LDAB,LDAC,LDAD,LDAE,LDAHY,LDALY,LDAIY,LDAA	; 78
	DC.L	NADA,NADA,NADA,NADA,ADDAHY,ADDALY,ADDAIY,NADA	; 80
	DC.L	NADA,NADA,NADA,NADA,ADCAHY,ADCALY,ADCAIY,NADA	; 88
	DC.L	NADA,NADA,NADA,NADA,SUBHY,SUBLY,SUBIY,NADA	; 90
	DC.L	NADA,NADA,NADA,NADA,SBCHY,SBCLY,SBCIY,NADA	; 98
	DC.L	NADA,NADA,NADA,NADA,ANDHY,ANDLY,ANDIY,NADA	; A0
	DC.L	NADA,NADA,NADA,NADA,XORHY,XORLY,XORIY,NADA	; A8
	DC.L	NADA,NADA,NADA,NADA,ORHY,ORLY,ORIY,NADA		; B0
	DC.L	NADA,NADA,NADA,NADA,CPHY,CPLY,CPIY,NADA		; B8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; C0
	DC.L	NADA,NADA,NADA,RInsCBIY,NADA,NADA,NADA,NADA	; C8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; D0
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; D8
	DC.L	NADA,POPIY,NADA,EXSPMIY,NADA,PUSHIY,NADA,NADA	; E0
	DC.L	NADA,JPIY,NADA,NADA,NADA,NADA,NADA,NADA		; E8
	DC.L	NADA,NADA,NADA,NADA,NADA,NADA,NADA,NADA		; F0
	DC.L	NADA,LDSPIY,NADA,NADA,NADA,NADA,NADA,NADA	; F8
********************************************************************

	CNOP	0,4
OUT00:
	CMP.L	Desbor+4+4(A7),A5
	BGT.S	OUT0C
	RTS
OUT0C:	MOVE.B	D1,D2
	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	4(A7),D1
	CogePag	D1,A5
	MOVE.L	(A7),A4				; Dir para el RTS
	LEA	Restas-4(A3,D1.W*8),A7
	MOVE.L	A4,(A7)				; Dir para el RTS
	MOVE.B	D2,D1
	MOVE.B	(A5)+,D2
	TST.B	D1
	JMP	([Outs-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.
	

	CNOP	0,4
IN00:
	CMP.L	Desbor+4+4(A7),A5
	BGT.S	IN0C
	MOVE.B	JoyX+2(A3),D1
	MOVE.B	DirPrefs+$19,D2
	BFINS	D2,D1{25:1}
	RTS
IN0C:	SUBQ.W	#1,A5
	MOVE.W	A5,D1
	SUB.W	4(A7),D1
	CogePag	D1,A5
	MOVE.L	(A7),A4				; Dir para el RTS
	LEA	Restas-4(A3,D1.W*8),A7
	MOVE.L	A4,(A7)				; Dir para el RTS
	MOVE.B	(A5)+,D2
	JMP	([Ins-$400.W,PC,D2.W*4])	; Salta a puntero de emulación.


; -------------------------------------------------------------------
; *******************************************************************
; -------------------------------------------------------------------

	CNOP	0,8
Mapper2:
	MOVE.B	(A4)+,D1
	MOVE.B	(A4),D2
	IFD	AMG_RAMMIRROR
	SUB.L	#IRAM+$1FFC+1,A4
	ELSE
	SUB.L	#IRAM+$3FFC+1,A4
	ENDC
	JSR	([MapperROM.w,PC,A4.W*4])
	MOVE.B	D2,D1
	JSR	([MapperROM+4.w,PC,A4.W*4])
	Otra	4
Mapper:
	MOVE.B	(A4),D1
	IFD	AMG_RAMMIRROR
	SUB.L	#IRAM+$1FFC,A4		; $FFFC-$FFFF in RAM
	ELSE
	SUB.L	#IRAM+$3FFC,A4
	ENDC
	JSR	([MapperROM.w,PC,A4.W*4])
	Otra	4

MapRET:	RTS

	CNOP	0,8
MapperROM:
	DC.L	FFFC,FFFD,FFFE,FFFF,MapRET,MapRET,MapRET,MapRET

; -=-=-=-
	CNOP	0,8
FFFC:
	IFD	AMG_RAMMIRROR
	MOVE.B	D1,IRAM+$3FFC		; the mapper's own register
	ELSE
	MOVE.B	D1,IRAM+$1FFC
	ENDC
	MOVE.B	IRAM+$3FFF,D1
	BRA	FFFF
; -=-=-=-
	CNOP	0,8
FFFD:
	IFD	AMG_RAMMIRROR
	MOVE.B	D1,IRAM+$3FFD		; the mapper's own register
	ELSE
	MOVE.B	D1,IRAM+$1FFD
	ENDC

	SUB.W	4(A7),A5

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

	MOVEQ	#0,D1
	MOVE.W	A5,D1
	CogePag	D1,A5

	RTS

; -=-=-=-

	CNOP	0,8
FFFE:
	IFD	AMG_RAMMIRROR
	MOVE.B	D1,IRAM+$3FFE		; the mapper's own register
	ELSE
	MOVE.B	D1,IRAM+$1FFE
	ENDC

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

	MOVEQ	#0,D1
	MOVE.W	A5,D1
	CogePag	D1,A5

	RTS

; -=-=-=-

	CNOP	0,8
FFFF:
	IFD	AMG_RAMMIRROR
	MOVE.B	D1,IRAM+$3FFF		; the mapper's own register
	ELSE
	MOVE.B	D1,IRAM+$1FFF
	ENDC

	SUB.W	4(A7),A5

	AND.W	MaskROM(A3),D1

	MULU	#$4080,D1
	ADD.L	MapROMBase(A3),D1
	SUB.L	#$4000,D1

	IFD	AMG_RAMMIRROR
	MOVE.L	#NoRAM-$8000,PagWrite+$10(A3)
	MOVE.L	#NoRAM-$8000,PagWrite+$14(A3)
	ELSE
	MOVE.L	#NoRAM-$8000,PagWrite+$8(A3)
	ENDC
	BTST	#3,IRAM+$3FFC
	BEQ.S	FFFFCon
	MOVE.L	#SRAM-$8000,D1
	IFD	AMG_SRAM2
	BTST	#2,IRAM+$3FFC		; RAM bank 1
	BEQ.S	AmgSram2B0
	ADD.L	#$4000,D1
AmgSram2B0:
	ENDC
	IFD	AMG_RAMMIRROR
	MOVE.L	D1,PagWrite+$10(A3)
	MOVE.L	D1,PagWrite+$14(A3)
	ELSE
	MOVE.L	D1,PagWrite+$8(A3)
	ENDC
FFFFCon:

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

	MOVEQ	#0,D1
	MOVE.W	A5,D1
	CogePag	D1,A5

	RTS


; -------------------------------------------------------------------
; *******************************************************************
; -------------------------------------------------------------------


	CNOP	0,8
MapperInit:
	MOVE.B	IRAM+$3FFD,D1

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
; -=-=-=-
	MOVE.B	IRAM+$3FFE,D1

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
; -=-=-=-
	MOVE.B	IRAM+$3FFF,D1

	AND.W	MaskROM(A3),D1

	MULU	#$4080,D1
	ADD.L	MapROMBase(A3),D1
	SUB.L	#$4000,D1

	IFD	AMG_RAMMIRROR
	MOVE.L	#NoRAM-$8000,PagWrite+$10(A3)
	MOVE.L	#NoRAM-$8000,PagWrite+$14(A3)
	ELSE
	MOVE.L	#NoRAM-$8000,PagWrite+$8(A3)
	ENDC
	BTST	#3,IRAM+$3FFC
	BEQ.S	FFFFCon2
	MOVE.L	#SRAM-$8000,D1
	IFD	AMG_SRAM2
	BTST	#2,IRAM+$3FFC		; RAM bank 1
	BEQ.S	AmgSram2B0b
	ADD.L	#$4000,D1
AmgSram2B0b:
	ENDC
	IFD	AMG_RAMMIRROR
	MOVE.L	D1,PagWrite+$10(A3)
	MOVE.L	D1,PagWrite+$14(A3)
	ELSE
	MOVE.L	D1,PagWrite+$8(A3)
	ENDC
FFFFCon2:

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

	MOVEQ	#0,D1

	RTS



; -------------------------------------------------------------------
; *******************************************************************
; -------------------------------------------------------------------

	CNOP	0,8
Ins:
	DC.L	IN00,INXX,INXX,INXX,INXX,IN05,INXX,INXX		; 00
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 08
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 10
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 18
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 20
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 28
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 30
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 38
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 40
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 48
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 50
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 58
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 60
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 68
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 70
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,IN7E,INXX		; 78
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 80
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 88
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 90
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; 98
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; A0
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; A8
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; B0
	DC.L	INXX,INXX,INXX,INXX,INXX,INBF,INBE,INBF		; B8
	DC.L	INJ0,INJ1,INXX,INXX,INXX,INXX,INXX,INXX		; C0
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; C8
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; D0
	DC.L	INXX,INXX,INXX,INXX,INJ0,INJ1,INXX,INXX		; D8
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; E0
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; E8
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; F0
	DC.L	INXX,INXX,INXX,INXX,INXX,INXX,INXX,INXX		; F8

	CNOP	0,8
Outs:
	DC.L	OUT00,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 00
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 08
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 10
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 18
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 20
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 28
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 30
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUT3F		; 38
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 40
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 48
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 50
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 58
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 60
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 68
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 70
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUT7F		; 78
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 80
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 88
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 90
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; 98
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; A0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; A8
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; B0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTBF,OUTBEa,OUTBF	; B8
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; C0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; C8
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; D0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; D8
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; E0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; E8
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; F0
	DC.L	OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX,OUTXX		; F8



	CNOP	0,4
	DS.L	20

	IFD	AMG_RAMMIRROR
PagRead=-$80		; 8K pages: 8 longs in the DS.L 20 above
PagWrite=$10		; 8 longs
Restas=$34		; 8 x 8 bytes to $6F; the 4 bytes before each are a JSR slot (I/O calls)
Desbor=$500-Restas	; 8 x (low, high)
	ELSE
PagRead=$10
PagWrite=$20
Restas=$34
Desbor=$50-Restas
	ENDC

	DC.W	0	; -$60(A3)
	DC.W	0	; -$5E(A3)	VLines
	DC.W	0	; -$5C(A3)	CurLine
	DC.B	0	; -$5A(A3)	GfxReCont
	DC.B	0	; -$59(A3)	SprReCont
	DC.W	0	; -$58(A3)	Contador1
	DC.W	0	; -$56(A3)	HorLine
	DC.B	0	; -$54(A3)	PalCopy
	DC.B	0	; -$53(A3)	fps60Dat
	DC.B	0	; -$52(A3)	UltCoorY
	DC.B	0	; -$51(A3)	UltCoorX
	DC.L	CopperLine0+$E	; -$50(A3)	IntMGAnt
	DC.B	0	; -$4C(A3)	ModoTraza
	DC.B	0	; -$4B(A3)
	DC.W	0	; -$4A(A3)	MaskVPAL
	DC.L	0	; -$48(A3)	JoyX
	DC.L	0	; -$44(A3)	KeyX
	DS.L	16	; -$40(A3)	Bufer
Regs:
	DC.W	0	;     (A3)
	DC.B	0	;   $2(A3)	I
	DC.B	0	;   $3(A3)	R
	DS.W	3	;   $4(A3)	PEXX (HL',BC',DE')
	DC.W	0	;   $A(A3)	DirVRAM
	DC.B	0	;   $C(A3)	ModoInt
	DC.B	0	;   $D(A3)	RasterInt
	DC.B	0	;   $E(A3)	PetIntMG
	DC.B	0	;   $F(A3)	IFF0


	DC.L	0		;  $10(A3)	PagRead
	DC.L	0		;  $14(A3)
	DC.L	0		;  $18(A3)
	DC.L	0		;  $1C(A3)

	DC.L	0		;  $20(A3)	PagWrite
	DC.L	0		;  $24(A3)
	DC.L	0		;  $28(A3)
	DC.L	0		;  $2C(A3)

	DS.L	2	; -$30(A3)	Desbor  [-$20(Restas)]
	DS.L	2	; -$38(A3)
	DS.L	2	; -$40(A3)
	DS.L	2	; -$48(A3)

	DS.L	2	; -$50(A3)	Restas
	DS.L	2	; -$58(A3)
	DS.L	2	; -$60(A3)
	DS.L	2	; -$68(A3)

	DC.B	0		; $70(A3)	TipoInt
	DC.B	0		; $71(A3)	LineInt
	DC.W	0		; $72(A3)	MaskROM
	DC.L	0		; $74(A3)	MapROMBase
	DC.B	0		; $78(A3)	Consola
	DC.B	0		; $79(A3)	PSG_Old
	DC.B	0		; $7A(A3)	Estado
	DC.B	0		; $7B(A3)	SalirMenu

FRegs:	DS.B	$7C-(FRegs-Regs)

	DS.B	$400	;  $7C(A3)	TAB_Flags
	DC.L	0	; $47C(A3)

Variables:
	DC.B	0	; $480(A3)	IO7F
	DC.B	0	; $481(A3)	IOBF
	DC.B	0	; $482(A3)	HaltDat
	DC.B	0	; $482(A3)
	DC.L	0	; $484(A3)	MapperIO
	DC.B	0	; $488(A3)	ANA
	DC.B	0	; $489(A3)	IFF
	DC.W	0	; $48A(A3)


FVaria:	DS.B	$380-(FVaria-Variables)

;	 ------------------------------------------------------------
;	**  Tablas de instrucciones del Z-80A Simulado por MC68020  **
;	 ------------------------------------------------------------
Instr:			; $800(A3)

	DC.L	NOP,LDBCN,LDBCA,INCBC,INCB,DECB,LDBN,IRLCA	; 00
	DC.L	EXAF,ADDHLBC,LDABC,DECBC,INCC,DECC,LDCN,IRRCA	; 08
	DC.L	DJNZ,LDDEN,LDDEA,INCDE,INCD,DECD,LDDN,IRLA	; 10
	DC.L	JR,ADDHLDE,LDADE,DECDE,INCE,DECE,LDEN,IRRA	; 18
	DC.L	JRNZ,LDHLN,LDMHL,INCHL,INCH,DECH,LDHN,DAA	; 20
	DC.L	JRZ,ADDHLHL,LDHLM,DECHL,INCL,DECL,LDLN,ICPL	; 28
	DC.L	JRNC,LDSPN,LDMA,INCSP,INCHLM,DECHLM,LDHLMN,SCF	; 30
	DC.L	JRC,ADDHLSP,LDAM,DECSP,INCA,DECA,LDAN,CCF	; 38
	DC.L	LDBB,LDBC,LDBD,LDBE,LDBH,LDBL,LDBHL,LDBA	; 40
	DC.L	LDCB,LDCC,LDCD,LDCE,LDCH,LDCL,LDCHL,LDCA	; 48
	DC.L	LDDB,LDDC,LDDD,LDDE,LDDH,LDDL,LDDHL,LDDA	; 50
	DC.L	LDEB,LDEC,LDED,LDEE,LDEH,LDEL,LDEHL,LDEA	; 58
	DC.L	LDHB,LDHC,LDHD,LDHE,LDHH,LDHL,LDHHL,LDHA	; 60
	DC.L	LDLB,LDLC,LDLD,LDLE,LDLH,LDLL,LDLHL,LDLA	; 68
	DC.L	LDHLB,LDHLC,LDHLD,LDHLE,LDHLH,LDHLL,HALT,LDHLA	; 70
	DC.L	LDAB,LDAC,LDAD,LDAE,LDAH,LDAL,LDAHL,LDAA	; 78
	DC.L	ADDAB,ADDAC,ADDAD,ADDAE,ADDAH,ADDAL,ADDAHL,ADDAA; 80
	DC.L	ADCAB,ADCAC,ADCAD,ADCAE,ADCAH,ADCAL,ADCAHL,ADCAA; 88
	DC.L	SUBB,SUBC,SUBD,SUBE,SUBH,SUBL,SUBHL,SUBA	; 90
	DC.L	SBCB,SBCC,SBCD,SBCE,SBCH,SBCL,SBCHL,SBCA	; 98
	DC.L	ANDB,ANDC,ANDD,ANDE,ANDH,ANDL,ANDHL,ANDA	; A0
	DC.L	XORB,XORC,XORD,XORE,XORH,XORL,XORHL,XORA	; A8
	DC.L	ORB,ORC,ORD,ORE,ORH,ORL,ORHL,ORA		; B0
	DC.L	CPB,CPC,CPD,CPE,CPH,CPL,CPHL,CPA		; B8
	DC.L	RETNZ,POPBC,JPNZ,JP,CALLNZ,PUSHBC,ADDAN,RST0	; C0
	DC.L	RETZ,IRET,JPZ,RInsCB,CALLZ,CALL,ADCAN,RST8	; C8
	DC.L	RETNC,POPDE,JPNC,OUTNA,CALLNC,PUSHDE,SUBN,RST10	; D0
	DC.L	RETC,EXX,JPC,INAN,CALLC,RInsDD,SBCN,RST18	; D8
	DC.L	RETPO,POPHL,JPPO,EXSPHL,CALLPO,PUSHHL,ANDN,RST20; E0
	DC.L	RETPE,JPHL,JPPE,EXDEHL,CALLPE,RInsED,XORN,RST28	; E8
	DC.L	RETP,POPAF,JPP,DI,CALLP,PUSHAF,ORN,RST30	; F0
	DC.L	RETM,LDSPHL,JPM,EI,CALLM,RInsFD,CPN,RST38	; F8
	DS.L	256

;   -----------------------------

	DS.B	512	; $1000(A3)	TabRedef

;   ---------------------------------------------------------------------
	DS.L	20
;   ---------------------------------------------------------------------

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	DS.L	20	; Seguridad

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-



;;	-=-=-=-==-=-=-=-=-=-=-
	CNOP	0,8
DameVBR:MOVEC	VBR,A0
	MOVE.L	A0,VBRPun
	NOP
	RTE
	CNOP	0,8
CongelaAMIGA:
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	DameVBR(PC),A5
	MOVE.L	$4.W,A6
	JSR	-$1E(A6)
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	$4.W,A5
	MOVE.L	$9C(A5),A5
	MOVE.L	$26(A5),WBCopp
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	DirPlanos,A0
	JSR	CreaPlanos
	LEA	DirColores,A0
	JSR	CreaColores
	LEA	DirSprites,A0
	JSR	CreaSprites
	LEA	DirSaltos,A0
	JSR	CreaSaltos
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$DFF000,A6
	MOVE.W	#$7FFF,D7
	MOVE.W	$1C(A6),INTENA
	MOVE.W	D7,$9A(A6)
	MOVE.W	$1E(A6),INTREQ
	MOVE.W	D7,$9C(A6)
	MOVE.W	$02(A6),DMACON
	BTST	#6,DMACON+1
	BEQ.S	NoBliOn
EspBli:	NOP
	NOP
	BTST	#6,2(A6)
	BNE.S	EspBli
	NOP
	NOP
NoBliOn:MOVE.W	D7,$96(A6)
	NOP
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	#MasterCopper,$80(A6)
	NOP
	MOVE.L	#Copper,$84(A6)
	NOP
	MOVE.W	#0,$88(A6)
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV
	NOP
	MOVE.W	#$83A0,$096(A6)	; ---,BLTPriDMA,BPL;COP,BLT,SPR,DSK;AUD3-0
;;	-=-=-=-==-=-=-=-=-=-=-
	SF	$BFEC01
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	VBRPun,A0
	MOVE.L	$24(A0),Traza
	MOVE.L	$6C(A0),VBlank
	MOVE.L	$64(A0),SOFTW
	MOVE.L	$84(A0),Trap1
	MOVE.L	$88(A0),Trap2
;;	-=-=-=-==-=-=-=-=-=-=-
;	MOVE.L	#DirTraza,$24(A0)
	MOVE.L	#InInter,$6C(A0)
;	MOVE.L	#VDPEmul,$64(A0)
;	MOVE.L	#IniInsBuc,$84(A0)
;	MOVE.L	#FinInsBuc,$88(A0)
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$BFE001,A6
	BFEXTU	(A6){6:1},D7		; Filtro.
	MOVE.B	D7,Filtro
	BSET	#1,$BFE001		; Filtro OFF
;;	-=-=-=-==-=-=-=-=-=-=-
	RTS

; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
Salir:
	MOVEM.L	D0-D7/A0-A7,Debug

	MOVE.L	IRAM+$3FFC,MapperIO(A3)		; Guarda Mapper.

	SUB.W	(A7),A5
	SUBQ.W	#1,A5
	MOVE.W	A5,PCReg

	MOVE.L	PILA,SP

; ---

DescongelaAMIGA:
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.B	Filtro,D7
	LEA	$BFE001,A6
	BFINS	D7,(A6){6:1}		; Filtro.
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.L	VBRPun,A0
	MOVE.L	Traza,$24(A0)
	MOVE.L	VBlank,$6C(A0)
	MOVE.L	SOFTW,$64(A0)
	MOVE.L	Trap1,$84(A0)
	MOVE.L	Trap2,$88(A0)
;;	-=-=-=-==-=-=-=-=-=-=-
	LEA	$DFF000,A6
	MOVE.W	#$7FFF,D7
	MOVE.W	D7,$09A(A6)
	MOVE.W	#$8000,D6
	OR.W	D6,DMACON
	MOVE.W	D7,$096(A6)
	OR.W	D6,INTENA
	OR.W	D6,INTREQ
	MOVE.W	D7,$09C(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	CLR.W	$180(A6)
	MOVE.L	WBCopp,$80(A6)
	NOP
	MOVE.L	WBCopp,$84(A6)
	NOP
	MOVE.W	#0,$88(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.W	#$8280,$096(A6)
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV0:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV0
	NOP
	NOP
	NOP
	NOP
	MOVE.W	#$0020,$09C(A6)
EspIntV1:NOP
	NOP
	NOP
	NOP
	BTST	#$05,$01F(A6)
	BEQ.S	EspIntV1
	NOP
	MOVE.W	D7,$09C(A6)
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
	MOVE.W	DMACON,$096(A6)
	NOP
	NOP
	MOVE.W	INTREQ,$09C(A6)
	NOP
	NOP
	MOVE.W	INTENA,$09A(A6)
	NOP
	NOP
;;	-=-=-=-==-=-=-=-=-=-=-
AmiRET:
	RTS
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;



; ---------------------------------=> Analiza requerimientos de interrupciones

	CNOP	0,4
MiraInterFin:
; ----------------------------------=> Pone refresco de BG en 1ª linea de CopperLine.
	LEA	TabRasDATA(PC),A4
	MOVE.B	#$02,TabRasCMDS
	MOVE.B	VDPRegs+$9(PC),(A4)	; BG Y
	MOVE.B	VDPRegs+$8(PC),2(A4)	; BG X
	MOVE.B	VDPRegs+$0(PC),1(A4)	; Control 0

	MOVE.B	VDPRegs+$8(PC),UltCoorX(A3)
	MOVE.B	VDPRegs+$9(PC),UltCoorY(A3)

	MOVE.L	#TabRasRGB,TabRasRGBcnt

;	-----------------------------
	MOVEM.L	D0-D7/A0-A7,Bufer(A3)
	LEA	BufBasura(PC),A7
;	---
	BSR	PonePaletaMS
;	---
	LEA	Regs(PC),A3
	MOVEM.L	Bufer(A3),D0-D7/A0-A7
;	-----------------------------

	CLR.W	CurLine(A3)
	MOVE.B	VDPRegs+$A(PC),HorLine(A3)	; Refresca LineInt
	SUBQ.b	#1,HorLine(A3)
	BCS	InterHor
	ADD.W	#HPeriod,(A3)
	BMI.S	MiraInter
	JMP	([A3,D2.W*8])
; ----------------------------------<=
	CNOP	0,8
MiraInter:
	ADDQ.W	#1,CurLine(A3)
	MOVE.W	CurLine(A3),D1
	JMP	([JumpCurLine.W,PC,D1.W*4])
MiraInterBuc:
	SUBQ.B	#1,HorLine(A3)
	BCS.S	InterHor
	ADD.W	#HPeriod,(A3)
	BMI.S	MiraInter
	BTST	#6,Estado(A3)		; Mira Interrupción Horizontal
	BNE	InterHorEI
	JMP	([A3,D2.W*8])
	CNOP	0,4
MiraInterBuc2:
	ADD.W	#HPeriod,(A3)
	BMI.S	MiraInter
	TST.B	Estado(A3)		; Mira Interrupción Vertical
	BMI	InterVerEI
	JMP	([A3,D2.W*8])
MiraInterBuc3:
	ADD.W	#HPeriod,(A3)
	BMI.S	MiraInter
	JMP	([A3,D2.W*8])
	CNOP	0,4
MiraInter255:
	MOVE.W	VLines(A3),D1
	ADD.W	D1,(A3)
	BMI.S	MiraInter
	JMP	([A3,D2.W*8])


;	------------------------=> Modo "Fast CPU"
	CNOP	0,4
ModoFastCPU:
	TST.B	fps60Dat(A3)		; ¿Se ha desbordado el frame?
	BEQ.S	EmulaGfx

	SUBQ.B	#1,CurLine+1(A3)

	ADD.W	#HPeriod,(A3)
	BMI	MiraInter

	JMP	([A3,D2.W*8])		; Vuelta al Z-80 emul.
;	------------------------<=

MiraInter192:
	CMP.B	#1,DirPrefs+$13		; ¿Modo Fast CPU?
	BEQ.S	ModoFastCPU

EmulaGfx:
	SUBQ.B	#1,HorLine(A3)
	BCS.S	InterHor
	BSET	#7,Estado(A3)		; Interrupción Vertical
	ADD.W	#HPeriod,(A3)
	BMI	MiraInter
	BTST	#6,Estado(A3)		; Mira Interrupción Horizontal
	BNE.S	InterHorEI
	JMP	([A3,D2.W*8])


	CNOP	0,4
InterHor:
	BSET	#6,Estado(A3)
	MOVE.B	VDPRegs+$A(PC),HorLine(A3)	; Refresca LineInt

	ST	PetIntMG(A3)

	ADD.W	#HPeriod,(A3)
	BMI	MiraInter

InterHorEI:
	BTST	#4,VDPRegs+0(PC)	; ¿Interrupción Horizontal?
	BEQ.S	NoInterX

	BRA.S	InterRun


	CNOP	0,4
NoInterX:
	MOVE.B	-1(A5),D2
	JMP	([A3,D2.W*8])


	CNOP	0,4
InterSalir:
	SF	SalirMenu(A3)
	JMP	Salir


	CNOP	0,4
MiraInter193:

;	-----------------------------
	MOVEM.L	D0-D7/A0-A7,Bufer(A3)
	LEA	BufBasura(PC),A7
;	---
	BSR	Emula1Frame
	IFD	AUTOTEST
	JSR	AutoFrame
	ENDC
;	---
	LEA	Regs(PC),A3
	MOVEM.L	Bufer(A3),D0-D7/A0-A7
;	-----------------------------

;	----------------
	TST.B	SalirMenu(A3)		; Mira si hay que Salir (ESC)
	BNE.S	InterSalir
;	----------------

InterVer:
	BSET	#7,Estado(A3)		; Interrupción Vertical

	ADD.W	#HPeriod,(A3)
	BMI	MiraInter

InterVerEI:
	BTST	#5,VDPRegs+1(PC)	; ¿Interrupción Vertial?
	BEQ.S	NoInterX

InterRun:

;	----------------
	TST.B	IFF(A3)			; ¿Modo DI?
	SEQ	PetIntMG(A3)		; Petición de una Interrupción V.
	BEQ.S	NoInterX
;	----------------
	SUB.W	#7,(A3)			; * Resta Cycles *
;	----------------
	MOVE.B	IFF(A3),IFF0(A3)
	SF	IFF(A3)			; ( DI ) Interrupciones OFF.
	IFD	AUTODUMP
	ADDQ.L	#1,AutoIrqs		; test builds: interrupts taken
	ENDC

;	----------------------=>  Mira si estamos en Halt y procede...
	TST.B	HaltDat(A3)
	BEQ.S	NoModoHalt
	SF	HaltDat(A3)
	ADDQ.W	#1,A5
NoModoHalt:
;	----------------------<=

;	----------------
	SUBQ.W	#1,A5			; Calcula dirección PC real.
	SUB.W	(A7),A5
	MOVE.W	A5,D2

	MOVEQ	#0,D1			; Guarda PC en la Pila.
	SUBQ.W	#2,D0
	MOVE.W	D0,D1
	CogePagE D1,A6
	MOVE.B	D2,(A6)
	MOVE.W	D0,D1
	ADDQ.W	#1,D1
	CogePagE D1,A4
	LSR.W	#8,D2
	MOVE.B	D2,(A4)

	MOVE.W	#$0100,D2		; Calcula Salto a Interrupción.
	MOVE.L	PagRead(A3),A4
	LEA	$38(A4),A5
	LEA	Restas(A3),A7
;	----------------

	TST.B	ModoInt(A3)		; ¿Es Modo IM 1?
	BNE.S	NoModo1
;	----------------		; Mira Si Se ha Pulsado 'Pause'
	TST.B	Consola(A3)
	BNE.S	NoNMI2

	BSET	#0,KeyX+3(A3)
	BEQ.S	SiNMI2
	BSET	#0,JoyX+3(A3)
	BNE.S	NoNMI2
SiNMI2:
	LEA	$66(A4),A5
NoNMI2:
	Otra2				; Interrumpiendo...
;	----------------
NoModo1:
	BMI.S	SiModo2			; ¿Es Modo IM 0?
	LEA	$66(A4),A5
	Otra2
;	----------------
SiModo2:
	MOVE.W	I(A3),D1
	ST	D1
	CogePag	D1,A4
	MOVE.W	(A4),D1
	ROR.W	#8,D1
	CogePag	D1,A5
	LEA	Restas(A3,D1.W*8),A7
	Otra2
;	----------------
; ---------------------------------<=




;	----------------
	CNOP	0,4
JumpCurLine:
	REPT	192
	DC.L	MiraInterBuc	; 0 -> 191
	ENDR
	DC.L	MiraInter192	; 192
	DC.L	MiraInter193	; 193
	REPT	224-194
	DC.L	MiraInterBuc2	; 194 -> 223
	ENDR
	REPT	255-224
	DC.L	MiraInterBuc3	; 224 -> 254
	ENDR
	DC.L	MiraInter255	; 255
	DC.L	MiraInterFin	; 256
	DC.L	MiraInterFin	; 257
	DC.L	MiraInterFin	; 258
;	----------------

; ---------------------------------=> Emulación de 1 Frame.
	CNOP	0,4
Emula1Frame:

	CMP.B	#1,DirPrefs+$13		; ¿Modo "Fast"?
	BEQ.S	ModoFrames

	CMP.B	#4,DirPrefs+$10
	BNE.S	ModoFrames
ModoAuto:
	TST.B	fps60Dat(A3)
	BNE.S	ModAutCon

	BSR	ImpFps			;  Calcula e Imprime fps
	BSR	Wait60fps		; Espera 60fps y mas rutinas
	RTS
	CNOP	0,4
ModAutCon:
	LEA	Regs(PC),A3
	BSR	ImprimeGfx		; Imprime Gfx en Fast
	LEA	Regs(PC),A3
	BSR	EscribeSpr		; Imprime Spr en Fast
	LEA	Regs(PC),A3
	BSR	ActCopperLine		; Crea CopperLine

	BSR	ImpFps			;  Calcula e Imprime fps
	BSR	Wait60fps		; Espera 60fps y mas rutinas

	LEA	Regs(PC),A3
	BSR	ImprimeGfx2
	BSR	ActualizaGFX
	LEA	Regs(PC),A3
	BSR	PrintSprChip
	RTS

; ---------------------------------=> Actualiza Gfx "modo Frames"
	CNOP	0,4
ModoFrames:
	LEA	Regs(PC),A3
	SUBQ.B	#1,GfxReCont(A3)
	BCC.S	SkipGfxFrame
	MOVE.B	DirPrefs+$10,GfxReCont(A3)
	BSR	ImprimeGfx		; Imprime Gfx en Fast
SkipGfxFrame:

	LEA	Regs(PC),A3
	SUBQ.B	#1,SprReCont(A3)
	BCC.S	SkipSprFrame
	MOVE.B	DirPrefs+$11,SprReCont(A3)
	BSR	EscribeSpr		; Imprime Spr en Fast
SkipSprFrame:

	LEA	Regs(PC),A3
	MOVE.B	DirPrefs+$10,D0
	CMP.B	GfxReCont(A3),D0
	BNE.S	SkipGfxFrame3
	BSR	ActCopperLine		; Crea CopperLine
SkipGfxFrame3:
; ---------------------------------<=

	BSR	ImpFps			;  Calcula e Imprime fps

	BSR	Wait60fps		; Espera 60fps y mas rutinas

; ---------------------------------=> Imprime Gfx y Spr de Fast a Chip.
	LEA	Regs(PC),A3
	MOVE.B	DirPrefs+$10,D0
	CMP.B	GfxReCont(A3),D0
	BNE.S	SkipGfxFrame2
	BSR	ImprimeGfx2
	BSR	ActualizaGFX
SkipGfxFrame2:
	LEA	Regs(PC),A3
	MOVE.B	DirPrefs+$11,D0
	CMP.B	SprReCont(A3),D0
	BNE.S	SkipSprFrame2
	BSR	PrintSprChip
SkipSprFrame2:
	RTS
; ---------------------------------<=

; ---------------------------------=> Espera a 60fps
	CNOP	0,4
Wait60fps:
	LEA	Regs(PC),A3
	IFD	AUTOTEST
	IFND	AUTOSYNC		; AUTOSYNC: real speed (sound recordings)
	BRA	NoWait60fps		; test builds run as fast as they can
	ENDC
	ENDC
	CMP.B	#2,DirPrefs+$13		; ¿Modo Turbo?
	BEQ.S	NoWait60fps

	TST.B	fps60Dat(A3)
	BEQ.S	NoWait60fps

;;OFROFO:
;;	BTST	#6,$BFE001
;;	BEQ.S	OFROFO

;;EWCCFT:
;;	CMP.B	#$FF,$DFF006
;;	BNE.S	EWCCFT


	MOVE.B	#2,fps60Dat(A3)
Wait60fpsBuc:
	CMP.B	#2,fps60Dat(A3)
	BEQ.S	Wait60fpsBuc
NoWait60fps:
	MOVE.B	#1,fps60Dat(A3)
; ---------------------------------<=

; ---------------------------------=> Coge ScanLine para calcular fps
	MOVE.W	#$4000,$DFF09A
	CLR.W	IntFpsConta
	BFEXTU	$DFF004{15:9},D0
	MOVE.W	D0,OldFpsDat
	MOVE.W	#$C000,$DFF09A
; ---------------------------------<=

;;	MOVE.W	#$00A,$DFF180

; ---------------------------------=> Pone en Copper Nuevo CopperLine
	MOVE.L	CopperLineUno,D0
CopLinWait:
	CMP.B	#$78,$DFF007
	BCC.S	CopLinWait
	MOVE.W	D0,CopperLineJmp+6
	SWAP	D0
	MOVE.W	D0,CopperLineJmp+2
; ---------------------------------<=

; ---------------------------------=>
;;;	BSR	PonePaletaMS
	BSR	TocaPSG
; ---------------------------------<=

	RTS

; ---------------------------------=> Calcula e imprime fps
	IFEQ	ShowFps
	CNOP	0,4
ImpFps:
	TST.B	DirPrefs+$12
	BEQ	SkipFpsRut

	SUBQ.W	#1,WaitFpsConta
	BCC	SkipFpsRut
	MOVE.W	#16,WaitFpsConta

	MOVE.W	#$4000,$DFF09A

	MOVE.W	IntFpsConta,D1
	MOVE.W	#$139,D2	; PAL
	TST.B	DirPrefs+$0F
	BEQ.S	FpsRutCon
	MOVE.W	#$107,D2	; NTSC
FpsRutCon:
	MULU	D2,D1
	BFEXTU	$DFF004{15:9},D0
	ADD.W	D1,D0
	MOVE.W	OldFpsDat,D1
	SUB.W	D1,D0

	MOVE.W	D0,LinesFpsDat

	MOVE.L	#VPeriod*256,D1
	DIVU	D0,D1
	MULU	#60,D1
	LSR.L	#8,D1

	CMP.W	#399,D1
	BCS.S	ShoFpsCon
	MOVE.W	#399,D1
ShoFpsCon:
	MOVE.W	(HexDecTab.W,PC,D1.W*2),D0

	MOVE.W	D0,D1
	LSR.W	#8,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+1,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	D0,D1
	LSR.W	#4,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+2,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	D0,D1
	AND.W	#$000F,D1
	LEA	(Font,D1.W),A0
	LEA	Panel+3,A1
	REPT	8
	MOVE.B	(A0),(A1)
	ADD.W	#10,A0
	ADD.W	#32,A1
	ENDR

	MOVE.W	#$C000,$DFF09A
SkipFpsRut:
	RTS
	ENDC
; ---------------------------------<=

;	----------------
		DS.L	400	; No Quitar. (Va delante de BufBasura)
BufBasura:	DS.L	400
		DC.L	0,0	; Seg:
;	----------------


	CNOP	0,8
HexDecTab:
	DC.W	$00,$01,$02,$03,$04,$05,$06,$07,$08,$09
	DC.W	$10,$11,$12,$13,$14,$15,$16,$17,$18,$19
	DC.W	$20,$21,$22,$23,$24,$25,$26,$27,$28,$29
	DC.W	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39
	DC.W	$40,$41,$42,$43,$44,$45,$46,$47,$48,$49
	DC.W	$50,$51,$52,$53,$54,$55,$56,$57,$58,$59
	DC.W	$60,$61,$62,$63,$64,$65,$66,$67,$68,$69
	DC.W	$70,$71,$72,$73,$74,$75,$76,$77,$78,$79
	DC.W	$80,$81,$82,$83,$84,$85,$86,$87,$88,$89
	DC.W	$90,$91,$92,$93,$94,$95,$96,$97,$98,$99
	DC.W	$100,$101,$102,$103,$104,$105,$106,$107,$108,$109
	DC.W	$110,$111,$112,$113,$114,$115,$116,$117,$118,$119
	DC.W	$120,$121,$122,$123,$124,$125,$126,$127,$128,$129
	DC.W	$130,$131,$132,$133,$134,$135,$136,$137,$138,$139
	DC.W	$140,$141,$142,$143,$144,$145,$146,$147,$148,$149
	DC.W	$150,$151,$152,$153,$154,$155,$156,$157,$158,$159
	DC.W	$160,$161,$162,$163,$164,$165,$166,$167,$168,$169
	DC.W	$170,$171,$172,$173,$174,$175,$176,$177,$178,$179
	DC.W	$180,$181,$182,$183,$184,$185,$186,$187,$188,$189
	DC.W	$190,$191,$192,$193,$194,$195,$196,$197,$198,$199
	DC.W	$200,$201,$202,$203,$204,$205,$206,$207,$208,$209
	DC.W	$210,$211,$212,$213,$214,$215,$216,$217,$218,$219
	DC.W	$220,$221,$222,$223,$224,$225,$226,$227,$228,$229
	DC.W	$230,$231,$232,$233,$234,$235,$236,$237,$238,$239
	DC.W	$240,$241,$242,$243,$244,$245,$246,$247,$248,$249
	DC.W	$250,$251,$252,$253,$254,$255,$256,$257,$258,$259
	DC.W	$260,$261,$262,$263,$264,$265,$266,$267,$268,$269
	DC.W	$270,$271,$272,$273,$274,$275,$276,$277,$278,$279
	DC.W	$280,$281,$282,$283,$284,$285,$286,$287,$288,$289
	DC.W	$290,$291,$292,$293,$294,$295,$296,$297,$298,$299
	DC.W	$300,$301,$302,$303,$304,$305,$306,$307,$308,$309
	DC.W	$310,$311,$312,$313,$314,$315,$316,$317,$318,$319
	DC.W	$320,$321,$322,$323,$324,$325,$326,$327,$328,$329
	DC.W	$330,$331,$332,$333,$334,$335,$336,$337,$338,$339
	DC.W	$340,$341,$342,$343,$344,$345,$346,$347,$348,$349
	DC.W	$350,$351,$352,$353,$354,$355,$356,$357,$358,$359
	DC.W	$360,$361,$362,$363,$364,$365,$366,$367,$368,$369
	DC.W	$370,$371,$372,$373,$374,$375,$376,$377,$378,$379
	DC.W	$380,$381,$382,$383,$384,$385,$386,$387,$388,$389
	DC.W	$390,$391,$392,$393,$394,$395,$396,$397,$398,$399


; ---------------------------------<=



; -------------------------------------> Interrupción de Vblank la 1ª vez.
	CNOP	0,8
InInter:
	MOVE.W	#$2700,SR
	MOVE.L	DirContinua,2(SP)
	MOVE.B	DirFlags+1,1(SP)
	MOVE.L	#Inter,([VBRPun],$6C.W)

	MOVE.L	(A3,D2.W*8),2(SP)		; prueba ;

	MOVE.W	#$0030,$DFF09C

	BRA	Inter
; -------------------------------------<

	CNOP	0,8
IntFpsConta:	DC.W	0
WaitFpsConta:	DC.W	0
OldFpsDat:	DC.W	0
LinesFpsDat:	DC.W	0

	CNOP	0,8
Inter:
	MOVE.W	#$2700,SR
	BTST	#5,$DFF01F
	BEQ.S	VDPEmul
	ADDQ.W	#1,IntFpsConta
	MOVE.W	#$0020,$DFF09C
	NOP
	RTE

	CNOP	0,8
VDPEmul:
	MOVEM.L	D0-D7/A0-A6,-(SP)

	LEA	Regs(PC),A3

; ------------------------------>
	SUBQ.B	#1,fps60Dat(A3)
	BCC.S	fps60NoDes
	SF	fps60Dat(A3)
fps60NoDes:
; ------------------------------<

	BSR	PoneSystem

; ---------------------------------------=> Lectura de JoySticks
	JSR	([JoyControlRut.w,PC])
	JSR	MiraTeclado
	JSR	([JoyControlRut2.w,PC])

	LEA	Regs(PC),A3
	MOVE.L	KeyX(A3),D1
; -----------------------------------=> No illogical moves.
	TST.B	DirPrefs+$14
	BEQ.S	AllMoves
	BFTST	D1{4:2}
	BNE.S	LogicalX
	OR.L	#$0C000000,D1
LogicalX:
	BFTST	D1{6:2}
	BNE.S	LogicalY
	OR.L	#$03000000,D1
LogicalY:
AllMoves:
; -----------------------------------<=
	AND.L	D1,JoyX(A3)
; -----------------------------------<=

; ---------------------------------------=> Swap JoyPorts
	TST.B	DirPrefs+$17
	BEQ.S	NoSwapJoyPorts

	MOVE.W	JoyX+0(A3),D0
	ROL.W	#2,D0
	AND.W	#$003F,D0
	MOVE.B	JoyX+0(A3),D1
	LSL.W	#6,D1
	OR.W	D1,D0
	OR.W	#$F000,D0
	ROR.W	#8,D0
	MOVE.W	D0,JoyX+0(A3)
NoSwapJoyPorts:
; ---------------------------------------<=

;	MOVE.W	#$A00,$DFF180

	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$0010,$DFF09C
	NOP
	RTE

	CNOP	0,8
JoyControlRut:	DC.L	LeeJoyStick
JoyControlRut2:	DC.L	LeeJoyStick

; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;



; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

ActCopperLine:
; ----------------------------------=> Prepara Tabla de colores en CopperLine
	LEA	TabRasRGB,A0
	MOVE.L	TabRasRGBcnt(PC),A1
	CMP.L	A0,A1
	BEQ.S	RGBCont
	LEA	TabRasCMDS,A2
	MOVEQ	#0,D1
RGBBuc:
	MOVE.B	(A0),D1
	OR.B	#$04,(A2,D1.W)
	ADDQ.W	#4,A0
	CMP.L	A1,A0
	BCS.S	RGBBuc
RGBCont:
	ST	(A1)
	MOVE.L	#TabRasRGB,TabRasRGBcnt
; ----------------------------------<=

; ----------------------------------=> Pone datos de posible desbordamiento de BG.
	MOVE.W	#$E0,D1
	SUB.B	TabRasDATA(PC),D1
	OR.B	#$01,(TabRasCMDS.L,D1.W)
; ----------------------------------<=

; ----------------------------------=> Chapuza para Game Gear.

	OR.B	#$80,TabRasCMDS+$00	; Pone 5 Bpl para sms

	TST.B	Regs+Consola(PC)
	BEQ.S	EsMasSysCon

	AND.B	#$7F,TabRasCMDS+$00
	OR.B	#$81,TabRasCMDS+$18
EsMasSysCon:
; ----------------------------------<=

; ----------------------------------=> Mira y pone modo 16 lineas UP.
	BTST	#6,VDPRegs+$0(PC)
	BEQ.S	NoScr16Up
	LEA	TabRasCMDS+1,A0
	OR.B	#$02,16-1(A0)
	MOVE.L	TabRasDATA,TabRasDATA+(16*8)
	SF	TabRasDATA+2		; Pone a 0 Coor X
	MOVE.L	#$FDFDFDFD,D0
	AND.B	D0,(A0)+
	AND.W	D0,(A0)+
	AND.L	D0,(A0)+
	AND.L	D0,(A0)+
	AND.L	D0,(A0)+
NoScr16Up:
; ----------------------------------<=

; ----------------------------------=> Borra CopperLine de frame anterior.
	MOVE.L	TabRasRESTDos,A0
	MOVE.W	(A0),D0
	BMI.S	AcCoCon0
	MOVE.W	#-1,(A0)+
AcCoBuc0:
	MOVE.W	#$00FC,([A0])
	ADDQ.W	#4,A0
	DBF	D0,AcCoBuc0
AcCoCon0:
; ----------------------------------<=

; ----------------------------------=> CopperLine Base.
	MOVE.L	TabRasRESTDos,A2
	ADDQ.W	#2,A2
	MOVE.L	CopperOptsDos,A3
	MOVE.L	CopperLineDos,A5

	LEA	TabRasCMDS,A6
	MOVE.W	#(192)-1,D6
	MOVEQ	#0,D7
AcCoBuc:
	TST.B	(A6)+
	BNE	AcCoRut
AcCoRet:
	ADDQ.B	#1,D7
	DBF	D6,AcCoBuc
; ----------------------------------<=

; ----------------------------------=> Intercambia Base de Tablas dobles.
	MOVE.L	TabRasRESTDos,A0
	MOVE.L	TabRasRESTUno,TabRasRESTDos
	MOVE.L	A0,TabRasRESTUno

	MOVE.L	CopperOptsDos,A0
	MOVE.L	CopperOptsUno,CopperOptsDos
	MOVE.L	A0,CopperOptsUno

	MOVE.L	CopperLineDos,A0
	MOVE.L	CopperLineUno,CopperLineDos
	MOVE.L	A0,CopperLineUno
; ----------------------------------<=
	RTS

; ----------------------------------=>
	CNOP	0,8
AcCoRut:
	MOVE.B	-(A6),D5
	SF	(A6)+

	MOVE.W	D7,D1

	MULU	#(CoppLineSize),D1
	LEA	$0A(A5,D1.W),A4

	MOVE.L	A3,D3
	MOVE.W	D3,(A4)+
	SWAP	D3
	MOVE.W	D3,-6(A4)

	LEA	(CoppLineSize)(A5,D1.W),A4
	MOVE.L	A4,-(SP)

	SUBQ.W	#4,A4
	MOVE.W	#$008A,(A4)

	MOVE.L	A4,(A2)+
	ADDQ.W	#1,([TabRasRESTDos])

	IFEQ	ColorDebug			;*;
	MOVE.L	#$01800A00,(A3)+		;*;
	ENDC					;*;


	TST.B	D5
	BPL.S	AcCoRet7
	MOVE.L	#$01005001,(A3)+
AcCoRet7:


	LSR.B	#1,D5
	BCS	AcCoRutBGY
AcCoRet0:
	LSR.B	#1,D5
	BCS	AcCoRutBGX
AcCoRet1:
	LSR.B	#1,D5
	BCS	AcCoRutRGB
AcCoRet2:
;	LSR.B	#1,D5
;	BCS	AcCoRutWinX
;AcCoRet3:
;	LSR.B	#1,D5
;	BCS	AcCoRutColorBG
;AcCoRet4:

	IFEQ	ColorDebug			;*;
	MOVE.W	#$0180,(A3)+			;*;
	MOVE.W	Color0+2,(A3)+			;*;
	ENDC					;*;


	MOVE.L	(SP)+,D3

	MOVE.W	#$0086,(A3)+
	MOVE.W	D3,(A3)+
	MOVE.W	#$0084,(A3)+		; Retorno Copper 
	SWAP	D3
	MOVE.W	D3,(A3)+

	MOVE.L	#$008A0000,(A3)+

	BRA	AcCoRet
; ----------------------------------<=

; ----------------------------------=> Actualiza RGB en CopperLine
AcCoRutRGB:
	MOVE.L	TabRasRGBcnt(PC),A0
AcCoRutRGBbuc:
	CMP.B	(A0)+,D7
	BNE.S	AcCoRutRGBfin

	MOVEQ	#0,D1
	MOVE.B	(A0)+,D1
	LSL.W	#1,D1
	ADD.W	#$0180,D1
	MOVE.W	D1,(A3)+

	TST.B	Regs+Consola(PC)
	BNE.S	ConvPalGG

	MOVE.W	(A0)+,D2
	MOVEQ	#0,D1
	BFINS	D2,D1{20:2}	; R
	LSR.B	#2,D2
	BFINS	D2,D1{24:2}	; G
	LSR.B	#2,D2
	BFINS	D2,D1{28:2}	; B
	IFD	AMG_PALFULL
	MOVE.W	D1,D2			; each 4-bit level = 2-bit level * 5
	LSR.W	#2,D2
	OR.W	D2,D1
	ENDC
	BRA.S	ConvPalMS
ConvPalGG:
	MOVE.W	(A0)+,D1
	ROR.L	#4,D1
	LSR.W	#4,D1
	ROR.B	#4,D1
	ROL.L	#4,D1
ConvPalMS:

	MOVE.W	D1,(A3)+

	BRA.S	AcCoRutRGBbuc

AcCoRutRGBfin:
	SUBQ.W	#1,A0
	MOVE.L	A0,TabRasRGBcnt
	BRA.S	AcCoRet2
; ----------------------------------<=

; ----------------------------------=> Actualiza Scroll Y en BG.
	CNOP	0,8
AcCoRutBGY:
	LSR.B	#1,D5
	BCS.S	AcCoRutBGX
	MOVE.B	Regs+UltCoorX(PC),(TabRasDATA+2.L,D7.W*8)
; ----------------------------------=> Actualiza Scroll X en BG.
AcCoRutBGX:
	LEA	(TabRasDATA.L,D7.W*8),A0

	MOVEQ	#0,D2
	MOVE.B	Regs+UltCoorY(PC),D2	; BG Coor Y	; antes => (A0)
	ADD.W	D7,D2

	CMP.W	#$E0,D2
	BCS.S	SehaDesb
	ADD.B	#$20,D2
	AND.W	#$00FF,D2
SehaDesb:

	MOVE.L	D2,D1
	LSL.W	#8,D1
	ADD.L	#Plano5,D1	; Destino en Coor Y

	MOVEQ	#0,D0
	MOVE.B	2(A0),D0	; BG Coor X
	MOVE.B	D0,Regs+UltCoorX
	NEG.B	D0
	LEA	(DATOSS.L,D0.W*8),A1
	ADD.L	(A1)+,D1	; Destino más Coor X.

	MOVE.W	#$00F2,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	MOVE.W	#$00F0,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1

	SUB.L	#SizePl5PaGx,D1

	MOVE.W	#$00E2,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	MOVE.W	#$00E0,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	ADD.L	#NEXBPL,D1
	MOVE.W	#$00E6,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	MOVE.W	#$00E4,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	ADD.L	#NEXBPL,D1
	MOVE.W	#$00EA,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	MOVE.W	#$00E8,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	ADD.L	#NEXBPL,D1
	MOVE.W	#$00EE,(A3)+
	MOVE.W	D1,(A3)+
	SWAP	D1
	MOVE.W	#$00EC,(A3)+
	MOVE.W	D1,(A3)+

	MOVE.L	(A1),(A3)+		; Pone Rotación.

	BRA	AcCoRet1
; ----------------------------------<=

	IFEQ	ColorDebug			;*;
	MOVE.W	#$0180,(A3)+			;*;
	MOVE.W	Color0+2,(A3)+			;*;
	ENDC					;*;


	MOVE.L	(SP)+,D3

	MOVE.W	#$0086,(A3)+
	MOVE.W	D3,(A3)+
	MOVE.W	#$0084,(A3)+		; Retorno Copper 
	SWAP	D3
	MOVE.W	D3,(A3)+

	MOVE.L	#$008A0000,(A3)+

	BRA	AcCoRet
; ----------------------------------<=


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


	CNOP	0,8
PoneSystem:
	TST.B	Regs+Consola(PC)
	BNE.S	PoneSystemGG
	MOVE.L	#$3BA1,D0
	BTST	#5,VDPRegs+0(PC)
	BEQ.S	NoLeftClip
	ADDQ.B	#$8,D0
NoLeftClip:
	MOVE.W	D0,Bordes+2
PoneSystemGG:
; -------------------------------------> Contador de tiempo 2. (proteccion anti-hackers)
;	LEA	Regs(PC),A3
;	LEA	DirPrefs+$1B-$5216,A0
;	MOVEQ	#0,D1
;	MOVE.B	$5216(A0),D1
;	LSR.B	#5,D1
;	ADD.W	D1,Contador1(A3)
;	BCC.S	Conta2Fin
;	MOVE.L	$1C3*8(A3),$1CD*8(A3)
;Conta2Fin:
; -------------------------------------<
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


MARI:	MACRO
	DC.L	\1,$01020000

	DC.L	\2,$010244FF
	DC.L	\2,$010244EE
	DC.L	\2,$010244DD
	DC.L	\2,$010244CC
	DC.L	\2,$010244BB
	DC.L	\2,$010244AA
	DC.L	\2,$01024499
	DC.L	\2,$01024488
	DC.L	\2,$01024477
	DC.L	\2,$01024466
	DC.L	\2,$01024455
	DC.L	\2,$01024444
	DC.L	\2,$01024433
	DC.L	\2,$01024422
	DC.L	\2,$01024411
	DC.L	\2,$01024400

	DC.L	\2,$010200FF
	DC.L	\2,$010200EE
	DC.L	\2,$010200DD
	DC.L	\2,$010200CC
	DC.L	\2,$010200BB
	DC.L	\2,$010200AA
	DC.L	\2,$01020099
	DC.L	\2,$01020088
	DC.L	\2,$01020077
	DC.L	\2,$01020066
	DC.L	\2,$01020055
	DC.L	\2,$01020044
	DC.L	\2,$01020033
	DC.L	\2,$01020022
	DC.L	\2,$01020011

	ENDM

	CNOP	0,8
DATOSS:
	MARI	-4,0
	MARI	0,4
	MARI	4,8
	MARI	8,12
	MARI	12,16
	MARI	16,20
	MARI	20,24
	MARI	24,28



; -------------------------------------------- ;
; -------------------------------------------- ;

	CNOP	0,8
ImprimeGfx:
	IFD	AMG_TMSMODES
	BTST	#2,VDPRegs+0(PC)	; TMS9918 modes (M4 clear), or one just left: Amg10.asm
	BEQ.S	AmgTmsH0
	TST.B	AmgTmsOn
	BEQ.S	AmgTmsH1
AmgTmsH0:	JMP	AmgTmsGfx
AmgTmsH1:
	ENDC
	LEA	PantAnt(PC),A5		; Código texto actualmente impreso.

	LEA	TablaFlipX,A6		; Tabla para modo Flip X

	LEA	VRAM,A0			; Base de la VRAM
	MOVE.B	VDPRegs+2(PC),D0
	AND.W	#$000E,D0
	LSL.W	#7,D0
	LEA	(A0,D0.W*8),A1		; Código texto.

	LEA	PantGfxFast,A2		; Destino

	MOVE.L	A7,-4(A6)		; Guarda Pila.
	LEA	TabDirRef(PC),A7	; Puntero de Gráficos modificados.

	MOVE.L	#TabHideSpr,CntHideSpr	; Inicializa contador.
	MOVE.L	#TabBorGfx,CntBorGfx	; Inicializa contador.

	MOVEQ	#(28)-1,D0		; Número de líneas.
ImpGfxBuc0:
	MOVEQ	#0,D7			; Bits de actualización de Gfx.
	MOVEQ	#(32)-1,D1		; Número de Caracteres por línea.
ImpGfxBuc1:
	CMP.W	(A1)+,(A5)+
	BNE.S	ImpGfxRut

	TST.B	([A7])
	BNE.S	ImpGfxRut
	ADDQ	#4,A7

	ADDQ.L	#1,CntHideSpr

	ADDQ	#1,A2			; Siguiente Caracter en Destino.
	DBF	D1,ImpGfxBuc1

	MOVE.B	D7,([CntBorGfx])
	ADDQ.L	#1,CntBorGfx

	ADD.W	#(64*8*4)-32,A2		; Siguiente Línea en Destino.
	DBF	D0,ImpGfxBuc0

	MOVE.L	-4(A6),A7		; Recupera Pila.
	RTS

	CNOP	0,4
ImpGfxRut:
	MOVE.W	-(A1),-(A5)		; Copia nuevo código de texto.

	MOVE.W	(A1)+,D2
	ROR.W	#1,D2
	LSR.W	#7,D2
	LEA	(Regs+TabRedef.W,PC,D2.W),A3
	MOVE.L	A3,(A7)+

	MOVEQ	#0,D2
	MOVE.B	(A5)+,D2

	LSL.W	#2,D2
	LEA	(A0,D2.W*8),A3		; Puntero al Gfx del caracter.

	BTST	#0,(A5)			; Mira tipo de tabla en VRAM.
	BEQ.S	ImpGfxCon0
	ADD.W	#$2000,A3
ImpGfxCon0:


; -=-
	MOVE.L	A2,A4
	SUB.L	#PantGfxFast,A4
	ADD.L	#Plano5,A4

	BTST	#3,(A5)			; ¿Segunda paleta?
	BEQ.S	PonePalCon
	MOVEQ	#-1,D2
	TST.B	32*32*2(A5)
	BNE.S	PonePalFin
	ST	32*32*2(A5)
	BRA.S	PonePalRut
PonePalCon:
	MOVEQ	#0,D2
	TST.B	32*32*2(A5)
	BEQ.S	PonePalFin
	SF	32*32*2(A5)
PonePalRut:
	REPT	8
	MOVE.B	D2,(A4)
	MOVE.B	D2,32(A4)
	ADD.W	#(64*4),A4		; Siguiente Línea en Destino.
	ENDR
PonePalFin:
; -=-

	BTST	#4,(A5)			; ¿Hide Sprites?
	SEQ	([CntHideSpr])
	ADDQ.L	#1,CntHideSpr


; -=-


	BTST	#2,(A5)			; ¿Flip Y?
	BNE	ImpGfxFlipY

	BTST	#1,(A5)+		; ¿Flip X?
	BNE	ImpGfxFlipX


	MOVE.B	(A3),(A2)+
	MOVE.B	(A3)+,32-1(A2)

ImpGfxSuma:SET	1
	REPT	(8*4)-1
	MOVE.B	(A3)+,(64*ImpGfxSuma)-1(A2)
ImpGfxSuma:SET	ImpGfxSuma+1
	ENDR

	OR.B	(TabClrGfx.W,PC,D1.W),D7

	DBF	D1,ImpGfxBuc1

	MOVE.B	D7,([CntBorGfx])
	ADDQ.L	#1,CntBorGfx

	ADD.W	#(64*8*4)-32,A2		; Siguiente Línea en Destino.
	DBF	D0,ImpGfxBuc0

	MOVE.L	-4(A6),A7		; Recupera Pila.
	RTS
;	=---------=
	CNOP	0,4
ImpGfxFlipX:

	MOVEQ	#0,D2

	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(A2)+
	MOVE.B	(A6,D2.W),32-1(A2)

ImpGfxSuma:SET	1
	REPT	(8*4)-1
	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*ImpGfxSuma)-1(A2)
ImpGfxSuma:SET	ImpGfxSuma+1
	ENDR

	OR.B	(TabClrGfx.W,PC,D1.W),D7

	DBF	D1,ImpGfxBuc1

	MOVE.B	D7,([CntBorGfx])
	ADDQ.L	#1,CntBorGfx

	ADD.W	#(64*8*4)-32,A2		; Siguiente Línea en Destino.
	DBF	D0,ImpGfxBuc0

	MOVE.L	-4(A6),A7		; Recupera Pila.
	RTS
;	=---------=
	CNOP	0,4
ImpGfxFlipY:
	BTST	#1,(A5)+		; ¿Flip X?
	BNE	ImpGfxFlipYX

ImpGfxSuma:SET	(7*4)
	REPT	(8)-1
	MOVE.B	(A3)+,(64*ImpGfxSuma)(A2)
	MOVE.B	(A3)+,(64*(ImpGfxSuma+1))(A2)
	MOVE.B	(A3)+,(64*(ImpGfxSuma+2))(A2)
	MOVE.B	(A3)+,(64*(ImpGfxSuma+3))(A2)
ImpGfxSuma:SET	ImpGfxSuma-4
	ENDR

	MOVE.B	(A3)+,(A2)+
	MOVE.B	(A3)+,(64*1)-1(A2)
	MOVE.B	(A3)+,(64*2)-1(A2)
	MOVE.B	(A3)+,(64*3)-1(A2)

	OR.B	(TabClrGfx.W,PC,D1.W),D7

	DBF	D1,ImpGfxBuc1

	MOVE.B	D7,([CntBorGfx])
	ADDQ.L	#1,CntBorGfx

	ADD.W	#(64*8*4)-32,A2		; Siguiente Línea en Destino.
	DBF	D0,ImpGfxBuc0

	MOVE.L	-4(A6),A7		; Recupera Pila.
	RTS
;	=---------=
	CNOP	0,4
ImpGfxFlipYX:

	MOVEQ	#0,D2

ImpGfxSuma:SET	(7*4)
	REPT	(8)-1
	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*ImpGfxSuma)(A2)

	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*(ImpGfxSuma+1))(A2)

	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*(ImpGfxSuma+2))(A2)

	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*(ImpGfxSuma+3))(A2)
ImpGfxSuma:SET	ImpGfxSuma-4
	ENDR

	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(A2)+
	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*1)-1(A2)
	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*2)-1(A2)
	MOVE.B	(A3)+,D2
	MOVE.B	(A6,D2.W),(64*3)-1(A2)

	OR.B	(TabClrGfx.W,PC,D1.W),D7

	DBF	D1,ImpGfxBuc1

	MOVE.B	D7,([CntBorGfx])
	ADDQ.L	#1,CntBorGfx

	ADD.W	#(64*8*4)-32,A2		; Siguiente Línea en Destino.
	DBF	D0,ImpGfxBuc0

	MOVE.L	-4(A6),A7		; Recupera Pila.
	RTS
;	=---------=

	CNOP	0,8
PantAnt:	DS.W	32*32	; No tocar el orden.
Pant32:		DS.W	32*32	; No tocar el orden.

TabHideSpr:	DS.B	32*32

TabDirRef:	REPT	32*32
		DC.L	Ceros
		ENDR

; -------------------------------------------- ;
; ------------------------------------------------ ;


	CNOP	0,8
ImprimeGfx2:


; ---
	TST.B	DirPrefs+$1D
	BNE	ImprimeGfx2Pri
; ---


	LEA	TabBorGfx(PC),A0
	LEA	PantGfxFast,A1
	LEA	PantGfx,A5
	MOVE.W	#(28)-1,D0
BucGfx0:
	MOVE.B	(A0)+,D2
	BEQ.S	ConGfx1

	MOVE.W	#8-1,D1
BucGfx1:
	LSL.B	#1,D2
	BCC.S	ConGfx0

	MOVE.W	#8-1,D3
	MOVE.L	A1,A2
	MOVE.L	A5,A6
BucGfx2:
	MOVE.L	(64*3)(A2),(64*3)(A6)
	MOVE.L	(64*3)(A2),(64*3)+32(A6)
	MOVE.L	(64*2)(A2),(64*2)(A6)
	MOVE.L	(64*2)(A2),(64*2)+32(A6)
	MOVE.L	(64*1)(A2),(64*1)(A6)
	MOVE.L	(64*1)(A2),(64*1)+32(A6)
	MOVE.L	(A2),(A6)
	MOVE.L	(A2),32(A6)
	ADD.W	#(64*4),A2
	ADD.W	#(64*4),A6
	DBF	D3,BucGfx2
ConGfx0:
	ADDQ	#4,A1
	ADDQ	#4,A5
	DBF	D1,BucGfx1
	CLR.B	-1(A0)
	ADD.W	#(64*4*8)-32,A1
	ADD.W	#(64*4*8)-32,A5
	DBF	D0,BucGfx0
	BRA.S	FinGfx
	CNOP	0,4
ConGfx1:
	ADD.W	#(64*4*8),A1
	ADD.W	#(64*4*8),A5
	DBF	D0,BucGfx0
FinGfx:
	RTS

; ---

	CNOP	0,4
ImprimeGfx2Pri:
	LEA	TabBorGfx(PC),A0
	LEA	PantGfxMask+(15*36),A3
	LEA	PantGfxFast,A1
	LEA	PantGfx,A5
	LEA	TabHideSpr(PC),A4

	MOVE.W	#(28)-1,D0
BucGfxp0:
	MOVE.B	(A0)+,D2
	BEQ	ConGfxp1

	MOVE.W	#8-1,D1
BucGfxp1:
	LSL.B	#1,D2
	BCC.S	ConGfxp0

	MOVE.W	#8-1,D3
	MOVE.L	A1,A2
	MOVE.L	A5,A6

	MOVE.L	A3,-(SP)
BucGfxp2:
	MOVE.L	(64*3)(A2),D7
	MOVE.L	D7,(64*3)(A6)
	MOVE.L	D7,(64*3)+32(A6)

	OR.L	(64*2)(A2),D7
	MOVE.L	(64*2)(A2),(64*2)(A6)
	MOVE.L	(64*2)(A2),(64*2)+32(A6)

	OR.L	(64*1)(A2),D7
	MOVE.L	(64*1)(A2),(64*1)(A6)
	MOVE.L	(64*1)(A2),(64*1)+32(A6)

	OR.L	(A2),D7
	MOVE.L	(A2),(A6)
	MOVE.L	(A2),32(A6)

	NOT.L	D7
	OR.L	(A4),D7		; */*/*/**/*/*/
	MOVE.L	D7,(A3)

	ADD.W	#(36),A3
	ADD.W	#(64*4),A2
	ADD.W	#(64*4),A6
	DBF	D3,BucGfxp2

	MOVE.L	(SP)+,A3

ConGfxp0:
	ADDQ	#4,A4

	ADDQ	#4,A3
	ADDQ	#4,A1
	ADDQ	#4,A5
	DBF	D1,BucGfxp1

	ADD.W	#(36*8)-32,A3

	TST.B	-(A0)
	BPL.S	NoRefCol1
	MOVE.L	-(36*8)(A3),-(36*8)+32(A3)
	MOVE.L	-(36*7)(A3),-(36*7)+32(A3)
	MOVE.L	-(36*6)(A3),-(36*6)+32(A3)
	MOVE.L	-(36*5)(A3),-(36*5)+32(A3)
	MOVE.L	-(36*4)(A3),-(36*4)+32(A3)
	MOVE.L	-(36*3)(A3),-(36*3)+32(A3)
	MOVE.L	-(36*2)(A3),-(36*2)+32(A3)
	MOVE.L	-(36*1)(A3),-(36*1)+32(A3)
NoRefCol1:
	CLR.B	(A0)+

	ADD.W	#(64*4*8)-32,A1
	ADD.W	#(64*4*8)-32,A5
	DBF	D0,BucGfxp0
	BRA.S	FinGfxp
	CNOP	0,4
ConGfxp1:
	ADD.W	#(32),A4

	ADD.W	#(36*8),A3
	ADD.W	#(64*4*8),A1
	ADD.W	#(64*4*8),A5
	DBF	D0,BucGfxp0
FinGfxp:
	RTS


	CNOP	0,8
CntHideSpr:	DC.L	0
CntBorGfx:	DC.L	0
TabBorGfx:	DS.B	32

TabClrGfx:
	DC.B	$01,$01,$01,$01
	DC.B	$02,$02,$02,$02
	DC.B	$04,$04,$04,$04
	DC.B	$08,$08,$08,$08
	DC.B	$10,$10,$10,$10
	DC.B	$20,$20,$20,$20
	DC.B	$40,$40,$40,$40
	DC.B	$80,$80,$80,$80


; ------------------------------------------------ ;
; ------------------------------------------------ ;

	CNOP	0,8
ActualizaGFX:
	LEA	Regs+TabRedef+$200(PC),A6
	MOVEM.L	Ceros(PC),D0-D7/A0-A5
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D7/A0-A5,-(A6)
	MOVEM.L	D0-D1,-(A6)
	RTS

	CNOP	0,8
Ceros:		DS.L	16



	LEA	VRAM,A0			; Base de la VRAM
	MOVE.B	VDPRegs+2(PC),D0
	AND.W	#$000E,D0
	LSL.W	#7,D0
	LEA	(A0,D0.W*8),A0		; Código texto.
	LEA	PantAnt(PC),A1
	LEA	Regs+TabRedef(PC),A2
	MOVE.W	#((32*28)/4)-1,D0
	MOVEQ	#0,D1
ActGfxBuc0:
	MOVE.W	(A0)+,D1
	ROR.W	#1,D1
	LSR.W	#7,D1
	TST.B	(A2,D1.W)
	BEQ.S	NoRedef4
	NOT.B	D1
	MOVE.B	D1,(A1)
NoRedef4:
	MOVE.W	(A0)+,D1
	ROR.W	#1,D1
	LSR.W	#7,D1
	TST.B	(A2,D1.W)
	BEQ.S	NoRedef5
	NOT.B	D1
	MOVE.B	D1,2(A1)
NoRedef5:
	MOVE.W	(A0)+,D1
	ROR.W	#1,D1
	LSR.W	#7,D1
	TST.B	(A2,D1.W)
	BEQ.S	NoRedef6
	NOT.B	D1
	MOVE.B	D1,4(A1)
NoRedef6:
	MOVE.W	(A0)+,D1
	ROR.W	#1,D1
	LSR.W	#7,D1
	TST.B	(A2,D1.W)
	BEQ.S	NoRedef7
	NOT.B	D1
	MOVE.B	D1,6(A1)
NoRedef7:
	ADDQ	#8,A1
	DBF	D0,ActGfxBuc0

	RTS

; ------------------------------------------------ ;





; -------------------------------------------- ;

	CNOP	0,8
EscribeSpr:
	IFD	AMG_TMSMODES
	BTST	#2,VDPRegs+0(PC)	; TMS9918 sprites: Amg10.asm
	BNE.S	AmgTmsS1
	JMP	AmgTmsSpr
AmgTmsS1:
	ENDC

	MOVE.L	#$00FE000F,D7
	BTST	#1,VDPRegs+1(PC)
	BNE.S	SonDe16
	MOVE.L	#$00FF0007,D7
SonDe16:

	MOVEQ	#8,D6
	BTST	#3,VDPRegs+0(PC)
	BNE.S	Resta8
	MOVEQ	#0,D6
Resta8:

	LEA	VRAM,A0
	BTST	#2,VDPRegs+6(PC)
	BEQ.S	SPRTITE0
	ADD.W	#$2000,A0
SPRTITE0:

	MOVE.B	VDPRegs+5(PC),D3	; Calcula Dir. de Spr Coors en VRAM.
	LSL.W	#7,D3
	AND.W	#$3F00,D3
	LEA	VRAM,A4
	ADD.W	D3,A4
	LEA	$80(A4),A5


	LEA	PantSprFast,A2

; ---
	TST.B	DirPrefs+$1C		; Sprites Priorities.
	BEQ	NoSprPri
; ---

; ---
	MOVE.W	#$D0,D3
	MOVEQ	#64-1,D0		; 64 Sprits a imprimir.
SPR2PBUC1:
	CMP.B	(A4)+,D3
	BEQ.S	EncontD0
	ADDQ	#2,A5
	DBF	D0,SPR2PBUC1
	MOVEQ	#(64)-1,D3
	BRA.S	SBUC3b
EncontD0:
	MOVEQ	#64-2,D3		; 64 Sprits a imprimir.
	SUB.W	D0,D3
	BMI	FinalSpr2
	SUBQ	#1,A4
SBUC3b:
	MOVEQ	#0,D0
	MOVE.B	-(A4),D0		; Coor Y
	ADD.B	#16,D0
	CMP.w	#$C0+16,d0
	BCS.S	HAZLOb

	SUBQ	#2,A5
	DBF	D3,SBUC3b
	BRA	FinalSpr2

	CNOP	0,8
HAZLOb:
	LEA	(TabBorSprA.W,PC,D0.W),A6

	MULU	#36,D0
	MOVEQ	#0,D1
	MOVE.B	-2(A5),D1		; Coor X
	SUB.B	D6,D1

	MOVE.L	(TabClrSpr.W,PC,D1.W*4),D2

	ROR.L	#3,D1
	ADD.W	D1,D0
	LEA	(A2,D0.L),A1


	CMP.W	#8-1,D7
	BEQ.S	BorBucb
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
BorBucb:
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+


	MOVE.B	-(A5),D2		; Tile
	SWAP	D7
	AND.W	D7,D2
	SWAP	D7
	LSL.W	#3,D2
	LEA	(A0,D2.W*4),A3

	CLR.W	D1
	ROL.L	#3,D1
	LSL.W	#6,D1
	LEA	(TablaGfxSpr.L,D1.W*8),A6

	MOVEQ	#0,D0

	MOVE.W	D7,D2

SBUC1b:

	MOVEQ	#0,D4
	MOVE.B	(A3),D4
	OR.B	1(A3),D4
	OR.B	2(A3),D4
	OR.B	3(A3),D4
	MOVE.W	(A6,D4.L*2),D4
	NOT.W	D4


	MOVE.B	(A3)+,D0
	MOVE.W	(A6,D0.L*2),D1
	AND.W	D4,(A1)
	OR.W	D1,(A1)

	MOVE.B	(A3)+,D0
	MOVE.W	(A6,D0.L*2),D1
	AND.W	D4,(36*256*1)(A1)
	OR.W	D1,(36*256*1)(A1)

	MOVE.B	(A3)+,D0
	MOVE.W	(A6,D0.L*2),D1
	AND.W	D4,(36*256*2)(A1)
	OR.W	D1,(36*256*2)(A1)

	MOVE.B	(A3)+,D0
	MOVE.W	(A6,D0.L*2),D1
	AND.W	D4,(36*256*3)(A1)
	OR.W	D1,(36*256*3)(A1)

	ADD.W	#(36),A1
	DBF	D2,SBUC1b

	SUBQ	#1,A5
	DBF	D3,SBUC3b

	BRA	FinalSpr2

; ---------------------------

	CNOP	0,4
NoSprPri:
	MOVE.W	#(64)-1,D3
SBUC3:
	MOVEQ	#0,D0
	MOVE.B	(A4)+,D0		; Coor Y
	ADD.B	#16,D0
	CMP.w	#$C0+16,d0
	BCS.s	hazlo
	CMP.w	#$D0+16,d0
	BEQ	FinalSpr2

	addq	#2,a5
	DBF	D3,SBUC3
	BRA	FinalSpr2

	CNOP	0,8
hazlo:
	LEA	(TabBorSprA.W,PC,D0.W),A6

	MULU	#36,D0
	MOVEQ	#0,D1
	MOVE.B	(A5)+,D1		; Coor X
	SUB.B	D6,D1

	MOVE.L	(TabClrSpr.W,PC,D1.W*4),D2

	ROR.L	#3,D1
	ADD.W	D1,D0
	LEA	(A2,D0.L),A1


	CMP.W	#8-1,D7
	BEQ.S	BorBuc
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
BorBuc:
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+
	OR.L	D2,TabBorSprBuc(A6)
	OR.L	D2,(A6)+


	MOVE.B	(A5)+,D2		; Tile
	SWAP	D7
	AND.W	D7,D2
	SWAP	D7
	LSL.W	#3,D2
	LEA	(A0,D2.W*4),A3

	CLR.W	D1
	ROL.L	#3,D1
	LSL.W	#6,D1
	LEA	(TablaGfxSpr.L,D1.W*8),A6

	MOVEQ	#0,D0

	MOVE.W	D7,D2
SBUC1:
	MOVE.B	(A3)+,D0
	BEQ.S	Ski0
	MOVE.W	(A6,D0.L*2),D1
	OR.W	D1,(A1)
Ski0:
	MOVE.B	(A3)+,D0
	BEQ.S	Ski1
	MOVE.W	(A6,D0.L*2),D1
	OR.W	D1,(36*256*1)(A1)
Ski1:
	MOVE.B	(A3)+,D0
	BEQ.S	Ski2
	MOVE.W	(A6,D0.L*2),D1
	OR.W	D1,(36*256*2)(A1)
Ski2:
	MOVE.B	(A3)+,D0
	BEQ.S	Ski3
	MOVE.W	(A6,D0.L*2),D1
	OR.W	D1,(36*256*3)(A1)
Ski3:
	ADD.W	#(36),A1
	DBF	D2,SBUC1

	DBF	D3,SBUC3

FinalSpr2:
	RTS


	CNOP	0,4
PrintSprChip:
; ---
	TST.B	DirPrefs+$1D
	BNE	FinalSpr2Pri
; ---

	LEA	TabBorSprA+15(PC),A0
	LEA	TabBorSprB+15(PC),A3
	LEA	Sprit0+16,A1
	LEA	Sprit1+16,A4
	LEA	PantSprFast+(15*36),A2
	MOVE.W	#(28*8)-1,D0
BUCSPR0b:
	MOVE.B	(A0),D2
	BEQ.S	CONSPR1b
	MOVE.B	(A3)+,(A0)+

	MOVE.W	#4-1,D1
BUCSPR1:
	LSL.B	#1,D2
	BCC.S	CONSPR0b
	MOVE.L	(36*256*3)(A2),8(A4)
	CLR.L	(36*256*3)(A2)
	MOVE.L	(36*256*2)(A2),(A4)
	CLR.L	(36*256*2)(A2)
	MOVE.L	(36*256*1)(A2),8(A1)
	CLR.L	(36*256*1)(A2)
	MOVE.L	(A2),(A1)
	CLR.L	(A2)
CONSPR0b:
	ADDQ	#4,A2

	ADDQ	#4,A1
	ADDQ	#4,A4

	LSL.B	#1,D2
	BCC.S	CONSPR0
	MOVE.L	(36*256*3)(A2),8(A4)
	CLR.L	(36*256*3)(A2)
	MOVE.L	(36*256*2)(A2),(A4)
	CLR.L	(36*256*2)(A2)
	MOVE.L	(36*256*1)(A2),8(A1)
	CLR.L	(36*256*1)(A2)
	MOVE.L	(A2),(A1)
	CLR.L	(A2)
CONSPR0:
	ADDQ	#4,A2

	ADD.W	#OtrSpr-4,A1
	ADD.W	#OtrSpr-4,A4

	DBF	D1,BUCSPR1

	ADDQ	#4,A2		; Esquivar los 4 bytes finales.

	SUB.L	#(OtrSpr*4)-16,A1
	SUB.L	#(OtrSpr*4)-16,A4

	CLR.B	-1(A3)
	DBF	D0,BUCSPR0b
	BRA.S	FINSPRb
	CNOP	0,4
CONSPR1b:
	MOVE.B	(A3)+,(A0)+
	ADD.W	#36,A2

	ADD.W	#16,A1
	ADD.W	#16,A4
	DBF	D0,BUCSPR0b
FINSPRb:
	RTS


	CNOP	0,4
FinalSpr2Pri:


	LEA	PantGfxMask+(15*36),A0
	LEA	TabDirMask(PC),A1
	MOVE.W	#(256)-1,D0
	MOVEQ	#0,D1
	MOVE.B	VDPRegs+9(PC),D1
	MULU	#36,D1
	ADD.L	D1,A0
BucleFS2:
	MOVE.L	A0,(A1)+
	ADD.W	#36,A0
	CMP.L	#PantGfxMask+(15*36)+(28*8*36),A0
	BCS.S	YVDGR
	LEA	PantGfxMask+(15*36),A0
YVDGR:
	DBF	D0,BucleFS2

; ---

	LEA	TabBorSprA+15(PC),A0
	LEA	TabBorSprB+15(PC),A3
	LEA	Sprit0+16,A1
	LEA	Sprit1+16,A4
	LEA	PantSprFast+(15*36),A2

	LEA	TabDirMask(PC),A6

	MOVE.W	#(28*8)-1,D0
BUCSPRp0b:

	MOVE.B	VDPRegs+8(PC),D5		; Coge Coordenada X de Scroll.
	NEG.B	D5

	MOVE.L	(A6)+,A5		;  Coge Dir Base para coor Y de Mask.

	MOVE.B	(A0),D2
	BEQ	CONSPRp1b
	MOVE.B	(A3)+,(A0)+

	MOVE.W	#4-1,D1
BUCSPRp1:
	LSL.B	#1,D2
	BCC.S	CONSPRp0b

	BFEXTU	(A5){D5:32},D6		; Coge Mask.

	MOVE.L	(36*256*3)(A2),D7
	CLR.L	(36*256*3)(A2)
	AND.L	D6,D7
	MOVE.L	D7,8(A4)

	MOVE.L	(36*256*2)(A2),D7
	CLR.L	(36*256*2)(A2)
	AND.L	D6,D7
	MOVE.L	D7,(A4)

	MOVE.L	(36*256*1)(A2),D7
	CLR.L	(36*256*1)(A2)
	AND.L	D6,D7
	MOVE.L	D7,8(A1)

	MOVE.L	(A2),D7
	CLR.L	(A2)
	AND.L	D6,D7
	MOVE.L	D7,(A1)

CONSPRp0b:
	ADD.B	#32,D5
	ADDQ	#4,A2

	ADDQ	#4,A1
	ADDQ	#4,A4

	LSL.B	#1,D2
	BCC.S	CONSPRp0

	BFEXTU	(A5){D5:32},D6		; Coge Mask.

	MOVE.L	(36*256*3)(A2),D7
	CLR.L	(36*256*3)(A2)
	AND.L	D6,D7
	MOVE.L	D7,8(A4)

	MOVE.L	(36*256*2)(A2),D7
	CLR.L	(36*256*2)(A2)
	AND.L	D6,D7
	MOVE.L	D7,(A4)

	MOVE.L	(36*256*1)(A2),D7
	CLR.L	(36*256*1)(A2)
	AND.L	D6,D7
	MOVE.L	D7,8(A1)

	MOVE.L	(A2),D7
	CLR.L	(A2)
	AND.L	D6,D7
	MOVE.L	D7,(A1)

CONSPRp0:
	ADD.B	#32,D5

	ADDQ	#4,A2

	ADD.W	#OtrSpr-4,A1
	ADD.W	#OtrSpr-4,A4

	DBF	D1,BUCSPRp1

	ADDQ	#4,A2		; Esquivar los 4 bytes finales.

	SUB.L	#(OtrSpr*4)-16,A1
	SUB.L	#(OtrSpr*4)-16,A4

	CLR.B	-1(A3)
	DBF	D0,BUCSPRp0b
	BRA.S	FINSPRpb
	CNOP	0,4
CONSPRp1b:
	MOVE.B	(A3)+,(A0)+
	ADD.W	#36,A2

	ADD.W	#16,A1
	ADD.W	#16,A4
	DBF	D0,BUCSPRp0b
FINSPRpb:
	RTS


	CNOP	0,8
TabClrSpr:
	DCB.L	24,$80808080
	DCB.L	08,$C0C0C0C0
	DCB.L	24,$40404040
	DCB.L	08,$60606060
	DCB.L	24,$20202020
	DCB.L	08,$30303030
	DCB.L	24,$10101010
	DCB.L	08,$18181818
	DCB.L	24,$08080808
	DCB.L	08,$0C0C0C0C
	DCB.L	24,$04040404
	DCB.L	08,$06060606
	DCB.L	24,$02020202
	DCB.L	08,$03030303
	DCB.L	32,$01010101

	CNOP	0,8
TabBorSprA:	DS.B	256+32
TabBorSprB:	DS.B	256+32
TabBorSprBuc=TabBorSprB-TabBorSprA

	CNOP	0,8
TabDirMask:	DS.L	256

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	CNOP	0,8
TocaPSG:
	IFD	AMG_PSG
	JMP	AmgPsgPlay		; Amg10.asm
	ENDC
	LEA	$DFF000,A6

	MOVEQ	#0,D1
	MOVE.B	PSG_Tab+0,D0
	BPL.S	EstaOff0
	AND.B	#$0F,D0
	MOVE.B	PSG_Tab+1,D1
	AND.B	#$3F,D1
	LSL.W	#4,D1
	OR.B	D0,D1
	LSL.W	#4,D1
	BNE.S	NoFreqCer0
	MOVEQ	#1,D1
NoFreqCer0:
	MOVE.W	D1,$A6(A6)	; Freq
	MOVE.B	PSG_Tab+2,D1
	NOT.B	D1
	AND.W	#$0F,D1
	LSL.W	#1,D1
EstaOff0:
	MOVE.W	D1,$A8(A6)	; Vol


	MOVEQ	#0,D1
	MOVE.B	PSG_Tab+4,D0
	BPL.S	EstaOff1
	AND.B	#$0F,D0
	MOVE.B	PSG_Tab+5,D1
	AND.B	#$3F,D1
	LSL.W	#4,D1
	OR.B	D0,D1
	LSL.W	#4,D1
	BNE.S	NoFreqCer1
	MOVEQ	#1,D1
NoFreqCer1:
	MOVE.W	D1,$B6(A6)	; Freq
	MOVE.B	PSG_Tab+6,D1
	NOT.B	D1
	AND.W	#$0F,D1
	LSL.W	#1,D1
EstaOff1:
	MOVE.W	D1,$B8(A6)	; Vol


	MOVEQ	#0,D1
	MOVE.B	PSG_Tab+8,D0
	BPL.S	EstaOff2
	AND.B	#$0F,D0
	MOVE.B	PSG_Tab+9,D1
	AND.B	#$3F,D1
	LSL.W	#4,D1
	OR.B	D0,D1
	LSL.W	#4,D1
	BNE.S	NoFreqCer2
	MOVEQ	#1,D1
NoFreqCer2:
	MOVE.W	D1,$C6(A6)	; Freq
	MOVE.B	PSG_Tab+10,D1
	NOT.B	D1
	AND.W	#$0F,D1
	LSL.W	#1,D1
EstaOff2:
	MOVE.W	D1,$C8(A6)	; Vol


	MOVEQ	#0,D1
	TST.B	PSG_Tab+12
	BPL.S	EstaOff3
	MOVE.B	PSG_Tab+8,D0
	AND.B	#$0F,D0
	MOVE.B	PSG_Tab+9,D1
	AND.B	#$3F,D1
	LSL.W	#4,D1
	OR.B	D0,D1
	LSR.W	#2,D1
	ADD.W	#128,D1
	MOVE.W	D1,$D6(A6)	; Freq
	MOVE.B	PSG_Tab+14,D1
	NOT.B	D1
	AND.W	#$0F,D1
EstaOff3:
	MOVE.W	D1,$D8(A6)	; Vol

	RTS
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-





; -------------------------------------------- ;
; -------------------------------------------- ;

	CNOP	0,8
PonePaletaMS:
	IFD	AMG_TMSMODES
	BTST	#2,VDPRegs+0(PC)	; TMS9918 fixed palette: Amg10.asm
	BNE.S	AmgTmsP1
	JMP	AmgTmsPal
AmgTmsP1:
	ENDC
	LEA	VPAL,A0
	TST.B	Regs+Consola(PC)
	BNE.S	PonePaletaGG

	BTST	#6,VDPRegs+1(PC)
	BNE.S	PonPalA0
	LEA	CerosPal(PC),A0
PonPalA0:

	LEA	Color0+2,A1
	MOVEQ	#32-1,D2
PonPalBucMS:
	MOVE.B	(A0)+,D0
	MOVEQ	#0,D1

	BFINS	D0,D1{20:2}	; R
	LSR.B	#2,D0

	BFINS	D0,D1{24:2}	; G
	LSR.B	#2,D0

	BFINS	D0,D1{28:2}	; B
	IFD	AMG_PALFULL
	MOVE.W	D1,D0			; each 4-bit level = 2-bit level * 5
	LSR.W	#2,D0
	OR.W	D0,D1
	ENDC

	MOVE.W	D1,(A1)
	ADDQ.W	#4,A1
	DBF	D2,PonPalBucMS
	RTS

; -------------------------------------------- ;

	CNOP	0,8
PonePaletaGG:
	LEA	Color0+2,A1
	MOVEQ	#32-1,D2
PonPalBucGG:
	MOVE.W	(A0)+,D0
	MOVEQ	#0,D1

	BFINS	D0,D1{28:4}	; B

	LSR.W	#8,D0
	BFINS	D0,D1{20:4}	; R

	LSR.W	#4,D0
	BFINS	D0,D1{24:4}	; G

	MOVE.W	D1,(A1)
	ADDQ.W	#4,A1
	DBF	D2,PonPalBucGG
	RTS

	CNOP	0,8
CerosPal:DS.W	32

; -------------------------------------------- ;
; -------------------------------------------- ;




; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;





	CNOP	0,8
OUTBF:
	NOT.B	IOBF(A3)
	BEQ.S	OUTBFb
	SWAP	D2
	MOVE.B	D1,D2
	SWAP	D2
	RTS
	CNOP	0,8
OUTBFb:
	TST.B	D1
	BMI.S	EsVDP
	SWAP	D2
	MOVE.L	#INBE,Ins+($BE*4)
	MOVE.L	#OUTBEa,Outs+($BE*4)
	AND.B	#$3F,D1
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.W	D1,DirVRAM(A3)
	LEA	(VRAM.L,D1.W),A2
	SWAP	D2
	RTS

EsVDP:
	IFD	AMG_VDPCODE2
; As on the real VDP: a register write ($80-$BF) also loads the address register, and the data port
; then writes to VRAM; the register number is the low four bits. v0.8 sent $A0-$BF to a dummy
; buffer and left the address alone, so Ax Battler's sprite table at $3F00 was never written.
	CMP.B	#$C0,D1
	BCC.S	EsVPAL
	SWAP	D2
	MOVE.L	#INBE,Ins+($BE*4)
	MOVE.L	#OUTBEa,Outs+($BE*4)
	MOVE.W	D1,A4
	AND.W	#$3F,D1
	LSL.W	#8,D1
	MOVE.B	D2,D1
	MOVE.W	D1,DirVRAM(A3)
	LEA	(VRAM.L,D1.W),A2
	MOVE.W	A4,D1
	AND.L	#$0F,D1
	MOVE.B	D2,(VDPRegs,D1.W)
	JMP	([VDPRuts.W,PC,D1.W*4])
	ENDC
;;	BTST	#6,D1			;  - Antiguo
;;	BNE.S	EsVPAL			; /
	CMP.B	#$A0,D1		; <=- No es seguro.
	BCC.S	EsVPAL

	SWAP	D2
	AND.L	#$3F,D1
	MOVE.B	D2,(VDPRegs,D1.W)
	JMP	([VDPRuts.W,PC,D1.W*4])

	CNOP	0,8
EsVPAL:
	SWAP	D2
	MOVE.L	#OUTBEb,Outs+($BE*4)
	MOVE.L	#INBEb,Ins+($BE*4)
	AND.W	MaskVPAL(A3),D2
	MOVE.W	D2,DirVRAM(A3)
	LEA	VPOL,A2
	CMP.B	#$C0,D1
	BCS.S	NoEsPalete
	LEA	VPAL,A2
NoEsPalete:
	SWAP	D2
	RTS

VDPRuts:
	DC.L	VDPx	; 00
	DC.L	VDPx	; 01
	DC.L	VDPx	; 02
	DC.L	VDPx	; 03
	DC.L	VDPx	; 04
	DC.L	VDPx	; 05
	DC.L	VDPx	; 06
	DC.L	VDPx	; 07
	DC.L	VDP8	; 08
	DC.L	VDP9	; 09
	DC.L	VDPx	; 0A
	DC.L	VDPx	; 0B
	DC.L	VDPx	; 0C
	DC.L	VDPx	; 0D
	DC.L	VDPx	; 0E
	DC.L	VDPx	; 0F
	REPT	64-16+2
	DC.L	VDPx	; $10...$3f
	ENDR

VDPRegs:	DS.B	$80

;	=------------------------=
	CNOP	0,8
OUTBEa:
	SF	IOBF(A3)
	MOVE.B	D1,(A2)+
	MOVE.W	DirVRAM(A3),D1
	LSR.W	#5,D1
	ST	(TabRedef.W,A3,D1.W)
	ADDQ.B	#1,DirVRAM+1(A3)
	BEQ.S	OUTBEaCon
	RTS
OUTBEaCon:
	MOVE.W	DirVRAM(A3),D1
	ADD.W	#$0100,D1
	AND.W	#$3FFF,D1
	MOVE.W	D1,DirVRAM(A3)
	LEA	(VRAM.L,D1.W),A2
	RTS
;	------
OUTBEb:
	SF	IOBF(A3)
	TST.B	PalCopy(A3)
	BNE.S	OUTBEc

	MOVE.B	D1,D2
	MOVE.W	DirVRAM(A3),D1
	MOVE.B	D2,(A2,D1.W)
	ADDQ.W	#1,D1
	AND.W	MaskVPAL(A3),D1
	MOVE.W	D1,DirVRAM(A3)
	RTS
;	------
OUTBEc:
	TST.B	Consola(A3)
	BNE.S	OUTBEcGG

	MOVE.B	D1,D2
	MOVE.W	DirVRAM(A3),D1
	MOVE.B	D2,(A2,D1.W)

	BTST	#6,VDPRegs+1(PC)
	BEQ.S	OUTBEcA0

	MOVE.L	TabRasRGBcnt(PC),A4
	MOVE.B	CurLine+1(A3),(A4)+	; Guardamos Scan Line
	MOVE.B	D1,(A4)+		; Guardamos numero de paleta.
	MOVE.W	D2,(A4)+		; Guardamos RGB.

	CMP.L	#TabRasRGB+(32*256*4),A4
	BCS.S	OutBEcCon
	SUBQ.W	#4,A4
OutBEcCon:
	MOVE.L	A4,TabRasRGBcnt
OUTBEcA0:
	ADDQ.W	#1,D1
	AND.W	MaskVPAL(A3),D1
	MOVE.W	D1,DirVRAM(A3)

	RTS
;	------
OUTBEcGG:
	MOVE.B	D1,D2
	MOVE.W	DirVRAM(A3),D1
	MOVE.B	D2,(A2,D1.W)

	LSR.B	#1,D1
	BCC.S	OUTBEcGGcon

	BTST	#6,VDPRegs+1(PC)
	BEQ.S	OUTBEcGGcon

	MOVE.L	TabRasRGBcnt(PC),A4
	MOVE.B	CurLine+1(A3),(A4)+	; Guardamos Scan Line
	MOVE.B	D1,(A4)+		; Guardamos numero de paleta.
	MOVE.W	(A2,D1.W*2),(A4)+	; Guardamos RGB.

	CMP.L	#TabRasRGB+(32*256*4),A4
	BCS.S	OutBEcCon2
	SUBQ.W	#4,A4
OutBEcCon2:
	MOVE.L	A4,TabRasRGBcnt

OUTBEcGGcon:
	MOVE.W	DirVRAM(A3),D1
	ADDQ.W	#1,D1
	AND.W	MaskVPAL(A3),D1
	MOVE.W	D1,DirVRAM(A3)
	RTS
;	------
;	------
INBE:
	MOVE.B	(A2)+,D1
	ADDQ.B	#1,DirVRAM+1(A3)
	BEQ.S	INBECon
	RTS
	CNOP	0,4
INBECon:
	ADDQ.B	#1,DirVRAM(A3)
	CMP.W	#$4000,DirVRAM(A3)
	BCC.S	INBECon2
	RTS
	CNOP	0,4
INBECon2:
	CLR.W	DirVRAM(A3)
	LEA	VRAM,A2
	RTS
;	------
INBEb:
	MOVE.W	DirVRAM(A3),D1
	MOVE.B	(A2,D1.W),D2
	ADDQ.W	#1,D1
	AND.W	MaskVPAL(A3),D1
	MOVE.W	D1,DirVRAM(A3)
	MOVE.B	D2,D1
	RTS
;	=------------------------=

	CNOP	0,8
INBF:
	SF	IOBF(A3)
	MOVE.B	Estado(A3),D1
	IFD	AUTODUMP
	ADDQ.L	#1,AutoStatRd		; test builds: status reads, and those with bit 7
	TST.B	D1
	BPL.S	.amgdump
	ADDQ.L	#1,AutoStat7
.amgdump:
	ENDC
	IFD	AMG_VDPSTATUS
	JMP	AmgVdpStatRd		; the console's status bits: Amg10.asm
	ELSE
	AND.B	#$3F,Estado(A3)
	BCHG	#5,Estado(A3)
	RTS
	ENDC

; ------------------------------------------------ ;

	CNOP	0,8
OUT3F:
	MOVE.B	D1,D2
	AND.B	#$0F,D1
	CMP.B	#$05,D1
	BEQ.S	Nacion
NacionJap:
	OR.B	#$C0,JoyX+1(A3)
	RTS
Nacion:
	BTST.B	#0,DirPrefs+$19
	BEQ.S	NacionJap

	AND.B	#$3F,JoyX+1(A3)
	LSL.B	#1,D2
	ROL.B	#1,D2
	ROXR.B	#1,D2
	AND.B	#$C0,D2
	OR.B	D2,JoyX+1(A3)
	RTS

;;;	JMP	([Outs+($7F*4).W,PC])

	CNOP	0,8
OUT7F:
	IFD	AMG_PSG
	JMP	AmgPsgOut		; Amg10.asm: the chip's latch/data protocol
	ENDC
	TST.B	IO7F(A3)
	BNE.S	OUT7Fb
	MOVE.B	D1,PSG_Old(A3)
	BTST	#4,D1
	BNE.S	OUT7Fb
	AND.B	#$70,D1
	CMP.B	#$60,D1
	BEQ.S	OUT7Fb
	ST	IO7F(A3)
	RTS

	CNOP	0,8
OUT7Fb:
	MOVE.B	PSG_Old(A3),D2
	BFINS	D2,D1{16:8}
	LSR.B	#4,D2
	AND.B	#$07,D2
	MOVE.W	D1,(PSG_Tab-$200.L,D2.W*2)
	SF	IO7F(A3)
	RTS

PSG_Tab:	DS.W	8


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; ------------------------------ ;
		CNOP	0,8
CopperOptsUno:	DC.L	CopperOpts1
CopperOptsDos:	DC.L	CopperOpts0

CopperLineUno:	DC.L	CopperLine1
CopperLineDos:	DC.L	CopperLine0

TabRasRESTUno:	DC.L	TabRasREST1-2
TabRasRESTDos:	DC.L	TabRasREST0-2

TabRasCMDS:	DS.B	260
TabRasDATA:	DS.L	260*2

		DC.L	-1	<=- No Quitar.
TabRasREST0:	DS.L	260	--------------
		DC.L	-1	<=- No Quitar.
TabRasREST1:	DS.L	260	--------------
		DC.L	0

		CNOP	0,8
TabRasRGBcnt:	DC.L	TabRasRGB
TabRasRGB:	DS.W	(32*256*2)
		DC.L	0,0,0

		CNOP	0,8
; ------------------------------ ;

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
VDPx:

VDP9:

	SWAP	D2
	RTS


VDP8:
	MOVE.W	CurLine(A3),D1
	ADDQ.W	#1,D1

	OR.B	#$02,(TabRasCMDS.L,D1.W)	; Actualiza Coor X
	MOVE.B	D2,(TabRasDATA+2.L,D1.W*8)	; BG Coor X

	SWAP	D2
	RTS


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


	CNOP	0,4
OUTXX:	RTS

	CNOP	0,4
INXX:	ST	D1
	RTS


	CNOP	0,4
IN05:
	MOVE.B	#$FE,D1
	RTS


	CNOP	0,4
IN7E:
	MOVE.B	CurLine+1(A3),D1
	RTS


	CNOP	0,4
INJ0:	MOVE.B	JoyX+0(A3),D1
	RTS

	CNOP	0,4
INJ1:	MOVE.B	JoyX+1(A3),D1
	RTS


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-





; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


; ------------------------------------------------ ;
; ------------------------------------------------ ;

LeeTecla:MACRO
	CMP.B	#\2,D0
	BNE.S	Lete\@
	BSET	#\1,\3(A3)
	RTS
Lete\@:
	ENDM

PonTecla:MACRO
	CMP.B	#\2,D0
	BNE.S	PoTe\@
	BCLR	#\1,\3(A3)
	RTS
PoTe\@:
	ENDM

	CNOP	0,8
MiraTeclado:
	MOVEQ	#0,D0
	MOVE.B	$BFEC01,D0
	BNE.S	Pulsacion
	RTS
Pulsacion:
	NOP
	SF	$BFEC01
	NOP
	NOP
	MOVE.W	#4,D2
	OR.B	#$40,$BFEE01		; CIAA Libre
TRETARDO:
	MOVE.B	$DFF006,D1
TRETARDOB:
	CMP.B	$DFF006,D1
	BEQ.S	TRETARDOB
	DBF	D2,TRETARDO
	AND.B	#$BF,$BFEE01		; CIAA Libre

	LEA	Regs,A3

	NOT.B	D0
	LSR.B	#$1,D0
	BCS	TeclaSoltada

	PonTecla 3,$4E,KeyX		; Derecha
	PonTecla 2,$4F,KeyX		; Izquierda
	PonTecla 0,$4C,KeyX		; Arriba
	PonTecla 1,$4D,KeyX		; Abajo

	PonTecla 5,$66,KeyX		; Botón A	(Amiga Izq)
	PonTecla 4,$64,KeyX		; Botón B	(Alt Izq)
	PonTecla 0,$46,KeyX+3		; Pause		(Del)
	PonTecla 7,$44,KeyX+2		; Start		(Enter)

	PonTecla 5,$60,KeyX		; Botón A	(Shift Izq)
	PonTecla 4,$40,KeyX		; Botón B	(Space)

	CMP.B	#$45,D0			; Salir		(Esc)
	BNE.S	NoEsESC
	ST	SalirMenu(A3)
	RTS
NoEsESC:
	CMP.B	#$5F,D0			; Salir		(Help)
	BNE.S	NoEsESC2
	ST	SalirMenu(A3)
NoEsESC2:
	RTS
	CNOP	0,4
TeclaSoltada:
	LeeTecla 3,$4E,KeyX		; Derecha
	LeeTecla 2,$4F,KeyX		; Izquierda
	LeeTecla 0,$4C,KeyX		; Arriba
	LeeTecla 1,$4D,KeyX		; Abajo

	LeeTecla 5,$66,KeyX		; Botón A	(Amiga Izq)
	LeeTecla 4,$64,KeyX		; Botón B	(Alt Izq)
	LeeTecla 0,$46,KeyX+3		; Pause		(Del)
	LeeTecla 7,$44,KeyX+2		; Start		(Enter)

	LeeTecla 5,$60,KeyX		; Botón A	(Shift Izq)
	LeeTecla 4,$40,KeyX		; Botón B	(Space)

	RTS

; ------------------------------------------------ ;
; ------------------------------------------------ ;

;	 ---------------------------
;	- Lee puerto 0 del JoyStick -
;	 ---------------------------

	CNOP	0,8
LeeJoyStick:
LeeJoypad:
	LEA	Regs,A3
	MOVE.W	$DFF00C,D0		; Puerto B.
	BSR	LEEJOY
	NOT.B	D2
	MOVE.B	D2,D1
	LSR.B	#2,D1
	BFINS	D2,D1{28:1}
	LSR.B	#1,D2
	BFINS	D2,D1{29:1}
	OR.B	#$F0,D1

	BTST	#7,$BFE001		; Botón A	(Fire #1)
	BNE.S	NOB1_E
	BCLR	#4,D1
NOB1_E:
	MOVE.W	#$FF00,$DFF034		; Botón B	(Fire #2)
	NOP
	NOP
	BTST	#6,$DFF016
	BNE.S	NOB2_E
	BCLR	#5,D1
NOB2_E:
	MOVE.B	D1,JoyX+0(A3)

	ST	JoyX+2(A3)

	MOVE.W	#$FF00,$DFF034		; Start		(Fire #3)
	NOP
	NOP
	BTST	#4,$DFF016
	BNE.S	NOB2C_E
	BCLR	#7,JoyX+2(A3)
NOB2C_E:
	RTS
; -------------------------------


; ------------------------------------------------ ;
; ------------------------------------------------ ;

;	 ---------------------------
;	- Lee puerto 1 del JoyStick -
;	 ---------------------------

	CNOP	0,8
LeeJoyStick2:
LeeJoypad2:
	LEA	Regs,A3
	MOVE.W	$DFF00A,D0		; Puerto A.
	BSR.S	LEEJOY
	NOT.B	D2
	MOVE.B	D2,D1
	LSR.B	#2,D1
	BFINS	D2,D1{28:1}
	LSR.B	#1,D2
	BFINS	D2,D1{29:1}
	OR.B	#$F0,D1

	BTST	#6,$BFE001		; Botón A	(Fire #1)
	BNE.S	NOB1_E2
	BCLR	#4,D1
NOB1_E2:
	MOVE.W	#$FF00,$DFF034		; Botón B	(Fire #2)
	NOP
	NOP
	BTST	#2,$DFF016
	BNE.S	NOB2_E2
	BCLR	#5,D1
NOB2_E2:

	MOVE.B	JoyX+0(A3),D0
	AND.W	#$003F,D0
	LSL.W	#6,D1
	OR.W	D1,D0
	ROR.W	#8,D0
	MOVE.W	D0,JoyX+0(A3)

	RTS
; -------------------------------
;	Lectura del Joystick.

;	Resultado en D2.b de la siguiente forma:
;	Bit 0=Derecha.
;	Bit 1=Izquierda.
;	Bit 2=Arriba.
;	Bit 3=Abajo.

	CNOP	0,8
LEEJOY:
	MOVE.W	D0,D1
	LSR.B	#1,D1
	AND.B	#$01,D1
	MOVE.B	D1,D2		; Derecha.

	LSR.W	#8,D1
	AND.B	#$02,D1
	OR.B	D1,D2		; Izquierda.

	MOVE.W	D0,D1
	LSR.W	#1,D1
	EOR.W	D1,D0

	MOVE.W	D0,D1
	LSL.B	#3,D1
	AND.B	#$08,D1
	OR.B	D1,D2		; Abajo.

	LSR.W	#6,D0
	AND.B	#$04,D0
	OR.B	D0,D2		; Arriba.
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	CNOP	0,8
LeeNoJoy2:
	LEA	Regs,A3
	OR.L	#$C0FF0000,JoyX(A3)
	RTS

	CNOP	0,8
LeeTeclado:
	LEA	Regs,A3
	OR.L	#$3FF0FFFF,JoyX(A3)
	RTS

	CNOP	0,8
LeeTeclado2:
	LEA	Regs,A3
	MOVE.B	KeyX(A3),D1
	ROR.W	#2,D1
	OR.W	#$3FF0,D1
	AND.W	D1,JoyX+0(A3)
	AND.W	#$C00F,D1
	OR.W	D1,JoyX+0(A3)
	RTS

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

CD32M:	MACRO
	LSR.B	#1,D0
	BCC.S	\@NoPuldat
	BCLR	#\1,\2
\@NoPuldat:
	ENDM

	CNOP	0,8
LeeCD32Joypad:
	LEA	Regs,A3
	MOVEQ	#7,D7
	MOVE.W	#$6f00,D6
	MOVEQ	#6+8,D5
	MOVE.W	$DFF00C,D0		; Puerto B.
	BSR	LEEJOY
	NOT.B	D2
	MOVE.B	D2,D3
	LSR.B	#2,D3
	BFINS	D2,D3{28:1}
	LSR.B	#1,D2
	BFINS	D2,D3{29:1}
	OR.B	#$F0,D3

	IFD	AMG_PADS
	JSR	AmgReadCD32
	ELSE
	BSR	ReadCD32
	ENDC
	IFD	AMG_PADMAP
	JSR	AmgPadMapP1		; Play = Pause/Start, shoulders = back to the menu
	ELSE
	LSR.B	#1,D0
	MOVEQ	#-1,D1
	MOVEQ	#-1,D2

	LSR.B	#1,D0
	BCC.S	NoPlay
	ST	SalirMenu(A3)
NoPlay:

	CD32M	4,D3	; Boton B
	IFD	AMG_PADS
	LSR.B	#1,D0		; forward shoulder (a Mega Drive pad's C on a Mega Multi): Pause and Start
	BCC.S	AmgFfwNo1
	BCLR	#0,D2
	BCLR	#7,D1
AmgFfwNo1:
	ELSE
	CD32M	5,D3	; Boton A
	ENDC
	CD32M	0,D2	; Pause
	CD32M	7,D1	; Start
	CD32M	4,D3	; Boton B
	CD32M	5,D3	; Boton A
	ENDC

	MOVE.B	D3,JoyX+0(A3)
	IFD	AMG_PAUSEEDGE
	JSR	AmgPauseEdge		; Pause: one NMI per press
	ELSE
	MOVE.B	D2,JoyX+3(A3)
	ENDC
	MOVE.B	D1,JoyX+2(A3)

	RTS

;***********************************************************************

	CNOP	0,8
LeeCD32Joypad2:
	LEA	Regs,A3
	MOVEQ	#6,D7
	MOVE.W	#$f600,D6
	MOVEQ	#2+8,D5
	MOVE.W	$DFF00A,D0		; Puerto A.
	BSR	LEEJOY
	NOT.B	D2
	MOVE.B	D2,D3
	LSR.B	#2,D3
	BFINS	D2,D3{28:1}
	LSR.B	#1,D2
	BFINS	D2,D3{29:1}
	OR.B	#$F0,D3

	IFD	AMG_PADS
	JSR	AmgReadCD32
	ELSE
	BSR	ReadCD32
	ENDC
	IFD	AMG_PADMAP
	JSR	AmgPadMapP2		; Play = Pause/Start, shoulders = back to the menu
	ELSE
	LSR.B	#1,D0
	MOVEQ	#-1,D1
	MOVEQ	#-1,D2

	LSR.B	#1,D0
	BCC.S	NoPlay2
	ST	SalirMenu(A3)
NoPlay2:

	CD32M	4,D3	; Boton B
	IFD	AMG_PADS
	LSR.B	#1,D0		; forward shoulder (a Mega Drive pad's C on a Mega Multi): Pause and Start
	BCC.S	AmgFfwNo2
	BCLR	#0,D2
	BCLR	#7,D1
AmgFfwNo2:
	ELSE
	CD32M	5,D3	; Boton A
	ENDC
	CD32M	0,D2	; Pause
	CD32M	7,D1	; Start
	CD32M	4,D3	; Boton B
	CD32M	5,D3	; Boton A
	ENDC


	MOVE.B	JoyX+0(A3),D0
	AND.W	#$003F,D0
	LSL.W	#6,D3
	OR.W	D3,D0
	ROR.W	#8,D0
	MOVE.W	D0,JoyX+0(A3)

	RTS

;***********************************************************************
;Reads CD 32 Controller
;You must read joystick positions or button in normal way
;BEFORE you call this.
;One VBL MUST have elapsed before repeating this!

; D0=:
CD_PLAY	EQU 1
CD_RWD	EQU 2
CD_FFW	EQU 3
CD_G	EQU 4
CD_Y	EQU 5
CD_R	EQU 6
CD_B	EQU 7

		CNOP	0,8
ReadCD32:
		bset	D7,$bfe201
		bclr	D7,$bfe001
		move.w	D6,$dff034
		moveq.l	#0,d0
		moveq.l	#7,d1
		bra.b	.gamecont4		
.gamecont3:
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
.gamecont4:
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		tst.b	$bfe001
		move.w	$dff016,d2
		bset	D7,$bfe001
		bclr	D7,$bfe001
		btst	D5,d2
		bne.b	.gamecont5
		bset	d1,d0
.gamecont5:
		dbf	d1,.gamecont3
		
		bclr	D7,$bfe201
		move.w	#$ffff,$dff034
		rts

;***********************************************************************
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-






; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;
; ------------------------------------------------ ;


; -------------------------------------
; **  Rutinas Básicas de 007  v2.27  **
; -------------------------------------

	CNOP	0,4

DP0=$8000	; 00(A0): Direccion Copper.   08(A0): Bytes de 1 Plano.
DP1=$C000	; 04(A0): Direccion Pant.     0C(A0): Bit-Planos. (DP0,1)

CreaPlanos:
	MOVE.W	#$E0,D3
CRPBUC00:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.L	(A0)+,A1
	MOVEM.L	(A0)+,D0-D2
	TST.W	D2
	SUB.W	#1,D2
	BPL.S	CRPCON00
	BTST	#$E,D2
	BEQ.S	CRPCON01
	ADD.W	#4,D3
CRPCON01:
	AND.W	#$3FFF,D2
	BSR	HACEPLANOS2
	BRA.S	CreaPlanos
CRPCON00:
	BSR	HACEPLANOS
	BRA.S	CreaPlanos
HACEPLANOS:			; A1=COPPER.   D0=Direccion. D1=PLANOSIZE.
	SWAP	D0		; D2=Planos-1. D3=DIRBPLH/L
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	ADD.L	D1,D0
	DBF	D2,HACEPLANOS
	RTS
HACEPLANOS2:			; Igual que antes pero Dual Playfield.
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	SWAP	D0
	MOVE.W	D3,(A1)+
	MOVE.W	D0,(A1)+
	ADD.W	#2,D3
	ADD.L	D1,D0
	ADD.W	#4,D3
	DBF	D2,HACEPLANOS2
	RTS


CREASALTO:			; A0=COPPER-List.   D0=Direccion
	MOVE.W	D0,$6(A0)
	SWAP	D0
	MOVE.W	D0,$2(A0)
	RTS
;	00(A0): Direccion de Copper.	08(A0): Numero Colores. (DP0,1)
;	04(A0): Direccion de Colores.	(Todos en x.L)
CreaColores:
	MOVE.W	#$180,D1
CRCBUC00:
	TST.L	(A0)
	BEQ	CRPRET
	MOVEM.L	(A0)+,A1-A2
	MOVE.L	(A0)+,D0
	SUB.W	#1,D0
	TST.W	D0
	BPL.S	CRCBUC01
	MOVE.W	#$190,D1
	BTST	#$E,D0
	BEQ.S	CRCBUC01A
	MOVE.W	#$1A0,D1
CRCBUC01A:
	AND.W	#$3FFF,D0
CRCBUC01:
	MOVE.W	D1,(A1)+
	MOVE.W	(A2)+,(A1)+
	ADD.W	#$02,D1
	DBF	D0,CRCBUC01
	BRA.S	CreaColores	
;	00(A0): Direccion del Copper.	08(A0): Numero Sprit (0-7)
;	04(A0): Direccion GFX Sprit.	(Todos en x.L)
CreaSprites:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.W	#$120,D2
	MOVE.L	(A0)+,A1
	MOVEM.L	(A0)+,D0-D1
	LSL.W	#2,D1
	ADD.L	D1,D2	
	MOVE.W	D2,(A1)+
	SWAP	D0
	MOVE.W	D0,(A1)+
	ADD.L	#2,D2
	MOVE.W	D2,(A1)+
	SWAP	D0
	MOVE.W	D0,(A1)+
	BRA.S	CreaSprites
;	00(A0): Direccion del Copper.	08(A0): Dir. Salto.
CreaSaltos:
	TST.L	(A0)
	BEQ	CRPRET
	MOVE.L	(A0)+,A1
	MOVE.L	(A0)+,D0
	MOVE.W	D0,$6(A1)
	SWAP	D0
	MOVE.W	D0,$2(A1)
	BRA.S	CreaSaltos	
RETARDO:			; D0=Retardo.
	MOVE.W	D0,-(SP)
	MOVE.B	$DFF006,D0
RETARDOB:
	CMP.B	$DFF006,D0
	BEQ.S	RETARDOB
	MOVE.W	(SP)+,D0
	DBF	D0,RETARDO
CRPRET:	RTS
; -----**************()**************-----

	CNOP	0,4
DirPlanos:
	DC.L	Plano0,PantGfx-4,(64),5
	IFEQ	ShowFps
	DC.L	Plano1,Panel-4,(32*8),2
	ENDC
	DC.L	0
DirColores:
	DC.L	Color0,GGPaleta,32
	DC.L	0
DirSprites:
	DC.L	DirSprit0,Sprit0,0
	DC.L	DirSprit1,Sprit1,1
	DC.L	DirSprit2,Sprit2,2
	DC.L	DirSprit3,Sprit3,3
	DC.L	DirSprit4,Sprit4,4
	DC.L	DirSprit5,Sprit5,5
	DC.L	DirSprit6,Sprit6,6
	DC.L	DirSprit7,Sprit7,7
	DC.L	0
DirSaltos:
	DC.L	CopperLineJmp,CopperLine0
	DC.L	0

	CNOP	0,8
VBlank:		DC.L	0
SOFTW:		DC.L	0
Traza:		DC.L	0
Trap1:		DC.L	0
Trap2:		DC.L	0
WBCopp:		DC.L	0
VBRPun:		DC.L	0
Debug:		DS.L	16
DMACON:		DC.W	0
INTENA:		DC.W	0
INTREQ:		DC.W	0
Filtro:		DC.B	0,0
DirContinua:	DC.L	Bucle
DirFlags:	DC.W	0
INTERDAT:	DC.W	0
PILA:		DC.L	0
PCReg:		DC.W	0,0


	CNOP	0,8
GGPaleta:
	DC.W	$0200,$00F0,$000F,$0F0F
	DC.W	$0F34,$03F1,$03DF,$0F8F
	DC.W	$0F50,$00F0,$000F,$0E58
	DC.W	$0F04,$00F0,$000F,$0F0F

	CNOP	0,8
Font:	INCBIN	"data/Font.raw"

	DC.L	0


; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------
; -------------------------------------------------------------




; -------------------------------------------------- ;
; -------------------------------------------------- ;
; -------------************************------------- ;
; -------------------------------------------------- ;
; -------------------------------------------------- ;


	IFD	AUTOTEST
	INCLUDE	"AutoTest.asm"
	ENDC
	INCLUDE	"Amg10.asm"		; 1.0 additions, each behind its own AMG_ switch
;	------------------------
	SECTION	Pantallas,DATA_C
;	------------------------

	CNOP	0,8
MasterCopper:
	DC.W	$01FC,$000D	; FMODE		Fetch mode register
	DC.W	$0100,$0001	; BPLCON0	Bitplane control (miscellaneous control bits)

DirSprit0:	DS.W	4
DirSprit1:	DS.W	4
DirSprit2:	DS.W	4
DirSprit3:	DS.W	4
DirSprit4:	DS.W	4
DirSprit5:	DS.W	4
DirSprit6:	DS.W	4
DirSprit7:	DS.W	4

Copper:

	DC.W	$0092,$0038	; DDFSTRT	Display bit plane data fetch start,horiz pos
	DC.W	$0094,$00B0	; DDFSTOP	Display bit plane data fetch stop, horiz pos

;	---------------------=> Muestra Fps
	IFEQ	ShowFps

Plano1:	DS.W	2*4
	DC.W	$008E,$31A1	; DIWSTRT	Display window start (upper left vertical-horizontal position)
	DC.W	$0090,$FBA1	; DIWSTOP	Display window stop (lower right vertical-horizontal position)

	DC.W	$0108,0-4	; BPL1MOD	Bitplane modulo (odd planes)
	DC.W	$010A,0-4	; BPL2MOD	Bitplane modulo (even planes)

	DC.W	$3101,$FFFE
	DC.W	$0102,$0000	; BPLCON1	Bitplane control (scroll value)
	DC.W	$0104,$007F	; BPLCON2	Bitplane control (video priority control)
	DC.W	$0106,$1040	; BPLCON3	Bitplane control (enhanced features)
	DC.W	$010C,$0011	; BPLCON4	Bitplane control (bitplane and sprite-masks)

CopShoFps:DC.W	$0100,$2001	; BPLCON0	Bitplane control (miscellaneous control bits)

BkBor:	DC.W	$0180,0,$0184,0,$0186,$0AAA

	DC.W	$3901,$FFFE
	DC.W	$0100,$0001	; BPLCON0	Bitplane control (miscellaneous control bits)
	ENDC
;	---------------------<=


Bordes:	DC.W	$008E,$3BA1	; DIWSTRT	Display window start (upper left vertical-horizontal position)
	DC.W	$0090,$FBA1	; DIWSTOP	Display window stop (lower right vertical-horizontal position)

	DC.W	$0108,(32+(64*3))-4	; BPL1MOD	Bitplane modulo (odd planes)
	DC.W	$010A,(32+(64*3))-4	; BPL2MOD	Bitplane modulo (even planes)

Plano0:	DS.W	5*4

ScrBits:DC.W	$0102,$0000	; BPLCON1	Bitplane control (scroll value)
	DC.W	$0104,$007F	; BPLCON2	Bitplane control (video priority control)
BpCon3:	DC.W	$0106,$1040	; BPLCON3	Bitplane control (enhanced features)
	DC.W	$010C,$0011	; BPLCON4	Bitplane control (bitplane and sprite-masks)

	DC.W	$3A01,$FFFE
Color0:	DS.W	32*2

	DC.W	$3AB1,$FFFE
CopperLineJmp:
	DC.W	$0084,0,$0086,0		; Salto a CopperLine0/CopperLine1

;;	DC.W	$3AC1,$FFFE
;;	DC.W	$0100,$5001	; BPLCON0	Bitplane control (miscellaneous control bits)

	DC.W	$008A,0

;	----------------------=> Los DOS CopperLine
CopperLine0:	DCB.L	(CoppLineSize/4)*195,$00FC0000

	DC.W	$FC01,$FFFE		; \
	DC.W	$009C,$8010		;  - Actualiza VDP

	DC.L	$FFFFFFFE

CopperLine1:	DCB.L	(CoppLineSize/4)*195,$00FC0000

	DC.W	$FC01,$FFFE		; \
	DC.W	$009C,$8010		;  - Actualiza VDP

	DC.L	$FFFFFFFE
;	----------------------<=

	CNOP	0,8
CopperRet:			; Retorna a Copperline Base.
	DC.W	$0088,0
	DC.L	$FFFFFFFE


; ------------------------------------------------ ;
	CNOP	0,8
NOSPRIT:DC.L	$FE00FF00,0,0,0,0
; ------------------------------------------------ ;

; ------------------------------------------------ ;
	CNOP	0,8
Panel:	INCBIN	"data/Panel.raw"
; ------------------------------------------------ ;

	DS.B	32*16	; Seguridad!


; <=----------------------------------------------=>
; <=----------------------------------------------=>
	CNOP	0,8
GGLogo:	INCBIN	"data/AmiMasterGear_Logo.raw"
	CNOP	0,8
GBTeclado:INCBIN	"data/Teclado.raw"
	CNOP	0,8
GBJoyStick:INCBIN	"data/JoyStick.raw"
	CNOP	0,8
GBJoypad:INCBIN	"data/Joypad.raw"
	CNOP	0,8
GBCD32:	INCBIN	"data/CD32.raw"
		CNOP	0,8
MSX2Pub:	;INCBIN	"data/AmiMSX2_Pub.raw"

	CNOP	0,8
MsZero:	INCBIN	"data/MsZero.raw"

	CNOP	0,8
BUSYGFX:
	dc.w	$0000,$0000
	dc.w	$0400,$07C0
	dc.w	$0000,$07C0
	dc.w	$0100,$0380
	dc.w	$0000,$07E0
	dc.w	$07C0,$1FF8
	dc.w	$1FF0,$3FEC
	dc.w	$3FF8,$7FDE
	dc.w	$3FF8,$7FBE
	dc.w	$7FFC,$FF7F
	dc.w	$7EFC,$FFFF
	dc.w	$7FFC,$FFFF
	dc.w	$3FF8,$7FFE
	dc.w	$3FF8,$7FFE
	dc.w	$1FF0,$3FFC
	dc.w	$07C0,$1FF8
	dc.w	$0000,$07E0
	dc.w	$0000,$0000
	dc.w	$0000,$0000
	dc.w	$0000,$0000

	DS.B	16	; Seguridad!

	CNOP	0,8
ONDA:	DC.B	127,-128,127,-128

	CNOP	0,8
Ruido:	INCBIN	"data/Sample-Ruido"

	DS.B	32*16	; Seguridad!
; <=----------------------------------------------=>
; <=----------------------------------------------=>



;	------------------------
	SECTION	Graficos,BSS_C
;	------------------------

; =----------------------------------------=> Gfx y Spr en Chip.
		CNOP	0,8
		DS.B	32*16
PantGfx:	DS.W	32*256*4
		DS.B	32*16
Plano5:		DS.W	32*256*4
		DS.B	32*16

NEXBPL=64
SizePl5PaGx=(Plano5-PantGfx)

; =----------------------------------------<=
	CNOP	0,8
Sprit0:	DS.B	16+(8*256*2)+16
Sprit1:	DS.B	16+(8*256*2)+16
Sprit2:	DS.B	16+(8*256*2)+16
Sprit3:	DS.B	16+(8*256*2)+16
Sprit4:	DS.B	16+(8*256*2)+16
Sprit5:	DS.B	16+(8*256*2)+16
Sprit6:	DS.B	16+(8*256*2)+16
Sprit7:	DS.B	16+(8*256*2)+16

NexSpr=Sprit1-Sprit0
OtrSpr=Sprit2-Sprit0

; =----------------------------------------=> Copper Optiones de Linea.
CopperOpts0:	DS.W	1024*8
		DS.W	32*16

CopperOpts1:	DS.W	1024*8
		DS.W	32*16
; =----------------------------------------<=
		DS.W	32*16

; =----------------------------------------<=



;	------------------------
	SECTION	Memoria,BSS
;	------------------------

; =----------------------------------------=> Copias Gfx en Fast.
		CNOP	0,8
		DS.B	32*16
PantGfxFast:	DS.W	32*256*4
		DS.B	32*16
PantGfxMask:	DS.B	36*256
PantSprFast:	DS.B	36*256*4
		DS.B	32*16
; =----------------------------------------<=

; =----------------------------------------=> MasterGear RAM.
	CNOP	0,8
	DS.B	$80
VPAL:	DS.W	32
	DS.B	$80
VPOL:	DS.W	32
	DS.B	$80
VRAM:	DS.B	16*1024
	DS.B	$80
IRAM:	DS.B	16*1024
	DS.B	$80
	IFD	AMG_SRAM2
SRAM:	DS.B	32*1024			; two 16K banks
	ELSE
SRAM:	DS.B	16*1024
	ENDC
	DS.B	$80
NoRAM:	DS.B	16*1024
	DS.B	$80
; =----------------------------------------<=

; =----------------------------------------=> Tablas de conversión "Flip X"
		CNOP	0,8
		DS.L	2		; <=--  No quitar.
TablaFlipX	DS.B	$100
; =----------------------------------------<=

; =----------------------------------------=> Tablas de Gráficos rotados de Sprites.
	CNOP	0,8
TablaGfxSpr:	DS.W	256*8
; =----------------------------------------<=

	DS.B	32*16	; Seguridad!

