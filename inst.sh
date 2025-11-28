#!/bin/bash
# install-dekodemo.sh - Dekodemo V2Ray Installer

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
    echo "         Unlimited Internet Optimized"
    echo "$LINE${NC}"
    echo
}

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root: sudo bash install-dekodemo.sh${NC}"
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

# Create V2Ray config for Dekodemo
echo -e "${YELLOW}[4] Creating Dekodemo configuration...${NC}"
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
      "tag": "dekodemo-vmess-udp",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "udp",
        "security": "none",
        "udpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "port": 6001,
      "protocol": "vmess",
      "tag": "dekodemo-vmess-ws",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/dekodemo",
          "headers": {
            "Host": ""
          }
        }
      }
    },
    {
      "port": 6002,
      "protocol": "vless",
      "tag": "dekodemo-vless-udp",
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
      "port": 6003,
      "protocol": "trojan",
      "tag": "dekodemo-trojan-udp",
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
      "tag": "direct",
      "settings": {
        "domainStrategy": "UseIP"
      }
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
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": ["geosite:category-ads-all"],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

# Download Dekodemo menu
echo -e "${YELLOW}[5] Downloading Dekodemo menu...${NC}"
wget -q -O /usr/local/bin/deko-menu https://raw.githubusercontent.com/your-repo/dekodemo/main/menu-dekodemo.sh
chmod +x /usr/local/bin/deko-menu

# Download backup script
echo -e "${YELLOW}[6] Downloading backup script...${NC}"
wget -q -O /usr/local/bin/deko-backup https://raw.githubusercontent.com/your-repo/dekodemo/main/backup.sh
chmod +x /usr/local/bin/deko-backup

# Setup firewall
echo -e "${YELLOW}[7] Configuring firewall...${NC}"
iptables -I INPUT -p udp --dport 6000:6100 -j ACCEPT
iptables -I INPUT -p tcp --dport 6000:6100 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[8] Starting service...${NC}"
systemctl enable v2ray
systemctl restart v2ray

# Completion message
header
echo -e "${GREEN}[✓] DEKODEMO V2RAY INSTALLATION COMPLETED!${NC}"
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
echo -e "${YELLOW}Dekodemo Features:${NC}"
echo "• VMESS UDP (Port 6000)"
echo "• VMESS WS /dekodemo (Port 6001)" 
echo "• VLESS UDP (Port 6002)"
echo "• Trojan UDP (Port 6003)"
echo
echo -e "${YELLOW}Quick Start:${NC}"
echo "1. Run 'deko-menu'"
echo "2. Create trial user"
echo "3. Import Vmess link to V2Ray client"
echo "$LINE"
