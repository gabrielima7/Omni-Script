#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: colors.sh
# Description: ANSI color utilities and theme management
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_COLORS_LOADED:-}" ]] && return 0
readonly _OMNI_COLORS_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Color Output Functions
# ─────────────────────────────────────────────────────────────────────────────

# Print with color
print_color() {
    local color="$1"; shift
    echo -e "${color}$*${RST}"
}

# Semantic color prints
print_success() { print_color "$COLOR_SUCCESS" "$@"; }
print_error() { print_color "$COLOR_ERROR" "$@"; }
print_warning() { print_color "$COLOR_WARNING" "$@"; }
print_info() { print_color "$COLOR_INFO" "$@"; }
print_debug() { print_color "$COLOR_DEBUG" "$@"; }
print_header() { print_color "$COLOR_HEADER" "$@"; }
print_accent() { print_color "$COLOR_ACCENT" "$@"; }

# Bold prints
print_bold() { echo -e "${BOLD}$*${RST}"; }
print_dim() { echo -e "${DIM}$*${RST}"; }

# ─────────────────────────────────────────────────────────────────────────────
# Gradient Text (256 colors)
# ─────────────────────────────────────────────────────────────────────────────
print_gradient() {
    local text="$1"
    local start_color="${2:-51}"  # Cyan
    local end_color="${3:-201}"   # Magenta
    local len=${#text}
    local step=$(( (end_color - start_color) / (len > 1 ? len - 1 : 1) ))
    local color="$start_color"
    
    for ((i=0; i<len; i++)); do
        printf '\033[38;5;%dm%s' "$color" "${text:i:1}"
        color=$((color + step))
    done
    printf '%s' "$RST"
    echo
}

# ─────────────────────────────────────────────────────────────────────────────
# Rainbow Text
# ─────────────────────────────────────────────────────────────────────────────
print_rainbow() {
    local text="$1"
    local colors=(196 208 226 46 51 141 201)
    local len=${#text}
    local color_count=${#colors[@]}
    
    for ((i=0; i<len; i++)); do
        local color_idx=$((i % color_count))
        printf '\033[38;5;%dm%s' "${colors[$color_idx]}" "${text:i:1}"
    done
    printf '%s' "$RST"
    echo
}

# ─────────────────────────────────────────────────────────────────────────────
# Status Line
# ─────────────────────────────────────────────────────────────────────────────
print_status() {
    local icon="$1"
    local message="$2"
    local color="${3:-$CYBER_CYAN}"
    echo -e "${color}${icon}${RST} ${message}"
}

print_status_ok() { print_status "$ICON_SUCCESS" "$1" "$NEON_GREEN"; }
print_status_fail() { print_status "$ICON_ERROR" "$1" "$BLOOD_RED"; }
print_status_warn() { print_status "$ICON_WARNING" "$1" "$FIRE_ORANGE"; }
print_status_info() { print_status "$ICON_INFO" "$1" "$CYBER_CYAN"; }
