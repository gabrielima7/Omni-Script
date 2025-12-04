#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: utils.sh
# Description: Common utility functions for Omni-Script
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_UTILS_LOADED:-}" ]] && return 0
readonly _OMNI_UTILS_LOADED=1

# ─────────────────────────────────────────────────────────────────────────────
# String Utilities
# ─────────────────────────────────────────────────────────────────────────────
trim() { local s="$*"; s="${s#"${s%%[![:space:]]*}"}"; echo "${s%"${s##*[![:space:]]}"}"; }
to_lower() { echo "${1,,}"; }
to_upper() { echo "${1^^}"; }
is_empty() { [[ -z "$(trim "$1")" ]]; }
contains() { [[ "$1" == *"$2"* ]]; }
starts_with() { [[ "$1" == "$2"* ]]; }
ends_with() { [[ "$1" == *"$2" ]]; }
repeat_char() { printf '%*s' "$2" '' | tr ' ' "$1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Array Utilities
# ─────────────────────────────────────────────────────────────────────────────
array_contains() { local n="$1"; shift; for e in "$@"; do [[ "$e" == "$n" ]] && return 0; done; return 1; }
array_join() { local d="$1"; shift; local f=1; for e in "$@"; do [[ $f == 1 ]] && { printf '%s' "$e"; f=0; } || printf '%s%s' "$d" "$e"; done; }

# ─────────────────────────────────────────────────────────────────────────────
# Validation Utilities
# ─────────────────────────────────────────────────────────────────────────────
is_integer() { [[ "$1" =~ ^-?[0-9]+$ ]]; }
is_positive_integer() { [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]; }
is_valid_port() { is_positive_integer "$1" && [[ "$1" -le 65535 ]]; }

is_valid_ipv4() {
    local ip="$1" IFS='.'; local -a o; read -ra o <<< "$ip"
    [[ ${#o[@]} -eq 4 ]] || return 1
    for x in "${o[@]}"; do [[ "$x" =~ ^[0-9]+$ && "$x" -ge 0 && "$x" -le 255 ]] || return 1; done
}

# ─────────────────────────────────────────────────────────────────────────────
# File Utilities
# ─────────────────────────────────────────────────────────────────────────────
file_exists() { [[ -f "$1" && -r "$1" ]]; }
dir_exists() { [[ -d "$1" ]]; }
ensure_dir() { [[ -d "$1" ]] || mkdir -p "$1"; }
file_size() { [[ -f "$1" ]] && stat -c%s "$1" 2>/dev/null || echo 0; }

# ─────────────────────────────────────────────────────────────────────────────
# System Utilities
# ─────────────────────────────────────────────────────────────────────────────
is_root() { [[ "$(id -u)" -eq 0 ]]; }
cmd_exists() { command -v "$1" &>/dev/null; }
get_current_user() { whoami; }
get_home_dir() { echo "${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"; }
is_terminal() { [[ -t 0 ]]; }
supports_colors() { [[ -t 1 && -n "${TERM:-}" && "$TERM" != "dumb" ]]; }
get_terminal_width() { [[ -t 1 ]] && tput cols 2>/dev/null || echo 80; }

# ─────────────────────────────────────────────────────────────────────────────
# Network Utilities
# ─────────────────────────────────────────────────────────────────────────────
url_reachable() { curl -sf --connect-timeout "${2:-5}" -o /dev/null "$1" 2>/dev/null; }
get_public_ip() { curl -sf --max-time 5 https://api.ipify.org 2>/dev/null || echo "unknown"; }
get_local_ip() { hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Date/Time Utilities
# ─────────────────────────────────────────────────────────────────────────────
get_timestamp() { date '+%Y-%m-%dT%H:%M:%S%z'; }
get_date() { date '+%Y-%m-%d'; }
get_epoch() { date '+%s'; }

format_duration() {
    local s="$1" h=$((s/3600)) m=$(((s%3600)/60)) sec=$((s%60))
    [[ $h -gt 0 ]] && printf "%dh %dm %ds" "$h" "$m" "$sec" && return
    [[ $m -gt 0 ]] && printf "%dm %ds" "$m" "$sec" && return
    printf "%ds" "$sec"
}

# ─────────────────────────────────────────────────────────────────────────────
# JSON Utilities
# ─────────────────────────────────────────────────────────────────────────────
has_jq() { cmd_exists jq; }
json_get() { has_jq && jq -r "$2" <<< "$1" 2>/dev/null || echo ""; }

# ─────────────────────────────────────────────────────────────────────────────
# Retry Logic
# ─────────────────────────────────────────────────────────────────────────────
retry() {
    local max="${1:-3}" delay="${2:-1}"; shift 2
    local attempt=1
    until "$@"; do [[ $attempt -ge $max ]] && return 1; sleep "$delay"; delay=$((delay*2)); ((attempt++)); done
}

# ─────────────────────────────────────────────────────────────────────────────
# Cleanup Utilities
# ─────────────────────────────────────────────────────────────────────────────
declare -ga _CLEANUP_FUNCTIONS=() _CLEANUP_FILES=()
register_cleanup() { _CLEANUP_FUNCTIONS+=("$1"); }
register_cleanup_file() { _CLEANUP_FILES+=("$1"); }
run_cleanup() {
    for f in "${_CLEANUP_FUNCTIONS[@]}"; do declare -f "$f" &>/dev/null && "$f" 2>/dev/null; done
    for f in "${_CLEANUP_FILES[@]}"; do rm -f "$f" 2>/dev/null; done
}
setup_cleanup_trap() { trap run_cleanup EXIT INT TERM; }
