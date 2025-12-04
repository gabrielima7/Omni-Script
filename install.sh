#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#   ____                   _    _____           _       __  
#  / __ \                 (_)  / ____|         (_)     / _| 
# | |  | |_ __ ___  _ __   _  | (___   ___ _ __ _ _ __ | |_  
# | |  | | '_ ` _ \| '_ \ | |  \___ \ / __| '__| | '_ \|  _| 
# | |__| | | | | | | | | || |  ____) | (__| |  | | |_) | |   
#  \____/|_| |_| |_|_| |_||_| |_____/ \___|_|  |_| .__/|_|   
#                                                | |         
#                                                |_|         
#
#  One-Liner Installer for Omni-Script IaC Framework
#  Usage: curl -sSL https://raw.githubusercontent.com/gabrielima7/Linux-Library/main/install.sh | bash
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/gabrielima7/Linux-Library"
REPO_RAW="https://raw.githubusercontent.com/gabrielima7/Linux-Library/main"
INSTALL_DIR="${HOME}/.local/share/omni-script"
BIN_DIR="${HOME}/.local/bin"
OMNI_CMD="omni"

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────
info() { echo -e "${CYAN}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
   ____                   _    _____           _       __  
  / __ \                 (_)  / ____|         (_)     / _| 
 | |  | |_ __ ___  _ __   _  | (___   ___ _ __ _ _ __ | |_  
 | |  | | '_ ` _ \| '_ \ | |  \___ \ / __| '__| | '_ \|  _| 
 | |__| | | | | | | | | || |  ____) | (__| |  | | |_) | |   
  \____/|_| |_| |_|_| |_||_| |_____/ \___|_|  |_| .__/|_|   
                                                | |         
                                                |_|         
EOF
    echo -e "${NC}"
    echo -e "${DIM}  Modular Infrastructure as Code Framework${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────${NC}"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Check Dependencies
# ─────────────────────────────────────────────────────────────────────────────
check_deps() {
    info "Checking dependencies..."
    
    local missing=()
    
    for cmd in curl git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing: ${missing[*]}"
        
        # Try to install
        if command -v apt-get &>/dev/null; then
            info "Installing with apt..."
            sudo apt-get update -qq
            sudo apt-get install -y "${missing[@]}"
        elif command -v dnf &>/dev/null; then
            info "Installing with dnf..."
            sudo dnf install -y "${missing[@]}"
        elif command -v pacman &>/dev/null; then
            info "Installing with pacman..."
            sudo pacman -S --noconfirm "${missing[@]}"
        else
            error "Please install: ${missing[*]}"
        fi
    fi
    
    success "Dependencies OK"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Omni-Script
# ─────────────────────────────────────────────────────────────────────────────
install_omni() {
    info "Installing Omni-Script..."
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    
    # Clone or update repository
    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        info "Updating existing installation..."
        cd "$INSTALL_DIR"
        git pull --quiet
    else
        info "Cloning repository..."
        rm -rf "$INSTALL_DIR"
        git clone --quiet --depth 1 "$REPO_URL" "$INSTALL_DIR"
    fi
    
    success "Downloaded Omni-Script"
    
    # Make scripts executable
    chmod +x "${INSTALL_DIR}/omni.sh"
    find "${INSTALL_DIR}/lib" -name "*.sh" -exec chmod +x {} \;
    find "${INSTALL_DIR}/modules" -name "*.sh" -exec chmod +x {} \;
    
    # Create symlink
    ln -sf "${INSTALL_DIR}/omni.sh" "${BIN_DIR}/${OMNI_CMD}"
    
    success "Installed to ${INSTALL_DIR}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Configure PATH
# ─────────────────────────────────────────────────────────────────────────────
configure_path() {
    local shell_rc=""
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    
    # Detect shell
    case "$SHELL" in
        */bash) shell_rc="$HOME/.bashrc" ;;
        */zsh)  shell_rc="$HOME/.zshrc" ;;
        *)      shell_rc="$HOME/.profile" ;;
    esac
    
    # Add PATH if not already there
    if ! grep -q '.local/bin' "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Omni-Script" >> "$shell_rc"
        echo "$path_line" >> "$shell_rc"
        info "Added ${BIN_DIR} to PATH in ${shell_rc}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify Installation
# ─────────────────────────────────────────────────────────────────────────────
verify_install() {
    info "Verifying installation..."
    
    if [[ -x "${BIN_DIR}/${OMNI_CMD}" ]]; then
        success "Installation verified!"
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}              ${BOLD}✓ Omni-Script Installed!${NC}                   ${GREEN}║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  ${CYAN}Run:${NC}  ${BOLD}omni help${NC}                                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  ${DIM}Or restart your terminal / run:${NC}                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}source ~/.bashrc${NC}                                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        error "Installation failed!"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
main() {
    clear
    banner
    
    echo -e "${BOLD}Starting installation...${NC}"
    echo ""
    
    check_deps
    install_omni
    configure_path
    verify_install
    
    # Run version check
    echo -e "${DIM}$("${BIN_DIR}/${OMNI_CMD}" --version 2>/dev/null || echo "v1.0.0")${NC}"
}

# Run
main "$@"
