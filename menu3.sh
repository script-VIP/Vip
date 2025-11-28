#!/bin/bash
# menu.sh - UDP Dekodemo Management Menu (Simplified)

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
    echo "           Simplified Version"
    echo "$LINE${NC}"
    echo
}

create_user() {
    show_menu
    echo -e "${CYAN}[CREATE USER]${NC}"
    echo "$LINE"
    
    read -p "Username: " user
    if [ -z "$user" ]; then
        echo -e "${RED}[!] Username required!${NC}"
        return
    fi
    
    # Check if user exists
    if [ -f "/etc/v2ray/users/$user.conf" ]; then
        echo -e "${RED}[!] User already exists!${NC}"
        return
    fi
    
    read -p "Days active: " days
    days=${days:-30}
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "manual-uuid-required")
    server_ip=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
    
    # Create user config
    mkdir -p /etc/v2ray/users
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=6000
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+$days days" "+%Y-%m-%d")
status=active
EOF

    echo
    echo -e "${GREEN}[✓] USER CREATED${NC}"
    echo "$LINE"
    echo -e "Username: $user"
    echo -e "UUID: $uuid"
    echo -e "Port: 6000"
    echo -e "Expiry: $(date -d "+$days days" "+%Y-%m-%d")"
    echo "$LINE"
    
    # Generate Vmess link
    vmess_config='{"v":"2","ps":"'$user'","add":"'$server_ip'","port":"6000","id":"'$uuid'","aid":"0","net":"udp","type":"none","host":"'$server_ip'","tls":"none"}'
    vmess_link="vmess://$(echo "$vmess_config" | base64 -w 0 2>/dev/null || echo "manual-config-required")"
    
    echo -e "Vmess Link:"
    echo -e "$vmess_link"
    echo "$LINE"
    
    read -p "Press Enter to continue..."
}

create_trial() {
    show_menu
    user="trial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "trial-uuid")
    server_ip=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
    
    mkdir -p /etc/v2ray/users
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port=6000
created=$(date "+%Y-%m-%d")
expiry=$(date -d "+1 days" "+%Y-%m-%d")
status=active
type=trial
EOF

    echo -e "${GREEN}[✓] TRIAL USER CREATED${NC}"
    echo "$LINE"
    echo -e "Username: $user"
    echo -e "UUID: $uuid" 
    echo -e "Port: 6000"
    echo -e "Expiry: $(date -d "+1 days" "+%Y-%m-%d")"
    echo "$LINE"
    
    vmess_config='{"v":"2","ps":"'$user'-Trial","add":"'$server_ip'","port":"6000","id":"'$uuid'","aid":"0","net":"udp","type":"none","host":"'$server_ip'","tls":"none"}'
    vmess_link="vmess://$(echo "$vmess_config" | base64 -w 0 2>/dev/null || echo "manual-config-required")"
    
    echo -e "Trial Link:"
    echo -e "$vmess_link"
    echo "$LINE"
    
    read -p "Press Enter to continue..."
}

list_users() {
    show_menu
    echo -e "${CYAN}[USER LIST]${NC}"
    echo "$LINE"
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
    else
        for user_file in /etc/v2ray/users/*.conf; do
            username=$(grep '^username=' "$user_file" | cut -d= -f2)
            expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
            echo -e "User: $username | Expiry: $expiry"
        done
    fi
    
    echo "$LINE"
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    show_menu
    echo "1. Create User"
    echo "2. Create Trial User" 
    echo "3. List Users"
    echo "4. Exit"
    echo "$LINE"
    
    read -p "Choose [1-4]: " choice
    
    case $choice in
        1) create_user ;;
        2) create_trial ;;
        3) list_users ;;
        4) 
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Invalid choice!${NC}"
            sleep 2
            ;;
    esac
done
