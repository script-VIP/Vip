clear
echo "=== INSTALL HAPROXY LENGKAP ==="
sleep 2

# Step 1: Install HAProxy
echo "[1] Installing HAProxy..."
apt update
apt install haproxy -y
systemctl enable haproxy
sleep 1

# Step 2: Buat sertifikat
echo "[2] Creating certificate..."
DOMAIN=$(cat /etc/xray/domain 2>/dev/null)
if [ -z "$DOMAIN" ]; then
    DOMAIN="localhost"
    echo "Using domain: $DOMAIN"
else
    echo "Domain found: $DOMAIN"
fi

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=$DOMAIN" \
    -keyout /etc/haproxy/hap.pem \
    -out /etc/haproxy/hap.pem 2>/dev/null

chmod 600 /etc/haproxy/hap.pem
echo "Certificate created: /etc/haproxy/hap.pem"
sleep 1

# Step 3: Buat config
echo "[3] Creating config..."
systemctl stop haproxy

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
    default_backend xray-backend

frontend http-in
    bind *:80
    default_backend xray-backend

backend xray-backend
    server xray1 127.0.0.1:2095 check
    server xray2 127.0.0.1:2096 check
    server xray3 127.0.0.1:2082 check
    server xray4 127.0.0.1:2083 check
EOF

sleep 1

# Step 4: Test dan start
echo "[4] Testing configuration..."
if haproxy -c -f /etc/haproxy/haproxy.cfg; then
    echo "✓ Configuration test PASSED"
    systemctl start haproxy
    sleep 2
else
    echo "✗ Configuration test FAILED"
    exit 1
fi

# Step 5: Hasil akhir
echo "[5] Final result:"
systemctl status haproxy --no-pager -l | head -10
echo ""
echo "=== LISTENING PORTS ==="
ss -tulpn | grep -E ':(80|443)' | head -5
echo ""
echo "=== TEST COMMANDS ==="
echo "curl -I http://$DOMAIN"
echo "curl -Ik https://$DOMAIN"
echo ""
echo "=== HAPROXY INSTALLED SUCCESSFULLY ==="
