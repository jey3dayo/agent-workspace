#!/usr/bin/env bash
set -euo pipefail

# Skills管理をGitからnpx skillsに移行するスクリプト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Skills管理移行スクリプト ==="
echo ""

cd "$AGENTS_DIR"

# Step 1: Git管理から削除
echo "Step 1: Git管理からskills/を削除中..."
git rm -r --cached skills/ 2>/dev/null || true
echo "✓ Git追跡から削除完了"
echo ""

# Step 2: 変更をコミット
echo "Step 2: 変更をコミット中..."
git add .gitignore
git commit -m "chore: Migrate skills/ from git to npx skills management

- Remove skills/ from git tracking
- Add skills/ to .gitignore
- Skills are now managed exclusively by npx skills" || echo "⚠ コミットするものがありません"
echo ""

# Step 3: 実体を削除してクリーンインストール
echo "Step 3: 既存スキルを削除して再インストール..."
rm -rf skills/

# スキルリスト
declare -a SKILLS=(
  "vercel-labs/agent-skills --skill vercel-react-best-practices web-design-guidelines"
  "vercel-labs/agent-browser"
  "openai/skills --skill gh-address-comments gh-fix-ci skill-creator"
  "nextlevelbuilder/ui-ux-pro-max-skill"
)

# 各スキルをインストール
for skill in "${SKILLS[@]}"; do
  echo "Installing: $skill"
  npx skills add $skill -g -y || echo "⚠ スキルインストール失敗: $skill"
done

echo ""
echo "✓ スキル再インストール完了"
echo ""

# Step 4: 検証
echo "Step 4: インストール済みスキル確認..."
npx skills list -g
echo ""

# Step 5: mise ci実行
echo "Step 5: mise ciで同期検証..."
mise ci

echo ""
echo "=== 移行完了 ==="
echo ""
echo "確認事項:"
echo "1. npx skills list -g でスキル一覧を確認"
echo "2. ~/.claude/skills/ にシンボリックリンクが作成されているか確認"
echo "3. git status で skills/ が無視されているか確認"
