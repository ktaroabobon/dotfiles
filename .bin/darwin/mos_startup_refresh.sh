#!/bin/zsh

set -euo pipefail

# MX Ergo S の左右チルトがログイン後に効かなくなる Mac だけで実行する。
readonly TARGET_LOCAL_HOSTNAME="KeitaronoMacBook-Pro"
readonly CURRENT_LOCAL_HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || true)"

if [[ "$CURRENT_LOCAL_HOSTNAME" != "$TARGET_LOCAL_HOSTNAME" ]]; then
  exit 0
fi

if [[ ! -d /Applications/Mos.app ]]; then
  print -u2 "Mos is not installed: /Applications/Mos.app"
  exit 0
fi

# ログイン直後は Bluetooth と MX Ergo S の HID デバイスがまだ準備中の場合がある。
sleep "${MOS_STARTUP_DELAY_SECONDS:-15}"

# Mos 4.2.1 はログイン後に Logitech HID++ のボタン入力を受け取れない場合がある。
# 一度終了して起動し直し、起動済みの Mos を再度 open して設定画面を生成すると
# HID++ セッションが再初期化される。-g により前面アプリは切り替えない。
pkill -TERM -x Mos 2>/dev/null || true
for _ in {1..10}; do
  pgrep -x Mos >/dev/null || break
  sleep 1
done

open -gja Mos
sleep 5
open -gja Mos

