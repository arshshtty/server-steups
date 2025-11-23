#!/bin/bash
# NAT Manager Installation Script
# Installs and configures NAT Manager for Proxmox

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
INSTALL_DIR="/opt/nat-manager"
CONFIG_DIR="/etc/nat_manager"
SYSTEMD_DIR="/etc/systemd/system"
BIN_DIR="/usr/local/bin"

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
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting NAT Manager installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    log_error "Cannot detect OS"
    exit 1
fi

log_info "Detected OS: $OS $VERSION_ID"

# Install dependencies
log_info "Installing dependencies..."

if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    apt-get update
    apt-get install -y python3 python3-pip python3-venv iptables iptables-persistent
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]]; then
    yum install -y python3 python3-pip iptables iptables-services
else
    log_warning "Unsupported OS. Attempting to continue anyway..."
fi

log_success "Dependencies installed"

# Create directories
log_info "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/backups"
mkdir -p /etc/iptables

log_success "Directories created"

# Copy files
log_info "Installing NAT Manager files..."

# Copy main script
cp "$SCRIPT_DIR/nat_manager.py" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/nat_manager.py"

# Create symlink for CLI
ln -sf "$INSTALL_DIR/nat_manager.py" "$BIN_DIR/nat-manager"

# Copy web UI
cp -r "$SCRIPT_DIR/web" "$INSTALL_DIR/"

# Copy config if doesn't exist
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cp "$SCRIPT_DIR/config/config.json.example" "$CONFIG_DIR/config.json"
    log_info "Created default configuration file"
else
    log_info "Configuration file already exists, skipping"
fi

log_success "Files installed"

# Setup Python virtual environment
log_info "Setting up Python virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"
pip install --upgrade pip
pip install flask
deactivate

log_success "Virtual environment created"

# Copy systemd service files
log_info "Installing systemd services..."

# Create web UI service
cat > "$SYSTEMD_DIR/nat-manager-web.service" << 'EOF'
[Unit]
Description=NAT Manager Web UI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nat-manager/web
Environment="NAT_CONFIG=/etc/nat_manager/config.json"
Environment="NAT_WEB_HOST=0.0.0.0"
Environment="NAT_WEB_PORT=8888"
ExecStart=/opt/nat-manager/venv/bin/python /opt/nat-manager/web/app.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create iptables restore service
cat > "$SYSTEMD_DIR/nat-manager-restore.service" << 'EOF'
[Unit]
Description=NAT Manager - Restore iptables rules on boot
After=network.target
Before=nat-manager-web.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/iptables/rules.v4
ExecStartPost=/usr/sbin/sysctl -w net.ipv4.ip_forward=1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

log_success "Systemd services installed"

# Enable IP forwarding permanently
log_info "Enabling IP forwarding..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1

log_success "IP forwarding enabled"

# Enable and start services
log_info "Enabling services..."
systemctl daemon-reload
systemctl enable nat-manager-restore.service
systemctl enable netfilter-persistent.service 2>/dev/null || true

# Ask if user wants to start the web UI now
echo ""
read -p "Do you want to start the NAT Manager Web UI now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl enable nat-manager-web.service
    systemctl start nat-manager-web.service
    log_success "Web UI started"

    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}NAT Manager is now installed and running!${NC}"
    echo ""
    echo "Access the Web UI at:"
    echo -e "  ${BLUE}http://${SERVER_IP}:8888${NC}"
    echo ""
    echo "Command-line usage:"
    echo "  nat-manager add <ip> --mode automatic"
    echo "  nat-manager list"
    echo "  nat-manager remove <ip>"
    echo ""
    echo "Configuration file:"
    echo "  $CONFIG_DIR/config.json"
    echo ""
    echo "Service management:"
    echo "  systemctl status nat-manager-web"
    echo "  systemctl restart nat-manager-web"
    echo "  systemctl stop nat-manager-web"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    log_info "Web UI not started. To start it later, run:"
    echo "  systemctl enable nat-manager-web"
    echo "  systemctl start nat-manager-web"
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Command-line usage:"
    echo "  nat-manager add <ip> --mode automatic"
    echo "  nat-manager list"
    echo "  nat-manager remove <ip>"
fi

echo ""
log_info "Installation log saved to /var/log/nat_manager.log"
