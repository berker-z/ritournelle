#!/usr/bin/env bash

# Wipe all account data under userdata/ (characters, stash, etc.).
# Keeps the userdata directory itself in place.

set -euo pipefail

# Script lives in the project root; resolve userdata relative to here.
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${ROOT_DIR}/userdata"

if [ ! -d "${TARGET}" ]; then
  echo "No userdata directory found at ${TARGET}"
  exit 0
fi

echo "Removing contents of ${TARGET}"
rm -rf "${TARGET:?}/"* "${TARGET:?}/".* 2>/dev/null || true

echo "Done."
