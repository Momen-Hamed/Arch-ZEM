#!/usr/bin/env bash
# hardware-detect.sh
# Detects battery, GPU vendor/generation, and installs the correct drivers.
# Part of Hyprland dotfiles.

# ─── GPU Detection ────────────────────────────────────────────────────────────

detect_gpu() {
    local gpu_info vendor="unknown" brand="unknown"

    if command -v lspci &>/dev/null; then
        gpu_info=$(lspci 2>/dev/null | grep -iE 'vga|3d|display')
    fi

    if [[ -z "$gpu_info" ]]; then
        gpu_info=$(grep -r '' /sys/class/drm/*/device/vendor 2>/dev/null)
    fi

    case "${gpu_info,,}" in
        *nvidia*)                          vendor="nvidia"; brand="NVIDIA" ;;
        *amd*|*radeon*|*"advanced micro"*) vendor="amd";   brand="AMD"    ;;
        *intel*)                           vendor="intel";  brand="Intel"  ;;
        *"0x10de"*)                        vendor="nvidia"; brand="NVIDIA" ;;
        *"0x1002"*)                        vendor="amd";    brand="AMD"    ;;
        *"0x8086"*)                        vendor="intel";  brand="Intel"  ;;
    esac

    GPU_VENDOR="$vendor"
    GPU_BRAND="$brand"
    GPU_RAW="$gpu_info"
}

# ─── GPU Generation Detection ─────────────────────────────────────────────────

detect_gpu_gen() {
    GPU_GEN="unknown"
    GPU_PACKAGES=""
    GPU_PACKAGES_EXTRA=""

    case "$GPU_VENDOR" in

        amd)
            local drm_driver
            drm_driver=$(cat /sys/class/drm/card0/device/uevent 2>/dev/null | grep -i driver | cut -d= -f2)

            if [[ "${drm_driver,,}" == "amdgpu" ]]; then
                GPU_GEN="GCN 3+ (amdgpu)"
                GPU_PACKAGES="vulkan-radeon lib32-vulkan-radeon"
                GPU_PACKAGES_EXTRA="libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau"
            elif [[ "${drm_driver,,}" == "radeon" ]]; then
                GPU_GEN="Pre-GCN 3 (radeon)"
                GPU_PACKAGES="mesa lib32-mesa"
            else
                GPU_GEN="unknown (driver: ${drm_driver:-not found})"
                GPU_PACKAGES="vulkan-radeon lib32-vulkan-radeon"
            fi
            ;;

        intel)
            local pci_id
            pci_id=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d|display' | grep -oP '\[8086:\K[0-9a-fA-F]+' | head -1)
            local pci_dec=0
            [[ -n "$pci_id" ]] && pci_dec=$((16#$pci_id))

            if (( pci_dec >= 0x5690 )); then
                GPU_GEN="Gen 12.5+ (Arc/Xe)"
                GPU_PACKAGES="vulkan-intel lib32-vulkan-intel intel-media-driver"
            elif (( pci_dec >= 0x1900 )); then
                GPU_GEN="Gen 9–12 (Skylake+)"
                GPU_PACKAGES="vulkan-intel lib32-vulkan-intel intel-media-driver"
            elif (( pci_dec >= 0x1600 )); then
                GPU_GEN="Gen 8 (Broadwell)"
                GPU_PACKAGES="vulkan-intel lib32-vulkan-intel libva-intel-driver"
            elif (( pci_dec >= 0x0100 )); then
                GPU_GEN="Gen 7–7.5 (Ivy Bridge/Haswell)"
                GPU_PACKAGES="vulkan-intel lib32-vulkan-intel libva-intel-driver"
                GPU_PACKAGES_EXTRA="# Note: incomplete Vulkan 1.3 support on Gen 7"
            else
                GPU_GEN="Gen 6 or older — no Vulkan"
                GPU_PACKAGES="mesa lib32-mesa"
            fi
            ;;

        nvidia)
            local model model_num
            model=$(echo "$GPU_RAW" | grep -oiP '(RTX|GTX|GT|GTS|Quadro|Tesla|MX)\s*[0-9]+[A-Za-z]*' | head -1)
            model_num=$(echo "$model" | grep -oP '[0-9]+' | head -1)

            if [[ -z "$model_num" ]]; then
                GPU_GEN="unknown NVIDIA"
                GPU_PACKAGES="nvidia-utils lib32-nvidia-utils"
            elif (( model_num >= 800 )); then
                GPU_GEN="Maxwell / Pascal / Turing / Ampere / Ada (900–4000 series)"
                GPU_PACKAGES="nvidia-utils lib32-nvidia-utils"
            elif (( model_num >= 600 )); then
                GPU_GEN="Kepler (600–700 series)"
                GPU_PACKAGES="nvidia-utils lib32-nvidia-utils"
                GPU_PACKAGES_EXTRA="# If issues arise try: nvidia-470xx-utils lib32-nvidia-470xx-utils (AUR)"
            elif (( model_num >= 400 )); then
                GPU_GEN="Fermi (400–500 series)"
                GPU_PACKAGES="nvidia-390xx-utils lib32-nvidia-390xx-utils"
            else
                GPU_GEN="Legacy (pre-Fermi)"
                GPU_PACKAGES="nvidia-340xx-utils"
            fi
            ;;

        *)
            GPU_GEN="unknown"
            GPU_PACKAGES="mesa lib32-mesa"
            ;;
    esac
}

# ─── Battery Detection ────────────────────────────────────────────────────────

detect_battery() {
    HAS_BATTERY=false
    BATTERY_STATUS="N/A"
    BATTERY_CAPACITY="N/A"

    for ps in /sys/class/power_supply/*/; do
        local type
        type=$(cat "${ps}type" 2>/dev/null)
        if [[ "$type" == "Battery" ]]; then
            HAS_BATTERY=true
            BATTERY_CAPACITY=$(cat "${ps}capacity" 2>/dev/null || echo "N/A")
            BATTERY_STATUS=$(cat "${ps}status"   2>/dev/null || echo "N/A")
            break
        fi
    done
}

# ─── Install ──────────────────────────────────────────────────────────────────

install_packages() {
    local pkgs="$1"

    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm $pkgs
    elif command -v yay &>/dev/null; then
        yay -S --needed --noconfirm $pkgs
    else
        sudo pacman -S --needed --noconfirm $pkgs
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

detect_gpu
detect_gpu_gen
detect_battery

echo "┌─ Hardware Detection ──────────────────────────────────────────┐"
echo "│"
echo "│  GPU Vendor  : $GPU_BRAND"
echo "│  GPU Gen     : $GPU_GEN"
if [[ -n "$GPU_RAW" ]]; then
    echo "│  GPU Info    : $(echo "$GPU_RAW" | head -1 | cut -c1-60)"
fi
echo "│"
if $HAS_BATTERY; then
    echo "│  Battery     : ✔  present"
    echo "│  Capacity    : ${BATTERY_CAPACITY}%"
    echo "│  Status      : $BATTERY_STATUS"
else
    echo "│  Battery     : ✘  not detected (desktop / unsupported)"
fi
echo "│"
echo "└───────────────────────────────────────────────────────────────┘"

echo ""
echo "┌─ Installing GPU Drivers ──────────────────────────────────────┐"
echo "│"
echo "│  Packages : $GPU_PACKAGES"
[[ -n "$GPU_PACKAGES_EXTRA" ]] && echo "│  Extra    : $GPU_PACKAGES_EXTRA"
echo "│"
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

all_packages="$GPU_PACKAGES"
if [[ -n "$GPU_PACKAGES_EXTRA" && "$GPU_PACKAGES_EXTRA" != "#"* ]]; then
    all_packages="$all_packages $GPU_PACKAGES_EXTRA"
fi

install_packages "$all_packages"

# ─── Battery cleanup ──────────────────────────────────────────────────────────

if ! $HAS_BATTERY; then
    BATTERY_SCRIPT="$HOME/.config/hypr/hyprlock/scripts/battery.sh"
    if [ -f "$BATTERY_SCRIPT" ]; then
        rm -f "$BATTERY_SCRIPT"
        echo "│  Battery script removed (no battery detected)"
    fi
fi

echo ""
echo "✔ Done."

export GPU_VENDOR GPU_BRAND GPU_GEN GPU_PACKAGES \
       HAS_BATTERY BATTERY_CAPACITY BATTERY_STATUS
