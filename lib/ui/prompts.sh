#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: prompts.sh
# Description: Interactive prompts and user input
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_PROMPTS_LOADED:-}" ]] && return 0
readonly _OMNI_PROMPTS_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Prompt for Input
# ─────────────────────────────────────────────────────────────────────────────
prompt_input() {
    local message="$1"
    local default="${2:-}"
    local varname="${3:-REPLY}"
    
    if [[ -n "$default" ]]; then
        echo -en "${CYBER_CYAN}?${RST} ${message} ${DIM}[${default}]${RST}: "
    else
        echo -en "${CYBER_CYAN}?${RST} ${message}: "
    fi
    
    read -r value
    value="${value:-$default}"
    
    if [[ "$varname" != "REPLY" ]]; then
        printf -v "$varname" '%s' "$value"
    fi
    echo "$value"
}

# ─────────────────────────────────────────────────────────────────────────────
# Prompt for Password (hidden input)
# ─────────────────────────────────────────────────────────────────────────────
prompt_password() {
    local message="${1:-Password}"
    local varname="${2:-PASSWORD}"
    
    echo -en "${CYBER_CYAN}${ICON_KEY}${RST} ${message}: "
    read -rs password
    echo
    
    printf -v "$varname" '%s' "$password"
    echo "$password"
}

# ─────────────────────────────────────────────────────────────────────────────
# Prompt Yes/No
# ─────────────────────────────────────────────────────────────────────────────
prompt_confirm() {
    local message="$1"
    local default="${2:-n}"
    
    local hint
    [[ "$default" == "y" ]] && hint="[Y/n]" || hint="[y/N]"
    
    echo -en "${CYBER_CYAN}?${RST} ${message} ${DIM}${hint}${RST}: "
    read -r response
    response="${response:-$default}"
    
    [[ "${response,,}" =~ ^(y|yes|sim|s)$ ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Select from List
# ─────────────────────────────────────────────────────────────────────────────
declare -g SELECTED=""
declare -g SELECTED_INDEX=0

prompt_select() {
    local message="$1"
    shift
    local options=("$@")
    local count=${#options[@]}
    
    echo -e "${CYBER_CYAN}?${RST} ${message}"
    echo ""
    
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        if [[ $i -eq 0 ]]; then
            echo -e "  ${NEON_GREEN}❯${RST} ${BOLD}${num})${RST} ${options[$i]}"
        else
            echo -e "    ${DIM}${num})${RST} ${options[$i]}"
        fi
    done
    
    echo ""
    echo -en "${CYBER_CYAN}Enter choice [1-${count}]:${RST} "
    read -r choice
    
    # Validate
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$count" ]]; then
        SELECTED_INDEX=$((choice - 1))
        SELECTED="${options[$SELECTED_INDEX]}"
        echo -e "${DIM}Selected: ${SELECTED}${RST}"
        return 0
    else
        SELECTED="${options[0]}"
        SELECTED_INDEX=0
        echo -e "${DIM}Using default: ${SELECTED}${RST}"
        return 0
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Select Target
# ─────────────────────────────────────────────────────────────────────────────
prompt_target() {
    local message="${1:-Select deployment target}"
    
    echo -e "${CYBER_CYAN}?${RST} ${message}"
    echo ""
    echo -e "  ${ICON_DOCKER} ${BOLD}1)${RST} Docker"
    echo -e "  ${ICON_PODMAN} ${DIM}2)${RST} Podman"
    echo -e "  ${ICON_LXC} ${DIM}3)${RST} LXC"
    echo -e "  ${ICON_BAREMETAL} ${DIM}4)${RST} Bare Metal"
    echo ""
    echo -en "${CYBER_CYAN}Enter choice [1-4]:${RST} "
    read -r choice
    
    case "$choice" in
        1) SELECTED="docker" ;;
        2) SELECTED="podman" ;;
        3) SELECTED="lxc" ;;
        4) SELECTED="baremetal" ;;
        *) SELECTED="docker" ;;
    esac
    
    echo -e "${DIM}Target: ${SELECTED}${RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Multi-select Checkbox (space to toggle, enter to confirm)
# ─────────────────────────────────────────────────────────────────────────────
declare -ga SELECTED_ITEMS=()

prompt_multiselect() {
    local message="$1"
    shift
    local options=("$@")
    local -a selected=()
    
    # Initialize all as not selected
    for i in "${!options[@]}"; do
        selected[$i]=0
    done
    
    echo -e "${CYBER_CYAN}?${RST} ${message} ${DIM}(space to toggle, enter to confirm)${RST}"
    echo ""
    
    for i in "${!options[@]}"; do
        local num=$((i + 1))
        echo -e "  [ ] ${num}) ${options[$i]}"
    done
    
    echo ""
    echo -en "${CYBER_CYAN}Toggle items (e.g., 1 3 5) or 'all':${RST} "
    read -r input
    
    SELECTED_ITEMS=()
    if [[ "$input" == "all" ]]; then
        SELECTED_ITEMS=("${options[@]}")
    else
        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "${#options[@]}" ]]; then
                SELECTED_ITEMS+=("${options[$((num - 1))]}")
            fi
        done
    fi
    
    echo -e "${DIM}Selected: ${SELECTED_ITEMS[*]}${RST}"
}
