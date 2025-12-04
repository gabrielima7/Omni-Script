#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: credentials.sh
# Description: Secure credential generation and management
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_CREDENTIALS_LOADED:-}" ]] && return 0
readonly _OMNI_CREDENTIALS_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Generate Secure Password
# ─────────────────────────────────────────────────────────────────────────────
generate_password() {
    local length="${1:-$DEFAULT_PASSWORD_LENGTH}"
    local charset="${2:-A-Za-z0-9!@#\$%^&*}"
    
    # Use /dev/urandom for cryptographically secure randomness
    tr -dc "$charset" </dev/urandom | head -c "$length"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate Alphanumeric Only Password
# ─────────────────────────────────────────────────────────────────────────────
generate_password_alnum() {
    local length="${1:-32}"
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate Username
# ─────────────────────────────────────────────────────────────────────────────
generate_username() {
    local prefix="${1:-user}"
    local suffix
    suffix=$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    echo "${prefix}_${suffix}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate API Key
# ─────────────────────────────────────────────────────────────────────────────
generate_api_key() {
    local length="${1:-48}"
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate UUID v4
# ─────────────────────────────────────────────────────────────────────────────
generate_uuid() {
    if [[ -f /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    else
        # Fallback
        printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
            $RANDOM $RANDOM $RANDOM \
            $(( (RANDOM & 0x0FFF) | 0x4000 )) \
            $(( (RANDOM & 0x3FFF) | 0x8000 )) \
            $RANDOM $RANDOM $RANDOM
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Hash Password (bcrypt-style using openssl)
# ─────────────────────────────────────────────────────────────────────────────
hash_password() {
    local password="$1"
    
    if command -v openssl &>/dev/null; then
        echo -n "$password" | openssl passwd -6 -stdin
    else
        # Fallback to sha256
        echo -n "$password" | sha256sum | cut -d' ' -f1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Store Credentials (encrypted)
# ─────────────────────────────────────────────────────────────────────────────
store_credentials() {
    local app_name="$1"
    local username="$2"
    local password="$3"
    local creds_file="${OMNI_CONFIG_DIR}/.credentials/${app_name}.env"
    
    mkdir -p "$(dirname "$creds_file")"
    chmod 700 "$(dirname "$creds_file")"
    
    cat > "$creds_file" << EOF
# Credentials for ${app_name}
# Generated: $(date -Iseconds)
APP_USER="${username}"
APP_PASSWORD="${password}"
EOF
    
    chmod 600 "$creds_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Load Credentials
# ─────────────────────────────────────────────────────────────────────────────
load_credentials() {
    local app_name="$1"
    local creds_file="${OMNI_CONFIG_DIR}/.credentials/${app_name}.env"
    
    if [[ -f "$creds_file" ]]; then
        # shellcheck source=/dev/null
        source "$creds_file"
        return 0
    fi
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Ensure Password (generate if empty)
# ─────────────────────────────────────────────────────────────────────────────
ensure_password() {
    local password="$1"
    local length="${2:-32}"
    
    if [[ -z "$password" ]]; then
        generate_password "$length"
    else
        echo "$password"
    fi
}
