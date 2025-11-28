#!/bin/bash
# menu-fixed.sh - Dekodemo Menu Fixed

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

LINE="==============================================="

show_header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        DEKODEMO V2RAY MANAGER"
    echo "         TCP & WebSocket Only"
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
    echo -e "${GREEN}  Create VMESS TCP Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    read -p "  Username    : " user
    read -p "  Active Days : " masaaktif
    
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating VMESS TCP account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    port=6000
    
    # Create user config
    mkdir -p /etc/v2ray/users
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=tcp
created=$(date "+%Y-%m-%d")
expiry=$(date -d "$masaaktif days" "+%Y-%m-%d")
status=active
EOF

    # Generate Vmess TCP config
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "Dekodemo-TCP-$user",
  "add": "$server_ip",
  "port": "$port",
  "id": "$uuid",
  "aid": "0",
  "net": "tcp",
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
    echo -e "${GREEN}  VMESS TCP CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Vmess TCP Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS TCP"
    echo -e "Created     : $(date "+%d %b, %Y")"
    echo -e "Expired     : $(date -d "$masaaktif days" "+%d %b, %Y")"
    echo ""
    echo -e "${GREEN}Copy this link to your V2Ray client${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

create_vmess_ws() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create VMESS WebSocket${NC}"
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
    
    cat > /etc/v2ray/users/$user-ws.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=ws
path=/dekodemo
created=$(date "+%Y-%m-%d")
expiry=$(date -d "$masaaktif days" "+%Y-%m-%d")
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
    echo -e "${CYAN}Vmess WebSocket Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : 6001"
    echo -e "Path        : /dekodemo"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS WebSocket"
    echo -e "Expired     : $(date -d "$masaaktif days" "+%d %b, %Y")"
    echo ""
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}DEKODEMO V2RAY MANAGER${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create VMESS TCP${NC}"
    echo -e "${BLUE}2. Create VMESS WebSocket${NC}"
    echo -e "${YELLOW}3. Service Status${NC}"
    echo -e "${RED}4. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-4]: " choice
    
    case $choice in
        1) create_vmess_tcp ;;
        2) create_vmess_ws ;;
        3) 
            show_header
            echo -e "V2Ray Status: $(systemctl is-active v2ray)"
            echo -e "Port 6000: VMESS TCP"
            echo -e "Port 6001: VMESS WS (/dekodemo)"
            pause
            ;;
        4)
            echo -e "${GREEN}[✓] Thank you!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
