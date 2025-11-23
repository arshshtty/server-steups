# Nginx Reverse Proxy Manager - Quick Start Guide

Get up and running with Nginx reverse proxies in under 5 minutes!

## Installation (2 minutes)

```bash
cd apps/nginx-proxy
sudo bash setup.sh
```

Just answer "Y" when asked about Certbot (for SSL support), and you're done!

## Your First Proxy (30 seconds)

Let's say you have an app running on `localhost:3000` and want to expose it at `myapp.example.com`:

```bash
sudo nginx-proxy add myapp.example.com localhost:3000
```

Done! Visit `http://myapp.example.com` to see your app.

## Enable HTTPS (1 minute)

```bash
sudo nginx-proxy enable-ssl myapp.example.com admin@example.com
```

Your site is now secured with Let's Encrypt SSL! The certificate will auto-renew.

## Common Commands

```bash
# List all your proxies
nginx-proxy list

# Add a proxy with WebSocket support (for real-time apps)
sudo nginx-proxy add chat.example.com localhost:8080 --websocket

# Remove a proxy
sudo nginx-proxy remove myapp.example.com

# Temporarily disable a proxy
sudo nginx-proxy disable myapp.example.com

# Re-enable a disabled proxy
sudo nginx-proxy enable myapp.example.com

# Check Nginx status
nginx-proxy status

# Show all commands
nginx-proxy help
```

## Real-World Examples

### Self-Hosted Apps

```bash
# Nextcloud file sync
sudo nginx-proxy add cloud.mydomain.com localhost:8080
sudo nginx-proxy enable-ssl cloud.mydomain.com admin@mydomain.com

# Gitea git service
sudo nginx-proxy add git.mydomain.com localhost:3000
sudo nginx-proxy enable-ssl git.mydomain.com admin@mydomain.com

# n8n automation (needs WebSocket)
sudo nginx-proxy add workflows.mydomain.com localhost:5678 --websocket
sudo nginx-proxy enable-ssl workflows.mydomain.com admin@mydomain.com
```

### Homelab Services

```bash
# Proxmox on another machine
sudo nginx-proxy add proxmox.home.local 192.168.1.100:8006

# Home Assistant (needs WebSocket)
sudo nginx-proxy add ha.home.local 192.168.1.50:8123 --websocket

# Portainer Docker management
sudo nginx-proxy add portainer.home.local localhost:9000
```

### Docker Containers

```bash
# Portainer (published on port 9000)
sudo nginx-proxy add portainer.example.com localhost:9000

# Jellyfin media server (port 8096)
sudo nginx-proxy add media.example.com localhost:8096

# Uptime Kuma monitoring (port 3001, needs WebSocket)
sudo nginx-proxy add status.example.com localhost:3001 --websocket
```

## Prerequisites for SSL

Before running `enable-ssl`, make sure:

1. Your domain's DNS points to your server's IP
2. Ports 80 and 443 are open in your firewall
3. You have a valid email address

Check DNS:
```bash
dig +short yourdomain.com
# Should show your server's IP
```

Open firewall ports (if using UFW):
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Troubleshooting

**502 Bad Gateway?**
- Check if your backend service is running
- Verify the port number is correct

```bash
# Check if something is listening on port 3000
sudo netstat -tlnp | grep :3000
```

**SSL certificate failed?**
- Ensure DNS points to your server
- Check ports 80 and 443 are open
- Wait a few minutes for DNS propagation

**Need to see what's happening?**

```bash
# Watch nginx-proxy logs
sudo tail -f /var/log/nginx-proxy.log

# Watch Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Watch a specific domain's logs
sudo tail -f /var/log/nginx/myapp.example.com-error.log
```

## What Next?

- Read the full [README.md](README.md) for advanced features
- Check `/etc/nginx/sites-available/` to see generated configs
- Set up monitoring with `tail -f /var/log/nginx/*-access.log`
- Consider adding rate limiting or authentication for sensitive services

## Common Use Case: Docker Compose Stack

If you have multiple Docker services:

```yaml
# docker-compose.yml
services:
  app1:
    image: myapp1
    ports:
      - "3000:3000"

  app2:
    image: myapp2
    ports:
      - "3001:3000"

  app3:
    image: myapp3
    ports:
      - "3002:3000"
```

Set up proxies for all of them:

```bash
sudo nginx-proxy add app1.example.com localhost:3000
sudo nginx-proxy add app2.example.com localhost:3001
sudo nginx-proxy add app3.example.com localhost:3002

# Enable SSL for all
sudo nginx-proxy enable-ssl app1.example.com admin@example.com
sudo nginx-proxy enable-ssl app2.example.com admin@example.com
sudo nginx-proxy enable-ssl app3.example.com admin@example.com
```

## Tips

1. **Always test backend first** - Make sure your app works on `http://localhost:PORT` before adding the proxy

2. **DNS first, SSL second** - Point your DNS to the server, wait a few minutes, then run `enable-ssl`

3. **Use WebSocket flag for real-time apps** - If your app uses WebSockets (Socket.io, real-time updates), add `--websocket`

4. **Check logs when debugging** - The logs at `/var/log/nginx-proxy.log` show all operations

5. **List before remove** - Run `nginx-proxy list` to see all your proxies before removing one

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  Nginx Reverse Proxy Manager - Command Reference       │
├─────────────────────────────────────────────────────────┤
│  Add proxy:        sudo nginx-proxy add DOMAIN BACKEND │
│  Remove proxy:     sudo nginx-proxy remove DOMAIN      │
│  List proxies:     nginx-proxy list                    │
│  Enable SSL:       sudo nginx-proxy enable-ssl DOMAIN  │
│  Disable proxy:    sudo nginx-proxy disable DOMAIN     │
│  Enable proxy:     sudo nginx-proxy enable DOMAIN      │
│  Show status:      nginx-proxy status                  │
│  Test config:      nginx-proxy test                    │
│  Reload Nginx:     sudo nginx-proxy reload             │
│  Help:             nginx-proxy help                    │
└─────────────────────────────────────────────────────────┘

Examples:
  sudo nginx-proxy add app.com localhost:3000
  sudo nginx-proxy add api.com 192.168.1.100:8080 --websocket
  sudo nginx-proxy enable-ssl app.com admin@example.com
  nginx-proxy list
```

---

That's it! You now have a powerful reverse proxy manager at your fingertips. For more details, see [README.md](README.md).
