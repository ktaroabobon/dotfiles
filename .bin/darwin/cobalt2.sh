#!/bin/zsh

echo "Start cobalt2.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

# Get script directory
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

#====================================================================================================
#
# Environment Check
#
#====================================================================================================

echo "Checking environment..."

# Check if oh-my-zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Error: oh-my-zsh is not installed. Please run init.sh first."
  exit 1
fi

# Check if iTerm2 is installed
if [ ! -d "/Applications/iTerm.app" ]; then
  echo "Warning: iTerm2 is not found. Some features may not work properly."
fi

#====================================================================================================
#
# Install Cobalt2 Theme
#
#====================================================================================================

echo "Installing Cobalt2 theme..."

# Download cobalt2.zsh-theme
THEME_URL="https://raw.githubusercontent.com/wesbos/Cobalt2-iterm/master/cobalt2.zsh-theme"
THEME_DIR="$HOME/.oh-my-zsh/themes"

if [ ! -f "$THEME_DIR/cobalt2.zsh-theme" ]; then
  echo "Downloading cobalt2.zsh-theme..."
  curl -fsSL "$THEME_URL" -o "$THEME_DIR/cobalt2.zsh-theme"
  if [ $? -eq 0 ]; then
    echo "Successfully downloaded cobalt2.zsh-theme"
  else
    echo "Error: Failed to download cobalt2.zsh-theme"
    exit 1
  fi
else
  echo "cobalt2.zsh-theme already exists"
fi

#====================================================================================================
#
# Apply Configuration
#
#====================================================================================================

echo "Applying configuration..."

# Check if .zshrc already has cobalt2 theme
if grep -q 'ZSH_THEME="cobalt2"' "$HOME/.zshrc"; then
  echo "ZSH_THEME is already set to cobalt2"
else
  echo "Setting ZSH_THEME to cobalt2..."
  # Backup current .zshrc
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  
  # Replace theme setting
  sed -i.bak 's/ZSH_THEME=".*"/ZSH_THEME="cobalt2"/' "$HOME/.zshrc"
  echo "Updated ZSH_THEME to cobalt2"
fi

# Add local bin to PATH if not already present
if ! grep -q '$HOME/.local/bin' "$HOME/.zshrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  echo "Added ~/.local/bin to PATH"
fi

#====================================================================================================
#
# Install Powerline
#
#====================================================================================================

echo "Installing Powerline..."

# Check if pip is installed
if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
  echo "Error: pip is not installed. Please install pip first."
  exit 1
fi

# Install powerline-status
PIP_CMD="pip"
if command -v pip3 &> /dev/null; then
  PIP_CMD="pip3"
fi

echo "Installing powerline-status..."
$PIP_CMD install --user powerline-status

if [ $? -eq 0 ]; then
  echo "Successfully installed powerline-status"
else
  echo "Warning: Failed to install powerline-status"
fi

#====================================================================================================
#
# Install Powerline Fonts
#
#====================================================================================================

echo "Installing Powerline fonts..."

# Create temporary directory for fonts
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone powerline fonts repository
echo "Cloning powerline fonts repository..."
git clone https://github.com/powerline/fonts.git

if [ $? -eq 0 ]; then
  echo "Successfully cloned powerline fonts repository"
  cd fonts
  echo "Installing fonts..."
  ./install.sh
  
  if [ $? -eq 0 ]; then
    echo "Successfully installed powerline fonts"
  else
    echo "Warning: Failed to install powerline fonts"
  fi
else
  echo "Warning: Failed to clone powerline fonts repository"
fi

# Clean up temporary directory
cd "$HOME"
rm -rf "$TEMP_DIR"

#====================================================================================================
#
# iTerm2 Configuration
#
#====================================================================================================

echo "Setting up iTerm2 configuration..."

# Download cobalt2.itermcolors
ITERMCOLORS_URL="https://raw.githubusercontent.com/wesbos/Cobalt2-iterm/master/cobalt2.itermcolors"
ITERMCOLORS_PATH="$HOME/Downloads/cobalt2.itermcolors"

if [ ! -f "$ITERMCOLORS_PATH" ]; then
  echo "Downloading cobalt2.itermcolors..."
  curl -fsSL "$ITERMCOLORS_URL" -o "$ITERMCOLORS_PATH"
  if [ $? -eq 0 ]; then
    echo "Successfully downloaded cobalt2.itermcolors to Downloads folder"
  else
    echo "Warning: Failed to download cobalt2.itermcolors"
  fi
else
  echo "cobalt2.itermcolors already exists in Downloads folder"
fi

echo "Reloading zsh configuration..."
source "$HOME/.zshrc" 2>/dev/null || true

echo "End cobalt2.sh"
echo "----------------------------------------"
echo ""
echo "Cobalt2 theme installation completed!"
echo ""
echo "Manual steps remaining:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Open iTerm2 and import the color scheme:"
echo "   - Go to Preferences (Cmd+,) → Profiles → Colors"
echo "   - Load cobalt2.itermcolors from Downloads folder"
echo "3. Import the profile configuration:"
echo "   - Go to Profiles → Other Actions → Import JSON Profiles"
echo "   - Import ktaroabobon-default.json from your dotfiles"
echo "4. Set font to 'Inconsolata for Powerline' in iTerm2 preferences"
echo ""
echo "Files downloaded to ~/Downloads/:"
echo "- cobalt2.itermcolors"
echo "" 
