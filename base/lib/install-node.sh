#!/bin/bash
# Node.js installation module

# Source common functions if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # shellcheck source=base/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
fi

install_node() {
    log_step "Installing Node.js and npm"

    # Check if already installed
    if command_exists node; then
        local current_version
        current_version=$(node --version 2>&1)
        log_warning "Node.js already installed: $current_version"

        if [ "${FORCE_NODE_INSTALL:-false}" = true ]; then
            log_info "FORCE_NODE_INSTALL=true, reinstalling..."
        else
            verify_npm || return 1
            return 0
        fi
    fi

    # Determine Node.js version to install
    local node_version="${NODE_VERSION:-lts}"
    log_info "Installing Node.js ($node_version)..."

    # Add NodeSource repository
    add_nodesource_repo "$node_version" || return 1

    # Install Node.js
    install_packages nodejs || return 1

    # Verify npm and npx
    verify_npm || return 1

    log_success "Node.js $(node --version) and npm $(npm --version) installed"
    return 0
}

add_nodesource_repo() {
    local version="$1"

    log_info "Adding NodeSource repository..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would add NodeSource repository for $version"
        return 0
    fi

    # Download and run NodeSource setup script
    local setup_script="/tmp/nodesource_setup.sh"

    # Determine the setup URL based on version
    local setup_url
    case "$version" in
        lts|LTS)
            setup_url="https://deb.nodesource.com/setup_lts.x"
            ;;
        current|latest)
            setup_url="https://deb.nodesource.com/setup_current.x"
            ;;
        [0-9]*)
            setup_url="https://deb.nodesource.com/setup_${version}.x"
            ;;
        *)
            log_error "Unknown Node.js version: $version"
            return 1
            ;;
    esac

    log_debug "Downloading NodeSource setup script from $setup_url"
    download_file "$setup_url" "$setup_script" || return 1

    # Run the setup script
    $SUDO bash "$setup_script" || {
        log_error "Failed to add NodeSource repository"
        rm -f "$setup_script"
        return 1
    }

    rm -f "$setup_script"
    log_success "NodeSource repository added"

    # Update package lists
    update_package_lists || return 1

    return 0
}

verify_npm() {
    log_info "Verifying npm and npx..."

    # Verify npm
    if ! command_exists npm; then
        log_error "npm is not installed"
        return 1
    fi

    local npm_version
    npm_version=$(npm --version 2>&1)
    log_success "npm is installed: $npm_version"

    # Verify npx (should come with npm 5.2+)
    if command_exists npx; then
        local npx_version
        npx_version=$(npx --version 2>&1)
        log_success "npx is installed: $npx_version"
    else
        log_warning "npx not found, installing..."

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would install npx globally"
            return 0
        fi

        $SUDO npm install -g npx || {
            log_error "Failed to install npx"
            return 1
        }

        log_success "npx installed"
    fi

    return 0
}

verify_node() {
    if [ "$SKIP_VERIFICATION" = true ]; then
        return 0
    fi

    log_info "Verifying Node.js installation..."

    local failures=0

    # Verify node command
    if ! verify_command node "Node.js"; then
        ((failures++))
    fi

    # Verify npm command
    if ! verify_command npm "npm"; then
        ((failures++))
    fi

    # Verify npx command
    if ! verify_command npx "npx"; then
        ((failures++))
    fi

    # Test node execution
    if [ "$DRY_RUN" = false ]; then
        if node -e "console.log('Node.js test OK')" >/dev/null 2>&1; then
            log_success "Node.js execution test passed"
        else
            log_error "Node.js execution test failed"
            ((failures++))
        fi
    fi

    if [ $failures -eq 0 ]; then
        log_success "Node.js verification passed"
        return 0
    else
        log_error "Node.js verification failed: $failures check(s) failed"
        return 1
    fi
}
