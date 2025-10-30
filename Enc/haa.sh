#!/bin/bash
echo "=== PERBAIKI HAPROXY ==="

DOMAIN=$(cat /etc/xray/domain 2>/dev/null)

# 1. Stop services
echo "1. Menghentikan services..."
systemctl stop haproxy
pkill -f haproxy

# 2. Fix certificate
echo "2. Memperbaiki certificate..."
rm -f /etc/haproxy/hap.pem
if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    echo "✓ Certificate dibuat dari Xray"
else
    # Buat self-signed certificate
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Org/CN=$DOMAIN" \
        -keyout /etc/haproxy/hap.pem \
        -out /etc/haproxy/hap.pem 2>/dev/null
    echo "✓ Self-signed certificate dibuat"
fi
chmod 600 /etc/haproxy/hap.pem

# 3. Buat config HAProxy
echo "3. Membuat config HAProxy..."
cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon
    maxconn 256

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend https-in
    bind *:443 ssl crt /etc/haproxy/hap.pem
    default_backend xray-ssl

frontend http-in  
    bind *:80
    default_backend xray-http

backend xray-ssl
    server xray1 127.0.0.1:2096 check

backend xray-http
    server xray2 127.0.0.1:2095 check
EOF

# 4. Test dan start
echo "4. Testing configuration..."
if haproxy -c -f /etc/haproxy/haproxy.cfg; then
    echo "✓ Config OK, starting HAProxy..."
    systemctl start haproxy
    sleep 2
    systemctl status haproxy --no-pager -l
else
    echo "✗ Config test failed"
    
    # Fallback config tanpa SSL
    echo "Mencoba config tanpa SSL..."
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    daemon
    maxconn 256

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in  
    bind *:80
    default_backend xray-http

backend xray-http
    server xray1 127.0.0.1:2095 check
EOF
    systemctl start haproxy
fi

# 5. Verify
echo "5. Verifikasi akhir..."
echo "Status:"
systemctl is-active haproxy
echo "Port listening:"
ss -tulpn | grep -E ':(80|443)'

echo "=== SELESAI ==="
