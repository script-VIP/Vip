#!/bin/bash
# install.sh - UDP Dekodemo Installer

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
    echo "           Fixed Version"
    echo "$LINE${NC}"
    echo
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root: sudo bash install.sh${NC}"
    exit 1
fi

# Install dependencies
header
echo -e "${YELLOW}[1] Installing dependencies...${NC}"
apt update
apt upgrade -y
apt install -y wget curl nano unzip jq net-tools sqlite3

# Install V2Ray (new method)
echo -e "${YELLOW}[2] Installing V2Ray...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Create directories
echo -e "${YELLOW}[3] Creating directories...${NC}"
mkdir -p /etc/v2ray/users /etc/v2ray/backup /usr/local/udp-dekodemo

# Create V2Ray config
echo -e "${YELLOW}[4] Creating configuration...${NC}"
cat > /etc/v2ray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": 6000,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "udp",
        "security": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
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
        "network": "udp",
        "security": "none"
      }
    },
    {
      "port": 6002,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "udp",
        "security": "none"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

# Download menu script
echo -e "${YELLOW}[5] Downloading menu...${NC}"
wget -q -O /usr/local/bin/deko-menu https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/menu.sh
chmod +x /usr/local/bin/deko-menu

# Download backup script
echo -e "${YELLOW}[6] Downloading backup script...${NC}"
wget -q -O /usr/local/bin/deko-backup https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/backup.sh
chmod +x /usr/local/bin/deko-backup

# Setup firewall
echo -e "${YELLOW}[7] Configuring firewall...${NC}"
iptables -I INPUT -p udp --dport 1000:65000 -j ACCEPT
iptables -I INPUT -p tcp --dport 1000:65000 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[8] Starting service...${NC}"
systemctl enable v2ray
systemctl restart v2ray

# Completion message
header
echo -e "${GREEN}[✓] INSTALLATION COMPLETED!${NC}"
echo "$LINE"
echo -e "${CYAN}Management Command:${NC}"
echo -e "${GREEN}deko-menu${NC}"
echo
echo -e "${CYAN}Backup Command:${NC}"
echo -e "${GREEN}deko-backup${NC}"
echo
echo -e "${CYAN}Service Commands:${NC}"
echo "systemctl status v2ray"
echo "systemctl restart v2ray"
echo
echo -e "${YELLOW}Quick Start:${NC}"
echo "1. Run 'deko-menu'"
echo "2. Create trial user"
echo "3. Test connection"
echo "$LINE"
