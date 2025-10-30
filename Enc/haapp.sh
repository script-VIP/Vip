#!/bin/bash
echo "=== FIX & INSTALL HAPROXY ==="

# Step 1: Fix system group error
echo "[1] Fixing system group error..."
dpkg-statoverride --remove /etc/ssl/private 2>/dev/null
dpkg-statoverride --remove /etc/ssl/certs 2>/dev/null
sed -i '/ssl-cert/d' /var/lib/dpkg/statoverride 2>/dev/null

# Step 2: Install HAProxy
echo "[2] Installing HAProxy..."
apt update
apt install --fix-broken -y
apt install haproxy -y

# Step 3: Verify install
echo "[3] Verifying installation..."
if which haproxy > /dev/null; then
    echo "✓ HAProxy installed successfully"
    haproxy -v
else
    echo "✗ HAProxy install failed, trying alternative..."
    # Alternative install
    cd /tmp
    wget http://archive.ubuntu.com/ubuntu/pool/main/h/haproxy/haproxy_2.8.5-1ubuntu3_amd64.deb
    dpkg -i haproxy_*.deb
    apt install -f -y
fi

# Step 4: Setup service
echo "[4] Setting up service..."
systemctl enable haproxy
cat > /etc/systemd/system/haproxy.service << 'EOF'
[Unit]
Description=HAProxy Load Balancer
After=network.target

[Service]
ExecStart=/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg
ExecReload=/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c -q
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Step 5: Buat config
echo "[5] Creating configuration..."
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "localhost")

# Buat certificate
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=$DOMAIN" \
    -keyout /etc/haproxy/hap.pem \
    -out /etc/haproxy/hap.pem 2>/dev/null
chmod 600 /etc/haproxy/hap.pem

# Buat config
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
EOF

# Step 6: Start service
echo "[6] Starting HAProxy..."
if haproxy -c -f /etc/haproxy/haproxy.cfg; then
    systemctl start haproxy
    sleep 2
    echo "✓ HAProxy started successfully"
else
    # Start manual
    haproxy -f /etc/haproxy/haproxy.cfg -D
    echo "✓ HAProxy started manually"
fi

# Step 7: Verify
echo "[7] Verification:"
ps aux | grep haproxy | grep -v grep
ss -tulpn | grep -E ':(80|443)'

echo "=== FINISHED ==="
