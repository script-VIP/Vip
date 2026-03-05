#!/bin/bash
# ZiVPN Fixer - Clean Version

if [[ $EUID -ne 0 ]]; then
    echo "❌ Harus root!"
    exit 1
fi

echo "🔧 MEMPERBAIKI ZIVPN..."

# Backup password
if [[ -f /etc/zivpn/passwd.txt ]]; then
    cp /etc/zivpn/passwd.txt /tmp/passwd.txt.bak
    echo "✅ Password dibackup"
fi

# Reset NAT
iptables -t nat -F
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-port 5667
echo "✅ NAT direset"

# Restart service
systemctl daemon-reload
systemctl restart zivpn.service
systemctl enable zivpn.service
echo "✅ Service direstart"

# Restore password
if [[ -f /tmp/passwd.txt.bak ]]; then
    cp /tmp/passwd.txt.bak /etc/zivpn/passwd.txt
    echo "✅ Password direstore"
fi

echo ""
echo "✅ FIX SELESAI!"
systemctl status zivpn.service --no-pager | grep Active
