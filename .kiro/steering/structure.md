# Structure Steering

## ルート構成の考え方
- `skills-internal/` に自作スキルを集約し、`<skill-name>/SKILL.md` を正とする
- `skills/` は外部スキルの配置先として扱う（同期や生成で更新される領域）
- `nix/` と `flake.nix` でバンドル生成・選択・検証のロジックを管理する
- `home.nix` は Home Manager 統合の入口で、`nix/selection.nix` / `nix/targets.nix` を参照する
- `scripts/` は短い運用補助スクリプトに限定する
- `.github/workflows/` で CI の lint/validate を定義する
- `README.md` はスキル一覧の入口として維持する
- `.kiro/steering/` はプロジェクト判断のメモリとして扱い、更新は追記を基本にする

## 命名/配置パターン
- スキルはディレクトリ名がスキル ID に一致する
- 主要な開発/運用設定は `mise.toml` に集約する
