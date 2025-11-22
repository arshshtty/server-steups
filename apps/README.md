# Self-Hosted Application Scripts

This directory contains installation and setup scripts for self-hosted applications.

## Purpose

While the `docker-compose/` directory contains containerized deployments, this directory provides:
- Native installation scripts (non-Docker)
- Automated setup procedures
- Configuration helpers
- Migration tools
- Custom deployment scripts

## Structure

Each application has its own directory:
```
app-name/
├── install.sh          # Installation script
├── configure.sh        # Configuration helper
├── update.sh          # Update script
├── backup.sh          # Backup script
├── README.md          # Documentation
└── config/            # Configuration templates
```

## Planned Applications

- **ntfy** - Push notification service
- **n8n** - Workflow automation
- **gitea** - Git service
- **caddy** - Web server with automatic HTTPS
- **monitoring** - Prometheus + Grafana
- **backup-tools** - Automated backup solutions

## Usage

### Install an Application

```bash
cd app-name/
chmod +x install.sh
sudo ./install.sh
```

### Configure

```bash
cd app-name/
./configure.sh
```

### Update

```bash
cd app-name/
./update.sh
```

### Backup

```bash
cd app-name/
./backup.sh
```

## When to Use vs Docker Compose

**Use scripts in this directory when:**
- You need native performance
- System integration is required
- Docker overhead is not acceptable
- Running on very constrained hardware
- Specific requirements prevent containerization

**Use docker-compose/ when:**
- You want easy deployment and updates
- Isolation is important
- Portability across systems is needed
- Multiple instances on same host
- Development and testing

## Best Practices

1. **Make scripts idempotent** - safe to run multiple times
2. **Check prerequisites** before installation
3. **Provide uninstall scripts** when possible
4. **Log operations** for troubleshooting
5. **Support different OS versions**
6. **Handle errors gracefully**
7. **Document all steps**

## Script Template

```bash
#!/bin/bash
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
fi

# Prerequisites check
command -v docker >/dev/null 2>&1 || {
    echo "Docker is required but not installed."
    exit 1
}

# Installation steps
echo "Installing application..."

# Configuration
echo "Configuring..."

# Service setup
echo "Setting up systemd service..."

echo "Installation complete!"
```

## Contributing

When adding a new application:
1. Create a directory for the app
2. Write modular, well-commented scripts
3. Test on fresh installations
4. Document all configuration options
5. Include troubleshooting section
6. Add uninstall/cleanup scripts
7. Update this README
