#!/bin/bash
# Python installation module

# Source common functions if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # shellcheck source=base/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
fi

install_python() {
    log_step "Installing Python and related tools"

    # Install Python3 and pip
    install_python3 || return 1

    # Install uv (fast Python package installer)
    if [ "${INSTALL_UV:-true}" = true ]; then
        install_uv || return 1
    fi

    return 0
}

install_python3() {
    log_info "Installing Python3, pip, and venv..."

    # Check if already installed
    if command_exists python3; then
        local version
        version=$(python3 --version 2>&1)
        log_warning "Python3 already installed: $version"
    fi

    # Install Python packages
    install_packages python3 python3-pip python3-venv || return 1

    # Verify pip3
    if command_exists pip3; then
        local pip_version
        pip_version=$(pip3 --version 2>&1 | head -n1)
        log_success "pip3 installed: $pip_version"
    else
        log_error "pip3 not found after installation"
        return 1
    fi

    return 0
}

install_uv() {
    log_info "Installing uv (fast Python package installer)..."

    # Check if already installed
    if command_exists uv; then
        log_warning "uv already installed: $(uv --version 2>&1)"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install uv"
        return 0
    fi

    # Download and install uv
    local installer="/tmp/uv_installer.sh"
    download_file "https://astral.sh/uv/install.sh" "$installer" || return 1

    sh "$installer" || {
        log_error "Failed to install uv"
        rm -f "$installer"
        return 1
    }

    rm -f "$installer"

    # Add to PATH in shell configs
    local cargo_bin="$HOME/.cargo/bin"
    local path_line='export PATH="$HOME/.cargo/bin:$PATH"'

    # Add to .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        add_to_file_if_missing "$path_line" "$HOME/.zshrc"
    fi

    # Add to .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        add_to_file_if_missing "$path_line" "$HOME/.bashrc"
    fi

    # Add to current session
    export PATH="$cargo_bin:$PATH"

    # Verify installation
    if [ -x "$cargo_bin/uv" ]; then
        log_success "uv installed: $("$cargo_bin/uv" --version 2>&1)"
    else
        log_warning "uv installed but not yet in PATH. Restart shell or run: source ~/.zshrc"
    fi

    return 0
}

verify_python() {
    if [ "$SKIP_VERIFICATION" = true ]; then
        return 0
    fi

    log_info "Verifying Python installation..."

    local failures=0

    # Verify python3
    if ! verify_command python3 "Python3"; then
        ((failures++))
    fi

    # Verify pip3
    if ! verify_command pip3 "pip3"; then
        ((failures++))
    fi

    # Verify uv if it should be installed
    if [ "${INSTALL_UV:-true}" = true ]; then
        local cargo_bin="$HOME/.cargo/bin"
        if [ -x "$cargo_bin/uv" ]; then
            log_success "uv is installed: $("$cargo_bin/uv" --version 2>&1)"
        else
            log_error "uv is not installed"
            ((failures++))
        fi
    fi

    # Test Python execution
    if [ "$DRY_RUN" = false ]; then
        if python3 -c "print('Python test OK')" >/dev/null 2>&1; then
            log_success "Python execution test passed"
        else
            log_error "Python execution test failed"
            ((failures++))
        fi
    fi

    if [ $failures -eq 0 ]; then
        log_success "Python verification passed"
        return 0
    else
        log_error "Python verification failed: $failures check(s) failed"
        return 1
    fi
}
