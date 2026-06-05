#!/usr/bin/env bash

WALL_DIR="$HOME/ِArch-ZEM/wallpaper.png"

# -----------------------------
# Detect monitor FPS (fallback: 60)
# -----------------------------
MONITOR_FPS=60

if command -v hyprctl &>/dev/null; then
  FPS=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].refreshRate // empty' | cut -d'.' -f1)
  [[ -n "$FPS" ]] && MONITOR_FPS="$FPS"
fi

ln -sf "$WALL_DIR" "$HOME/.config/rofi/current_wallpaper"

awww img "$WALL_DIR" \
  --transition-type wipe \
  --transition-angle 120 \
  --transition-duration 2 \
  --transition-fps "$MONITOR_FPS"

matugen image "$WALL_DIR" \
  --type scheme-tonal-spot \
  --source-color-index 0 \
  -m dark

~/.config/rofi/scripts/reload_apps.sh & disown

sed -i '/applyg_default_wallpaper.sh\.sh/d' "$HOME/.config/hypr/hyprland/execs.conf"
