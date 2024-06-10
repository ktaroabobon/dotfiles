#!/bin/zsh

echo "Start default.sh"

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
sudo apt install -y chrome-gnome-shell gnome-tweak wmctrl

# GNOMEターミナルの設定を変更
echo "GNOMEターミナルの設定を変更"
gsettings set org.gnome.Terminal.Legacy.Settings headerbar false

# MacOS Big Sur風テーマのインストール
echo "MacOS Big Sur風テーマのインストール"
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh --opacity solid --alt normal --theme blue --icon ubuntu --nautilus-style mojave --panel-size smaller
sudo ./tweaks.sh --gdm default --opacity solid --color dark --theme blue --icon ubuntu
./tweaks.sh --firefox
./tweaks.sh --dash-to-dock --color dark
cd ..

# MacOS Big Sur風アイコンのインストール
echo "MacOS Big Sur風アイコンのインストール"
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh --theme default --bold
cd ..

# MacOS Big Sur風カーソルアイコンのインストール
echo "MacOS Big Sur風カーソルアイコンのインストール"
mkdir -p ~/.icons
cd ~/.icons
curl -L -O https://github.com/ful1e5/apple_cursor/releases/download/v1.1.1/macOSBigSur.tar.gz
tar -xzf macOSBigSur.tar.gz
rm macOSBigSur.tar.gz
cd ~

# Ulauncherのインストール
echo "Ulauncherのインストール"
sudo add-apt-repository ppa:agornostal/ulauncher
sudo apt install -y ulauncher

# gsettingsのインストール
echo "gsettingsのインストール"
sudo apt-get install libglib2.0-bin

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
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-dark-solid'

# 日本語入力環境の設定
echo "日本語入力環境の設定"
sudo sed -i 's/^deb-src/#deb-src/' /etc/apt/sources.list
echo 'deb-src https://jp.archive.ubuntu.com/ubuntu/ hirsute main restricted' | sudo tee -a /etc/apt/sources.list
sudo apt build-dep ibus-mozc
apt source ibus-mozc
cd mozc-*
sed -i 's/const bool kActivateOnLaunch = false;/const bool kActivateOnLaunch = true;/' $(find . -name property_handler.cc)
sudo apt install -y fakeroot
dpkg-buildpackage -us -uc -b
cd ..
sudo dpkg -i mozc*.deb ibus-mozc*.deb

echo "End default.sh"
echo "----------------------------------------"
