#!/bin/zsh

echo "Start brew.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

# Permission settings (ignore errors in CI environment)
sudo chown -R "$(whoami)":admin /usr/local/* 2>/dev/null || true
sudo chmod -R g+w /usr/local/* 2>/dev/null || true

# Get script directory and run Brewfile
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
BREWFILE="$SCRIPT_DIR/Brewfile"

if [ "${CI:-}" = "true" ]; then
  # CI 環境では cask / mas のインストールは時間が掛かる & 認証が必要なためスキップする。
  # formula のみを一時 Brewfile に抽出して bundle する。
  TMP_BREWFILE=$(mktemp)
  grep -Ev '^[[:space:]]*(cask|mas)[[:space:]]' "$BREWFILE" > "$TMP_BREWFILE"
  brew bundle --no-upgrade --file="$TMP_BREWFILE" || echo "Some packages failed to install (continuing)"
  rm -f "$TMP_BREWFILE"
else
  # 実機では cask / mas も含めて全部インストール。失敗は続行扱い。
  brew bundle --file="$BREWFILE" || echo "Some packages failed to install (continuing)"
fi

echo "End brew.sh"
echo "----------------------------------------"
