; The game grid.

.include "gamegrid.h"

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/block.h"
.include "routines/math.h"
.include "routines/resourceloader.h"
.include "routines/random.h"
.include "routines/screen.h"
.include "routines/reset-snes.h"

.include "resources.h"
.include "vram.h"

MODULE GameGrid

CARD_TILEMAP_WIDTH	= 3
CARD_TILEMAP_HEIGHT	= 15

.segment "SHADOW"
	BYTE	updateCardMapOnZero
	BYTE	updateDoorMapOnZero

	; need to access with both registers when DB = $80
	WORD	grid, GAMEGRID_WIDTH * GAMEGRID_HEIGHT

	WORD	tmp1
	WORD	tmp2
	WORD	tmp3
	WORD	tmp4

.segment "WRAM7E"

Init_MemClear:
	WORD	cardTileMap, 32 * 24
	WORD	doorTileMap, 32 * 24

	;; If byte is non-zero then the card has been opened
	BYTE	gridCardOpened, GAMEGRID_WIDTH * GAMEGRID_HEIGHT
Init_MemClear_End:

.code

.A8
.I16
ROUTINE Init

	LDA	#INIDISP_FORCE
	STA	INIDISP

	JSR	Reset__ClearVRAM

	LDA	#PPU_MEMORY_SCREEN_MODE
	STA	BGMODE

	Screen_SetVramBaseAndSize PPU_MEMORY

	LDA	#TM_BG1 | TM_BG2
	STA	TM

	LDA	#.lobyte(-CARD_X_OFFSET_PX)
	STA	BG1HOFS
	LDA	#.hibyte(-CARD_X_OFFSET_PX)
	STA	BG1HOFS

	LDA	#.lobyte(-CARD_Y_OFFSET_PX)
	STA	BG1VOFS
	LDA	#.hibyte(-CARD_Y_OFFSET_PX)
	STA	BG1VOFS

	LDA	#.lobyte(-CARD_X_OFFSET_PX)
	STA	BG2HOFS
	LDA	#.hibyte(-CARD_X_OFFSET_PX)
	STA	BG2HOFS

	LDA	#.lobyte(-CARD_Y_OFFSET_PX)
	STA	BG2VOFS
	LDA	#.hibyte(-CARD_Y_OFFSET_PX)
	STA	BG2VOFS


	STZ	CGADD

	LDA	#RESOURCES_PALETTES::CARDS
	JSR	ResourceLoader__LoadPalette_8A

	LDA	#DOOR_PALETTE * 16
	STA	CGADD

	LDA	#RESOURCES_PALETTES::DOOR
	JSR	ResourceLoader__LoadPalette_8A

	LDX	#PPU_MEMORY_BG2_TILES
	STX	VMADD

	LDA	#RESOURCES_VRAM::CARDS_4BPP
	JSR	ResourceLoader__LoadVram_8A

	LDX	#PPU_MEMORY_BG1_TILES
	STX	VMADD

	LDA	#RESOURCES_VRAM::DOOR_4BPP
	JSR	ResourceLoader__LoadVram_8A

	MemClear	Init_MemClear

	STZ	updateCardMapOnZero
	STZ	updateDoorMapOnZero

	; Initial Setup of cards

	LDX	#0
	LDY	#N_CARDS_TO_MATCH
	REPEAT
		LDA	#(N_UNIQUE_TILES - 1) * 2

		REPEAT
			STA	f:grid, X
			INX
			INX

			DEC
			DEC
		UNTIL_MINUS

		DEY
	UNTIL_ZERO

	RTS



.A8
.I16
ROUTINE VBlank
	LDA	updateCardMapOnZero
	IF_ZERO
		TransferToVramLocation	cardTileMap, PPU_MEMORY_BG2_MAP

		; A = non-zero
		STA	updateCardMapOnZero
	ENDIF

	LDA	updateDoorMapOnZero
	IF_ZERO
		TransferToVramLocation	doorTileMap, PPU_MEMORY_BG1_MAP

		; A = non-zero
		STA	updateDoorMapOnZero
	ENDIF

	RTS



.A8
.I16
ROUTINE ShuffleCards

	; Uses Fisher-Yates shuffle
	; https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle

tmp_i	 = tmp1

	PHB
	PHK
	PLB

	MemClear	Init_MemClear

	LDY	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1
	STY	tmp_i

	REPEAT
		LDY	tmp_i
		JSR	Random__Rnd_U16Y

		SEP	#$10
.I8
		TYA
		ASL
		TAY

		LDA	tmp_i
		ASL
		TAX

		LDA	grid, X
		PHA

		LDA	grid, Y
		STA	grid, X

		PLA
		STA	grid, Y

		REP	#$10
.I16

		DEC	tmp_i
	UNTIL_ZERO

	PLB
	RTS


.A8
.I16
ROUTINE	ClearScreen
	REP	#$30
.A16
.I16
	PHB

	LDA	#0
	STA	f:grid
	LDX	#.loword(grid)
	LDY	#.loword(grid) + 2
	LDA	#.sizeof(grid) - 2 - 1
	MVN	#.bankbyte(grid), #.bankbyte(grid)

	SEP	#$20
.A8
	STZ	updateCardMapOnZero

	PLB
	RTS



; DB = 7E
.A8
.I16
ROUTINE	DrawAllCards
	LDA	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1

	REPEAT
		PHA
		JSR	DrawCard

		PLA
		DEC
	UNTIL_MINUS

	RTS



; A = card index
; DB = 7E
.A8
.I16
ROUTINE DrawCard

tmp_gridIndex	= tmp1
tmp_mapIndex	= tmp2

	CMP	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	IF_GE
		LDA	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1
	ENDIF

	ASL
	STA	tmp_gridIndex
	STZ	tmp_gridIndex + 1


	; x = tmp_gridIndex / (GAMEGRID_WIDTH * 2)
	; y = tmp_gridIndex % (GAMEGRID_WIDTH * 2)
	; tmp_mapIndex = y * CARD_TILE_HEIGHT * 64 + x * CARD_TILE_HEIGHT

	.assert CARD_TILE_WIDTH = 4, error, "bad code"
	.assert CARD_TILE_HEIGHT = 4, error, "bad code"

	LDY	tmp_gridIndex
	LDA	#GAMEGRID_WIDTH * 2
	JSR	Math__Divide_U16Y_U8A_DB

	REP	#$30
.A16
	TXA
	ASL
	ASL
	STA	tmp_mapIndex

	TYA
	XBA
	ADD	tmp_mapIndex
	TAY

	LDX	tmp_gridIndex
	LDA	grid, X
	TAX

	LDA	f:Tile_Locations, X
	TAX

	.repeat	CARD_TILE_HEIGHT, cy
		.repeat	CARD_TILE_WIDTH, cx
			LDA	f:Resources__CardsTileMap + (cy * 32 + cx) * 2, X
			STA	a:cardTileMap + (cy * 32 + cx) * 2, Y
		.endrepeat
	.endrepeat

	SEP	#$20
.A8

	STZ	updateCardMapOnZero

	RTS



; A = door value
; DB = $7E
.A8
.I16
ROUTINE DrawAllDoors
tmp_doorValue	= tmp3

	STA	tmp_doorValue

	LDX	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1

	REPEAT
		PHX
		LDA	tmp_doorValue
		JSR	DrawDoor

		PLX
		DEX
	UNTIL_MINUS

	RTS



; A = door value
; X = door index
; DB = $7E
.A8
.I16
ROUTINE DrawDoor

;tmp_gridIndex	= tmp1
;tmp_mapIndex	= tmp2
;tmp_doorValue	= tmp3
tmp_doorId	= tmp4

	CMP	#N_DOOR_FRAMES
	IF_GE
		LDA	#N_DOOR_FRAMES - 1
	ENDIF
	STA	tmp_doorId


	TXA
	CMP	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	IF_GE
		LDA	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT - 1
	ENDIF

	ASL
	STA	tmp_gridIndex
	STZ	tmp_gridIndex + 1


	; x = tmp_gridIndex / (GAMEGRID_WIDTH * 2)
	; y = tmp_gridIndex % (GAMEGRID_WIDTH * 2)
	; tmp_mapIndex = y * CARD_TILE_HEIGHT * 64 + x * CARD_TILE_HEIGHT

	.assert CARD_TILE_WIDTH = 4, error, "bad code"
	.assert CARD_TILE_HEIGHT = 4, error, "bad code"

	LDY	tmp_gridIndex
	LDA	#GAMEGRID_WIDTH * 2
	JSR	Math__Divide_U16Y_U8A_DB

	REP	#$30
.A16
	TXA
	ASL
	ASL
	STA	tmp_mapIndex

	TYA
	XBA
	ADD	tmp_mapIndex
	TAY


	LDA	tmp_doorId
	AND	#$00FF
	ASL
	ASL
	ASL
	ASL
	ASL	; * 32
	TAX

	; X = gridIndex
	; Y = tilemap location

	.repeat	CARD_TILE_HEIGHT, dy
		.repeat	CARD_TILE_WIDTH, dx
			LDA	f:DoorTileMapData + (dy * CARD_TILE_HEIGHT + dx) * 2, X
			STA	a:doorTileMap + (dy * 32 + dx) * 2, Y
		.endrepeat
	.endrepeat

	SEP	#$20
.A8
	STZ	updateDoorMapOnZero

	RTS



; A = card id
; Return c set if card is unopened
.A8
.I16
ROUTINE IsCardUnOpened
	SEP	#$30
.I8
	CMP	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	BGE	_IsCardUnOpened_ReturnFalse

	TAX
	LDA	gridCardOpened, X
	IF_ZERO
		SEC
	ELSE
_IsCardUnOpened_ReturnFalse:
		CLC
	ENDIF

	REP	#$10
.I16
	RTS



; A = card id
.A8
.I16
ROUTINE MarkCardCardOpened
	CMP	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	IF_LT
		SEP	#$30
.I8
		TAX
		LDA	#$FF
		STA	gridCardOpened, X

		REP	#$10
	ENDIF
.I16
	RTS


; DB = $7E
; X = card1 id
; Y = card2 id
; OUT: carry set if both cards are equal
.A8
.I16
ROUTINE AreCardsAMatch
	SEP	#$30
.I8
	CPX	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	BGE	_AreCardsAMatch_ReturnFalse

	CPY	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT
	BGE	_AreCardsAMatch_ReturnFalse

	; card indexes cannot be equal
	STX	tmp1
	CPY	tmp1
	BEQ	_AreCardsAMatch_ReturnFalse

	TXA
	ASL
	TAX

	TYA
	ASL
	TAY

	LDA	grid, X
	CMP	grid, Y

	IF_EQ
		SEC
	ELSE
_AreCardsAMatch_ReturnFalse:
		CLC
	ENDIF

	REP	#$10
.I16
	RTS



.segment "BANK1"

LABEL Tile_Locations
	.repeat	CARD_TILEMAP_HEIGHT, cy
		.repeat	CARD_TILEMAP_WIDTH, cx
			.word	(cy * CARD_TILE_HEIGHT * 32 + cx * CARD_TILE_WIDTH) * 2
		.endrepeat
	.endrepeat

_DOOR_TILE_LEFT_FULL	=  1
_DOOR_TILE_LEFT_EMPTY	=  6
_DOOR_TILE_RIGHT_FULL	=  7
_DOOR_TILE_RIGHT_EMPTY	= 15

DOOR_PALETTE		= 7

.macro _Generate_DoorTileMapLineBlock left, right
	.local d
	d = (DOOR_PALETTE << TILEMAP_PALETTE_SHIFT) | TILEMAP_ORDER_FLAG

	.word	left  | d
	.word	right | d
	.word	right | d | TILEMAP_H_FLIP_FLAG
	.word	left  | d | TILEMAP_H_FLIP_FLAG
	.word	left  + 16 | d
	.word	right + 16 | d
	.word	right + 16 | d | TILEMAP_H_FLIP_FLAG
	.word	left  + 16 | d | TILEMAP_H_FLIP_FLAG

	.word	left  + 16 | d | TILEMAP_V_FLIP_FLAG
	.word	right + 16 | d | TILEMAP_V_FLIP_FLAG
	.word	right + 16 | d | TILEMAP_H_FLIP_FLAG | TILEMAP_V_FLIP_FLAG
	.word	left  + 16 | d | TILEMAP_H_FLIP_FLAG | TILEMAP_V_FLIP_FLAG
	.word	left  | d | TILEMAP_V_FLIP_FLAG
	.word	right | d | TILEMAP_V_FLIP_FLAG
	.word	right | d | TILEMAP_H_FLIP_FLAG | TILEMAP_V_FLIP_FLAG
	.word	left  | d | TILEMAP_H_FLIP_FLAG | TILEMAP_V_FLIP_FLAG
.endmacro

.macro	_Generate_DoorTileMapLine value
	.if value < 8
		_Generate_DoorTileMapLineBlock _DOOR_TILE_LEFT_FULL, _DOOR_TILE_RIGHT_FULL + value
	.else
		_Generate_DoorTileMapLineBlock _DOOR_TILE_LEFT_FULL + value - 7, _DOOR_TILE_RIGHT_EMPTY
	.endif
.endmacro

LABEL	DoorTileMapData
	.repeat N_DOOR_FRAMES, i
		_Generate_DoorTileMapLine i
	.endrepeat

ENDMODULE

