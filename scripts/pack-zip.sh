#!/usr/bin/env bash
# pack-zip.sh — pack AnyKernel3 zip per variant
# env: SOURCE_TYPE, KSU_TYPE, KERNEL_HASH, WORK_DIR
set -e

: "${SOURCE_TYPE:?}"
: "${KSU_TYPE:?}"
: "${WORK_DIR:?}"

AK3_REPO="https://github.com/superuseryu/AnyKernel3"
IMAGE="${WORK_DIR}/out/dist/Image"

[ -f "$IMAGE" ] || { echo "[ERROR] Image not found: $IMAGE"; exit 1; }

: "${KERNEL_HASH:?}"

case "${KSU_TYPE}" in
  ksun) ZIP_VARIANT="ksun" ;;
  ksun-susfs) ZIP_VARIANT="ksun-susfs" ;;
  resuki) ZIP_VARIANT="resuki" ;;
  resuki-susfs) ZIP_VARIANT="resuki-susfs" ;;
  none) ZIP_VARIANT="noksu" ;;
  *)    echo "[ERROR] Unknown KSU type: ${KSU_TYPE}"; exit 1 ;;
esac

ZIP_NAME="Shibuya-${KERNEL_HASH}-${ZIP_VARIANT}.zip"


cd "$WORK_DIR"
git clone --depth=1 "$AK3_REPO" ak3_tmp

# Override with rtwo-specific anykernel.sh (replaces Sapphire AK3 script)
AK3_SCRIPT="${WORK_DIR}/scripts/anykernel.sh"
[ -f "$AK3_SCRIPT" ] && cp "$AK3_SCRIPT" ak3_tmp/anykernel.sh

cp "$IMAGE" "ak3_tmp/Image"

cd ak3_tmp
zip -r9 "../${ZIP_NAME}" * -x .git/*
cd ..
rm -rf ak3_tmp

SIZE_MB=$(echo "scale=2; $(stat -c%s "$ZIP_NAME") / 1024 / 1024" | bc | sed 's/^\./0./')
echo " Packed: $ZIP_NAME ($SIZE_MB MB)"

echo "ZIP_NAME=$ZIP_NAME"         >> "${GITHUB_ENV:-/dev/null}"
echo "ZIP_SIZE_MB=$SIZE_MB"       >> "${GITHUB_ENV:-/dev/null}"
