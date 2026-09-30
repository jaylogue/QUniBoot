LIBTRANSCRIPT_VERSION = 0.3.4
LIBTRANSCRIPT_SITE = https://os.ghalkes.nl/dist
LIBTRANSCRIPT_SOURCE = libtranscript-$(LIBTRANSCRIPT_VERSION).tar.bz2
LIBTRANSCRIPT_LICENSE = GPL-3.0-only
LIBTRANSCRIPT_LICENSE_FILES = COPYING

LIBTRANSCRIPT_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf

# --host enables the cross-compilation mode of the configure script, which
# takes the target compiler from the target-configured libtool script
# (host-cross-libtool package), so $(HOST_DIR)/bin is put on the PATH. The
# Buildroot pkg-config wrapper is passed explicitly, and its staging
# directory results are recorded in the generated Makefile.
define LIBTRANSCRIPT_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--without-gettext \
		PKG_CONFIG=$(HOST_DIR)/bin/pkg-config
endef

# The generated Makefile runs the libtool script by name, so
# $(HOST_DIR)/bin must be on the PATH during make.
define LIBTRANSCRIPT_BUILD_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D)
endef

LIBTRANSCRIPT_INSTALL_STAGING = YES

# The upstream install creates the character set table symlinks with
# plain ln, so the data directory must not exist when the install runs.
define LIBTRANSCRIPT_INSTALL_STAGING_CMDS
	rm -rf $(STAGING_DIR)/usr/lib/transcript1
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR)
endef

# Install the shared library and the character set table data in
# /usr/lib/transcript1. Build-time files (headers, pkg-config file,
# documentation) are kept out of the target.
define LIBTRANSCRIPT_INSTALL_TARGET_CMDS
	rm -rf $(TARGET_DIR)/usr/lib/transcript1
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/include/transcript $(TARGET_DIR)/usr/share/doc/libtranscript
	rm -f $(TARGET_DIR)/usr/lib/libtranscript.la
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libtranscript.pc
endef

$(eval $(generic-package))
