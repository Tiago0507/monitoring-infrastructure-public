#!/bin/bash
# Script para probar conectividad a todos los servidores antes del deployment

echo "=========================================="
echo "Testing Connectivity to All Servers"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.."

echo "Testing Ansible connectivity..."
echo ""

# Test DNS servers
echo "1. DNS Servers:"
ansible dns_servers -i inventory.ini -m ping 2>&1 | grep -E "SUCCESS|FAILED|UNREACHABLE" || echo "   Connection test in progress..."
echo ""

# Test Email server
echo "2. Email Server:"
ansible email_servers -i inventory.ini -m ping 2>&1 | grep -E "SUCCESS|FAILED|UNREACHABLE" || echo "   Connection test in progress..."
echo ""

# Test NTP server
echo "3. NTP Server:"
ansible ntp_servers -i inventory.ini -m ping 2>&1 | grep -E "SUCCESS|FAILED|UNREACHABLE" || echo "   Connection test in progress..."
echo ""

# Test DHCP server
echo "4. DHCP Server:"
ansible dhcp_servers -i inventory.ini -m ping 2>&1 | grep -E "SUCCESS|FAILED|UNREACHABLE" || echo "   Connection test in progress..."
echo ""

echo "=========================================="
echo "Manual SSH Test (optional)"
echo "=========================================="
echo "If Ansible failed, try manual SSH:"
echo ""
echo "  ssh vagrant@192.168.20.10  # DNS Primary"
echo "  ssh vagrant@192.168.20.11  # DNS Secondary"
echo "  ssh vagrant@192.168.20.20  # Email Server"
echo "  ssh vagrant@192.168.20.30  # NTP Server"
echo "  ssh vagrant@192.168.20.50  # DHCP Server"
echo ""
echo "Default password: vagrant"
echo ""
echo "If you need password authentication:"
echo "1. Install sshpass: sudo apt-get install sshpass"
echo "2. Edit inventory.ini and uncomment: ansible_ssh_pass=vagrant"
echo ""
