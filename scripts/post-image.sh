#!/usr/bin/bash

if [ -x ${HOST_DIR}/bin/bmaptool ]; then
    echo Creating root filesystem image bmap file
    ${HOST_DIR}/bin/bmaptool create ${BINARIES_DIR}/rootfs.ext4 > ${BINARIES_DIR}/rootfs.ext4.bmap
fi
