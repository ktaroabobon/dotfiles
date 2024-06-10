.PHONY: help
help:
	@echo "使い方: make [ターゲット]"
	@echo ""
	@echo "利用可能なターゲット:"
	@echo "  all       : 初期化、brew、link の順で実行します。"
	@echo "  init      : 初期化スクリプトを実行します。"
	@echo "  brew      : brew スクリプトを実行します。"
	@echo "  link      : link スクリプトを実行します。"
	@echo "  defaults  : defaults スクリプトを実行します。"
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
	@echo "  make all       : 初期化、brew、link の順で実行します。"
	@echo "  make init      : 初期化スクリプトを実行します。"
	@echo "  make brew      : brew スクリプトを実行します。"
	@echo "  make link      : link スクリプトを実行します。"
	@echo "  make defaults  : defaults スクリプトを実行します。"

.PHONY: all
all:
	$(MAKE) init
	$(MAKE) brew
	$(MAKE) link

.PHONY: init
init:
	.bin/init.sh

.PHONY: brew
brew:
	.bin/brew.sh

.PHONY: link
link:
	.bin/link.sh

.PHONY: defaults
defaults:
	.bin/defaults.sh

# ------------------------------------------------------------------------------
# Test environment related commands and comments

# build test environment
.PHONY: build
build:
	docker-compose up -d --build

# login to test environment
.PHONY: login
login:
	$(MAKE) login/ubuntu

# ubuntuコンテナにubuntuユーザーでログイン
.PHONY: login/ubuntu
login/ubuntu:
	docker-compose exec ubuntu sh -c 'if command -v zsh > /dev/null 2>&1; then exec zsh; else exec bash; fi'

# down test environment
.PHONY: down
down:
	docker-compose down

# 環境をリビルドする
.PHONY: rebuild
rebuild:
	$(MAKE) down
	$(MAKE) build

# init.shのテスト（test/test_init.sh）を実行する
.PHONY: test/init
test/init:
	docker-compose exec ubuntu sh -c '.bin/test/test_init.sh'