#!/bin/bash

set -euo pipefail

IMAGE_TYPE="full"

help() {
  echo "Usage: sudo $0 [options] <image-file-name> <device-name>"
  echo "Options:"
  echo "  -h | --help"
  echo "      Display help."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    "-h"|"--help")
      help
      exit 0
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

if [[ $# -lt 1 ]]; then
  echo "Error: Missing image file name"
  exit 1
fi
IMAGE_FILE="$1"
shift

if [[ $# -lt 1 ]]; then
  echo "Error: Missing device name"
  exit 1
fi
DEVICE="$1"
shift

if [[ $# -gt 0 ]]; then
  echo "Unexpected argument: $1"
  exit 1
fi

if [[ ! -f "${IMAGE_FILE}" ]]; then
  echo "Error: Unable to read image file: ${IMAGE_FILE}"
  exit 1
fi

if [[ ! -e "${DEVICE}" ]]; then
  echo "Error: Device not found: ${DEVICE}"
  exit 1
fi

if [[ ! -b "${DEVICE}" ]]; then
  echo "Error: Not a block device: ${DEVICE}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Error: Run this script with sudo."
  exit 1
fi

TOP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}/")"/.. && pwd)

# ── Ask for confirmation ─────────────────────────────────────────────────────

echo "==> Target device: ${DEVICE}"
lsblk --fs ${DEVICE}
echo "==> WARNING: DATA ON ${DEVICE} WILL BE DESTROYED!"
read -rp "    Type YES to continue: " confirm
[[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 0; }

# ── Unmount any mounted partitions ───────────────────────────────────────────

echo "==> Unmounting any mounted partitions on ${DEVICE}..."
umount "${DEVICE}"?* 2>/dev/null || true

# ── Install the SD image ──────────────────────────────────────────────────────

echo "==> Installing ${IMAGE_FILE} onto SD card"
${TOP_DIR}/output/host/bin/bmaptool copy "${IMAGE_FILE}" "${DEVICE}"

# ── Unmount USB ───────────────────────────────────────────────────────────────

echo "==> Unmounting ${DEVICE}..."
sync
umount "${DEVICE}"?* 2>/dev/null || true
eject "${DEVICE}"
