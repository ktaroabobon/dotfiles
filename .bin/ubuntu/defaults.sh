#!/bin/zsh

# ネイティブの Ubuntu デスクトップ向け（GNOME 前提）。WSL2 では使わない。

echo "Start default.sh"

# テーマやソースの取得は専用の作業ディレクトリで行う。
# カレントディレクトリ相対のまま `rm -rf` / `git clone` すると、
# リポジトリの中で実行されて作業ツリーを汚す。
WORK_DIR="${HOME}/.cache/dotfiles-ubuntu"
mkdir -p "$WORK_DIR"

# gsettingsコマンドが利用可能か確認し、インストールする
if ! command -v gsettings &> /dev/null
then
    echo "gsettingsが見つかりません。インストールします..."
    sudo apt install -y gnome-session-bin
fi

# ディレクトリ名を英語に変更
echo "ディレクトリ名を英語に変更"
LANG=C xdg-user-dirs-update --force
LANG=C xdg-user-dirs-gtk-update --force

# ホームディレクトリ下の日本語のディレクトリを削除
echo "日本語のディレクトリを削除"
rm -rf ~/デスクトップ ~/ドキュメント ~/ダウンロード ~/ミュージック ~/ピクチャ ~/ビデオ

# 不要なデスクトップアイコンを非表示にする
echo "不要なデスクトップアイコンを非表示にする"
gsettings set org.gnome.desktop.background show-desktop-icons false

# デスクトップアイコンの配置を右上に設定
echo "デスクトップアイコンの配置を右上に設定"
gsettings set org.gnome.shell.extensions.desktop-icons icon-placement 'top-right'

# 必要なツールをインストール
echo "必要なツールをインストール"
sudo apt install -y chrome-gnome-shell git gnome-tweaks wmctrl

# GNOMEターミナルの設定を変更
echo "GNOMEターミナルの設定を変更"
gsettings set org.gnome.Terminal.Legacy.Settings headerbar false

# MacOS Big Sur風テーマのインストール
echo "MacOS Big Sur風テーマのインストール"
cd "$WORK_DIR" || exit 1
if [ -d "WhiteSur-gtk-theme" ]; then
    rm -rf WhiteSur-gtk-theme
fi
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme || exit 1
./install.sh --opacity solid --alt normal --theme blue --icon ubuntu --nautilus-style mojave --panel-size smaller
if command -v gdm &> /dev/null; then
    sudo ./tweaks.sh --gdm default --opacity solid --theme blue --icon ubuntu
fi
./tweaks.sh --firefox
./tweaks.sh --dash-to-dock
cd "$WORK_DIR" || exit 1

# MacOS Big Sur風アイコンのインストール
echo "MacOS Big Sur風アイコンのインストール"
if [ -d "WhiteSur-icon-theme" ]; then
    rm -rf WhiteSur-icon-theme
fi
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme || exit 1
./install.sh --theme default --bold
cd "$WORK_DIR" || exit 1

# MacOS Big Sur風カーソルアイコンのインストール
echo "MacOS Big Sur風カーソルアイコンのインストール"
mkdir -p ~/.icons
cd ~/.icons || exit 1
curl -L -O https://github.com/ful1e5/apple_cursor/releases/download/v1.1.1/macOSBigSur.tar.gz
tar -xzf macOSBigSur.tar.gz
rm macOSBigSur.tar.gz
cd "$WORK_DIR" || exit 1

# Ulauncherのインストール
echo "Ulauncherのインストール"
sudo add-apt-repository -y ppa:agornostal/ulauncher
sudo apt install -y ulauncher

# キーボードショートカットの設定
echo "キーボードショートカットの設定"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver '["<Primary><Super>q"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys help '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal '["<Super>t"]'
gsettings set org.gnome.desktop.wm.keybindings switch-applications '["<Super>Tab"]'
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward '["<Shift><Super>Tab"]'
gsettings set org.gnome.desktop.wm.keybindings switch-windows '["<Super>`"]'
gsettings set org.gnome.shell.keybindings toggle-overview '["<Control>Up"]'
gsettings set org.gnome.shell.keybindings show-apps '["<Control>Down"]'
gsettings set org.gnome.desktop.wm.keybindings show-desktop '["<Control><Super>x"]'
gsettings set org.gnome.desktop.wm.keybindings switch-input-source '["<Control>o"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '["<Shift><Super>3"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot-clipboard '["<Shift><Control><Super>3"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot '["<Shift><Super>4"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot-clipboard '["<Shift><Control><Super>4"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot '["<Shift><Super>5"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clipboard '["<Shift><Control><Super>5"]'

# 無効化するショートカットの設定
# FIXME: ここで空にしているキーは、上のブロックで設定したものと同じ
#        (screensaver / screenshot 系)。結果として上の設定は効いていない。
#        README の「無効にするショートカット」はウィンドウを非表示 /
#        通知フォーカス / 通知リストであり、ここと一致していない。
#        どちらが意図なのか確認が必要なため、テストでは検証対象から外している。
echo "無効化するショートカットの設定"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot-clipboard '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot-clipboard '[]'
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clipboard '[]'

# gnome-tweaksの設定
echo "gnome-tweaksの設定"
gsettings set org.gnome.desktop.wm.preferences focus-mode 'mouse'
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-dark-solid'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-dark-solid' --schemadir ~/.themes/WhiteSur-dark-solid/gnome-shell

# 日本語入力環境の設定
# ibus-mozc を起動時からひらがなモードにするため、ソースを書き換えてビルドし直す。
echo "日本語入力環境の設定"

# ソースパッケージを取るには deb-src が要る。
# Ubuntu 24.04 以降の apt は deb822 形式 (/etc/apt/sources.list.d/ubuntu.sources)
# を使うため、旧来の /etc/apt/sources.list を編集しても効かない。
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    echo "deb822 形式の sources を更新します"
    sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
else
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo "従来形式の sources.list で ${CODENAME} の deb-src を有効にします"
    sudo sed -i "s|^# *deb-src \(.*\) ${CODENAME}|deb-src \1 ${CODENAME}|" /etc/apt/sources.list
fi
sudo apt update

sudo apt build-dep -y ibus-mozc
cd "$WORK_DIR" || exit 1
apt source ibus-mozc
cd mozc-* || exit 1
find . -name property_handler.cc -exec \
    sed -i 's/const bool kActivateOnLaunch = false;/const bool kActivateOnLaunch = true;/' {} +
sudo apt install -y fakeroot
dpkg-buildpackage -us -uc -b
cd "$WORK_DIR" || exit 1
sudo dpkg -i mozc*.deb ibus-mozc*.deb

echo "End default.sh"
echo "----------------------------------------"
