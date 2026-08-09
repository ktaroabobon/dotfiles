# ----------------------------------------------------------------
# home-infra control CLI (`hictl`) をどのマシンからでも叩く
# ----------------------------------------------------------------
# home-infra の常駐ホストは WSL2 (Ubuntu) 側。`hictl` は「家のシステムを操作する」
# 意味に統一してあり、どこで叩いても実行されるのは常駐ホストの hictl になる。
#
#   - 常駐ホスト自身   : ローカルの bin/hictl をそのまま実行する
#   - tailnet の他マシン: Tailscale SSH で常駐ホストに入って実行する
#
# リポジトリ内で開発用に「そのチェックアウトの hictl」を叩きたいときは、
# この関数を経由しない `./bin/hictl ...` を使う（相対パス指定なので衝突しない）。
#
# 環境変数で上書きできる:
#   HOME_INFRA_HOST  常駐ホストの MagicDNS 名 / hostname（既定 ktarowin10）
#   HOME_INFRA_REPO  常駐ホスト上のリポジトリパス（既定 ~/workspace/home-infra）
# ----------------------------------------------------------------

function hictl() {
  local host="${HOME_INFRA_HOST:-ktarowin10}"
  local repo="${HOME_INFRA_REPO:-\$HOME/workspace/home-infra}"

  # 常駐ホスト自身なら SSH を挟まない
  if [ "$(hostname -s 2>/dev/null)" = "$host" ]; then
    local local_repo="${HOME_INFRA_REPO:-$HOME/workspace/home-infra}"
    if [ ! -x "$local_repo/bin/hictl" ]; then
      echo "hictl: $local_repo/bin/hictl が見つかりません（HOME_INFRA_REPO で上書きできます）" >&2
      return 1
    fi
    # mise があれば通す。非対話シェルでは mise activate が効かず bun が PATH に
    # 居ないため、絶対パスで解決する（詳細は home-infra の wsl2-host-setup.md 7 節）
    if [ -x "$HOME/.local/bin/mise" ]; then
      ( cd "$local_repo" && "$HOME/.local/bin/mise" exec -- ./bin/hictl "$@" )
    else
      ( cd "$local_repo" && ./bin/hictl "$@" )
    fi
    return $?
  fi

  if ! command -v ssh >/dev/null 2>&1; then
    echo "hictl: ssh が見つかりません" >&2
    return 1
  fi

  # 引数を安全に渡す（リモート側のシェルで再解釈されるため個別にクォートする）
  local quoted=""
  local a
  for a in "$@"; do
    quoted="$quoted $(printf '%q' "$a")"
  done

  # attach など TTY が要る操作のために、手元が端末のときだけ -t を付ける
  local tty_opt=""
  [ -t 1 ] && tty_opt="-t"

  # shellcheck disable=SC2086
  ssh $tty_opt "$host" "cd $repo && \$HOME/.local/bin/mise exec -- ./bin/hictl$quoted"
}
