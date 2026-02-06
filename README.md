# Agent Skills

AI エージェント（Claude Code, Codex, Cursor 等）向けスキルの宣言的管理システム。
Nix Flake + Home Manager により、スキルの取得・選択・配布を一元管理する。

## ディレクトリ構成

```
~/.agents/
├── flake.nix          # Flake 定義（inputs + outputs）
├── flake.lock         # 依存のピン留め
├── home.nix           # Home Manager 設定
├── nix/
│   ├── lib.nix        # コア関数（discover/select/bundle/sync）
│   ├── module.nix     # HM モジュール（programs.agent-skills）
│   ├── sources.nix    # 外部ソース → パスマッピング
│   ├── selection.nix  # 有効スキル ID リスト
│   └── targets.nix    # デプロイ先定義
├── skills-internal/   # 自作スキル（Single Source of Truth）
├── scripts/           # コンテンツ変換スクリプト
└── mise.toml          # タスクランナー
```

## 前提条件

- [Nix](https://nixos.org/) がインストールされていること（Flakes 有効）
- [Home Manager](https://github.com/nix-community/home-manager) が利用可能であること

## 使い方

### スキルのインストール

```bash
home-manager switch --flake ~/.agents --impure
```

### スキル一覧の確認

```bash
nix run ~/.agents#list
```

### バリデーション

```bash
nix run ~/.agents#validate
```

### mise 経由の操作

```bash
mise run skills:install     # HM でインストール
mise run update             # 全ソース更新 + 再インストール
mise run ci                 # lint + バリデーション
mise run skills:list        # 有効スキル一覧
mise run skills:validate    # バリデーション
```

## 外部スキルの追加

1. `flake.nix` の `inputs` に GitHub リポジトリを追加:

   ```nix
   my-skills = {
     url = "github:owner/repo";
     flake = false;
   };
   ```

2. `nix/sources.nix` にパスマッピングを追加:

   ```nix
   my-skills.path = "${inputs.my-skills}/skills";
   ```

3. `nix/selection.nix` の `enable` リストにスキル ID を追加
4. `home-manager switch --flake ~/.agents --impure`

## 自作スキルの追加

1. `skills-internal/<name>/SKILL.md` を作成
2. `nix/selection.nix` の `enable` リストに ID を追加
3. `home-manager switch --flake ~/.agents --impure`

同名スキルがある場合、`skills-internal`（ローカル）が外部ソースより優先される。

## 同期先（ターゲット）

| ツール   | 配置先                |
| -------- | --------------------- |
| Claude   | `~/.claude/skills/`   |
| Codex    | `~/.codex/skills/`    |
| Cursor   | `~/.cursor/skills/`   |
| OpenCode | `~/.opencode/skills/` |
| OpenClaw | `~/.openclaw/skills/` |
| 共有     | `~/.skills/`          |

ターゲットの追加・変更は `home.nix` の `targets` と `nix/targets.nix` を編集する。

## スキル一覧

### 自作スキル（skills-internal） — 24 スキル

| スキル ID                | 概要                                         |
| ------------------------ | -------------------------------------------- |
| agent-creator            | サブエージェント定義の作成ガイド             |
| cc-sdd                   | Kiro 形式 Spec-Driven Development プラグイン |
| claude-system            | Claude Code の創造的活用ガイド               |
| code-quality-improvement | ESLint / 型安全性の段階的改善                |
| code-review              | 設定可能なコードレビュー・品質評価           |
| codex-system             | Codex CLI 連携（深い推論パートナー）         |
| command-creator          | slash コマンドの作成ガイド                   |
| doc-standards            | ドキュメント標準フレームワーク               |
| docs-manager             | ドキュメントの検証・管理                     |
| dotfiles-integration     | dotfiles クロスツール統合レビュー            |
| gemini-system            | Gemini CLI 連携（リサーチ・マルチモーダル）  |
| generate-svg             | SVG 図解生成（透過背景・ダークモード対応）   |
| gh-fix-review            | GitHub PR レビューコメントの自動処理         |
| integration-framework    | Claude Code 統合アーキテクチャガイド         |
| markdown-docs            | Markdown ドキュメントのレビュー・改善        |
| marketplace-builder      | Claude Code Marketplace 構築支援             |
| mcp-tools                | MCP サーバーセットアップ・セキュリティガイド |
| polish                   | lint/format/test の自動修正イテレーション    |
| review                   | 包括的コードレビュー（複数モード対応）       |
| rules-creator            | ルール・steering・hookify の作成ガイド       |
| sync-origin              | リモートデフォルトブランチとの自動同期       |
| task                     | 自然言語タスクの自動ルーティング             |
| task-to-pr               | タスク → 実装 → PR 作成の一気通貫実行        |
| tsr                      | TypeScript/React の未使用コード検出・除去    |

### 外部スキル — 6 スキル

| スキル ID             | ソース               | 概要                                           |
| --------------------- | -------------------- | ---------------------------------------------- |
| agent-browser         | vercel-agent-browser | Web 操作の自動化（ナビゲーション・フォーム等） |
| gh-address-comments   | openai-skills        | GitHub PR レビューコメント対応支援             |
| gh-fix-ci             | openai-skills        | GitHub Actions 失敗の調査・修正支援            |
| skill-creator         | openai-skills        | 新規スキル作成・更新ガイド                     |
| ui-ux-pro-max         | ui-ux-pro-max        | UI/UX 設計の包括的ガイド                       |
| web-design-guidelines | vercel-agent-skills  | Web インターフェース設計ガイドライン           |

外部ソースは `flake.nix` の inputs でピン留めされ、`nix flake update` で更新できる。

## 運用コマンド一覧

| 操作                  | コマンド                                         |
| --------------------- | ------------------------------------------------ |
| インストール          | `home-manager switch --flake ~/.agents --impure` |
| 全ソース更新          | `nix flake update --flake ~/.agents`             |
| 特定ソース更新        | `nix flake update <input> --flake ~/.agents`     |
| スキル一覧            | `nix run ~/.agents#list`                         |
| バリデーション        | `nix run ~/.agents#validate`                     |
| lint + バリデーション | `mise run ci`                                    |
| 更新 + インストール   | `mise run update`                                |
