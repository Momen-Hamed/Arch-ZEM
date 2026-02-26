#!/usr/bin/env bash
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
  base-devel git \
  hyprland sudo wget curl \
  wayland wayland-protocols \
  xorg-xwayland xorg-xhost \
  pipewire wireplumber \
  greetd greetd-gtkgreet \
  pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack \
  lib32-pipewire lib32-pipewire-jack lib32-libpulse \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  polkit-gnome \
  efibootmgr \
  zsh zsh-autosuggestions zsh-syntax-highlighting \
  nautilus gparted \
  rofi waybar slurp grim cliphist hyprlock hypridle \
  qalculate-gtk btop cava neovim \
  gnome-clocks gnome-text-editor \
  inter-font noto-fonts-emoji nerd-fonts noto-fonts-cjk \
  adw-gtk-theme ntfs-3g \
  wine wine-mono wine-gecko winetricks \
  ffmpeg gamescope telegram-desktop \
  gst-plugins-{base,good,bad,ugly} \
  samba gnutls sdl2-compat \
  virtualbox virtualbox-host-modules-arch \
  swaync \
  font-manager \
  mangohud lib32-mangohud gamemode lib32-gamemode goverlay vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools mesa lib32-mesa intel-media-driver steam \
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
  power-profiles-daemon \
  gobject-introspection python-gobject \
  satty \
  qt5-base qt6-base qt5-tools qt6-tools qt5-wayland qt6-wayland \
  evince \
  haruna

sudo modprobe vboxdrv
sudo modprobe vboxnetflt
sudo modprobe vboxnetadp

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

echo "==> Configuring greetd..."

sudo mkdir -p /etc/greetd
sudo touch "$GREETD_CONFIG"

sudo grep -q '^\[default_session\]' "$GREETD_CONFIG" || \
  sudo tee -a "$GREETD_CONFIG" >/dev/null <<EOF

[default_session]
command = "start-hyprland"
user = "ziadlawatey"
EOF

sudo sed -i '
/^\[default_session\]/,/^\[/ {
  s/^command *=.*/command = "start-hyprland"/
  s/^user *=.*/user = "ziadlawatey"/
}
' "$GREETD_CONFIG"

sudo grep -q '^command *= *"start-hyprland"' "$GREETD_CONFIG" || \
  sudo sed -i '/^\[default_session\]/a command = "start-hyprland"' "$GREETD_CONFIG"

sudo grep -q '^user *= *"ziadlawatey"' "$GREETD_CONFIG" || \
  sudo sed -i '/^\[default_session\]/a user = "ziadlawatey"' "$GREETD_CONFIG"


# -----------------------------
# NvChad setup
# -----------------------------
NVIM_DIR="$HOME/.config/nvim"
NVCHAD_MARKER="$NVIM_DIR/lua/core/init.lua"

if [ ! -f "$NVCHAD_MARKER" ]; then
  echo "==> Installing NvChad..."
  git clone https://github.com/NvChad/starter "$NVIM_DIR" || true
else
  echo "==> NvChad already installed, skipping clone"
fi

# always run these
cp -f N4ZL-Dotfiles/nvim_plugins/* "$NVIM_DIR/lua/plugins/"
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

# -----------------------------
# Install yay
# -----------------------------
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
fi

# -----------------------------
# AUR packages
# -----------------------------
yay_install \
  waypaper \
  pavucontrol \
  bibata-cursor-theme-bin \
  heroic-games-launcher-bin \
  elecwhat-bin \
  ttf-symbola \
  wttrbar \
  freedownloadmanager \
  zen-browser-bin \
  visual-studio-code-bin \
  proton-ge-custom-bin \
  protonup-qt-bin
  spotify \
  cmatrix-git

cd /usr/share/icons/
sudo rm -rf Bibata-Modern-Amber Bibata-Modern-Amber-Right Bibata-Modern-Classic-Right Bibata-Modern-Ice Bibata-Modern-Ice-Right Bibata-Original-Amber Bibata-Original-Amber Bibata-Original-Amber-Right Bibata-Original-Classic Bibata-Original-Classic-Right Bibata-Original-Ice Bibata-Original-Ice-Right
cd ~/

# -----------------------------
# Flatpak
# -----------------------------
flatpak install flathub org.vinegarhq.Sober || true

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
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "==> Copying dotfiles to home (overwrite enabled)..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy .config (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.config" ]; then
  rsync -a "$SCRIPT_DIR/.config/" "$HOME/.config/"
fi

# Copy .local (merge, overwrite same files)
if [ -d "$SCRIPT_DIR/.local" ]; then
  rsync -a "$SCRIPT_DIR/.local/"  "$HOME/.local/"
fi

# Copy .zshrc (replace file)
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
  cp -f "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
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
sudo timedatectl set-timezone Asia/Riyadh
sudo timedatectl set-local-rtc 1 --adjust-system-clock
sudo timedatectl set-ntp true

timedatectl status | grep -E "Time zone|System clock synchronized|NTP service"

cd ~/
git clone https://github.com/vinceliuice/Colloid-icon-theme.git; cd Colloid-icon-theme/
./install.sh -s default
cd ~/
rm -rf Colloid-icon-theme/

cd /mnt

sudo mkdir overall_storage others windows

echo
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


#grim -g "$(slurp)" - | satty --early-exit --action-on-enter save-to-file --right-click-copy --filename - --output-filename ~/Pictures/screenshots/$(date '+%y-%d:%m-%H:%M').png


