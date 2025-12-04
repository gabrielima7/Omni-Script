#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: summary.sh
# Description: Installation summary and credential display
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_SUMMARY_LOADED:-}" ]] && return 0
readonly _OMNI_SUMMARY_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Display Installation Summary
# ─────────────────────────────────────────────────────────────────────────────
display_summary() {
    local app="" url="" user="" password="" config="" target="" status="Running"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app) app="$2"; shift 2 ;;
            --url) url="$2"; shift 2 ;;
            --user) user="$2"; shift 2 ;;
            --password) password="$2"; shift 2 ;;
            --config) config="$2"; shift 2 ;;
            --target) target="$2"; shift 2 ;;
            --status) status="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    
    local width=70
    local inner=$((width - 2))
    
    echo ""
    echo -e "${NEON_GREEN}${BOX_TL}$(printf "${BOX_H}%.0s" $(seq 1 $inner))${BOX_TR}${RST}"
    echo -e "${NEON_GREEN}${BOX_V}${RST}$(printf '%*s' $(( (inner - 22) / 2 )) '')${BOLD}🎉 INSTALLATION COMPLETE${RST}$(printf '%*s' $(( (inner - 22) / 2 )) '')${NEON_GREEN}${BOX_V}${RST}"
    echo -e "${NEON_GREEN}${BOX_VL}$(printf "${BOX_H}%.0s" $(seq 1 $inner))${BOX_VR}${RST}"
    
    # App info
    [[ -n "$app" ]] && _summary_row "Application" "$app" "$width"
    [[ -n "$target" ]] && _summary_row "Target" "$target" "$width"
    [[ -n "$status" ]] && _summary_row "Status" "${NEON_GREEN}✅ ${status}${RST}" "$width"
    
    echo -e "${NEON_GREEN}${BOX_VL}$(printf "${BOX_H}%.0s" $(seq 1 $inner))${BOX_VR}${RST}"
    
    # Credentials
    [[ -n "$url" ]] && _summary_row "${ICON_LINK} Access URL" "$url" "$width"
    [[ -n "$user" ]] && _summary_row "${ICON_USER} Username" "$user" "$width"
    [[ -n "$password" ]] && _summary_row "${ICON_KEY} Password" "$password" "$width"
    
    echo -e "${NEON_GREEN}${BOX_VL}$(printf "${BOX_H}%.0s" $(seq 1 $inner))${BOX_VR}${RST}"
    
    # Config file
    [[ -n "$config" ]] && _summary_row "📝 Config File" "$config" "$width"
    
    echo -e "${NEON_GREEN}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $inner))${BOX_BR}${RST}"
    echo ""
}

_summary_row() {
    local label="$1"
    local value="$2"
    local width="$3"
    local inner=$((width - 2))
    local label_len=${#label}
    local padding=$((inner - label_len - ${#value} - 4))
    
    printf "${NEON_GREEN}${BOX_V}${RST}  %-20s %s%*s${NEON_GREEN}${BOX_V}${RST}\n" "$label:" "$value" "$((padding > 0 ? padding : 1))" ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Quick Status Box
# ─────────────────────────────────────────────────────────────────────────────
show_status_box() {
    local title="$1"
    local status="$2"
    local color="${3:-$CYBER_CYAN}"
    
    echo -e "${color}┌─────────────────────────────────────┐${RST}"
    echo -e "${color}│${RST} ${BOLD}${title}${RST}"
    echo -e "${color}│${RST} Status: ${status}"
    echo -e "${color}└─────────────────────────────────────┘${RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Credential Card
# ─────────────────────────────────────────────────────────────────────────────
show_credentials() {
    local user="$1"
    local password="$2"
    local url="${3:-}"
    
    echo -e "${FIRE_ORANGE}┌─────────────────────────────────────┐${RST}"
    echo -e "${FIRE_ORANGE}│${RST} ${ICON_SECURITY} ${BOLD}CREDENTIALS${RST}"
    echo -e "${FIRE_ORANGE}├─────────────────────────────────────┤${RST}"
    echo -e "${FIRE_ORANGE}│${RST} ${ICON_USER} User: ${BOLD}${user}${RST}"
    echo -e "${FIRE_ORANGE}│${RST} ${ICON_KEY} Pass: ${BOLD}${password}${RST}"
    [[ -n "$url" ]] && echo -e "${FIRE_ORANGE}│${RST} ${ICON_LINK} URL:  ${url}"
    echo -e "${FIRE_ORANGE}└─────────────────────────────────────┘${RST}"
    echo -e "${DIM}⚠️  Save these credentials securely!${RST}"
}
