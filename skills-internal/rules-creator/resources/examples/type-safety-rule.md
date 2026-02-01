---
paths: {src,lib}/**/*.ts, {src,lib}/**/*.tsx
---

# 型安全性: any型禁止

## 適用範囲（Paths）

このルールは以下のファイルパターンに適用されます：

```yaml
paths: {src,lib}/**/*.ts, {src,lib}/**/*.tsx
```

TypeScriptソースコードとReactコンポーネントファイルが対象です。

**Pathsパターン構文：**

- `{src,lib}/**/*.ts` - src と lib ディレクトリ配下の全 TypeScript ファイル
- `{src,lib}/**/*.tsx` - src と lib ディレクトリ配下の全 React TypeScript ファイル

## 制約

TypeScriptコードで **`any` 型の使用を禁止** します。

すべての変数、関数引数、戻り値には明示的な型定義が必要です。

## 根拠

**技術的正当性:**

- 型安全性を維持し、コンパイル時に型エラーを検出
- 実行時エラーを防ぎ、コードの信頼性を向上
- IntelliSenseの精度向上により開発効率が向上
- リファクタリングの安全性を確保

## 例

### ✅ 正しい

明示的な型定義を使用：

```typescript
// 明示的な型定義
interface User {
  id: string
  name: string
  email: string
}

function processUser(user: User): Result<ProcessedUser, Error> {
  // 型安全な処理
  return ok(transformUser(user))
}

// ジェネリクスで型安全性を保持
function fetchData<T>(url: string): Promise<Result<T, Error>> {
  // 明示的な型パラメータ
}
```

### ❌ 不正

any 型の使用：

```typescript
// any型の使用（禁止）
function processData(data: any): any {
  return data.something // 型チェックなし
}

// 暗黙的なany（禁止）
function handleEvent(event) {
  // eventの型が不明
}

// 型アサーションの乱用（禁止）
const data = response as any
```

## 例外

以下の場合のみ、明示的に `unknown` 型を使用し、型ガードで安全に処理：

```typescript
// unknown型を使用し、型ガードで安全化
function parseJSON(json: string): Result<unknown, Error> {
  try {
    const data: unknown = JSON.parse(json)
    // 型ガードで検証
    if (isValidData(data)) {
      return ok(data)
    }
    return err(new Error('Invalid data'))
  } catch (e) {
    return err(e as Error)
  }
}

function isValidData(data: unknown): data is DataType {
  // 型ガードで検証
  return typeof data === 'object' && data !== null && 'id' in data && 'name' in data
}
```

## 強制

このルールは以下の方法で強制されます：

- [x] ESLint ルール: `@typescript-eslint/no-explicit-any`
- [x] TypeScript Compiler: `strict: true`, `noImplicitAny: true`
- [x] CI/CDチェック: 型チェックが失敗すればビルドブロック
- [x] Pre-commitフック: コミット前に型チェック実行

**ESLint設定例:**

```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-member-access": "error",
    "@typescript-eslint/no-unsafe-call": "error"
  }
}
```

**tsconfig.json設定例:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true
  }
}
```

## 関連ルール

- `error-handling.md`: Result<T,E>パターンの使用
- `type-assertions.md`: 型アサーションの制限

## レビュースケジュール

最終レビュー: 2025-01-15
次回レビュー: 2025-07-15

---

**この例について:**

このファイルは、Settings Rules における paths フィールドの実用例です：

- YAML frontmatter で TypeScript/TSX ファイルに限定
- ブレース展開 `{src,lib}` で複数ディレクトリを指定
- 明確な制約定義と技術的正当性
- 正しい/不正な例の提示
- ESLint/TypeScriptでの強制メカニズム

参照元: `.kiro/settings/rules/design-principles.md` のパターンをベースに、paths フィールドを追加して具体化しました。
