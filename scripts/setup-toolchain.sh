#!/usr/bin/env bash
# setup-toolchain.sh
set -e

: "${WORK_DIR:=$GITHUB_WORKSPACE}"

CLANG_VER="neutron-clang-30062026"
CLANG_URL="https://github.com/Neutron-Toolchains/clang-build-catalogue/releases/download/30062026/${CLANG_VER}.tar.zst"
CLANG_DIR="${WORK_DIR}/prebuilts/clang/host/linux-x86/clang-${CLANG_VER}"

mkdir -p "$CLANG_DIR"
aria2c -x16 -s16 -d /tmp -o clang.tar.zst "$CLANG_URL"
tar --zstd -xf /tmp/clang.tar.zst -C "$CLANG_DIR"
rm -f /tmp/clang.tar.zst

echo "CLANG_DIR=$CLANG_DIR" >> "${GITHUB_ENV:-/dev/null}"
echo "[OK] Toolchain ready: $CLANG_DIR"
