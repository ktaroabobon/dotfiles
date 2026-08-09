#!/bin/zsh

# Snapの確認とインストール
if ! command -v snap &> /dev/null; then
    echo "Snapが見つかりません。インストールします..."
    sudo apt update
    sudo apt install -y snapd
    sudo ln -s /var/lib/snapd/snap /snap
    echo "Snapのインストールが完了しました。"
else
    echo "Snapは既にインストールされています。"
fi

# 必要なアプリケーションのインストール
echo "必要なアプリケーションのインストールを開始します..."

# AWS CLI
echo "Installing AWS CLI"
sudo snap install aws-cli --classic

# Docker
echo "Installing Docker"
sudo snap install docker

# JetBrains Toolbox
echo "Installing JetBrains Toolbox"
sudo snap install jetbrains-toolbox --classic

# Visual Studio Code
echo "Installing Visual Studio Code"
sudo snap install code --classic

# Postman
echo "Installing Postman"
sudo snap install postman

# Google Chrome
echo "Installing Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Firefox
echo "Installing Firefox"
sudo snap install firefox

# Zoom
echo "Installing Zoom"
sudo snap install zoom-client

# Logitech Options
echo "Installing Logitech Options"
sudo snap install logi-options-plus

# Discord
echo "Installing Discord"
sudo snap install discord

# Slack
echo "Installing Slack"
sudo snap install slack --classic

echo "全てのアプリケーションのインストールが完了しました。"
