#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: podman_adapter.sh  
# Description: Podman target adapter
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_PODMAN_ADAPTER_LOADED:-}" ]] && return 0
readonly _OMNI_PODMAN_ADAPTER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
# ─────────────────────────────────────────────────────────────────────────────
adapter_check() {
    if ! cmd_exists podman; then
        log_error "Podman not installed"
        return 1
    fi
    podman info &>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Podman Compose Up
# ─────────────────────────────────────────────────────────────────────────────
podman_compose_up() {
    local dir="${1:-.}"
    
    if cmd_exists podman-compose; then
        podman-compose -f "${dir}/docker-compose.yml" up -d
    else
        podman compose -f "${dir}/docker-compose.yml" up -d
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────────────────────
adapter_install() {
    local app_name="$1"
    local compose_dir="${OMNI_DATA_DIR}/apps/${app_name}"
    
    adapter_check || return 1
    
    log_info "${ICON_PODMAN} Deploying ${app_name} via Podman..."
    
    if [[ -f "${compose_dir}/docker-compose.yml" ]]; then
        podman_compose_up "$compose_dir"
    else
        log_error "No compose file found"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Remove/Start/Stop/Logs/Status
# ─────────────────────────────────────────────────────────────────────────────
adapter_remove() { local c="$1"; podman stop "$c" 2>/dev/null; podman rm "$c"; }
adapter_start() { podman start "$1"; }
adapter_stop() { podman stop "$1"; }
adapter_logs() { podman logs --tail "${2:-100}" -f "$1"; }
adapter_status() { podman ps -a --filter "name=$1" --format "table {{.Names}}\t{{.Status}}"; }

# ─────────────────────────────────────────────────────────────────────────────
# Backup
# ─────────────────────────────────────────────────────────────────────────────
adapter_backup() {
    local container="$1"
    local backup_dir="${OMNI_BACKUP_DIR}/${container}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    ensure_dir "$backup_dir"
    podman stop "$container" 2>/dev/null
    
    # Export volumes
    local volumes
    volumes=$(podman inspect -f '{{range .Mounts}}{{.Name}} {{end}}' "$container" 2>/dev/null)
    for vol in $volumes; do
        [[ -n "$vol" ]] && podman volume export "$vol" > "${backup_dir}/${vol}_${timestamp}.tar"
    done
    
    podman start "$container" 2>/dev/null
    log_success "Backup: ${backup_dir}"
}
