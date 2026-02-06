# 対象ツール

## 概要

`~/.agents/` スキル管理システム（Nix Flake + Home Manager）が対応する開発ツール一覧

## 対象ツール一覧

### 1. Claude Code

- スキル: `~/.claude/skills/`
- 設定: `~/.claude/settings.json`
- ルール: `~/.claude/rules/`
- エージェント: `~/.claude/agents/`

### 2. Codex

- スキル: `~/.codex/skills/`
- 設定: `~/.codex/settings.json`

### 3. Cursor

- スキル: `~/.cursor/skills/`

### 4. OpenCode

- スキル: `~/.opencode/skills/`
- 設定: `~/.opencode/settings.json`

### 5. OpenClaw

- スキル: `~/.openclaw/skills/`

### 6. 共有 (Shared)

- スキル: `~/.skills/`

## スキル同期の仕組み

`home.nix` の `targets` で宣言的に定義:

```nix
targets = {
  claude   = { enable = true; dest = ".claude/skills"; };
  codex    = { enable = true; dest = ".codex/skills"; };
  cursor   = { enable = true; dest = ".cursor/skills"; };
  opencode = { enable = true; dest = ".opencode/skills"; };
  openclaw = { enable = true; dest = ".openclaw/skills"; };
  shared   = { enable = true; dest = ".skills"; };
};
```

## 新しいツールの追加方法

1. `home.nix` の `targets` に追記
2. `nix/targets.nix` にも追記（non-HM fallback 用）
3. `home-manager switch --flake ~/.agents`

## 注意事項

- 各ツールのスキルディレクトリには rsync でスキルがコピーされる
- 直接編集せず、`~/.agents/skills-internal/` で管理すること
- 同期は `home-manager switch --flake ~/.agents` または `mise ci` で実行
