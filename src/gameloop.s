
.include "gameloop.h"

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/block.h"
.include "routines/math.h"
.include "routines/controller.h"
.include "routines/random.h"
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
	OPEN_ALL_DOORS	=  4
	SHOW_CARDS	=  6
	CLOSE_ALL_DOORS	=  8
	SELECT_FIRST	= 10
	SELECT_SECOND	= 12
	WAIT_FOR_DOORS	= 14
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
		PEA	$7E80
		PLB		; $80

		JSR	Random__AddJoypadEntropy
		JSR	Controller__UpdateRepeatingDPad

		PLB		; $7E

		LDX	state
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
	.addr	State_OpenAllDoors
	.addr	State_ShowCards
	.addr	State_CloseAllDoors
	.addr	State_SelectFirst
	.addr	State_SelectSecond
	.addr	State_WaitForDoors

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
		BRA	EnterState_OpenAllDoors
	ENDIF

	JSR	GameGrid__ShuffleCards

	RTS




; DB = $7E
.A8
.I16
ROUTINE EnterState_OpenAllDoors
	LDX	#GameState::OPEN_ALL_DOORS
	STX	state

	PEA	$7E80
	PLB		; $80
	JSR	Screen__FadeOut
	PLB		; $7E

	JSR	Sprites__Clear

	JSR	GameGrid__DrawAllCards

	LDA	#0
	JSR	GameGrid__DrawAllDoors

	PEA	$7E80
	PLB		; $80
	JSR	Screen__FadeIn
	PLB		; $7E

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
ROUTINE State_OpenAllDoors

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
	BNE	EnterState_CloseAllDoors

	LDA	Controller__pressed + 1
	AND	#.hibyte(JOY_SKIP)
	BNE	EnterState_CloseAllDoors


	LDY	animationCounter
	DEY
	STY	animationCounter

	BEQ	EnterState_CloseAllDoors

	RTS



; DB = $7E
.A8
.I16
ROUTINE EnterState_CloseAllDoors
	LDX	#GameState::CLOSE_ALL_DOORS
	STX	state

	LDA	#N_DOOR_FRAMES
	STA	doorValue

	LDA	#1
	STA	animationCounter

	RTS



; DB = $7E
.A8
.I16
ROUTINE State_CloseAllDoors

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
	JSR	HandleCursor

	LDA	Controller__pressed
	ORA	Controller__pressed + 1
	IF_BIT	#JOYL_A | JOYL_X	; also the same as B and Y

		; check if card is already opened
		LDA	cursorPos
		JSR	GameGrid__IsCardUnOpened
		BCS	EnterState_SelectSecond
	ENDIF

	RTS


; DB = $7E
.A8
.I16
ROUTINE EnterState_SelectSecond
	LDX	#GameState::SELECT_SECOND
	STX	state

	LDA	cursorPos
	STA	firstSelectedPos
	JSR	GameGrid__MarkCardCardOpened

	LDA	#1
	STA	animationCounter

	STZ	firstDoorValue

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_SelectSecond

	; Animate the opening of the door in the background
	LDA	firstDoorValue
	CMP	#N_DOOR_FRAMES
	IF_LT
		DEC	animationCounter
		IF_ZERO
			INC	firstDoorValue
			LDA	firstDoorValue

			LDX	firstSelectedPos
			JSR	GameGrid__DrawDoor

			LDA	#OPEN_DOOR_ANIMATION_DELAY
			STA	animationCounter
		ENDIF
	ENDIF

	JSR	HandleCursor

	LDA	Controller__pressed
	ORA	Controller__pressed + 1
	IF_BIT	#JOYL_A | JOYL_X	; also the same as B and Y
		LDA	cursorPos
		JSR	GameGrid__IsCardUnOpened
		BCS	EnterState_WaitForDoors
	ENDIF

	RTS


; DB = $7E
.A8
.I16
ROUTINE EnterState_WaitForDoors
	LDX	#GameState::WAIT_FOR_DOORS
	STX	state

	LDA	cursorPos
	STA	secondSelectedPos
	JSR	GameGrid__MarkCardCardOpened

	STZ	secondDoorValue

	RTS


; DB = $7E
.A8
.I16
ROUTINE State_WaitForDoors

	DEC	animationCounter
	IF_ZERO
		; Animation of second door
		INC	secondDoorValue

		LDA	secondDoorValue
		CMP	#N_DOOR_FRAMES + 1
		IF_GE
			BRA	CheckMatch
		ENDIF

		LDX	secondSelectedPos
		JSR	GameGrid__DrawDoor

		; Continue animation of second door if necessary
		LDA	firstDoorValue
		CMP	#N_DOOR_FRAMES
		IF_LT
			INC
			STA	firstDoorValue

			LDX	firstSelectedPos
			JSR	GameGrid__DrawDoor

			LDA	#OPEN_DOOR_ANIMATION_DELAY
			STA	animationCounter
		ENDIF

		LDA	#OPEN_DOOR_ANIMATION_DELAY
		STA	animationCounter
	ENDIF

	RTS



;; Checks that the two cards are equal and move to correct state
.A8
.I16
ROUTINE CheckMatch
	LDX	firstSelectedPos
	LDY	secondSelectedPos
	JSR	GameGrid__AreCardsAMatch

	IF_C_CLEAR
		; not a match
		; Player Looses
		JSR	Sprites__DrawGameOverMessage

		LDX	#GameState::PRESS_START
		STX	state
	ELSE
		INC	nCorrectGuesses
		LDA	nCorrectGuesses

		CMP	#N_UNIQUE_TILES
		IF_EQ
			; Player Wins
			JSR	Sprites__DrawYouWinMessage

			LDX	#GameState::PRESS_START
			STX	state
		ELSE
			JMP	EnterState_SelectFirst
		ENDIF
	ENDIF

	RTS

;; move the cursor depending on the controller
.A8
.I16
ROUTINE HandleCursor
	LDA	Controller__pressed + 1
	IF_BIT	#JOYH_UP
		LDA	cursorPos
		SUB	#GAMEGRID_WIDTH

		IF_MINUS
			ADD	#GAMEGRID_HEIGHT * GAMEGRID_WIDTH
		ENDIF
		STA	cursorPos

	ELSE_BIT #JOYH_DOWN
		LDA	cursorPos
		ADD	#GAMEGRID_WIDTH

		CMP	#GAMEGRID_HEIGHT * GAMEGRID_WIDTH
		IF_GE
			SUB	#GAMEGRID_HEIGHT * GAMEGRID_WIDTH
		ENDIF
		STA	cursorPos
	ENDIF

	LDA	Controller__pressed + 1
	IF_BIT	#JOYH_LEFT
		DEC	cursorPos
		IF_MINUS
			LDA	#GAMEGRID_HEIGHT * GAMEGRID_WIDTH -1
			STA	cursorPos
		ENDIF

	ELSE_BIT #JOYH_RIGHT
		INC	cursorPos

		LDA	cursorPos
		CMP	#GAMEGRID_HEIGHT * GAMEGRID_WIDTH
		IF_GE
			STZ	cursorPos
		ENDIF
	ENDIF

	LDA	cursorPos
	JMP	Sprites__DrawCursor


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

