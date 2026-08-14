#!/usr/bin/env bash
# setup-ksu.sh - integrate root variants
# env: KSU_TYPE, KERNEL_DIR, WORK_DIR
set -euo pipefail

: "${KSU_TYPE:?}"
: "${KERNEL_DIR:?}"
: "${WORK_DIR:?}"

git config --global init.defaultBranch main
git config --global advice.addEmbeddedRepo false

cd "$KERNEL_DIR"

case "$KSU_TYPE" in
  resuki)
    rm -rf ./KernelSU ./drivers/kernelsu
    RESUKI_PIN=$(jq -r ".resuki_commit // empty" "$WORK_DIR/sources/source-pins.json")
    [ -n "$RESUKI_PIN" ] || { echo "[ERROR] Missing resuki_commit source pin"; exit 1; }
    curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" \
      | bash -s "$RESUKI_PIN"
    [ -d "KernelSU/kernel" ] || { echo "[ERROR] ReSukiSU not found"; exit 1; }

    _resuki_count=$(git -C KernelSU rev-list --count HEAD 2>/dev/null || echo 0)
    RESUKI_VERSION=$((30700 + _resuki_count))
    printf "%s\n" "$RESUKI_VERSION" > "$WORK_DIR/resuki_version.txt"
    ;;

  none)
    ;;

  *)
    echo "[ERROR] Unknown KSU type: $KSU_TYPE"
    exit 1
    ;;
esac

echo "[OK] Root setup complete: $KSU_TYPE"
