
.include "gameloop.h"

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/block.h"
.include "routines/math.h"
.include "routines/controller.h"
.include "routines/resourceloader.h"
.include "routines/screen.h"

.include "gamegrid.h"
.include "resources.h"
.include "vram.h"

MODULE GameLoop

.enum GameState
	END		=  0
	PRESS_START	=  2
	OPEN_DOORS	=  4
.endenum

.segment "WRAM7E"
	;; Game State
	;; see GameState enum
	ADDR	state

	;; position of cursor
	BYTE	cursorPos

	;; Currently selected cursor
	BYTE	currentSelectedPos

	;; Number of correct guesses
	;; when == N_UNIQUE_TILES the player wins
	BYTE	nCorrectGuesses

.code


ROUTINE PlayGame
	PHP
	PHB

	REP	#$30
	SEP	#$20
.A8
.I16
	PEA	$7E80
	PLB		; $80

	JSR	Init

	PLB		; $7E

	LDX	#GameState::PRESS_START
	STX	state

	REPEAT
		JSR	(.loword(StateTable), X)
		JSR	Screen__WaitFrame

		LDX	state
	UNTIL_ZERO

	PLB
	PLP
	RTS

.rodata

StateTable:
	.addr	DoNothing
	.addr	State_PressStart
	.addr	State_OpenDoors

.code

ROUTINE DoNothing
	RTS



;; Show press start message
; DB = $7E
.A8
.I16
ROUTINE	State_PressStart
	LDA	Controller__pressed + 1
	IF_BIT	#JOYH_START
		BRA	EnterState_OpenDoors
	ENDIF
	
	RTS



; DB = $7E
.A8
.I16
ROUTINE EnterState_OpenDoors
	LDX	#GameState::OPEN_DOORS
	STX	state

	; ::TODO randomize cards

	JSR	GameGrid__DrawAllCards

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_OpenDoors
	; ::TODO code::
	RTS


;; Initialize the system
; DB = $80
.A8
.I16
ROUTINE Init
	JSR	GameGrid__Init

	JSR	Screen__WaitFrame

	LDA	#15
	STA	INIDISP

	RTS

ENDMODULE

