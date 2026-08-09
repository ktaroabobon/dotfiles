#!/usr/bin/env bash
# Brewfile の反映漏れチェック (brew_drift.sh --pr) を launchd に登録/解除する。
#
#   brew_drift_launchd.sh install     毎週月曜 10:00 に実行するよう登録する
#   brew_drift_launchd.sh uninstall   登録を解除する
#   brew_drift_launchd.sh status      登録状態を表示する

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

LABEL="com.ktaroabobon.brew-drift"
TEMPLATE="$SCRIPT_DIR/$LABEL.plist.template"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

case "${1:-}" in
  install)
    [ -f "$TEMPLATE" ] || { echo "❌ テンプレートがありません: $TEMPLATE" >&2; exit 1; }

    # plist にはリポジトリの実パスを焼き込む。worktree は消える前提のものなので、
    # そこから登録すると週次実行が存在しないパスを叩くようになる。
    if [ "$(git -C "$REPO_ROOT" rev-parse --git-dir 2> /dev/null)" \
      != "$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2> /dev/null)" ]; then
      echo "❌ ここは git worktree です: $REPO_ROOT" >&2
      echo "   worktree は削除される前提のため、本体のリポジトリで実行してください" >&2
      exit 1
    fi

    mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
    sed -e "s|__REPO_ROOT__|$REPO_ROOT|g" -e "s|__HOME__|$HOME|g" "$TEMPLATE" > "$PLIST"
    plutil -lint "$PLIST" > /dev/null

    # 既に読み込まれている場合は入れ替える
    launchctl bootout "$DOMAIN/$LABEL" 2> /dev/null || true
    launchctl bootstrap "$DOMAIN" "$PLIST"

    echo "✅ 登録しました: $PLIST"
    echo "   リポジトリ: $REPO_ROOT"
    echo "   スケジュール: 毎週月曜 10:00"
    echo "   ログ: $HOME/Library/Logs/brew-drift.log"
    echo
    echo "すぐ試すには: launchctl kickstart -p $DOMAIN/$LABEL"
    ;;

  uninstall)
    launchctl bootout "$DOMAIN/$LABEL" 2> /dev/null || true
    rm -f "$PLIST"
    echo "✅ 解除しました: $LABEL"
    ;;

  status)
    if launchctl print "$DOMAIN/$LABEL" > /dev/null 2>&1; then
      echo "✅ 登録済み: $LABEL"
      launchctl print "$DOMAIN/$LABEL" | grep -E '^\s+(state|path|last exit code) ' || true
    else
      echo "未登録 ($LABEL)"
      echo "登録するには: make brew-drift-install"
    fi
    ;;

  *)
    echo "usage: ${0##*/} {install|uninstall|status}" >&2
    exit 2
    ;;
esac
