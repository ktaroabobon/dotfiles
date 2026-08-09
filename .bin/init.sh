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

  # Check if oh-my-zsh is installed, if not install it
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh is not installed. Installing oh-my-zsh..."
    
    # CI 環境対応: Git の SSH を HTTPS にリダイレクト
    git config --global url."https://github.com/".insteadOf "git@github.com:"
    git config --global url."https://".insteadOf "git://"
    
    # 公式のインストール方法に従う
    echo "Installing Oh My Zsh using official installer..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    if [ $? -eq 0 ]; then
      echo "Successfully installed oh-my-zsh"
    else
      echo "Error: Failed to install oh-my-zsh"
      exit 1
    fi
  else
    echo "oh-my-zsh is already installed"
  fi
fi

# Check if Ubuntu (incl. WSL2)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # apt が対話プロンプトで止まらないようにする（CI / ssh 越しの非対話実行のため）
  export DEBIAN_FRONTEND=noninteractive

  # Update and upgrade
  echo "Update and upgrade"
  sudo -E apt update
  sudo -E apt upgrade -y
  sudo -E apt autoremove --purge -y

  # Install essential packages
  echo "Install essential packages"
  sudo -E apt-get install -y build-essential
  # Add additional commands for Ubuntu here

  # Install zsh, git, curl, make, make-guile, and vi
  echo "Install zsh, git, curl, make, make-guile, and vi"
  sudo -E apt -y install zsh powerline fonts-powerline
  sudo -E apt -y install git
  sudo -E apt -y install curl
  sudo -E apt -y install make
  sudo -E apt -y install make-guile
  sudo -E apt -y install vim
  sudo -E apt-get install -y language-pack-en
  sudo update-locale

  # Default shell to zsh
  # 対象ユーザーを明示しないと sudo 経由では root のログインシェルが変わってしまう
  echo "Default shell to zsh"
  sudo chsh -s "$(command -v zsh)" "${USER:-$(id -un)}"

  # Set up git
  echo "Set up git"
  git config --global user.email "ktaroabobon@gmail.com"
  git config --global user.name "ktaroabobon"

  # Install oh-my-zsh
  # インストーラは既存の .zshrc を .zshrc.pre-oh-my-zsh へ退避して作り直すため、
  # .zshrc への追記より先に済ませる。--unattended でシェル切り替えと chsh を抑止する。
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Install oh-my-zsh"
    omz_installer=$(mktemp)
    # curl の失敗を握り潰さない（sh -c "$(curl ...)" は curl が落ちても成功扱いになる）
    if ! curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_installer"; then
      echo "Error: Failed to download the oh-my-zsh installer"
      rm -f "$omz_installer"
      exit 1
    fi
    if ! sh "$omz_installer" "" --unattended; then
      echo "Error: Failed to install oh-my-zsh"
      rm -f "$omz_installer"
      exit 1
    fi
    rm -f "$omz_installer"
  else
    echo "oh-my-zsh is already installed"
  fi

  zshrc_file="${HOME}/.zshrc"

  # ログインシェルを zsh に固定する（再実行で重複追記しない）
  shell_line='export SHELL=$(which zsh)'
  if ! grep -qF "$shell_line" "$zshrc_file"; then
    echo "$shell_line" >> "$zshrc_file"
  fi

  # Change oh-my-zsh theme to Agnoster
  echo "Change oh-my-zsh theme to Agnoster"
  theme_line='ZSH_THEME="agnoster"'

  if grep -q "^ZSH_THEME=" "$zshrc_file"; then
    # Replace existing ZSH_THEME line
    awk -v theme_line="$theme_line" '{sub(/^ZSH_THEME=.*$/, theme_line)}1' "$zshrc_file" > "${zshrc_file}.tmp" && mv "${zshrc_file}.tmp" "$zshrc_file"
  else
    # Add new ZSH_THEME line
    echo "$theme_line" >> "$zshrc_file"
  fi

  # Restart the shell
  # exec はプロセスを置き換えるため、以降の処理と終了コードが失われる。
  # 対話端末のときだけ行い、CI / 非対話ではスキップして最後まで完走させる。
  if [ -z "${CI:-}" ] && [ -t 0 ] && [ -t 1 ]; then
    exec zsh
  fi
  echo "Skip 'exec zsh' (non-interactive shell). Open a new terminal to use zsh."
fi

echo "End init.sh"
echo "----------------------------------------"
