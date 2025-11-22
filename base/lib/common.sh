#!/bin/bash
# Common functions and utilities for setup scripts
# Source this file in your scripts: source "$(dirname "$0")/lib/common.sh"

# Script metadata
readonly SCRIPT_VERSION="${SCRIPT_VERSION:-1.0.0}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Default configuration
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
LOG_FILE="${LOG_FILE:-}"
SKIP_VERIFICATION="${SKIP_VERIFICATION:-false}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
    echo -e "${BLUE}${msg}${NC}"
    [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
    echo -e "${GREEN}${msg}${NC}"
    [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $1"
    echo -e "${YELLOW}${msg}${NC}"
    [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo -e "${RED}${msg}${NC}" >&2
    [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [DEBUG] $1"
        echo -e "${CYAN}${msg}${NC}"
        [ -n "$LOG_FILE" ] && echo "$msg" >> "$LOG_FILE"
    fi
}

log_step() {
    local msg="$1"
    echo ""
    echo -e "${BLUE}==>${NC} ${msg}"
    [ -n "$LOG_FILE" ] && echo "==> $msg" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        export IS_ROOT=true
        export SUDO=""
        log_debug "Running as root"
    else
        export IS_ROOT=false
        export SUDO="sudo"
        log_debug "Running as non-root user"
    fi
}

# Detect OS and version
detect_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS: /etc/os-release not found"
        return 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    export OS_NAME="$NAME"
    export OS_ID="$ID"
    export OS_VERSION="$VERSION_ID"
    export OS_CODENAME="${VERSION_CODENAME:-}"

    log_debug "Detected OS: $OS_NAME $OS_VERSION ($OS_CODENAME)"

    # Validate OS compatibility
    if [[ ! "$OS_ID" =~ ^(ubuntu|debian)$ ]]; then
        log_error "This script only supports Ubuntu and Debian"
        log_error "Detected: $OS_NAME"
        return 1
    fi

    # Check minimum version for Ubuntu
    if [ "$OS_ID" = "ubuntu" ]; then
        local min_version="20.04"
        if ! version_ge "$OS_VERSION" "$min_version"; then
            log_error "Ubuntu version $OS_VERSION is not supported"
            log_error "Minimum required version: $min_version"
            return 1
        fi
    fi

    # Check minimum version for Debian
    if [ "$OS_ID" = "debian" ]; then
        local min_version="10"
        if ! version_ge "$OS_VERSION" "$min_version"; then
            log_error "Debian version $OS_VERSION is not supported"
            log_error "Minimum required version: $min_version"
            return 1
        fi
    fi

    log_success "OS validation passed: $OS_NAME $OS_VERSION"
    return 0
}

# Compare versions (returns 0 if $1 >= $2)
version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed (apt)
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Execute command with dry-run support
execute() {
    local cmd="$*"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute: $cmd"
        return 0
    fi

    log_debug "Executing: $cmd"
    eval "$cmd"
}

# Safe package installation
install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would install: ${packages[*]}"
        return 0
    fi

    $SUDO apt-get install -y "${packages[@]}" || {
        log_error "Failed to install packages: ${packages[*]}"
        return 1
    }

    log_success "Packages installed successfully"
    return 0
}

# Update package lists
update_package_lists() {
    log_info "Updating package lists..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would update package lists"
        return 0
    fi

    $SUDO apt-get update || {
        log_error "Failed to update package lists"
        return 1
    }

    log_success "Package lists updated"
    return 0
}

# Upgrade system packages
upgrade_system() {
    log_info "Upgrading system packages..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would upgrade system packages"
        return 0
    fi

    $SUDO apt-get upgrade -y || {
        log_error "Failed to upgrade system packages"
        return 1
    }

    log_success "System packages upgraded"
    return 0
}

# Download file with retries
download_file() {
    local url="$1"
    local output="$2"
    local max_retries="${3:-3}"
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        log_debug "Downloading $url (attempt $((retry_count + 1))/$max_retries)"

        if curl -fsSL "$url" -o "$output"; then
            log_debug "Download successful"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            log_warning "Download failed, retrying in 2 seconds..."
            sleep 2
        fi
    done

    log_error "Failed to download $url after $max_retries attempts"
    return 1
}

# Verify installation of a command
verify_command() {
    local cmd="$1"
    local name="${2:-$cmd}"

    if command_exists "$cmd"; then
        local version
        version=$($cmd --version 2>&1 | head -n1 || echo "unknown")
        log_success "$name is installed: $version"
        return 0
    else
        log_error "$name is not installed or not in PATH"
        return 1
    fi
}

# Add line to file if not present
add_to_file_if_missing() {
    local line="$1"
    local file="$2"

    if [ ! -f "$file" ]; then
        log_warning "File does not exist: $file"
        execute "touch '$file'"
    fi

    if grep -qF "$line" "$file" 2>/dev/null; then
        log_debug "Line already present in $file"
        return 0
    fi

    log_debug "Adding line to $file: $line"
    execute "echo '$line' >> '$file'"
}

# Create backup of file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"

    if [ ! -f "$file" ]; then
        log_debug "No file to backup: $file"
        return 0
    fi

    log_info "Creating backup: $backup"
    execute "cp '$file' '$backup'"
}

# Show summary of installed tools
show_summary() {
    echo ""
    log_success "=================================================="
    log_success "Installation Summary"
    log_success "=================================================="
    echo ""
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script exited with error code: $exit_code"
    fi

    # Add any cleanup tasks here

    exit $exit_code
}

# Initialize common setup
init_common() {
    # Set up error handling
    set -e
    trap cleanup_on_exit EXIT

    # Check if we're root
    check_root

    # Create log file if specified
    if [ -n "$LOG_FILE" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        touch "$LOG_FILE"
        log_info "Logging to: $LOG_FILE"
    fi

    # Detect OS
    detect_os || exit 1
}

# Parse common command line arguments
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_warning "DRY RUN MODE - No changes will be made"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                log_debug "Verbose mode enabled"
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            --skip-verification)
                SKIP_VERIFICATION=true
                shift
                ;;
            --version)
                echo "Version: $SCRIPT_VERSION"
                exit 0
                ;;
            -h|--help)
                return 1  # Signal to show help
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    return 0
}
