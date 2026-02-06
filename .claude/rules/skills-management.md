# スキル管理ルール

`~/.agents/` を中心としたスキル統一管理システムの AI 向け運用原則。
ディレクトリ構成・運用コマンド・スキル追加手順は [README.md](../../../README.md) を参照。

## スキル配置の原則

### 外部スキル → `flake.nix` の inputs

- flake inputs で GitHub リポジトリをピン留め
- `nix/sources.nix` でパスマッピング

### 自前スキル → `~/.agents/skills-internal/`

- 自作スキル、実験的スキル、カスタマイズスキル
- Single Source of Truth: ここで管理し、Nix バンドルで各ツールに配布
- ローカルスキルは外部スキルより優先（同名 ID の場合）

## 対象ツール一覧

スキルディレクトリ以外のパス情報（AI がファイル操作する際の参考）:

| ツール   | 設定                        | ルール             | エージェント        |
| -------- | --------------------------- | ------------------ | ------------------- |
| Claude   | `~/.claude/settings.json`   | `~/.claude/rules/` | `~/.claude/agents/` |
| Codex    | `~/.codex/settings.json`    | —                  | —                   |
| Cursor   | —                           | —                  | —                   |
| OpenCode | `~/.opencode/settings.json` | —                  | —                   |
| OpenClaw | —                           | —                  | —                   |

`nix/targets.nix` で宣言的にスキル同期先を定義（Single Source of Truth）:

```nix
{
  claude   = { enable = true; dest = ".claude/skills"; };
  newtool  = { enable = true; dest = ".newtool/skills"; };
}
```

`home.nix` と `flake.nix` の両方がこのファイルを import する。

## ターゲット追加時

`nix/targets.nix` のみ編集すればよい。`enable = false` でツール単位の無効化も可能。

## スキル実行時のパス解決

HM による rsync 同期後、各ツールのスキルディレクトリにはスキルの実体コピーが配置される。

- スキルが `scripts/foo.py` を参照 → `~/.claude/skills/<skill-name>/scripts/foo.py`
- 全ツールに同一内容が配布されるため、どのツールからでも同じパスパターンで参照可能

## 注意事項

- スキル追加・変更後は `home-manager switch --flake ~/.agents --impure` を実行
- 同名スキルは `skills-internal` が優先（ローカル後勝ち）
- 外部ソース間の重複 ID はエラー
- `nix flake update` でソース更新後は再インストールが必要
- 直接編集せず、`~/.agents/skills-internal/` で管理すること
