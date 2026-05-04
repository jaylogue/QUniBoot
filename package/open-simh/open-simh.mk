OPEN_SIMH_SITE = https://github.com/open-simh/simh.git
OPEN_SIMH_SITE_METHOD = git
OPEN_SIMH_VERSION = HEAD
OPEN_SIMH_LICENSE = BSD 3-Clause License
OPEN_SIMH_LICENSE_FILES = LICENSE

OPEN_SIMH_DEPENDENCIES = ncurses libpcap libedit pcre

# Convert makefile to unix line-endings so that patches apply cleanly
define OPEN_SIMH_FIXUP_MAKEFILE
    tr -d '\r' < $(@D)/makefile > $(@D)/makefile.tmp
    mv $(@D)/makefile.tmp $(@D)/makefile
endef

OPEN_SIMH_PRE_PATCH_HOOKS+=OPEN_SIMH_FIXUP_MAKEFILE

define OPEN_SIMH_BUILD_CMDS
    @echo Building Open SIMH host tools
    $(MAKE) GCC="$(HOSTCC) $(HOST_CFLAGS)" TESTS=0 -C $(@D) BIN/buildtools/BuildROMs

    @echo Building Open SIMH PDP-11 sim
    $(MAKE) GCC="$(TARGET_CC) $(TARGET_CFLAGS)" TESTS=0 -C $(@D) pdp11
endef

define OPEN_SIMH_INSTALL_TARGET_CMDS
    @echo Installing Open SIMH executables into /usr/local/bin
    $(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/local/bin $(@D)/BIN/pdp11
endef

$(eval $(generic-package))
