#!/usr/bin/env bash

# mesa lib32-mesa -media-driver vulkan-intel lib32-vulkan-intel
set -e

# -----------------------------
# Helpers
# -----------------------------
pacman_install() {
  sudo pacman -S --needed --noconfirm "$@"
}

yay_install() {
  yay -S --needed --noconfirm "$@"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# Enable multilib
# -----------------------------
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo "==> Enabling multilib..."
  sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
  sudo pacman -Sy --noconfirm
fi

# -----------------------------
# System update
# -----------------------------
echo "==> Updating system..."
sudo pacman -Syu --noconfirm

# -----------------------------
# Diagnose
# -----------------------------
if [ -f "$SCRIPT_DIR/diagnose.sh" ]; then
  bash "$SCRIPT_DIR/diagnose.sh"
fi

# -----------------------------
# Base packages
# -----------------------------
pacman_install \
  kitty \
  bluez bluez-utils \
  base-devel git cpio cmake pkg-config gcc \
  hyprland sudo wget curl \
  wayland wayland-protocols \
  xorg-xwayland xorg-xhost \
  pipewire wireplumber \
  greetd \
  pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack \
  lib32-pipewire lib32-pipewire-jack lib32-libpulse \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  polkit-gnome \
  efibootmgr \
  zsh zsh-autosuggestions zsh-syntax-highlighting \
  nautilus gparted \
  rofi waybar slurp grim cliphist hyprlock hypridle \
  qalculate-gtk btop cava cowsay \
  gnome-clocks gnome-text-editor \
  inter-font noto-fonts-emoji nerd-fonts noto-fonts-cjk \
  adw-gtk-theme ntfs-3g \
  wine-mono wine-gecko winetricks zenity \
  ffmpeg gamescope telegram-desktop \
  gst-plugins-{base,good,bad,ugly} \
  samba gnutls sdl2-compat \
  swaync \
  font-manager \
  mangohud lib32-mangohud gamemode lib32-gamemode goverlay vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools steam \
  discord \
  blueman \
  scrcpy wayvnc \
  thermald \
  flatpak \
  xdg-utils \
  linux-headers \
  ufw \
  swww \
  eog \
  matugen \
  jq \
  brightnessctl \
  fastfetch \
  rofi-emoji \
  pacman-contrib \
  rsync \
  vulkan-headers \
  power-profiles-daemon \
  gobject-introspection python-gobject \
  satty \
  qt5-base qt6-base qt5-tools qt6-tools qt5-wayland qt6-wayland \
  evince \
  totem \
  unrar \
  rofimoji \
  file-roller \
  gnome-calendar \
  gnome-weather \
  vkd3d \
  sound-theme-freedesktop libcanberra libcanberra-pulse socat \
  gnome-system-monitor \
  timeshift \
  wtype \
  bc \
  hyprpicker \
  qt6-5compat qt5-graphicaleffects

# -----------------------------
# VirtualBox
# -----------------------------
read -rp "Install VirtualBox? [y/N]: " VBOX_CONFIRM
if [[ "$VBOX_CONFIRM" =~ ^[Yy]$ ]]; then
  sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-modules-arch
  sudo modprobe vboxdrv
  sudo modprobe vboxnetflt
  sudo modprobe vboxnetadp
fi

# -----------------------------
# Remove bad portal
# -----------------------------
sudo pacman -Rns --noconfirm xdg-desktop-portal-wlr 2>/dev/null || true

# -----------------------------
# Enable PipeWire
# -----------------------------
sudo systemctl enable greetd.service
sudo systemctl enable --now bluetooth
systemctl --user enable --now pipewire.service
systemctl --user enable --now wireplumber.service
systemctl --user enable --now pipewire-pulse.socket
systemctl --user enable --now pipewire-pulse.service
sudo systemctl enable --now thermald.service
sudo systemctl enable --now ufw.service
sudo systemctl enable --now power-profiles-daemon

# -----------------------------
# Configure greetd
# -----------------------------
GREETD_CONFIG="/etc/greetd/config.toml"
USERNAME=$(whoami)

echo "==> Configuring greetd..."

sudo grep -q '^\[default_session\]' "$GREETD_CONFIG" || \
  sudo tee -a "$GREETD_CONFIG" >/dev/null <<EOF
[default_session]
command = "start-hyprland"
user = "$USERNAME"
EOF

sudo sed -i "
/^\[default_session\]/,/^\[/ {
  s/^command *=.*/command = \"start-hyprland\"/
  s/^user *=.*/user = \"$USERNAME\"/
}
" "$GREETD_CONFIG"

sudo grep -q '^command *= *"start-hyprland"' "$GREETD_CONFIG" || \
  sudo sed -i '/^\[default_session\]/a command = "start-hyprland"' "$GREETD_CONFIG"

sudo grep -q "^user *= *\"$USERNAME\"" "$GREETD_CONFIG" || \
  sudo sed -i "/^\[default_session\]/a user = \"$USERNAME\"" "$GREETD_CONFIG"

# -----------------------------
# Editor setup
# -----------------------------
echo "Select editor to install:"
echo "1) NvChad (neovim)"
echo "2) nano"
echo "3) Skip"
read -rp "Choice [1/2/3]: " EDITOR_CHOICE

if [[ "$EDITOR_CHOICE" == "1" ]]; then
  sudo pacman -S --needed --noconfirm neovim
  NVIM_DIR="$HOME/.config/nvim"
  NVCHAD_MARKER="$NVIM_DIR/lua/core/init.lua"
  if [ ! -f "$NVCHAD_MARKER" ]; then
    echo "==> Installing NvChad..."
    git clone https://github.com/NvChad/starter "$NVIM_DIR" || true
  else
    echo "==> NvChad already installed, skipping clone"
  fi
  cp -f "$HOME/nvim_plugins/*" "$NVIM_DIR/lua/plugins/"
  nvim
  INIT_LUA="$NVIM_DIR/init.lua"
  if ! grep -q "Load matugen colors" "$INIT_LUA" 2>/dev/null; then
    cat >> "$INIT_LUA" <<'EOF'
-- Load matugen colors after startup
vim.schedule(function()
  require "mappings"
  local colors = vim.fn.stdpath("config") .. "/colors.lua"
  if vim.fn.filereadable(colors) == 1 then
    dofile(colors)
  end
end)
EOF
  fi
  COLORS_LUA="$NVIM_DIR/colors.lua"
  [ -f "$COLORS_LUA" ] || touch "$COLORS_LUA"
elif [[ "$EDITOR_CHOICE" == "2" ]]; then
  echo "==> Installing nano..."
  sudo pacman -S --needed --noconfirm nano
else
  echo "==> Skipping editor install."
fi

# -----------------------------
# AUR packages
# -----------------------------
yay_install \
  pavucontrol \
  bibata-cursor-theme-bin \
  heroic-games-launcher-bin \
  elecwhat-bin \
  ttf-symbola \
  freedownloadmanager \
  visual-studio-code-bin \
  proton-ge-custom-bin \
  protonup-qt-bin \
  spotify \
  cmatrix-git \
  overskride-bin \
  nmgui-bin \
  network-manager-applet \
  ocean-sound-theme \
  adwsteamgtk \
  dxvk-bin \
  darkly-qt6-git \
  darkly-qt5-git \
  swayosd-git \
  snappy-switcher

# -----------------------------
# Browser
# -----------------------------
echo "Select browser to install:"
echo "1) Brave"
echo "2) Zen Browser"
echo "3) Firefox"
echo "4) Google Chrome"
echo "5) Skip"
read -rp "Choice [1/2/3/4/5]: " BROWSER_CHOICE

case "$BROWSER_CHOICE" in
  1) yay -S --needed --noconfirm brave-bin ;;
  2) yay -S --needed --noconfirm zen-browser-bin ;;
  3) sudo pacman -S --needed --noconfirm firefox ;;
  4) yay -S --needed --noconfirm google-chrome ;;
  *) echo "==> Skipping browser install." ;;
esac

cd /usr/share/icons/
sudo rm -rf Bibata-Modern-Amber Bibata-Modern-Amber-Right Bibata-Modern-Classic-Right Bibata-Modern-Ice Bibata-Modern-Ice-Right Bibata-Original-Amber Bibata-Original-Amber Bibata-Original-Amber-Right Bibata-Original-Classic Bibata-Original-Classic-Right Bibata-Original-Ice Bibata-Original-Ice-Right
cd ~/

# -----------------------------
# Flatpak
# -----------------------------
read -rp "Install Roblox (Sober)? [y/N]: " ROBLOX_CONFIRM
if [[ "$ROBLOX_CONFIRM" =~ ^[Yy]$ ]]; then
  flatpak install flathub org.vinegarhq.Sober || true
fi

# -----------------------------
# Nautilus default
# -----------------------------
xdg-mime query default inode/directory | grep -q Nautilus || \
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# -----------------------------
# Deploy dotfiles (force overwrite)
# -----------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
curl -sS https://starship.rs/install.sh | sh
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo "==> Copying dotfiles to home (overwrite enabled)..."

# Copy .config (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.config" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.config/" "$HOME/.config/"
fi
# Copy .local (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.local" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.local/"  "$HOME/.local/"
fi
# Copy .zshrc (replace file)
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
  rsync -a --checksum "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
fi

# -----------------------------
# Monitor configuration
# -----------------------------
echo "==> Detecting monitors..."

MONITORS=()
MONITOR_INFO=()

if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
  mapfile -t RAW < <(hyprctl monitors -j 2>/dev/null)
  mapfile -t MONITOR_NAMES < <(echo "${RAW[@]}" | jq -r '.[].name')
  mapfile -t MONITOR_RES   < <(echo "${RAW[@]}" | jq -r '.[].width|tostring' | paste - <(echo "${RAW[@]}" | jq -r '.[].height|tostring') | sed 's/\t/x/')
  mapfile -t MONITOR_HZ    < <(echo "${RAW[@]}" | jq -r '.[].refreshRate')
  mapfile -t MONITOR_MAKE  < <(echo "${RAW[@]}" | jq -r '.[].make // "Unknown"')
  mapfile -t MONITOR_MODEL < <(echo "${RAW[@]}" | jq -r '.[].model // "Unknown"')
else
  if command -v kmsprint &>/dev/null; then
    mapfile -t MONITOR_NAMES < <(kmsprint | grep -oP '(?<=Connector )\S+')
  else
    mapfile -t MONITOR_NAMES < <(ls /sys/class/drm/ | grep -v render | grep -v card[0-9]$ | sed 's/card[0-9]-//')
  fi
  MONITOR_RES=()
  MONITOR_HZ=()
  MONITOR_MAKE=()
  MONITOR_MODEL=()
  for m in "${MONITOR_NAMES[@]}"; do
    MONITOR_RES+=("unknown")
    MONITOR_HZ+=("unknown")
    MONITOR_MAKE+=("unknown")
    MONITOR_MODEL+=("unknown")
  done
fi

MONITOR_COUNT=${#MONITOR_NAMES[@]}

if [[ "$MONITOR_COUNT" -eq 0 ]]; then
  echo "==> No monitors detected, skipping monitor configuration."
else
  echo ""
  echo "==> Detected monitors:"
  for i in "${!MONITOR_NAMES[@]}"; do
    echo "  [$((i+1))] ${MONITOR_NAMES[$i]} — ${MONITOR_MAKE[$i]} ${MONITOR_MODEL[$i]} — ${MONITOR_RES[$i]} @ ${MONITOR_HZ[$i]}Hz"
  done
  echo ""

  # --- Primary monitor ---
  PRIMARY_IDX=0
  if [[ "$MONITOR_COUNT" -gt 1 ]]; then
    while true; do
      read -rp "Select primary monitor [1-${MONITOR_COUNT}]: " PRIMARY_CHOICE
      if [[ "$PRIMARY_CHOICE" =~ ^[0-9]+$ ]] && (( PRIMARY_CHOICE >= 1 && PRIMARY_CHOICE <= MONITOR_COUNT )); then
        PRIMARY_IDX=$(( PRIMARY_CHOICE - 1 ))
        break
      fi
      echo "  Invalid choice, try again."
    done
  else
    echo "==> Only one monitor detected, setting it as primary."
  fi
  PRIMARY_MON="${MONITOR_NAMES[$PRIMARY_IDX]}"
  echo "==> Primary monitor: $PRIMARY_MON"

  # --- Per-monitor layout configuration ---
  declare -A MON_POSITION
  declare -A MON_ALIGN
  declare -A MON_TRANSFORM

  for i in "${!MONITOR_NAMES[@]}"; do
    MON="${MONITOR_NAMES[$i]}"
    [[ "$i" -eq "$PRIMARY_IDX" ]] && LABEL="(primary)" || LABEL=""
    echo ""
    echo "--- Configuring monitor: $MON $LABEL ---"

    if [[ "$i" -ne "$PRIMARY_IDX" ]]; then
      echo "  Where should $MON be placed relative to the primary monitor?"
      echo "    1) Left"
      echo "    2) Right"
      echo "    3) Above (top)"
      echo "    4) Below (bottom)"
      while true; do
        read -rp "  Choice [1-4]: " SIDE_CHOICE
        case "$SIDE_CHOICE" in
          1) MON_POSITION[$i]="left"  ; break ;;
          2) MON_POSITION[$i]="right" ; break ;;
          3) MON_POSITION[$i]="top"   ; break ;;
          4) MON_POSITION[$i]="bottom"; break ;;
          *) echo "  Invalid choice, try again." ;;
        esac
      done

      SIDE="${MON_POSITION[$i]}"
      if [[ "$SIDE" == "left" || "$SIDE" == "right" ]]; then
        echo "  How should $MON be vertically aligned relative to the primary?"
        echo "    1) Top-aligned"
        echo "    2) Center-aligned"
        echo "    3) Bottom-aligned"
        while true; do
          read -rp "  Choice [1-3]: " ALIGN_CHOICE
          case "$ALIGN_CHOICE" in
            1) MON_ALIGN[$i]="top"   ; break ;;
            2) MON_ALIGN[$i]="center"; break ;;
            3) MON_ALIGN[$i]="bottom"; break ;;
            *) echo "  Invalid choice, try again." ;;
          esac
        done
      else
        echo "  How should $MON be horizontally aligned relative to the primary?"
        echo "    1) Left-aligned"
        echo "    2) Center-aligned"
        echo "    3) Right-aligned"
        while true; do
          read -rp "  Choice [1-3]: " ALIGN_CHOICE
          case "$ALIGN_CHOICE" in
            1) MON_ALIGN[$i]="left"  ; break ;;
            2) MON_ALIGN[$i]="center"; break ;;
            3) MON_ALIGN[$i]="right" ; break ;;
            *) echo "  Invalid choice, try again." ;;
          esac
        done
      fi
    else
      MON_POSITION[$i]="primary"
      MON_ALIGN[$i]="none"
    fi

    echo "  Orientation for $MON:"
    echo "    1) Horizontal (normal)"
    echo "    2) Vertical (rotated 90° clockwise)"
    echo "    3) Vertical (rotated 90° counter-clockwise)"
    echo "    4) Upside-down (180°)"
    while true; do
      read -rp "  Choice [1-4]: " ORI_CHOICE
      case "$ORI_CHOICE" in
        1) MON_TRANSFORM[$i]="0"; break ;;
        2) MON_TRANSFORM[$i]="1"; break ;;
        3) MON_TRANSFORM[$i]="3"; break ;;
        4) MON_TRANSFORM[$i]="2"; break ;;
        *) echo "  Invalid choice, try again." ;;
      esac
    done
  done

  # --- Generate hyprland monitor config ---
  HYPR_CONF_DIR="$HOME/.config/hypr"
  MONITORS_CONF="$HYPR_CONF_DIR/hyprland/monitors.conf"
  mkdir -p "$HYPR_CONF_DIR/hyprland"

  echo "==> Writing monitor config to $MONITORS_CONF ..."
  : > "$MONITORS_CONF"

  get_res() { echo "${MONITOR_RES[$1]:-preferred}"; }
  get_hz()  { echo "${MONITOR_HZ[$1]:-0}"; }

  PRI_RES=$(get_res "$PRIMARY_IDX")
  PRI_HZ=$(get_hz   "$PRIMARY_IDX")
  PRI_W=$(echo "$PRI_RES" | cut -dx -f1)
  PRI_H=$(echo "$PRI_RES" | cut -dx -f2)
  PRI_TRANSFORM="${MON_TRANSFORM[$PRIMARY_IDX]}"

  echo -e "## Main Monitor" >> "$MONITORS_CONF"
  echo "monitor=${MONITOR_NAMES[$PRIMARY_IDX]}, ${PRI_RES}@${PRI_HZ}, 0x0, 1, transform, $PRI_TRANSFORM" >> "$MONITORS_CONF"

  for i in "${!MONITOR_NAMES[@]}"; do
    [[ "$i" -eq "$PRIMARY_IDX" ]] && continue

    MON="${MONITOR_NAMES[$i]}"
    MON_RES=$(get_res "$i")
    MON_HZ=$(get_hz   "$i")
    MON_W=$(echo "$MON_RES" | cut -dx -f1)
    MON_H=$(echo "$MON_RES" | cut -dx -f2)
    TRANSFORM="${MON_TRANSFORM[$i]}"
    SIDE="${MON_POSITION[$i]}"
    ALIGN="${MON_ALIGN[$i]}"

    if [[ "$TRANSFORM" == "1" || "$TRANSFORM" == "3" ]]; then
      EFF_W=$MON_H; EFF_H=$MON_W
      EFF_PRI_W=$PRI_H; EFF_PRI_H=$PRI_W
    else
      EFF_W=$MON_W; EFF_H=$MON_H
      EFF_PRI_W=$PRI_W; EFF_PRI_H=$PRI_H
    fi

    case "$SIDE" in
      left)
        POS_X=$(( -EFF_W ))
        case "$ALIGN" in
          top)    POS_Y=0 ;;
          center) POS_Y=$(( (EFF_PRI_H - EFF_H) / 2 )) ;;
          bottom) POS_Y=$(( EFF_PRI_H - EFF_H )) ;;
        esac
        ;;
      right)
        POS_X=$EFF_PRI_W
        case "$ALIGN" in
          top)    POS_Y=0 ;;
          center) POS_Y=$(( (EFF_PRI_H - EFF_H) / 2 )) ;;
          bottom) POS_Y=$(( EFF_PRI_H - EFF_H )) ;;
        esac
        ;;
      top)
        POS_Y=$(( -EFF_H ))
        case "$ALIGN" in
          left)   POS_X=0 ;;
          center) POS_X=$(( (EFF_PRI_W - EFF_W) / 2 )) ;;
          right)  POS_X=$(( EFF_PRI_W - EFF_W )) ;;
        esac
        ;;
      bottom)
        POS_Y=$EFF_PRI_H
        case "$ALIGN" in
          left)   POS_X=0 ;;
          center) POS_X=$(( (EFF_PRI_W - EFF_W) / 2 )) ;;
          right)  POS_X=$(( EFF_PRI_W - EFF_W )) ;;
        esac
        ;;
    esac

    echo -e "\n## Monitor $((i+1))" >> "$MONITORS_CONF"
    echo "monitor=$MON, ${MON_RES}@${MON_HZ}, ${POS_X}x${POS_Y}, 1, transform, $TRANSFORM" >> "$MONITORS_CONF"
  done

  echo ""
  echo "==> Generated $MONITORS_CONF:"
  cat "$MONITORS_CONF"
  echo ""

  HYPRLAND_CONF="$HYPR_CONF_DIR/hyprland.conf"
  if [ -f "$HYPRLAND_CONF" ]; then
    grep -q "monitors.conf" "$HYPRLAND_CONF" || \
      sed -i '1s|^|source = ~/.config/hypr/hyprland/monitors.conf\n|' "$HYPRLAND_CONF"
  fi
fi

# -----------------------------
# Hyprlock username
# -----------------------------
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$HYPRLOCK_CONF" ]; then
  echo "Hyprlock display name:"
  echo "1) Keep default (\$USER)"
  echo "2) Set custom name"
  read -rp "Choice [1/2]: " HYPRLOCK_CHOICE
  if [[ "$HYPRLOCK_CHOICE" == "2" ]]; then
    read -rp "Enter display name: " HYPRLOCK_NAME
    sed -i "s/text = \$USER/text = $HYPRLOCK_NAME/" "$HYPRLOCK_CONF"
  fi
fi

# -----------------------------
# Root GTK theming
# -----------------------------
sudo mkdir -p /root/.config
sudo ln -sf ~/.config/gtk-3.0 /root/.config/
sudo ln -sf ~/.config/gtk-4.0 /root/.config/
sudo ln -sf ~/.config/nvim /root/.config/

# -----------------------------
# X access for root apps
# -----------------------------
xhost +SI:localuser:root || true

# -----------------------------
# Time & NTP
# -----------------------------
TIMEZONE=$(curl -s https://ipapi.co/timezone)
sudo timedatectl set-timezone "$TIMEZONE"
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true

timedatectl status | grep -E "Time zone|System clock synchronized|NTP service"

cd ~/
git clone https://github.com/vinceliuice/Colloid-icon-theme.git; cd Colloid-icon-theme/
./install.sh -s default
cd ~/
rm -rf Colloid-icon-theme/

mkdir -p ~/Videos ~/Documents ~/Pictures ~/Downloads ~/Desktop
echo
echo "✅ Setup complete."

MONITOR_FPS=60

if command -v hyprctl &> /dev/null && command -v jq &> /dev/null; then
    detected_fps=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .refreshRate' | cut -d'.' -f1)
    if [[ -n "$detected_fps" && "$detected_fps" != "null" ]]; then
        MONITOR_FPS="$detected_fps"
    fi
fi

TRANSITION_FPS="$MONITOR_FPS"

awww img "$HOME/n4zl-dotfiles/wallpaper.jpg" --transition-type wipe --transition-angle 120 --transition-duration 2 --transition-fps "$TRANSITION_FPS"
matugen image "$HOME/n4zl-dotfiles/wallpaper.jpg"  --type scheme-tonal-spot --source-color-index 0 -m dark
~/.config/rofi/scripts/reload_apps.sh

# -----------------------------
# Reboot confirmation
# -----------------------------
read -rp "🔄 Reboot now? [y/N]: " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo "Reboot skipped."
fi
