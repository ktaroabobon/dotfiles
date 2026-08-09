#!/bin/bash
# Tailscale を公式 apt リポジトリから導入する。
#
# WSL2 では home-infra の常駐ホストとして tailnet に参加させる。tailnet は
# 外出先からの入口（tailscale serve）であると同時に、他マシンから hictl を叩く
# 経路でもあるため、ここが落ちると外から一切届かなくなる。
#
# 注意: **Windows 側には入れないこと**。同一 PC が tailnet 上の 2 ノードになり、
# 名前と経路が混乱する（.bin/windows/README.md 参照）。

set -eu

echo "Start tailscale.sh"

if [ "$(uname)" != "Linux" ]; then
  echo "This script is only for Linux (incl. WSL2)"
  exit 1
fi

if command -v tailscale >/dev/null 2>&1; then
  echo "tailscale は導入済み: $(tailscale version | head -1)"
else
  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "Ubuntu ${CODENAME} 向けのリポジトリを登録します"

  sudo install -m 0755 -d /usr/share/keyrings
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
    | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" \
    | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y tailscale
  echo "導入しました: $(tailscale version | head -1)"
fi

# systemd で自動起動する状態にしておく。WSL2 では /etc/wsl.conf に
# `[boot] systemd=true` が要る（無いと enable しても起動時に上がらない）。
# 既に整っているときは sudo を呼ばない — 再実行のたびにパスワードを聞かれると、
# 非対話での実行（他マシンから ssh 越しに流す等）で固まるため
if command -v systemctl >/dev/null 2>&1; then
  if [ "$(systemctl is-enabled tailscaled 2>/dev/null)" = "enabled" ] &&
     [ "$(systemctl is-active tailscaled 2>/dev/null)" = "active" ]; then
    echo "tailscaled: 既に active かつ enabled のため何もしません"
  else
    sudo systemctl enable --now tailscaled
    echo "tailscaled: active=$(systemctl is-active tailscaled) enabled=$(systemctl is-enabled tailscaled)"
  fi
fi

cat <<'NEXT'

--- 手動で行う手順 ---
1. tailnet に参加する（--ssh は他マシンからの Tailscale SSH 受け入れ。root 権限が要る）
     sudo tailscale up --ssh

2. home-infra の常駐ホストにする場合は HTTPS の入口も作る
     sudo tailscale serve --bg 8787

   毎回 sudo を打ちたくなければ 1 度だけ:
     sudo tailscale set --operator=$USER

手順の詳細は home-infra の docs/runbook/wsl2-host-setup.md 7 節を参照。
NEXT

echo "End tailscale.sh"
echo "----------------------------------------"
