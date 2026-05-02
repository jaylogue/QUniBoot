#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /dev/sdX"
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

echo "==> Installing SD image"
${TOP_DIR}/output/host/bin/bmaptool copy ${TOP_DIR}/output/images/sdcard.img "${DEVICE}"

# ── Unmount USB ───────────────────────────────────────────────────────────────

echo "==> Unmounting $DEVICE..."
sync
umount "${DEVICE}"?* 2>/dev/null || true
eject "${DEVICE}"
