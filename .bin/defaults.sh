#!/bin/zsh

echo "Start defaults.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

#====================================================================================================
#
# General
#
#====================================================================================================

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

#====================================================================================================
#
# Dock
#
#====================================================================================================

# Disable animation at application launch
defaults write com.apple.dock launchanim -bool false

# Disable show recent applications
defaults write com.apple.dock show-recents -bool false

# Delete all icons in the Dock
defaults write com.apple.dock persistent-apps -array

#====================================================================================================
#
# Screen Shot
#
#====================================================================================================

# Save screenshots to the pictures directory
defaults write com.apple.screencapture location -string "${HOME}/Pictures"

#====================================================================================================
#
# Finder
#
#====================================================================================================

# Disable animation
defaults write com.apple.finder DisableAllAnimations -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show file with all extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable the status bar
defaults write com.apple.finder ShowStatusBar -bool false

# Disable the path bar
defaults write com.apple.finder ShowPathbar -bool false

#====================================================================================================
#
# Desktop
#
#====================================================================================================

# Hide all icons on the desktop
defaults write com.apple.finder CreateDesktop -bool false

#====================================================================================================
#
# Menu bar
#
#====================================================================================================

# Set menu bar clock format
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm:ss"

for app in "Dock" \
  "Finder" \
  "SystemUIServer"; do
  killall "${app}" &>/dev/null 2>&1
done
