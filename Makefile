PSXSDK_DIR = /usr/local/psxsdk

AS = mipsel-unknown-elf-as
AS_FLAGS = -msoft-float
CC = mipsel-unknown-elf-gcc
DEFINE = -DVIDEO_MODE=VMODE_PAL -D__PSXSDK__ -fno-strict-overflow -fsigned-char -msoft-float -mno-gpopt -fno-builtin -g
LIBS = -lfixmath
INCLUDE = include $(PSXSDK_DIR)/include
CC_FLAGS = -Wall -ffunction-sections -fdata-sections -c -Os -Wfatal-errors -g $(addprefix -I, $(INCLUDE))
LD = mipsel-unknown-elf-gcc
LD_FLAGS = $(LIBS) -Wl,--gc-sections -L$(PSXSDK_DIR)/lib -I/usr/local/psxsdk/include -T /usr/local/psxsdk/mipsel-unknown-elf/lib/ldscripts/playstation.x

PROJECT = opensend

INIT_ADDR = 0x801A0000

ELF2EXE = elf2exe
ELF2EXE_FLAGS = -mark="Open-source PSX-EXE loader created with PSXSDK" -init_addr=$(INIT_ADDR)
LICENSE_FILE = /usr/local/psxsdk/share/licenses/infoeur.dat

PATH := $(PATH):$(PSXSDK_DIR)/bin

EMULATOR = pcsxr
SOUND_INTERFACE =
EMULATOR_FLAGS = -nogui -psxout
OBJ_DIR = obj
SRC_DIR = src
EXE_PATH = obj

BIN_TARGET_PATH = bin

GNU_SIZE = mipsel-unknown-elf-size

OBJECTS = $(addprefix $(OBJ_DIR)/,	\
			Font.o Gfx.o Serial.o System.o  Interrupts.o \
			IO.o main.o reception.o \
			)

CDROM_ROOT = cdimg

$(BIN_TARGET_PATH)/$(PROJECT).bin: $(EXE_PATH)/$(PROJECT).iso
	mkdir -p $(BIN_TARGET_PATH)
#~ 	mkpsxiso $< $@ $(LICENSE_FILE) $(MUSIC_TRACKS)
	mkpsxiso $< $@ $(LICENSE_FILE) -s
# $(PROJECT).cue is automatically generated by mkpsxiso
	$(GNU_SIZE) $(EXE_PATH)/$(PROJECT).elf

rebuild:
	make clean
	make $(BIN_TARGET_PATH)/$(PROJECT).bin

-include $(DEPS)

clean:
	rm -f $(EXE_DIR)/*.exe
	rm -f $(EXE_DIR)/*.iso
	rm -f $(EXE_DIR)/*.elf
	rm -f $(OBJ_DIR)/*.o
	rm -f $(OBJ_DIR)/*.d
	rm -f $(OBJ_SOUNDS_DIR)/*.vag
	rm -f $(OBJ_SPRITES_PATH)/*.tim
	rm -f $(OBJ_FONTS_PATH)/*.tim

$(OBJ_DIR)/%.d: $(SRC_DIR)/%.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $< $(DEFINE) $(CXX_FLAGS) -MM > $@

$(OBJ_DIR)/%.d: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	echo $$PATH
	$(CC) $< $(DEFINE) $(CC_FLAGS) -MM > $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(OBJ_DIR)/%.d
	@mkdir -p $(OBJ_DIR)
	$(CXX) $< -o $@ $(DEFINE) $(CXX_FLAGS) -MMD

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(OBJ_DIR)/%.d
	@mkdir -p $(OBJ_DIR)
	$(CC) $< -o $@ $(DEFINE) $(CC_FLAGS) -MMD

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(OBJ_DIR)
	$(AS) $< -o $@ $(AS_FLAGS)

$(EXE_PATH)/$(PROJECT).elf: $(OBJECTS)
	@mkdir -p $(EXE_PATH)
	$(LD) $^ -o $@ $(LD_FLAGS)

$(EXE_PATH)/$(PROJECT).iso: $(EXE_PATH)/$(PROJECT).exe $(SOUND_OBJECTS) $(LEVEL_OBJECTS) $(SPRITE_OBJECTS) $(APPS_OBJECTS)
	@mkdir -p $(EXE_PATH)
	mkisofs -o $@ -V $(PROJECT) -sysid PLAYSTATION $(CDROM_ROOT)

$(EXE_PATH)/$(PROJECT).exe: $(EXE_PATH)/$(PROJECT).elf
	@mkdir -p $(EXE_PATH)
	$(ELF2EXE) $< $@ $(ELF2EXE_FLAGS)
	@mkdir -p $(CDROM_ROOT)
	cp $@ $(CDROM_ROOT)

run: $(BIN_TARGET_PATH)/$(PROJECT).bin
	export PATH=$$PATH:$(EMULATOR_DIR)
	@mkdir -p $(BIN_TARGET_PATH)
	$(EMULATOR) -cdfile $(BIN_TARGET_PATH)/$(PROJECT).bin $(EMULATOR_FLAGS)

$(OBJ_SPRITES_PATH)/%.tim: $(SRC_SPRITES_PATH)/%.bmp $(SRC_SPRITES_PATH)/%.flags
	@mkdir -p $(OBJ_SPRITES_PATH)
	$(BMP2TIM) $< $@ `cat $(word 2,$^)`

$(OBJ_APPS_PATH)/%.EOL: $(SRC_APPS_PATH)/%.EOL
	@mkdir -p $(OBJ_APPS_PATH)
	cp $^ $@

$(OBJ_FONTS_PATH)/%.tim: $(SRC_SPRITES_PATH)/%.bmp $(SRC_SPRITES_PATH)/%.flags
	@mkdir -p $(OBJ_FONTS_PATH)
	$(BMP2TIM) $< $@ `cat $(word 2,$^)`

$(OBJ_SOUNDS_DIR)/%.vag: $(SOURCE_SOUNDS_FOLDER)/%.wav $(SOURCE_SOUNDS_FOLDER)/%.flags
	@mkdir -p $(OBJ_SOUNDS_DIR)
	wav2vag $< $@ `cat $(word 2,$^)`

%.bin: %.mp3
	rm -f ../Bin/$@1
	$(FFMPEG) -i $< $(FFMPEG_FLAGS) $@
	cp ../Music/$@ ../Bin/

# ----------------------------------------
# Phony targets
# ----------------------------------------
.PHONY: clean run rebuild
