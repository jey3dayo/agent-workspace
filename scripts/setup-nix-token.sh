#!/usr/bin/env bash
set -euo pipefail

CONF=~/.agents/secrets/nix/access-tokens.conf
NIX_CONF=~/.config/nix/nix.conf
INCLUDE_LINE="!include $HOME/.agents/secrets/nix/access-tokens.conf"

# gh 認証チェック
if ! gh auth status &>/dev/null; then
  echo "ERROR: gh auth login を先に実行してください"
  exit 1
fi

# トークン書き込み
mkdir -p ~/.agents/secrets/nix
chmod 700 ~/.agents/secrets ~/.agents/secrets/nix
echo "access-tokens = github.com=$(gh auth token)" > "$CONF"
chmod 600 "$CONF"
echo "OK: $CONF"

# nix.conf に !include 追加（未設定の場合のみ）
mkdir -p ~/.config/nix
touch "$NIX_CONF"
if ! grep -qF 'access-tokens.conf' "$NIX_CONF"; then
  echo "$INCLUDE_LINE" >> "$NIX_CONF"
  echo "OK: $NIX_CONF に !include を追加"
else
  echo "SKIP: $NIX_CONF に !include は設定済み"
fi

# 検証
echo "---"
nix config show 2>/dev/null | grep access-tokens && echo "OK: Nix がトークンを認識" || echo "WARN: トークンが認識されていません"
