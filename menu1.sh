#!/bin/bash
# menu.sh - UDP Dekodemo Management Menu

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

loading() {
    echo -ne "${YELLOW}Loading $1"
    for i in {1..3}; do
        echo -ne "."
        sleep 0.5
    done
    echo -e "${NC}"
}

create_vmess_user() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Vmess Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    # Username input with validation
    while true; do
        read -p "  Username    : " user
        if [ -z "$user" ]; then
            echo -e "${RED}[!] Username cannot be empty!${NC}"
            continue
        fi
        
        # Check if user already exists
        if [ -f "/etc/v2ray/users/$user.conf" ]; then
            echo -e "${RED}—————————————————————————${NC}"
            echo -e "${RED}      Username Already Exists${NC}"
            echo -e "${RED}—————————————————————————${NC}"
            echo ""
        else
            break
        fi
    done
    
    # Get other inputs
    read -p "  Limit IP    : " iplimit
    read -p "  Limit Quota (GB): " quota
    read -p "  Active For (Days): " masaaktif
    
    iplimit=${iplimit:-1}
    quota=${quota:-0}
    masaaktif=${masaaktif:-30}
    
    echo ""
    loading "Creating Account"
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Calculate expiry dates
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    tgl=$(date -d "$masaaktif days" +"%d")
    bln=$(date -d "$masaaktif days" +"%b")
    thn=$(date -d "$masaaktif days" +"%Y")
    expe="$tgl $bln, $thn"
    
    tgl2=$(date +"%d")
    bln2=$(date +"%b")
    thn2=$(date +"%Y")
    tnggl="$tgl2 $bln2, $thn2"
    
    # Generate multiple port options
    port_ws=8080
    port_tls=8443
    port_grpc=443
    
    # Create user config file
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port_ws=$port_ws
port_tls=$port_tls
port_grpc=$port_grpc
limit_ip=$iplimit
quota=$quota
created=$tnggl
expiry=$expe
expiry_date=$exp
status=active
EOF

    # Generate V2Ray JSON configurations
    vmess_tls=$(cat << EOF
{
  "v": "2",
  "ps": "$user-TLS",
  "add": "$server_ip",
  "port": "$port_tls",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "$server_ip",
  "tls": "tls"
}
EOF
)

    vmess_ws=$(cat << EOF
{
  "v": "2",
  "ps": "$user-WS",
  "add": "$server_ip",
  "port": "$port_ws",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "$server_ip",
  "tls": "none"
}
EOF
)

    vmess_grpc=$(cat << EOF
{
  "v": "2",
  "ps": "$user-gRPC",
  "add": "$server_ip",
  "port": "$port_grpc",
  "id": "$uuid",
  "aid": "0",
  "net": "grpc",
  "path": "vmess-grpc",
  "type": "none",
  "host": "$server_ip",
  "tls": "tls"
}
EOF
)

    # Generate base64 links
    vmesslink1="vmess://$(echo "$vmess_tls" | base64 -w 0)"
    vmesslink2="vmess://$(echo "$vmess_ws" | base64 -w 0)"
    vmesslink3="vmess://$(echo "$vmess_grpc" | base64 -w 0)"

    # Create configuration file
    mkdir -p /etc/v2ray/configs
    cat > /etc/v2ray/configs/vmess-$user.txt << EOF
======================
$user Vmess Configuration
======================

# Format Vmess WS TLS
- name: $user-WS TLS
  type: vmess
  server: $server_ip
  port: $port_tls
  uuid: $uuid
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  skip-cert-verify: true
  servername: $server_ip
  network: ws
  ws-opts:
    path: /vmess
    headers:
      Host: $server_ip

# Format Vmess WS Non TLS
- name: $user-WS Non TLS
  type: vmess
  server: $server_ip
  port: $port_ws
  uuid: $uuid
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  skip-cert-verify: false
  servername: $server_ip
  network: ws
  ws-opts:
    path: /vmess
    headers:
      Host: $server_ip

# Format Vmess gRPC
- name: $user-gRPC
  server: $server_ip
  port: $port_grpc
  type: vmess
  uuid: $uuid
  alterId: 0
  cipher: auto
  network: grpc
  tls: true
  servername: $server_ip
  skip-cert-verify: true
  grpc-opts:
    grpc-service-name: vmess-grpc

======================
Link Akun Vmess
======================
Link TLS    : $vmesslink1
======================
Link WS     : $vmesslink2
======================
Link GRPC   : $vmesslink3
======================
Aktif Selama : $masaaktif Hari
Dibuat Pada  : $tnggl
Berakhir Pada: $expe
======================
EOF

    # Restart service to apply changes
    systemctl restart v2ray > /dev/null 2>&1

    # Display account details
    show_account_details
}

show_account_details() {
    clear
    echo -e "${CYAN}$LINE"
    echo -e "  ${GREEN}DETAIL AKUN VMESS${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e " ${YELLOW}Username${NC}    : ${GREEN}$user${NC}"
    echo -e " ${YELLOW}Limit Quota${NC} : ${GREEN}$quota GB${NC}"
    echo -e " ${YELLOW}Limit IP${NC}    : ${GREEN}$iplimit Device${NC}"
    echo -e " ${YELLOW}Active For${NC}  : ${GREEN}$masaaktif Days${NC}"
    echo -e " ${YELLOW}Created On${NC}  : ${GREEN}$tnggl${NC}"
    echo -e " ${YELLOW}Expired On${NC}  : ${GREEN}$expe${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e " ${YELLOW}Server IP${NC}   : ${GREEN}$server_ip${NC}"
    echo -e " ${YELLOW}Port TLS${NC}    : ${GREEN}$port_tls${NC}"
    echo -e " ${YELLOW}Port WS${NC}     : ${GREEN}$port_ws${NC}"
    echo -e " ${YELLOW}Port gRPC${NC}   : ${GREEN}$port_grpc${NC}"
    echo -e " ${YELLOW}UUID${NC}        : ${GREEN}$uuid${NC}"
    echo -e " ${YELLOW}AlterId${NC}     : ${GREEN}0${NC}"
    echo -e " ${YELLOW}Security${NC}    : ${GREEN}auto${NC}"
    echo -e " ${YELLOW}Network${NC}     : ${GREEN}ws/grpc${NC}"
    echo -e " ${YELLOW}Path WS${NC}     : ${GREEN}/vmess${NC}"
    echo -e " ${YELLOW}ServiceName${NC} : ${GREEN}vmess-grpc${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    echo -e "${YELLOW}Configuration File:${NC}"
    echo -e "${GREEN}/etc/v2ray/configs/vmess-$user.txt${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    echo -e "${GREEN}Link TLS:${NC}"
    echo -e "${BLUE}$vmesslink1${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    echo -e "${GREEN}Link WS:${NC}"
    echo -e "${BLUE}$vmesslink2${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    echo -e "${GREEN}Link GRPC:${NC}"
    echo -e "${BLUE}$vmesslink3${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    echo -e "${YELLOW}Thanks For Using UDP Dekodemo${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    pause
}

create_trial_user() {
    show_header
    echo -e "${CYAN}—————————————————————————${NC}"
    echo -e "${GREEN}  Create Trial Account${NC}"
    echo -e "${CYAN}—————————————————————————${NC}"
    echo ""
    
    # Generate trial username
    user="trial-$(date +%s | tail -c 4)"
    iplimit=1
    quota=1
    masaaktif=1
    
    echo -e "${YELLOW}Generating trial account...${NC}"
    loading "Creating Trial"
    
    # Generate credentials
    uuid=$(cat /proc/sys/kernel/random/uuid)
    server_ip=$(curl -s ifconfig.me)
    
    # Calculate expiry dates
    exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
    tgl=$(date -d "$masaaktif days" +"%d")
    bln=$(date -d "$masaaktif days" +"%b")
    thn=$(date -d "$masaaktif days" +"%Y")
    expe="$tgl $bln, $thn"
    
    tgl2=$(date +"%d")
    bln2=$(date +"%b")
    thn2=$(date +"%Y")
    tnggl="$tgl2 $bln2, $thn2"
    
    # Generate ports
    port_ws=8080
    port_tls=8443
    port_grpc=443
    
    # Create user config
    cat > /etc/v2ray/users/$user.conf << EOF
username=$user
uuid=$uuid
protocol=vmess
port_ws=$port_ws
port_tls=$port_tls
port_grpc=$port_grpc
limit_ip=$iplimit
quota=$quota
created=$tnggl
expiry=$expe
expiry_date=$exp
status=active
type=trial
EOF

    # Generate V2Ray JSON
    vmess_tls=$(cat << EOF
{
  "v": "2",
  "ps": "$user-TLS-Trial",
  "add": "$server_ip",
  "port": "$port_tls",
  "id": "$uuid",
  "aid": "0",
  "net": "ws",
  "path": "/vmess",
  "type": "none",
  "host": "$server_ip",
  "tls": "tls"
}
EOF
)

    vmesslink1="vmess://$(echo "$vmess_tls" | base64 -w 0)"

    # Restart service
    systemctl restart v2ray > /dev/null 2>&1

    # Display trial details
    clear
    echo -e "${CYAN}$LINE"
    echo -e "  ${GREEN}TRIAL ACCOUNT CREATED${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e " ${YELLOW}Username${NC}    : ${GREEN}$user${NC}"
    echo -e " ${YELLOW}Limit IP${NC}    : ${GREEN}$iplimit Device${NC}"
    echo -e " ${YELLOW}Quota${NC}       : ${GREEN}$quota GB${NC}"
    echo -e " ${YELLOW}Active For${NC}  : ${GREEN}$masaaktif Day${NC}"
    echo -e " ${YELLOW}Created On${NC}  : ${GREEN}$tnggl${NC}"
    echo -e " ${YELLOW}Expired On${NC}  : ${GREEN}$expe${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e " ${YELLOW}Server IP${NC}   : ${GREEN}$server_ip${NC}"
    echo -e " ${YELLOW}Port TLS${NC}    : ${GREEN}$port_tls${NC}"
    echo -e " ${YELLOW}UUID${NC}        : ${GREEN}$uuid${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e "${GREEN}Trial Link:${NC}"
    echo -e "${BLUE}$vmesslink1${NC}"
    echo -e "${CYAN}$LINE${NC}"
    echo -e "${YELLOW}This is a trial account - 1 Day Only${NC}"
    echo -e "${CYAN}$LINE${NC}"
    
    pause
}

list_users() {
    show_header
    echo -e "${CYAN}[USER LIST]${NC}"
    echo "$LINE"
    
    if [ ! -d "/etc/v2ray/users" ] || [ -z "$(ls -A /etc/v2ray/users)" ]; then
        echo -e "${RED}No users found!${NC}"
    else
        echo -e "${YELLOW}Username     | Type   | Limit IP | Expiry     | Status${NC}"
        echo "$DLINE"
        for user_file in /etc/v2ray/users/*.conf; do
            if [ -f "$user_file" ]; then
                username=$(grep '^username=' "$user_file" | cut -d= -f2)
                user_type=$(grep '^type=' "$user_file" | cut -d= -f2 2>/dev/null || echo "regular")
                limit_ip=$(grep '^limit_ip=' "$user_file" | cut -d= -f2)
                expiry=$(grep '^expiry=' "$user_file" | cut -d= -f2)
                status=$(grep '^status=' "$user_file" | cut -d= -f2)
                
                if [ "$status" = "active" ]; then
                    status_color="${GREEN}ACTIVE${NC}"
                else
                    status_color="${RED}INACTIVE${NC}"
                fi
                
                if [ "$user_type" = "trial" ]; then
                    type_color="${YELLOW}TRIAL${NC}"
                else
                    type_color="${GREEN}REGULAR${NC}"
                fi
                
                printf "%-12s | %b | %-8s | %-10s | %b\n" "$username" "$type_color" "$limit_ip" "$expiry" "$status_color"
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
        while IFS= read -r line; do
            echo -e "${CYAN}$line${NC}"
        done < "$user_file"
        echo "$DLINE"
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
    config_file="/etc/v2ray/configs/vmess-$username.txt"
    
    if [ -f "$user_file" ]; then
        rm -f "$user_file"
        rm -f "$config_file" 2>/dev/null
        echo -e "${GREEN}[✓] User $username deleted successfully${NC}"
        systemctl restart v2ray > /dev/null 2>&1
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
    echo -e "Total Users: $(ls /etc/v2ray/users/*.conf 2>/dev/null | wc -l)"
    
    pause
}

# Main menu
while true; do
    show_header
    echo -e "${CYAN}MAIN MENU${NC}"
    echo "$LINE"
    echo -e "${GREEN}1. Create Vmess User${NC}"
    echo -e "${GREEN}2. Create Trial User${NC}"
    echo -e "${YELLOW}3. List Users${NC}"
    echo -e "${YELLOW}4. User Details${NC}"
    echo -e "${RED}5. Delete User${NC}"
    echo -e "${BLUE}6. Service Status${NC}"
    echo -e "${RED}7. Exit${NC}"
    echo "$LINE"
    
    read -p "Choose option [1-7]: " choice
    
    case $choice in
        1) create_vmess_user ;;
        2) create_trial_user ;;
        3) list_users ;;
        4) user_details ;;
        5) delete_user ;;
        6) service_status ;;
        7)
            echo -e "${GREEN}[✓] Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option!${NC}"
            sleep 2
            ;;
    esac
done
