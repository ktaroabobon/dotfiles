#!/bin/zsh

# .zshrc の plugins=() が参照する oh-my-zsh のカスタムプラグインを配置する。
#
# oh-my-zsh は $ZSH_CUSTOM/plugins/<name> に置かれたものをカスタムプラグインとして
# 読み込む。同名の Homebrew formula もあるが、あちらは .zshrc から明示的に
# source する形式で別物。plugins=() に名前を書いている以上こちらが必要で、
# 無いとシェルを開くたびに「[oh-my-zsh] plugin 'xxx' not found」が出る。

echo "Start omz_plugins.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH_DIR" ]; then
  echo "Error: oh-my-zsh is not installed. Please run init.sh first."
  exit 1
fi

PLUGIN_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}/plugins"
mkdir -p "$PLUGIN_DIR"

# .zshrc の plugins=() と揃えること（git は oh-my-zsh 同梱なので対象外）
omz_plugins=(
  zsh-syntax-highlighting
  zsh-completions
  zsh-autosuggestions
  zsh-history-substring-search
)

for name in "${omz_plugins[@]}"; do
  dest="$PLUGIN_DIR/$name"

  if [ -d "$dest" ]; then
    echo "$name is already installed"
    continue
  fi

  echo "Installing $name..."
  # 管理下の .gitconfig には `[url "git@github.com:"] insteadOf = https://github.com/`
  # があるため、そのまま clone すると SSH に書き換わる。SSH 鍵が無い環境 (CI など)
  # でも通るよう、グローバル設定を読まずに https のまま取得する。
  if GIT_CONFIG_GLOBAL=/dev/null git clone --depth 1 \
    "https://github.com/zsh-users/${name}.git" "$dest"; then
    echo "Successfully installed $name"
  else
    echo "Error: Failed to install $name"
    exit 1
  fi
done

echo "End omz_plugins.sh"
echo "----------------------------------------"
