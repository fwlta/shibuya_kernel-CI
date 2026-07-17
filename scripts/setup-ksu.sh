#!/usr/bin/env bash
# setup-ksu.sh — integrate KSU variant into kernel source
# env: KSU_TYPE (ksun|resuki|none), KERNEL_DIR, WORK_DIR
set -e

: "${KSU_TYPE:?}"
: "${KERNEL_DIR:?}"
: "${WORK_DIR:?}"

git config --global init.defaultBranch main
git config --global advice.addEmbeddedRepo false

cd "$KERNEL_DIR"

# KernelSU-Next

if [ "$KSU_TYPE" = "ksun" ]; then
  rm -rf ./KernelSU ./drivers/kernelsu ./KernelSU-Next
  KSUN_PIN=$(jq -r ".ksun_tag // empty" "$WORK_DIR/sources/source-pins.json")
  [ -n "$KSUN_PIN" ] || { echo "[ERROR] Missing ksun_tag source pin"; exit 1; }
  curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev/kernel/setup.sh" | bash -s "$KSUN_PIN"
  [ -d "KernelSU-Next/kernel" ] || { echo "[ERROR] KernelSU-Next not found"; exit 1; }

  cd KernelSU-Next
  git fetch --tags 2>/dev/null || true
  KSUN_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "$KSUN_PIN")
  _ksun_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  KSUN_VERSION=$((30000 + _ksun_count))
  echo "KSUN_TAG=$KSUN_TAG"    >> "${GITHUB_ENV:-/dev/null}"
  echo "$KSUN_TAG"                  > "$WORK_DIR/ksun_tag.txt"
  echo "$KSUN_VERSION" > "$WORK_DIR/ksun_version.txt"
  cd ..

# ReSukiSU
elif [ "$KSU_TYPE" = "resuki" ]; then
  rm -rf ./KernelSU ./drivers/kernelsu ./KernelSU-Next
  RESUKI_PIN=$(jq -r ".resuki_commit // empty" "$WORK_DIR/sources/source-pins.json")
  [ -n "$RESUKI_PIN" ] || { echo "[ERROR] Missing resuki_commit source pin"; exit 1; }
  curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" \
    | bash -s "$RESUKI_PIN"
  [ -d "KernelSU/kernel" ] || { echo "[ERROR] ReSukiSU not found"; exit 1; }

  cd KernelSU
  git fetch --tags 2>/dev/null || true
  RESUKI_TAG=$(git describe --tags --exact-match 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "$RESUKI_PIN")
  _resuki_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  RESUKI_VERSION=$((30700 + _resuki_count))
  echo "RESUKI_TAG=$RESUKI_TAG"      >> "${GITHUB_ENV:-/dev/null}"
  echo "$RESUKI_TAG"                > "$WORK_DIR/resuki_ksu_tag.txt"
  echo "$RESUKI_VERSION" > "$WORK_DIR/resuki_version.txt"
  cd ..

fi

echo "[OK] KSU setup complete: $KSU_TYPE"
