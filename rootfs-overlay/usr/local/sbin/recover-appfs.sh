#!/bin/bash
#
# Recover the app filesystem partition if it has been removed.
#
# This is necessary when the user overwrites the rootfs with a new, os-only
# image which doesn't contain a partition table entry for the app filesystem.

set -euo pipefail

SD_CARD_DEV=mmcblk0
ROOTFS_DEV=mmcblk0p2
APPFS_DEV=mmcblk0p3

# If the app filesystem partition does not exist...
if [[ ! -b /dev/${APPFS_DEV} ]]; then

  # Compute the starting block number of the free space immediately
  # following the rootfs partition
  FREE_START=$(( $(< /sys/class/block/${ROOTFS_DEV}/start) + $(< /sys/class/block/${ROOTFS_DEV}/size) ))

  # Scan the free space after the rootfs partition looking for the
  # app filesystem. Re-create the partition if found.
  echo "Attempting to restore app filesystem partition..."
  parted --script /dev/${SD_CARD_DEV} rescue ${FREE_START}s 100%

  # if successfully recovered...
  if [[ -b /dev/${APPFS_DEV} ]]; then

    # Fix any errors in the filesystem before attempting to mount it.
    echo "Checking app filesystem"
    e2fsck -p /dev/${APPFS_DEV}

    # Mount the app filesystem
    echo "Mounting app filesystem"
    mount /dev/${APPFS_DEV}

  else
    echo "App filesystem partition not found"
  fi

fi
