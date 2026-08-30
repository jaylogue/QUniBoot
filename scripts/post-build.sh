#!/usr/bin/bash

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

if [[ ! -f "${TARGET_DIR}/etc/init.d/DISABLED.S50crond" ]]; then
    echo "Disabling cron"
    mv ${TARGET_DIR}/etc/init.d/S50crond ${TARGET_DIR}/etc/init.d/DISABLED.S50crond
fi

if [[ ! -f "${TARGET_DIR}/etc/init.d/DISABLED.S50telnet" ]]; then
    echo "Disabling telnetd"
    mv ${TARGET_DIR}/etc/init.d/S50telnet ${TARGET_DIR}/etc/init.d/DISABLED.S50telnet
fi

echo "Customizing welcome message"
cat > ${TARGET_DIR}/etc/issue <<EOF
Welcome to ${PLATFORM_NAME}

EOF

echo "Customizing extlinux.conf"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBONE_PATH}/board/qunibone/extlinux.conf ${BINARIES_DIR}/extlinux/extlinux.conf
sed -i -e "s/label \+qunibone/label ${PLATFORM_NAME_LC}/" ${BINARIES_DIR}/extlinux/extlinux.conf

echo "Installing autoconfig-example.txt"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBONE_PATH}/board/qunibone/autoconfig-example.txt ${BINARIES_DIR}/autoconfig-example.txt

echo "Restoring busybox vi"
ln -sf busybox ${TARGET_DIR}/bin/vi

echo "Linking root directory"
if [[ -e ${TARGET_DIR}/root && ! -L ${TARGET_DIR}/root ]]; then
    rm -rf ${TARGET_DIR}/root
fi
ln -sfn qunibone ${TARGET_DIR}/root
