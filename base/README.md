# Base System Setup Scripts

Modular, production-ready setup scripts for Debian/Ubuntu servers and VMs with advanced features.

## 📁 Directory Structure

```
base/
├── setup.sh              # Full-featured setup (v2.0.0)
├── setup-minimal.sh      # Minimal setup (v2.0.0)
├── verify.sh             # Post-installation verification
├── lib/                  # Shared libraries
│   ├── common.sh        # Common functions and utilities
│   ├── install-zsh.sh   # Zsh installation module
│   ├── install-node.sh  # Node.js installation module
│   ├── install-python.sh # Python installation module
│   ├── install-docker.sh # Docker installation module
│   └── install-extras.sh # Additional utilities module
└── config/
    └── default.conf     # Default configuration template
```

## 🚀 Quick Start

### Standard Installation
```bash
cd base
./setup.sh
```

### Remote Installation
```bash
# Full setup
curl -fsSL https://raw.githubusercontent.com/USER/server-steups/main/base/setup.sh | bash

# Minimal setup
curl -fsSL https://raw.githubusercontent.com/USER/server-steups/main/base/setup-minimal.sh | bash
```

### Dry Run (Preview Changes)
```bash
./setup.sh --dry-run
```

## 📜 Scripts

### setup.sh (v2.0.0)

**Full-featured setup with modular architecture**

Installs:
- ✅ Zsh with Oh My Zsh and plugins (autosuggestions, syntax-highlighting, completions)
- ✅ Node.js (LTS) + npm + npx
- ✅ Python 3 + pip + venv + uv
- ✅ Docker + Docker Compose (both plugin and standalone)
- ✅ CLI utilities (fzf, bat, ripgrep, htop, tmux, jq, tree, etc.)

**New Features in v2.0:**
- 🎯 **Dry-run mode** - Preview changes without installing
- 🔍 **Post-installation verification** - Automatic validation
- ⚙️ **Configuration file support** - Customize via config files
- 📝 **Comprehensive logging** - Optional file logging
- 🧩 **Modular architecture** - Reusable installation modules
- 🎛️ **Component selection** - Skip components with flags
- 🛡️ **OS detection** - Validates Ubuntu/Debian version
- 📊 **Installation summary** - Clear report of what was installed

**Usage Examples:**
```bash
# Standard installation
./setup.sh

# Dry run to preview
./setup.sh --dry-run

# Install without Docker
./setup.sh --no-docker

# Verbose mode with logging
./setup.sh --verbose --log-file /tmp/setup.log

# Skip all updates
./setup.sh --no-updates

# Multiple options
./setup.sh --no-docker --no-extras --verbose
```

**Command Line Options:**
```
--dry-run              Show what would be installed without making changes
-v, --verbose          Enable verbose output
--log-file FILE        Write log to specified file
--skip-verification    Skip post-installation verification
--version              Show version and exit
-h, --help             Show help message

Component Selection:
--no-zsh               Skip Zsh and Oh My Zsh installation
--no-node              Skip Node.js installation
--no-python            Skip Python installation
--no-docker            Skip Docker installation
--no-extras            Skip additional utilities installation
--no-updates           Skip system package updates
```

### setup-minimal.sh (v2.0.0)

**Lightweight version optimized for CI/CD and containers**

**Improvements in v2.0:**
- ✅ Better error handling (`set -euo pipefail`)
- ✅ Idempotent checks (skip if already installed)
- ✅ Post-installation verification
- ✅ Dry-run support via environment variable
- ✅ Proper logging with timestamps
- ✅ Graceful failure handling

**Usage:**
```bash
# Standard
./setup-minimal.sh

# Dry run
DRY_RUN=true ./setup-minimal.sh

# Skip verification
SKIP_VERIFICATION=true ./setup-minimal.sh
```

**Environment Variables:**
- `DRY_RUN=true` - Preview without installing
- `SKIP_VERIFICATION=true` - Skip verification steps

### verify.sh

Post-installation verification script that checks all installations.

**Usage:**
```bash
./verify.sh
```

## ⚙️ Configuration

### Method 1: Environment Variables

```bash
export INSTALL_DOCKER=false
export NODE_VERSION=20
export VERBOSE=true
./setup.sh
```

### Method 2: Configuration File

Create `~/.setup-config` or `/etc/setup-config`:

```bash
# Component selection
INSTALL_ZSH=true
INSTALL_NODE=true
INSTALL_PYTHON=true
INSTALL_DOCKER=false
INSTALL_EXTRAS=true

# Node.js version (lts, current, or specific version)
NODE_VERSION=lts

# Enable verbose logging
VERBOSE=true
```

See `config/default.conf` for all available options.

### Method 3: Command Line Flags

```bash
./setup.sh --no-docker --no-extras --verbose
```

## 🔧 Customization

### Using the Modular Libraries

The installation modules can be used independently:

```bash
# Source the common library
source lib/common.sh

# Initialize
init_common

# Use specific installation modules
source lib/install-docker.sh
install_docker
verify_docker
```

### Available Modules

- **lib/common.sh** - Logging, OS detection, package management
- **lib/install-zsh.sh** - Zsh and Oh My Zsh installation
- **lib/install-node.sh** - Node.js installation
- **lib/install-python.sh** - Python and uv installation
- **lib/install-docker.sh** - Docker and Docker Compose installation
- **lib/install-extras.sh** - Additional CLI utilities

### Creating Custom Scripts

```bash
#!/bin/bash
source "$(dirname "$0")/lib/common.sh"
source "$(dirname "$0")/lib/install-node.sh"

# Initialize
init_common

# Install only Node.js
install_node || exit 1
verify_node || exit 1

log_success "Custom installation complete!"
```

## 🧪 Testing

### Dry Run
```bash
./setup.sh --dry-run
```

### Verbose Output
```bash
./setup.sh --verbose
```

### Test in Docker
```bash
docker run -it --rm ubuntu:22.04 bash
# Inside container:
apt-get update && apt-get install -y curl
curl -fsSL https://example.com/setup.sh | bash
```

## 📊 What Gets Installed

### Full Setup (setup.sh)

**Core Development Tools:**
- Zsh 5.x with Oh My Zsh
- Node.js LTS (configurable)
- Python 3.x + pip + venv
- uv (fast Python package installer)
- Docker Engine + Docker Compose

**Oh My Zsh Plugins:**
- git, docker, docker-compose
- npm, node, python, pip
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- sudo, command-not-found

**Additional Utilities:**
- **Essential:** git, curl, wget, vim, htop, tmux
- **Development:** build-essential, jq, tree
- **Network:** net-tools, dnsutils, iputils-ping
- **Modern CLI:** fzf, bat, ripgrep, eza

### Minimal Setup (setup-minimal.sh)

- Zsh + Oh My Zsh (essential plugins only)
- Node.js LTS
- Python 3 + pip + uv
- Docker + Docker Compose
- Basic essentials (git, curl, wget, build-essential)

## 🐛 Troubleshooting

### Zsh not default shell?
```bash
chsh -s $(which zsh)
# Then log out and back in
```

### Docker permission denied?
```bash
# Log out and back in, or:
newgrp docker
```

### uv not in PATH?
```bash
source ~/.zshrc
# Or manually:
export PATH="$HOME/.cargo/bin:$PATH"
```

### Script fails midway?
```bash
# Check the log file if you used --log-file
cat /tmp/setup.log

# Run verification to see what's missing
./verify.sh

# Re-run with verbose mode
./setup.sh --verbose
```

### Want to see what would be installed?
```bash
./setup.sh --dry-run
```

## 📋 Requirements

- **OS:** Debian 10+ or Ubuntu 20.04+
- **Access:** sudo/root privileges
- **Network:** Internet connection
- **Disk:** ~2GB free space (full setup)

## 🔄 Version History

### v2.0.0 (Current)
- Modular architecture with reusable libraries
- Dry-run mode support
- Configuration file support
- Post-installation verification
- Comprehensive logging
- Component selection flags
- OS version detection and validation
- Improved error handling

### v1.0.0 (Legacy)
- Monolithic scripts
- Basic installation
- No verification
- Limited error handling

## 📚 Additional Resources

- [Legacy Documentation](../docs/) - Original VM setup guides
- [Configuration Reference](config/default.conf) - All configuration options
- [Main Repository README](../README.md) - Overall project documentation

## 🤝 Contributing

To improve these scripts:
1. Test on fresh Ubuntu/Debian installations
2. Update relevant module in `lib/`
3. Update configuration if needed
4. Test dry-run mode
5. Update this README

## 💡 Tips

1. **Always dry-run first** on production systems:
   ```bash
   ./setup.sh --dry-run | less
   ```

2. **Use configuration files** for consistent setups:
   ```bash
   cp config/default.conf ~/.setup-config
   nano ~/.setup-config
   ./setup.sh
   ```

3. **Log installations** for audit trails:
   ```bash
   ./setup.sh --log-file /var/log/setup-$(date +%Y%m%d).log
   ```

4. **Customize for your team** by modifying `config/default.conf`

5. **Chain installations** in automation:
   ```bash
   ./setup.sh --no-docker && ./custom-script.sh
   ```

---

**Version:** 2.0.0
**Last Updated:** 2024-11-22
**Maintained by:** Server Setup Scripts Project
