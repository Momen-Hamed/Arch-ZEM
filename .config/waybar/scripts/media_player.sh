#!/bin/bash
# Ignore these players
IGNORED_PLAYERS=("kdeconnect")
# Player icons
declare -A PLAYER_ICONS=(
["spotify"]="󰓇"
["mpv"]="󰐊"
["vlc"]="󰕼"
["rhythmbox"]="󰓃"
["firefox"]="󰈹"
["chromium"]="󰊯"
["brave"]="󰖟"
["default"]="󰝚"
)

PLAYER_LOCK="/tmp/waybar_media_player"
PLAYING_SINCE="/tmp/waybar_media_playing_since"

# Get all active players
players=$(playerctl -l 2>/dev/null)
if [[ -z "$players" ]]; then
echo '{"text": "󰝚   Nothing is playing", "class": "idle"}'
exit
fi

# Build filtered players list
filtered_players=()
for player in $players; do
    skip=false
    for ignored in "${IGNORED_PLAYERS[@]}"; do
        if [[ "$player" == *"$ignored"* ]]; then
            skip=true
            break
        fi
    done
    $skip && continue
    status=$(playerctl -p "$player" status 2>/dev/null)
    [[ "$status" == "Playing" || "$status" == "Paused" ]] && filtered_players+=("$player")
done

# ── Switch player on right click ──────────────────────────────────────────────
if [[ "$1" == "switch" ]]; then
    current=$(cat "$PLAYER_LOCK" 2>/dev/null)
    current_idx=-1
    for i in "${!filtered_players[@]}"; do
        [[ "${filtered_players[$i]}" == "$current" ]] && current_idx=$i && break
    done
    next_idx=$(( (current_idx + 1) % ${#filtered_players[@]} ))
    echo "${filtered_players[$next_idx]}" > "$PLAYER_LOCK"
    rm -f "$PLAYING_SINCE"
    exit
fi

# ── Mute/unmute on middle click ───────────────────────────────────────────────
if [[ "$1" == "mute" ]]; then
    locked=$(cat "$PLAYER_LOCK" 2>/dev/null)
    active_player="$locked"
    player_name=$(echo "$active_player" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')
    declare -A WPCTL_NAMES=(
        ["firefox"]="zen"
        ["chromium"]="chromium"
        ["brave"]="brave"
        ["spotify"]="spotify"
        ["mpv"]="mpv"
        ["vlc"]="vlc"
    )
    wpctl_name="${WPCTL_NAMES[$player_name]:-$player_name}"
    NODE_ID=$(wpctl status | grep -i "$wpctl_name" | grep -o '[0-9]\+\.' | tr -d '.' | tail -1)
    if [[ -z "$NODE_ID" ]]; then
        echo "Could not find PipeWire node for $wpctl_name" >&2
        exit 1
    fi
    wpctl set-mute "$NODE_ID" toggle
    exit
fi

# Find the best active player (locked first, but playing overrides paused lock after 2s)
active_player=""
locked=$(cat "$PLAYER_LOCK" 2>/dev/null)

# Check if any other player is currently Playing
playing_player=""
for p in "${filtered_players[@]}"; do
    [[ "$p" == "$locked" ]] && continue
    s=$(playerctl -p "$p" status 2>/dev/null)
    if [[ "$s" == "Playing" ]]; then
        playing_player="$p"
        break
    fi
done

if [[ -n "$locked" ]]; then
    locked_status=$(playerctl -p "$locked" status 2>/dev/null)
    if [[ "$locked_status" == "Playing" ]]; then
        rm -f "$PLAYING_SINCE"
        active_player="$locked"
    elif [[ -n "$playing_player" ]]; then
        now=$(date +%s)
        if [[ ! -f "$PLAYING_SINCE" ]]; then
            echo "$now" > "$PLAYING_SINCE"
        fi
        since=$(cat "$PLAYING_SINCE")
        if (( now - since >= 2 )); then
            active_player="$playing_player"
            echo "$active_player" > "$PLAYER_LOCK"
            rm -f "$PLAYING_SINCE"
        else
            active_player="$locked"
        fi
    else
        rm -f "$PLAYING_SINCE"
        active_player="$locked"
    fi
fi

if [[ -z "$active_player" ]]; then
    for player in $players; do
        skip=false
        for ignored in "${IGNORED_PLAYERS[@]}"; do
            if [[ "$player" == *"$ignored"* ]]; then
                skip=true
                break
            fi
        done
        $skip && continue
        status=$(playerctl -p "$player" status 2>/dev/null)
        if [[ "$status" == "Playing" ]]; then
            active_player="$player"
            break
        elif [[ "$status" == "Paused" && -z "$active_player" ]]; then
            active_player="$player"
        fi
    done
    echo "$active_player" > "$PLAYER_LOCK"
fi

if [[ -z "$active_player" ]]; then
echo '{"text": "󰝚   Nothing is playing", "class": "idle"}'
exit
fi
# ── Volume control (called with "up" or "down" argument) ──────────────────────
if [[ "$1" == "up" || "$1" == "down" ]]; then
    player_name=$(echo "$active_player" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')
# Map playerctl names to wpctl stream names
declare -A WPCTL_NAMES=(
["firefox"]="zen"
["chromium"]="chromium"
["brave"]="brave"
["spotify"]="spotify"
["mpv"]="mpv"
["vlc"]="vlc"
)
    wpctl_name="${WPCTL_NAMES[$player_name]:-$player_name}"
# Find the PipeWire stream node ID
    NODE_ID=$(wpctl status | grep -i "$wpctl_name" | grep -o '[0-9]\+\.' | tr -d '.' | tail -1)
if [[ -z "$NODE_ID" ]]; then
echo "Could not find PipeWire node for $wpctl_name" >&2
exit 1
fi
[[ "$1" == "up" ]]   && wpctl set-volume -l 1 "$NODE_ID" 5%+
[[ "$1" == "down" ]] && wpctl set-volume "$NODE_ID" 5%-
exit
fi
# ── Normal status output ──────────────────────────────────────────────────────
status=$(playerctl -p "$active_player" status 2>/dev/null)
title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)
# Get player base name (spotify.instance1 -> spotify)
player_name=$(echo "$active_player" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')
# Pick player icon
player_icon="${PLAYER_ICONS[$player_name]:-${PLAYER_ICONS[default]}}"
# Status icon
if [[ "$status" == "Playing" ]]; then
    status_icon=""
    class="playing"
else
    status_icon=""
    class="paused"
fi
# Mute icon
declare -A WPCTL_NAMES=(
["firefox"]="zen"
["chromium"]="chromium"
["brave"]="brave"
["spotify"]="spotify"
["mpv"]="mpv"
["vlc"]="vlc"
)
wpctl_name="${WPCTL_NAMES[$player_name]:-$player_name}"
NODE_ID=$(wpctl status | grep -i "$wpctl_name" | grep -o '[0-9]\+\.' | tr -d '.' | tail -1)
muted_icon=""
if [[ -n "$NODE_ID" ]]; then
    vol_output=$(wpctl get-volume "$NODE_ID" 2>/dev/null)
    is_muted=$(echo "$vol_output" | grep -c "MUTED")
    vol_level=$(echo "$vol_output" | awk '{print int($2 * 100)}')
    if [[ "$is_muted" -eq 1 ]]; then
        muted_icon=" 󰝟"
    elif [[ "$vol_level" -eq 0 ]]; then
        muted_icon=" 󰖁"
    fi
fi
# Truncate long titles
max_length=35
if [[ ${#title} -gt $max_length ]]; then
    title="${title:0:$max_length}..."
fi
# Build text
if [[ -n "$artist" ]]; then
    text="$status_icon$muted_icon  $artist - $title"
else
    text="$status_icon$muted_icon  $title"
fi

tooltip="$player_icon  $(echo "$player_name" | sed 's/\b./\u&/g')"
echo "{\"text\": \"$text\", \"class\": \"$class\", \"tooltip\": \"$tooltip\"}"