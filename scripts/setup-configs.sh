#!/usr/bin/env bash
set -euo pipefail

: "${KSU_TYPE:?}"
: "${DEFCONFIG:?}"

if [ "$KSU_TYPE" = "none" ]; then
  exit 0
fi

cat >> "$DEFCONFIG" << EOF
CONFIG_KSU=y
CONFIG_BBG=y
EOF
