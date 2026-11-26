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
# .zsh も同様に個別リンクする（理由は下記）。
# .local はほかのアプリの実データも入るため、管理対象のファイルだけを後段で個別リンクする。
for dotfile in "${SCRIPT_DIR}"/.??*; do
  [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.claude" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.codex" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.zsh" ]] && continue
  [[ "$dotfile" == "${SCRIPT_DIR}/.local" ]] && continue

  ln -fnsv "$dotfile" "$HOME"
done

# ~/.zsh は実ディレクトリとして作り、中身を個別にリンクする。
# ディレクトリごとリンクすると ~/.zsh が darwin/.zsh へのシンボリックリンクに
# なり、後段の shared のリンクがそれを辿って *リポジトリの中* に作られてしまう。
mkdir -p "$HOME/.zsh"

# darwin 固有のスクリプト
for f in "${SCRIPT_DIR}"/.zsh/*; do
  [ -e "$f" ] && ln -fnsv "$f" "$HOME/.zsh/$(basename "$f")"
done

# 共有スクリプト（プラットフォーム非依存）
SHARED_DIR="$(cd "${SCRIPT_DIR}/../shared" && pwd)"
if [ -d "$SHARED_DIR" ]; then
  for shared in "$SHARED_DIR"/*; do
    [ -e "$shared" ] && ln -fnsv "$shared" "$HOME/.zsh/$(basename "$shared")"
  done
fi

# Claude Code 設定の個別リンク。
# $HOME/.claude/ は実体ディレクトリのまま残し、管理対象だけシンボリックリンクに差し替える。
CLAUDE_SRC="${SCRIPT_DIR}/.claude"
if [ -d "$CLAUDE_SRC" ]; then
  mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills"

  # ルート直下のファイル
  for f in CLAUDE.md settings.json keybindings.json; do
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

  # AGENTS.md は Claude Code の CLAUDE.md と同じ原則を指す。手元で書いた実ファイルは上書きしない
  if [ -e "$HOME/.codex/AGENTS.md" ] && [ ! -L "$HOME/.codex/AGENTS.md" ]; then
    echo "~/.codex/AGENTS.md が実ファイルなのでリンクしません。中身を .bin/darwin/.claude/CLAUDE.md へ移してから消してください"
  else
    ln -fnsv "$CODEX_SRC/AGENTS.md" "$HOME/.codex/AGENTS.md"
  fi

  # rules/ 配下のファイル
  for rule in "$CODEX_SRC/rules"/*; do
    [ -e "$rule" ] && ln -fnsv "$rule" "$HOME/.codex/rules/$(basename "$rule")"
  done
fi

# リポジトリから消したファイルを指していたリンクを片付ける（リンク切れを残さない）。
find "$HOME/.claude" "$HOME/.codex" -maxdepth 2 -type l -lname "${SCRIPT_DIR}/*" ! -exec test -e {} \; -delete 2>/dev/null || true

# 場所ごとにアカウント(gh / claude / aws の設定)を切り替えるラッパー。
# ~/.local/profile-bin は実体ディレクトリとして作り、本体とコマンドごとの後処理(_ で始まる
# ファイル)だけをリポジトリへリンクする。包むコマンドは本体への相対リンクにするので、
# リポジトリの中にはリンクを作らない。
PROFILE_BIN_SRC="${SCRIPT_DIR}/.local/profile-bin"
if [ -f "$PROFILE_BIN_SRC/_profile-wrapper" ]; then
  mkdir -p "$HOME/.local/profile-bin"
  for f in "$PROFILE_BIN_SRC"/_*; do
    [ -f "$f" ] && ln -fnsv "$f" "$HOME/.local/profile-bin/$(basename "$f")"
  done
  while IFS= read -r tool; do
    case "$tool" in
      '' | '#'*) continue ;;
    esac
    ln -fnsv _profile-wrapper "$HOME/.local/profile-bin/$tool"
  done < "$PROFILE_BIN_SRC/tools"
fi

echo "End link.sh"
echo "----------------------------------------"
