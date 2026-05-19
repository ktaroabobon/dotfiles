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
# .claude / .codex は実マシン側に動的データ (sessions/, history.jsonl, sqlite 等) を
# 持つため、ここではディレクトリ単位でリンクせず、後段で個別リンクする。
for dotfile in "${SCRIPT_DIR}"/.??*; do
  [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.claude" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.codex" ]] && continue

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

# Codex 設定の個別リンク。
# $HOME/.codex/ は実体ディレクトリのまま残し、管理対象だけシンボリックリンクに差し替える。
# auth.json などの認証情報やセッション/ログ系は管理対象外。
CODEX_SRC="${SCRIPT_DIR}/.codex"
if [ -d "$CODEX_SRC" ]; then
  mkdir -p "$HOME/.codex/rules"

  # ルート直下のファイル
  for f in config.toml; do
    [ -f "$CODEX_SRC/$f" ] && ln -fnsv "$CODEX_SRC/$f" "$HOME/.codex/$f"
  done

  # rules/ 配下のファイル
  for rule in "$CODEX_SRC/rules"/*; do
    [ -e "$rule" ] && ln -fnsv "$rule" "$HOME/.codex/rules/$(basename "$rule")"
  done
fi

echo "End link.sh"
echo "----------------------------------------"
