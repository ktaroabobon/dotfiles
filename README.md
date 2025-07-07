# dotfiles

## 概要

このリポジトリは私の dotfiles を含んでいます。

## 要件

- macOS バージョン 11.0 以降
- Ubuntu バージョン 22.04

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

##### 2.3 設定の確認

新しいターミナルを開いて、以下が正しく表示されることを確認:

- Cobalt2 テーマの配色
- Git ブランチ情報の表示
- Powerline フォントの正しい表示

#### 3. 個別実行（トラブルシューティング用）

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

### Ubuntu

Ubuntu 用のセットアップ：

```sh
cd dofiles
.bin/init.sh
```

次のステップは [こちら](.bin/ubuntu/README.md) を参照してください。
