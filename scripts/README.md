# Utility Scripts

This directory contains general-purpose utility scripts for server management.

## Purpose

Reusable scripts that work across different services and applications:
- Backup and restore utilities
- Update management
- Monitoring helpers
- Security tools
- Maintenance scripts

## Available Scripts

### backup.sh
Universal backup script with multi-tool support:
- **Supported Tools**: restic, rclone, borg
- **Destinations**: Local filesystem, SSH/SFTP, S3, rclone remotes (Dropbox, Google Drive, etc.)
- **Features**:
  - Encrypted and deduplicated backups (restic, borg)
  - Cloud sync capabilities (rclone)
  - Flexible retention policies
  - Backup verification and integrity checks
  - Restore functionality
  - Pre/post backup hooks
  - Dry-run mode
  - Comprehensive logging

**Quick Start:**
```bash
# Local backup with restic
./scripts/backup.sh --tool restic --source /home --destination /mnt/backup

# Backup to remote server via SSH
./scripts/backup.sh --tool restic --source /var/www \
  --destination-type ssh --destination user@server.com:/backups

# Backup to S3
./scripts/backup.sh --tool restic --source /data \
  --destination-type s3 --destination s3:s3.amazonaws.com/my-bucket

# Backup to Dropbox using rclone
./scripts/backup.sh --tool rclone --source /home/user/documents \
  --destination-type rclone --destination dropbox:backups

# Use configuration file
./scripts/backup.sh --config /etc/backup.conf

# List available backups
./scripts/backup.sh --list --config /etc/backup.conf

# Restore from backup
./scripts/backup.sh --restore /tmp/restore --snapshot latest --config /etc/backup.conf

# Check backup integrity
./scripts/backup.sh --check --config /etc/backup.conf

# Prune old backups
./scripts/backup.sh --prune --config /etc/backup.conf
```

**Configuration:**
Copy `backup.conf.example` to create your configuration:
```bash
cp scripts/backup.conf.example /etc/backup.conf
# Edit with your settings
nano /etc/backup.conf
```

**Scheduled Backups:**
Add to crontab for automated backups:
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/scripts/backup.sh --config /etc/backup.conf

# Weekly cleanup at 3 AM on Sundays
0 3 * * 0 /path/to/scripts/backup.sh --prune --config /etc/backup.conf
```

**Security Notes:**
- Use environment variables for passwords: `RESTIC_PASSWORD`, `BORG_PASSPHRASE`
- Store AWS credentials in `~/.aws/credentials` or use IAM roles
- Configure rclone remotes with `rclone config`
- Use password files instead of plain text: `RESTIC_PASSWORD_FILE`

## Planned Scripts

### restore.sh
Restore from backups:
- Selective restoration
- Verification
- Rollback capabilities

### update.sh
Update all services and containers:
- Docker image updates
- System package updates
- Security patches
- Changelog generation

### monitor.sh
System monitoring:
- Disk space checks
- Container health
- Resource usage
- Alert notifications

### security-check.sh
Security audit:
- Open ports scan
- SSL certificate expiry
- Security updates available
- Configuration hardening checks

### cleanup.sh
System cleanup:
- Old Docker images
- Unused volumes
- Log rotation
- Temporary files

## Usage Examples

```bash
# Backup all services
./scripts/backup.sh --all

# Backup specific service
./scripts/backup.sh --service gitea

# Update all containers
./scripts/update.sh

# Security audit
./scripts/security-check.sh

# Cleanup
./scripts/cleanup.sh --dry-run
```

## Best Practices

1. **Make scripts configurable** - use config files or env vars
2. **Add dry-run options** for destructive operations
3. **Log all operations** with timestamps
4. **Send notifications** for important events
5. **Include help text** (`--help` flag)
6. **Return proper exit codes**
7. **Handle signals gracefully** (SIGTERM, SIGINT)

## Script Standards

All scripts should:
- Start with `#!/bin/bash`
- Use `set -e` for error handling
- Include usage/help function
- Accept common flags (`-h`, `-v`, `--dry-run`)
- Log to syslog or file
- Use consistent naming
- Be executable (`chmod +x`)

## Configuration

Create a central config file: `scripts/config.sh`

```bash
# Common configuration
BACKUP_DIR="/var/backups"
LOG_DIR="/var/log/server-scripts"
NOTIFICATION_EMAIL="admin@example.com"
RETENTION_DAYS=30
```

Source in other scripts:
```bash
source "$(dirname "$0")/config.sh"
```

## Logging

Use consistent logging:
```bash
log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$LOG_FILE" >&2
}
```

## Notifications

Support multiple notification methods:
- Email (sendmail, SMTP)
- Webhook (Discord, Slack, ntfy)
- SMS (Twilio)
- Push notifications

## Contributing

When adding new scripts:
1. Follow naming conventions (`lowercase-with-dashes.sh`)
2. Include help text and usage examples
3. Add error handling
4. Test thoroughly
5. Document in this README
6. Consider security implications
