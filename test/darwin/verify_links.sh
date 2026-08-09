#!/usr/bin/env bash
# .bin/darwin/link.sh が張ったシンボリックリンクを検証する。
#
# `ls -la` はリンク切れでも成功してしまうため、
#   1. シンボリックリンクであること
#   2. リンク先がリポジトリ内の想定ファイルであること
#   3. リンク切れでないこと
# を個別に確認する。link.sh の対象はリポジトリの中身から導出するので、
# 管理対象を増やしてもこのスクリプトを直す必要はない。

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
DARWIN_DIR="$REPO_ROOT/.bin/darwin"
SHARED_DIR="$REPO_ROOT/.bin/shared"

status=0

check() {
  local link="$1" expected="$2"

  if [ ! -L "$link" ]; then
    echo "❌ $link がシンボリックリンクではありません"
    status=1
    return
  fi

  local actual
  actual=$(readlink "$link")
  if [ "$actual" != "$expected" ]; then
    echo "❌ $link -> $actual (期待: $expected)"
    status=1
    return
  fi

  if [ ! -e "$link" ]; then
    echo "❌ $link はリンク切れです -> $actual"
    status=1
    return
  fi

  echo "✅ $link -> $actual"
}

echo "--- ホーム直下のドットファイル ---"
# .claude / .codex / .zsh はディレクトリごとではなく中身を個別にリンクする
for f in "$DARWIN_DIR"/.??*; do
  base=$(basename "$f")
  case "$base" in
    .git | .DS_Store | .claude | .codex | .zsh) continue ;;
  esac
  check "$HOME/$base" "$f"
done

echo
echo "--- ~/.zsh (darwin/.zsh + プラットフォーム非依存の shared/) ---"
for f in "$DARWIN_DIR"/.zsh/* "$SHARED_DIR"/*; do
  [ -e "$f" ] || continue
  check "$HOME/.zsh/$(basename "$f")" "$f"
done

echo
echo "--- ~/.claude ---"
for f in CLAUDE.md RTK.md settings.json keybindings.json; do
  [ -f "$DARWIN_DIR/.claude/$f" ] || continue
  check "$HOME/.claude/$f" "$DARWIN_DIR/.claude/$f"
done
for d in commands hooks; do
  for f in "$DARWIN_DIR/.claude/$d"/* "$DARWIN_DIR/.claude/$d"/.??*; do
    [ -e "$f" ] || continue
    check "$HOME/.claude/$d/$(basename "$f")" "$f"
  done
done
for d in "$DARWIN_DIR/.claude/skills"/*/; do
  [ -d "$d" ] || continue
  check "$HOME/.claude/skills/$(basename "$d")" "${d%/}"
done

echo
echo "--- ~/.codex ---"
if [ -f "$DARWIN_DIR/.codex/config.toml" ]; then
  check "$HOME/.codex/config.toml" "$DARWIN_DIR/.codex/config.toml"
fi
for f in "$DARWIN_DIR/.codex/rules"/*; do
  [ -e "$f" ] || continue
  check "$HOME/.codex/rules/$(basename "$f")" "$f"
done

echo
echo "--- リンク切れの総ざらい ---"
# リポジトリ側のファイル名を変えたとき、無音で壊れるのを防ぐ
dangling=$(find "$HOME/.zsh" "$HOME/.claude" "$HOME/.codex" \
  -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null)
if [ -n "$dangling" ]; then
  echo "❌ リンク切れがあります:"
  echo "$dangling"
  status=1
else
  echo "✅ リンク切れなし"
fi

exit $status
