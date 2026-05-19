#!/bin/zsh

echo "Start link.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

SCRIPT_DIR=$(
  cd $(dirname $0)
  pwd
)

# ホーム直下にリンクするドットファイル/ドットディレクトリ。
# .claude は実マシン側に動的データ (sessions/, projects/, history.jsonl 等) を
# 持つため、ここではディレクトリ単位でリンクせず、後段で個別リンクする。
for dotfile in "${SCRIPT_DIR}"/.??*; do
  [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.claude" ]] && continue

  ln -fnsv "$dotfile" "$HOME"
done

# Claude Code 設定の個別リンク。
# $HOME/.claude/ は実体ディレクトリのまま残し、管理対象だけシンボリックリンクに差し替える。
CLAUDE_SRC="${SCRIPT_DIR}/.claude"
if [ -d "$CLAUDE_SRC" ]; then
  mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills"

  # ルート直下のファイル
  for f in CLAUDE.md RTK.md settings.json keybindings.json; do
    [ -f "$CLAUDE_SRC/$f" ] && ln -fnsv "$CLAUDE_SRC/$f" "$HOME/.claude/$f"
  done

  # commands/ 配下のファイル
  for cmd in "$CLAUDE_SRC/commands"/*; do
    [ -e "$cmd" ] && ln -fnsv "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
  done

  # hooks/ 配下のファイル (隠しファイル含む)
  for hook in "$CLAUDE_SRC/hooks"/* "$CLAUDE_SRC/hooks"/.??*; do
    [ -e "$hook" ] && ln -fnsv "$hook" "$HOME/.claude/hooks/$(basename "$hook")"
  done

  # skills/ 配下のディレクトリ単位リンク
  for skill in "$CLAUDE_SRC/skills"/*/; do
    skill_name=$(basename "$skill")
    ln -fnsv "${skill%/}" "$HOME/.claude/skills/$skill_name"
  done
fi

echo "End link.sh"
echo "----------------------------------------"
