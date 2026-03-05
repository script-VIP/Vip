#!/bin/bash
# ZiVPN Updater - Clean Version

if [[ $EUID -ne 0 ]]; then
    echo "❌ Harus root!"
    exit 1
fi

echo "📥 UPDATE ZIVPN..."

# Backup password
if [[ -f /etc/zivpn/passwd.txt ]]; then
    cp /etc/zivpn/passwd.txt /tmp/passwd.txt.bak
fi

# Download manager terbaru
wget -q -O /usr/local/bin/zivpn-manager "https://raw.githubusercontent.com/script-VIP/Vip/main/zivpn-manager"
chmod +x /usr/local/bin/zivpn-manager

# Download fix script terbaru
wget -q -O /usr/local/bin/fix-zivpn.sh "https://raw.githubusercontent.com/script-VIP/Vip/main/fix-zivpn.sh"
chmod +x /usr/local/bin/fix-zivpn.sh

# Restore password
if [[ -f /tmp/passwd.txt.bak ]]; then
    cp /tmp/passwd.txt.bak /etc/zivpn/passwd.txt
fi

echo "✅ UPDATE SELESAI!"
echo "Jalankan: menu"
