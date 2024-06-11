# 手動設定手順

このREADMEには、`default.sh`スクリプトの実行後に手動で設定する必要がある手順を記載しています。

## 1. Ulauncherの設定

1. Ulauncherを起動します。
2. メニューバーに表示されるUlauncherのアイコンをクリックして、`Preferences`を選択します。
3. 以下の設定を行います：
    - **Hotkey**: `Ctrl+Super+Space`
      - あなたがSpotlightを起動しているキーボードショートカットに設定します。
    - **Color Theme**: `Elementary Dark`
      - あなたの趣味に応じて設定します。
    - **Launch at Login**にチェックを入れます。

## 2. キーボードショートカットの設定

1. `gnome-control-center`（設定）を起動します。
2. `キーボードショートカット`を選択します。
3. 以下のショートカットを設定します：
    - **フルスクリーンモードを切り替える**：`Ctrl+Super+F`
    - **画面をロック**：`Ctrl+Super+Q`
    - **アプリケーションを切り替える**：`Super+Tab`
    - **ひとつのアプリケーション内のウィンドウを切り替える**：`Super+｀`
      - 全角の｀で表示してありますが、半角で入力してください。
    - **アクティビティ画面を表示する**：`Ctrl+Up`
    - **すべてのアプリケーションを表示**：`Ctrl+Down`
    - **すべての通常のウィンドウを隠す**：`Ctrl+Super+X`
    - **次の入力ソースへ切り替える**：`Ctrl+o`
    - **スクリーンショットをPicturesフォルダーに保存する**：`Shift+Super+#`
    - **スクリーンショットをクリップボードにコピーする**：`Shift+Ctrl+Super+#`
    - **ウィンドウのスクリーンショットをPicturesフォルダーに保存する**：`Shift+Super+$`
    - **ウィンドウのスクリーンショットをクリップボードにコピーする**：`Shift+Ctrl+Super+$`
    - **選択領域のスクリーンショットをPicturesフォルダーに保存する**：`Shift+Super+%`
    - **選択領域のスクリーンショットをクリップボードにコピーする**：`Shift+Ctrl+Super+%`

4. 無効にするショートカットを設定します：
    - **ウィンドウを非表示にする**
    - **アクティブな通知にフォーカスを当てる**
    - **通知リストを表示する**

## 3. GNOMEターミナルの設定

1. `gnome-terminal`（端末）を起動します。
2. ウィンドウを右クリックして出てくるメニューから`設定`を選択します。
3. 以下のショートカットを設定します：
    - **新しいタブを開く**：`Super+T`
    - **新しいウィンドウを開く**：`Super+N`
    - **コピー**：`Super+C`
    - **貼り付け**：`Super+V`

## 4. 日本語入力環境の設定

1. 日本語入力としては既に`iBus+Mozc`が入っていますが、Mozcの入力モード切り替えはキーボードショートカットで上手く操作できないため、起動時から`ibus-mozc`がデフォルトでひらがなモードになるようにソースを書き換え、入力ソースの切り替えでIMEの切り替えを実現します。

2. 適当なディレクトリを作って、そこに移動します：
    ```sh
    mkdir ~/mozc-setup
    cd ~/mozc-setup
    ```

3. `ibus-mozc`のソースを取ってこられるように`apt`の設定を変更します：
    ```sh
    sudo vi /etc/apt/sources.list
    ```
    - 以下の行のコメントを外します：
      ```sh
      deb-src https://jp.archive.ubuntu.com/ubuntu/ hirsute main restricted
      ```

4. `ibus-mozc`がコンパイルできるように整えます：
    ```sh
    sudo apt update
    sudo apt upgrade
    sudo apt build-dep ibus-mozc
    ```

5. ソースコードを持ってきて修正します：
    ```sh
    apt source ibus-mozc
    cd mozc-*
    vi $(find . -name property_handler.cc)
    ```
    - 以下の行を修正します：
      ```cpp
      （修正前） const bool kActivateOnLaunch = false;
      （修正後） const bool kActivateOnLaunch = true;
      ```

6. コンパイルしてインストールします：
    ```sh
    sudo apt install fakeroot
    dpkg-buildpackage -us -uc -b
    cd ..
    sudo dpkg -i mozc*.deb ibus-mozc*.deb
    ```

7. Mozcの設定を行います：
    ```sh
    /usr/lib/mozc/mozc_tool --mode=config_dialog
    ```
    - 「一般」で、キー設定の選択を「ことえり」にします。

8. 念のため、システムを再起動します。

## 5. 壁紙の設定

1. 好きな壁紙をダウンロードし、`~/Pictures`ディレクトリに保存します。
2. デスクトップを右クリックして「背景を変更する」を選択します。
3. 「画像を追加」をクリックし、ダウンロードした壁紙を選択して設定します。

これで、指定された手動設定が完了します。
