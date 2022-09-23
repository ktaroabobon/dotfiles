#!/bin/zsh

echo "Start link.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

SCRIPT_DIR=$(
  cd $(dirname $0)
  pwd
)

for dotfile in "${SCRIPT_DIR}"/.??* ; do
  [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue

  ln -fnsv "$dotfile" "$HOME"
done