# Server Setup Scripts Repository

## Overview

This repository contains setup scripts, Docker Compose configurations, and installation guides for self-hosted applications and server infrastructure. The goal is to provide a centralized collection of reusable scripts to quickly deploy and configure servers with various tools and services.

## Purpose

Store and organize:
- Server setup and configuration scripts
- Docker Compose files for containerized applications
- Installation scripts for self-hosted applications (ntfy, n8n, gitea, etc.)
- Container management utilities
- Reusable infrastructure as code templates

## Repository Structure

```
server-steups/
├── base/                      # Base system setup scripts
│   ├── setup.sh              # Full development environment setup
│   ├── setup-minimal.sh      # Minimal setup for servers
│   └── verify.sh             # Verification script
├── docker-compose/           # Docker Compose configurations
│   ├── ntfy/                 # ntfy notification service
│   ├── n8n/                  # n8n workflow automation
│   ├── gitea/                # Gitea git service
│   └── README.md            # Docker compose usage guide
├── apps/                     # Self-hosted app installation scripts
│   ├── ntfy/                 # ntfy setup scripts
│   ├── n8n/                  # n8n setup scripts
│   ├── gitea/                # gitea setup scripts
│   └── README.md            # App installation guide
├── scripts/                  # Utility scripts
│   ├── backup.sh            # Backup utilities
│   ├── restore.sh           # Restore utilities
│   └── update.sh            # Update utilities
├── docs/                     # Documentation (legacy)
│   └── ...                  # Existing documentation files
├── CLAUDE.md                # This file - Claude Code documentation
└── README.md                # Main repository documentation
```

## Current Contents

The repository currently contains legacy VM/container setup scripts:
- **setup.sh** (8 KB): Full-featured Debian/Ubuntu setup with Zsh, Node.js, Python, Docker, and CLI tools
- **setup-minimal.sh** (1.7 KB): Lightweight version for CI/CD
- **verify.sh** (2.8 KB): Post-installation verification
- **Documentation files**: Multiple markdown and text files documenting the VM setup workflow

## Planned Additions

### Self-Hosted Applications

1. **ntfy** - Push notification service
   - Docker Compose setup
   - Configuration templates
   - Reverse proxy configs

2. **n8n** - Workflow automation platform
   - Docker Compose with PostgreSQL
   - Environment configuration
   - Backup/restore scripts

3. **gitea** - Self-hosted Git service
   - Docker Compose setup
   - Database configuration
   - Migration guides

4. **Additional services to be added**:
   - Uptime Kuma (monitoring)
   - Vaultwarden (password manager)
   - Nextcloud (file sync)
   - Jellyfin (media server)
   - Traefik/Caddy (reverse proxy)

### Infrastructure Scripts

- SSL certificate management (Let's Encrypt)
- Automated backups
- System monitoring setup
- Log aggregation
- Security hardening scripts

## Working with This Repository

### Adding New Services

When adding a new self-hosted service:

1. Create a directory under `apps/` and `docker-compose/`
2. Include:
   - `docker-compose.yml` - Docker Compose configuration
   - `README.md` - Service-specific documentation
   - `.env.example` - Environment variable template
   - `setup.sh` - Installation/setup script (if needed)
   - `backup.sh` - Backup script (if applicable)

3. Update main README.md with the new service

### Best Practices

- Keep docker-compose files production-ready
- Use environment variables for sensitive data
- Include comprehensive README files
- Add example configurations
- Document prerequisites
- Include troubleshooting steps
- Version control everything except secrets

### Testing

- Test all scripts on fresh Ubuntu/Debian installations
- Verify Docker Compose files work in isolation
- Check all environment variables are documented
- Ensure scripts are idempotent where possible

## Development Branch

This repository uses feature branches for development:
- Main branch: `main` (production-ready scripts)
- Feature branches: `claude/server-setup-scripts-*`

## Conventions

### File Naming
- Scripts: `kebab-case.sh`
- Docker Compose: `docker-compose.yml`
- Environment files: `.env.example`

### Documentation
- Each service/app should have its own README
- Include version information
- Document all configuration options
- Provide real-world examples

### Code Style
- Use shellcheck for bash scripts
- Follow Docker best practices
- Include comments for complex operations
- Add error handling

## Common Tasks

### Deploy a new service
```bash
cd docker-compose/SERVICE_NAME
cp .env.example .env
# Edit .env with your configuration
docker-compose up -d
```

### Run base setup on new server
```bash
curl -fsSL https://raw.githubusercontent.com/USER/server-steups/main/base/setup.sh | bash
```

### Update all containers
```bash
./scripts/update.sh
```

### Backup configuration
```bash
./scripts/backup.sh
```

## Security Notes

- Never commit `.env` files with real secrets
- Always use `.env.example` as templates
- Store secrets in secure vaults (not in git)
- Use strong, unique passwords
- Keep systems and containers updated
- Enable firewall rules
- Use HTTPS/TLS for all services

## Contributing

When making changes:
1. Create a feature branch
2. Test thoroughly on a clean system
3. Update documentation
4. Commit with clear messages
5. Push to feature branch

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Self-Hosted List](https://github.com/awesome-selfhosted/awesome-selfhosted)

## License

MIT License - Use freely for personal or commercial projects
