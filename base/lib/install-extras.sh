#!/bin/bash
# Additional utilities installation module

# Source common functions if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # shellcheck source=base/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
fi

install_extras() {
    log_step "Installing additional utilities"

    # Install basic utilities
    install_basic_utilities || return 1

    # Install modern CLI tools
    if [ "${INSTALL_MODERN_TOOLS:-true}" = true ]; then
        install_fzf || return 1
        install_bat || return 1
        install_ripgrep || return 1
        install_eza || return 1
    fi

    return 0
}

install_basic_utilities() {
    log_info "Installing basic utilities..."

    local packages=(
        curl
        wget
        git
        build-essential
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        unzip
        zip
        vim
        htop
        tmux
        jq
        tree
        net-tools
        iputils-ping
        dnsutils
    )

    install_packages "${packages[@]}" || return 1

    log_success "Basic utilities installed"
    return 0
}

install_fzf() {
    if command_exists fzf; then
        log_warning "fzf already installed: $(fzf --version 2>&1)"
        return 0
    fi

    log_info "Installing fzf (fuzzy finder)..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install fzf"
        return 0
    fi

    # Clone fzf repository
    local fzf_dir="$HOME/.fzf"
    if [ ! -d "$fzf_dir" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir" || {
            log_error "Failed to clone fzf repository"
            return 1
        }
    fi

    # Install fzf
    "$fzf_dir/install" --all --no-bash --no-fish || {
        log_error "Failed to install fzf"
        return 1
    }

    log_success "fzf installed"
    return 0
}

install_bat() {
    # Check if bat or batcat exists
    if command_exists bat || command_exists batcat; then
        log_warning "bat already installed"
        return 0
    fi

    log_info "Installing bat (better cat)..."

    install_packages bat || return 1

    # On Ubuntu/Debian, bat is installed as batcat
    if command_exists batcat && ! command_exists bat; then
        log_info "Creating bat symlink..."

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would create bat symlink"
            return 0
        fi

        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

        # Add to PATH if not already there
        add_to_file_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"

        log_success "bat symlink created"
    fi

    log_success "bat installed"
    return 0
}

install_ripgrep() {
    if command_exists rg; then
        log_warning "ripgrep already installed: $(rg --version 2>&1 | head -n1)"
        return 0
    fi

    log_info "Installing ripgrep (better grep)..."

    install_packages ripgrep || return 1

    log_success "ripgrep installed"
    return 0
}

install_eza() {
    if command_exists eza; then
        log_warning "eza already installed: $(eza --version 2>&1 | head -n1)"
        return 0
    fi

    log_info "Installing eza (better ls)..."

    # eza might not be available in all repositories
    if install_packages eza 2>/dev/null; then
        log_success "eza installed"
        return 0
    else
        log_warning "eza not available in repositories, skipping"
        return 0
    fi
}

verify_extras() {
    if [ "$SKIP_VERIFICATION" = true ]; then
        return 0
    fi

    log_info "Verifying additional utilities..."

    local failures=0

    # Verify basic utilities
    for cmd in git curl wget vim htop tmux jq tree; do
        if ! command_exists "$cmd"; then
            log_error "$cmd is not installed"
            ((failures++))
        fi
    done

    # Verify modern tools if they should be installed
    if [ "${INSTALL_MODERN_TOOLS:-true}" = true ]; then
        for cmd in fzf rg; do
            if ! command_exists "$cmd"; then
                log_warning "$cmd is not installed"
            fi
        done

        # Check for bat or batcat
        if ! command_exists bat && ! command_exists batcat; then
            log_warning "bat is not installed"
        fi
    fi

    if [ $failures -eq 0 ]; then
        log_success "Additional utilities verification passed"
        return 0
    else
        log_error "Additional utilities verification failed: $failures check(s) failed"
        return 1
    fi
}
