; Wernerfont

		include	"exec/types.i"
		include	"exec/nodes.i"
		include	"libraries/diskfont.i"

begin:
		moveq	#0,d0
		rts

		dc.l	0
		dc.l	0
		dc.b	NT_FONT
		dc.b	0
		dc.l	fontName

		dc.w	DFH_ID
		dc.w	1
		dc.l	0

fontName:	dc.b	"Werner"
length		equ	*-fontName
		dcb.b	MAXFONTNAME-length,0

font:
		dc.l	0
		dc.l	0
		dc.b	NT_FONT
		dc.b	0
		dc.l	fontName
		dc.l	0
		dc.w	0
		dc.w	32
		dc.b	FSF_COLORFONT
		dc.b	FPF_DESIGNED
		dc.w	32
		dc.w	31
		dc.w	1
		dc.w	0
		dc.b	32
		dc.b	95
		dc.l	fontData
		dc.w	256

		dc.l	fontLoc
		dc.l	fontSpace
		dc.l	fontKern

; jetzt die Zusatzinfos für Colorfonts
		dc.w	CT_COLORFONT				; Flags
		dc.b	5					; Depth
		dc.b	$ff					; FGColor
		dc.b	0					; low
		dc.b	31					; high
		dc.b	%11111					; PlanePick
		dc.b	0					; PlaneOnOff
		dc.l	CFColors
		dc.l	fontData
		dc.l	fontData+1*(fontLoc-fontData)/5
		dc.l	fontData+2*(fontLoc-fontData)/5
		dc.l	fontData+3*(fontLoc-fontData)/5
		dc.l	fontData+4*(fontLoc-fontData)/5
		dc.l	begin
		dc.l	begin
		dc.l	begin
fontData:
		incbin	"DPaintIV:Werner_big/Zeichensatz2.raw"
fontLoc:
		dc.w	0,32
		dc.w	32,32
		dc.w	64,32
		dc.w	96,32
		dc.w	128,32
		dc.w	160,32
		dc.w	192,32
		dc.w	224,32
		dc.w	256,32
		dc.w	288,32
		dc.w	320,32
		dc.w	352,32
		dc.w	384,32
		dc.w	416,32
		dc.w	448,32
		dc.w	480,32
		dc.w	512,32
		dc.w	544,32
		dc.w	576,32
		dc.w	608,32
		dc.w	640,32
		dc.w	672,32
		dc.w	704,32
		dc.w	736,32
		dc.w	768,32
		dc.w	800,32
		dc.w	832,32
		dc.w	864,32
		dc.w	896,32
		dc.w	928,32
		dc.w	960,32
		dc.w	992,32
		dc.w	1024,32
		dc.w	1056,32
		dc.w	1088,32
		dc.w	1120,32
		dc.w	1152,32
		dc.w	1184,32
		dc.w	1216,32
		dc.w	1248,32
		dc.w	1280,32
		dc.w	1312,32
		dc.w	1344,32
		dc.w	1376,32
		dc.w	1408,32
		dc.w	1440,32
		dc.w	1472,32
		dc.w	1504,32
		dc.w	1536,32
		dc.w	1568,32
		dc.w	1600,32
		dc.w	1632,32
		dc.w	1664,32
		dc.w	1696,32
		dc.w	1728,32
		dc.w	1760,32
		dc.w	1792,32
		dc.w	1824,32
		dc.w	1856,32
		dc.w	1888,32
		dc.w	1920,32
		dc.w	1952,32
		dc.w	1984,32
		dc.w	2016,32
fontSpace:
		dcb.w   64,32
fontKern:
		dcb.w	64,0
CFColors:
		dc.w	0
		dc.w	32
		dc.l	ColorTable
ColorTable:
		dc.w	$0000,$0200,$0050,$0070,$0400,$0611,$0721,$022f
		dc.w	$044f,$066f,$0832,$0843,$0954,$0a65,$0f00,$0f22
		dc.w	$0f44,$0f66,$0b86,$0c97,$099f,$0bbf,$0da9,$0f99
		dc.w	$0fbb,$0eca,$0ccf,$0fdd,$0fdd,$0eef,$0fee,$0fff
fontEnd:
		END

