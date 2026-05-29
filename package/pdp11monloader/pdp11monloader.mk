PDP11MONLOADER_SITE = https://github.com/j-hoppe/pdp11monloader.git
PDP11MONLOADER_SITE_METHOD = git
PDP11MONLOADER_VERSION = HEAD
PDP11MONLOADER_LICENSE = BSD 3-Clause License
PDP11MONLOADER_LICENSE_FILES = LICENSE

PDP11MONLOADER_DEPENDENCIES = 

# Convert source files to unix line-endings so that patches apply cleanly
define PDP11MONLOADER_CONVERT_LINE_ENDINGS
    cd $(@D); for f in *.c *.h makefile; do \
        tr -d '\r' < $$f > $$f.tmp; \
        mv $$f.tmp $$f; \
    done
endef
PDP11MONLOADER_PRE_PATCH_HOOKS+=PDP11MONLOADER_CONVERT_LINE_ENDINGS

define PDP11MONLOADER_BUILD_CMDS
    @# Building pdp11monloader
    $(TARGET_CONFIGURE_OPTS) \
    MAKE_TARGET_ARCH=BBB \
    BBB_CC="$(TARGET_CC)" \
    $(MAKE) -C $(@D) all
endef

define PDP11MONLOADER_INSTALL_TARGET_CMDS
    @# Installing pdp11monloader executable into /usr/local/bin
    $(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/local/bin $(@D)/bin-bbb/pdp11monloader
endef

$(eval $(generic-package))
