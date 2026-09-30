TILDE_VERSION = 1.1.3
TILDE_SITE = https://os.ghalkes.nl/dist
TILDE_SOURCE = tilde-$(TILDE_VERSION).tar.bz2
TILDE_LICENSE = GPL-3.0-only
TILDE_LICENSE_FILES = COPYING

TILDE_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf \
	libt3config \
	libt3highlight \
	libt3widget \
	libtranscript \
	libunistring

# --host enables the cross-compilation mode of the configure script. tilde
# builds a plain executable rather than a libtool library, so its
# cross-compilation mode cannot derive the target compiler from the
# libtool script, and the compiler is passed explicitly. The Buildroot
# pkg-config wrapper is passed explicitly, and its staging directory
# results are recorded in the generated Makefile, so make and install run
# without a modified PATH.
define TILDE_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--without-gettext \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		PKG_CONFIG=$(HOST_DIR)/bin/pkg-config
endef

define TILDE_BUILD_CMDS
	$(MAKE) -C $(@D)
endef

# Install only the tilde executable and the base.config configuration
# file, which tilde reads at start up. Documentation and the man page
# are kept out of the target.
define TILDE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/src/tilde $(TARGET_DIR)/usr/bin/tilde
	$(INSTALL) -D -m 0644 $(@D)/src/base.config $(TARGET_DIR)/usr/share/tilde/base.config
endef

$(eval $(generic-package))
