# Base System Setup Scripts

This directory contains base system setup scripts for Debian/Ubuntu servers and VMs.

## Scripts

### setup.sh
Full-featured setup script that installs a complete development environment:
- Zsh with Oh My Zsh and plugins
- Node.js (LTS) + npm
- Python 3 + pip + uv
- Docker + Docker Compose
- CLI utilities (fzf, bat, ripgrep, htop, tmux, etc.)

**Usage:**
```bash
chmod +x setup.sh
./setup.sh
```

**Or remote installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/USER/server-steups/main/base/setup.sh | bash
```

### setup-minimal.sh
Lightweight version for CI/CD and containers:
- Essential packages only
- Faster execution
- Minimal footprint

**Usage:**
```bash
chmod +x setup-minimal.sh
./setup-minimal.sh
```

### verify.sh
Post-installation verification script that checks all installations.

**Usage:**
```bash
chmod +x verify.sh
./verify.sh
```

## When to Use

- **setup.sh**: Development machines, personal VMs, workstations
- **setup-minimal.sh**: Production servers, CI/CD, Docker base images
- **verify.sh**: After running either setup script

## Requirements

- Debian 10+ or Ubuntu 20.04+
- Internet connection
- sudo access (or run as root)

## Customization

Edit the scripts to:
- Add/remove packages
- Change Node.js or Python versions
- Modify Zsh plugins
- Add your dotfiles

See the [legacy documentation](../docs/) for detailed guides.
