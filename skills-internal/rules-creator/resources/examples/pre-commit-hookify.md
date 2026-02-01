# Pre-Commit Hookify Example

このファイルはPre-commit品質ゲートのHookifyルール例です。

## パターン特徴

- Bashイベントのトリガー
- git commitパターンマッチング
- ブロックアクション
- 品質チェックの自動実行

## 主要な構造要素

1. YAMLフロントマター:
   - event: bash
   - pattern: "^git commit"
   - action: block
   - message: エラーメッセージ

2. アクション:
   - Linter実行
   - 型チェック
   - テスト実行

3. 失敗時:
   - コミットブロック
   - エラー表示
   - 修正提案

類似のHookifyルールを参考にして作成してください。
