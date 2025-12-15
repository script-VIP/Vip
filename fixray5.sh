#!/bin/bash
# PERBAIKI XRAY & HAPROXY ERROR

echo "=== PERBAIKI ERROR UTAMA ==="
echo "1. Xray: Regex syntax error"
echo "2. Haproxy: Port 80 conflict with Nginx"
echo ""

# 1. HENTIKAN SEMUA SERVICE
echo "🛑 Menghentikan semua service..."
systemctl stop xray haproxy nginx udp-custom noobzvpns ws 2>/dev/null
sleep 2

# 2. PERBAIKI ERROR XRAY (Regex Error)
echo "🔧 Memperbaiki Xray config (regex error)..."
if [ -f /etc/xray/config.json ]; then
    # Backup config lama
    cp /etc/xray/config.json /etc/xray/config.json.backup.$(date +%Y%m%d)
    
    # Download config baru YANG BENAR
    echo "Downloading fresh config.json..."
    wget -qO /etc/xray/config.json "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/config.json"
    
    # Alternatif: fix regex manual
    sed -i 's/(?!/#/g' /etc/xray/config.json 2>/dev/null || true
    sed -i 's/\\\\./#/g' /etc/xray/config.json 2>/dev/null || true
    
    # Test config
    echo "Testing Xray config..."
    if /usr/local/bin/xray test -config /etc/xray/config.json 2>&1 | grep -q "error"; then
        echo "❌ Masih ada error, menggunakan config minimal..."
        cat > /etc/xray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": 10000,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
    fi
fi

# 3. PERBAIKI HAPROXY (Port 80 Conflict)
echo "🔧 Memperbaiki Haproxy config (port conflict)..."

# Hapus config haproxy yang pakai port 80
if grep -q "bind \*:80" /etc/haproxy/haproxy.cfg; then
    echo "Haproxy mencoba pakai port 80, tapi Nginx sudah pakai"
    echo "Mengubah Haproxy untuk tidak pakai port 80..."
    
    # Buat config haproxy yang benar
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode tcp
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend ssl
    bind *:443 ssl crt /etc/haproxy/hap.pem alpn h2,http/1.1
    default_backend xray

backend xray
    server xray1 127.0.0.1:10000
EOF
    
    echo "✅ Haproxy config diperbaiki (hanya port 443)"
fi

# 4. PERBAIKI NGINX CONFIG
echo "🌐 Mengatur Nginx untuk port 80 saja..."
cat > /etc/nginx/conf.d/xray.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    location /vmess {
        proxy_pass http://127.0.0.1:10002/vmess;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 5. BUAT SSL CERT UNTUK HAPROXY
echo "📜 Membuat/mengecek SSL certificate..."
domain=$(cat /etc/xray/domain)
if [ ! -f /etc/haproxy/hap.pem ] || [ ! -s /etc/haproxy/hap.pem ]; then
    echo "Membuat hap.pem dari xray certificate..."
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    chmod 600 /etc/haproxy/hap.pem
fi

# 6. TEST KONFIGURASI SEBELUM START
echo "✅ Testing configurations..."
echo "--- Testing Xray config ---"
/usr/local/bin/xray test -config /etc/xray/config.json && echo "✅ Xray config OK" || echo "❌ Xray config masih error"

echo "--- Testing Haproxy config ---"
haproxy -c -f /etc/haproxy/haproxy.cfg && echo "✅ Haproxy config OK" || echo "❌ Haproxy config error"

# 7. KILL PROCESS YANG PAKAI PORT 10000
echo "🧹 Membersihkan port 10000..."
fuser -k 10000/tcp 2>/dev/null || true

# 8. START SERVICE BERTAHAP
echo "🚀 Menjalankan services..."
systemctl daemon-reload

echo "1. Starting Xray..."
systemctl start xray
sleep 3

echo "2. Starting Nginx..."
systemctl start nginx
sleep 2

echo "3. Starting Haproxy..."
systemctl start haproxy
sleep 2

# 9. CEK STATUS AKHIR
echo ""
echo "=== STATUS SETELAH PERBAIKAN ==="
echo "Xray    : $(systemctl is-active xray)"
echo "Nginx   : $(systemctl is-active nginx)"
echo "Haproxy : $(systemctl is-active haproxy)"

echo ""
echo "=== PORT LISTENING ==="
ss -tulpn | grep -E ':80|:443|:10000' || echo "Tidak ada process listening"

echo ""
echo "=== LOG ERROR TERBARU ==="
echo "Xray:"
tail -5 /var/log/xray/error.log 2>/dev/null || echo "Tidak ada error log"

echo ""
echo "=== TEST KONEKSI ==="
echo -n "Xray (port 10000): "
timeout 2 nc -z localhost 10000 2>&1 | grep -o "succeeded" || echo "failed"

echo -n "HTTPS (port 443): "
timeout 2 curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 2>/dev/null || echo "timeout"

echo ""
echo "✅ PERBAIKAN SELESAI!"
echo "Jika masih error, coba:"
echo "1. systemctl status xray --no-pager"
echo "2. journalctl -u xray -n 20"
