#!/bin/zsh

# Initialize counters
pass_count=0
fail_count=0

# Helper function to print test result
# 注: カウンタは `((c++))` ではなく算術代入で増やす。`((c++))` は c=0 のとき
# 算術結果 0 のため終了ステータス 1 を返し、呼び出し側の判定を狂わせる。
print_result() {
    if [[ $1 -eq 0 ]]; then
        echo "[PASS] $2"
        pass_count=$((pass_count + 1))
    else
        echo "[FAIL] $2"
        fail_count=$((fail_count + 1))
    fi
}

echo "Start test_init.sh"

# Check if macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running tests on macOS"

    # Test if xcode command line tools installation is successful
    echo "Running test for xcode command line tools installation"
    xcode-select -p >/dev/null 2>&1
    print_result $? "xcode command line tools installation"

    # Test if Homebrew installation is successful
    echo "Running test for Homebrew installation"
    brew --version >/dev/null 2>&1
    print_result $? "Homebrew installation"

    # Test if vi (vim) installation is successful
    echo "Running test for vi installation"
    vim --version >/dev/null 2>&1
    print_result $? "vi (vim) installation"

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running tests on Linux"

    # Test if essential packages installation is successful
    echo "Running test for essential packages installation"
    gcc --version >/dev/null 2>&1
    print_result $? "essential packages installation"

    # Test if zsh installation is successful
    echo "Running test for zsh installation"
    zsh --version >/dev/null 2>&1
    print_result $? "zsh installation"

    # Test if git installation is successful
    echo "Running test for git installation"
    git --version >/dev/null 2>&1
    print_result $? "git installation"

    # Test if curl installation is successful
    echo "Running test for curl installation"
    curl --version >/dev/null 2>&1
    print_result $? "curl installation"

    # Test if make installation is successful
    echo "Running test for make installation"
    make --version >/dev/null 2>&1
    print_result $? "make installation"

    # Test if make-guile installation is successful
    # 注: `apt show` は未インストールでもカタログに存在すれば 0 を返すため使わない
    echo "Running test for make-guile installation"
    dpkg -s make-guile >/dev/null 2>&1
    print_result $? "make-guile installation"

    # Test if vi (vim) installation is successful
    echo "Running test for vi installation"
    vim --version >/dev/null 2>&1
    print_result $? "vi (vim) installation"

    # Test if language pack installation is successful
    echo "Running test for language pack installation"
    locale -a | grep -q "en_US.utf8"
    print_result $? "language pack installation"

    # Test if git configuration is set correctly
    echo "Running test for git configuration"
    git config --global user.email | grep -q "ktaroabobon@gmail.com"
    print_result $? "git user.email configuration"

    git config --global user.name | grep -q "ktaroabobon"
    print_result $? "git user.name configuration"

    # Test if oh-my-zsh installation is successful
    echo "Running test for oh-my-zsh installation"
    ls ~/.oh-my-zsh >/dev/null 2>&1
    print_result $? "oh-my-zsh installation"

    # Test if oh-my-zsh theme is set correctly
    echo "Running test for oh-my-zsh theme"
    grep -q "ZSH_THEME=\"agnoster\"" ~/.zshrc
    print_result $? "oh-my-zsh theme"

else
    echo "Unsupported operating system"
    exit 1
fi

echo "----------------------------------------"
echo "End of test_init.sh"
echo "----------------------------------------"
echo "Total tests: $((pass_count + fail_count))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"

# 失敗を終了コードで返す（これが無いと CI から呼んでも常に成功扱いになる）
[[ $fail_count -eq 0 ]] || exit 1
