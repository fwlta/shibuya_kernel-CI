#!/usr/bin/env bash
# release-notes.sh - generate release body
set -e

: "${RUN_URL:?}"
: "${REPO:?}"
: "${SHA:?}"

SHORT_SHA="${SHA:0:9}"
COMMIT_URL="https://github.com/${REPO}/commit/${SHA}"
BODY=""

BODY="${BODY}**Kernel:** \`${KERNEL_UNAME}\`"$'\n\n'

BODY="${BODY}**Variants:** ReSukiSU, NoKSU"$'\n'
BODY="${BODY}**Device:** Motorola Edge 40 Pro (rtwo)"$'\n'


BODY="${BODY}**Commit:** [\`${SHORT_SHA}\`](${COMMIT_URL})"$'\n'
BODY="${BODY}**Build:** [Run #${GITHUB_RUN_NUMBER} summary](${RUN_URL})"$'\n'

{
  echo "RELEASE_BODY<<EOREL"
  echo "$BODY"
  echo "EOREL"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Release body generated"
