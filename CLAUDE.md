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
│   ├── ntfy/                 # ntfy setup scripts
│   ├── n8n/                  # n8n setup scripts
│   ├── gitea/                # gitea setup scripts
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
   - Traefik/Caddy (reverse proxy)

### Infrastructure Scripts

- SSL certificate management (Let's Encrypt)
- Automated backups
- System monitoring setup
- Log aggregation
- Security hardening scripts

## Working with This Repository

### Adding New Services

When adding a new self-hosted service:

1. Create a directory under `apps/` and `docker-compose/`
2. Include:
   - `docker-compose.yml` - Docker Compose configuration
   - `README.md` - Service-specific documentation
   - `.env.example` - Environment variable template
   - `setup.sh` - Installation/setup script (if needed)
   - `backup.sh` - Backup script (if applicable)

3. Update main README.md with the new service

### Best Practices

- Keep docker-compose files production-ready
- Use environment variables for sensitive data
- Include comprehensive README files
- Add example configurations
- Document prerequisites
- Include troubleshooting steps
- Version control everything except secrets

### Testing

- Test all scripts on fresh Ubuntu/Debian installations
- Verify Docker Compose files work in isolation
- Check all environment variables are documented
- Ensure scripts are idempotent where possible

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

### Deploy a new service
```bash
cd docker-compose/SERVICE_NAME
cp .env.example .env
# Edit .env with your configuration
docker-compose up -d
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

- Never commit `.env` files with real secrets
- Always use `.env.example` as templates
- Store secrets in secure vaults (not in git)
- Use strong, unique passwords
- Keep systems and containers updated
- Enable firewall rules
- Use HTTPS/TLS for all services

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
