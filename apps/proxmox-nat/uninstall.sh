#!/bin/bash
# NAT Manager Uninstallation Script

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root or with sudo"
    exit 1
fi

echo ""
log_warning "This will uninstall NAT Manager from your system."
echo ""
read -p "Do you want to keep your port mappings and configuration? (y/n) " -n 1 -r
echo ""
KEEP_DATA=$REPLY

echo ""
read -p "Are you sure you want to uninstall NAT Manager? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

log_info "Uninstalling NAT Manager..."

# Stop and disable services
log_info "Stopping services..."
systemctl stop nat-manager-web.service 2>/dev/null || true
systemctl disable nat-manager-web.service 2>/dev/null || true
systemctl stop nat-manager-restore.service 2>/dev/null || true
systemctl disable nat-manager-restore.service 2>/dev/null || true

# Remove systemd service files
log_info "Removing service files..."
rm -f /etc/systemd/system/nat-manager-web.service
rm -f /etc/systemd/system/nat-manager-restore.service
systemctl daemon-reload

# Remove installation directory
log_info "Removing installation files..."
rm -rf /opt/nat-manager

# Remove symlink
rm -f /usr/local/bin/nat-manager

# Remove configuration and data if requested
if [[ ! $KEEP_DATA =~ ^[Yy]$ ]]; then
    log_info "Removing configuration and data..."
    rm -rf /etc/nat_manager
    log_warning "All port mappings have been removed from the database"
    log_warning "NOTE: iptables rules are still active!"
    echo ""
    echo "To remove all NAT rules from iptables, run:"
    echo "  iptables -t nat -F PREROUTING"
    echo "  iptables-save > /etc/iptables/rules.v4"
else
    log_info "Configuration and data preserved in /etc/nat_manager"
fi

# Remove log file
rm -f /var/log/nat_manager.log

echo ""
echo -e "${GREEN}NAT Manager has been uninstalled.${NC}"
echo ""
