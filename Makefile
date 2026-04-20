TOP_DIR                 := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
BUILDROOT_DIR           = $(TOP_DIR)/buildroot
DOWNLOAD_DIR            = $(TOP_DIR)/dl
CONFIG_DIR              = $(TOP_DIR)/config
PATCHES_DIR             = $(TOP_DIR)/patches
OUTPUT_DIR              = $(TOP_DIR)/output

BUILDROOT_PACKAGE_URL   = https://buildroot.org/downloads/buildroot-2025.02.12.tar.xz
BUILDROOT_PACKAGE_FILE  = $(shell basename $(BUILDROOT_PACKAGE_URL))

BUILDROOT_MAKE_ARGS     = -C $(BUILDROOT_DIR) \
                          O=$(OUTPUT_DIR) \
                          BR2_EXTERNAL=$(TOP_DIR) \
                          BR2_DEFCONFIG=$(CONFIG_DIR)/qunibone_defconfig \
                          BR2_GLOBAL_PATCH_DIR=$(PATCHES_DIR) \
                          BR2_DL_DIR=$(DOWNLOAD_DIR)

.PHONY : download-buildroot stage-buildroot configure-buildroot
.DEFAULT_GOAL := all

download-buildroot : $(TOP_DIR)/$(BUILDROOT_PACKAGE_FILE)

$(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE) :
	mkdir -p $(DOWNLOAD_DIR)
	wget -O $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE) $(BUILDROOT_PACKAGE_URL)

stage-buildroot $(BUILDROOT_DIR) :
	mkdir -p $(BUILDROOT_DIR)
	tar -C $(BUILDROOT_DIR) --strip-components=1 -xf $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE)
	for p in $(PATCHES_DIR)/buildroot/*.patch; do \
		patch -d $(BUILDROOT_DIR) -p1 < $$p; \
	done

configure-buildroot $(OUTPUT_DIR)/.config : $(BUILDROOT_DIR)
	$(MAKE) $(BUILDROOT_MAKE_ARGS) qunibone_defconfig

all: $(OUTPUT_DIR)/.config
	$(MAKE) $(BUILDROOT_MAKE_ARGS) all

Makefile: ;
	# Explicitly do nothing for automatic 'Makefile' target.
	# This prevents the implicit rule below from trigging for the 'Makefile' target.

% : $(OUTPUT_DIR)/.config
	$(MAKE) $(BUILDROOT_MAKE_ARGS) $@
