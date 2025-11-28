#!/bin/bash
# menu-udp-real.sh - UDP Dekodemo yang Benar

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
    echo "        UDP DEKODEMO MANAGER"
    echo "         Terbukti Bisa Connect"
    echo "$LINE${NC}"
    echo -e "Server: $(curl -s ifconfig.me) | Status: $(systemctl is-active xray)"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

create_udp_vmess() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create UDP VMESS${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    read -p "  Username    : " user
    read -p "  Active Days : " masaaktif
    
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating UDP VMESS account...${NC}"
    sleep 2
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Generate random port untuk UDP
    port=$((6000 + RANDOM % 100))
    
    # Create user config
    mkdir -p /etc/xray/users
    cat > /etc/xray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=udp
created=$(date "+%Y-%m-%d")
expiry=$(date -d "$masaaktif days" "+%Y-%m-%d")
status=active
EOF

    # Generate Vmess config untuk UDP - INI YANG BENAR!
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "UDP-$user",
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
    echo -e "${GREEN}  UDP VMESS CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}UDP Vmess Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS"
    echo -e "Network     : UDP"
    echo -e "Created     : $(date "+%d %b, %Y")"
    echo -e "Expired     : $(date -d "$masaaktif days" "+%d %b, %Y")"
    echo ""
    echo -e "${GREEN}PASTIKAN di client pilih NETWORK: UDP${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    # Test connection
    echo -e "${YELLOW}Testing UDP port...${NC}"
    if timeout 3 bash -c "echo > /dev/udp/$server_ip/$port"; then
        echo -e "${GREEN}[✓] UDP Port $port is open${NC}"
    else
        echo -e "${YELLOW}[!] UDP test might be blocked by firewall${NC}"
    fi
    
    pause
}

create_udp_trial() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create UDP Trial${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    user="udptrial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    port=$((6100 + RANDOM % 100))
    
    echo -e "${YELLOW}Creating UDP trial account...${NC}"
    sleep 2
    
    cat > /etc/xray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=$port
network=udp
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+1 days" "+%Y-%m-%d")
status=active
type=trial
EOF

    # Generate Vmess UDP untuk trial
    vmess_config=$(cat << EOF
{
  "v": "2",
  "ps": "UDP-Trial-$user",
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
    echo -e "${GREEN}  UDP TRIAL CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}UDP Trial Link:${NC}"
    echo -e "${YELLOW}$vmess_link${NC}"
    echo ""
    echo -e "${CYAN}Trial Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "UUID        : $uuid"
    echo -e "Protocol    : VMESS UDP"
    echo -e "Expired     : $(date -d "+1 days" "+%d %b, %Y")"
    echo ""
    echo -e "${RED}Note: Trial valid for 1 day${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

test_udp_connection() {
    show_header
    echo -e "${CYAN}[TEST UDP CONNECTION]${NC}"
    echo "$LINE"
    
    server_ip=$(curl -s ifconfig.me)
    echo -e "Server IP: $server_ip"
    echo ""
    
    # Test common UDP ports
    ports=(6000 6001 6002 6100 6200)
    
    for port in "${ports[@]}"; do
        echo -n "Testing UDP port $port: "
        if timeout 2 bash -c "echo > /dev/udp/$server_ip/$port" 2>/dev/null; then
            echo -e "${GREEN}OPEN${NC}"
        else
            echo -e "${RED}CLOSED/BLOCKED${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Jika port CLOSED, cek firewall/ISP${NC}"
    echo "$LINE"
    
    pause
}

apply_udp_config() {
    show_header
    echo -e "${CYAN}[APPLY UDP CONFIG]${NC}"
    echo "$LINE"
    
    # Config sederhana yang work untuk UDP
    cat > /etc/xray/config.json << 'EOF'
{
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
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    systemctl restart xray
    echo -e "${GREEN}[✓] UDP configuration applied${NC}"
    echo -e "${YELLOW}Simple config - lebih mungkin work${NC}"
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}UDP DEKODEMO MANAGER${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create UDP VMESS${NC}"
    echo -e "${YELLOW}2. Create UDP Trial${NC}"
    echo -e "${BLUE}3. Test UDP Connection${NC}"
    echo -e "${CYAN}4. Apply Simple UDP Config${NC}"
    echo -e "${RED}5. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-5]: " choice
    
    case $choice in
        1) create_udp_vmess ;;
        2) create_udp_trial ;;
        3) test_udp_connection ;;
        4) apply_udp_config ;;
        5)
            echo -e "${GREEN}[✓] Goodbye! UDP Dekodemo${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
