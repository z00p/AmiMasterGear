
;	Menu para AmiMasterGear Emulator.
;	Por: Juan Antonio Gómez Gálvez

;    DC.L    $80000093,1			; En MainMenuWIN
;    DC.L    $80080032,6,$00000000		; En MTags0

_SysBase=4

MenuLaunch:
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	GadNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_GadToolsBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	IntNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_IntuitionBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	DosNom(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_DosBase
	BEQ	LibsError
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	AslNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_AslBase
; <=----------------------------------=>
	MOVEQ	#0,D0
	LEA	XpkNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_XpkBase
; <=----------------------------------=>
	MOVEQ	#3,D0
	LEA	StcNom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_StcBase
	BNE.S	YaStc20
	MOVEQ	#3,D0
	LEA	Stc2Nom(PC),A1
	MOVE.L	4.W,A6
	JSR	-$228(A6)
	MOVE.L	D0,_StcBase
YaStc20:
; <=-----------------------=>

; <=----------------------------------=>
	CLR.L	MENSWB
	MOVE.L	$4.W,A6
	SUB.L	A1,A1
	JSR	-$126(A6)
	MOVE.L	D0,A2
	TST.L	$AC(A2)
	BNE.S	CLI
	LEA	$5C(A2),A0
	JSR	-$180(A6)
	LEA	$5C(A2),A0
	JSR	-$174(A6)
	MOVE.L	D0,MENSWB
	MOVE.L	D0,A2
	MOVE.L	$24(A2),D0
	BEQ.S	CLI
	MOVE.L	_DosBase,A6
	MOVE.L	D0,A0
	MOVE.L	(A0),D1
	JSR	-$7E(A6)
CLI:
; <=----------------------------------=>

	IFD	AMG_TITLES
	JSR	AmgTitles
	ENDC
	IFD	AMG_PADS
	MOVE.L	#AmgPadLab3,JoyTypeLabels+12	; 'Standard Joypad' (the same read as Amiga JoyStick) -> 'KTRL CD32+'
	ENDC
	IFD	AMG_PADDBG
	MOVE.L	#AmgIn00Dbg,Ins		; test: port $00 shows the raw CD32 read
	ENDC
	IFD	AMG_PORTLABELS
	MOVE.L	#AmgPortLabP2,JoyPortLabels	; first button = player 1 = Amiga joystick port (2)
	MOVE.L	#AmgPortLabP1,JoyPortLabels+4	; second = player 2 = Amiga mouse port (1)
	ENDC
	LEA	DirInfoText(PC),A0
	BSR	Centrar

; <=-----------------------=>

	OR.W	#$0010,MainMenuNewMenu16+$A	; disable Edit Prefs ;

	BSR	Programa

; <=-----------------------=>
	MOVE.L	BucCart(PC),D0
	BEQ.S	NoHayCart2
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
NoHayCart2:
; <=-----------------------=>
	TST.L	_AslBase(PC)
	BEQ.S	NoHayAsl2

	MOVE.L	InsReqBase,A0
	MOVE.L	_AslBase,A6
	JSR	-$36(A6)	; FreeAslRequest.

	MOVE.L	FroReqBase,A0
	MOVE.L	_AslBase,A6
	JSR	-$36(A6)	; FreeAslRequest.

	MOVE.L	SavReqBase,A0
	MOVE.L	_AslBase,A6
	JSR	-$36(A6)	; FreeAslRequest.
NoHayAsl2:
; <=-----------------------=>
	MOVE.L	$4.W,A6
	TST.L	MENSWB(PC)
	BEQ.S	MENSWBRET
	JSR	-$84(A6)
	MOVE.L	MENSWB(PC),A1
	JSR	-$17A(A6)
MENSWBRET:
; <=-----------------------=>

; <=-----------------------=>
LiberaLib:MACRO
	MOVE.L	\1,A1
	TST.L	A1
	BEQ.S	\@LibLib
	MOVE.L	$4.W,A6
	JSR	-$19E(A6)	; Libera Librería.
\@LibLib:
	ENDM

LibsError:
	LiberaLib _DosBase
	LiberaLib _IntuitionBase
	LiberaLib _GadToolsBase
	LiberaLib _AslBase
	LiberaLib _XpkBase
	LiberaLib _StcBase
MenuRET:
	RTS
; <=-----------------------=>

; <=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=>

;*;	DC.L	$80080001,Texto Ventana
;*;	DC.L	$80080002,Screen WND donde aparece el requester.
;*;	DC.L	$80080003,Coor X
;*;	DC.L	$80080004,Coor Y
;*;	DC.L	$80080005,Size X
;*;	DC.L	$80080006,Size Y
;*;	DC.L	$80080009,Directorio
;*;	DC.L	$8008000A,PatrÓn
;*;	DC.L	$80080012,Texto Ok
;*;	DC.L	$80080013,Texto Cancel
;*;	DC.L	$80080014,Patron On=1/Off=0
;*;	DC.L	$8008002F,1	; 1=Modo Directorios.
;*;	DC.L	$8008003C,1	; 1=No muestra los "#?.info"

	CNOP	0,4
InsTags:
	DC.L	$80080002,0
	DC.L	$80080012,tInsert
	DC.L	$80080003,165
	DC.L	$80080004,11
	DC.L	$80080006,196
	DC.L	$8008003C,11		; No muestra los "#?.info"
	DC.L	$80080009,DirPrefs+$20
	DC.L	0,0

	CNOP	0,4
InsLoadTags:
	DC.L	$80080012,tInsert
	DC.L	$80080001,tInsLoad
	DC.L	$8008002C,0		; 0=Modo Load.
	DC.L	0,0

; ---

	CNOP	0,4
FroTags:
	DC.L	$80080002,0
	DC.L	$80080012,tLoad
	DC.L	$80080003,165
	DC.L	$80080004,11
	DC.L	$80080006,196
	DC.L	$8008003C,11		; No muestra los "#?.info"
	DC.L	$80080009,DirPrefs+$200
	DC.L	0,0

	CNOP	0,4
SavTags:
	DC.L	$80080002,0
	DC.L	$80080012,tLoad
	DC.L	$80080003,165
	DC.L	$80080004,11
	DC.L	$80080006,196
	DC.L	$8008003C,11		; No muestra los "#?.info"
	DC.L	$80080009,DirPrefs+$300
	DC.L	0,0

	CNOP	0,4
FroGetTags:
	DC.L	$80080012,tGet
	DC.L	$80080001,tFroGet
	DC.L	$8008002C,0		; 0=Modo Load.
	DC.L	0,0

	CNOP	0,4
FroLoadTags:
	DC.L	$80080012,tLoad
	DC.L	$80080001,tFroLoad
	DC.L	$80080008,FileNomFro2
	DC.L	$8008002C,0		; 0=Modo Load.
	DC.L	0,0

	CNOP	0,4
FroSaveTags:
	DC.L	$80080012,tSave
	DC.L	$80080001,tFroSave
	DC.L	$80080008,FileNomFro2
	DC.L	$8008002C,1		; 1=Modo Save.
	DC.L	0,0

	CNOP	0,4
IFFSaveTags:
	DC.L	$80080001,tScrSave
	DC.L	$80080009,0
	DC.L	$80080012,tSave
	DC.L	$8008002C,1		; 1=Modo Save.
	DC.L	0,0


	EVEN
tInsert:DC.B	"Insert",0,0
tInsLoad:DC.B	"Select Cartridge file.",0,0
tGet:	DC.B	"Get",0,0
tLoad:	DC.B	"Load",0,0
tSave:	DC.B	"Save",0,0
tFroGet:DC.B	"Select Frozen Directory.",0,0
tFroLoad:DC.B	"Load Frozen file.",0,0
tFroSave:DC.B	"Save Frozen file.",0,0
tScrSave:DC.B	"Save Screen as IFF-ILBM file.",0,0
tSprSave:DC.B	"Save Sprites as IFF-ILBM file.",0,0
tRAMSave:DC.B	"Save RAM as Binary file.",0,0
tVRAMSave:DC.B	"Save VRAM as Binary file.",0,0

; <=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=>

; <=-----------------------=>
	CNOP	0,8
DirInfoText:
	DC.L	AboutText0,324
	DC.L	AboutText1,324
	DC.L	AboutText2,324
	DC.L	AboutText3,324
	DC.L	AboutText4,324
	DC.L	AboutText5,324
	DC.L	AboutText6,324
	DC.L	AboutText7,324
	DC.L	AboutText8,324
	DC.L	AboutText9,324
	DC.L	AboutText10,324
	DC.L	0,0,0,0
; <=-----------------------=>

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,4
DisBase:	DC.L	0
BucFile:	DC.L	0
InsReqBase:	DC.L	0
XpkFibBase:	DC.L	0
FroReqBase:	DC.L	0
SavReqBase:	DC.L	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
DirCart:	DC.L	0
BucCart:	DC.L	0
PagCart:	DC.W	0
Comprimido:	DC.B	0
RawCartSize:	DC.B	0
	IFD	AMG_ANYSIZE
AmgRealPages:	DC.W	0		; 16K pages in the file (PagCart is this rounded up)
	ENDC
CheatDir:	DC.W	0
BucPunto:	DC.W	0
CheckId:	DC.L	0
EsUn060:	DC.B	0
GoDat:		DC.B	0
DisCheaDat:	DC.B	0
SaveVRAMdat:	DC.B	0
DirFrozen:	DC.L	0
BucFrozen:	DC.L	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
_GadToolsBase:	DC.L	0
_IntuitionBase:	DC.L	0
_DosBase:	DC.L	0
_AslBase:	DC.L	0
_XpkBase:	DC.L	0
_StcBase:	DC.L	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,8
GadNom:		DC.B	"gadtools.library",0
IntNom:		DC.B	"intuition.library",0
DosNom:		DC.B	"dos.library",0
AslNom:		DC.B	"asl.library",0
XpkNom:		DC.B	"xpkmaster.library",0
StcNom:		DC.B	"stc.library",0
Stc2Nom:	DC.B	"stc020.library",0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,8
MENSWB:		DC.L	0
ControlKeys:	DC.W	0
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		CNOP	0,4
FileNom:	DS.B	$208
FileNomSav:	DS.B	$208
FileNomFro:	DS.B	$208
FileNomSav2:	DS.B	$108
FileNomFro2:	DS.B	$108
		CNOP	0,4
BuferDsk:	DS.L	8
		CNOP	0,4
Examine:	DS.B	520
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		DS.L	25	; Seguriad

tErNoAsl:	DC.B	"      I need asl.library      ",0
tErNoStc:	DC.B	"I need stc.library for unpack!",0
tErNoCartucho:	DC.B	"   Cartridge not inserted!!   ",0
tErOpenFile:	DC.B	" I cannot open file selected! ",0
tErReadFile:	DC.B	"Error while loading Cartridge!",0
tErNoGBCart:	DC.B	"   Invalid Cartridge size!!   ",0
tErOutOfMem:	DC.B	"   -=>  Out of memory!  <=-   ",0
tErSavePrefs:	DC.B	"    Preferences not saved!    ",0
tErNoCheats:	DC.B	" Power ON with Cheats enabled!",0
tErPowerON:	DC.B	"   Please,  Power ON first!   ",0
tErNoFrozen:	DC.B	"      Not a Frozen file!      ",0
	IFD	AMG_FROZERR
tAmgFznLoad:	DC.B	"   Frozen file not loaded!    ",0
tAmgFznSave:	DC.B	"    Frozen file not saved!    ",0
	ENDC

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
		DS.L	10	; Seguriad
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-

	CNOP	0,8
CabFileBuf:	DS.L	4
*************************************************************
		DS.L	25	; Seguriad
*************************************************************
*************************************************************

; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Programa:
; ------------------------------------------
	BSR	LoadPrefs
	BSR	PonPrefs
; ------------------------------------------
	BSR	SetupScreen
; ------------------------------------------

	BSR	MiraAGA
	TST.L	D0
	BEQ	Quitar

	BSR	MC68020
	TST.L	D0
	BEQ	Quitar

;;	BSR	CheckAGA

; ------------------------------------------

; ------------------------------------------
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenMainMenuWindow
; ------------------------------------------
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	move.l  Scr,a0
	move.l  40(a0),a1
	move.w  4(a1),D1
	MOVE.L	MainMenuWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsMasterGearPic,A1
	MOVE.L	_IntuitionBase,A6
	JSR	-114(A6)
; ------------------------------------------
	BSR	ImpJoyType
; ------------------------------------------
; <=-----------------------=>
	IFD	AMG_DRAWERS
	JSR	AmgDrawers
	ENDC
	TST.L	_AslBase(PC)
	BEQ.S	NoHayAsl

	MOVEQ	#0,D0
	LEA	InsTags(PC),A0
	MOVE.L	MainMenuWnd,4(A0)
	MOVE.L	_AslBase,A6
	JSR	-$30(A6)	; AllocAslRequest.
	MOVE.L	D0,InsReqBase

	MOVEQ	#0,D0
	LEA	FroTags(PC),A0
	MOVE.L	MainMenuWnd,4(A0)
	MOVE.L	_AslBase,A6
	JSR	-$30(A6)	; AllocAslRequest.
	MOVE.L	D0,FroReqBase

	MOVEQ	#0,D0
	LEA	SavTags(PC),A0
	MOVE.L	MainMenuWnd,4(A0)
	MOVE.L	_AslBase,A6
	JSR	-$30(A6)	; AllocAslRequest.
	MOVE.L	D0,SavReqBase
NoHayAsl:
; <=-----------------------=>
BucleMenu:
	IFD	AUTOTEST
	IFD	AUTOHELP
	MOVEQ	#1,D0			; test builds: the PC grabs the menu, then the help page
	JSR	AutoGrab
	BSR	HelpPage
	ENDC
	BSR	DisMouse
	BSR	InsertAuto
	TST.L	BucCart
	BEQ.S	.noCart
	TST.B	AutoFailed
	BNE.S	.noCart
	LEA	AutoStartText,A0
	JSR	AutoPuts
	BSR	PowerON
	IFD	AUTOCYCLE
	JSR	AutoNextRom		; test builds: the next cartridge on the command line, Insert + Power ON again
	BEQ.S	.noCart
	BSR	EnaMouse
	BRA	BucleMenu
	ENDC
.noCart:
	LEA	AutoEndText,A0
	JSR	AutoPuts
	BSR	EnaMouse
	BRA	AutoQuit
	ENDC
; ------------------------------------------
	LEA	MainMenuPunts,A1
	BSR	Control
; ------------------------------------------
	BSR	ActuPrefs
	TST.B	DirPrefs+$0C(PC)
	BNE.S	SiSaveBatt
	BSR	AskSaveBatt
	BMI.S	BucleMenu
	BRA.S	NoSaveBatt
SiSaveBatt:
	BSR	SaveBatt
NoSaveBatt:
; ------------------------------------------
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	JSR	OpenQuitWindow
	LEA	QuitPunts,A1
	BSR	Control
	JSR	CloseQuitWindow
	BSR	EnaMouse
; ------------------------------------------
	IFD	AUTOTEST
AutoQuit:
	ENDC
	BSR	CloseMainMenuWindow
; ------------------------------------------
; --------------------------		; Screen mode on Exit.
	MOVE.B	DirPrefs+$18(PC),D0
	LSR.B	#1,D0
	BEQ.S	NoChangeCon
	MOVEQ	#0,D1
	LSR.B	#1,D0
	BNE.S	EsNTSC2
	MOVE.W	#$20,D1
EsNTSC2:MOVE.W	D1,$DFF1DC
NoChangeCon:
; ------------------------------------------
Quitar:	JSR	CloseDownScreen
; ------------------------------------------=> Quit
	MOVEQ	#0,D0	; Salir Sín Errores
	RTS
; ------------------------------------------
; ------------------------------------------
NoQuit:
	ADD.W	#16+4,SP
	JSR	CloseQuitWindow
	BSR	EnaMouse
	BRA	BucleMenu
; ------------------------------------------

; <=-----------------------=>
	CNOP	0,8
NeedASL:
	LEA	tErNoAsl(PC),A0
	JMP	ImpError
; <=-----------------------=>

; ------------------------------------------
; ******************************************
; ------------------------------------------

About:
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenAboutWindow

; TEMPORAL:
	LEA	AboutGadgets+(GD_Aboutmore*4),A0
	MOVE.L	AboutWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff


	LEA	AboutPunts,A1
	BSR	Control

	BSR	CloseAboutWindow
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

HelpPage:
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenHelpPageWindow

	MOVEQ	#20,D0
	MOVEQ	#16,D1
	MOVE.L	#GBTeclado,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVE.L	#264,D0
	MOVEQ	#16,D1
	MOVE.L	#GBCD32,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVEQ	#20,D0
	MOVE.L	#110,D1
	MOVE.L	#GBJoyStick,DirJoyTypePic
	BSR	ImprHelpJoy

	MOVE.L	#264,D0
	MOVE.L	#110,D1
	MOVE.L	#GBJoypad,DirJoyTypePic
	BSR	ImprHelpJoy

	IFD	AUTOHELP
	MOVEQ	#2,D0			; test builds: the PC grabs the help page
	JSR	AutoGrab
	ELSE
	LEA	HelpPagePunts,A1
	BSR	Control
	ENDC

	BSR	CloseHelpPageWindow
	BSR	EnaMouse
	RTS

ImprHelpJoy:
	move.l  Scr,a0
	move.l  40(a0),a1
	ADD.w	4(a1),D1
	MOVE.L	HelpPageWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsJoyTypePic,A1
	MOVE.L	_IntuitionBase,A6
	JMP	-114(A6)

; ------------------------------------------
; ******************************************
; ------------------------------------------

ImpError:
	IFD	AUTOTEST
	JMP	AutoError		; on the serial port, no window to click
	ENDC
	MOVE.L	A0,ImpErrorText0+$C

	BSR	DisMouse

	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenImpErrorWindow

	LEA	ImpErrorPunts,A1
	BSR	Control

	BSR	CloseImpErrorWindow
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

CheatMode:
	IFD	GG_Menu
	LEA	tErPowerON(PC),A0
	TST.B	GoDat(PC)		; ¿MSX Encendido?
	BEQ	ImpError
	ENDC

	LEA	tErNoCheats(PC),A0
	TST.B	DisCheaDat(PC)		; ¿Modo Cheat activo?
	BNE	ImpError

	BSR	DisMouse

	MOVEM.L	MCeros(PC),D0-D7/A0-A6
	JSR	OpenCheatWindow
	LEA	CheatPunts,A1
	BSR	Control

	MOVE.L	([CheatGadgets+(GD_PokeAddress*4)],$50.w),A0
	MOVE.L	(A0)+,PokeAddressString
	MOVE.W	(A0)+,PokeAddressString+4
	MOVE.L	([CheatGadgets+(GD_PokeValue*4)],$50.w),A0
	MOVE.L	(A0)+,PokeValueString
	MOVE.L	([CheatGadgets+(GD_CheatSeaVal*4)],$50.w),A0
	MOVE.L	(A0)+,CheatSeaValString
	MOVE.L	([CheatGadgets+(GD_CheatComVal*4)],$50.w),A0
	MOVE.L	(A0)+,CheatComValString

	JSR	CloseCheatWindow
	BSR	EnaMouse
	RTS

DoPoke:
	MOVE.L	([CheatGadgets+(GD_PokeAddress*4)],$50.w),A0
	BSR	CalculPok
	MOVE.L	D0,-(SP)

	MOVE.L	([CheatGadgets+(GD_PokeValue*4)],$50.w),A0
	BSR	CalculPok

	MOVE.L	D0,D1
	MOVE.L	(SP)+,D0

	MOVE.L	D0,A0
	LSR.W	#8,D0
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D0		; 8K pages
	ELSE
	LSR.B	#6,D0
	ENDC
	LEA	Regs,A3
	MOVE.L	PagWrite(A3,D0.W*4),D2
	BEQ.S	NoInitTipos
	ADD.L	D2,A0
	MOVE.B	D1,(A0)
NoInitTipos:
	RTS

CalculPok:
	TST.B	(A0)
	BNE.S	PokBien
	MOVE.W	#$3000,(A0)
PokBien:
	MOVEQ	#0,D0
PokBuc1:
	TST.B	(A0)
	BEQ.S	PokCon1
	ADDQ	#1,A0
	ADDQ.W	#1,D0
	BRA.S	PokBuc1
PokCon1:
	LEA	BufTxt(PC),A1
	MOVE.L	#"0000",(A1)+
	MOVE.L	#"0000",(A1)+
	MOVE.W	#"00",(A1)+

PokBuc0:
	TST.B	(A0)
	BEQ.S	PokCon0
	CMP.B	#" ",(A0)
	BEQ.S	PokCon0
	MOVE.B	(A0),-(A1)
PokCon0:
	SUBQ	#1,A0
	DBF	D0,PokBuc0

	CMP.B	#"$",(A1)
	BEQ.S	EsHexade

	LEA	BufTxt(PC),A0
	BSR	PASHEX
	BRA	EsDecimal

	CNOP	0,4
EsHexade:
	MOVE.B	#"0",(A1)
	LEA	BufTxt+5(PC),A0

	MOVEQ	#0,D0
	MOVE.B	1(A0),D7
	BSR	Calcul
	MOVE.B	D7,D0
	MOVE.B	2(A0),D7
	BSR	Calcul
	MOVE.B	D7,D1
	MOVE.B	3(A0),D7
	BSR	Calcul
	MOVE.B	D7,D2
	MOVE.B	4(A0),D7
	BSR	Calcul
	MOVE.B	D7,D3
	BFINS	D0,D0{16:4}
	BFINS	D1,D0{20:4}
	BFINS	D2,D0{24:4}
	BFINS	D3,D0{28:4}
EsDecimal:
	RTS

Calcul:
	SUB.B	#"0",D7
	CMP.B	#10,D7
	BLT.S	CalcURet
	SUB.B	#"A"-"9"-1,D7
	CMP.B	#16,D7
	BLT.S	CalcURet
	SUB.B	#"a"-"F"-11,D7
CalcURet:RTS

Calcul2:
	CMP.B	#$A,D2
	BCS.S	NoEsNum
	ADD.B	#"A"-"9"-1,D2
NoEsNum:ADD.B	#"0",D2
	RTS

Calcul3:
	BFEXTU	D1{16:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	BFEXTU	D1{20:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	BFEXTU	D1{24:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	BFEXTU	D1{28:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	RTS

Calcul3b:
	BFEXTU	D1{24:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	BFEXTU	D1{28:4},D2
	BSR	Calcul2
	MOVE.B	D2,(A2)+
	RTS

BufTxt:	DS.B	14

; -=-=-

	CNOP	0,8
CheatSearch:
	MOVE.L	CheatWnd,A0	; A0=Window
	BSR	PBUSY

	LEA	CheatIText3,A0
	LEA	CheatIText4,A1
	LEA	CheatIText5,A2
	LEA	CheatIText6,A3
CheatIbuc:
	MOVE.B	#" ",(A0)+
	MOVE.B	#" ",(A1)+
	MOVE.B	#" ",(A2)+
	MOVE.B	#" ",(A3)+
	TST.B	(A0)
	BNE.S	CheatIbuc

	LEA	CheatIText3,A0
	MOVE.L	#"Ok! ",(A0)

	LEA	CheatBuf,A0
	MOVE.W	#((8*1024)/4)-1,D0
CheBuc1:CLR.L	(A0)+
	DBF	D0,CheBuc1

	MOVE.L	([CheatGadgets+(GD_CheatSeaVal*4)],$50.w),A0
	BSR	CalculPok

	LEA	CheatBuf,A1
	MOVEQ	#0,D1
	LEA	Regs,A3
CheBuc0:
	MOVE.W	D1,D2
	LSR.W	#8,D2
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D2		; 8K pages
	ELSE
	LSR.B	#6,D2
	ENDC
	MOVE.L	D1,A0
	ADD.L	PagWrite(A3,D2.W*4),A0
	CMP.B	(A0),D0
	BNE.S	NoEsIgual
	MOVE.W	D1,D2
	LSR.W	#3,D2
	BSET	D1,(A1,D2.W)
NoEsIgual:
	ADDQ.W	#1,D1
	BCC.S	CheBuc0

	move.l	_IntuitionBase,a6
	move.l	CheatWnd,a0
	move.b	54(a0),D0
	move.b	55(a0),D1
	extb.l	D0
	extb.l	D1
	move.l	50(a0),a0
	lea	CheatText3,a1
	jsr     PrintIText(a6)

	MOVE.L	CheatWnd,A0	; A0=Window
	BSR	PNORM
	RTS
; -=-
	CNOP	0,8
CheatCompare:
	CLR.W	CheatDir
CheatMore:
	MOVE.L	CheatWnd,A0	; A0=Window
	BSR	PBUSY

	LEA	CheatGadgets+(GD_CheatMore*4),A0
	MOVE.L	CheatWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff

	LEA	CheatIText3,A0
	LEA	CheatIText4,A1
	LEA	CheatIText5,A2
	LEA	CheatIText6,A3
CheatIbuc2:
	MOVE.B	#" ",(A0)+
	MOVE.B	#" ",(A1)+
	MOVE.B	#" ",(A2)+
	MOVE.B	#" ",(A3)+
	TST.B	(A0)
	BNE.S	CheatIbuc2

	LEA	CheatIText3,A0
	MOVE.L	#"None",(A0)
	MOVE.B	#".",4(A0)

	MOVE.L	([CheatGadgets+(GD_CheatComVal*4)],$50.w),A0
	BSR	CalculPok

	LEA	CheatBuf,A1
	LEA	CheatIText3,A2
	MOVEQ	#4,D4
	MOVEQ	#8,D3
	LEA	Regs,A3
	MOVEQ	#0,D1
	MOVE.W	CheatDir,D1
CheBuc2:
	MOVE.W	D1,D2
	LSR.W	#8,D2
	IFD	AMG_RAMMIRROR
	LSR.B	#5,D2		; 8K pages
	ELSE
	LSR.B	#6,D2
	ENDC
	MOVE.L	D1,A0
	ADD.L	PagWrite(A3,D2.W*4),A0
	CMP.B	(A0),D0
	BNE	NoEsIgual2
	MOVE.W	D1,D2
	LSR.W	#3,D2
	BTST	D1,(A1,D2.W)
	BEQ	NoEsIgual2
; -=-
	MOVE.B	#"$",(A2)+

	BSR	Calcul3

	SUBQ.W	#1,D3
	BNE.S	CheFinLin

	ADDQ	#1,A2
	MOVEQ	#8,D3

	SUBQ.W	#1,D4
	BNE.s	NoEsIgual2

	ADDQ.W	#1,D1
	BCS.S	CheatFinal
	MOVE.W	D1,CheatDir

	LEA	CheatGadgets+(GD_CheatMore*4),A0
	MOVE.L	CheatWnd,A1
	MOVEQ	#0,D0
	BSR	GadsOnOff

	BRA.S	CheatFinal
CheFinLin:
	MOVE.B	#" ",(A2)+
; -=-
NoEsIgual2:
	ADDQ.W	#1,D1
	BCC.S	CheBuc2

CheatFinal:
	move.l	_IntuitionBase,a6
	move.l	CheatWnd,a0
	move.b	54(a0),D0
	move.b	55(a0),D1
	extb.l	D0
	extb.l	D1
	move.l	50(a0),a0
	lea	CheatText3,a1
	jsr     PrintIText(a6)

	MOVE.L	CheatWnd,A0	; A0=Window
	BSR	PNORM
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

AskSaveBatt:
	TST.B	DirPrefs+$0D(PC)
	BEQ.S	AskSaveBattRet

	BSR	CalChecksum
	CMP.L	CheckId,D2
	BEQ.S	AskSaveBattRet

	BSR	DisMouse
	MOVEM.L	MCeros(PC),D0-D7/A0-A6
	JSR	OpenAskSaveBattWindow

	LEA	AskSaveBattPunts,A1
	BSR	Control

	JSR	CloseAskSaveBattWindow
	BSR	EnaMouse
AskSaveBattRet:
	MOVEQ	#1,D0
	RTS

AskSaveBattSave:
	ADD.W	#16+4,SP
	JSR	CloseAskSaveBattWindow
	BSR	EnaMouse

	BSR	SaveBatt

	MOVEQ	#0,D0
	RTS

AskSaveBattCancel:
	ADD.W	#16+4,SP
	JSR	CloseAskSaveBattWindow
	BSR	EnaMouse
	MOVEQ	#-1,D0
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

AskSureReset:
	MOVE.L	#"Rese",ClearIText0+16
	MOVE.B	#"t",ClearIText0+20
	BRA.S	AskSure
AskSureEject:
	MOVE.L	#"Ejec",ClearIText0+16
	MOVE.B	#"t",ClearIText0+20
	BRA.S	AskSure
AskSureClear:
	MOVE.L	#"Clea",ClearIText0+16
	MOVE.B	#"r",ClearIText0+20
AskSure:
	BSR	DisMouse
	MOVEM.L	MCeros(PC),D0-D7/A0-A6
	JSR	OpenClearWindow

	LEA	ClearPunts,A1
	BSR	Control

	CLR.L	-(SP)		; Yes
	BRA.S	AskSureCon
AskSureNo:
	ADD.W	#16+4,SP
	MOVEQ	#-1,D0
	MOVE.L	D0,-(SP)	; No
AskSureCon:
	JSR	CloseClearWindow
	BSR	EnaMouse
	MOVE.L	(SP)+,D0
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------


; ------------------------------------------
; ------------------------------------------
; ------------------------------------------


; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Continue:
	MOVEQ	#-1,D7
	BRA.S	ContinueCon
	CNOP	0,8
PowerON:
	MOVEQ	#00,D7
ContinueCon:
	LEA	tErNoCartucho(PC),A0
	TST.L	BucCart(PC)
	BEQ	ImpError

	MOVEM.L	D0-D7/A0-A6,-(SP)
	BSR	ActuPrefs
	MOVEM.L	(SP)+,D0-D7/A0-A6

	TST.L	D7			; ¿Es Power ON?
	BNE.S	NoLoRefres
	MOVE.B	DirPrefs+$0E(PC),DisCheaDat	; Refresca Disable Cheats.
NoLoRefres:
; -=-=-
	LEA	DirPrefs(PC),A5
; -=-=-
	TST.B	GoDat(PC)		; ¿Encendido por primera vez?
	BEQ.S	NoReset
	TST.L	D7			; ¿Es Power ON?
	BNE.S	NoReset
	TST.B	$0A(A5)			; ¿Hacer Reset?
	BEQ.S	NoReset
	MOVEM.L	D7/A5,-(SP)
	BSR	AskSureReset
	MOVEM.L	(SP)+,D7/A5
	TST.L	D0
	BEQ.S	NoReset
	RTS
NoReset:
; -=-=-
	MOVEQ	#0,D1
	TST.B	$0F(A5)			; Frecuencia pantalla.
	BNE.S	NoEsNTSC
	MOVE.W	#$20,D1
NoEsNTSC:MOVE.W	D1,$DFF1DC
; -=-=-
	ST	GoDat
; -=-=-
	IFD	GG_Menu
	JSR	MasterGearEmul
	ENDC
; -=-=-
	BSR	RefrescaReloj
; -=-=-
	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#0,D0
	BSR	GadsOnOff
; -=-=-
	BSR	CalChecksum
	CMP.L	CheckId,D2
	BEQ.S	BattNoChanged

	LEA	MainMenuText11,A1
	MOVE.W	#$0204,(A1)
	MOVE.L	#tTipoRAM3,$0C(A1)		; 'RAM:' Changed
	MOVE.L	MainMenuWnd,A0
	BSR	TxtPrint
BattNoChanged:
; -=-=-
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
Eject:
	TST.L	BucCart(PC)
	BEQ	EjNoHayCart

	BSR	AskSureEject
	BEQ.S	EjectSi
	RTS
EjectSi:
	MOVE.L	BucCart(PC),D0
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
	CLR.L	DirCart


	MOVE.L	#MainMenuIText12,MainMenuText12+$C	; No Cart Inserted.
	MOVE.L	#tTipoROM,MainMenuText10+$C		; 'ROM:' ----
	MOVE.W	#$0100,MainMenuText11
	MOVE.L	#tTipoRAM0,MainMenuText11+$C		; 'RAM:' -------


	MOVE.L	InsReqBase,A2
	MOVE.L	4(A2),A0
	LEA	tNomFileCart,A1
	BSR	PONOM
	move.l  _IntuitionBase,a6
	move.l  MainMenuWnd,a0
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	lea	MainMenuText10,a1
	jsr     PrintIText(a6)
EjNoHayCart:

	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff

	RTS

; ------------------------------------------

	CNOP	0,8
Insert:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	BSR	ActuPrefs

	TST.B	DirPrefs+$0C(PC)
	BNE.S	SiSaveBatt2
	BSR	AskSaveBatt
	BMI	MenuRET
	BRA.S	NoSaveBatt2
SiSaveBatt2:
	BSR	SaveBatt
NoSaveBatt2:

	BSR	DisMouse

	MOVE.L	InsReqBase,A0
	LEA	InsLoadTags,A1
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	BEQ	ReqCancel


	MOVE.L	InsReqBase,A2
	BSR	ArreglaNom

	IFD	AUTOTEST
InsertAuto:				; as Insert, with FileNom already filled in
	ENDC

;	--------------------
	TST.L	_XpkBase(PC)		; Mira si es un xpk.
	BEQ.S	NoXpkFile

	LEA	XpkFibBase,A0		; ¿Fichero xpk?
	LEA	xpkTags0(PC),A1
	MOVE.L	_XpkBase,A6
	JSR	-54(A6)		; xpkOpen
	BNE.S	NoXpkFile

	MOVE.L	XpkFibBase,A0		; ¿Comprimido con xpk?
	CMP.L	#1,(A0)
	BNE.S	NoXpkFile

	MOVE.L	4(A0),-(SP)

	MOVE.L	XpkFibBase,A0
	MOVE.L	_XpkBase,A6
	JSR	-78(A6)		; xpkClose

	MOVE.L	(SP)+,D0
	MOVE.L	D0,BucFile
	BSR	MiraCartSize
	BEQ.S	NoXpkFile

	MOVE.B	#$7F,Comprimido
	BRA.S	EsXpkFile
NoXpkFile:

;	--------------------
	MOVE.L	#FileNom,D1		; Open File
	MOVE.L	#$3ED,D2
	BSR	OpenFile
	BEQ	OpenError

	BSR	LongFile		; Mira Size.
	MOVE.L	D0,BucFile
	BEQ	ReadError

	MOVE.L	#(4*4),D3
	MOVE.L	#CabFileBuf,D2
	BSR	ReadFile
	BNE	ReadError

	CMP.W	#"S4",CabFileBuf
	BNE.S	NoStcComp
	MOVE.L	CabFileBuf+$08(PC),D0
	BSR	MiraCartSize
	BEQ.S	NoStcComp

	TST.L	_StcBase(PC)
	BEQ	ErNoStc

	ST	Comprimido
	BRA.S	SiStcComp
NoStcComp:

;	--------------------
	MOVE.L	BucFile(PC),D0
	BSR	MiraCartSize
	BEQ	NoGBCart
	SF	Comprimido
SiStcComp:
EsXpkFile:
	MOVE.W	D0,PagCart
	MULU	#$4080,D0
	ADD.L	#$80,D0
	MOVE.L	D0,-(SP)

	MOVE.L	BucCart(PC),D0
	BEQ.S	NoHayCart
	MOVE.L	DirCart(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.
	CLR.L	BucCart
NoHayCart:
	MOVE.L	(SP)+,BucCart

	MOVE.L	#$00010001,D1
	MOVE.L	BucCart,D0
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; Requiere memoria.
	MOVE.L	D0,DirCart
	BEQ	OutOfMem

;	--------------------

	CMP.B	#$7F,Comprimido
	BNE.S	NoDescomXpk

	LEA	xpkTags1(PC),A0
	MOVE.L	DirCart(PC),$0C(A0)
	ADD.L	#$80,$0C(A0)
	MOVE.L	BucCart(PC),$14(A0)	; tendria que ser BucFile
	MOVE.L	_XpkBase,A6
	JSR	-48(A6)		; xpkUnPack
;;	B??  error

	BRA.S	NoCompri0
NoDescomXpk:

;	--------------------
	LEA	CabFileBuf(PC),A1
	MOVE.L	DirCart,A0
	TST.B	Comprimido(PC)
	BNE.S	SiCompri0
	ADD.W	#$80,A0
SiCompri0:
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	(A1)+,(A0)+
	MOVE.L	A0,D2
	MOVE.L	BucFile(PC),D3
	SUB.L	#(4*4),D3
	BSR	ReadFile
	BNE	ReadError

	BSR	CloseFile
; -=-=-

	TST.B	Comprimido(PC)
	BEQ.S	NoCompri0

;	--------------------
	MOVE.L	DirCart,A1
	LEA	$80(A1),A0
	MOVE.L	_StcBase,A6
	JSR	-$24(A6)
	MOVE.L	DirCart,A0
	MOVE.W	#($80/4)-1,D0
DesStcBuc:
	CLR.L	(A0)+
	DBF	D0,DesStcBuc
	MOVE.L	CabFileBuf+$08,BucFile
NoCompri0:
; -=-=-
	TST.B	RawCartSize(PC)		; Para soportar el skip 512 bytes.
	BEQ.S	SiRawCartSize
	MOVE.L	DirCart,A0
	ADD.W	#$80,A0
	MOVE.L	BucFile,D0
	SUB.L	#$200,D0
BucRawCartSize:
	MOVE.B	$200(A0),(A0)+
	SUBQ.L	#1,D0
	BNE.S	BucRawCartSize
SiRawCartSize:
; -=-=-

; -=-=-
	MOVE.L	DirCart,A0
	ADD.W	#$80,A0
	MOVE.W	PagCart,D0
	MOVE.W	D0,D1
	MULU	#$4080,D1
	LEA	(A0,D1.L),A1
	MOVE.W	D0,D1
	MULU	#$4000,D1
	LEA	(A0,D1.L),A0
	SUBQ.W	#1,D0
ArrROMPagBuc0:
	MOVEQ	#($80/4)-1,D1
ArrROMPagBuc1:
	CLR.L	-(A1)
	DBF	D1,ArrROMPagBuc1
	MOVE.W	#($4000/4)-1,D1
ArrROMPagBuc2:
	MOVE.L	-(A0),-(A1)
	DBF	D1,ArrROMPagBuc2
	DBF	D0,ArrROMPagBuc0

	IFD	AMG_ANYSIZE
	MOVE.L	DirCart,A0		; pages past the file mirror the file's own pages
	ADD.W	#$80,A0
	MOVE.W	AmgRealPages,D2
	MOVEQ	#0,D3
AmgPadBuc:
	CMP.W	PagCart,D2
	BCC.S	AmgPadFin
	MOVE.W	D3,D0
	MULU	#$4080,D0
	LEA	(A0,D0.L),A1
	MOVE.W	D2,D0
	MULU	#$4080,D0
	LEA	(A0,D0.L),A2
	MOVE.W	#($4000/4)-1,D0
AmgPadCop:
	MOVE.L	(A1)+,(A2)+
	DBF	D0,AmgPadCop
	ADDQ.W	#1,D2
	ADDQ.W	#1,D3
	CMP.W	AmgRealPages,D3
	BCS.S	AmgPadBuc
	MOVEQ	#0,D3
	BRA.S	AmgPadBuc
AmgPadFin:
	ENDC

; -=-=-=-

	MOVE.L	#tNomFileCart,MainMenuText12+$C

	MOVEQ	#-1,D1
	MOVE.W	PagCart,D0
	LSR.W	#1,D0
	BEQ.S	InCalRom1
InCalRom:
	ADDQ.W	#1,D1
	LSR.W	#1,D0
	BCC.S	InCalRom
	MOVE.L	(TipoROM.W,PC,D1.W*4),MainMenuText10+$C
InCalRom1:

; -=-=-=-

	LEA	SRAM,A0
	IFD	AMG_SRAM2
	MOVE.W	#((1024*32)/4)-1,D0
	ELSE
	MOVE.W	#((1024*16)/4)-1,D0
	ENDC
BorraSRAM:CLR.L	(A0)+
	DBF	D0,BorraSRAM

; -=-=-=-

	BSR	MiraTipoCart	; Pone Master System o Game Gear según extensión

	TST.B	DirPrefs+$16(PC)	; ¿Es Game Gear?
	BEQ.S	NoESGGCon

	MOVE.L	DirCart(PC),A0
	ADD.L	#$80+$4000+$80+$3FFF,A0
	MOVE.B	(A0),D0
	AND.B	#$30,D0
	CMP.B	#$10,D0
	BEQ.S	EsJapanese
	BSR	European
	BRA.S	NoESGGCon
EsJapanese:
	BSR	Japanese
NoESGGCon:

; -=-=-=-

	MOVE.W	#$0100,MainMenuText11
	MOVE.L	#tTipoRAM0,MainMenuText11+$C		; 'RAM:' -------

	TST.B	DirPrefs+$0B(PC)
	BEQ.S	NoLeeBatt
	BSR	ReadBatt
NoLeeBatt:

	BSR	CalChecksum
	MOVE.L	D2,CheckId		; Guarda Check-Sum.

; -=-=-=-

	MOVE.L	InsReqBase,A2
	MOVE.L	4(A2),A0
	LEA	tNomFileCart,A1
	BSR	PONOM

	move.l  _IntuitionBase,a6
	move.l  MainMenuWnd,a0
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	lea	MainMenuText10,a1
	jsr     PrintIText(a6)

	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#1,D0
	BSR	GadsOnOff

	BSR	EnaMouse
	RTS

; ------------------------------------------

MiraTipoCart:
	MOVE.L	InsReqBase,A0
	MOVE.L	4(A0),A0
	IFD	AUTOTEST
	LEA	FileNom,A0		; no requester: the extension is in FileNom
	ENDC
	BSR	BuscaExt
	TST.L	D0
	BMI.S	NoCanviEmul
; ---
	MOVEQ	#0,D1			; Nuevo valor!!!
	MOVE.W	D0,D1
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_EmuType,D2
	MOVE.L	#$8008000F,D0
	BSR	UpdateTag
; ---
NoCanviEmul:

	LEA	FileNom(PC),A0
	LEA	FileNomSav(PC),A1
	LEA	FileNomFro(PC),A2
	MOVE.W	#$200,D0
SavBuc0:
	MOVE.B	(A0),(A1)+
	MOVE.B	(A0)+,(A2)+
	BEQ.S	SavCon0
	DBF	D0,SavBuc0
	MOVE.L	#"Mal"*256,FileNomSav
	MOVE.L	#"Mal"*256,FileNomFro
	RTS
SavCon0:
	MOVE.W	BucPunto,D0
	SUB.W	D0,A1
	MOVE.L	#".sav",(A1)+
	CLR.B	(A1)
	SUB.W	D0,A2
	MOVE.L	#".Fro",(A2)+
	MOVE.L	#"zen"*256,(A2)+
	SUBQ	#1,A2

	MOVE.W	#40-1,D0
SavBuc1:
	TST.B	-1(A1)
	BEQ.S	SavCon1
	CMP.B	#"/",-1(A1)
	BEQ.S	SavCon1
	CMP.B	#":",-1(A1)
	BEQ.S	SavCon1
	SUBQ	#1,A1
	DBF	D0,SavBuc1
	RTS
SavCon1:
	MOVE.L	A1,A0
	LEA	FileNomSav2,A1
	MOVE.W	#50-1,D0
	BSR	CopyNom

	MOVE.W	#40-1,D0
SavBuc2:
	TST.B	-1(A2)
	BEQ.S	SavCon2
	CMP.B	#"/",-1(A2)
	BEQ.S	SavCon2
	CMP.B	#":",-1(A2)
	BEQ.S	SavCon2
	SUBQ	#1,A2
	DBF	D0,SavBuc2
	RTS
SavCon2:
	MOVE.L	A2,A0
	LEA	FileNomFro2,A1
	MOVE.W	#50-1,D0
	BSR	CopyNom

	RTS

; -----------------------------------

BuscaExt:
	LEA	MiTiNom+8(PC),A1
	MOVEQ	#0,D0
MiTiBuc0:
	TST.B	(A0)+
	BEQ.S	MiTiCon0
	ADDQ.W	#1,D0
	BRA.S	MiTiBuc0
MiTiCon0:
	IFD	AMG_NAMECAP		; 1.3: a name of 65 characters or more wrote over MiraCartSize
	JSR	AmgBuscaFix		; (Amg10.asm); the same 14 bytes as the three below
	NOP
	NOP
	NOP
	NOP
	ELSE
	MOVEQ	#0,D3
	MOVE.W	#1,BucPunto
	LEA	(A1,D0.W),A1
	ENDC
MiTiBuc1:
	ADDQ.W	#1,D3
	MOVE.B	-(A0),-(A1)
	CMP.B	#".",(A1)
	BEQ.S	MiTiPunto
	CMP.B	#$60,(A1)
	BCS.S	MiTiCon1
	SUB.B	#$20,(A1)
MiTiCon1:
	DBF	D0,MiTiBuc1
	MOVEQ	#-1,D0
	RTS
MiTiPunto:
	MOVE.L	(A1),D1
	MOVEQ	#0,D2
	CMP.L	#".SMS",D1		; Sega Master System
	BEQ.S	MiTiFin
	MOVEQ	#1,D2
	CMP.L	#".SGG",D1		; Sega Game Gear
	AND.L	#$FFFFFF00,D1
	MOVEQ	#0,D2
	CMP.L	#".MS"*256,D1		; Master System
	BEQ.S	MiTiFin
	MOVEQ	#1,D2
	CMP.L	#".GG"*256,D1		; Game Gear
	BEQ.S	MiTiFin
	DBF	D0,MiTiBuc1
	MOVEQ	#-1,D0
	RTS
MiTiFin:
	MOVE.W	D3,BucPunto
	MOVE.L	D2,D0
	RTS

	CNOP	0,4
MiTiNom:DS.B	8+64
	CNOP	0,4

; -----------------------------------

	IFD	AMG_ANYSIZE
; D0 = file size. Any size up to 4 MB: rounded up to 16K pages, then to a power of two of at least
; two pages, as the bank mask needs; the pages past the file are filled with mirrors after loading.
; A 512-byte copier header is size MOD 16K = 512. Out: D0 = pages, D1 = -1 (or 0 = refused).
MiraCartSize:
	SF	RawCartSize
	MOVE.L	D0,D1
	AND.L	#$3FFF,D1
	CMP.L	#$200,D1
	BNE.S	AmgSizeHead
	CMP.L	#$4000,D0
	BLS.S	AmgSizeHead
	SUB.L	#$200,D0
	ST	RawCartSize
AmgSizeHead:
	TST.L	D0
	BEQ.S	AmgSizeBad
	CMP.L	#$400000,D0
	BHI.S	AmgSizeBad
	ADD.L	#$3FFF,D0
	MOVEQ	#14,D1
	LSR.L	D1,D0
	MOVE.W	D0,AmgRealPages
	MOVEQ	#2,D1
AmgSizePow:
	CMP.W	D0,D1
	BCC.S	AmgSizeOk
	ADD.W	D1,D1
	BRA.S	AmgSizePow
AmgSizeOk:
	MOVE.L	D1,D0
	MOVEQ	#-1,D1
	RTS
AmgSizeBad:
	MOVEQ	#0,D1
	RTS
	ELSE
MiraCartSize:
	SF	RawCartSize
	BFTST	D0{17:15}		; mira mínimo 32Kb
	BEQ.S	SiOkCartCon
	SUB.L	#$200,D0
	ST	RawCartSize
	BFTST	D0{17:15}		; mira mínimo 32Kb
	BNE.S	NoOkCartCon
SiOkCartCon:
	LSR.L	#8,D0
	LSR.L	#6,D0
;;	CMP.L	#$20,D0			; mira máximo 2Mb
;;	BGT.S	NoOkCartCon
	MOVEQ	#-1,D1
	RTS
NoOkCartCon:
	MOVEQ	#0,D1
	RTS
	ENDC

ReqCancel:
	BSR	EnaMouse
	RTS

ErNoStc:
	BSR	CloseFile
	LEA	tErNoStc,A0
	BRA	ImpError
OpenError:
	LEA	tErOpenFile,A0
	BRA	ImpError
ReadError:
	BSR	CloseFile
	LEA	tErReadFile,A0
	BRA	ImpError
NoGBCart:
	BSR	CloseFile
	LEA	tErNoGBCart,A0
	BRA	ImpError
OutOfMem:
	CLR.L	BucCart
	BSR	CloseFile
	LEA	tErOutOfMem,A0
	BRA	ImpError


	CNOP	0,8
xpkTags0:
	DC.L	$80005851,FileNom	; Nombre del Fichero a abrir.
	DC.L	0

xpkTags1:
	DC.L	$80005851,FileNom	; Nombre del Fichero a abrir.
	DC.L	$80005862,0
	DC.L	$80005871,0
	DC.L	0

;	DC.L	$80005851,Nombre del Fichero a abrir.
;	DC.L	$80005852,FileHandle (retorno del dosOpen) lectura.
;	DC.L	$80005853,Bloque de memoría donde leer.
;	DC.L	$80005860,Nombre del Fichero a crear/reescribir.
;	DC.L	$80005861,FileHandle (retorno del dosOpen) escritura.
;	DC.L	$80005862,Bloque de memoría donde escribir.
;	DC.L	$80005870,Size del bufer donde leer.
;	DC.L	$80005871,Size del bufer donde escribir.
;	DC.L	$80005877,=1 Soportar leer ficheros no xpkeados!

; ------------------------------------------

	CNOP	0,8
TipoROM:
	DC.L	tTipoROM0
	DC.L	tTipoROM1
	DC.L	tTipoROM2
	DC.L	tTipoROM3
	DC.L	tTipoROM4
	DC.L	tTipoROM5
	DC.L	tTipoROM6
	DC.L	tTipoROM7

tTipoROM:	DC.B	"-----",0
tTipoROM0:	DC.B	" 32Kb",0
tTipoROM1:	DC.B	" 64Kb",0
tTipoROM2:	DC.B	"128Kb",0
tTipoROM3:	DC.B	"256Kb",0
tTipoROM4:	DC.B	"512Kb",0
tTipoROM5:	DC.B	"1.0Mb",0
tTipoROM6:	DC.B	"2.0Mb",0
tTipoROM7:	DC.B	"4.0Mb",0

tTipoRAM0:	DC.B	"-------",0,0
tTipoRAM1:	DC.B	"Loaded!",0,0
tTipoRAM2:	DC.B	" Saved ",0,0
tTipoRAM3:	DC.B	"Changed",0,0
tTipoRAM4:	DC.B	"Cleared",0,0

tNomCart:	DC.B	"----------------",0
tManufNoID:	DC.B	"---------------",0
tNomFileCart:	DC.B    'No Cartridge Inserted!           ',0,0,0

	CNOP	0,4

; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,8
LoadFrozen:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	TST.L	BucCart(PC)		; ¿Hay cartucho?
	BNE.S	LoadFrozenRut
	RTS
LoadFrozenRut:

	BSR	DisMouse

	MOVE.L	FroReqBase,A0
	LEA	FroLoadTags,A1
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	BNE.S	LoadFrozenRut1

	BSR	EnaMouse
	RTS

LoadFrozenRut1:

	MOVE.L	FroReqBase,A2
	BSR	ArreglaNom

	MOVE.L	FroReqBase,A2
	MOVE.L	4(A2),A0
	LEA	FileNomFro2,A1
	MOVE.W	#$100-1,D0
	BSR	CopyNom

; -=-=-

	MOVE.L	#$00010001,D1
	MOVE.L	#SizeFrozen,D0		; Memoria a Requerir.
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; Requiere memoria.
	MOVE.L	D0,DirFrozen
	LEA	tErOutOfMem,A0
	BEQ	ImpError		; Error: Out of mem.


	MOVE.L	#FileNom,D1
	MOVE.L	#$3ED,D2
	BSR	OpenFile
	IFD	AMG_FROZERR
	BEQ	AmgLFznOpenErr
	ELSE
	BEQ	OpenLFrozError
	ENDC

;;	MOVE.L	BucFrozen,D3
	MOVE.L	#SizeFrozen,D3
	MOVE.L	DirFrozen,D2
	BSR	ReadFile
	IFD	AMG_FROZERR
	TST.L	D0
	BMI	AmgLFznReadErr
	ELSE
	NOP			; was BEQ.S NoLFrozError (the next instruction)
	ENDC

;;	error cargando.
NoLFrozError:
	BSR	CloseFile
OpenLFrozError:

; -=-=-

	LEA	Regs,A3
	MOVE.L	DirFrozen,A1

	CMP.L	#"AmiM",(A1)+	; ID
	BNE	NoEsfzn
	CMP.L	#"Gfzn",(A1)+	; ID
	BNE	NoEsfzn

	ADD.W	#16-8,A1
LFznBuc:

	LEA	IRAM,A2
	MOVE.W	#($2000/4)-1,D0
	CMP.L	#"IRAM",(A1)
	BEQ	FznCopyMem

	LEA	SRAM,A2
	MOVE.W	#($4000/4)-1,D0
	CMP.L	#"SRAM",(A1)
	BEQ	FznCopyMem
	IFD	AMG_SRAM2
	LEA	SRAM+$4000,A2
	CMP.L	#"SRM2",(A1)
	BEQ	FznCopyMem
	ENDC

	LEA	VRAM,A2
	MOVE.W	#($4000/4)-1,D0
	CMP.L	#"VRAM",(A1)
	BEQ	FznCopyMem

	CMP.L	#"Regs",(A1)
	BEQ	FznRegs

	CMP.L	#"Outs",(A1)
	BEQ	FznOuts

	LEA	VDPRegs,A2
	MOVE.W	#($40/4)-1,D0
	CMP.L	#"VDP ",(A1)
	BEQ	FznCopyMem

	LEA	VPAL,A2
	MOVE.W	#(64/4)-1,D0
	CMP.L	#"PAL ",(A1)
	BEQ	FznCopyMem

	LEA	PSG_Tab,A2
	MOVE.W	#(16/4)-1,D0
	CMP.L	#"PSG ",(A1)
	BEQ	FznCopyMem

	CMP.L	#"FIN!",(A1)
	BEQ.S	FznFin

FznSkip:
	ADDQ	#6,A1
	MOVEQ	#0,D1
	MOVE.W	(A1)+,D1
	ADD.L	D1,A1
	BRA	LFznBuc

; -=-=-


NoEsfzn:
	LEA	tErNoFrozen(PC),A0
	BSR	ImpError
	BRA.S	FznSalir

	IFD	AMG_FROZERR
AmgLFznReadErr:
	BSR	CloseFile
AmgLFznOpenErr:
	LEA	tAmgFznLoad(PC),A0
	BSR	ImpError
	BRA.S	FznSalir
	ENDC

FznFin:

; -=-=-
	LEA	MainMenuGadgets+(GD_Continue*4),A0
	MOVE.L	MainMenuWnd,A1
	MOVEQ	#0,D0
	BSR	GadsOnOff
; -=-=-
FznSalir:
	MOVE.L	#SizeFrozen,D0	; Libera memoria de Frozen.
	MOVE.L	DirFrozen(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.

	BSR	EnaMouse

	RTS

; ------------------------------------------

FznCopyMem:
	LEA	8(A1),A0
FznCopyMemBuc:
	MOVE.L	(A0)+,(A2)+
	DBF	D0,FznCopyMemBuc
	BRA	FznSkip

FznOuts:
	LEA	8(A1),A0

	MOVE.L	#VPAL,Debug+$28		; A2
	MOVE.L	#OUTBEb,Outs+($BE*4)
	MOVE.L	#INBEb,Ins+($BE*4)

	TST.B	(A0)+
	BNE.S	FznCon0

	MOVEQ	#0,D1
	MOVE.W	DirVRAM(A3),D1
	ADD.L	#VRAM,D1
	MOVE.L	D1,Debug+$28		; A2
	MOVE.L	#OUTBEa,Outs+($BE*4)
	MOVE.L	#INBE,Ins+($BE*4)
FznCon0:
	BRA	FznSkip

FznRegs:
	LEA	8(A1),A0

	MOVE.B	(A0)+,Debug+$1F		; A
	MOVE.B	(A0)+,Debug+$0F		; F
	MOVE.W	(A0)+,Debug+$12		; HL
	MOVE.W	(A0)+,Debug+$16		; BC
	MOVE.W	(A0)+,Debug+$1A		; DE
	MOVE.W	(A0)+,Debug+$22		; IX
	MOVE.W	(A0)+,Debug+$26		; IY
	MOVE.W	(A0)+,Debug+$02		; SP
	MOVE.W	(A0)+,PCReg		; PC
	MOVE.B	(A0)+,Debug+$1D		; A'
	MOVE.B	(A0)+,Debug+$0D		; F'
	ADDQ.W	#2,A0

	MOVE.L	A1,-(SP)

	MOVE.L	MapROMBase(A3),-(SP)
	MOVE.W	(A3),-(SP)		; Parche de ANA e IFF

	MOVE.L	A3,A1
	MOVE.W	#($10)-1,D0
	BSR	CopiaMem

	LEA	$70(A3),A1
	MOVE.W	#($0C)-1,D0
	BSR	CopiaMem

	LEA	$480(A3),A1
	MOVE.W	#($20)-1,D0
	BSR	CopiaMem

	LEA	Flags_DAA(A3),A4
	MOVE.W	#($100)-1,D0
BucFlagDaa2:
	MOVE.B	(A0),(A4)+		; Flags DAA
	ADDQ	#4,A0
	DBF	D0,BucFlagDaa2

	MOVE.W	(A3),ANA(A3)		; Parche de ANA e IFF
	MOVE.W	(SP)+,(A3)		; Parche de ANA e IFF
	MOVE.L	(SP)+,MapROMBase(A3)

; -=-=-
	MOVEQ	#0,D1
	MOVE.W	#$1F,D0
	TST.B	Consola(A3)		; (¿GameGear o MasterSystem?)
	BEQ.S	EsMasSys
	MOVEQ	#1,D1
	MOVE.W	#$3F,D0
EsMasSys:
	MOVE.W	D0,MaskVPAL(A3)
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_EmuType,D2
	MOVE.L	#$8008000F,D0
	BSR	UpdateTag
; -=-=-

	MOVE.L	(SP)+,A1

	BRA	FznSkip

; ------------------------------------------

	IFD	AMG_SRAM2
SizeFrozen=$A400+$4400			; room for the SRM2 chunk
	ELSE
SizeFrozen=$A400
	ENDC

	CNOP	0,8
SaveFrozen:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	TST.L	BucCart(PC)		; ¿Hay cartucho insertado?
	BNE.S	SaveFrozenRut
	RTS
SaveFrozenRut:

	LEA	tErNoCheats(PC),A0
	TST.B	DisCheaDat(PC)		; ¿Modo Cheat activo?
	BNE	ImpError


	BSR	DisMouse

	MOVE.L	FroReqBase,A0
	LEA	FroSaveTags,A1
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	BNE.S	SaveFrozenRut1

	BSR	EnaMouse
	RTS

SaveFrozenRut1:

	MOVE.L	FroReqBase,A2
	BSR	ArreglaNom

	MOVE.L	FroReqBase,A2
	MOVE.L	4(A2),A0
	LEA	FileNomFro2,A1
	MOVE.W	#$100-1,D0
	BSR	CopyNom

; -=-=-

	MOVE.L	#$00010001,D1
	MOVE.L	#SizeFrozen,D0		; Memoria a Requerir.
	MOVE.L	4.W,A6
	JSR	-$C6(A6)		; Requiere memoria.
	MOVE.L	D0,DirFrozen
	LEA	tErOutOfMem,A0
	BEQ	ImpError		; Error: Out of mem.


	LEA	Regs,A3
	MOVE.L	DirFrozen,A1

	MOVE.L	#"AmiM",(A1)+		; ID
	MOVE.L	#"Gfzn",(A1)+		; ID
	MOVE.W	#0,(A1)+		; ???
	MOVE.W	#0,(A1)+		; Version.
	CLR.L	(A1)+			; Size Frozen file

	LEA	8(A1),A2
; 	--------------------------------------------------
	MOVE.L	#"IRAM",(A1)+
	CLR.L	(A1)+
	LEA	IRAM,A0			; Copia RAM interna.
	MOVE.W	#($2000/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"SRAM",(A1)+
	CLR.L	(A1)+
	LEA	SRAM,A0			; Copia Battery-RAM.
	MOVE.W	#($4000/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
	IFD	AMG_SRAM2
	MOVE.L	#"SRM2",(A1)+
	CLR.L	(A1)+
	LEA	SRAM+$4000,A0		; cartridge RAM bank 1
	MOVE.W	#($4000/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
	ENDC
; 	--------------------------------------------------
	MOVE.L	#"VRAM",(A1)+
	CLR.L	(A1)+
	LEA	VRAM,A0			; Copia VRAM.
	MOVE.W	#($4000/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"Regs",(A1)+
	CLR.L	(A1)+
	MOVE.B	Debug+$1F,(A1)+		; A
	MOVE.B	Debug+$0F,(A1)+		; F
	MOVE.W	Debug+$12,(A1)+		; HL
	MOVE.W	Debug+$16,(A1)+		; BC
	MOVE.W	Debug+$1A,(A1)+		; DE
	MOVE.W	Debug+$22,(A1)+		; IX
	MOVE.W	Debug+$26,(A1)+		; IY
	MOVE.W	Debug+$02,(A1)+		; SP
	MOVE.W	PCReg,(A1)+		; PC
	MOVE.B	Debug+$1D,(A1)+		; A'
	MOVE.B	Debug+$0D,(A1)+		; F'
	CLR.W	(A1)+

	MOVE.W	(A3),-(SP)		; Parche de ANA e IFF
	MOVE.W	ANA(A3),(A3)		; Parche de ANA e IFF
	MOVE.L	A3,A0
	MOVE.W	#($10)-1,D0
	BSR	CopiaMem
	MOVE.W	(SP)+,(A3)		; Parche de ANA e IFF

	LEA	$70(A3),A0
	MOVE.W	#($0C)-1,D0
	BSR	CopiaMem

	LEA	$480(A3),A0
	MOVE.W	#($20)-1,D0
	BSR	CopiaMem

	LEA	Flags_DAA(A3),A4
	MOVE.W	#($100)-1,D0
BucFlagDaa:
	MOVE.B	(A4),(A1)+		; Flags DAA
	ADDQ	#4,A4
	DBF	D0,BucFlagDaa
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"Outs",(A1)+
	CLR.L	(A1)+

	CMP.L	#OUTBEa,Outs+($BE*4)
	SNE	(A1)+
	CLR.B	(A1)+
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"VDP ",(A1)+
	CLR.L	(A1)+
	LEA	VDPRegs,A0
	MOVE.W	#($40/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"PAL ",(A1)+
	CLR.L	(A1)+
	LEA	VPAL,A0
	MOVE.W	#(64/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"PSG ",(A1)+
	CLR.L	(A1)+
	LEA	PSG_Tab,A0
	MOVE.W	#(16/4)-1,D0
	BSR	CopiaMem4
	BSR	CanviChunk
; 	--------------------------------------------------
	MOVE.L	#"FIN!",(A1)+

	MOVE.L	DirFrozen,A0
	SUB.L	A0,A1
	MOVE.L	A1,BucFrozen
	MOVE.L	A1,$C(A0)


	MOVE.L	#FileNom,D1
	MOVE.L	#$3EE,D2
	BSR	OpenFile
	IFD	AMG_FROZERR
	BEQ	AmgSFznOpenErr
	ELSE
	BEQ	OpenSFrozError
	ENDC

	MOVE.L	BucFrozen,D3
	MOVE.L	DirFrozen,D2
	BSR	WriteFile
	IFD	AMG_FROZERR
	BNE.S	AmgSFznWriteErr
	ELSE
	NOP			; was BEQ.S NoSFrozError (the next instruction)
	ENDC

;;	error salvando.

NoSFrozError:
	BSR	CloseFile
	IFD	AMG_FROZERR
	BRA.S	OpenSFrozError
AmgSFznWriteErr:
	BSR	CloseFile
AmgSFznOpenErr:
	LEA	tAmgFznSave(PC),A0
	BSR	ImpError
	ENDC
OpenSFrozError:


	MOVE.L	#SizeFrozen,D0	; Libera memoria de Frozen.
	MOVE.L	DirFrozen(PC),A1
	MOVE.L	$4.W,A6
	JSR	-$D2(A6)		; Libera memoria.

	BSR	EnaMouse

	RTS

; ------------------------------------------

CanviChunk:
	MOVE.L	A1,A4
	SUB.L	A2,A4
	MOVE.W	A4,-2(A2)
	LEA	8(A1),A2
	RTS

; ------------------------------------------
	
CopiaMem:
	MOVE.B	(A0)+,(A1)+
	DBF	D0,CopiaMem
	RTS

CopiaMem4:
	MOVE.L	(A0)+,(A1)+
	DBF	D0,CopiaMem4
	RTS

; ------------------------------------------
; ****************************************** Batt
; ------------------------------------------

ReadBatt:
	TST.L	BucCart(PC)
	BNE.S	ReadBattRut
	RTS
ReadBattRut:
	MOVE.L	#FileNomSav,D1
	MOVE.L	#$3ED,D2
	BSR	OpenFile
	BEQ	OpenBattError

	MOVE.L	#SRAM,D2
	MOVE.L	#(16*1024),D3
	BSR	ReadFile
	BNE	ReadBattError
	IFD	AMG_SRAM2
	MOVE.L	#SRAM+$4000,D2		; bank 1, if the file has it
	MOVE.L	#(16*1024),D3
	BSR	ReadFile
	ENDC

	BSR	CalChecksum
	MOVE.L	D2,CheckId		; Guarda Check-Sum.

	LEA	MainMenuText11,A1
	MOVE.W	#$0506,(A1)
	MOVE.L	#tTipoRAM1,$0C(A1)		; 'RAM:' Loaded!
	MOVE.L	MainMenuWnd,A0
	BSR	TxtPrint

OpenBattError:
ReadBattError:
	BSR	CloseFile
	RTS

; ------------------------------------------

SaveBatt:
	TST.L	BucCart(PC)		; ¿Hay cartucho insertado?
	BNE.S	SaveBattRut
	RTS
SaveBattRut:
	MOVE.L	CheckId,D7		; ¿Ha cambiado el Checksum?
	BSR	CalChecksum
	MOVE.L	D2,CheckId		; Guarda Check-Sum.
	CMP.L	D2,D7
	BNE.S	SaveBattRut0
	RTS
SaveBattRut0:
	MOVE.L	#FileNomSav,D1
	MOVE.L	#$3EE,D2
	BSR	OpenFile
	BEQ	OpenBattError

	MOVE.L	#SRAM,D2
	MOVE.L	#(16*1024),D3
	BSR	WriteFile
	BNE	ReadBattError
	IFD	AMG_SRAM2
	LEA	SRAM+$4000,A0
	MOVE.W	#($4000/4)-1,D0
AmgSaveB1Buc:
	TST.L	(A0)+
	BNE.S	AmgSaveB1
	DBF	D0,AmgSaveB1Buc
	BRA.S	AmgSaveB1No
AmgSaveB1:
	MOVE.L	#SRAM+$4000,D2
	MOVE.L	#(16*1024),D3
	BSR	WriteFile
	BNE	ReadBattError
AmgSaveB1No:
	ENDC

	BSR	CloseFile

	LEA	MainMenuText11,A1
	MOVE.W	#$0105,(A1)
	MOVE.L	#tTipoRAM2,$0C(A1)		; 'RAM:' Saved
	MOVE.L	MainMenuWnd,A0
	BSR	TxtPrint

	RTS

; ------------------------------------------

ClearBatt:
	TST.L	BucCart(PC)		; ¿Hay cartucho insertado?
	BEQ.S	NoClearBatt

	BSR	AskSureClear
	BNE.S	NoClearBatt

	LEA	SRAM,A0
	IFD	AMG_SRAM2
	MOVE.W	#($8000/8)-1,D0
	ELSE
	MOVE.W	#($4000/8)-1,D0
	ENDC
ClrBatBuc:
	CLR.L	(A0)+
	CLR.L	(A0)+
	DBF	D0,ClrBatBuc

	BSR	CalChecksum
	MOVE.L	D2,CheckId		; Guarda Check-Sum.

	LEA	MainMenuText11,A1
	MOVE.W	#$0100,(A1)
	MOVE.L	#tTipoRAM4,$0C(A1)		; 'RAM:' Cleared
	MOVE.L	MainMenuWnd,A0
	BSR	TxtPrint

NoClearBatt:
	RTS

; ------------------------------------------

CalChecksum:				; Resultado: Check-Sum en D2
	LEA	SRAM,A0
	IFD	AMG_SRAM2
	MOVE.W	#($8000/2)-1,D0
	ELSE
	MOVE.W	#($4000/2)-1,D0
	ENDC
	MOVEQ	#0,D1
	MOVEQ	#0,D2
CaChCaBuc:
	MOVE.W	(A0)+,D1
	ADD.L	D1,D2
	DBF	D0,CaChCaBuc
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

JoyPort:
	LEA	DirPrefs(PC),A5
	MOVE.B	$08(A5),D0	; JoyType
	MOVE.B	([MainMenuGadgets+(GD_JoyType*4)],$57.w),D1	; JoyType
	TST.B	([MainMenuGadgets+(GD_JoyPort*4)],$5B.w)	; JoyPort
	BNE.S	JoyPortCon
	BFINS	D1,D0{26:2}
	MOVE.B	D0,$08(A5)	; JoyType
	BRA.S	JoyPortCon2
JoyPortCon:
	BFINS	D1,D0{30:2}
	MOVE.B	D0,$08(A5)	; JoyType
	LSR.B	#4,D0
JoyPortCon2:
; ---
	MOVE.B	D0,D1
	AND.L	#$00000003,D1
	LEA	MainMenuPunts,A0
	MOVE.W	#GD_JoyType,D2
	MOVE.L	#$8008000F,D0
	BSR	UpdateTag
; ---
	IFD	AMG_SRAM2
	BRA	ImpJoyType		; .S is illegal when the CNOP below pads nothing
	ELSE
	BRA.S	ImpJoyType
	ENDC

; ------------------------------------------

	CNOP	0,8
ImpJoyType:
	MOVE.B	([MainMenuGadgets+(GD_JoyType*4)],$57.w),D0	; JoyType
	AND.W	#$0003,D0
	MOVE.L	(TabGfxJoyType.w,PC,D0.w*4),DirJoyTypePic

	MOVE.L	#552,D0
	MOVE.L	#143,D1
	move.l  Scr,a0
	move.l  40(a0),a1
	ADD.w  4(a1),D1
	MOVE.L	MainMenuWnd,A0
	MOVE.L	50(A0),A0
	LEA	DatsJoyTypePic,A1
	MOVE.L	_IntuitionBase,A6
	JMP	-114(A6)
	CNOP	0,4
TabGfxJoyType:
	DC.L	GBJoyStick
	DC.L	GBTeclado
	DC.L	GBCD32
	DC.L	GBJoypad

; ------------------------------------------
; ******************************************
; ------------------------------------------

NoChange:
	MOVEQ	#$01,D3
	MOVE.B	D3,DirPrefs+$18
	BRA.S	SetScrExit
ForcePAL:
	MOVEQ	#$02,D3
	MOVE.B	D3,DirPrefs+$18
	BRA.S	SetScrExit
ForceNTSC:
	MOVEQ	#$04,D3
	MOVE.B	D3,DirPrefs+$18
SetScrExit:
	MOVE.L	#(0*$40)+15,D0		; Nº Línea. (Sub-Item+Item)
	MOVEQ	#2,D1			; Nº menu.
	MOVEQ	#3-1,D4

	BRA.S	PoneOptMenus
	
; -----------------------------------

European:
	MOVEQ	#$01,D3
	MOVE.B	D3,DirPrefs+$19
	BRA.S	SetCountry
Japanese:
	MOVEQ	#$02,D3
	MOVE.B	D3,DirPrefs+$19
SetCountry:
	MOVE.L	#(0*$40)+14,D0		; Nº Línea. (Sub-Item+Item)
	MOVEQ	#2,D1			; Nº menu.
	MOVEQ	#3-1,D4

	NOP			; was BRA.S PoneOptMenus (the next instruction)

; -----------------------------------

PoneOptMenus:
;;	MOVEQ	#$40,D3			; D3 = Bits a 0 = OFF, bit a 1 = ON
;;	MOVE.L	#(0*$40)+1,D0		; D0 = Nº Línea. (Sub-Item+Item)
;;	MOVEQ	#3,D1			; D1 = Nº menu.
;;	MOVEQ	#7-1,D4			; D4 = Nº de Líneas en Menú
PoOpMeBuc:
	MOVEM.L	D0-D4,-(SP)
	BSR	CogeCheck
	MOVEM.L	(SP)+,D0-D4

	BCLR	#0,$C(A0)
	LSR.B	#1,D3
	BCC.S	PoOpMeCon
	BSET	#0,$C(A0)
PoOpMeCon:
	ADD.W	#(1*$40),D0
	DBF	D4,PoOpMeBuc
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

ActuPrefs:
	LEA	DirPrefs(PC),A5

	MOVE.B	$08(A5),D0	; JoyType
	MOVE.B	([MainMenuGadgets+(GD_JoyType*4)],$57.w),D1	; JoyType
	TST.B	([MainMenuGadgets+(GD_JoyPort*4)],$5B.w)	; JoyPort
	BNE.S	JoyPort2
	BFINS	D1,D0{30:2}
	BRA.S	JoyPort1
JoyPort2:
	BFINS	D1,D0{26:2}
JoyPort1:
	MOVE.B	D0,$08(A5)	; JoyType


	LEA	MainMenuPunts,A0

	MOVE.W	#GD_EmuType,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$16(A5)	; Tipo Consola

	MOVE.W	#GD_ScrMode,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$0F(A5)	; Screen

	MOVE.W	#GD_GfxRefresh,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$10(A5)	; GfxFrames

	MOVE.W	#GD_SprRefresh,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$11(A5)	; SprFrames

	MOVE.W	#GD_CPUspd,D1
	MOVEQ	#0,D0
	BSR	GetGadgetValue
	MOVE.B	D0,$13(A5)	; CPU Speed


	MOVE.L	InsReqBase(PC),A0
	MOVE.L	8(A0),A0
	LEA	$20(A5),A1
	MOVE.W	#($100/8)-1,D0
ActPreBuc0:
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D0,ActPreBuc0

	MOVE.L	SavReqBase(PC),A0
	MOVE.L	8(A0),A0
	LEA	$300(A5),A1
	MOVE.W	#($100/8)-1,D0
ActPreBuc1:
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D0,ActPreBuc1

	MOVE.L	FroReqBase(PC),A0
	MOVE.L	8(A0),A0
	LEA	$200(A5),A1
	MOVE.W	#($100/8)-1,D0
ActPreBuc2:
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBF	D0,ActPreBuc2

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#0,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$15(A5)				; JoyStick 2

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#1,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$17(A5)				; Swap JoyPorts

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#3,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$09(A5)				; Black Border

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#4,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$14(A5)				; No illogical moves

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#6,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$0B(A5)				; Auto-Load Battery

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#7,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$0C(A5)				; Auto-Save Battery

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#8,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$0D(A5)				; Ask for Save Battery

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#10,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$12(A5)				; Show fps

	MOVEQ	#2,D1		; Nº menu.
	MOVE.L	#(0*$40)+12,D0	; Nº Línea. (Sub-Item+Item)
	BSR	CogeCheck
	SNE	$1C(A5)				; Sprites Priorities

	MOVEQ	#2,D1		; Nº menu.
	MOVE.L	#(1*$40)+12,D0	; Nº Línea. (Sub-Item+Item)
	BSR	CogeCheck
	SNE	$1D(A5)				; Background Priorities

	MOVEQ	#2,D1		; Nº menu.
	MOVE.L	#(2*$40)+12,D0	; Nº Línea. (Sub-Item+Item)
	BSR	CogeCheck
	SNE	$1E(A5)				; Realtime Scroll changes

	MOVEQ	#2,D1		; Nº menu.
	MOVE.L	#(3*$40)+12,D0	; Nº Línea. (Sub-Item+Item)
	BSR	CogeCheck
	SNE	$1F(A5)				; Realtime Scroll changes

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#18,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$0E(A5)				; Disable Cheats

	MOVEQ	#2,D1		; Nº menu.
	MOVEQ	#19,D0		; Nº Línea.
	BSR	CogeCheck
	SNE	$0A(A5)				; Ask for Reset


	MOVE.L	([MainMenuGadgets+(GD_Vlines*4)],$50.w),A0
	BSR	CalculPok
	MOVE.W	D0,DirPrefs+$128

	LEA	DirPrefs(PC),A5

	RTS

; -----------------------------------

CogeCheck:
	MOVE.L	MainMenuMenus,A0
	MOVE.L	_IntuitionBase(PC),A6
	LSL.W	#5,D0	
	OR.W	D1,D0
	JSR	-$90(A6)		; ItemAdress (A0,d0)
	MOVE.L	D0,A0
	BTST	#0,$C(A0)
	RTS

; -----------------------------------

PonPrefs:
	LEA	DirPrefs(PC),A5

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_JoyType,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$08(A5),D2
	AND.W	#$0003,D2
	BSR	OverrideTag

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_GfxRefresh,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$10(A5),D2
	BSR	OverrideTag

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_SprRefresh,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$11(A5),D2
	BSR	OverrideTag

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_ScrMode,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$0F(A5),D2
	BSR	OverrideTag

	LEA	MainMenuPunts,A0
	LEA	MainMenuGTags,A1
	MOVE.W	#GD_CPUspd,D0
	MOVE.L	#$8008000F,D1
	MOVEQ	#0,D2
	MOVE.B	$13(A5),D2
	BSR	OverrideTag

	MOVE.B	$15(A5),D0
	BFINS	D0,MainMenuNewMenu32+10{7:1}	; JoyStick 2

	MOVE.B	$17(A5),D0
	BFINS	D0,MainMenuNewMenu33+10{7:1}	; Swap JoyPorts.

	MOVE.B	$09(A5),D0
	BFINS	D0,MainMenuNewMenu35+10{7:1}	; Black Border.

	MOVE.B	$14(A5),D0
	BFINS	D0,MainMenuNewMenu36+10{7:1}	; No illogical moves.

	MOVE.B	$0B(A5),D0
	BFINS	D0,MainMenuNewMenu38+10{7:1}	; Auto-Load Battery

	MOVE.B	$0C(A5),D0
	BFINS	D0,MainMenuNewMenu39+10{7:1}	; Auto-Save Battery

	MOVE.B	$0D(A5),D0
	BFINS	D0,MainMenuNewMenu40+10{7:1}	; Ask for Save Battery

	MOVE.B	$12(A5),D0
	BFINS	D0,MainMenuNewMenu42+10{7:1}	; Show fps

	MOVE.B	$1C(A5),D0
	BFINS	D0,MainMenuNewMenu45+10{7:1}	; Sprites Priorities

	MOVE.B	$1D(A5),D0
	BFINS	D0,MainMenuNewMenu46+10{7:1}	; Background Priorities

	MOVE.B	$1E(A5),D0
	BFINS	D0,MainMenuNewMenu47+10{7:1}	; Realtime Scroll Refresh

	MOVE.B	$1F(A5),D0
	BFINS	D0,MainMenuNewMenu48+10{7:1}	; Realtime Palette Refresh
; -=-
	MOVE.B	$19(A5),D0
	BFINS	D0,MainMenuNewMenu56+10{7:1}	; European / USA
	LSR.B	#1,D0
	BFINS	D0,MainMenuNewMenu57+10{7:1}	; Japaneses
; -=-
	MOVE.B	$18(A5),D0
	BFINS	D0,MainMenuNewMenu59+10{7:1}	; Set Screen on Exit 'No Change'
	LSR.B	#1,D0
	BFINS	D0,MainMenuNewMenu60+10{7:1}	; Set Screen on Exit 'Force PAL'
	LSR.B	#1,D0
	BFINS	D0,MainMenuNewMenu61+10{7:1}	; Set Screen on Exit 'Force NTSC'
; -=-
	MOVE.B	$0E(A5),D0
	BFINS	D0,MainMenuNewMenu63+10{7:1}	; Disable Cheats

	MOVE.B	$0A(A5),D0
	BFINS	D0,MainMenuNewMenu64+10{7:1}	; Ask for Reset

	RTS

; -----------------------------------

LoadPrefs:
	MOVE.L	#NOMPREFS,D1
	MOVE.L	#1005,D2
	BSR	OpenFile
	BEQ.S	PREFSRET

	MOVE.L	#BufPrefs,D2
	MOVE.L	#BucPrefs,D3
	BSR	ReadFile
;	BNE	CloseFile

	BSR	CloseFile
	LEA	BufPrefs,A0
	CMP.L	#"AmiM",(A0)
	BNE.S	PREFSRET
	CMP.L	#"Gv05",4(A0)
	BEQ.S	PREFSOK
	CMP.L	#"Gv04",4(A0)
	BEQ.S	PREFSv04
PREFSRET:
	RTS

	CNOP	0,4
PREFSOK:
	MOVE.L	#"Gv05",4(A0)
	LEA	DirPrefs,A1
	MOVE.W	#BucPrefs-1,D0
COPIPREFS:
	MOVE.B	(A0)+,(A1)+
	DBF	D0,COPIPREFS
	IFD	AMG_OLDPREFS
	JSR	AmgOldPrefs		; prefs from 0.8 or 1.1: both priority options on (Amg10.asm)
	ENDC
	RTS

	CNOP	0,4
PREFSv04:
	MOVE.L	#"Gv05",4(A0)
	LEA	DirPrefs,A1
	MOVE.W	#$120-1,D0
COPIPREFSv04:
	MOVE.B	(A0)+,(A1)+
	DBF	D0,COPIPREFSv04
	IFD	AMG_OLDPREFS
	JSR	AmgOldPrefs		; prefs from 0.8 or 1.1: both priority options on (Amg10.asm)
	ENDC
	RTS

; ------------------------------------------

SavePrefs:
	BSR	ActuPrefs

	MOVE.L	#NOMPREFS,D1
	MOVE.L	#1006,D2
	BSR	OpenFile
	BEQ.S	ERDEVICE2

	MOVE.L	#DirPrefs,D2
	MOVE.L	#BucPrefs,D3
	BSR	WriteFile
	BNE.S	ERDEVICE2

	BSR	CloseFile
	RTS

	CNOP	0,4
ERDEVICE2:
	BSR	CloseFile
	LEA	tErSavePrefs(PC),A0
	BRA	ImpError
	RTS

	CNOP	0,8
NOMPREFS:
	DC.B	"S:AmiMasterGear.prefs",0,0,0,0

; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
	CNOP	0,8
DirPrefs:
	DC.B	"AmiMGv05"	; $00 - ID
	IFD	AMG_JOYDEF		; test: another JoyType byte by default (WinUAE pad runs)
	DC.B	AMG_JOYDEF
	ELSE
	IFD	AMG_PADDEF
	DC.B	$02		; $08 - JoyType (2/1): Port 2 starts on CD32 Joypad (v0.8: Keyboard Only)
	ELSE
	DC.B	$01		; $08 - JoyType (2/1)
	ENDC
	ENDC
	DC.B	$FF		; $09 - Black Border
	DC.B	$00		; $0A - Ask for Reset
	DC.B	$FF		; $0B - Auto-load Battery
	DC.B	$00		; $0C - Auto-save Battery
	DC.B	$FF		; $0D - Ask for Save Battery
	DC.B	$00		; $0E - Disable Cheats
	IFD	AMG_NTSC
	DC.B	$01		; $0F - Screen mode: NTSC (60Hz) by default; most games, and the Game Gear, are 60 Hz
	ELSE
	DC.B	$00		; $0F - Screen mode
	ENDC
	DC.B	$00		; $10 - GfxRefresh
	DC.B	$00		; $11 - SprRefresh
	DC.B	$00		; $12 - Show fps
	DC.B	$00		; $13 - Emulation Speed
	DC.B	$FF		; $14 - No illogical moves
	DC.B	$00		; $15 - JoyStick 2 ON
	DC.B	$00		; $16 - Tipo de Consola (0=MS , 1=GG)
	DC.B	$00		; $17 - Swap JoyPorts
	DC.B	1		; $18 - Screen on Exit.
	DC.B	1		; $19 - Country code.
	DC.B	2		; $1A - CPU Emulation

	DC.B	$00		; $1B - Modo AntiCrack 2.

	IFD	AMG_SPRPRI
	DC.B	$FF		; $1C - Sprites Priorities: on by default, as the console draws them (v0.8: off)
	ELSE
	DC.B	$00		; $1C - Sprites Priorities
	ENDC
	IFD	AMG_BGPRI
	DC.B	$FF		; $1D - Background Priorities: on by default, so tiles with the priority bit cover sprites (v0.8: off)
	ELSE
	DC.B	$00		; $1D - Background Priorities
	ENDC
	DC.B	$FF		; $1E - Realtime Scroll Refresh
	IFD	AMG_RASTERPAL
	DC.B	$FF		; $1F - Realtime Palette Refresh: on (palette changes per line, as GG Aleste II's title)
	ELSE
	DC.B	$00		; $1F - Realtime Palette Refresh
	ENDC

	DC.B	"Cartridges"	; $20
	DS.B	$100-10

	DC.L	1234		; $120 - Usuario Registrado Codificado #1.
	DC.L	5678		; $124 - Usuario Registrado Codificado #2.

	DC.W	$00		; $128 - VLines

	IFD	AMG_OLDPREFS
	DS.B	$1F8-$12A		; free
	DC.B	"AmiMGv12"	; $1F8 - saved by 1.2 or later (0.8 and 1.1 leave these bytes alone)
	DS.B	2
	ELSE
	DS.B	$200-$128	; $128=>$1FF	; Libres.
	ENDC

	DC.B	"Frozen"	; $200
	DS.B	$100-6

	DC.B	"Battery"	; $300
	DS.B	$100-7

	CNOP	0,4
	DC.B	" -=> AmiMasterGear preferences file <=- ",0
	CNOP	0,4
FinPrefs:
BucPrefs=FinPrefs-DirPrefs
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-
	DS.L	6
	CNOP	0,8
BufPrefs:
	DS.B	BucPrefs
	DS.L	6
; -=-=-=-==-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-


; ------------------------------------------
; ******************************************
; ------------------------------------------

	CNOP	0,4
EditPrefs:
	BSR	DisMouse
	MOVEM.L	MCeros,D0-D7/A0-A6
	BSR	OpenPrefsWindow

	MOVE.L	#DirPrefs+$200,D1
	LEA	PrefsPunts,A0
	MOVE.W	#GD_FrozenStr,D2
	MOVE.L	#$8008002D,D0
	BSR	UpdateTag

	MOVE.L	#DirPrefs+$300,D1
	LEA	PrefsPunts,A0
	MOVE.W	#GD_BatteryStr,D2
	MOVE.L	#$8008002D,D0
	BSR	UpdateTag

	MOVE.L	#DirPrefs+$20,D1
	LEA	PrefsPunts,A0
	MOVE.W	#GD_CartridgesStr,D2
	MOVE.L	#$8008002D,D0
	BSR	UpdateTag


	LEA	PrefsPunts,A1
	BSR	Control

	BSR	ClosePrefsWindow
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

SaveVRAM:
	MOVE.B	#3,SaveVRAMdat
	BRA.S	SaveSprCont
SaveRAM:
	MOVE.B	#2,SaveVRAMdat
	BRA.S	SaveSprCont
SaveSprites:
	MOVE.B	#1,SaveVRAMdat
	BRA.S	SaveSprCont
SaveScreen:
	SF	SaveVRAMdat
SaveSprCont:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	BSR	DisMouse

	MOVE.L	SavReqBase,A0
	LEA	IFFSaveTags,A1
	MOVEQ	#0,D0
	MOVE.B	SaveVRAMdat,D0
	MOVE.L	(IFFTabScr+4.W,PC,D0.W*8),4(A1)
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	BNE.S	SaveScreenRut

	BSR	EnaMouse
	RTS

SaveScreenRut:

	MOVE.L	SavReqBase,A2
	BSR	ArreglaNom


	MOVE.L	#FileNom,D1
	MOVE.L	#$3EE,D2
	BSR	OpenFile
	BEQ	OpenError


	MOVEQ	#0,D0
	MOVE.B	SaveVRAMdat,D0
	JSR	([IFFTabScr.W,PC,D0.W*8])


	BSR	CloseFile
	BSR	EnaMouse
	RTS


IFFTabScr:
	DC.L	GrabaScr,tScrSave
	DC.L	GrabaSpr,tSprSave
	DC.L	GrabaRAM,tRAMSave
	DC.L	GrabaVRAM,tVRAMSave

; -*-

GrabaSpr:
	LEA	Color0+(16*4)+2,A0	; RGB en el CopperList.
	LEA	IlCol4,A1
	MOVE.W	#(16)-1,D0
PALSBUC4:
	MOVE.B	(A0)+,D1
	LSL.B	#4,D1
	MOVE.B	D1,(A1)+
	MOVE.B	(A0),D1
	AND.B	#$F0,D1
	MOVE.B	D1,(A1)+
	MOVE.B	(A0)+,D1
	LSL.B	#4,D1
	MOVE.B	D1,(A1)+
	ADDQ.W	#2,A0
	DBF	D0,PALSBUC4


	MOVE.L	#(ILBMFin4-ILBM4),D3
	MOVE.L	#ILBM4,D2
	BSR	WriteFile

	MOVE.W	DirSprit0+2,D0
	SWAP	D0
	MOVE.W	DirSprit0+6,D0
	MOVE.L	D0,A0
	ADD.W	#16,A0
SPR5CON:
	MOVE.W	#(192/32)-1,D4
SPR5BUC:
	LEA	ILBMraw,A1
	MOVE.W	#(32)-1,D2
SPR5BUC1:
	MOVE.L	A0,A2
	MOVE.W	#(2)-1,D3
SPR5BUC0:
	MOVE.L	A2,A3
	REPT	4
	MOVE.L	(A3)+,(A1)+
	MOVE.L	(A3)+,(A1)+
	ADD.L	#OtrSpr-8,A3
	ENDR
	MOVE.L	A2,A3
	ADDQ	#8,A3
	REPT	4
	MOVE.L	(A3)+,(A1)+
	MOVE.L	(A3)+,(A1)+
	ADD.L	#OtrSpr-8,A3
	ENDR
	ADD.L	#NexSpr,A2
	DBF	D3,SPR5BUC0
	ADD.W	#(32/4)*2,A0
	DBF	D2,SPR5BUC1
	MOVEM.L	D0-D4/A0-A1,-(SP)
	MOVE.L	#ILBMraw,D2
	MOVE.L	#(4*1024),D3
	BSR	WriteFile
	MOVEM.L	(SP)+,D0-D4/A0-A1
	DBF	D4,SPR5BUC
	RTS

GrabaRAM:
	MOVE.L	#SRAM,D2		; $8000->$BFFF
	MOVE.L	#(16*1024),D3
	BSR	WriteFile
	MOVE.L	#IRAM,D2		; $C000->$FFFF
	MOVE.L	#(16*1024),D3
	BSR	WriteFile
	RTS

GrabaVRAM:
	MOVE.L	#VRAM,D2		; $0000->$3FFF
	MOVE.L	#(16*1024),D3
	BSR	WriteFile
	RTS

; -*-

GrabaScr:
	LEA	Color0+2,A0	; RGB en el CopperList.
	LEA	IlCol,A1
	MOVE.W	#(32)-1,D0
PALSBUC:
	MOVE.B	(A0)+,D1
	LSL.B	#4,D1
	MOVE.B	D1,(A1)+
	MOVE.B	(A0),D1
	AND.B	#$F0,D1
	MOVE.B	D1,(A1)+
	MOVE.B	(A0)+,D1
	LSL.B	#4,D1
	MOVE.B	D1,(A1)+
	ADDQ.W	#2,A0
	DBF	D0,PALSBUC

	MOVE.L	#(ILBMFin-ILBM),D3
	MOVE.L	#ILBM,D2
	BSR	WriteFile

	MOVE.L	#Plano5,D4
	MOVE.L	#PantGfx,D2
	MOVE.L	#(192)-1,D3
SavScrBuc:
	MOVE.W	D3,-(SP)
	MOVE.L	#(4)-1,D3
SavScrBuc0:
	MOVEM.L	D2-D4,-(SP)
	MOVE.L	#32,D3
	BSR	WriteFile
	MOVEM.L	(SP)+,D2-D4
	ADD.L	#64,D2
	DBF	D3,SavScrBuc0

	EXG.L	D2,D4

	MOVEM.L	D2-D4,-(SP)
	MOVE.L	#32,D3
	BSR	WriteFile
	MOVEM.L	(SP)+,D2-D4
	EXG.L	D2,D4
	ADD.L	#(64*4),D4

	MOVE.W	(SP)+,D3
	DBF	D3,SavScrBuc
	RTS


	CNOP	0,4
ILBM:
	DC.L	"FORM",$0000789C,"ILBM"
	DC.L	"BMHD",$00000014,$010000C0
	DC.L	$00000000,$05000000
	DC.L	$00002C2C,$01400100
	DC.L	"CMAP",$00000060
IlCol:	DS.B	32*3				; Colores.
	DC.L	"CAMG",$00000004,$00001000
	DC.L	"BODY",$00007800
ILBMFin:
	DC.L	0,0

	CNOP	0,4
ILBM4:
	DC.L	"FORM",$0000606C,"ILBM"
	DC.L	"BMHD",$00000014,$010000C0
	DC.L	$00000000,$04000000
	DC.L	$00002C2C,$01400100
	DC.L	"CMAP",$00000030
IlCol4:	DS.B	16*3				; Colores.
	DC.L	"CAMG",$00000004,$00001000
	DC.L	"BODY",$00006000
ILBMFin4:
	DC.L	0,0

	CNOP	0,8

; ------------------------------------------
; ******************************************
; ------------------------------------------

GetFrozen:
	TST.L	_AslBase(PC)
	BEQ	NeedASL

	BSR	DisMouse

	MOVE.L	FroReqBase,A0
	LEA	FroGetTags,A1
	MOVE.L	_AslBase,A6
	JSR	-$3C(A6)	; RequestFile.

	TST.L	D0
	NOP			; was BEQ.S GetFrozenFin (the next instruction)


;	MOVE.L	FroReqBase,A2
;
;	MOVE.L	4(A2),A0
;	LEA	FileNomFro2,A1
;	MOVE.W	#$100-1,D0
;	BSR	CopyNom

GetFrozenFin:
	BSR	EnaMouse
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

; ------------------------------------------
; ******************************************
; ------------------------------------------
; ------------------------------------------
; ------------------------------------------
; ------------------------------------------


; -----------------------------------
; -----------------------------------
	CNOP	0,4
SETPAL:
	MOVE.W	#$20,$DFF1DC
	RTS
; -----------------------------------
	CNOP	0,4
SETNTSC:
	MOVE.W	#0,$DFF1DC
	RTS
; -----------------------------------
	CNOP	0,4
MC68020:
	MOVE.L	$4.w,A0
	MOVE.B	$129(A0),D0
	SMI	EsUn060

	AND.B	#$8E,D0
	BNE.S	MC68020RET

NoAGA2:
	MOVEM.L	MCeros(PC),D0-D7/A0-A6
	JSR	OpenMC68020Window
	LEA	MC68020PUNTS,A1
	BSR	Control
	JSR	CloseMC68020Window
MC68020RET:
	MOVEQ	#-1,D0
	RTS
MC68020SALIR:
	ADD.W	#16+4,SP
	JSR	CloseMC68020Window
	MOVEQ	#0,D0
	RTS

; -----------------------------------
	CNOP	0,4
MiraAGA:
	LEA	$DFF000,A6
	MOVE.W	$7C(A6),D1
	MOVE.W	#30-1,D3
BucAGA2:
	MOVE.W	$7C(A6),D2
	CMP.B	D2,D1
	BNE	NoAGA2
	DBF	D3,BucAGA2
	ORI.B	#$F0,D1
	CMPI.B	#$F8,D1
	BNE	NoAGA2
	MOVEQ	#-1,D0
	RTS

; ------------------------------------------
; ******************************************
; ------------------------------------------

;	--------------------------
;	Refresca el Relog interno.
;	--------------------------

	CNOP	0,8
RefrescaReloj:
	LEA	battclockreso(PC),A1
	MOVE.L	$4.w,A6
	JSR	-$1F2(A6)		; Open Resource.
	MOVE.L	D0,A2
	MOVE.L	A2,D0
	BEQ.S	RefRelFin

	LEA	TimeBuffer(PC),A1
	LEA	timerdevice(PC),A0
	MOVEQ	#0,D0
	MOVE.L	D0,D1
	JSR	-$1BC(A6)		; Open Device.
	MOVE.L	D0,D6
	BNE.S	RefRelFin


	MOVEQ	#0,D7
	MOVEQ	#0,D0
	LEA	TimeBuffer(PC),A0
	MOVE.W	D0,$8(A0)
	SUB.L	A1,A1
	MOVE.L	A1,$A(A0)
	MOVE.L	A1,$E(A0)
	CLR.L	$24(A0)

	MOVE.L	A2,A6
	JSR	-$C(A6)
	LEA	TimeBuffer(PC),A0
	MOVE.L	D0,$20(A0)
	MOVE.W	#$B,$1C(A0)
	MOVE.L	A0,A1
	MOVE.L	$4.w,A6
	JSR	-$1C8(A6)		; DoIO.

	LEA	TimeBuffer(PC),A1
;	MOVE.L	$4.w,A6
	JSR	-$1C2(A6)		; Close Device.
RefRelFin:
	RTS

	CNOP	0,8
battclockreso:	DC.B	'battclock.resource',0,0
timerdevice:	DC.B	'timer.device',0,0

	CNOP	0,8
TimeBuffer:	DS.B	$30
	CNOP	0,4

; ------------------------------------------
; ******************************************
; ------------------------------------------

LongFile:
	MOVE.L	#FileNom,D1
	MOVEQ	#-2,D2
	MOVE.L	_DosBase,A6
	JSR	-$54(A6)		; Lock
	TST.L	D0
	BEQ.S	LONGFILER
	MOVE.L	D0,-(SP)

	MOVE.L	D0,D1
	move.L	#Examine,d2
	MOVE.L	_DosBase,A6
	JSR	-$66(A6)		; Examine

	MOVE.L	(SP)+,D1
	JSR	-$5A(A6)		; UnLock

	MOVE.L	Examine+$7C,D0
LONGFILER:
	RTS

; -----------------------------------

OpenFile:
	MOVE.L	_DosBase,A6
	JSR	-30(A6)			; OPEN
	MOVE.L	D0,DisBase
	RTS
CloseFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	BEQ.S	NoCloseFile
	JSR	-36(A6)			; CLOSE
	CLR.L	DisBase
NoCloseFile:
	RTS
WriteFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	MOVE.L	D3,-(SP)
	JSR	-48(A6)			; WRITE
	MOVE.L	(SP)+,D3
	CMP.L	D0,D3
	RTS
ReadFile:
	MOVE.L	_DosBase,A6
	MOVE.L	DisBase,D1
	MOVE.L	D3,-(SP)
	JSR	-42(A6)			; READ
	MOVE.L	(SP)+,D3
	CMP.L	D0,D3
	RTS

; -----------------------------------
	CNOP	0,4
PONOM:
	MOVE.L	A1,A2
NTXTYA0:
	TST.B	(A2)
	BEQ.S	COPYNOM2
	MOVE.B	#" ",(A2)+
	BRA.S	NTXTYA0
	CNOP	0,4
COPYNOM2:
	MOVE.B	(A0)+,D0
	BEQ.S	PONOMS
	TST.B	(A1)
	BEQ.S	PONOMS
	MOVE.B	D0,(A1)+
	BRA.S	COPYNOM2
PONOMS:	RTS
; -----------------------------------
	CNOP	0,4
CopyNom:
	MOVE.B	(A0)+,(A1)+
	DBEQ	D0,CopyNom
	RTS
; -----------------------------------
	CNOP	0,4
ArreglaNom:
	LEA	FileNom(PC),A1
	MOVE.W	#$100-1,D0
	MOVE.L	8(A2),A0
	TST.B	(A0)
	BEQ.S	ArrglNom
	BSR	CopyNom
	SUBQ	#1,A1
	CMP.B	#":",-1(A1)
	BEQ.S	ArrglNom
	MOVE.B	#"/",(A1)+
ArrglNom:
	MOVE.W	#$100-1,D0
	MOVE.L	4(A2),A0
	BSR	CopyNom
	RTS
; -----------------------------------



; -----------------------------------
;	Pasa Decimal  &  Pasa Hexa v1.0
;	(PD)  Juan Antonio Gomez Galvez
;	(Codigo texto para DEVPAC II),(3-X-92)

;	- D0=Numero que se va a pasar a decimal.
;	- Resultado: D0 y A0 tienen el puntero del buffer
;	  de los numeros en ASCII en decimal.  (10 bytes)

PASDEC:
	LEA	DSUMA(PC),A0
	CLR.L	(A0)+
	CLR.L	(A0)+
	CLR.W	(A0)+

	MOVE.W	#$08-1,D1
	LEA	DATOSSUMA(PC),A0
SUMBUC01:
	MOVEM.L	D0-D1/A0,-(SP)
	AND.L	#$000F,D0
	TST.B	D0
	BEQ	SUMCON00
SUMBUC02:
	MOVEM.L	D0/A0,-(SP)
	LEA	DSUMA(PC),A1
	BSR	SUMDEC
	MOVEM.L	(SP)+,D0/A0
	SUBQ.B	#$01,D0
	BNE.S	SUMBUC02
SUMCON00:
	MOVEM.L	(SP)+,D0-D1/A0
	LSR.L	#$04,D0
	ADD.L	#$0A,A0
	DBF	D1,SUMBUC01

	LEA	DSUMA(PC),A0
	ADD.L	#$30303030,(A0)+
	ADD.L	#$30303030,(A0)+
	ADD.W	#$3030,(A0)+

	LEA	DSUMA(PC),A0
SUMBUC03:
	TST.B	(A0)
	BEQ	SUMCON01
	MOVE.B	(A0),D0
	CMP.B	#$30,D0
	BNE.S	FINRET
	MOVE.B	#$20,(A0)+
	BRA	SUMBUC03
SUMCON01:
	MOVE.B	#"0",-(A0)
	BRA.S	FINRET
SUMDEC:
	MOVEQ.L	#$0A-1,D1
	ADD.L	#$0A,A0
	ADD.L	#$0A,A1
SUMBUC00:
	MOVE.B	-(A0),D3
	ADD.B	D3,-(A1)
	MOVE.B	(A1),D0
	SUB.B	#$0A,D0
	BCS.S	SUMBIEN00
	MOVE.B	D0,(A1)
	ADD.B	#$01,-1(A1)
	DBF	D1,SUMBUC00
	RTS
SUMBIEN00:
	CLR.L	D0
	DBF	D1,SUMBUC00
	RTS
FINRET:
	LEA	DSUMA(PC),A0
	MOVE.L	A0,D0
	RTS


;	- A0 el puntero del buffer de los
;	  numeros en ASCII en decimal. (10 bytes)
;	- Resultado: D0=Numero en hexadecimal.

PASHEX:
	CLR.L	D5
	LEA	PUNTERO(PC),A1
	MOVE.L	A0,(A1)
	MOVEQ.L	#$0A-1,D0
PASBUC02:
	SUB.B	#$30,(A0)+
	BCC.S	PASCON00
	CLR.B	-$01(A0)
PASCON00:
	CMP.B	#$0A,-$01(A0)
	BLT.S	PASCON01
	CLR.B	-$01(A0)
PASCON01:
	DBF	D0,PASBUC02
	MOVE.L	PUNTERO(PC),A0
	LEA	FDATOSSUMA(PC),A1
	MOVEQ.L	#$08-1,D4
	MOVE.L	#$10000000,D3
PHEBUC01:
	MOVEQ.L	#-1,D7
PHEBUC00:
	ADD.L	#$01,D7
	BSR	COPY1
	BSR	RESTAD
	CMP.B	#$09,D0
	BNE.S	PHEBUC00
	BSR	COPY2
	CLR.L	D6
	TST.L	D7
	BEQ.S	PHECON00
PHEBUC02:
	ADD.L	D3,D6
	SUB.L	#$01,D7
	BNE.S	PHEBUC02
	ADD.L	D6,D5
PHECON00:
	LSR.L	#$04,D3
	SUB.L	#$0A,A1
	DBF	D4,PHEBUC01
	MOVE.L	D5,D0
	RTS
COPY1:
	MOVE.L	PUNTERO(PC),A6
	LEA	DSUMA2(PC),A5
COPCON00:
	MOVE.L	(A6)+,(A5)+
	MOVE.L	(A6)+,(A5)+
	MOVE.W	(A6)+,(A5)+
	RTS
COPY2:
	MOVE.L	PUNTERO(PC),A5
	LEA	DSUMA2(PC),A6
	BRA.S	COPCON00
RESTAD:
	MOVEM.L	A0-A1,-(SP)
	ADD.L	#$0A,A0
	ADD.L	#$0A,A1
	CLR.L	D0
	ROXR.L	#$1,D0		; FLAG X=0
	MOVE.L	#$0A-1,D0
RESBUC00:
	SBCD.B	-(A1),-(A0)
	AND.B	#$0F,(A0)
	DBF	D0,RESBUC00
	MOVE.B	(A0),D0
	MOVEM.L	(SP)+,A0-A1
	RTS

	DC.L	0
DSUMA:
	DS.B	$0A
	DC.L	0
DSUMA2:
	DS.B	$0A
	DC.L	0
DATOSSUMA:
	DC.B	0,0,0,0,0,0,0,0,0,1
	DC.B	0,0,0,0,0,0,0,0,1,6
	DC.B	0,0,0,0,0,0,0,2,5,6
	DC.B	0,0,0,0,0,0,4,0,9,6
	DC.B	0,0,0,0,0,6,5,5,3,6
	DC.B	0,0,0,1,0,4,8,5,7,6
	DC.B	0,0,1,6,7,7,7,2,1,6
FDATOSSUMA:
	DC.B	0,2,6,8,4,3,5,4,5,6
	DC.L	0
PUNTERO:
	DC.L	0

;	Fin del codigo texto.

; -----------------------------------

DisMouse:
	TST.L	MainMenuWnd(PC)
	BEQ.S	NoDisMouse
	TST.L	WREQBASE
	BEQ.S	SiDisMouse
NoDisMouse:
	RTS
SiDisMouse:
	MOVEQ	#$70,D0
	MOVE.L	#$10001,D1
	MOVE.L	$4.W,A6
	JSR	-$2AC(A6)		; AllocVec
	MOVE.L	D0,VECBASE
	BEQ.S	ERVEC
	MOVE.L	D0,A0
	MOVE.L	MainMenuWnd(PC),A1
	MOVE.L	_IntuitionBase(PC),A6
	JSR	-$F0(A6)		; Request
ERVEC:
	MOVE.L	D0,WREQBASE
PBUSY:
	MOVE.L	MainMenuWnd(PC),A0
	LEA	BUSYGFX,A1
	MOVE.L	#16,D0
	MOVE.L	#16,D1
	MOVEQ	#0,D2
	MOVEQ	#0,D3
	MOVE.L	_IntuitionBase,A6
	JMP	-$10E(A6)
; --------------------------------------------------------
EnaMouse:
	TST.L	WREQBASE
	BEQ.S	ERVEC3
	MOVE.L	VECBASE(PC),A0
	MOVE.L	MainMenuWnd(PC),A1
	MOVE.L	_IntuitionBase,A6
	JSR	-$78(A6)		; EndRequest
ERVEC3:
	MOVE.L	VECBASE(PC),D0
	BEQ.S	ERVEC2
	MOVE.L	D0,A1
	MOVE.L	$4.W,A6
	JSR	-$2B2(A6)		; FreeVec

	CLR.L	VECBASE
	CLR.L	WREQBASE
	BRA.S	PNORM
ERVEC2:
	CLR.L	VECBASE
	CLR.L	WREQBASE
	RTS
PNORM:
	MOVE.L	MainMenuWnd(PC),A0
	MOVE.L	_IntuitionBase,A6
	JMP	-$3C(A6)

	CNOP	0,4
VECBASE:DC.L	0
WREQBASE:DC.L	0
; -----------------------------------

; -----------------------------------


; -----------------------------------
TxtPrint:
	move.b  54(a0),d0
	ext.w   d0
	move.b  55(a0),d1
	ext.w   d1
	move.l  50(a0),a0
	move.l  _IntuitionBase,a6
	jsr     PrintIText(a6)
	RTS
; -----------------------------------	; D0.l = 0 On
	CNOP	0,4			; D0.l = 1 Off
GadsOnOff:
	MOVE.L	D0,OnOffTAGS+4
	MOVE.L	(A0),A0
	SUB.L	A2,A2
	LEA	OnOffTAGS(PC),A3
	MOVE.L	_GadToolsBase(PC),A6
	JSR	-$2A(A6)
	RTS
	CNOP	0,4
OnOffTAGS:
	DC.L    $8003000E,1
	DC.L	0,0
; -----------------------------------
UpdateTag:
	MOVEM.L	D0-D1/A0,-(SP)
	MOVE.W	D1,D0
	MOVE.W	D2,D1
	BSR	SetGadgetValue
	MOVEM.L	(SP)+,D0-D1/A0

	MOVE.L	([iWnd.w,A0]),A1
	LEA	([iGadgets.w,A0],D2.w*4),A0

	MOVE.L	D0,.tagData
	MOVE.L	D1,.tagData+4
	MOVE.L	(A0),A0
	SUB.L	A2,A2
	LEA	.tagData(PC),A3
	MOVE.L	_GadToolsBase,A6
	JSR	-$2A(A6)
	RTS
	CNOP	0,4
.tagData:
	DC.L    0,0
	DC.L	0,0
; -----------------------------------

; <=-----------------------=>

; A0:xxxPunts
; A1:Dir TagListBase
; D0=Número de gadget
; D1=Número de Tag a modificar
; D2=Dato a modificar.
	CNOP	0,4
OverrideTag:
	CMP.L	#$8008000F,D1
	BNE.S	.noGadgetValue

	MOVEM.L	D0/D1,-(SP)
	MOVE.W	D0,D1
	MOVE.W	D2,D0
	BSR	SetGadgetValue
	MOVEM.L	(SP)+,D0/D1
.noGadgetValue:
.loop1:
	TST.W	D0
	BEQ.S	.skip
.loop2:
	TST.L	(A1)+
	DBNE	D0,.loop1
	ADDQ	#4,A1
	BRA.S	.loop2
.skip:
	TST.L	(A1)
	BEQ.S	.ret
	CMP.L	(A1)+,D1
	BEQ.S	.over
	ADDQ	#4,A1
	BRA.S	.skip
.over:
	MOVE.L	D2,(A1)+
.ret:
	RTS

; <=-----------------------=>
	CNOP	0,4
Centrar:
	TST.L	(A0)
	BNE.S	MIRACERO
	RTS
MIRACERO:
	MOVE.L	(A0)+,A2
	MOVE.L	(A0)+,D1
	MOVE.L	$C(A2),A1
	MOVEQ	#0,D0
MIRACEROB:
	ADDQ.W	#1,D0
	TST.B	(A1)+
	BNE.S	MIRACEROB
	SUBQ.W	#1,D0
	LSL.W	#3,D0
	SUB.W	D0,D1
	LSR.W	#1,D1
	MOVE.W	D1,4(A2)
	BRA.S	Centrar
; <=-----------------------=>

; <=-------------------------------------------------------=>
;	 Rutina de control de lectura de Gadgets.
;	<= -------------------------------------=>
;	    A1 = SaltosGadgets.	; Para salir hacer:  ADD.L  #16+4,SP
;	-12(A1)= Window Handle.
;	 -8(A1)= Punteros Gadgets.
;	 -4(A1)= Nº de Gadgets-1
	CNOP	0,8
Control:
	CLR.W	ControlKeys
	MOVE.L	-8(A1),-(SP)
	MOVE.L	A1,-(SP)
	MOVE.L	-12(A1),A0
	MOVE.L	(A0),-(SP)
ControlLoop:
	MOVE.L	(SP),A0
	MOVE.L	$56(A0),A0
	MOVE.L	$4,A6
	JSR	-$180(A6)	; Wait Port. (iport)(A0)

	MOVE.L	(SP),A0
	MOVE.L	$56(A0),A0
	MOVE.L	_GadToolsBase,A6
	JSR	-$48(A6)	; (D0)IntuiMessage = GT_GetIMsg(iport)(A0)
	TST.L	D0
	BEQ.S	ControlLoop

	MOVE.L	D0,A1
	MOVE.L	A1,-(SP)	; STRUCTURE IntuiMessage
	MOVE.L	$1C(A1),-(SP)	; APTR im_IAddress (the pointer to the Gadget or the Screen)
	MOVE.L	$14(A1),-(SP)	; LONG im_Class (the Class bits correspond directly with the IDCMP Flags)
	MOVE.W	$18(A1),-(SP)	; WORD im_Code (the Code field is for special values like MENU number)

	MOVE.L	_GadToolsBase,A6
	JSR	-$4E(A6)	; GT_ReplyIMsg(imsg)(A1)

	MOVE.W	(SP)+,D2
	MOVEM.L	(SP)+,D0-D1/A1

	CMP.W	#$200,D0	; IDCMP_CLOSEWINDOW
	BEQ	ControlCloseWindow

	CMP.W	#$100,D0	; IDCMP_MENUPICK
	BEQ	ControlMenuPick

;	CMP.W	#$010,D0	; IDCMP_MOUSEMOVE
;	BEQ	ControlMouseMove

	CMP.W	#$020,D0	; IDCMP_GADGETDOWN
	BEQ	ControlGadgetDown

	CMP.W	#$040,D0	; IDCMP_GADGETUP
	BEQ	ControlGadgetUp

	CMP.W	#$400,D0	; IDCMP_RAWKEY
	BEQ.S	ControlRawKey

	BRA.S	ControlLoop

; -----------------------------------=> Vuelta al Control.
ControlRET:
	RTS
; -----------------------------------=> Salir del Control.
ControlSalir:
	ADD.W	#16,SP
	RTS
; -----------------------------------=> Usado por Subrutina Control-Gadgets
ControlCloseWindow:
	ADD.W	#12,SP
	RTS
; -----------------------------------

ControlRawKey:
	MOVEQ	#0,D1
	MOVE.W	ControlKeys,D1
	MOVE.B	$19(A1),D1	; Tecla.
	MOVE.L	4(SP),A1
	MOVE.L	-16(A1),D0
	BEQ	ControlLoop	

	CMP.B	#$60,D1		; Shift Izquierdo Pulsado.
	BEQ.S	ShiftPul
	CMP.B	#$61,D1		; Shift Derecho Pulsado.
	BEQ.S	ShiftPul
	CMP.B	#$E0,D1		; Shift Izquierdo Soltado.
	BEQ.S	ShiftSol
	CMP.B	#$E1,D1		; Shift Derecho Soltado.
	BEQ.S	ShiftSol

	MOVE.L	D0,A1
EsTeclaBuc:
	CMP.L	#$100,(A1)
	BEQ.S	EsFullTecla
	TST.L	(A1)
	BMI	ControlLoop
	CMP.L	(A1)+,D1
	ADDQ	#4,A1
	BNE.S	EsTeclaBuc

	MOVE.L	-4(A1),A1
	JSR	(A1)
	BRA	ControlLoop

EsFullTecla:
	MOVE.L	4(A1),A1
	JSR	(A1)
	BRA	ControlLoop

ShiftPul:
	BSET	#0,ControlKeys
	BRA	ControlLoop

ShiftSol:
	BCLR	#0,ControlKeys
	BRA	ControlLoop

; -----------------------------------

ControlGadgetDown:
	MOVE.L	4(SP),A1	; ***Punts
	MOVE.L	8(SP),A0	; ***Wnd

	SUBQ.L	#4,A1
	MOVE.L	(A1),D0
	BMI	ControlCloseWindow

	MOVE.L	#$FFFF,D3
.loop1:
	ADDQ.W	#1,D3
	CMP.L	(A0)+,D1
	DBEQ	D0,.loop1
	TST.W	D0
	BMI	ControlLoop

	CMP.W	#GD_JoyPort,D3
	BEQ.S	ControlGadgetUp

	BRA	ControlLoop

ControlGadgetUp:
	MOVE.L	4(SP),A1	; ***Punts
	MOVE.L	8(SP),A0	; ***Wnd

	SUBQ.L	#4,A1
	MOVE.L	(A1),D0
	BMI	ControlCloseWindow

	MOVE.L	#$FFFF,D3
.loop1:
	ADDQ.W	#1,D3
	CMP.L	(A0)+,D1
	DBEQ	D0,.loop1
	TST.W	D0
	BMI	ControlLoop


	MOVE.L	4(SP),A0	; ***Punts
	MOVE.W	D2,D0
	MOVE.W	D3,D1
	BSR	SetGadgetValue


	MOVE.L	(A1),D0
.loop2:
	ADDQ.L	#4,A1
	TST.L	4(A1)
	BEQ	ControlLoop
	CMP.L	(A1)+,D3
	DBEQ	D0,.loop2
	TST.W	D0
	BMI	ControlLoop

	MOVE.L	(A1),A1
	JSR	(A1)
	BRA	ControlLoop

; -----------------------------------

ControlMenuPick:
	MOVE.L	$14(A1),D0
	MOVE.W	$18(A1),D1
	MOVE.L	$1C(A1),A0

	BFEXTU	D1{27:5},D2
	BFEXTU	D1{21:6},D3
	BFEXTU	D1{16:5},D4

	CMP.W	#$1F,D2
	BEQ	ControlLoop
	MOVE.L	(PunterosMenu.W,PC,D2.W*4),A0
	CMP.W	#$2F,D3
	BEQ	ControlLoop
	CMP.W	#$1F,D4
	BEQ.S	EJECMENU
	MOVE.L	(A0,D3.W*4),A0
	MOVE.W	D4,D3
EJECMENU:
	JSR	([A0,D3.W*4])
	BRA	ControlLoop

; -----------------------------------

; A0:WindowPunts
; D0:Value
; D1:GadgetKey
SetGadgetValue:
	MOVE.L	iValues(A0),A0
	TST.L	A0
	BEQ.S	.ret
.loop:
	TST.W	(A0)
	BMI.S	.ret

	ADDQ	#4,A0

	CMP.W	-4(A0),D1
	BNE.S	.loop

	MOVE.W	D0,-(A0)
.ret:
	RTS

; A0:WindowPunts
; D0:DefaultValue
; D1:GadgetKey
; D0=Value
GetGadgetValue:
	MOVE.L	A0,-(SP)
	MOVE.L	iValues(A0),A0
	TST.L	A0
	BEQ.S	.ret
.loop:
	TST.W	(A0)
	BMI.S	.ret

	ADDQ	#4,A0

	CMP.W	-4(A0),D1
	BNE.S	.loop

	MOVEQ	#0,D0
	MOVE.W	-(A0),D0
.ret:
	MOVE.L	(SP)+,A0
	RTS





; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>


	CNOP	0,4
PunterosMenu:
	DC.L	MenuProject
	DC.L	MenuCartridges
	DC.L	MenuOptions
	DC.L	0,0

MenuProject:
	DC.L	About			; About
	DC.L	HelpPage		; Help Page
	DC.L	ControlRET		; -----
	DC.L	SubMenuScreen		; Menu Screen
	DC.L	CheatMode		; Cheat Mode
	DC.L	ControlRET		; -----
	DC.L	SubMenuGraphics		; Save VRAM
	DC.L	ControlRET		; -----
	DC.L	EditPrefs		; Edit Prefs
	DC.L	SavePrefs		; Save Prefs
	DC.L	ControlRET		; -----
	DC.L	ControlSalir		; Quit
	DC.L	ControlRET		; -----
SubMenuGraphics:
	DC.L	SaveScreen		; Screen
	DC.L	SaveSprites		; Sprites
	DC.L	ControlRET		; -----
	DC.L	SaveRAM			; RAM as Binary
	DC.L	SaveVRAM		; VRAM as Binary
	DC.L	ControlRET		; -----
SubMenuScreen:
	DC.L	SETPAL			; Set PAL
	DC.L	SETNTSC			; Set NTSC
	DC.L	ControlRET
MenuCartridges:
	DC.L	Insert			; Insert Cartridge
	DC.L	Eject			; Eject  Cartridge
	DC.L	ControlRET		; -----
	DC.L	LoadFrozen		; Load Frozen
	DC.L	SaveFrozen		; Save Frozen
	DC.L	ControlRET		; -----
	DC.L	ReadBatt		; Load RAM-Battery
	DC.L	SaveBatt		; Save RAM-Battery
	DC.L	ControlRET		; -----
	DC.L	ClearBatt		; Clear RAM-Battery
	DC.L	ControlRET		; -----
MenuOptions:
	DC.L	ControlRET		; JoyStick 2
	DC.L	ControlRET		; Overwrite
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Black Border
	DC.L	ControlRET		; No illogical moves
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Auto-Load Battery
	DC.L	ControlRET		; Auto-Save Battery
	DC.L	ControlRET		; Ask for Save Battery
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Show fps.
	DC.L	ControlRET		; -----
	DC.L	SubMenuVideo		; Video Emulation
	DC.L	ControlRET		; -----
	DC.L	SubMenuXpk		; xpk for save
	DC.L	SubMenuCountry		; Country Code
	DC.L	SubMenuExitmode		; Screen mode on exit
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Disable Cheats
	DC.L	ControlRET		; Ask for Reset
	DC.L	ControlRET		; -----

SubMenuVideo:
	DC.L	ControlRET		; Sprites priorities
	DC.L	ControlRET		; Background priorities
	DC.L	ControlRET		; Realtime Scroll Refresh
	DC.L	ControlRET		; Realtime Palette Refresh

SubMenuXpk:
	DC.L	ControlRET		; Select Packer
	DC.L	ControlRET		; -----
	DC.L	ControlRET		; Frozen games
	DC.L	ControlRET		; Battery-RAM

SubMenuExitmode:
	DC.L	NoChange		; No Change.
	DC.L	ForcePAL		; Force to PAL
	DC.L	ForceNTSC		; Force to NTSC

SubMenuCountry:
	DC.L	European		; European / USA
	DC.L	Japanese		; Japanese

; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>
; <=-------------------------------------------------------=>

	CNOP	0,8
MCeros:	DS.L	16

; <=-------------------------------------------------------=>

; =------------------------------------------=> Datos de Ventanas:

	CNOP	0,4

iValues=-20
iKeys=-16
iWnd=-12
iGadgets=-8
iCNT=-4

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	MainMenuValues
	DC.L	0
	DC.L	MainMenuWnd
	DC.L	MainMenuGadgets
	DC.L	MainMenu_CNT-1
MainMenuPunts:
	DC.L	GD_Insert,Insert
	DC.L	GD_ReadBatt,ReadBatt
	DC.L	GD_SaveBatt,SaveBatt
	DC.L	GD_ClearBatt,ClearBatt
	DC.L	GD_JoyPort,JoyPort
	DC.L	GD_JoyType,ImpJoyType
	DC.L	GD_HelpPage,HelpPage
	DC.L	GD_PowerON,PowerON
	DC.L	GD_Continue,Continue
	DC.L	GD_Exit,ControlSalir
	DC.L	0,0
MainMenuValues:
	DC.W	GD_CPUspd,0
	DC.W	GD_ScrMode,0
	DC.W	GD_GfxRefresh,0
	DC.W	GD_SprRefresh,0
	DC.W	GD_JoyType,0
	DC.W	GD_JoyPort,0
	DC.W	GD_EmuType,0	; Tipo Consola
	DC.W	GD_Vlines,0
	DC.W	-1,-1


; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	QuitKeys
	DC.L	QuitWnd
	DC.L	QuitGadgets
	DC.L	Quit_CNT-1
QuitPunts:
	DC.L	GD_QuitYes,ControlSalir
	DC.L	GD_QuitNo,NoQuit
	DC.L	0,0
QuitKeys:
	DC.L	$40,ControlSalir
	DC.L	$44,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	ImpErrorKeys
	DC.L	ImpErrorWnd
	DC.L	ImpErrorGadgets
	DC.L	ImpError_CNT-1
ImpErrorPunts:
	DC.L	GD_Econtinue,ControlSalir
	DC.L	0,0
ImpErrorKeys:
	DC.L	$40,ControlSalir
	DC.L	$44,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	HelpPageKeys
	DC.L	HelpPageWnd
	DC.L	HelpPageGadgets
	DC.L	HelpPage_CNT-1
HelpPagePunts:
	DC.L	GD_HPcontinue,ControlSalir
	DC.L	0,0
HelpPageKeys:
	DC.L	$40,ControlSalir
	DC.L	$44,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	CheatKeys
	DC.L	CheatWnd
	DC.L	CheatGadgets
	DC.L	Cheat_CNT-1
CheatPunts:
	DC.L	GD_PokeAddress,ControlRET
	DC.L	GD_PokeValue,ControlRET
	DC.L	GD_Poke,DoPoke
	DC.L	GD_CheatSeaVal,CheatSearch
	DC.L	GD_CheatComVal,CheatCompare
	DC.L	GD_CheatMore,CheatMore
	DC.L	GD_PokeExit,ControlSalir
	DC.L	0,0
CheatKeys:
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	AboutKeys
	DC.L	AboutWnd
	DC.L	AboutGadgets
	DC.L	About_CNT-1
AboutPunts:
	DC.L	GD_Aboutmore,ControlSalir
	DC.L	GD_AboutExit,ControlSalir
	DC.L	0,0
AboutKeys:
	DC.L	$40,ControlSalir
	DC.L	$44,ControlSalir
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	0
	DC.L	MC68020Wnd
	DC.L	MC68020Gadgets
	DC.L	MC68020_CNT-1
MC68020PUNTS:
	DC.L	GD_magacontinue,ControlSalir
	DC.L	GD_magaExitWB,MC68020SALIR
	DC.L	0,0

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	0
	DC.L	AskSaveBattWnd
	DC.L	AskSaveBattGadgets
	DC.L	AskSaveBatt_CNT-1
AskSaveBattPunts:
	DC.L	GD_ModiNO,ControlSalir
	DC.L	GD_ModiCancel,AskSaveBattCancel
	DC.L	GD_ModiSave,AskSaveBattSave
	DC.L	0,0

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	0
	DC.L	ClearWnd
	DC.L	ClearGadgets
	DC.L	Clear_CNT-1
ClearPunts:
	DC.L	GD_ClearYes,ControlSalir
	DC.L	GD_ClearNo,AskSureNo
	DC.L	0,0

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

	DC.L	0
	DC.L	PrefsKeys
	DC.L	PrefsWnd
	DC.L	PrefsGadgets
	DC.L	Prefs_CNT-1
PrefsPunts:
	DC.L	GD_PrefsSave,ControlSalir
	DC.L	GD_PrefsUse,ControlSalir
	DC.L	GD_PrefsCancel,ControlSalir
	DC.L	GD_FrozenGet,GetFrozen
	DC.L	0,0
PrefsKeys:
	DC.L	-1,-1

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; END Punts ;

; =------------------------------------------<=

	CNOP	0,8
DatsMasterGearPic:
	DC.W	28,09
	DC.W	325,51
	DC.W	3
	DC.L	GGLogo
	DC.B	7,0
	DC.L	0

	CNOP	0,8
DatsJoyTypePic:
	DC.W	0,0
	DC.W	47,16
	DC.W	3
DirJoyTypePic:	DC.L	GBTeclado
	DC.B	7,0
	DC.L	0

; -----------------------------------

; =------------------------------------------=> Include de GadToolsBox
	CNOP	0,8
	INCLUDE	"GadToolsBox/AmiMasterGear.s"
; =------------------------------------------<=

; -----------------------------------
	CNOP	0,8
CheatBuf:	DS.B	8*1024
; -----------------------------------
ILBMraw:	DS.B	4*1024
; -----------------------------------

; =------------------------------------------=> ¡Comienza la Acción!
	CNOP	0,8
MasterGearEmul:
; =------------------------------------------<=

; =------------------------------------------=> Sección gráfica de prueba.
	IFND	GG_Menu
	SECTION	Gfx,data_c

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


MapROMBase=0
PagRead=0
PagWrite=0
DirVRAM=0
MaskVPAL=0
Consola=0

Debug=0
Pexx=0
I=0
R=0
Flags_DAA=0
OUTBEa=0
OUTBEb=0
INBE=0
INBEb=0
OtrSpr=0
NexSpr=0

ANA=$488

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

DirSprit0:
Color0:
PantGfx:
Plano5:
Regs:
IRAM:
VRAM:
Outs:
Ins:
VDPRegs:
VPAL:
PSG_Tab:
PCReg:
SRAM:	DS.B	20*1024

	ENDC
; =------------------------------------------<=
