#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# File: composer.sh
# Description: Docker Compose file generator for Builder Stack
# ═══════════════════════════════════════════════════════════════════════════════

[[ -n "${_OMNI_COMPOSER_LOADED:-}" ]] && return 0
readonly _OMNI_COMPOSER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/security/credentials.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Generate Docker Compose
# ─────────────────────────────────────────────────────────────────────────────
compose_generate() {
    local output_dir="$1"
    local compose_file="${output_dir}/docker-compose.yml"
    local env_file="${output_dir}/.env"
    
    # Generate secrets
    local db_pass
    db_pass=$(generate_password 24)
    
    # Create .env file
    cat > "$env_file" << EOF
COMPOSE_PROJECT_NAME=${STACK_NAME}
DB_PASSWORD=${db_pass}
DOMAIN=${STACK_NAME}.local
EOF
    
    # Start compose file
    cat > "$compose_file" << 'EOF'
version: "3.9"

services:
EOF

    # Add database
    _add_database_service "$compose_file"
    
    # Add backend  
    _add_backend_service "$compose_file"
    
    # Add frontend
    _add_frontend_service "$compose_file"
    
    # Add proxy
    _add_proxy_service "$compose_file"
    
    # Add networks and volumes
    cat >> "$compose_file" << 'EOF'

networks:
  internal:
  web:

volumes:
  db_data:
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Database Service
# ─────────────────────────────────────────────────────────────────────────────
_add_database_service() {
    local file="$1"
    
    case "$STACK_DB" in
        PostgreSQL)
            cat >> "$file" << 'EOF'
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: app
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

EOF
            ;;
        MariaDB)
            cat >> "$file" << 'EOF'
  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
      MYSQL_DATABASE: app
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - internal

EOF
            ;;
        MongoDB)
            cat >> "$file" << 'EOF'
  db:
    image: mongo:7
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/data/db
    networks:
      - internal

EOF
            ;;
        Redis)
            cat >> "$file" << 'EOF'
  cache:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - internal

EOF
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Backend Service
# ─────────────────────────────────────────────────────────────────────────────
_add_backend_service() {
    local file="$1"
    
    [[ "$STACK_BACKEND" == "None" ]] && return
    
    cat >> "$file" << 'EOF'
  backend:
    build: ./backend
    restart: unless-stopped
    depends_on:
      - db
    networks:
      - internal
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=PathPrefix(`/api`)"

EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Frontend Service
# ─────────────────────────────────────────────────────────────────────────────
_add_frontend_service() {
    local file="$1"
    
    [[ "$STACK_FRONTEND" == "None" ]] && return
    
    cat >> "$file" << 'EOF'
  frontend:
    build: ./frontend
    restart: unless-stopped
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`${DOMAIN}`)"

EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Proxy Service
# ─────────────────────────────────────────────────────────────────────────────
_add_proxy_service() {
    local file="$1"
    
    case "$STACK_PROXY" in
        Traefik)
            cat >> "$file" << 'EOF'
  proxy:
    image: traefik:v3.0
    restart: unless-stopped
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - web

EOF
            ;;
        Nginx)
            cat >> "$file" << 'EOF'
  proxy:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - web

EOF
            ;;
        Caddy)
            cat >> "$file" << 'EOF'
  proxy:
    image: caddy:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      - web

EOF
            ;;
    esac
}
