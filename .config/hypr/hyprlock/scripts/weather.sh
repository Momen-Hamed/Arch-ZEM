#!/bin/bash
# Weather widget script for hyprlock
# Uses open-meteo.com (no API key required)
# Dependencies: curl, jq
CACHE_FILE="/tmp/hyprlock_weather_cache"
CACHE_TTL=1800  # 30 minutes in seconds
# --- CONFIG ---
# Your coordinates (required for open-meteo)
# Find yours at: https://www.latlong.net
LAT="21.49"   # Jeddah default
LON="39.19"   # Jeddah default
# Icon style: "nerd" (requires nerd fonts) or "emoji"
ICON_STYLE="nerd"
# Path to your hyprlock config
CONFIG_FILE="$HOME/.config/hypr/hyprlock.conf"

# WMO weather code to icon mapping
get_icon_nerd() {
local code=3
case $code in
0) echo "󰖙" ;;           # Clear sky
1|2) echo "󰖕" ;;         # Mainly clear, partly cloudy
3) echo "󰖔" ;;           # Overcast
45|48) echo "󰖑" ;;       # Fog
51|53|55|61|63|65|80|81|82) echo "󰖗" ;;  # Rain/Drizzle
71|73|75|77|85|86) echo "󰖘" ;;           # Snow
95|96|99) echo "󰖓" ;;    # Thunder
*) echo "󰖙" ;;
esac
}
get_icon_emoji() {
local code=$1
case $code in
0) echo "☀️" ;;
1|2) echo "⛅" ;;
3) echo "☁️" ;;
45|48) echo "🌫️" ;;
51|53|55|61|63|65|80|81|82) echo "🌧️" ;;
71|73|75|77|85|86) echo "❄️" ;;
95|96|99) echo "⛈️" ;;
*) echo "🌡️" ;;
esac
}

update_size() {
local digits=$1
local new_size
case $digits in
1) new_size="70, 45" ;;
2) new_size="81, 45" ;;
*) new_size="91, 45" ;;
esac
sed -i \
-e 's/size = 70, 45/size = '"$new_size"'/g' \
-e 's/size = 81, 45/size = '"$new_size"'/g' \
-e 's/size = 91, 45/size = '"$new_size"'/g' \
"$CONFIG_FILE"
}

fetch_weather() {
local url="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weathercode&temperature_unit=celsius"
local data
data=$(curl -sf --max-time 10 "$url" 2>/dev/null)
if [[ -z "$data" ]]; then
echo "󰖙  --°"
return
fi
local temp_c
local condition_code
temp_c=$(echo "$data" | jq -r '.current.temperature_2m | round' 2>/dev/null | tr -dc '0-9-')
condition_code=$(echo "$data" | jq -r '.current.weathercode' 2>/dev/null)
local icon
if [[ "$ICON_STYLE" == "nerd" ]]; then
icon=$(get_icon_nerd "$condition_code")
else
icon=$(get_icon_emoji "$condition_code")
fi 
# Update size based on digit count
local stripped
stripped=$(echo "$temp_c" | tr -d '-')
local digits=${#stripped}
update_size "$digits"
# Save to cache
echo "${icon}  ${temp_c}°" > "$CACHE_FILE"
echo "$(date +%s)" >> "$CACHE_FILE"
}
# Check cache validity
use_cache=false
if [[ -f "$CACHE_FILE" ]]; then
cached_output=$(sed -n '1p' "$CACHE_FILE")
cached_time=$(sed -n '2p' "$CACHE_FILE")
current_time=$(date +%s)
if (( current_time - cached_time < CACHE_TTL )); then
use_cache=true
fi
fi
if $use_cache; then
echo "$cached_output"
else
fetch_weather
cached_output=$(sed -n '1p' "$CACHE_FILE" 2>/dev/null)
echo "${cached_output:-󰖙  --°}"
fi