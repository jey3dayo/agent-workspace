#!/usr/bin/env bash
set -euo pipefail

# skills-internal から skills へ特定スキルをコピー
# 外部リポジトリの更新後に自前カスタマイズを再適用する

SKILLS_TO_SYNC=(
  "codex-system"
  "gemini-system"
)

echo "=== skills-internal → skills 同期 ==="
echo

for skill in "${SKILLS_TO_SYNC[@]}"; do
  src="$HOME/.agents/skills-internal/$skill"
  dst="$HOME/.agents/skills/$skill"
  
  if [ ! -d "$src" ]; then
    echo "⚠ スキップ: $skill (skills-internal に存在しません)"
    continue
  fi
  
  if [ ! -d "$dst" ]; then
    echo "⚠ スキップ: $skill (skills に存在しません)"
    continue
  fi
  
  echo "同期中: $skill"

  # SKILL.mdのみをコピー（ディレクトリ構造は維持しない）
  #
  # 設計意図: references/ ディレクトリは同期対象外
  #
  # skills-internal/codex-system/references/ 配下には多数の参照ドキュメント
  # (agent-prompts.md、code-review-task.mdなど)が存在しますが、これらは意図的に
  # 同期対象外としています。
  #
  # 理由:
  # - references/ は skills-internal 固有のカスタムドキュメント
  # - 外部リポジトリ (skills/) は独自のreferences/を持つべき
  # - SKILL.md内のreferences/リンクは skills-internal 内でのみ解決される
  # - 外部リポジトリへの一方的な上書きを避ける
  #
  # SKILL.mdのみを同期することで、スキルのエントリポイント定義だけを
  # 最新化し、詳細なリファレンスは各リポジトリが独立して管理します。

  if [ -f "$src/SKILL.md" ]; then
    cp -f "$src/SKILL.md" "$dst/SKILL.md"
    echo "✓ 完了: $skill (SKILL.md)"
  else
    echo "⚠ スキップ: $skill (SKILL.md が存在しません)"
  fi
  echo
done

echo "=== 同期完了 ==="
