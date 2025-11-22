#!/bin/bash
set -e

# Minimal setup script - just the essentials
echo "🚀 Starting minimal setup..."

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Essential packages
sudo apt-get install -y curl wget git build-essential zsh

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure plugins
sed -i 's/plugins=(git)/plugins=(git docker npm node python zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Python
sudo apt-get install -y python3 python3-pip python3-venv

# uv
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc

# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set Zsh as default
chsh -s $(which zsh)

# Cleanup
sudo apt-get autoremove -y && sudo apt-get clean

echo "✅ Setup complete! Run 'zsh' or log out/in to start using your new environment."
