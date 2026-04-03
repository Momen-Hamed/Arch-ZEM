#!/usr/bin/env bash
# network-display.sh
# Shows either WiFi or Ethernet info based on a state file.
# Used as a waybar custom module.
STATE_FILE="/tmp/waybar-network-mode"
# Default to wifi if no state file
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "wifi")
# ─── Get WiFi info ────────────────────────────────────────────────────────────
# ─── Helpers ──────────────────────────────────────────────────────────────────
get_speed() {
local iface="$1"
local rx_file="/sys/class/net/$iface/statistics/rx_bytes"
local tx_file="/sys/class/net/$iface/statistics/tx_bytes"
local cache="/tmp/waybar-net-$iface"
local rx tx
    rx=$(cat "$rx_file" 2>/dev/null || echo 0)
    tx=$(cat "$tx_file" 2>/dev/null || echo 0)
local rx_prev=0 tx_prev=0 ts_prev ts_now
    ts_now=$(date +%s%N)
if [[ -f "$cache" ]]; then
read -r rx_prev tx_prev ts_prev < "$cache"
else
        ts_prev=$ts_now
fi
echo "$rx $tx $ts_now" > "$cache"
local elapsed=$(( (ts_now - ts_prev) / 1000000 ))
(( elapsed < 1 )) && elapsed=1
local down=$(( (rx - rx_prev) * 1000 / elapsed ))
local up=$(( (tx - tx_prev) * 1000 / elapsed ))
# Format bytes to human readable
format_bytes() {
local b=$1
if   (( b >= 1048576 )); then printf "%.2f MB/s" "$(echo "scale=2; $b/1048576" | bc)"
else                          printf "%.2f KB/s" "$(echo "scale=2; $b/1024" | bc)"
fi
}
    DOWN_STR=$(format_bytes $down)
    UP_STR=$(format_bytes $up)
}
get_wifi() {
local essid signal icon
    essid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    signal=$(nmcli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2)
if [[ -z "$essid" ]]; then
echo '{"text": "󰖪", "tooltip": "WiFi: Disconnected", "class": "disconnected"}'
return
fi
if   (( signal >= 80 )); then icon="󰤨"
elif (( signal >= 60 )); then icon="󰤥"
elif (( signal >= 40 )); then icon="󰤢"
elif (( signal >= 20 )); then icon="󰤟"
else                          icon="󰤯"
fi
local iface
    iface=$(nmcli -t -f active,device dev wifi | grep '^yes' | cut -d: -f2)
get_speed "$iface"
echo "{\"text\": \"$icon\", \"tooltip\": \"$icon  $essid\\n⇣$DOWN_STR  ⇡$UP_STR\", \"class\": \"wifi\"}"
}
# ─── Get Ethernet info ────────────────────────────────────────────────────────
get_ethernet() {
local eth_dev eth_state
    eth_dev=$(nmcli -t -f TYPE,DEVICE dev | grep '^ethernet' | cut -d: -f2 | head -1)
    eth_state=$(nmcli -t -f DEVICE,STATE dev | grep "^$eth_dev:" | cut -d: -f2)
if [[ "$eth_state" != "connected" ]]; then
echo '{"text": "󰀂", "tooltip": "Ethernet: Disconnected", "class": "disconnected"}'
return
fi
get_speed "$eth_dev"
echo "{\"text\": \"󰀂\", \"tooltip\": \"󰀂  $eth_dev\\n⇣$DOWN_STR  ⇡$UP_STR\", \"class\": \"ethernet\"}"
}
# ─── Output based on mode ─────────────────────────────────────────────────────
if [[ "$MODE" == "wifi" ]]; then
get_wifi
else
get_ethernet
fi