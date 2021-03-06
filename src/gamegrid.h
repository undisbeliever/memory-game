
.ifndef ::__GAMEGRID_H_
::__GAMEGRID_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

GAMEGRID_WIDTH		= 6
GAMEGRID_HEIGHT		= 5
N_UNIQUE_TILES		= 15
N_CARDS_TO_MATCH	= 2

N_DOOR_FRAMES		= 13

CARD_TILE_HEIGHT	= 4
CARD_TILE_WIDTH		= 4

CARD_X_OFFSET_PX	= (32 - (GAMEGRID_WIDTH * CARD_TILE_WIDTH)) / 2 * 8
CARD_Y_OFFSET_PX	= (28 - (GAMEGRID_HEIGHT * CARD_TILE_HEIGHT)) / 2 * 8

IMPORT_MODULE GameGrid

	;; Initializes the game grids
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE	Init

	;; VBlank routine - copies tilemaps to VRAM
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE VBlank

	;; Shuffles the cards, marks all cards as unopened
	;; REQUIRES: 8 bit A, 16 bit Index, DB = anywhere
	ROUTINE	ShuffleCards

	;; Clears the tilemap
	;; REQUIRES: 8 bit A, 16 bit Index, DB = anywhere
	ROUTINE	ClearScreen

	;; Draws all cards on the screen
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	ROUTINE	DrawAllCards

	;; Draws the given card in the given index
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A = card Index
	ROUTINE	DrawCard

	;; Draws all door with a given value
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A = door value
	ROUTINE	DrawAllDoors

	;; Draws a door on a given card with a given value
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A = door value
	;;	  X = card index
	ROUTINE	DrawDoor

	;; Checks to see if the card is already open
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A = card Index
	;; RETURN: carry set if card is unmatched
	ROUTINE IsCardUnOpened

	;; Marks a card as opened
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A = card Index
	ROUTINE MarkCardCardOpened

	;; Checks to see if the two cards are equal
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: X = card 1 Index
	;;	  Y = card 2 index
	;; RETURN: carry set if cards are equal
	ROUTINE AreCardsAMatch
ENDMODULE

.endif ; __GAMEGRID_H_

; vim: ft=asm:

