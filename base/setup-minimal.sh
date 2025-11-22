#!/bin/bash
# Minimal setup script - just the essentials
# Version: 2.0.0
# Optimized for CI/CD and Docker containers

# Error handling
set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] !${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect sudo requirement
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Configuration from environment
DRY_RUN="${DRY_RUN:-false}"
SKIP_VERIFICATION="${SKIP_VERIFICATION:-false}"

# Start
log "Starting minimal setup..."
log "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
echo ""

# Update system
log "Updating package lists..."
if [ "$DRY_RUN" = false ]; then
    $SUDO apt-get update || { log_error "Failed to update package lists"; exit 1; }
    $SUDO apt-get upgrade -y || { log_error "Failed to upgrade packages"; exit 1; }
fi
log_success "System updated"

# Install essential packages
log "Installing essential packages..."
if [ "$DRY_RUN" = false ]; then
    $SUDO apt-get install -y curl wget git build-essential zsh || {
        log_error "Failed to install essential packages"
        exit 1
    }
fi
log_success "Essential packages installed"

# Install Oh My Zsh
log "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if [ "$DRY_RUN" = false ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
            log_error "Failed to install Oh My Zsh"
            exit 1
        }
    fi
    log_success "Oh My Zsh installed"
else
    log_warning "Oh My Zsh already installed"
fi

# Install Zsh plugins
log "Installing Zsh plugins..."
if [ "$DRY_RUN" = false ]; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
    fi
fi
log_success "Zsh plugins installed"

# Configure plugins
if [ -f "$HOME/.zshrc" ] && [ "$DRY_RUN" = false ]; then
    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
        sed -i 's/plugins=(git)/plugins=(git docker npm node python zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        log_success "Zsh plugins configured"
    fi
fi

# Install Node.js
log "Installing Node.js..."
if ! command_exists node; then
    if [ "$DRY_RUN" = false ]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash - || {
            log_error "Failed to add NodeSource repository"
            exit 1
        }
        $SUDO apt-get install -y nodejs || {
            log_error "Failed to install Node.js"
            exit 1
        }
    fi
    log_success "Node.js installed"
else
    log_warning "Node.js already installed"
fi

# Install Python
log "Installing Python..."
if [ "$DRY_RUN" = false ]; then
    $SUDO apt-get install -y python3 python3-pip python3-venv || {
        log_error "Failed to install Python"
        exit 1
    }
fi
log_success "Python installed"

# Install uv
log "Installing uv..."
if ! command_exists uv && [ ! -f "$HOME/.cargo/bin/uv" ]; then
    if [ "$DRY_RUN" = false ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh || {
            log_warning "Failed to install uv (non-fatal)"
        }

        # Add to PATH
        if [ -f "$HOME/.zshrc" ]; then
            grep -q '.cargo/bin' "$HOME/.zshrc" || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
        fi
    fi
    log_success "uv installed"
else
    log_warning "uv already installed"
fi

# Install Docker
log "Installing Docker..."
if ! command_exists docker; then
    if [ "$DRY_RUN" = false ]; then
        curl -fsSL https://get.docker.com | sh || {
            log_error "Failed to install Docker"
            exit 1
        }

        # Add user to docker group
        if [[ $EUID -ne 0 ]]; then
            $SUDO usermod -aG docker "$USER"
            log_warning "Added $USER to docker group (requires re-login)"
        fi
    fi
    log_success "Docker installed"
else
    log_warning "Docker already installed"
fi

# Install Docker Compose
log "Installing docker-compose..."
if ! command_exists docker-compose; then
    if [ "$DRY_RUN" = false ]; then
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        $SUDO curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || {
            log_error "Failed to install docker-compose"
            exit 1
        }
        $SUDO chmod +x /usr/local/bin/docker-compose
    fi
    log_success "docker-compose installed"
else
    log_warning "docker-compose already installed"
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ] && [ "$DRY_RUN" = false ]; then
    log "Setting Zsh as default shell..."
    chsh -s "$(which zsh)" || log_warning "Failed to set Zsh as default shell"
fi

# Cleanup
log "Cleaning up..."
if [ "$DRY_RUN" = false ]; then
    $SUDO apt-get autoremove -y >/dev/null 2>&1
    $SUDO apt-get clean >/dev/null 2>&1
fi
log_success "Cleanup complete"

# Verification
if [ "$SKIP_VERIFICATION" = false ] && [ "$DRY_RUN" = false ]; then
    echo ""
    log "Verifying installations..."

    failures=0

    # Verify critical installations
    for cmd in zsh node python3 docker docker-compose; do
        if command_exists "$cmd"; then
            version=$($cmd --version 2>&1 | head -n1 || echo "unknown")
            log_success "$cmd: $version"
        else
            log_error "$cmd not found"
            ((failures++))
        fi
    done

    # Verify npm separately
    if command_exists npm; then
        log_success "npm: $(npm --version 2>&1)"
    else
        log_error "npm not found"
        ((failures++))
    fi

    # Verify pip3
    if command_exists pip3; then
        log_success "pip3: $(pip3 --version 2>&1 | cut -d' ' -f2)"
    else
        log_error "pip3 not found"
        ((failures++))
    fi

    # Verify uv (non-critical)
    if command_exists uv || [ -x "$HOME/.cargo/bin/uv" ]; then
        uv_cmd="${HOME}/.cargo/bin/uv"
        [ -x "$uv_cmd" ] && log_success "uv: $($uv_cmd --version 2>&1)"
    else
        log_warning "uv not found (optional)"
    fi

    echo ""
    if [ $failures -eq 0 ]; then
        log_success "All verifications passed ✓"
    else
        log_error "Verification failed: $failures check(s) failed"
        exit 1
    fi
fi

# Final message
echo ""
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "  Setup complete! 🎉"
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  1. Run 'zsh' or log out/in to start using Zsh"
if [[ $EUID -ne 0 ]]; then
    echo "  2. Log out/in for Docker group permissions"
fi
echo "  3. Run 'source ~/.zshrc' to apply shell changes"
echo ""
