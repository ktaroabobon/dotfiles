#!/usr/bin/env bash
# 指定した rc ファイルを zsh で読み込めることを検証する。
#
# 注意点が 3 つある。
#   1. パイプを挟むと `$?` がパイプ末尾のコマンド (tee 等) の終了コードになり、
#      rc がどれだけ壊れていても成功扱いになる。ここではパイプを使わない。
#   2. `set -x` のトレースを混ぜない。混ぜるとエラー判定の grep が
#      rc の中身 (ZSH_THEME="cobalt2" など) に誤ってマッチする。
#   3. 終了コード 0 でもコマンド不在は素通りする。
#      `eval "$(direnv hook zsh)"` は direnv が無くても 0 を返すため、
#      出力に対して command not found を別途チェックする。

set -uo pipefail

rc="${1:-}"
if [ -z "$rc" ]; then
  echo "usage: ${0##*/} <.zshrc|.zprofile>" >&2
  exit 2
fi

rc_path="$HOME/$rc"

if [ ! -f "$rc_path" ]; then
  echo "❌ $rc_path が見つかりません"
  exit 1
fi

zsh_exec=$(command -v zsh || true)
if [ -z "$zsh_exec" ]; then
  echo "❌ zsh が見つかりません"
  exit 1
fi
echo "zsh: $zsh_exec ($("$zsh_exec" --version))"

log="${RUNNER_TEMP:-/tmp}/load-rc-${rc#.}.log"

if ! "$zsh_exec" -c "source '$rc_path'" > "$log" 2>&1; then
  echo "❌ $rc の読み込みに失敗しました"
  cat "$log"
  exit 1
fi
echo "✅ $rc を読み込めました"

if [ -s "$log" ]; then
  echo "--- 読み込み時の出力 ---"
  cat "$log"
  echo "------------------------"
fi

if grep -q "command not found" "$log"; then
  echo "❌ $rc の読み込み中に command not found が発生しています"
  echo "   rc が参照しているツールが Brewfile に入っているか確認してください"
  exit 1
fi
