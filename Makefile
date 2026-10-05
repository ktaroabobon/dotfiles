.PHONY: help
help:
	@echo "使い方: make [ターゲット]"
	@echo ""
	@echo "利用可能なターゲット:"
	@echo "  all       : 初期化、brew、link、defaults、cobalt2 の順で実行します。(macOS)"
	@echo "  all-ubuntu : 初期化と link-ubuntu を実行します。(Ubuntu / WSL2)"
	@echo "  init      : 初期化スクリプトを実行します。"
	@echo "  brew      : brew スクリプトを実行します。"
	@echo "  link      : link スクリプトを実行します。(macOS)"
	@echo "  link-ubuntu : Ubuntu / WSL2 向けのリンクを実行します。"
	@echo "  tailscale-ubuntu : Tailscale を導入します。(Ubuntu / WSL2)"
	@echo "  omz-plugins : oh-my-zsh のカスタムプラグインを配置します。(macOS)"
	@echo "  defaults  : defaults スクリプトを実行します。"
	@echo "  cobalt2   : cobalt2 テーマのセットアップを実行します。"
	@echo "  ssh-key   : ed25519 鍵を生成し、公開鍵をクリップボードにコピーします。"
	@echo "  zoom-bg   : Zoom バーチャル背景画像を一括ダウンロードします。"
	@echo "  brew-drift : 実機に入っていて Brewfile に無いものを表示します。(macOS)"
	@echo "  brew-drift-pr : 上記の差分から draft PR を作ります。(macOS)"
	@echo "  brew-drift-install : 週次チェックを launchd に登録します。(macOS)"
	@echo "  mos-refresh-install : Mos の Logitech HID++ 接続復旧をログイン時に実行します。(対象Macのみ)"
	@echo ""
	@echo "注意事項:"
	@echo "  - ターゲットを指定しない場合、help ターゲットが実行されます。"
	@echo "  - ターゲットは、make コマンドの引数として指定します。"
	@echo "  - ターゲットの実行順序は、Makefile 内で定義された順序に従います。"
	@echo "  - ターゲットは、.PHONY ターゲットとして定義する必要があります。"
	@echo "  - ターゲットの実行時には、対応するスクリプトが実行されます。"
	@echo "  - ターゲットの実行時には、依存関係のあるターゲットも実行されます。"
	@echo ""
	@echo "例:"
	@echo "  make all       : 初期化、brew、link、defaults、cobalt2 の順で実行します。"
	@echo "  make init      : 初期化スクリプトを実行します。"
	@echo "  make brew      : brew スクリプトを実行します。"
	@echo "  make link      : link スクリプトを実行します。"
	@echo "  make defaults  : defaults スクリプトを実行します。"
	@echo "  make cobalt2   : cobalt2 テーマのセットアップを実行します。"
	@echo "  make ssh-key   : ed25519 鍵を生成し、公開鍵をクリップボードにコピーします。"
	@echo "  make zoom-bg   : Zoom バーチャル背景画像を一括ダウンロードします。"

.PHONY: all
all:
	$(MAKE) init
	$(MAKE) brew
	$(MAKE) link
	$(MAKE) omz-plugins
	$(MAKE) defaults
	$(MAKE) cobalt2

# Ubuntu / WSL2 向けの一括セットアップ。GUI (defaults) と snap は WSL2 では
# 使わないため含めない。
.PHONY: all-ubuntu
all-ubuntu:
	$(MAKE) init
	$(MAKE) link-ubuntu

.PHONY: init
init:
	.bin/init.sh

.PHONY: brew
brew:
	.bin/darwin/brew.sh

.PHONY: link
link:
	.bin/darwin/link.sh

.PHONY: link-ubuntu
link-ubuntu:
	.bin/ubuntu/link.sh

# Tailscale を公式 apt リポジトリから導入する (Ubuntu / WSL2)
.PHONY: tailscale-ubuntu
tailscale-ubuntu:
	.bin/ubuntu/tailscale.sh

# .zshrc の plugins=() が参照する oh-my-zsh のカスタムプラグインを配置する
.PHONY: omz-plugins
omz-plugins:
	.bin/darwin/omz_plugins.sh

.PHONY: defaults
defaults:
	.bin/darwin/defaults.sh

.PHONY: cobalt2
cobalt2:
	.bin/darwin/cobalt2.sh

# ed25519 鍵を生成し、公開鍵をクリップボードへコピーする
.PHONY: ssh-key
ssh-key:
	.bin/darwin/ssh_keygen.sh

# Zoom バーチャル背景画像を .bin/darwin/zoom_backgrounds.txt の URL から一括ダウンロードする
.PHONY: zoom-bg
zoom-bg:
	.bin/darwin/zoom_backgrounds.sh

# ------------------------------------------------------------------------------
# Brewfile の反映漏れチェック (macOS)
# 実機の状態を見る必要があるため CI では回せない。週次実行は launchd に任せる。

# 実機に入っていて Brewfile に無いものを表示する（差分があれば exit 1）
.PHONY: brew-drift
brew-drift:
	.bin/darwin/brew_drift.sh

# 差分があればブランチを切って draft PR を作る
.PHONY: brew-drift-pr
brew-drift-pr:
	.bin/darwin/brew_drift.sh --pr

# 週次チェック（毎週月曜 10:00）を launchd に登録する
.PHONY: brew-drift-install
brew-drift-install:
	.bin/darwin/brew_drift_launchd.sh install

# 週次チェックの登録を解除する
.PHONY: brew-drift-uninstall
brew-drift-uninstall:
	.bin/darwin/brew_drift_launchd.sh uninstall

# 週次チェックの登録状態を表示する
.PHONY: brew-drift-status
brew-drift-status:
	.bin/darwin/brew_drift_launchd.sh status

# ------------------------------------------------------------------------------
# Mos / MX Ergo S のログイン後 HID++ 接続復旧（対象Macのみ）

.PHONY: mos-refresh-install
mos-refresh-install:
	.bin/darwin/mos_startup_refresh_launchd.sh install

.PHONY: mos-refresh-uninstall
mos-refresh-uninstall:
	.bin/darwin/mos_startup_refresh_launchd.sh uninstall

.PHONY: mos-refresh-status
mos-refresh-status:
	.bin/darwin/mos_startup_refresh_launchd.sh status

# ------------------------------------------------------------------------------
# Test environment related commands and comments

# build test environment
.PHONY: build
build:
	docker compose up -d --build

# login to test environment
.PHONY: login
login:
	$(MAKE) login/ubuntu

# ubuntuコンテナにubuntuユーザーでログイン
.PHONY: login/ubuntu
login/ubuntu:
	docker compose exec ubuntu sh -c 'if command -v zsh > /dev/null 2>&1; then exec zsh; else exec bash; fi'

# down test environment
.PHONY: down
down:
	docker compose down

# 環境をリビルドする
.PHONY: rebuild
rebuild:
	$(MAKE) down
	$(MAKE) build

# init.shのテスト（test/test_init.sh）を実行する
.PHONY: test/init
test/init:
	docker compose exec -T ubuntu sh -c 'test/test_init.sh'
