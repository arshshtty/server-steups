#!/bin/bash
# Docker installation module

# Source common functions if not already sourced
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    # shellcheck source=base/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
fi

install_docker() {
    log_step "Installing Docker and Docker Compose"

    # Check if already installed
    if command_exists docker; then
        log_warning "Docker already installed: $(docker --version 2>&1)"

        if [ "${FORCE_DOCKER_INSTALL:-false}" = true ]; then
            log_info "FORCE_DOCKER_INSTALL=true, reinstalling..."
        else
            # Still need to check user groups and docker-compose
            add_user_to_docker_group || return 1
            install_docker_compose || return 1
            return 0
        fi
    fi

    # Add Docker repository
    add_docker_repo || return 1

    # Install Docker packages
    log_info "Installing Docker Engine..."
    install_packages \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin || return 1

    log_success "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') installed"

    # Add current user to docker group
    add_user_to_docker_group || return 1

    # Install standalone docker-compose
    install_docker_compose || return 1

    return 0
}

add_docker_repo() {
    log_info "Adding Docker repository..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would add Docker repository"
        return 0
    fi

    # Install prerequisites
    install_packages \
        ca-certificates \
        curl \
        gnupg \
        lsb-release || return 1

    # Create keyrings directory
    $SUDO install -m 0755 -d /etc/apt/keyrings

    # Add Docker's official GPG key
    local gpg_key="/etc/apt/keyrings/docker.gpg"
    local gpg_url

    # Determine URL based on OS
    case "$OS_ID" in
        ubuntu)
            gpg_url="https://download.docker.com/linux/ubuntu/gpg"
            ;;
        debian)
            gpg_url="https://download.docker.com/linux/debian/gpg"
            ;;
        *)
            log_error "Unsupported OS for Docker installation: $OS_ID"
            return 1
            ;;
    esac

    log_debug "Downloading Docker GPG key from $gpg_url"
    curl -fsSL "$gpg_url" | $SUDO gpg --dearmor -o "$gpg_key" || {
        log_error "Failed to add Docker GPG key"
        return 1
    }

    $SUDO chmod a+r "$gpg_key"

    # Set up the repository
    local arch
    arch=$(dpkg --print-architecture)

    local repo_url
    case "$OS_ID" in
        ubuntu)
            repo_url="https://download.docker.com/linux/ubuntu"
            ;;
        debian)
            repo_url="https://download.docker.com/linux/debian"
            ;;
    esac

    echo \
        "deb [arch=$arch signed-by=$gpg_key] $repo_url \
        $OS_CODENAME stable" | \
        $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

    log_success "Docker repository added"

    # Update package lists
    update_package_lists || return 1

    return 0
}

add_user_to_docker_group() {
    # Skip if running as root
    if [ "$IS_ROOT" = true ]; then
        log_debug "Running as root, skipping docker group addition"
        return 0
    fi

    local current_user
    current_user=$(whoami)

    # Check if user is already in docker group
    if groups "$current_user" | grep -q '\bdocker\b'; then
        log_success "User $current_user is already in docker group"
        return 0
    fi

    log_info "Adding $current_user to docker group..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would add $current_user to docker group"
        return 0
    fi

    $SUDO usermod -aG docker "$current_user" || {
        log_error "Failed to add $current_user to docker group"
        return 1
    }

    log_success "User $current_user added to docker group"
    log_warning "You may need to log out and back in for docker group permissions to take effect"
    log_info "Or run: newgrp docker"

    return 0
}

install_docker_compose() {
    # Check if docker-compose (standalone) is already installed
    if command_exists docker-compose; then
        log_warning "docker-compose already installed: $(docker-compose --version 2>&1)"
        return 0
    fi

    log_info "Installing docker-compose (standalone)..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install docker-compose"
        return 0
    fi

    # Get latest version from GitHub API
    local version
    version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

    if [ -z "$version" ]; then
        log_error "Failed to get docker-compose version from GitHub API"
        return 1
    fi

    log_debug "Installing docker-compose $version"

    # Determine architecture
    local arch
    arch=$(uname -m)

    local compose_url="https://github.com/docker/compose/releases/download/${version}/docker-compose-$(uname -s)-${arch}"
    local compose_path="/usr/local/bin/docker-compose"

    # Download docker-compose
    $SUDO curl -L "$compose_url" -o "$compose_path" || {
        log_error "Failed to download docker-compose"
        return 1
    }

    # Make it executable
    $SUDO chmod +x "$compose_path" || {
        log_error "Failed to make docker-compose executable"
        return 1
    }

    local installed_version
    installed_version=$(docker-compose --version 2>&1)
    log_success "docker-compose installed: $installed_version"

    return 0
}

verify_docker() {
    if [ "$SKIP_VERIFICATION" = true ]; then
        return 0
    fi

    log_info "Verifying Docker installation..."

    local failures=0

    # Verify docker command
    if ! verify_command docker "Docker"; then
        ((failures++))
    fi

    # Verify docker-compose plugin
    if docker compose version >/dev/null 2>&1; then
        log_success "docker compose plugin is available: $(docker compose version 2>&1)"
    else
        log_warning "docker compose plugin is not available"
    fi

    # Verify standalone docker-compose
    if ! verify_command docker-compose "docker-compose"; then
        ((failures++))
    fi

    # Test docker execution (skip if running as non-root and not in docker group yet)
    if [ "$DRY_RUN" = false ]; then
        if [ "$IS_ROOT" = true ] || groups | grep -q '\bdocker\b'; then
            if docker run --rm hello-world >/dev/null 2>&1; then
                log_success "Docker execution test passed"
            else
                log_warning "Docker execution test failed (may need to log out/in for group permissions)"
            fi
        else
            log_info "Skipping Docker execution test (need to log out/in for group permissions)"
        fi
    fi

    if [ $failures -eq 0 ]; then
        log_success "Docker verification passed"
        return 0
    else
        log_error "Docker verification failed: $failures check(s) failed"
        return 1
    fi
}
