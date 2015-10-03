
.ifndef ::__RESOURCES_H_
::__RESOURCES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"


.enum RESOURCES_VRAM
	CARDS_4BPP
	DOOR_4BPP
	SPRITES_4BPP
.endenum

.enum RESOURCES_PALETTES
	CARDS
	DOOR
	SPRITES
.endenum

IMPORT_MODULE Resources

	INCLUDE_BINARY	CardsTileMap

ENDMODULE

.endif ; __RESOURCES_H_

; vim: ft=asm:

