#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: constants.sh
# Description: Global constants and configuration for Omni-Script
# ═══════════════════════════════════════════════════════════════════════════════

# Prevent multiple sourcing
[[ -n "${_OMNI_CONSTANTS_LOADED:-}" ]] && return 0
readonly _OMNI_CONSTANTS_LOADED=1

# ─────────────────────────────────────────────────────────────────────────────
# Version Information
# ─────────────────────────────────────────────────────────────────────────────
readonly OMNI_VERSION="1.0.0"
readonly OMNI_CODENAME="Genesis"
readonly OMNI_RELEASE_DATE="2024-12-04"

# ─────────────────────────────────────────────────────────────────────────────
# Directory Structure
# ─────────────────────────────────────────────────────────────────────────────
readonly OMNI_BASE_DIR="${OMNI_BASE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly OMNI_LIB_DIR="${OMNI_BASE_DIR}/lib"
readonly OMNI_MODULES_DIR="${OMNI_BASE_DIR}/modules"
readonly OMNI_RECIPES_DIR="${OMNI_BASE_DIR}/recipes"
readonly OMNI_TEMPLATES_DIR="${OMNI_BASE_DIR}/templates"
readonly OMNI_CACHE_DIR="${HOME}/.cache/omni-script"
readonly OMNI_DATA_DIR="${HOME}/.local/share/omni-script"
readonly OMNI_CONFIG_DIR="${HOME}/.config/omni-script"
readonly OMNI_LOG_DIR="${OMNI_DATA_DIR}/logs"
readonly OMNI_BACKUP_DIR="${OMNI_DATA_DIR}/backups"

# ─────────────────────────────────────────────────────────────────────────────
# ANSI Color Codes (256-color palette for "Hacker-Chic" aesthetic)
# ─────────────────────────────────────────────────────────────────────────────
# Reset
readonly RST="\033[0m"
readonly RESET="${RST}"

# Basic Colors
readonly BLACK="\033[0;30m"
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BLUE="\033[0;34m"
readonly MAGENTA="\033[0;35m"
readonly CYAN="\033[0;36m"
readonly WHITE="\033[0;37m"

# Bold Colors
readonly BOLD="\033[1m"
readonly BOLD_RED="\033[1;31m"
readonly BOLD_GREEN="\033[1;32m"
readonly BOLD_YELLOW="\033[1;33m"
readonly BOLD_BLUE="\033[1;34m"
readonly BOLD_MAGENTA="\033[1;35m"
readonly BOLD_CYAN="\033[1;36m"
readonly BOLD_WHITE="\033[1;37m"

# Dim Colors
readonly DIM="\033[2m"
readonly DIM_WHITE="\033[2;37m"

# 256-Color Palette (Cyber/Hacker Theme)
readonly CYBER_CYAN="\033[38;5;51m"
readonly NEON_GREEN="\033[38;5;46m"
readonly MATRIX_GREEN="\033[38;5;34m"
readonly ELECTRIC_PURPLE="\033[38;5;141m"
readonly FIRE_ORANGE="\033[38;5;208m"
readonly BLOOD_RED="\033[38;5;196m"
readonly ICE_BLUE="\033[38;5;39m"
readonly GOLD="\033[38;5;220m"
readonly SILVER="\033[38;5;250m"
readonly DARK_GRAY="\033[38;5;240m"

# Background Colors
readonly BG_BLACK="\033[40m"
readonly BG_RED="\033[41m"
readonly BG_GREEN="\033[42m"
readonly BG_YELLOW="\033[43m"
readonly BG_BLUE="\033[44m"
readonly BG_MAGENTA="\033[45m"
readonly BG_CYAN="\033[46m"
readonly BG_WHITE="\033[47m"

# Semantic Colors
readonly COLOR_SUCCESS="${NEON_GREEN}"
readonly COLOR_ERROR="${BLOOD_RED}"
readonly COLOR_WARNING="${FIRE_ORANGE}"
readonly COLOR_INFO="${CYBER_CYAN}"
readonly COLOR_DEBUG="${DARK_GRAY}"
readonly COLOR_HEADER="${ELECTRIC_PURPLE}"
readonly COLOR_ACCENT="${GOLD}"

# ─────────────────────────────────────────────────────────────────────────────
# Unicode Symbols and Emojis
# ─────────────────────────────────────────────────────────────────────────────
# Status Icons
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️"
readonly ICON_INFO="ℹ️"
readonly ICON_QUESTION="❓"
readonly ICON_LOADING="⏳"
readonly ICON_DONE="✔"
readonly ICON_FAIL="✖"

# Category Icons
readonly ICON_DOCKER="🐳"
readonly ICON_PODMAN="🦭"
readonly ICON_LXC="📦"
readonly ICON_BAREMETAL="🖥️"
readonly ICON_PACKAGE="📦"
readonly ICON_SECURITY="🔒"
readonly ICON_NETWORK="🌐"
readonly ICON_CONFIG="⚙️"
readonly ICON_BACKUP="💾"
readonly ICON_ROCKET="🚀"
readonly ICON_SEARCH="🔍"
readonly ICON_FOLDER="📁"
readonly ICON_FILE="📄"
readonly ICON_KEY="🔑"
readonly ICON_USER="👤"
readonly ICON_LINK="🔗"
readonly ICON_CLOCK="🕐"
readonly ICON_STAR="⭐"
readonly ICON_FIRE="🔥"
readonly ICON_TOOLS="🛠️"
readonly ICON_DATABASE="🗃️"
readonly ICON_STACK="🏗️"

# Box Drawing Characters
readonly BOX_TL="╔"
readonly BOX_TR="╗"
readonly BOX_BL="╚"
readonly BOX_BR="╝"
readonly BOX_H="═"
readonly BOX_V="║"
readonly BOX_VL="╠"
readonly BOX_VR="╣"
readonly BOX_HT="╦"
readonly BOX_HB="╩"
readonly BOX_CROSS="╬"

# Simple Box Characters
readonly SBOX_TL="┌"
readonly SBOX_TR="┐"
readonly SBOX_BL="└"
readonly SBOX_BR="┘"
readonly SBOX_H="─"
readonly SBOX_V="│"
readonly SBOX_VL="├"
readonly SBOX_VR="┤"

# Tree Characters
readonly TREE_BRANCH="├──"
readonly TREE_LAST="└──"
readonly TREE_PIPE="│  "
readonly TREE_SPACE="   "

# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints
# ─────────────────────────────────────────────────────────────────────────────
readonly DOCKERHUB_API="https://hub.docker.com/v2"
readonly DOCKERHUB_REGISTRY="https://registry.hub.docker.com/v2"
readonly QUAY_API="https://quay.io/api/v1"
readonly LXC_IMAGES_API="https://images.linuxcontainers.org/1.0/images"
readonly GITHUB_API="https://api.github.com"

# ─────────────────────────────────────────────────────────────────────────────
# Supported Targets
# ─────────────────────────────────────────────────────────────────────────────
readonly -a SUPPORTED_TARGETS=("docker" "podman" "lxc" "baremetal")

# ─────────────────────────────────────────────────────────────────────────────
# Supported Package Managers
# ─────────────────────────────────────────────────────────────────────────────
readonly -a SUPPORTED_PKG_MANAGERS=("apt" "dnf" "yum" "pacman" "apk" "zypper")

# ─────────────────────────────────────────────────────────────────────────────
# Supported Distributions
# ─────────────────────────────────────────────────────────────────────────────
declare -rA DISTRO_PKG_MAP=(
    ["debian"]="apt"
    ["ubuntu"]="apt"
    ["linuxmint"]="apt"
    ["pop"]="apt"
    ["zorin"]="apt"
    ["fedora"]="dnf"
    ["centos"]="dnf"
    ["rhel"]="dnf"
    ["rocky"]="dnf"
    ["alma"]="dnf"
    ["arch"]="pacman"
    ["manjaro"]="pacman"
    ["endeavouros"]="pacman"
    ["alpine"]="apk"
    ["opensuse"]="zypper"
    ["suse"]="zypper"
)

# ─────────────────────────────────────────────────────────────────────────────
# Default Configuration Values
# ─────────────────────────────────────────────────────────────────────────────
readonly DEFAULT_TIMEZONE="UTC"
readonly DEFAULT_LOCALE="en_US.UTF-8"
readonly DEFAULT_DNS_PRIMARY="1.1.1.1"
readonly DEFAULT_DNS_SECONDARY="8.8.8.8"
readonly DEFAULT_PASSWORD_LENGTH=32
readonly DEFAULT_DOCKER_NETWORK="omni-network"
readonly DEFAULT_DOCKER_SUBNET="172.20.0.0/16"
readonly DEFAULT_RESTART_POLICY="unless-stopped"
readonly DEFAULT_LXC_PROFILE="default"
readonly DEFAULT_LXC_STORAGE="default"
readonly DEFAULT_BACKUP_RETENTION=7
readonly DEFAULT_COMPRESSION="zstd"

# ─────────────────────────────────────────────────────────────────────────────
# Spinner Frames
# ─────────────────────────────────────────────────────────────────────────────
readonly -a SPINNER_DOTS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
readonly -a SPINNER_BRAILLE=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
readonly -a SPINNER_ARROWS=("←" "↖" "↑" "↗" "→" "↘" "↓" "↙")
readonly -a SPINNER_LINES=("-" "\\" "|" "/")
readonly -a SPINNER_BLOCKS=("▏" "▎" "▍" "▌" "▋" "▊" "▉" "█" "▉" "▊" "▋" "▌" "▍" "▎" "▏")

# ─────────────────────────────────────────────────────────────────────────────
# Exit Codes
# ─────────────────────────────────────────────────────────────────────────────
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_NOT_FOUND=3
readonly EXIT_PERMISSION=4
readonly EXIT_DEPENDENCY=5
readonly EXIT_NETWORK=6
readonly EXIT_CONFIG=7
readonly EXIT_ABORT=130  # Ctrl+C

# ─────────────────────────────────────────────────────────────────────────────
# Logging Levels
# ─────────────────────────────────────────────────────────────────────────────
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default log level (can be overridden)
declare -g OMNI_LOG_LEVEL="${OMNI_LOG_LEVEL:-$LOG_LEVEL_INFO}"
declare -g OMNI_VERBOSE="${OMNI_VERBOSE:-false}"
declare -g OMNI_DRY_RUN="${OMNI_DRY_RUN:-false}"
