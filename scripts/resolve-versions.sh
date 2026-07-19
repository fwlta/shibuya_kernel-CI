#!/usr/bin/env bash
# resolve-versions.sh — read version info from artifacts + GitHub API
# env: BUILD_TYPE, GITHUB_ENV (implicit)
set -e

: "${BUILD_TYPE:-stable}"

VERSION_FILE=$(find ./artifacts -name "kernel_version.txt" | head -1)
KERNEL_VERSION=$([ -f "$VERSION_FILE" ] && cat "$VERSION_FILE" || echo "5.15.x")
KERNEL_UNAME="$KERNEL_VERSION"


_kv=$(find ./artifacts -name "ksun_version.txt" | head -1)
KSUN_VERSION=$([ -f "$_kv" ] && cat "$_kv" | tr -d '[:space:]' || echo "")

_sv=$(find ./artifacts -name "resuki_version.txt" | head -1)
RESUKI_VERSION=$([ -f "$_sv" ] && cat "$_sv" | tr -d '[:space:]' || echo "")

_kr=$(curl -sf --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/actions/workflows/build-manager-ci.yml/runs?status=success&branch=dev&per_page=1" \
  | jq -r '.workflow_runs[0].id // empty' 2>/dev/null | tr -d '[:space:]')
KSUN_MANAGER_URL="${_kr:+https://github.com/KernelSU-Next/KernelSU-Next/actions/runs/${_kr}}"
KSUN_MANAGER_URL="${KSUN_MANAGER_URL:-https://github.com/KernelSU-Next/KernelSU-Next/actions}"
KSUN_MANAGER_ARTIFACT_ID=$([ -n "$_kr" ] && \
  curl -sf --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/actions/runs/${_kr}/artifacts" \
  | jq -r '.artifacts[] | select(.name == "manager") | .id // empty' | head -1 || true)

_sr=$(curl -sf --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/ReSukiSU/ReSukiSU/actions/workflows/build-manager.yml/runs?status=success&branch=main&per_page=1" \
  | jq -r '.workflow_runs[0].id // empty' 2>/dev/null | tr -d '[:space:]')
RESUKI_MANAGER_URL="${_sr:+https://github.com/ReSukiSU/ReSukiSU/actions/runs/${_sr}}"
RESUKI_MANAGER_URL="${RESUKI_MANAGER_URL:-https://github.com/ReSukiSU/ReSukiSU/actions/workflows/build-manager.yml}"
RESUKI_MANAGER_ARTIFACT_ID=$([ -n "$_sr" ] && \
  curl -sf --max-time 10 -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://api.github.com/repos/ReSukiSU/ReSukiSU/actions/runs/${_sr}/artifacts" \
  | jq -r '.artifacts[] | select(.name == "Manager-release") | .id // empty' | head -1 || true)


RELEASE_TAG="shibuya-${GITHUB_RUN_NUMBER}"
RELEASE_NAME="Shibuya Kernel #${GITHUB_RUN_NUMBER}"

if [ "$BUILD_TYPE" = "testing" ]; then
  IS_PRERELEASE="true"
else
  IS_PRERELEASE="false"
fi


{
  echo "KSUN_VERSION=$KSUN_VERSION"
  echo "RESUKI_VERSION=$RESUKI_VERSION"
  echo "KSUN_MANAGER_URL=$KSUN_MANAGER_URL"
  echo "RESUKI_MANAGER_URL=$RESUKI_MANAGER_URL"
  echo "KSUN_MANAGER_ARTIFACT_ID=$KSUN_MANAGER_ARTIFACT_ID"
  echo "RESUKI_MANAGER_ARTIFACT_ID=$RESUKI_MANAGER_ARTIFACT_ID"
  echo "KERNEL_VERSION=$KERNEL_VERSION"
  echo "KERNEL_UNAME=$KERNEL_UNAME"
  echo "RELEASE_TAG=$RELEASE_TAG"
  echo "RELEASE_NAME=$RELEASE_NAME"
  echo "IS_PRERELEASE=$IS_PRERELEASE"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Versions resolved"
echo "  Kernel  : $KERNEL_VERSION"
echo "  Tag     : $RELEASE_TAG"
