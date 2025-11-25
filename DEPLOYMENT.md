# Deployment Guide

Technical documentation for deploying the monitoring infrastructure.

---

## Prerequisites

All infrastructure VMs must be running:

```bash
# Navigate to each infrastructure directory and start VMs
cd dns-infrastructure && vagrant up
cd email-infrastructure && vagrant up
cd ntp-infrastructure && vagrant up
cd dhcp-infrastructure && vagrant up
```

---

## Inventory Configuration

The `inventory.ini` file defines all target servers:

```ini
[dns_servers]
dns-primary ansible_host=192.168.20.10 ansible_user=vagrant
dns-secondary ansible_host=192.168.20.11 ansible_user=vagrant

[email_servers]
email-server ansible_host=192.168.20.20 ansible_user=vagrant

[ntp_servers]
ntp-server ansible_host=192.168.20.30 ansible_user=vagrant

[dhcp_servers]
dhcp-server ansible_host=192.168.20.50 ansible_user=vagrant

[monitoring]
monitoring-server ansible_host=192.168.20.40 ansible_user=vagrant
```

### Authentication

Default configuration uses SSH keys managed by Vagrant. If password authentication is needed:

1. Install `sshpass`:
   ```bash
   sudo apt-get install sshpass -y
   ```

2. Add to inventory:
   ```ini
   ansible_ssh_pass=vagrant
   ```

### Test Connectivity

```bash
ansible all_servers -i inventory.ini -m ping
```

Expected output:
```
server-name | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## Deployment Steps

### 1. Start Monitoring Server

```bash
cd monitoring-infrastructure
vagrant up
```

### 2. Deploy Monitoring Stack

```bash
ansible-playbook -i inventory.ini deploy_monitoring.yml
```

This installs:
- Prometheus with configured scrape targets
- Grafana with dashboards
- Node Exporter for local metrics

### 3. Deploy Exporters

```bash
ansible-playbook -i inventory.ini deploy_exporters.yml
```

This installs service-specific exporters on each infrastructure server.

### 4. Complete Deployment

Alternatively, deploy everything at once:

```bash
ansible-playbook -i inventory.ini deploy_all.yml
```

---

## Service Configuration

### Exporter Ports

| Service | Port | Exporter |
|---------|------|----------|
| System Metrics | 9100 | node_exporter |
| DNS | 9119 | bind_exporter |
| SMTP | 9154 | postfix_exporter |
| IMAP/POP3 | 9166 | dovecot_exporter |
| NTP | 9123 | chrony_exporter |

### Service Management

```bash
# Check service status
sudo systemctl status <exporter-name>

# View logs
sudo journalctl -u <exporter-name> -f

# Restart service
sudo systemctl restart <exporter-name>
```

---

## Validation

### Verify Exporters

Test exporter endpoints:

```bash
curl http://192.168.20.10:9119/metrics | head -20
curl http://192.168.20.20:9154/metrics | head -20
curl http://192.168.20.30:9123/metrics | head -20
curl http://192.168.20.40:9100/metrics | head -20
```

### Verify Prometheus

Access http://192.168.20.40:9090/targets and verify all endpoints show "UP" state.

### Verify Grafana

1. Access http://192.168.20.40:3000
2. Login (admin/admin)
3. Navigate to Dashboards
4. Verify data appears

---

## Troubleshooting

### Exporter Service Failed

```bash
ssh user@192.168.20.XX
sudo systemctl status <exporter-name>
sudo journalctl -u <exporter-name> -n 50
sudo systemctl restart <exporter-name>
```

### BIND Exporter Issues

Verify statistics channel is configured:

```bash
sudo grep "statistics-channels" /etc/bind/named.conf.options
sudo systemctl restart named
```

### Prometheus Not Scraping

```bash
ssh vagrant@192.168.20.40
sudo journalctl -u prometheus -f
sudo systemctl reload prometheus
```

### Grafana No Data

1. Check Prometheus targets: http://192.168.20.40:9090/targets
2. Verify exporters respond: `curl http://SERVER:PORT/metrics`
3. Check Grafana data source configuration

---

## Maintenance

### Add New Server

1. Add to `inventory.ini`
2. Test: `ansible <new-server> -i inventory.ini -m ping`
3. Deploy: `ansible-playbook -i inventory.ini deploy_exporters.yml --limit <new-server>`

### Update Configuration

Edit `/etc/prometheus/prometheus.yml` and reload:

```bash
sudo systemctl reload prometheus
```

### Backup Dashboards

```bash
ssh vagrant@192.168.20.40
sudo cp -r /var/lib/grafana/dashboards ~/grafana-backup-$(date +%Y%m%d)
```

---

## Rollback

### Remove Exporters

```bash
ansible all_servers -i inventory.ini -b -m systemd \
  -a "name=node_exporter state=stopped enabled=no"

ansible all_servers -i inventory.ini -b -m file \
  -a "path=/etc/systemd/system/node_exporter.service state=absent"

ansible all_servers -i inventory.ini -b -m file \
  -a "path=/usr/local/bin/node_exporter state=absent"
```

### Destroy Monitoring Server

```bash
vagrant destroy -f monitoring-server
```
