# ----------------------------------------------------------------
# home-infra control CLI (`hictl`) — Windows 用
# ----------------------------------------------------------------
# home-infra の常駐ホストは同じ PC の WSL2 (Ubuntu) 側なので、tailnet を経由せず
# wsl.exe で直接叩く。Windows を tailnet ノードにすると同一 PC が 2 ノードになり
# 名前と経路が混乱するため、そちらには参加させない前提。
#
# 環境変数で上書きできる:
#   HOME_INFRA_DISTRO  WSL のディストロ名（既定 Ubuntu-24.04）
#   HOME_INFRA_REPO    WSL2 上のリポジトリパス（既定 ~/workspace/home-infra）
#
# 配置: PowerShell プロファイル（$PROFILE）から dot-source する。
#   . "$HOME\workspace\dotfiles\.bin\windows\hictl.ps1"
# ----------------------------------------------------------------

function hictl {
    $distro = if ($env:HOME_INFRA_DISTRO) { $env:HOME_INFRA_DISTRO } else { 'Ubuntu-24.04' }
    $repo   = if ($env:HOME_INFRA_REPO)   { $env:HOME_INFRA_REPO }   else { '$HOME/workspace/home-infra' }

    # 引数は WSL 側の shell で再解釈されるため、単一引用符で括って安全に渡す
    $quoted = ($args | ForEach-Object { "'" + ($_ -replace "'", "'\''") + "'" }) -join ' '

    # 非対話の WSL セッションでは mise activate が効かず bun が PATH に居ないため、
    # mise を絶対パスで解決する（詳細は home-infra の wsl2-host-setup.md 7 節）
    $cmd = "cd $repo && `$HOME/.local/bin/mise exec -- ./bin/hictl $quoted"
    wsl.exe -d $distro -e bash -lc $cmd
}
