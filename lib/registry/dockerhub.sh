#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: dockerhub.sh
# Description: Docker Hub API integration
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_DOCKERHUB_LOADED:-}" ]] && return 0
readonly _OMNI_DOCKERHUB_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../core/constants.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/utils.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Search Docker Hub
# ─────────────────────────────────────────────────────────────────────────────
search_dockerhub() {
    local query="$1"
    local limit="${2:-5}"
    
    if ! cmd_exists curl; then
        echo -e "  ${DIM}curl required for Docker Hub search${RST}"
        return 1
    fi
    
    local response
    response=$(curl -sf "${DOCKERHUB_API}/search/repositories/?query=${query}&page_size=${limit}" 2>/dev/null)
    
    if [[ -z "$response" ]] || ! has_jq; then
        echo -e "  ${DIM}No results or jq not available${RST}"
        return 1
    fi
    
    local count
    count=$(echo "$response" | jq -r '.count // 0')
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "  ${DIM}No images found${RST}"
        return 0
    fi
    
    echo "$response" | jq -r --arg icon "$TREE_BRANCH" --arg star "⭐" \
        '.results[] | "  \($icon) \(.repo_name) \($star) \(.star_count) - \(.short_description // "")[0:45]"' 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Latest Stable Tag (excludes latest, alpha, beta, rc, dev)
# ─────────────────────────────────────────────────────────────────────────────
get_latest_stable_tag() {
    local image="$1"
    local namespace="${image%%/*}"
    local repo="${image#*/}"
    
    # Handle official images (no namespace)
    if [[ "$namespace" == "$image" ]]; then
        namespace="library"
        repo="$image"
    fi
    
    if ! cmd_exists curl || ! has_jq; then
        echo "latest"
        return 1
    fi
    
    local url="${DOCKERHUB_API}/repositories/${namespace}/${repo}/tags?page_size=50"
    local response
    response=$(curl -sf "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "latest"
        return 1
    fi
    
    # Filter out unstable tags and get the latest semantic version
    local tag
    tag=$(echo "$response" | jq -r '
        .results[].name 
        | select(. != "latest") 
        | select(test("alpha|beta|rc|dev|nightly|edge") | not)
        | select(test("^[0-9]"))
    ' 2>/dev/null | sort -rV | head -1)
    
    if [[ -n "$tag" ]]; then
        echo "$tag"
    else
        echo "latest"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Image Tags
# ─────────────────────────────────────────────────────────────────────────────
get_image_tags() {
    local image="$1"
    local limit="${2:-10}"
    local namespace="${image%%/*}"
    local repo="${image#*/}"
    
    [[ "$namespace" == "$image" ]] && namespace="library" && repo="$image"
    
    local url="${DOCKERHUB_API}/repositories/${namespace}/${repo}/tags?page_size=${limit}"
    local response
    response=$(curl -sf "$url" 2>/dev/null)
    
    if [[ -z "$response" ]] || ! has_jq; then
        return 1
    fi
    
    echo "$response" | jq -r '.results[].name' 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Check if Image Exists
# ─────────────────────────────────────────────────────────────────────────────
image_exists() {
    local image="$1"
    local tag="${2:-latest}"
    local namespace="${image%%/*}"
    local repo="${image#*/}"
    
    [[ "$namespace" == "$image" ]] && namespace="library" && repo="$image"
    
    local url="${DOCKERHUB_API}/repositories/${namespace}/${repo}/tags/${tag}"
    curl -sf "$url" &>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Image Info
# ─────────────────────────────────────────────────────────────────────────────
get_image_info() {
    local image="$1"
    local namespace="${image%%/*}"
    local repo="${image#*/}"
    
    [[ "$namespace" == "$image" ]] && namespace="library" && repo="$image"
    
    local url="${DOCKERHUB_API}/repositories/${namespace}/${repo}"
    curl -sf "$url" 2>/dev/null
}
