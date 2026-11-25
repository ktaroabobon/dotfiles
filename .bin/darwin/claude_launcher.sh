#!/bin/zsh

set -eu

echo "Start claude_launcher.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="${SCRIPT_DIR}/claude_launcher/launcher.applescript"
CLAUDE_APP="/Applications/Claude.app"
APP="${HOME}/Applications/Claude Launcher.app"

if [ ! -d "${CLAUDE_APP}" ]; then
  echo "${CLAUDE_APP} が見つかりません。先に Claude デスクトップアプリをインストールしてください"
  exit 1
fi

mkdir -p "${HOME}/Applications"
rm -rf "${APP}"
osacompile -o "${APP}" "${SOURCE}"

# Dock で見分けやすいよう、Claude 本体のアイコンを使う。
# CFBundleIconName が残っていると Assets.car の Script Editor のアイコンが優先されるため、参照ごと外す
cp "${CLAUDE_APP}/Contents/Resources/electron.icns" "${APP}/Contents/Resources/applet.icns"
rm -f "${APP}/Contents/Resources/Assets.car"
plutil -remove CFBundleIconName "${APP}/Contents/Info.plist"

# osacompile は識別子を付けない。識別子が無いと、作り直すたびに System Events の操作の許可が別のアプリとして扱われる
plutil -replace CFBundleIdentifier -string "com.ktaroabobon.claude-launcher" "${APP}/Contents/Info.plist"

# アイコンの差し替えで osacompile の署名が無効になるため、ad-hoc で署名し直す
codesign --force --deep --sign - "${APP}"

echo "${APP} を作成しました"
echo "End claude_launcher.sh"
echo "----------------------------------------"
