XXDPDIR_SITE = https://github.com/AK6DN/xxdpdir.git
XXDPDIR_SITE_METHOD = git
XXDPDIR_VERSION = HEAD
XXDPDIR_LICENSE = BSD 3-Clause License
XXDPDIR_LICENSE_FILES = LICENSE

XXDPDIR_DEPENDENCIES = perl

define XXDPDIR_INSTALL_TARGET_CMDS
    @# Installing xxdpdir scripts
    $(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/local/bin $(@D)/xxdpdir.pl
    ln -sf xxdpdir.pl $(TARGET_DIR)/usr/local/bin/xxdpdir
    SITE_PATH=$$(grep -oP "installsitelib='\\K[^']+" $(TARGET_DIR)/usr/lib/perl5/5.*/arm-linux/Config_heavy.pl); \
        $(INSTALL) -D -m 0644 -t $(TARGET_DIR)$${SITE_PATH} $(@D)/XXDP.pm
endef

$(eval $(generic-package))
