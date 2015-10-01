
.ifndef ::__GAMELOOP_H_
::__GAMELOOP_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"


IMPORT_MODULE GameLoop

	;; Plays a game of memory
	;; REQUIRES: nothing
	ROUTINE	PlayGame

ENDMODULE

.endif ; __GAMELOOP_H_

; vim: ft=asm:

