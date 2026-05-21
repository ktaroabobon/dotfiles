#!/bin/zsh

echo "Start zoom_backgrounds.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
URLS_FILE="${SCRIPT_DIR}/zoom_backgrounds.txt"
DEST_DIR="${ZOOM_BG_DIR:-${HOME}/Pictures/ZoomBackgrounds}"

mkdir -p "${DEST_DIR}"
echo "保存先: ${DEST_DIR}"

if [ ! -f "${URLS_FILE}" ]; then
  echo "URL リスト ${URLS_FILE} が存在しないためスキップします"
  echo "End zoom_backgrounds.sh"
  echo "----------------------------------------"
  exit 0
fi

if ! command -v wget >/dev/null 2>&1; then
  echo "wget が見つかりません。brew bundle 経由で wget をインストールしてください"
  exit 1
fi

downloaded=0
skipped=0
failed=0

while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
  # 前後の空白を削る
  line="${raw_line#"${raw_line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  # 空行・コメント行はスキップ
  [ -z "${line}" ] && continue
  case "${line}" in
    \#*) continue ;;
  esac

  filename="${line##*/}"
  filename="${filename%%\?*}"
  if [ -z "${filename}" ]; then
    echo "ファイル名を URL から取り出せませんでした: ${line}"
    failed=$((failed + 1))
    continue
  fi

  target="${DEST_DIR}/${filename}"
  if [ -f "${target}" ]; then
    echo "既に存在するためスキップ: ${filename}"
    skipped=$((skipped + 1))
    continue
  fi

  echo "ダウンロード: ${filename}"
  if wget --quiet --show-progress --output-document="${target}" "${line}"; then
    downloaded=$((downloaded + 1))
  else
    echo "ダウンロード失敗: ${line}"
    rm -f "${target}"
    failed=$((failed + 1))
  fi
done < "${URLS_FILE}"

echo "結果: 新規 ${downloaded} 件 / スキップ ${skipped} 件 / 失敗 ${failed} 件"

# Zoom のバーチャル背景ディレクトリへのシンボリックリンクは Zoom の実装に依存するため案内のみに留める
echo ""
echo "Zoom アプリの「バーチャル背景」設定画面で ${DEST_DIR} 配下の画像を選択してください。"

echo "End zoom_backgrounds.sh"
echo "----------------------------------------"
