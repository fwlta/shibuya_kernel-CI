#!/usr/bin/env bash
# resolve-versions.sh — read version info from artifacts + GitHub API
# env: GITHUB_ENV (implicit)
set -e

VERSION_FILE=$(find ./artifacts -name "kernel_version.txt" | head -1)
KERNEL_VERSION=$([ -f "$VERSION_FILE" ] && cat "$VERSION_FILE" || echo "5.15.x")
KERNEL_UNAME="$KERNEL_VERSION"


_sv=$(find ./artifacts -name "resuki_version.txt" | head -1)
RESUKI_VERSION=$([ -f "$_sv" ] && cat "$_sv" | tr -d '[:space:]' || echo "")

RELEASE_TAG="shibuya-${GITHUB_RUN_NUMBER}"
RELEASE_NAME="Shibuya Kernel #${GITHUB_RUN_NUMBER}"
IS_PRERELEASE="false"


{
  echo "RESUKI_VERSION=$RESUKI_VERSION"
  echo "KERNEL_VERSION=$KERNEL_VERSION"
  echo "KERNEL_UNAME=$KERNEL_UNAME"
  echo "RELEASE_TAG=$RELEASE_TAG"
  echo "RELEASE_NAME=$RELEASE_NAME"
  echo "IS_PRERELEASE=$IS_PRERELEASE"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Versions resolved"
echo "  Kernel  : $KERNEL_VERSION"
echo "  Tag     : $RELEASE_TAG"
