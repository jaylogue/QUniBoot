RETRO_FUSE_SITE = https://github.com/jaylogue/retro-fuse.git
RETRO_FUSE_SITE_METHOD = git
RETRO_FUSE_VERSION = HEAD
RETRO_FUSE_LICENSE = Apache License
RETRO_FUSE_LICENSE_FILES = LICENSE.txt

RETRO_FUSE_DEPENDENCIES = libfuse

define RETRO_FUSE_BUILD_CMDS
    @echo Building retro-fuse package
    $(MAKE) CC=$(TARGET_CC) -C $(@D)
endef

define RETRO_FUSE_INSTALL_TARGET_CMDS
    @echo Installing retro-fuse executables into /usr/local/bin
    $(MAKE) CC=$(TARGET_CC) INSTALL="install --strip-program=$(TARGET_STRIP)" DESTDIR=$(TARGET_DIR) -C $(@D) install
endef

$(eval $(generic-package))
