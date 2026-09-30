LIBT3HIGHLIGHT_VERSION = 0.5.0
LIBT3HIGHLIGHT_SITE = https://os.ghalkes.nl/dist
LIBT3HIGHLIGHT_SOURCE = libt3highlight-$(LIBT3HIGHLIGHT_VERSION).tar.bz2
LIBT3HIGHLIGHT_LICENSE = GPL-3.0-only
LIBT3HIGHLIGHT_LICENSE_FILES = COPYING

LIBT3HIGHLIGHT_DEPENDENCIES = \
	host-cross-libtool \
	host-pkgconf \
	libt3config \
	pcre2

# The configure script assumes a native build, so the target compiler, the
# large file support flag, and the target-configured libtool script (from
# the host-cross-libtool package) are passed explicitly. $(HOST_DIR)/bin is
# put on the PATH so pkg-config runs as the Buildroot wrapper, which
# reports the staging directory paths that the cross compiler accepts.
define LIBT3HIGHLIGHT_CONFIGURE_CMDS
	cd $(@D) && PATH="$(HOST_DIR)/bin:$$PATH" ./configure \
		--prefix=/usr \
		--without-gettext \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		LFSFLAGS="-D_FILE_OFFSET_BITS=64" \
		LIBTOOL="$(HOST_DIR)/bin/$(GNU_TARGET_NAME)-libtool"
endef

# The generated Makefile calls pkg-config by name, so $(HOST_DIR)/bin must
# be on the PATH during make. The install targets also strip the
# t3highlight binary with install -s, which runs the strip found on the
# PATH, so a local strip that wraps the target strip is created and put
# first on the PATH. This strips the binary with the target strip rather
# than the build machine strip.
define LIBT3HIGHLIGHT_BUILD_CMDS
	rm -rf $(abspath $(@D)/.bin)
	mkdir -p $(abspath $(@D)/.bin)
	ln -sf $(TARGET_STRIP) $(abspath $(@D)/.bin)/strip
	PATH="$(abspath $(@D)/.bin):$(HOST_DIR)/bin:$$PATH" $(MAKE) -C $(@D)
endef

LIBT3HIGHLIGHT_INSTALL_STAGING = YES

define LIBT3HIGHLIGHT_INSTALL_STAGING_CMDS
	PATH="$(abspath $(@D)/.bin):$(HOST_DIR)/bin:$$PATH" \
		$(MAKE) -C $(@D) install DESTDIR=$(STAGING_DIR)
endef

# Install the shared library and the syntax definition data in
# /usr/share/libt3highlight2. Build-time files (headers, pkg-config
# file, documentation), the t3highlight command line tool and its style
# files, and the man page are kept out of the target.
define LIBT3HIGHLIGHT_INSTALL_TARGET_CMDS
	PATH="$(abspath $(@D)/.bin):$(HOST_DIR)/bin:$$PATH" \
		$(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/include/t3 $(TARGET_DIR)/usr/share/doc/libt3highlight
	rm -f $(TARGET_DIR)/usr/bin/t3highlight
	rm -f $(TARGET_DIR)/usr/share/man/man1/t3highlight.1
	-rmdir $(TARGET_DIR)/usr/share/man/man1 $(TARGET_DIR)/usr/share/man 2>/dev/null
	rm -f $(TARGET_DIR)/usr/lib/libt3highlight.la
	rm -f $(TARGET_DIR)/usr/lib/pkgconfig/libt3highlight.pc
	rm -f $(TARGET_DIR)/usr/share/libt3highlight2/*.style
endef

$(eval $(generic-package))
