#!/bin/bash
# Wallpaper Launcher with Matugen
# original rofi launcher by gh0stzk
# rewritten for Hyprland
# optimized final version

set -e

# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------

wall_dir="${HOME}/Wallpapers/Images"
cacheDir="${HOME}/.cache/jp/wallpicker"
rofi_command="rofi -dmenu -theme ${HOME}/.config/rofi/menus/wallpaper/wallpaper.rasi"

# ----------------------------------------------------------------------------
# Detect monitor refresh rate (Hyprland)
# ----------------------------------------------------------------------------

MONITOR_FPS=60

if command -v hyprctl &> /dev/null && command -v jq &> /dev/null; then
    detected_fps=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .refreshRate' | cut -d'.' -f1)
    if [[ -n "$detected_fps" && "$detected_fps" != "null" ]]; then
        MONITOR_FPS="$detected_fps"
    fi
fi

# ----------------------------------------------------------------------------
# Swww transition settings
# ----------------------------------------------------------------------------

TRANSITION_TYPE="wipe"
TRANSITION_DURATION=2
TRANSITION_ANGLE=120
TRANSITION_FPS="$MONITOR_FPS"

# ----------------------------------------------------------------------------
# Create cache directory
# ----------------------------------------------------------------------------

mkdir -p "${cacheDir}"

# ----------------------------------------------------------------------------
# Generate thumbnails
# ----------------------------------------------------------------------------

for imagen in "$wall_dir"/*.{jpg,jpeg,png,webp}; do
    [ -f "$imagen" ] || continue
    filename=$(basename "$imagen")

    if [ ! -f "${cacheDir}/${filename}" ]; then
        convert -strip "$imagen" \
            -thumbnail 500x500^ \
            -gravity center \
            -extent 500x500 \
            "${cacheDir}/${filename}"
    fi
done

# ----------------------------------------------------------------------------
# Select wallpaper with rofi
# ----------------------------------------------------------------------------

wall_selection=$(find "${wall_dir}" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -exec basename {} \; | sort | while read -r file; do
        echo -en "$file\x00icon\x1f${cacheDir}/$file\n"
done | $rofi_command)

[[ -n "$wall_selection" ]] || exit 0

WALLPAPER="${wall_dir}/${wall_selection}"

# ----------------------------------------------------------------------------
# Set wallpaper with swww
# ----------------------------------------------------------------------------

awww img "$WALLPAPER" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-duration "$TRANSITION_DURATION" \
    --transition-angle "$TRANSITION_ANGLE" \
    --transition-fps "$TRANSITION_FPS"

# ----------------------------------------------------------------------------
# Symlink current wallpaper
# ----------------------------------------------------------------------------

ln -sf "$WALLPAPER" ~/.config/rofi/current_wallpaper

# ----------------------------------------------------------------------------
# Dependency Check (Matugen)
# ----------------------------------------------------------------------------

if ! command -v matugen &> /dev/null; then
    notify-send "Matugen Error" "matugen is not installed!"
    exit 1
fi

# ----------------------------------------------------------------------------
# Generate theme with Matugen
# ----------------------------------------------------------------------------

if ! matugen image "$WALLPAPER" --type scheme-tonal-spot --source-color-index 0; then
    notify-send "Matugen Error" "Failed to generate theme!"
    exit 1
fi

# ----------------------------------------------------------------------------
# Reload apps with contrast
# ----------------------------------------------------------------------------

~/.config/rofi/scripts/reload_apps.sh
sudo ~/.config/rofi/scripts/reload_root_apps.sh
# ----------------------------------------------------------------------------
# Notification
# ----------------------------------------------------------------------------

notify-send "Wallpaper Applied" "Wallpaper updated successfully!"
