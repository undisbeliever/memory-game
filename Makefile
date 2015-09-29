
ROM_NAME      = Memory_Game
CONFIG        = LOROM_1MBit_copyright
API_MODULES   = reset-snes sfc-header block screen controller math random metasprite resourceloader
API_DIR       = snesdev-common
SOURCE_DIR    = src
RESOURCES_DIR = resources

include $(API_DIR)/Makefile.in

