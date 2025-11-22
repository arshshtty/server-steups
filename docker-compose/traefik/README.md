# Traefik Reverse Proxy

Dead simple yet effective Traefik v3 reverse proxy setup with automatic HTTPS via Let's Encrypt.

## What is Traefik?

Traefik is a modern reverse proxy and load balancer that makes deploying microservices easy. It automatically discovers services and configures itself dynamically.

**Key Features:**
- 🔒 Automatic HTTPS with Let's Encrypt
- 🐳 Docker integration (auto-discovery)
- 📊 Built-in dashboard
- 🔄 Zero-downtime deployments
- 🚀 Simple label-based configuration

## Quick Start

### 1. Run the Setup Script

```bash
cd docker-compose/traefik
./setup.sh
```

The script will:
- Create necessary directories
- Set up `.env` configuration
- Create Docker network
- Optionally generate dashboard password
- Start Traefik

### 2. Manual Setup (Alternative)

If you prefer manual setup:

```bash
# Create required directories
mkdir -p letsencrypt logs dynamic

# Create acme.json with proper permissions
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json

# Copy and edit environment file
cp .env.example .env
nano .env

# Create Docker network
docker network create traefik_proxy

# Start Traefik
docker compose up -d
```

## Configuration

### Environment Variables

Edit `.env` with your settings:

```bash
# Let's Encrypt email for notifications
ACME_EMAIL=admin@example.com

# Dashboard domain
TRAEFIK_DASHBOARD_DOMAIN=traefik.example.com

# Dashboard basic auth (generate with htpasswd)
DASHBOARD_AUTH=admin:$$apr1$$...

# Enable/disable dashboard
ENABLE_DASHBOARD=true

# Log level (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL=INFO
```

### Generate Dashboard Password

```bash
# Install htpasswd
sudo apt-get install apache2-utils

# Generate password (replace 'admin' and 'your_password')
htpasswd -nb admin your_password | sed -e 's/\$/\$\$/g'

# Copy the output to DASHBOARD_AUTH in .env
```

## Using Traefik with Your Services

### Example: Basic Web Service

Add these labels to any service in a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  myapp:
    image: nginx:alpine
    networks:
      - traefik_proxy
    labels:
      # Enable Traefik
      - "traefik.enable=true"
      # HTTP router
      - "traefik.http.routers.myapp.rule=Host(`myapp.example.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      # Service port
      - "traefik.http.services.myapp.loadbalancer.server.port=80"

networks:
  traefik_proxy:
    external: true
```

### Example: Service with Path Prefix

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`example.com`) && PathPrefix(`/api`)"
  - "traefik.http.routers.api.entrypoints=websecure"
  - "traefik.http.routers.api.tls.certresolver=letsencrypt"
```

### Example: Service with Basic Auth

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.protected.rule=Host(`secret.example.com`)"
  - "traefik.http.routers.protected.entrypoints=websecure"
  - "traefik.http.routers.protected.tls.certresolver=letsencrypt"
  # Add basic auth middleware
  - "traefik.http.routers.protected.middlewares=auth"
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
```

### Example: Service with Custom Headers

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.webapp.rule=Host(`app.example.com`)"
  - "traefik.http.routers.webapp.entrypoints=websecure"
  - "traefik.http.routers.webapp.tls.certresolver=letsencrypt"
  # Add security headers
  - "traefik.http.routers.webapp.middlewares=security-headers"
  - "traefik.http.middlewares.security-headers.headers.customresponseheaders.X-Frame-Options=SAMEORIGIN"
  - "traefik.http.middlewares.security-headers.headers.customresponseheaders.X-Content-Type-Options=nosniff"
```

## Advanced Configuration

### Using Cloudflare DNS Challenge

If you need wildcards or can't use port 80/443:

1. Get Cloudflare API token with DNS edit permissions
2. Update `.env`:
   ```bash
   CF_API_EMAIL=your@email.com
   CF_DNS_API_TOKEN=your_token_here
   ```

3. Uncomment DNS challenge lines in `docker-compose.yml`:
   ```yaml
   - --certificatesresolvers.letsencrypt.acme.dnschallenge=true
   - --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare
   ```

### Dynamic Configuration

Create files in `./dynamic/` for additional configuration:

**dynamic/middlewares.yml:**
```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 50

    compress:
      compress: {}
```

**dynamic/tls.yml:**
```yaml
tls:
  options:
    default:
      minVersion: VersionTLS12
      cipherSuites:
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
```

## Management Commands

### View Status
```bash
docker compose ps
```

### View Logs
```bash
# All logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100

# Access logs
tail -f logs/access.log

# Traefik logs
tail -f logs/traefik.log
```

### Restart Traefik
```bash
docker compose restart
```

### Update Traefik
```bash
docker compose pull
docker compose up -d
```

### Stop Traefik
```bash
docker compose down
```

### Check Configuration
```bash
# Validate docker-compose.yml
docker compose config

# Check running containers
docker ps
```

## Accessing the Dashboard

### Via Domain (Recommended)
1. Point your domain to your server
2. Set `TRAEFIK_DASHBOARD_DOMAIN` in `.env`
3. Access: `https://traefik.example.com`

### Via Port (Development)
1. Set `TRAEFIK_DASHBOARD_PORT=8080` in `.env`
2. Set `DASHBOARD_INSECURE=true` in `.env` (not for production!)
3. Access: `http://your-server-ip:8080`

**Dashboard Features:**
- View all routes and services
- Monitor health checks
- See TLS certificates
- Check middlewares
- View metrics

## File Structure

```
traefik/
├── docker-compose.yml      # Main configuration
├── .env.example           # Environment template
├── .env                   # Your configuration (git-ignored)
├── setup.sh              # Automated setup script
├── README.md             # This file
├── letsencrypt/          # SSL certificates
│   └── acme.json         # Let's Encrypt data
├── logs/                 # Log files
│   ├── traefik.log      # Application logs
│   └── access.log       # Access logs
└── dynamic/              # Dynamic configuration
    └── *.yml            # Optional config files
```

## Troubleshooting

### Certificate Issues

**Problem:** Let's Encrypt rate limit exceeded
```bash
# Check certificate status
docker compose logs traefik | grep -i acme

# Use staging for testing
# Add to docker-compose.yml:
- --certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
```

**Problem:** acme.json permission denied
```bash
chmod 600 letsencrypt/acme.json
```

### Service Not Working

**Check if service is in traefik_proxy network:**
```bash
docker network inspect traefik_proxy
```

**Check Traefik logs:**
```bash
docker compose logs traefik | grep -i error
```

**Verify labels:**
```bash
docker inspect container_name | grep -i traefik
```

### Dashboard Not Accessible

**Check dashboard is enabled:**
```bash
grep ENABLE_DASHBOARD .env
```

**Verify auth credentials:**
```bash
# Test basic auth
curl -u admin:password https://traefik.example.com
```

### Port Conflicts

**Problem:** Port 80 or 443 already in use
```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Stop the service
sudo systemctl stop apache2  # or nginx
```

## Security Best Practices

1. **Use Strong Passwords**
   - Generate secure dashboard passwords
   - Don't use default credentials

2. **Restrict Dashboard Access**
   - Use basic auth (minimum)
   - Consider IP whitelisting
   - Use VPN for sensitive environments

3. **Keep Updated**
   ```bash
   docker compose pull
   docker compose up -d
   ```

4. **Monitor Logs**
   - Check for failed auth attempts
   - Watch for unusual traffic patterns

5. **Use HTTPS Only**
   - Never disable TLS in production
   - Use HTTP→HTTPS redirect (enabled by default)

6. **Firewall Configuration**
   ```bash
   # Allow only necessary ports
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   # Don't expose 8080 publicly
   ```

## DNS Configuration

Point your domains to your server:

### A Record
```
traefik.example.com    A    1.2.3.4
app.example.com        A    1.2.3.4
```

### CNAME Record
```
*.example.com    CNAME    example.com
```

## Performance Tips

1. **Enable Compression**
   ```yaml
   # Add to service labels
   - "traefik.http.routers.myapp.middlewares=compress"
   ```

2. **Use HTTP/2**
   - Enabled by default on HTTPS

3. **Enable Access Log Sampling**
   ```bash
   # In docker-compose.yml
   - --accesslog.filters.statuscodes=400-599
   ```

4. **Limit Log Size**
   ```bash
   # Rotate logs with logrotate
   sudo nano /etc/logrotate.d/traefik
   ```

## Migration from Other Proxies

### From Nginx
- Replace `proxy_pass` with Traefik labels
- SSL certificates handled automatically
- No need for manual configuration files

### From Caddy
- Similar label-based approach
- Both support automatic HTTPS
- Traefik has better Docker integration

### From Apache
- Much simpler configuration
- No .htaccess needed
- Better suited for containers

## Examples for Common Applications

### Nextcloud
```yaml
- "traefik.http.routers.nextcloud.rule=Host(`cloud.example.com`)"
- "traefik.http.routers.nextcloud.middlewares=nextcloud-headers"
- "traefik.http.middlewares.nextcloud-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
```

### GitLab
```yaml
- "traefik.http.routers.gitlab.rule=Host(`git.example.com`)"
- "traefik.http.services.gitlab.loadbalancer.server.port=80"
```

### WordPress
```yaml
- "traefik.http.routers.wordpress.rule=Host(`blog.example.com`)"
- "traefik.http.services.wordpress.loadbalancer.server.port=80"
```

## Resources

- [Official Documentation](https://doc.traefik.io/traefik/)
- [Docker Provider Guide](https://doc.traefik.io/traefik/providers/docker/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Traefik Community Forum](https://community.traefik.io/)

## Support

For issues with this setup:
1. Check the troubleshooting section
2. Review Traefik logs
3. Consult official documentation
4. Check Docker network configuration

## License

MIT License - Use freely for personal or commercial projects.
