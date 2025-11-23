#!/bin/bash
# Nginx Reverse Proxy Manager - Uninstallation Script
# Version: 1.0.0

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/nginx-proxy"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

# Logging functions
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Main uninstall function
main() {
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     Nginx Reverse Proxy Manager - Uninstall              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

EOF

    check_root

    log_warning "This will remove the Nginx Reverse Proxy Manager"
    echo ""

    # Ask about keeping configurations
    read -p "Keep proxy configurations and data? (Y/n): " -n 1 -r
    echo
    local keep_data=true
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        keep_data=false
    fi

    echo ""
    log_info "Starting uninstallation..."
    echo ""

    # Remove command
    if [ -f "$INSTALL_DIR/nginx-proxy" ]; then
        rm -f "$INSTALL_DIR/nginx-proxy"
        log_success "Removed: $INSTALL_DIR/nginx-proxy"
    fi

    # Handle configuration and proxy files
    if [ "$keep_data" = false ]; then
        # Remove all proxy configurations
        if [ -f "$CONFIG_DIR/proxies.json" ]; then
            log_info "Removing proxy configurations..."

            # Get list of managed domains from config
            if command -v python3 >/dev/null 2>&1; then
                domains=$(python3 -c "
import json
try:
    with open('$CONFIG_DIR/proxies.json', 'r') as f:
        data = json.load(f)
    for domain in data.keys():
        print(domain)
except:
    pass
" 2>/dev/null)

                # Remove each domain's nginx config
                for domain in $domains; do
                    if [ -f "$NGINX_SITES_AVAILABLE/$domain" ]; then
                        rm -f "$NGINX_SITES_AVAILABLE/$domain"
                        log_info "Removed Nginx config: $domain"
                    fi

                    if [ -L "$NGINX_SITES_ENABLED/$domain" ]; then
                        rm -f "$NGINX_SITES_ENABLED/$domain"
                        log_info "Disabled site: $domain"
                    fi
                done
            fi
        fi

        # Remove configuration directory
        if [ -d "$CONFIG_DIR" ]; then
            rm -rf "$CONFIG_DIR"
            log_success "Removed: $CONFIG_DIR"
        fi

        # Remove log file
        if [ -f "/var/log/nginx-proxy.log" ]; then
            rm -f "/var/log/nginx-proxy.log"
            log_success "Removed log file"
        fi
    else
        log_info "Keeping configuration directory: $CONFIG_DIR"
        log_info "Keeping proxy configurations in: $NGINX_SITES_AVAILABLE/"
    fi

    # Reload Nginx
    if command -v nginx >/dev/null 2>&1; then
        if nginx -t 2>&1 | grep -q "successful"; then
            systemctl reload nginx
            log_info "Reloaded Nginx"
        fi
    fi

    echo ""
    log_success "Uninstallation complete!"

    if [ "$keep_data" = true ]; then
        echo ""
        log_info "To completely remove all data, run:"
        log_info "  sudo rm -rf $CONFIG_DIR"
        log_info "  sudo rm -f /var/log/nginx-proxy.log"
    fi

    echo ""
    log_warning "Note: Nginx itself was NOT removed"
    log_info "To remove Nginx, run: sudo apt-get remove nginx"
    echo ""
}

# Run main function
main "$@"
