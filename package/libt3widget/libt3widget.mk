LIBT3WIDGET_VERSION = 1.2.2
LIBT3WIDGET_SITE = https://os.ghalkes.nl/dist
LIBT3WIDGET_SOURCE = libt3widget-$(LIBT3WIDGET_VERSION).tar.bz2
LIBT3WIDGET_LICENSE = GPL-3.0-only
LIBT3WIDGET_LICENSE_FILES = COPYING

LIBT3WIDGET_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf \
	libt3config \
	libt3key \
	libt3window \
	libtranscript \
	libunistring \
	pcre2

# --host enables the cross-compilation mode of the configure script, which
# takes the target compiler from the target-configured libtool script
# (host-cross-libtool package), so $(HOST_DIR)/bin is put on the PATH. The
# Buildroot pkg-config wrapper is passed explicitly, and its staging
# directory results are recorded in the generated Makefile.
define LIBT3WIDGET_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--without-gettext \
		--without-x11 \
		--without-gpm \
		PKG_CONFIG=$(HOST_DIR)/bin/pkg-config
endef

# The generated Makefile runs the libtool script by name, so
# $(HOST_DIR)/bin must be on the PATH during make.
define LIBT3WIDGET_BUILD_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D)
endef

LIBT3WIDGET_INSTALL_STAGING = YES

define LIBT3WIDGET_INSTALL_STAGING_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR)
endef

# Install only the shared library. Build-time files (headers, pkg-config
# file, documentation) are kept out of the target.
define LIBT3WIDGET_INSTALL_TARGET_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/include/t3 $(TARGET_DIR)/usr/share/doc/libt3widget
	rm -f $(TARGET_DIR)/usr/lib/libt3widget.la
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libt3widget.pc
endef

$(eval $(generic-package))
