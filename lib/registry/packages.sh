#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: packages.sh
# Description: Package manager search (APT, DNF, APK, Pacman)
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_PACKAGES_LOADED:-}" ]] && return 0
readonly _OMNI_PACKAGES_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Search Packages (Auto-detect package manager)
# ─────────────────────────────────────────────────────────────────────────────
search_packages() {
    local query="$1"
    local limit="${2:-5}"
    local found=false
    
    # APT (Debian/Ubuntu)
    if cmd_exists apt-cache; then
        found=true
        apt-cache search "$query" 2>/dev/null | head -"$limit" | while read -r pkg desc; do
            echo -e "  ${TREE_BRANCH} ${NEON_GREEN}apt:${RST} ${BOLD}${pkg}${RST} - ${DIM}${desc:0:50}${RST}"
        done
    fi
    
    # DNF/YUM (Fedora/RHEL)
    if cmd_exists dnf; then
        found=true
        dnf search -q "$query" 2>/dev/null | grep -E "^[a-z]" | head -"$limit" | while read -r line; do
            local pkg="${line%% :*}"
            local desc="${line#* : }"
            echo -e "  ${TREE_BRANCH} ${FIRE_ORANGE}dnf:${RST} ${BOLD}${pkg}${RST} - ${DIM}${desc:0:50}${RST}"
        done
    fi
    
    # APK (Alpine)
    if cmd_exists apk; then
        found=true
        apk search "$query" 2>/dev/null | head -"$limit" | while read -r pkg; do
            echo -e "  ${TREE_BRANCH} ${ICE_BLUE}apk:${RST} ${BOLD}${pkg}${RST}"
        done
    fi
    
    # Pacman (Arch)
    if cmd_exists pacman; then
        found=true
        pacman -Ss "$query" 2>/dev/null | grep -E "^[a-z]" | head -"$limit" | while read -r line; do
            echo -e "  ${TREE_BRANCH} ${ELECTRIC_PURPLE}pacman:${RST} ${line}"
        done
    fi
    
    [[ "$found" == "false" ]] && echo -e "  ${DIM}No package manager detected${RST}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Package
# ─────────────────────────────────────────────────────────────────────────────
install_package() {
    local pkg="$1"
    local pm="${OMNI_PKG_MANAGER:-apt}"
    
    case "$pm" in
        apt)    sudo apt-get install -y "$pkg" ;;
        dnf)    sudo dnf install -y "$pkg" ;;
        yum)    sudo yum install -y "$pkg" ;;
        apk)    sudo apk add "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        zypper) sudo zypper install -y "$pkg" ;;
        *)      return 1 ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Check if Package is Installed
# ─────────────────────────────────────────────────────────────────────────────
is_package_installed() {
    local pkg="$1"
    local pm="${OMNI_PKG_MANAGER:-apt}"
    
    case "$pm" in
        apt)    dpkg -l "$pkg" &>/dev/null ;;
        dnf|yum) rpm -q "$pkg" &>/dev/null ;;
        apk)    apk info -e "$pkg" &>/dev/null ;;
        pacman) pacman -Q "$pkg" &>/dev/null ;;
        *)      return 1 ;;
    esac
}
