#!/bin/bash
# Zsh and Oh My Zsh installation module

# Source common functions if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # shellcheck source=base/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
fi

install_zsh() {
    log_step "Installing Zsh and Oh My Zsh"

    # Install Zsh
    if command_exists zsh; then
        log_warning "Zsh already installed: $(zsh --version)"
    else
        log_info "Installing Zsh..."
        install_packages zsh || return 1
        log_success "Zsh installed"
    fi

    # Install Oh My Zsh
    install_oh_my_zsh || return 1

    # Install Zsh plugins
    install_zsh_plugins || return 1

    # Configure plugins
    configure_zsh_plugins || return 1

    # Set as default shell (optional)
    if [ "${SET_ZSH_DEFAULT:-true}" = true ]; then
        set_zsh_default_shell || return 1
    fi

    return 0
}

install_oh_my_zsh() {
    local omz_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh}"

    if [ -d "$omz_dir" ]; then
        log_warning "Oh My Zsh already installed"
        return 0
    fi

    log_info "Installing Oh My Zsh..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install Oh My Zsh"
        return 0
    fi

    # Download installer
    local installer="/tmp/oh-my-zsh-installer.sh"
    download_file "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$installer" || return 1

    # Run installer in unattended mode
    sh "$installer" --unattended || {
        log_error "Failed to install Oh My Zsh"
        rm -f "$installer"
        return 1
    }

    rm -f "$installer"
    log_success "Oh My Zsh installed"
    return 0
}

install_zsh_plugins() {
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    log_info "Installing Zsh plugins..."

    # zsh-autosuggestions
    install_zsh_plugin \
        "zsh-autosuggestions" \
        "https://github.com/zsh-users/zsh-autosuggestions" \
        "$custom_dir/plugins/zsh-autosuggestions" || return 1

    # zsh-syntax-highlighting
    install_zsh_plugin \
        "zsh-syntax-highlighting" \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "$custom_dir/plugins/zsh-syntax-highlighting" || return 1

    # zsh-completions
    install_zsh_plugin \
        "zsh-completions" \
        "https://github.com/zsh-users/zsh-completions" \
        "$custom_dir/plugins/zsh-completions" || return 1

    log_success "Zsh plugins installed"
    return 0
}

install_zsh_plugin() {
    local name="$1"
    local repo="$2"
    local target="$3"

    if [ -d "$target" ]; then
        log_debug "$name already installed"
        return 0
    fi

    log_info "Installing $name..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would clone $repo to $target"
        return 0
    fi

    git clone --depth 1 "$repo" "$target" || {
        log_error "Failed to install $name"
        return 1
    }

    log_success "$name installed"
    return 0
}

configure_zsh_plugins() {
    local zshrc="$HOME/.zshrc"

    if [ ! -f "$zshrc" ]; then
        log_warning ".zshrc not found, skipping plugin configuration"
        return 0
    fi

    local desired_plugins="${ZSH_PLUGINS:-git docker docker-compose npm node python pip zsh-autosuggestions zsh-syntax-highlighting zsh-completions sudo command-not-found}"

    log_info "Configuring Zsh plugins..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would configure plugins: $desired_plugins"
        return 0
    fi

    # Create backup
    backup_file "$zshrc"

    # Check if plugins are already configured
    if grep -q "zsh-autosuggestions" "$zshrc" 2>/dev/null; then
        log_warning "Zsh plugins already configured"
        return 0
    fi

    # Update plugins line
    if grep -q "^plugins=(" "$zshrc"; then
        sed -i "s/^plugins=(.*/plugins=($desired_plugins)/" "$zshrc"
    else
        # Add plugins line if it doesn't exist
        echo "plugins=($desired_plugins)" >> "$zshrc"
    fi

    log_success "Zsh plugins configured"
    return 0
}

set_zsh_default_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        log_success "Zsh is already the default shell"
        return 0
    fi

    log_info "Setting Zsh as default shell..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would set Zsh as default shell"
        return 0
    fi

    # Check if zsh is in /etc/shells
    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        log_warning "Adding Zsh to /etc/shells"
        echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
    fi

    # Change shell
    if chsh -s "$zsh_path"; then
        log_success "Zsh set as default shell (will take effect on next login)"
    else
        log_warning "Failed to set Zsh as default shell automatically"
        log_info "You can set it manually with: chsh -s $zsh_path"
    fi

    return 0
}

verify_zsh() {
    if [ "$SKIP_VERIFICATION" = true ]; then
        return 0
    fi

    log_info "Verifying Zsh installation..."

    local failures=0

    # Verify zsh command
    if ! verify_command zsh "Zsh"; then
        ((failures++))
    fi

    # Verify Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh is installed"
    else
        log_error "Oh My Zsh is not installed"
        ((failures++))
    fi

    # Verify plugins
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
        if [ -d "$custom_dir/plugins/$plugin" ]; then
            log_success "Plugin $plugin is installed"
        else
            log_error "Plugin $plugin is not installed"
            ((failures++))
        fi
    done

    if [ $failures -eq 0 ]; then
        log_success "Zsh verification passed"
        return 0
    else
        log_error "Zsh verification failed: $failures check(s) failed"
        return 1
    fi
}
