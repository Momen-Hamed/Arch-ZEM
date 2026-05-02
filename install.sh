#!/usr/bin/env bash

# mesa lib32-mesa -media-driver vulkan-intel lib32-vulkan-intel
set -e

SCRIPT_DIR="$HOME/n4zl-dotfiles"

# -----------------------------
# Helpers
# -----------------------------
pacman_install() {
  sudo pacman -S --needed --noconfirm "$@"
}

yay_install() {
  yay -S --needed --noconfirm "$@"
}

is_installed() {
  pacman -Q "$1" &>/dev/null
}

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
if is_installed virtualbox; then
  echo "==> VirtualBox already installed, skipping."
else
  read -rp "Install VirtualBox? [y/N]: " VBOX_CONFIRM
  if [[ "$VBOX_CONFIRM" =~ ^[Yy]$ ]]; then
    sudo pacman -S --needed --noconfirm virtualbox virtualbox-host-modules-arch
    sudo modprobe vboxdrv
    sudo modprobe vboxnetflt
    sudo modprobe vboxnetadp
  fi
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
setup_nvim_extras() {
  NVIM_DIR="$HOME/.config/nvim"

  if [ ! -f "$NVIM_DIR/init.lua" ]; then
    echo "==> Installing NvChad..."
    git clone https://github.com/NvChad/starter "$NVIM_DIR" || true
  else
    echo "==> NvChad already installed, skipping clone"
  fi

  echo "==> Syncing nvim plugins..."
  cp -f "$SCRIPT_DIR"/nvim_plugins/* "$NVIM_DIR/lua/plugins/" 2>/dev/null || true

  INIT_LUA="$NVIM_DIR/init.lua"
  if ! grep -q "Load matugen colors" "$INIT_LUA" 2>/dev/null; then
    cat >> "$INIT_LUA" <<'EOF'
-- Load matugen colors after startup
vim.schedule(function()
  local colors = vim.fn.stdpath("config") .. "/colors.lua"
  if vim.fn.filereadable(colors) == 1 then
    local ok, err = pcall(dofile, colors)
    if not ok then
      vim.notify("colors.lua: " .. err, vim.log.levels.WARN)
    end
  end
end)
EOF
  fi

  COLORS_LUA="$NVIM_DIR/colors.lua"
  [ -f "$COLORS_LUA" ] || touch "$COLORS_LUA"
  echo "" > "$COLORS_LUA"

  echo "==> Installing nvim plugins in background..."
  nohup nvim --headless "+Lazy sync" +qa > /tmp/nvim-lazy.log 2>&1 &
  echo "==> Plugin sync running in background, check /tmp/nvim-lazy.log for details."
}

if is_installed neovim; then
  echo "==> Neovim already installed, checking plugins..."
  setup_nvim_extras
elif is_installed nano || is_installed vim; then
  echo "==> Editor already installed, skipping editor setup."
else
  echo "Select editor to install:"
  echo "1) neovim"
  echo "2) nano"
  echo "3) vim"
  echo "4) Skip"
  read -rp "Choice [1/2/3/4]: " EDITOR_CHOICE

  if [[ "$EDITOR_CHOICE" == "1" ]]; then
    sudo pacman -S --needed --noconfirm neovim
    setup_nvim_extras
  elif [[ "$EDITOR_CHOICE" == "2" ]]; then
    echo "==> Installing nano..."
    sudo pacman -S --needed --noconfirm nano
  elif [[ "$EDITOR_CHOICE" == "3" ]]; then
    echo "==> Installing vim..."
    sudo pacman -S --needed --noconfirm vim
  else
    echo "==> Skipping editor install."
  fi
fi

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
if ! command -v yay &>/dev/null; then
  echo "==> Installing yay..."
  
  TMP_DIR=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
  cd "$TMP_DIR/yay"
  makepkg -si --noconfirm
  cd ~

  rm -rf "$TMP_DIR"

  # Also remove any yay folder left in home
  rm -rf "$HOME/yay"
else
  echo "==> yay already installed, skipping."
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
for browser in firefox brave-bin google-chrome zen-browser-bin; do
  if is_installed "$browser"; then
    echo "==> Browser already installed ($browser), skipping."
    BROWSER_FOUND=1
    break
  fi
done

if [[ -z "$BROWSER_FOUND" ]]; then
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
fi

cd /usr/share/icons/
sudo rm -rf Bibata-Modern-Amber Bibata-Modern-Amber-Right Bibata-Modern-Classic-Right Bibata-Modern-Ice Bibata-Modern-Ice-Right Bibata-Original-Amber Bibata-Original-Amber Bibata-Original-Amber-Right Bibata-Original-Classic Bibata-Original-Classic-Right Bibata-Original-Ice Bibata-Original-Ice-Right
cd "$SCRIPT_DIR"

# -----------------------------
# Flatpak (Roblox)
# -----------------------------
if flatpak list | grep -q org.vinegarhq.Sober; then
  echo "==> Sober already installed, skipping."
else
  read -rp "Install Roblox (Sober)? [y/N]: " ROBLOX_CONFIRM
  if [[ "$ROBLOX_CONFIRM" =~ ^[Yy]$ ]]; then
    flatpak install flathub org.vinegarhq.Sober || true
  fi
fi

# -----------------------------
# Nautilus default
# -----------------------------
xdg-mime query default inode/directory | grep -q Nautilus || \
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# -----------------------------
# Deploy dotfiles (force overwrite)
# -----------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
else
  echo "==> Oh My Zsh already installed, skipping."
fi

if ! command -v starship &>/dev/null; then
  echo "==> Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "==> starship already installed, skipping."
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
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
# Diagnose
# -----------------------------
if [ -f "$SCRIPT_DIR/diagnose.sh" ]; then
  bash "$SCRIPT_DIR/diagnose.sh"
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

if [ ! -d "/usr/share/icons/Colloid" ]; then
  echo "==> Installing Colloid icon theme..."
  TMP_DIR=$(mktemp -d)
  git clone https://github.com/vinceliuice/Colloid-icon-theme.git "$TMP_DIR/colloid"
  cd "$TMP_DIR/colloid"
  ./install.sh -s default
  cd ~
  rm -rf "$TMP_DIR"
else
  echo "==> Colloid icon theme already installed, skipping."
fi

mkdir -p ~/Videos ~/Documents ~/Pictures/Screenshots/ ~/Downloads ~/Desktop
echo

# -----------------------------
# Change default shell to zsh if not already
# -----------------------------
CURRENT_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)

if [[ "$CURRENT_SHELL" == "$(which zsh)" ]]; then
    echo "==> Default shell is already zsh, skipping."
else
    echo "==> Setting zsh as default shell for user $USERNAME..."
    chsh -s "$(which zsh)" "$USERNAME"
fi

EXECS_CONF="$HOME/.config/hypr/hyprland/execs.conf"

# Add both scripts to run on next boot
echo "exec-once = sleep 3 && ~/n4zl-dotfiles/scripts/monitors.sh && ~/n4zl-dotfiles/scripts/customization.sh" >> "$EXECS_CONF"

echo "exec-once = sleep 1.5 && ~/n4zl-dotfiles/scripts/applying_default_wallpaper.sh" >> "$EXECS_CONF"

echo "✅ Setup complete."


# -----------------------------
# Reboot confirmation
# -----------------------------
read -rp "🔄 Reboot now? [y/N]: " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo "Reboot skipped."
fi
