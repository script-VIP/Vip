#!/bin/bash
# FIX XRAY REGEX ERROR SAJA

echo "=== FIX XRAY REGEX ERROR ==="
echo "Error: invalid or unsupported Perl syntax: \`(?!\`"
echo ""

# 1. Stop Xray
echo "🛑 Stopping Xray..."
systemctl stop xray

# 2. Backup config lama
BACKUP_FILE="/etc/xray/config.json.backup.$(date +%Y%m%d_%H%M%S)"
cp /etc/xray/config.json "$BACKUP_FILE"
echo "✅ Config di-backup ke: $BACKUP_FILE"

# 3. Perbaiki regex error secara spesifik
echo "🔧 Memperbaiki regex error..."
# Cari dan hapus regex yang bermasalah
sed -i '/"regex":.*(?!.*/d' /etc/xray/config.json
sed -i 's/"regex":.*\\\\./# regex removed/g' /etc/xray/config.json

# Hapus DNS settings yang bermasalah (sementara)
sed -i '/"dns":/,/}/d' /etc/xray/config.json

# 4. Buat config minimal yang PASTI berfungsi
echo "🔄 Membuat config minimal..."
cat > /etc/xray/config.json.minimal << 'EOF'
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
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "port": 10001,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "port": 10002,
      "listen": "127.0.0.1",
      "protocol": "trojan",
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

# 5. Test config lama (jika masih error, pakai config minimal)
echo "🧪 Testing config..."
if /usr/local/bin/xray test -config /etc/xray/config.json 2>&1 | grep -q "error"; then
    echo "❌ Config lama masih error, pakai config minimal..."
    cp /etc/xray/config.json.minimal /etc/xray/config.json
else
    echo "✅ Config lama sudah diperbaiki"
fi

# 6. Test config baru
echo "Final test..."
/usr/local/bin/xray test -config /etc/xray/config.json && echo "✅ Config OK!" || {
    echo "❌ Masih error, pakai config sangat minimal..."
    cat > /etc/xray/config.json << 'EOF'
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": 10000,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {"clients": []},
    "streamSettings": {"network": "tcp"}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
}

# 7. Start Xray
echo "🚀 Starting Xray..."
systemctl start xray
sleep 3

# 8. Cek status
echo ""
echo "=== HASIL ==="
echo "Xray status: $(systemctl is-active xray)"
echo ""

if systemctl is-active --quiet xray; then
    echo "✅ Xray BERHASIL di-start!"
    echo "Port 10000 listening: $(ss -tulpn | grep :10000 | wc -l)"
    
    # Test koneksi ke Xray
    echo -n "Test koneksi ke port 10000: "
    timeout 2 nc -z localhost 10000 && echo "✅ BERHASIL" || echo "❌ GAGAL"
    
    # Test Haproxy -> Xray
    echo -n "Test Haproxy -> Xray (port 443): "
    curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 && echo "✅ OK" || echo "❌ ERROR"
else
    echo "❌ Xray masih gagal. Cek log:"
    journalctl -u xray --no-pager -n 20
fi

echo ""
echo "=== INSTRUKSI ==="
echo "Jika masih error, coba:"
echo "1. Lihat error detail: journalctl -u xray -n 30"
echo "2. Cek config: cat /etc/xray/config.json | head -50"
echo "3. Jalankan manual: /usr/local/bin/xray run -config /etc/xray/config.json"
