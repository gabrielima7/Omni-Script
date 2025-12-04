#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: adapter_base.sh
# Description: Abstract base interface for target adapters (Strategy Pattern)
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_ADAPTER_BASE_LOADED:-}" ]] && return 0
readonly _OMNI_ADAPTER_BASE_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Current Adapter State
# ─────────────────────────────────────────────────────────────────────────────
declare -g CURRENT_ADAPTER=""
declare -g CURRENT_TARGET=""

# ─────────────────────────────────────────────────────────────────────────────
# Load Adapter
# ─────────────────────────────────────────────────────────────────────────────
load_adapter() {
    local target="$1"
    local adapter_dir
    adapter_dir="$(dirname "${BASH_SOURCE[0]}")"
    
    case "$target" in
        docker)
            source "${adapter_dir}/docker_adapter.sh"
            CURRENT_ADAPTER="docker"
            ;;
        podman)
            source "${adapter_dir}/podman_adapter.sh"
            CURRENT_ADAPTER="podman"
            ;;
        lxc)
            source "${adapter_dir}/lxc_adapter.sh"
            CURRENT_ADAPTER="lxc"
            ;;
        baremetal|bare)
            source "${adapter_dir}/baremetal_adapter.sh"
            CURRENT_ADAPTER="baremetal"
            ;;
        *)
            log_error "Unknown target: $target"
            return 1
            ;;
    esac
    
    CURRENT_TARGET="$target"
    log_debug "Loaded adapter: ${CURRENT_ADAPTER}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Adapter Interface (to be implemented by each adapter)
# ─────────────────────────────────────────────────────────────────────────────

# Check if adapter prerequisites are met
adapter_check() {
    log_error "adapter_check not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Install an application
adapter_install() {
    log_error "adapter_install not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Remove an application
adapter_remove() {
    log_error "adapter_remove not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Start a service/container
adapter_start() {
    log_error "adapter_start not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Stop a service/container
adapter_stop() {
    log_error "adapter_stop not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Get logs
adapter_logs() {
    log_error "adapter_logs not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Get status
adapter_status() {
    log_error "adapter_status not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Backup
adapter_backup() {
    log_error "adapter_backup not implemented for ${CURRENT_ADAPTER}"
    return 1
}

# Restore
adapter_restore() {
    log_error "adapter_restore not implemented for ${CURRENT_ADAPTER}"
    return 1
}
