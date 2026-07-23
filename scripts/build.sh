#!/usr/bin/env bash
# build.sh — moto SM8550 kernel build
# env: SOURCE_TYPE, DEFCONFIG, KERNEL_SRC, WORK_DIR, CLANG_DIR
set -e

: "${SOURCE_TYPE:?}"
: "${KERNEL_SRC:?}"
: "${WORK_DIR:?}"
: "${DEFCONFIG:?}"
: "${CLANG_DIR:?}"

OUT_DIR="${WORK_DIR}/out"
START=$(date +%s)

export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-alpine}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-fwlta}"
export PATH="${CLANG_DIR}/bin:$PATH"
# Use CONFIG_LOCALVERSION verbatim instead of adding an SCM suffix.
export LOCALVERSION=""

if command -v ccache &>/dev/null; then _CC="ccache clang"; else _CC="clang"; fi

MAKE_FLAGS=(
  -j$(nproc)
  O="${OUT_DIR}/dist"
  ARCH=arm64
  SUBARCH=arm64
  LLVM=1
  LLVM_IAS=1
  CC="$_CC"
  LD=ld.lld
  AR=llvm-ar
  NM=llvm-nm
  OBJCOPY=llvm-objcopy
  OBJDUMP=llvm-objdump
  STRIP=llvm-strip
  OBJSIZE=llvm-size
  READELF=llvm-readelf
  CROSS_COMPILE=aarch64-linux-gnu-
  CROSS_COMPILE_ARM32=arm-linux-gnueabi-
  KBUILD_BUILD_USER="$KBUILD_BUILD_USER"
  KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"
  KCFLAGS="-pipe -fno-strict-aliasing -fno-common -Wno-error -Wno-unknown-warning-option -Wno-array-bounds -Wno-stringop-overflow -Wno-mismatched-function-types -Wno-unused-variable -Wno-misleading-indentation -Wno-incompatible-function-pointer-types"
  LLVM_PARALLEL_LINK_JOBS=2
)

set -o pipefail
mkdir -p "${OUT_DIR}/dist"
cd "$KERNEL_SRC"

LOG="/tmp/build_${SOURCE_TYPE}.log"

echo "[${SOURCE_TYPE^^}] Building defconfig: $DEFCONFIG"
make "${MAKE_FLAGS[@]}" "$DEFCONFIG"

echo "[${SOURCE_TYPE^^}] Switching to ThinLTO..."
./scripts/config --file "${OUT_DIR}/dist/.config" \
  -e LTO_CLANG \
  -d LTO_NONE \
  -e LTO_CLANG_THIN \
  -d LTO_CLANG_FULL \
  -e THINLTO
make "${MAKE_FLAGS[@]}" olddefconfig

# Merge platform fragment
_FRAG_MERGED=false
if [ -n "${CLO_FRAGMENT:-}" ] && [ -f "arch/arm64/configs/${CLO_FRAGMENT}" ]; then
  echo "[${SOURCE_TYPE^^}] Merging platform fragment: $CLO_FRAGMENT"
  KCONFIG_CONFIG="${OUT_DIR}/dist/.config" \
    scripts/kconfig/merge_config.sh -m \
    "${OUT_DIR}/dist/.config" \
    "arch/arm64/configs/${CLO_FRAGMENT}"
  make "${MAKE_FLAGS[@]}" olddefconfig
  _FRAG_MERGED=true
fi

# Merge device-specific extra fragments.
# moto-kalama.config / moto-kalama-gki.config are required for Moto hardware
# init (display, thermal, sensors) — missing these causes boot animation loop.
for _EXTRA in \
  "arch/arm64/configs/vendor/ext_config/moto-kalama.config" \
  "arch/arm64/configs/vendor/ext_config/moto-kalama-gki.config" \
  "arch/arm64/configs/vendor/ext_config/moto-kalama-rtwo.config"; do
  if [ -f "$_EXTRA" ]; then
    echo "[${SOURCE_TYPE^^}] Merging extra fragment: $_EXTRA"
    KCONFIG_CONFIG="${OUT_DIR}/dist/.config" \
      scripts/kconfig/merge_config.sh -m \
      "${OUT_DIR}/dist/.config" "$_EXTRA"
    make "${MAKE_FLAGS[@]}" olddefconfig
    _FRAG_MERGED=true
  else
    echo "[${SOURCE_TYPE^^}] Extra fragment not found, skipping: $_EXTRA"
  fi
done

if $_FRAG_MERGED; then
    echo "[MOTO] Re-enforcing Android SELinux after fragment merge"
    ./scripts/config --file "${OUT_DIR}/dist/.config" \
    -e NET \
    -e INET \
    -e AUDIT \
    -e SECURITY \
    -e SECURITY_NETWORK \
    -e SECURITY_SELINUX \
    --set-val SECURITY_SELINUX_SIDTAB_HASH_BITS 9 \
    --set-val SECURITY_SELINUX_SID2STR_CACHE_SIZE 256
  make "${MAKE_FLAGS[@]}" olddefconfig
fi

KERNEL_HASH="$(cat "${WORK_DIR}/kernel_hash.txt")"
[[ "$KERNEL_HASH" =~ ^[0-9a-f]{7,12}$ ]] || {
  echo "[ERROR] Invalid kernel hash: $KERNEL_HASH"
  exit 1
}
KERNEL_LOCALVERSION=":Shibuya-rc1/${KERNEL_HASH}"
echo "[${SOURCE_TYPE^^}] Setting LocalVersion: ${KERNEL_LOCALVERSION}"
./scripts/config --file "${OUT_DIR}/dist/.config" \
  --set-str LOCALVERSION "${KERNEL_LOCALVERSION}" \
  -d LOCALVERSION_AUTO
make "${MAKE_FLAGS[@]}" olddefconfig

./scripts/config --file "${OUT_DIR}/dist/.config" -e CONFIG_IP6_NF_NAT

echo "[${SOURCE_TYPE^^}] Generating SELinux headers..."
SELINUX_GENHEADERS="${OUT_DIR}/dist/genheaders"
"${CLANG_DIR}/bin/clang" \
  -I"${KERNEL_SRC}/include/uapi" \
  -I"${KERNEL_SRC}/include" \
  -I"${KERNEL_SRC}/security/selinux/include" \
  -O2 -std=gnu89 \
  -o "${SELINUX_GENHEADERS}" \
  "${KERNEL_SRC}/scripts/selinux/genheaders/genheaders.c"
mkdir -p "${OUT_DIR}/dist/security/selinux"
"${SELINUX_GENHEADERS}" \
  "${OUT_DIR}/dist/security/selinux/flask.h" \
  "${OUT_DIR}/dist/security/selinux/av_permissions.h"

echo "[${SOURCE_TYPE^^}] Building Image..."
if ! make "${MAKE_FLAGS[@]}" Image 2>&1 | tee "$LOG"; then
  echo "[FAIL] ${SOURCE_TYPE^^} build failed:"
  tail -100 "$LOG"
  exit 1
fi

if [ -f "${OUT_DIR}/dist/arch/arm64/boot/Image" ]; then
  cp "${OUT_DIR}/dist/arch/arm64/boot/Image" "${OUT_DIR}/dist/Image"
  echo "[${SOURCE_TYPE^^}] Image copied to ${OUT_DIR}/dist/Image"
else
  echo "[FAIL] Image file not found in build directory!"
  exit 1
fi

DURATION=$(( $(date +%s) - START ))
echo " Build done in $((DURATION/60))m $((DURATION%60))s"
