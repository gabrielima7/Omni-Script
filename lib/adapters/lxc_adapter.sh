#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: lxc_adapter.sh
# Description: LXC/LXD target adapter
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_LXC_ADAPTER_LOADED:-}" ]] && return 0
readonly _OMNI_LXC_ADAPTER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
# ─────────────────────────────────────────────────────────────────────────────
adapter_check() {
    if ! cmd_exists lxc; then
        log_error "LXC/LXD not installed"
        return 1
    fi
    
    if ! lxc list &>/dev/null; then
        log_error "LXD not initialized or no permissions"
        return 1
    fi
    
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Create Container
# ─────────────────────────────────────────────────────────────────────────────
lxc_create() {
    local name="$1"
    local image="${2:-ubuntu:22.04}"
    local profile="${3:-default}"
    
    log_info "${ICON_LXC} Creating LXC container: ${name}"
    lxc launch "$image" "$name" -p "$profile"
}

# ─────────────────────────────────────────────────────────────────────────────
# Execute Command in Container
# ─────────────────────────────────────────────────────────────────────────────
lxc_exec() {
    local container="$1"
    shift
    lxc exec "$container" -- "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# Push File to Container
# ─────────────────────────────────────────────────────────────────────────────
lxc_push_file() {
    local container="$1"
    local src="$2"
    local dest="$3"
    lxc file push "$src" "${container}${dest}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────────────────────
adapter_install() {
    local app_name="$1"
    local container_name="${2:-${app_name}}"
    local image="${3:-ubuntu:22.04}"
    
    adapter_check || return 1
    
    # Create container if not exists
    if ! lxc info "$container_name" &>/dev/null; then
        lxc_create "$container_name" "$image"
        sleep 5  # Wait for container to start
    fi
    
    # Push and run install script
    local script_path="${OMNI_RECIPES_DIR}/applications/${app_name}/lxc.sh"
    if [[ -f "$script_path" ]]; then
        lxc_push_file "$container_name" "$script_path" "/tmp/install.sh"
        lxc_exec "$container_name" chmod +x /tmp/install.sh
        lxc_exec "$container_name" /tmp/install.sh
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Remove
# ─────────────────────────────────────────────────────────────────────────────
adapter_remove() {
    local container="$1"
    local force="${2:-false}"
    
    if [[ "$force" == "true" ]]; then
        lxc delete "$container" --force
    else
        lxc stop "$container" 2>/dev/null
        lxc delete "$container"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Start/Stop/Logs/Status
# ─────────────────────────────────────────────────────────────────────────────
adapter_start() { lxc start "$1"; }
adapter_stop() { lxc stop "$1"; }
adapter_logs() { lxc exec "$1" -- journalctl -f 2>/dev/null || lxc exec "$1" -- tail -f /var/log/syslog; }
adapter_status() { lxc list -f csv -c ns4 | grep "^$1,"; }

# ─────────────────────────────────────────────────────────────────────────────
# Backup (Export container)
# ─────────────────────────────────────────────────────────────────────────────
adapter_backup() {
    local container="$1"
    local backup_dir="${OMNI_BACKUP_DIR}/${container}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    ensure_dir "$backup_dir"
    log_info "Exporting ${container}..."
    lxc export "$container" "${backup_dir}/${container}_${timestamp}.tar.gz" --instance-only
    log_success "Backup: ${backup_dir}/${container}_${timestamp}.tar.gz"
}

# ─────────────────────────────────────────────────────────────────────────────
# Configure Network (Static IP)
# ─────────────────────────────────────────────────────────────────────────────
lxc_set_static_ip() {
    local container="$1"
    local ip="$2"
    local gateway="${3:-}"
    local device="${4:-eth0}"
    
    lxc config device override "$container" "$device" ipv4.address="$ip"
    [[ -n "$gateway" ]] && lxc config set "$container" user.network-gateway="$gateway"
}
