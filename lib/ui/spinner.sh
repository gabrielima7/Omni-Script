#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: spinner.sh
# Description: Non-blocking spinners and loading animations
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_SPINNER_LOADED:-}" ]] && return 0
readonly _OMNI_SPINNER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Spinner State
# ─────────────────────────────────────────────────────────────────────────────
declare -g _SPINNER_PID=""
declare -g _SPINNER_MSG=""

# ─────────────────────────────────────────────────────────────────────────────
# Start Spinner
# ─────────────────────────────────────────────────────────────────────────────
spinner_start() {
    local message="${1:-Loading...}"
    local style="${2:-dots}"
    _SPINNER_MSG="$message"
    
    # Select frames based on style
    local -a frames
    case "$style" in
        braille)  frames=("${SPINNER_BRAILLE[@]}") ;;
        arrows)   frames=("${SPINNER_ARROWS[@]}") ;;
        lines)    frames=("${SPINNER_LINES[@]}") ;;
        blocks)   frames=("${SPINNER_BLOCKS[@]}") ;;
        *)        frames=("${SPINNER_DOTS[@]}") ;;
    esac
    
    # Kill existing spinner
    spinner_stop 2>/dev/null
    
    # Start background spinner
    (
        local i=0
        local count=${#frames[@]}
        while true; do
            printf "\r${CYBER_CYAN}%s${RST} %s " "${frames[$i]}" "$message"
            i=$(( (i + 1) % count ))
            sleep 0.1
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Stop Spinner
# ─────────────────────────────────────────────────────────────────────────────
spinner_stop() {
    local status="${1:-success}"
    local message="${2:-$_SPINNER_MSG}"
    
    if [[ -n "$_SPINNER_PID" ]] && kill -0 "$_SPINNER_PID" 2>/dev/null; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null
    fi
    _SPINNER_PID=""
    
    # Clear line and show final status
    printf "\r\033[K"
    case "$status" in
        success) echo -e "${NEON_GREEN}${ICON_SUCCESS}${RST} ${message}" ;;
        error)   echo -e "${BLOOD_RED}${ICON_ERROR}${RST} ${message}" ;;
        warn)    echo -e "${FIRE_ORANGE}${ICON_WARNING}${RST} ${message}" ;;
        *)       echo -e "${CYBER_CYAN}${ICON_INFO}${RST} ${message}" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Run with Spinner
# ─────────────────────────────────────────────────────────────────────────────
with_spinner() {
    local message="$1"; shift
    local cmd=("$@")
    
    spinner_start "$message"
    if "${cmd[@]}" &>/dev/null; then
        spinner_stop "success" "$message"
        return 0
    else
        spinner_stop "error" "$message failed"
        return 1
    fi
}
