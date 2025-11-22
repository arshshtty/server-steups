#!/bin/bash
# Post-Installation Verification Script
# Run this after setup.sh to verify everything is installed correctly

echo "🔍 Verifying Installation..."
echo "=============================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1: $(command -v $1)"
        if [ ! -z "$2" ]; then
            echo "  Version: $($1 $2 2>&1 | head -n1)"
        fi
    else
        echo -e "${RED}✗${NC} $1: Not found"
    fi
}

echo "Core Tools:"
check_command zsh "--version"
check_command git "--version"
check_command curl "--version"
check_command wget "--version"

echo ""
echo "Node.js Ecosystem:"
check_command node "--version"
check_command npm "--version"
check_command npx "--version"

echo ""
echo "Python Ecosystem:"
check_command python3 "--version"
check_command pip3 "--version"
check_command uv "--version"
command -v uvx &> /dev/null && echo -e "${GREEN}✓${NC} uvx available" || echo -e "${RED}✗${NC} uvx not found"

echo ""
echo "Docker:"
check_command docker "--version"
check_command docker-compose "--version"

echo ""
echo "Oh My Zsh:"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}✓${NC} Oh My Zsh installed at $HOME/.oh-my-zsh"
else
    echo -e "${RED}✗${NC} Oh My Zsh not found"
fi

echo ""
echo "Zsh Plugins:"
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] && echo -e "${GREEN}✓${NC} zsh-autosuggestions" || echo -e "${RED}✗${NC} zsh-autosuggestions"
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] && echo -e "${GREEN}✓${NC} zsh-syntax-highlighting" || echo -e "${RED}✗${NC} zsh-syntax-highlighting"
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ] && echo -e "${GREEN}✓${NC} zsh-completions" || echo -e "${RED}✗${NC} zsh-completions"

echo ""
echo "Additional Tools:"
check_command vim "--version"
check_command htop "--version"
check_command tmux "-V"
check_command jq "--version"
check_command tree "--version"
check_command fzf "--version"
command -v bat &> /dev/null && check_command bat "--version" || command -v batcat &> /dev/null && check_command batcat "--version"
check_command rg "--version"

echo ""
echo "Shell Configuration:"
echo "Current shell: $SHELL"
echo "Default shell: $(getent passwd $USER | cut -d: -f7)"

echo ""
echo "Docker Group Membership:"
if groups | grep -q docker; then
    echo -e "${GREEN}✓${NC} User is in docker group"
else
    echo -e "${RED}✗${NC} User is NOT in docker group (may need to log out/in)"
fi

echo ""
echo "=============================="
echo "Verification Complete!"
echo ""
echo "Next steps:"
echo "1. If Zsh is not your current shell, run: zsh"
echo "2. If not in docker group, log out and back in"
echo "3. Run: source ~/.zshrc"
echo ""
