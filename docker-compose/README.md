# Docker Compose Configurations

This directory contains Docker Compose configurations for self-hosted applications and services.

## Structure

Each service has its own directory with:
```
service-name/
├── docker-compose.yml    # Docker Compose configuration
├── .env.example         # Environment variables template
├── README.md           # Service-specific documentation
├── config/             # Configuration files (if needed)
└── data/              # Persistent data (gitignored)
```

## Planned Services

- **ntfy** - Push notification service
- **n8n** - Workflow automation platform
- **gitea** - Self-hosted Git service
- **uptime-kuma** - Monitoring tool
- **vaultwarden** - Password manager
- **traefik** - Reverse proxy and load balancer

## Usage

### Deploy a Service

```bash
cd service-name/
cp .env.example .env
# Edit .env with your configuration
nano .env

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Update a Service

```bash
cd service-name/
docker-compose pull
docker-compose up -d
```

### Backup Data

```bash
# Backup volumes
docker-compose down
tar -czf backup-$(date +%Y%m%d).tar.gz data/
docker-compose up -d
```

## Best Practices

1. **Use .env files** for configuration (never commit real .env files)
2. **Map volumes** for persistent data
3. **Use networks** to isolate services
4. **Set resource limits** for production
5. **Enable healthchecks** for reliability
6. **Use specific versions** (not `latest`)
7. **Configure logging** properly
8. **Add labels** for organization

## Security

- Never expose database ports publicly
- Use strong passwords
- Enable HTTPS with reverse proxy
- Keep images updated
- Review security advisories
- Use secrets management
- Limit container capabilities

## Common Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service]

# Restart a service
docker-compose restart [service]

# Update and restart
docker-compose pull && docker-compose up -d

# Remove everything (including volumes)
docker-compose down -v
```

## Contributing

When adding a new service:
1. Create a directory with the service name
2. Include all required files (see Structure above)
3. Test thoroughly
4. Document environment variables
5. Add usage examples
6. Update this README
