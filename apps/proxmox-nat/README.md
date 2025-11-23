# NAT Manager for Proxmox

A comprehensive NAT port forwarding management tool for Proxmox servers with a single public IPv4 address. Features both a command-line interface and a modern web-based dashboard for easy management.

## Overview

When running Proxmox on a remote server with only one public IPv4 address, you need to set up NAT (Network Address Translation) to allow your VMs and containers to be accessible from the internet. This tool makes managing those port forwarding rules simple and intuitive.

### Features

- ✨ **Web-based Dashboard** - Modern, responsive UI for point-and-click management
- 🖥️ **CLI Interface** - Full command-line interface for automation and scripting
- 🔄 **Automatic Port Assignment** - Intelligently assigns ports starting from 50000
- 📊 **Real-time Statistics** - View all your mappings and statistics at a glance
- 💾 **Backup & Restore** - Create backups of your configuration
- 📤 **Import/Export** - Export configuration as JSON for migration
- 🔒 **Port Reservation** - Reserve ports for host services
- 🔍 **Database Rebuild** - Rebuild database from existing iptables rules
- 📝 **Logging** - Comprehensive logging for troubleshooting

### Default Port Mappings (Automatic Mode)

When you add a container in automatic mode, the first 4 ports are pre-configured:

| External Port | Internal Port | Protocol | Service |
|--------------|---------------|----------|---------|
| 50000        | 22            | TCP      | SSH     |
| 50001        | 80            | TCP      | HTTP    |
| 50002        | 443           | TCP      | HTTPS   |
| 50003        | 8080          | TCP      | Alt HTTP|
| 50004+       | Same as external | TCP   | Custom  |

## Installation

### Quick Install

```bash
# Clone the repository (or download the files)
cd apps/proxmox-nat

# Run the installation script
sudo bash setup.sh
```

The installation script will:
1. Install required dependencies (Python, Flask, iptables-persistent)
2. Copy files to `/opt/nat-manager`
3. Create configuration in `/etc/nat_manager`
4. Set up systemd services
5. Enable IP forwarding
6. Optionally start the web UI

### Manual Installation

If you prefer to install manually:

```bash
# Install dependencies
apt-get update
apt-get install -y python3 python3-pip python3-venv iptables iptables-persistent

# Create directories
mkdir -p /opt/nat-manager
mkdir -p /etc/nat_manager/backups
mkdir -p /etc/iptables

# Copy files
cp nat_manager.py /opt/nat-manager/
cp -r web /opt/nat-manager/
cp config/config.json.example /etc/nat_manager/config.json

# Setup Python environment
cd /opt/nat-manager
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create symlink
ln -s /opt/nat-manager/nat_manager.py /usr/local/bin/nat-manager

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
```

## Usage

### Web Interface

After installation, access the web interface at:

```
http://your-server-ip:8888
```

The web interface provides:
- **Dashboard** - Overview with statistics
- **Add Mapping** - Simple form to add new port mappings
- **View Mappings** - See all current mappings organized by container IP
- **Reserved Ports** - Manage reserved ports
- **Backup/Export** - Create backups and export configurations

#### Web UI Screenshots

The interface includes:
- Statistics cards showing total mappings, containers, protocols, and reserved ports
- Easy-to-use forms for adding mappings
- Tables displaying all current port forwarding rules
- One-click actions to remove mappings
- Modal dialogs for all operations

### Command Line Interface

#### Add Port Mappings

**Automatic mode** (recommended for most cases):

```bash
# Add with default 6 ports (SSH, HTTP, HTTPS, 8080, and 2 extras)
nat-manager add 192.168.1.100

# Add with description
nat-manager add 192.168.1.100 --description "Production web server"

# Add with custom number of ports
nat-manager add 192.168.1.100 --num-ports 8
```

**Manual mode** (for custom configurations):

```bash
# Specify exact ports and protocols
nat-manager add 192.168.1.100 \
  --mode manual \
  --internal-ports 22 80 443 3306 \
  --protocols tcp tcp tcp tcp \
  --description "Web + Database server"
```

#### List Port Mappings

```bash
# List all mappings
nat-manager list

# List mappings for specific container
nat-manager list 192.168.1.100
```

Example output:
```
192.168.1.100:
  50000/tcp -> 22
  50001/tcp -> 80
  50002/tcp -> 443
  50003/tcp -> 8080

192.168.1.101:
  50006/tcp -> 22
  50007/tcp -> 3000
```

#### Remove Port Mappings

```bash
# Remove all mappings for a container
nat-manager remove 192.168.1.100
```

#### Reserve Ports

Reserve ports so they won't be auto-assigned to containers:

```bash
# Reserve ports for host services
nat-manager reserve 22 80 443 --description "Host services"

# List reserved ports
nat-manager list-reserved

# Unreserve ports
nat-manager unreserve 22 80 443
```

#### Backup & Restore

```bash
# Create a backup
nat-manager backup
# Output: ✓ Created backup: 20250123_143022

# Restore from backup
nat-manager restore 20250123_143022
```

Backups are stored in `/etc/nat_manager/backups/`

#### Import & Export

```bash
# Export to JSON
nat-manager export /tmp/nat-config.json

# Import from JSON
nat-manager import /tmp/nat-config.json
```

#### Rebuild Database

If you've manually added iptables rules or the database is out of sync:

```bash
nat-manager rebuild-db
```

This scans your current iptables rules and rebuilds the database accordingly.

## Configuration

Configuration file: `/etc/nat_manager/config.json`

```json
{
  "port_start": 50000,
  "db_file": "/etc/nat_manager/port_mappings.db",
  "network_interface": "vmbr0",
  "backup_dir": "/etc/nat_manager/backups",
  "log_file": "/var/log/nat_manager.log",
  "log_level": "INFO"
}
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `port_start` | Starting port for auto-assignment | 50000 |
| `db_file` | SQLite database path | `/etc/nat_manager/port_mappings.db` |
| `network_interface` | Network interface for iptables rules | `vmbr0` |
| `backup_dir` | Directory for backups | `/etc/nat_manager/backups` |
| `log_file` | Log file path | `/var/log/nat_manager.log` |
| `log_level` | Logging level (DEBUG, INFO, WARNING, ERROR) | `INFO` |

**Important**: If your Proxmox uses a different bridge interface (e.g., `vmbr1`), update the `network_interface` setting.

## Service Management

### Web UI Service

```bash
# Start the web UI
systemctl start nat-manager-web

# Stop the web UI
systemctl stop nat-manager-web

# Restart the web UI
systemctl restart nat-manager-web

# Check status
systemctl status nat-manager-web

# View logs
journalctl -u nat-manager-web -f
```

### Auto-restore Service

The `nat-manager-restore` service automatically restores iptables rules on boot:

```bash
# Check status
systemctl status nat-manager-restore

# Manually trigger restore
systemctl start nat-manager-restore
```

## How It Works

### Architecture

1. **SQLite Database**: Stores all port mapping configurations
2. **iptables NAT Rules**: Actual port forwarding using Linux netfilter
3. **Flask Web App**: Provides the web interface
4. **Python CLI**: Command-line management tool

### NAT Rule Example

When you add a mapping for container `192.168.1.100`, the tool creates iptables rules like:

```bash
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 50000 \
  -j DNAT --to-destination 192.168.1.100:22
```

This redirects traffic from public port 50000 to the container's port 22.

### Data Flow

```
Internet
    ↓
[Public IP:50000]
    ↓
iptables NAT (vmbr0)
    ↓
[192.168.1.100:22] (Container)
```

## Common Use Cases

### Web Server Container

```bash
# Add container with web services
nat-manager add 192.168.1.100 --description "Nginx web server"

# Access via:
# - SSH: your-ip:50000
# - HTTP: your-ip:50001
# - HTTPS: your-ip:50002
```

### Development Environment

```bash
# Add container with custom ports for development
nat-manager add 192.168.1.101 \
  --mode manual \
  --internal-ports 22 3000 5432 6379 \
  --protocols tcp tcp tcp tcp \
  --description "Dev environment (Node.js + PostgreSQL + Redis)"
```

### Database Server

```bash
# Add with just SSH and database port
nat-manager add 192.168.1.102 \
  --mode manual \
  --internal-ports 22 3306 \
  --protocols tcp tcp \
  --description "MySQL database"
```

## Troubleshooting

### Port mappings not working

1. **Check iptables rules**:
   ```bash
   iptables -t nat -L PREROUTING -n -v
   ```

2. **Verify IP forwarding is enabled**:
   ```bash
   sysctl net.ipv4.ip_forward
   # Should return: net.ipv4.ip_forward = 1
   ```

3. **Check if port is in use**:
   ```bash
   ss -tulpn | grep :50000
   ```

4. **Verify container firewall**:
   Make sure the container's firewall allows incoming connections.

### Web UI not accessible

1. **Check service status**:
   ```bash
   systemctl status nat-manager-web
   ```

2. **Check if port 8888 is open**:
   ```bash
   ss -tulpn | grep :8888
   ```

3. **View logs**:
   ```bash
   tail -f /var/log/nat_manager.log
   journalctl -u nat-manager-web -f
   ```

### Database out of sync

If you've manually modified iptables rules:

```bash
nat-manager rebuild-db
```

### Rules not persisting after reboot

1. **Check iptables-persistent**:
   ```bash
   systemctl status netfilter-persistent
   ```

2. **Manually save rules**:
   ```bash
   iptables-save > /etc/iptables/rules.v4
   ```

3. **Verify restore service**:
   ```bash
   systemctl enable nat-manager-restore
   systemctl status nat-manager-restore
   ```

## Security Considerations

### For Single-User Environments

Since you mentioned this is for personal use, the default configuration is simplified:

- Web UI runs on port 8888 (accessible to local network)
- No authentication on web interface
- Root access required (necessary for iptables management)

### Recommended Security Practices

Even for personal use, consider:

1. **Firewall the Web UI**: Only allow access from your IP
   ```bash
   ufw allow from YOUR_IP to any port 8888
   ```

2. **Use SSH tunneling** for web access:
   ```bash
   ssh -L 8888:localhost:8888 root@your-server
   # Then access http://localhost:8888
   ```

3. **Regular backups**:
   ```bash
   # Add to crontab
   0 2 * * * /usr/local/bin/nat-manager backup
   ```

4. **Monitor logs**:
   ```bash
   tail -f /var/log/nat_manager.log
   ```

## Uninstallation

```bash
cd /opt/nat-manager
bash uninstall.sh
```

The uninstall script will:
- Stop and remove systemd services
- Remove installation files
- Optionally keep or remove configuration and database
- Preserve iptables rules (you must manually remove if needed)

To remove all NAT rules after uninstallation:

```bash
iptables -t nat -F PREROUTING
iptables-save > /etc/iptables/rules.v4
```

## File Locations

| Path | Description |
|------|-------------|
| `/opt/nat-manager/` | Installation directory |
| `/etc/nat_manager/config.json` | Configuration file |
| `/etc/nat_manager/port_mappings.db` | SQLite database |
| `/etc/nat_manager/backups/` | Backup directory |
| `/var/log/nat_manager.log` | Log file |
| `/etc/iptables/rules.v4` | iptables rules (persistent) |
| `/usr/local/bin/nat-manager` | CLI symlink |

## Advanced Usage

### Custom External Ports

```bash
nat-manager add 192.168.1.100 \
  --mode manual \
  --internal-ports 22 80 \
  --external-ports 2222 8080 \
  --protocols tcp tcp
```

### Temporary Rules (not saved to database)

```bash
nat-manager add 192.168.1.100 --temporary
```

Temporary rules are removed when iptables is reloaded.

### Using a Different Network Interface

If your Proxmox uses `vmbr1` instead of `vmbr0`:

1. Edit `/etc/nat_manager/config.json`:
   ```json
   {
     "network_interface": "vmbr1"
   }
   ```

2. Restart the web service:
   ```bash
   systemctl restart nat-manager-web
   ```

## Contributing

Contributions are welcome! This tool is part of a larger server setup repository.

## Credits

- Original concept from the [LowEndTalk discussion](https://lowendtalk.com/discussion/197821/nat-manager-py-manage-nat-port-forwarding-for-proxmox-vms-and-containers)
- Enhanced with web UI and improved features for ease of use

## License

MIT License - See repository root for details

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `/var/log/nat_manager.log`
3. Open an issue in the repository

---

**Note**: This tool manages iptables rules. Always test in a non-production environment first and maintain backups of your configuration.
