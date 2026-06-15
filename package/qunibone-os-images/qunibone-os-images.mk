

# 10.02_devices/5_boot
# 10.03_app_demo/4_deploy link to 4_deploy_u or 4_deploy_q
# 10.03_app_demo/5_applications
# 10.03_app_demo/5_applications_q copy to 10.03_app_demo/5_applications
# 10.03_app_demo/5_applications_u copy to 10.03_app_demo/5_applications

QUNIBONE_EXTERNAL_FILES_URL = http://files.retrocmp.com/qunibone
QUNIBONE_OS_IMAGES_DL_DIR = $(DL_DIR)/qunibone-os-images
QUNIBONE_OS_IMAGES_TAR_FILE = $(QUNIBONE_OS_IMAGES_DL_DIR)/qunibone-os-images.tar.gz

define QUNIBONE_OS_IMAGES_PRE_DOWNLOAD
	[ \! -f $(QUNIBONE_OS_IMAGES_TAR_FILE) ] || { \
		echo "QUniBone OS images tar file already exists: $(QUNIBONE_OS_IMAGES_TAR_FILE)"; \
	}
	[ -f $(QUNIBONE_OS_IMAGES_TAR_FILE) ] || { \
		echo "Downloading QUniBone OS images; this may take awhile..."; \
		wget -m -np -nH --cut-dirs=1 -R "index.html*,.URL" -P $(QUNIBONE_OS_IMAGES_DL_DIR)/site-mirror \
			$(QUNIBONE_EXTERNAL_FILES_URL)/10.03_app_demo/5_applications/ \
			$(QUNIBONE_EXTERNAL_FILES_URL)/10.03_app_demo/5_applications_q/ \
			$(QUNIBONE_EXTERNAL_FILES_URL)/10.03_app_demo/5_applications_u/ \
			; \
		echo "Creating OS images tar file: $(QUNIBONE_OS_IMAGES_TAR_FILE)"; \
		tar -C $(QUNIBONE_OS_IMAGES_DL_DIR)/site-mirror -czf $(QUNIBONE_OS_IMAGES_TAR_FILE) . ; \
	}
endef

QUNIBONE_OS_IMAGES_PRE_DOWNLOAD_HOOKS+=QUNIBONE_OS_IMAGES_PRE_DOWNLOAD

define QUNIBONE_OS_IMAGES_INSTALL_TARGET_CMDS
	@[ -f $(QUNIBONE_OS_IMAGES_TAR_FILE) ] || { \
		echo "QUniBone OS images tar file not found: $(QUNIBONE_OS_IMAGES_TAR_FILE)"; \
		false; \
	}

	@echo "Installing QUniBone OS image files"
	tar -C $(QUNIBONE_INSTALL_DIR) -xvf $(QUNIBONE_OS_IMAGES_TAR_FILE) --xform 's|5_applications_[qu]|5_applications|' \
		./10.03_app_demo/5_applications \
		./10.03_app_demo/5_applications$(QUNIBONE_PLATFORM_SUFFIX)
	
	@echo "Setting script permissions"
	@find $(QUNIBONE_INSTALL_DIR)/10.03_app_demo/5_applications -type f -name \*.sh -exec chmod +x {} \;
	
	@echo "Creating script shortcuts"
	@(cd $(QUNIBONE_INSTALL_DIR); find ./10.03_app_demo/5_applications -type f -name \*.sh -exec ln -sf {} . \;)
endef

$(eval $(generic-package))