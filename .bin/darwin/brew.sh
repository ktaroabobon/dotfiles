#!/bin/zsh

echo "Start brew.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

# Permission settings
sudo chown -R "$(whoami)":admin /usr/local/*
sudo chown -R g+w /usr/local/*

# Run .Brewfile
brew bundle --global

echo "End brew.sh"
echo "----------------------------------------"
