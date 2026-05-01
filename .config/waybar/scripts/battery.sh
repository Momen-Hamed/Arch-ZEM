#!/bin/bash

if [ "$1" = "switch" ]; then
    CURRENT=$(powerprofilesctl get)
    case "$CURRENT" in
        "power-saver") powerprofilesctl set balanced ;;
        "balanced") powerprofilesctl set performance ;;
        "performance") powerprofilesctl set power-saver ;;
    esac
    exit 0
fi

CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)
PROFILE=$(powerprofilesctl get)
TIME=$(upower -i $(upower -e | grep BAT) | grep "time to" | awk '{print $4, $5}')

ICONS=("" "" "" "" "")

if [ "$CAPACITY" -le 15 ]; then
    ICON="${ICONS[0]}"
elif [ "$CAPACITY" -le 25 ]; then
    ICON="${ICONS[1]}"
elif [ "$CAPACITY" -le 50 ]; then
    ICON="${ICONS[2]}"
elif [ "$CAPACITY" -le 75 ]; then
    ICON="${ICONS[3]}"
else
    ICON="${ICONS[4]}"
fi

if [ "$STATUS" = "Charging" ]; then
    TOOLTIP="+ $CAPACITY% | $TIME\nProfile: $PROFILE"
else
    TOOLTIP="$CAPACITY% | $TIME\nProfile: $PROFILE"
fi

echo "{\"text\": \"$ICON\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$STATUS\"}"
