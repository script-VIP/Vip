#!/bin/bash
# Fix Xray Service yang mati tapi akun masih ada

echo "=== FIX XRAY SERVICE OFFLINE ==="
echo "Checking status..."

# 1. Cek status service
systemctl status xray --no-pager | head -20

# 2. Stop semua service terkait
echo "🛑 Stopping related services..."
systemctl stop xray nginx haproxy udp-custom noobzvpns ws 2>/dev/null

# 3. Cek konfigurasi Xray
echo "🔍 Checking Xray configuration..."
if [ ! -f /etc/xray/config.json ]; then
    echo "⚠️  config.json not found! Downloading..."
    wget -qO /etc/xray/config.json "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/config.json"
fi

# Test config
echo "Testing config..."
/usr/local/bin/xray test -config /etc/xray/config.json
if [ $? -ne 0 ]; then
    echo "❌ Config error! Fixing..."
    mv /etc/xray/config.json /etc/xray/config.json.bad
    wget -qO /etc/xray/config.json "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/config.json"
fi

# 4. Cek SSL certificates
echo "🔐 Checking SSL certificates..."
if [ ! -f /etc/xray/xray.crt ] || [ ! -f /etc/xray/xray.key ]; then
    echo "⚠️  SSL certificates missing!"
    domain=$(cat /etc/xray/domain 2>/dev/null || curl -s ifconfig.me)
    echo "Domain: $domain"
    
    # Generate SSL
    systemctl stop nginx
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force
    /root/.acme.sh/acme.sh --installcert -d $domain \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc --force
    chmod 600 /etc/xray/xray.key
fi

# 5. Fix permissions
echo "🔧 Fixing permissions..."
chown -R www-data:www-data /etc/xray
chown -R www-data:www-data /var/log/xray
chmod 755 /var/log/xray
chmod 644 /etc/xray/*.json
chmod 600 /etc/xray/*.key

# 6. Cek port conflicts
echo "🚪 Checking port conflicts..."
for port in 80 443 8443 2082 2086 2095; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo "⚠️  Port $port used by PID $pid"
        # kill -9 $pid  # Uncomment jika perlu kill
    fi
done

# 7. Update systemd service
echo "🔄 Updating systemd service..."
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=www-data
Group=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# 8. Enable dan start
echo "⚡ Enabling and starting services..."
systemctl daemon-reload
systemctl enable xray nginx haproxy

# Start bertahap
systemctl start xray
sleep 2
systemctl start nginx
sleep 1
systemctl start haproxy

# 9. Cek status
echo ""
echo "=== FINAL STATUS ==="
echo "Xray: $(systemctl is-active xray)"
echo "Nginx: $(systemctl is-active nginx)"
echo "Haproxy: $(systemctl is-active haproxy)"

# 10. Cek log error
echo ""
echo "=== XRAY ERROR LOG (last 10 lines) ==="
tail -10 /var/log/xray/error.log 2>/dev/null || echo "No error log found"

# 11. Cek listening ports
echo ""
echo "=== LISTENING PORTS ==="
ss -tulpn | grep -E ':80|:443|:8443|:2082|:2095'

# 12. Test connection
echo ""
echo "=== QUICK TEST ==="
timeout 3 curl -sI http://localhost:80 >/dev/null && echo "✅ Port 80 OK" || echo "❌ Port 80 failed"
timeout 3 curl -sI https://localhost:443 --insecure >/dev/null && echo "✅ Port 443 OK" || echo "❌ Port 443 failed"

echo ""
echo "=== INSTRUCTIONS ==="
echo "Jika masih error, coba:"
echo "1. journalctl -u xray -n 50 --no-pager"
echo "2. /usr/local/bin/xray run -config /etc/xray/config.json"
echo "3. Cek firewall: ufw status / iptables -L"
