# スキル管理ルール

`~/.agents/` を中心としたスキル統一管理システムの AI 向け運用原則。
ディレクトリ構成・運用コマンド・スキル追加手順は [README.md](../../../README.md) を参照。

## スキル配置の原則

### 外部スキル → `flake.nix` の inputs

- flake inputs で GitHub リポジトリをピン留め
- `nix/sources.nix` でパスマッピング

### 自前スキル → `~/.agents/skills-internal/`

- 自作スキル、実験的スキル、カスタマイズスキル
- Single Source of Truth: ここで管理し、Nix バンドルで各ツールに配布
- ローカルスキルは外部スキルより優先（同名 ID の場合）

## 対象ツール一覧

スキルディレクトリ以外のパス情報（AI がファイル操作する際の参考）:

| ツール   | 設定                        | ルール             | エージェント        |
| -------- | --------------------------- | ------------------ | ------------------- |
| Claude   | `~/.claude/settings.json`   | `~/.claude/rules/` | `~/.claude/agents/` |
| Codex    | `~/.codex/settings.json`    | —                  | —                   |
| Cursor   | —                           | —                  | —                   |
| OpenCode | `~/.opencode/settings.json` | —                  | —                   |
| OpenClaw | —                           | —                  | —                   |

`home.nix` の `targets` で宣言的にスキル同期先を定義:

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

## ターゲット追加時の注意

新しいツールを追加する場合、以下の両方を編集する必要がある:

1. `home.nix` の `targets` に追記
2. `nix/targets.nix` にも追記（non-HM fallback 用）

片方だけの編集では不整合が発生する。

## スキル実行時のパス解決

HM による rsync 同期後、各ツールのスキルディレクトリにはスキルの実体コピーが配置される。

- スキルが `scripts/foo.py` を参照 → `~/.claude/skills/<skill-name>/scripts/foo.py`
- 全ツールに同一内容が配布されるため、どのツールからでも同じパスパターンで参照可能

## 注意事項

- スキル追加・変更後は `home-manager switch --flake ~/.agents --impure` を実行
- 同名スキルは `skills-internal` が優先（ローカル後勝ち）
- 外部ソース間の重複 ID はエラー
- `nix flake update` でソース更新後は再インストールが必要
- 直接編集せず、`~/.agents/skills-internal/` で管理すること
