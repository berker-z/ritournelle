#!/usr/bin/env bash

# Wipe all account data under userdata/ (characters, stash, etc.).
# Clears both the repo-local res://userdata and the Godot user://userdata.

set -euo pipefail

# Script lives in the project root; resolve userdata relative to here.
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_TARGET="${ROOT_DIR}/userdata"

# Determine Godot user:// path. Adjust APP_NAME if project name changes.
APP_NAME="Ritournelle"
case "$(uname -s)" in
  Linux*)
    USER_TARGET="${HOME}/.local/share/godot/app_userdata/${APP_NAME}/userdata"
    ;;
  Darwin*)
    USER_TARGET="${HOME}/Library/Application Support/Godot/app_userdata/${APP_NAME}/userdata"
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    USER_TARGET="$(cygpath -u "$APPDATA")/Godot/app_userdata/${APP_NAME}/userdata"
    ;;
  *)
    USER_TARGET=""
    ;;
esac

wipe_dir() {
  local target="$1"
  if [ -z "$target" ]; then
    return
  fi
  if [ ! -d "$target" ]; then
    echo "Skipping (not found): $target"
    return
  fi
  echo "Removing contents of $target"
  rm -rf "${target:?}/"* "${target:?}/".* 2>/dev/null || true
}

wipe_dir "$REPO_TARGET"
wipe_dir "$USER_TARGET"

echo "Done."
