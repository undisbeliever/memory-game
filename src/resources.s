; Loader of resources.

; :SHOULDDO automatically generate this with a program::

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/resourceloader.h"
.include "routines/metasprite.h"


.segment "BANK1"

PalettesTable:


VramTable:


.segment "BANK2"

MetaSpriteLayoutBank = .bankbyte(*)



