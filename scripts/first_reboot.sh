#!/usr/bin/env bash

DONE_FILE="$HOME/.config/hypr/.first_reboot_done"

if [ -f "$DONE_FILE" ]; then
    exit 0
fi

touch "$DONE_FILE"

sleep 3
SCRIPT_KITTY_WINDOW=1 kitty bash "$HOME/n4zl-dotfiles/scripts/customization.sh"
