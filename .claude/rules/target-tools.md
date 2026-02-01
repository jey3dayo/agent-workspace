# 対象ツール

## 概要

`~/.agents/` スキル管理システムが対応する開発ツール一覧

## 対象ツール一覧

### 1. Claude Code

**説明**: Anthropic公式のCLIツール

**paths**:

- スキル: `~/.claude/skills/`
- 設定: `~/.claude/settings.json`
- ルール: `~/.claude/rules/`
- エージェント: `~/.claude/agents/`

### 2. Codex

**説明**: コード補完・生成ツール

**paths**:

- スキル: `~/.codex/skills/`
- 設定: `~/.codex/settings.json`

### 3. OpenCode

**説明**: オープンソースコーディング支援ツール

**paths**:

- スキル: `~/.opencode/skills/`
- 設定: `~/.opencode/settings.json`

## スキル同期との関係

`~/.agents/scripts/sync-skills.sh` は以下のディレクトリにスキルを同期します：

```bash
SOURCE_DIRS=(
  "$HOME/.agents/skills"           # 外部スキル
  "$HOME/.agents/skills-internal"  # 自前スキル（後勝ち）
)

TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.opencode/skills"
)
```

## 新しいツールの追加方法

1. `~/.agents/scripts/sync-skills.sh` の `TARGET_DIRS` に追加
2. このドキュメントに情報を追記
3. 同期スクリプトを実行: `~/.agents/scripts/sync-skills.sh`

## 注意事項

- 各ツールのスキルディレクトリは `~/.agents/` へのシンボリックリンク
- 直接編集せず、`~/.agents/skills-internal/` で管理すること
- 同期は `mise ci` または手動実行で行う
