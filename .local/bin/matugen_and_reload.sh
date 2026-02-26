#!/usr/bin/env bash

echo "🎨 Generating theme with matugen..."
echo "✅ Matugen completed successfully"

## Helper Functions

kill_if_running() { pgrep -x "$1" >/dev/null && pkill -x "$1"; }

restart_service() {
    if pgrep -f "$1" >/dev/null; then
        pkill -f "$1"
        sleep 0.5
        $1 &>/dev/null &
    fi
}

has_window() {
    hyprctl clients -j | jq -e ".[] | select(.class == \"$1\")" >/dev/null 2>&1
}

## Reload Apps (Parallel Execution)

# Waybar
pkill waybar; waybar &>/dev/null &

# Kill only
kill_if_running waypaper

# Nautilus - only restart if it has a visible window
if has_window "org.gnome.Nautilus"; then
    pkill -x nautilus
    nautilus &>/dev/null &
fi

# Other GTK Apps
pgrep -x qalculate-gtk >/dev/null && { pkill -x qalculate-gtk; qalculate-gtk &>/dev/null & } &
pgrep -x pavucontrol >/dev/null && { pkill -x pavucontrol; pavucontrol &>/dev/null & } &
pgrep -x blueman-manager >/dev/null && { pkill -x blueman-manager; blueman-manager &>/dev/null & } &

# GNOME Clocks - only restart if it has a visible window
if has_window "org.gnome.clocks"; then
    pkill -x gnome-clocks
    gnome-clocks &>/dev/null &
fi

# GNOME Text Editor (process name != binary name)
pgrep -x gnome-text-edit >/dev/null && { pkill -x gnome-text-edit; gnome-text-editor &>/dev/null & } &

# System Services (need delay to restart properly)
restart_service "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" &
restart_service "/usr/lib/xdg-desktop-portal-gtk" &

# GParted
pgrep -x gparted >/dev/null && { sudo pkill gparted; sudo -E gparted & }

# Spotify
pgrep -x spotify >/dev/null && { spicetify config color_scheme dark && spicetify apply & }

wait  # Wait for all background jobs to complete

echo "✅ Theme reload complete!"
