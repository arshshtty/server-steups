# Server Setup Scripts

A comprehensive collection of server setup scripts, Docker Compose configurations, and installation guides for self-hosted applications.

## Purpose

This repository provides ready-to-use scripts and configurations for:
- Setting up new Debian/Ubuntu servers
- Deploying self-hosted applications with Docker Compose
- Managing containerized services
- Automating server maintenance tasks

## Repository Structure

```
server-steups/
├── base/                      # Base system setup scripts
│   ├── setup.sh              # Full development environment
│   ├── setup-minimal.sh      # Minimal server setup
│   └── verify.sh             # Installation verification
├── docker-compose/           # Docker Compose configurations
│   ├── ntfy/                 # Push notification service
│   ├── n8n/                  # Workflow automation
│   └── gitea/                # Self-hosted Git
├── apps/                     # Native installation scripts
│   └── ...                   # Application-specific scripts
├── scripts/                  # Utility scripts
│   ├── backup.sh            # Backup automation
│   ├── update.sh            # Update management
│   └── ...                   # Other utilities
├── docs/                     # Legacy documentation
└── CLAUDE.md                # Development guide
```

## Quick Start

### 1. Setup a New Server

Run the base setup script on a fresh Debian/Ubuntu installation:

```bash
# Full setup (development environment)
curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/base/setup.sh | bash

# Or minimal setup (production servers)
curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/base/setup-minimal.sh | bash
```

**What gets installed:**
- Zsh with Oh My Zsh
- Node.js LTS + npm
- Python 3 + pip + uv
- Docker + Docker Compose
- Essential CLI tools (git, curl, vim, htop, tmux, fzf, bat, ripgrep)

### 2. Deploy Self-Hosted Applications

```bash
# Clone the repository
git clone https://github.com/USER/server-steups.git
cd server-steups

# Deploy a service (example: ntfy)
cd docker-compose/ntfy
cp .env.example .env
nano .env  # Configure your settings
docker-compose up -d
```

## Planned Self-Hosted Applications

- **ntfy** - Push notifications to your phone or desktop
- **n8n** - Workflow automation (alternative to Zapier)
- **Gitea** - Lightweight self-hosted Git service
- **Uptime Kuma** - Status monitoring tool
- **Vaultwarden** - Password manager (Bitwarden-compatible)
- **Nextcloud** - File sync and sharing
- **Jellyfin** - Media streaming server
- **Traefik/Caddy** - Reverse proxy with automatic HTTPS

## Directory Guides

- **[base/](base/README.md)** - Base system setup scripts and verification
- **[docker-compose/](docker-compose/README.md)** - Docker Compose configurations for services
- **[apps/](apps/README.md)** - Native installation scripts
- **[scripts/](scripts/README.md)** - Backup, update, and maintenance utilities
- **[docs/](docs/)** - Legacy documentation

## Usage Examples

### Setup New Development VM
```bash
curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/base/setup.sh | bash
source ~/.zshrc
```

### Deploy Multiple Services
```bash
# Start all services in a directory
cd docker-compose
for dir in */; do
    (cd "$dir" && [ -f docker-compose.yml ] && docker-compose up -d)
done
```

### Backup All Services
```bash
./scripts/backup.sh --all
```

### Update Everything
```bash
./scripts/update.sh
```

## Requirements

- Debian 10+ or Ubuntu 20.04+
- Internet connection
- sudo/root access
- Docker (for containerized apps)

## Security Best Practices

1. **Never commit secrets** - Use `.env.example` templates only
2. **Review scripts before running** - Especially when piped from curl
3. **Use strong passwords** - For all services
4. **Enable HTTPS** - Use Caddy or Traefik for automatic SSL
5. **Keep systems updated** - Run updates regularly
6. **Firewall configuration** - Only expose necessary ports
7. **Backup regularly** - Automate backups of critical data

## Contributing

This is a personal repository but feel free to:
- Fork and customize for your needs
- Submit improvements via pull requests
- Report issues or suggestions
- Share your configurations

### Adding a New Service

1. Create directory in `docker-compose/SERVICE_NAME/`
2. Add:
   - `docker-compose.yml`
   - `.env.example`
   - `README.md`
   - Configuration files
3. Test thoroughly
4. Update main README

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines and repository conventions.

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Awesome Self-Hosted](https://github.com/awesome-selfhosted/awesome-selfhosted)
- [LinuxServer.io](https://www.linuxserver.io/) - Quality Docker images

## License

MIT License - Use freely for personal or commercial projects.

## Roadmap

- [ ] Add ntfy setup
- [ ] Add n8n with PostgreSQL
- [ ] Add Gitea configuration
- [ ] Create backup automation script
- [ ] Add Traefik reverse proxy
- [ ] Add monitoring stack (Prometheus + Grafana)
- [ ] Create update automation
- [ ] Add security hardening scripts
- [ ] Document SSL/TLS setup
- [ ] Create migration guides

---

**Note:** This repository is actively being developed and restructured. Check back for new services and improvements!
