TOOLCHAIN_PREFIX = $(abspath toolchain/$(TARGET))
export PATH := $(TOOLCHAIN_PREFIX)/bin:$(PATH)

export TARGET_CC = $(TARGET)-gcc
export TARGET_CXX = $(TARGET)-g++
export TARGET_LD = $(TARGET)-gcc

toolchain: toolchain_binutils toolchain_gcc

BINUTILS_BUILD = toolchain/binutils-build-$(BINUTILS_VERSION)

toolchain_binutils:
	mkdir -p toolchain 
	cd toolchain && wget $(TOOLCHAIN_BINUTILS_URL)
	cd toolchain && tar -xf binutils-$(BINUTILS_VERSION).tar.xz
	mkdir $(BINUTILS_BUILD)
	cd $(BINUTILS_BUILD)/ && ../binutils-$(BINUTILS_VERSION)/configure \
		--prefix="$(TOOLCHAIN_PREFIX)" \
		--target=$(TARGET) \
		--with-sysroot \
		--disable-nls \
		--disable-werror
	$(MAKE) -j6 -C $(BINUTILS_BUILD)
	$(MAKE) -C $(BINUTILS_BUILD) install

GCC_BUILD = toolchain/gcc-build-$(GCC_VERSION)

toolchain_gcc: toolchain_binutils
	cd toolchain && wget $(TOOLCHAIN_GCC_URL)
	cd toolchain && tar -xf gcc-$(GCC_VERSION).tar.xz
	mkdir $(GCC_BUILD)
	cd $(GCC_BUILD)/ && ../gcc-$(GCC_VERSION)/configure \
		--prefix="$(TOOLCHAIN_PREFIX)" \
		--target=$(TARGET) \
		--disable-nls \
		--enable-languages=c,c++ \
		--without-headers
	$(MAKE) -j6 -C $(GCC_BUILD) all-gcc all-target-libgcc
	$(MAKE) -C $(GCC_BUILD) install-gcc install-target-libgcc


