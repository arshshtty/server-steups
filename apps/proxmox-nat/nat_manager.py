#!/usr/bin/env python3
"""
nat_manager.py - NAT Port Forwarding Manager for Proxmox

Enhanced version with configuration file support, better logging, and web API integration.
"""

import sys
import sqlite3
import subprocess
import os
import re
import shutil
import argparse
import json
import logging
from datetime import datetime
from pathlib import Path

# Default configuration - can be overridden by config file
DEFAULT_CONFIG = {
    'port_start': 50000,
    'db_file': '/etc/nat_manager/port_mappings.db',
    'network_interface': 'vmbr0',
    'backup_dir': '/etc/nat_manager/backups',
    'log_file': '/var/log/nat_manager.log',
    'log_level': 'INFO'
}

class NATManager:
    def __init__(self, config_file=None):
        """Initialize NAT Manager with configuration"""
        self.config = DEFAULT_CONFIG.copy()

        # Load configuration file if provided
        if config_file and os.path.exists(config_file):
            with open(config_file, 'r') as f:
                user_config = json.load(f)
                self.config.update(user_config)

        # Setup logging
        self.setup_logging()

        # Ensure directories exist
        self.ensure_directories()

        # Initialize database
        self.conn = self.init_db()
        self.cursor = self.conn.cursor()

    def setup_logging(self):
        """Configure logging"""
        log_dir = os.path.dirname(self.config['log_file'])
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir, exist_ok=True)

        logging.basicConfig(
            level=getattr(logging, self.config['log_level']),
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.config['log_file']),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def ensure_directories(self):
        """Ensure required directories exist"""
        for key in ['db_file', 'backup_dir']:
            path = self.config[key]
            directory = os.path.dirname(path) if key == 'db_file' else path
            if directory and not os.path.exists(directory):
                os.makedirs(directory, exist_ok=True)
                self.logger.info(f"Created directory: {directory}")

    def init_db(self):
        """Initialize SQLite database"""
        conn = sqlite3.connect(self.config['db_file'])
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS port_mappings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                container_ip TEXT NOT NULL,
                external_port INTEGER NOT NULL,
                internal_port INTEGER NOT NULL,
                protocol TEXT NOT NULL DEFAULT 'tcp',
                temporary INTEGER NOT NULL DEFAULT 0,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS reserved_ports (
                port INTEGER PRIMARY KEY,
                description TEXT
            )
        ''')
        conn.commit()
        return conn

    def check_iptables_persistent(self):
        """Check if iptables-persistent is installed and enabled"""
        iptables_persistent_installed = False
        try:
            result = subprocess.run(
                ['dpkg-query', '-W', '-f=${Status}', 'iptables-persistent'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            if 'install ok installed' in result.stdout:
                iptables_persistent_installed = True
        except Exception:
            pass

        netfilter_service_enabled = False
        try:
            result = subprocess.run(
                ['systemctl', 'is-enabled', 'netfilter-persistent'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            if 'enabled' in result.stdout.strip():
                netfilter_service_enabled = True
        except Exception:
            pass

        if not iptables_persistent_installed:
            self.logger.warning("iptables-persistent is not installed. Rules may not persist after reboot.")
        elif not netfilter_service_enabled:
            self.logger.warning("netfilter-persistent service is not enabled. Rules may not persist after reboot.")

        return iptables_persistent_installed and netfilter_service_enabled

    def validate_ip(self, ip):
        """Validate IP address format"""
        pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
        if not pattern.match(ip):
            return False
        # Check each octet is 0-255
        octets = ip.split('.')
        return all(0 <= int(octet) <= 255 for octet in octets)

    def is_port_in_use(self, port):
        """Check if port is in use on the system"""
        result = subprocess.run(
            ['ss', '-tulpn'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        return f":{port} " in result.stdout or f":{port}\n" in result.stdout

    def assign_ports(self, num_ports):
        """Automatically assign available ports"""
        self.cursor.execute('SELECT external_port FROM port_mappings')
        assigned_ports = [row[0] for row in self.cursor.fetchall()]
        self.cursor.execute('SELECT port FROM reserved_ports')
        reserved_ports = [row[0] for row in self.cursor.fetchall()]

        next_port = self.config['port_start']
        while True:
            conflict = False
            for i in range(num_ports):
                port = next_port + i
                if port in assigned_ports or self.is_port_in_use(port) or port in reserved_ports:
                    conflict = True
                    break
            if not conflict:
                break
            else:
                next_port += num_ports

        return [next_port + i for i in range(num_ports)]

    def iptables_rule_exists(self, protocol, external_port, container_ip, internal_port):
        """Check if an iptables rule exists"""
        cmd = [
            'iptables', '-t', 'nat', '-C', 'PREROUTING',
            '-i', self.config['network_interface'],
            '-p', protocol, '--dport', str(external_port),
            '-j', 'DNAT', '--to-destination', f'{container_ip}:{internal_port}'
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.returncode == 0

    def setup_iptables_rules(self, container_ip, external_ports, internal_ports, protocols, save_rules=True):
        """Set up iptables NAT rules"""
        for external_port, internal_port, protocol in zip(external_ports, internal_ports, protocols):
            if not self.iptables_rule_exists(protocol, external_port, container_ip, internal_port):
                cmd = [
                    'iptables', '-t', 'nat', '-A', 'PREROUTING',
                    '-i', self.config['network_interface'],
                    '-p', protocol, '--dport', str(external_port),
                    '-j', 'DNAT', '--to-destination', f'{container_ip}:{internal_port}'
                ]
                subprocess.run(cmd, check=True)
                self.logger.info(f"Added iptables rule: {external_port}/{protocol} -> {container_ip}:{internal_port}")
            else:
                self.logger.info(f"Iptables rule already exists: {external_port}/{protocol}")

        # Enable IP forwarding
        subprocess.run(['sysctl', '-w', 'net.ipv4.ip_forward=1'], check=True)

        if save_rules:
            self.save_iptables_rules()

    def remove_iptables_rules(self, container_ip, external_ports, internal_ports, protocols, save_rules=True):
        """Remove iptables NAT rules"""
        for external_port, internal_port, protocol in zip(external_ports, internal_ports, protocols):
            cmd = [
                'iptables', '-t', 'nat', '-D', 'PREROUTING',
                '-i', self.config['network_interface'],
                '-p', protocol, '--dport', str(external_port),
                '-j', 'DNAT', '--to-destination', f'{container_ip}:{internal_port}'
            ]
            try:
                subprocess.run(cmd, check=True)
                self.logger.info(f"Removed iptables rule: {external_port}/{protocol}")
            except subprocess.CalledProcessError:
                self.logger.warning(f"Failed to remove rule (may not exist): {external_port}/{protocol}")

        if save_rules:
            self.save_iptables_rules()

    def save_iptables_rules(self):
        """Save iptables rules to persistent storage"""
        rules_file = '/etc/iptables/rules.v4'
        rules_dir = os.path.dirname(rules_file)

        if not os.path.exists(rules_dir):
            os.makedirs(rules_dir, exist_ok=True)

        try:
            result = subprocess.run(['iptables-save'], stdout=subprocess.PIPE, check=True)
            with open(rules_file, 'wb') as f:
                f.write(result.stdout)
            self.logger.info("Saved iptables rules")
        except Exception as e:
            self.logger.error(f"Failed to save iptables rules: {e}")

    def add_container(self, container_ip, mode='automatic', num_ports=6,
                     internal_ports=None, external_ports=None, protocols=None,
                     temporary=False, description=None):
        """Add port mappings for a container"""
        if not self.validate_ip(container_ip):
            raise ValueError(f"Invalid IP address: {container_ip}")

        # Check if IP already has mappings
        self.cursor.execute('SELECT COUNT(*) FROM port_mappings WHERE container_ip = ?', (container_ip,))
        if self.cursor.fetchone()[0] > 0:
            raise ValueError(f"IP {container_ip} already has port mappings")

        # Determine ports
        if external_ports:
            assigned_ports = external_ports
            num_ports = len(assigned_ports)
        else:
            assigned_ports = self.assign_ports(num_ports)

        # Determine internal ports and protocols
        if mode == 'automatic':
            INTERNAL_PORTS_DEFAULT = [22, 80, 443, 8080]
            PROTOCOLS_DEFAULT = ['tcp', 'tcp', 'tcp', 'tcp']
            internal_ports = []
            protocols_list = []
            for i in range(num_ports):
                if i < len(INTERNAL_PORTS_DEFAULT):
                    internal_ports.append(INTERNAL_PORTS_DEFAULT[i])
                    protocols_list.append(PROTOCOLS_DEFAULT[i])
                else:
                    internal_ports.append(assigned_ports[i])
                    protocols_list.append('tcp')
        elif mode == 'manual':
            if not internal_ports:
                raise ValueError("Internal ports required in manual mode")
            if len(internal_ports) != num_ports:
                raise ValueError("Number of internal ports doesn't match num_ports")
            protocols_list = protocols if protocols else ['tcp'] * num_ports
        else:
            raise ValueError(f"Invalid mode: {mode}")

        # Setup iptables rules
        save_rules = not temporary
        self.setup_iptables_rules(container_ip, assigned_ports, internal_ports, protocols_list, save_rules)

        # Save to database (unless temporary)
        if not temporary:
            for ext_port, int_port, proto in zip(assigned_ports, internal_ports, protocols_list):
                self.cursor.execute('''
                    INSERT INTO port_mappings
                    (container_ip, external_port, internal_port, protocol, description)
                    VALUES (?, ?, ?, ?, ?)
                ''', (container_ip, ext_port, int_port, proto, description))
            self.conn.commit()
            self.logger.info(f"Added port mappings for {container_ip}")

        return list(zip(assigned_ports, internal_ports, protocols_list))

    def remove_container(self, container_ip):
        """Remove all port mappings for a container"""
        self.cursor.execute(
            'SELECT external_port, internal_port, protocol FROM port_mappings WHERE container_ip = ?',
            (container_ip,)
        )
        mappings = self.cursor.fetchall()

        if not mappings:
            raise ValueError(f"No port mappings found for {container_ip}")

        external_ports = [m[0] for m in mappings]
        internal_ports = [m[1] for m in mappings]
        protocols = [m[2] for m in mappings]

        self.remove_iptables_rules(container_ip, external_ports, internal_ports, protocols)

        self.cursor.execute('DELETE FROM port_mappings WHERE container_ip = ?', (container_ip,))
        self.conn.commit()
        self.logger.info(f"Removed all port mappings for {container_ip}")

        return len(mappings)

    def list_mappings(self, container_ip=None):
        """List port mappings"""
        if container_ip:
            self.cursor.execute('''
                SELECT external_port, internal_port, protocol, temporary, description, created_at
                FROM port_mappings WHERE container_ip = ?
                ORDER BY external_port
            ''', (container_ip,))
            return [(container_ip, *row) for row in self.cursor.fetchall()]
        else:
            self.cursor.execute('''
                SELECT container_ip, external_port, internal_port, protocol, temporary, description, created_at
                FROM port_mappings
                ORDER BY container_ip, external_port
            ''')
            return self.cursor.fetchall()

    def get_all_mappings_dict(self):
        """Get all mappings as a dictionary (for web UI)"""
        mappings = self.list_mappings()
        result = {}
        for mapping in mappings:
            ip = mapping[0]
            if ip not in result:
                result[ip] = []
            result[ip].append({
                'external_port': mapping[1],
                'internal_port': mapping[2],
                'protocol': mapping[3],
                'temporary': bool(mapping[4]),
                'description': mapping[5],
                'created_at': mapping[6]
            })
        return result

    def reserve_ports(self, ports, description=None):
        """Reserve ports for host use"""
        for port in ports:
            self.cursor.execute(
                'INSERT OR IGNORE INTO reserved_ports (port, description) VALUES (?, ?)',
                (port, description)
            )
        self.conn.commit()
        self.logger.info(f"Reserved ports: {ports}")

    def unreserve_ports(self, ports):
        """Unreserve ports"""
        for port in ports:
            self.cursor.execute('DELETE FROM reserved_ports WHERE port = ?', (port,))
        self.conn.commit()
        self.logger.info(f"Unreserved ports: {ports}")

    def list_reserved_ports(self):
        """List reserved ports"""
        self.cursor.execute('SELECT port, description FROM reserved_ports ORDER BY port')
        return self.cursor.fetchall()

    def export_mappings(self, file_path):
        """Export port mappings to JSON file"""
        mappings = self.list_mappings()
        data = [{
            'container_ip': m[0],
            'external_port': m[1],
            'internal_port': m[2],
            'protocol': m[3],
            'description': m[5]
        } for m in mappings]

        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
        self.logger.info(f"Exported mappings to {file_path}")

    def import_mappings(self, file_path):
        """Import port mappings from JSON file"""
        with open(file_path, 'r') as f:
            data = json.load(f)

        imported = 0
        for entry in data:
            container_ip = entry['container_ip']
            external_port = entry['external_port']
            internal_port = entry['internal_port']
            protocol = entry.get('protocol', 'tcp')
            description = entry.get('description')

            # Check if mapping already exists
            self.cursor.execute(
                'SELECT COUNT(*) FROM port_mappings WHERE container_ip = ? AND external_port = ?',
                (container_ip, external_port)
            )
            if self.cursor.fetchone()[0] == 0:
                self.setup_iptables_rules(container_ip, [external_port], [internal_port], [protocol])
                self.cursor.execute('''
                    INSERT INTO port_mappings
                    (container_ip, external_port, internal_port, protocol, description)
                    VALUES (?, ?, ?, ?, ?)
                ''', (container_ip, external_port, internal_port, protocol, description))
                imported += 1

        self.conn.commit()
        self.logger.info(f"Imported {imported} mappings from {file_path}")
        return imported

    def backup_configuration(self):
        """Backup current configuration"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = os.path.join(self.config['backup_dir'], f'backup_{timestamp}')
        os.makedirs(backup_path, exist_ok=True)

        # Backup database
        shutil.copy(self.config['db_file'], os.path.join(backup_path, 'port_mappings.db'))

        # Backup iptables rules
        result = subprocess.run(['iptables-save'], stdout=subprocess.PIPE)
        with open(os.path.join(backup_path, 'rules.v4'), 'wb') as f:
            f.write(result.stdout)

        self.logger.info(f"Created backup at {backup_path}")
        return timestamp

    def restore_configuration(self, timestamp):
        """Restore configuration from backup"""
        backup_path = os.path.join(self.config['backup_dir'], f'backup_{timestamp}')
        if not os.path.exists(backup_path):
            raise ValueError(f"Backup {timestamp} does not exist")

        # Restore database
        shutil.copy(os.path.join(backup_path, 'port_mappings.db'), self.config['db_file'])

        # Restore iptables rules
        with open(os.path.join(backup_path, 'rules.v4'), 'r') as f:
            subprocess.run(['iptables-restore'], stdin=f)

        self.logger.info(f"Restored configuration from {backup_path}")

    def rebuild_database(self):
        """Rebuild database from existing iptables rules"""
        self.logger.info("Rebuilding database from iptables rules...")
        result = subprocess.run(['iptables-save'], stdout=subprocess.PIPE, text=True)

        imported = 0
        for line in result.stdout.splitlines():
            if '-A PREROUTING' in line and '-j DNAT' in line and f'-i {self.config["network_interface"]}' in line:
                protocol_match = re.search(r'-p (\w+)', line)
                dport_match = re.search(r'--dport (\d+)', line)
                to_dest_match = re.search(r'--to-destination ([^:]+):(\d+)', line)

                if protocol_match and dport_match and to_dest_match:
                    protocol = protocol_match.group(1)
                    external_port = int(dport_match.group(1))
                    container_ip = to_dest_match.group(1)
                    internal_port = int(to_dest_match.group(2))

                    # Check if already in database
                    self.cursor.execute('''
                        SELECT COUNT(*) FROM port_mappings
                        WHERE container_ip = ? AND external_port = ? AND protocol = ?
                    ''', (container_ip, external_port, protocol))

                    if self.cursor.fetchone()[0] == 0:
                        self.cursor.execute('''
                            INSERT INTO port_mappings
                            (container_ip, external_port, internal_port, protocol)
                            VALUES (?, ?, ?, ?)
                        ''', (container_ip, external_port, internal_port, protocol))
                        imported += 1

        self.conn.commit()
        self.logger.info(f"Rebuilt database with {imported} new entries")
        return imported

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(description='NAT Manager for Proxmox')
    parser.add_argument('--config', help='Configuration file path')

    subparsers = parser.add_subparsers(dest='action', help='Available actions')

    # Add action
    add_parser = subparsers.add_parser('add', help='Add port mappings')
    add_parser.add_argument('container_ip', help='Container IP address')
    add_parser.add_argument('--mode', choices=['automatic', 'manual'], default='automatic')
    add_parser.add_argument('--num-ports', type=int, default=6)
    add_parser.add_argument('--internal-ports', nargs='*', type=int)
    add_parser.add_argument('--external-ports', nargs='*', type=int)
    add_parser.add_argument('--protocols', nargs='*', choices=['tcp', 'udp'])
    add_parser.add_argument('--temporary', action='store_true')
    add_parser.add_argument('--description', help='Description of the mapping')

    # Remove action
    remove_parser = subparsers.add_parser('remove', help='Remove port mappings')
    remove_parser.add_argument('container_ip', help='Container IP address')

    # List action
    list_parser = subparsers.add_parser('list', help='List port mappings')
    list_parser.add_argument('container_ip', nargs='?', help='Container IP (optional)')

    # Reserve action
    reserve_parser = subparsers.add_parser('reserve', help='Reserve ports')
    reserve_parser.add_argument('ports', nargs='+', type=int)
    reserve_parser.add_argument('--description', help='Why these ports are reserved')

    # Unreserve action
    unreserve_parser = subparsers.add_parser('unreserve', help='Unreserve ports')
    unreserve_parser.add_argument('ports', nargs='+', type=int)

    # List reserved
    list_reserved_parser = subparsers.add_parser('list-reserved', help='List reserved ports')

    # Export action
    export_parser = subparsers.add_parser('export', help='Export mappings to JSON')
    export_parser.add_argument('file', help='Output file path')

    # Import action
    import_parser = subparsers.add_parser('import', help='Import mappings from JSON')
    import_parser.add_argument('file', help='Input file path')

    # Backup action
    backup_parser = subparsers.add_parser('backup', help='Backup configuration')

    # Restore action
    restore_parser = subparsers.add_parser('restore', help='Restore from backup')
    restore_parser.add_argument('timestamp', help='Backup timestamp')

    # Rebuild database
    rebuild_parser = subparsers.add_parser('rebuild-db', help='Rebuild database from iptables')

    args = parser.parse_args()

    if not args.action:
        parser.print_help()
        sys.exit(1)

    # Ensure running as root
    if os.geteuid() != 0:
        print("ERROR: This script must be run as root")
        sys.exit(1)

    # Initialize manager
    manager = NATManager(config_file=args.config)
    manager.check_iptables_persistent()

    try:
        if args.action == 'add':
            mappings = manager.add_container(
                args.container_ip,
                mode=args.mode,
                num_ports=args.num_ports,
                internal_ports=args.internal_ports,
                external_ports=args.external_ports,
                protocols=args.protocols,
                temporary=args.temporary,
                description=args.description
            )
            print(f"\n✓ Assigned ports to {args.container_ip}:")
            for ext, inter, proto in mappings:
                print(f"  {ext}/{proto} -> {args.container_ip}:{inter}")

        elif args.action == 'remove':
            count = manager.remove_container(args.container_ip)
            print(f"✓ Removed {count} port mappings for {args.container_ip}")

        elif args.action == 'list':
            mappings = manager.list_mappings(args.container_ip)
            if not mappings:
                print("No port mappings found")
            else:
                current_ip = None
                for m in mappings:
                    if m[0] != current_ip:
                        current_ip = m[0]
                        print(f"\n{current_ip}:")
                    temp = " (temporary)" if m[4] else ""
                    desc = f" - {m[5]}" if m[5] else ""
                    print(f"  {m[1]}/{m[3]} -> {m[2]}{temp}{desc}")

        elif args.action == 'reserve':
            manager.reserve_ports(args.ports, args.description)
            print(f"✓ Reserved ports: {', '.join(map(str, args.ports))}")

        elif args.action == 'unreserve':
            manager.unreserve_ports(args.ports)
            print(f"✓ Unreserved ports: {', '.join(map(str, args.ports))}")

        elif args.action == 'list-reserved':
            reserved = manager.list_reserved_ports()
            if not reserved:
                print("No reserved ports")
            else:
                print("Reserved ports:")
                for port, desc in reserved:
                    desc_str = f" - {desc}" if desc else ""
                    print(f"  {port}{desc_str}")

        elif args.action == 'export':
            manager.export_mappings(args.file)
            print(f"✓ Exported mappings to {args.file}")

        elif args.action == 'import':
            count = manager.import_mappings(args.file)
            print(f"✓ Imported {count} mappings from {args.file}")

        elif args.action == 'backup':
            timestamp = manager.backup_configuration()
            print(f"✓ Created backup: {timestamp}")

        elif args.action == 'restore':
            manager.restore_configuration(args.timestamp)
            print(f"✓ Restored configuration from {args.timestamp}")

        elif args.action == 'rebuild-db':
            count = manager.rebuild_database()
            print(f"✓ Rebuilt database with {count} entries from iptables")

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        manager.close()


if __name__ == '__main__':
    main()
