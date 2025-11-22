#!/bin/bash
# Universal Backup Script
# Supports: restic, rclone, borg
# Destinations: SSH, S3, rclone remote, local, and more
# Version: 1.0.0

set -euo pipefail

# Configuration
SCRIPT_VERSION="${SCRIPT_VERSION:-1.0.0}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
LOG_FILE="${LOG_FILE:-/var/log/backup.log}"

# Determine script directory (before sourcing common.sh)
BACKUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library if available
if [ -f "$BACKUP_SCRIPT_DIR/../base/lib/common.sh" ]; then
    # shellcheck source=../base/lib/common.sh
    source "$BACKUP_SCRIPT_DIR/../base/lib/common.sh"
else
    # Minimal fallback logging
    log_info() { echo "[INFO] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
    log_success() { echo "[SUCCESS] $1"; }
    log_warning() { echo "[WARNING] $1"; }
    command_exists() { command -v "$1" >/dev/null 2>&1; }
fi

# Source backup library
if [ -f "$BACKUP_SCRIPT_DIR/lib/backup-lib.sh" ]; then
    # shellcheck source=lib/backup-lib.sh
    source "$BACKUP_SCRIPT_DIR/lib/backup-lib.sh"
fi

# Default configuration values
BACKUP_TOOL="${BACKUP_TOOL:-restic}"
BACKUP_NAME="${BACKUP_NAME:-$(hostname)-backup}"
BACKUP_SOURCES="${BACKUP_SOURCES:-}"
BACKUP_DESTINATION="${BACKUP_DESTINATION:-}"
BACKUP_DESTINATION_TYPE="${BACKUP_DESTINATION_TYPE:-local}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
RETENTION_WEEKS="${RETENTION_WEEKS:-8}"
RETENTION_MONTHS="${RETENTION_MONTHS:-12}"
RETENTION_YEARS="${RETENTION_YEARS:-3}"

# Tool-specific variables
RESTIC_PASSWORD="${RESTIC_PASSWORD:-}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-}"
BORG_PASSPHRASE="${BORG_PASSPHRASE:-}"
BORG_REPOSITORY="${BORG_REPOSITORY:-}"

# Destination-specific variables
SSH_HOST="${SSH_HOST:-}"
SSH_USER="${SSH_USER:-}"
SSH_PORT="${SSH_PORT:-22}"
SSH_PATH="${SSH_PATH:-}"
S3_BUCKET="${S3_BUCKET:-}"
S3_REGION="${S3_REGION:-us-east-1}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"
RCLONE_PATH="${RCLONE_PATH:-}"

# Pre and post backup hooks
PRE_BACKUP_SCRIPT="${PRE_BACKUP_SCRIPT:-}"
POST_BACKUP_SCRIPT="${POST_BACKUP_SCRIPT:-}"

show_help() {
    cat << EOF
Universal Backup Script v${SCRIPT_VERSION}

Usage: $0 [OPTIONS]

Options:
    -t, --tool TOOL              Backup tool to use (restic|rclone|borg) [default: restic]
    -s, --source PATH            Path(s) to backup (can be specified multiple times)
    -d, --destination PATH       Backup destination path
    --destination-type TYPE      Destination type (local|ssh|s3|rclone) [default: local]
    -n, --name NAME              Backup name [default: hostname-backup]
    -c, --config FILE            Load configuration from file
    --list                       List available backups
    --restore PATH               Restore backup to PATH
    --snapshot ID                Snapshot/archive ID for restore
    --check                      Check backup integrity
    --prune                      Prune old backups based on retention policy
    --dry-run                    Show what would be done without doing it
    -v, --verbose                Verbose output
    --log-file FILE              Log file path [default: /var/log/backup.log]
    -h, --help                   Show this help message

Backup Tools:
    restic                       Fast, encrypted, deduplicated backups
    rclone                       Sync files to cloud storage
    borg                         Deduplicated, encrypted backups

Destination Types:
    local                        Local filesystem
    ssh                          Remote server via SSH
    s3                           Amazon S3 or S3-compatible storage
    rclone                       rclone remote (Dropbox, Google Drive, etc.)

Configuration File:
    You can use a configuration file instead of command-line arguments.
    See backup.conf.example for a template.

Environment Variables:
    For sensitive data, you can use environment variables:
    - RESTIC_PASSWORD           Restic repository password
    - BORG_PASSPHRASE           Borg repository passphrase
    - AWS_ACCESS_KEY_ID         AWS access key
    - AWS_SECRET_ACCESS_KEY     AWS secret key

Examples:
    # Backup home directory to local path using restic
    $0 --tool restic --source /home/user --destination /mnt/backup

    # Backup to remote server via SSH
    $0 --tool restic --source /var/www --destination-type ssh \\
       --destination user@server.com:/backups

    # Backup to S3
    $0 --tool restic --source /data --destination-type s3 \\
       --destination s3:s3.amazonaws.com/my-bucket

    # Backup using rclone to Dropbox
    $0 --tool rclone --source /home/user/documents \\
       --destination-type rclone --destination dropbox:backups

    # Use configuration file
    $0 --config /etc/backup.conf

    # List backups
    $0 --list --config /etc/backup.conf

    # Restore from backup
    $0 --restore /tmp/restore --snapshot latest --config /etc/backup.conf

    # Check backup integrity
    $0 --check --config /etc/backup.conf

    # Prune old backups
    $0 --prune --config /etc/backup.conf

EOF
}

validate_config() {
    local errors=0

    if [ -z "$BACKUP_SOURCES" ]; then
        log_error "No backup sources specified"
        ((errors++))
    fi

    if [ -z "$BACKUP_DESTINATION" ] && [ -z "$RESTIC_REPOSITORY" ] && [ -z "$BORG_REPOSITORY" ]; then
        log_error "No backup destination specified"
        ((errors++))
    fi

    # Validate backup tool is installed
    if ! command_exists "$BACKUP_TOOL"; then
        log_error "Backup tool '$BACKUP_TOOL' is not installed"
        log_info "Install $BACKUP_TOOL before running this script"
        ((errors++))
    fi

    # Tool-specific validation
    case "$BACKUP_TOOL" in
        restic)
            if [ -z "$RESTIC_PASSWORD" ] && [ -z "$RESTIC_PASSWORD_FILE" ]; then
                log_warning "RESTIC_PASSWORD not set - you may be prompted for password"
            fi
            ;;
        borg)
            if [ -z "$BORG_PASSPHRASE" ]; then
                log_warning "BORG_PASSPHRASE not set - repository may not be encrypted"
            fi
            ;;
        rclone)
            # Check if rclone remote is configured
            if [ "$BACKUP_DESTINATION_TYPE" = "rclone" ] && [ -z "$RCLONE_REMOTE" ]; then
                log_error "RCLONE_REMOTE not specified for rclone destination"
                ((errors++))
            fi
            ;;
    esac

    return $errors
}

load_config_file() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Loading configuration from: $config_file"
    # shellcheck source=/dev/null
    source "$config_file"
}

run_pre_backup_hook() {
    if [ -n "$PRE_BACKUP_SCRIPT" ] && [ -f "$PRE_BACKUP_SCRIPT" ]; then
        log_info "Running pre-backup script: $PRE_BACKUP_SCRIPT"
        bash "$PRE_BACKUP_SCRIPT" || {
            log_error "Pre-backup script failed"
            return 1
        }
    fi
}

run_post_backup_hook() {
    local exit_code=$1

    if [ -n "$POST_BACKUP_SCRIPT" ] && [ -f "$POST_BACKUP_SCRIPT" ]; then
        log_info "Running post-backup script: $POST_BACKUP_SCRIPT"
        bash "$POST_BACKUP_SCRIPT" "$exit_code" || {
            log_warning "Post-backup script failed"
        }
    fi
}

perform_backup() {
    log_info "Starting backup with $BACKUP_TOOL"
    log_info "Backup name: $BACKUP_NAME"
    log_info "Sources: $BACKUP_SOURCES"
    log_info "Destination: $BACKUP_DESTINATION"

    run_pre_backup_hook || return 1

    case "$BACKUP_TOOL" in
        restic)
            backup_with_restic
            ;;
        rclone)
            backup_with_rclone
            ;;
        borg)
            backup_with_borg
            ;;
        *)
            log_error "Unknown backup tool: $BACKUP_TOOL"
            return 1
            ;;
    esac

    local backup_status=$?
    run_post_backup_hook $backup_status

    return $backup_status
}

list_backups() {
    log_info "Listing backups from $BACKUP_TOOL repository"

    case "$BACKUP_TOOL" in
        restic)
            list_restic_snapshots
            ;;
        borg)
            list_borg_archives
            ;;
        rclone)
            list_rclone_backups
            ;;
        *)
            log_error "List operation not supported for: $BACKUP_TOOL"
            return 1
            ;;
    esac
}

restore_backup() {
    local restore_path="$1"
    local snapshot_id="${2:-latest}"

    log_info "Restoring backup to: $restore_path"
    log_info "Snapshot: $snapshot_id"

    case "$BACKUP_TOOL" in
        restic)
            restore_with_restic "$restore_path" "$snapshot_id"
            ;;
        borg)
            restore_with_borg "$restore_path" "$snapshot_id"
            ;;
        rclone)
            restore_with_rclone "$restore_path"
            ;;
        *)
            log_error "Restore operation not supported for: $BACKUP_TOOL"
            return 1
            ;;
    esac
}

check_backup() {
    log_info "Checking backup integrity"

    case "$BACKUP_TOOL" in
        restic)
            check_restic_repo
            ;;
        borg)
            check_borg_repo
            ;;
        rclone)
            log_warning "Integrity check not applicable for rclone sync"
            return 0
            ;;
        *)
            log_error "Check operation not supported for: $BACKUP_TOOL"
            return 1
            ;;
    esac
}

prune_backups() {
    log_info "Pruning old backups"
    log_info "Retention policy: $RETENTION_DAYS days, $RETENTION_WEEKS weeks, $RETENTION_MONTHS months, $RETENTION_YEARS years"

    case "$BACKUP_TOOL" in
        restic)
            prune_restic_snapshots
            ;;
        borg)
            prune_borg_archives
            ;;
        rclone)
            log_warning "Pruning not applicable for rclone sync"
            return 0
            ;;
        *)
            log_error "Prune operation not supported for: $BACKUP_TOOL"
            return 1
            ;;
    esac
}

main() {
    local operation="backup"
    local restore_path=""
    local snapshot_id=""
    local config_file=""
    local sources=()

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tool)
                BACKUP_TOOL="$2"
                shift 2
                ;;
            -s|--source)
                sources+=("$2")
                shift 2
                ;;
            -d|--destination)
                BACKUP_DESTINATION="$2"
                shift 2
                ;;
            --destination-type)
                BACKUP_DESTINATION_TYPE="$2"
                shift 2
                ;;
            -n|--name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            -c|--config)
                config_file="$2"
                shift 2
                ;;
            --list)
                operation="list"
                shift
                ;;
            --restore)
                operation="restore"
                restore_path="$2"
                shift 2
                ;;
            --snapshot)
                snapshot_id="$2"
                shift 2
                ;;
            --check)
                operation="check"
                shift
                ;;
            --prune)
                operation="prune"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                log_warning "DRY RUN MODE - No changes will be made"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                echo "Universal Backup Script v${SCRIPT_VERSION}"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Initialize logging
    if [ -n "$LOG_FILE" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        touch "$LOG_FILE" 2>/dev/null || LOG_FILE=""
    fi

    log_info "=========================================="
    log_info "Universal Backup Script v${SCRIPT_VERSION}"
    log_info "=========================================="

    # Load configuration file if specified
    if [ -n "$config_file" ]; then
        load_config_file "$config_file" || exit 1
    fi

    # Combine sources from command line and config
    if [ ${#sources[@]} -gt 0 ]; then
        BACKUP_SOURCES="${sources[*]}"
    fi

    # Build repository path based on destination type
    if [ -n "$BACKUP_DESTINATION" ]; then
        case "$BACKUP_DESTINATION_TYPE" in
            ssh)
                if [ "$BACKUP_TOOL" = "restic" ]; then
                    RESTIC_REPOSITORY="sftp:${BACKUP_DESTINATION}"
                elif [ "$BACKUP_TOOL" = "borg" ]; then
                    BORG_REPOSITORY="ssh://${BACKUP_DESTINATION}"
                fi
                ;;
            s3)
                if [ "$BACKUP_TOOL" = "restic" ]; then
                    RESTIC_REPOSITORY="${BACKUP_DESTINATION}"
                fi
                ;;
            rclone)
                RCLONE_REMOTE="${BACKUP_DESTINATION%%:*}"
                RCLONE_PATH="${BACKUP_DESTINATION#*:}"
                ;;
            local)
                if [ "$BACKUP_TOOL" = "restic" ]; then
                    RESTIC_REPOSITORY="$BACKUP_DESTINATION"
                elif [ "$BACKUP_TOOL" = "borg" ]; then
                    BORG_REPOSITORY="$BACKUP_DESTINATION"
                fi
                ;;
        esac
    fi

    # Validate configuration
    if ! validate_config; then
        log_error "Configuration validation failed"
        exit 1
    fi

    # Execute requested operation
    case "$operation" in
        backup)
            perform_backup || exit 1
            ;;
        list)
            list_backups || exit 1
            ;;
        restore)
            if [ -z "$restore_path" ]; then
                log_error "Restore path not specified"
                exit 1
            fi
            restore_backup "$restore_path" "$snapshot_id" || exit 1
            ;;
        check)
            check_backup || exit 1
            ;;
        prune)
            prune_backups || exit 1
            ;;
    esac

    log_success "=========================================="
    log_success "Operation completed successfully"
    log_success "=========================================="
}

# Run main function
main "$@"
