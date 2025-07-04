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
brew bundle --file="$SCRIPT_DIR/Brewfile"

echo "End brew.sh"
echo "----------------------------------------"
