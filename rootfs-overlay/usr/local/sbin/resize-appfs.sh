#!/bin/sh
#
# Resize the app filesystem to fill available space on the SD card.

set -euo pipefail

SD_CARD_DEV=mmcblk0
APPFS_DEV=mmcblk0p3

# If the app filesystem partition exists...
if [[ -b /dev/${APPFS_DEV} ]]; then

  # Compute the amount of free space (in blocks) after the app filesystem partition
  SD_CARD_SIZE=$(< /sys/class/block/${SD_CARD_DEV}/size)
  APPFS_END=$(( $(< /sys/class/block/${APPFS_DEV}/start) + $(< /sys/class/block/${APPFS_DEV}/size) ))
  FREE_SIZE=$(( ${SD_CARD_SIZE} - ${APPFS_END} ))

  # If a substantial amount of free space (>100MB) exists after the partition
  # attempt to grow the partition and filesystem to fill the available space.
  if [[ ${FREE_SIZE} -gt 204800 ]]; then

    echo "Resizing app filesystem..."

    # Unmount the filesystem, if mounted
    if findmnt /dev/${APPFS_DEV} >/dev/null; then
      echo "Unmounting app filesystem"
      umount /dev/${APPFS_DEV}
    fi

    # Resize the filesystem partition to occupy the remaining space on the device.
    echo "Expanding app filesystem partition to fill device"
    parted --script /dev/${SD_CARD_DEV} resizepart $(< /sys/class/block/${APPFS_DEV}/partition) 100%

    # Remount the filesystem
    echo "Remounting app filesystem"
    mount /dev/${APPFS_DEV}

    # Expand the filesystem to fill the new space in the partition.
    echo "Expanding app filesystem to fill partition"
    resize2fs /dev/${APPFS_DEV}

  fi
fi
