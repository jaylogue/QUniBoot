# 10.02_devices/5_boot

QUNIBONE_EXTERNAL_FILES_URL = http://files.retrocmp.com/qunibone
QUNIBONE_BOOT_ROMS_DL_DIR = $(DL_DIR)/qunibone-boot-roms
QUNIBONE_BOOT_ROMS_TAR_FILE = $(QUNIBONE_BOOT_ROMS_DL_DIR)/qunibone-boot-roms.tar.gz

define QUNIBONE_BOOT_ROMS_PRE_DOWNLOAD
	[ \! -f $(QUNIBONE_BOOT_ROMS_TAR_FILE) ] || { \
		echo "QUniBone boot ROMs tar file already exists: $(QUNIBONE_BOOT_ROMS_TAR_FILE)"; \
	}
	[ -f $(QUNIBONE_BOOT_ROMS_TAR_FILE) ] || { \
		echo "Downloading PDP-11 boot ROMs; this may take awhile..."; \
		wget -m -np -nH --cut-dirs=1 -R "index.html*,.URL" -P $(QUNIBONE_BOOT_ROMS_DL_DIR)/site-mirror \
			$(QUNIBONE_EXTERNAL_FILES_URL)/10.02_devices/5_boot/ \
			; \
		echo "Creating boot ROMs tar file: $(QUNIBONE_BOOT_ROMS_TAR_FILE)"; \
		tar -C $(QUNIBONE_BOOT_ROMS_DL_DIR)/site-mirror -czf $(QUNIBONE_BOOT_ROMS_TAR_FILE) . ; \
	}
endef

QUNIBONE_BOOT_ROMS_PRE_DOWNLOAD_HOOKS+=QUNIBONE_BOOT_ROMS_PRE_DOWNLOAD

define QUNIBONE_BOOT_ROMS_INSTALL_TARGET_CMDS
	@[ -f $(QUNIBONE_BOOT_ROMS_TAR_FILE) ] || { \
		echo "QUniBone boot ROMs tar file not found: $(QUNIBONE_BOOT_ROMS_TAR_FILE)"; \
		false; \
	}

	@echo "Installing PDP-11 boot ROMs"
	tar -C $(QUNIBONE_INSTALL_DIR) -xvf $(QUNIBONE_BOOT_ROMS_TAR_FILE)
endef

$(eval $(generic-package))
