#!/usr/bin/bash
#
# QUniBoot post-build script
#
# This script is invoked after all packages are build, but before the filessytem images
# are assembled.  Its purpose is to apply a number of QUniBoot-specific customizations
# to the files in the target directory that will ultimately be incorporated into the
# root filesystem.
#

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

if [[ "${TARGET_DIR}" = "" || "${TARGET_DIR}" = "/" ]]; then
    echo "Invalid target directory argument"
    exit 1
fi

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

DEFERRED_INIT_SCRIPTS="S40network S49ntpd.sh S50avahi-daemon S50sshd S50telnet"
for f in ${DEFERRED_INIT_SCRIPTS}; do
    echo "Deferring init script: ${f}"
    mv ${TARGET_DIR}/etc/init.d/${f} ${TARGET_DIR}/etc/init.d/${f/#S/D}
done

DISABLED_INIT_SCRIPTS="S50crond D50telnet"
for f in ${DISABLED_INIT_SCRIPTS}; do
    echo "Disabling init script: ${f}"
    mv ${TARGET_DIR}/etc/init.d/${f} ${TARGET_DIR}/etc/init.d/DISABLED.${f}
done

echo "Customizing os-release file"
QUNIBOOT_VERSION=$("${BR2_EXTERNAL_QUNIBOOT_PATH}/scripts/get-version.sh")
cat > ${TARGET_DIR}/etc/os-release <<EOF
NAME=QUniBoot
ID=quniboot
VARIANT=${PLATFORM_NAME}
VARIANT_ID=${PLATFORM_NAME_LC}
VERSION=${QUNIBOOT_VERSION}
PRETTY_NAME="QUniBoot for ${PLATFORM_NAME} (${QUNIBOOT_VERSION})"
HOME_URL="https://github.com/jaylogue/QUniBoot"
EOF

echo "Customizing welcome message"
cat > ${TARGET_DIR}/etc/issue <<EOF
Welcome to ${PLATFORM_NAME}

EOF

echo "Customizing extlinux.conf"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBOOT_PATH}/board/qunibone/extlinux.conf ${BINARIES_DIR}/extlinux/extlinux.conf
sed -i -e "s/label \+qunibone/label ${PLATFORM_NAME_LC}/" ${BINARIES_DIR}/extlinux/extlinux.conf

echo "Installing autoconfig-example.txt"
install -m 0644 -D ${BR2_EXTERNAL_QUNIBOOT_PATH}/board/qunibone/autoconfig-example.txt ${BINARIES_DIR}/autoconfig-example.txt

echo "Restoring busybox vi"
ln -sf busybox ${TARGET_DIR}/bin/vi

echo "Linking root directory"
if [[ -e ${TARGET_DIR}/root && ! -L ${TARGET_DIR}/root ]]; then
    rm -rf ${TARGET_DIR}/root
fi
ln -sfn qunibone ${TARGET_DIR}/root
