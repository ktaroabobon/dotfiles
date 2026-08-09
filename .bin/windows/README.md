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
