# Server Setup Scripts Repository

## Overview

This repository contains setup scripts, Docker Compose configurations, and installation guides for self-hosted applications and server infrastructure. The goal is to provide a centralized collection of reusable scripts to quickly deploy and configure servers with various tools and services.

## Purpose

Store and organize:
- Server setup and configuration scripts
- Docker Compose files for containerized applications
- Installation scripts for self-hosted applications (ntfy, n8n, gitea, etc.)
- Container management utilities
- Reusable infrastructure as code templates

## Repository Structure

```
server-steups/
├── base/                      # Base system setup scripts
│   ├── setup.sh              # Full development environment setup
│   ├── setup-minimal.sh      # Minimal setup for servers
│   └── verify.sh             # Verification script
├── docker-compose/           # Docker Compose configurations
│   ├── ntfy/                 # ntfy notification service
│   ├── n8n/                  # n8n workflow automation
│   ├── gitea/                # Gitea git service
│   └── README.md            # Docker compose usage guide
├── apps/                     # Self-hosted app installation scripts
│   ├── proxmox-nat/          # NAT port forwarding manager
│   ├── prometheus-grafana/   # Monitoring stack
│   ├── nginx-proxy/          # Nginx reverse proxy manager
│   ├── ntfy/                 # ntfy setup scripts (planned)
│   ├── n8n/                  # n8n setup scripts (planned)
│   ├── gitea/                # gitea setup scripts (planned)
│   └── README.md            # App installation guide
├── scripts/                  # Utility scripts
│   ├── backup.sh            # Backup utilities
│   ├── restore.sh           # Restore utilities
│   └── update.sh            # Update utilities
├── docs/                     # Documentation (legacy)
│   └── ...                  # Existing documentation files
├── CLAUDE.md                # This file - Claude Code documentation
└── README.md                # Main repository documentation
```

## Current Contents

### Base Setup Scripts (v2.0.0)

The repository contains production-ready, modular setup scripts:

**Main Scripts:**
- **base/setup.sh**: Full-featured setup with modular architecture
- **base/setup-minimal.sh**: Lightweight version for CI/CD
- **base/verify.sh**: Post-installation verification

**Shared Libraries (NEW):**
- **base/lib/common.sh**: Common functions (logging, OS detection, package management)
- **base/lib/install-zsh.sh**: Zsh and Oh My Zsh installation module
- **base/lib/install-node.sh**: Node.js installation module
- **base/lib/install-python.sh**: Python and uv installation module
- **base/lib/install-docker.sh**: Docker and Docker Compose installation module
- **base/lib/install-extras.sh**: Additional CLI utilities module

**Configuration:**
- **base/config/default.conf**: Configuration template with all available options

**Key Features (v2.0):**
- ✅ Modular architecture for reusability
- ✅ Dry-run mode to preview changes
- ✅ Configuration file support
- ✅ Post-installation verification
- ✅ Comprehensive logging with file output
- ✅ Component selection via flags
- ✅ OS version detection and validation
- ✅ Improved error handling and recovery

**Documentation:**
- Multiple markdown and text files documenting the VM setup workflow in `docs/`

### NAT Manager for Proxmox (v1.0.0)

A comprehensive NAT port forwarding management tool for Proxmox servers with a single public IPv4 address.

**Key Features:**
- ✅ Modern web-based dashboard (Flask + Bootstrap)
- ✅ Command-line interface for automation
- ✅ Automatic port assignment (starting from 50000)
- ✅ Pre-configured default ports (SSH:22, HTTP:80, HTTPS:443, 8080)
- ✅ Real-time statistics and monitoring
- ✅ Backup/restore functionality
- ✅ Import/export configuration as JSON
- ✅ Port reservation system
- ✅ Database rebuild from existing iptables rules
- ✅ Systemd services for auto-start and rule restoration
- ✅ Comprehensive logging

**Components:**
- **nat_manager.py**: Core Python script with configuration file support
- **web/app.py**: Flask-based REST API and web interface
- **web/templates/**: Responsive Bootstrap-based dashboard
- **web/static/**: CSS and JavaScript for interactive UI
- **setup.sh**: Automated installation with dependency management
- **uninstall.sh**: Clean removal with optional data preservation
- **systemd services**: Auto-start web UI and restore iptables on boot

**Installation:**
```bash
cd apps/proxmox-nat
sudo bash setup.sh
# Access web UI at http://your-server:8888
```

**Use Cases:**
- Managing NAT port forwarding for multiple VMs/containers
- Proxmox servers with single public IPv4 address
- Simplifying iptables NAT rule management
- Providing non-technical users with GUI for port management

**Documentation:**
- **README.md**: Comprehensive guide with examples and troubleshooting (540 lines)
- **QUICKSTART.md**: 5-minute getting started guide

### Monitoring Stack (Prometheus + Grafana)

Production-ready monitoring solution with metrics collection and visualization.

**Components:**
- Prometheus for metrics collection
- Grafana for visualization
- Pre-configured dashboards
- Docker Compose based deployment

### Nginx Reverse Proxy Manager (v1.0.0)

A dead simple yet effective CLI tool for managing Nginx reverse proxy configurations.

**Key Features:**
- ✅ Dead simple CLI interface
- ✅ Automatic SSL/TLS with Let's Encrypt integration
- ✅ WebSocket support for real-time applications
- ✅ Configuration management in JSON format
- ✅ Zero-downtime Nginx reloads
- ✅ Pre-configured security headers
- ✅ Automatic firewall configuration (UFW)
- ✅ Per-domain access and error logs
- ✅ One-command proxy setup

**Components:**
- **nginx-proxy**: Main bash script for CLI management
- **setup.sh**: Automated installation with dependency management
- **uninstall.sh**: Clean removal with optional data preservation
- **config/**: Configuration templates and examples

**Installation:**
```bash
cd apps/nginx-proxy
sudo bash setup.sh
```

**Quick Usage:**
```bash
# Add a reverse proxy
sudo nginx-proxy add myapp.com localhost:3000

# Enable SSL with Let's Encrypt
sudo nginx-proxy enable-ssl myapp.com admin@example.com

# List all proxies
nginx-proxy list

# Remove a proxy
sudo nginx-proxy remove myapp.com
```

**Use Cases:**
- Exposing multiple self-hosted applications on different subdomains
- Proxying to Docker containers or VMs
- Quick reverse proxy setup for homelab services
- SSL/TLS termination with automatic certificate renewal
- WebSocket proxy for real-time applications (n8n, Home Assistant, etc.)

**Documentation:**
- **README.md**: Comprehensive guide with examples and troubleshooting
- **QUICKSTART.md**: 5-minute getting started guide

## Completed Additions

### Infrastructure Tools

1. **NAT Manager** ✅ - Port forwarding management for Proxmox
   - Web-based dashboard
   - CLI interface
   - Automatic port assignment
   - Backup/restore functionality

2. **Prometheus + Grafana** ✅ - Monitoring stack
   - Metrics collection
   - Visualization dashboards
   - Docker-based deployment

3. **Nginx Reverse Proxy Manager** ✅ - Simple reverse proxy management
   - CLI-based management
   - Automatic SSL with Let's Encrypt
   - WebSocket support
   - One-command proxy setup

## Planned Additions

### Self-Hosted Applications

1. **ntfy** - Push notification service
   - Docker Compose setup
   - Configuration templates
   - Reverse proxy configs

2. **n8n** - Workflow automation platform
   - Docker Compose with PostgreSQL
   - Environment configuration
   - Backup/restore scripts

3. **gitea** - Self-hosted Git service
   - Docker Compose setup
   - Database configuration
   - Migration guides

4. **Additional services to be added**:
   - Uptime Kuma (monitoring)
   - Vaultwarden (password manager)
   - Nextcloud (file sync)
   - Jellyfin (media server)

### Infrastructure Scripts

- Automated backups
- System monitoring setup
- Log aggregation
- Security hardening scripts

## Working with This Repository

### Adding New Services

When adding a new self-hosted service, choose the appropriate deployment method:

#### Docker Compose Services

For containerized applications:

1. Create a directory under `docker-compose/SERVICE_NAME/`
2. Include:
   - `docker-compose.yml` - Docker Compose configuration
   - `README.md` - Service-specific documentation
   - `.env.example` - Environment variable template
   - Configuration files as needed

3. Update main README.md with the new service

#### Native/Python Applications

For native applications (like NAT Manager):

1. Create a directory under `apps/SERVICE_NAME/`
2. Include:
   - Main script(s) (e.g., `service_manager.py`)
   - `web/` directory for web-based interfaces (if applicable)
     - `app.py` - Flask/web framework entry point
     - `templates/` - HTML templates
     - `static/` - CSS, JavaScript, images
   - `config/` directory with `.example` configuration files
   - `systemd/` directory with service files
   - `setup.sh` - Automated installation script
   - `uninstall.sh` - Clean removal script
   - `requirements.txt` - Python dependencies
   - `README.md` - Comprehensive documentation
   - `QUICKSTART.md` - Quick start guide (optional but recommended)

3. Update main README.md and CLAUDE.md with the new service

**Example Structure (Python Web Application):**
```
apps/my-service/
├── my_service.py              # Core functionality
├── web/                       # Web interface
│   ├── app.py                # Flask application
│   ├── templates/
│   │   └── index.html
│   └── static/
│       ├── css/style.css
│       └── js/app.js
├── config/
│   └── config.json.example
├── systemd/
│   ├── my-service-web.service
│   └── my-service-restore.service
├── setup.sh
├── uninstall.sh
├── requirements.txt
├── README.md
└── QUICKSTART.md
```

### Best Practices

**General:**
- Include comprehensive README files with examples
- Add example configurations (`.example` files)
- Document prerequisites and dependencies
- Include troubleshooting sections
- Version control everything except secrets
- Provide both quick start and detailed documentation

**Docker Compose Services:**
- Keep docker-compose files production-ready
- Use environment variables for sensitive data
- Include health checks
- Set resource limits
- Use named volumes for data persistence

**Python/Flask Web Applications:**
- Use virtual environments (`venv`)
- Provide `requirements.txt` with pinned versions
- Support configuration via JSON/environment variables
- Include systemd service files for production deployment
- Run as appropriate user (root only when necessary, e.g., iptables)
- Implement proper logging (file + stdout)
- Add error handling and user-friendly error messages
- Use Bootstrap or similar framework for consistent UI
- Provide REST API endpoints for programmatic access
- Include both CLI and web interfaces when applicable

### Testing

**Shell Scripts:**
- Test all scripts on fresh Ubuntu/Debian installations
- Verify scripts are idempotent (safe to run multiple times)
- Test dry-run modes where applicable
- Run shellcheck for syntax validation

**Docker Compose Services:**
- Verify Docker Compose files work in isolation
- Check all environment variables are documented
- Test service health checks
- Verify persistent data survives container restarts

**Python Web Applications:**
- Test installation script on clean system
- Verify systemd services start and stop correctly
- Test web UI in multiple browsers
- Verify CLI commands work as expected
- Test configuration file loading
- Verify logging is working correctly
- Test uninstall script preserves/removes data as expected

## Development Branch

This repository uses feature branches for development:
- Main branch: `main` (production-ready scripts)
- Feature branches: `claude/server-setup-scripts-*`

## Conventions

### File Naming
- Scripts: `kebab-case.sh`
- Docker Compose: `docker-compose.yml`
- Environment files: `.env.example`

### Documentation
- Each service/app should have its own README
- Include version information
- Document all configuration options
- Provide real-world examples

### Code Style
- Use shellcheck for bash scripts
- Follow Docker best practices
- Include comments for complex operations
- Add error handling
- Use `set -e` or `set -euo pipefail` for error handling
- Implement idempotency (scripts safe to run multiple times)
- Use functions for reusability
- Provide dry-run modes where applicable
- Add verification steps after installation
- Use meaningful variable names and constants

## Common Tasks

### Deploy a Docker Compose service
```bash
cd docker-compose/SERVICE_NAME
cp .env.example .env
# Edit .env with your configuration
docker-compose up -d
```

### Deploy a Python web application (e.g., NAT Manager)
```bash
cd apps/SERVICE_NAME
sudo bash setup.sh
# Follow interactive prompts
# Access web UI as shown in output
```

### Manage Python web application services
```bash
# Check status
systemctl status nat-manager-web

# View logs
journalctl -u nat-manager-web -f

# Restart service
systemctl restart nat-manager-web

# Stop service
systemctl stop nat-manager-web
```

### Run base setup on new server
```bash
curl -fsSL https://raw.githubusercontent.com/USER/server-steups/main/base/setup.sh | bash
```

### Update all containers
```bash
./scripts/update.sh
```

### Backup configuration
```bash
./scripts/backup.sh
```

## Security Notes

**General:**
- Never commit `.env` files with real secrets
- Always use `.env.example` as templates
- Store secrets in secure vaults (not in git)
- Use strong, unique passwords
- Keep systems and containers updated
- Enable firewall rules
- Use HTTPS/TLS for all services

**Web Applications:**
- Restrict web UI access using firewall rules (ufw, iptables)
- Use SSH tunneling for remote access when possible
- Run web services as non-root when possible (except when system operations require it)
- Implement rate limiting on API endpoints
- Add authentication for production deployments
- Use HTTPS/TLS with reverse proxy (Caddy, Nginx, Traefik)
- Keep Flask and dependencies updated
- Set secure session cookies (httponly, secure, samesite)

**For Single-User/Personal Deployments:**
- Default configurations prioritize ease of use over enterprise security
- Web UIs may run without authentication for convenience
- Ensure proper network segmentation (private network only)
- Use SSH tunneling or VPN for access from outside trusted network

## Shell Script Best Practices

When writing setup or utility scripts for this repository, follow these best practices:

### Error Handling
```bash
# Always use strict error handling
set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipe failure

# Or combined:
set -euo pipefail

# Add cleanup on exit
trap cleanup_function EXIT
```

### Idempotency
```bash
# Check if already installed before installing
if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed"
    return 0
fi

# Check if configuration already applied
if grep -q "desired_config" /path/to/file; then
    echo "Already configured"
    return 0
fi
```

### Modular Design
```bash
# Use functions for reusability
install_component() {
    local component="$1"
    echo "Installing $component..."
    # Installation logic
}

verify_component() {
    local component="$1"
    if command -v "$component" >/dev/null 2>&1; then
        echo "✓ $component installed"
        return 0
    else
        echo "✗ $component not found"
        return 1
    fi
}
```

### Configuration Support
```bash
# Support configuration from multiple sources
CONFIG_FILE="${CONFIG_FILE:-$HOME/.app-config}"

# 1. Load default configuration
source "$SCRIPT_DIR/config/default.conf"

# 2. Load system-wide config
[ -f /etc/app-config ] && source /etc/app-config

# 3. Load user config
[ -f "$HOME/.app-config" ] && source "$HOME/.app-config"

# 4. Environment variables override all
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
```

### Dry-Run Support
```bash
DRY_RUN="${DRY_RUN:-false}"

execute() {
    local cmd="$*"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would execute: $cmd"
        return 0
    fi
    eval "$cmd"
}

# Usage
execute "apt-get install -y package"
```

### Logging
```bash
# Color-coded logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}
```

### OS Detection and Validation
```bash
detect_os() {
    if [ ! -f /etc/os-release ]; then
        echo "Cannot detect OS"
        return 1
    fi

    . /etc/os-release

    if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
        echo "Unsupported OS: $ID"
        return 1
    fi

    echo "Detected: $NAME $VERSION_ID"
    return 0
}
```

### Download with Retries
```bash
download_file() {
    local url="$1"
    local output="$2"
    local max_retries="${3:-3}"

    for ((i=1; i<=max_retries; i++)); do
        if curl -fsSL "$url" -o "$output"; then
            return 0
        fi
        echo "Download failed, retry $i/$max_retries..."
        sleep 2
    done

    echo "Failed to download after $max_retries attempts"
    return 1
}
```

### Script Template
```bash
#!/bin/bash
# Script Description
# Version: 1.0.0

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Source common library if available
if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

# Main function
main() {
    echo "Starting..."

    # Your logic here

    echo "Complete!"
}

# Run main function
main "$@"
```

## Contributing

When making changes:
1. Create a feature branch
2. Test thoroughly on a clean system
3. Follow the shell script best practices above
4. Update documentation
5. Run shellcheck on bash scripts
6. Test dry-run mode
7. Commit with clear messages
8. Push to feature branch

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Self-Hosted List](https://github.com/awesome-selfhosted/awesome-selfhosted)

## License

MIT License - Use freely for personal or commercial projects
