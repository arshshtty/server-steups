#!/bin/bash
# Prometheus + Grafana Monitoring Stack Setup
# Version: 1.0.0

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_DIR="$REPO_ROOT/docker-compose/prometheus-grafana"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
DRY_RUN="${DRY_RUN:-false}"
SKIP_DOCKER_CHECK="${SKIP_DOCKER_CHECK:-false}"
AUTO_START="${AUTO_START:-true}"

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
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Execute command with dry-run support
execute() {
    local cmd="$*"
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would execute: $cmd"
        return 0
    fi
    eval "$cmd"
}

# Check if Docker is installed
check_docker() {
    if [ "$SKIP_DOCKER_CHECK" = true ]; then
        log_info "Skipping Docker check"
        return 0
    fi

    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed"
        log_info "Install Docker first: cd $REPO_ROOT/base && ./setup.sh"
        return 1
    fi

    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not installed"
        log_info "Install Docker Compose first: cd $REPO_ROOT/base && ./setup.sh"
        return 1
    fi

    log_success "Docker and Docker Compose are installed"
}

# Check if Docker daemon is running
check_docker_running() {
    if [ "$SKIP_DOCKER_CHECK" = true ]; then
        return 0
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        log_info "Start Docker: sudo systemctl start docker"
        return 1
    fi

    log_success "Docker daemon is running"
}

# Create .env file if it doesn't exist
setup_env_file() {
    if [ ! -f "$COMPOSE_DIR/.env" ]; then
        log_info "Creating .env file from template"
        execute "cp '$COMPOSE_DIR/.env.example' '$COMPOSE_DIR/.env'"
        log_warning "Default .env file created. Please update GRAFANA_ADMIN_PASSWORD!"
        log_info "Edit: nano $COMPOSE_DIR/.env"
        return 1
    else
        log_success ".env file exists"
        return 0
    fi
}

# Validate .env file
validate_env_file() {
    if ! grep -q "GRAFANA_ADMIN_PASSWORD=changeme_secure_password" "$COMPOSE_DIR/.env" 2>/dev/null; then
        log_success "Grafana password has been changed from default"
        return 0
    else
        log_warning "Grafana is using default password!"
        log_warning "Change GRAFANA_ADMIN_PASSWORD in $COMPOSE_DIR/.env"
        return 1
    fi
}

# Check required files exist
check_required_files() {
    local missing_files=()

    local required_files=(
        "$COMPOSE_DIR/docker-compose.yml"
        "$COMPOSE_DIR/prometheus/prometheus.yml"
        "$COMPOSE_DIR/prometheus/alerts.yml"
        "$COMPOSE_DIR/grafana/provisioning/datasources/prometheus.yml"
        "$COMPOSE_DIR/grafana/provisioning/dashboards/default.yml"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    log_success "All required files present"
}

# Pull Docker images
pull_images() {
    log_info "Pulling Docker images..."
    execute "cd '$COMPOSE_DIR' && docker-compose pull"
    log_success "Docker images pulled"
}

# Start the monitoring stack
start_stack() {
    if [ "$AUTO_START" != true ]; then
        log_info "Skipping auto-start (AUTO_START=false)"
        return 0
    fi

    log_info "Starting monitoring stack..."
    execute "cd '$COMPOSE_DIR' && docker-compose up -d"
    log_success "Monitoring stack started"
}

# Verify services are running
verify_services() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would verify services"
        return 0
    fi

    log_info "Waiting for services to start..."
    sleep 5

    local services=("prometheus" "grafana" "node-exporter" "cadvisor")
    local failed_services=()

    for service in "${services[@]}"; do
        if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
            log_success "$service is running"
        else
            log_error "$service is not running"
            failed_services+=("$service")
        fi
    done

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Some services failed to start"
        log_info "Check logs: cd $COMPOSE_DIR && docker-compose logs"
        return 1
    fi

    log_success "All services are running"
}

# Display access information
show_access_info() {
    echo ""
    log_success "Monitoring stack is ready!"
    echo ""
    echo "Access the services:"
    echo "  Grafana:       http://localhost:3000"
    echo "  Prometheus:    http://localhost:9090"
    echo "  Node Exporter: http://localhost:9100/metrics"
    echo "  cAdvisor:      http://localhost:8080"
    echo ""
    echo "Default Grafana credentials:"
    echo "  Username: admin"
    echo "  Password: (check .env file)"
    echo ""
    echo "Next steps:"
    echo "  1. Change Grafana admin password"
    echo "  2. Import dashboards (see README.md for recommendations)"
    echo "  3. Configure alerting if needed"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    cd $COMPOSE_DIR && docker-compose logs -f"
    echo "  Stop stack:   cd $COMPOSE_DIR && docker-compose down"
    echo "  Restart:      cd $COMPOSE_DIR && docker-compose restart"
    echo ""
}

# Main function
main() {
    echo "========================================="
    echo "  Prometheus + Grafana Setup"
    echo "========================================="
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warning "Running in DRY-RUN mode (no changes will be made)"
        echo ""
    fi

    # Pre-flight checks
    log_info "Running pre-flight checks..."
    check_docker || exit 1
    check_docker_running || exit 1
    check_required_files || exit 1

    # Setup
    log_info "Setting up monitoring stack..."
    local need_env_edit=false
    if ! setup_env_file; then
        need_env_edit=true
    fi

    validate_env_file || log_warning "Using default password (not recommended for production)"

    # Deploy
    pull_images || log_warning "Failed to pull some images"
    start_stack

    # Verify
    if [ "$AUTO_START" = true ]; then
        verify_services || log_warning "Some services may not be running correctly"
        show_access_info
    fi

    # Final reminders
    if [ "$need_env_edit" = true ]; then
        echo ""
        log_warning "IMPORTANT: Edit .env file and set a secure password:"
        echo "  nano $COMPOSE_DIR/.env"
        echo ""
        echo "Then restart the stack:"
        echo "  cd $COMPOSE_DIR && docker-compose down && docker-compose up -d"
    fi

    log_success "Setup complete!"
}

# Run main function
main "$@"
