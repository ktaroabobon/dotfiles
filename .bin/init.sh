#!/bin/zsh

echo "Start init.sh"

# Check if macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Install xcode command line tools
  echo "Install xcode command line tools"
  xcode-select --install >/dev/null 2>&1

  # Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

  # Add Homebrew path
  export PATH=/opt/homebrew/bin:$PATH
fi
# Check if Ubuntu
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Update and upgrade
  echo "Update and upgrade"
  sudo apt update
  sudo apt upgrade
  sudo apt autoremove --purge

  # Install essential packages
  echo "Install essential packages"
  sudo apt-get install -y build-essential
  # Add additional commands for Ubuntu here

  # Install zsh, git, curl
  echo "Install zsh, git, curl"
  sudo apt -y install zsh powerline fonts-powerline
  sudo apt -y install git
  sudo apt -y install curl

  # Default shell to zsh
  echo "Default shell to zsh"
  chsh -s $(which zsh)

  # Set up git
  echo "Set up git"
  git config --global user.email "ktaroabobon@gmail.com"
  git config --global user.name "ktaroabobon"

  # Install oh-my-zsh
  echo "Install oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Change oh-my-zsh theme to Agnoster
  echo "Change oh-my-zsh theme to Agnoster"
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc

  # Restart the terminal
  echo "Restarting terminal..."
  exec zsh
fi

echo "End init.sh"
echo "----------------------------------------"
