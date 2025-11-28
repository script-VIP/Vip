#!/bin/bash
# install-fixed.sh - Dekodemo V2Ray Fixed Installer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LINE="==============================================="

header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        DEKODEMO V2RAY INSTALLER"
    echo "         Fixed for Modern V2Ray"
    echo "$LINE${NC}"
    echo
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root: sudo bash install-fixed.sh${NC}"
    exit 1
fi

# Install dependencies
header
echo -e "${YELLOW}[1] Installing dependencies...${NC}"
apt update
apt upgrade -y
apt install -y wget curl nano unzip jq net-tools

# Install V2Ray
echo -e "${YELLOW}[2] Installing V2Ray...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Create directories
echo -e "${YELLOW}[3] Creating directories...${NC}"
mkdir -p /etc/v2ray/users /etc/v2ray/backup /etc/v2ray/configs

# Create FIXED V2Ray config (TCP/WS only)
echo -e "${YELLOW}[4] Creating fixed configuration...${NC}"
cat > /etc/v2ray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 6000,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "port": 6001,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/dekodemo"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

# Download fixed menu
echo -e "${YELLOW}[5] Downloading fixed menu...${NC}"
wget -q -O /usr/local/bin/deko-menu https://raw.githubusercontent.com/your-repo/dekodemo/main/menu-fixed.sh
chmod +x /usr/local/bin/deko-menu

# Setup firewall
echo -e "${YELLOW}[6] Configuring firewall...${NC}"
iptables -I INPUT -p tcp --dport 6000:6010 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[7] Starting service...${NC}"
systemctl enable v2ray
systemctl restart v2ray

# Check service status
if systemctl is-active v2ray >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] V2Ray service started successfully${NC}"
else
    echo -e "${YELLOW}[!] Checking V2Ray logs...${NC}"
    journalctl -u v2ray -n 10 --no-pager
fi

# Completion message
header
echo -e "${GREEN}[✓] DEKODEMO V2RAY INSTALLATION COMPLETED!${NC}"
echo "$LINE"
echo -e "${CYAN}Management Command:${NC}"
echo -e "${GREEN}deko-menu${NC}"
echo
echo -e "${CYAN}Supported Protocols:${NC}"
echo -e "${GREEN}• VMESS TCP (Port 6000)${NC}"
echo -e "${GREEN}• VMESS WebSocket (Port 6001)${NC}"
echo -e "${YELLOW}Path: /dekodemo${NC}"
echo
echo -e "${YELLOW}Quick Start:${NC}"
echo "1. Run 'deko-menu'"
echo "2. Create VMESS TCP account"
echo "3. Use V2Ray client to connect"
echo "$LINE"
