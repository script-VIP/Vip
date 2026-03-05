#!/bin/bash
# ZiVPN Installer - Clean Version

if [[ $EUID -ne 0 ]]; then
    echo "❌ Harus root!"
    exit 1
fi

# Deteksi OS
if [[ ! -f /etc/os-release ]]; then
    echo "❌ Tidak bisa deteksi OS"
    exit 1
fi

. /etc/os-release
if [[ $ID != "ubuntu" && $ID != "debian" ]]; then
    echo "❌ Hanya support Ubuntu/Debian"
    exit 1
fi

# Deteksi architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)     BIN="udp-zivpn-linux-amd64" ;;
    aarch64)    BIN="udp-zivpn-linux-arm64" ;;
    armv7l|armv6l) BIN="udp-zivpn-linux-arm" ;;
    *) 
        echo "❌ Architecture $ARCH tidak support"
        exit 1
        ;;
esac

echo "✅ OS: $ID $VERSION_ID"
echo "✅ ARCH: $ARCH"

# Install dependencies
apt update -y
apt install -y wget curl ufw iptables

# Download binary
echo "📥 Download binary..."
wget -q -O /usr/local/bin/zivpn "https://raw.githubusercontent.com/script-VIP/Vip/main/$BIN"
chmod +x /usr/local/bin/zivpn

# Buat direktori
mkdir -p /etc/zivpn

# Buat config
cat > /etc/zivpn/config.json <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": ["zi"]
  }
}
EOF

# Buat file password
echo "zi" > /etc/zivpn/passwd.txt

# Download manager
wget -q -O /usr/local/bin/zivpn-manager "https://raw.githubusercontent.com/script-VIP/Vip/main/zivpn-manager"
chmod +x /usr/local/bin/zivpn-manager

# Buat alias
echo "alias menu='/usr/local/bin/zivpn-manager'" >> ~/.bashrc

# Setup NAT
iptables -t nat -F
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-port 5667

# Setup service
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZiVPN UDP Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/zivpn -config /etc/zivpn/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable & start
systemctl daemon-reload
systemctl enable zivpn.service
systemctl start zivpn.service

# UFW
ufw allow 5667/udp comment 'ZiVPN'
ufw allow 6000:19999/udp comment 'ZiVPN Range'

echo ""
echo "✅ INSTALASI SELESAI!"
echo "📋 Jalankan: menu"
