; kleines Werner-Spiel
; benötigt OS3 und AA-Chipsatz
; geschrieben von Patrick Klie

		include	"lvo/exec.i"
		include	"lvo/intuition.i"
		include	"lvo/graphics.i"
		include	"lvo/dos.i"
		include	"lvo/icon.i"
		include	"lvo/diskfont.i"

		include	"libraries/dos.i"
		include	"intuition/screens.i"
		include	"graphics/gfxbase.i"
		include	"exec/memory.i"
		include	"exec/nodes.i"
		include	"hardware/intbits.i"
		include	"workbench/workbench.i"
		include	"graphics/videocontrol.i"
		include	"startup2"

VersionString:	dc.b	"$VER: WernerAGA 1.0 (21.5.95)",0
		cnop	0,4

TRUE		equ	1
FALSE		equ	0
xsize:		equ	20
ysize:		equ	14
bpl		equ	xsize*ysize			; bytes per level
Depth		equ	4

begin:
		lea	SysBase(pc),a0
		move.l	4.w,(a0)
		lea	GFXName(pc),a1
		moveq	#39,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOOpenLibrary(a6)
		lea	GFXBase(pc),a0
		move.l	d0,(a0)
		beq	quit
		movea.l	d0,a0
		move.b	gb_ChipRevBits0(a0),d0
		and.b	#$f,d0				; AGA-Chipsatz
		cmp.b	#$f,d0
		bne	Close_GFX			; nicht: raus
Alloc_Signal:
		moveq	#-1,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOAllocSignal(a6)
		lea	SignalNum(pc),a0
		move.l	d0,(a0)
		beq	Close_GFX
		moveq	#0,d1
		bset	d0,d1
		lea	SignalMask(pc),a0
		move.l	d1,(a0)
CreateMsgPort1:				; fürs Double-Buffering (Safe-Mess.)
		movea.l	SysBase(pc),a6
		jsr	_LVOCreateMsgPort(a6)
		lea	MsgPort1(pc),a0
		move.l	d0,(a0)
		beq	Free_Signal
CreateMsgPort2:				; fürs Double-Buffering (Disp-Mess.)
		movea.l	SysBase(pc),a6
		jsr	_LVOCreateMsgPort(a6)
		lea	MsgPort2(pc),a0
		move.l	d0,(a0)
		beq	DeleteMsgPort1
Find_Task:
		suba.l	a1,a1
		movea.l	SysBase(pc),a6
		jsr	_LVOFindTask(a6)
		lea	MainTask(pc),a0
		move.l	d0,(a0)
		beq	DeleteMsgPort2		; eigentlich unnötig, aber
						; trotzdem zur Sicherheit
SetPri:
		movea.l	MainTask(pc),a1
		moveq	#127,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOSetTaskPri(a6)
Open_Int:
		lea	IntName(pc),a1
		moveq	#39,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOOpenLibrary(a6)
		lea	IntBase(pc),a0
		move.l	d0,(a0)
		beq	Free_Signal
Open_DOS:
		lea	DOSName(pc),a1
		moveq	#39,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOOpenLibrary(a6)
		lea	DOSBase(pc),a0
		move.l	d0,(a0)
		beq	Close_Int
Open_Icon:
		lea	IconName(pc),a1
		moveq	#39,d0
		jsr	_LVOOpenLibrary(a6)
		lea	IconBase(pc),a0
		move.l	d0,(a0)
		beq	Close_DOS
Open_Diskfont:
		lea	DiskfontName(pc),a1
		moveq	#39,d0
		jsr	_LVOOpenLibrary(a6)
		lea	DiskfontBase(pc),a0
		move.l	d0,(a0)
		beq	Close_Icon
Open_MEDPlayer:
		lea	MEDPlayerName(pc),a1
		moveq	#0,d0
		jsr	_LVOOpenLibrary(a6)
		lea	MEDPlayerBase(pc),a0
		move.l	d0,(a0)
		beq	Close_Diskfont
OpenWernerFont:
		lea	TextAttr1(pc),a0
		movea.l	DiskfontBase(pc),a6
		jsr	_LVOOpenDiskFont(a6)
		lea	TextFont1(pc),a0
		move.l	d0,(a0)
		beq	Close_MEDPlayer
OpenWernerFont2:
		movea.l	DiskfontBase(pc),a6
		lea	TextAttr2(pc),a0
		jsr	_LVOOpenDiskFont(a6)
		lea	TextFont2(pc),a0
		move.l	d0,(a0)
		beq	CloseWernerFont
GetCurrentDir:
		movea.l	DOSBase(pc),a6
		jsr	_LVOGetProgramDir(a6)
		move.l	d0,d1
		jsr	_LVOCurrentDir(a6)

		lea	altlock(pc),a0
		move.l	d0,(a0)
GetDiskObj:
		movea.l	IconBase(pc),a6
		lea	PrgName(pc),a0
		jsr	_LVOGetDiskObject(a6)
		lea	MyDiskObject(pc),a0
		move.l	d0,(a0)
		beq	Open_Screen
		movea.l	d0,a0
		lea	TTArray(pc),a1
		move.l	do_ToolTypes(a0),(a1)
FindTT:
		movea.l	TTArray(pc),a0
		lea	TypeName(pc),a1
		jsr	_LVOFindToolType(a6)
		tst.l	d0				; Tooltype vorhanden
		beq	Open_Screen			; wenn nicht -=>weiter
		movea.l	d0,a0
		lea	DirName+8(pc),a1
.Loop:
		move.b	(a0)+,(a1)+
		bne.s	.Loop
Lock:
		lea	DirName(pc),a0
		move.l	a0,d1
		moveq	#ACCESS_READ,d2
		movea.l	DOSBase(pc),a6
		jsr	_LVOLock(a6)
		lea	Lock1(pc),a0
		move.l	d0,(a0)
		beq	Open_Screen
wechsel:					; ins Level-Verz. gehen
		move.l	d0,d1
		jsr	_LVOCurrentDir(a6)
öffnen:
		lea	TypeName(pc),a0			; nun die Level laden
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	_LVOOpen(a6)
		lea	FileHandle1(pc),a0
		move.l	d0,(a0)
		beq.s	schließen
ExamineFH:
		move.l	d0,d1
		lea	FIB1(pc),a0
		move.l	a0,d2
		movea.l	DOSBase(pc),a6
		jsr	_LVOExamineFH(a6)
		tst.l	d0
		beq.s	Open_Screen
AllocVec:
		lea	FIB1(pc),a0
		move.l	fib_Size(a0),d0
		move.l	d0,-(sp)				;Größe merken
		move.l	#MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR,d1
		movea.l	SysBase(pc),a6
		jsr	_LVOAllocVec(a6)
		lea	mem1(pc),a0
		move.l	d0,(a0)
		beq.s	schließen
einlesen:
		move.l	FileHandle1(pc),d1
		move.l	mem1(pc),d2
		move.l	(sp)+,d3
		movea.l	DOSBase(pc),a6
		jsr	_LVORead(a6)
eintragen:
		divu	#bpl,d3
		lea	levelanzahl(pc),a0
		move.w	d3,(a0)
		lea	levelpointer(pc),a0
		move.l	mem1(pc),(a0)
schließen:
		move.l	FileHandle1(pc),d1
		movea.l	DOSBase(pc),a6
		jsr	_LVOClose(a6)
Open_Screen:
		suba.l	a0,a0
		lea	Screen_Tags(pc),a1
		movea.l	IntBase(pc),a6
		jsr	_LVOOpenScreenTagList(a6)
		lea	Screen1(pc),a0
		move.l	d0,(a0)
		beq	FreeDiskObj
		lea	Window_Tags+4(pc),a0
		move.l	d0,(a0)
		movea.l	d0,a0
		lea	sc_ViewPort(a0),a0
		lea	ViewPort1(pc),a1
		move.l	a0,(a1)
Open_Window:
		suba.l	a0,a0
		lea	Window_Tags(pc),a1
		jsr	_LVOOpenWindowTagList(a6)
		lea	Window1(pc),a0
		move.l	d0,(a0)
		beq	Close_Screen
		lea	RastPort1(pc),a1
		movea.l	d0,a0
		move.l	wd_RPort(a0),(a1)
		lea	Bitmap1(pc),a0
		movea.l	(a1),a1
		move.l	rp_BitMap(a1),(a0)

		move.l	Window1(pc),a0
		lea	UserPort1(pc),a1
		move.l	wd_UserPort(a0),(a1)
AllocBitMap:					; für die Figuren
		movea.l	GFXBase(pc),a6
		move.l	#320,d0
		moveq	#64,d1
		moveq	#Depth,d2
		move.l	#BMF_CLEAR|BMF_DISPLAYABLE|BMF_INTERLEAVED,d3
		movea.l	Bitmap1(pc),a0
		jsr	_LVOAllocBitMap(a6)
		lea	Bitmap2(pc),a0
		move.l	d0,(a0)
		beq	Close_Window
Alloc_BitMap2:					; fürs Double-Buffering
		movea.l	GFXBase(pc),a6
		move.l	#640+maxWidth+maxScrollSpeed,d0
		move.l	#512,d1
		moveq	#Depth,d2
		move.l	#BMF_CLEAR|BMF_DISPLAYABLE|BMF_INTERLEAVED,d3
		move.l	#BMF_CLEAR|BMF_DISPLAYABLE,d3
		suba.l	a0,a0
		movea.l	Bitmap1(pc),a0
		jsr	_LVOAllocBitMap(a6)
		lea	Bitmap3(pc),a0
		move.l	d0,(a0)
		beq	FreeBitmap
InitRP:
		movea.l	GFXBase(pc),a6
		movea.l	RastPort2(pc),a1
		jsr	_LVOInitRastPort(a6)
		movea.l	RastPort2(pc),a1
		move.l	Bitmap3(pc),rp_BitMap(a1)
InitTmpRas:
		movea.l	GFXBase(pc),a6
		lea	TmpRas1(pc),a0
		lea	Buffer1,a1
		move.l	#((640+maxScrollSpeed+maxWidth)*38)/8,d0
		jsr	_LVOInitTmpRas(a6)
		lea	TmpRas1(pc),a0
		movea.l	RastPort2(pc),a1
		move.l	a0,rp_TmpRas(a1)
AllocDBufInfo:
		movea.l	GFXBase(pc),a6
		movea.l	ViewPort1(pc),a0
		jsr	_LVOAllocDBufInfo(a6)
		lea	DBufInfo1(pc),a0
		move.l	d0,(a0)
		beq	FreeBitmap2
Set_Pointer:
		movea.l	Window1(pc),a0
		suba.l	a1,a1
		lea	Pointer1(pc),a1
		moveq	#1,d0
		moveq	#1,d1
		moveq	#0,d2
		moveq	#0,d3
		movea.l	IntBase(pc),a6
		jsr	_LVOSetPointer(a6)
DrawImages:
		movea.l	IntBase(pc),a6
		movea.l	RastPort1(pc),a0
		lea	Image1(pc),a1
		moveq	#0,d0
		moveq	#0,d1
		jsr	_LVODrawImage(a6)
CopyImages:
; kopiert Figuren in die Off-Screen-Bitmap
		movea.l	GFXBase(pc),a6
		movea.l	Bitmap1(pc),a0
		movea.l	Bitmap2(pc),a1
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		move.w	#320,d4
		moveq	#64,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)

		bsr	Title
unlock:
		move.l	Lock1(pc),d1
		movea.l	DOSBase(pc),a6
		jsr	_LVOUnLock(a6)
zurück:							; ins Ursprungs-verz
		move.l	altlock(pc),d1
		movea.l	DOSBase(pc),a6
		jsr	_LVOCurrentDir(a6)
Clear_Pointer:
		movea.l	Window1(pc),a0
		movea.l	IntBase(pc),a6
		jsr	_LVOClearPointer(a6)
FreeDBufInfo:
		movea.l	DBufInfo1(pc),a1
		movea.l	GFXBase(pc),a6
		jsr	_LVOFreeDBufInfo(a6)
FreeBitmap2:
		move.w	AnzVert(pc),d0
		beq.s	.weiter
		lea	Bitmap1(pc),a0
		lea	Bitmap3(pc),a1
		move.l	(a0),d0
		move.l	(a1),d1
		move.l	d0,(a1)
		move.l	d1,(a0)
.weiter:
		movea.l	GFXBase(pc),a6
		jsr	_LVOWaitBlit(a6)		; erst warten
		movea.l	Bitmap3(pc),a0
		jsr	_LVOFreeBitMap(a6)
FreeBitmap:
		movea.l	GFXBase(pc),a6
		jsr	_LVOWaitBlit(a6)		; erst warten
		movea.l	Bitmap2(pc),a0		; mit den Figuren
		jsr	_LVOFreeBitMap(a6)
Close_Window:
		movea.l	Window1(pc),a0
		movea.l	IntBase(pc),a6
		jsr	_LVOCloseWindow(a6)
Close_Screen:
		movea.l	Screen1(pc),a0
		movea.l	IntBase(pc),a6
		jsr	_LVOCloseScreen(a6)
Free_Vec:
		movea.l	SysBase(pc),a6
		move.l	mem1(pc),d0
		beq.s	FreeDiskObj
		movea.l	d0,a1
		jsr	_LVOFreeVec(a6)
FreeDiskObj:
		move.l	MyDiskObject(pc),d0
		beq	CloseWernerFont2
		movea.l	d0,a0
		movea.l	IconBase(pc),a6
		jsr	_LVOFreeDiskObject(a6)
CloseWernerFont2:
		movea.l	GFXBase(pc),a6
		movea.l	TextFont2(pc),a1
		jsr	_LVOCloseFont(a6)
CloseWernerFont:
		movea.l	GFXBase(pc),a6
		movea.l	TextFont1(pc),a1
		jsr	_LVOCloseFont(a6)
Close_MEDPlayer:
		movea.l	MEDPlayerBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
Close_Diskfont:
		movea.l	DiskfontBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
Close_Icon:
		movea.l	IconBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
Close_DOS:
		movea.l	DOSBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
Close_Int:
		movea.l	IntBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
SetPriback:
		movea.l	MainTask(pc),a1
		moveq	#0,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOSetTaskPri(a6)
DeleteMsgPort2:
; erstmal alle Nachrichten entfernen
		movea.l	SysBase(pc),a6
		movea.l	MsgPort2(pc),a0
		jsr	_LVODeleteMsgPort(a6)
DeleteMsgPort1:
		movea.l	SysBase(pc),a6
		movea.l	MsgPort1(pc),a0
		jsr	_LVODeleteMsgPort(a6)
Free_Signal:
		movea.l	SysBase(pc),a6
		move.l	SignalNum(pc),d0
		jsr	_LVOFreeSignal(a6)
Close_GFX:
		movea.l	GFXBase(pc),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOCloseLibrary(a6)
quit:
		moveq	#0,d0
		rts
;-----------------------------------------------------------------------------
AddIntServer1:
		lea	Zeitzähler(pc),a0
		move.w	#10,(a0)
		movea.l	SysBase(pc),a6
		moveq	#INTB_VERTB,d0
		lea	IntServer1(pc),a1
		jmp	_LVOAddIntServer(a6)
;-----------------------------------------------------------------------------
RemIntServer1:
		lea	VBL_Counter(pc),a0
		move.w	#5,(a0)
		movea.l	SysBase(pc),a6
		moveq	#INTB_VERTB,d0
		lea	IntServer1(pc),a1
		jmp	_LVORemIntServer(a6)
;-----------------------------------------------------------------------------
AddIntServer2:
		movea.l	SysBase(pc),a6
		moveq	#INTB_VERTB,d0
		lea	IntServer2(pc),a1
		jmp	_LVOAddIntServer(a6)
;-----------------------------------------------------------------------------
RemIntServer2:
		lea	VBL_Counter(pc),a0
		move.w	#5,(a0)
		movea.l	SysBase(pc),a6
		moveq	#INTB_VERTB,d0
		lea	IntServer2(pc),a1
		jmp	_LVORemIntServer(a6)
;-----------------------------------------------------------------------------
Title:
; das Titelbild anzeigen
maxScrollSpeed	equ	2	; maximale Scrollgeschw. in Pixel/(50*sec)
maxWidth	equ	38	; max. Breite eines Zeichens in Pixel

		bsr	Clear_Screens
		bsr	SetPropFont
		movea.l	IntBase(pc),a6
		movea.l	RastPort1(pc),a0
		lea	TitleImage1(pc),a1
		moveq	#0,d0
		moveq	#0,d1
		jsr	_LVODrawImage(a6)

		movea.l	GFXBase(pc),a6
		movea.l	Bitmap1(pc),a0
		movea.l	Bitmap3(pc),a1
		suba.l	a2,a2
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		move.w	#640+maxScrollSpeed+maxWidth,d4
		move.w	#512,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)	; Titel in 3.Bitmap kopieren

		movea.l	ViewPort1(pc),a0
		lea	ColorSpec3(pc),a1
		bsr	Fadein
assignmsgports:
; kreierte Message-Ports in dbi_Messi-Struktur eintragen
		movea.l	DBufInfo1(pc),a0
		lea	dbi_SafeMessage(a0),a1
		lea	dbi_DispMessage(a0),a2
		move.l	MsgPort1(pc),MN_REPLYPORT(a1)
		move.l	MsgPort2(pc),MN_REPLYPORT(a2)
		bsr	AddIntServer2
.Anfang:
		lea	.Offset(pc),a0
		clr.w	(a0)
		movea.l	GFXBase(pc),a6
		movea.l	TextFont2(pc),a5
		move.l	tf_CharSpace(a5),a5	; Charspace-Tabelle
		lea	Scrolltext(pc),a4
		move.l	#Scrolltext_end-Scrolltext,d6
		subq.l	#1,d6
.startscroll:
; erstmal die SafeMesssi abwarten
		move.w	SafeToWrite(pc),d0
		bne.s	.go_on
.Loop2:
		movea.l	MsgPort1(pc),a0
		movea.l	SysBase(pc),a6
		jsr	_LVOGetMsg(a6)
		tst.l	d0
		bne.s	.go_on
		moveq	#0,d0
		moveq	#0,d1
		movea.l	MsgPort1(pc),a0
		move.b	MP_SIGBIT(a0),d1
		bset	d1,d0
		jsr	_LVOWait(a6)
		bra.s	.Loop2
.go_on:
; alle übrigen Messis holen
;		movea.l	MsgPort1(pc),a0
;		movea.l	SysBase(pc),a6
;		jsr	_LVOGetMsg(a6)
;		tst.l	d0
;		bne.s	.go_on

		lea	SafeToWrite(pc),a0
		move.w	#TRUE,(a0)
		movea.l	RastPort2(pc),a1
		move.l	#640,d0
		add.w	.Offset(pc),d0
		move.w	#510,d1
		movea.l	GFXBase(pc),a6
		jsr	_LVOMove(a6)

		movea.l	RastPort2(pc),a1
		movea.l	a4,a0
		lea     .Char+1(pc),a2
		move.b	(a0),(a2)
		moveq	#1,d0
		jsr	_LVOText(a6)
		lea	1(a4),a4		; Pos um 1 inkrementieren
		moveq	#0,d7
		moveq	#0,d0
		move.w	.Char(pc),d0
		sub.w	#32,d0
		add.l	d0,d0		; Offset verdoppeln, da Word-Einträge
		moveq	#0,d7
		move.w	(a5,d0.l),d7
		divu	.ScrollSpeed(pc),d7
		swap	d7
		lea     .Offset(pc),a0
		move.w	d7,(a0)
		swap	d7
		and.l	#$ffff,d7
		subq.l	#1,d7

.Hauptloop:
		move.w	SafeToWrite(pc),d0
		bne.s	.weiter
.Loop:
		movea.l	MsgPort1(pc),a0		; für Safe-Message
		movea.l	SysBase(pc),a6
		jsr	_LVOGetMsg(a6)
		tst.l	d0
		bne.s	.weiter
		moveq	#0,d0
		moveq	#0,d1
		movea.l	MsgPort1(pc),a0
		move.b	MP_SIGBIT(a0),d1
		bset	d1,d0
		jsr	_LVOWait(a6)
		bra.s	.Loop
.weiter:
; alle übrigen Messis holen
;		movea.l	MsgPort1(pc),a0
;		movea.l	SysBase(pc),a6
;		jsr	_LVOGetMsg(a6)
;		tst.l	d0
;		bne.s	.weiter

		lea	SafeToWrite(pc),a0
		move.w	#TRUE,(a0)

;		movea.l	RastPort2(pc),a1
;		moveq	#0,d0
;		move.w	.ScrollSpeed(pc),d0
;		moveq	#0,d1
;		move.l	d0,d2
;		moveq	#0,d3
;		move.w	#474,d3
;		moveq	#0,d4
;		move.w	#640+maxScrollSpeed+maxWidth,d4
;		moveq	#0,d5
;		move.w	#512,d5
;		movea.l	GFXBase(pc),a6
;		jsr	_LVOScrollRaster(a6)

		move.w	.ScrollSpeed(pc),d0
		move.w	#474,d1
		moveq	#0,d2
		move.w	d1,d3
		move.w	#640+maxScrollSpeed+maxWidth,d4 ; Breite
		sub.w	.ScrollSpeed(pc),d4
		moveq	#38,d5
		movem.l	d6/d7,-(sp)
		move.b	#$c0,d6
		moveq	#-1,d7
		movea.l	Bitmap3(pc),a0
		movea.l	a0,a1
		suba.l	a2,a2
		movea.l	GFXBase(pc),a6
		jsr	_LVOBltBitMap(a6)	; nach links scrollen

		move.w	SafeToChange(pc),d0
		bne.s	.weiter2
.hervorholen:					; off-Screen-Bitmap anzeigen
		movea.l	SysBase(pc),a6
		movea.l	MsgPort2(pc),a0		; für Safe-Message
		jsr	_LVOGetMsg(a6)
		tst.l	d0
		bne.s	.weiter2
		moveq	#0,d0
		moveq	#0,d1
		movea.l	MsgPort2(pc),a0
		move.b	MP_SIGBIT(a0),d1
		bset	d1,d0
		jsr	_LVOWait(a6)
		bra.s	.hervorholen
.weiter2:
		movea.l	SysBase(pc),a6
		movea.l	MsgPort2(pc),a0
		jsr	_LVOGetMsg(a6)
		tst.l	d0
		bne.s	.weiter2

		lea	SafeToChange(pc),a0
		move.w	#TRUE,(a0)

		movea.l	GFXBase(pc),a6
		jsr	_LVOWaitBlit(a6)
;		move.l	SignalMask(pc),d0
;		movea.l	SysBase(pc),a6
;		jsr	_LVOWait(a6)
;		movea.l	GFXBase(pc),a6
;		jsr	_LVOWaitTOF(a6)

		movea.l	ViewPort1(pc),a0
		movea.l	Bitmap3(pc),a1
		movea.l	DBufInfo1(pc),a2
		movea.l	GFXBase(pc),a6
		jsr	_LVOChangeVPBitMap(a6)
		jsr	_LVOWaitBlit(a6)
		lea	AnzVert(pc),a0
		not.w	(a0)
		lea	SafeToChange(pc),a0
		move.w	#FALSE,(a0)
		lea	SafeToWrite(pc),a0
		move.w	#FALSE,(a0)
.tauschen:
		lea	Bitmap1(pc),a0
		lea	Bitmap3(pc),a1
		move.l	(a0),d0
		move.l	(a1),d1
		move.l	d0,(a1)
		move.l	d1,(a0)
		lea	RastPort1(pc),a0
		lea	RastPort2(pc),a1
		move.l	(a0),d0
		move.l	(a1),d1
		move.l	d0,(a1)
		move.l	d1,(a0)
.rüberkopieren:
		movea.l	GFXBase(pc),a6
		jsr	_LVOWaitBlit(a6)
;		movea.l	Bitmap1(pc),a0
;		movea.l	Bitmap3(pc),a1
;		suba.l	a2,a2
;		moveq	#0,d0
;		move.w	#474,d1
;		moveq	#0,d2
;		move.w	d1,d3
;		move.w	#640+maxWidth+maxScrollSpeed,d4
;		moveq	#38,d5
;		move.b	#$c0,d6
;		moveq	#-1,d7
;		movea.l	GFXBase(pc),a6
;		jsr	_LVOBltBitMap(a6)

		movea.l	Bitmap1(pc),a0
		movea.l	Bitmap3(pc),a1
		movea.l	bm_Planes(a0),a0
		movea.l	bm_Planes(a1),a1
		add.l	#((640+maxWidth+maxScrollSpeed)/8)*Depth*474,a0
		add.l	#((640+maxWidth+maxScrollSpeed)/8)*Depth*474,a1

		move.l	#Depth*55*((640+maxWidth+maxScrollSpeed))/8,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOCopyMemQuick(a6)

		movem.l	(sp)+,d6/d7

		btst	#7,$bfe001
		beq	.raus
		dbra	d7,.Hauptloop
		dbra	d6,.startscroll
.raus:
		bsr	RemIntServer2

		bsr	WaitforButton
		movea.l	ViewPort1(pc),a0
		bsr	Fadeout
		bsr	SetMSFont	; wieder den monospaced Font setzen
		bra.s	Main

.Char:		ds.w	1		; ASCII-Code des aktuellen Zeichens
.ScrollSpeed:	dc.w	2
.Offset:	dc.w	0
AnzVert:	dc.w	0		; bei jedem ChangeVPBitMap-Aufruf
					; Wechsel von 0 nach -1 und umgekehrt
					; wenn AnzVert=0, dann gibt Free-
					; bitmap3 den richtigen Speicher frei
					; sonst Inhalt von Bitmap1 und Bitmap3
					; tauschen
SafeToWrite:	dc.w	TRUE
SafeToChange:	dc.w	TRUE
		cnop	0,4
;-----------------------------------------------------------------------------
Main:
; jetzt beginnt das eigentliche Spiel
		bsr	CopyLevel
		bsr	Clear_Screens
		bsr	Darstellen
		bsr	PrintTexts
		movea.l	ViewPort1(pc),a0
		lea	ColorSpec1(pc),a1
		bsr	Fadein
		bsr	WaitforButton
		bsr	AddIntServer1

Spiel:
		lea	Zähler2(pc),a5
		clr.w	(a5)
		lea	Puffer(pc),a4

		movea.l	SysBase(pc),a6
		movea.l	UserPort1(pc),a0
		jsr	_LVOGetMsg(a6)
		tst.l	d0
		beq.s	.weiter
		movea.l	d0,a1
		move.l	im_Class(a1),d6
		move.w	im_Code(a1),d7
		jsr	_LVOReplyMsg(a6)
.prüf1:
		cmpi.l	#IDCMP_VANILLAKEY,d6
		bne.s	.weiter
		cmpi.b	#" ",d7			; Space gedrückt?
		beq	Tot
.prüf2:
		cmpi.b	#27,d7			; Esc gedrückt
		bne.s	.prüf3
		bra	Game_over2
.prüf3:
		cmpi.b	#13,d7			; Return gedrückt?
		beq	gepackt
.weiter:

		move.l	SignalMask(pc),d0
		jsr	_LVOWait(a6)

		movea.l	GFXBase(pc),a6
Loop:
		bsr	TestJoy
		cmp.b	#"s",(a4)
		beq	WorkonStone
		cmp.b	#"x",(a4)
		beq	WorkonfallingStone
		cmp.b	#"b",(a4)
		beq	WorkonBullup
		cmp.b	#"r",(a4)
		beq	WorkonBullright
		cmp.b	#"u",(a4)
		beq	WorkonBulldown
		cmp.b	#"l",(a4)
		beq	WorkonBullleft
weiter:
		lea	1(a4),a4
		addq.w	#1,(a5)
		cmp.w	#bpl,(a5)
                bne	Loop
		bsr	Korrigieren
		bsr	TestJoy
		bra	WorkonWerner
prüfzeit:
		lea	Zeitzähler(pc),a0
		subq.w	#1,(a0)
		bne.s	.weiter
.decrtime:
		move.w	#10,(a0)
		lea	time(pc),a0
		subq.w	#1,(a0)
		beq	Tot

		bsr	PrintTime
.weiter:
		bra	Spiel
.raus:
		bsr	RemIntServer1
		rts
Korrigieren:
; wandelt "n" in "u" und "y" in "x" um
		move.l	#bpl-1,d7
.Loop:
		cmp.b	#"n",(a4)
		bne.s	.weiter
		move.b	#"u",(a4)
.weiter:
		cmp.b	#"y",(a4)
		bne.s	.weiter2
		move.b	#"x",(a4)
.weiter2:
		lea	-1(a4),a4
		dbra	d7,.Loop
.raus:
		rts
WorkonStone:
		cmp.b	#" ",20(a4)			; leer darunter?
		bne	.prüfe_weiter
; der Stein kann fallen
		move.b	#" ",(a4)
		move.b	#"y",20(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		move.w	d0,d2
		move.w	d1,d3
		addq.w	#1,d3				; einen tiefer
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)	; Stein darunter zeichnen
		bra	.raus

.prüfe_weiter:				; etwas liegt unter dem Stein
		cmp.b	#"s",20(a4)	; ein Stein?
		bne	.raus		; kein Stein->raus

.prüfe_rechts:				; ist es rechts leer?
		cmp.b	#" ",1(a4)
		bne.s	.prüfe_links
.prüfe_untenrechts:
		cmp.b	#" ",21(a4)
		bne.s	.prüfe_links
.falle_untenrechts:
		move.b	#" ",(a4)
		move.b	#"y",21(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		addq.w	#1,d0
		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra.s	.raus
.prüfe_links:
		cmp.b	#" ",-1(a4)
		bne.s	.raus
.prüfe_untenlinks:
		cmp.b	#" ",19(a4)
		bne.s	.raus
.falle_untenlinks:
		move.b	#" ",(a4)
		move.b	#"y",19(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		subq.w	#1,d0
		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
.raus:
		bra	weiter
WorkonfallingStone:
		cmp.b	#"w",20(a4)			; Werner darunter
		beq     Tot
		cmp.b	#" ",20(a4)			; leer darunter?
		bne	.prüfe_weiter
; der Stein kann fallen
		move.b	#" ",(a4)
		move.b	#"y",20(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		move.w	d0,d2
		move.w	d1,d3
		addq.w	#1,d3				; einen tiefer
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)	; Stein darunter zeichnen
		bra	.raus

.prüfe_weiter:				; etwas liegt unter dem Stein
		cmp.b	#"s",20(a4)	; ein Stein?
		bne	.wandeln		; kein Stein->raus

.prüfe_rechts:				; ist es rechts leer?
		cmp.b	#" ",1(a4)
		bne.s	.prüfe_links
.prüfe_untenrechts:
		cmp.b	#" ",21(a4)
		bne.s	.prüfe_links
.falle_untenrechts:
		move.b	#" ",(a4)
		move.b	#"y",21(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		addq.w	#1,d0
		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.raus
.prüfe_links:
		cmp.b	#" ",-1(a4)
		bne.s	.wandeln
.prüfe_untenlinks:
		cmp.b	#" ",19(a4)
		bne.s	.wandeln
.falle_untenlinks:
		move.b	#" ",(a4)
		move.b	#"y",19(a4)
		move.w	(a5),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2
		lsl.w	#5,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; Stelle löschen

		movem.w	(sp)+,d0-d1
		subq.w	#1,d0
		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#32,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra.s	.raus
.wandeln:
; fallenden Stein in ruhenden Stein umwandeln
		move.b	#"s",(a4)
.raus:
		bra	weiter
WorkonBullup:
		cmp.b	#"w",-20(a4)
		beq	Tot
		cmp.b	#" ",-20(a4)
		bne	.prüfe_rechts
.hoch:
		bsr	Bulle_hoch
		bra	.raus
.prüfe_rechts:
		cmp.b	#"w",1(a4)
		beq	Tot
		cmp.b	#" ",1(a4)
		bne	.prüfe_links
.rechts:
		bsr	Bulle_rechts
		bra	.raus
.prüfe_links:
		cmp.b	#"w",-1(a4)
		beq	Tot
		cmp.b	#" ",-1(a4)
		bne	.prüfe_unten
.links:
		bsr	Bulle_links
		bra.s	.raus
.prüfe_unten:
		cmp.b	#"w",20(a4)
		beq	Tot
		cmp.b	#" ",20(a4)
		bne.s	.raus
.runter:
		bsr	Bulle_runter
.raus:
		bra	weiter
WorkonBullright:
		cmp.b	#"w",1(a4)
		beq	Tot
		cmp.b	#" ",1(a4)
		bne.s	.prüfe_unten
.rechts:
		bsr	Bulle_rechts
		bra.s	.raus
.prüfe_unten:
		cmp.b	#"w",20(a4)
		beq	Tot
		cmp.b	#" ",20(a4)
		bne.s	.prüfe_oben
.runter:
		bsr	Bulle_runter
		bra	.raus
.prüfe_oben:
		cmp.b	#"w",-20(a4)
		beq	Tot
		cmp.b	#" ",-20(a4)
		bne.s	.prüfe_links
.hoch:
		bsr	Bulle_hoch
		bra.s	.raus
.prüfe_links:
		cmp.b	#"w",-1(a4)
		beq	Tot
		cmp.b	#" ",-1(a4)
		bne.s	.raus
.links:
		bsr	Bulle_links
.raus:
		bra	weiter
WorkonBulldown:
		cmp.b	#"w",20(a4)
		beq	Tot
		cmp.b	#" ",20(a4)
		bne.s	.prüfe_links
.runter:
		bsr	Bulle_runter
		bra	.raus
.prüfe_links:
		cmp.b	#"w",-1(a4)
		beq	Tot
		cmp.b	#" ",-1(a4)
		bne.s	.prüfe_rechts
.links:
		bsr	Bulle_links
		bra	.raus
.prüfe_rechts:
		cmp.b	#"w",1(a4)
		beq	Tot
		cmp.b	#" ",1(a4)
		bne.s	.prüfe_oben
.rechts:
		bsr	Bulle_rechts
		bra.s	.raus
.prüfe_oben:
		cmp.b	#"w",-20(a4)
		beq	Tot
		cmp.b	#" ",-20(a4)
		bne.s	.raus
.hoch:
		bsr	Bulle_hoch
.raus:
		bra	weiter
WorkonBullleft:
		cmp.b	#"w",-1(a4)
		beq	Tot
		cmp.b	#" ",-1(a4)
		bne.s	.prüfe_oben
.links:
		bsr	Bulle_links
		bra	.raus
.prüfe_oben:
		cmp.b	#"w",-20(a4)
		beq	Tot
		cmp.b	#" ",-20(a4)
		bne.s	.prüfe_unten
.hoch:
		bsr	Bulle_hoch
		bra	.raus
.prüfe_unten:
		cmp.b	#"w",20(a4)
		beq	Tot
		cmp.b	#" ",20(a4)
		bne	.prüfe_rechts
.runter:
		bsr	Bulle_runter
		bra	.raus
.prüfe_rechts:
		cmp.b	#"w",1(a4)
		beq	Tot
		cmp.b	#" ",1(a4)
		bne	.raus
.rechts:
		bsr	Bulle_rechts
.raus:
		bra	weiter

Zähler2:	ds.w	1
Bulle_hoch:
		move.b	#" ",(a4)
		move.b	#"b",-20(a4)
		move.w	Zähler2(pc),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)		; akt. Stelle löschen

		movem.w	(sp)+,d0-d1
		subq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#256,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jmp	_LVOBltBitMap(a6)
Bulle_rechts:
		move.b	#" ",(a4)
		move.b	#"r",1(a4)
		move.w	Zähler2(pc),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)

		movem.w	(sp)+,d0-d1
		addq.w	#1,d0
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#288,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		lea	1(a4),a4		; rechts daneben überspringen
		addq.w	#1,(a5)
		rts
Bulle_runter:
		move.b	#" ",(a4)
		move.b	#"n",20(a4)
		move.w	Zähler2(pc),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)

		movem.w	(sp)+,d0-d1
		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#0,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jmp	_LVOBltBitMap(a6)
Bulle_links:
		move.b	#" ",(a4)
		move.b	#"l",-1(a4)
		move.w	Zähler2(pc),d0
		bsr	Offset2Coords
		movem.w	d0-d1,-(sp)
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)

		movem.w	(sp)+,d0-d1
		subq.w	#1,d0
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#32,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jmp	_LVOBltBitMap(a6)
;-----------------------------------------------------------------------------
WorkonWerner:
		lea	Puffer(pc),a0
		moveq	#-1,d0
.Loop:
		addq.l	#1,d0
		cmp.b	#"w",(a0)+
		beq.s	.weiter
		bra.s	.Loop
.weiter:
		lea	-1(a0),a0			; korrigieren
		bsr	Offset2Coords

		move.w	Joystick(pc),d2
		btst	#1,d2
		bne.s	Werner_right
		btst	#3,d2
		bne	Werner_left
		btst	#0,d2
		bne	Werner_up
		btst	#2,d2
		bne	Werner_down
		bra	undwech
Werner_right:
		cmp.b	#"f",1(a0)
		beq	gepackt
		cmp.b	#"b",1(a0)
		beq	Tot
		cmp.b	#"r",1(a0)
		beq	Tot
		cmp.b	#"u",1(a0)
		beq	Tot
		cmp.b	#"l",1(a0)
		beq	Tot
		cmp.b	#" ",1(a0)
		beq.s	.bewege
		cmp.b	#"d",1(a0)
		beq.s	.bewege
		btst	#0,d2
		bne	Werner_up
		btst	#2,d2
		bne	Werner_down
		bra	undwech
.bewege:
		move.b	#" ",(a0)
		move.b	#"w",1(a0)
		bsr	Werner_löschen

		addq.w	#1,d0
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#160,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	undwech
Werner_left:
		cmp.b	#"f",-1(a0)
		beq	gepackt
		cmp.b	#"b",-1(a0)
		beq	Tot
		cmp.b	#"r",-1(a0)
		beq	Tot
		cmp.b	#"u",-1(a0)			; rennt er gegen
		beq	Tot				; einen Bullen?
		cmp.b	#"l",-1(a0)
		beq	Tot
		cmp.b	#" ",-1(a0)
		beq.s	.bewege
		cmp.b	#"d",-1(a0)
		beq.s	.bewege
		btst	#0,d2
		bne.s	Werner_up
		btst	#2,d2
		bne	Werner_down
		bra	undwech
.bewege:
		move.b	#" ",(a0)
		move.b	#"w",-1(a0)
		bsr	Werner_löschen

		subq.w	#1,d0
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#224,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	undwech
Werner_up:
		cmp.b	#"f",-20(a0)
		beq	gepackt
		cmp.b	#"b",-20(a0)
		beq	Tot
		cmp.b	#"r",-20(a0)
		beq	Tot
		cmp.b	#"u",-20(a0)			; rennt er gegen
		beq	Tot				; einen Bullen?
		cmp.b	#"l",-20(a0)
		beq	Tot
		cmp.b	#" ",-20(a0)
		beq.s	.bewege
		cmp.b	#"d",-20(a0)
		beq.s	.bewege
		bra	undwech
.bewege:
		move.b	#" ",(a0)
		move.b	#"w",-20(a0)
		bsr	Werner_löschen

		subq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#128,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra.s	undwech
Werner_down:
		cmp.b	#"f",20(a0)
		beq	gepackt
		cmp.b	#"b",20(a0)
		beq	Tot
		cmp.b	#"r",20(a0)
		beq	Tot
		cmp.b	#"u",20(a0)			; rennt er gegen
		beq	Tot				; einen Bullen?
		cmp.b	#"l",20(a0)
		beq	Tot
		cmp.b	#" ",20(a0)
		beq.s	.bewege
		cmp.b	#"d",20(a0)
		beq.s	.bewege
		bra.s	undwech
.bewege:
		move.b	#" ",(a0)
		move.b	#"w",20(a0)
		bsr	Werner_löschen

		addq.w	#1,d1
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		move.w	#192,d0
		moveq	#0,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
undwech:
		bra	prüfzeit
Werner_löschen:
		movem.w	d0/d1,-(sp)			; Coords retten
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#64,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		movea.l	GFXBase(pc),a6
		jsr	_LVOBltBitMap(a6)

		movem.w	(sp)+,d0/d1			; -> Coords
		rts
;-----------------------------------------------------------------------------
Tot:
; leider gestorben
		bsr	RemIntServer1
		lea	Puffer(pc),a0
		move.w	#-1,d0
.Loop:
		addq.w	#1,d0
		cmp.b	#"w",(a0)+
		beq.s	.weiter
		bra.s	.Loop
.weiter:
		bsr	Offset2Coords
		lsl.w	#5,d0
		lsl.w	#5,d1
		move.w	d0,d2
		move.w	d1,d3
		moveq	#96,d0
		moveq	#32,d1
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2
		moveq	#32,d4
		moveq	#32,d5
		move.b	#$c0,d6
		moveq	#-1,d7
		movea.l	GFXBase(pc),a6
		jsr	_LVOBltBitMap(a6)
		lea	lives(pc),a0
		subq.w	#1,(a0)
		beq.s	Game_over
		lea	time(pc),a0
		move.w	#120,(a0)
		movea.l	DOSBase(pc),a6
		move.l	#50*1,d1
		jsr	_LVODelay(a6)
		movea.l	ViewPort1(pc),a0
		bsr	Fadeout
		bsr	Clear_Screens
		bra	Main
;-----------------------------------------------------------------------------
Game_over2:
		bsr	RemIntServer1
Game_over:
; alle Leben verbraucht
		movea.l	ViewPort1(pc),a0
		bsr	Fadeout
		bsr	Clear_Screens
		lea	lives(pc),a0
		move.w	#10,(a0)
		lea	levelnumber(pc),a0
		move.w	#0,(a0)
		rts
;-----------------------------------------------------------------------------
gepackt:
; Level geschafft
		bsr	RemIntServer1
.ringring:
		lea	score(pc),a0
		lea	time(pc),a1
		subq.w	#1,(a1)
		bmi	.weiter
		addq.w	#1,(a0)
		bsr	PrintScore
		bsr	PrintTime
		bra.s	.ringring
.weiter:
		movea.l	ViewPort1(pc),a0
		bsr	Fadeout
		bsr	Clear_Screens
		lea	time(pc),a0
		move.w	#120,(a0)
		lea	lives(pc),a0
		addq.w	#1,(a0)
		lea	levelnumber(pc),a0
		addq.w	#1,(a0)
		move.w	levelanzahl(pc),d0
		subq.w	#1,d0
		move.w	(a0),d1
		cmp.w	d0,d1
		bgt	fertig
		bra	Main
;-----------------------------------------------------------------------------
fertig:
; Spiel gepackt
		movea.l	DOSBase(pc),a6
		move.l	#1*50,d1
		jsr	_LVODelay(a6)
		movea.l	ViewPort1(pc),a0
		bsr	Fadeout
		lea	lives(pc),a0
		move.w	#10,(a0)
		lea	levelnumber(pc),a0
		move.w	#0,(a0)
		rts				; und beenden
;-----------------------------------------------------------------------------
CopyLevel:
		movea.l	SysBase(pc),a6
		movea.l	levelpointer(pc),a0
		move.w	levelnumber(pc),d0
		move.w	#bpl,d1
		mulu	d0,d1
		add.w	d1,a0
		lea	Puffer(pc),a1
		move.l	#bpl,d0
		jmp	_LVOCopyMemQuick(a6)
;-----------------------------------------------------------------------------
SetPropFont:
; proportionalen Font in beiden RastPorts setzen
		movea.l	GFXBase(pc),a6
		movea.l	TextFont2(pc),a0
		movea.l	RastPort2(pc),a1
		jsr	_LVOSetFont(a6)
		movea.l	TextFont2(pc),a0
		movea.l	RastPort1(pc),a1
		jmp	_LVOSetFont(a6)
;-----------------------------------------------------------------------------
SetMSFont:
; monospaced Font in beiden RastPorts setzen
		movea.l	GFXBase(pc),a6
		movea.l	TextFont1(pc),a0
		movea.l	RastPort1(pc),a1
		jsr	_LVOSetFont(a6)
		movea.l	TextFont1(pc),a0
		movea.l	RastPort2(pc),a1
		jmp	_LVOSetFont(a6)
;-----------------------------------------------------------------------------
Clear_Screens:
		movea.l	GFXBase(pc),a6
		moveq	#0,d0
		movea.l	RastPort1(pc),a1
		jsr	_LVOSetRast(a6)

		moveq	#0,d0
		movea.l	RastPort2(pc),a1
		jmp	_LVOSetRast(a6)
;-----------------------------------------------------------------------------
Darstellen:
; zeigt den Level
		lea	.Zähler(pc),a5
		clr.w	(a5)
		movea.l	GFXBase(pc),a6
		lea	Puffer(pc),a4
.Loop:
		cmp.b	#"m",(a4)
		beq.s	.ZeichneMauer
		cmp.b	#"s",(a4)
		beq	.ZeichneStein
		cmp.b	#"d",(a4)
		beq	.ZeichneDreck
		cmp.b	#"f",(a4)
		beq	.ZeichneFlasche
		cmp.b	#"w",(a4)
		beq	.ZeichneWerner
		cmp.b	#"b",(a4)
		beq	.ZeichneBullehoch
		cmp.b	#"r",(a4)
		beq	.ZeichneBullerechts
		cmp.b	#"u",(a4)
		beq	.ZeichneBullerunter
		cmp.b	#"l",(a4)
		beq	.ZeichneBullelinks
.weiter:
		lea	1(a4),a4
		addq.w	#1,(a5)
		cmp.w	#bpl,(a5)
		bne	.Loop
.raus:
		rts
.ZeichneMauer:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#0,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra.s	.weiter
.ZeichneStein:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#32,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra.s	.weiter
.ZeichneDreck:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#64,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter
.ZeichneFlasche:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#96,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter
.ZeichneWerner:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		move.w	#192,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter
.ZeichneBullehoch:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		move.w	#256,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter
.ZeichneBullerechts:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		move.w	#288,d0			; SrcX
		moveq	#0,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter

.ZeichneBullerunter:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#0,d0			; SrcX
		moveq	#32,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter

.ZeichneBullelinks:
		move.w	(a5),d0
		and.l	#$ffff,d0
		bsr	Offset2Coords
		move.w	d0,d2
		move.w	d1,d3
		lsl.w	#5,d2			; DestX
		lsl.w	#5,d3			; DestY
		moveq	#32,d0			; SrcX
		moveq	#32,d1			; SrcY
		movea.l	Bitmap2(pc),a0
		movea.l	Bitmap1(pc),a1
		suba.l	a2,a2			; TempRastPort
		moveq	#32,d4			; SizeX
		moveq	#32,d5			; SizeY
		move.b	#$c0,d6			; MinTerm
		moveq	#-1,d7
		jsr	_LVOBltBitMap(a6)
		bra	.weiter

.Zähler:	dc.w	0
		cnop	0,4
;-----------------------------------------------------------------------------
PrintTexts:
; schreibt alle Texte
		bsr	PrintScoretext
		bsr	PrintScore
		bsr	PrintTimetext
		bsr	PrintTime
		bsr	PrintLivestext
		bsr	PrintLives
		bsr	PrintLeveltext
		bsr	PrintLevel
		rts
;-----------------------------------------------------------------------------
String:		dc.b	"     "
		dc.b    "   "				; nur Füllbytes
ClearString:
		lea	String(pc),a0
		move.l	#"    ",(a0)
		move.l	#"    ",4(a0)
		rts
PrintScoretext:
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		moveq	#0,d0
		move.w	#479,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	Scorestring(pc),a0
		moveq	#6,d0
		jmp	_LVOText(a6)
;-----------------------------------------------------------------------------
PrintScore:
		move.w	score(pc),d2
		andi.l	#$ffff,d2
		lea	String(pc),a0
		bsr	decl
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#192,d0
		move.w	#479,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	String(pc),a0
		moveq	#5,d0
		jsr	_LVOText(a6)
		bra	ClearString
;-----------------------------------------------------------------------------
PrintTimetext:
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#352,d0
		move.w	#479,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	Timestring(pc),a0
		moveq	#6,d0
		jmp	_LVOText(a6)
;-----------------------------------------------------------------------------
PrintTime:
		move.w	time(pc),d2
		andi.l	#$ffff,d2
		lea	String(pc),a0
		bsr	decl
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#544,d0
		move.w	#479,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	String+2(pc),a0
		moveq	#3,d0
		jsr	_LVOText(a6)
		bra	ClearString
;-----------------------------------------------------------------------------
PrintLivestext:
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		moveq	#0,d0
		move.w	#511,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	Livesstring(pc),a0
		moveq	#6,d0
		jmp	_LVOText(a6)
;-----------------------------------------------------------------------------
PrintLives:
		move.w	lives(pc),d2
		andi.l	#$ffff,d2
		lea	String(pc),a0
		bsr	decl
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#192,d0
		move.w	#511,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	String+1(pc),a0
		moveq	#4,d0
		jsr	_LVOText(a6)
		bra	ClearString
;-----------------------------------------------------------------------------
PrintLeveltext:
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#320,d0
		move.w	#511,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	Levelstring(pc),a0
		moveq	#7,d0
		jmp	_LVOText(a6)
;-----------------------------------------------------------------------------
PrintLevel:
		move.w	levelnumber(pc),d2
		andi.l	#$ffff,d2
		addq.w	#1,d2
		lea	String(pc),a0
		bsr	decl
		movea.l	GFXBase(pc),a6
		movea.l	RastPort1(pc),a1
		move.w	#544,d0
		move.w	#511,d1
		jsr	_LVOMove(a6)
		movea.l	RastPort1(pc),a1
		lea	String+2(pc),a0
		moveq	#3,d0
		jsr	_LVOText(a6)
		bra	ClearString
;-----------------------------------------------------------------------------
Offset2Coords:
; Input :	d0.w: Offset
; Output:	d0.w: x-Coord
;		d1.w: y-Coord
		divu	#20,d0
		move.w	d0,d1
		swap	d0
		rts
;-----------------------------------------------------------------------------
Coords2Offset:
; Input:	d0.w: x-Coord
;		d1.w: y-Coord
; Output:	d0.w: Offset
		mulu	#20,d1
		add.w	d1,d0
		rts
;-----------------------------------------------------------------------------
TestJoy:
		lea	Joystick(pc),a0
		clr.w	(a0)
		moveq	#0,d0
		moveq	#0,d1
		move.w	$dff00c,d0
.prüf_rechts:
		btst	#1,d0
		bne	.setze_rechts
.prüf_links:
		btst	#9,d0
		bne	.setze_links
.prüf_hoch:
		moveq	#0,d2
		move.w	d0,d2
		and.w	#%0000001100000000,d2
		eori.w	#%0000000100000000,d2
		tst.w	d2
		beq.s	.setze_hoch
		cmp.w	#%0000001100000000,d2
		beq.s	.setze_hoch
.prüf_runter:
		moveq	#0,d2
		move.w	d0,d2
		and.w	#%0000000000000011,d2
		eor.w	#%01,d2
		tst.w	d2
		beq.s	.setze_runter
		cmp.b	#%0000000000000011,d2
		beq.s	.setze_runter
		bra.s	.raus
.setze_rechts:
		move.w	#%0000000000000010,d1
		bra.s	.prüf_hoch
.setze_links:
		move.w	#%0000000000001000,d1
		bra.s	.prüf_hoch
.setze_hoch:
		or.w	#%0000000000000001,d1
		bra.s	.raus
.setze_runter:
		or.w	#%0000000000000100,d1
.raus:
		move.w	d1,(a0)
		rts
Joystick:	ds.w	1	; Bit0 gesetzt	: hoch
				; Bit1 gesetzt	: rechts
				; Bit2 gesetzt	: runter
				; Bit3 gesetzt	: links
;-----------------------------------------------------------------------------
		cnop	0,4
WaitforButton:
		btst	#7,$bfe001		; ööhh, wass, Busy-Waiting??
		bne	WaitforButton		; ach was, hier doch nicht!
		rts
;-----------------------------------------------------------------------------
TestButton:
; returniert TRUE in d0, wenn Knopf gedrückt wurde
; returniert FALSE in d1, wenn Knopf nicht gedrückt wurde
		btst	#7,$bfe001
		beq	.gedrückt
		moveq	#FALSE,d0
		rts
.gedrückt:
		moveq	#TRUE,d0
		rts
;-----------------------------------------------------------------------------
Fadeout:
; blendet den Screen sanft aus (vom schwarzen Screen)
; Parameter:
; a0:	ViewPort
		moveq	#0,d5				; fürs Warten

		move.l	a0,a5				; ViewPort nach a5

		movea.l	GFXBase(pc),a6
		moveq	#0,d0
		moveq	#32,d1
		movea.l	vp_ColorMap(a0),a0
		lea	.locale_ct+4(pc),a1
		jsr	_LVOGetRGB32(a6)


		movea.l	a5,a0
		lea	.locale_ct(pc),a1
		jsr	_LVOLoadRGB32(a6)		; zur Sicherheit
.los:
		moveq	#(3*32)-1,d7
		moveq	#1,d6
		lea	.locale_ct+4(pc),a1
.Loop1:
		cmp.b	#0,(a1)
		beq.s	.nextEntry
		moveq	#0,d6				; -=> verändert
		subq.b	#1,(a1)+
		subq.b	#1,(a1)+
		subq.b	#1,(a1)+
		subq.b	#1,(a1)+
		dbra	d7,.Loop1
		bra.s	.durch
.nextEntry:
		lea	4(a1),a1
		dbra	d7,.Loop1
.durch:						; einmal die Palette durch
		tst.l	d6	; wurde überhaupt noch was verändert?
		bne.s	.raus

		cmpi.l	#1,d5	; größere Werte -> schneller
		bne.s	.ändern
		jsr	_LVOWaitTOF(a6)
		moveq	#0,d5
		bra.s	.weiter
.ändern:
		addq.l	#1,d5
.weiter:
		movea.l	a5,a0
		lea	.locale_ct(pc),a1
		jsr	_LVOLoadRGB32(a6)
		bra.s	.los
.raus:
		rts

		cnop	0,4
.locale_ct:
		dc.w	32
		dc.w	0
		rept	32
		dc.l	$00000000,$00000000,$00000000
		endr
		dc.l	0			; fertig
;-----------------------------------------------------------------------------
Fadein:
; blendet den Screen sanft ein (Voraussetzung: alle Farben auf schwarz)
; Parameter:
; a0:	ViewPort
; a1:	pointer to table
		moveq	#0,d5
		move.l	a0,a5				; ViewPort nach a5
		movea.l	a1,a0
		lea	.locale_ct2(pc),a1
		move.l	#(12*32)+8,d0
		movea.l	SysBase(pc),a6
		jsr	_LVOCopyMemQuick(a6)
		lea	ColorSpec2(pc),a0		; nur schwarze Farben
		lea	.locale_ct(pc),a1
		move.l	#(12*32)+8,d0
		jsr	_LVOCopyMemQuick(a6)

		movea.l	a5,a0
		lea	.locale_ct(pc),a1
		movea.l	GFXBase(pc),a6
;		jsr	_LVOLoadRGB32(a6)		; zur Sicherheit
.los:
		moveq	#1,d6
		move.l	#(32*3)-1,d7
		lea	.locale_ct+4(pc),a0
		lea	.locale_ct2+4(pc),a1
.Loop1:
		move.b	(a0),d0
		move.b	(a1),d1
		cmp.b	d0,d1
		beq.s	.nextEntry
		moveq	#0,d6				; -=> etwas geändert
		addq.b	#1,(a0)+
		addq.b	#1,(a0)+
		addq.b	#1,(a0)+
		addq.b	#1,(a0)+
		lea	4(a1),a1
		dbra	d7,.Loop1
		bra.s	.durch

.nextEntry:
		lea	4(a0),a0
		lea	4(a1),a1
		dbra	d7,.Loop1
.durch:
		tst.l	d6
		bne.s	.raus

		cmpi.l	#1,d5	; größere Werte -> schneller
		bne.s	.ändern
		jsr	_LVOWaitTOF(a6)
		moveq	#0,d5
		bra.s	.weiter
.ändern:
		addq.l	#1,d5
.weiter:
		movea.l	a5,a0
		lea	.locale_ct(pc),a1
		jsr	_LVOLoadRGB32(a6)
		bra.s	.los
.raus:
		rts

		cnop	0,4
.locale_ct:
		dc.w	32
		dc.w	0
		rept	32
		dc.l	$00000000,$00000000,$00000000
		endr
		dc.l	0			; fertig
.locale_ct2:
		dc.w	32
		dc.w	0
		rept	32
		dc.l	$00000000,$00000000,$00000000
		endr
		dc.l	0			; fertig
;-----------------------------------------------------------------------------
decl:
; wandelt Zahl in ASCII-String um
; Übergabeparameter:
; d2: Zahl
; a0: Adresse, an der der String abgelegt werden soll

		movem.l	a2/d2,-(sp)
		movea.l	a0,a2
		tst.l	d2
		beq.s	.null
		moveq	#4,d0
		movea.l	a2,a0
		lea	pwrof10(PC),a1
.next:
		moveq	#"0",d1
.dec:
		addq	#1,d1
		sub.l	(a1),d2
		bcc.s	.dec
		subq	#1,d1
		add.l	(a1),d2
		move.b	d1,(a0)+
		lea	4(a1),a1
		dbra	d0,.next
		movea.l	a2,a0
.rep:
		move.b	#" ",(a0)+
		cmp.b	#"0",(a0)
		beq.s	.rep
.done:
		movem.l	(sp)+,a2/d2
		rts
.null:
		move.b	#"0",4(a0)
		bra.s	.done
		cnop	0,4
pwrof10:
		dc.l	10000
		dc.l	1000
		dc.l	100
		dc.l	10
		dc.l	1

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------

; Daten
SysBase:	ds.l	1
MainTask:	ds.l	1
SignalMask:	ds.l	1
SignalNum:	ds.l	1
MsgPort1:	ds.l	1
MsgPort2:	ds.l	1
GFXBase:	ds.l	1
IntBase:	ds.l	1
DOSBase:	ds.l	1
IconBase:	ds.l	1
DiskfontBase:	ds.l	1
MEDPlayerBase:	ds.l	1
TextFont1:	ds.l	1
TextFont2:	ds.l	1
TTArray:	ds.l	1				; ** Tooltype
MyDiskObject:	ds.l	1
altlock:	ds.l	1			; Lock auf voriges Verz.
Lock1:		ds.l	1			; Lock auf z.B. "levelset2"
Lock2:		ds.l	1
FileHandle1:	ds.l	1
FIB1:		ds.b	260
mem1:		ds.l	1			; nimmt geladenen Levelset auf
Screen1:	ds.l	1
Window1:	ds.l	1
UserPort1:	ds.l	1
RastPort1:	ds.l	1
RastPort2:	dc.l	OwnRP
OwnRP:		ds.b	rp_SIZEOF
ViewPort1:	ds.l	1
ColorMap1:	ds.l	1
Bitmap1:	ds.l	1			; vom Screen
Bitmap2:	ds.l	1			; für die Figuren
Bitmap3:	ds.l	1			; fürs Double-Buffering

TmpRas1:
		ds.l	1			; RasPtr
		ds.l	1			; Size

DBufInfo1:	ds.l	1
Pointer1:	ds.l	8
vctags:		dc.l	VTAG_BORDERSPRITE_SET,TRUE
		dc.l	TAG_DONE
Screen_Tags:
		dc.l	SA_Left,0
		dc.l	SA_Top,0
		dc.l	SA_Width,640+maxScrollSpeed+maxWidth
		dc.l	SA_Height,512
		dc.l	SA_Depth,Depth
		dc.l	SA_DisplayID,DBLPALHIRESFF_KEY
;		dc.l	SA_DisplayID,LORES_KEY
;		dc.l	SA_DisplayID,VGAPRODUCT_KEY
		dc.l	SA_Colors32,ColorSpec2
		dc.l	SA_Interleaved,TRUE
;		dc.l	SA_Exclusive,TRUE
;		dc.l	SA_Draggable,FALSE
		dc.l	SA_Quiet,TRUE
		dc.l	SA_Overscan,1
		dc.l	SA_Font,TextAttr1
		dc.l	SA_VideoControl,vctags
		dc.l	TAG_DONE
Window_Tags:
		dc.l	WA_CustomScreen,0
		dc.l	WA_Left,0
		dc.l	WA_Top,0
		dc.l	WA_Width,640+maxScrollSpeed+maxWidth
		dc.l	WA_Height,512
		dc.l	WA_IDCMP,IDCMP_VANILLAKEY
		dc.l	WA_Activate,TRUE
		dc.l	WA_Borderless,TRUE
		dc.l	WA_RMBTrap,TRUE
		dc.l	WA_NoCareRefresh,TRUE
		dc.l	TAG_DONE
ColorSpec1:
		dc.w	32				; number of colors
		dc.w	0				; first color
		dc.l	$00000000,$00000000,$00000000
		dc.l	$29292929,$02020202,$01010101
		dc.l	$02020202,$51515151,$00000000
		dc.l	$08080808,$7d7d7d7d,$04040404
		dc.l	$4a4a4a4a,$0f0f0f0f,$0a0a0a0a
		dc.l	$60606060,$1e1e1e1e,$15151515
		dc.l	$70707070,$2a2a2a2a,$1f1f1f1f
		dc.l	$27272727,$2b2b2b2b,$ffffffff
		dc.l	$49494949,$4c4c4c4c,$ffffffff
		dc.l	$67676767,$6a6a6a6a,$ffffffff
		dc.l	$80808080,$39393939,$2b2b2b2b
		dc.l	$8f8f8f8f,$4a4a4a4a,$38383838
		dc.l	$9f9f9f9f,$5c5c5c5c,$47474747
		dc.l	$afafafaf,$6e6e6e6e,$58585858
		dc.l	$ffffffff,$00000000,$03030303
		dc.l	$ffffffff,$2d2d2d2d,$2d2d2d2d
		dc.l	$ffffffff,$4e4e4e4e,$4e4e4e4e
		dc.l	$ffffffff,$6e6e6e6e,$6e6e6e6e
		dc.l	$bfbfbfbf,$82828282,$6a6a6a6a
		dc.l	$cececece,$97979797,$7e7e7e7e
		dc.l	$99999999,$9b9b9b9b,$ffffffff
		dc.l	$b2b2b2b2,$b4b4b4b4,$ffffffff
		dc.l	$dededede,$aeaeaeae,$93939393
		dc.l	$ffffffff,$90909090,$90909090
		dc.l	$ffffffff,$b2b2b2b2,$b2b2b2b2
		dc.l	$eeeeeeee,$c4c4c4c4,$abababab
		dc.l	$cccccccc,$cdcdcdcd,$ffffffff
		dc.l	$ffffffff,$d3d3d3d3,$d3d3d3d3
		dc.l	$ffffffff,$d6d6d6d6,$d1d1d1d1
		dc.l	$eeeeeeee,$efefefef,$ffffffff
		dc.l	$ffffffff,$eeeeeeee,$eeeeeeee
		dc.l	$ffffffff,$ffffffff,$ffffffff
		dc.l	0				; fertig

ColorSpec2:						; alles schwarz
		dc.w	32
		dc.w	0
		rept	32
		dc.l	$00000000,$00000000,$00000000
		endr
		dc.l	0

ColorSpec3:						; für's Titelbild
		dc.w	32
		dc.w	0

		dc.l	$00000000,$00000000,$00000000
		dc.l	$ffffffff,$ffffffff,$ffffffff
		dc.l	$ffffffff,$e3e3e3e3,$e3e3e3e3
		dc.l	$ffffffff,$c6c6c6c6,$c6c6c6c6
		dc.l	$ffffffff,$aaaaaaaa,$aaaaaaaa
		dc.l	$ffffffff,$8e8e8e8e,$8e8e8e8e
		dc.l	$ffffffff,$72727272,$72727272
		dc.l	$ffffffff,$56565656,$56565656
		dc.l	$ffffffff,$3a3a3a3a,$3a3a3a3a
		dc.l	$ffffffff,$1d1d1d1d,$1d1d1d1d
		dc.l	$ffffffff,$00000000,$00000000
		dc.l	$d2d2d2d2,$ffffffff,$d2d2d2d2
		dc.l	$b4b4b4b4,$ffffffff,$b3b3b3b3
		dc.l	$99999999,$eeeeeeee,$98989898
		dc.l	$7f7f7f7f,$e6e6e6e6,$7e7e7e7e
		dc.l	$67676767,$dededede,$65656565
		dc.l	$51515151,$d7d7d7d7,$4f4f4f4f
		dc.l	$3b3b3b3b,$cfcfcfcf,$39393939
		dc.l	$26262626,$c7c7c7c7,$24242424
		dc.l	$13131313,$bfbfbfbf,$12121212
		dc.l	$01010101,$b7b7b7b7,$00000000
		dc.l	$d2d2d2d2,$d2d2d2d2,$ffffffff
		dc.l	$babababa,$bcbcbcbc,$fdfdfdfd
		dc.l	$a5a5a5a5,$a7a7a7a7,$fdfdfdfd
		dc.l	$90909090,$92929292,$fcfcfcfc
		dc.l	$7c7c7c7c,$7f7f7f7f,$fcfcfcfc
		dc.l	$68686868,$6b6b6b6b,$fbfbfbfb
		dc.l	$53535353,$56565656,$fafafafa
		dc.l	$3e3e3e3e,$41414141,$fafafafa
		dc.l	$29292929,$2d2d2d2d,$f9f9f9f9
		dc.l	$15151511,$19191919,$f9f9f9f9
		dc.l	$00000000,$03030303,$f8f8f8f8
		dc.l	0

Puffer:		ds.b	bpl			; enthält aktuellen Level
levelnumber:	dc.w	0
lives:		dc.w	1000
score:		dc.w	0
time:		dc.w	120
levelpointer:	dc.l	levels			; Pointer auf die eingebauten
						; oder geladenen Level
levelanzahl:	dc.w	(levels_end-levels)/bpl
Zeitzähler:	dc.w	10
levels:
; m=Mauer, d=Dreck, w=Werner, b=Bulle, s=Stein, f=Flasche

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"mmmfmmmmmmmmmmmmmmmm"
		dc.b	"mr r r r r r r r r m"
		dc.b	"m m       m mmmmmmum"
		dc.b	"mb m     m  m l lm m"
		dc.b	"m   m   m   mu   mum"
		dc.b	"mb   m m    m   bm m"
		dc.b	"m     mw    mu   mum"
		dc.b	"mb    m     m   bm m"
		dc.b	"m     m     mu   mum"
		dc.b	"mb    m     m r bm m"
		dc.b	"m     m     mmmmmmum"
		dc.b	"mb l           l l m"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"msdssssssssssssssssm"
		dc.b	"mwdssssssssddddddddm"
		dc.b	"msdddssssssdssssssdm"
		dc.b	"msdsdsddddsddddsssdm"
		dc.b	"msdsdsdsdssssdssssdm"
		dc.b	"msdsdsdsdssssdssssdm"
		dc.b	"msdsdsdsdssssdssssdm"
		dc.b	"msdsdsdsddsdsdssssdm"
		dc.b	"msdsdsdsdssdsdssssdm"
		dc.b	"msdsdsdsddddddssssdm"
		dc.b	"msdsdsdssssssdssssdm"
		dc.b	"msdsdddssssssddddsfm"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"msdsmbbbsssssssssssm"
		dc.b	"mwdm    b s bbsssssm"
		dc.b	"mds   bssss bssssssm"
		dc.b	"mdbb    ssss  sssbsm"
		dc.b	"mds        sssssssbm"
		dc.b	"mdm         sssbb  m"
		dc.b	"mdm            ss  m"
		dc.b	"mmm                m"
		dc.b	"m      b     b b   m"
		dc.b	"m             b    m"
		dc.b	"mddddddddddddddddddm"
		dc.b	"m                 fm"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"m   m  m mbm m m mfm"
		dc.b	"m wbmb m m m mbm m m"
		dc.b	"m   m  m    b    m m"
		dc.b	"mm mmb   m m m m m m"
		dc.b	"mb  m  mmmmmmmmm m m"
		dc.b	"mm  mb m   m  b    m"
		dc.b	"m   m    m mmmm  m m"
		dc.b	"mm mmb mmb    m  m m"
		dc.b	"m   mmmmmmm mmmmmmmm"
		dc.b	"mb  m   bb         m"
		dc.b	"mm mmmmmmmmmmmm mmmm"
		dc.b	"mb                 m"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"mf  b  b   b  b    m"
		dc.b	"m mmm m m m  m mmm m"
		dc.b	"m mrm mmm m m bmlm m"
		dc.b	"m mmm mmm m mm mmm m"
		dc.b	"m mbm m m m m mmbm m"
		dc.b	"m m m m m m  m m m m"
		dc.b	"m                  m"
		dc.b	"m b  b  b b      b m"
		dc.b	"m b   b    b b     m"
		dc.b	"m  b   b      b  b m"
		dc.b	"m         d    b   m"
		dc.b	"m        dwd       m"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"m m m r mwm   dsssfm"
		dc.b	"m   mbf m m   dssssm"
		dc.b	"m m m l m m   dssssm"
		dc.b	"m m mm mm mmmbdddddm"
		dc.b	"m m    bm mbm      m"
		dc.b	"m m     m   mb     m"
		dc.b	"m mmmmmmm m m      m"
		dc.b	"m         mfmb     m"
		dc.b	"m mmmmmmm mmmmmm mmm"
		dc.b	"m mm b mm         bm"
		dc.b	"m  mbf mm mmmmmmm mm"
		dc.b	"mbmm   mm mf      bm"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"mddddddddddddddddddm"
		dc.b	"mdddddddddddddddddwm"
		dc.b	"mddddddddddddddddddm"
		dc.b	"mdmmmmmmmmmmmmmmmmmm"
		dc.b	"mddddddddddddddddddm"
		dc.b	"mmmmmmmmmmmmmmmmmmdm"
		dc.b	"mb        b       bm"
		dc.b	"mdmmmmmmmmmmmmmmmmmm"
		dc.b	"m b   b      b    bm"
		dc.b	"mmmmmmmmmmmmmmmmmmdm"
		dc.b	"m   b    b         m"
		dc.b	"mf   b  b          m"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"m r r r r r r r r um"
		dc.b	"mbmmmmmmmmmmmmmmmm m"
		dc.b	"m ml l l l l l l mum"
		dc.b	"mbm mmmmmmmmmmmmbm m"
		dc.b	"mwm mr r r r r m mum"
		dc.b	"m m m mmmmmmmmumbm m"
		dc.b	"m  umbmmmfmmmm   mum"
		dc.b	"mbm m l l l   lmbm m"
		dc.b	"m mummmmmmmmmmmm mum"
		dc.b	"mbm r r r r r r bm m"
		dc.b	"m mmmmmmmmmmmmmmmmum"
		dc.b	"mb l l l l l l l l m"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

		dc.b	"mmmmmmmmmmmmmmmmmmmm"
		dc.b	"mfsw    m         bm"
		dc.b	"mmsmm mmmmmm mmmm mm"
		dc.b	"mdsb    m  b  mb   m"
		dc.b	"mdsmmm mmmm mmmmm mm"
		dc.b	"mds b   m b   m b  m"
		dc.b	"mdsmm mmmmmm mmmm mm"
		dc.b	"mds   b mb    m   bm"
		dc.b	"mdsmm mmmmm mmmmm mm"
		dc.b	"mdsm     b    mb   m"
		dc.b	"mdsm   m     mmmm mm"
		dc.b	"mmsmmmmdmmmmm      m"
		dc.b	"mddb             dmm"
		dc.b	"mmmmmmmmmmmmmmmmmmmm"

levels_end:
TitleImage1:
		dc.w	38,0,565,121,Depth
		dc.l	TitleImageData1
		dc.b	2*(1<<Depth)-1,0
		dc.l	TitleImage2
TitleImage2:
		dc.w	129,169,383,36,Depth
		dc.l	TitleImageData2
		dc.b	2*(1<<Depth)-1,0
		dc.l	TitleImage3
TitleImage3:
		dc.w	72,250,496,48,Depth
		dc.l	TitleImageData3
		dc.b	2*(1<<Depth)-1,0
		dc.l	TitleImage4
TitleImage4:
		dc.w	304,341,54,49,Depth
		dc.l	TitleImageData4
		dc.b	2*(1<<Depth)-1,0
		dc.l	0
Image1:
		dc.w	0,0,32,32,Depth	; x-pos, y-pos, width, height, depth
		dc.l	ImageData1	; pointer to gfxdata
		dc.b	2*(1<<Depth)-1,0; PlanePick, PlaneOff
		dc.l	Image2		; Pointer to next Image-Structure
Image2:
		dc.w	32,0,32,32,Depth
		dc.l	ImageData2
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image3
Image3:
		dc.w	64,0,32,32,Depth
		dc.l	ImageData3
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image4
Image4:
		dc.w	96,0,32,32,Depth
		dc.l	ImageData4
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image5
Image5:
		dc.w	128,0,32,32,Depth
		dc.l	ImageData5
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image6
Image6:
		dc.w	160,0,32,32,Depth
		dc.l	ImageData6
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image7
Image7:
		dc.w	192,0,32,32,Depth
		dc.l	ImageData7
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image8
Image8:
		dc.w	224,0,32,32,Depth
		dc.l	ImageData8
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image9
Image9:
		dc.w	256,0,32,32,Depth
		dc.l	ImageData9
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image10
Image10:
		dc.w	288,0,32,32,Depth
		dc.l	ImageData10
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image11
Image11:
		dc.w	0,32,32,32,Depth
		dc.l	ImageData11
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image12
Image12:
		dc.w	32,32,32,32,Depth
		dc.l	ImageData12
		dc.b	2*(1<<Depth)-1,0
		dc.l	Image13
Image13:
		dc.w	96,32,32,32,Depth
		dc.l	ImageData13
		dc.b	2*(1<<Depth)-1,0
		dc.l	0
Image14:						; Pfeil
		dc.w	128,32,13,14,Depth
		dc.l	ImageData14
		dc.b	2*(1<<Depth)-1,0
		dc.l	0
IntServer1:
		dc.l	0				; succ
		dc.l	0				; pred
		dc.b	NT_INTERRUPT
		dc.b	60				; pri
		dc.l	InterruptName			; name
		dc.l	MainTask			; pointer to data
		dc.l	Int1Code			; pointer to code
IntServer2:
		dc.l	0				; succ
		dc.l	0				; pred
		dc.b	NT_INTERRUPT
		dc.b	60				; pri
		dc.l	InterruptName2			; name
		dc.l	MainTask			; pointer to data
		dc.l	Int2Code			; pointer to code

Int1Code:
; im Spiel: jede 10-tel Sek: Haupttask signalisieren
		lea	VBL_Counter(pc),a0
		subq.w	#1,(a0)
		bne.s	.raus
		move.w	#5,(a0)
		move.l	4(a1),d0
		movea.l	(a1),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOSignal(a6)
.raus:
		lea	$dff000,a0
		moveq	#0,d0
		rts
VBL_Counter:	dc.w	5
		cnop	0,4
Int2Code:
; VertBlank-> signalisieren
		move.l	4(a1),d0
		movea.l	(a1),a1
		movea.l	SysBase(pc),a6
		jsr	_LVOSignal(a6)
.raus:
		lea	$dff000,a0
		moveq	#0,d0
		rts

TextAttr1:				; der im Spiel
		dc.l	FontName1
		dc.w	32
		dc.b	FSF_COLORFONT
		dc.b	FPF_DISKFONT|FPF_DESIGNED
TextAttr2:
		dc.l	FontName2
		dc.w	38
		dc.b	FSF_COLORFONT
		dc.b	FPF_DISKFONT|FPF_DESIGNED|FPF_PROPORTIONAL
;TextAttr2:
;		dc.l	FontName2
;		dc.w	32
;		dc.b	FSF_COLORFONT
;		dc.b	FPF_DISKFONT|FPF_DESIGNED
GFXName:	dc.b	"graphics.library",0
IntName:	dc.b	"intuition.library",0
DOSName:	dc.b	"dos.library",0
IconName:	dc.b	"icon.library",0
DiskfontName:	dc.b	"diskfont.library",0
MEDPlayerName:	dc.b	"medplayer.library",0
FontName1:	dc.b	"Werner.font",0
FontName2:	dc.b	"Werner2.font",0
;FontName2:	dc.b	"Werner.font",0
PrgName:	dc.b	"Werner",0
TypeName:	dc.b	"levelset",0
DirName:	dc.b	"levelset                         ",0
InterruptName:	dc.b	"WernerAGA_VERTB_Int",0
InterruptName2:	dc.b	"WernerAGA_VERTB_Int2",0

Scorestring:	dc.b	"SCORE:"
Scorestring_end:
Timestring:	dc.b	" TIME:"
Timestring_end:
Livesstring:	dc.b	"LIVES:"
Livesstring_end:
Levelstring:	dc.b	" LEVEL:"
Scrolltext:
		dc.b	"Welcome to Werner Version 1.0 AGA      written by Patrick Klie for WTS                                                       "
Scrolltext_end:

		SECTION Grafikdaten,DATA,CHIP
		include	"Grafiken.i"

		END

