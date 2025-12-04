#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: search.sh
# Description: Unified search engine for packages and container images
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_SEARCH_LOADED:-}" ]] && return 0
readonly _OMNI_SEARCH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Source sub-modules
# ─────────────────────────────────────────────────────────────────────────────
_REGISTRY_DIR="$(dirname "${BASH_SOURCE[0]}")"
[[ -f "${_REGISTRY_DIR}/dockerhub.sh" ]] && source "${_REGISTRY_DIR}/dockerhub.sh"
[[ -f "${_REGISTRY_DIR}/packages.sh" ]] && source "${_REGISTRY_DIR}/packages.sh"
[[ -f "${_REGISTRY_DIR}/lxc_images.sh" ]] && source "${_REGISTRY_DIR}/lxc_images.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Unified Search
# ─────────────────────────────────────────────────────────────────────────────
unified_search() {
    local query="$1"
    local filter="${2:-all}"  # all, packages, images
    
    echo -e "${CYBER_CYAN}${ICON_SEARCH}${RST} Searching for: ${BOLD}${query}${RST}"
    echo ""
    
    # Search packages
    if [[ "$filter" == "all" || "$filter" == "packages" ]]; then
        echo -e "${ELECTRIC_PURPLE}📦 PACKAGES${RST}"
        echo -e "${DIM}───────────────────────────────────────${RST}"
        if declare -f search_packages &>/dev/null; then
            search_packages "$query"
        else
            _search_packages_fallback "$query"
        fi
        echo ""
    fi
    
    # Search Docker Hub
    if [[ "$filter" == "all" || "$filter" == "images" ]]; then
        echo -e "${ELECTRIC_PURPLE}${ICON_DOCKER} DOCKER HUB${RST}"
        echo -e "${DIM}───────────────────────────────────────${RST}"
        if declare -f search_dockerhub &>/dev/null; then
            search_dockerhub "$query"
        else
            _search_dockerhub_fallback "$query"
        fi
        echo ""
    fi
    
    # Search LXC Images
    if [[ "$filter" == "all" || "$filter" == "lxc" ]]; then
        echo -e "${ELECTRIC_PURPLE}${ICON_LXC} LXC IMAGES${RST}"
        echo -e "${DIM}───────────────────────────────────────${RST}"
        if declare -f search_lxc_images &>/dev/null; then
            search_lxc_images "$query"
        else
            echo -e "${DIM}  LXC image search not yet available${RST}"
        fi
        echo ""
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Fallback Package Search
# ─────────────────────────────────────────────────────────────────────────────
_search_packages_fallback() {
    local query="$1"
    
    if cmd_exists apt-cache; then
        apt-cache search "$query" 2>/dev/null | head -5 | while read -r pkg desc; do
            echo -e "  ${TREE_BRANCH} ${NEON_GREEN}apt:${RST} ${pkg} - ${DIM}${desc}${RST}"
        done
    elif cmd_exists dnf; then
        dnf search "$query" 2>/dev/null | grep -v "^=" | head -5 | while read -r line; do
            echo -e "  ${TREE_BRANCH} ${NEON_GREEN}dnf:${RST} ${line}"
        done
    elif cmd_exists apk; then
        apk search "$query" 2>/dev/null | head -5 | while read -r pkg; do
            echo -e "  ${TREE_BRANCH} ${NEON_GREEN}apk:${RST} ${pkg}"
        done
    else
        echo -e "  ${DIM}Package manager not detected${RST}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Fallback Docker Hub Search
# ─────────────────────────────────────────────────────────────────────────────
_search_dockerhub_fallback() {
    local query="$1"
    
    if ! cmd_exists curl || ! cmd_exists jq; then
        echo -e "  ${DIM}Requires curl and jq${RST}"
        return 1
    fi
    
    local response
    response=$(curl -sf "https://hub.docker.com/v2/search/repositories/?query=${query}&page_size=5" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo -e "  ${DIM}No results or API unavailable${RST}"
        return 1
    fi
    
    echo "$response" | jq -r '.results[] | "  ├── \(.repo_name) ⭐ \(.star_count) - \(.short_description // "No description")[0:50]"' 2>/dev/null | head -5
}
