#!/usr/bin/env bash
# verify-kernel.sh — verify built Image, extract version string
set -e

: "${WORK_DIR:?}"
: "${KERNEL_SRC:?}"

IMAGE="${WORK_DIR}/out/dist/Image"
[ -f "$IMAGE" ] || { echo "[ERROR] Image not found: $IMAGE"; exit 1; }

CONFIG="${WORK_DIR}/out/dist/.config"
[ -f "$CONFIG" ] || { echo "[ERROR] Kernel config not found: $CONFIG"; exit 1; }

for symbol in AUDIT SECURITY SECURITY_NETWORK SECURITY_SELINUX; do
  grep -qx "CONFIG_${symbol}=y" "$CONFIG" || {
    echo "[ERROR] Required Android security option is disabled: CONFIG_${symbol}"
    exit 1
  }
done

VERSION_FULL=$(strings "$IMAGE" | grep "Linux version 5" | head -1)
echo "$VERSION_FULL"

if echo "$VERSION_FULL" | grep -q "dirty"; then
  echo "Warning: kernel version contains a dirty marker"
fi

VERSION_CLEAN=$(echo "$VERSION_FULL" | sed 's/Linux version //' | sed 's/ (.*//')
KERNEL_HASH=$(cat "${WORK_DIR}/kernel_hash.txt")
KERNEL_BASE_VERSION=$(make -s --no-print-directory -C "$KERNEL_SRC" kernelversion)
EXPECTED_VERSION="${KERNEL_BASE_VERSION}:Shibuya:${KERNEL_HASH}"
[ "$VERSION_CLEAN" = "$EXPECTED_VERSION" ] || {
  echo "[ERROR] Unexpected kernel version: $VERSION_CLEAN"
  echo "[ERROR] Expected: $EXPECTED_VERSION"
  exit 1
}
echo "$VERSION_CLEAN"
echo "KERNEL_VERSION=$VERSION_CLEAN" >> "${GITHUB_ENV:-/dev/null}"
echo "$VERSION_CLEAN" > "$WORK_DIR/out/dist/kernel_version.txt"
