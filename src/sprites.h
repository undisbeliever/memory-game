
.ifndef ::__SPRITES_H_
::__SPRITES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"


IMPORT_MODULE Sprites

	;; Initializes the sprite module
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE	Init

	;; VBlank routine - copies buffer to OAM
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE VBlank

	;; Clears the sprites
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	ROUTINE Clear

	;; Draws the sprite cursor at a given location
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; INPUT: A - card ID
	ROUTINE DrawCursor


	;; Draws the press start message at the center of the screen
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	ROUTINE DrawPressStartInCenter


	;; Draws the you win message
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	ROUTINE DrawYouWinMessage


	;; Draws the game over message
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	ROUTINE DrawGameOverMessage

ENDMODULE

.endif ; __SPRITES_H_

; vim: ft=asm:
