LIBT3WINDOW_VERSION = 0.4.2
LIBT3WINDOW_SITE = https://os.ghalkes.nl/dist
LIBT3WINDOW_SOURCE = libt3window-$(LIBT3WINDOW_VERSION).tar.bz2
LIBT3WINDOW_LICENSE = GPL-3.0-only
LIBT3WINDOW_LICENSE_FILES = COPYING

LIBT3WINDOW_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf \
	libt3config \
	libtranscript \
	libunistring \
	ncurses

# --host enables the cross-compilation mode of the configure script, which
# takes the target compiler from the target-configured libtool script
# (host-cross-libtool package), so $(HOST_DIR)/bin is put on the PATH. The
# Buildroot pkg-config wrapper is passed explicitly, and its staging
# directory results are recorded in the generated Makefile.
define LIBT3WINDOW_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--without-gettext \
		PKG_CONFIG=$(HOST_DIR)/bin/pkg-config
endef

# The generated Makefile runs the libtool script by name, so
# $(HOST_DIR)/bin must be on the PATH during make.
define LIBT3WINDOW_BUILD_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D)
endef

LIBT3WINDOW_INSTALL_STAGING = YES

define LIBT3WINDOW_INSTALL_STAGING_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR)
endef

# Install only the shared library. Build-time files (headers, pkg-config
# file, documentation) are kept out of the target.
define LIBT3WINDOW_INSTALL_TARGET_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/include/t3 $(TARGET_DIR)/usr/share/doc/libt3window
	rm -f $(TARGET_DIR)/usr/lib/libt3window.la
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libt3window.pc
endef

$(eval $(generic-package))
