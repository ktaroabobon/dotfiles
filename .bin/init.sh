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

  # Install vi using Homebrew
  echo "Install vi"
  brew install vim
fi

# Check if Ubuntu
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Update and upgrade
  echo "Update and upgrade"
  sudo apt update
  sudo apt upgrade -y
  sudo apt autoremove --purge -y

  # Install essential packages
  echo "Install essential packages"
  sudo apt-get install -y build-essential
  # Add additional commands for Ubuntu here

  # Install zsh, git, curl, make, make-guile, and vi
  echo "Install zsh, git, curl, make, make-guile, and vi"
  sudo apt -y install zsh powerline fonts-powerline
  sudo apt -y install git
  sudo apt -y install curl
  sudo apt -y install make
  sudo apt -y install make-guile
  sudo apt -y install vim
  sudo apt-get install -y language-pack-en
  sudo update-locale

  # Default shell to zsh
  echo "Default shell to zsh"
  sudo chsh -s $(which zsh)
  echo 'export SHELL=$(which zsh)' >> ${HOME}/.zshrc

  # Set up git
  echo "Set up git"
  git config --global user.email "ktaroabobon@gmail.com"
  git config --global user.name "ktaroabobon"

  # Install oh-my-zsh
  echo "Install oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Change oh-my-zsh theme to Agnoster
  echo "Change oh-my-zsh theme to Agnoster"
  zshrc_file="${HOME}/.zshrc"
  theme_line='ZSH_THEME="agnoster"'
  
  if grep -q "^ZSH_THEME=" "$zshrc_file"; then
    # Replace existing ZSH_THEME line
    awk -v theme_line="$theme_line" '{sub(/^ZSH_THEME=.*$/, theme_line)}1' "$zshrc_file" > "${zshrc_file}.tmp" && mv "${zshrc_file}.tmp" "$zshrc_file"
  else
    # Add new ZSH_THEME line
    echo "$theme_line" >> "$zshrc_file"
  fi


  # Restart the shell
  exec zsh
fi

echo "End init.sh"
echo "----------------------------------------"
