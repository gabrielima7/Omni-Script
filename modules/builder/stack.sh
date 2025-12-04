#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: stack.sh
# Description: Builder Stack - Compose full environments interactively
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_BUILDER_STACK_LOADED:-}" ]] && return 0
readonly _OMNI_BUILDER_STACK_LOADED=1

BUILDER_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${BUILDER_DIR}/../../lib/core/constants.sh"
source "${BUILDER_DIR}/../../lib/core/logger.sh"
source "${BUILDER_DIR}/../../lib/ui/prompts.sh"
source "${BUILDER_DIR}/../../lib/ui/banners.sh"
source "${BUILDER_DIR}/../../lib/security/credentials.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Available Components
# ─────────────────────────────────────────────────────────────────────────────
readonly -a STACK_DATABASES=("PostgreSQL" "MariaDB" "MongoDB" "Redis" "None")
readonly -a STACK_BACKENDS=("Node.js" "Python/Django" "Go" "PHP" "None")
readonly -a STACK_FRONTENDS=("React" "Vue" "Static HTML" "None")
readonly -a STACK_PROXIES=("Traefik" "Nginx" "Caddy" "None")

# ─────────────────────────────────────────────────────────────────────────────
# Stack State
# ─────────────────────────────────────────────────────────────────────────────
declare -g STACK_DB=""
declare -g STACK_BACKEND=""
declare -g STACK_FRONTEND=""
declare -g STACK_PROXY=""
declare -g STACK_TARGET=""
declare -g STACK_NAME=""

# ─────────────────────────────────────────────────────────────────────────────
# Main Builder Stack Interface
# ─────────────────────────────────────────────────────────────────────────────
builder_stack() {
    local subcommand="${1:-build}"
    
    case "$subcommand" in
        build)   stack_build_wizard ;;
        preset)  stack_preset "${2:-}" ;;
        *)       stack_build_wizard ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Interactive Build Wizard
# ─────────────────────────────────────────────────────────────────────────────
stack_build_wizard() {
    show_section "Builder Stack" "🏗️"
    
    echo -e "${CYBER_CYAN}Compose your custom environment${RST}"
    echo ""
    
    # Stack name
    STACK_NAME=$(prompt_input "Stack name" "my-stack")
    echo ""
    
    # Database
    echo -e "${BOLD}Step 1/5: Database${RST}"
    prompt_select "Select database" "${STACK_DATABASES[@]}"
    STACK_DB="$SELECTED"
    echo ""
    
    # Backend
    echo -e "${BOLD}Step 2/5: Backend${RST}"
    prompt_select "Select backend" "${STACK_BACKENDS[@]}"
    STACK_BACKEND="$SELECTED"
    echo ""
    
    # Frontend
    echo -e "${BOLD}Step 3/5: Frontend${RST}"
    prompt_select "Select frontend" "${STACK_FRONTENDS[@]}"
    STACK_FRONTEND="$SELECTED"
    echo ""
    
    # Proxy
    echo -e "${BOLD}Step 4/5: Reverse Proxy${RST}"
    prompt_select "Select proxy" "${STACK_PROXIES[@]}"
    STACK_PROXY="$SELECTED"
    echo ""
    
    # Target
    echo -e "${BOLD}Step 5/5: Deployment Target${RST}"
    prompt_target
    STACK_TARGET="$SELECTED"
    echo ""
    
    # Summary
    _show_stack_summary
    
    if prompt_confirm "Generate and deploy this stack?"; then
        _generate_stack
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Show Stack Summary
# ─────────────────────────────────────────────────────────────────────────────
_show_stack_summary() {
    echo ""
    echo -e "${ELECTRIC_PURPLE}╔═══════════════════════════════════════╗${RST}"
    echo -e "${ELECTRIC_PURPLE}║${RST}         ${BOLD}Stack Configuration${RST}          ${ELECTRIC_PURPLE}║${RST}"
    echo -e "${ELECTRIC_PURPLE}╠═══════════════════════════════════════╣${RST}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Name:      ${STACK_NAME}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Database:  ${STACK_DB}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Backend:   ${STACK_BACKEND}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Frontend:  ${STACK_FRONTEND}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Proxy:     ${STACK_PROXY}"
    echo -e "${ELECTRIC_PURPLE}║${RST} Target:    ${STACK_TARGET}"
    echo -e "${ELECTRIC_PURPLE}╚═══════════════════════════════════════╝${RST}"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate Stack (Docker Compose)
# ─────────────────────────────────────────────────────────────────────────────
_generate_stack() {
    local stack_dir="${OMNI_DATA_DIR}/stacks/${STACK_NAME}"
    mkdir -p "$stack_dir"
    
    log_info "Generating stack configuration..."
    
    # Generate docker-compose.yml
    source "${BUILDER_DIR}/composer.sh"
    compose_generate "$stack_dir"
    
    log_success "Stack generated at: ${stack_dir}"
    
    # Deploy if Docker/Podman
    if [[ "$STACK_TARGET" == "docker" || "$STACK_TARGET" == "podman" ]]; then
        if prompt_confirm "Deploy now?"; then
            cd "$stack_dir" || return 1
            if [[ "$STACK_TARGET" == "docker" ]]; then
                docker compose up -d
            else
                podman-compose up -d
            fi
            log_success "Stack deployed!"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Preset Stacks
# ─────────────────────────────────────────────────────────────────────────────
stack_preset() {
    local preset="$1"
    
    case "$preset" in
        lamp)
            STACK_NAME="lamp-stack"
            STACK_DB="MariaDB"
            STACK_BACKEND="PHP"
            STACK_FRONTEND="Static HTML"
            STACK_PROXY="Nginx"
            ;;
        mean)
            STACK_NAME="mean-stack"
            STACK_DB="MongoDB"
            STACK_BACKEND="Node.js"
            STACK_FRONTEND="None"
            STACK_PROXY="Nginx"
            ;;
        django)
            STACK_NAME="django-stack"
            STACK_DB="PostgreSQL"
            STACK_BACKEND="Python/Django"
            STACK_FRONTEND="None"
            STACK_PROXY="Traefik"
            ;;
        *)
            log_error "Unknown preset: ${preset}"
            log_info "Available: lamp, mean, django"
            return 1
            ;;
    esac
    
    prompt_target
    STACK_TARGET="$SELECTED"
    
    _show_stack_summary
    _generate_stack
}
