#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: docker_adapter.sh
# Description: Docker/Docker Compose target adapter
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_DOCKER_ADAPTER_LOADED:-}" ]] && return 0
readonly _OMNI_DOCKER_ADAPTER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
# ─────────────────────────────────────────────────────────────────────────────
adapter_check() {
    if ! cmd_exists docker; then
        log_error "Docker not installed"
        return 1
    fi
    
    if ! docker info &>/dev/null; then
        log_error "Docker daemon not running or no permissions"
        return 1
    fi
    
    log_debug "Docker adapter ready"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate Docker Compose
# ─────────────────────────────────────────────────────────────────────────────
generate_compose() {
    local output_dir="$1"
    local content="$2"
    
    ensure_dir "$output_dir"
    echo "$content" > "${output_dir}/docker-compose.yml"
    log_debug "Generated docker-compose.yml in ${output_dir}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Docker Compose Up
# ─────────────────────────────────────────────────────────────────────────────
docker_compose_up() {
    local dir="${1:-.}"
    
    if cmd_exists docker-compose; then
        docker-compose -f "${dir}/docker-compose.yml" up -d
    else
        docker compose -f "${dir}/docker-compose.yml" up -d
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Docker Compose Down
# ─────────────────────────────────────────────────────────────────────────────
docker_compose_down() {
    local dir="${1:-.}"
    
    if cmd_exists docker-compose; then
        docker-compose -f "${dir}/docker-compose.yml" down
    else
        docker compose -f "${dir}/docker-compose.yml" down
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install (Deploy via Compose)
# ─────────────────────────────────────────────────────────────────────────────
adapter_install() {
    local app_name="$1"
    local compose_dir="${OMNI_DATA_DIR}/apps/${app_name}"
    
    adapter_check || return 1
    
    log_info "${ICON_DOCKER} Deploying ${app_name} via Docker..."
    
    if [[ ! -f "${compose_dir}/docker-compose.yml" ]]; then
        log_error "No docker-compose.yml found for ${app_name}"
        return 1
    fi
    
    docker_compose_up "$compose_dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# Remove
# ─────────────────────────────────────────────────────────────────────────────
adapter_remove() {
    local app_name="$1"
    local compose_dir="${OMNI_DATA_DIR}/apps/${app_name}"
    local remove_volumes="${2:-false}"
    
    log_info "${ICON_DOCKER} Removing ${app_name}..."
    
    if [[ -f "${compose_dir}/docker-compose.yml" ]]; then
        if [[ "$remove_volumes" == "true" ]]; then
            docker compose -f "${compose_dir}/docker-compose.yml" down -v
        else
            docker_compose_down "$compose_dir"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Start/Stop/Logs/Status
# ─────────────────────────────────────────────────────────────────────────────
adapter_start() {
    local container="$1"
    docker start "$container"
}

adapter_stop() {
    local container="$1"
    docker stop "$container"
}

adapter_logs() {
    local container="$1"
    local lines="${2:-100}"
    docker logs --tail "$lines" -f "$container"
}

adapter_status() {
    local container="$1"
    docker ps -a --filter "name=$container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup
# ─────────────────────────────────────────────────────────────────────────────
adapter_backup() {
    local container="$1"
    local backup_dir="${OMNI_BACKUP_DIR}/${container}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    ensure_dir "$backup_dir"
    
    log_info "Backing up ${container}..."
    
    # Stop container
    docker stop "$container" 2>/dev/null
    
    # Get volumes and backup
    local volumes
    volumes=$(docker inspect -f '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' "$container" 2>/dev/null)
    
    for vol in $volumes; do
        local vol_name="${vol%%:*}"
        if [[ -n "$vol_name" && "$vol_name" != "{{range" ]]; then
            log_debug "Backing up volume: ${vol_name}"
            docker run --rm -v "${vol_name}:/data" -v "${backup_dir}:/backup" \
                alpine tar czf "/backup/${vol_name}_${timestamp}.tar.gz" -C /data . 2>/dev/null
        fi
    done
    
    # Restart container
    docker start "$container" 2>/dev/null
    
    log_success "Backup completed: ${backup_dir}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────────────────────
docker_pull() {
    local image="$1"
    docker pull "$image"
}

docker_network_exists() {
    local network="$1"
    docker network inspect "$network" &>/dev/null
}

docker_create_network() {
    local network="$1"
    local subnet="${2:-}"
    
    if ! docker_network_exists "$network"; then
        if [[ -n "$subnet" ]]; then
            docker network create --subnet="$subnet" "$network"
        else
            docker network create "$network"
        fi
    fi
}
