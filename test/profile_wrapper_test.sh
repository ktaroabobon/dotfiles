#!/usr/bin/env bash
# .bin/darwin/.local/profile-bin/_profile-wrapper の振る舞いを検証する。
#
# ラッパーは /bin/sh で動く。macOS の /bin/sh は bash 3.2 で、新しいシェルでは通る書き方
# ($( ) の中の case など) で構文エラーになったことがあるため、CI の macOS で必ず回す。
# 一時的な HOME に git の includeIf と偽のコマンドを置き、実行した場所ごとに
# 本物のコマンドへ渡る環境変数を確かめる。

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WRAPPER="$REPO_ROOT/.bin/darwin/.local/profile-bin/_profile-wrapper"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
home="$work/home"
real_bin="$work/real-bin"
profile_bin="$home/.local/profile-bin"
# ~/workspace をシンボリックリンクにして、境目のパスと実行した場所(pwd -P)の
# 書き方が違っても一致することを確かめる(macOS の一時ディレクトリも /private/var へのリンク)
mkdir -p "$home/.config/git" "$profile_bin" "$real_bin" \
  "$work/real-workspace/work/repo" "$work/real-workspace/personal/repo"
ln -s "$work/real-workspace" "$home/workspace"

cat > "$home/.gitconfig" <<'EOF'
[include]
	path = ~/.config/git/local
EOF
cat > "$home/.config/git/local" <<'EOF'
[includeIf "gitdir:~/workspace/work/"]
	path = ~/.config/git/config-work
EOF
cat > "$home/.config/git/config-work" <<'EOF'
[profile]
	env = GH_CONFIG_DIR=~/.config/gh-work
	env = AWS_PROFILE=work-dev
EOF
git init -q "$home/workspace/work/repo"
git init -q "$home/workspace/personal/repo"

# 本物の代わりに、受け取った環境変数を出すだけのコマンド
cat > "$real_bin/aws" <<'EOF'
#!/bin/sh
echo "AWS_PROFILE=${AWS_PROFILE:-unset} GH_CONFIG_DIR=${GH_CONFIG_DIR:-unset} args=$*"
EOF
chmod +x "$real_bin/aws"

ln -s "$WRAPPER" "$profile_bin/_profile-wrapper"
ln -s _profile-wrapper "$profile_bin/aws"
ln -s _profile-wrapper "$profile_bin/terraform"

status=0

# expect <説明> <実行する場所(HOME からの相対)> <期待する出力> [env の追加の引数...]
expect() {
  local label="$1" dir="$2" expected="$3"
  shift 3
  local actual
  # ラッパーのディレクトリを PATH に 2 回入れ、自分自身を本物と取り違えないことも見る
  actual=$(cd "$home/$dir" && env -i HOME="$home" \
    PATH="$profile_bin:$real_bin:$profile_bin:/usr/bin:/bin" "$@" "$profile_bin/aws" s3 ls 2>&1)
  if [ "$actual" = "$expected" ]; then
    echo "✅ $label"
  else
    echo "❌ $label"
    echo "   期待: $expected"
    echo "   実際: $actual"
    status=1
  fi
}

h="$home"
expect "境目の下のリポジトリではプロファイルの値を渡す" workspace/work/repo \
  "AWS_PROFILE=work-dev GH_CONFIG_DIR=$h/.config/gh-work args=s3 ls"
expect "境目の下ならリポジトリの外でも渡す" workspace/work \
  "AWS_PROFILE=work-dev GH_CONFIG_DIR=$h/.config/gh-work args=s3 ls"
expect "境目の外では何も渡さない" workspace/personal/repo \
  "AWS_PROFILE=unset GH_CONFIG_DIR=unset args=s3 ls"
expect "前回このラッパーが設定した値は、境目の外では消す" workspace/personal/repo \
  "AWS_PROFILE=unset GH_CONFIG_DIR=unset args=s3 ls" \
  AWS_PROFILE=work-dev _PROFILE_SET_AWS_PROFILE=work-dev
expect "利用者が明示した値は、境目の下でも上書きしない" workspace/work/repo \
  "AWS_PROFILE=work-stg GH_CONFIG_DIR=$h/.config/gh-work args=s3 ls" \
  AWS_PROFILE=work-stg _PROFILE_SET_AWS_PROFILE=work-dev
expect "利用者が明示した値は、境目の外でも消さない" workspace/personal/repo \
  "AWS_PROFILE=other GH_CONFIG_DIR=unset args=s3 ls" \
  AWS_PROFILE=other

actual=$(cd "$home" && env -i HOME="$home" PATH="$profile_bin:/usr/bin:/bin" "$profile_bin/terraform" 2>&1)
code=$?
if [ "$code" -eq 127 ] && [[ "$actual" == *"本物の terraform が PATH に見つからない"* ]]; then
  echo "✅ 本物が無いときは 127 で止まる"
else
  echo "❌ 本物が無いときは 127 で止まる (exit=$code: $actual)"
  status=1
fi

exit $status
