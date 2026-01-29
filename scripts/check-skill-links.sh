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

check_skill_dir() {
  local skill_dir="$1"
  local skill_name="$2"
  local had_issue=0

  while IFS= read -r link; do
    local target resolved
    target=$(readlink "$link" 2>/dev/null || true)

    if [ ! -e "$link" ]; then
      if [[ "$target" == *"/.agents/skills/"* || "$target" == *"/.agents/skills-internal/"* ]]; then
        continue
      fi
      echo "WARN $skill_name: broken link: $link -> ${target:-?}"
      had_issue=1
      continue
    fi

    if is_tmp_path "$target"; then
      echo "WARN $skill_name: /tmp link: $link -> $target"
      had_issue=1
      continue
    fi

    resolved=$(resolve_path "$link")
    if [ -n "$resolved" ] && is_tmp_path "$resolved"; then
      echo "WARN $skill_name: /tmp link: $link -> $resolved"
      had_issue=1
    fi
  done < <(find "$skill_dir" -type l 2>/dev/null)

  return $had_issue
}

echo "=== skills link check ==="

skills_with_issues=0

for source_dir in "${SOURCE_DIRS[@]}"; do
  if [ ! -d "$source_dir" ]; then
    echo "WARN source dir missing: $source_dir"
    continue
  fi

  for skill_dir in "$source_dir"/*; do
    if [ ! -d "$skill_dir" ]; then
      continue
    fi

    skill_name=$(basename "$skill_dir")
    if check_skill_dir "$skill_dir" "$skill_name"; then
      echo "- $skill_name ok"
    else
      skills_with_issues=$((skills_with_issues + 1))
    fi
  done
done

echo "summary: $skills_with_issues skills with issues"
exit 0
