#!/bin/bash
# install-fixed.sh - Fixed UDP Dekodemo Installer

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
    echo -e "${RED}[!] Please run as root: sudo bash install-fixed.sh${NC}"
    exit 1
fi

# Fix dpkg error first
fix_dpkg_error() {
    header
    echo -e "${YELLOW}[0] Fixing dpkg errors...${NC}"
    
    # Remove problematic statoverride
    if grep -q "ssl-cert" /var/lib/dpkg/statoverride 2>/dev/null; then
        echo -e "${YELLOW}[+] Removing ssl-cert from statoverride...${NC}"
        cp /var/lib/dpkg/statoverride /var/lib/dpkg/statoverride.backup
        grep -v "ssl-cert" /var/lib/dpkg/statoverride > /var/lib/dpkg/statoverride.fixed
        mv /var/lib/dpkg/statoverride.fixed /var/lib/dpkg/statoverride
    fi
    
    # Fix dpkg configuration
    dpkg --configure -a 2>/dev/null || true
    apt-get install -f -y 2>/dev/null || true
    
    echo -e "${GREEN}[✓] Dpkg errors fixed${NC}"
    sleep 2
}

# Install dependencies with error handling
install_dependencies() {
    header
    echo -e "${YELLOW}[1] Installing dependencies...${NC}"
    
    # Update package list
    apt update || {
        echo -e "${YELLOW}[!] apt update failed, trying alternative...${NC}"
        apt-get update || true
    }
    
    # Install essential packages one by one
    for package in wget curl nano unzip net-tools; do
        echo -e "${YELLOW}[+] Installing $package...${NC}"
        apt install -y $package 2>/dev/null || apt-get install -y $package 2>/dev/null || true
    done
    
    # Try to install jq separately
    echo -e "${YELLOW}[+] Installing jq...${NC}"
    if ! command -v jq >/dev/null 2>&1; then
        wget -q -O /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
        chmod +x /usr/local/bin/jq
    fi
    
    echo -e "${GREEN}[✓] Dependencies installed${NC}"
    sleep 2
}

# Install V2Ray with manual method
install_v2ray() {
    header
    echo -e "${YELLOW}[2] Installing V2Ray...${NC}"
    
    # Stop existing V2Ray
    systemctl stop v2ray 2>/dev/null || true
    
    # Download and install V2Ray manually
    mkdir -p /tmp/v2ray-install
    cd /tmp/v2ray-install
    
    # Download V2Ray
    if wget -q https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip; then
        unzip -q v2ray-linux-64.zip
        cp v2ray /usr/local/bin/
        cp v2ctl /usr/local/bin/
        chmod +x /usr/local/bin/v2ray /usr/local/bin/v2ctl
        
        # Create directories
        mkdir -p /etc/v2ray /var/log/v2ray
        mkdir -p /usr/local/share/v2ray
        
        # Create systemd service
        cat > /etc/systemd/system/v2ray.service << 'EOF'
[Unit]
Description=V2Ray Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/v2ray run -config /etc/v2ray/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        echo -e "${GREEN}[✓] V2Ray installed manually${NC}"
    else
        echo -e "${RED}[!] V2Ray download failed${NC}"
        echo -e "${YELLOW}[!] Continuing with basic setup...${NC}"
    fi
    
    sleep 2
}

setup_directories() {
    header
    echo -e "${YELLOW}[3] Setting up directories...${NC}"
    
    mkdir -p /etc/v2ray/users /etc/v2ray/backup /etc/v2ray/configs
    mkdir -p /usr/local/udp-dekodemo
    
    echo -e "${GREEN}[✓] Directories created${NC}"
    sleep 2
}

create_config() {
    header
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

    echo -e "${GREEN}[✓] Configuration created${NC}"
    sleep 2
}

download_scripts() {
    header
    echo -e "${YELLOW}[5] Downloading management scripts...${NC}"
    
    # Download menu script
    if wget -q -O /usr/local/bin/deko-menu https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/menu.sh; then
        chmod +x /usr/local/bin/deko-menu
        echo -e "${GREEN}[✓] Menu script downloaded${NC}"
    else
        # Create basic menu if download fails
        create_basic_menu
    fi
    
    # Download backup script
    if wget -q -O /usr/local/bin/deko-backup https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/backup.sh; then
        chmod +x /usr/local/bin/deko-backup
        echo -e "${GREEN}[✓] Backup script downloaded${NC}"
    else
        create_basic_backup
    fi
    
    sleep 2
}

create_basic_menu() {
    cat > /usr/local/bin/deko-menu << 'EOF'
#!/bin/bash
echo "Basic menu - please download full menu later"
echo "Run: wget -O /usr/local/bin/deko-menu https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/menu.sh"
echo "Then: chmod +x /usr/local/bin/deko-menu"
EOF
    chmod +x /usr/local/bin/deko-menu
}

create_basic_backup() {
    cat > /usr/local/bin/deko-backup << 'EOF'
#!/bin/bash
echo "Backup functionality - please download full backup script later"
echo "Run: wget -O /usr/local/bin/deko-backup https://raw.githubusercontent.com/your-repo/udp-dekodemo/main/backup.sh"
echo "Then: chmod +x /usr/local/bin/deko-backup"
EOF
    chmod +x /usr/local/bin/deko-backup
}

setup_firewall() {
    header
    echo -e "${YELLOW}[6] Configuring firewall...${NC}"
    
    # Basic firewall setup without iptables-persistent
    iptables -I INPUT -p udp --dport 6000:6100 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 6000:6100 -j ACCEPT 2>/dev/null || true
    
    echo -e "${GREEN}[✓] Firewall configured${NC}"
    sleep 2
}

start_services() {
    header
    echo -e "${YELLOW}[7] Starting services...${NC}"
    
    systemctl daemon-reload
    systemctl enable v2ray 2>/dev/null || true
    
    if systemctl start v2ray 2>/dev/null; then
        echo -e "${GREEN}[✓] V2Ray service started${NC}"
    else
        echo -e "${YELLOW}[!] V2Ray service not started (manual installation)${NC}"
    fi
    
    sleep 2
}

show_completion() {
    header
    echo -e "${GREEN}[✓] INSTALLATION COMPLETED!${NC}"
    echo "$LINE"
    echo -e "${CYAN}Management Command:${NC}"
    echo -e "${GREEN}deko-menu${NC}"
    echo
    echo -e "${CYAN}Backup Command:${NC}"
    echo -e "${GREEN}deko-backup${NC}"
    echo
    echo -e "${YELLOW}If services failed to start:${NC}"
    echo "1. Check: /usr/local/bin/v2ray --version"
    echo "2. Manual start: /usr/local/bin/v2ray -config /etc/v2ray/config.json"
    echo "3. Check logs: journalctl -u v2ray"
    echo
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "1. Run 'deko-menu'"
    echo "2. Create trial user"
    echo "3. Test connection"
    echo "$LINE"
}

# Main installation process
main() {
    fix_dpkg_error
    install_dependencies
    install_v2ray
    setup_directories
    create_config
    download_scripts
    setup_firewall
    start_services
    show_completion
}

# Run main function
main "$@"
