# タスク分解ガイド

## 目的

複雑なタスクを適切に分解し、`TaskCreate`/`TaskList`/`TaskUpdate`を活用して進捗を可視化します。

## 複雑度評価

### Simple（タスク分解不要）

以下のすべてを満たす場合:

- 単一ファイルの変更
- 変更内容が明確（明確な修正、バグフィックス）
- 3ステップ以下で完了

**例**:

- タイポ修正
- 単一関数の修正
- 設定ファイルの更新

**対応**: TaskCreateを使用せず、直接実装

### Complex（タスク分解必要）

以下のいずれかを満たす場合:

- 複数ファイルの変更
- アーキテクチャ変更を伴う
- 3ステップを超える作業
- 複数のコンポーネント/モジュールに影響

**例**:

- 新機能追加
- リファクタリング
- 複数箇所のバグ修正
- API変更

**対応**: TaskCreateでサブタスクを登録

## TaskCreateパターン

### 機能追加パターン

**例**: ユーザー認証機能を追加

```markdown
TaskCreate #1: "データモデル定義"
description: User, Session モデルを定義し、データベーススキーマを作成
activeForm: "データモデルを定義中"

TaskCreate #2: "認証API実装"
description: POST /auth/login, POST /auth/logout エンドポイントを実装
activeForm: "認証APIを実装中"
blockedBy: [#1]

TaskCreate #3: "ミドルウェア実装"
description: JWT検証ミドルウェアを実装し、保護ルートに適用
activeForm: "ミドルウェアを実装中"
blockedBy: [#2]

TaskCreate #4: "テスト追加"
description: 認証フロー全体の統合テストを追加
activeForm: "テストを追加中"
blockedBy: [#3]
```

**依存関係の推論**:

- データモデル → API → ミドルウェア → テスト（線形依存）

### リファクタリングパターン

**例**: コンポーネントのディレクトリ構造を再編成

```markdown
TaskCreate #1: "新ディレクトリ構造設計"
description: コンポーネント分類を定義し、移動計画を立案
activeForm: "ディレクトリ構造を設計中"

TaskCreate #2: "Atomic コンポーネント移動"
description: Button, Input 等の基本コンポーネントを移動
activeForm: "Atomicコンポーネントを移動中"
blockedBy: [#1]

TaskCreate #3: "Composite コンポーネント移動"
description: Form, Modal 等の複合コンポーネントを移動
activeForm: "Compositeコンポーネントを移動中"
blockedBy: [#2]

TaskCreate #4: "インポートパス修正"
description: すべてのインポート文を新しいパスに更新
activeForm: "インポートパスを修正中"
blockedBy: [#3]

TaskCreate #5: "テスト実行と検証"
description: 全テストを実行し、インポートエラーがないか確認
activeForm: "テストを実行中"
blockedBy: [#4]
```

**依存関係の推論**:

- 設計 → Atomic移動 → Composite移動 → インポート修正 → テスト（線形依存）

### バグ修正パターン

**例**: データ競合によるバグを修正

```markdown
TaskCreate #1: "原因調査"
description: データ競合の発生箇所と原因を特定
activeForm: "原因を調査中"

TaskCreate #2: "状態管理修正"
description: 競合を防ぐために状態管理ロジックを修正
activeForm: "状態管理を修正中"
blockedBy: [#1]

TaskCreate #3: "エッジケース対応"
description: 特定されたエッジケースに対する防御コードを追加
activeForm: "エッジケースに対応中"
blockedBy: [#2]

TaskCreate #4: "回帰テスト追加"
description: バグの再発を防ぐテストケースを追加
activeForm: "回帰テストを追加中"
blockedBy: [#3]
```

**依存関係の推論**:

- 調査 → 修正 → エッジケース対応 → テスト（線形依存）

## 依存関係の推論ルール

### 線形依存（blockedBy: [前のタスク]）

以下の場合、線形依存を設定:

- 順序が明確（データモデル → API → UI）
- 前のタスクの出力が次のタスクの入力

### 並列実行（blockedByなし）

以下の場合、並列実行可能:

- 独立したモジュール/ファイル
- 相互依存がない
- 同時に作業可能

**例**:

```markdown
TaskCreate #1: "ユーザーAPI実装"
TaskCreate #2: "商品API実装"

# #1と#2は並列実行可能（独立したリソース）
```

### 複数依存（blockedBy: [#1, #2]）

以下の場合、複数依存を設定:

- 複数のタスクの完了が必要
- 統合タスク

**例**:

```markdown
TaskCreate #1: "ユーザーAPI実装"
TaskCreate #2: "商品API実装"
TaskCreate #3: "統合テスト"
blockedBy: [#1, #2]
```

## TaskUpdate使用タイミング

### 作業開始時

```
TaskUpdate taskId: "1" status: "in_progress"
```

- `TaskList`で次のタスクを取得後、すぐに実行
- `blockedBy`が空のタスクのみ選択

### 作業完了時

```
TaskUpdate taskId: "1" status: "completed"
```

- タスクが完全に完了した場合のみ
- テストが失敗している場合は`completed`にしない

### タスク削除時

```
TaskUpdate taskId: "1" status: "deleted"
```

- タスクが不要になった場合
- 要件変更でタスクが無効になった場合

## 実装フロー

```
Step 2: タスク分解と計画立案
  ├─ 複雑度評価（Simple/Complex）
  ├─ Complexの場合:
  │   ├─ TaskCreateでサブタスク登録
  │   ├─ 依存関係推論（blockedBy設定）
  │   └─ 計画承認（大規模変更の場合）
  └─ Simpleの場合: 直接Step 3へ

Step 5: サブタスク実装ループ
  ├─ TaskListで次のタスク取得
  │   └─ 条件: blockedBy が空、ID順
  ├─ TaskUpdate status: "in_progress"
  ├─ タスク実装
  ├─ TaskUpdate status: "completed"
  └─ すべてのタスクが完了するまで繰り返し
```

## 注意事項

- タスク分解は過度に細かくしない（5-7タスク程度が目安）
- 各タスクは独立して理解できる粒度にする
- `activeForm`は現在進行形で、ユーザーに表示されることを意識
- 依存関係は明示的に設定（推測に頼らない）
- TaskUpdateは作業開始時と完了時に必ず実行
