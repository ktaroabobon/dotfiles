#!/bin/zsh

# .bin/ubuntu/defaults.sh の結果を検証する。
# gsettings と GNOME セッション（dbus）が必要なため、コンテナや CI では実行できない。
# ネイティブの Ubuntu デスクトップ上で実行すること。

# Initialize counters
pass_count=0
fail_count=0

# Helper function to print test result
# 注: カウンタは `((c++))` ではなく算術代入で増やす。`((c++))` は c=0 のとき
# 算術結果 0 のため終了ステータス 1 を返す。
print_result() {
    if [[ $1 -eq 0 ]]; then
        echo "[PASS] $2"
        pass_count=$((pass_count + 1))
    else
        echo "[FAIL] $2"
        fail_count=$((fail_count + 1))
    fi
}

# gsettings の値が期待どおりかを確認する。
# `gsettings get` は値が空配列でも成功して何かを出力するため、
# 「取得できたか」ではなく「期待値と一致するか」で判定する。
check_gsettings() {
    local schema="$1" key="$2" expected="$3"
    local actual
    actual=$(gsettings get "$schema" "$key" 2>/dev/null)
    if [[ "$actual" == "$expected" ]]; then
        print_result 0 "$schema $key = $expected"
    else
        print_result 1 "$schema $key = ${actual:-(取得失敗)} (期待: $expected)"
    fi
}

echo "Start test_defaults.sh"

# Test if gsettings command is available
echo "Running test for gsettings command"
command -v gsettings >/dev/null 2>&1
print_result $? "gsettings command availability"

# Test if directories are set to English names
echo "Running test for directory names"
xdg_user_dirs=("Desktop" "Documents" "Downloads" "Music" "Pictures" "Videos")
for dir in "${xdg_user_dirs[@]}"
do
    if [ -d "${HOME}/${dir}" ]; then
        print_result 0 "${dir} directory exists"
    else
        print_result 1 "${dir} directory does not exist"
    fi
done

# Test if unnecessary desktop icons are hidden
echo "Running test for desktop icons visibility"
check_gsettings org.gnome.desktop.background show-desktop-icons "false"

# Test if desktop icons are aligned to the top right
echo "Running test for desktop icons alignment"
check_gsettings org.gnome.shell.extensions.desktop-icons icon-placement "'top-right'"

# Test if necessary tools are installed
tools=("chrome-gnome-shell" "git" "gnome-tweaks" "wmctrl")
for tool in "${tools[@]}"
do
    echo "Running test for $tool installation"
    dpkg -s "$tool" >/dev/null 2>&1
    print_result $? "$tool installation"
done

# Test if GNOME Terminal headerbar is disabled
echo "Running test for GNOME Terminal headerbar setting"
check_gsettings org.gnome.Terminal.Legacy.Settings headerbar "false"

# Test if MacOS Big Sur theme and icons are installed
# 注: clone したディレクトリの有無ではなく、install.sh が配置した成果物を見る。
#     clone は成功しても install.sh が失敗することがあるため。
echo "Running test for MacOS Big Sur theme installation"
if ls -d "${HOME}/.themes/"WhiteSur* >/dev/null 2>&1; then
    print_result 0 "MacOS Big Sur theme installation"
else
    print_result 1 "MacOS Big Sur theme installation (~/.themes に WhiteSur* が無い)"
fi

echo "Running test for MacOS Big Sur icon installation"
if ls -d "${HOME}/.icons/"WhiteSur* >/dev/null 2>&1; then
    print_result 0 "MacOS Big Sur icon installation"
else
    print_result 1 "MacOS Big Sur icon installation (~/.icons に WhiteSur* が無い)"
fi

# Test if MacOS Big Sur cursor icons are installed
echo "Running test for MacOS Big Sur cursor icon installation"
if [ -d "${HOME}/.icons/macOSBigSur" ]; then
    print_result 0 "MacOS Big Sur cursor icon installation"
else
    print_result 1 "MacOS Big Sur cursor icon installation"
fi

# Test if Ulauncher is installed
echo "Running test for Ulauncher installation"
dpkg -s ulauncher >/dev/null 2>&1
print_result $? "Ulauncher installation"

# Test if keyboard shortcuts are set correctly
# 注: screensaver / screenshot 系は defaults.sh 内で設定した直後に空へ上書き
#     されており、意図が確定していないため検証対象から外している
#     (.bin/ubuntu/defaults.sh の FIXME を参照)。
echo "Running test for keyboard shortcuts"
check_gsettings org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t']"
check_gsettings org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
check_gsettings org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
check_gsettings org.gnome.desktop.wm.keybindings switch-windows "['<Super>\`']"
check_gsettings org.gnome.shell.keybindings toggle-overview "['<Control>Up']"
check_gsettings org.gnome.shell.keybindings show-apps "['<Control>Down']"
check_gsettings org.gnome.desktop.wm.keybindings show-desktop "['<Control><Super>x']"
check_gsettings org.gnome.desktop.wm.keybindings switch-input-source "['<Control>o']"

# Test gnome-tweaks settings
echo "Running test for gnome-tweaks settings"
check_gsettings org.gnome.desktop.wm.preferences focus-mode "'mouse'"
check_gsettings org.gnome.desktop.wm.preferences button-layout "'close,minimize,maximize:'"
check_gsettings org.gnome.desktop.interface gtk-theme "'WhiteSur-dark-solid'"
check_gsettings org.gnome.desktop.interface icon-theme "'WhiteSur-dark'"

echo "----------------------------------------"
echo "End of test_defaults.sh"
echo "----------------------------------------"
echo "Total tests: $((pass_count + fail_count))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"

# 失敗を終了コードで返す（これが無いと呼び出し側では常に成功扱いになる）
[[ $fail_count -eq 0 ]] || exit 1
