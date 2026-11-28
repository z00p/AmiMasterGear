; AmgMenu.asm: AmiMasterGear's big RTG menu (AMG_BIGMENU), AmiGameBoy 2.5's big menu
; (src/hybrid/bigmenu.s there) brought over: Juan's GadToolsBox menu opened in the output-sized
; Picasso96 mode, 1920x1080 (then 1280x720), with the shared kit rtgmenu.s (MIT, rtgmenu.LICENSE):
; his 640x212 layout in a 4:3 area (1440x1080 / 960x720) at the top, straight under the title bar,
; positions and sizes scaled by X 9/4, Y 9/2 at 1080 (X 3/2, Y 3 at 720); frames, bevels and text
; drawn at the screen's own size in the Pixel font (rmfont_18x36 / rmfont_12x24, rtg-framework
; tools/menufont.py, z00p); the logo and the four Joy type pictures redrawn at that resolution
; (src/data/hires_*.bin: the logo by tools/bigmenu_art.py, the Joy type pictures are AmiGameBoy's,
; Juan drew the same four for both). The menu's tick and Amiga key are drawn to the font's size.
; Intuition and GadTools still draw and run everything: before Juan's SetupScreen this file makes
; his numbers and his font bigger (the screen tags, the 10 window tables, the NewGadget tables, the
; IntuiText chains, the ASL requesters' place, the font, the pictures); the 47 GadToolsBox bevels
; go through RmnBevel (RmnPatchBevels). Only the menu: the game keeps its own screen (AmgRtg.asm).
;
; Layout (big menu only): the main window 24 lines taller (Juan's lines, before scaling): Screen
; Options and Cartridge longer, Screen Options' rows 14 lines apart (Juan's 16) with the Scanlines
; selector (Off / On) and the Scanline style list (bm_chpre: an OS 3.2 chooser.gadget pop-up, else
; a cycle gadget; labelled "Style") as its fourth and fifth rows, the Cartridge box's second and
; third rows spread down, the Emulation Speed / Joy-Control row and the buttons 24 lower. The selectors are trimmed to the text's
; height (RmnTrimCycles: test feedback, 26 Nov 2026, "less padding above and below the text").
;
; Settings in PROGDIR:AmiMasterGear.config (plain text, lines "Key = Value", any case; unknown lines
; are kept when this file rewrites it):
;   Menu = Classic	the menu as before (AMG_RTGMENU's 640x270 / 640x256, else the AGA menu)
;   Scanlines = On | Off	the Scanlines selector, and
;   ScanlineStyle = 25 | 50 | 75 | blendlight | blend | blendstrong	the Scanline style list
;			(Hard 25/50/75%, Blended light / Blended / strong, Arnold's order and
;			words); both lines written as soon as either changes (the game screen,
;			AmgRtgCfg.asm, reads the same lines). With AMG_RTGCFG the selectors start
;			from AmgCfgScan and AmgCfgStyle (the config, then the ToolTypes, where
;			Arnold's single words such as "Scanlines = blend" also work) and set them,
;			so the next Power ON follows them
; No 1920x1080 or 1280x720 P96 mode, or a screen of it that cannot open, or Juan's tables not as
; expected: the menu as before, untouched.
;
; Hooks (AmiMasterGear_Menu.asm, under IFD AMG_BIGMENU): bm_init in Programa after LoadPrefs and
; AmgRtgMenuMode, before SetupScreen (Juan's start-up code has taken the Workbench start-up message
; by then: no DOS call before that, AmiGameBoy's lesson, alert 87000004 when started from an icon);
; his three DrawImage calls go through bm_drawimage; Quitar calls bm_exit; his gadget table gets
; GD_Scan and GD_ScanSty (and Control finds 18). GadToolsBox/AmiMasterGear.s: the 17th and 18th
; gadgets (made only when bm_lay: bm_mmcnt), the chooser hooks bm_chpre .. bm_chfree.
; AMG_BIGDBG (test): PROGDIR:bigmenu.log rewritten at each step (step, ModeID, width, height,
; depth, X and Y scales, font height): 0 entered, 1 config read, 2 libraries, 3 mode, 4 scales,
; 5 test screen, 6 bevels, 7 font, 8 tables scaled, $10 first picture drawn, $20 Quit.

BMSTEP	MACRO
	IFD	AMG_BIGDBG
	move.l	#\1,bm_dbg
	jsr	bm_dbgw
	ENDC
	ENDM

BM_DY		=24			; the main window's extra height (Juan's lines)
BM_LH		=212+BM_DY		; the layout's height for RmnSetup
BM_BEVELS	=47			; GadToolsBox bevels in MainMenuRender .. ClearRender
BM_MBEVELS	=17			; of them in MainMenuRender
BM_DBGN		=8			; AMG_BIGDBG: longs in the log line
BM_WINS		=(ClearHeight+2-MainMenuLeft)/8	; window Left/Top/Width/Height, contiguous
	IFNE	(ClearHeight+2-MainMenuLeft)-BM_WINS*8
	FAIL	"window table not contiguous"
	ENDC
	IFNE	GD_Scan-MainMenu_CNT
	FAIL	"GD_Scan is not the gadget after Juan's last"
	ENDC

	SECTION	AmgBigCode,CODE
bm_init:
	movem.l	d0-d7/a0-a6,-(sp)
	sf	bm_on
	BMSTEP	0
	bsr	bm_config		; "Menu = Classic"? "Scanlines = On"?
	BMSTEP	1
	tst.b	bm_classic
	bne	.x
	move.l	4.w,a6
	lea	bm_gfxn(pc),a1
	moveq	#39,d0
	jsr	-552(a6)		; OpenLibrary
	move.l	d0,RmnGfx
	beq	.close
	lea	bm_intn(pc),a1
	moveq	#39,d0
	jsr	-552(a6)
	move.l	d0,RmnInt
	beq	.close
	lea	bm_p96n(pc),a1
	moveq	#2,d0
	jsr	-552(a6)
	move.l	d0,RmnP96
	beq	.close
	BMSTEP	2
	IFD	AMG_BIG720
	move.l	#720,d0			; test: the 720 fallback straight away
	ELSE
	move.l	#1080,d0
	ENDC
.trysz:	move.l	d0,bm_want		; 1080, then 720 when 1080 has no mode or no screen
	jsr	RmnFind			; d0 ModeID, d1/d2 size, d3 depth
	movem.l	d0-d3,bm_mode
	tst.l	d0
	beq	.nosize
	BMSTEP	3
	move.w	#640,d4
	move.w	#BM_LH,d5
	moveq	#2,d6			; the 4:3 area
	jsr	RmnSetup
	tst.l	d0
	beq	.nosize
	BMSTEP	4
	movem.l	bm_mode,d0-d3
	jsr	RmnTryOpen		; enough board memory?
	tst.l	d0
	bne	.nosize
	BMSTEP	5
	lea	MainMenuRender,a0	; Juan's bevels where we expect them?
	lea	OpenClearWindow,a1
	move.l	#BM_BEVELS,d0
	moveq	#0,d1			; count only
	jsr	RmnPatchBevels
	cmp.l	#BM_BEVELS,d0
	bne	.close
	BMSTEP	6
	bsr	bm_font			; every topaz 8 of the menu is the Pixel font
	tst.l	d0
	beq	.close
	BMSTEP	7
; from here on the menu is big
	st	bm_on
	bsr	bm_marks		; the menu's tick and Amiga key at the font's size
	bsr	bm_layout		; the taller main window and the Scanlines selector (Juan's numbers)
	move.w	RmnFontH,d0
	move.w	d0,bm_fy		; the font's height
	addq.w	#3,d0
	move.w	d0,RmnBar1		; window tops: under the big screen title bar
	move.w	#11,RmnBar0
	move.w	DriPens+6,RmnShine	; SHINEPEN, SHADOWPEN
	move.w	DriPens+8,RmnShadow
	movem.l	bm_mode,d0-d3		; the screen
	move.l	d1,ScreenTags+20	; SA_Width
	move.l	d2,ScreenTags+28	; SA_Height
	move.l	d3,ScreenTags+36	; SA_Depth
	move.l	d0,ScreenTags+68	; SA_DisplayID
	lea	MainMenuLeft,a0		; the windows
	moveq	#BM_WINS,d0
	moveq	#8,d1
	moveq	#1,d2
	jsr	RmnRects
	lea	bm_ngads(pc),a2		; the gadgets
	moveq	#30,d1
	moveq	#0,d2
.ng:	move.l	(a2)+,d0
	beq.s	.ngx
	move.l	d0,a0
	move.l	(a2)+,d0
	jsr	RmnRects
	bra.s	.ng
.ngx:	lea	MainMenuNGads,a0	; the main window's selectors: no taller than the text needs
	lea	MainMenuGTypes,a1
	moveq	#0,d0
	move.w	bm_mmcnt,d0
	moveq	#30,d1
	jsr	RmnTrimCycles
	lea	bm_itexts(pc),a0	; the texts
	jsr	RmnITexts
	lea	InsTags,a0		; the ASL requesters (Juan's tags)
	bsr	bm_asl
	lea	FroTags,a0
	bsr	bm_asl
	lea	SavTags,a0
	bsr	bm_asl
	lea	bm_imgs(pc),a2		; the pictures
.im:	move.l	(a2)+,d0
	beq.s	.imx
	move.l	d0,a0
	movem.w	(a2)+,d0-d2
	bsr	bm_hires		; a redrawn copy for this size?
	bne.s	.im
	jsr	RmnImage		; else Juan's in blocks
	bra.s	.im
.imx:	lea	MainMenuRender,a0	; the bevels
	lea	OpenClearWindow,a1
	move.l	#BM_BEVELS,d0
	moveq	#1,d1
	jsr	RmnPatchBevels
	BMSTEP	8
	bra.s	.x
.nosize:
	cmp.l	#1080,bm_want
	bne.s	.close
	move.l	#720,d0
	bra	.trysz
.close:	bsr	bm_libs			; classic: nothing changed
.x:
	IFD	AMG_BIGDBG
	bsr	bm_dbgw
	ENDC
	movem.l	(sp)+,d0-d7/a0-a6
	rts

; ---- the menu's font (Juan's topaz8 TextAttr pointed at it) -> D0 = 1 done, 0 none (classic)
bm_font:
	movem.l	d1/a0-a2,-(sp)
	moveq	#8,d0			; the Pixel font made for this cell
	jsr	RmnScY
	lea	bm_pix24,a2
	cmp.w	#36,d0
	bcs.s	.p
	lea	bm_pix36,a2
.p:	lea	topaz8,a0
	lea	bm_pixn(pc),a1
	jsr	RmnFontBlob
	movem.l	(sp)+,d1/a0-a2
	rts

; ---- the menu's checkmark and Amiga-key images for the font's cell (RmnMarks), given to the
; main window (WA_Checkmark, WA_AmigaKey) and to LayoutMenus (GTMN_Checkmark, GTMN_AmigaKey) by a
; TAG_MORE in Juan's two tag lists. Ink BARDETAILPEN, paper BARBLOCKPEN (Juan's DriPens).
; Anything unexpected: the system's.
bm_marks:
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.l	#$80080031,MTags1	; GTMN_TextAttr, Juan's LayoutMenus tags as built
	bne	.x
	cmp.l	#$80000093,MainMenuSC+8	; WA_NewLookMenus, the main window's last tag
	bne	.x
	tst.l	MainMenuSC+16
	bne	.x
	moveq	#8,d0
	jsr	RmnScY
	lea	bm_mk24,a0
	cmp.w	#36,d0
	bcs.s	.s
	lea	bm_mk36,a0
.s:	move.w	DriPens+18,d0		; BARDETAILPEN
	move.w	DriPens+20,d1		; BARBLOCKPEN
	lea	bm_mkbuf,a1
	move.w	#BMK_BUFSZ,d2
	jsr	RmnMarks
	tst.l	d0
	beq	.x
	move.l	MTags1+4,bm_mtags+4
	move.l	#2,MTags1		; TAG_MORE
	move.l	#bm_mtags,MTags1+4
	move.l	MainMenuSC+12,bm_wtags+4
	move.l	#2,MainMenuSC+8
	move.l	#bm_wtags,MainMenuSC+12
.x:	movem.l	(sp)+,d0-d2/a0-a1
	rts

; ---- the taller main window, in Juan's 640x212 numbers before they are scaled. His numbers it
; moves are checked first; anything unexpected: his layout, no Scanlines selector (bm_lay clear).
; A place (x, y) moves down by bm_ydown; a box that spans the moved rows (its top above line 90, its
; foot below line 120: Cartridge, Screen Options, the outer frame) grows by BM_DY.
bm_layout:
	movem.l	d0-d4/a0-a2,-(sp)
	cmp.w	#190,MainMenuHeight
	bne	.x
	cmp.w	#11,MainMenuTop
	bne	.x
	lea	MainMenuNGads,a0
	cmp.l	#(385<<16)|143,30*GD_JoyType(a0)
	bne	.x
	cmp.l	#(98<<16)|142,30*GD_Vlines(a0)
	bne	.x
	cmp.l	#(35<<16)|113,30*GD_EmuType(a0)
	bne	.x
	cmp.l	#(502<<16)|112,30*GD_SprRefresh(a0)
	bne	.x
	cmp.l	#(502<<16)|96,30*GD_GfxRefresh(a0)
	bne	.x
	cmp.l	#(473<<16)|80,30*GD_ScrMode(a0)
	bne	.x
	cmp.l	#(34<<16)|97,30*GD_ReadBatt(a0)
	bne	.x
	cmp.w	#7,MainMenuGTypes+2*GD_SprRefresh
	bne	.x
	moveq	#0,d1			; the main window's bevels: count
	bsr	bm_mbevs
	cmp.w	#BM_MBEVELS,d0
	bne	.x
; as expected: change it
	moveq	#1,d1
	bsr	bm_mbevs		; the bevels
	lea	MainMenuNGads,a0	; the gadgets
	moveq	#MainMenu_CNT-1,d4
.g:	move.w	(a0),d0
	move.w	2(a0),d1
	bsr	bm_ydown
	add.w	d2,2(a0)
	lea	30(a0),a0
	dbf	d4,.g
	lea	MainMenuText0,a0	; the main window's texts
.t:	move.w	4(a0),d0
	move.w	6(a0),d1
	bsr	bm_ydown
	add.w	d2,6(a0)
	move.l	16(a0),d0		; it_NextText
	move.l	d0,a0
	bne.s	.t
	add.w	#BM_DY,MainMenuHeight
	lea	MainMenuNGads,a0	; Screen Options: five rows 14 apart
	move.w	#94,30*GD_GfxRefresh+2(a0)
	move.w	#108,30*GD_SprRefresh+2(a0)
	IFD	AMG_RTGCFG		; the game screen's options (AmgRtgCfg.asm: config, then ToolTypes)
	tst.b	AmgCfgScan
	sne	d0
	neg.b	d0
	move.b	d0,bm_scan
	move.b	AmgCfgStyle,bm_style
	ENDC
	moveq	#0,d0			; the selectors as the config says
	move.b	bm_scan,d0
	move.l	d0,bm_scantags+12
	move.b	bm_style,d0
	cmp.b	#5,d0
	bls.s	.sy
	moveq	#1,d0
	move.b	d0,bm_style
.sy:	move.l	d0,bm_stytags+12
	move.w	#MainMenu_CNT+2,bm_mmcnt	; GadToolsBox makes them too
	st	bm_lay
.x:	movem.l	(sp)+,d0-d4/a0-a2
	rts

; D0/D1 = a place in the main window (Juan's x, y) -> D2.w = how far it moves down
bm_ydown:	moveq	#BM_DY,d2
	cmp.w	#132,d1			; the Emulation Speed / Joy-Control row, the buttons
	bge.s	.x
	moveq	#0,d2
	cmp.w	#390,d0			; Screen Options keeps its rows
	bge.s	.x
	cmp.w	#90,d1			; Cartridge: the first row stays,
	blt.s	.x
	moveq	#BM_DY/2,d2		; the second half way,
	cmp.w	#110,d1
	blt.s	.x
	moveq	#BM_DY,d2		; the third all the way
.x:	rts

; Juan's bevels in MainMenuRender (the pattern RmnPatchBevels looks for): D1 = 0 count them,
; 1 move them (bm_ydown) and grow the long ones -> D0 = how many
bm_mbevs:
	movem.l	d1-d4/a0-a1,-(sp)
	moveq	#0,d4
	lea	MainMenuRender,a0
	lea	HelpPageRender,a1
	move.w	d1,d3
.s:	lea	24(a0),a0
	cmp.l	a1,a0
	bhi.s	.e
	lea	-24(a0),a0
	cmp.w	#$303C,(a0)		; move.w #x,d0 / add.w d4,d0 / move.w #y,d1 / add.w d5,d1 /
	bne.s	.n			; move.w #w,d2 / move.w #h,d3 / jsr DrawBevelBoxA(a6)
	cmp.l	#$D044323C,4(a0)
	bne.s	.n
	cmp.l	#$D245343C,10(a0)
	bne.s	.n
	cmp.w	#$363C,16(a0)
	bne.s	.n
	cmp.l	#$4EAEFF88,20(a0)
	bne.s	.n
	addq.w	#1,d4
	tst.w	d3
	beq.s	.nx
	move.w	2(a0),d0		; x, y
	move.w	8(a0),d1
	cmp.w	#90,d1			; a long box: grows
	bge.s	.m
	move.w	d1,d2
	add.w	18(a0),d2
	cmp.w	#120,d2
	ble.s	.m
	add.w	#BM_DY,18(a0)
.m:	bsr	bm_ydown
	add.w	d2,8(a0)
.nx:	lea	24(a0),a0
	bra.s	.s
.n:	addq.l	#2,a0
	bra.s	.s
.e:	moveq	#0,d0
	move.w	d4,d0
	movem.l	(sp)+,d1-d4/a0-a1
	rts

; ---- an ASL tag list of Juan's (A0): the left, top, width and height it gives, scaled as a
; window's (into the 4:3 area, the top under the big title bar)
bm_asl:	movem.l	d0-d1/a0,-(sp)
.t:	move.l	(a0)+,d1
	beq.s	.x
	move.l	(a0)+,d0
	cmp.l	#$80080003,d1		; ASLFR_InitialLeftEdge
	bne.s	.t1
	jsr	RmnScX
	add.w	RmnOX,d0
	bra.s	.put
.t1:	cmp.l	#$80080004,d1		; ASLFR_InitialTopEdge: under the bar as the windows
	bne.s	.t2
	sub.w	RmnBar0,d0
	bpl.s	.t1a
	moveq	#0,d0
.t1a:	jsr	RmnScY
	add.w	RmnBar1,d0
	add.w	RmnOY,d0
	bra.s	.put
.t2:	cmp.l	#$80080005,d1		; ASLFR_InitialWidth
	bne.s	.t3
	jsr	RmnScX
	bra.s	.put
.t3:	cmp.l	#$80080006,d1		; ASLFR_InitialHeight
	bne.s	.t
	jsr	RmnScY
.put:	move.l	d0,-4(a0)
	bra.s	.t
.x:	movem.l	(sp)+,d0-d1/a0
	rts

; ---- the Scanlines selector (Juan's gadget table): D2.w = 0 Off, 1 On. Both scanline lines
; written to the config at once.
bm_gscan:
	movem.l	d0-d7/a0-a6,-(sp)
	tst.b	bm_lay
	beq.s	.x
	tst.w	d2
	sne	d7
	neg.b	d7
	cmp.b	bm_scan,d7
	beq.s	.x
	move.b	d7,bm_scan
	IFD	AMG_RTGCFG
	move.b	d7,AmgCfgScan		; the game screen takes it at the next Power ON (AmgRtgLayout)
	ENDC
	moveq	#0,d0
	move.b	d7,d0
	move.l	d0,bm_scantags+12	; GTCY_Active, for the next time the window opens
	bsr	bm_cfgscan
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts

; ---- the Scanline style selector: the chooser's CHOOSER_Selected, or (the cycle gadget when
; chooser.gadget did not open) D2.w: 0-2 Hard 25/50/75%, 3-5 Blended light / Blended / strong.
; The style is kept while Scanlines is Off. Both lines written to the config at once.
bm_gsty:
	movem.l	d0-d7/a0-a6,-(sp)
	tst.b	bm_lay
	beq.s	.x
	move.l	bm_chobj,d0
	beq.s	.cy
	move.l	d0,a0
	lea	bm_chsel,a1
	move.l	#$85001005,d0		; CHOOSER_Selected
	move.l	_IntuitionBase,a6
	jsr	-654(a6)		; GetAttr
	move.l	bm_chsel,d2
.cy:	cmp.l	#5,d2
	bhi.s	.x
	cmp.b	bm_style,d2
	beq.s	.x
	move.b	d2,bm_style
	IFD	AMG_RTGCFG
	move.b	d2,AmgCfgStyle		; the next Power ON
	ENDC
	moveq	#0,d0
	move.b	d2,d0
	move.l	d0,bm_stytags+12	; GTCY_Active / the chooser's setting next time
	bsr	bm_cfgscan
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts

; "Scanlines = On|Off" and "ScanlineStyle = <word>" into the config. Keeps every register.
bm_cfgscan:
	movem.l	d0/a2-a3,-(sp)
	lea	bm_kscan(pc),a3
	lea	bm_von(pc),a2
	tst.b	bm_scan
	bne.s	.w
	lea	bm_voff(pc),a2
.w:	bsr	bm_cfgset
	lea	bm_ksty(pc),a3
	moveq	#0,d0
	move.b	bm_style,d0
	cmp.b	#5,d0
	bls.s	.s
	moveq	#1,d0
.s:	move.l	bm_stywd(pc,d0.w*4),a2
	bsr	bm_cfgset
	movem.l	(sp)+,d0/a2-a3
	rts
bm_stywd:	dc.l	bm_w25,bm_w50,bm_w75,bm_wbl,bm_wbn,bm_wbs

; ---- The Scanline style as an OS 3.2 chooser.gadget pop-up list (AmiPCEngine's way, Menu.asm
; ChooserPre and the rest): GadToolsBox makes the window's gadgets in turn; for GD_ScanSty
; bm_chpre makes a chooser in the cycle gadget's box (trimmed and scaled as the other selectors)
; and GadTools makes a text gadget one pixel wide that only draws the label. MainMenuGadgets
; holds the chooser, so Juan's GADGETUP lookup finds it (bm_gsty). No chooser.gadget (OS 3.1)
; or no object: the 6-entry cycle gadget.

; D0 = the gadget's kind, D3 = its number, A4 = its tags, BufNewGad = its box -> D0 = the kind
; GadTools makes (TEXT_KIND when a chooser was made). Keeps the other registers.
bm_chpre:
	cmp.w	#GD_ScanSty,d3
	bne	.r
	tst.b	bm_lay
	beq	.r
	movem.l	d1-d4/a0-a2/a6,-(sp)
	move.l	bm_chbase,d1
	bne.s	.lib
	move.l	4.w,a6
	lea	bm_chn(pc),a1
	moveq	#44,d0
	jsr	-552(a6)		; OpenLibrary
	move.l	d0,bm_chbase
	beq	.no
.lib:	lea	bm_chlist,a0		; the list of chooser nodes
	lea	4(a0),a1		; NewList
	move.l	a1,(a0)
	clr.l	4(a0)
	move.l	a0,8(a0)
	move.l	a0,bm_chtags+44		; CHOOSER_Labels
	lea	bm_stylab,a2
.n:	move.l	(a2)+,d0
	beq.s	.nd
	move.l	d0,bm_cnatags+4
	lea	bm_cnatags,a0
	move.l	bm_chbase,a6
	jsr	-36(a6)			; AllocChooserNodeA
	tst.l	d0
	beq.s	.nd
	lea	bm_chlist,a0
	move.l	d0,a1
	move.l	4.w,a6
	jsr	-246(a6)		; AddTail
	bra.s	.n
.nd:	lea	BufNewGad,a1
	move.w	(a1),d0
	ext.l	d0
	move.l	d0,bm_chtags+4		; GA_Left
	move.w	2(a1),d0
	ext.l	d0
	move.l	d0,bm_chtags+12		; GA_Top
	move.w	4(a1),d0
	ext.l	d0
	move.l	d0,bm_chtags+20		; GA_Width
	move.w	6(a1),d0
	ext.l	d0
	move.l	d0,bm_chtags+28		; GA_Height
	moveq	#0,d0
	move.w	16(a1),d0
	move.l	d0,bm_chtags+36		; GA_ID
	moveq	#0,d0
	move.b	bm_style,d0
	move.l	d0,bm_chtags+52		; CHOOSER_Selected
	move.l	bm_chbase,a6
	jsr	-30(a6)			; CHOOSER_GetClass
	move.l	d0,a0
	sub.l	a1,a1
	lea	bm_chtags,a2
	move.l	_IntuitionBase,a6
	jsr	-636(a6)		; NewObjectA
	move.l	d0,bm_chobj
	beq.s	.no			; none: the cycle gadget
	move.w	#1,BufNewGad+4		; the GadTools gadget: the label only
	movem.l	(sp)+,d1-d4/a0-a2/a6
	moveq	#13,d0			; TEXT_KIND
	rts
.no:	movem.l	(sp)+,d1-d4/a0-a2/a6
	moveq	#7,d0			; CYCLE_KIND
.r:	rts

; A0 = MainMenuGadgets' entry for gadget D3: the chooser there when there is one. Keeps every
; register but D0.
bm_chpost:
	cmp.w	#GD_ScanSty,d3
	bne.s	.x
	move.l	bm_chobj,d0
	beq.s	.x
	move.l	d0,(a0)
.x:	rts

; the chooser into the open main window, drawn. Keeps every register.
bm_chadd:
	movem.l	d0-d1/a0-a2/a6,-(sp)
	move.l	bm_chobj,d0
	beq.s	.x
	move.l	MainMenuWnd,d1
	beq.s	.x
	move.l	_IntuitionBase,a6
	move.l	d1,a0
	move.l	d0,a1
	moveq	#-1,d0
	jsr	-42(a6)			; AddGadget
	move.l	bm_chobj,a0
	move.l	MainMenuWnd,a1
	sub.l	a2,a2
	moveq	#1,d0
	jsr	-432(a6)		; RefreshGList
.x:	movem.l	(sp)+,d0-d1/a0-a2/a6
	rts

; the chooser out of the window before it closes. Keeps every register.
bm_chrem:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	bm_chobj,d0
	beq.s	.x
	move.l	MainMenuWnd,d1
	beq.s	.x
	move.l	_IntuitionBase,a6
	move.l	d1,a0
	move.l	d0,a1
	jsr	-228(a6)		; RemoveGadget
.x:	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

; the chooser and its list freed (after the window and the GadTools gadgets). Keeps every register.
bm_chfree:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	bm_chobj,d0
	beq.s	.l
	clr.l	bm_chobj
	move.l	d0,a0
	move.l	_IntuitionBase,a6
	jsr	-642(a6)		; DisposeObject
.l:	tst.l	bm_chlist		; never made: nothing in it
	beq.s	.x
.f:	lea	bm_chlist,a0
	move.l	4.w,a6
	jsr	-258(a6)		; RemHead
	tst.l	d0
	beq.s	.x
	move.l	d0,a0
	move.l	bm_chbase,a6
	jsr	-42(a6)			; FreeChooserNode
	bra.s	.f
.x:	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

	IFD	AMG_BIGTEST
; test (AutoTest.asm AutoGrab, after the menu's grab): the two selectors used with real mouse
; events (input.device), then Juan's Control loop takes the messages as in play, so the config
; file is written (the PC reads it after the run): a click on Scanlines (it flips), a press on the
; Scanline style (its list opens: grab 3), the release on the list's third entry (Hard 75%), a
; click on Exit (Control returns). Then grab 4 and "@S <Scanlines> <style>" on the serial port.
bm_autotest:
	movem.l	d0-d7/a0-a6,-(sp)
	tst.b	bm_lay
	beq	.x
	bsr	bm_inopen
	beq	.x
	move.l	MainMenuGadgets+GD_Scan*4,a0
	bsr	bm_gmid
	bsr	bm_inmove
	bsr	bm_indown
	bsr	bm_inup
	moveq	#25,d1
	bsr	bm_delay
	move.l	MainMenuGadgets+GD_ScanSty*4,a0
	bsr	bm_gmid
	bsr	bm_inmove
	bsr	bm_indown
	moveq	#50,d1
	bsr	bm_delay
	moveq	#3,d0
	jsr	AutoGrab		; the list open
	move.l	Scr,a0			; the list: a window on the menu's screen not Juan's
	move.l	4(a0),d0		; sc_FirstWindow
.w:	tst.l	d0
	beq.s	.up
	move.l	d0,a0
	cmp.l	MainMenuWnd,d0
	bne.s	.lw
	move.l	(a0),d0			; NextWindow
	bra.s	.w
.lw:	move.w	4(a0),d0		; x: the middle
	move.w	8(a0),d2
	lsr.w	#1,d2
	add.w	d2,d0
	moveq	#0,d2			; y: the third of six rows
	move.w	10(a0),d2
	moveq	#0,d3
	move.b	55(a0),d3		; BorderTop
	sub.w	d3,d2
	moveq	#0,d4
	move.b	57(a0),d4		; BorderBottom
	sub.w	d4,d2
	mulu	#5,d2
	divu	#12,d2
	add.w	d3,d2
	add.w	6(a0),d2
	move.w	d2,d1
	bsr	bm_inmove
	moveq	#10,d1
	bsr	bm_delay
.up:	bsr	bm_inup
	moveq	#50,d1
	bsr	bm_delay
	move.l	MainMenuGadgets+GD_Exit*4,a0
	bsr	bm_gmid
	bsr	bm_inmove
	bsr	bm_indown
	bsr	bm_inup
	bsr	bm_inclose
	lea	MainMenuPunts,a1	; Juan's loop: the three GADGETUPs, Exit returns
	jsr	Control
	moveq	#4,d0
	jsr	AutoGrab
	lea	bm_attxt+3,a1
	move.b	bm_scan,d0
	add.b	#"0",d0
	move.b	d0,(a1)+
	addq.l	#1,a1
	move.b	bm_style,d0
	add.b	#"0",d0
	move.b	d0,(a1)
	lea	bm_attxt,a0
	jsr	AutoPuts
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts

; A0 = a gadget of the main window -> D0/D1 = its middle on the screen
bm_gmid:
	move.l	MainMenuWnd,a1
	move.w	4(a1),d0
	add.w	4(a0),d0
	move.w	8(a0),d2
	lsr.w	#1,d2
	add.w	d2,d0
	move.w	6(a1),d1
	add.w	6(a0),d1
	move.w	10(a0),d2
	lsr.w	#1,d2
	add.w	d2,d1
	rts

; input.device for the test's mouse events -> NE: open
bm_inopen:
	movem.l	d1/a0-a1/a6,-(sp)
	move.l	4.w,a6
	jsr	-666(a6)		; CreateMsgPort
	move.l	d0,bm_inport
	beq.s	.x
	move.l	d0,a0
	moveq	#48,d0
	jsr	-654(a6)		; CreateIORequest
	move.l	d0,bm_inreq
	beq.s	.x
	lea	bm_inname(pc),a0
	moveq	#0,d0
	move.l	bm_inreq,a1
	moveq	#0,d1
	jsr	-444(a6)		; OpenDevice
	tst.l	d0
	seq	d0
	ext.w	d0
	ext.l	d0
.x:	movem.l	(sp)+,d1/a0-a1/a6
	tst.l	d0
	rts
bm_inclose:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	4.w,a6
	move.l	bm_inreq,a1
	jsr	-450(a6)		; CloseDevice
	move.l	bm_inreq,a0
	jsr	-660(a6)		; DeleteIORequest
	move.l	bm_inport,a0
	jsr	-672(a6)		; DeleteMsgPort
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
; the pointer to D0/D1 on the menu's screen (IECLASS_NEWPOINTERPOS, IESUBCLASS_PIXEL)
bm_inmove:
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	Scr,bm_inpix
	move.w	d0,bm_inpix+4
	move.w	d1,bm_inpix+6
	move.l	#$13010000,d0		; class, subclass, code 0
	moveq	#0,d1			; qualifier
	move.l	#bm_inpix,d2
	bsr.s	bm_inev
	moveq	#2,d1
	bsr	bm_delay
	movem.l	(sp)+,d0-d2/a0-a1
	rts
bm_indown:
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	#$02000068,d0		; IECLASS_RAWMOUSE, IECODE_LBUTTON
	move.l	#$C000,d1		; IEQUALIFIER_RELATIVEMOUSE | LEFTBUTTON
	bra.s	bm_inbut
bm_inup:
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	#$020000E8,d0		; the button up
	move.l	#$8000,d1
bm_inbut:
	moveq	#0,d2
	bsr.s	bm_inev
	moveq	#5,d1
	bsr	bm_delay
	movem.l	(sp)+,d0-d2/a0-a1
	rts
; D0 = class.b subclass.b code.w, D1.w = qualifier, D2 = ie_EventAddress (or X/Y) -> written
bm_inev:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	lea	bm_inevt,a0
	clr.l	(a0)			; ie_NextEvent
	move.l	d0,4(a0)
	move.w	d1,8(a0)
	move.l	d2,10(a0)
	clr.l	14(a0)
	clr.l	18(a0)
	move.l	bm_inreq,a1
	move.w	#11,28(a1)		; IND_WRITEEVENT
	move.l	#22,36(a1)
	move.l	a0,40(a1)
	move.l	4.w,a6
	jsr	-456(a6)		; DoIO
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
; D1 = ticks
bm_delay:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	_DosBase,a6
	jsr	-198(a6)		; Delay
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
bm_inname:	dc.b	"input.device",0
	even
	ENDC

; ---- A0 = one of Juan's pictures (planar data) -> NE: its redrawn copy for this size is
; RmnDrawImage's (RmnImageUse); EQ: none (RmnImage then). Keeps every register.
bm_hires:
	movem.l	d0-d1/a0-a2,-(sp)
	moveq	#4,d1			; 1080: 2 x 4 blocks
	cmp.l	#$00020004,RmnBX	; RmnBX, RmnBY
	beq.s	.sz
	moveq	#8,d1			; 720: 1 x 2
	cmp.l	#$00010002,RmnBX
	bne.s	.no
.sz:	lea	bm_hrtab,a2
.f:	move.l	(a2),d0
	beq.s	.no
	cmp.l	a0,d0
	beq.s	.use
	lea	12(a2),a2
	bra.s	.f
.use:	move.l	(a2,d1.w),a1
	jsr	RmnImageUse
	tst.l	d0
	bra.s	.x
.no:	moveq	#0,d0
.x:	movem.l	(sp)+,d0-d1/a0-a2
	rts

; close the libraries (classic menu, or at the end)
bm_libs:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	move.l	4.w,a6
	lea	RmnGfx,a0
	moveq	#4-1,d1			; RmnGfx, RmnInt, RmnP96, RmnDisk
.l:	move.l	(a0),d0
	beq.s	.n
	clr.l	(a0)
	move.l	a0,-(sp)
	move.l	d0,a1
	jsr	-414(a6)		; CloseLibrary
	move.l	(sp)+,a0
.n:	addq.l	#4,a0
	dbf	d1,.l
	move.l	bm_chbase,d0		; chooser.gadget (the Scanline style)
	beq.s	.nc
	clr.l	bm_chbase
	move.l	d0,a1
	jsr	-414(a6)		; CloseLibrary
.nc:	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

; ---- Juan's DrawImage calls (hooks for JSR/JMP -114(A6), A6 = Intuition): A0 = RastPort, A1 =
; Image, D0 = x in the window, D1 = y in the window + the screen font's height (his convention).
; Big: the picture's redrawn (or scaled) copy at the scaled place inside the window's border; the
; 4:3 side borders drawn again (cheap); the menu strip's labels in one column (RmnMenuAlign).
bm_drawimage:
	tst.b	bm_on
	bne.s	.big
	jmp	-114(a6)		; DrawImage
.big:	movem.l	d0-d3/a0-a2,-(sp)
	move.l	MainMenuWnd,d0
	beq.s	.na
	move.l	d0,a0
	move.l	MainMenuMenus,d0
	beq.s	.na
	move.l	d0,a1
	jsr	RmnMenuAlign
.na:	movem.l	(sp),d0-d3/a0-a2	; Juan's arguments again
	tst.b	bm_lay			; the Joy type picture in the main window: the row moved down
	beq.s	.nj
	cmp.l	#DatsJoyTypePic,a1
	bne.s	.nj
	move.l	MainMenuWnd,d2
	beq.s	.nj
	move.l	d2,a2
	cmp.l	50(a2),a0		; wd_RPort
	bne.s	.nj
	add.w	#BM_DY,d1
.nj:
	IFD	AMG_BIGDBG
	cmp.l	#$10,bm_dbg
	bcc.s	.logd
	BMSTEP	$10
.logd:
	ENDC
	move.l	Scr,a0
	jsr	RmnBorders
	moveq	#0,d2
	move.b	36(a0),d2		; sc_WBorLeft = the window's BorderLeft
	moveq	#0,d3
	move.b	35(a0),d3		; sc_WBorTop
	add.w	bm_fy,d3
	addq.w	#1,d3			; the window's BorderTop (title bar)
	sub.w	d2,d0			; x inside the border
	sub.w	d3,d1			; y inside it: y + font = y + 8 at 1x, so y - 1 - WBorTop
	move.l	16(sp),a0		; the RastPort
	jsr	RmnDrawImage
	movem.l	(sp)+,d0-d3/a0-a2
	rts

; ---- after Juan's CloseDownScreen (hook in Quitar): the pictures, the font, the libraries
bm_exit:
	tst.b	bm_on
	beq.s	.x
	BMSTEP	$20
	jsr	RmnFreeAll
	bsr	bm_libs
	sf	bm_on
.x:	rts

; ---- PROGDIR:AmiMasterGear.config -> bm_classic ("Menu = Classic"), bm_scan ("Scanlines = On").
; No file, no line: the big menu, Scanlines Off.
bm_config:
	movem.l	d0-d4/a0-a2/a6,-(sp)
	sf	bm_classic
	sf	bm_scan
	bsr	bm_cfgread		; d3 = bytes in bm_buf
	ble	.x
	lea	bm_buf,a0
	clr.b	(a0,d3.l)		; the end
.line:	move.b	(a0),d0			; a line: blanks, the key, blanks, "=", blanks, the value
	beq	.x
	cmp.b	#" ",d0
	beq.s	.sk
	cmp.b	#9,d0
	bne.s	.key
.sk:	addq.l	#1,a0
	bra.s	.line
.key:	move.l	a0,a2
	lea	bm_kmenu(pc),a1
	bsr.s	.word
	beq.s	.k2
	move.b	(a0),d0			; "Classic"
	or.b	#$20,d0
	cmp.b	#"c",d0
	bne.s	.next
	st	bm_classic
	bra.s	.next
.k2:	move.l	a2,a0
	lea	bm_kscan(pc),a1
	bsr.s	.word
	beq.s	.next
	move.b	(a0),d0			; "On"
	or.b	#$20,d0
	cmp.b	#"o",d0
	bne.s	.next
	move.b	1(a0),d0
	or.b	#$20,d0
	cmp.b	#"n",d0
	bne.s	.next
	move.b	#1,bm_scan
.next:	move.b	(a0)+,d0		; to the next line
	beq.s	.x
	cmp.b	#10,d0
	bne.s	.next
	bra.s	.line
.x:	movem.l	(sp)+,d0-d4/a0-a2/a6
	rts
; A0 at a line's first word, A1 = a key -> NE: it is the key, A0 after "=" and blanks
.word:	move.b	(a1)+,d1
	beq.s	.wend
	or.b	#$20,d1
	move.b	(a0),d0
	or.b	#$20,d0
	cmp.b	d1,d0
	bne.s	.wno
	addq.l	#1,a0
	bra.s	.word
.wend:	bsr.s	.blank
	cmp.b	#"=",(a0)
	bne.s	.wno
	addq.l	#1,a0
	bsr.s	.blank
	moveq	#1,d0
	rts
.wno:	moveq	#0,d0
	rts
.blank:	cmp.b	#" ",(a0)
	beq.s	.b1
	cmp.b	#9,(a0)
	bne.s	.b2
.b1:	addq.l	#1,a0
	bra.s	.blank
.b2:	rts

; the config file into bm_buf -> D3 = its bytes (0: none, empty, or unreadable; -1: there but too
; big to hold or unreadable, leave it alone). No requesters (pr_WindowPtr -1). Keeps D0-D2/A0-A6.
bm_cfgread:
	movem.l	d0-d2/d4-d5/a0-a1/a5-a6,-(sp)
	bsr	bm_noreq
	moveq	#0,d5
	move.l	_DosBase,d0
	beq.s	.x
	move.l	d0,a6
	move.l	#bm_cfgn,d1
	move.l	#1005,d2		; MODE_OLDFILE
	jsr	-30(a6)			; Open
	move.l	d0,d4
	bne.s	.rd
	jsr	-132(a6)		; IoErr
	cmp.l	#205,d0			; ERROR_OBJECT_NOT_FOUND: no file, fine
	beq.s	.x
	moveq	#-1,d5
	bra.s	.x
.rd:	move.l	d4,d1
	move.l	#bm_buf,d2
	move.l	#BM_BUFSZ,d3
	jsr	-42(a6)			; Read
	move.l	d0,d5
	move.l	d4,d1
	jsr	-36(a6)			; Close
	cmp.l	#BM_BUFSZ,d5		; full: maybe more, too big
	bcs.s	.x
	moveq	#-1,d5
.x:	bsr	bm_req
	move.l	d5,d3
	movem.l	(sp)+,d0-d2/d4-d5/a0-a1/a5-a6
	rts

; ---- the line "<A3> = <A2>" (A2 a value with a blank first, " On") into PROGDIR:AmiMasterGear.config:
; the line with that key gets the new value, every other line is kept as it is; no such line: it
; is added at the end; no file: one is made. Keeps every register.
bm_cfgset:
	movem.l	d0-d7/a0-a6,-(sp)
	bsr	bm_cfgread		; d3 = bytes
	tst.l	d3
	bmi	.x
	move.l	d3,d5
	lea	bm_buf,a0		; copy, line by line; a0 in, a1 its end, a4 out, d6 = found
	lea	(a0,d5.l),a1
	lea	bm_out,a4
	moveq	#0,d6
.line:	cmp.l	a1,a0
	bcc.s	.end
	move.l	a0,a5			; the line
.bl:	cmp.l	a1,a5			; over blanks
	bcc.s	.copy
	cmp.b	#" ",(a5)
	beq.s	.bl1
	cmp.b	#9,(a5)
	bne.s	.key
.bl1:	addq.l	#1,a5
	bra.s	.bl
.key:	move.l	a3,a6			; the key, any case, a whole word
.k1:	move.b	(a6)+,d0
	beq.s	.kend
	cmp.l	a1,a5
	bcc.s	.copy
	move.b	(a5)+,d1
	eor.b	d0,d1
	and.b	#$df,d1
	bne.s	.copy
	bra.s	.k1
.kend:	cmp.l	a1,a5			; then blanks and "="
	bcc.s	.copy
	move.b	(a5)+,d0
	cmp.b	#" ",d0
	beq.s	.kend
	cmp.b	#9,d0
	beq.s	.kend
	cmp.b	#"=",d0
	bne.s	.copy
.eq:	move.b	(a0)+,(a4)+		; the line up to its "=", then the value
	cmp.l	a5,a0
	bcs.s	.eq
	bsr	.value
	moveq	#1,d6
.rest:	cmp.l	a1,a0			; the old value: to the end of the line
	bcc.s	.end
	cmp.b	#13,(a0)
	beq.s	.copy
	cmp.b	#10,(a0)
	beq.s	.copy
	addq.l	#1,a0
	bra.s	.rest
.copy:	cmp.l	a1,a0			; the rest of the line as it is, with its LF
	bcc.s	.end
	move.b	(a0)+,d0
	move.b	d0,(a4)+
	cmp.b	#10,d0
	bne.s	.copy
	bra.s	.line
.end:	tst.b	d6
	bne.s	.write
	lea	bm_out,a0		; none: add the line, after an LF if the file lacks one
	cmp.l	a0,a4
	beq.s	.add
	cmp.b	#10,-1(a4)
	beq.s	.add
	move.b	#10,(a4)+
.add:	move.l	a3,a0
.a1:	move.b	(a0)+,(a4)+
	bne.s	.a1
	subq.l	#1,a4
	move.b	#" ",(a4)+
	move.b	#"=",(a4)+
	bsr	.value
	move.b	#10,(a4)+
.write:	bsr	bm_noreq
	move.l	_DosBase,a6
	move.l	#bm_cfgn,d1
	move.l	#1006,d2		; MODE_NEWFILE
	jsr	-30(a6)
	move.l	d0,d4
	beq.s	.wx
	move.l	d4,d1
	move.l	#bm_out,d2
	move.l	a4,d3
	sub.l	d2,d3
	jsr	-48(a6)			; Write
	move.l	d4,d1
	jsr	-36(a6)			; Close
.wx:	bsr	bm_req
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts
.value:	move.l	a2,a6			; " On" / " Off"
.v1:	move.b	(a6)+,(a4)+
	bne.s	.v1
	subq.l	#1,a4
	rts

; no DOS requesters while the config is read or written (pr_WindowPtr -1), then as it was
bm_noreq:
	movem.l	d0-d1/a0-a1/a6,-(sp)
	sub.l	a1,a1
	move.l	4.w,a6
	jsr	-294(a6)		; FindTask
	move.l	d0,a0
	move.l	$b8(a0),bm_winptr	; pr_WindowPtr
	moveq	#-1,d0
	move.l	d0,$b8(a0)
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
bm_req:	movem.l	d0-d1/a0-a1/a6,-(sp)
	sub.l	a1,a1
	move.l	4.w,a6
	jsr	-294(a6)
	move.l	d0,a0
	move.l	bm_winptr,$b8(a0)
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

	IFD	AMG_BIGDBG
; test: PROGDIR:bigmenu.log = step, ModeID, width, height, depth, X, Y, font height (hex)
bm_dbgw:
	movem.l	d0-d7/a0-a6,-(sp)
	movem.l	bm_mode,d0-d3
	movem.l	d0-d3,bm_dbg+4
	move.l	RmnSXn,bm_dbg+4*5	; SXn, SXd
	move.l	RmnSYn,bm_dbg+4*6	; SYn, SYd
	moveq	#0,d0
	move.w	RmnFontH,d0
	move.l	d0,bm_dbg+4*7
	lea	bm_dbg,a0
	lea	bm_dbgt,a1
	moveq	#BM_DBGN-1,d2
.l:	move.l	(a0)+,d0
	moveq	#8-1,d1
.h:	rol.l	#4,d0
	move.b	d0,d3
	and.b	#15,d3
	add.b	#"0",d3
	cmp.b	#"9",d3
	bls.s	.d
	addq.b	#7,d3
.d:	move.b	d3,(a1)+
	dbf	d1,.h
	move.b	#" ",(a1)+
	dbf	d2,.l
	move.b	#10,-1(a1)
	move.l	_DosBase,a6
	move.l	#bm_dbgname,d1
	move.l	#1006,d2		; MODE_NEWFILE
	jsr	-30(a6)
	move.l	d0,d4
	beq.s	.x
	move.l	d4,d1
	move.l	#bm_dbgt,d2
	moveq	#BM_DBGN*9,d3
	jsr	-48(a6)			; Write
	move.l	d4,d1
	jsr	-36(a6)
.x:	movem.l	(sp)+,d0-d7/a0-a6
	rts
bm_dbgname:	dc.b	"PROGDIR:bigmenu.log",0
	even
	ENDC

bm_ngads:
	dc.l	MainMenuNGads,MainMenu_CNT+2,HelpPageNGads,HelpPage_CNT	; (+ Scanlines, Style)
	dc.l	MC68020NGads,MC68020_CNT,AskSaveBattNGads,AskSaveBatt_CNT
	dc.l	QuitNGads,Quit_CNT,CheatNGads,Cheat_CNT
	dc.l	ImpErrorNGads,ImpError_CNT,AboutNGads,About_CNT
	dc.l	PrefsNGads,Prefs_CNT,ClearNGads,Clear_CNT,0
bm_itexts:
	dc.l	MainMenuText0,HelpPageText0,MC68020Text0,AskSaveBattText0,QuitText0
	dc.l	CheatText0,ImpErrorText0,AboutText0,PrefsText0,ClearText0,0
bm_imgs:				; planar data, width, height, depth
	dc.l	GGLogo
	dc.w	325,51,3
	dc.l	GBTeclado
	dc.w	47,16,3
	dc.l	GBJoyStick
	dc.w	47,16,3
	dc.l	GBJoypad
	dc.w	47,16,3
	dc.l	GBCD32
	dc.w	47,16,3
	dc.l	0
bm_gfxn:	dc.b	"graphics.library",0
bm_intn:	dc.b	"intuition.library",0
bm_p96n:	dc.b	"Picasso96API.library",0
bm_pixn:	dc.b	"rmpixel.font",0	; the Pixel font, made at run time (never on disk)
bm_cfgn:	dc.b	"PROGDIR:AmiMasterGear.config",0
bm_kmenu:	dc.b	"Menu",0		; the config's words
bm_kscan:	dc.b	"Scanlines",0
bm_ksty:	dc.b	"ScanlineStyle",0
bm_von:		dc.b	" On",0
bm_voff:	dc.b	" Off",0
bm_w25:		dc.b	" 25",0		; the style words (Arnold's)
bm_w50:		dc.b	" 50",0
bm_w75:		dc.b	" 75",0
bm_wbl:		dc.b	" blendlight",0
bm_wbn:		dc.b	" blend",0
bm_wbs:		dc.b	" blendstrong",0
bm_chn:		dc.b	"gadgets/chooser.gadget",0
	even
	include	"rtgmenu.s"

	SECTION	AmgBigData,DATA
bm_on:		dc.b	0		; the menu is big
bm_classic:	dc.b	0		; "Menu = Classic"
bm_scan:	dc.b	0		; "Scanlines = On"
bm_style:	dc.b	1		; the Scanline style: 0-2 Hard 25/50/75%, 3-5 Blended light/-/strong
bm_lay:		dc.b	0		; the taller main window and the Scanlines selector are on
	even
bm_fy:		dc.w	8		; the menu font's height
bm_mmcnt:	dc.w	MainMenu_CNT	; the main window's gadgets GadToolsBox makes
	cnop	0,4
bm_mode:	dc.l	0,0,0,0		; ModeID, width, height, depth
bm_want:	dc.l	0		; the height asked: 1080, then 720
bm_winptr:	dc.l	0
	include	"rtgmenu_data.s"
	cnop	0,4
bm_pix36:	incbin	"data/rmfont_18x36.bin"	; rtg-framework tools/menufont.py (z00p)
	cnop	0,4
bm_pix24:	incbin	"data/rmfont_12x24.bin"
	cnop	0,4
bm_mk36:	incbin	"data/rmmark_18x36.bin"	; the menu's tick and Amiga key (menufont.py)
	cnop	0,4
bm_mk24:	incbin	"data/rmmark_12x24.bin"
bm_mtags:	dc.l	$80080031,0		; GTMN_TextAttr (Juan's)
	dc.l	$80080041,RmnChkImg	; GTMN_Checkmark
	dc.l	$80080042,RmnKeyImg	; GTMN_AmigaKey
	dc.l	0
bm_wtags:	dc.l	$80000093,0		; WA_NewLookMenus (Juan's)
	dc.l	$8000006D,RmnChkImg	; WA_Checkmark
	dc.l	$80000094,RmnKeyImg	; WA_AmigaKey
	dc.l	0
bm_scantags:	dc.l	$8008000E,bm_scanlab	; GTCY_Labels
	dc.l	$8008000F,0		; GTCY_Active (bm_layout, bm_gscan)
	dc.l	0
bm_scanlab:	dc.l	bm_toff,bm_ton,0
bm_stytags:	dc.l	$8008000E,bm_stylab	; GTCY_Labels (the cycle gadget without chooser.gadget)
	dc.l	$8008000F,1		; GTCY_Active (bm_layout, bm_gsty)
	dc.l	0
bm_stylab:	dc.l	bm_s25,bm_s50,bm_s75,bm_sbl,bm_sbn,bm_sbs,0
bm_chtags:	dc.l	$80030001,0		; GA_Left (bm_chpre)
	dc.l	$80030003,0		; GA_Top
	dc.l	$80030005,0		; GA_Width
	dc.l	$80030007,0		; GA_Height
	dc.l	$80030010,0		; GA_ID
	dc.l	$85001004,0		; CHOOSER_Labels
	dc.l	$85001005,0		; CHOOSER_Selected
	dc.l	$80030016,1		; GA_RelVerify
	dc.l	$80030028,topaz8	; GA_TextAttr (the menu's font)
	dc.l	$85001001,1		; CHOOSER_PopUp
	dc.l	$8500100D,1		; CHOOSER_Justification: centred, as the cycle gadgets
	dc.l	0
bm_cnatags:	dc.l	$85001501,0,0		; CNA_Text
bm_chbase:	dc.l	0		; chooser.gadget (closed by bm_libs)
bm_chobj:	dc.l	0		; the chooser while the main window is made
bm_chsel:	dc.l	0
bm_chlist:	dc.l	0,0,0		; its nodes (a List header)
	IFD	AMG_BIGTEST
bm_inport:	dc.l	0
bm_inreq:	dc.l	0
bm_inpix:	dc.l	0,0		; IEPointerPixel: screen, x, y
bm_inevt:	ds.b	22		; an InputEvent
bm_attxt:	dc.b	"@S 0 0",10,0
	ENDC
bm_scantext:	dc.b	"Scanlines",0	; the selectors' labels
bm_stytext:	dc.b	"Style",0
bm_toff:	dc.b	"Off",0
bm_ton:		dc.b	"On",0
bm_s25:		dc.b	"Hard 25%",0	; Arnold's settings (bar Off), his order
bm_s50:		dc.b	"Hard 50%",0
bm_s75:		dc.b	"Hard 75%",0
bm_sbl:		dc.b	"Blended light",0
bm_sbn:		dc.b	"Blended",0
bm_sbs:		dc.b	"Blended strong",0
	cnop	0,4
bm_hrtab:				; Juan's picture, its redraw at 1080, at 720
	dc.l	GGLogo,bm_hlogo1,bm_hlogo7
	dc.l	GBTeclado,bm_hkey1,bm_hkey7
	dc.l	GBJoyStick,bm_hstick1,bm_hstick7
	dc.l	GBJoypad,bm_hpad1,bm_hpad7
	dc.l	GBCD32,bm_hcd1,bm_hcd7
	dc.l	0
	cnop	0,4			; tools/bigmenu_art.py; rtg-framework tools/agbart (z00p)
bm_hlogo1:	incbin	"data/hires_amglogo_1080.bin"
bm_hkey1:	incbin	"data/hires_teclado_1080.bin"
bm_hstick1:	incbin	"data/hires_joystick_1080.bin"
bm_hpad1:	incbin	"data/hires_joypad_1080.bin"
bm_hcd1:	incbin	"data/hires_cd32_1080.bin"
bm_hlogo7:	incbin	"data/hires_amglogo_720.bin"
bm_hkey7:	incbin	"data/hires_teclado_720.bin"
bm_hstick7:	incbin	"data/hires_joystick_720.bin"
bm_hpad7:	incbin	"data/hires_joypad_720.bin"
bm_hcd7:	incbin	"data/hires_cd32_720.bin"
	even

	SECTION	AmgBigBss,BSS
	IFD	AMG_BIGDBG
bm_dbg:		ds.l	BM_DBGN
bm_dbgt:	ds.b	BM_DBGN*9
	ENDC
BM_BUFSZ	=2048
bm_buf:		ds.b	BM_BUFSZ+2
bm_out:		ds.b	BM_BUFSZ*2+64
	SECTION	AmgBigChip,BSS_C
BMK_BUFSZ	=1024			; the tick and Amiga key, 2 planes each (720 bytes at 1080)
bm_mkbuf:	ds.b	BMK_BUFSZ
