# Top-level Makefile for QUniBoot project
#
# This Makefile effectively wraps the standard BuildRoot Makefile. It directly handles
# some precursor targets itself, such as downloading and configuring BuildRoot, and
# passes other targets (including 'all') to the BuildRoot Makefile. Because of this,
# you can use any of the standard BuildRoot make targets with this Makefile.
#
#
# SELECTING THE TARGET DEVICE
#
# The target QUniBoot device (either 'unibone' or 'qbone') can be specified using the
# QUNIBOOT_TARGET make variable.  E.g.:
#
#     make QUNIBOOT_TARGET=qbone all
#
# If omitted, the Makefile builds QUniBoot images for a UniBone system.
#
# Note that you must do a 'make distclean' when switching target devices.
#
#
# USEFUL MAKE TARGETS
#
#    download-buildroot  -- Download the BuildRoot package file from buildroot.org.
#
#    stage-buildroot     -- Unpack the BuildRoot package and apply QUniBoot-specific patches.
#
#    configure-buildroot -- Configure BuildRoot for building QUniBoot images for the target device.
#
#    all                 -- Download, unpack and configure BuildRoot, and then build QUniBoot
#                           images for the target device.
#
#    clean               -- Delete all build products including build, host, staging and
#                           target directories, along with images and the toolchain, and
#                           Note that this does NOT remove BuildRoot itself or the BuildRoot
#                           configuration.
#
#    distclean           -- Remove all build products along with BuildRoot and its configuration.
#
#    clean-target        -- Remove just the BuildRoot 'output/target' directory (the template for
#                           the root filesystem), forcing it to be rebuilt on the next invocation.
#
#    clean-ccache        -- Remove the cache directory used by ccache.
#
#    <package>-rebuild   -- Force a rebuild of the specified package.
#
#    <package>-dirclean  -- Remove build products for the specified package.
#

TOP_DIR                := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
BUILDROOT_DIR           = $(TOP_DIR)/buildroot
DOWNLOAD_DIR            = $(TOP_DIR)/dl
CONFIG_DIR              = $(TOP_DIR)/configs
PATCHES_DIR             = $(TOP_DIR)/patches
OUTPUT_DIR              = $(TOP_DIR)/output

BUILDROOT_PACKAGE_URL   = https://buildroot.org/downloads/buildroot-2025.02.13.tar.xz
BUILDROOT_PACKAGE_FILE  = $(shell basename $(BUILDROOT_PACKAGE_URL))

BUILDROOT_MAKE_ARGS     = -C $(BUILDROOT_DIR) \
                          O=$(OUTPUT_DIR) \
                          BR2_EXTERNAL=$(TOP_DIR) \
                          BR2_DEFCONFIG=$(CONFIG_DIR)/qunibone_defconfig \
                          BR2_GLOBAL_PATCH_DIR=$(PATCHES_DIR) \
                          BR2_DL_DIR=$(DOWNLOAD_DIR)

ifeq ($(QUNIBOOT_TARGET),unibone)
BUILDROOT_MAKE_ARGS    += BR2_PACKAGE_QUNIBONE_PLATFORM_UNIBUS=y BR2_PACKAGE_QUNIBONE_PLATFORM_QBUS=n
else
ifeq ($(QUNIBOOT_TARGET),qbone)
BUILDROOT_MAKE_ARGS    += BR2_PACKAGE_QUNIBONE_PLATFORM_UNIBUS=n BR2_PACKAGE_QUNIBONE_PLATFORM_QBUS=y
else
ifdef QUNIBOOT_TARGET
$(warning Unknown QUNIBOOT_TARGET: $(QUNIBOOT_TARGET))
$(warning Please specify one of 'unibone' or 'qbone')
$(error )
endif
endif
endif

.PHONY : download-buildroot stage-buildroot configure-buildroot clean-target all distclean
.DEFAULT_GOAL := all

download-buildroot : $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE)

$(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE) :
	mkdir -p $(DOWNLOAD_DIR)
	wget -O $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE) $(BUILDROOT_PACKAGE_URL)

stage-buildroot $(BUILDROOT_DIR) : $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE)
	mkdir -p $(BUILDROOT_DIR)
	tar -C $(BUILDROOT_DIR) --strip-components=1 -xf $(DOWNLOAD_DIR)/$(BUILDROOT_PACKAGE_FILE)
	for p in $(PATCHES_DIR)/buildroot/*.patch; do \
		patch -d $(BUILDROOT_DIR) -p1 < $$p; \
	done

configure-buildroot $(OUTPUT_DIR)/.config : $(BUILDROOT_DIR)
	$(MAKE) $(BUILDROOT_MAKE_ARGS) qunibone_defconfig

clean-target :
	rm -rf $(OUTPUT_DIR)/target $(OUTPUT_DIR)/build/*/.stamp_target_installed

clean-ccache :
	rm -rf $(TOP_DIR)/.buildroot-ccache

all : $(OUTPUT_DIR)/.config
	$(MAKE) $(BUILDROOT_MAKE_ARGS) all

distclean :
	[ -f $(BUILDROOT_DIR)/Makefile ] && $(MAKE) $(BUILDROOT_MAKE_ARGS) distclean
	rm -rf $(BUILDROOT_DIR)

# Explicitly do nothing for automatic 'Makefile' target.
# This prevents the implicit rule below from trigging for the 'Makefile' target.
Makefile : ;

# Pass all other targets to BuildRoot's makefile
% : $(OUTPUT_DIR)/.config
	$(MAKE) $(BUILDROOT_MAKE_ARGS) $@
