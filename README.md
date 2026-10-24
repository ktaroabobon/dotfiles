# dotfiles

## 概要

このリポジトリは私の dotfiles を含んでいます。

## 要件

- macOS バージョン 11.0 以降
- Ubuntu 24.04（WSL2 での利用を想定）

## インストール

このリポジトリをダウンロードします：

```sh
cd ~ && git clone https://github.com/ktaroabobon/dotfiles.git
```

### macOS

#### 1. 自動セットアップ

```sh
cd dotfiles 
make all
```

`make all` は以下の順序で自動的に実行されます：

1. **初期化** (`make init`): 基本的なセットアップ
2. **Homebrew** (`make brew`): パッケージマネージャーとアプリケーションのインストール
3. **リンク** (`make link`): 設定ファイルのシンボリックリンク作成
4. **oh-my-zsh プラグイン** (`make omz-plugins`): `.zshrc` の `plugins=()` が参照するカスタムプラグインを配置
5. **システム設定** (`make defaults`): macOS の各種設定
6. **Cobalt2** (`make cobalt2`): テーマと Powerline フォントのインストール

#### 2. 自動セットアップ後の手動設定

##### 2.1 ターミナルの再起動

```sh
# 新しいターミナルを開くか、以下のコマンドを実行
source ~/.zshrc
```

##### 2.2 iTerm2 の設定

**カラーテーマの設定:**

1. iTerm2 を起動
2. `環境設定` を開く (Cmd+,)
3. `プロファイル` → `カラー` タブを選択
4. `カラープリセット` → `インポート...` をクリック
5. `~/Downloads/cobalt2.itermcolors` ファイルを選択してインポート
6. インポート後、`cobalt2` を選択

**プロファイル設定の適用:**

1. `プロファイル` → `その他の操作` → `JSON プロファイルをインポート...` をクリック
2. dotfiles フォルダ内の `ktaroabobon-default.json` を選択してインポート
3. インポートされたプロファイルを選択

**フォント設定:**

1. `プロファイル` → `テキスト` タブを選択
2. `フォント` セクションで以下を設定:
   - `標準フォント`: `Inconsolata for Powerline` を選択
   - `非 ASCII フォント`: `Inconsolata for Powerline` を選択
3. 必要に応じて `合字を使用` にチェック

##### 2.3 Claude Code 設定

`make link`（または `make all`）実行時に、`.bin/darwin/.claude/` 配下の管理対象ファイルが `$HOME/.claude/` に個別シンボリックリンクとして配置されます。

- `CLAUDE.md` / `RTK.md` / `settings.json` / `keybindings.json`
- `commands/`（ユーザー定義スラッシュコマンド）
- `hooks/`（RTK rewrite hook など）
- `skills/`（Kiro 系スキル、`create-issue` などのユーザースキル）

`$HOME/.claude/` ディレクトリ自体は実体のまま残り、`sessions/` や `projects/`、`history.jsonl` などの動的データはリポジトリの管理対象外です。

##### 2.4 Codex 設定

`make link` 実行時に、`.bin/darwin/.codex/` 配下の管理対象ファイルが `$HOME/.codex/` に個別シンボリックリンクとして配置されます。

- `config.toml`（モデル/承認/プロジェクト trust_level 等の設定）
- `rules/default.rules`（承認ルール集）

`auth.json` などの認証情報、`sessions/`、`history.jsonl`、`logs_*.sqlite`、`state_*.sqlite`、`automations/` などの動的データやマシン固有データはリポジトリの管理対象外です。

##### 2.5 設定の確認

新しいターミナルを開いて、以下が正しく表示されることを確認:

- Cobalt2 テーマの配色
- Git ブランチ情報の表示
- Powerline フォントの正しい表示

#### 3. Brewfile の反映漏れチェック（週次）

実機に入れたツールを Brewfile に書き忘れると、新しいマシンで `make all` しても再現しません。これを週次で検出します。

```sh
# 実機に入っていて Brewfile に無いものを表示する
make brew-drift
```

差分があれば draft PR を作れます。

```sh
make brew-drift-pr
```

毎週月曜 10:00 に自動でチェックして PR を作るには、launchd に登録します。

```sh
make brew-drift-install     # 登録
make brew-drift-status      # 登録状態の確認
make brew-drift-uninstall   # 解除
```

- plist にはリポジトリの実パスを焼き込むため、**本体のリポジトリで実行してください**（git worktree からの登録は弾かれます）
- 指定時刻に Mac がスリープ/電源オフでも、次に起動したときに実行されます
- ログは `~/Library/Logs/brew-drift.log`
- 前回の PR が未マージのときは、重ねて作らずスキップします
- 管理対象にしたくないものは [.bin/darwin/brew_drift_ignore.txt](.bin/darwin/brew_drift_ignore.txt) に追加すると次回から検出されません（Apple 純正アプリは登録済み）

検出は `brew bundle dump` と Brewfile の突き合わせで行うため、tap 付きのパッケージは Brewfile 側も `cask "stablyai/orca/orca"` のようにフルネームで書いてください。

#### 4. Claude デスクトップアプリを複数アカウントで使う

Claude デスクトップアプリは、1 つのデータフォルダに 1 つのログイン状態しか保持しません。ランチャーは起動時に `--user-data-dir` でデータフォルダを分けるので、別のアカウントでログインしたアプリを同時に開けます。この方法は Anthropic が提供している機能ではないため、アプリの更新で使えなくなる可能性があります。

```sh
make claude-launcher
```

- `~/Applications/Claude Launcher.app` が作られます。起動すると、どのアカウントで開くかを選ぶ画面が出ます。起動中のアカウントには「(起動中)」と表示されます。
- 選んだアカウントのアプリがすでに起動していれば、新しく起動せずにそのウィンドウを前面に出します。初回はこの操作のために「System Events」の操作の許可を求められるので、許可してください。
- アカウントの追加・編集・削除は、選択画面の右上の歯車から開く設定画面で行います。右上の「+」で追加し、「−」で選んだアカウントを一覧から外し、行のダブルクリックで編集します。一覧から外しても、データフォルダと会話履歴は削除されません。
- ランチャーのアイコンは、インストール済みの `/Applications/Claude.app` から作成時と起動時に読み込みます。このリポジトリには Claude のアイコンを含めていません。

アカウントごとに設定する項目は次の 4 つです。空欄の項目は既定の場所を使います。

| 項目 | 内容 | 空欄のとき |
| --- | --- | --- |
| 表示名 | 選択画面のボタンに出る名前です。 | 空欄にはできません。 |
| データフォルダ名 | ログイン状態の保存先です。`~/Library/Application Support/` の下の名前を書きます。 | `Claude` を使います。 |
| 会話履歴のフォルダ | Code タブの会話履歴と設定の保存先です。`CLAUDE_CONFIG_DIR` として渡します。 | `~/.claude` を使います。 |
| GitHub CLI の設定フォルダ | Code タブから実行する `gh` の認証情報の保存先です。`GH_CONFIG_DIR` として渡します。 | `~/.config/gh` を使います。 |

- アカウントの一覧は `~/Library/Application Support/Claude Launcher/accounts.plist` に保存されます。アカウント名やフォルダをこのリポジトリに含めないため、手元だけに置いています。
- 会話履歴のフォルダは、ターミナルで `claude` を実行するときの `CLAUDE_CONFIG_DIR` と同じ場所にしてください。違う場所にすると、ターミナルで始めた会話をデスクトップアプリで開けません。
- Dock から起動したアプリはシェルの環境変数を引き継ぎません。そのため、会話履歴などの場所はランチャーが起動時に明示的に渡します。設定の変更は、そのアカウントのアプリを次に起動したときから適用されます。
- 2 つのアプリで同じアカウントにログインしないでください。Projects が読み込めなくなったという報告があります。

#### 5. 個別実行（トラブルシューティング用）

必要に応じて、個別のコマンドを実行できます：

```sh
# 初期化のみ
make init

# Homebrew のみ
make brew

# リンクのみ
make link

# システム設定のみ（Cobalt2 テーマ含む）
make defaults
```

#### 5. MX Ergo Sの左右チルトをログイン後に復旧

`KeitaronoMacBook-Pro`では、ログイン直後にMosがLogitech HID++のボタン入力を受け取れず、MX Ergo Sの左右チルトが効かない場合があります。次のコマンドで、ログイン後にMosを再起動して設定画面をバックグラウンド表示するLaunchAgentを登録できます。

```sh
make mos-refresh-install
```

```sh
make mos-refresh-status      # 登録状態を確認
make mos-refresh-uninstall   # 登録を解除
```

実行スクリプト自身もLocalHostNameを確認するため、ほかのMacでは動作しません。ログは`~/Library/Logs/mos-startup-refresh.log`に出力されます。

### Ubuntu / WSL2

#### 1. 自動セットアップ

```sh
cd dotfiles
make all-ubuntu
```

`make all-ubuntu` は以下の順序で実行されます：

1. **初期化** (`make init`): apt パッケージ、zsh、oh-my-zsh（agnoster テーマ）のセットアップ
2. **リンク** (`make link-ubuntu`): 共有スクリプト（`hictl`）を `~/.zsh` に配置し、`.zshrc` / `.bashrc` から source

macOS 側の `make link` と違い、シェルの rc 自体は管理対象にしていません（既存環境を壊さないため）。

#### 2. Tailscale（tailnet の常駐ホストにする場合）

```sh
make tailscale-ubuntu
```

tailnet への参加（`tailscale up`）は認証が要るため手動です。スクリプトの出力に手順が表示されます。

#### 3. デスクトップ環境

GNOME テーマや snap アプリの設定は [こちら](.bin/ubuntu/README.md) を参照してください。WSL2 では不要です。
