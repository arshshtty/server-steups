#!/usr/bin/env python3
"""
Web UI for NAT Manager - Flask application
Provides a simple, user-friendly interface for managing Proxmox NAT port forwarding
"""

from flask import Flask, render_template, request, jsonify, send_from_directory
import sys
import os

# Add parent directory to path to import nat_manager
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from nat_manager import NATManager

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)

# Initialize NAT Manager
CONFIG_FILE = os.environ.get('NAT_CONFIG', '/etc/nat_manager/config.json')
manager = None


def get_manager():
    """Get or create NAT Manager instance"""
    global manager
    if manager is None:
        manager = NATManager(config_file=CONFIG_FILE if os.path.exists(CONFIG_FILE) else None)
    return manager


@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')


@app.route('/api/mappings', methods=['GET'])
def get_mappings():
    """Get all port mappings"""
    try:
        mgr = get_manager()
        mappings = mgr.get_all_mappings_dict()
        return jsonify({'success': True, 'mappings': mappings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/mappings/<container_ip>', methods=['GET'])
def get_container_mappings(container_ip):
    """Get mappings for a specific container"""
    try:
        mgr = get_manager()
        mappings = mgr.list_mappings(container_ip)
        result = [{
            'external_port': m[1],
            'internal_port': m[2],
            'protocol': m[3],
            'temporary': bool(m[4]),
            'description': m[5],
            'created_at': m[6]
        } for m in mappings]
        return jsonify({'success': True, 'mappings': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/mappings', methods=['POST'])
def add_mapping():
    """Add new port mapping"""
    try:
        data = request.json
        mgr = get_manager()

        container_ip = data.get('container_ip')
        mode = data.get('mode', 'automatic')
        num_ports = data.get('num_ports', 6)
        internal_ports = data.get('internal_ports')
        external_ports = data.get('external_ports')
        protocols = data.get('protocols')
        description = data.get('description')

        mappings = mgr.add_container(
            container_ip,
            mode=mode,
            num_ports=num_ports,
            internal_ports=internal_ports,
            external_ports=external_ports,
            protocols=protocols,
            description=description
        )

        result = [{
            'external_port': m[0],
            'internal_port': m[1],
            'protocol': m[2]
        } for m in mappings]

        return jsonify({'success': True, 'mappings': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/api/mappings/<container_ip>', methods=['DELETE'])
def remove_mapping(container_ip):
    """Remove all mappings for a container"""
    try:
        mgr = get_manager()
        count = mgr.remove_container(container_ip)
        return jsonify({'success': True, 'removed': count})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/api/reserved', methods=['GET'])
def get_reserved():
    """Get reserved ports"""
    try:
        mgr = get_manager()
        reserved = mgr.list_reserved_ports()
        result = [{
            'port': r[0],
            'description': r[1]
        } for r in reserved]
        return jsonify({'success': True, 'reserved': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/reserved', methods=['POST'])
def reserve_ports():
    """Reserve ports"""
    try:
        data = request.json
        mgr = get_manager()
        ports = data.get('ports', [])
        description = data.get('description')

        mgr.reserve_ports(ports, description)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/api/reserved', methods=['DELETE'])
def unreserve_ports():
    """Unreserve ports"""
    try:
        data = request.json
        mgr = get_manager()
        ports = data.get('ports', [])

        mgr.unreserve_ports(ports)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/api/backup', methods=['POST'])
def create_backup():
    """Create a backup"""
    try:
        mgr = get_manager()
        timestamp = mgr.backup_configuration()
        return jsonify({'success': True, 'timestamp': timestamp})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/export', methods=['GET'])
def export_config():
    """Export configuration as JSON"""
    try:
        mgr = get_manager()
        mappings = mgr.list_mappings()
        data = [{
            'container_ip': m[0],
            'external_port': m[1],
            'internal_port': m[2],
            'protocol': m[3],
            'description': m[5]
        } for m in mappings]
        return jsonify({'success': True, 'data': data})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get statistics"""
    try:
        mgr = get_manager()
        mappings = mgr.list_mappings()
        reserved = mgr.list_reserved_ports()

        # Count containers
        containers = set(m[0] for m in mappings)

        # Count by protocol
        tcp_count = sum(1 for m in mappings if m[3] == 'tcp')
        udp_count = sum(1 for m in mappings if m[3] == 'udp')

        return jsonify({
            'success': True,
            'stats': {
                'total_mappings': len(mappings),
                'total_containers': len(containers),
                'tcp_mappings': tcp_count,
                'udp_mappings': udp_count,
                'reserved_ports': len(reserved)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/rebuild-db', methods=['POST'])
def rebuild_db():
    """Rebuild database from iptables"""
    try:
        mgr = get_manager()
        count = mgr.rebuild_database()
        return jsonify({'success': True, 'imported': count})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'error': 'Internal server error'}), 500


if __name__ == '__main__':
    # Check if running as root
    if os.geteuid() != 0:
        print("WARNING: This application requires root privileges to manage iptables")
        print("Please run with sudo or as root")
        sys.exit(1)

    # Get host and port from environment or use defaults
    host = os.environ.get('NAT_WEB_HOST', '0.0.0.0')
    port = int(os.environ.get('NAT_WEB_PORT', 8888))

    print(f"Starting NAT Manager Web UI on http://{host}:{port}")
    print("Press Ctrl+C to stop")

    app.run(host=host, port=port, debug=False)
