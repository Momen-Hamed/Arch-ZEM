#!/usr/bin/env bash

if [ -z "$SCRIPT_KITTY_WINDOW" ]; then
    SCRIPT_KITTY_WINDOW=1 kitty --title "floating-kitty" bash "$0"
    exit 0
fi

# Get screen resolution and set window size
SCREEN_WIDTH=$(hyprctl monitors -j | jq '.[0].width')
SCREEN_HEIGHT=$(hyprctl monitors -j | jq '.[0].height')
WIN_WIDTH=$(( SCREEN_WIDTH * 55 / 100 ))
WIN_HEIGHT=$(( SCREEN_HEIGHT * 65 / 100 ))

hyprctl dispatch setfloating "title:^(floating-kitty)$" &>/dev/null
hyprctl dispatch resizewindowpixel "exact $WIN_WIDTH $WIN_HEIGHT,title:^(floating-kitty)$" &>/dev/null
hyprctl dispatch centerwindow "title:^(floating-kitty)$" &>/dev/null

if [ -z "$SCRIPT_KITTY_WINDOW" ]; then
    SCRIPT_KITTY_WINDOW=1 kitty bash "$0"
    exit 0
fi

HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$HYPRLOCK_CONF" ]; then
    echo "Hyprlock display name:"
    echo "1) Keep default ($USER)"
    echo "2) Set custom name"
    read -rp "Choice [1/2]: " HYPRLOCK_CHOICE
    if [[ "$HYPRLOCK_CHOICE" == "2" ]]; then
        read -rp "Enter display name: " HYPRLOCK_NAME
        ESCAPED_NAME=$(printf '%s\n' "$HYPRLOCK_NAME" | sed 's/[&/\]/\\&/g')
        sed -i "s/text = \$USER/text = $ESCAPED_NAME/" "$HYPRLOCK_CONF"
        echo "Display name updated to '$HYPRLOCK_NAME'."
    fi
fi

read -rp "Press Enter to close..."

sed -i '/customization\.sh/d' "$HOME/.config/hypr/hyprland/execs.conf"
