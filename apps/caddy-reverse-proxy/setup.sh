#!/bin/bash
# Caddy Reverse Proxy Setup Script
# Version: 1.0.0
# Description: Dead simple yet effective Caddy reverse proxy installation

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;36m'
readonly NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CADDY_CONFIG_DIR="/etc/caddy"
CADDY_DATA_DIR="/var/lib/caddy"
BACKUP_DIR="$HOME/caddy-backup-$(date +%Y%m%d-%H%M%S)"

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

# Detect OS
detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    . /etc/os-release

    if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
        log_error "Unsupported OS: $ID. This script supports Ubuntu and Debian only."
        exit 1
    fi

    log_info "Detected OS: $NAME $VERSION_ID"
}

# Install Caddy
install_caddy() {
    log_info "Installing Caddy..."

    # Check if Caddy is already installed
    if command -v caddy >/dev/null 2>&1; then
        INSTALLED_VERSION=$(caddy version | head -n1 | awk '{print $1}')
        log_warning "Caddy is already installed: $INSTALLED_VERSION"
        read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Caddy installation"
            return 0
        fi
    fi

    # Install required packages
    log_info "Installing dependencies..."
    apt-get update -qq
    apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https curl

    # Add Caddy repository
    log_info "Adding Caddy repository..."
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

    # Install Caddy
    log_info "Installing Caddy package..."
    apt-get update -qq
    apt-get install -y caddy

    # Verify installation
    if command -v caddy >/dev/null 2>&1; then
        CADDY_VERSION=$(caddy version | head -n1)
        log_success "Caddy installed successfully: $CADDY_VERSION"
    else
        log_error "Caddy installation failed"
        exit 1
    fi
}

# Backup existing configuration
backup_config() {
    if [ -f "$CADDY_CONFIG_DIR/Caddyfile" ]; then
        log_info "Backing up existing Caddyfile..."
        mkdir -p "$BACKUP_DIR"
        cp "$CADDY_CONFIG_DIR/Caddyfile" "$BACKUP_DIR/"
        log_success "Backup created: $BACKUP_DIR/Caddyfile"
    fi
}

# Setup configuration directory
setup_config() {
    log_info "Setting up configuration directory..."

    # Create config directory if it doesn't exist
    mkdir -p "$CADDY_CONFIG_DIR"
    mkdir -p "$CADDY_DATA_DIR"

    # Copy example configurations
    log_info "Copying example configurations..."
    cp "$SCRIPT_DIR/examples/"*.example "$CADDY_CONFIG_DIR/" 2>/dev/null || true

    # Create a basic Caddyfile if one doesn't exist
    if [ ! -f "$CADDY_CONFIG_DIR/Caddyfile" ]; then
        log_info "Creating basic Caddyfile..."
        cat > "$CADDY_CONFIG_DIR/Caddyfile" << 'EOF'
# Caddy Reverse Proxy Configuration
# Visit https://caddyserver.com/docs/caddyfile for documentation

# Global options
{
    # Email for Let's Encrypt notifications
    # email your-email@example.com
}

# Example: Reverse proxy to a local service
# Uncomment and modify for your use case

# example.com {
#     reverse_proxy localhost:8080
# }

# Example: Multiple services with subdomains
# service1.example.com {
#     reverse_proxy localhost:3000
# }

# service2.example.com {
#     reverse_proxy localhost:4000
# }

# Example: Docker container by name
# app.example.com {
#     reverse_proxy my-container:8080
# }
EOF
        log_success "Basic Caddyfile created at $CADDY_CONFIG_DIR/Caddyfile"
    else
        log_warning "Caddyfile already exists, skipping creation"
    fi

    # Set proper permissions
    chown -R root:root "$CADDY_CONFIG_DIR"
    chmod 644 "$CADDY_CONFIG_DIR/Caddyfile"
}

# Enable and start Caddy service
enable_service() {
    log_info "Enabling and starting Caddy service..."

    # Reload systemd
    systemctl daemon-reload

    # Enable Caddy to start on boot
    systemctl enable caddy

    # Start Caddy service
    if systemctl is-active --quiet caddy; then
        log_info "Reloading Caddy configuration..."
        systemctl reload caddy
    else
        log_info "Starting Caddy service..."
        systemctl start caddy
    fi

    # Check status
    if systemctl is-active --quiet caddy; then
        log_success "Caddy service is running"
    else
        log_error "Caddy service failed to start"
        log_info "Check logs with: journalctl -u caddy -n 50"
        exit 1
    fi
}

# Display next steps
show_next_steps() {
    echo ""
    echo "=============================================="
    log_success "Caddy Reverse Proxy Setup Complete!"
    echo "=============================================="
    echo ""
    echo "Configuration file: $CADDY_CONFIG_DIR/Caddyfile"
    echo "Example configurations: $CADDY_CONFIG_DIR/*.example"
    echo ""
    echo "Next steps:"
    echo "  1. Edit the Caddyfile: nano $CADDY_CONFIG_DIR/Caddyfile"
    echo "  2. Add your domain(s) and backend service(s)"
    echo "  3. Reload Caddy: systemctl reload caddy"
    echo ""
    echo "Useful commands:"
    echo "  • Check status: systemctl status caddy"
    echo "  • View logs: journalctl -u caddy -f"
    echo "  • Validate config: caddy validate --config $CADDY_CONFIG_DIR/Caddyfile"
    echo "  • Reload config: systemctl reload caddy"
    echo "  • Restart service: systemctl restart caddy"
    echo ""
    echo "Example configurations are available in:"
    echo "  $SCRIPT_DIR/examples/"
    echo ""
    if [ -d "$BACKUP_DIR" ]; then
        echo "Backup of previous configuration:"
        echo "  $BACKUP_DIR/"
        echo ""
    fi
    echo "For detailed documentation, see:"
    echo "  $SCRIPT_DIR/README.md"
    echo "  https://caddyserver.com/docs/"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "=============================================="
    echo "  Caddy Reverse Proxy Setup"
    echo "  Version: 1.0.0"
    echo "=============================================="
    echo ""

    check_root
    detect_os
    install_caddy
    backup_config
    setup_config
    enable_service
    show_next_steps
}

# Run main function
main "$@"
