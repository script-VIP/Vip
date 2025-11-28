#!/bin/bash
# menu-dekodemo.sh - Dekodemo V2Ray Manager

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
    echo "           DEKODEMO V2RAY MANAGER"
    echo "         Unlimited Internet Optimized"
    echo "$LINE${NC}"
    echo -e "Server: $(curl -s ifconfig.me) | Status: $(systemctl is-active v2ray)"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

apply_dekodemo_config() {
    show_header
    echo -e "${CYAN}[APPLY DEKODEMO CONFIGURATION]${NC}"
    echo "$LINE"
    
    # Create optimized Dekodemo config
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
        "network": "udp",
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

    systemctl restart v2ray
    echo -e "${GREEN}[✓] Dekodemo configuration applied${NC}"
    echo -e "${YELLOW}Port 6000: VMESS UDP${NC}"
    echo -e "${YELLOW}Port 6001: VMESS WS (/dekodemo)${NC}"
    
    pause
}

create_vmess_udp() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create VMESS UDP Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    while true; do
        read -p "  Username    : " user
        if [ -z "$user" ]; then
            echo -e "${RED}[!] Username cannot be empty!${NC}"
            continue
        fi
        
        if [ -f "/etc/v2ray/users/$user.conf" ]; then
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
    echo -e "${YELLOW}Creating VMESS UDP account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    port=6000
    
    # Calculate expiry
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    expe=$(date -d "$masaaktif days" +"%d %b, %Y")
    tnggl=$(date +"%d %b, %Y")
    
    # Create user config
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=udp
limit_ip=$iplimit
created=$tnggl
expiry=$expe
status=active
EOF

    # Generate Vmess config
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "Dekodemo-$user",
  "add": "$server_ip",
  "port": "$port",
  "id": "$uuid",
  "aid": "0",
  "net": "udp",
  "type": "none",
  "host": "",
  "tls": "none"
}
EOF
)

    vmess_link="vmess://$(echo "$vmess_config" | base64 -w 0)"
    
    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  VMESS UDP CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Vmess Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS"
    echo -e "Network     : UDP"
    echo -e "Limit IP    : $iplimit"
    echo -e "Created     : $tnggl"
    echo -e "Expired     : $expe"
    echo ""
    echo -e "${GREEN}Copy this Vmess link to your V2Ray client${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

create_vmess_ws() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create VMESS WS Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    read -p "  Username    : " user
    read -p "  Active Days : " masaaktif
    
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating VMESS WebSocket account...${NC}"
    sleep 2
    
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    port=6001
    
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    expe=$(date -d "$masaaktif days" +"%d %b, %Y")
    
    cat > /etc/v2ray/users/$user-ws.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=ws
path=/dekodemo
created=$(date "+%Y-%m-%d")
expiry=$exp
status=active
EOF

    # Generate Vmess WS config
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "Dekodemo-WS-$user",
  "add": "$server_ip",
  "port": "$port",
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

    vmess_link="vmess://$(echo "$vmess_config" | base64 -w 0)"
    
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  VMESS WS CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Vmess WS Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "Path        : /dekodemo"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS WebSocket"
    echo -e "Created     : $(date "+%d %b, %Y")"
    echo -e "Expired     : $expe"
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
    port=6000
    
    echo -e "${YELLOW}Generating trial account...${NC}"
    sleep 2
    
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=udp
limit_ip=1
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+1 days" "+%Y-%m-%d")
status=active
type=trial
EOF

    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "Dekodemo-Trial-$user",
  "add": "$server_ip",
  "port": "$port",
  "id": "$uuid",
  "aid": "0",
  "net": "udp",
  "type": "none",
  "host": "",
  "tls": "none"
}
EOF
)

    vmess_link="vmess://$(echo "$vmess_config" | base64 -w 0)"
    
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  TRIAL ACCOUNT CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Trial Vmess Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Trial Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS UDP"
    echo -e "Limit IP    : 1"
    echo -e "Expired     : $(date -d "+1 days" "+%d %b, %Y")"
    echo ""
    echo -e "${RED}Note: Trial valid for 1 day only${NC}"
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
        echo -e "${YELLOW}Username     | Protocol | Port  | Network | Expiry${NC}"
        echo "$DLINE"
        for user_file in /etc/v2ray/users/*.conf; do
            username=$(grep '^username=' "$user_file" | cut -d= -f2)
            protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
            port=$(grep '^port=' "$user_file" | cut -d= -f2)
            network=$(grep '^network=' "$user_file" | cut -d= -f2)
            expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
            user_type=$(grep '^type=' "$user_file" | cut -d= -f2 2>/dev/null || echo "regular")
            
            if [ "$user_type" = "trial" ]; then
                type_color="${YELLOW}*${NC}"
            else
                type_color="${GREEN} ${NC}"
            fi
            
            printf "%-12s | %-8s | %-5s | %-6s | %-10s %b\n" "$username" "$protocol" "$port" "$network" "$expiry" "$type_color"
        done
        echo ""
        echo -e "${YELLOW}* = Trial account${NC}"
    fi
    
    echo "$LINE"
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}DEKODEMO V2RAY MANAGER${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Apply Dekodemo Config${NC}"
    echo -e "${GREEN}2. Create VMESS UDP${NC}"
    echo -e "${BLUE}3. Create VMESS WS${NC}"
    echo -e "${YELLOW}4. Create Trial Account${NC}"
    echo -e "${CYAN}5. List Users${NC}"
    echo -e "${RED}6. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-6]: " choice
    
    case $choice in
        1) apply_dekodemo_config ;;
        2) create_vmess_udp ;;
        3) create_vmess_ws ;;
        4) create_trial ;;
        5) list_users ;;
        6)
            echo -e "${GREEN}[✓] Thank you for using Dekodemo V2Ray!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
