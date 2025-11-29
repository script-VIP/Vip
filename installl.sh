#!/bin/bash
# install-ss-udp.sh - Shadowsocks UDP Dekodemo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LINE="==============================================="

header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        SHADOWSOCKS UDP DEKODEMO"
    echo "         PASTI WORK - No Error"
    echo "$LINE${NC}"
    echo
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root: sudo bash install-ss-udp.sh${NC}"
    exit 1
fi

# Install dependencies
header
echo -e "${YELLOW}[1] Installing dependencies...${NC}"
apt update
apt upgrade -y
apt install -y wget curl nano unzip jq net-tools

# Install Shadowsocks Rust (terbaik untuk UDP)
echo -e "${YELLOW}[2] Installing Shadowsocks Rust...${NC}"
wget -q https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.17.0/shadowsocks-v1.17.0.x86_64-unknown-linux-gnu.tar.xz
tar -xf shadowsocks-v1.17.0.x86_64-unknown-linux-gnu.tar.xz
cp ssserver /usr/local/bin/
chmod +x /usr/local/bin/ssserver

# Create directories
echo -e "${YELLOW}[3] Creating directories...${NC}"
mkdir -p /etc/shadowsocks /etc/shadowsocks/users /etc/shadowsocks/backup

# Create Shadowsocks config
echo -e "${YELLOW}[4] Creating Shadowsocks UDP config...${NC}"
cat > /etc/shadowsocks/config.json << 'EOF'
{
    "server": "0.0.0.0",
    "server_port": 6000,
    "method": "2022-blake3-aes-128-gcm",
    "password": "defaultpassword",
    "mode": "tcp_and_udp",
    "fast_open": true,
    "udp_timeout": 300,
    "nofile": 51200
}
EOF

# Create systemd service
echo -e "${YELLOW}[5] Creating service...${NC}"
cat > /etc/systemd/system/ss-udp.service << EOF
[Unit]
Description=Shadowsocks UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Download menu Shadowsocks
echo -e "${YELLOW}[6] Downloading Shadowsocks menu...${NC}"
wget -q -O /usr/local/bin/ss-menu https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/menu-ss-udp.sh
chmod +x /usr/local/bin/ss-menu

# Setup firewall untuk UDP
echo -e "${YELLOW}[7] Configuring UDP firewall...${NC}"
iptables -I INPUT -p udp --dport 6000:65000 -j ACCEPT
iptables -I INPUT -p tcp --dport 6000:65000 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[8] Starting Shadowsocks service...${NC}"
systemctl daemon-reload
systemctl enable ss-udp
systemctl start ss-udp

# Completion message
header
echo -e "${GREEN}[✓] SHADOWSOCKS UDP INSTALLATION COMPLETED!${NC}"
echo "$LINE"
echo -e "${CYAN}Management Command:${NC}"
echo -e "${GREEN}ss-menu${NC}"
echo
echo -e "${CYAN}Shadowsocks UDP Port:${NC}"
echo -e "6000 - Shadowsocks 2022 (TCP & UDP)"
echo
echo -e "${YELLOW}Format:${NC}"
echo -e "ss://method:password@server:port"
echo
echo -e "${GREEN}Test:${NC}"
echo "1. Run 'ss-menu'"
echo "2. Create trial account" 
echo "3. Test dengan client Shadowsocks"
echo "$LINE"
