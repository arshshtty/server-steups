# Caddy Reverse Proxy - Quick Start Guide

Get Caddy up and running in 5 minutes or less!

## Prerequisites

- Ubuntu/Debian server
- Domain name pointing to your server
- Ports 80 and 443 open

## Step 1: Install (30 seconds)

```bash
cd apps/caddy-reverse-proxy
sudo bash setup.sh
```

Wait for installation to complete.

## Step 2: Configure (2 minutes)

Edit the Caddyfile:

```bash
sudo nano /etc/caddy/Caddyfile
```

### For a Single Service

Replace the contents with:

```
{
    email your-email@example.com
}

yourdomain.com {
    reverse_proxy localhost:8080
}
```

Replace:
- `your-email@example.com` with your email
- `yourdomain.com` with your domain
- `localhost:8080` with your service address

### For Multiple Services

```
{
    email your-email@example.com
}

app1.yourdomain.com {
    reverse_proxy localhost:3000
}

app2.yourdomain.com {
    reverse_proxy localhost:4000
}

app3.yourdomain.com {
    reverse_proxy localhost:5000
}
```

### For Docker Containers

```
{
    email your-email@example.com
}

app.yourdomain.com {
    reverse_proxy container-name:8080
}
```

## Step 3: Reload (10 seconds)

```bash
sudo systemctl reload caddy
```

## Step 4: Verify (1 minute)

1. Visit your domain: `https://yourdomain.com`
2. Check the SSL certificate (should show as valid)
3. Verify your service is accessible

## That's It!

Caddy has automatically:
- ✅ Obtained an SSL certificate from Let's Encrypt
- ✅ Configured HTTPS with HTTP/2
- ✅ Set up automatic certificate renewal
- ✅ Started proxying traffic to your service

## Common Commands

```bash
# Check status
sudo systemctl status caddy

# View logs
sudo journalctl -u caddy -f

# Reload after config changes
sudo systemctl reload caddy

# Validate configuration
caddy validate --config /etc/caddy/Caddyfile
```

## Need More?

- **Examples**: Check `/etc/caddy/*.example` files
- **Full Documentation**: See [README.md](README.md)
- **Troubleshooting**: See [README.md#troubleshooting](README.md#troubleshooting)

## Quick Examples

### Add Basic Auth

```bash
# Generate password hash
caddy hash-password

# Add to Caddyfile
admin.yourdomain.com {
    reverse_proxy localhost:8080

    basicauth {
        admin <paste-hash-here>
    }
}

# Reload
sudo systemctl reload caddy
```

### Add CORS Headers for API

```
api.yourdomain.com {
    reverse_proxy localhost:5000

    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE"
    }
}
```

### File Server with Browsing

```
files.yourdomain.com {
    root * /var/www/files
    file_server browse
}
```

### Redirect www to non-www

```
www.yourdomain.com {
    redir https://yourdomain.com{uri} permanent
}

yourdomain.com {
    reverse_proxy localhost:8080
}
```

## Troubleshooting Quick Fixes

### Certificate Not Working?

1. Verify DNS: `dig +short yourdomain.com`
2. Check ports: `sudo netstat -tulpn | grep -E ':(80|443)'`
3. Check logs: `sudo journalctl -u caddy -n 50`

### 502 Bad Gateway?

1. Is your service running? `curl localhost:8080`
2. Check the port number in Caddyfile
3. View Caddy logs: `sudo journalctl -u caddy -f`

### Configuration Errors?

```bash
# Validate before reloading
caddy validate --config /etc/caddy/Caddyfile

# Format Caddyfile
caddy fmt --overwrite /etc/caddy/Caddyfile
```

## Next Steps

1. **Secure your setup**: Add firewall rules
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **Set up monitoring**: Check logs regularly
   ```bash
   sudo journalctl -u caddy --since today
   ```

3. **Add more services**: Just add more blocks to Caddyfile

4. **Customize**: Check example files for advanced features

## Getting Help

- Read the [full README](README.md)
- Check [Caddy documentation](https://caddyserver.com/docs/)
- Visit [Caddy community forum](https://caddy.community/)

---

**Pro Tip**: Caddy automatically renews certificates 30 days before expiration. No cron jobs needed!
