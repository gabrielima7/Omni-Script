#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: parser.sh
# Description: Configuration file parser
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_CONFIG_PARSER_LOADED:-}" ]] && return 0
readonly _OMNI_CONFIG_PARSER_LOADED=1

# ─────────────────────────────────────────────────────────────────────────────
# Parse INI-style Config
# ─────────────────────────────────────────────────────────────────────────────
parse_config() {
    local file="$1"
    local section=""
    
    [[ ! -f "$file" ]] && return 1
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Section header
        if [[ "$line" =~ ^\[([a-zA-Z0-9_]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Key=value
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # Export as SECTION_KEY or just KEY
            if [[ -n "$section" ]]; then
                local varname="CONF_${section^^}_${key^^}"
            else
                local varname="CONF_${key^^}"
            fi
            
            export "$varname"="$value"
        fi
    done < "$file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Config Value
# ─────────────────────────────────────────────────────────────────────────────
config_get() {
    local section="$1"
    local key="$2"
    local default="${3:-}"
    
    local varname="CONF_${section^^}_${key^^}"
    local value="${!varname:-$default}"
    echo "$value"
}

# ─────────────────────────────────────────────────────────────────────────────
# Write Config Value
# ─────────────────────────────────────────────────────────────────────────────
config_set() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"
    
    # Simple implementation - append or update
    if grep -q "^${key}[[:space:]]*=" "$file" 2>/dev/null; then
        sed -i "s|^${key}[[:space:]]*=.*|${key} = \"${value}\"|" "$file"
    else
        echo "${key} = \"${value}\"" >> "$file"
    fi
}
