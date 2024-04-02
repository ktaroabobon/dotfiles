#!/bin/zsh

echo "Start init.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

# Install xcode command line tools
eho "Install xcode command line tools"
xcode-select --install >/dev/null 2>&1

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Add path
export PATH=opt/homebrew/bin;$PATH

echo "End init.sh"
echo "----------------------------------------"
