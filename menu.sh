#!/bin/bash
# menu.sh - UDP Dekodemo Management Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

LINE="==============================================="
DLINE="-----------------------------------------------"

show_header() {
    clear
    echo -e "${CYAN}$LINE"
    echo "        UDP DEKODEMO MANAGEMENT"
    echo "              Menu System"
    echo "$LINE${NC}"
    echo -e "Server: $(curl -s ifconfig.me) | Status: $(systemctl is-active v2ray)"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

create_user() {
    show_header
    echo -e "${CYAN}[CREATE USER]${NC}"
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
    read -p "Protocol [1-3]: " proto_choice
    
    case $proto_choice in
        1) protocol="vmess" ;;
        2) protocol="vless" ;;
        3) protocol="trojan" ;;
        *) protocol="vmess" ;;
    esac
    
    read -p "Days active: " days
    if [ -z "$days" ] || [ "$days" -lt 1 ]; then
        echo -e "${RED}[!] Minimum 1 day!${NC}"
        pause
        return
    fi
    
    read -p "Limit IP (default 1): " limit_ip
    limit_ip=${limit_ip:-1}
    
    # Generate credentials
    case $protocol in
        "vmess"|"vless")
            uuid=$(cat /proc/sys/kernel/random/uuid)
            password=""
            ;;
        "trojan")
            password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
            uuid=""
            ;;
    esac
    
    expiry=$(date -d "+$days days" "+%Y-%m-%d")
    port=$((6000 + RANDOM % 1000))
    
    # Save user config
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

create_trial() {
    show_header
    echo -e "${CYAN}[CREATE TRIAL USER]${NC}"
    echo "$LINE"
    
    username="trial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    port=$((7000 + RANDOM % 1000))
    expiry=$(date -d "+1 days" "+%Y-%m-%d")
    
    cat > /etc/v2ray/users/$username.conf << EOF
username=$username
uuid=$uuid
protocol=vmess
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
    echo -e "${CYAN}Protocol : ${GREEN}vmess${NC}"
    echo -e "${CYAN}Port     : ${GREEN}$port${NC}"
    echo -e "${CYAN}UUID     : ${GREEN}$uuid${NC}"
    echo -e "${CYAN}Limit IP : ${GREEN}1${NC}"
    echo -e "${CYAN}Expiry   : ${GREEN}$expiry (1 Day)${NC}"
    echo -e "${GREEN}$LINE${NC}"
    
    pause
}

list_users() {
    show_header
    echo -e "${CYAN}[USER LIST]${NC}"
    echo "$LINE"
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
    else
        echo -e "${YELLOW}Username     | Protocol | Port  | Expiry     | Status${NC}"
        echo "$DLINE"
        for user_file in /etc/v2ray/users/*.conf; do
            if [ -f "$user_file" ]; then
                username=$(grep '^username=' "$user_file" | cut -d= -f2)
                protocol=$(grep '^protocol=' "$user_file" | cut -d= -f2)
                port=$(grep '^port=' "$user_file" | cut -d= -f2)
                expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
                status=$(grep '^status=' "$user_file" | cut -d= -f2)
                
                if [ "$status" = "active" ]; then
                    status_color="${GREEN}ACTIVE${NC}"
                else
                    status_color="${RED}INACTIVE${NC}"
                fi
                
                printf "%-12s | %-8s | %-5s | %-10s | %b\n" "$username" "$protocol" "$port" "$expiry" "$status_color"
            fi
        done
    fi
    
    echo "$LINE"
    pause
}

user_details() {
    show_header
    echo -e "${CYAN}[USER DETAILS]${NC}"
    echo "$LINE"
    
    read -p "Enter username: " username
    
    user_file="/etc/v2ray/users/$username.conf"
    if [ -f "$user_file" ]; then
        echo
        echo -e "${GREEN}User Configuration:${NC}"
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
    show_header
    echo -e "${CYAN}[DELETE USER]${NC}"
    echo "$LINE"
    
    read -p "Enter username to delete: " username
    
    user_file="/etc/v2ray/users/$username.conf"
    if [ -f "$user_file" ]; then
        rm -f "$user_file"
        echo -e "${GREEN}[✓] User $username deleted successfully${NC}"
    else
        echo -e "${RED}[!] User not found!${NC}"
    fi
    
    pause
}

service_status() {
    show_header
    echo -e "${CYAN}[SERVICE STATUS]${NC}"
    echo "$LINE"
    
    echo -e "V2Ray Status: $(systemctl is-active v2ray)"
    echo -e "V2Ray Enabled: $(systemctl is-enabled v2ray)"
    echo
    echo -e "${YELLOW}Active Connections:${NC}"
    netstat -tulpn | grep v2ray | head -10 || echo "No active connections"
    
    echo
    echo -e "${YELLOW}Server Information:${NC}"
    echo -e "IP: $(curl -s ifconfig.me)"
    echo -e "Hostname: $(hostname)"
    echo -e "Uptime: $(uptime -p)"
    
    pause
}

backup_system() {
    show_header
    echo -e "${CYAN}[BACKUP SYSTEM]${NC}"
    echo "$LINE"
    
    backup_name="deko-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    backup_path="/etc/v2ray/backup/$backup_name"
    
    echo -e "${YELLOW}[+] Creating backup...${NC}"
    tar -czf "$backup_path" /etc/v2ray/config.json /etc/v2ray/users/ /usr/local/bin/deko-menu /usr/local/bin/deko-backup 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup created: $backup_name${NC}"
        echo -e "${YELLOW}Size: $(du -h "$backup_path" | cut -f1)${NC}"
    else
        echo -e "${RED}[!] Backup failed!${NC}"
    fi
    
    pause
}

restore_system() {
    show_header
    echo -e "${CYAN}[RESTORE SYSTEM]${NC}"
    echo "$LINE"
    
    echo -e "${YELLOW}Available backups:${NC}"
    ls -1 /etc/v2ray/backup/ 2>/dev/null || echo "No backups found"
    echo
    
    read -p "Enter backup filename: " backup_file
    
    if [ -f "/etc/v2ray/backup/$backup_file" ]; then
        echo -e "${YELLOW}[+] Restoring from backup...${NC}"
        
        # Stop service
        systemctl stop v2ray
        
        # Extract backup
        tar -xzf "/etc/v2ray/backup/$backup_file" -C /
        
        # Start service
        systemctl start v2ray
        
        echo -e "${GREEN}[✓] System restored successfully${NC}"
    else
        echo -e "${RED}[!] Backup file not found!${NC}"
    fi
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}MAIN MENU${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create User${NC}"
    echo -e "${GREEN}2. Create Trial User${NC}"
    echo -e "${YELLOW}3. List Users${NC}"
    echo -e "${YELLOW}4. User Details${NC}"
    echo -e "${RED}5. Delete User${NC}"
    echo -e "${BLUE}6. Service Status${NC}"
    echo -e "${CYAN}7. Backup System${NC}"
    echo -e "${CYAN}8. Restore System${NC}"
    echo -e "${RED}9. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-9]: " choice
    
    case $choice in
        1) create_user ;;
        2) create_trial ;;
        3) list_users ;;
        4) user_details ;;
        5) delete_user ;;
        6) service_status ;;
        7) backup_system ;;
        8) restore_system ;;
        9)
            echo -e "${GREEN}[✓] Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
