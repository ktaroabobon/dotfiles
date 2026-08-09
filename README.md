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
4. **システム設定** (`make defaults`): macOS の各種設定 + Cobalt2 テーマの自動インストール

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

#### 4. 個別実行（トラブルシューティング用）

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
