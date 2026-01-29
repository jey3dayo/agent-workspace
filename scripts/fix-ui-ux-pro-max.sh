#!/bin/bash

set -euo pipefail

SKILL_DIR="$HOME/.agents/skills/ui-ux-pro-max"

resolve_path() {
  local path="$1"
  if readlink -f / >/dev/null 2>&1; then
    readlink -f "$path" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$path" <<'PY'
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
  elif command -v python >/dev/null 2>&1; then
    python - "$path" <<'PY'
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
  else
    echo ""
  fi
}

is_tmp_path() {
  case "$1" in
    /tmp/*|/private/tmp/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

needs_fix() {
  local path="$1"

  if [ -L "$path" ]; then
    local target resolved
    target=$(readlink "$path" 2>/dev/null || true)
    if [ ! -e "$path" ]; then
      return 0
    fi
    if is_tmp_path "$target"; then
      return 0
    fi
    resolved=$(resolve_path "$path")
    if [ -n "$resolved" ] && is_tmp_path "$resolved"; then
      return 0
    fi
    return 1
  fi

  if [ ! -d "$path" ]; then
    return 0
  fi

  return 1
}

if [ ! -d "$SKILL_DIR" ]; then
  echo "- ui-ux-pro-max: not installed"
  exit 0
fi

parts=(scripts data templates)
fix_needed=0

for part in "${parts[@]}"; do
  if needs_fix "$SKILL_DIR/$part"; then
    fix_needed=1
    break
  fi
done

if [ "$fix_needed" -eq 0 ]; then
  echo "- ui-ux-pro-max: ok"
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR ui-ux-pro-max: git not found"
  exit 1
fi

tmpdir=""
cleanup() {
  if [ -n "$tmpdir" ] && [ -d "$tmpdir" ]; then
    rm -rf "$tmpdir"
  fi
}
trap cleanup EXIT

tmpdir=$(mktemp -d)

git clone --depth 1 https://github.com/nextlevelbuilder/ui-ux-pro-max-skill "$tmpdir" >/dev/null 2>&1

SRC_DIR="$tmpdir/src/ui-ux-pro-max"
if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR ui-ux-pro-max: source not found"
  exit 1
fi

for part in "${parts[@]}"; do
  if needs_fix "$SKILL_DIR/$part"; then
    rm -rf "$SKILL_DIR/$part"
    cp -a "$SRC_DIR/$part" "$SKILL_DIR/"
  fi
done

if [ ! -f "$SKILL_DIR/scripts/search.py" ]; then
  echo "ERROR ui-ux-pro-max: search.py missing"
  exit 1
fi

echo "OK ui-ux-pro-max: fixed"
