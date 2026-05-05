#!/bin/bash

APP_TARGET_DIR=$(realpath "${TARGET_DIR}/../app-target")

echo "Generating app-target directory"
mkdir -p ${APP_TARGET_DIR}
cp -a "${TARGET_DIR}/root/." "${APP_TARGET_DIR}/"
find "${TARGET_DIR}/root" -mindepth 1 -delete

echo "Generating app filesystem image appfs.ext4"
mkfs.ext4 -N 0 -m 0 -L "APPFS" -I 256 -O ^64bit -d "${APP_TARGET_DIR}" "${BINARIES_DIR}/appfs.ext4" 1024M
