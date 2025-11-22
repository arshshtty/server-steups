# Prometheus + Grafana Setup Scripts

Automated setup scripts for deploying the Prometheus + Grafana monitoring stack.

## Quick Start

```bash
# Run the setup script
cd apps/prometheus-grafana
./setup.sh
```

This will:
1. Check Docker installation
2. Create .env file from template
3. Pull required Docker images
4. Start the monitoring stack
5. Verify all services are running

## Usage

### Basic Setup

```bash
./setup.sh
```

### Dry-Run Mode

Preview what would be installed without making changes:

```bash
DRY_RUN=true ./setup.sh
```

### Manual Start

Set up without auto-starting services:

```bash
AUTO_START=false ./setup.sh
```

### Skip Docker Checks

Useful in CI/CD or when Docker check fails but Docker is installed:

```bash
SKIP_DOCKER_CHECK=true ./setup.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DRY_RUN` | false | Preview changes without applying |
| `SKIP_DOCKER_CHECK` | false | Skip Docker installation checks |
| `AUTO_START` | true | Automatically start services after setup |

## Manual Setup

If you prefer to set up manually:

```bash
# 1. Navigate to docker-compose directory
cd ../../docker-compose/prometheus-grafana

# 2. Create .env file
cp .env.example .env
nano .env  # Edit configuration

# 3. Start the stack
docker-compose up -d

# 4. Check status
docker-compose ps
docker-compose logs -f
```

## Post-Installation

### Access Services

- **Grafana**: http://localhost:3000 (admin/admin or your configured password)
- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080

### Import Grafana Dashboards

1. Login to Grafana
2. Go to Dashboards → Import
3. Import recommended dashboards:
   - **Node Exporter Full** (ID: 1860) - Host metrics
   - **Docker Container & Host Metrics** (ID: 179) - Container metrics
   - **cAdvisor Exporter** (ID: 14282) - Detailed container metrics

### Configure Alerts

Alert rules are pre-configured in `prometheus/alerts.yml`. To add custom alerts:

1. Edit `../../docker-compose/prometheus-grafana/prometheus/alerts.yml`
2. Reload Prometheus: `curl -X POST http://localhost:9090/-/reload`

## Troubleshooting

### Script fails with "Docker not installed"

Install Docker first:
```bash
cd ../../base
./setup.sh --docker-only
```

### Services won't start

Check logs:
```bash
cd ../../docker-compose/prometheus-grafana
docker-compose logs
```

### Grafana shows "No Data"

1. Check Prometheus is running: `docker ps | grep prometheus`
2. Verify Prometheus targets: http://localhost:9090/targets
3. Test datasource in Grafana: Configuration → Data Sources → Prometheus → Test

## Updating

```bash
cd ../../docker-compose/prometheus-grafana

# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

## Backup

```bash
cd ../../docker-compose/prometheus-grafana

# Backup Grafana
docker run --rm \
  -v prometheus-grafana_grafana_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/grafana-backup.tar.gz /data

# Backup Prometheus
docker run --rm \
  -v prometheus-grafana_prometheus_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/prometheus-backup.tar.gz /data
```

## Uninstall

```bash
cd ../../docker-compose/prometheus-grafana

# Stop and remove containers (keeps data)
docker-compose down

# Remove containers and data
docker-compose down -v
```

## Documentation

For detailed documentation, see:
- [Docker Compose README](../../docker-compose/prometheus-grafana/README.md)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## Version

Script version: 1.0.0
Last updated: 2025-11-22
