#!/bin/zsh

set -euo pipefail

readonly TARGET_LOCAL_HOSTNAME="KeitaronoMacBook-Pro"
readonly CURRENT_LOCAL_HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || true)"
readonly SCRIPT_DIR="${0:A:h}"
readonly LABEL="com.ktaroabobon.mos-startup-refresh"
readonly TEMPLATE="$SCRIPT_DIR/$LABEL.plist.template"
readonly INSTALL_DIR="$HOME/Library/Application Support/dotfiles"
readonly INSTALLED_SCRIPT="$INSTALL_DIR/mos_startup_refresh.sh"
readonly PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
readonly LOG_PATH="$HOME/Library/Logs/mos-startup-refresh.log"
readonly DOMAIN="gui/$(id -u)"

if [[ "$(uname)" != "Darwin" ]]; then
  print -u2 "This script is only for macOS"
  exit 1
fi

case "${1:-}" in
  install)
    if [[ "$CURRENT_LOCAL_HOSTNAME" != "$TARGET_LOCAL_HOSTNAME" ]]; then
      print "対象外のMacなので登録しません: $CURRENT_LOCAL_HOSTNAME"
      exit 0
    fi

    [[ -f "$TEMPLATE" ]] || { print -u2 "テンプレートがありません: $TEMPLATE"; exit 1; }
    [[ -f "$SCRIPT_DIR/mos_startup_refresh.sh" ]] || { print -u2 "実行スクリプトがありません"; exit 1; }

    mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
    cp "$SCRIPT_DIR/mos_startup_refresh.sh" "$INSTALLED_SCRIPT"
    chmod 755 "$INSTALLED_SCRIPT"

    sed \
      -e "s|__SCRIPT_PATH__|$INSTALLED_SCRIPT|g" \
      -e "s|__LOG_PATH__|$LOG_PATH|g" \
      "$TEMPLATE" > "$PLIST"
    plutil -lint "$PLIST" >/dev/null

    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    launchctl bootstrap "$DOMAIN" "$PLIST"
    print "登録しました: $PLIST"
    ;;

  uninstall)
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
    rm -f "$PLIST" "$INSTALLED_SCRIPT"
    print "解除しました: $LABEL"
    ;;

  status)
    if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
      print "登録済み: $LABEL"
      launchctl print "$DOMAIN/$LABEL" | grep -E '^\s+(state|path|last exit code) ' || true
    else
      print "未登録: $LABEL"
    fi
    ;;

  *)
    print -u2 "usage: ${0:t} {install|uninstall|status}"
    exit 2
    ;;
esac
