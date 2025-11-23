#!/bin/bash
# Nginx Reverse Proxy Manager - Installation Script
# Version: 1.0.0

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/nginx-proxy"
LOG_FILE="/var/log/nginx-proxy-install.log"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}

# Print banner
print_banner() {
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Nginx Reverse Proxy Manager - Setup               ║
║        Simple CLI tool for managing reverse proxies      ║
║        Version: 1.0.0                                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo ""
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
        log_error "Cannot detect OS - /etc/os-release not found"
        return 1
    fi

    . /etc/os-release

    if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
        log_warning "This script is tested on Ubuntu/Debian. Your OS: $ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    log_info "Detected OS: $NAME $VERSION_ID"
}

# Check if Nginx is installed
check_nginx() {
    if command -v nginx >/dev/null 2>&1; then
        local version=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')
        log_info "Nginx is already installed (version: $version)"
        return 0
    fi
    return 1
}

# Install Nginx
install_nginx() {
    log_info "Installing Nginx..."

    apt-get update -qq
    apt-get install -y nginx

    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx

    log_success "Nginx installed and started successfully"
}

# Install certbot (optional)
install_certbot() {
    if command -v certbot >/dev/null 2>&1; then
        log_info "Certbot is already installed"
        return 0
    fi

    log_info "Installing Certbot for Let's Encrypt SSL support..."

    apt-get install -y certbot python3-certbot-nginx

    # Enable certbot renewal timer
    systemctl enable certbot.timer
    systemctl start certbot.timer

    log_success "Certbot installed successfully"
    log_info "SSL certificates will auto-renew via systemd timer"
}

# Install Python3 (required for JSON config management)
install_python() {
    if command -v python3 >/dev/null 2>&1; then
        log_info "Python3 is already installed"
        return 0
    fi

    log_info "Installing Python3..."
    apt-get install -y python3

    log_success "Python3 installed successfully"
}

# Setup nginx-proxy command
setup_command() {
    log_info "Installing nginx-proxy command..."

    # Copy the main script
    cp "$SCRIPT_DIR/nginx-proxy" "$INSTALL_DIR/nginx-proxy"
    chmod +x "$INSTALL_DIR/nginx-proxy"

    log_success "Command installed: $INSTALL_DIR/nginx-proxy"
}

# Create configuration directory
setup_config() {
    log_info "Creating configuration directory..."

    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        log_info "Created: $CONFIG_DIR"
    fi

    # Create initial config file
    if [ ! -f "$CONFIG_DIR/proxies.json" ]; then
        echo '{}' > "$CONFIG_DIR/proxies.json"
        log_info "Created: $CONFIG_DIR/proxies.json"
    fi

    log_success "Configuration directory ready"
}

# Configure firewall (if ufw is installed)
configure_firewall() {
    if ! command -v ufw >/dev/null 2>&1; then
        log_info "UFW not installed, skipping firewall configuration"
        return 0
    fi

    log_info "Configuring firewall (UFW)..."

    # Check if UFW is active
    if ufw status | grep -q "Status: active"; then
        # Allow HTTP
        if ! ufw status | grep -q "80/tcp.*ALLOW"; then
            ufw allow 80/tcp comment 'Nginx HTTP'
            log_info "Allowed HTTP (port 80)"
        fi

        # Allow HTTPS
        if ! ufw status | grep -q "443/tcp.*ALLOW"; then
            ufw allow 443/tcp comment 'Nginx HTTPS'
            log_info "Allowed HTTPS (port 443)"
        fi

        log_success "Firewall configured successfully"
    else
        log_info "UFW is not active, skipping firewall rules"
    fi
}

# Setup Nginx default configuration
setup_nginx_default() {
    log_info "Configuring Nginx default settings..."

    # Ensure sites-available and sites-enabled directories exist
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled

    # Check if nginx.conf includes sites-enabled
    if ! grep -q "include /etc/nginx/sites-enabled/\*" /etc/nginx/nginx.conf; then
        log_info "Adding sites-enabled include to nginx.conf..."

        # Backup original config
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

        # Add include directive in http block
        sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    fi

    # Test Nginx configuration
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        log_success "Nginx configuration updated successfully"
    else
        log_error "Nginx configuration test failed"
        if [ -f /etc/nginx/nginx.conf.backup ]; then
            log_info "Restoring backup configuration..."
            mv /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
        fi
        return 1
    fi
}

# Print installation summary
print_summary() {
    cat <<EOF

╔═══════════════════════════════════════════════════════════╗
║                 Installation Complete!                    ║
╚═══════════════════════════════════════════════════════════╝

The Nginx Reverse Proxy Manager has been installed successfully.

📋 Quick Start:

   # Add a reverse proxy
   sudo nginx-proxy add myapp.com localhost:3000

   # List all proxies
   nginx-proxy list

   # Enable SSL with Let's Encrypt
   sudo nginx-proxy enable-ssl myapp.com admin@example.com

   # Remove a proxy
   sudo nginx-proxy remove myapp.com

📚 Commands:
   nginx-proxy add <domain> <backend>    - Add new proxy
   nginx-proxy remove <domain>           - Remove proxy
   nginx-proxy list                      - List all proxies
   nginx-proxy enable-ssl <domain>       - Enable HTTPS
   nginx-proxy help                      - Show all commands

📁 Files:
   Command:        $INSTALL_DIR/nginx-proxy
   Configuration:  $CONFIG_DIR/proxies.json
   Nginx sites:    /etc/nginx/sites-available/
   Logs:           /var/log/nginx-proxy.log

🔒 Security Notes:
   - Default configurations use HTTP (port 80)
   - Use 'nginx-proxy enable-ssl' to enable HTTPS
   - Ensure your DNS records point to this server
   - Configure your firewall appropriately

📖 For more information:
   nginx-proxy help
   cat $SCRIPT_DIR/README.md

EOF
}

# Main installation function
main() {
    print_banner

    log_info "Starting installation..."
    log_info "Installation log: $LOG_FILE"
    echo ""

    # Checks
    check_root
    detect_os

    echo ""

    # Install components
    if ! check_nginx; then
        install_nginx
    fi

    echo ""

    install_python
    echo ""

    # Ask about certbot
    read -p "Install Certbot for SSL/TLS support? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_certbot
    else
        log_info "Skipping Certbot installation"
        log_warning "SSL features will not be available without Certbot"
    fi

    echo ""

    # Setup
    setup_config
    setup_command
    setup_nginx_default
    configure_firewall

    echo ""

    # Success
    log_success "Installation completed successfully!"

    print_summary
}

# Run main function
main "$@"
