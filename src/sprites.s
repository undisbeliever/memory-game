
.include "sprites.h"

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/block.h"
.include "routines/math.h"
.include "routines/controller.h"
.include "routines/resourceloader.h"
.include "routines/screen.h"
.include "routines/reset-snes.h"

.include "gamegrid.h"
.include "resources.h"
.include "vram.h"

N_TEXT_SPRITES	= 15

SPRITE_PALETTE	= 0
SPRITE_ORDER    = 3
CURSOR_TILE	= 0

CARD_SPACING	= CARD_TILE_WIDTH * 8
SPRITE_SIZE	= 16

MODULE Sprites

.segment "SHADOW"
	BYTE	updateOamOnZero

.segment "WRAM7E"
oamBuffer:
	STRUCT	cursorSprites, OamFormat, 4
	STRUCT	textSprites, OamFormat, N_TEXT_SPRITES
oamBuffer_End:

	WORD	tmp1

.code

.A8
.I16
ROUTINE Init
	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#TM_BG1 | TM_BG2 | TM_OBJ
	STA	TM

	LDA	#SPRITE_PALETTE * 16 + 128
	STA	CGADD

	LDA	#RESOURCES_PALETTES::SPRITES
	JSR	ResourceLoader__LoadPalette_8A

	LDX	#PPU_MEMORY_OAM_TILES
	STX	VMADD

	LDA	#RESOURCES_VRAM::SPRITES_4BPP
	JSR	ResourceLoader__LoadVram_8A

	JSR	Reset__ClearOAM

	; Clear the second OAM table
	LDY	#$0100
	STY	OAMADD

	FOR_X	#32, DEC, #0
		STZ	OAMDATA
	NEXT

	BRA	Clear


.A8
.I16
ROUTINE VBlank
	LDA	updateOamOnZero
	IF_ZERO
		TransferToOamLocation	oamBuffer, 0
	ENDIF

	RTS



; DB access shadow
.A8
.I16
ROUTINE Clear
	; Ourside screen
	LDA	#256 - 16
	LDX	#oamBuffer_End - oamBuffer - .sizeof(OamFormat)

	REPEAT
		STA	f:oamBuffer + OamFormat::yPos, X

		DEX
		DEX
		DEX
		DEX
	UNTIL_MINUS

	STZ	updateOamOnZero

	RTS



; A = card ID
; DB = $7E
.A8
.I16
ROUTINE DrawCursor

tmp_gridIndex = tmp1

	CMP	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	IF_GE
		LDA	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1
	ENDIF

	ASL
	STA	tmp_gridIndex
	STZ	tmp_gridIndex + 1


	; x = tmp_gridIndex / (GAMEGRID_WIDTH * 2)
	; y = tmp_gridIndex % (GAMEGRID_WIDTH * 2)
	; xPos = x * CARD_SPACING + CARD_X_OFFSET_PX
	; yPos = y * CARD_SPACING + CARD_Y_OFFSET_PX

	LDY	tmp_gridIndex
	LDA	#GAMEGRID_WIDTH * 2
	JSR	Math__Divide_U16Y_U8A_DB

	.assert CARD_SPACING = 32, error, "Bad Value"

	TXA	; x is already * 2
	ASL
	ASL
	ASL
	ASL	; * 32
	ADD	#CARD_X_OFFSET_PX

	STA	cursorSprites + 0 * .sizeof(OamFormat) + OamFormat::xPos
	STA	cursorSprites + 2 * .sizeof(OamFormat) + OamFormat::xPos

	ADD	#CARD_SPACING - SPRITE_SIZE
	STA	cursorSprites + 1 * .sizeof(OamFormat) + OamFormat::xPos
	STA	cursorSprites + 3 * .sizeof(OamFormat) + OamFormat::xPos

	TYA
	ASL
	ASL
	ASL
	ASL
	ASL	; * 32
	ADD	#CARD_Y_OFFSET_PX - 1

	STA	cursorSprites + 0 * .sizeof(OamFormat) + OamFormat::yPos
	STA	cursorSprites + 1 * .sizeof(OamFormat) + OamFormat::yPos

	ADD	#CARD_SPACING - SPRITE_SIZE
	STA	cursorSprites + 2 * .sizeof(OamFormat) + OamFormat::yPos
	STA	cursorSprites + 3 * .sizeof(OamFormat) + OamFormat::yPos


_CURSOR_OAMATTR = CURSOR_TILE | (SPRITE_PALETTE << OAM_CHARATTR_PALETTE_SHIFT) | (SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT)

	LDY	#_CURSOR_OAMATTR
	STY	cursorSprites + 0 * .sizeof(OamFormat) + OamFormat::char

	LDY	#_CURSOR_OAMATTR | OAM_CHARATTR_H_FLIP_FLAG
	STY	cursorSprites + 1 * .sizeof(OamFormat) + OamFormat::char

	LDY	#_CURSOR_OAMATTR | OAM_CHARATTR_V_FLIP_FLAG
	STY	cursorSprites + 2 * .sizeof(OamFormat) + OamFormat::char

	LDY	#_CURSOR_OAMATTR | OAM_CHARATTR_H_FLIP_FLAG | OAM_CHARATTR_V_FLIP_FLAG
	STY	cursorSprites + 3 * .sizeof(OamFormat) + OamFormat::char

	STZ	updateOamOnZero

	RTS


; DB = $7E
.A8
.I16
ROUTINE DrawPressStartInCenter
	LDX	#.loword(PressStartCenterSprites)

	BRA	_DrawMessage


; DB = $7E
.A8
.I16
ROUTINE DrawYouWinMessage
	LDX	#.loword(YouWinSprites)

	BRA	_DrawMessage



; DB = $7E
.A8
.I16
ROUTINE DrawGameOverMessage
	LDX	#.loword(GameOverSprites)

	BRA	_DrawMessage


; X = message address in bank 1
; DB = $7E
.A8
.I16
ROUTINE _DrawMessage
	REP	#$30
.A16
	LDY	#.loword(textSprites)
	LDA	#.sizeof(textSprites)
	MVN	.bankbyte(textSprites), .bankbyte(PressStartCenterSprites)

	SEP	#$20
.A8

	STZ	updateOamOnZero

	RTS



.segment "BANK1"

PRESS_START_XPOS	= (256 - 112) / 2
PRESS_START_CENTER_YPOS	= (224 - 16) / 2
PRESS_START_BOTTOM_YPOS	= 224 - 16 - 16
TEXT_MESSAGE_XPOS	= (256 - 128) / 2
TEXT_MESSAGE_YPOS	= 16


.macro _Sprite xPos, yPos, tile
	.byte	xPos
	.byte	yPos - 1
	.word	tile | (SPRITE_PALETTE << OAM_CHARATTR_PALETTE_SHIFT) | (SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT)
.endmacro

	.assert .loword(*) <> 0, error, "Bad value"

LABEL PressStartCenterSprites
	.repeat 7, t
		_Sprite PRESS_START_XPOS + t * SPRITE_SIZE, PRESS_START_CENTER_YPOS, $02 + t * 2
	.endrepeat

	.repeat 8
		_Sprite	0, 240, 0
	.endrepeat


LABEL YouWinSprites
	.repeat 7, t
		_Sprite PRESS_START_XPOS + t * SPRITE_SIZE, PRESS_START_BOTTOM_YPOS, $02 + t * 2
	.endrepeat

	.repeat 8, t
		_Sprite TEXT_MESSAGE_XPOS + t * SPRITE_SIZE, TEXT_MESSAGE_YPOS, $40 + t * 2
	.endrepeat


LABEL GameOverSprites
	.repeat 7, t
		_Sprite PRESS_START_XPOS + t * SPRITE_SIZE, PRESS_START_BOTTOM_YPOS, $02 + t * 2
	.endrepeat

	.repeat 8, t
		_Sprite TEXT_MESSAGE_XPOS + t * SPRITE_SIZE, TEXT_MESSAGE_YPOS, $20 + t * 2
	.endrepeat


ENDMODULE

