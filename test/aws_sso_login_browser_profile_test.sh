#!/usr/bin/env bash
# .bin/darwin/.local/profile-bin/_aws-sso-login-browser-profile の振り分けを検証する。
#
# 本物の aws / osascript / open の代わりに、受け取った引数を記録するだけのコマンドを置き、
# aws sso login のときだけ --no-browser を付けて、出てきた URL を対応表の Dia のプロファイルで
# 開こうとすることを確かめる。フックは /bin/sh で動くので、CI の macOS(bash 3.2)で必ず回す。

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HOOK="$REPO_ROOT/.bin/darwin/.local/profile-bin/_aws-sso-login-browser-profile"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bin="$work/bin"
log="$work/log"
mkdir -p "$bin" "$work/.aws" "$work/.config"

cat > "$work/.aws/config" <<'EOF'
[profile work]
sso_session = work-sso
sso_account_id = 111111111111
sso_role_name = Admin

[sso-session work-sso]
sso_start_url = https://d-work.awsapps.com/start
sso_region = ap-northeast-1

[profile legacy]
sso_start_url = https://d-legacy.awsapps.com/start/
sso_region = ap-northeast-1

[profile unmapped]
sso_start_url = https://d-other.awsapps.com/start/
sso_region = ap-northeast-1
EOF
cat > "$work/.config/aws-sso-login-browser-profile" <<'EOF'
# 入口の URL に含まれる文字列  Dia のプロファイル名
d-work    Work
d-legacy  Home Infra
EOF

# FAKE_AWS_OUTPUT の各行を stderr に出し、FAKE_AWS_STATUS で終わる
cat > "$bin/aws" <<'EOF'
#!/bin/sh
echo "aws $*" >> "$LOG"
printf '%b' "${FAKE_AWS_OUTPUT:-}" >&2
exit "${FAKE_AWS_STATUS:-0}"
EOF
cat > "$bin/osascript" <<'EOF'
#!/bin/sh
cat > /dev/null
shift
echo "osascript $*" >> "$LOG"
exit "${FAKE_OSASCRIPT_STATUS:-0}"
EOF
cat > "$bin/open" <<'EOF'
#!/bin/sh
echo "open $*" >> "$LOG"
EOF
chmod +x "$bin"/*

status=0

# run <aws の終了コードの期待値> [env の追加の引数...] -- <aws の引数...>
run() {
  local expected_status="$1"
  shift
  local envs=()
  while [ "$1" != -- ]; do
    envs+=("$1")
    shift
  done
  shift
  : > "$log"
  env -i HOME="$work" PATH="$bin:/usr/bin:/bin" LOG="$log" \
    AWS_CONFIG_FILE="$work/.aws/config" AWS_SSO_LOGIN_BROWSER_PROFILE_MAP="$work/.config/aws-sso-login-browser-profile" \
    "${envs[@]}" "$HOOK" "$bin/aws" "$@" > "$work/out" 2>&1
  local code=$?
  if [ "$code" -ne "$expected_status" ]; then
    echo "   終了コード: 期待 $expected_status / 実際 $code"
    return 1
  fi
}

# expect <説明> <期待する記録(改行区切り)>
expect_log() {
  local label="$1" expected="$2" actual
  actual=$(cat "$log")
  if [ "$actual" = "$expected" ]; then
    echo "✅ $label"
  else
    echo "❌ $label"
    echo "   期待:"
    printf '%s\n' "$expected" | sed 's/^/     /'
    echo "   実際:"
    printf '%s\n' "$actual" | sed 's/^/     /'
    echo "   出力:"
    sed 's/^/     /' "$work/out"
    status=1
  fi
}

authorize='https://oidc.ap-northeast-1.amazonaws.com/authorize?response_type=code&client_id=abc'
pkce_output="Browser will not be automatically opened.\nPlease visit the following URL:\n\n$authorize\n\nSuccessfully logged into Start URL: https://d-work.awsapps.com/start\n"
device_output="Browser will not be automatically opened.\nPlease visit the following URL:\n\nhttps://device.sso.ap-northeast-1.amazonaws.com/\n\nThen enter the code:\n\nABCD-EFGH\n"

run 0 -- s3 ls || status=1
expect_log "sso login 以外はそのまま渡す" "aws s3 ls"

run 0 FAKE_AWS_OUTPUT="$pkce_output" -- sso login --profile work || status=1
expect_log "--profile のプロファイルの組織の Dia のプロファイルで開く" \
  "aws sso login --profile work --no-browser
osascript Work $authorize"

run 0 AWS_PROFILE=work FAKE_AWS_OUTPUT="$pkce_output" -- sso login || status=1
expect_log "AWS_PROFILE のプロファイルでも振り分ける" \
  "aws sso login --no-browser
osascript Work $authorize"

run 0 FAKE_AWS_OUTPUT="$pkce_output" -- sso login --sso-session work-sso || status=1
expect_log "--sso-session でも振り分ける" \
  "aws sso login --sso-session work-sso --no-browser
osascript Work $authorize"

run 0 FAKE_AWS_OUTPUT="$device_output" -- sso login --profile legacy || status=1
expect_log "デバイスコードの方式はコード入りの URL を、空白を含む名前のプロファイルで開く" \
  "aws sso login --profile legacy --no-browser
osascript Home Infra https://device.sso.ap-northeast-1.amazonaws.com/?user_code=ABCD-EFGH"

run 0 FAKE_AWS_OUTPUT="$pkce_output" -- sso login --profile unmapped || status=1
expect_log "対応表に無い組織は aws に任せる" "aws sso login --profile unmapped"

run 0 -- sso login --profile work --no-browser || status=1
expect_log "利用者が --no-browser を付けたら何もしない" "aws sso login --profile work --no-browser"

run 0 FAKE_AWS_OUTPUT="$pkce_output" FAKE_OSASCRIPT_STATUS=1 -- sso login --profile work || status=1
expect_log "Dia で開けないときは既定のブラウザで開く" \
  "aws sso login --profile work --no-browser
osascript Work $authorize
open $authorize"

run 3 FAKE_AWS_OUTPUT="$pkce_output" FAKE_AWS_STATUS=3 -- sso login --profile work || status=1
expect_log "aws の終了コードをそのまま返す" \
  "aws sso login --profile work --no-browser
osascript Work $authorize"

exit $status
