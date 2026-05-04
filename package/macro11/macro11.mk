MACRO11_SITE = https://gitlab.com/Rhialto/macro11.git
MACRO11_SITE_METHOD = git
MACRO11_VERSION = HEAD
MACRO11_LICENSE = BSD 3-Clause License
MACRO11_LICENSE_FILES = LICENSE

MACRO11_DEPENDENCIES = 


define MACRO11_BUILD_CMDS
    @# Building MACRO-11
    $(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) macro11 dumpobj
endef

define MACRO11_INSTALL_TARGET_CMDS
    @# Installing MACRO-11 executables into /usr/local/bin
    $(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/local/bin $(@D)/{macro11,dumpobj} 
endef

$(eval $(generic-package))
