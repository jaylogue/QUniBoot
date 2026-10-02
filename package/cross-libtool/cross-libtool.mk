HOST_CROSS_LIBTOOL_VERSION = 1.0
HOST_CROSS_LIBTOOL_SITE = $(HOST_CROSS_LIBTOOL_PKGDIR)/src
HOST_CROSS_LIBTOOL_SITE_METHOD = local
HOST_CROSS_LIBTOOL_LICENSE = GPL-2.0+ (libtool script)
HOST_CROSS_LIBTOOL_AUTORECONF = YES

# The generated libtool script runs on the build machine but compiles and
# links for the target. A host-configure passes neither the cross triplets
# nor the target toolchain, so both are supplied here.
HOST_CROSS_LIBTOOL_CONF_OPTS = \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--target=$(GNU_TARGET_NAME) \
	--with-sysroot=$(STAGING_DIR)
HOST_CROSS_LIBTOOL_CONF_ENV = \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	AR="$(TARGET_AR)" \
	AS="$(TARGET_AS)" \
	LD="$(TARGET_LD)" \
	NM="$(TARGET_NM)" \
	RANLIB="$(TARGET_RANLIB)" \
	STRIP="$(TARGET_STRIP)" \
	OBJCOPY="$(TARGET_OBJCOPY)" \
	OBJDUMP="$(TARGET_OBJDUMP)" \
	READELF="$(TARGET_READELF)" \
	CPP="$(TARGET_CPP)" \
	CPPFLAGS="$(TARGET_CPPFLAGS)" \
	CFLAGS="$(TARGET_CFLAGS)" \
	CXXFLAGS="$(TARGET_CXXFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)"

# configure.ac generates no Makefile, so there is nothing to build
define HOST_CROSS_LIBTOOL_BUILD_CMDS
	true
endef

define HOST_CROSS_LIBTOOL_INSTALL_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libtool \
		$(HOST_DIR)/bin/$(GNU_TARGET_NAME)-libtool
endef

$(eval $(host-autotools-package))
