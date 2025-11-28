#!/bin/bash
# install-deko.sh - Fixed UDP Dekodemo Installer

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
    echo -e "${RED}[!] Please run as root: sudo bash install-deko.sh${NC}"
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
bash <(curl -Ls https://install.direct/go.sh)

# Create directories
echo -e "${YELLOW}[3] Creating directories...${NC}"
mkdir -p /etc/v2ray/users /etc/v2ray/backup

# Create V2Ray config
echo -e "${YELLOW}[4] Creating configuration...${NC}"
cat > /etc/v2ray/config.json << EOF
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

# Create management menu
echo -e "${YELLOW}[5] Creating management menu...${NC}"
cat > /usr/local/bin/deko-menu << 'EOF'
#!/bin/bash
# deko-menu.sh - UDP Dekodemo Management

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

LINE="==============================================="

show_menu() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        UDP DEKODEMO MANAGEMENT" 
    echo "$LINE${NC}"
    echo "1. Create User"
    echo "2. Create Trial User"
    echo "3. List Users"
    echo "4. Delete User"
    echo "5. Service Status"
    echo "6. Backup System"
    echo "7. Restore System"
    echo "8. Exit"
    echo "$LINE"
}

create_user() {
    echo -e "\n${CYAN}[CREATE USER]${NC}"
    read -p "Username: " username
    read -p "Protocol (vmess/vless): " protocol
    read -p "Days active: " days
    
    if [ -z "$username" ] || [ -z "$days" ]; then
        echo -e "${RED}[!] Invalid input!${NC}"
        return
    fi
    
    uuid=$(cat /proc/sys/kernel/random/uuid)
    expiry=$(date -d "+$days days" "+%Y-%m-%d")
    port=$((6000 + RANDOM % 1000))
    
    cat > /etc/v2ray/users/$username.conf << EOF
username=$username
uuid=$uuid
protocol=$protocol
port=$port
created=$(date "+%Y-%m-%d")
expiry=$expiry
status=active
EOF

    echo -e "${GREEN}[✓] User created!${NC}"
    echo "Username: $username"
    echo "UUID: $uuid"
    echo "Port: $port"
    echo "Expiry: $expiry"
}

create_trial() {
    username="trial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    port=$((7000 + RANDOM % 1000))
    expiry=$(date -d "+1 days" "+%Y-%m-%d")
    
    cat > /etc/v2ray/users/$username.conf << EOF
username=$username
uuid=$uuid
protocol=vmess
port=$port
created=$(date "+%Y-%m-%d")
expiry=$expiry
status=active
EOF

    echo -e "${GREEN}[✓] Trial user created!${NC}"
    echo "Username: $username"
    echo "UUID: $uuid" 
    echo "Port: $port"
    echo "Expiry: $expiry (1 Day)"
}

list_users() {
    echo -e "\n${CYAN}[USER LIST]${NC}"
    echo "================================="
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
        return
    fi
    
    for user_file in /etc/v2ray/users/*.conf; do
        if [ -f "$user_file" ]; then
            username=$(grep '^username=' "$user_file" | cut -d= -f2)
            protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
            port=$(grep '^port=' "$user_file" | cut -d= -f2)
            expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
            status=$(grep '^status=' "$user_file" | cut -d= -f2)
            
            echo -e "User: ${GREEN}$username${NC}"
            echo "Protocol: $protocol"
            echo "Port: $port"
            echo "Expiry: $expiry"
            echo "Status: $status"
            echo "---------------------------------"
        fi
    done
}

delete_user() {
    echo -e "\n${CYAN}[DELETE USER]${NC}"
    read -p "Username to delete: " username
    
    if [ -f "/etc/v2ray/users/$username.conf" ]; then
        rm -f "/etc/v2ray/users/$username.conf"
        echo -e "${GREEN}[✓] User $username deleted!${NC}"
    else
        echo -e "${RED}[!] User not found!${NC}"
    fi
}

service_status() {
    echo -e "\n${CYAN}[SERVICE STATUS]${NC}"
    echo "V2Ray: $(systemctl is-active v2ray)"
    echo "Ports: $(netstat -tulpn | grep v2ray | wc -l) active"
}

backup_system() {
    echo -e "\n${CYAN}[BACKUP SYSTEM]${NC}"
    backup_name="deko-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "/etc/v2ray/backup/$backup_name" /etc/v2ray/config.json /etc/v2ray/users/ 2>/dev/null
    echo -e "${GREEN}[✓] Backup created: $backup_name${NC}"
}

restore_system() {
    echo -e "\n${CYAN}[RESTORE SYSTEM]${NC}"
    echo "Available backups:"
    ls -1 /etc/v2ray/backup/ 2>/dev/null || echo "No backups found"
    echo
    read -p "Backup filename: " backup_file
    
    if [ -f "/etc/v2ray/backup/$backup_file" ]; then
        systemctl stop v2ray
        tar -xzf "/etc/v2ray/backup/$backup_file" -C /
        systemctl start v2ray
        echo -e "${GREEN}[✓] System restored!${NC}"
    else
        echo -e "${RED}[!] Backup not found!${NC}"
    fi
}

# Main menu
while true; do
    show_menu
    read -p "Choose option [1-8]: " choice
    
    case $choice in
        1) create_user ;;
        2) create_trial ;;
        3) list_users ;;
        4) delete_user ;;
        5) service_status ;;
        6) backup_system ;;
        7) restore_system ;;
        8) 
            echo -e "${GREEN}[✓] Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done
EOF

chmod +x /usr/local/bin/deko-menu

# Setup firewall
echo -e "${YELLOW}[6] Configuring firewall...${NC}"
iptables -I INPUT -p udp --dport 1:65535 -j ACCEPT
iptables -I INPUT -p tcp --dport 1:65535 -j ACCEPT
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Start service
echo -e "${YELLOW}[7] Starting service...${NC}"
systemctl enable v2ray
systemctl restart v2ray

# Completion message
header
echo -e "${GREEN}[✓] INSTALLATION COMPLETED!${NC}"
echo "$LINE"
echo -e "${CYAN}Management Command:${NC}"
echo -e "${GREEN}deko-menu${NC}"
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
