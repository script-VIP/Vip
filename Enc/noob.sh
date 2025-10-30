#!/bin/bash
echo "=== HAPUS NOOBZVPS & SETUP BARU ==="

DOMAIN=$(cat /etc/xray/domain 2>/dev/null)

# 1. Hapus noobzvpns
echo "1. Menghapus noobzvpns..."
systemctl stop noobzvpns 2>/dev/null
systemctl disable noobzvpns 2>/dev/null
rm -f /etc/systemd/system/noobzvpns.service
rm -f /usr/bin/noobzvpns
rm -rf /etc/noobzvpns/
pkill -f noobzvpns
systemctl daemon-reload

# 2. Cek port Xray
echo "2. Mencari port Xray..."
XRAY_PORTS=$(ss -tulpn | grep xray | awk '{print $5}' | cut -d: -f2 | sort -u)
echo "Port Xray yang ditemukan: $XRAY_PORTS"

# 3. Setup HAProxy
echo "3. Setup HAProxy..."
systemctl stop haproxy

# Buat config berdasarkan port yang tersedia
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

# Update certificate
if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    chmod 600 /etc/haproxy/hap.pem
fi

# 4. Restart services
echo "4. Restart services..."
systemctl restart haproxy

# 5. Verify
echo "5. Verifikasi..."
systemctl status haproxy --no-pager -l
echo "Port listening:"
ss -tulpn | grep -E ':(80|443)'

echo "=== SELESAI ==="
echo "Noobzvps dihapus, HAProxy langsung ke Xray"
if [ -n "$DOMAIN" ]; then
    echo "Test dengan:"
    echo "curl -I http://$DOMAIN"
    echo "curl -Ik https://$DOMAIN"
fi
