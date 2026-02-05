# CI修正パターン集

## 目的

CI失敗を自動修正するための戦略とパターンを提供します。`inspect_pr_checks.py`と組み合わせて使用します。

## inspect_pr_checks.py 使用方法

### 基本的な使い方

```bash
# 現在のブランチのPRチェックを検査
python scripts/inspect_pr_checks.py

# 特定のPR番号を指定
python scripts/inspect_pr_checks.py --pr 123

# JSON形式で出力
python scripts/inspect_pr_checks.py --json

# 最大行数とコンテキスト行数を指定
python scripts/inspect_pr_checks.py --max-lines 200 --context 50
```

### 出力形式

**テキスト出力**:

```
PR #123: 2 件の失敗したチェックを分析しました。
------------------------------------------------------------
チェック名: TypeScript Build
詳細: https://github.com/.../runs/...
Run ID: 12345
Job ID: 67890
ステータス: ok
ワークフロー: CI (failure)
ブランチ/SHA: feat/auth 1a2b3c4d5e6f
Run URL: https://github.com/.../runs/12345
失敗スニペット:
  src/auth.ts:45:12 - error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.
  45   validateToken(token);
                   ~~~~~
------------------------------------------------------------
```

**JSON出力** (`--json`):

```json
{
  "pr": "123",
  "results": [
    {
      "name": "TypeScript Build",
      "detailsUrl": "https://github.com/.../runs/...",
      "runId": "12345",
      "jobId": "67890",
      "status": "ok",
      "run": {
        "conclusion": "failure",
        "workflowName": "CI",
        "headBranch": "feat/auth",
        "headSha": "1a2b3c4d5e6f"
      },
      "logSnippet": "src/auth.ts:45:12 - error TS2345: ...",
      "logTail": "..."
    }
  ]
}
```

### エラー検出ワークフロー

```bash
# Step 1: CI失敗を検出
gh pr checks

# Step 2: エラー詳細を取得
python scripts/inspect_pr_checks.py --json > /tmp/ci-errors.json

# Step 3: エラーカテゴリを判定（logSnippetを解析）
# Step 4: 修正戦略を適用（以下のパターン参照）
# Step 5: 修正 → コミット → プッシュ
git add .
git commit -m "CI修正: {category}"
git push
```

## エラーカテゴリと修正戦略

### 1. 型エラー（TypeScript）

**検出キーワード**:

- `TS2345`, `TS2339`, `TS2322`, `TS7006`, `TS2571`
- `error TS`, `Type 'X' is not assignable`, `Property 'X' does not exist`

**修正戦略**:

#### A. 型不一致の修正

**パターン**: 引数や戻り値の型が一致しない

```typescript
// エラー例
validateToken(token); // error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'

// 修正1: 型アサーション（正しい型が保証されている場合）
validateToken(Number(token));

// 修正2: 関数シグネチャ修正（引数の型が間違っている場合）
function validateToken(token: string) { ... }

// 修正3: オプショナル型（nullableな場合）
function validateToken(token: string | null) { ... }
```

#### B. プロパティ不存在エラー

**パターン**: オブジェクトに存在しないプロパティにアクセス

```typescript
// エラー例
user.email; // error TS2339: Property 'email' does not exist on type 'User'

// 修正1: 型定義を拡張
interface User {
  email: string;
}

// 修正2: オプショナルアクセス
user.email ?? "default@example.com";

// 修正3: 型ガード
if ("email" in user) {
  user.email;
}
```

#### C. any型エラー

**パターン**: 暗黙的any型

```typescript
// エラー例
function processData(data) { ... } // error TS7006: Parameter 'data' implicitly has an 'any' type

// 修正: 適切な型を指定
function processData(data: string) { ... }
function processData(data: unknown) { ... } // 型が不明な場合
```

### 2. Lintエラー（ESLint）

**検出キーワード**:

- `error`, `warning`, `eslint`, `Expected`, `Unexpected`
- ファイルパスとルール名（例: `no-unused-vars`, `@typescript-eslint/no-explicit-any`）

**修正戦略**:

#### A. 未使用変数

**ルール**: `no-unused-vars`, `@typescript-eslint/no-unused-vars`

```typescript
// エラー例
const unused = 42; // error: 'unused' is assigned a value but never used

// 修正1: 削除
// （変数を削除）

// 修正2: _プレフィックス（避けられない場合のみ）
const _unused = 42; // エラーハンドリングなど制約がある場合
```

#### B. any型使用

**ルール**: `@typescript-eslint/no-explicit-any`

```typescript
// エラー例
function process(data: any) { ... } // error: Unexpected any. Specify a different type

// 修正1: 具体的な型
function process(data: UserData) { ... }

// 修正2: unknown型
function process(data: unknown) { ... }

// 修正3: ジェネリック型
function process<T>(data: T) { ... }
```

#### C. 型アサーション

**ルール**: `@typescript-eslint/no-unnecessary-type-assertion`

```typescript
// エラー例
const value = someValue as string; // error: This assertion is unnecessary

// 修正: 型アサーションを削除
const value = someValue;
```

### 3. テスト失敗

**検出キーワード**:

- `FAIL`, `FAILED`, `expected`, `received`, `AssertionError`
- `Test Suites:`, `Tests:`, `jest`, `vitest`, `mocha`

**修正戦略**:

#### A. アサーション失敗

**パターン**: 期待値と実際の値が一致しない

```typescript
// エラー例
expect(result).toBe(42);
// Expected: 42
// Received: "42"

// 修正1: 型変換
expect(Number(result)).toBe(42);

// 修正2: 期待値を修正（仕様が変わった場合）
expect(result).toBe("42");

// 修正3: 実装を修正
function calculate(): number {
  // 戻り値をnumberに
  return 42; // 文字列ではなく数値を返す
}
```

#### B. モック不足

**パターン**: 外部依存が適切にモックされていない

```typescript
// エラー例
// Error: Cannot read property 'get' of undefined (axios)

// 修正: モック追加
vi.mock("axios", () => ({
  default: {
    get: vi.fn().mockResolvedValue({ data: [] }),
  },
}));
```

#### C. 非同期処理の待機不足

**パターン**: awaitが不足している

```typescript
// エラー例
test("fetches data", () => {
  const result = fetchData(); // Promise未解決
  expect(result).toEqual(expected); // 失敗
});

// 修正
test("fetches data", async () => {
  const result = await fetchData();
  expect(result).toEqual(expected);
});
```

### 4. ビルドエラー

**検出キーワード**:

- `Error: Cannot find module`, `Module not found`, `ENOENT`
- `Build failed`, `Compilation error`

**修正戦略**:

#### A. モジュール不足

**パターン**: 依存関係がインストールされていない

```bash
# エラー例
Error: Cannot find module 'lodash'

# 修正: 依存関係をインストール
npm install lodash
# または
pnpm add lodash
```

#### B. インポートパス間違い

**パターン**: ファイルパスが間違っている

```typescript
// エラー例
import { helper } from "./utils/helper"; // Error: Cannot find module

// 修正: 正しいパスに修正
import { helper } from "../utils/helper";
// または
import { helper } from "@/utils/helper"; // エイリアスを使用
```

#### C. ビルド設定エラー

**パターン**: tsconfig.json や webpack設定の問題

```json
// エラー例: "Cannot find name 'process'"

// 修正: tsconfig.jsonに型定義を追加
{
  "compilerOptions": {
    "types": ["node"]
  }
}
```

## 自動修正の優先順位

### 1. 確実に修正可能（自動実行）

- 未使用変数の削除
- 不要な型アサーションの削除
- インポート文のソート
- フォーマット違反

### 2. 推論が必要（慎重に実行）

- 型不一致の修正（型アサーション vs シグネチャ変更）
- プロパティ不存在（型定義追加 vs オプショナルアクセス）
- テストの期待値修正

### 3. 手動介入が必要

- ロジックエラー
- アーキテクチャ変更が必要な問題
- 外部API変更による破壊的変更

## 修正実装パターン

### パターン1: 単一ファイルの型エラー

```bash
# 1. エラー検出
python scripts/inspect_pr_checks.py --json > /tmp/ci-errors.json

# 2. エラー解析
# logSnippet から:
#   - ファイルパス: src/auth.ts
#   - 行番号: 45
#   - エラー内容: TS2345

# 3. ファイル読み込み
Read src/auth.ts

# 4. 修正実装
Edit src/auth.ts (該当箇所を修正)

# 5. コミット・プッシュ
git add src/auth.ts
git commit -m "CI修正: 型エラー - validateToken引数型の修正"
git push
```

### パターン2: 複数ファイルのLintエラー

```bash
# 1. Lint実行（ローカル）
npm run lint

# 2. 自動修正可能なものを修正
npm run lint -- --fix

# 3. 残りの手動修正
# （no-unused-varsなど）

# 4. コミット・プッシュ
git add .
git commit -m "CI修正: Lint - 未使用変数の削除"
git push
```

### パターン3: テスト失敗

```bash
# 1. テスト実行（ローカル）
npm run test

# 2. 失敗したテストを特定
# logSnippet から:
#   - テストファイル: tests/auth.test.ts
#   - テスト名: "should validate token"

# 3. テストコードまたは実装を修正
Read tests/auth.test.ts
Read src/auth.ts
Edit tests/auth.test.ts

# 4. 再実行して確認
npm run test

# 5. コミット・プッシュ
git add tests/auth.test.ts src/auth.ts
git commit -m "CI修正: テスト - validateTokenのアサーション修正"
git push
```

## 修正ループの中断条件

### 自動修正を継続

- 1回目の修正: 無条件で継続
- 2回目の修正: 前回と異なるエラーカテゴリなら継続
- 3回目の修正: 前回と異なるエラーカテゴリなら継続

### ユーザーに報告（中断）

以下の場合、3回以内でも中断してユーザーに報告:

- 同じエラーが3回連続で発生
- エラーカテゴリが判定できない（未知のエラー）
- ログが取得できない（status: "log_unavailable"）
- 外部チェック（status: "external"）

### 試行回数超過時の報告フォーマット

```
CI修正を3回試行しましたが、失敗が継続しています。

試行した修正:
1. CI修正: 型エラー - validateToken引数型の修正
2. CI修正: Lint - 未使用変数の削除
3. CI修正: 型エラー - User型定義の拡張

残存するエラー:
- チェック名: TypeScript Build
- エラーカテゴリ: 型エラー
- ファイル: src/auth.ts:67
- 内容: error TS2339: Property 'role' does not exist on type 'User'

推奨される次のステップ:
1. User型にroleプロパティを追加
2. または、roleアクセスをオプショナルチェーンに変更
3. 手動でコミット・プッシュして再確認
```

## 注意事項

- 修正は確認なしで自動実行されるため、慎重に判断する
- 各修正後、必ずプッシュしてCIを再トリガーする
- 同じエラーが繰り返される場合は早期に中断する
- ログが不完全な場合（status: "log_pending"）は、数秒待ってから再試行
- 外部チェック（GitHub Apps等）は自動修正できないため、スキップする
