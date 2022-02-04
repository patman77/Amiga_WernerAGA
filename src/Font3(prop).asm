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

fontName:	dc.b	"Werner2.font"
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
		dc.w	38
		dc.b	FSF_COLORFONT
		dc.b	FPF_DESIGNED|FPF_PROPORTIONAL
		dc.w	38
		dc.w	37
		dc.w	1
		dc.w	0
		dc.b	32
		dc.b	127
		dc.l	fontData
		dc.w	248

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
		incbin	"ram:Zeichensatz2(prop).raw"
fontLoc:
		dc.w	0,12
		dc.w	12,12
		dc.w	24,16
		dc.w	40,18
		dc.w	58,18
		dc.w	76,33
		dc.w	109,28
		dc.w	137,18
		dc.w	155,12
		dc.w	167,13
		dc.w	180,18
		dc.w	198,32
		dc.w	230,12
		dc.w	242,12
		dc.w	254,12
		dc.w	266,12
		dc.w	278,18
		dc.w	296,18
		dc.w	314,18
		dc.w	332,18
		dc.w	350,18
		dc.w	368,18
		dc.w	386,18
		dc.w	404,19
		dc.w	423,17
		dc.w	440,18
		dc.w	458,12
		dc.w	470,12
		dc.w	482,36
		dc.w	518,33
		dc.w	551,36
		dc.w	587,17
		dc.w	604,32
		dc.w	636,28
		dc.w	664,22
		dc.w	686,26
		dc.w	712,28
		dc.w	740,22
		dc.w	762,20
		dc.w	782,30
		dc.w	812,31
		dc.w	843,12
		dc.w	855,12
		dc.w	867,26
		dc.w	893,22
		dc.w	915,34
		dc.w	949,30
		dc.w	979,31
		dc.w	1010,22
		dc.w	1032,30
		dc.w	1062,24
		dc.w	1086,22
		dc.w	1108,23
		dc.w	1131,27
		dc.w	1158,27
		dc.w	1185,36
		dc.w	1221,25
		dc.w	1246,23
		dc.w	1269,24
		dc.w	1293,12
		dc.w	1305,12
		dc.w	1317,12
		dc.w	1329,18
		dc.w	1347,19
		dc.w	1366,17
		dc.w	1383,18
		dc.w	1401,20
		dc.w	1421,16
		dc.w	1437,22
		dc.w	1459,19
		dc.w	1478,13
		dc.w	1491,20
		dc.w	1511,21
		dc.w	1532,11
		dc.w	1543,9
		dc.w	1552,20
		dc.w	1572,11
		dc.w	1583,32
		dc.w	1615,22
		dc.w	1637,20
		dc.w	1657,22
		dc.w	1679,21
		dc.w	1700,14
		dc.w	1714,16
		dc.w	1730,13
		dc.w	1743,22
		dc.w	1765,21
		dc.w	1786,30
		dc.w	1816,19
		dc.w	1835,20
		dc.w	1855,17
		dc.w	1872,16
		dc.w	1888,18
		dc.w	1906,16
		dc.w	1922,18
		dc.w	1940,38
fontSpace:
		dc.w	12
		dc.w	12
		dc.w	16
		dc.w	18
		dc.w	18
		dc.w	33
		dc.w	28
		dc.w	18
		dc.w	12
		dc.w	13
		dc.w	18
		dc.w	32
		dc.w	12
		dc.w	12
		dc.w	12
		dc.w	12
		dc.w	18
		dc.w	18
		dc.w	18
		dc.w	18
		dc.w	18
		dc.w	18
		dc.w	18
		dc.w	19
		dc.w	17
		dc.w	18
		dc.w	12
		dc.w	12
		dc.w	36
		dc.w	33
		dc.w	36
		dc.w	17
		dc.w	32
		dc.w	28
		dc.w	22
		dc.w	26
		dc.w	28
		dc.w	22
		dc.w	20
		dc.w	30
		dc.w	31
		dc.w	12
		dc.w	12
		dc.w	26
		dc.w	22
		dc.w	34
		dc.w	30
		dc.w	31
		dc.w	22
		dc.w	30
		dc.w	24
		dc.w	22
		dc.w	23
		dc.w	27
		dc.w	27
		dc.w	36
		dc.w	25
		dc.w	23
		dc.w	24
		dc.w	12
		dc.w	12
		dc.w	12
		dc.w	18
		dc.w	19
		dc.w	17
		dc.w	18
		dc.w	20
		dc.w	16
		dc.w	22
		dc.w	19
		dc.w	13
		dc.w	20
		dc.w	21
		dc.w	11
		dc.w	9
		dc.w	20
		dc.w	11
		dc.w	32
		dc.w	22
		dc.w	20
		dc.w	22
		dc.w	21
		dc.w	14
		dc.w	16
		dc.w	13
		dc.w	22
		dc.w	21
		dc.w	30
		dc.w	19
		dc.w	20
		dc.w	17
		dc.w	16
		dc.w	18
		dc.w	16
		dc.w	18
		dc.w	38
fontKern:
		dcb.w	96,0
CFColors:
		dc.w	0
		dc.w	32
		dc.l	ColorTable
ColorTable:
		dc.w	$0000,$0fff,$0fee,$0fcc,$0faa,$0f88,$0f77,$0f55
		dc.w	$0f33,$0f11,$0f00,$0dfd,$0bfb,$09e9,$07e7,$06d6
		dc.w	$05d4,$03c3,$02c2,$01b1,$00b0,$0ddf,$0bbf,$0aaf
		dc.w	$099f,$077f,$066f,$055f,$034f,$022f,$011f,$000f
fontEnd:
		END

