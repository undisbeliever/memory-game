
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
.include "sprites.h"
.include "vram.h"

CONFIG OPEN_DOOR_ANIMATION_DELAY,	3
CONFIG CLOSE_DOOR_ANIMATION_DELAY,	1
CONFIG SHOW_CARDS_SECONDS,		5


MODULE GameLoop

.enum GameState
	END		=  0
	PRESS_START	=  2
	OPEN_DOORS	=  4
	SHOW_CARDS	=  6
	CLOSE_DOORS	=  8
	SELECT_FIRST	= 10
.endenum

.segment "WRAM7E"
	;; Game State
	;; see GameState enum
	ADDR	state

	;; position of cursor
	WORD	cursorPos

	;; Currently selected cursor
	WORD	firstSelectedPos

	;; the door value of the first selected door
	BYTE	firstDoorValue

	;; Currently selected cursor
	WORD	secondSelectedPos

	;; the door value of the second selected door
	BYTE	secondDoorValue

	;; Number of correct guesses
	;; when == N_UNIQUE_TILES the player wins
	BYTE	nCorrectGuesses


	;; Counter for the animations
	WORD	animationCounter

	;; the state of all the doors
	doorValue = firstDoorValue
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

	JSR	Sprites__DrawPressStartInCenter

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
	.addr	State_ShowCards
	.addr	State_CloseDoors
	.addr	State_SelectFirst

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

	JSR	Sprites__Clear

	JSR	GameGrid__DrawAllCards

	LDA	#0
	JSR	GameGrid__DrawAllDoors

	STZ	nCorrectGuesses

	LDX	#0
	STX	cursorPos
	STX	firstSelectedPos
	STX	secondSelectedPos

	LDA	#OPEN_DOOR_ANIMATION_DELAY
	STA	animationCounter

	STZ	doorValue

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_OpenDoors

	DEC	animationCounter		
	IF_ZERO
		INC	doorValue
		LDA	doorValue
		CMP	#N_DOOR_FRAMES + 1
		BGE	EnterState_ShowCards

		JSR	GameGrid__DrawAllDoors

		LDA	#OPEN_DOOR_ANIMATION_DELAY
		STA	animationCounter
	ENDIF

	RTS



; DB = $7E
.A8
.I16
ROUTINE EnterState_ShowCards
	LDX	#GameState::SHOW_CARDS
	STX	state

	LDA	STAT78
	IF_BIT	#STAT78_PAL_MASK
		LDY	#SHOW_CARDS_SECONDS * 50
	ELSE
		LDY	#SHOW_CARDS_SECONDS * 60
	ENDIF

	STY	animationCounter

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_ShowCards
	; skip if the user presses a button
	JOY_SKIP = JOY_BUTTONS | JOY_START

	LDA	Controller__pressed
	AND	#.lobyte(JOY_SKIP)
	BNE	EnterState_CloseDoors

	LDA	Controller__pressed + 1
	AND	#.hibyte(JOY_SKIP)
	BNE	EnterState_CloseDoors


	LDY	animationCounter
	DEY
	STY	animationCounter

	BEQ	EnterState_CloseDoors

	RTS



; DB = $7E
.A8
.I16
ROUTINE EnterState_CloseDoors
	LDX	#GameState::CLOSE_DOORS
	STX	state

	LDA	#N_DOOR_FRAMES
	STA	doorValue

	LDA	#CLOSE_DOOR_ANIMATION_DELAY
	STA	animationCounter

	RTS



; DB = $7E
.A8
.I16
ROUTINE State_CloseDoors

	DEC	animationCounter		
	IF_ZERO
		LDA	doorValue
		JSR	GameGrid__DrawAllDoors

		DEC	doorValue
		BMI	EnterState_SelectFirst

		LDA	#CLOSE_DOOR_ANIMATION_DELAY
		STA	animationCounter
	ENDIF

	RTS



; DB = $7E
.A8
.I16
ROUTINE EnterState_SelectFirst
	LDX	#GameState::SELECT_FIRST
	STX	state

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_SelectFirst
	; ::TODO::

	LDA	cursorPos
	JSR	Sprites__DrawCursor

	RTS


;; Initialize the system
; DB = $80
.A8
.I16
ROUTINE Init
	JSR	GameGrid__Init
	JSR	Sprites__Init

	JSR	Screen__WaitFrame

	LDA	#15
	STA	INIDISP

	RTS

ENDMODULE

