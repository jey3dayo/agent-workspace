# スキル管理ルール

## 目的

`~/.agents/` を中心としたスキル統一管理システムの運用ルール（Nix Flake + Home Manager ベース）

## ディレクトリ構造

```
~/.agents/
├── flake.nix              # Flake 定義（HM + apps）
├── flake.lock             # ピン留めされた依存
├── nix/
│   ├── lib.nix            # コア関数（discover/select/bundle/sync）
│   ├── module.nix         # HM モジュール（programs.agent-skills）
│   ├── sources.nix        # 外部ソース定義
│   ├── selection.nix      # 有効化スキル ID リスト
│   └── targets.nix        # デフォルトターゲット定義
├── home.nix               # HM 設定（ユーザーカスタマイズ）
├── skills-internal/       # 自前スキル（Single Source of Truth）
└── scripts/
    └── replace-bold-headings.js  # コンテンツ変換
```

## 同期先

- `~/.claude/skills/` → Claude Code
- `~/.codex/skills/` → Codex
- `~/.cursor/skills/` → Cursor
- `~/.opencode/skills/` → OpenCode
- `~/.openclaw/skills/` → OpenClaw
- `~/.skills/` → 共有

## スキル配置の原則

### 1. 外部スキル → `flake.nix` の inputs

- flake inputs で GitHub リポジトリをピン留め
- `nix/sources.nix` でパスマッピング

### 2. 自前スキル → `~/.agents/skills-internal/`

- 自作スキル、実験的スキル、カスタマイズスキル
- Single Source of Truth: ここで管理し、Nix バンドルで各ツールに配布
- ローカルスキルは外部スキルより優先（同名 ID の場合）

## 運用コマンド

| 操作                | コマンド                                           |
| ------------------- | -------------------------------------------------- |
| スキルインストール  | `home-manager switch --flake ~/.agents`            |
| 全ソース更新        | `nix flake update --flake ~/.agents`               |
| 特定 input 更新     | `nix flake update openai-skills --flake ~/.agents` |
| スキル一覧表示      | `nix run ~/.agents#list`                           |
| バリデーション      | `nix run ~/.agents#validate`                       |
| 更新 + インストール | `mise run skills:update`                           |

## 新規スキル作成フロー

1. `~/.agents/skills-internal/{skill-name}/SKILL.md` を作成
2. `nix/selection.nix` の enable リストに追加
3. `home-manager switch --flake ~/.agents`

## ターゲット追加方法

1. `home.nix` の targets に追記
2. `nix/targets.nix` にも追記（non-HM fallback 用）
3. `home-manager switch --flake ~/.agents`

## スキル実行時のパス解決

HM による rsync 同期後、各ツールのスキルディレクトリにはスキルの実体コピーが配置される。

- スキルが `scripts/foo.py` を参照 → `~/.claude/skills/<skill-name>/scripts/foo.py`
- 全ツールに同一内容が配布されるため、どのツールからでも同じパスパターンで参照可能

## 注意事項

- スキル追加・変更後は `home-manager switch --flake ~/.agents` を実行
- 同名スキルは `skills-internal` が優先（ローカル後勝ち）
- 外部ソース間の重複 ID はエラー
- `nix flake update` でソース更新後は再インストールが必要
