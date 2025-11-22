#!/bin/bash
# Debian/Ubuntu VM/Container Setup Script
# Full-featured setup with all development tools
# Version: 2.0.0

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library
# shellcheck source=base/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Source installation modules
# shellcheck source=base/lib/install-zsh.sh
source "$SCRIPT_DIR/lib/install-zsh.sh"
# shellcheck source=base/lib/install-node.sh
source "$SCRIPT_DIR/lib/install-node.sh"
# shellcheck source=base/lib/install-python.sh
source "$SCRIPT_DIR/lib/install-python.sh"
# shellcheck source=base/lib/install-docker.sh
source "$SCRIPT_DIR/lib/install-docker.sh"
# shellcheck source=base/lib/install-extras.sh
source "$SCRIPT_DIR/lib/install-extras.sh"

# ============================================================================
# Configuration
# ============================================================================

# Set defaults
INSTALL_ZSH="${INSTALL_ZSH:-true}"
INSTALL_NODE="${INSTALL_NODE:-true}"
INSTALL_PYTHON="${INSTALL_PYTHON:-true}"
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
INSTALL_EXTRAS="${INSTALL_EXTRAS:-true}"
UPDATE_PACKAGES="${UPDATE_PACKAGES:-true}"
UPGRADE_SYSTEM="${UPGRADE_SYSTEM:-true}"
RUN_VERIFICATION="${RUN_VERIFICATION:-true}"
SHOW_SUMMARY="${SHOW_SUMMARY:-true}"

# Load configuration from file if it exists
for config in "$SCRIPT_DIR/config/default.conf" /etc/setup-config "$HOME/.setup-config"; do
    if [ -f "$config" ]; then
        log_debug "Loading configuration from $config"
        # shellcheck source=/dev/null
        source "$config"
        break
    fi
done

# ============================================================================
# Help Function
# ============================================================================

show_help() {
    cat << EOF
Debian/Ubuntu VM/Container Setup Script v2.0.0

Usage: $0 [OPTIONS]

A comprehensive setup script for quickly configuring new Debian/Ubuntu
virtual machines and containers with essential development tools.

OPTIONS:
    --dry-run              Show what would be installed without making changes
    -v, --verbose          Enable verbose output
    --log-file FILE        Write log to specified file
    --skip-verification    Skip post-installation verification
    --version              Show version and exit
    -h, --help             Show this help message

COMPONENT SELECTION:
    --no-zsh               Skip Zsh and Oh My Zsh installation
    --no-node              Skip Node.js installation
    --no-python            Skip Python installation
    --no-docker            Skip Docker installation
    --no-extras            Skip additional utilities installation
    --no-updates           Skip system package updates

CONFIGURATION:
    Configuration can be customized by:
    1. Exporting environment variables
    2. Creating ~/.setup-config or /etc/setup-config
    3. Editing $SCRIPT_DIR/config/default.conf

    See config/default.conf for all available options.

WHAT GETS INSTALLED:
    Core Development Tools:
    - Zsh with Oh My Zsh and plugins
    - Node.js (LTS) + npm + npx
    - Python 3 + pip + venv + uv
    - Docker + Docker Compose

    Additional Utilities:
    - git, curl, wget, vim, htop, tmux
    - jq, tree, net-tools, dnsutils
    - fzf (fuzzy finder)
    - bat (better cat)
    - ripgrep (better grep)
    - eza (better ls, if available)

EXAMPLES:
    # Standard installation
    ./setup.sh

    # Dry run to see what would be installed
    ./setup.sh --dry-run

    # Install without Docker
    ./setup.sh --no-docker

    # Verbose mode with logging
    ./setup.sh --verbose --log-file /tmp/setup.log

    # Remote installation
    curl -fsSL https://example.com/setup.sh | bash

REQUIREMENTS:
    - Debian 10+ or Ubuntu 20.04+
    - Internet connection
    - sudo access (or run as root)

For more information, see the README.md file.
EOF
}

# ============================================================================
# Main Installation Function
# ============================================================================

main() {
    # Parse command line arguments
    if ! parse_common_args "$@"; then
        show_help
        exit 0
    fi

    # Handle component flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-zsh) INSTALL_ZSH=false; shift ;;
            --no-node) INSTALL_NODE=false; shift ;;
            --no-python) INSTALL_PYTHON=false; shift ;;
            --no-docker) INSTALL_DOCKER=false; shift ;;
            --no-extras) INSTALL_EXTRAS=false; shift ;;
            --no-updates) UPDATE_PACKAGES=false; UPGRADE_SYSTEM=false; shift ;;
            *) shift ;;
        esac
    done

    # Initialize
    init_common

    # Show banner
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "  Debian/Ubuntu VM/Container Setup Script v2.0.0"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Update system packages
    if [ "$UPDATE_PACKAGES" = true ]; then
        update_package_lists || exit 1
    fi

    if [ "$UPGRADE_SYSTEM" = true ]; then
        upgrade_system || exit 1
    fi

    # Install components
    local install_failures=0

    if [ "$INSTALL_EXTRAS" = true ]; then
        install_extras || ((install_failures++))
    fi

    if [ "$INSTALL_ZSH" = true ]; then
        install_zsh || ((install_failures++))
    fi

    if [ "$INSTALL_NODE" = true ]; then
        install_node || ((install_failures++))
    fi

    if [ "$INSTALL_PYTHON" = true ]; then
        install_python || ((install_failures++))
    fi

    if [ "$INSTALL_DOCKER" = true ]; then
        install_docker || ((install_failures++))
    fi

    # Cleanup
    log_step "Cleaning up"
    execute "$SUDO apt-get autoremove -y"
    execute "$SUDO apt-get clean"

    # Run verification
    if [ "$RUN_VERIFICATION" = true ] && [ "$install_failures" -eq 0 ]; then
        run_verification || log_warning "Some verifications failed"
    fi

    # Show summary
    if [ "$SHOW_SUMMARY" = true ]; then
        show_installation_summary
    fi

    # Final messages
    echo ""
    if [ $install_failures -eq 0 ]; then
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_success "  Setup Complete! 🎉"
        log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        show_post_install_instructions
        exit 0
    else
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "  Setup completed with $install_failures error(s)"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
}

# ============================================================================
# Verification
# ============================================================================

run_verification() {
    log_step "Running post-installation verification"

    local verification_failures=0

    [ "$INSTALL_EXTRAS" = true ] && { verify_extras || ((verification_failures++)); }
    [ "$INSTALL_ZSH" = true ] && { verify_zsh || ((verification_failures++)); }
    [ "$INSTALL_NODE" = true ] && { verify_node || ((verification_failures++)); }
    [ "$INSTALL_PYTHON" = true ] && { verify_python || ((verification_failures++)); }
    [ "$INSTALL_DOCKER" = true ] && { verify_docker || ((verification_failures++)); }

    if [ $verification_failures -eq 0 ]; then
        log_success "All verifications passed ✓"
        return 0
    else
        log_warning "$verification_failures verification(s) failed"
        return 1
    fi
}

# ============================================================================
# Summary
# ============================================================================

show_installation_summary() {
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "  Installation Summary"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show what was installed
    if [ "$INSTALL_ZSH" = true ] && command_exists zsh; then
        echo "  ✓ Zsh $(zsh --version 2>&1 | cut -d' ' -f2)"
        echo "  ✓ Oh My Zsh + plugins"
    fi

    if [ "$INSTALL_NODE" = true ] && command_exists node; then
        echo "  ✓ Node.js $(node --version 2>&1)"
        echo "  ✓ npm $(npm --version 2>&1)"
        echo "  ✓ npx $(npx --version 2>&1)"
    fi

    if [ "$INSTALL_PYTHON" = true ] && command_exists python3; then
        echo "  ✓ Python $(python3 --version 2>&1 | cut -d' ' -f2)"
        echo "  ✓ pip $(pip3 --version 2>&1 | cut -d' ' -f2)"
        if [ -x "$HOME/.cargo/bin/uv" ]; then
            echo "  ✓ uv $("$HOME/.cargo/bin/uv" --version 2>&1)"
        fi
    fi

    if [ "$INSTALL_DOCKER" = true ] && command_exists docker; then
        echo "  ✓ Docker $(docker --version 2>&1 | cut -d' ' -f3 | tr -d ',')"
        if command_exists docker-compose; then
            echo "  ✓ docker-compose $(docker-compose --version 2>&1 | grep -oP '[\d\.]+' | head -n1)"
        fi
    fi

    if [ "$INSTALL_EXTRAS" = true ]; then
        echo "  ✓ Additional tools: git, curl, wget, vim, htop, tmux, jq, tree"
        command_exists fzf && echo "  ✓ fzf (fuzzy finder)"
        (command_exists bat || command_exists batcat) && echo "  ✓ bat (better cat)"
        command_exists rg && echo "  ✓ ripgrep (better grep)"
        command_exists eza && echo "  ✓ eza (better ls)"
    fi

    echo ""
}

show_post_install_instructions() {
    log_warning "IMPORTANT: Post-Installation Steps"
    echo ""

    if [ "$INSTALL_ZSH" = true ]; then
        echo "  1. Reload your shell or log out/in to apply changes:"
        echo "     source ~/.zshrc"
        echo "     # or"
        echo "     zsh"
        echo ""
    fi

    if [ "$INSTALL_DOCKER" = true ] && [ "$IS_ROOT" = false ]; then
        echo "  2. Docker group permissions require a re-login to take effect:"
        echo "     # Log out and back in, or run:"
        echo "     newgrp docker"
        echo ""
    fi

    if [ "$INSTALL_PYTHON" = true ] && [ "${INSTALL_UV:-true}" = true ]; then
        echo "  3. uv is installed in ~/.cargo/bin"
        echo "     Restart your shell or run: source ~/.zshrc"
        echo ""
    fi

    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo "  📋 Full installation log: $LOG_FILE"
        echo ""
    fi
}

# ============================================================================
# Run Main Function
# ============================================================================

main "$@"
