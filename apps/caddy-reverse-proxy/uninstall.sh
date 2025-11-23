#!/bin/bash
# Caddy Reverse Proxy Uninstall Script
# Version: 1.0.0
# Description: Clean removal of Caddy with optional data preservation

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;36m'
readonly NC='\033[0m'

# Configuration
CADDY_CONFIG_DIR="/etc/caddy"
CADDY_DATA_DIR="/var/lib/caddy"
BACKUP_DIR="$HOME/caddy-backup-$(date +%Y%m%d-%H%M%S)"
KEEP_DATA=false

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

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --keep-data)
                KEEP_DATA=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << EOF
Caddy Uninstall Script

Usage: sudo bash uninstall.sh [OPTIONS]

Options:
    --keep-data     Keep configuration and data files (backup only)
    --help          Show this help message

Examples:
    # Complete removal
    sudo bash uninstall.sh

    # Remove Caddy but keep configuration
    sudo bash uninstall.sh --keep-data

EOF
}

# Check if Caddy is installed
check_installed() {
    if ! command -v caddy >/dev/null 2>&1; then
        log_warning "Caddy is not installed"
        exit 0
    fi

    CADDY_VERSION=$(caddy version | head -n1)
    log_info "Found Caddy: $CADDY_VERSION"
}

# Backup configuration
backup_config() {
    log_info "Creating backup of configuration..."

    mkdir -p "$BACKUP_DIR"

    if [ -d "$CADDY_CONFIG_DIR" ]; then
        cp -r "$CADDY_CONFIG_DIR" "$BACKUP_DIR/config"
        log_success "Configuration backed up to: $BACKUP_DIR/config"
    fi

    if [ -d "$CADDY_DATA_DIR" ]; then
        # Only backup certificates, not the entire data directory
        if [ -d "$CADDY_DATA_DIR/certificates" ]; then
            cp -r "$CADDY_DATA_DIR/certificates" "$BACKUP_DIR/certificates"
            log_success "Certificates backed up to: $BACKUP_DIR/certificates"
        fi
    fi
}

# Stop and disable service
stop_service() {
    log_info "Stopping Caddy service..."

    if systemctl is-active --quiet caddy; then
        systemctl stop caddy
        log_success "Caddy service stopped"
    else
        log_info "Caddy service is not running"
    fi

    if systemctl is-enabled --quiet caddy 2>/dev/null; then
        systemctl disable caddy
        log_success "Caddy service disabled"
    fi
}

# Remove Caddy package
remove_package() {
    log_info "Removing Caddy package..."

    apt-get remove --purge -y caddy 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true

    log_success "Caddy package removed"
}

# Remove repository
remove_repository() {
    log_info "Removing Caddy repository..."

    if [ -f /etc/apt/sources.list.d/caddy-stable.list ]; then
        rm -f /etc/apt/sources.list.d/caddy-stable.list
        log_success "Repository list removed"
    fi

    if [ -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg ]; then
        rm -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg
        log_success "Repository keyring removed"
    fi

    apt-get update -qq 2>/dev/null || true
}

# Remove configuration and data
remove_data() {
    if [ "$KEEP_DATA" = true ]; then
        log_info "Keeping configuration and data files (--keep-data flag set)"
        log_info "Configuration: $CADDY_CONFIG_DIR"
        log_info "Data: $CADDY_DATA_DIR"
        return 0
    fi

    log_warning "Removing configuration and data directories..."

    if [ -d "$CADDY_CONFIG_DIR" ]; then
        rm -rf "$CADDY_CONFIG_DIR"
        log_success "Configuration directory removed: $CADDY_CONFIG_DIR"
    fi

    if [ -d "$CADDY_DATA_DIR" ]; then
        rm -rf "$CADDY_DATA_DIR"
        log_success "Data directory removed: $CADDY_DATA_DIR"
    fi
}

# Remove logs
remove_logs() {
    log_info "Removing logs..."

    # Remove custom log files if they exist
    if [ -d /var/log/caddy ]; then
        rm -rf /var/log/caddy
        log_success "Log directory removed"
    fi

    # Clear systemd journal for Caddy
    journalctl --vacuum-time=1s --unit=caddy 2>/dev/null || true
}

# Display completion message
show_completion() {
    echo ""
    echo "=============================================="
    log_success "Caddy Uninstall Complete!"
    echo "=============================================="
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo "Backup location: $BACKUP_DIR"
        echo ""
        echo "The following files were backed up:"
        ls -lh "$BACKUP_DIR"
        echo ""
    fi

    if [ "$KEEP_DATA" = true ]; then
        echo "Configuration and data preserved:"
        echo "  Config: $CADDY_CONFIG_DIR"
        echo "  Data: $CADDY_DATA_DIR"
        echo ""
        echo "To completely remove these directories:"
        echo "  sudo rm -rf $CADDY_CONFIG_DIR"
        echo "  sudo rm -rf $CADDY_DATA_DIR"
        echo ""
    fi

    echo "To reinstall Caddy in the future:"
    echo "  cd apps/caddy-reverse-proxy"
    echo "  sudo bash setup.sh"
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo "To restore from backup:"
        echo "  sudo cp -r $BACKUP_DIR/config/* $CADDY_CONFIG_DIR/"
        echo ""
    fi
}

# Confirm uninstallation
confirm_uninstall() {
    echo ""
    echo "=============================================="
    echo "  Caddy Reverse Proxy Uninstall"
    echo "  Version: 1.0.0"
    echo "=============================================="
    echo ""

    if [ "$KEEP_DATA" = true ]; then
        log_info "Mode: Remove Caddy but keep configuration"
    else
        log_warning "Mode: Complete removal (package + configuration + data)"
    fi

    echo ""
    echo "This will:"
    echo "  • Stop and disable Caddy service"
    echo "  • Remove Caddy package"
    echo "  • Remove repository configuration"
    if [ "$KEEP_DATA" = false ]; then
        echo "  • Remove configuration directory: $CADDY_CONFIG_DIR"
        echo "  • Remove data directory: $CADDY_DATA_DIR"
    fi
    echo "  • Create backup in: $BACKUP_DIR"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
}

# Main uninstallation function
main() {
    parse_args "$@"
    check_root
    check_installed
    confirm_uninstall
    backup_config
    stop_service
    remove_package
    remove_repository
    remove_logs
    remove_data
    show_completion
}

# Run main function
main "$@"
