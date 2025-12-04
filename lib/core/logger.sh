#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: logger.sh
# Description: Structured logging system with levels, colors, and file output
# ═══════════════════════════════════════════════════════════════════════════════

# Prevent multiple sourcing
[[ -n "${_OMNI_LOGGER_LOADED:-}" ]] && return 0
readonly _OMNI_LOGGER_LOADED=1

# Source constants if not already loaded
if [[ -z "${_OMNI_CONSTANTS_LOADED:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Logger Configuration
# ─────────────────────────────────────────────────────────────────────────────
declare -g _LOG_FILE=""
declare -g _LOG_TO_FILE=false
declare -g _LOG_TIMESTAMP=true
declare -g _LOG_CALLER=false

# ─────────────────────────────────────────────────────────────────────────────
# Initialize Logger
# ─────────────────────────────────────────────────────────────────────────────
logger_init() {
    local log_dir="${1:-$OMNI_LOG_DIR}"
    local log_file="${2:-omni-$(date +%Y%m%d).log}"
    
    # Create log directory if needed
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || true
    fi
    
    _LOG_FILE="${log_dir}/${log_file}"
    _LOG_TO_FILE=true
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Current Timestamp
# ─────────────────────────────────────────────────────────────────────────────
_get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Caller Information
# ─────────────────────────────────────────────────────────────────────────────
_get_caller() {
    local frame="${1:-2}"
    local caller_info
    caller_info=$(caller "$frame" 2>/dev/null) || return
    local line func file
    read -r line func file <<< "$caller_info"
    echo "${file##*/}:${line}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Logging Function
# ─────────────────────────────────────────────────────────────────────────────
_log() {
    local level="$1"
    local level_num="$2"
    local color="$3"
    local icon="$4"
    shift 4
    local message="$*"
    
    # Check if we should log this level
    if [[ "$level_num" -lt "${OMNI_LOG_LEVEL:-1}" ]]; then
        return 0
    fi
    
    # Build the log line
    local timestamp=""
    local caller_info=""
    local log_line=""
    local plain_line=""
    
    if [[ "${_LOG_TIMESTAMP}" == "true" ]]; then
        timestamp="[$(_get_timestamp)] "
    fi
    
    if [[ "${_LOG_CALLER}" == "true" ]]; then
        caller_info="[$(_get_caller 3)] "
    fi
    
    # Formatted output for terminal
    log_line="${timestamp}${color}${icon} [${level}]${RST} ${caller_info}${message}"
    
    # Plain output for file
    plain_line="${timestamp}[${level}] ${caller_info}${message}"
    
    # Output to stderr for ERROR and FATAL, stdout otherwise
    if [[ "$level_num" -ge "$LOG_LEVEL_ERROR" ]]; then
        echo -e "$log_line" >&2
    else
        echo -e "$log_line"
    fi
    
    # Write to log file if enabled
    if [[ "${_LOG_TO_FILE}" == "true" && -n "${_LOG_FILE}" ]]; then
        echo "$plain_line" >> "$_LOG_FILE" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Public Logging Functions
# ─────────────────────────────────────────────────────────────────────────────

# Debug level - detailed information for debugging
log_debug() {
    _log "DEBUG" "$LOG_LEVEL_DEBUG" "$DARK_GRAY" "🔍" "$@"
}

# Info level - general information
log_info() {
    _log "INFO" "$LOG_LEVEL_INFO" "$CYBER_CYAN" "ℹ️ " "$@"
}

# Success message (info level but green)
log_success() {
    _log "INFO" "$LOG_LEVEL_INFO" "$NEON_GREEN" "✅" "$@"
}

# Warning level - potential issues
log_warn() {
    _log "WARN" "$LOG_LEVEL_WARN" "$FIRE_ORANGE" "⚠️ " "$@"
}

# Error level - errors that don't stop execution
log_error() {
    _log "ERROR" "$LOG_LEVEL_ERROR" "$BLOOD_RED" "❌" "$@"
}

# Fatal level - critical errors that stop execution
log_fatal() {
    _log "FATAL" "$LOG_LEVEL_FATAL" "$BLOOD_RED" "💀" "$@"
    exit "${EXIT_ERROR:-1}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Specialized Logging Functions
# ─────────────────────────────────────────────────────────────────────────────

# Step indicator for multi-step processes
log_step() {
    local step="$1"
    local total="$2"
    shift 2
    local message="$*"
    echo -e "${CYBER_CYAN}[${step}/${total}]${RST} ${message}"
}

# Section header
log_section() {
    local title="$*"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local line
    line=$(printf '%*s' "$width" '' | tr ' ' '─')
    echo ""
    echo -e "${ELECTRIC_PURPLE}${line}${RST}"
    echo -e "${ELECTRIC_PURPLE}$(printf '%*s' "$padding" '')${BOLD} ${title} ${RST}"
    echo -e "${ELECTRIC_PURPLE}${line}${RST}"
    echo ""
}

# Command execution log
log_cmd() {
    local cmd="$*"
    if [[ "${OMNI_VERBOSE:-false}" == "true" ]]; then
        echo -e "${DIM}  \$ ${cmd}${RST}"
    fi
}

# Dry run indicator
log_dry_run() {
    if [[ "${OMNI_DRY_RUN:-false}" == "true" ]]; then
        echo -e "${GOLD}[DRY-RUN]${RST} $*"
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Verbosity Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Print only in verbose mode
verbose() {
    if [[ "${OMNI_VERBOSE:-false}" == "true" ]]; then
        echo -e "${DIM}$*${RST}"
    fi
}

# Print debug info only if DEBUG level
debug() {
    if [[ "${OMNI_LOG_LEVEL:-1}" -le "$LOG_LEVEL_DEBUG" ]]; then
        echo -e "${DARK_GRAY}[DEBUG] $*${RST}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Assertion / Validation Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Assert a condition, log error and exit if false
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        log_fatal "$message"
    fi
}

# Check if command exists
require_cmd() {
    local cmd="$1"
    local install_hint="${2:-}"
    
    if ! command -v "$cmd" &>/dev/null; then
        if [[ -n "$install_hint" ]]; then
            log_error "Required command not found: $cmd"
            log_info "Install hint: $install_hint"
        else
            log_error "Required command not found: $cmd"
        fi
        return 1
    fi
    return 0
}

# Check multiple commands
require_cmds() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        return 1
    fi
    return 0
}
