#!/bin/bash
echo "=== Fixing HAProxy Config ==="

# Stop HAProxy
systemctl stop haproxy

# Remove problematic bind-process lines
sed -i '/bind-process/d' /etc/haproxy/haproxy.cfg

# Test config
echo "=== Testing New Config ==="
haproxy -c -f /etc/haproxy/haproxy.cfg

# Start HAProxy
systemctl start haproxy

# Check status
systemctl status haproxy
