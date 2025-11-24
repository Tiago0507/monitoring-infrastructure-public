#!/bin/bash
# Script to verify all exporters are running

echo "=========================================="
echo "Checking Exporters Status"
echo "=========================================="
echo ""

check_exporter() {
    local name=$1
    local host=$2
    local port=$3

    if curl -s -o /dev/null -w "%{http_code}" "http://${host}:${port}/metrics" | grep -q "200"; then
        echo "✓ ${name} (${host}:${port}): UP"
        return 0
    else
        echo "✗ ${name} (${host}:${port}): DOWN"
        return 1
    fi
}

FAILED=0

# DNS Servers
echo "DNS Servers:"
check_exporter "DNS Primary - BIND" "192.168.20.10" "9119" || FAILED=$((FAILED + 1))
check_exporter "DNS Primary - Node" "192.168.20.10" "9100" || FAILED=$((FAILED + 1))
check_exporter "DNS Secondary - BIND" "192.168.20.11" "9119" || FAILED=$((FAILED + 1))
check_exporter "DNS Secondary - Node" "192.168.20.11" "9100" || FAILED=$((FAILED + 1))
echo ""

# Email Server
echo "Email Server:"
check_exporter "Email - Postfix" "192.168.20.20" "9154" || FAILED=$((FAILED + 1))
check_exporter "Email - Dovecot" "192.168.20.20" "9166" || FAILED=$((FAILED + 1))
check_exporter "Email - Node" "192.168.20.20" "9100" || FAILED=$((FAILED + 1))
echo ""

# NTP Server
echo "NTP Server:"
check_exporter "NTP - Chrony" "192.168.20.30" "9123" || FAILED=$((FAILED + 1))
check_exporter "NTP - Node" "192.168.20.30" "9100" || FAILED=$((FAILED + 1))
echo ""

# DHCP Server
echo "DHCP Server:"
check_exporter "DHCP - Node" "192.168.20.50" "9100" || FAILED=$((FAILED + 1))
echo ""

# Monitoring Server
echo "Monitoring Server:"
check_exporter "Monitoring - Node" "192.168.20.40" "9100" || FAILED=$((FAILED + 1))
check_exporter "Prometheus" "192.168.20.40" "9090" || FAILED=$((FAILED + 1))
echo ""

echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo "Status: ALL EXPORTERS RUNNING"
    exit 0
else
    echo "Status: $FAILED EXPORTER(S) DOWN"
    exit 1
fi
