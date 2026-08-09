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

# Homebrew 6.0 以降、非公式 tap の formula / cask は明示的に信頼しないと読み込めない。
# 信頼していないものに当たると `brew bundle` はそこで中断するため、
# Brewfile の残りが丸ごとインストールされない。
#
# Brewfile に書いてある = 利用者が意図して入れているものなので、tap 全体ではなく
# Brewfile に列挙されたエントリだけを信頼する（tap 全体の信頼は、その tap の
# 将来の formula すべてに及ぶため避ける）。
if brew trust --help > /dev/null 2>&1; then
  echo "Trusting third-party tap entries listed in the Brewfile"

  # trust するには先に tap されている必要がある
  for t in $(sed -n 's/^tap "\([^"]*\)".*/\1/p' "$BREWFILE"); do
    brew tap "$t" || echo "Warning: failed to tap $t"
  done

  for f in $(sed -n 's|^brew "\([^"]*/[^"]*/[^"]*\)".*|\1|p' "$BREWFILE"); do
    brew trust --formula "$f" || echo "Warning: failed to trust formula $f"
  done

  for c in $(sed -n 's|^cask "\([^"]*/[^"]*/[^"]*\)".*|\1|p' "$BREWFILE"); do
    brew trust --cask "$c" || echo "Warning: failed to trust cask $c"
  done
fi

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
