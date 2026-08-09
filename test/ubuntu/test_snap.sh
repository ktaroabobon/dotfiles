#!/bin/zsh

# .bin/ubuntu/snap.sh の結果を検証する。
# snapd は systemd を必要とするため、コンテナや GitHub Actions では実行できない。
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

echo "Start test_snap.sh"

# Test if snap command is available
echo "Running test for snap command"
command -v snap >/dev/null 2>&1
print_result $? "snap command availability"

# Test if necessary applications are installed via snap
# 注: `grep -q "^$app"` は前方一致なので code が codelite に、docker が
#     dockerhoge にマッチしてしまう。パッケージ名は完全一致で確認する。
apps=("aws-cli" "docker" "jetbrains-toolbox" "code" "postman" "firefox" "zoom-client" "logi-options-plus" "discord" "slack")
snap_list=$(snap list 2>/dev/null)
for app in "${apps[@]}"
do
    echo "Running test for $app installation"
    echo "$snap_list" | awk -v name="$app" 'NR > 1 && $1 == name { found = 1 } END { exit !found }'
    print_result $? "$app installation"
done

# Test if Google Chrome is installed (snap ではなく .deb で入れている)
echo "Running test for Google Chrome installation"
google-chrome --version >/dev/null 2>&1
print_result $? "Google Chrome installation"

echo "----------------------------------------"
echo "End of test_snap.sh"
echo "----------------------------------------"
echo "Total tests: $((pass_count + fail_count))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"

# 失敗を終了コードで返す（これが無いと呼び出し側では常に成功扱いになる）
[[ $fail_count -eq 0 ]] || exit 1
