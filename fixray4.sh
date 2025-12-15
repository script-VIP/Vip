#!/bin/bash
# Script perbaikan Xray TANPA hapus akun yang ada

echo "=== PERBAIKAN XRAY TANPA HAPUS AKUN ==="
echo "Backup database akun terlebih dahulu..."

# 1. BACKUP DATABASE AKUN YANG ADA
BACKUP_DIR="/backup_akun_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup semua database akun
cp -f /etc/vmess/.vmess.db $BACKUP_DIR/ 2>/dev/null
cp -f /etc/vless/.vless.db $BACKUP_DIR/ 2>/dev/null
cp -f /etc/trojan/.trojan.db $BACKUP_DIR/ 2>/dev/null
cp -f /etc/shadowsocks/.shadowsocks.db $BACKUP_DIR/ 2>/dev/null
cp -f /etc/ssh/.ssh.db $BACKUP_DIR/ 2>/dev/null

echo "✅ Backup akun disimpan di: $BACKUP_DIR"

# 2. HENTIKAN SERVICE DENGAN BENAR
echo "🛑 Menghentikan services..."
systemctl stop nginx haproxy xray 2>/dev/null
pkill -f nginx 2>/dev/null
pkill -f haproxy 2>/dev/null

# 3. FIX PORT 80 CONFLICT
echo "🔧 Memperbaiki Port 80 conflict..."

# Cek apa yang pakai port 80
echo "Proses yang menggunakan port 80:"
lsof -ti:80 | xargs ps -fp 2>/dev/null || echo "Tidak ada proses di port 80"

# Kill process yang pakai port 80 (kecuali nginx/xray)
for pid in $(lsof -ti:80 2>/dev/null); do
    pname=$(ps -p $pid -o comm=)
    if [[ "$pname" != "nginx" ]] && [[ "$pname" != "xray" ]]; then
        echo "Menghentikan proses $pname (PID: $pid) di port 80"
        kill -9 $pid 2>/dev/null
    fi
done

# 4. PERBAIKI NGINX CONFIG
echo "🔄 Memperbaiki konfigurasi Nginx..."
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    gzip on;
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# 5. PERBAIKI XRAY CONFIG TANPA HAPUS AKUN
echo "🔐 Memperbaiki Xray config..."
if [ ! -f /etc/xray/config.json ]; then
    echo "Download config.json baru..."
    wget -qO /etc/xray/config.json "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/config.json"
else
    # Backup config lama
    cp /etc/xray/config.json /etc/xray/config.json.backup
    echo "Config lama di-backup"
fi

# 6. RESTORE DATABASE AKUN
echo "📂 Restore database akun..."
for db in vmess vless trojan shadowsocks ssh; do
    db_file="/etc/$db/.$db.db"
    backup_file="$BACKUP_DIR/.$db.db"
    
    if [ -f "$backup_file" ] && [ -s "$backup_file" ]; then
        echo "Restore $db dari backup..."
        mkdir -p "$(dirname "$db_file")"
        cp "$backup_file" "$db_file"
        chmod 644 "$db_file"
    else
        echo "Buat database baru untuk $db..."
        mkdir -p "$(dirname "$db_file")"
        echo -e "### XRAY ${db^^} USER LIST\n& plughin Account" > "$db_file"
        chmod 644 "$db_file"
    fi
done

# 7. PERBAIKI HAPROXY
echo "🌐 Memperbaiki Haproxy..."
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
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

frontend ssh
    bind *:80
    default_backend nginx

frontend ssl
    bind *:443 ssl crt /etc/haproxy/hap.pem alpn h2,http/1.1
    default_backend xray

backend nginx
    server nginx 127.0.0.1:81

backend xray
    server xray 127.0.0.1:10000
EOF

# 8. BUAT SSL JIKA TIDAK ADA
echo "📜 Mengecek SSL certificate..."
domain=$(cat /etc/xray/domain 2>/dev/null)
if [ -z "$domain" ]; then
    domain=$(curl -s ifconfig.me)
    echo "$domain" > /etc/xray/domain
    echo "Domain set ke: $domain"
fi

if [ ! -f /etc/xray/xray.crt ] || [ ! -f /etc/xray/xray.key ]; then
    echo "Membuat SSL certificate..."
    systemctl stop nginx 2>/dev/null
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force
    /root/.acme.sh/acme.sh --installcert -d $domain \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc --force
fi

# Update haproxy pem file
cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
chmod 600 /etc/haproxy/hap.pem

# 9. PERBAIKI PERMISSION
echo "🔒 Memperbaiki permission..."
chown -R www-data:www-data /etc/xray
chmod 755 /var/log/xray
chmod 644 /etc/xray/*.json
chmod 600 /etc/xray/*.key

# 10. START SERVICES BERTAHAP
echo "🚀 Menjalankan services..."
systemctl daemon-reload

# Start nginx dulu
systemctl start nginx
sleep 2

# Start xray
systemctl start xray
sleep 2

# Start haproxy
systemctl start haproxy

# 11. CEK STATUS
echo ""
echo "=== STATUS AKHIR ==="
echo "Nginx: $(systemctl is-active nginx)"
echo "Xray: $(systemctl is-active xray)"
echo "Haproxy: $(systemctl is-active haproxy)"

echo ""
echo "=== PORT LISTENING ==="
ss -tulpn | grep -E ':80|:443'

echo ""
echo "=== AKUN YANG TERSIMPAN ==="
echo "VMESS: $(grep -c '^###' /etc/vmess/.vmess.db 2>/dev/null || echo 0) akun"
echo "VLESS: $(grep -c '^###' /etc/vless/.vless.db 2>/dev/null || echo 0) akun"

echo ""
echo "✅ PERBAIKAN SELESAI!"
echo "Backup akun ada di: $BACKUP_DIR"
echo "Coba akses server via browser: http://$(curl -s ifconfig.me)"
