#!/bin/bash
# ============================================
# SCRIPT PERBAIKAN SSL - UNTUK SEMUA DOMAIN
# ============================================
# Cara pakai: bash fix.sh
# ============================================

clear
echo "====================================="
echo "   PERBAIKAN SSL UNTUK SEMUA DOMAIN"
echo "====================================="
echo ""

# Minta input domain
read -p "Masukkan domain Anda (contoh: myindo.my.id): " domain
echo ""
echo "Domain yang akan diperbaiki: $domain"
echo ""
read -p "Lanjutkan? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Dibatalkan."
    exit 1
fi

echo ""
echo "====================================="
echo "MULAI PERBAIKAN SSL untuk $domain"
echo "====================================="
echo ""

# Stop service yang menggunakan port 80
echo "[1/6] Menghentikan service..."
systemctl stop nginx 2>/dev/null
systemctl stop haproxy 2>/dev/null
systemctl stop apache2 2>/dev/null
systemctl stop xray 2>/dev/null
systemctl stop v2ray 2>/dev/null
sleep 2

# Buka port 80 di firewall
echo "[2/6] Membuka port 80 di firewall..."
ufw allow 80/tcp 2>/dev/null
iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
ip6tables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
sleep 2

# Hapus direktori lama yang error
echo "[3/6] Membersihkan file SSL lama untuk $domain..."
rm -rf /root/.acme.sh/${domain}*
rm -rf /root/.acme.sh/${domain}_ecc
rm -f /etc/xray/xray.key
rm -f /etc/xray/xray.crt
rm -f /etc/v2ray/v2ray.key
rm -f /etc/v2ray/v2ray.crt
mkdir -p /etc/xray /etc/v2ray
sleep 2

# Install ulang acme.sh jika perlu
echo "[4/6] Memastikan acme.sh terinstall..."
if [ ! -f /root/.acme.sh/acme.sh ]; then
    echo "Menginstall acme.sh..."
    curl https://get.acme.sh | sh
fi
source ~/.bashrc
sleep 2

# Issue sertifikat baru (mode standalone)
echo "[5/6] Menerbitkan sertifikat baru untuk $domain..."
echo "Proses ini akan memakan waktu 10-30 detik..."
/root/.acme.sh/acme.sh --issue --standalone -d $domain --force --keylength ec-256 --debug 2>/dev/null

# Cek hasil
if [ $? -eq 0 ]; then
    echo "[6/6] Install sertifikat ke XRAY/V2RAY..."
    
    # Install untuk XRAY
    /root/.acme.sh/acme.sh --install-cert -d $domain --ecc \
        --key-file /etc/xray/xray.key \
        --fullchain-file /etc/xray/xray.crt 2>/dev/null
    
    # Install untuk V2RAY
    /root/.acme.sh/acme.sh --install-cert -d $domain --ecc \
        --key-file /etc/v2ray/v2ray.key \
        --fullchain-file /etc/v2ray/v2ray.crt 2>/dev/null
    
    # Set permission
    chmod 644 /etc/xray/xray.key 2>/dev/null
    chmod 644 /etc/xray/xray.crt 2>/dev/null
    chmod 644 /etc/v2ray/v2ray.key 2>/dev/null
    chmod 644 /etc/v2ray/v2ray.crt 2>/dev/null
    
    # Restart service
    systemctl start nginx 2>/dev/null
    systemctl start haproxy 2>/dev/null
    systemctl start xray 2>/dev/null
    systemctl start v2ray 2>/dev/null
    
    echo ""
    echo "====================================="
    echo "✅ SUKSES! SSL UNTUK $domain"
    echo "====================================="
    echo " Lokasi file:"
    echo "   - XRAY : /etc/xray/xray.crt"
    echo "   - V2RAY: /etc/v2ray/v2ray.crt"
    echo ""
    echo " Cek dengan perintah:"
    echo "   ls -la /etc/xray/"
    echo "   ls -la /etc/v2ray/"
else
    echo ""
    echo "====================================="
    echo "❌ GAGAL! Error saat penerbitan SSL"
    echo "====================================="
    echo ""
    echo "Kemungkinan penyebab untuk domain $domain:"
    echo "1. Domain belum pointing ke IP VPS ini"
    echo "2. Port 80 masih diblokir oleh ISP/Cloudflare"
    echo "3. DNS Cloudflare dalam mode PROXY (harus DNS Only)"
    echo ""
    echo "Tes koneksi ke domain:"
    echo "   curl -v http://$domain"
    echo ""
    echo "Tes DNS:"
    echo "   dig $domain"
fi

# Kembalikan service
systemctl start nginx 2>/dev/null
systemctl start haproxy 2>/dev/null
echo ""
echo "Selesai..."
