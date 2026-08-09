#!/bin/bash
# Ubuntu / WSL2 向けのリンク。darwin 側の link.sh と違い、シェルの rc は
# 管理対象にしていない（既存環境を壊さないため）。共有スクリプトを ~/.zsh へ
# 置き、rc からの source 行だけを冪等に追記する。

set -eu

echo "Start ubuntu/link.sh"

if [ "$(uname)" != "Linux" ]; then
  echo "This script is only for Linux (incl. WSL2)"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SHARED_DIR="$(cd "$SCRIPT_DIR/../shared" && pwd)"

mkdir -p "$HOME/.zsh"
ln -fnsv "$SHARED_DIR/hictl.zsh" "$HOME/.zsh/hictl.zsh"

# rc への source 行を冪等に追記する（zsh / bash の実在するものすべてに入れる）
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  if grep -qF '.zsh/hictl.zsh' "$rc"; then
    echo "already sourced: $rc"
    continue
  fi
  {
    echo ''
    echo '# home-infra control CLI (dotfiles: .bin/shared/hictl.zsh)'
    echo 'if [ -f ~/.zsh/hictl.zsh ]; then'
    echo '  source ~/.zsh/hictl.zsh'
    echo 'fi'
  } >> "$rc"
  echo "sourced into: $rc"
done

echo "End ubuntu/link.sh"
echo "----------------------------------------"
