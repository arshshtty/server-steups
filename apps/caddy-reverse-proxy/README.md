# Caddy Reverse Proxy

A dead simple yet effective Caddy reverse proxy setup for self-hosted applications and services.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Common Use Cases](#common-use-cases)
- [Example Configurations](#example-configurations)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Uninstallation](#uninstallation)

## Overview

Caddy is a powerful, enterprise-ready web server with automatic HTTPS. This setup provides:

- **Automatic HTTPS**: Free TLS certificates from Let's Encrypt with automatic renewal
- **Dead Simple Config**: Human-readable Caddyfile syntax
- **Reverse Proxy**: Route traffic to your applications and services
- **Docker Support**: Easy integration with Docker containers
- **WebSocket Support**: Built-in support for real-time applications
- **Zero Downtime**: Graceful configuration reloads

## Features

- ✅ One-command installation
- ✅ Automatic HTTPS with Let's Encrypt
- ✅ HTTP/2 and HTTP/3 support
- ✅ Reverse proxy to local services
- ✅ Docker container integration
- ✅ WebSocket support
- ✅ Load balancing
- ✅ File server capabilities
- ✅ Custom headers and security
- ✅ Path-based routing
- ✅ Basic authentication
- ✅ Comprehensive example configurations

## Quick Start

### Installation

```bash
cd apps/caddy-reverse-proxy
sudo bash setup.sh
```

### Basic Configuration

1. Edit the Caddyfile:
   ```bash
   sudo nano /etc/caddy/Caddyfile
   ```

2. Add your domain and backend service:
   ```
   example.com {
       reverse_proxy localhost:8080
   }
   ```

3. Reload Caddy:
   ```bash
   sudo systemctl reload caddy
   ```

That's it! Caddy will automatically obtain an SSL certificate and start proxying traffic.

## Installation

### Prerequisites

- Ubuntu 20.04+ or Debian 10+
- Root/sudo access
- Domain name pointing to your server (for automatic HTTPS)
- Firewall configured to allow ports 80 and 443

### Install Script

The installation script will:

1. Install Caddy from official repository
2. Set up configuration directory
3. Create example Caddyfiles
4. Enable and start Caddy service

```bash
cd apps/caddy-reverse-proxy
sudo bash setup.sh
```

### Manual Installation

If you prefer manual installation:

```bash
# Install dependencies
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl

# Add Caddy repository
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
    sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
    sudo tee /etc/apt/sources.list.d/caddy-stable.list

# Install Caddy
sudo apt update
sudo apt install caddy

# Enable and start service
sudo systemctl enable --now caddy
```

## Configuration

### Caddyfile Location

The main configuration file is located at:
```
/etc/caddy/Caddyfile
```

### Basic Syntax

```
domain.com {
    reverse_proxy localhost:8080
}
```

### Global Options

Add global configuration at the top of the Caddyfile:

```
{
    # Email for Let's Encrypt notifications
    email your-email@example.com

    # Custom ACME server (optional)
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory

    # Admin API endpoint
    admin off  # Disable admin API
}
```

### Multiple Sites

```
site1.com {
    reverse_proxy localhost:3000
}

site2.com {
    reverse_proxy localhost:4000
}

site3.com {
    reverse_proxy localhost:5000
}
```

## Common Use Cases

### 1. Simple Reverse Proxy

Proxy a domain to a local service:

```
example.com {
    reverse_proxy localhost:8080
}
```

### 2. Docker Containers

Proxy to Docker container by name (requires same network):

```
app.example.com {
    reverse_proxy my-container:3000
}
```

### 3. Multiple Services with Subdomains

```
example.com {
    reverse_proxy localhost:3000
}

blog.example.com {
    reverse_proxy localhost:4000
}

api.example.com {
    reverse_proxy localhost:5000
}
```

### 4. Path-Based Routing

Route different paths to different services:

```
example.com {
    handle /api/* {
        reverse_proxy localhost:5000
    }

    handle /admin/* {
        reverse_proxy localhost:6000
    }

    handle {
        reverse_proxy localhost:3000
    }
}
```

### 5. WebSocket Support

WebSocket support is automatic - no special configuration needed:

```
ws.example.com {
    reverse_proxy localhost:8080
}
```

### 6. Load Balancing

Distribute traffic across multiple backends:

```
example.com {
    reverse_proxy localhost:8001 localhost:8002 localhost:8003 {
        lb_policy round_robin
        health_uri /health
        health_interval 10s
    }
}
```

### 7. File Server

Serve static files with directory browsing:

```
files.example.com {
    root * /var/www/files
    file_server browse
}
```

### 8. Basic Authentication

Protect a site with username/password:

```
admin.example.com {
    reverse_proxy localhost:8080

    basicauth {
        # Generate with: caddy hash-password
        admin $2a$14$Zkx19XLiW6VYouLHR5NmfOFU0z2GTNmpkT/5qqR7hx4IjWJPDhjvG
    }
}
```

Generate a password hash:
```bash
caddy hash-password
```

### 9. IP Restriction

Allow access only from specific IPs:

```
admin.example.com {
    @allowed {
        remote_ip 192.168.1.0/24 10.0.0.0/8
    }

    handle @allowed {
        reverse_proxy localhost:6000
    }

    handle {
        abort
    }
}
```

### 10. Custom Headers

Add security headers:

```
example.com {
    reverse_proxy localhost:8080

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        -Server  # Remove server header
    }
}
```

## Example Configurations

Pre-configured example files are available in `/etc/caddy/` after installation:

- **basic-reverse-proxy.example** - Simple reverse proxy setup
- **docker-services.example** - Docker container integration
- **multiple-services.example** - Multiple services with subdomains
- **websocket-support.example** - WebSocket applications
- **file-server.example** - Static file serving
- **advanced-features.example** - Load balancing, custom headers, logging
- **self-hosted-apps.example** - Popular self-hosted applications

Copy and modify these examples:

```bash
# View an example
cat /etc/caddy/docker-services.example

# Copy to your Caddyfile
sudo cp /etc/caddy/docker-services.example /etc/caddy/Caddyfile

# Edit and customize
sudo nano /etc/caddy/Caddyfile

# Reload Caddy
sudo systemctl reload caddy
```

## Management

### Service Management

```bash
# Check status
sudo systemctl status caddy

# Start service
sudo systemctl start caddy

# Stop service
sudo systemctl stop caddy

# Restart service
sudo systemctl restart caddy

# Reload configuration (zero downtime)
sudo systemctl reload caddy

# Enable on boot
sudo systemctl enable caddy
```

### View Logs

```bash
# Follow logs in real-time
sudo journalctl -u caddy -f

# View last 50 lines
sudo journalctl -u caddy -n 50

# View logs since today
sudo journalctl -u caddy --since today

# View errors only
sudo journalctl -u caddy -p err
```

### Validate Configuration

Before reloading, validate your Caddyfile:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

### Format Caddyfile

Auto-format your Caddyfile:

```bash
caddy fmt --overwrite /etc/caddy/Caddyfile
```

### Manual Reload

Reload configuration without systemd:

```bash
caddy reload --config /etc/caddy/Caddyfile
```

### View Current Configuration

```bash
# Using curl (if admin API is enabled)
curl localhost:2019/config/

# Read the file
cat /etc/caddy/Caddyfile
```

## Troubleshooting

### Caddy Won't Start

1. Check logs:
   ```bash
   sudo journalctl -u caddy -n 50
   ```

2. Validate configuration:
   ```bash
   caddy validate --config /etc/caddy/Caddyfile
   ```

3. Check port availability:
   ```bash
   sudo netstat -tulpn | grep -E ':(80|443)'
   ```

### Certificate Issues

1. Check if ports 80 and 443 are open:
   ```bash
   sudo ufw status
   ```

2. Verify DNS points to your server:
   ```bash
   dig +short example.com
   ```

3. Check Let's Encrypt rate limits (50 certs per domain per week)

4. Use staging environment for testing:
   ```
   {
       acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
   }
   ```

### Proxy Not Working

1. Verify backend service is running:
   ```bash
   curl localhost:8080
   ```

2. Check Caddy logs for errors:
   ```bash
   sudo journalctl -u caddy -f
   ```

3. Verify reverse_proxy syntax:
   ```
   example.com {
       reverse_proxy localhost:8080
   }
   ```

### Connection Reset / 502 Bad Gateway

- Backend service is not running
- Wrong port number in reverse_proxy
- Firewall blocking internal connections
- SELinux restrictions (check with `sudo ausearch -m avc -ts recent`)

### Domain Not Resolving

1. Check DNS:
   ```bash
   nslookup example.com
   dig example.com
   ```

2. Verify A record points to server IP

3. Wait for DNS propagation (can take up to 48 hours)

### Testing Configuration

Test configuration without applying:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

### Enable Debug Logging

Add to Caddyfile:

```
{
    debug
}
```

Then reload and check logs.

## Security

### Best Practices

1. **Always use HTTPS**: Caddy handles this automatically
2. **Keep Caddy updated**: `sudo apt update && sudo apt upgrade caddy`
3. **Use strong passwords**: Generate with `caddy hash-password`
4. **Restrict admin access**: Use IP restrictions for sensitive endpoints
5. **Add security headers**: See example configurations
6. **Monitor logs**: Regularly check for suspicious activity
7. **Firewall**: Only allow ports 80, 443, and SSH

### Firewall Configuration

```bash
# UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### Security Headers

Add to your Caddyfile:

```
example.com {
    reverse_proxy localhost:8080

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
}
```

### Rate Limiting

Protect against abuse (requires plugin):

```bash
caddy add-package github.com/mholt/caddy-ratelimit
```

### Disable Admin API

Add to global options:

```
{
    admin off
}
```

## Uninstallation

To remove Caddy:

```bash
cd apps/caddy-reverse-proxy
sudo bash uninstall.sh
```

Or manually:

```bash
# Stop and disable service
sudo systemctl stop caddy
sudo systemctl disable caddy

# Remove package
sudo apt remove --purge caddy

# Remove configuration (optional)
sudo rm -rf /etc/caddy

# Remove data directory (optional)
sudo rm -rf /var/lib/caddy

# Remove repository
sudo rm /etc/apt/sources.list.d/caddy-stable.list
sudo rm /usr/share/keyrings/caddy-stable-archive-keyring.gpg
```

## Additional Resources

- [Official Caddy Documentation](https://caddyserver.com/docs/)
- [Caddyfile Syntax](https://caddyserver.com/docs/caddyfile)
- [Caddy Community Forum](https://caddy.community/)
- [Caddy GitHub Repository](https://github.com/caddyserver/caddy)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## Tips and Tricks

### Redirect www to non-www

```
www.example.com {
    redir https://example.com{uri} permanent
}

example.com {
    reverse_proxy localhost:8080
}
```

### Serve Multiple Domains from Same Backend

```
example.com, www.example.com, example.net {
    reverse_proxy localhost:8080
}
```

### Custom Error Pages

```
example.com {
    reverse_proxy localhost:8080

    handle_errors {
        rewrite * /{err.status_code}.html
        file_server {
            root /var/www/error-pages
        }
    }
}
```

### Logging to File

```
{
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
        }
        format json
    }
}
```

### Maintenance Mode

```
example.com {
    respond "Site under maintenance. Back soon!" 503
}
```

Or serve a static page:

```
example.com {
    root * /var/www/maintenance
    file_server
}
```

### Testing with Localhost

Test configuration locally before going live:

```
:8080 {
    reverse_proxy localhost:3000
}
```

Access at `http://localhost:8080`

## Version History

- **1.0.0** (2025-01-23)
  - Initial release
  - Automated installation script
  - Comprehensive example configurations
  - Full documentation

## License

MIT License - Use freely for personal or commercial projects.

## Support

For issues and questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review [example configurations](#example-configurations)
- Consult [Caddy documentation](https://caddyserver.com/docs/)
- Visit [Caddy community forum](https://caddy.community/)
