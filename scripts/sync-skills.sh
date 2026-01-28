#!/bin/bash

# スキル同期スクリプト
# ~/.agents/skills/ の全スキルを3箇所に同期する

set -euo pipefail

AGENTS_SKILLS="$HOME/.agents/skills"
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

# スキルの同期
sync_skills() {
  echo "=== スキル同期開始 ==="
  echo

  # ソースディレクトリの存在確認
  if [ ! -d "$AGENTS_SKILLS" ]; then
    log_error "ソースディレクトリが存在しません: $AGENTS_SKILLS"
    exit 1
  fi

  # ターゲットディレクトリの確認・作成
  for target_dir in "${TARGET_DIRS[@]}"; do
    if [ ! -d "$target_dir" ]; then
      log_warn "ターゲットディレクトリを作成します: $target_dir"
      mkdir -p "$target_dir"
    fi
  done

  # 各スキルを処理
  for skill_dir in "$AGENTS_SKILLS"/*; do
    if [ ! -d "$skill_dir" ]; then
      continue
    fi

    skill_name=$(basename "$skill_dir")
    skill_logged=0

    # 各ターゲットディレクトリにシンボリックリンクを作成
    for target_dir in "${TARGET_DIRS[@]}"; do
      link_path="$target_dir/$skill_name"
      relative_path="../../.agents/skills/$skill_name"

      # 既存のリンクまたはディレクトリを確認
      if [ -e "$link_path" ]; then
        if [ -L "$link_path" ]; then
          # 既存のシンボリックリンクを確認
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
        else
          if [ "$skill_logged" -eq 0 ]; then
            echo "処理中: $skill_name"
            skill_logged=1
          fi
          log_warn "  $(basename "$target_dir"): ディレクトリ/ファイルが存在します（スキップ）"
        fi
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
