#!/bin/bash
# install-udp-dekodemo.sh - UDP Dekodemo yang Benar

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LINE="==============================================="

header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        UDP DEKODEMO INSTALLER"
    echo "         Config Terbukti Work"
    echo "$LINE${NC}"
    echo
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root: sudo bash install-udp-dekodemo.sh${NC}"
    exit 1
fi

# Install dependencies
header
echo -e "${YELLOW}[1] Installing dependencies...${NC}"
apt update
apt upgrade -y
apt install -y wget curl nano unzip jq net-tools

# Install XRay (lebih support UDP)
echo -e "${YELLOW}[2] Installing XRay (better UDP support)...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Create directories
echo -e "${YELLOW}[3] Creating directories...${NC}"
mkdir -p /etc/xray /etc/xray/users /etc/xray/backup /etc/xray/configs

# Create UDP Config yang BENAR
echo -e "${YELLOW}[4] Creating UDP configuration...${NC}"
cat > /etc/xray/config.json << 'EOF'
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
        "network": "udp"
      }
    },
    {
      "port": 6001,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "udp"
      }
    },
    {
      "port": 6002,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "udp"
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

# Download menu UDP
echo -e "${YELLOW}[5] Downloading UDP menu...${NC}"
wget -q -O /usr/local/bin/udp-menu https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/menu-udp-real.sh
chmod +x /usr/local/bin/udp-menu

# Setup firewall untuk UDP
echo -e "${YELLOW}[6] Configuring UDP firewall...${NC}"
iptables -I INPUT -p udp --dport 6000:65000 -j ACCEPT
iptables -I INPUT -p tcp --dport 6000:65000 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[7] Starting XRay service...${NC}"
systemctl enable xray
systemctl restart xray

# Completion message
header
echo -e "${GREEN}[✓] UDP DEKODEMO INSTALLATION COMPLETED!${NC}"
echo "$LINE"
echo -e "${CYAN}Management Command:${NC}"
echo -e "${GREEN}udp-menu${NC}"
echo
echo -e "${CYAN}UDP Ports:${NC}"
echo -e "6000 - VMESS UDP"
echo -e "6001 - VLESS UDP" 
echo -e "6002 - Trojan UDP"
echo
echo -e "${YELLOW}Test Connection:${NC}"
echo "1. Run 'udp-menu'"
echo "2. Create trial account"
echo "3. Test with V2Ray client"
echo "$LINE"
