#!/bin/bash
# ZiVPN Uninstaller - Clean Version

if [[ $EUID -ne 0 ]]; then
    echo "❌ Harus root!"
    exit 1
fi

read -p "Yakin uninstall ZiVPN? (y/n): " confirm

if [[ $confirm != "y" ]]; then
    echo "Batal"
    exit 0
fi

echo "🗑️  Uninstall ZiVPN..."

# Stop service
systemctl stop zivpn.service 2>/dev/null
systemctl disable zivpn.service 2>/dev/null

# Hapus files
rm -f /usr/local/bin/zivpn
rm -f /usr/local/bin/zivpn-manager
rm -rf /etc/zivpn
rm -f /etc/systemd/system/zivpn.service
rm -f /usr/local/bin/install.sh
rm -f /usr/local/bin/fix-zivpn.sh

# Hapus alias dari .bashrc
sed -i '/alias menu=/d' ~/.bashrc

# Reload systemd
systemctl daemon-reload

# Hapus firewall rules
ufw delete allow 5667/udp 2>/dev/null
ufw delete allow 6000:19999/udp 2>/dev/null

echo "✅ Uninstall selesai!"
