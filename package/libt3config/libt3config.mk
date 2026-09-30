LIBT3CONFIG_VERSION = 1.0.0
LIBT3CONFIG_SITE = https://os.ghalkes.nl/dist
LIBT3CONFIG_SOURCE = libt3config-$(LIBT3CONFIG_VERSION).tar.bz2
LIBT3CONFIG_LICENSE = GPL-3.0-only
LIBT3CONFIG_LICENSE_FILES = COPYING

LIBT3CONFIG_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf

# The configure script assumes a native build, so the target compiler, the
# large file support flag, and the target-configured libtool script (from
# the host-cross-libtool package) are passed explicitly. $(HOST_DIR)/bin is
# put on the PATH so the pkg-config probe in configure runs the Buildroot
# pkg-config wrapper, which reports the staging directory paths that the
# cross compiler accepts. configure records the compiler and libtool paths
# in the generated Makefile, so make runs without a modified PATH.
define LIBT3CONFIG_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--prefix=/usr \
		--without-gettext \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		LFSFLAGS="-D_FILE_OFFSET_BITS=64" \
		LIBTOOL="$(HOST_DIR)/bin/$(GNU_TARGET_NAME)-libtool"
endef

define LIBT3CONFIG_BUILD_CMDS
	$(MAKE) -C $(@D)
endef

LIBT3CONFIG_INSTALL_STAGING = YES

define LIBT3CONFIG_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR)
endef

# Install only the shared library. Build-time files (headers, pkg-config
# file, documentation) are kept out of the target.
define LIBT3CONFIG_INSTALL_TARGET_CMDS
	$(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/include/t3 $(TARGET_DIR)/usr/share/doc/libt3config
	rm -f $(TARGET_DIR)/usr/lib/libt3config.la
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libt3config.pc
endef

$(eval $(generic-package))
