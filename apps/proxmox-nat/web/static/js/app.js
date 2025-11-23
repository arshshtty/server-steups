// NAT Manager Web UI JavaScript

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    loadStats();
    loadMappings();
    loadReservedPorts();
});

// Show alert message
function showAlert(message, type = 'success') {
    const alertContainer = document.getElementById('alert-container');
    const alertId = 'alert-' + Date.now();

    const alertHtml = `
        <div class="alert alert-${type} alert-dismissible fade show" role="alert" id="${alertId}">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;

    alertContainer.insertAdjacentHTML('beforeend', alertHtml);

    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        const alert = document.getElementById(alertId);
        if (alert) {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }
    }, 5000);
}

// Load statistics
async function loadStats() {
    try {
        const response = await fetch('/api/stats');
        const data = await response.json();

        if (data.success) {
            document.getElementById('stat-total-mappings').textContent = data.stats.total_mappings;
            document.getElementById('stat-containers').textContent = data.stats.total_containers;
            document.getElementById('stat-tcp').textContent = data.stats.tcp_mappings;
            document.getElementById('stat-udp').textContent = data.stats.udp_mappings;
            document.getElementById('stat-reserved').textContent = data.stats.reserved_ports;
        }
    } catch (error) {
        console.error('Error loading stats:', error);
    }
}

// Load port mappings
async function loadMappings() {
    try {
        const response = await fetch('/api/mappings');
        const data = await response.json();

        if (data.success) {
            displayMappings(data.mappings);
        } else {
            showAlert('Error loading mappings: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error loading mappings: ' + error.message, 'danger');
    }
}

// Display port mappings
function displayMappings(mappings) {
    const container = document.getElementById('mappings-container');
    container.innerHTML = '';

    if (Object.keys(mappings).length === 0) {
        container.innerHTML = `
            <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> No port mappings configured yet.
                Click "Add Port Mapping" to get started.
            </div>
        `;
        return;
    }

    for (const [ip, ports] of Object.entries(mappings)) {
        const cardHtml = `
            <div class="card mb-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">
                        <i class="bi bi-hdd-network"></i> ${ip}
                    </h5>
                    <button class="btn btn-danger btn-sm" onclick="removeMapping('${ip}')">
                        <i class="bi bi-trash"></i> Remove All
                    </button>
                </div>
                <div class="card-body">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>External Port</th>
                                <th>Internal Port</th>
                                <th>Protocol</th>
                                <th>Description</th>
                                <th>Created</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${ports.map(port => `
                                <tr>
                                    <td><span class="badge bg-primary">${port.external_port}</span></td>
                                    <td>${port.internal_port}</td>
                                    <td><span class="badge bg-${port.protocol === 'tcp' ? 'success' : 'info'}">${port.protocol.toUpperCase()}</span></td>
                                    <td>${port.description || '-'}</td>
                                    <td><small>${formatDate(port.created_at)}</small></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        `;
        container.insertAdjacentHTML('beforeend', cardHtml);
    }
}

// Format date
function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString();
}

// Load reserved ports
async function loadReservedPorts() {
    try {
        const response = await fetch('/api/reserved');
        const data = await response.json();

        if (data.success) {
            displayReservedPorts(data.reserved);
        }
    } catch (error) {
        console.error('Error loading reserved ports:', error);
    }
}

// Display reserved ports
function displayReservedPorts(reserved) {
    const tbody = document.getElementById('reserved-table-body');
    tbody.innerHTML = '';

    if (reserved.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="3" class="text-center text-muted">No reserved ports</td>
            </tr>
        `;
        return;
    }

    reserved.forEach(item => {
        const row = `
            <tr>
                <td><span class="badge bg-warning">${item.port}</span></td>
                <td>${item.description || '-'}</td>
                <td>
                    <button class="btn btn-danger btn-sm" onclick="unreservePort(${item.port})">
                        <i class="bi bi-unlock"></i> Unreserve
                    </button>
                </td>
            </tr>
        `;
        tbody.insertAdjacentHTML('beforeend', row);
    });
}

// Toggle manual fields
function toggleManualFields() {
    const mode = document.getElementById('add-mode').value;
    const manualFields = document.getElementById('manual-fields');
    const numPortsGroup = document.getElementById('num-ports-group');

    if (mode === 'manual') {
        manualFields.style.display = 'block';
        numPortsGroup.style.display = 'none';
    } else {
        manualFields.style.display = 'none';
        numPortsGroup.style.display = 'block';
    }
}

// Show add modal
function showAddModal() {
    const modal = new bootstrap.Modal(document.getElementById('addModal'));
    document.getElementById('addForm').reset();
    toggleManualFields();
    modal.show();
}

// Add mapping
async function addMapping() {
    const ip = document.getElementById('add-ip').value.trim();
    const mode = document.getElementById('add-mode').value;
    const description = document.getElementById('add-description').value.trim();

    if (!ip) {
        showAlert('Please enter a container IP address', 'warning');
        return;
    }

    const payload = {
        container_ip: ip,
        mode: mode,
        description: description || undefined
    };

    if (mode === 'automatic') {
        payload.num_ports = parseInt(document.getElementById('add-num-ports').value);
    } else {
        const internalPortsStr = document.getElementById('add-internal-ports').value.trim();
        const protocolsStr = document.getElementById('add-protocols').value.trim();

        if (!internalPortsStr) {
            showAlert('Please enter internal ports', 'warning');
            return;
        }

        payload.internal_ports = internalPortsStr.split(',').map(p => parseInt(p.trim()));

        if (protocolsStr) {
            payload.protocols = protocolsStr.split(',').map(p => p.trim().toLowerCase());
        }
    }

    try {
        const response = await fetch('/api/mappings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Successfully added ${data.mappings.length} port mappings for ${ip}`, 'success');
            bootstrap.Modal.getInstance(document.getElementById('addModal')).hide();
            loadMappings();
            loadStats();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error adding mapping: ' + error.message, 'danger');
    }
}

// Remove mapping
async function removeMapping(ip) {
    if (!confirm(`Are you sure you want to remove all port mappings for ${ip}?`)) {
        return;
    }

    try {
        const response = await fetch(`/api/mappings/${ip}`, {
            method: 'DELETE'
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Removed ${data.removed} port mappings for ${ip}`, 'success');
            loadMappings();
            loadStats();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error removing mapping: ' + error.message, 'danger');
    }
}

// Show reserve modal
function showReserveModal() {
    const modal = new bootstrap.Modal(document.getElementById('reserveModal'));
    document.getElementById('reserveForm').reset();
    modal.show();
}

// Reserve ports
async function reservePorts() {
    const portsStr = document.getElementById('reserve-ports').value.trim();
    const description = document.getElementById('reserve-description').value.trim();

    if (!portsStr) {
        showAlert('Please enter ports to reserve', 'warning');
        return;
    }

    const ports = portsStr.split(',').map(p => parseInt(p.trim()));

    try {
        const response = await fetch('/api/reserved', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ports, description })
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Reserved ${ports.length} ports`, 'success');
            bootstrap.Modal.getInstance(document.getElementById('reserveModal')).hide();
            loadReservedPorts();
            loadStats();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error reserving ports: ' + error.message, 'danger');
    }
}

// Unreserve port
async function unreservePort(port) {
    if (!confirm(`Are you sure you want to unreserve port ${port}?`)) {
        return;
    }

    try {
        const response = await fetch('/api/reserved', {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ports: [port] })
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Unreserved port ${port}`, 'success');
            loadReservedPorts();
            loadStats();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error unreserving port: ' + error.message, 'danger');
    }
}

// Show backup modal
function showBackupModal() {
    const modal = new bootstrap.Modal(document.getElementById('backupModal'));
    modal.show();
}

// Create backup
async function createBackup() {
    try {
        const response = await fetch('/api/backup', {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Backup created: ${data.timestamp}`, 'success');
            bootstrap.Modal.getInstance(document.getElementById('backupModal')).hide();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error creating backup: ' + error.message, 'danger');
    }
}

// Show export modal
async function showExportModal() {
    try {
        const response = await fetch('/api/export');
        const data = await response.json();

        if (data.success) {
            document.getElementById('export-data').value = JSON.stringify(data.data, null, 2);
            const modal = new bootstrap.Modal(document.getElementById('exportModal'));
            modal.show();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error exporting configuration: ' + error.message, 'danger');
    }
}

// Copy export data
function copyExportData() {
    const textarea = document.getElementById('export-data');
    textarea.select();
    document.execCommand('copy');
    showAlert('Copied to clipboard!', 'success');
}

// Show rebuild modal
function showRebuildModal() {
    const modal = new bootstrap.Modal(document.getElementById('rebuildModal'));
    modal.show();
}

// Rebuild database
async function rebuildDatabase() {
    try {
        const response = await fetch('/api/rebuild-db', {
            method: 'POST'
        });

        const data = await response.json();

        if (data.success) {
            showAlert(`Rebuilt database with ${data.imported} entries from iptables`, 'success');
            bootstrap.Modal.getInstance(document.getElementById('rebuildModal')).hide();
            loadMappings();
            loadStats();
        } else {
            showAlert('Error: ' + data.error, 'danger');
        }
    } catch (error) {
        showAlert('Error rebuilding database: ' + error.message, 'danger');
    }
}
