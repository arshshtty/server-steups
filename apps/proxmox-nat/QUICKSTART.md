# NAT Manager - Quick Start Guide

Get up and running with NAT Manager in 5 minutes!

## Installation (1 minute)

```bash
cd apps/proxmox-nat
sudo bash setup.sh
```

Follow the prompts and choose "yes" to start the web UI.

## Access Web Interface (30 seconds)

Open your browser and navigate to:

```
http://YOUR_SERVER_IP:8888
```

## Add Your First Container (2 minutes)

### Option 1: Using Web UI

1. Click **"Add Port Mapping"** button
2. Enter your container IP (e.g., `192.168.1.100`)
3. Select **"Automatic"** mode
4. Click **"Add Mapping"**

Done! You now have ports forwarded:
- `50000` → SSH (22)
- `50001` → HTTP (80)
- `50002` → HTTPS (443)
- `50003` → Alt HTTP (8080)
- Plus 2 additional ports

### Option 2: Using CLI

```bash
nat-manager add 192.168.1.100 --description "My first container"
```

## Connect to Your Container

```bash
# SSH to your container
ssh user@YOUR_SERVER_IP -p 50000

# Access web services
curl http://YOUR_SERVER_IP:50001
curl https://YOUR_SERVER_IP:50002
```

## Common Commands

```bash
# View all mappings
nat-manager list

# Remove a container's mappings
nat-manager remove 192.168.1.100

# Create a backup
nat-manager backup

# Reserve ports (so they won't be auto-assigned)
nat-manager reserve 22 80 443
```

## What's Next?

- Read the full [README.md](README.md) for advanced usage
- Explore the web interface features
- Set up automatic backups
- Configure firewall rules for the web UI

## Quick Tips

1. **First 4 ports are always**: SSH(22), HTTP(80), HTTPS(443), 8080
2. **Web UI is on port**: 8888
3. **Backups are saved in**: `/etc/nat_manager/backups/`
4. **View logs**: `tail -f /var/log/nat_manager.log`
5. **Restart web UI**: `systemctl restart nat-manager-web`

## Troubleshooting

### Can't access web UI?

```bash
systemctl status nat-manager-web
# If not running:
systemctl start nat-manager-web
```

### Port forwarding not working?

```bash
# Check if IP forwarding is enabled
sysctl net.ipv4.ip_forward

# Verify iptables rules
iptables -t nat -L PREROUTING -n -v
```

### Need help?

Check `/var/log/nat_manager.log` for detailed information.

---

**That's it!** You're now managing NAT port forwarding with a professional web interface. 🎉
