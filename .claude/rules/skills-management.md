# スキル管理ルール

## 目的

`~/.agents/` を中心としたスキル統一管理システムの運用ルール

## ディレクトリ構造

```
~/.agents/
├── skills/           # 外部リポジトリからのスキル（npx add-skill、git submodule等）
├── skills-internal/  # 自前で作成・管理するスキル（Single Source of Truth）
└── scripts/
    └── sync-skills.sh  # 自動同期スクリプト
```

**同期先**:

- `~/.claude/skills/` → Claude Code
- `~/.codex/skills/` → Codex
- `~/.opencode/skills/` → OpenCode

## スキル配置の原則

### 1. 外部スキル → `~/.agents/skills/`

- `npx add-skill <repo> -a claude-code` で取得
- 公開スキル、Vercel公式、コミュニティスキル
- Git submoduleでの管理も可能

### 2. 自前スキル → `~/.agents/skills-internal/`

- 自作スキル、実験的スキル、カスタマイズスキル
- **Single Source of Truth**: ここで管理し、各ツールに同期
- marketplace等の外部リポジトリからコピーしたものもここで管理

## 同期の仕組み

**処理順序**: `skills/` → `skills-internal/` （後勝ち）

- 同名スキルがある場合、`skills-internal/` が優先される
- `mise ci` 実行時に自動同期
- 手動同期: `~/.agents/scripts/sync-skills.sh`

## 循環リンク対策

`sync-skills.sh` は自動的に循環シンボリックリンクを検出・削除：

```bash
# 検出例: skills-internal/code-review/code-review -> ../../.agents/skills-internal/code-review
⚠ 循環リンク検出・削除: /path/to/circular/link
```

**原因**: 外部からのrsyncやコピー時に混入する可能性
**対策**: 同期スクリプトが自動で削除するため、手動対応不要

## 新規スキル作成フロー

1. 公開スキルを探す: `npx add-skill <repo> -a claude-code`
2. 自作する場合: `~/.agents/skills-internal/{skill-name}/SKILL.md` を作成
3. 同期を実行: `~/.agents/scripts/sync-skills.sh` または `mise ci`

## スキル実行時のパス解決

外部スキルが相対パスでスクリプトやファイルを参照している場合:

1. **スキルディレクトリを基準とする**: スキルが`scripts/foo.py`を参照している場合、`~/.agents/skills/<skill-name>/scripts/foo.py`として実行する
2. **絶対パスの構築**: 相対パスを見つけたら、`~/.agents/skills/<skill-name>/`を接頭辞として絶対パスに変換する
3. **シンボリックリンク**: `~/.claude/skills/<skill-name>`は`~/.agents/skills/<skill-name>`へのシンボリックリンクなので、どちらを基準にしても同じファイルを参照する

**例**:

- スキル: `gh-address-comments`
- SKILL.mdの指示: `scripts/fetch_comments.py`を実行
- 実際のパス: `~/.agents/skills/gh-address-comments/scripts/fetch_comments.py`
- 実行コマンド: `python3 ~/.agents/skills/gh-address-comments/scripts/fetch_comments.py`

## 注意事項

- スキル追加・変更後は必ず同期を実行すること
- 循環リンクは自動削除されるため、手動対応は不要
- 同名スキルがある場合は `skills-internal` が優先される（後勝ち）
- スキルを削除する場合は、両方のディレクトリから削除すること
