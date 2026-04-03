#!/usr/bin/env bash
# network-toggle-display.sh
# Right-click: toggles waybar network display between wifi and ethernet.

STATE_FILE="/tmp/waybar-network-mode"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "wifi")

if [[ "$MODE" == "wifi" ]]; then
    echo "ethernet" > "$STATE_FILE"
else
    echo "wifi" > "$STATE_FILE"
fi

# Force waybar to refresh the custom module
pkill -RTMIN+8 waybar
