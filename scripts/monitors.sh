#!/usr/bin/env bash

if [ -z "$SCRIPT_KITTY_WINDOW" ]; then
    SCRIPT_KITTY_WINDOW=1 kitty --title "floating-kitty" bash "$0"
    exit 0
fi

# Get screen resolution and set window size
SCREEN_WIDTH=$(hyprctl monitors -j | jq '.[0].width')
SCREEN_HEIGHT=$(hyprctl monitors -j | jq '.[0].height')
WIN_WIDTH=$(( SCREEN_WIDTH * 55 / 100 ))
WIN_HEIGHT=$(( SCREEN_HEIGHT * 65 / 100 ))

hyprctl dispatch setfloating "title:^(floating-kitty)$" &>/dev/null
hyprctl dispatch resizewindowpixel "exact $WIN_WIDTH $WIN_HEIGHT,title:^(floating-kitty)$" &>/dev/null
hyprctl dispatch centerwindow "title:^(floating-kitty)$" &>/dev/null

BOLD="\e[1m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
DIM="\e[2m"
RESET="\e[0m"

header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║         Monitor Configuration Setup          ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() { echo -e "\n${BOLD}${YELLOW}  >> $1${RESET}\n"; }
success()  { echo -e "${GREEN}  ✔ $1${RESET}"; }
prompt()   { echo -e -n "${CYAN}  $1${RESET} "; }
back_or_invalid() { echo -e "${RED}  Invalid choice. Enter 'b' to go back or try again.${RESET}"; }

transform_label() {
    case "$1" in
        0) echo "Normal" ;;
        1) echo "90° clockwise" ;;
        2) echo "180° (upside-down)" ;;
        3) echo "90° counter-clockwise" ;;
        *) echo "Unknown" ;;
    esac
}

detect_monitors() {
    header
    section "Detecting Monitors"

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
            mapfile -t MONITOR_NAMES < <(ls /sys/class/drm/ | grep -v render | grep -v "card[0-9]$" | sed 's/card[0-9]-//')
        fi
        MONITOR_RES=(); MONITOR_HZ=(); MONITOR_MAKE=(); MONITOR_MODEL=()
        for m in "${MONITOR_NAMES[@]}"; do
            MONITOR_RES+=("unknown"); MONITOR_HZ+=("unknown")
            MONITOR_MAKE+=("unknown"); MONITOR_MODEL+=("unknown")
        done
    fi

    MONITOR_COUNT=${#MONITOR_NAMES[@]}

    if [[ "$MONITOR_COUNT" -eq 0 ]]; then
        echo -e "${RED}  No monitors detected. Exiting.${RESET}"
        read -rp "  Press Enter to close..."
        exit 1
    fi

    echo -e "  ${BOLD}Found ${MONITOR_COUNT} monitor(s):${RESET}\n"
    for i in "${!MONITOR_NAMES[@]}"; do
        echo -e "  ${BOLD}[${CYAN}$((i+1))${RESET}${BOLD}]${RESET} ${MONITOR_NAMES[$i]}"
        echo -e "      ${DIM}${MONITOR_MAKE[$i]} ${MONITOR_MODEL[$i]} — ${MONITOR_RES[$i]} @ ${MONITOR_HZ[$i]}Hz${RESET}"
        echo ""
    done
}

step_primary() {
    header
    section "Step 1 — Select Primary Monitor"
    echo -e "  ${DIM}Your primary monitor is where your taskbar and main workspace will be.${RESET}\n"
    for i in "${!MONITOR_NAMES[@]}"; do
        echo -e "  ${BOLD}[${CYAN}$((i+1))${RESET}${BOLD}]${RESET} ${MONITOR_NAMES[$i]} — ${MONITOR_MAKE[$i]} ${MONITOR_MODEL[$i]} — ${MONITOR_RES[$i]} @ ${MONITOR_HZ[$i]}Hz"
    done
    echo ""

    if [[ "$MONITOR_COUNT" -eq 1 ]]; then
        PRIMARY_IDX=0
        success "Only one monitor detected — set as primary automatically."
        sleep 1
        return 0
    fi

    while true; do
        prompt "Select primary monitor [1-${MONITOR_COUNT}] (b=back): "
        read -r CHOICE
        [[ "$CHOICE" == "b" ]] && return 1
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= MONITOR_COUNT )); then
            PRIMARY_IDX=$(( CHOICE - 1 ))
            success "Primary monitor set to: ${MONITOR_NAMES[$PRIMARY_IDX]}"
            sleep 0.5
            return 0
        fi
        back_or_invalid
    done
}

step_scale() {
    local i=$1
    local LABEL="$2"
    local MON="${MONITOR_NAMES[$i]}"

    header
    section "$LABEL — Scale"
    echo -e "  Monitor: ${BOLD}${CYAN}$MON${RESET} ${DIM}(${MONITOR_RES[$i]})${RESET}"
    echo -e "  ${DIM}Scale controls UI element size. 1 = native, 2 = double (HiDPI).${RESET}\n"
    echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} 1      (native)"
    echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} 1.25"
    echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} 1.5"
    echo -e "  ${BOLD}[${CYAN}4${RESET}${BOLD}]${RESET} 1.75"
    echo -e "  ${BOLD}[${CYAN}5${RESET}${BOLD}]${RESET} 2      (HiDPI)"
    echo -e "  ${BOLD}[${CYAN}6${RESET}${BOLD}]${RESET} Custom"
    echo ""

    while true; do
        prompt "Choice [1-6] (b=back): "
        read -r CHOICE
        [[ "$CHOICE" == "b" ]] && return 1
        case "$CHOICE" in
            1) MON_SCALE[$i]="1"    ; return 0 ;;
            2) MON_SCALE[$i]="1.25" ; return 0 ;;
            3) MON_SCALE[$i]="1.5"  ; return 0 ;;
            4) MON_SCALE[$i]="1.75" ; return 0 ;;
            5) MON_SCALE[$i]="2"    ; return 0 ;;
            6)
                while true; do
                    prompt "Enter custom scale (e.g. 1.33) or b to go back: "
                    read -r CUSTOM
                    [[ "$CUSTOM" == "b" ]] && break
                    if [[ "$CUSTOM" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                        MON_SCALE[$i]="$CUSTOM"
                        return 0
                    fi
                    echo -e "${RED}  Invalid. Enter a number like 1.5${RESET}"
                done
                ;;
            *) back_or_invalid ;;
        esac
    done
}

step_position() {
    local i=$1
    local MON="${MONITOR_NAMES[$i]}"

    header
    section "Step — Monitor Position"
    echo -e "  Configuring: ${BOLD}${CYAN}$MON${RESET} ${DIM}(${MONITOR_MAKE[$i]} ${MONITOR_MODEL[$i]} — ${MONITOR_RES[$i]} @ ${MONITOR_HZ[$i]}Hz)${RESET}"
    echo -e "  Primary: ${BOLD}${MONITOR_NAMES[$PRIMARY_IDX]}${RESET}\n"
    echo -e "  Where should ${BOLD}$MON${RESET} be placed relative to the primary?\n"
    echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} Left"
    echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} Right"
    echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} Above"
    echo -e "  ${BOLD}[${CYAN}4${RESET}${BOLD}]${RESET} Below"
    echo ""

    while true; do
        prompt "Choice [1-4] (b=back): "
        read -r CHOICE
        [[ "$CHOICE" == "b" ]] && return 1
        case "$CHOICE" in
            1) MON_POSITION[$i]="left"  ; return 0 ;;
            2) MON_POSITION[$i]="right" ; return 0 ;;
            3) MON_POSITION[$i]="top"   ; return 0 ;;
            4) MON_POSITION[$i]="bottom"; return 0 ;;
            *) back_or_invalid ;;
        esac
    done
}

step_align() {
    local i=$1
    local MON="${MONITOR_NAMES[$i]}"
    local SIDE="${MON_POSITION[$i]}"

    # Skip alignment if same resolution as primary
    if [[ "${MONITOR_RES[$i]}" == "${MONITOR_RES[$PRIMARY_IDX]}" ]]; then
        MON_ALIGN[$i]="center"
        return 0
    fi

    header
    section "Step — Monitor Alignment"
    echo -e "  Configuring: ${BOLD}${CYAN}$MON${RESET} — placed ${BOLD}${SIDE}${RESET} of primary\n"

    if [[ "$SIDE" == "left" || "$SIDE" == "right" ]]; then
        echo -e "  How should ${BOLD}$MON${RESET} be vertically aligned?\n"
        echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} Top"
        echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} Center"
        echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} Bottom"
        echo ""
        while true; do
            prompt "Choice [1-3] (b=back): "
            read -r CHOICE
            [[ "$CHOICE" == "b" ]] && return 1
            case "$CHOICE" in
                1) MON_ALIGN[$i]="top"   ; return 0 ;;
                2) MON_ALIGN[$i]="center"; return 0 ;;
                3) MON_ALIGN[$i]="bottom"; return 0 ;;
                *) back_or_invalid ;;
            esac
        done
    else
        echo -e "  How should ${BOLD}$MON${RESET} be horizontally aligned?\n"
        echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} Left"
        echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} Center"
        echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} Right"
        echo ""
        while true; do
            prompt "Choice [1-3] (b=back): "
            read -r CHOICE
            [[ "$CHOICE" == "b" ]] && return 1
            case "$CHOICE" in
                1) MON_ALIGN[$i]="left"  ; return 0 ;;
                2) MON_ALIGN[$i]="center"; return 0 ;;
                3) MON_ALIGN[$i]="right" ; return 0 ;;
                *) back_or_invalid ;;
            esac
        done
    fi
}

step_orientation() {
    local i=$1
    local MON="${MONITOR_NAMES[$i]}"
    local LABEL="$2"

    header
    section "$LABEL — Orientation"
    echo -e "  Configuring: ${BOLD}${CYAN}$MON${RESET}\n"
    echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} Normal (horizontal)"
    echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} Rotated 90° clockwise"
    echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} Rotated 90° counter-clockwise"
    echo -e "  ${BOLD}[${CYAN}4${RESET}${BOLD}]${RESET} Upside-down (180°)"
    echo ""

    while true; do
        prompt "Choice [1-4] (b=back): "
        read -r CHOICE
        [[ "$CHOICE" == "b" ]] && return 1
        case "$CHOICE" in
            1) MON_TRANSFORM[$i]="0"; return 0 ;;
            2) MON_TRANSFORM[$i]="1"; return 0 ;;
            3) MON_TRANSFORM[$i]="3"; return 0 ;;
            4) MON_TRANSFORM[$i]="2"; return 0 ;;
            *) back_or_invalid ;;
        esac
    done
}

step_review() {
    header
    section "Review Configuration"

    echo -e "  ${BOLD}Primary Monitor:${RESET} ${CYAN}${MONITOR_NAMES[$PRIMARY_IDX]}${RESET}"
    echo -e "  ${DIM}${MONITOR_MAKE[$PRIMARY_IDX]} ${MONITOR_MODEL[$PRIMARY_IDX]} — ${MONITOR_RES[$PRIMARY_IDX]} @ ${MONITOR_HZ[$PRIMARY_IDX]}Hz${RESET}"
    echo -e "  Scale: ${MON_SCALE[$PRIMARY_IDX]}"
    echo ""

    for i in "${!MONITOR_NAMES[@]}"; do
        [[ "$i" -eq "$PRIMARY_IDX" ]] && continue
        local SAME_RES_NOTE=""
        [[ "${MONITOR_RES[$i]}" == "${MONITOR_RES[$PRIMARY_IDX]}" ]] && SAME_RES_NOTE=" ${DIM}(same res — auto-centered)${RESET}"
        echo -e "  ${BOLD}Monitor $((i+1)):${RESET} ${CYAN}${MONITOR_NAMES[$i]}${RESET}"
        echo -e "  ${DIM}${MONITOR_MAKE[$i]} ${MONITOR_MODEL[$i]} — ${MONITOR_RES[$i]} @ ${MONITOR_HZ[$i]}Hz${RESET}"
        echo -e "  Position:    ${MON_POSITION[$i]} of primary${SAME_RES_NOTE}"
        echo -e "  Orientation: $(transform_label "${MON_TRANSFORM[$i]}")"
        echo -e "  Scale:       ${MON_SCALE[$i]}"
        echo ""
    done

    echo -e "  ${BOLD}[${CYAN}1${RESET}${BOLD}]${RESET} Apply and save"
    echo -e "  ${BOLD}[${CYAN}2${RESET}${BOLD}]${RESET} Start over"
    echo -e "  ${BOLD}[${CYAN}3${RESET}${BOLD}]${RESET} Quit without saving"
    echo ""

    while true; do
        prompt "Choice [1-3]: "
        read -r CHOICE
        case "$CHOICE" in
            1) return 0 ;;
            2) return 2 ;;
            3) return 3 ;;
            *) back_or_invalid ;;
        esac
    done
}

write_config() {
    HYPR_CONF_DIR="$HOME/.config/hypr"
    MONITORS_CONF="$HYPR_CONF_DIR/hyprland/monitors.conf"
    mkdir -p "$HYPR_CONF_DIR/hyprland"
    : > "$MONITORS_CONF"

    get_res() { echo "${MONITOR_RES[$1]:-preferred}"; }
    get_hz()  { echo "${MONITOR_HZ[$1]:-0}"; }

    PRI_RES=$(get_res "$PRIMARY_IDX")
    PRI_HZ=$(get_hz "$PRIMARY_IDX")
    PRI_W=$(echo "$PRI_RES" | cut -dx -f1)
    PRI_H=$(echo "$PRI_RES" | cut -dx -f2)
    PRI_SCALE="${MON_SCALE[$PRIMARY_IDX]}"

    echo "## Main Monitor" >> "$MONITORS_CONF"
    echo "monitor=${MONITOR_NAMES[$PRIMARY_IDX]}, ${PRI_RES}@${PRI_HZ}, 0x0, ${PRI_SCALE}, transform, 0" >> "$MONITORS_CONF"

    for i in "${!MONITOR_NAMES[@]}"; do
        [[ "$i" -eq "$PRIMARY_IDX" ]] && continue

        MON="${MONITOR_NAMES[$i]}"
        MON_RES=$(get_res "$i")
        MON_HZ=$(get_hz "$i")
        MON_W=$(echo "$MON_RES" | cut -dx -f1)
        MON_H=$(echo "$MON_RES" | cut -dx -f2)
        TRANSFORM="${MON_TRANSFORM[$i]}"
        SIDE="${MON_POSITION[$i]}"
        ALIGN="${MON_ALIGN[$i]}"
        SCALE="${MON_SCALE[$i]}"

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
                esac ;;
            right)
                POS_X=$EFF_PRI_W
                case "$ALIGN" in
                    top)    POS_Y=0 ;;
                    center) POS_Y=$(( (EFF_PRI_H - EFF_H) / 2 )) ;;
                    bottom) POS_Y=$(( EFF_PRI_H - EFF_H )) ;;
                esac ;;
            top)
                POS_Y=$(( -EFF_H ))
                case "$ALIGN" in
                    left)   POS_X=0 ;;
                    center) POS_X=$(( (EFF_PRI_W - EFF_W) / 2 )) ;;
                    right)  POS_X=$(( EFF_PRI_W - EFF_W )) ;;
                esac ;;
            bottom)
                POS_Y=$EFF_PRI_H
                case "$ALIGN" in
                    left)   POS_X=0 ;;
                    center) POS_X=$(( (EFF_PRI_W - EFF_W) / 2 )) ;;
                    right)  POS_X=$(( EFF_PRI_W - EFF_W )) ;;
                esac ;;
        esac

        echo "" >> "$MONITORS_CONF"
        echo "## Monitor $((i+1))" >> "$MONITORS_CONF"
        echo "monitor=$MON, ${MON_RES}@${MON_HZ}, ${POS_X}x${POS_Y}, ${SCALE}, transform, $TRANSFORM" >> "$MONITORS_CONF"
    done

    HYPRLAND_CONF="$HYPR_CONF_DIR/hyprland.conf"
    if [ -f "$HYPRLAND_CONF" ]; then
        grep -q "monitors.conf" "$HYPRLAND_CONF" || \
            sed -i '1s|^|source = ~/.config/hypr/hyprland/monitors.conf\n|' "$HYPRLAND_CONF"
    fi

    header
    section "Done!"
    success "Config written to: $MONITORS_CONF"
    echo ""
    echo -e "${DIM}"
    cat "$MONITORS_CONF"
    echo -e "${RESET}"
    read -rp "  Press Enter to close..."
}

declare -A MON_POSITION
declare -A MON_ALIGN
declare -A MON_TRANSFORM
declare -A MON_SCALE

main() {
    detect_monitors

    while true; do
        step_primary || continue

        # Scale for primary
        while true; do
            step_scale "$PRIMARY_IDX" "Primary Monitor" && break || continue
        done

        local all_done=true
        for i in "${!MONITOR_NAMES[@]}"; do
            [[ "$i" -eq "$PRIMARY_IDX" ]] && continue

            # Position + Alignment
            while true; do
                step_position "$i" || { all_done=false; break 2; }
                step_align "$i" && break || continue
            done

            # Orientation
            while true; do
                step_orientation "$i" "Secondary Monitor" && break || {
                    step_align "$i" || break
                }
            done

            # Scale for secondary
            while true; do
                step_scale "$i" "Secondary Monitor" && break || {
                    step_orientation "$i" "Secondary Monitor" || break
                }
            done
        done

        $all_done || continue

        step_review
        local rv=$?
        case $rv in
            0) write_config; break ;;
            2) continue ;;
            3) break ;;
        esac
    done
}

main

sed -i 's/sleep 3 && ~\/n4zl-dotfiles\/scripts\/monitors\.sh && /sleep 3 && /' "$HOME/.config/hypr/hyprland/execs.conf"
