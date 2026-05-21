#!/bin/zsh

set -u

echo "Start ssh_keygen.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS"
  exit 1
fi

KEY_TYPE="ed25519"
KEY_PATH="${HOME}/.ssh/id_${KEY_TYPE}"

# コメント（メールアドレス）の決定: 引数 > git config > USER@HOST
if [ "$#" -ge 1 ] && [ -n "$1" ]; then
  COMMENT="$1"
elif command -v git >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
  COMMENT="$(git config --global user.email)"
fi
COMMENT="${COMMENT:-${USER}@$(hostname)}"

# ~/.ssh を 700 で作成
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [ -f "${KEY_PATH}" ]; then
  echo "既に ${KEY_PATH} が存在するため生成をスキップします"
else
  echo "ssh-keygen -t ${KEY_TYPE} -C \"${COMMENT}\" -f ${KEY_PATH}"
  ssh-keygen -t "${KEY_TYPE}" -C "${COMMENT}" -f "${KEY_PATH}" -N ""
  chmod 600 "${KEY_PATH}"
  chmod 644 "${KEY_PATH}.pub"
fi

# 公開鍵をクリップボードへ
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "${KEY_PATH}.pub"
  echo "公開鍵 (${KEY_PATH}.pub) をクリップボードにコピーしました"
else
  echo "pbcopy が見つからないためクリップボードコピーをスキップしました"
fi

echo "----- 公開鍵 -----"
cat "${KEY_PATH}.pub"
echo "------------------"

echo "End ssh_keygen.sh"
echo "----------------------------------------"
