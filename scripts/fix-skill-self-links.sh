#!/bin/bash

set -euo pipefail

SOURCE_DIRS=(
  "$HOME/.agents/skills"
  "$HOME/.agents/skills-internal"
)

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

removed=0

for source_dir in "${SOURCE_DIRS[@]}"; do
  if [ ! -d "$source_dir" ]; then
    continue
  fi

  for skill_dir in "$source_dir"/*; do
    if [ ! -d "$skill_dir" ]; then
      continue
    fi

    skill_name=$(basename "$skill_dir")
    link="$skill_dir/$skill_name"

    if [ ! -L "$link" ]; then
      continue
    fi

    target=$(readlink "$link" 2>/dev/null || true)
    resolved=$(resolve_path "$link")

    if [[ "$target" == *"/.agents/skills/$skill_name"* || "$target" == *"/.agents/skills-internal/$skill_name"* || "$resolved" == "$skill_dir" ]]; then
      rm "$link"
      removed=$((removed + 1))
    fi
  done
done

if [ "$removed" -eq 0 ]; then
  echo "- self-links: ok"
else
  echo "OK self-links: removed $removed"
fi
