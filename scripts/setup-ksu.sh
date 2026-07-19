#!/usr/bin/env bash
# setup-ksu.sh - integrate root variants and optional SUSFS
# env: KSU_TYPE, KERNEL_DIR, WORK_DIR
set -euo pipefail

: "${KSU_TYPE:?}"
: "${KERNEL_DIR:?}"
: "${WORK_DIR:?}"

git config --global init.defaultBranch main
git config --global advice.addEmbeddedRepo false

cd "$KERNEL_DIR"

_setup_susfs() {
  local SUSFS_PIN SUSFS_DIR SUSFS_PATCH ACTUAL_PIN

  SUSFS_PIN=$(jq -r ".susfs_commit // empty" "$WORK_DIR/sources/source-pins.json")
  [ -n "$SUSFS_PIN" ] || { echo "[ERROR] Missing susfs_commit source pin"; exit 1; }

  SUSFS_DIR="$KERNEL_DIR/susfs4ksu"
  rm -rf "$SUSFS_DIR"
  git init -q "$SUSFS_DIR"
  git -C "$SUSFS_DIR" remote add origin https://gitlab.com/simonpunk/susfs4ksu.git
  git -C "$SUSFS_DIR" fetch -q --depth=1 origin "$SUSFS_PIN"
  git -C "$SUSFS_DIR" checkout -q --detach FETCH_HEAD

  ACTUAL_PIN=$(git -C "$SUSFS_DIR" rev-parse HEAD)
  [ "$ACTUAL_PIN" = "$SUSFS_PIN" ] || {
    echo "[ERROR] SUSFS pin mismatch: expected $SUSFS_PIN, got $ACTUAL_PIN"
    exit 1
  }

  SUSFS_PATCH="$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android13-5.15.patch"
  [ -f "$SUSFS_PATCH" ] || { echo "[ERROR] SUSFS kernel patch not found"; exit 1; }

  # Motorola adds trace/hooks/mm.h inside the context expected by upstream.
  # Extend that one hunk's context so patch(1) can apply it strictly.
  python3 - "$SUSFS_PATCH" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = """@@ -21,6 +21,9 @@
 #include <linux/shmem_fs.h>
 #include <linux/uaccess.h>
 #include <linux/pkeys.h>
+#if defined(CONFIG_KSU_SUSFS_SUS_KSTAT) || defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)
+#include <linux/susfs_def.h>
+#endif // #if defined(CONFIG_KSU_SUSFS_SUS_KSTAT) || defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)
__BLANK__
 #include <asm/elf.h>""".replace("__BLANK__", " " )
new = """@@ -21,7 +21,10 @@
 #include <linux/shmem_fs.h>
 #include <linux/uaccess.h>
 #include <linux/pkeys.h>
+#if defined(CONFIG_KSU_SUSFS_SUS_KSTAT) || defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)
+#include <linux/susfs_def.h>
+#endif // #if defined(CONFIG_KSU_SUSFS_SUS_KSTAT) || defined(CONFIG_KSU_SUSFS_SUS_MAP) || defined(CONFIG_KSU_SUSFS_OPEN_REDIRECT)
 #include <trace/hooks/mm.h>
__BLANK__
 #include <asm/elf.h>""".replace("__BLANK__", " " )
if old not in text:
    raise SystemExit("[ERROR] Expected SUSFS task_mmu hunk was not found")
path.write_text(text.replace(old, new, 1))
PY

  patch --batch --forward -p1 < "$SUSFS_PATCH"
  cp -f "$SUSFS_DIR"/kernel_patches/fs/* fs/
  cp -f "$SUSFS_DIR"/kernel_patches/include/linux/* include/linux/

  grep -q "CONFIG_KSU_SUSFS" fs/namei.c
  grep -q "susfs.o" fs/Makefile
  grep -q "susfs_def.h" fs/proc/task_mmu.c
  [ -f fs/susfs.c ] && [ -f include/linux/susfs.h ] && [ -f include/linux/susfs_def.h ]

  printf "%s\n" "$SUSFS_PIN" > "$WORK_DIR/susfs_commit.txt"
  rm -rf "$SUSFS_DIR"
  echo "[OK] SUSFS kernel patch applied: ${SUSFS_PIN:0:12}"
}

case "$KSU_TYPE" in
  ksun|ksun-susfs)
    rm -rf ./KernelSU ./drivers/kernelsu ./KernelSU-Next

    if [ "$KSU_TYPE" = "ksun-susfs" ]; then
      KSUN_PIN=$(jq -r ".ksun_susfs_commit // empty" "$WORK_DIR/sources/source-pins.json")
      [ -n "$KSUN_PIN" ] || { echo "[ERROR] Missing ksun_susfs_commit source pin"; exit 1; }
      curl -LSs "https://raw.githubusercontent.com/pershoot/KernelSU-Next/$KSUN_PIN/kernel/setup.sh" \
        | bash -s "$KSUN_PIN"
    else
      KSUN_PIN=$(jq -r ".ksun_tag // empty" "$WORK_DIR/sources/source-pins.json")
      [ -n "$KSUN_PIN" ] || { echo "[ERROR] Missing ksun_tag source pin"; exit 1; }
      curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev/kernel/setup.sh" \
        | bash -s "$KSUN_PIN"
    fi

    [ -d "KernelSU-Next/kernel" ] || { echo "[ERROR] KernelSU-Next not found"; exit 1; }
    _ksun_count=$(git -C KernelSU-Next rev-list --count HEAD 2>/dev/null || echo 0)
    KSUN_VERSION=$((30000 + _ksun_count))
    printf "%s\n" "$KSUN_VERSION" > "$WORK_DIR/ksun_version.txt"
    ;;

  resuki|resuki-susfs)
    rm -rf ./KernelSU ./drivers/kernelsu ./KernelSU-Next
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

case "$KSU_TYPE" in
  *-susfs) _setup_susfs ;;
esac

echo "[OK] Root setup complete: $KSU_TYPE"
