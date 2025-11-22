#!/bin/bash
# Backup library with tool-specific functions
# Source this file in backup scripts

# ============================================
# RESTIC Functions
# ============================================

backup_with_restic() {
    local sources_array
    IFS=' ' read -r -a sources_array <<< "$BACKUP_SOURCES"

    # Check if repository exists, if not initialize
    if ! restic -r "$RESTIC_REPOSITORY" snapshots &>/dev/null; then
        log_info "Initializing new restic repository"
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY-RUN] Would initialize: restic init -r $RESTIC_REPOSITORY"
        else
            restic -r "$RESTIC_REPOSITORY" init || {
                log_error "Failed to initialize restic repository"
                return 1
            }
        fi
    fi

    # Perform backup
    local restic_cmd="restic -r $RESTIC_REPOSITORY backup ${sources_array[*]}"
    restic_cmd="$restic_cmd --tag $BACKUP_NAME"

    if [ "$VERBOSE" = "true" ]; then
        restic_cmd="$restic_cmd --verbose"
    fi

    log_info "Running: $restic_cmd"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would execute: $restic_cmd"
        return 0
    fi

    eval "$restic_cmd" || {
        log_error "Restic backup failed"
        return 1
    }

    log_success "Restic backup completed successfully"
    return 0
}

list_restic_snapshots() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would list snapshots from: $RESTIC_REPOSITORY"
        return 0
    fi

    restic -r "$RESTIC_REPOSITORY" snapshots || {
        log_error "Failed to list restic snapshots"
        return 1
    }
}

restore_with_restic() {
    local restore_path="$1"
    local snapshot_id="$2"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would restore snapshot $snapshot_id to $restore_path"
        return 0
    fi

    mkdir -p "$restore_path"

    restic -r "$RESTIC_REPOSITORY" restore "$snapshot_id" --target "$restore_path" || {
        log_error "Failed to restore from restic"
        return 1
    }

    log_success "Restore completed successfully"
    return 0
}

check_restic_repo() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would check repository: $RESTIC_REPOSITORY"
        return 0
    fi

    restic -r "$RESTIC_REPOSITORY" check || {
        log_error "Repository check failed"
        return 1
    }

    log_success "Repository check passed"
    return 0
}

prune_restic_snapshots() {
    local forget_cmd="restic -r $RESTIC_REPOSITORY forget"
    forget_cmd="$forget_cmd --keep-daily $RETENTION_DAYS"
    forget_cmd="$forget_cmd --keep-weekly $RETENTION_WEEKS"
    forget_cmd="$forget_cmd --keep-monthly $RETENTION_MONTHS"
    forget_cmd="$forget_cmd --keep-yearly $RETENTION_YEARS"
    forget_cmd="$forget_cmd --prune"

    if [ "$VERBOSE" = "true" ]; then
        forget_cmd="$forget_cmd --verbose"
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would execute: $forget_cmd"
        return 0
    fi

    eval "$forget_cmd" || {
        log_error "Failed to prune restic snapshots"
        return 1
    }

    log_success "Pruning completed successfully"
    return 0
}

# ============================================
# RCLONE Functions
# ============================================

backup_with_rclone() {
    local sources_array
    IFS=' ' read -r -a sources_array <<< "$BACKUP_SOURCES"

    local destination="${RCLONE_REMOTE}:${RCLONE_PATH}"

    for source in "${sources_array[@]}"; do
        log_info "Syncing $source to $destination"

        local rclone_cmd="rclone sync"

        if [ "$VERBOSE" = "true" ]; then
            rclone_cmd="$rclone_cmd --progress --verbose"
        fi

        rclone_cmd="$rclone_cmd $source $destination/$(basename "$source")"

        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY-RUN] Would execute: $rclone_cmd"
            continue
        fi

        eval "$rclone_cmd" || {
            log_error "Failed to sync $source with rclone"
            return 1
        }
    done

    log_success "Rclone sync completed successfully"
    return 0
}

list_rclone_backups() {
    local destination="${RCLONE_REMOTE}:${RCLONE_PATH}"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would list files from: $destination"
        return 0
    fi

    rclone ls "$destination" || {
        log_error "Failed to list rclone destination"
        return 1
    }
}

restore_with_rclone() {
    local restore_path="$1"
    local destination="${RCLONE_REMOTE}:${RCLONE_PATH}"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would restore from $destination to $restore_path"
        return 0
    fi

    mkdir -p "$restore_path"

    rclone sync "$destination" "$restore_path" || {
        log_error "Failed to restore with rclone"
        return 1
    }

    log_success "Restore completed successfully"
    return 0
}

# ============================================
# BORG Functions
# ============================================

backup_with_borg() {
    local sources_array
    IFS=' ' read -r -a sources_array <<< "$BACKUP_SOURCES"

    # Check if repository exists, if not initialize
    if ! borg info "$BORG_REPOSITORY" &>/dev/null; then
        log_info "Initializing new borg repository"
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY-RUN] Would initialize: borg init -e repokey $BORG_REPOSITORY"
        else
            borg init --encryption=repokey "$BORG_REPOSITORY" || {
                log_error "Failed to initialize borg repository"
                return 1
            }
        fi
    fi

    # Create archive name with timestamp
    local archive_name="${BACKUP_NAME}-$(date +%Y-%m-%d_%H-%M-%S)"
    local borg_cmd="borg create"

    if [ "$VERBOSE" = "true" ]; then
        borg_cmd="$borg_cmd --verbose --stats --progress"
    fi

    borg_cmd="$borg_cmd $BORG_REPOSITORY::$archive_name ${sources_array[*]}"

    log_info "Creating archive: $archive_name"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would execute: $borg_cmd"
        return 0
    fi

    eval "$borg_cmd" || {
        log_error "Borg backup failed"
        return 1
    }

    log_success "Borg backup completed successfully"
    return 0
}

list_borg_archives() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would list archives from: $BORG_REPOSITORY"
        return 0
    fi

    borg list "$BORG_REPOSITORY" || {
        log_error "Failed to list borg archives"
        return 1
    }
}

restore_with_borg() {
    local restore_path="$1"
    local archive_id="$2"

    # If archive_id is "latest", find the most recent archive
    if [ "$archive_id" = "latest" ]; then
        archive_id=$(borg list "$BORG_REPOSITORY" --short | tail -n1)
        log_info "Using latest archive: $archive_id"
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would restore archive $archive_id to $restore_path"
        return 0
    fi

    mkdir -p "$restore_path"

    borg extract "$BORG_REPOSITORY::$archive_id" --target "$restore_path" || {
        log_error "Failed to restore from borg"
        return 1
    }

    log_success "Restore completed successfully"
    return 0
}

check_borg_repo() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would check repository: $BORG_REPOSITORY"
        return 0
    fi

    borg check "$BORG_REPOSITORY" || {
        log_error "Repository check failed"
        return 1
    }

    log_success "Repository check passed"
    return 0
}

prune_borg_archives() {
    local prune_cmd="borg prune $BORG_REPOSITORY"
    prune_cmd="$prune_cmd --keep-daily=$RETENTION_DAYS"
    prune_cmd="$prune_cmd --keep-weekly=$RETENTION_WEEKS"
    prune_cmd="$prune_cmd --keep-monthly=$RETENTION_MONTHS"
    prune_cmd="$prune_cmd --keep-yearly=$RETENTION_YEARS"

    if [ "$VERBOSE" = "true" ]; then
        prune_cmd="$prune_cmd --verbose --stats"
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY-RUN] Would execute: $prune_cmd"
        return 0
    fi

    eval "$prune_cmd" || {
        log_error "Failed to prune borg archives"
        return 1
    }

    log_success "Pruning completed successfully"
    return 0
}
