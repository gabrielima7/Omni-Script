#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: init.sh
# Description: System initialization and OS detection
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_INIT_LOADED:-}" ]] && return 0
readonly _OMNI_INIT_LOADED=1

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Global State
# ─────────────────────────────────────────────────────────────────────────────
declare -g OMNI_OS_ID=""
declare -g OMNI_OS_NAME=""
declare -g OMNI_OS_VERSION=""
declare -g OMNI_PKG_MANAGER=""
declare -g OMNI_ARCH=""

# ─────────────────────────────────────────────────────────────────────────────
# Detect Operating System
# ─────────────────────────────────────────────────────────────────────────────
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        OMNI_OS_ID="${ID:-unknown}"
        OMNI_OS_NAME="${NAME:-Unknown}"
        OMNI_OS_VERSION="${VERSION_ID:-unknown}"
    elif [[ -f /etc/lsb-release ]]; then
        # shellcheck source=/dev/null
        source /etc/lsb-release
        OMNI_OS_ID="${DISTRIB_ID,,}"
        OMNI_OS_NAME="${DISTRIB_DESCRIPTION:-Unknown}"
        OMNI_OS_VERSION="${DISTRIB_RELEASE:-unknown}"
    else
        OMNI_OS_ID="unknown"
        OMNI_OS_NAME="Unknown Linux"
        OMNI_OS_VERSION="unknown"
    fi

    # Detect architecture
    OMNI_ARCH="$(uname -m)"
    
    log_debug "Detected OS: ${OMNI_OS_NAME} (${OMNI_OS_ID} ${OMNI_OS_VERSION}) [${OMNI_ARCH}]"
}

# ─────────────────────────────────────────────────────────────────────────────
# Detect Package Manager
# ─────────────────────────────────────────────────────────────────────────────
detect_package_manager() {
    # Fallback: detect by available commands (most reliable)
    for pm in apt dnf yum pacman apk zypper; do
        if cmd_exists "$pm"; then
            OMNI_PKG_MANAGER="$pm"
            break
        fi
    done
    
    log_debug "Package manager: ${OMNI_PKG_MANAGER:-none}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Check Core Dependencies
# ─────────────────────────────────────────────────────────────────────────────
check_dependencies() {
    local missing=()
    local required_cmds=("curl" "grep" "sed" "awk")
    local optional_cmds=("jq" "docker" "podman" "lxc")
    
    for cmd in "${required_cmds[@]}"; do
        if ! cmd_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing required commands: ${missing[*]}"
        return 1
    fi
    
    # Log optional commands status
    for cmd in "${optional_cmds[@]}"; do
        if cmd_exists "$cmd"; then
            log_debug "Optional: $cmd ✓"
        fi
    done
    
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Detect Available Targets
# ─────────────────────────────────────────────────────────────────────────────
declare -ga OMNI_AVAILABLE_TARGETS=()

detect_targets() {
    OMNI_AVAILABLE_TARGETS=("baremetal")  # Always available
    
    if cmd_exists docker && docker info &>/dev/null; then
        OMNI_AVAILABLE_TARGETS+=("docker")
    fi
    
    if cmd_exists podman && podman info &>/dev/null; then
        OMNI_AVAILABLE_TARGETS+=("podman")
    fi
    
    if cmd_exists lxc && lxc list &>/dev/null; then
        OMNI_AVAILABLE_TARGETS+=("lxc")
    fi
    
    log_debug "Available targets: ${OMNI_AVAILABLE_TARGETS[*]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Create Required Directories
# ─────────────────────────────────────────────────────────────────────────────
init_directories() {
    local dirs=(
        "$OMNI_CACHE_DIR"
        "$OMNI_DATA_DIR"
        "$OMNI_CONFIG_DIR"
        "$OMNI_LOG_DIR"
        "$OMNI_BACKUP_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        ensure_dir "$dir"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Initialization
# ─────────────────────────────────────────────────────────────────────────────
omni_init() {
    detect_os
    detect_package_manager
    detect_targets
    init_directories
    check_dependencies
    setup_cleanup_trap
    
    log_debug "Omni-Script initialized successfully"
}
