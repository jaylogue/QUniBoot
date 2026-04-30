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
    WELCOMENAME='UniBone'
    HOSTNAME='unibone'
elif [[ "${QUNIBONE_PLATFORM}" = "QBUS" ]]; then
    WELCOMENAME='QBone'
    HOSTNAME='qbone'
else
    echo "Invalid platform argument"
    exit 1
fi

echo "Setting hostname"
echo ${HOSTNAME} > ${TARGET_DIR}/etc/hostname

echo "Setting welcome message"
echo "Wecome to ${WELCOMENAME}" > ${TARGET_DIR}/etc/issue

if [[ ! -f "${TARGET_DIR}/etc/init.d/DISABLED.S50crond" ]]; then
    echo "Disabling cron"
    mv ${TARGET_DIR}/etc/init.d/S50crond ${TARGET_DIR}/etc/init.d/DISABLED.S50crond
fi
