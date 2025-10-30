#!/bin/bash
echo "Configuring HAProxy for noobzvpns..."

# Stop services
systemctl stop haproxy

# Create proper HAProxy config
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    daemon
    maxconn 256
    user haproxy
    group haproxy

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option tcplog

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

# Test config
haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart HAProxy
systemctl restart haproxy

echo "Configuration updated!"
echo "HAProxy now forwarding:"
echo "Port 80  -> 127.0.0.1:8080"
echo "Port 443 -> 127.0.0.1:8443"
