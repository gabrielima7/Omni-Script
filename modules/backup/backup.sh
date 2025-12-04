#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: backup.sh
# Description: Universal backup system for all targets
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_BACKUP_LOADED:-}" ]] && return 0
readonly _OMNI_BACKUP_LOADED=1

BACKUP_MODULE_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${BACKUP_MODULE_DIR}/../../lib/core/constants.sh"
source "${BACKUP_MODULE_DIR}/../../lib/core/logger.sh"
source "${BACKUP_MODULE_DIR}/../../lib/core/utils.sh"
source "${BACKUP_MODULE_DIR}/../../lib/ui/spinner.sh"
source "${BACKUP_MODULE_DIR}/../../lib/adapters/adapter_base.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Main Backup Entry Point
# ─────────────────────────────────────────────────────────────────────────────
backup_app() {
    local app_name="$1"
    shift
    
    local target=""
    local full_backup=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target) target="$2"; shift 2 ;;
            --full) full_backup=true; shift ;;
            *) shift ;;
        esac
    done
    
    log_section "Backup: ${app_name}" "💾"
    
    # Auto-detect target if not specified
    if [[ -z "$target" ]]; then
        target=$(_detect_app_target "$app_name")
    fi
    
    if [[ -z "$target" ]]; then
        log_error "Could not detect target for ${app_name}"
        log_info "Specify with: omni backup ${app_name} --target docker|podman|lxc|baremetal"
        return 1
    fi
    
    load_adapter "$target"
    
    local backup_dir="${OMNI_BACKUP_DIR}/${app_name}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    ensure_dir "$backup_dir"
    
    spinner_start "Creating backup..."
    
    adapter_backup "$app_name" && {
        spinner_stop "success" "Backup complete"
        _rotate_backups "$backup_dir"
        _show_backup_info "$backup_dir"
    } || {
        spinner_stop "error" "Backup failed"
        return 1
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Detect App Target
# ─────────────────────────────────────────────────────────────────────────────
_detect_app_target() {
    local app_name="$1"
    
    # Check Docker
    if command -v docker &>/dev/null && docker ps -a --format '{{.Names}}' | grep -q "^${app_name}$"; then
        echo "docker"
        return
    fi
    
    # Check Podman
    if command -v podman &>/dev/null && podman ps -a --format '{{.Names}}' | grep -q "^${app_name}$"; then
        echo "podman"
        return
    fi
    
    # Check LXC
    if command -v lxc &>/dev/null && lxc list -f csv -c n | grep -q "^${app_name}$"; then
        echo "lxc"
        return
    fi
    
    # Check systemd service
    if systemctl list-units --type=service --all | grep -q "${app_name}"; then
        echo "baremetal"
        return
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Rotate Old Backups
# ─────────────────────────────────────────────────────────────────────────────
_rotate_backups() {
    local backup_dir="$1"
    local retention="${DEFAULT_BACKUP_RETENTION:-7}"
    
    # Delete backups older than retention days
    find "$backup_dir" -name "*.tar.gz" -mtime +"$retention" -delete 2>/dev/null
    find "$backup_dir" -name "*.tar" -mtime +"$retention" -delete 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Show Backup Info
# ─────────────────────────────────────────────────────────────────────────────
_show_backup_info() {
    local backup_dir="$1"
    
    echo ""
    echo -e "${NEON_GREEN}Backup Location:${RST} ${backup_dir}"
    echo -e "${NEON_GREEN}Files:${RST}"
    
    ls -lh "$backup_dir"/*.tar.gz 2>/dev/null | tail -5 | while read -r line; do
        echo -e "  ${DIM}${line}${RST}"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Restore
# ─────────────────────────────────────────────────────────────────────────────
restore_app() {
    local app_name="$1"
    local backup_file="${2:-}"
    local target="${3:-}"
    
    local backup_dir="${OMNI_BACKUP_DIR}/${app_name}"
    
    # Find latest backup if not specified
    if [[ -z "$backup_file" ]]; then
        backup_file=$(ls -t "$backup_dir"/*.tar.gz 2>/dev/null | head -1)
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "No backup found for ${app_name}"
        return 1
    fi
    
    log_info "Restoring from: ${backup_file}"
    
    # Target-specific restore would go here
    adapter_restore "$app_name" "$backup_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# List Backups
# ─────────────────────────────────────────────────────────────────────────────
list_backups() {
    local app_name="${1:-}"
    
    if [[ -n "$app_name" ]]; then
        local dir="${OMNI_BACKUP_DIR}/${app_name}"
        [[ -d "$dir" ]] && ls -lh "$dir" || echo "No backups found"
    else
        echo -e "${BOLD}Available Backups:${RST}"
        for dir in "${OMNI_BACKUP_DIR}"/*/; do
            [[ -d "$dir" ]] && echo "  - $(basename "$dir")"
        done
    fi
}
