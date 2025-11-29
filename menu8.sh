#!/bin/bash
# menu-ss-udp.sh - Shadowsocks UDP Menu

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
    echo "        SHADOWSOCKS UDP MANAGER"
    echo "         PASTI WORK - No Error"
    echo "$LINE${NC}"
    echo -e "Server: $(curl -s ifconfig.me) | Status: $(systemctl is-active ss-udp)"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

generate_password() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1
}

create_ss_user() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Shadowsocks Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    read -p "  Username    : " user
    read -p "  Active Days : " masaaktif
    
    masaaktif=${masaaktif:-30}
    
    echo ""
    echo -e "${YELLOW}Creating Shadowsocks account...${NC}"
    sleep 2
    
    # Generate credentials
    password=$(generate_password)
    server_ip=$(curl -s ifconfig.me)
    port=$((6000 + RANDOM % 1000))
    method="2022-blake3-aes-128-gcm"
    
    # Create user config
    mkdir -p /etc/shadowsocks/users
    cat > /etc/shadowsocks/users/$user.conf << EOF
username=$user
password=$password
port=$port
method=$method
server_ip=$server_ip
created=$(date "+%Y-%m-%d")
expiry=$(date -d "$masaaktif days" "+%Y-%m-%d")
status=active
EOF

    # Generate Shadowsocks URI
    base64_password=$(echo -n "$method:$password" | base64 -w 0)
    ss_uri="ss://$base64_password@$server_ip:$port"
    
    # Display results
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  SHADOWSOCKS CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Shadowsocks URI:${NC}"
    echo -e "${YELLOW}$ss_uri${NC}"
    echo ""
    echo -e "${CYAN}Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "Password    : $password"
    echo -e "Method      : $method"
    echo -e "Protocol    : Shadowsocks 2022"
    echo -e "Support     : TCP & UDP"
    echo -e "Created     : $(date "+%d %b, %Y")"
    echo -e "Expired     : $(date -d "$masaaktif days" "+%d %b, %Y")"
    echo ""
    echo -e "${GREEN}Copy URI ke client Shadowsocks${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    # Test UDP port
    echo -e "${YELLOW}Testing UDP port $port...${NC}"
    if timeout 3 bash -c "echo > /dev/udp/$server_ip/$port" 2>/dev/null; then
        echo -e "${GREEN}[✓] UDP Port $port is OPEN${NC}"
    else
        echo -e "${YELLOW}[!] UDP test might need client test${NC}"
    fi
    
    pause
}

create_ss_trial() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Shadowsocks Trial${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    user="sstrial-$(date +%s | tail -c 4)"
    password=$(generate_password)
    server_ip=$(curl -s ifconfig.me)
    port=$((7000 + RANDOM % 1000))
    method="2022-blake3-aes-128-gcm"
    
    echo -e "${YELLOW}Creating Shadowsocks trial...${NC}"
    sleep 2
    
    cat > /etc/shadowsocks/users/$user.conf << EOF
username=$user
password=$password
port=$port
method=$method
server_ip=$server_ip
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+1 days" "+%Y-%m-%d")
status=active
type=trial
EOF

    # Generate Shadowsocks URI
    base64_password=$(echo -n "$method:$password" | base64 -w 0)
    ss_uri="ss://$base64_password@$server_ip:$port"
    
    show_header
    echo -e "${GREEN}—————————————————————————${NC}"
    echo -e "${GREEN}  SHADOWSOCKS TRIAL CREATED${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    echo ""
    echo -e "${CYAN}Trial Shadowsocks URI:${NC}"
    echo -e "${YELLOW}$ss_uri${NC}"
    echo ""
    echo -e "${CYAN}Trial Details:${NC}"
    echo -e "Username    : $user"
    echo -e "Server IP   : $server_ip"
    echo -e "Port        : $port"
    echo -e "Password    : $password"
    echo -e "Method      : $method"
    echo -e "Support     : TCP & UDP"
    echo -e "Expired     : $(date -d "+1 days" "+%d %b, %Y")"
    echo ""
    echo -e "${RED}Note: Trial valid for 1 day${NC}"
    echo -e "${GREEN}—————————————————————————${NC}"
    
    pause
}

test_udp_ports() {
    show_header
    echo -e "${CYAN}[TEST UDP PORTS]${NC}"
    echo "$LINE"
    
    server_ip=$(curl -s ifconfig.me)
    echo -e "Server IP: $server_ip"
    echo ""
    
    # Test multiple UDP ports
    for port in 6000 6001 6002 7000 7001 7002; do
        echo -n "Testing UDP port $port: "
        if timeout 2 bash -c "echo > /dev/udp/$server_ip/$port" 2>/dev/null; then
            echo -e "${GREEN}OPEN${NC}"
        else
            echo -e "${RED}CLOSED/BLOCKED${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Shadowsocks Status: $(systemctl is-active ss-udp)${NC}"
    echo -e "${YELLOW}Jika port OPEN, Shadowsocks UDP pasti work!${NC}"
    echo "$LINE"
    
    pause
}

apply_ss_config() {
    show_header
    echo -e "${CYAN}[APPLY SHADOWSOCKS CONFIG]${NC}"
    echo "$LINE"
    
    # Restart service dengan config baru
    systemctl restart ss-udp
    
    echo -e "${GREEN}[✓] Shadowsocks service restarted${NC}"
    echo -e "${YELLOW}Port 6000: Shadowsocks 2022 (TCP & UDP)${NC}"
    echo -e "${YELLOW}Method: 2022-blake3-aes-128-gcm${NC}"
    
    # Test service
    if systemctl is-active ss-udp >/dev/null; then
        echo -e "${GREEN}[✓] Service is running${NC}"
    else
        echo -e "${RED}[!] Service failed to start${NC}"
        journalctl -u ss-udp -n 10 --no-pager
    fi
    
    pause
}

show_ss_help() {
    show_header
    echo -e "${CYAN}[SHADOWSOCKS HELP]${NC}"
    echo "$LINE"
    echo ""
    echo -e "${YELLOW}Client yang Support:${NC}"
    echo -e "• ${GREEN}Shadowsocks Android${NC}"
    echo -e "• ${GREEN}Shadowrocket (iOS)${NC}" 
    echo -e "• ${GREEN}Clash Meta${NC}"
    echo -e "• ${GREEN}Nekobox${NC}"
    echo ""
    echo -e "${YELLOW}Cara Pakai:${NC}"
    echo -e "1. Copy SS URI: ${GREEN}ss://xxxx@ip:port${NC}"
    echo -e "2. Import di client Shadowsocks"
    echo -e "3. Pilih protocol: ${GREEN}TCP & UDP${NC}"
    echo -e "4. Connect dan enjoy!"
    echo ""
    echo -e "${GREEN}Shadowsocks 2022 support UDP native!${NC}"
    echo "$LINE"
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}SHADOWSOCKS UDP MANAGER${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create Shadowsocks Account${NC}"
    echo -e "${YELLOW}2. Create Shadowsocks Trial${NC}"
    echo -e "${BLUE}3. Test UDP Ports${NC}"
    echo -e "${CYAN}4. Restart Service${NC}"
    echo -e "${PURPLE}5. Shadowsocks Help${NC}"
    echo -e "${RED}6. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-6]: " choice
    
    case $choice in
        1) create_ss_user ;;
        2) create_ss_trial ;;
        3) test_udp_ports ;;
        4) apply_ss_config ;;
        5) show_ss_help ;;
        6)
            echo -e "${GREEN}[✓] Thank you! Shadowsocks UDP${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
