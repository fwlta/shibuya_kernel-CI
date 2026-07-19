#!/usr/bin/env bash
# clone-source.sh — clone moto SM8550 kernel source
# env: SOURCE_TYPE, KERNEL_SRC (output dir)
set -e

: "${SOURCE_TYPE:?}"
: "${KERNEL_SRC:=$WORK_DIR/kernel_src}"

mkdir -p "$KERNEL_SRC"

case "$SOURCE_TYPE" in

  moto)
    MOTO_REPO="https://github.com/fwlta/android_kernel_motorola_sm8550"
    MOTO_BRANCH="shibuya-rc1"
    if [ "${MOTO_CACHE_HIT}" = "true" ] && [ -d "$KERNEL_SRC/.git" ]; then
      echo "[Moto] Cache hit — fetching delta only..."
      for attempt in 1 2 3; do
        git -C "$KERNEL_SRC" fetch origin --depth=32 "$MOTO_BRANCH" && \
          git -C "$KERNEL_SRC" reset --hard FETCH_HEAD && break
        echo "Warning: fetch attempt $attempt failed, retrying in 30s..."
        sleep 30
      done
    else
      echo "[Moto] Cloning $MOTO_BRANCH ..."
      for attempt in 1 2 3; do
        git clone --recursive --branch "$MOTO_BRANCH" "$MOTO_REPO" "$KERNEL_SRC" --depth=32 && break
        echo "Warning: attempt $attempt failed, retrying in 30s..."
        rm -rf "$KERNEL_SRC" && mkdir -p "$KERNEL_SRC"
        sleep 30
      done
    fi
    ;;

  *)
    echo "[ERROR] Unknown source type: $SOURCE_TYPE"
    exit 1
    ;;
esac
KERNEL_HASH="$(git -C "$KERNEL_SRC" rev-parse --short=7 HEAD)"
printf "%s\n" "$KERNEL_HASH" > "${WORK_DIR}/kernel_hash.txt"
echo "KERNEL_HASH=$KERNEL_HASH" >> "${GITHUB_ENV:-/dev/null}"


# Freeze the exact source revision used by this build. This runs before
# Kconfig is available, so setlocalversion would miss LOCALVERSION_SHA and
# fall back to the generic SCM suffix.
printf "/%s\\n" "$KERNEL_HASH" > "$KERNEL_SRC/.scmversion"

echo "[OK] Source cloned → $KERNEL_SRC"
echo "KERNEL_SRC=$KERNEL_SRC" >> "${GITHUB_ENV:-/dev/null}"
