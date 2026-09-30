LIBT3KEY_VERSION = 0.2.11
LIBT3KEY_SITE = https://os.ghalkes.nl/dist
LIBT3KEY_SOURCE = libt3key-$(LIBT3KEY_VERSION).tar.bz2
LIBT3KEY_LICENSE = GPL-3.0-only
LIBT3KEY_LICENSE_FILES = COPYING

LIBT3KEY_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf \
	libt3config \
	ncurses

# --host enables the cross-compilation mode of the configure script, which
# takes the target compiler from the target-configured libtool script
# (host-cross-libtool package), so $(HOST_DIR)/bin is put on the PATH. The
# Buildroot pkg-config wrapper is passed explicitly, and its staging
# directory results are recorded in the generated Makefile.
define LIBT3KEY_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--without-gettext \
		--without-t3learnkeys \
		PKG_CONFIG=$(HOST_DIR)/bin/pkg-config
endef

# The generated Makefile runs the libtool script by name, so
# $(HOST_DIR)/bin must be on the PATH during make.
define LIBT3KEY_BUILD_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D) lib
endef

# The upstream install target runs the t3keyc program, which is a target
# binary and cannot be executed on the build machine. The t3keyc and
# t3learnkeys programs are therefore not built or installed, and the key
# mapping data is installed directly.

# Install the shared library, headers and pkg-config file to staging.
LIBT3KEY_INSTALL_STAGING = YES

define LIBT3KEY_INSTALL_STAGING_CMDS
	$(INSTALL) -d $(STAGING_DIR)/usr/lib
	$(HOST_DIR)/bin/$(GNU_TARGET_NAME)-libtool --mode=install \
		install -s -m 0644 $(@D)/src/libt3key.la $(STAGING_DIR)/usr/lib
	rm -f $(STAGING_DIR)/usr/lib/libt3key.la
	$(INSTALL) -D -m 0644 -t $(STAGING_DIR)/usr/include/t3key \
		$(@D)/src/key.h $(@D)/src/key_api.h $(@D)/src/key_errors.h
	$(INSTALL) -D -m 0644 $(@D)/libt3key.pc $(STAGING_DIR)/usr/lib/pkgconfig/
endef

# Install the shared library and the key mapping data in
# /usr/share/libt3key1. In addition to the key mapping files, the
# terminal name aliases listed in the aka field of each file are created
# as symlinks, as the t3keyc program would have done on the target.
define LIBT3KEY_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib
	$(HOST_DIR)/bin/$(GNU_TARGET_NAME)-libtool --mode=install \
		install -s -m 0644 $(@D)/src/libt3key.la $(TARGET_DIR)/usr/lib
	rm -f $(TARGET_DIR)/usr/lib/libt3key.la
	$(INSTALL) -d $(TARGET_DIR)/usr/share/libt3key1
	$(INSTALL) -m 0644 -t $(TARGET_DIR)/usr/share/libt3key1 $(@D)/src/database/*
	@for f in $(@D)/src/database/*; do \
		base=$$(basename $$f); \
		grep -q '^aka' $$f || continue; \
		grep '^aka' $$f | grep -oE '"[^"]+"' | tr -d '"' \
			| while read -r alias; do \
				[ -n "$$alias" ] && \
					ln -sf $$base $(TARGET_DIR)/usr/share/libt3key1/$$alias; \
			done; \
	done
endef

$(eval $(generic-package))
