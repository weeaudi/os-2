ASM=nasm
CC=gcc
CC16=wcc
LD16=wlink

SRC_DIR=src
TOOLS_DIR=tools
BUILD_DIR=build

include build_scripts/config.mk

.PHONY: all floppy_image kernel bootloader run debug clean always

all: floppy_image tools_fat

include build_scripts/toolchain.mk

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "AIDOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::test.txt"
	mmd -i $(BUILD_DIR)/main_floppy.img "::mydir"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::mydir/test.txt"

#
# Bootloader
#
bootloader: stage1 stage2

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: always
	$(MAKE) -C ${SRC_DIR}/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: always
	$(MAKE) -C ${SRC_DIR}/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
		$(MAKE) -C ${SRC_DIR}/kernel BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Tools
#
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

run:
	$(MAKE)
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

debug:
	$(MAKE)
	bochs -f bochs_config

#
# Clean
#
clean:
	$(MAKE) -C ${SRC_DIR}/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))
	$(MAKE) -C ${SRC_DIR}/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))
	$(MAKE) -C ${SRC_DIR}/kernel BUILD_DIR=$(abspath $(BUILD_DIR))
	rm -rf $(BUILD_DIR)/*