# 対話しないシェル(Claude Code の Bash ツールやスクリプト)からも、場所ごとにアカウントを
# 切り替えるラッパーが本物のコマンドより先に見つかるようにする
export PATH="$HOME/.local/profile-bin:$HOME/.local/bin:$PATH"
