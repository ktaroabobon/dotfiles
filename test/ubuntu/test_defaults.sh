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
desktop_icons_setting=$(gsettings get org.gnome.desktop.background show-desktop-icons)
if [ "$desktop_icons_setting" = "false" ]; then
    print_result 0 "desktop icons visibility"
else
    print_result 1 "desktop icons visibility"
fi

# Test if desktop icons are aligned to the top right
echo "Running test for desktop icons alignment"
icon_placement=$(gsettings get org.gnome.shell.extensions.desktop-icons icon-placement)
if [ "$icon_placement" = "'top-right'" ]; then
    print_result 0 "desktop icons alignment"
else
    print_result 1 "desktop icons alignment"
fi

# Test if necessary tools are installed
tools=("chrome-gnome-shell" "git" "gnome-tweaks" "wmctrl")
for tool in "${tools[@]}"
do
    echo "Running test for $tool installation"
    dpkg -s $tool >/dev/null 2>&1
    print_result $? "$tool installation"
done

# Test if GNOME Terminal headerbar is disabled
echo "Running test for GNOME Terminal headerbar setting"
gnome_terminal_headerbar=$(gsettings get org.gnome.Terminal.Legacy.Settings headerbar)
if [ "$gnome_terminal_headerbar" = "false" ]; then
    print_result 0 "GNOME Terminal headerbar setting"
else
    print_result 1 "GNOME Terminal headerbar setting"
fi

# Test if MacOS Big Sur theme and icons are installed
echo "Running test for MacOS Big Sur theme installation"
if [ -d "WhiteSur-gtk-theme" ]; then
    print_result 0 "MacOS Big Sur theme installation"
else
    print_result 1 "MacOS Big Sur theme installation"
fi

echo "Running test for MacOS Big Sur icon installation"
if [ -d "WhiteSur-icon-theme" ]; then
    print_result 0 "MacOS Big Sur icon installation"
else
    print_result 1 "MacOS Big Sur icon installation"
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
echo "Running test for keyboard shortcuts"
keyboard_shortcuts=(
    "org.gnome.settings-daemon.plugins.media-keys screensaver"
    "org.gnome.desktop.wm.keybindings switch-applications"
    "org.gnome.desktop.wm.keybindings switch-applications-backward"
    "org.gnome.desktop.wm.keybindings switch-windows"
    "org.gnome.shell.keybindings toggle-overview"
    "org.gnome.shell.keybindings show-apps"
    "org.gnome.desktop.wm.keybindings show-desktop"
    "org.gnome.desktop.wm.keybindings switch-input-source"
)
for shortcut in "${keyboard_shortcuts[@]}"
do
    setting=$(gsettings get $shortcut)
    if [[ -n "$setting" ]]; then
        print_result 0 "$shortcut shortcut"
    else
        print_result 1 "$shortcut shortcut"
    fi
done

echo "----------------------------------------"
echo "End of test_defaults.sh"
echo "----------------------------------------"
echo "Total tests: $((pass_count + fail_count))"
echo "Passed: $pass_count"
echo "Failed: $fail_count"
