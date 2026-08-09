# Windows 用の設定

## `hictl`（home-infra control CLI）

home-infra の常駐ホストは同じ PC の WSL2 (Ubuntu) 側にある。**tailnet を経由せず
`wsl.exe` で直接叩く**ので、Windows を tailnet ノードにする必要はない（同一 PC が
2 ノードになると名前と経路が混乱するため、むしろ参加させない）。

PowerShell プロファイルから dot-source する:

```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
Add-Content $PROFILE "`n. `"$HOME\workspace\dotfiles\.bin\windows\hictl.ps1`""
```

新しい PowerShell を開いて確認する:

```powershell
hictl services ps
```

### 上書きできる環境変数

| 変数 | 既定 | 用途 |
|---|---|---|
| `HOME_INFRA_DISTRO` | `Ubuntu-24.04` | WSL のディストロ名 |
| `HOME_INFRA_REPO` | `$HOME/workspace/home-infra` | WSL2 上のリポジトリパス |

## Tailscale は入れない

**Windows 側に Tailscale をインストールしないこと。**

home-infra の常駐ホストは同じ PC の WSL2 (Ubuntu) 側で、そちらが tailnet ノードになっている。Windows にも入れると **同一 PC が tailnet 上の 2 ノードになり**、`<マシン名>` と `<マシン名>-1` のように名前が割れて経路が混乱する。実際にその状態を踏んで整理した。

Windows から home-infra を操作するのに tailnet は要らない。`hictl` は `wsl.exe` で同じ PC の WSL2 を直接叩くので、Windows が tailnet に居なくても動く。

既に入っている場合は、Tailscale アプリからログアウトする（サービス自体は残っていても、tailnet から抜けていれば実害はない）。

WSL2 側の導入手順は [`.bin/ubuntu/tailscale.sh`](../ubuntu/tailscale.sh) を参照。
