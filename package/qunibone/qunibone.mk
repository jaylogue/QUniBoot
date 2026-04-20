QUNIBONE_SITE = https://github.com/j-hoppe/QUniBone.git
QUNIBONE_SITE_METHOD = git
QUNIBONE_VERSION = HEAD
QUNIBONE_LICENSE = BSD 2-Clause License
QUNIBONE_LICENSE_FILES = LICENSE

QUNIBONE_DEPENDENCIES = host-ti-cgt-pru

# 2. Compile the source
define QUNIBONE_BUILD_CMDS
    $(TARGET_CONFIGURE_OPTS) \
    QUNIBONE_DIR=$(@D) \
    QUNIBONE_PLATFORM=UNIBUS \
    QUNIBONE_PLATFORM_SUFFIX=_u \
    MAKE_CONFIGURATION=RELEASE \
    MAKE_TARGET_ARCH=BBB \
    BBB_CC="$(TARGET_CC) -I$(STAGING_DIR)/usr/include/tirpc" \
    PRU_CGT=$(HOST_DIR)/usr/share/ti-cgt-pru \
    LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib -ltirpc" \
    $(MAKE) -C $(@D)/10.03_app_demo/2_src -j1
endef

# 3. Install to the target rootfs staging area
define QUNIBONE_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/10.03_app_demo/4_deploy_u/demo $(TARGET_DIR)/root/demo
endef

$(eval $(generic-package))