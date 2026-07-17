#!/usr/bin/env bash
# release-notes.sh — generate release body
set -e

: "${BUILD_TYPE:-stable}"
: "${RUN_URL:?}"
: "${REPO:?}"
: "${SHA:?}"

SHORT_SHA="${SHA:0:9}"
COMMIT_URL="https://github.com/${REPO}/commit/${SHA}"
BODY=""

if [ "$BUILD_TYPE" = "testing" ]; then
  BODY="${BODY}> [!WARNING]"$'\n'
  BODY="${BODY}> Testing build. Use at your own risk."$'\n\n'
fi

BODY="${BODY}[KSU-Next Manager](${KSUN_MANAGER_URL})"$'\n'
BODY="${BODY}[ReSukiSU Manager](${RESUKI_MANAGER_URL})"$'\n'
BODY="${BODY}**Kernel:** \`${KERNEL_UNAME}\`"$'\n\n'

BODY="${BODY}**Variants:** KSU-Next · ReSukiSU · NoKSU"$'\n'
BODY="${BODY}**Device:** Motorola Edge 40 Pro (rtwo)"$'\n'


BODY="${BODY}**Commit:** [\`${SHORT_SHA}\`](${COMMIT_URL})"$'\n'
BODY="${BODY}**Build:** [Run #${GITHUB_RUN_NUMBER} summary](${RUN_URL})"$'\n'

{
  echo "RELEASE_BODY<<EOREL"
  echo "$BODY"
  echo "EOREL"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Release body generated"
