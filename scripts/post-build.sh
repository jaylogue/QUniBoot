#!/usr/bin/bash

env

if [[ $# -lt 1 ]]; then
    echo "Missing target directory argument"
    exit 1
fi
TARGET_DIR=$1

if [[ $# -lt 2 ]]; then
    echo "Missing platform argument"
    exit 1
fi
QUNIBONE_PLATFORM=$2

if [[ "${QUNIBONE_PLATFORM}" = "UNIBUS" ]]; then
    PLATFORM_NAME='UniBone'
elif [[ "${QUNIBONE_PLATFORM}" = "QBUS" ]]; then
    PLATFORM_NAME='QBone'
else
    echo "Invalid platform argument"
    exit 1
fi
PLATFORM_NAME_UC=$(echo ${PLATFORM_NAME} | tr '[:lower:]' '[:upper:]')
PLATFORM_NAME_LC=$(echo ${PLATFORM_NAME} | tr '[:upper:]' '[:lower:]')

echo "Setting hostname"
echo ${PLATFORM_NAME_LC} > ${TARGET_DIR}/etc/hostname

echo "Setting welcome message"
echo "Wecome to ${PLATFORM_NAME}" > ${TARGET_DIR}/etc/issue

if [[ ! -f "${TARGET_DIR}/etc/init.d/DISABLED.S50crond" ]]; then
    echo "Disabling cron"
    mv ${TARGET_DIR}/etc/init.d/S50crond ${TARGET_DIR}/etc/init.d/DISABLED.S50crond
fi

echo "Customizing extlinux.conf"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBONE_PATH}/configs/extlinux.conf ${BINARIES_DIR}/extlinux/extlinux.conf
sed -i -e "s/label \+qunibone/label ${PLATFORM_NAME_LC}/" ${BINARIES_DIR}/extlinux/extlinux.conf

echo "Customizing genimage.cfg"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBONE_PATH}/configs/genimage.cfg ${BINARIES_DIR}/genimage.cfg
sed -i -e "s/label = \"QUNIBONE\"/label = \"${PLATFORM_NAME_UC}\"/" ${BINARIES_DIR}/genimage.cfg
