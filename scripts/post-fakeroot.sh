#!/bin/bash
#
# Post-fakeroot script
#
# This script is invoked immediately prior to root filesystem image generation,
# within the context of a fakeroot(1) environment. Its purpose is to segregate
# the files that go into the app filesystem (essentially, everything in the root
# home directory) and generate the app filesystem image itself. After this is
# done, the normal BuildRoot process generates the root filesystem from the
# remaining files.
# 

# NOTE: The app fs partition is sized to just fit the existing qunibone app
# data files. This minimizes the final SD card image size, and therefore the
# associated write time. On first boot, the partition is automatically expanded
# to fill available space on the user's SD card.
APP_FS_SIZE=512M

APP_TARGET_DIR=$(realpath "${TARGET_DIR}/../app-target")

echo "Generating app-target directory"
mkdir -p ${APP_TARGET_DIR}
cp -a "${TARGET_DIR}/root/." "${APP_TARGET_DIR}/"
find "${TARGET_DIR}/root" -mindepth 1 -delete

echo "Generating app filesystem image appfs.ext4"
rm -f "${BINARIES_DIR}/appfs.ext4"
truncate -s ${APP_FS_SIZE} "${BINARIES_DIR}/appfs.ext4"
mkfs.ext4 -N 0 -m 0 -L "APPFS" -I 256 -O ^64bit -d "${APP_TARGET_DIR}" "${BINARIES_DIR}/appfs.ext4" ${APP_FS_SIZE}
