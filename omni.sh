#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  ██████╗ ███╗   ███╗███╗   ██╗██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
# ██╔═══██╗████╗ ████║████╗  ██║██║    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
# ██║   ██║██╔████╔██║██╔██╗ ██║██║    ███████╗██║     ██████╔╝██║██████╔╝   ██║   
# ██║   ██║██║╚██╔╝██║██║╚██╗██║██║    ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
# ╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║    ███████║╚██████╗██║  ██║██║██║        ██║   
#  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
# ═══════════════════════════════════════════════════════════════════════════════
# Omni-Script: Modular Infrastructure as Code Framework
# Version: 1.0.0
# License: MIT
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly MODULES_DIR="${SCRIPT_DIR}/modules"
readonly RECIPES_DIR="${SCRIPT_DIR}/recipes"
readonly CONFIG_FILE="${SCRIPT_DIR}/global.conf"

# ─────────────────────────────────────────────────────────────────────────────
# Source Core Libraries
# ─────────────────────────────────────────────────────────────────────────────
source_libs() {
    local libs=(
        "${LIB_DIR}/core/constants.sh"
        "${LIB_DIR}/core/logger.sh"
        "${LIB_DIR}/core/utils.sh"
        "${LIB_DIR}/core/init.sh"
        "${LIB_DIR}/ui/colors.sh"
        "${LIB_DIR}/ui/banners.sh"
        "${LIB_DIR}/ui/spinner.sh"
        "${LIB_DIR}/ui/progress.sh"
        "${LIB_DIR}/ui/prompts.sh"
        "${LIB_DIR}/ui/summary.sh"
        "${LIB_DIR}/config/parser.sh"
        "${LIB_DIR}/config/global.sh"
        "${LIB_DIR}/security/credentials.sh"
        "${LIB_DIR}/registry/search.sh"
        "${LIB_DIR}/adapters/adapter_base.sh"
    )
    
    for lib in "${libs[@]}"; do
        if [[ -f "$lib" ]]; then
            # shellcheck source=/dev/null
            source "$lib"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────────────────────────
show_usage() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                          🚀 OMNI-SCRIPT CLI                                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Modular Infrastructure as Code Framework for Hybrid Deployments             ║
╚══════════════════════════════════════════════════════════════════════════════╝

USAGE:
    omni <command> [options]

COMMANDS:
    install <app>       Install an application
    remove <app>        Remove an application
    search <query>      Search packages and container images
    stack               Build a custom stack (databases, backends, frontends)
    backup <app>        Backup an application
    restore <app>       Restore an application from backup
    list                List installed applications
    status <app>        Check application status
    logs <app>          View application logs
    config              Manage global configuration
    update              Update Omni-Script to latest version
    help                Show this help message

OPTIONS:
    --target <target>   Specify target: docker, podman, lxc, baremetal
    --config global     Use global configuration defaults
    --dry-run           Show what would be done without executing
    --verbose           Enable verbose output
    --version           Show version information

EXAMPLES:
    omni install nginx --target docker
    omni search postgres
    omni stack build --target docker
    omni backup portainer --full
    omni config show

For more information, visit: https://github.com/gabrielima7/Linux-Library
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Version
# ─────────────────────────────────────────────────────────────────────────────
show_version() {
    echo "Omni-Script v${OMNI_VERSION}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Command Router
# ─────────────────────────────────────────────────────────────────────────────
route_command() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        install)
            cmd_install "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        search)
            cmd_search "$@"
            ;;
        stack)
            cmd_stack "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        logs)
            cmd_logs "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo "Run 'omni help' for usage information."
            exit 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Command Implementations (Stubs - will be expanded)
# ─────────────────────────────────────────────────────────────────────────────
cmd_install() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        echo "Usage: omni install <app> [--target docker|podman|lxc|baremetal]"
        exit 1
    fi
    
    # Check if installer module is loaded
    if declare -f installer_run &>/dev/null; then
        installer_run "$@"
    else
        source "${MODULES_DIR}/installer/engine.sh" 2>/dev/null || true
        if declare -f installer_run &>/dev/null; then
            installer_run "$@"
        else
            echo "⚠️  Installer module not yet implemented"
            echo "📦 Would install: $app"
        fi
    fi
}

cmd_remove() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        exit 1
    fi
    echo "🗑️  Would remove: $app"
}

cmd_search() {
    local query="${1:-}"
    if [[ -z "$query" ]]; then
        echo "❌ Error: Search query required"
        echo "Usage: omni search <query>"
        exit 1
    fi
    
    if declare -f unified_search &>/dev/null; then
        unified_search "$query"
    else
        echo "🔍 Searching for: $query"
        echo "⚠️  Search module loading..."
        source "${LIB_DIR}/registry/search.sh" 2>/dev/null || true
        if declare -f unified_search &>/dev/null; then
            unified_search "$query"
        else
            echo "⚠️  Search module not yet available"
        fi
    fi
}

cmd_stack() {
    local subcommand="${1:-build}"
    
    if declare -f builder_stack &>/dev/null; then
        builder_stack "$@"
    else
        source "${MODULES_DIR}/builder/stack.sh" 2>/dev/null || true
        if declare -f builder_stack &>/dev/null; then
            builder_stack "$@"
        else
            echo "🏗️  Builder Stack"
            echo "⚠️  Module not yet implemented"
        fi
    fi
}

cmd_backup() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        exit 1
    fi
    
    if declare -f backup_app &>/dev/null; then
        backup_app "$@"
    else
        source "${MODULES_DIR}/backup/backup.sh" 2>/dev/null || true
        if declare -f backup_app &>/dev/null; then
            backup_app "$@"
        else
            echo "💾 Would backup: $app"
            echo "⚠️  Backup module not yet implemented"
        fi
    fi
}

cmd_restore() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        exit 1
    fi
    echo "♻️  Would restore: $app"
}

cmd_list() {
    echo "📋 Installed Applications"
    echo "========================="
    echo "⚠️  List feature not yet implemented"
}

cmd_status() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        exit 1
    fi
    echo "📊 Status for: $app"
}

cmd_logs() {
    local app="${1:-}"
    if [[ -z "$app" ]]; then
        echo "❌ Error: Application name required"
        exit 1
    fi
    echo "📜 Logs for: $app"
}

cmd_config() {
    local subcommand="${1:-show}"
    case "$subcommand" in
        show)
            if [[ -f "$CONFIG_FILE" ]]; then
                echo "⚙️  Global Configuration"
                echo "========================"
                cat "$CONFIG_FILE"
            else
                echo "⚠️  No configuration file found at: $CONFIG_FILE"
            fi
            ;;
        set)
            echo "⚙️  Config set: ${2:-}"
            ;;
        *)
            echo "Usage: omni config [show|set key=value]"
            ;;
    esac
}

cmd_update() {
    echo "🔄 Checking for updates..."
    echo "⚠️  Update feature not yet implemented"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Entry Point
# ─────────────────────────────────────────────────────────────────────────────
main() {
    # Source libraries
    source_libs
    
    # Initialize system if init function exists
    if declare -f omni_init &>/dev/null; then
        omni_init
    fi
    
    # Show banner if function exists and no args
    if [[ $# -eq 0 ]] && declare -f show_banner &>/dev/null; then
        show_banner
    fi
    
    # Route to appropriate command
    route_command "$@"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
