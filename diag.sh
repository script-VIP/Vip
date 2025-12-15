#!/bin/bash
# Script diagnosa error Haproxy dan Xray

echo "========================================="
echo "      DIAGNOSA ERROR HAPROXY & XRAY      "
echo "========================================="
echo ""

# 1. CEK STATUS SEMUA SERVICE
echo "=== 1. STATUS SEMUA SERVICE ==="
services=("xray" "haproxy" "nginx" "udp-custom" "noobzvpns" "ws")
for service in "${services[@]}"; do
    status=$(systemctl is-active $service 2>/dev/null || echo "not-found")
    enabled=$(systemctl is-enabled $service 2>/dev/null || echo "N/A")
    printf "%-15s: %-10s (enabled: %s)\n" "$service" "$status" "$enabled"
done
echo ""

# 2. CEK PORT LISTENING
echo "=== 2. PORT LISTENING ==="
echo "Port penting yang harus listening:"
echo "Port 80  (HTTP)  : $(ss -tulpn | grep ':80 ' | wc -l) process"
echo "Port 443 (HTTPS) : $(ss -tulpn | grep ':443 ' | wc -l) process"
echo "Port 10000(Xray) : $(ss -tulpn | grep ':10000' | wc -l) process"
echo ""

# Detail process di port
for port in 80 443 10000; do
    echo "--- Port $port ---"
    ss -tulpn | grep ":$port " || echo "Tidak ada process"
    lsof -i :$port 2>/dev/null | head -5 || true
    echo ""
done

# 3. CEK LOG ERROR TERBARU
echo "=== 3. LOG ERROR TERBARU ==="

echo "--- Xray Error Log (10 lines) ---"
if [ -f /var/log/xray/error.log ]; then
    tail -10 /var/log/xray/error.log
else
    echo "File /var/log/xray/error.log tidak ditemukan"
fi
echo ""

echo "--- Haproxy Error Log ---"
if [ -f /var/log/haproxy.log ]; then
    tail -10 /var/log/haproxy.log
elif journalctl -u haproxy --no-pager -n 10 2>/dev/null | grep -q "."; then
    journalctl -u haproxy --no-pager -n 10
else
    echo "Haproxy log tidak ditemukan"
fi
echo ""

echo "--- Nginx Error Log ---"
tail -5 /var/log/nginx/error.log 2>/dev/null || echo "Nginx error log tidak ditemukan"
echo ""

# 4. CEK JOURNALCTL UNTUK SERVICE
echo "=== 4. JOURNALCTL LOG (30 lines each) ==="

for service in xray haproxy nginx; do
    echo "--- $service journal ---"
    journalctl -u $service --no-pager -n 30 2>/dev/null | tail -10 || echo "Tidak ada log untuk $service"
    echo ""
done

# 5. CEK KONFIGURASI FILE
echo "=== 5. CEK KONFIGURASI FILE ==="

# Cek file config ada atau tidak
configs=(
    "/etc/xray/config.json"
    "/etc/haproxy/haproxy.cfg"
    "/etc/nginx/nginx.conf"
    "/etc/xray/xray.crt"
    "/etc/xray/xray.key"
)

for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        size=$(ls -lh "$config" | awk '{print $5}')
        lines=$(wc -l < "$config" 2>/dev/null || echo "0")
        printf "%-30s: ADA (%s, %s lines)\n" "$config" "$size" "$lines"
    else
        printf "%-30s: TIDAK ADA\n" "$config"
    fi
done
echo ""

# 6. CEK PERMISSION
echo "=== 6. CEK PERMISSION & OWNERSHIP ==="
important_files=(
    "/etc/xray"
    "/var/log/xray"
    "/etc/haproxy/haproxy.cfg"
    "/etc/xray/config.json"
    "/etc/xray/xray.key"
)

for file in "${important_files[@]}"; do
    if [ -e "$file" ]; then
        perms=$(stat -c "%A %U:%G" "$file" 2>/dev/null || echo "N/A")
        printf "%-30s: %s\n" "$file" "$perms"
    fi
done
echo ""

# 7. CEK PROCESS YANG BERJALAN
echo "=== 7. PROCESS YANG BERJALAN ==="
for proc in xray haproxy nginx; do
    count=$(ps aux | grep -E "(^|/)$proc" | grep -v grep | wc -l)
    if [ $count -gt 0 ]; then
        echo "--- $proc process ($count found) ---"
        ps aux | grep -E "(^|/)$proc" | grep -v grep | head -3
    else
        echo "$proc: TIDAK BERJALAN"
    fi
    echo ""
done

# 8. TEST KONEKSI INTERNAL
echo "=== 8. TEST KONEKSI INTERNAL ==="
echo "Test localhost:"
echo -n "Port 80  : "
timeout 2 curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "timeout"
echo -n "Port 443 : "
timeout 2 curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 2>/dev/null || echo "timeout"
echo -n "Port 10000: "
timeout 2 nc -z localhost 10000 2>&1 | grep -o "succeeded" || echo "failed"
echo ""

# 9. CEK DEPENDENCIES
echo "=== 9. CEK DEPENDENCIES ==="
echo -n "Xray binary: "
if [ -x /usr/local/bin/xray ]; then
    /usr/local/bin/xray version 2>/dev/null | head -1 || echo "Ada tapi error"
else
    echo "Tidak ditemukan"
fi

echo -n "Haproxy: "
haproxy -v 2>/dev/null | head -1 || echo "Tidak terinstall"

echo -n "Nginx: "
nginx -v 2>&1 | head -1 || echo "Tidak terinstall"
echo ""

# 10. CEK FIREWALL & IPTABLES
echo "=== 10. CEK FIREWALL ==="
echo "IPTABLES rules untuk port 80,443:"
iptables -L -n | grep -E "(80|443)" || echo "Tidak ada rules khusus"
echo ""

# 11. CEK DOMAIN & SSL
echo "=== 11. CEK DOMAIN & SSL ==="
domain=$(cat /etc/xray/domain 2>/dev/null || echo "Tidak ada domain file")
echo "Domain: $domain"
echo -n "SSL Certificate: "
if [ -f /etc/xray/xray.crt ]; then
    openssl x509 -in /etc/xray/xray.crt -text -noout 2>/dev/null | grep -A1 "Not After" || echo "Valid"
else
    echo "Tidak ditemukan"
fi
echo ""

# 12. CEK MEMORY & RESOURCE
echo "=== 12. CEK RESOURCE ==="
echo "Memory free: $(free -h | awk '/^Mem:/ {print $4}')"
echo "Disk free: $(df -h / | awk 'NR==2 {print $4}')"
echo "Load average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "========================================="
echo "            DIAGNOSA SELESAI             "
echo "========================================="
echo ""
echo "📋 REKOMENDASI PERBAIKAN BERDASARKAN DIAGNOSA:"
echo "1. Jika 'xray not-found': Service tidak terinstall"
echo "2. Jika 'xray inactive': Config error / port conflict"
echo "3. Jika log ada 'permission denied': Fix permission"
echo "4. Jika log ada 'address already in use': Port conflict"
echo "5. Jika SSL error: Renew certificate"
echo ""
echo "⚠️  ERROR UTAMA YANG DITEMUKAN:"
