#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_warning "This script is running as root. Some operations will be performed system-wide."
   SUDO=""
else
   SUDO="sudo"
fi

log_info "Starting Debian/Ubuntu VM/Container Setup Script"
log_info "=================================================="

# Update system
log_info "Updating system packages..."
$SUDO apt-get update
$SUDO apt-get upgrade -y

# Install essential packages
log_info "Installing essential packages..."
$SUDO apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    vim \
    htop \
    tmux \
    jq \
    tree \
    net-tools \
    iputils-ping \
    dnsutils \
    zip

log_success "Essential packages installed"

# Install Zsh
log_info "Installing Zsh..."
$SUDO apt-get install -y zsh
log_success "Zsh installed"

# Install Oh My Zsh
log_info "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_warning "Oh My Zsh already installed"
fi

# Install Zsh plugins
log_info "Installing Zsh plugins..."

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# zsh-completions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions
fi

# Update .zshrc with plugins
if [ -f "$HOME/.zshrc" ]; then
    sed -i 's/plugins=(git)/plugins=(git docker docker-compose npm node python pip zsh-autosuggestions zsh-syntax-highlighting zsh-completions sudo command-not-found)/' "$HOME/.zshrc"
    log_success "Zsh plugins configured"
fi

# Install Node.js and npm using NodeSource
log_info "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash -
$SUDO apt-get install -y nodejs
log_success "Node.js $(node --version) and npm $(npm --version) installed"

# npx comes with npm 5.2+, verify it's available
if command -v npx &> /dev/null; then
    log_success "npx $(npx --version) is available"
else
    log_warning "npx not found, installing..."
    $SUDO npm install -g npx
fi

# Install Python3 and pip3
log_info "Installing Python3 and pip3..."
$SUDO apt-get install -y python3 python3-pip python3-venv
log_success "Python $(python3 --version) and pip installed"

# Install uv (Python package installer)
log_info "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
log_success "uv installed"

# Add uv to PATH in shell configs
if ! grep -q '.cargo/bin' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
fi
if ! grep -q '.cargo/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Install Docker
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    $SUDO apt-get update
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (if not root)
    if [[ $EUID -ne 0 ]]; then
        $SUDO usermod -aG docker $USER
        log_warning "Added $USER to docker group. You may need to log out and back in for this to take effect."
    fi

    log_success "Docker $(docker --version) installed"
else
    log_warning "Docker already installed: $(docker --version)"
fi

# Install docker-compose (standalone)
log_info "Installing docker-compose standalone..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    $SUDO curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO chmod +x /usr/local/bin/docker-compose
    log_success "docker-compose $(docker-compose --version) installed"
else
    log_warning "docker-compose already installed: $(docker-compose --version)"
fi

# Install additional useful tools
log_info "Installing additional useful tools..."

# fzf (fuzzy finder)
if ! command -v fzf &> /dev/null; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish
    log_success "fzf installed"
fi

# bat (better cat)
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    $SUDO apt-get install -y bat
    # On Ubuntu/Debian, bat is installed as batcat
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p ~/.local/bin
        ln -s /usr/bin/batcat ~/.local/bin/bat
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    log_success "bat installed"
fi

# exa (better ls) or eza (modern replacement)
if ! command -v eza &> /dev/null; then
    $SUDO apt-get install -y eza 2>/dev/null || log_warning "eza not available in repos, skipping"
fi

# ripgrep (better grep)
if ! command -v rg &> /dev/null; then
    $SUDO apt-get install -y ripgrep
    log_success "ripgrep installed"
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting Zsh as default shell..."
    chsh -s $(which zsh)
    log_success "Zsh set as default shell (will take effect on next login)"
else
    log_success "Zsh is already the default shell"
fi

# Clean up
log_info "Cleaning up..."
$SUDO apt-get autoremove -y
$SUDO apt-get clean

# Summary
echo ""
log_success "=================================================="
log_success "Setup Complete! 🎉"
log_success "=================================================="
echo ""
log_info "Installed tools:"
echo "  ✓ Zsh with Oh My Zsh + plugins"
echo "  ✓ Node.js $(node --version)"
echo "  ✓ npm $(npm --version)"
echo "  ✓ npx $(npx --version)"
echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
echo "  ✓ pip $(pip3 --version | cut -d' ' -f2)"
echo "  ✓ uv ($(uv --version 2>/dev/null || echo 'installed'))"
echo "  ✓ Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "  ✓ docker-compose $(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
echo "  ✓ Additional tools: git, curl, wget, vim, htop, tmux, jq, tree, fzf, bat, ripgrep"
echo ""
log_warning "IMPORTANT: Please run 'source ~/.zshrc' or log out and back in to apply all changes."
if [[ $EUID -ne 0 ]]; then
    log_warning "You may need to log out and back in for Docker group permissions to take effect."
fi
echo ""
log_info "To start using Zsh now, run: zsh"
echo ""
