#!/usr/bin/env bash
# 実機の Homebrew の状態と Brewfile を突き合わせ、反映漏れを検出する。
#
#   brew_drift.sh          差分を表示する（差分があれば終了コード 1）
#   brew_drift.sh --pr     差分があればブランチを切って draft PR を作る
#
# 実機を見ないと分からないため CI では回せない。週次実行は launchd に任せる
# (make brew-drift-install)。
#
# 「実機にあるが Brewfile に無い」方向だけを見る。逆方向（Brewfile にあるが
# 実機に無い）は、その時点で入れていないだけのこともあり自動判断できないため
# 対象にしない。

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
BREWFILE="$SCRIPT_DIR/Brewfile"
IGNORE_FILE="$SCRIPT_DIR/brew_drift_ignore.txt"

MODE="check"
if [ "${1:-}" = "--pr" ]; then
  MODE="pr"
elif [ -n "${1:-}" ]; then
  echo "usage: ${0##*/} [--pr]" >&2
  exit 2
fi

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

# Brewfile / dump の行から「種別 と キー」を取り出す。
# mas はアプリ名が変わることがあるので id をキーにする。
extract_keys() {
  awk '
    /^tap "/  { k = $0; sub(/^tap "/,  "", k); sub(/".*/, "", k); print "tap\t"  k; next }
    /^brew "/ { k = $0; sub(/^brew "/, "", k); sub(/".*/, "", k); print "brew\t" k; next }
    /^cask "/ { k = $0; sub(/^cask "/, "", k); sub(/".*/, "", k); print "cask\t" k; next }
    /^mas /   { k = $0; sub(/.*id:[[:space:]]*/, "", k); sub(/[^0-9].*/, "", k); print "mas\t" k; next }
  ' "$1" | sort -u
}

# 無視リスト（"種別:キー" 形式、# 以降はコメント）
ignored_keys() {
  [ -f "$IGNORE_FILE" ] || return 0
  sed 's/#.*//' "$IGNORE_FILE" | tr -d '[:blank:]' | grep -v '^$' | tr ':' '\t' | sort -u
}

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

current="$tmpdir/current.Brewfile"
# npm / vscode / cargo なども dump できるが、今の Brewfile の管理範囲に合わせる
brew bundle dump --file=- --formula --cask --tap --mas > "$current"

extract_keys "$current" > "$tmpdir/current.keys"
extract_keys "$BREWFILE" > "$tmpdir/brewfile.keys"
ignored_keys > "$tmpdir/ignored.keys" || true

# 実機にあって Brewfile に無いもの、から無視リストを引く
comm -23 "$tmpdir/current.keys" "$tmpdir/brewfile.keys" > "$tmpdir/missing.raw"
comm -23 "$tmpdir/missing.raw" "$tmpdir/ignored.keys" > "$tmpdir/missing.keys"

if [ ! -s "$tmpdir/missing.keys" ]; then
  echo "✅ Brewfile は実機の状態に追いついています"
  exit 0
fi

count=$(wc -l < "$tmpdir/missing.keys" | tr -d ' ')
echo "⚠️  Brewfile に反映されていないものが ${count} 件あります"
echo

# 表示と、Brewfile に足す行の組み立て。
# dump の出力から元の行をそのまま持ってくる（説明コメントは落とす）。
: > "$tmpdir/additions"
while IFS=$'\t' read -r kind key; do
  case "$kind" in
    tap)  line="tap \"$key\"" ;;
    brew) line="brew \"$key\"" ;;
    cask) line="cask \"$key\"" ;;
    mas)
      # dump の行をそのまま使う（アプリ名を保つため）
      line=$(grep -E "^mas .*id:[[:space:]]*${key}\$" "$current" | head -1)
      [ -n "$line" ] || line="mas id: $key"
      ;;
    *) continue ;;
  esac
  echo "  $line"
  echo "$line" >> "$tmpdir/additions"
done < "$tmpdir/missing.keys"

if [ "$MODE" = "check" ]; then
  echo
  echo "PR を作るには: make brew-drift-pr"
  exit 1
fi

# ---- ここから --pr モード ----

echo
echo "=== PR を作成します ==="

if ! command -v gh > /dev/null 2>&1; then
  echo "❌ gh が見つかりません" >&2
  exit 1
fi

cd "$REPO_ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "❌ 作業ツリーに変更があります。コミットするか退避してから実行してください" >&2
  git status --short >&2
  exit 1
fi

# 前回分が未マージなら重ねて作らない
existing=$(gh pr list --state open --search "head:chore/brew-drift" --json number,headRefName \
  --jq '.[] | "\(.number) \(.headRefName)"' 2>/dev/null || true)
if [ -n "$existing" ]; then
  echo "⏭  未マージの反映漏れ PR があるためスキップします:"
  echo "$existing"
  exit 0
fi

stamp=$(date +%Y%m%d)
branch="chore/brew-drift-${stamp}"

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo "⏭  ブランチ ${branch} が既にあるためスキップします"
  exit 0
fi

original_branch=$(git branch --show-current)
git fetch --quiet origin main
git switch --quiet -c "$branch" origin/main

{
  echo ""
  echo "# ---- 反映漏れ（$(date +%F) の自動検出）----"
  echo "# make brew-drift が実機との差分として拾ったもの。"
  echo "# 上のカテゴリへの振り分けと、そもそも管理対象にするかの判断は手動で行う。"
  echo "# 管理したくないものは .bin/darwin/brew_drift_ignore.txt に足すと次回から出ない。"
  cat "$tmpdir/additions"
} >> "$BREWFILE"

git add "$BREWFILE"
git commit --quiet -m "chore(darwin): 実機との差分 ${count} 件を Brewfile に取り込む

make brew-drift が検出した反映漏れを自動で追記したもの。
カテゴリへの振り分けと要否の判断はレビューで行う。
管理対象外にしたいものは .bin/darwin/brew_drift_ignore.txt に追加する。"

git push --quiet -u origin "$branch"

pr_url=$(gh pr create --draft --base main --head "$branch" \
  --title "chore(darwin): Brewfile の反映漏れ ${count} 件（${stamp}）" \
  --body "$(printf '%s\n' \
    "週次の反映漏れチェック (\`make brew-drift\`) が、実機にあって Brewfile に無いものを ${count} 件検出しました。" \
    "" \
    "\`\`\`" \
    "$(cat "$tmpdir/additions")" \
    "\`\`\`" \
    "" \
    "## レビューでお願いしたいこと" \
    "" \
    "- 管理対象にするか（試しに入れただけのものは外す）" \
    "- Brewfile 内の適切なカテゴリへの振り分け" \
    "- 今後も無視してよいものは \`.bin/darwin/brew_drift_ignore.txt\` に追加する" \
    "" \
    "検出は \`brew bundle dump --formula --cask --tap --mas\` と Brewfile の突き合わせによるものです。")")

echo "✅ $pr_url"

git switch --quiet "$original_branch"
