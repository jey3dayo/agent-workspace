#!/bin/bash

# スキル同期スクリプト
# ~/.agents/skills/ と ~/.agents/skills-internal/ の全スキルを3箇所に同期する

set -euo pipefail

# ソーススキルディレクトリ（外部 → 内部の順で処理。後勝ちになる）
SOURCE_DIRS=(
  "$HOME/.agents/skills"
  "$HOME/.agents/skills-internal"
)
TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.opencode/skills"
)

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

# /tmp 参照やリンク切れを検出して同期事故を防ぐ
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

validate_skill_dir() {
  local skill_dir="$1"
  local bad=0

  while IFS= read -r link; do
    local target resolved
    target=$(readlink "$link" 2>/dev/null || true)

    if [ ! -e "$link" ]; then
      # 自己参照系のリンクは許容（readlink -f がループで失敗するため）
      if [[ "$target" == *"/.agents/skills/"* ]]; then
        continue
      fi
      log_error "  内部リンク切れ: $link -> ${target:-?}"
      bad=1
      continue
    fi

    if [[ "$target" == /tmp/* || "$target" == /private/tmp/* ]]; then
      log_error "  /tmp リンク検出: $link -> $target"
      bad=1
      continue
    fi

    resolved=$(resolve_path "$link")
    if [[ "$resolved" == /tmp/* || "$resolved" == /private/tmp/* ]]; then
      log_error "  /tmp リンク検出: $link -> $resolved"
      bad=1
    fi
  done < <(find "$skill_dir" -type l 2>/dev/null)

  return $bad
}

# スキルの同期
sync_skills() {
  echo "=== スキル同期開始 ==="
  echo

  # ソースディレクトリの存在確認
  local has_source=0
  for source_dir in "${SOURCE_DIRS[@]}"; do
    if [ -d "$source_dir" ]; then
      has_source=1
    else
      log_warn "ソースディレクトリが存在しません: $source_dir"
    fi
  done
  if [ "$has_source" -eq 0 ]; then
    log_error "有効なソースディレクトリがありません"
    exit 1
  fi

  # ターゲットディレクトリの確認・作成
  for target_dir in "${TARGET_DIRS[@]}"; do
    if [ ! -d "$target_dir" ]; then
      log_warn "ターゲットディレクトリを作成します: $target_dir"
      mkdir -p "$target_dir"
    fi
  done

  # 重複チェック（同名スキルが複数ソースに存在）
  declare -A seen_sources

  # 各スキルを処理
  for source_dir in "${SOURCE_DIRS[@]}"; do
    if [ ! -d "$source_dir" ]; then
      continue
    fi

    for skill_dir in "$source_dir"/*; do
      if [ ! -d "$skill_dir" ]; then
        continue
      fi

      skill_name=$(basename "$skill_dir")
      skill_logged=0

      if ! validate_skill_dir "$skill_dir"; then
        echo "処理中: $skill_name"
        log_error "  内部リンク異常のため同期をスキップ"
        echo
        continue
      fi

      if [ -n "${seen_sources[$skill_name]:-}" ]; then
        log_warn "重複スキル名: $skill_name (${seen_sources[$skill_name]} と $(basename "$source_dir"))"
      fi
      seen_sources["$skill_name"]="$(basename "$source_dir")"

      # 各ターゲットディレクトリにシンボリックリンクを作成
      for target_dir in "${TARGET_DIRS[@]}"; do
        link_path="$target_dir/$skill_name"
        relative_path="../../.agents/$(basename "$source_dir")/$skill_name"

        # 既存のリンクまたはディレクトリを確認
        if [ -L "$link_path" ]; then
          # 既存のシンボリックリンクを確認（リンク切れでも readlink は有効）
          current_target=$(readlink "$link_path")
          if [ "$current_target" = "$relative_path" ]; then
            # 正しいリンクは表示しない
            :
          else
            if [ "$skill_logged" -eq 0 ]; then
              echo "処理中: $skill_name"
              skill_logged=1
            fi
            log_warn "  $(basename "$target_dir"): 異なるリンク先 ($current_target)"
            ln -sf "$relative_path" "$link_path"
            log_info "  $(basename "$target_dir"): リンクを修正"
          fi
        elif [ -e "$link_path" ]; then
          if [ "$skill_logged" -eq 0 ]; then
            echo "処理中: $skill_name"
            skill_logged=1
          fi
          log_warn "  $(basename "$target_dir"): ディレクトリ/ファイルが存在します（スキップ）"
        else
          # 新規リンク作成
          ln -s "$relative_path" "$link_path"
          if [ "$skill_logged" -eq 0 ]; then
            echo "処理中: $skill_name"
            skill_logged=1
          fi
          log_info "  $(basename "$target_dir"): リンク作成"
        fi
      done
      if [ "$skill_logged" -eq 1 ]; then
        echo
      fi
    done
  done

  echo "=== 同期完了 ==="
}

# ステータス表示
show_status() {
  echo "=== スキルリンク状態 ==="
  echo

  for target_dir in "${TARGET_DIRS[@]}"; do
    # ツール名を取得（.claude/.codex/.opencode）
    tool_name=$(basename "$(dirname "$target_dir")")
    echo "[$tool_name]"

    for link in "$target_dir"/*; do
      if [ -L "$link" ]; then
        target=$(readlink "$link")
        name=$(basename "$link")
        if [ -e "$link" ]; then
          echo "  ✓ $name → $target"
        else
          log_error "  ✗ $name → $target (リンク切れ)"
        fi
      elif [ -d "$link" ]; then
        echo "  📁 $(basename "$link") (実体)"
      fi
    done
    echo
  done
}

# メイン処理
case "${1:-sync}" in
  sync)
    sync_skills
    ;;
  status)
    show_status
    ;;
  *)
    echo "使用方法: $0 {sync|status}"
    echo "  sync   - 全スキルを3箇所に同期"
    echo "  status - リンク状態を表示"
    exit 1
    ;;
esac
