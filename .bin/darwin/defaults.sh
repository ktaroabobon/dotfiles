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

echo "Disable auto-capitalization"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

#====================================================================================================
#
# Dock
#
#====================================================================================================

echo "Disable animation at application launch"
defaults write com.apple.dock launchanim -bool false

echo "Disable show recent applications"
defaults write com.apple.dock show-recents -bool false

echo "Delete all icons in the Dock"
defaults write com.apple.dock persistent-apps -array

#====================================================================================================
#
# TrackPad, Mouse, Keyboard
#
#====================================================================================================

echo "TrackPad speed up to 3"
defaults write -g com.apple.trackpad.scaling 3

echo "Mouse scaling speed up to 2.5"
defaults write -g com.apple.mouse.scaling 2.5


#====================================================================================================
#
# Symbolic hot key
#
#====================================================================================================

echo "Disable Spotlight search hotkey (cmd+space)"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'

#====================================================================================================
#
# Screen Shot
#
#====================================================================================================

echo "Save screenshots to the pictures directory"
defaults write com.apple.screencapture location -string "${HOME}/Pictures"

#====================================================================================================
#
# Finder
#
#====================================================================================================

echo "Disable animation"
defaults write com.apple.finder DisableAllAnimations -bool true

echo "Show hidden files"
defaults write com.apple.finder AppleShowAllFiles -bool true

echo "Show file with all extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Disable the status bar"
defaults write com.apple.finder ShowStatusBar -bool false

echo "Disable the path bar"
defaults write com.apple.finder ShowPathbar -bool false

#====================================================================================================
#
# Desktop
#
#====================================================================================================

echo "Hide all icons on the desktop"
defaults write com.apple.finder CreateDesktop -bool false

#====================================================================================================
#
# Menu bar
#
#====================================================================================================

echo "Set menu bar clock format with seconds"
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm:ss"

echo "Show battery percentage in menu bar"
defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -bool true

for app in "Dock" \
  "Finder" \
  "SystemUIServer" \
  "ControlCenter"; do
  killall "${app}" &>/dev/null 2>&1
done

echo "End defaults.sh"
echo "----------------------------------------"
