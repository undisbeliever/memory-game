; The game grid.

.include "gamegrid.h"

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/block.h"
.include "routines/math.h"
.include "routines/resourceloader.h"
.include "routines/screen.h"
.include "routines/reset-snes.h"

.include "resources.h"
.include "vram.h"

MODULE GameGrid

CARD_TILEMAP_WIDTH	= 3
CARD_TILEMAP_HEIGHT	= 15


.segment "SHADOW"
	WORD	updateCardMapOnZero

.segment "WRAM7E"

Init_MemClear:
	WORD	cardTileMap, 32 * 24

	WORD	grid, GAMEGRID_WIDTH * GAMEGRID_HEIGHT
Init_MemClear_End:

	WORD	tmp1
	WORD	tmp2
	WORD	tmp3

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

	LDA	#TM_BG1
	STA	TM

	LDA	#.lobyte(-CARD_X_OFFSET_PX)
	STA	BG1HOFS
	LDA	#.hibyte(-CARD_X_OFFSET_PX)
	STA	BG1HOFS

	LDA	#.lobyte(-CARD_Y_OFFSET_PX)
	STA	BG1VOFS
	LDA	#.hibyte(-CARD_Y_OFFSET_PX)
	STA	BG1VOFS

	STZ	CGADD

	LDA	#RESOURCES_PALETTES::CARDS
	JSR	ResourceLoader__LoadPalette_8A


	LDX	#PPU_MEMORY_BG1_TILES
	STX	VMADD

	LDA	#RESOURCES_VRAM::CARDS_4BPP
	JSR	ResourceLoader__LoadVram_8A

	MemClear	Init_MemClear

	STZ	updateCardMapOnZero

	; Setup cards

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

	PEA	$807E
	PLB

	JSR	DrawAllCards

	PLB

	RTS



.A8
.I16
ROUTINE VBlank
	LDA	updateCardMapOnZero
	IF_ZERO
		TransferToVramLocation	cardTileMap, PPU_MEMORY_BG1_MAP

		; A = non-zero
		STA	updateCardMapOnZero
	ENDIF

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
	MVN	.bankbyte(grid), .bankbyte(grid)

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
	IF_LT
		ASL
		STA	tmp_gridIndex
		STZ	tmp_gridIndex + 1
	ELSE
		LDY	#GAMEGRID_WIDTH * GAMEGRID_HEIGHT * 2
	ENDIF

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


.segment "BANK1"

LABEL Tile_Locations
	.repeat	CARD_TILEMAP_HEIGHT, cy
		.repeat	CARD_TILEMAP_WIDTH, cx
			.word	(cy * CARD_TILE_HEIGHT * 32 + cx * CARD_TILE_WIDTH) * 2
		.endrepeat
	.endrepeat

ENDMODULE

