# Nginx Reverse Proxy Manager

A dead simple yet effective CLI tool for managing Nginx reverse proxy configurations. Perfect for self-hosters, homelab enthusiasts, and anyone who needs to quickly expose multiple services through a single server.

## Features

✅ **Dead Simple CLI** - Add/remove proxies with a single command
✅ **Automatic SSL/TLS** - Let's Encrypt integration with auto-renewal
✅ **WebSocket Support** - Built-in WebSocket proxy configuration
✅ **Configuration Management** - Track all proxies in JSON format
✅ **Zero Downtime** - Live reload of Nginx without service interruption
✅ **Security Headers** - Pre-configured security headers for all proxies
✅ **Firewall Integration** - Automatic UFW configuration (if installed)
✅ **Comprehensive Logging** - Track all changes and operations

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Add a Reverse Proxy](#add-a-reverse-proxy)
  - [List All Proxies](#list-all-proxies)
  - [Enable SSL/TLS](#enable-ssltls)
  - [Remove a Proxy](#remove-a-proxy)
  - [Enable/Disable Proxies](#enabledisable-proxies)
- [Use Cases](#use-cases)
- [Advanced Usage](#advanced-usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Security Considerations](#security-considerations)

## Installation

### Prerequisites

- Ubuntu/Debian-based Linux distribution
- Root or sudo access
- Internet connection

### One-Line Install

```bash
cd apps/nginx-proxy
sudo bash setup.sh
```

### What Gets Installed

The setup script will install:

1. **Nginx** - If not already installed
2. **Python3** - Required for JSON configuration management
3. **Certbot** (optional) - For Let's Encrypt SSL certificates
4. **nginx-proxy** command - Installed to `/usr/local/bin/`

### Manual Installation

If you prefer to install components manually:

```bash
# Install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# Install Python3
sudo apt-get install -y python3

# Install Certbot (optional, for SSL)
sudo apt-get install -y certbot python3-certbot-nginx

# Copy nginx-proxy command
sudo cp nginx-proxy /usr/local/bin/
sudo chmod +x /usr/local/bin/nginx-proxy

# Create config directory
sudo mkdir -p /etc/nginx-proxy
echo '{}' | sudo tee /etc/nginx-proxy/proxies.json
```

## Quick Start

### 1. Add Your First Reverse Proxy

Let's say you have a Node.js app running on `localhost:3000` and you want to expose it at `myapp.example.com`:

```bash
sudo nginx-proxy add myapp.example.com localhost:3000
```

That's it! Your app is now accessible at `http://myapp.example.com`

### 2. Enable HTTPS with Let's Encrypt

```bash
sudo nginx-proxy enable-ssl myapp.example.com admin@example.com
```

Now your app is secured with HTTPS and the certificate will auto-renew!

### 3. List All Your Proxies

```bash
nginx-proxy list
```

Output:
```
myapp.example.com              localhost:3000            SSL:✅  Enabled:✅
api.example.com                192.168.1.100:8080        SSL:✅  Enabled:✅
```

## Usage

### Add a Reverse Proxy

**Basic HTTP proxy:**

```bash
sudo nginx-proxy add <domain> <backend>
```

**Examples:**

```bash
# Expose a local service
sudo nginx-proxy add blog.example.com localhost:2368

# Proxy to another machine on your network
sudo nginx-proxy add homeassistant.example.com 192.168.1.50:8123

# Proxy to a Docker container
sudo nginx-proxy add portainer.example.com localhost:9000

# Add a proxy with WebSocket support (for real-time apps)
sudo nginx-proxy add n8n.example.com localhost:5678 --websocket
```

**Backend Format:**

The backend can be:
- `localhost:PORT` - Local service
- `IP:PORT` - Service on another machine
- `hostname:PORT` - Service by hostname

### List All Proxies

```bash
nginx-proxy list
```

Shows all configured proxies with their status:
- Domain name
- Backend address
- SSL status (✅ enabled, ❌ disabled)
- Enabled status (✅ enabled, ❌ disabled)

### Enable SSL/TLS

**With Let's Encrypt:**

```bash
sudo nginx-proxy enable-ssl <domain> [email]
```

**Examples:**

```bash
# With email (recommended)
sudo nginx-proxy enable-ssl myapp.example.com admin@example.com

# Interactive mode (will prompt for email)
sudo nginx-proxy enable-ssl myapp.example.com
```

**Requirements:**
- Domain must point to your server's IP address
- Ports 80 and 443 must be accessible from the internet
- Certbot must be installed

**Auto-Renewal:**

Certificates automatically renew via systemd timer. Check status:

```bash
systemctl status certbot.timer
```

### Remove a Proxy

```bash
sudo nginx-proxy remove <domain>
```

**Example:**

```bash
sudo nginx-proxy remove myapp.example.com
```

This will:
- Disable the site
- Remove Nginx configuration
- Remove from JSON config
- Reload Nginx

**Note:** SSL certificates are NOT automatically removed. To remove a certificate:

```bash
sudo certbot delete --cert-name myapp.example.com
```

### Enable/Disable Proxies

**Disable a proxy** (keeps configuration, just stops serving):

```bash
sudo nginx-proxy disable <domain>
```

**Re-enable a disabled proxy:**

```bash
sudo nginx-proxy enable <domain>
```

This is useful when you want to temporarily stop serving a domain without removing the configuration.

### Other Commands

**Check Nginx status:**

```bash
nginx-proxy status
```

**Test Nginx configuration:**

```bash
nginx-proxy test
```

**Reload Nginx:**

```bash
sudo nginx-proxy reload
```

**Show help:**

```bash
nginx-proxy help
```

## Use Cases

### 1. Self-Hosted Applications

Expose multiple self-hosted apps on different subdomains:

```bash
# Nextcloud
sudo nginx-proxy add cloud.example.com localhost:8080

# Gitea
sudo nginx-proxy add git.example.com localhost:3000

# n8n automation
sudo nginx-proxy add workflows.example.com localhost:5678 --websocket

# Uptime Kuma monitoring
sudo nginx-proxy add status.example.com localhost:3001 --websocket
```

### 2. Homelab Services

Proxy to services running on different machines:

```bash
# Proxmox web interface
sudo nginx-proxy add proxmox.home.local 192.168.1.100:8006

# TrueNAS
sudo nginx-proxy add nas.home.local 192.168.1.101:80

# Home Assistant
sudo nginx-proxy add homeassistant.home.local 192.168.1.102:8123 --websocket
```

### 3. Development Environments

Quickly expose development servers:

```bash
# React development server
sudo nginx-proxy add dev.example.com localhost:3000 --websocket

# Django backend
sudo nginx-proxy add api-dev.example.com localhost:8000

# Database admin tool
sudo nginx-proxy add pgadmin.local localhost:5050
```

### 4. Docker Containers

Proxy to containerized applications:

```bash
# Portainer
sudo nginx-proxy add portainer.example.com localhost:9000

# Jellyfin media server
sudo nginx-proxy add media.example.com localhost:8096

# Vaultwarden password manager
sudo nginx-proxy add vault.example.com localhost:8080
```

## Advanced Usage

### WebSocket Support

For applications that use WebSockets (real-time communication), add the `--websocket` flag:

```bash
sudo nginx-proxy add chat.example.com localhost:3000 --websocket
```

This configures Nginx to properly handle WebSocket connections with:
- HTTP/1.1 protocol upgrade
- Connection upgrade headers
- Proper timeout settings

**Applications that typically need WebSocket support:**
- Chat applications
- Real-time dashboards
- n8n workflow automation
- Home Assistant
- Uptime Kuma
- Socket.io applications

### Custom Nginx Configuration

The generated configurations are stored in `/etc/nginx/sites-available/<domain>`.

You can manually edit them if needed:

```bash
sudo nano /etc/nginx/sites-available/myapp.example.com
sudo nginx -t                    # Test configuration
sudo systemctl reload nginx      # Apply changes
```

**Note:** Manual changes will be preserved unless you remove and re-add the proxy.

### Viewing Logs

**Application logs:**

```bash
tail -f /var/log/nginx/myapp.example.com-access.log
tail -f /var/log/nginx/myapp.example.com-error.log
```

**nginx-proxy logs:**

```bash
tail -f /var/log/nginx-proxy.log
```

### Backup and Restore

**Backup all configurations:**

```bash
# Backup proxy configs
sudo cp /etc/nginx-proxy/proxies.json ~/backup/proxies.json.backup

# Backup Nginx site configs
sudo tar -czf ~/backup/nginx-sites.tar.gz /etc/nginx/sites-available/
```

**Restore from backup:**

```bash
# Restore proxy configs
sudo cp ~/backup/proxies.json.backup /etc/nginx-proxy/proxies.json

# Restore Nginx configs
sudo tar -xzf ~/backup/nginx-sites.tar.gz -C /

# Re-enable all sites
cd /etc/nginx/sites-available
for site in *; do
    sudo ln -sf /etc/nginx/sites-available/$site /etc/nginx/sites-enabled/$site
done

sudo nginx -t && sudo systemctl reload nginx
```

## Configuration

### Configuration Files

**Proxy database:**
- Location: `/etc/nginx-proxy/proxies.json`
- Format: JSON
- Example: See `config/proxies.json.example`

**Nginx configurations:**
- Available: `/etc/nginx/sites-available/<domain>`
- Enabled: `/etc/nginx/sites-enabled/<domain>` (symlinks)

**Logs:**
- nginx-proxy: `/var/log/nginx-proxy.log`
- Per-domain access: `/var/log/nginx/<domain>-access.log`
- Per-domain errors: `/var/log/nginx/<domain>-error.log`

### Environment Variables

You can override default paths:

```bash
# Custom config directory
export CONFIG_DIR="/opt/nginx-proxy"
sudo nginx-proxy add myapp.com localhost:3000

# Custom Nginx directories
export NGINX_SITES_AVAILABLE="/custom/path/sites-available"
export NGINX_SITES_ENABLED="/custom/path/sites-enabled"
```

### Generated Nginx Configuration

Each proxy gets a configuration like this:

```nginx
server {
    listen 80;
    server_name myapp.example.com;

    access_log /var/log/nginx/myapp.example.com-access.log;
    error_log /var/log/nginx/myapp.example.com-error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

## Troubleshooting

### Common Issues

**1. "Configuration already exists for domain"**

A proxy for this domain already exists. Either:
- Remove it first: `sudo nginx-proxy remove domain.com`
- The script will ask if you want to overwrite

**2. "Nginx configuration test failed"**

The generated configuration has syntax errors. Check:

```bash
sudo nginx -t
```

Common causes:
- Invalid backend format
- Conflicting server names
- Manual configuration errors

**3. "Cannot enable SSL - Certbot not installed"**

Install Certbot:

```bash
sudo apt-get install certbot python3-certbot-nginx
```

**4. "SSL certificate request failed"**

Common causes:
- Domain doesn't point to your server
- Ports 80/443 not accessible from internet
- Firewall blocking traffic
- DNS not propagated yet

Verify DNS:
```bash
dig +short yourdomain.com
```

Check firewall:
```bash
sudo ufw status
```

**5. "502 Bad Gateway"**

The backend service is not responding. Check:
- Is the backend service running?
- Is it listening on the correct port?
- Can Nginx reach the backend?

```bash
# Check if service is listening
sudo netstat -tlnp | grep :3000

# Test backend locally
curl http://localhost:3000
```

**6. "Connection refused"**

The backend service is not running or not accessible. Verify:

```bash
# Check if port is open
sudo ss -tlnp | grep <port>

# For Docker containers, check container is running
docker ps

# Check if service is running
systemctl status <service-name>
```

### Debug Mode

To see detailed Nginx error logs:

```bash
# Watch Nginx error log in real-time
sudo tail -f /var/log/nginx/error.log

# Watch specific domain error log
sudo tail -f /var/log/nginx/myapp.example.com-error.log

# Check nginx-proxy operations
sudo tail -f /var/log/nginx-proxy.log
```

### Test Nginx Configuration

Always test before reloading:

```bash
sudo nginx -t
```

If the test fails, the reload won't happen and your existing configuration stays active.

### Reset Everything

If things get messy, you can reset:

```bash
# Remove all proxies (one by one)
nginx-proxy list  # Get list of domains
sudo nginx-proxy remove domain1.com
sudo nginx-proxy remove domain2.com

# Or manually clean up
sudo rm -f /etc/nginx/sites-available/*
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx-proxy/proxies.json
echo '{}' | sudo tee /etc/nginx-proxy/proxies.json

# Reload Nginx
sudo systemctl reload nginx
```

## Uninstallation

To remove nginx-proxy while keeping your proxy configurations:

```bash
cd apps/nginx-proxy
sudo bash uninstall.sh
```

When prompted, choose:
- **Y** to keep configurations (can reinstall later)
- **N** to remove everything

### Complete Removal

To remove everything including Nginx:

```bash
# Run uninstall script and choose N (remove all data)
sudo bash uninstall.sh

# Remove Nginx
sudo apt-get remove --purge nginx nginx-common
sudo apt-get autoremove

# Remove Certbot (if you don't need it)
sudo apt-get remove --purge certbot python3-certbot-nginx
```

## Security Considerations

### Default Security

The tool includes several security features by default:

✅ **Security Headers** - All proxies include:
- `X-Frame-Options: SAMEORIGIN` - Prevent clickjacking
- `X-Content-Type-Options: nosniff` - Prevent MIME sniffing
- `X-XSS-Protection: 1; mode=block` - XSS protection

✅ **Separate Logs** - Each domain gets its own access/error logs

✅ **Timeouts** - Reasonable timeout values to prevent hanging connections

### Best Practices

**1. Always Use HTTPS in Production**

```bash
sudo nginx-proxy enable-ssl yourdomain.com admin@example.com
```

**2. Firewall Configuration**

Allow only necessary ports:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**3. Restrict Access to Internal Services**

For services that should only be accessible from your network:

```nginx
# Edit /etc/nginx/sites-available/internal.local
location / {
    allow 192.168.1.0/24;  # Your local network
    deny all;

    proxy_pass http://localhost:3000;
    # ... rest of config
}
```

**4. Use Strong SSL Configuration**

After enabling SSL, consider:
- Using modern TLS versions only (1.2+)
- Strong cipher suites
- HSTS headers

**5. Regular Updates**

Keep Nginx and Certbot updated:

```bash
sudo apt-get update
sudo apt-get upgrade nginx certbot python3-certbot-nginx
```

**6. Monitor Logs**

Regularly check logs for suspicious activity:

```bash
sudo tail -f /var/log/nginx/*-access.log
```

### Sensitive Services

For services with sensitive data, consider:

1. **Additional authentication layer** (Nginx auth_basic or OAuth proxy)
2. **VPN access only** (WireGuard, Tailscale)
3. **IP whitelisting**
4. **Rate limiting**

## FAQ

**Q: Can I use this with Docker containers?**

A: Yes! Just proxy to the container's published port:

```bash
sudo nginx-proxy add app.com localhost:8080
```

**Q: Can I proxy to HTTPS backends?**

A: Currently, the script generates HTTP proxy configs. You can manually edit the config to use `https://` in the `proxy_pass` directive.

**Q: Does this work with Proxmox containers/VMs?**

A: Yes! Just use the container/VM IP:

```bash
sudo nginx-proxy add vm.local 192.168.1.100:80
```

**Q: Can I use wildcard domains?**

A: Yes, but you'll need to manually edit the Nginx config and use wildcard SSL certificates.

**Q: What about rate limiting?**

A: Not included by default. You can add rate limiting by editing the Nginx config manually.

**Q: Can I use this with Cloudflare?**

A: Yes! Just point your Cloudflare DNS to your server's IP. You can use either:
- Cloudflare SSL + this tool's Let's Encrypt
- Cloudflare SSL (Full/Strict mode)

## Contributing

Contributions are welcome! Please:

1. Test thoroughly on Ubuntu/Debian
2. Follow the existing code style
3. Update documentation
4. Add examples for new features

## License

MIT License - Use freely for personal or commercial projects

## Credits

Created as part of the [server-steups](https://github.com/arshshtty/server-steups) repository.

## Support

For issues, questions, or suggestions:
- Open an issue in the repository
- Check the troubleshooting section above
- Review Nginx error logs

---

**Version:** 1.0.0
**Last Updated:** 2025-01-15
