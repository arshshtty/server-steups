#!/bin/bash
# Traefik Reverse Proxy Setup Script
# Version: 1.0.0

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ===================================
# Helper Functions
# ===================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

execute() {
    local cmd="$*"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $cmd"
        return 0
    fi
    eval "$cmd"
}

# ===================================
# Validation Functions
# ===================================

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed. Please install Docker first."
        log_info "Run: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    log_success "Docker is installed"
}

check_docker_compose() {
    if ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not installed or not available."
        exit 1
    fi
    log_success "Docker Compose is available"
}

# ===================================
# Setup Functions
# ===================================

create_directories() {
    log_info "Creating necessary directories..."

    execute "mkdir -p $SCRIPT_DIR/letsencrypt"
    execute "mkdir -p $SCRIPT_DIR/logs"
    execute "mkdir -p $SCRIPT_DIR/dynamic"

    # Set proper permissions for acme.json
    if [ -f "$SCRIPT_DIR/letsencrypt/acme.json" ]; then
        execute "chmod 600 $SCRIPT_DIR/letsencrypt/acme.json"
    else
        execute "touch $SCRIPT_DIR/letsencrypt/acme.json"
        execute "chmod 600 $SCRIPT_DIR/letsencrypt/acme.json"
    fi

    log_success "Directories created"
}

setup_env_file() {
    if [ -f "$SCRIPT_DIR/.env" ]; then
        log_warning ".env file already exists, skipping..."
        return 0
    fi

    log_info "Creating .env file from template..."
    execute "cp $SCRIPT_DIR/.env.example $SCRIPT_DIR/.env"
    log_success ".env file created"
    log_warning "Please edit $SCRIPT_DIR/.env with your configuration!"
}

create_traefik_config() {
    if [ -f "$SCRIPT_DIR/traefik.yml" ]; then
        log_info "traefik.yml already exists, skipping..."
        return 0
    fi

    log_info "Creating basic traefik.yml configuration..."

    cat > "$SCRIPT_DIR/traefik.yml" <<'EOF'
# Traefik Static Configuration
# This file contains static configuration that doesn't change often

# API and Dashboard
api:
  dashboard: true

# Providers
providers:
  docker:
    exposedByDefault: false
  file:
    directory: /dynamic
    watch: true

# Entry Points
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

# Certificate Resolvers
certificatesResolvers:
  letsencrypt:
    acme:
      storage: /letsencrypt/acme.json
EOF

    log_success "traefik.yml created"
}

generate_password() {
    if ! command -v htpasswd >/dev/null 2>&1; then
        log_warning "htpasswd not found. Installing apache2-utils..."
        if [ "$DRY_RUN" = false ]; then
            sudo apt-get update -qq
            sudo apt-get install -y apache2-utils
        fi
    fi

    log_info "Generating dashboard password..."
    echo ""
    read -p "Enter username for Traefik dashboard [admin]: " username
    username=${username:-admin}

    read -s -p "Enter password: " password
    echo ""

    if [ -n "$password" ]; then
        hashed=$(htpasswd -nb "$username" "$password" | sed -e 's/\$/\$\$/g')
        log_info "Add this to your .env file:"
        echo ""
        echo "DASHBOARD_AUTH=$hashed"
        echo ""
    fi
}

create_network() {
    log_info "Creating Docker network 'traefik_proxy'..."

    if docker network ls | grep -q traefik_proxy; then
        log_warning "Network 'traefik_proxy' already exists"
        return 0
    fi

    execute "docker network create traefik_proxy"
    log_success "Network created"
}

start_traefik() {
    log_info "Starting Traefik..."

    cd "$SCRIPT_DIR"
    execute "docker compose up -d"

    log_success "Traefik started!"
    log_info "Check status with: docker compose ps"
    log_info "View logs with: docker compose logs -f"
}

show_next_steps() {
    echo ""
    echo "=========================================="
    echo "  Traefik Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Edit your .env file:"
    echo "   nano $SCRIPT_DIR/.env"
    echo ""
    echo "2. Update ACME_EMAIL with your email"
    echo "3. Update TRAEFIK_DASHBOARD_DOMAIN with your domain"
    echo "4. Update DASHBOARD_AUTH with a secure password"
    echo "   Generate with: htpasswd -nb admin your_password | sed -e 's/\$/\$\$/g'"
    echo ""
    echo "5. Start Traefik:"
    echo "   cd $SCRIPT_DIR"
    echo "   docker compose up -d"
    echo ""
    echo "6. Check logs:"
    echo "   docker compose logs -f"
    echo ""
    echo "7. Configure your services to use Traefik"
    echo "   See README.md for examples"
    echo ""
}

# ===================================
# Main Function
# ===================================

main() {
    log_info "Traefik Reverse Proxy Setup"
    echo ""

    # Validate prerequisites
    check_docker
    check_docker_compose

    # Setup
    create_directories
    setup_env_file
    create_traefik_config
    create_network

    if [ "$DRY_RUN" = true ]; then
        log_warning "Dry-run mode: No changes were made"
        show_next_steps
        exit 0
    fi

    # Ask to generate password
    read -p "Generate dashboard password now? [y/N]: " gen_pass
    if [[ "$gen_pass" =~ ^[Yy]$ ]]; then
        generate_password
    fi

    # Ask to start Traefik
    read -p "Start Traefik now? [y/N]: " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        start_traefik
    else
        show_next_steps
    fi

    log_success "Setup complete!"
}

# Show usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Setup Traefik reverse proxy with Docker Compose

OPTIONS:
    --dry-run       Preview changes without making them
    --verbose       Enable verbose output
    -h, --help      Show this help message

EXAMPLES:
    # Preview setup
    $0 --dry-run

    # Run setup
    $0

    # Run with verbose output
    $0 --verbose

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
