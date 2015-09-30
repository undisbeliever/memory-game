; Initialisation code

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/controller.h"
.include "routines/screen.h"
.include "routines/metasprite.h"

.include "gamegrid.h"


;; Initialisation Routine
ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDXY	#$144fe7		; source: random.org
	STXY	Random__Seed

	MetaSprite_Init

	JSR	GameGrid__Init

	LDA	#15
	STA	INIDISP

	JSR	WaitForButtonPress

	REPEAT
	FOREVER


.A8
.I16
ROUTINE WaitForButtonPress
	REPEAT
		JSR	Screen__WaitFrame
		JSR	Random__AddJoypadEntropy

		REP	#$30
.A16
		LDA	Controller__pressed
		AND	#JOY_BUTTONS | JOY_START

		SEP	#$30
.A8
	UNTIL_NE

	RTS


.segment "COPYRIGHT"
		;1234567890123456789012345678901
	.byte	"Memory Game                    ", 10
	.byte	"(c) 2015, The Undisbeliever    ", 10
	.byte	"MIT Licensed                   ", 10
	.byte	"One Game Per Month Challange   ", 10

