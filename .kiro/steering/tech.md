# Tech Steering

## 主要スタック
- Nix Flake + Home Manager でスキルの構成・配布・検証を行う
- Node.js + mise によりドキュメント系ツールチェーンを統一する
- Markdown を一次情報として運用する

## 自動化/CI
- GitHub Actions で lint/format と Nix 検証を実行する
- ローカルと CI の共通基盤として `mise` タスクを使う

## 運用上の決定事項
- README は入口、詳細は各 `SKILL.md` を正とする
- 自作スキルを外部スキルより優先して扱う
- 変更時は README と `SKILL.md` の整合性を維持する
