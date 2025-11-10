#!/bin/bash
echo "=== Starting HAProxy Fix ==="

# Stop services
systemctl stop haproxy
systemctl stop nginx

# Fix certificate
rm -f /etc/haproxy/hap.pem
cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
chmod 600 /etc/haproxy/hap.pem

# Download fresh config
wget -q -O /etc/haproxy/haproxy.cfg "https://raw.githubusercontent.com/AngIMAN/sc/main/Cfg/haproxy.cfg"
DOMAIN=$(cat /etc/xray/domain)
sed -i "s/xxx/${DOMAIN}/g" /etc/haproxy/haproxy.cfg

# Test config
echo "=== Testing Config ==="
haproxy -c -f /etc/haproxy/haproxy.cfg
nginx -t

# Start services
echo "=== Starting Services ==="
systemctl start nginx
systemctl start haproxy

# Check status
echo "=== Service Status ==="
systemctl status nginx --no-pager -l
systemctl status haproxy --no-pager -l

echo "=== Fix Complete ==="
