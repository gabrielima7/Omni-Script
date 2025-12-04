#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: progress.sh
# Description: Progress bars for downloads and installations
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_PROGRESS_LOADED:-}" ]] && return 0
readonly _OMNI_PROGRESS_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Progress Bar
# ─────────────────────────────────────────────────────────────────────────────
progress_bar() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    local width="${4:-30}"
    local extra="${5:-}"
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Build bar
    local bar="${NEON_GREEN}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${DARK_GRAY}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${RST}"
    
    # Display
    printf "\r${CYBER_CYAN}%s${RST}  [%s]  ${BOLD}%3d%%${RST}  %s" "$label" "$bar" "$percent" "$extra"
}

# ─────────────────────────────────────────────────────────────────────────────
# Complete Progress Bar
# ─────────────────────────────────────────────────────────────────────────────
progress_complete() {
    local label="${1:-Progress}"
    local message="${2:-Complete}"
    printf "\r\033[K${NEON_GREEN}${ICON_SUCCESS}${RST} ${label} - ${message}\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# Download Progress (for curl)
# ─────────────────────────────────────────────────────────────────────────────
download_with_progress() {
    local url="$1"
    local output="$2"
    local label="${3:-Downloading}"
    
    curl -# -L -o "$output" "$url" 2>&1 | \
        stdbuf -oL tr '\r' '\n' | \
        while IFS= read -r line; do
            if [[ "$line" =~ ([0-9]+\.[0-9]) ]]; then
                local pct="${BASH_REMATCH[1]%.*}"
                progress_bar "$pct" 100 "$label" 30
            fi
        done
    
    progress_complete "$label"
}

# ─────────────────────────────────────────────────────────────────────────────
# Multi-step Progress
# ─────────────────────────────────────────────────────────────────────────────
declare -g _STEP_CURRENT=0
declare -g _STEP_TOTAL=0

steps_init() {
    _STEP_TOTAL="$1"
    _STEP_CURRENT=0
}

step_next() {
    local message="$1"
    ((_STEP_CURRENT++))
    echo -e "${CYBER_CYAN}[${_STEP_CURRENT}/${_STEP_TOTAL}]${RST} ${message}"
}

step_done() {
    local message="${1:-Step complete}"
    echo -e "      ${NEON_GREEN}${ICON_DONE}${RST} ${DIM}${message}${RST}"
}

step_fail() {
    local message="${1:-Step failed}"
    echo -e "      ${BLOOD_RED}${ICON_FAIL}${RST} ${message}"
}
