# Prometheus + Grafana Monitoring Stack

A complete monitoring solution using Prometheus for metrics collection and Grafana for visualization.

## Overview

This stack includes:

- **Prometheus** - Time-series database for metrics storage and querying
- **Grafana** - Visualization and dashboarding platform
- **Node Exporter** - Exports host-level metrics (CPU, memory, disk, network)
- **cAdvisor** - Exports container-level metrics

## Features

✅ Pre-configured Prometheus scrape configs
✅ Auto-provisioned Grafana datasource
✅ Alert rules for common issues (CPU, memory, disk)
✅ Host metrics monitoring via Node Exporter
✅ Container metrics monitoring via cAdvisor
✅ Persistent data storage with Docker volumes
✅ Configurable retention periods
✅ Ready for production use

## Quick Start

### 1. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit configuration (change default passwords!)
nano .env
```

**Important:** Change `GRAFANA_ADMIN_PASSWORD` before deploying!

### 2. Deploy the Stack

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Verify all containers are running
docker-compose ps
```

### 3. Access Services

- **Grafana**: http://localhost:3000 (default: admin/admin)
- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROMETHEUS_PORT` | 9090 | Prometheus web UI port |
| `PROMETHEUS_RETENTION` | 15d | Data retention period |
| `GRAFANA_PORT` | 3000 | Grafana web UI port |
| `GRAFANA_ADMIN_USER` | admin | Grafana admin username |
| `GRAFANA_ADMIN_PASSWORD` | admin | Grafana admin password (change this!) |
| `GRAFANA_ALLOW_SIGNUP` | false | Allow user registration |
| `GRAFANA_ROOT_URL` | http://localhost:3000 | Public Grafana URL |
| `GRAFANA_PLUGINS` | - | Comma-separated list of plugins to install |
| `NODE_EXPORTER_PORT` | 9100 | Node Exporter metrics port |
| `CADVISOR_PORT` | 8080 | cAdvisor web UI port |

### Prometheus Configuration

Edit `prometheus/prometheus.yml` to:
- Add new scrape targets
- Adjust scrape intervals
- Configure service discovery
- Add external labels

Example: Add custom application monitoring
```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:8080']
        labels:
          environment: 'production'
```

### Alert Rules

Alert rules are defined in `prometheus/alerts.yml`. Included alerts:

**Host Alerts:**
- High CPU usage (>80% for 5min)
- High memory usage (>85% for 5min)
- Low disk space (<15% for 10min)
- Critical disk space (<5% for 5min)

**Container Alerts:**
- Container down (>5min)
- High container CPU (>80% for 5min)
- High container memory (>90% for 5min)

**Prometheus Alerts:**
- Target down (>5min)

To add custom alerts, edit `prometheus/alerts.yml` and reload Prometheus:
```bash
docker-compose exec prometheus kill -HUP 1
# Or use the API
curl -X POST http://localhost:9090/-/reload
```

## Grafana Dashboards

### Adding Community Dashboards

Grafana has thousands of pre-built dashboards at [grafana.com/dashboards](https://grafana.com/grafana/dashboards/).

**Recommended dashboards:**

1. **Node Exporter Full** (ID: 1860)
   - Comprehensive host metrics
   - CPU, memory, disk, network graphs

2. **Docker Container & Host Metrics** (ID: 179)
   - Container resource usage
   - Host system overview

3. **cAdvisor Exporter** (ID: 14282)
   - Detailed container metrics
   - Resource limits and usage

**To import:**
1. Login to Grafana
2. Go to Dashboards → Import
3. Enter dashboard ID
4. Select "Prometheus" as datasource
5. Click Import

### Creating Custom Dashboards

1. Navigate to Dashboards → New Dashboard
2. Add panels with Prometheus queries
3. Example queries:
   ```promql
   # CPU usage
   100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

   # Memory usage
   (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

   # Disk usage
   (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

   # Container CPU
   rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100
   ```

## Usage Examples

### View Metrics in Prometheus

1. Open http://localhost:9090
2. Go to "Graph" tab
3. Try example queries:
   ```promql
   up
   node_cpu_seconds_total
   container_memory_usage_bytes
   ```

### Check Alert Status

```bash
# View active alerts in Prometheus UI
open http://localhost:9090/alerts

# Check Prometheus logs
docker-compose logs prometheus
```

### Monitor Specific Container

Add to `prometheus/prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9090']
```

Then reload Prometheus:
```bash
curl -X POST http://localhost:9090/-/reload
```

## Backup and Restore

### Backup Grafana

```bash
# Backup Grafana data
docker-compose exec grafana tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
docker cp grafana:/tmp/grafana-backup.tar.gz ./grafana-backup.tar.gz

# Or backup the volume
docker run --rm -v prometheus-grafana_grafana_data:/data -v $(pwd):/backup ubuntu tar czf /backup/grafana-data.tar.gz /data
```

### Backup Prometheus

```bash
# Backup Prometheus data
docker run --rm -v prometheus-grafana_prometheus_data:/data -v $(pwd):/backup ubuntu tar czf /backup/prometheus-data.tar.gz /data
```

### Restore

```bash
# Restore Grafana
docker run --rm -v prometheus-grafana_grafana_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/grafana-data.tar.gz -C /

# Restore Prometheus
docker run --rm -v prometheus-grafana_prometheus_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/prometheus-data.tar.gz -C /
```

## Maintenance

### Update Containers

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart prometheus
```

### Clean Up

```bash
# Stop and remove containers (keeps data)
docker-compose down

# Remove containers and volumes (deletes data!)
docker-compose down -v
```

## Troubleshooting

### Grafana shows "No Data"

1. Check Prometheus is running: `docker-compose ps`
2. Verify datasource: Grafana → Configuration → Data Sources
3. Test connection to Prometheus: `curl http://localhost:9090/-/ready`
4. Check Prometheus targets: http://localhost:9090/targets

### Prometheus can't scrape targets

1. Check targets status: http://localhost:9090/targets
2. Verify network connectivity:
   ```bash
   docker-compose exec prometheus wget -O- http://node-exporter:9100/metrics
   ```
3. Check firewall rules
4. Review Prometheus logs: `docker-compose logs prometheus`

### High memory usage

1. Reduce retention period in `.env`:
   ```bash
   PROMETHEUS_RETENTION=7d
   ```
2. Limit Prometheus memory:
   ```yaml
   services:
     prometheus:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

### cAdvisor not showing metrics

1. Check cAdvisor is running: `docker-compose ps`
2. Verify privileged mode is enabled
3. Check kernel compatibility
4. Review cAdvisor logs: `docker-compose logs cadvisor`

## Security Considerations

### Production Deployment

1. **Change default passwords** in `.env`
2. **Use reverse proxy** (Traefik/Caddy) with HTTPS
3. **Restrict network access** to monitoring ports
4. **Enable authentication** on Prometheus:
   ```yaml
   # Add to docker-compose.yml
   command:
     - '--web.config.file=/etc/prometheus/web.yml'
   ```
5. **Regular backups** of Grafana dashboards and data
6. **Update containers** regularly for security patches

### Firewall Rules

Only expose Grafana externally, keep Prometheus internal:
```bash
# Allow Grafana
ufw allow 3000/tcp

# Block Prometheus, Node Exporter, cAdvisor from external access
ufw deny 9090/tcp
ufw deny 9100/tcp
ufw deny 8080/tcp
```

## Integration with Reverse Proxy

### Traefik Example

```yaml
services:
  grafana:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.example.com`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
```

### Caddy Example

```
grafana.example.com {
    reverse_proxy grafana:3000
}
```

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter)
- [cAdvisor Metrics](https://github.com/google/cadvisor)

## Next Steps

1. Import recommended Grafana dashboards
2. Configure alerting (Alertmanager, email, Slack)
3. Add monitoring for your applications
4. Set up long-term storage (Thanos, Cortex)
5. Configure service discovery for dynamic environments
6. Implement backup automation

## Version

- Prometheus: latest
- Grafana: latest
- Node Exporter: latest
- cAdvisor: latest

Last updated: 2025-11-22
