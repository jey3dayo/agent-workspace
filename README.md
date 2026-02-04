# Codex Skills Collection

このリポジトリは、Codex エージェント向けのスキル（SKILL.md）を集約・運用するための場所です。
README では「入口としての概要」と「スキル一覧」をまとめ、詳細は各スキル配下の `SKILL.md` を参照します。

## 目的

- スキルの発見性を高め、用途に合ったスキルを素早く見つける
- スキルの作成・運用ルールを簡潔に共有する
- 変更点の入口を README に集約する

## ディレクトリ構成

- `skills-internal/` : 自作スキル（`skills-internal/<skill-name>/SKILL.md`）
- `skills/` : 外部由来スキル（チェックアウト/インストール済み）
- `scripts/` : スキル運用や補助スクリプト（必要に応じて）
- `mise.toml` : 開発・実行環境の設定

## 使い方（概要）

- スキルは **名前で指定** するか、**依頼内容がスキル説明に一致**したときに利用します。
- 具体的な手順・コマンド・制約は **各 `SKILL.md` が正** です。
- README は **一覧性** と **入口** を重視し、詳細は最小限に留めます。

## 同期（即時反映）

- `./scripts/sync-skills.sh` で `skills/` と `skills-internal/` を各エージェント（`.claude` / `.codex` / `.opencode`）に同期します
- 同名スキルがある場合は **`skills-internal` を優先** します（重複は原則置かない）
- 状態確認は `./scripts/sync-skills.sh status`

## スキル一覧（自作 / 外部）

### 自作スキル（skills-internal）

| カテゴリ              | スキル                                                                    | 概要                                                                |
| --------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 自動化 / 生成         | [`generate-svg`](skills-internal/generate-svg/SKILL.md)                   | SVG 図解生成（透過背景、ダークモード対応、Material Icons 統合など） |
| GitHub / CI           | [`task-to-pr`](skills-internal/task-to-pr/SKILL.md)                       | 依頼→実装→チェック→PR作成まで一気通貫で実施                         |
| アーキテクチャ / 運用 | [`integration-framework`](skills-internal/integration-framework/SKILL.md) | Claude Code 統合アーキテクチャのガイド（TaskContext/Bus など）      |

### 外部スキル（skills/）

> **Note**: これらのスキルは `npx skills add` でインストールされます。詳細は各リポジトリを参照してください。

| カテゴリ              | スキル                                                                                     | 概要                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| 自動化 / 生成         | [`agent-browser`](https://github.com/vercel-labs/agent-browser)                            | Web 操作の自動化（ナビゲーション、フォーム入力、スクリーンショット、データ抽出など） |
| GitHub / CI           | [`gh-address-comments`](https://github.com/openai/skills/tree/main/skills/.curated)        | GitHub PR のレビューコメント対応を支援（gh CLI）                                     |
| GitHub / CI           | [`gh-fix-ci`](https://github.com/openai/skills/tree/main/skills/.curated)                  | GitHub Actions の失敗ログを調査し、修正計画から実装まで支援                          |
| 設計 / 品質           | [`ui-ux-pro-max`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)                 | UI/UX 設計の包括的ガイド（スタイル、配色、フォント等）                               |
| 設計 / 品質           | [`web-design-guidelines`](https://github.com/vercel-labs/agent-skills)                     | Web インターフェース設計のガイドライン準拠チェック                                   |
| 設計 / 品質           | [`vercel-react-best-practices`](https://github.com/vercel-labs/agent-skills)               | React/Next.js のパフォーマンス最適化ガイド（Vercel）                                 |
| アーキテクチャ / 運用 | [`skill-creator`](https://github.com/openai/skills/tree/main/skills/.system/skill-creator) | 新規スキル作成・既存スキル更新のガイド                                               |
| アーキテクチャ / 運用 | [`codex-system`](https://github.com/DeL-TaiseiOzaki/claude-code-orchestra)                 | Claude Code ↔ Codex CLI の連携。Codex を深い推論パートナーとして活用                 |
| アーキテクチャ / 運用 | [`gemini-system`](https://github.com/DeL-TaiseiOzaki/claude-code-orchestra)                | Claude Code ↔ Gemini CLI の連携。Gemini をリサーチ・マルチモーダル専門家として活用   |

## スキル追加・更新の流れ（一般）

1. **自作スキル**: `skills-internal/<skill-name>/SKILL.md` を作成または更新する
2. **外部スキル**: `npx skills add <repository>` でインストールする
   - 例: `npx skills add vercel-labs/agent-browser -g -y`
3. README のスキル一覧に追加/更新する
4. 依存するツール・前提条件があれば `SKILL.md` に明記する
5. `mise ci` を実行してスキル同期を確認する

## 例外: ui-ux-pro-max の手動構成パターン

`ui-ux-pro-max` は `.claude/skills` 側が `src/` へのシンボリックリンク構成のため、
`skills add` 等で `.claude/skills` だけを取得するとリンク切れになりやすい。

対策:

- `skills/` 配下は **実体ディレクトリ（scripts/data/templates）** で保持する
- 実体は **git で管理しない**（容量肥大化を避けるため `.gitignore` 済み）
- 破損チェック: `mise run skills:check-links`（警告のみ）
- 修復/取得: `mise run skills:fix:ui-ux-pro-max`

`mise ci` は `skills:check-links` と `skills:fix:ui-ux-pro-max` を先頭で実行する。

## 運用方針

- **README は入口**、**SKILL.md が詳細**の原則を守る
- 追加・更新時は README と SKILL.md の記載を同期する
- 既存のスキルの挙動を変える場合は、影響範囲と使い方の更新を明記する
