#!/bin/bash
echo "=== FIX NOOBZVPS CONFIG ==="

# Stop services
systemctl stop noobzvpns
systemctl stop haproxy

# 1. Fix noobzvpns config
echo "Fixing noobzvpns config.json..."
cat > /etc/noobzvpns/config.json << 'EOF'
{
    "tcp_std": [
        {
            "local_port": 8080,
            "remote_addr": "127.0.0.1",
            "remote_port": 80
        }
    ],
    "tcp_ssl": [
        {
            "local_port": 8443,
            "remote_addr": "127.0.0.1",
            "remote_port": 443,
            "ssl_cert": "/etc/xray/xray.crt",
            "ssl_key": "/etc/xray/xray.key", 
            "ssl_version": "AUTO"
        }
    ],
    "conn_timeout": 30,
    "dns_resolver": "/etc/resolv.conf",
    "http_ok": "HTTP/1.1 101 Switching Protocols[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
}
EOF

# 2. Sync certificates
echo "Syncing certificates..."
cp /etc/xray/xray.crt /etc/noobzvpns/cert.pem
cp /etc/xray/xray.key /etc/noobzvpns/key.pem
cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
chmod 600 /etc/haproxy/hap.pem /etc/noobzvpns/cert.pem /etc/noobzvpns/key.pem

# 3. Fix HAProxy config
echo "Updating HAProxy config..."
cat > /etc/haproxy/haproxy.cfg << 'EOF'
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
    default_backend vpn-https

frontend http-in  
    bind *:80
    default_backend vpn-http

backend vpn-https
    server vpn1 127.0.0.1:8443 check

backend vpn-http
    server vpn2 127.0.0.1:8080 check
EOF

# 4. Restart services
echo "Restarting services..."
systemctl restart noobzvpns
sleep 3
systemctl restart haproxy

# 5. Verify
echo "=== VERIFICATION ==="
echo "1. Service status:"
systemctl status noobzvpns --no-pager -l | head -10
systemctl status haproxy --no-pager -l | head -10

echo "2. Listening ports:"
ss -tulpn | grep -E ':(80|443|8080|8443)'

echo "3. Config test:"
haproxy -c -f /etc/haproxy/haproxy.cfg

echo "=== TEST CONNECTION ==="
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "your-domain.com")
echo "Test with: curl -I http://$DOMAIN"
echo "Test with: curl -Ik https://$DOMAIN"
