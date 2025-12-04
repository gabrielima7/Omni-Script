#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: engine.sh
# Description: Main installer engine - orchestrates application installation
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_INSTALLER_ENGINE_LOADED:-}" ]] && return 0
readonly _OMNI_INSTALLER_ENGINE_LOADED=1

# Source dependencies
INSTALLER_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${INSTALLER_DIR}/../../lib/core/constants.sh"
source "${INSTALLER_DIR}/../../lib/core/logger.sh"
source "${INSTALLER_DIR}/../../lib/core/utils.sh"
source "${INSTALLER_DIR}/../../lib/ui/prompts.sh"
source "${INSTALLER_DIR}/../../lib/ui/spinner.sh"
source "${INSTALLER_DIR}/../../lib/ui/summary.sh"
source "${INSTALLER_DIR}/../../lib/security/credentials.sh"
source "${INSTALLER_DIR}/../../lib/adapters/adapter_base.sh"
source "${INSTALLER_DIR}/../../lib/registry/search.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Main Installer Entry Point
# ─────────────────────────────────────────────────────────────────────────────
installer_run() {
    local app_name="$1"
    shift
    
    local target=""
    local use_global_config=false
    local dry_run=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target) target="$2"; shift 2 ;;
            --config) [[ "$2" == "global" ]] && use_global_config=true; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            *) shift ;;
        esac
    done
    
    log_section "Installing ${app_name}" "📦"
    
    # Step 1: Check if recipe exists
    if ! recipe_exists "$app_name"; then
        log_error "No recipe found for: ${app_name}"
        log_info "Try: omni search ${app_name}"
        return 1
    fi
    
    # Step 2: Select target if not specified
    if [[ -z "$target" ]]; then
        prompt_target "Where would you like to install ${app_name}?"
        target="$SELECTED"
    fi
    
    # Step 3: Load appropriate adapter
    load_adapter "$target" || return 1
    adapter_check || return 1
    
    # Step 4: Configuration
    local admin_user admin_pass
    if [[ "$use_global_config" == "true" ]]; then
        log_info "Using global configuration defaults"
    else
        echo ""
        if prompt_confirm "Would you like to customize settings?"; then
            configure_app_interactive "$app_name"
        fi
    fi
    
    # Step 5: Generate credentials if needed
    admin_user=$(generate_username "$app_name")
    admin_pass=$(generate_password 32)
    
    # Step 6: Dry run check
    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY-RUN] Would install ${app_name} on ${target}"
        log_info "[DRY-RUN] User: ${admin_user}"
        log_info "[DRY-RUN] Password: ${admin_pass}"
        return 0
    fi
    
    # Step 7: Run installation
    spinner_start "Installing ${app_name}..."
    
    # Source and run recipe
    local recipe_file="${OMNI_RECIPES_DIR}/applications/${app_name}/${target}.sh"
    if [[ -f "$recipe_file" ]]; then
        # shellcheck source=/dev/null
        source "$recipe_file"
        
        # Export credentials for recipe
        export ADMIN_USER="$admin_user"
        export ADMIN_PASSWORD="$admin_pass"
        
        if declare -f "install_${app_name}" &>/dev/null; then
            "install_${app_name}" && spinner_stop "success" "Installation complete" || {
                spinner_stop "error" "Installation failed"
                return 1
            }
        else
            adapter_install "$app_name" && spinner_stop "success" || spinner_stop "error"
        fi
    else
        adapter_install "$app_name" && spinner_stop "success" || spinner_stop "error"
    fi
    
    # Step 8: Store credentials
    store_credentials "$app_name" "$admin_user" "$admin_pass"
    
    # Step 9: Display summary
    display_summary \
        --app "$app_name" \
        --target "$target" \
        --user "$admin_user" \
        --password "$admin_pass" \
        --config "${OMNI_CONFIG_DIR}/.credentials/${app_name}.env"
}

# ─────────────────────────────────────────────────────────────────────────────
# Check if Recipe Exists
# ─────────────────────────────────────────────────────────────────────────────
recipe_exists() {
    local app_name="$1"
    [[ -d "${OMNI_RECIPES_DIR}/applications/${app_name}" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Interactive Configuration
# ─────────────────────────────────────────────────────────────────────────────
configure_app_interactive() {
    local app_name="$1"
    
    echo ""
    log_section "Configuration for ${app_name}" "⚙️"
    
    # Network
    if prompt_confirm "Configure network settings?"; then
        prompt_input "IP Address (leave empty for auto)" "" "APP_IP"
        prompt_input "Domain/Hostname" "${app_name}.local" "APP_DOMAIN"
    fi
    
    # Ports
    if prompt_confirm "Configure custom ports?"; then
        prompt_input "HTTP Port" "80" "APP_HTTP_PORT"
        prompt_input "HTTPS Port" "443" "APP_HTTPS_PORT"
    fi
    
    # Resources
    if prompt_confirm "Set resource limits?"; then
        prompt_input "CPU limit (e.g., 2)" "" "APP_CPU_LIMIT"
        prompt_input "Memory limit (e.g., 2G)" "" "APP_MEM_LIMIT"
    fi
    
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# List Available Recipes
# ─────────────────────────────────────────────────────────────────────────────
list_recipes() {
    local category="${1:-applications}"
    local recipe_path="${OMNI_RECIPES_DIR}/${category}"
    
    if [[ -d "$recipe_path" ]]; then
        find "$recipe_path" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    fi
}
