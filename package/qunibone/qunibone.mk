QUNIBONE_SITE = https://github.com/j-hoppe/QUniBone.git
QUNIBONE_SITE_METHOD = git
QUNIBONE_VERSION = HEAD
QUNIBONE_LICENSE = BSD 2-Clause License
QUNIBONE_LICENSE_FILES = LICENSE

QUNIBONE_DEPENDENCIES = host-ti-cgt-pru linux

QUNIBONE_INSTALL_DIR=$(TARGET_DIR)/qunibone

# Choice option
ifeq ($(BR2_PACKAGE_QUNIBONE_PLATFORM_UNIBUS),y)
QUNIBONE_PLATFORM=UNIBUS
QUNIBONE_PLATFORM_SUFFIX=_u
endif

ifeq ($(BR2_PACKAGE_QUNIBONE_PLATFORM_QBUS),y)
QUNIBONE_PLATFORM=QBUS
QUNIBONE_PLATFORM_SUFFIX=_q
endif

ifeq ($(BR2_PACKAGE_QUNIBONE_DEBUG),y)
QUNIBONE_MAKE_CONFIGURATION=DBG
else
QUNIBONE_MAKE_CONFIGURATION=RELEASE
endif

define QUNIBONE_BUILD_CMDS
    @echo Building QUniBone software
    $(TARGET_CONFIGURE_OPTS) \
    QUNIBONE_DIR=$(@D) \
    QUNIBONE_PLATFORM=$(QUNIBONE_PLATFORM) \
    MAKE_CONFIGURATION=$(QUNIBONE_MAKE_CONFIGURATION) \
    MAKE_TARGET_ARCH=BBB \
    BBB_CC="$(TARGET_CC) -I$(STAGING_DIR)/usr/include/tirpc" \
    PRU_CGT=$(HOST_DIR)/usr/share/ti-cgt-pru \
    LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib -ltirpc" \
    $(MAKE) -C $(@D)/10.03_app_demo/2_src -j1

    @echo Compiling QUniBone DTS overlay
    $(CPP) -nostdinc \
        -I $(LINUX_DIR)/include \
        -undef -x assembler-with-cpp \
        $(BR2_EXTERNAL_QUNIBONE_PATH)/package/qunibone/qunibone.dtso | \
    $(LINUX_DIR)/scripts/dtc/dtc -@ -I dts -O dtb \
        -o $(@D)/qunibone.dtbo -
endef

define QUNIBONE_INSTALL_TARGET_CMDS
    @echo Installing QUniBone executable into /usr/local/bin
    $(INSTALL) -D -m 0755 $(@D)/10.03_app_demo/4_deploy$(QUNIBONE_PLATFORM_SUFFIX)/demo $(TARGET_DIR)/usr/local/bin/demo

    @echo Creating symlink to QUniBone executable in 10.03_app_demo/4_deploy
    $(INSTALL) -d $(QUNIBONE_INSTALL_DIR)/10.03_app_demo/4_deploy
    ln -fs /usr/local/bin/demo $(QUNIBONE_INSTALL_DIR)/10.03_app_demo/4_deploy/demo

    @echo Installing demo.sh script into home directory
    $(INSTALL) -D -m 0755 $(@D)/demo.sh $(QUNIBONE_INSTALL_DIR)/demo.sh

    @echo Installing QUniBone DTS overlay into images directory
    $(INSTALL) -D -m 0644 $(@D)/qunibone.dtbo $(BINARIES_DIR)/qunibone.dtbo
endef

$(eval $(generic-package))
