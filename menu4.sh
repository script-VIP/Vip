#!/bin/bash
# menu-httpcustom.sh - HTTP Custom Compatible Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

LINE="==============================================="
DLINE="-----------------------------------------------"

show_header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        HTTP CUSTOM V2RAY MANAGER"
    echo "         Support TCP/WS Protocol"
    echo "$LINE${NC}"
    echo -e "Server: $(curl -s ifconfig.me) | Status: $(systemctl is-active v2ray)"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

create_vmess_tcp() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Vmess TCP Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    # Username input
    while true; do
        read -p "  Username    : " user
        if [ -z "$user" ]; then
            echo -e "${RED}[!] Username cannot be empty!${NC}"
            continue
        fi
        
        if [ -f "/etc/v2ray/users/$user-tcp.conf" ]; then
            echo -e "${RED}[!] Username already exists!${NC}"
        else
            break
        fi
    done
    
    read -p "  Limit IP    : " iplimit
    read -p "  Active Days : " masaaktif
    
    iplimit=${iplimit:-1}
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Calculate expiry
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    expe=$(date -d "$masaaktif days" +"%d %b, %Y")
    tnggl=$(date +"%d %b, %Y")
    
    # Create user config
    cat > /etc/v2ray/users/$user-tcp.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=8080
network=tcp
limit_ip=$iplimit
created=$tnggl
expiry=$expe
expiry_date=$exp
status=active
type=tcp
EOF

    # Generate Vmess TCP config
    vmess_tcp=$(cat << EOF
{
  "v": "2",
  "ps": "$user-TCP",
  "add": "$server_ip",
  "port": "8080",
  "id": "$uuid",
  "aid": "0",
  "net": "tcp",
  "type": "none",
  "host": "",
  "tls": "none"
}
EOF
)

    vmesslink_tcp="vmess://$(echo "$vmess_tcp" | base64 -w 0)"
    
    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  ACCOUNT CREATED SUCCESS${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Details Account:${NC}"
    echo -e "Username    : $user"
    echo -e "Protocol    : VMESS TCP"
    echo -e "Server      : $server_ip"
    echo -e "Port        : 8080"
    echo -e "UUID        : $uuid"
    echo -e "Limit IP    : $iplimit"
    echo -e "Created     : $tnggl"
    echo -e "Expired     : $expe"
    echo ""
    echo -e "${YELLOW}Vmess TCP Link:${NC}"
    echo -e "$vmesslink_tcp"
    echo ""
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

create_vmess_ws() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Vmess WS Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    # Username input
    while true; do
        read -p "  Username    : " user
        if [ -z "$user" ]; then
            echo -e "${RED}[!] Username cannot be empty!${NC}"
            continue
        fi
        
        if [ -f "/etc/v2ray/users/$user-ws.conf" ]; then
            echo -e "${RED}[!] Username already exists!${NC}"
        else
            break
        fi
    done
    
    read -p "  Limit IP    : " iplimit
    read -p "  Active Days : " masaaktif
    
    iplimit=${iplimit:-1}
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Calculate expiry
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    expe=$(date -d "$masaaktif days" +"%d %b, %Y")
    tnggl=$(date +"%d %b, %Y")
    
    # Create user config
    cat > /etc/v2ray/users/$user-ws.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=8081
network=ws
path=/dekodemo
limit_ip=$iplimit
created=$tnggl
expiry=$expe
expiry_date=$exp
status=active
type=ws
EOF

    # Generate Vmess WS config with /dekodemo path
    vmess_ws=$(cat << EOF
{
  "v": "2",
  "ps": "$user-WS",
  "add": "$server_ip",
  "port": "8081",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "path": "/dekodemo",
  "host": "$server_ip",
  "tls": "none"
}
EOF
)

    vmesslink_ws="vmess://$(echo "$vmess_ws" | base64 -w 0)"
    
    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  ACCOUNT CREATED SUCCESS${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Details Account:${NC}"
    echo -e "Username    : $user"
    echo -e "Protocol    : VMESS WebSocket"
    echo -e "Server      : $server_ip"
    echo -e "Port        : 8081"
    echo -e "Path        : /dekodemo"
    echo -e "UUID        : $uuid"
    echo -e "Limit IP    : $iplimit"
    echo -e "Created     : $tnggl"
    echo -e "Expired     : $expe"
    echo ""
    echo -e "${YELLOW}Vmess WS Link:${NC}"
    echo -e "$vmesslink_ws"
    echo ""
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

create_vless_ws() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Vless WS Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    read -p "  Username    : " user
    read -p "  Active Days : " masaaktif
    
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Calculate expiry
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    expe=$(date -d "$masaaktif days" +"%d %b, %Y")
    
    # Create user config
    cat > /etc/v2ray/users/$user-vless.conf << EOF
username=$user
uuid=$uuid
protocol=vless
port=8082
network=ws
path=/dekodemo
created=$(date "+%Y-%m-%d")
expiry=$exp
status=active
type=vless
EOF

    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  VLESS ACCOUNT CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Details Account:${NC}"
    echo -e "Username    : $user"
    echo -e "Protocol    : VLESS WebSocket"
    echo -e "Server      : $server_ip"
    echo -e "Port        : 8082"
    echo -e "Path        : /dekodemo"
    echo -e "UUID        : $uuid"
    echo -e "Created     : $(date "+%d %b, %Y")"
    echo -e "Expired     : $expe"
    echo ""
    echo -e "${YELLOW}VLESS WS Config:${NC}"
    echo -e "vless://$uuid@$server_ip:8082?type=ws&path=%2Fdekodemo&host=$server_ip#Vless-$user"
    echo ""
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

create_trial() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Trial Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    user="trial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    echo -e "${YELLOW}Generating trial account...${NC}"
    sleep 2
    
    # Create trial config
    cat > /etc/v2ray/users/$user-trial.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=8080
network=tcp
limit_ip=1
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+1 days" "+%Y-%m-%d")
status=active
type=trial
EOF

    # Generate Vmess TCP for trial
    vmess_trial=$(cat << EOF
{
  "v": "2",
  "ps": "$user-Trial",
  "add": "$server_ip",
  "port": "8080",
  "id": "$uuid",
  "aid": "0",
  "net": "tcp",
  "type": "none",
  "host": "",
  "tls": "none"
}
EOF
)

    vmesslink_trial="vmess://$(echo "$vmess_trial" | base64 -w 0)"
    
    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  TRIAL ACCOUNT CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Trial Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Protocol    : VMESS TCP"
    echo -e "Server      : $server_ip"
    echo -e "Port        : 8080"
    echo -e "UUID        : $uuid"
    echo -e "Limit IP    : 1"
    echo -e "Expired     : $(date -d "+1 days" "+%d %b, %Y")"
    echo ""
    echo -e "${YELLOW}Trial Link:${NC}"
    echo -e "$vmesslink_trial"
    echo ""
    echo -e "${RED}Note: Trial account valid for 1 day only${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

list_users() {
    show_header
    echo -e "${CYAN}[USER LIST]${NC}"
    echo "$LINE"
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
    else
        echo -e "${YELLOW}Username     | Type   | Protocol | Port  | Expiry${NC}"
        echo "$DLINE"
        for user_file in /etc/v2ray/users/*.conf; do
            username=$(grep '^username=' "$user_file" | cut -d= -f2)
            protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
            port=$(grep '^port=' "$user_file" | cut -d= -f2)
            expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
            user_type=$(grep '^type=' "$user_file" | cut -d= -f2 2>/dev/null || echo "regular")
            
            if [ "$user_type" = "trial" ]; then
                type_color="${YELLOW}TRIAL${NC}"
            else
                type_color="${GREEN}REGULAR${NC}"
            fi
            
            printf "%-12s | %b | %-8s | %-5s | %-10s\n" "$username" "$type_color" "$protocol" "$port" "$expiry"
        done
    fi
    
    echo "$LINE"
    pause
}

service_status() {
    show_header
    echo -e "${CYAN}[SERVICE STATUS]${NC}"
    echo "$LINE"
    
    echo -e "V2Ray Status: $(systemctl is-active v2ray)"
    echo ""
    echo -e "${YELLOW}Active Ports:${NC}"
    echo -e "8080 - VMESS TCP"
    echo -e "8081 - VMESS WS (/dekodemo)"
    echo -e "8082 - VLESS WS (/dekodemo)"
    echo ""
    echo -e "${YELLOW}Server Info:${NC}"
    echo -e "IP: $(curl -s ifconfig.me)"
    echo -e "Total Users: $(ls /etc/v2ray/users/*.conf 2>/dev/null | wc -l)"
    
    echo "$LINE"
    pause
}

apply_config() {
    show_header
    echo -e "${CYAN}[APPLY CONFIGURATION]${NC}"
    echo "$LINE"
    
    # Create main config with /dekodemo path
    cat > /etc/v2ray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 8080,
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
      "port": 8081,
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
    },
    {
      "port": 8082,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
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

    systemctl restart v2ray
    echo -e "${GREEN}[✓] Configuration applied with /dekodemo path${NC}"
    echo -e "${YELLOW}WebSocket path: /dekodemo${NC}"
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}MAIN MENU - HTTP CUSTOM${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create VMESS TCP${NC}"
    echo -e "${GREEN}2. Create VMESS WS (/dekodemo)${NC}"
    echo -e "${BLUE}3. Create VLESS WS (/dekodemo)${NC}"
    echo -e "${YELLOW}4. Create Trial Account${NC}"
    echo -e "${CYAN}5. List Users${NC}"
    echo -e "${PURPLE}6. Service Status${NC}"
    echo -e "${GREEN}7. Apply /dekodemo Config${NC}"
    echo -e "${RED}8. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-8]: " choice
    
    case $choice in
        1) create_vmess_tcp ;;
        2) create_vmess_ws ;;
        3) create_vless_ws ;;
        4) create_trial ;;
        5) list_users ;;
        6) service_status ;;
        7) apply_config ;;
        8)
            echo -e "${GREEN}[✓] Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
