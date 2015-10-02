; Loader of resources.

; :SHOULDDO automatically generate this with a program::

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/resourceloader.h"
.include "routines/metasprite.h"

.segment "BANK1"

PalettesTable:
	.faraddr	Cards_Palette
	.byte		128
	.faraddr	Door_Palette
	.byte		16


VramTable:
	.faraddr	Cards_4bpp
	.faraddr	Door_4bpp



MODULE Resources

.segment "BANK2"

Cards_Palette:
	.incbin "resources/images4bpp/cards.clr"

Door_Palette:
	.incbin "resources/tiles4bpp/door.clr"


Cards_4bpp:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	Cards_4bpp_End - Cards_4bpp - 3
	.incbin "resources/images4bpp/cards.4bpp"
Cards_4bpp_End:

Door_4bpp:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	Door_4bpp_End - Door_4bpp - 3
	.incbin "resources/tiles4bpp/door.4bpp"
Door_4bpp_End:

	INCLUDE_BINARY CardsTileMap, "resources/images4bpp/cards.map" 


.segment "BANK3"

MetaSpriteLayoutBank = .bankbyte(*)


ENDMODULE

