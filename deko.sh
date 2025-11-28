#!/bin/bash
# install-udp-dekodemo.sh - Universal Installer for Ubuntu/Debian/Termius

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

LINE="==========================================================="
DLINE="-----------------------------------------------------------"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${CYAN}[INFO] Detected OS: $OS $VER${NC}"
}

header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "           UDP DEKODEMO UNIVERSAL INSTALLER"
    echo "           Support: Ubuntu/Debian/Termius"
    echo "$LINE${NC}"
    echo -e "${YELLOW}OS: $OS $VER${NC}"
    echo
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Please run as root: sudo bash install-udp-dekodemo.sh${NC}"
        exit 1
    fi
}

install_dependencies() {
    header
    echo -e "${YELLOW}[1] Installing dependencies for $OS...${NC}"
    
    if command -v apt-get >/dev/null 2>&1; then
        # Ubuntu/Debian
        apt update
        apt upgrade -y
        apt install -y wget curl nano unzip jq net-tools sqlite3 pv git build-essential
        echo -e "${GREEN}[✓] Ubuntu/Debian dependencies installed${NC}"
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        yum update -y
        yum install -y wget curl nano unzip jq net-tools sqlite3 pv git make gcc
        echo -e "${GREEN}[✓] CentOS/RHEL dependencies installed${NC}"
    else
        echo -e "${RED}[!] Unsupported package manager${NC}"
        exit 1
    fi
    sleep 2
}

install_v2ray() {
    header
    echo -e "${YELLOW}[2] Installing V2Ray...${NC}"
    
    # Remove existing V2Ray
    systemctl stop v2ray 2>/dev/null || true
    systemctl disable v2ray 2>/dev/null || true
    
    # Install V2Ray using official script
    bash <(curl -Ls https://install.direct/go.sh)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] V2Ray installed successfully${NC}"
    else
        echo -e "${RED}[!] V2Ray installation failed, trying alternative method...${NC}"
        install_v2ray_manual
    fi
    
    sleep 2
}

install_v2ray_manual() {
    echo -e "${YELLOW}[!] Trying manual V2Ray installation...${NC}"
    
    # Download and install V2Ray manually
    mkdir -p /tmp/v2ray-install
    cd /tmp/v2ray-install
    
    wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
    unzip v2ray-linux-64.zip
    cp v2ray /usr/local/bin/
    cp v2ctl /usr/local/bin/
    chmod +x /usr/local/bin/v2ray /usr/local/bin/v2ctl
    
    # Create systemd service
    cat > /etc/systemd/system/v2ray.service << EOF
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
    echo -e "${GREEN}[✓] V2Ray manual installation completed${NC}"
}

setup_directories() {
    header
    echo -e "${YELLOW}[3] Setting up directories...${NC}"
    
    mkdir -p /etc/v2ray/users /etc/v2ray/backup /etc/v2ray/logs
    mkdir -p /usr/local/udp-dekodemo/{scripts,backup,configs}
    mkdir -p /var/log/udp-dekodemo
    
    # Create database for user management
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 /etc/v2ray/users.db "CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            uuid TEXT,
            protocol TEXT,
            port INTEGER,
            limit_ip INTEGER DEFAULT 1,
            created DATE,
            expiry DATE,
            status TEXT DEFAULT 'active',
            download_limit INTEGER DEFAULT 0,
            upload_limit INTEGER DEFAULT 0,
            last_online DATETIME
        );"
        echo -e "${GREEN}[✓] SQLite database created${NC}"
    else
        echo -e "${YELLOW}[!] SQLite not available, using file-based user management${NC}"
    fi
    
    sleep 2
}

setup_firewall() {
    header
    echo -e "${YELLOW}[4] Configuring firewall...${NC}"
    
    # Check if iptables is available
    if ! command -v iptables >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] iptables not found, installing...${NC}"
        apt install -y iptables || yum install -y iptables
    fi
    
    # Install iptables persistent if available
    if command -v apt-get >/dev/null 2>&1; then
        apt install -y iptables-persistent
    fi
    
    # Basic firewall configuration
    iptables -F
    iptables -X
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow UDP Dekodemo ports
    for port in 6000 6001 6002 6003 6004 6005 7000 8000 8080 8443 443 80; do
        iptables -A INPUT -p udp --dport $port -j ACCEPT
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
    done
    
    # Allow custom port range
    iptables -A INPUT -p udp --dport 10000:65000 -j ACCEPT
    iptables -A INPUT -p tcp --dport 10000:65000 -j ACCEPT
    
    # Save rules if possible
    if command -v iptables-save >/dev/null 2>&1; then
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
    
    echo -e "${GREEN}[✓] Firewall configured${NC}"
    sleep 2
}

create_configs() {
    header
    echo -e "${YELLOW}[5] Creating configuration files...${NC}"
    
    # Main V2Ray config
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
      "tag": "udp-dekodemo-vmess",
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
      "protocol": "vless",
      "tag": "udp-dekodemo-vless",
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
      "tag": "udp-dekodemo-trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "udp",
        "security": "none"
      }
    },
    {
      "port": 6003,
      "protocol": "shadowsocks",
      "tag": "udp-dekodemo-ss",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "",
        "network": "udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "blocked",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
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

    # Create management scripts
    create_management_scripts
    
    echo -e "${GREEN}[✓] Configuration files created${NC}"
    sleep 2
}

create_management_scripts() {
    # Main menu script
    cat > /usr/local/bin/udp-menu << 'EOF'
#!/bin/bash
# udp-menu.sh - UDP Dekodemo Management Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

LINE="==========================================================="
DLINE="-----------------------------------------------------------"

# Import functions
source /usr/local/udp-dekodemo/scripts/functions.sh

# Main menu
while true; do
    clear
    show_header
    echo -e "${CYAN}MAIN MENU${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. User Management${NC}"
    echo -e "${BLUE}2. Service Control${NC}"
    echo -e "${YELLOW}3. Backup & Restore${NC}"
    echo -e "${PURPLE}4. System Info${NC}"
    echo -e "${RED}5. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1) user_management_menu ;;
        2) service_control_menu ;;
        3) backup_restore_menu ;;
        4) system_info_menu ;;
        5)
            echo -e "${GREEN}[✓] Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
EOF

    # Functions script
    mkdir -p /usr/local/udp-dekodemo/scripts
    cat > /usr/local/udp-dekodemo/scripts/functions.sh << 'EOF'
#!/bin/bash
# functions.sh - UDP Dekodemo Functions

show_header() {
    echo -e "${CYAN}$LINE"
    echo "           UDP DEKODEMO MANAGEMENT"
    echo "           Universal Version - Termius Support"
    echo "$LINE${NC}"
    echo -e "${YELLOW}Server: $(hostname) | IP: $(curl -s ifconfig.me)${NC}"
    echo
}

user_management_menu() {
    while true; do
        clear
        show_header
        echo -e "${CYAN}USER MANAGEMENT${NC}"
        echo "$LINE"
        echo -e "${GREEN}1. Create User${NC}"
        echo -e "${GREEN}2. Create Trial User${NC}"
        echo -e "${YELLOW}3. List Users${NC}"
        echo -e "${YELLOW}4. User Details${NC}"
        echo -e "${BLUE}5. Delete User${NC}"
        echo -e "${RED}6. Back to Main${NC}"
        echo "$LINE"
        
        read -p "Choose option [1-6]: " choice
        
        case $choice in
            1) create_user ;;
            2) create_trial_user ;;
            3) list_users ;;
            4) user_details ;;
            5) delete_user ;;
            6) break ;;
            *) echo -e "${RED}[!] Invalid option!${NC}"; sleep 2 ;;
        esac
    done
}

create_user() {
    clear
    show_header
    echo -e "${CYAN}CREATE USER${NC}"
    echo "$LINE"
    
    read -p "Username: " username
    if [ -z "$username" ]; then
        echo -e "${RED}[!] Username cannot be empty!${NC}"
        pause
        return
    fi
    
    echo -e "${YELLOW}Select protocol:${NC}"
    echo "1. VMess (UDP)"
    echo "2. VLESS (UDP)"
    echo "3. Trojan (UDP)"
    echo "4. Shadowsocks (UDP)"
    read -p "Protocol [1-4]: " proto_choice
    
    case $proto_choice in
        1) protocol="vmess" ;;
        2) protocol="vless" ;;
        3) protocol="trojan" ;;
        4) protocol="shadowsocks" ;;
        *) protocol="vmess" ;;
    esac
    
    read -p "Days active: " days
    read -p "Limit IP (default 1): " limit_ip
    limit_ip=${limit_ip:-1}
    
    # Generate credentials
    case $protocol in
        "vmess"|"vless")
            uuid=$(cat /proc/sys/kernel/random/uuid)
            password=""
            ;;
        "trojan"|"shadowsocks")
            password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
            uuid=""
            ;;
    esac
    
    expiry=$(date -d "+$days days" "+%Y-%m-%d")
    port=$((6000 + RANDOM % 1000))
    
    # Save to database
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 /etc/v2ray/users.db "INSERT INTO users (username, password, uuid, protocol, port, limit_ip, created, expiry) VALUES ('$username', '$password', '$uuid', '$protocol', $port, $limit_ip, '$(date "+%Y-%m-%d")', '$expiry');"
    fi
    
    # Save to file
    cat > /etc/v2ray/users/$username.conf << EOF
username=$username
password=$password
uuid=$uuid
protocol=$protocol
port=$port
limit_ip=$limit_ip
created=$(date "+%Y-%m-%d")
expiry=$expiry
status=active
EOF

    echo
    echo -e "${GREEN}$LINE${NC}"
    echo -e "${GREEN}           USER CREATED SUCCESSFULLY${NC}"
    echo -e "${GREEN}$LINE${NC}"
    echo -e "${CYAN}Username : ${GREEN}$username${NC}"
    echo -e "${CYAN}Protocol : ${GREEN}$protocol${NC}"
    echo -e "${CYAN}Port     : ${GREEN}$port${NC}"
    [ -n "$uuid" ] && echo -e "${CYAN}UUID     : ${GREEN}$uuid${NC}"
    [ -n "$password" ] && echo -e "${CYAN}Password : ${GREEN}$password${NC}"
    echo -e "${CYAN}Limit IP : ${GREEN}$limit_ip${NC}"
    echo -e "${CYAN}Expiry   : ${GREEN}$expiry${NC}"
    echo -e "${GREEN}$LINE${NC}"
    
    pause
}

create_trial_user() {
    username="trial-$(date +%s | tail -c 4)"
    protocol="vmess"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    port=$((7000 + RANDOM % 1000))
    expiry=$(date -d "+1 days" "+%Y-%m-%d")
    
    cat > /etc/v2ray/users/$username.conf << EOF
username=$username
password=
uuid=$uuid
protocol=$protocol
port=$port
limit_ip=1
created=$(date "+%Y-%m-%d")
expiry=$expiry
status=active
EOF

    echo
    echo -e "${GREEN}$LINE${NC}"
    echo -e "${GREEN}           TRIAL USER CREATED${NC}"
    echo -e "${GREEN}$LINE${NC}"
    echo -e "${CYAN}Username : ${GREEN}$username${NC}"
    echo -e "${CYAN}Protocol : ${GREEN}$protocol${NC}"
    echo -e "${CYAN}Port     : ${GREEN}$port${NC}"
    echo -e "${CYAN}UUID     : ${GREEN}$uuid${NC}"
    echo -e "${CYAN}Expiry   : ${GREEN}$expiry (1 Day)${NC}"
    echo -e "${GREEN}$LINE${NC}"
    
    pause
}

list_users() {
    clear
    show_header
    echo -e "${CYAN}USER LIST${NC}"
    echo "$LINE"
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
    else
        echo -e "${YELLOW}Username | Protocol | Port | Expiry | Status${NC}"
        echo "$DLINE"
        for user_file in /etc/v2ray/users/*.conf; do
            if [ -f "$user_file" ]; then
                username=$(grep '^username=' "$user_file" | cut -d= -f2)
                protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
                port=$(grep '^port=' "$user_file" | cut -d= -f2)
                expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
                status=$(grep '^status=' "$user_file" | cut -d= -f2)
                
                if [ "$status" = "active" ]; then
                    status_display="${GREEN}ACTIVE${NC}"
                else
                    status_display="${RED}INACTIVE${NC}"
                fi
                
                printf "%-10s | %-8s | %-5s | %-10s | %b\\n" "$username" "$protocol" "$port" "$expiry" "$status_display"
            fi
        done
    fi
    
    echo "$LINE"
    pause
}

user_details() {
    clear
    show_header
    echo -e "${CYAN}USER DETAILS${NC}"
    echo "$LINE"
    
    read -p "Enter username: " username
    
    user_file="/etc/v2ray/users/$username.conf"
    if [ -f "$user_file" ]; then
        echo
        echo -e "${GREEN}User Details:${NC}"
        echo "$DLINE"
        cat "$user_file"
        echo "$DLINE"
        
        # Show connection info
        echo
        echo -e "${YELLOW}Connection Information:${NC}"
        server_ip=$(curl -s ifconfig.me)
        protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
        port=$(grep '^port=' "$user_file" | cut -d= -f2)
        uuid=$(grep '^uuid=' "$user_file" | cut -d= -f2 2>/dev/null || echo "N/A")
        password=$(grep '^password=' "$user_file" | cut -d= -f2 2>/dev/null || echo "N/A")
        
        echo -e "Server: $server_ip"
        echo -e "Port: $port"
        echo -e "Protocol: $protocol"
        [ "$uuid" != "N/A" ] && echo -e "UUID: $uuid"
        [ "$password" != "N/A" ] && echo -e "Password: $password"
    else
        echo -e "${RED}[!] User not found!${NC}"
    fi
    
    pause
}

delete_user() {
    clear
    show_header
    echo -e "${CYAN}DELETE USER${NC}"
    echo "$LINE"
    
    read -p "Enter username to delete: " username
    
    user_file="/etc/v2ray/users/$username.conf"
    if [ -f "$user_file" ]; then
        rm -f "$user_file"
        
        # Remove from database
        if command -v sqlite3 >/dev/null 2>&1; then
            sqlite3 /etc/v2ray/users.db "DELETE FROM users WHERE username='$username';"
        fi
        
        echo -e "${GREEN}[✓] User $username deleted successfully${NC}"
    else
        echo -e "${RED}[!] User not found!${NC}"
    fi
    
    pause
}

service_control_menu() {
    while true; do
        clear
        show_header
        echo -e "${CYAN}SERVICE CONTROL${NC}"
        echo "$LINE"
        echo -e "${GREEN}1. Start Service${NC}"
        echo -e "${YELLOW}2. Stop Service${NC}"
        echo -e "${BLUE}3. Restart Service${NC}"
        echo -e "${PURPLE}4. Service Status${NC}"
        echo -e "${RED}5. Back to Main${NC}"
        echo "$LINE"
        
        read -p "Choose option [1-5]: " choice
        
        case $choice in
            1) start_service ;;
            2) stop_service ;;
            3) restart_service ;;
            4) service_status ;;
            5) break ;;
            *) echo -e "${RED}[!] Invalid option!${NC}"; sleep 2 ;;
        esac
    done
}

start_service() {
    systemctl start v2ray
    echo -e "${GREEN}[✓] V2Ray service started${NC}"
    sleep 2
}

stop_service() {
    systemctl stop v2ray
    echo -e "${YELLOW}[!] V2Ray service stopped${NC}"
    sleep 2
}

restart_service() {
    systemctl restart v2ray
    echo -e "${GREEN}[✓] V2Ray service restarted${NC}"
    sleep 2
}

service_status() {
    clear
    show_header
    echo -e "${CYAN}SERVICE STATUS${NC}"
    echo "$LINE"
    
    echo -e "V2Ray Status: $(systemctl is-active v2ray)"
    echo -e "V2Ray Enabled: $(systemctl is-enabled v2ray)"
    echo
    echo -e "${YELLOW}Active Ports:${NC}"
    netstat -tulpn | grep v2ray || echo "No active ports found"
    
    pause
}

backup_restore_menu() {
    while true; do
        clear
        show_header
        echo -e "${CYAN}BACKUP & RESTORE${NC}"
        echo "$LINE"
        echo -e "${GREEN}1. Backup System${NC}"
        echo -e "${BLUE}2. Restore System${NC}"
        echo -e "${YELLOW}3. List Backups${NC}"
        echo -e "${RED}4. Back to Main${NC}"
        echo "$LINE"
        
        read -p "Choose option [1-4]: " choice
        
        case $choice in
            1) backup_system ;;
            2) restore_system ;;
            3) list_backups ;;
            4) break ;;
            *) echo -e "${RED}[!] Invalid option!${NC}"; sleep 2 ;;
        esac
    done
}

backup_system() {
    clear
    show_header
    echo -e "${CYAN}SYSTEM BACKUP${NC}"
    echo "$LINE"
    
    backup_name="udp-dekodemo-backup-$(date +%Y%m%d-%H%M%S)"
    backup_path="/etc/v2ray/backup/$backup_name.tar.gz"
    
    echo -e "${YELLOW}[+] Creating backup: $backup_name${NC}"
    
    # Create backup
    tar -czf "$backup_path" \
        /etc/v2ray/config.json \
        /etc/v2ray/users/ \
        /etc/v2ray/users.db \
        /etc/iptables/rules.v4 \
        /usr/local/udp-dekodemo/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup created: $backup_path${NC}"
        echo -e "${YELLOW}Size: $(du -h "$backup_path" | cut -f1)${NC}"
    else
        echo -e "${RED}[!] Backup failed!${NC}"
    fi
    
    pause
}

restore_system() {
    clear
    show_header
    echo -e "${CYAN}SYSTEM RESTORE${NC}"
    echo "$LINE"
    
    echo -e "${YELLOW}Available backups:${NC}"
    ls -1 /etc/v2ray/backup/*.tar.gz 2>/dev/null || echo "No backups found"
    echo
    
    read -p "Enter backup filename: " backup_file
    
    if [ -f "/etc/v2ray/backup/$backup_file" ]; then
        echo -e "${YELLOW}[+] Restoring from: $backup_file${NC}"
        
        # Stop service before restore
        systemctl stop v2ray
        
        # Extract backup
        tar -xzf "/etc/v2ray/backup/$backup_file" -C /
        
        # Restart service
        systemctl start v2ray
        
        echo -e "${GREEN}[✓] System restored successfully${NC}"
    else
        echo -e "${RED}[!] Backup file not found!${NC}"
    fi
    
    pause
}

list_backups() {
    clear
    show_header
    echo -e "${CYAN}BACKUP LIST${NC}"
    echo "$LINE"
    
    if ls -1 /etc/v2ray/backup/*.tar.gz >/dev/null 2>&1; then
        echo -e "${YELLOW}Backup Files:${NC}"
        echo "$DLINE"
        for backup in /etc/v2ray/backup/*.tar.gz; do
            echo -e "File: $(basename "$backup")"
            echo -e "Size: $(du -h "$backup" | cut -f1)"
            echo -e "Date: $(stat -c %y "$backup" | cut -d' ' -f1)"
            echo "$DLINE"
        done
    else
        echo -e "${RED}No backups found!${NC}"
    fi
    
    pause
}

system_info_menu() {
    clear
    show_header
    echo -e "${CYAN}SYSTEM INFORMATION${NC}"
    echo "$LINE"
    
    echo -e "${YELLOW}Server Info:${NC}"
    echo -e "Hostname: $(hostname)"
    echo -e "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
    echo -e "Kernel: $(uname -r)"
    echo -e "Uptime: $(uptime -p)"
    
    echo
    echo -e "${YELLOW}Network Info:${NC}"
    echo -e "Public IP: $(curl -s ifconfig.me)"
    echo -e "Local IP: $(hostname -I | cut -d' ' -f1)"
    
    echo
    echo -e "${YELLOW}Service Info:${NC}"
    echo -e "V2Ray Status: $(systemctl is-active v2ray)"
    echo -e "Active Users: $(ls /etc/v2ray/users/*.conf 2>/dev/null | wc -l)"
    
    echo
    echo -e "${YELLOW}Disk Usage:${NC}"
    df -h / | tail -1
    
    echo "$LINE"
    pause
}

pause() {
    echo
    read -p "Press Enter to continue..."
}
EOF

    # Backup script
    cat > /usr/local/bin/udp-backup << 'EOF'
#!/bin/bash
# udp-backup.sh - Backup UDP Dekodemo System

backup_name="udp-dekodemo-$(date +%Y%m%d-%H%M%S)"
backup_file="/etc/v2ray/backup/$backup_name.tar.gz"

echo "[+] Creating backup: $backup_name"
tar -czf "$backup_file" \
    /etc/v2ray/config.json \
    /etc/v2ray/users/ \
    /etc/v2ray/users.db \
    /etc/iptables/rules.v4 \
    /usr/local/udp-dekodemo/ \
    /var/log/v2ray/ 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[✓] Backup created: $backup_file"
    echo "[✓] Size: $(du -h "$backup_file" | cut -f1)"
else
    echo "[!] Backup failed!"
    exit 1
fi
EOF

    # Restore script
    cat > /usr/local/bin/udp-restore << 'EOF'
#!/bin/bash
# udp-restore.sh - Restore UDP Dekodemo System

if [ $# -eq 0 ]; then
    echo "Usage: udp-restore <backup-file>"
    echo "Available backups:"
    ls -1 /etc/v2ray/backup/*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

backup_file="/etc/v2ray/backup/$1"
if [ ! -f "$backup_file" ]; then
    echo "[!] Backup file not found: $1"
    exit 1
fi

echo "[+] Stopping V2Ray service..."
systemctl stop v2ray

echo "[+] Restoring from backup: $1"
tar -xzf "$backup_file" -C /

echo "[+] Starting V2Ray service..."
systemctl start v2ray

echo "[✓] System restored successfully"
EOF

    chmod +x /usr/local/bin/udp-menu
    chmod +x /usr/local/bin/udp-backup
    chmod +x /usr/local/bin/udp-restore
    chmod +x /usr/local/udp-dekodemo/scripts/functions.sh
}

setup_cron_jobs() {
    header
    echo -e "${YELLOW}[6] Setting up cron jobs...${NC}"
    
    # Add daily backup at 2 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/udp-backup >/dev/null 2>&1") | crontab -
    
    # Add service monitor every 5 minutes
    (crontab -l 2>/dev/null; echo "*/5 * * * * systemctl is-active v2ray || systemctl start v2ray") | crontab -
    
    echo -e "${GREEN}[✓] Cron jobs configured${NC}"
    sleep 2
}

start_services() {
    header
    echo -e "${YELLOW}[7] Starting services...${NC}"
    
    systemctl daemon-reload
    systemctl enable v2ray
    systemctl start v2ray
    
    # Wait for service to start
    sleep 5
    
    if systemctl is-active v2ray >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] V2Ray service started successfully${NC}"
    else
        echo -e "${RED}[!] V2Ray service failed to start${NC}"
        echo -e "${YELLOW}[!] Check logs: journalctl -u v2ray${NC}"
    fi
    
    sleep 2
}

show_completion() {
    header
    echo -e "${GREEN}$LINE"
    echo "           INSTALLATION COMPLETED!"
    echo "$LINE${NC}"
    echo
    echo -e "${CYAN}MANAGEMENT COMMANDS:${NC}"
    echo -e "${GREEN}udp-menu${NC}          - Main management menu"
    echo -e "${GREEN}udp-backup${NC}        - Quick backup"
    echo -e "${GREEN}udp-restore${NC}       - Restore from backup"
    echo
    echo -e "${CYAN}SERVICE COMMANDS:${NC}"
    echo -e "systemctl status v2ray  - Check service status"
    echo -e "systemctl restart v2ray - Restart service"
    echo -e "journalctl -u v2ray     - View logs"
    echo
    echo -e "${CYAN}BACKUP LOCATION:${NC}"
    echo -e "/etc/v2ray/backup/"
    echo
    echo -e "${YELLOW}QUICK START:${NC}"
    echo -e "1. Run ${GREEN}udp-menu${NC} to manage users"
    echo -e "2. Create trial user for testing"
    echo -e "3. Check service status"
    echo
    echo -e "${GREEN}[✓] Ready to use!${NC}"
    echo
}

# Main installation process
main() {
    detect_os
    check_root
    install_dependencies
    install_v2ray
    setup_directories
    setup_firewall
    create_configs
    setup_cron_jobs
    start_services
    show_completion
}

# Run main function
main "$@"
