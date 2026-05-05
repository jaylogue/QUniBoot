#!/bin/bash

set -euo pipefail

IMAGE_TYPE="full"

help() {
  echo "Usage: sudo $0 [options] /dev/sdX"
  echo "Options:"
  echo "  --full"
  echo "  --os-only"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    "-h"|"--help")
      help
      exit 0
      ;;
    "--os-only")
      IMAGE_TYPE="os-only"
      shift
      ;;
    "--full")
      IMAGE_TYPE="full"
      shift
      ;;
    -*)
      echo "Unrecognised option: $1"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -gt 1 ]]; then
  echo "Unexpected argument: $2"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Missing device name"
  exit 1
fi

DEVICE="$1"
if [[ ! -b "$DEVICE" ]]; then
  echo "Error: '$DEVICE' is not a block device."
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Error: Run this script with sudo."
  exit 1
fi

TOP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}/")"/.. && pwd)

# ── Ask for confirmation ─────────────────────────────────────────────────────

echo "==> Target device: $DEVICE"
lsblk --fs $DEVICE
echo "==> WARNING: ALL DATA ON $DEVICE WILL BE DESTROYED!"
read -rp "    Type YES to continue: " confirm
[[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 0; }

# ── Unmount any mounted partitions ───────────────────────────────────────────

echo "==> Unmounting any mounted partitions on $DEVICE..."
umount "${DEVICE}"?* 2>/dev/null || true

# ── Install the SD image ──────────────────────────────────────────────────────

echo "==> Installing qunibone-${IMAGE_TYPE}.img onto SD card"
${TOP_DIR}/output/host/bin/bmaptool copy ${TOP_DIR}/output/images/qunibone-${IMAGE_TYPE}.img "${DEVICE}"

# ── Unmount USB ───────────────────────────────────────────────────────────────

echo "==> Unmounting $DEVICE..."
sync
umount "${DEVICE}"?* 2>/dev/null || true
eject "${DEVICE}"
