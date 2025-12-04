#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: baremetal_adapter.sh
# Description: Bare metal (direct OS) target adapter
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_BAREMETAL_ADAPTER_LOADED:-}" ]] && return 0
readonly _OMNI_BAREMETAL_ADAPTER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../registry/packages.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
# ─────────────────────────────────────────────────────────────────────────────
adapter_check() {
    if ! is_root && [[ -z "${SUDO_USER:-}" ]]; then
        log_warn "Bare metal installation may require root privileges"
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────────────────────
adapter_install() {
    local app_name="$1"
    local script_path="${OMNI_RECIPES_DIR}/applications/${app_name}/baremetal.sh"
    
    log_info "${ICON_BAREMETAL} Installing ${app_name} on bare metal..."
    
    if [[ -f "$script_path" ]]; then
        # shellcheck source=/dev/null
        source "$script_path"
        if declare -f "install_${app_name}" &>/dev/null; then
            "install_${app_name}"
        else
            bash "$script_path"
        fi
    else
        log_error "No bare metal recipe found for ${app_name}"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Remove
# ─────────────────────────────────────────────────────────────────────────────
adapter_remove() {
    local app_name="$1"
    local pm="${OMNI_PKG_MANAGER:-apt}"
    
    case "$pm" in
        apt)    sudo apt-get remove -y "$app_name" ;;
        dnf)    sudo dnf remove -y "$app_name" ;;
        apk)    sudo apk del "$app_name" ;;
        pacman) sudo pacman -R --noconfirm "$app_name" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Service Management (systemd)
# ─────────────────────────────────────────────────────────────────────────────
adapter_start() {
    local service="$1"
    sudo systemctl start "$service"
}

adapter_stop() {
    local service="$1"
    sudo systemctl stop "$service"
}

adapter_status() {
    local service="$1"
    systemctl status "$service" --no-pager
}

adapter_logs() {
    local service="$1"
    local lines="${2:-100}"
    journalctl -u "$service" -n "$lines" -f
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup
# ─────────────────────────────────────────────────────────────────────────────
adapter_backup() {
    local app_name="$1"
    local backup_dir="${OMNI_BACKUP_DIR}/${app_name}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    ensure_dir "$backup_dir"
    
    # Backup common paths
    local paths=("/etc/${app_name}" "/var/lib/${app_name}" "/opt/${app_name}")
    
    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            local name
            name=$(basename "$path")
            tar czf "${backup_dir}/${name}_${timestamp}.tar.gz" -C "$(dirname "$path")" "$name" 2>/dev/null
        fi
    done
    
    log_success "Backup saved to ${backup_dir}"
}
