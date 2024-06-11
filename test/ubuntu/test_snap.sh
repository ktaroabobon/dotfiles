#!/bin/zsh

# Initialize counters
pass_count=0
fail_count=0

# Helper function to print test result
print_result() {
    if [[ $1 -eq 0 ]]; then
        echo "[PASS] $2"
        ((pass_count++))
    else
        echo "[FAIL] $2"
        ((fail_count++))
    fi
}

echo "Start test_snap.sh"

# Test if snap command is available
echo "Running test for snap command"
command -v snap >/dev/null 2>&1
print_result $? "snap command availability"

# Test if necessary applications are installed via snap
apps=("aws-cli" "docker" "jetbrains-toolbox" "code" "postman" "firefox" "zoom-client" "logi-options-plus" "discord" "slack")
for app in "${apps[@]}"
do
    echo "Running test for $app installation"
    snap list | grep -q "^$app"
    print_result $? "$app installation"
done

# Test if Google Chrome is installed
echo "Running test for Google Chrome installation"
google_chrome_version=$(google-chrome --version)
if [[ $? -eq 0 ]]; then
    print_result 0 "Google Chrome installation"
else
    print_result 1 "Google Chrome installation"
fi

echo "----------------------------------------"
echo "End of test_snap.sh"
echo "----------------------------------------"
echo "Total tests: $((pass_count + fail_count))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"
