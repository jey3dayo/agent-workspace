# Rules Creator 詳細リファレンス

## ルールタイプ詳細

### 1. Guidelines (CLAUDE.md)

**構造:**

```markdown
# 開発協働ガイド

## 基本原則

### 1. 型安全性

- 型アサーション排除
- any型排除
- 適切なエラーハンドリング

### 2. 品質保証

- テスト実行必須
- Lint違反0件
- ビルド成功確認

## ワークフロー

1. 計画承認
2. コード理解
3. 型安全実装
4. 品質保証
```

**特徴:**

- 暗黙的な強制
- AIが理解し従う
- システムレベルの強制なし

### 2. Settings Rules (.kiro/settings/rules/)

**YAML フロントマター（推奨）:**

Settings Rules では、ルールを特定のファイルパターンに限定するために YAML frontmatter を使用できます。

```yaml
---
paths: src/**/*.ts, tests/**/*.test.ts
---
```

**paths フィールド:**

- **目的**: ルールが適用されるファイルパターンを指定
- **省略時**: ルールは全ファイルに無条件適用
- **サポートされるパターン**:
  - `**` - 任意の深さのディレクトリ（例：`src/**/*.ts`）
  - `*` - 任意のファイル名（例：`*.md`）
  - `{a,b}` - ブレース展開で複数パターン（例：`{src,lib}/**/*.ts`）
  - カンマ区切り - 複数パターンの組み合わせ（例：`src/**/*.ts, tests/**/*.test.ts`）

**使用例:**

```yaml
# TypeScript 型安全性ルール
---
paths: {src,lib}/**/*.ts, {src,lib}/**/*.tsx
---

# テストルール
---
paths: tests/**/*.test.ts, **/__tests__/**/*.ts
---

# アーキテクチャルール（ドメイン層のみ）
---
paths: src/domain/**/*.ts
---
```

**構造:**

```markdown
---
paths: src/**/*.ts, tests/**/*.test.ts
---

# ルール名

## 適用範囲（Paths）

このルールは以下のファイルパターンに適用されます：...

## 制約

[明確で明示的な要求または禁止の記述]

## 根拠

[なぜこのルールが存在するか - ビジネス/技術的正当性]

## 例

### ✅ 正しい

[ルールに従うコード例]

### ❌ 不正

[ルールに違反するコード例]

## 例外

[有効な例外があれば文書化]

## 強制

[このルールをどうチェックするか]

- [ ] 手動レビュー
- [ ] 自動Linter
- [ ] CI/CDチェック
```

**例（型安全性ルール）:**

```markdown
# 型安全性: any型禁止

## 制約

TypeScriptコードで `any` 型の使用を禁止

## 根拠

型安全性を維持し、実行時エラーを防ぐため

## 例

### ✅ 正しい

\`\`\`typescript
function process(data: User): Result<ProcessedData, Error> {
// 明示的な型定義
}
\`\`\`

### ❌ 不正

\`\`\`typescript
function process(data: any): any {
// any型の使用
}
\`\`\`

## 強制

- [x] ESLint: @typescript-eslint/no-explicit-any
- [x] CI/CD: 型チェック必須
```

### 3. Steering Documents (.kiro/steering/)

**標準ファイル:**

- `product.md` - プロダクトビジョン、機能、ビジネスコンテキスト
- `tech.md` - 技術スタック、アーキテクチャ決定、パターン
- `structure.md` - プロジェクトレイアウト、モジュール構成、命名規則

**構造:**

```markdown
# [コンテキスト領域] Steering

## 概要

[この領域の高レベル要約]

## 主要決定事項

### 決定1: [タイトル]

**コンテキスト**: なぜこの決定をしたか
**決定**: 何を決定したか
**影響**: 開発にどう影響するか

## パターンと規則

### パターン1: [名前]

**使用法**: いつこのパターンを使うか
**実装**: どう実装するか
**例**: 例ファイルへの参照

## AIへのコンテキスト

この領域で作業する際:

1. ガイドライン1
2. ガイドライン2

## 参照

- ドキュメント: [リンク]
- 例: [ファイルパス]
```

**例（技術Steering）:**

```markdown
# 技術Steering

## 概要

Next.js 15アプリケーション、レイヤードアーキテクチャ、Result<T,E>パターン

## 主要決定事項

### 決定1: レイヤードアーキテクチャ

**コンテキスト**: 関心の分離とテスタビリティのため
**決定**: Domain → Application → Interface 層
**影響**: 各機能はこの構造に従う必要がある

### 決定2: Result<T,E>パターン

**コンテキスト**: 明示的なエラーハンドリング
**決定**: すべての操作がResult型を返す
**影響**: 例外投げ禁止、常にエラーケースを処理

## パターンと規則

- **Factory Functions**: ページ初期化に `getInitialProps` 使用
- **Type Safety**: any型禁止、strictTypeScript設定
```

### 4. Hookify Rules (.claude/hookify.\*.local.md)

**構造:**

```yaml
---
event: bash | file | stop | prompt | all
pattern: "command pattern" または複雑な条件
action: warn | block
message: ユーザーへのメッセージ
---

# Hookify Rule: [ルール名]

## トリガー
[いつこのルールが実行されるか]

## 条件
[どの条件下でアクションが実行されるか]

## アクション
[どの自動アクションが実行されるか]

## 失敗時
[アクションが失敗したら何が起こるか]
```

**例（Pre-Commit品質ゲート）:**

```yaml
---
event: bash
pattern: "^git commit"
action: block
message: "Pre-commit checks failed. Run: npm run lint && npm run test"
---

# Hookify Rule: Pre-Commit Quality Gate

## トリガー
git commitコマンド実行前

## 条件
常に（すべてのコミット）

## アクション
1. Linter実行: `npm run lint`
2. 型チェック: `npm run type-check`
3. テスト: `npm run test`

## 失敗時
- コミットをブロック
- エラー出力を表示
- 修正を提案
```

**例（危険なコマンドの警告）:**

```yaml
---
event: bash
pattern: "rm -rf"
action: warn
message: "⚠️  Warning: Destructive command detected. Are you sure?"
---

# Hookify Rule: Warn on Dangerous Delete

## トリガー
`rm -rf` コマンド検出時

## アクション
ユーザーに警告を表示（ブロックはしない）

## 失敗時
なし（警告のみ）
```

## ルール作成のベストプラクティス

### 1. 明確さと具体性

**良い例:**

> "すべての公開APIエンドポイントはZodスキーマを使用して入力を検証しなければならない"

**悪い例:**

> "入力を適切に検証する"

### 2. 正当化

常に **WHY** を説明し、**WHAT** だけでなく

### 3. 例

正しい例と不正な例の両方を提供

### 4. 測定可能性

ルールは検証可能であるべき（手動または自動）

### 5. 一貫性

ルールはプロジェクトの全体的な哲学や他のルールと一致すべき

### 6. 保守性

プロジェクトが進化するにつれてルールをレビューし更新

## ルール構成

### ファイル命名

- **kebab-case**: `rule-name.md`
- **説明的**: 名前が制約を反映
- **カテゴリ化**: 必要に応じて関連ルールをサブディレクトリに

### ディレクトリ構造

```
.kiro/
├── settings/
│   └── rules/
│       ├── type-safety/
│       │   ├── no-any-type.md
│       │   └── explicit-return-types.md
│       ├── architecture/
│       │   ├── layer-dependencies.md
│       │   └── import-restrictions.md
│       └── testing/
│           └── integration-coverage.md
├── steering/
│   ├── product.md
│   ├── tech.md
│   ├── structure.md
│   └── custom/
│       ├── security.md
│       └── performance.md
.claude/
└── hookify.pre-commit-quality.local.md
```

## AIワークフローとの統合

### AIがルールをどう使用するか

**Settings Rules:**

1. 分析と実装中に読み込まれる
2. 違反は警告またはアクションをブロック
3. コードレビューフィードバックで参照される

**Steering:**

1. セッション開始時に永続的メモリとして読み込まれる
2. 明示的な言及なしに意思決定を伝える
3. コンテキストを提供

**Hookify:**

1. イベントによって自動的にトリガー
2. AIの関与なしに実行
3. AIは hookify 結果を参照可能

### ルールの競合

ルールが競合する場合:

1. **明示的なルール** がガイドラインを上書き
2. **プロジェクトルール** がグローバルルールを上書き
3. **新しいルール** が古いルールを上書き（文書化されている場合）
4. ユーザーに **エスカレート** して解決

## 品質基準

### 必須要素チェックリスト

- [ ] 明確で曖昧さのない制約記述
- [ ] ルールが存在する理由の説明
- [ ] 正しいパターンと不正なパターンの例
- [ ] 強制メカニズムの指定
- [ ] 例外の文書化（存在する場合）

### ベストプラクティス

- [ ] ルールが測定可能/検証可能
- [ ] プロジェクト哲学と一致
- [ ] 既存ルールと競合しない
- [ ] 例が実際のプロジェクトパターンを使用
- [ ] 定期的なレビューサイクルを確立

### アンチパターン（避けるべきこと）

- ❌ 曖昧または不明確な制約
- ❌ 根拠のないルール
- ❌ 進捗をブロックする過度に制限的なルール
- ❌ 決して強制されないルール
- ❌ 解決策のない競合ルール
- ❌ 不必要にガイドラインを重複するルール

## テンプレートとリソース

### スターターテンプレート

以下のテンプレートが利用可能:

- `resources/templates/settings-rule-template.md` - Settings rules用
- `resources/templates/steering-template.md` - Steeringドキュメント用
- `resources/templates/hookify-template.md` - Hookify rules用

### 実例

以下の実例を参照してください:

- `resources/examples/type-safety-rule.md` - 型安全性ルール例
- `resources/examples/architecture-steering.md` - アーキテクチャSteering例
- `resources/examples/pre-commit-hookify.md` - Pre-commit hook例

### 品質チェックリスト

`resources/checklist.md` に包括的なチェックリストがあります。

## ルールのテスト

### Settings Rules

1. 意図的な違反を作成
2. 検出メカニズムが動作するか確認
3. フィードバックが明確か確認
4. 例外ケースをテスト

### Steering Documents

1. AIにsteeringコンテキストを参照させる
2. AIがパターンを正しく適用するか確認
3. 誤解釈がないかチェック
4. AIのフィードバックに基づいて更新

### Hookify Rules

1. イベントを手動でトリガー
2. アクションが実行されるか確認
3. 失敗シナリオをテスト
4. ロギングが動作するか確認

## ルールの進化

### ルールを更新すべき時

- プロジェクト要件が変更
- 新しいパターンが出現
- ルールが厳しすぎるまたは緩すぎると判明
- 技術スタックが進化
- チームフィードバックが問題を示す

### 廃止プロセス

1. ルールを廃止としてマーク（日付付き）
2. 代替ルールを文書化（存在する場合）
3. サンセット日を設定
4. 移行期間後に削除

### バージョン管理

- gitでルールを追跡
- コミットメッセージで変更を文書化
- 大きなルール変更のChangelogを検討
- ルールを四半期ごとにレビュー

## 高度なパターン

### 条件付きルール

```markdown
## 制約

モジュールが `domain/` 層にある場合、`infrastructure/` からインポートしてはならない

## 条件チェック

パターンに一致するファイルにのみ適用: `src/domain/**/*.ts`
```

### 段階的なルール

```markdown
## 強制タイムライン

- Phase 1 (現在): 警告のみ
- Phase 2 (2025-Q2): CI/CDでエラー
- Phase 3 (2025-Q3): ブロッキング
```

### コンテキスト認識ルール

```markdown
## 制約

APIルートはレート制限を実装しなければならない

## コンテキスト

適用対象: `src/app/api/**/route.ts`
例外: `// @internal` でマークされた内部専用ルート
```

## ルールガバナンス

### 所有権

- **チームルール**: チーム承認が必要
- **プロジェクトルール**: プロジェクトリードが決定
- **個人ルール**: 個人開発者（ローカルのみ）

### レビュープロセス

1. 根拠を添えてルールを提案
2. チームディスカッション
3. トライアル期間（警告のみ）
4. トライアル後に完全強制
5. 定期的なレビュー（四半期ごと）

## 次のステップ

ルール作成後:

1. 適切な場所に配置（.kiro/settings/rules/、.kiro/steering/、.claude/）
2. チームに伝達
3. 強制メカニズムをセットアップ
4. 違反を監視
5. フィードバックを収集し反復
6. プロジェクトのルールインデックスに文書化

## 関連リソース

- **doc-standards skill**: ドキュメント標準ルールの作成時に参照（メタデータ、タグシステム、サイズガイドライン、品質チェック）
- **command-creator skill**: ルールを強制するコマンドの作成方法
- **agent-creator skill**: ルールを検証するエージェントの作成方法
- **skill-creator skill**: より広いドメインルールの場合
- `/Users/t00114/.claude/.kiro/settings/rules/`: 既存ルール例
- `/Users/t00114/.claude/CLAUDE.md`: グローバルガイドライン

---

このskillを使用して、一貫性があり、よく統合された高品質なルールを作成してください。
