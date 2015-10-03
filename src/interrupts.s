; Inturrupt Handlers

.include "includes/registers.inc"

.include "routines/block.h"
.include "routines/screen.h"
.include "routines/random.h"
.include "routines/controller.h"
.include "routines/metasprite.h"

.include "gamegrid.h"
.include "sprites.h"


;; Blank Handlers
ROUTINE IrqHandler
	RTI

ROUTINE CopHandler
	RTI

ROUTINE VBlank
	JML	_VBlankBank

_VBlankBank:
	; Save state
	REP #$30
	PHA
	PHB
	PHD
	PHX
	PHY

	PHK
	PLB

	SEP #$20
.A8
.I16
	; Reset NMI Flag.
	LDA	RDNMI

	JSR	GameGrid__VBlank
	JSR	Sprites__VBlank

	MetaSprite_VBlank
	Screen_VBlank
	Controller_VBlank

	; Load State
	REP	#$30
	PLY
	PLX
	PLD
	PLB
	PLA
	
	RTI

