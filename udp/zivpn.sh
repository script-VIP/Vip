#!/bin/bash
# ==========================================
# UDP ZIVPN Installer - Ubuntu 24 & Debian
# Format: domain:port@username:password
# ==========================================

# Colors dengan kotak
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Config ports
PORTS=("443" "53" "80" "8080" "2086" "2087" "8880" "2052" "2083")
DEFAULT_PORT="443"

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║              UDP ZIVPN INSTALLER             ║"
    echo "║           Ubuntu 24 & Debian All OS          ║"
    echo "║        Format: domain:port@user:pass         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Run as root!${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${YELLOW}[INFO] Installing dependencies...${NC}"
    apt update
    apt install -y wget curl git build-essential
    apt install -y net-tools software-properties-common
}

get_public_ip() {
    echo -e "${YELLOW}[INFO] Getting public IP...${NC}"
    IP=$(curl -s ifconfig.me)
    if [ -z "$IP" ]; then
        IP=$(curl -s ipinfo.io/ip)
    fi
    echo -e "${GREEN}Public IP: $IP${NC}"
}

download_binary() {
    echo -e "${YELLOW}[INFO] Downloading UDP ZIVPN Binary...${NC}"
    cd /usr/local/bin/
    
    # Download binary (ganti dengan link binary asli)
    wget -q -O udpzivpn "https://github.com/rizyul/devscrypt/raw/main/bin/udpzivpn"
    chmod +x udpzivpn
}

create_service() {
    echo -e "${YELLOW}[INFO] Creating service...${NC}"
    
    cat > /etc/systemd/system/udpzivpn.service << EOF
[Unit]
Description=UDP ZIVPN Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin/
ExecStart=/usr/local/bin/udpzivpn server -port $DEFAULT_PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udpzivpn
}

create_management_script() {
    echo -e "${YELLOW}[INFO] Creating management script...${NC}"
    
    cat > /usr/local/bin/udpzivpn-menu << 'EOF'
#!/bin/bash
# UDP ZIVPN Management Menu - Format SSH UDP

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

get_ip() {
    IP=$(curl -s ifconfig.me)
    echo "$IP"
}

show_menu() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║            UDP ZIVPN MANAGEMENT              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║   ${GREEN}1. Create User${NC}${CYAN}                               ║"
    echo "║   ${GREEN}2. Trial Account${NC}${CYAN}                             ║"
    echo "║   ${GREEN}3. Renew Account${NC}${CYAN}                             ║"
    echo "║   ${GREEN}4. Delete Account${NC}${CYAN}                            ║"
    echo "║   ${GREEN}5. Detail Account${NC}${CYAN}                            ║"
    echo "║   ${GREEN}6. Online Users${NC}${CYAN}                              ║"
    echo "║   ${YELLOW}7. Lock/Unlock User${NC}${CYAN}                         ║"
    echo "║   ${BLUE}8. Service Status${NC}${CYAN}                            ║"
    echo "║   ${RED}9. Restart Service${NC}${CYAN}                           ║"
    echo "║   ${RED}0. Exit${NC}${CYAN}                                      ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

create_user() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               CREATE NEW USER                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "Username: " username
    read -p "Password: " password
    read -p "Days: " days
    read -p "Limit IP: " limitip
    
    # Generate random port dari list
    ports=("443" "53" "80" "8080" "2086" "2087" "8880" "2052" "2083")
    port=${ports[$RANDOM % ${#ports[@]}]}
    
    # Get public IP
    IP=$(get_ip)
    
    # Simpan user
    echo "$username:$password:$days:$limitip:$port" >> /etc/udpzivpn/users.db
    
    # Format SSH UDP: domain:port@username:password
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║             USER CREATED SUCCESS!            ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Format SSH UDP:                            ║"
    echo "║  ${YELLOW}$IP:$port@$username:$password${GREEN}              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Username : $username                        ║"
    echo "║  Password : $password                        ║" 
    echo "║  Expired  : $days Days                       ║"
    echo "║  Limit IP : $limitip                         ║"
    echo "║  Port     : $port                            ║"
    echo "║  Protocol : UDP                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

trial_account() {
    username="trial-$(date +%s | tail -c 4)"
    password="trial123"
    days="1"
    limitip="1"
    ports=("443" "53" "80" "8080" "2086" "2087" "8880" "2052" "2083")
    port=${ports[$RANDOM % ${#ports[@]}]}
    IP=$(get_ip)
    
    # Simpan trial user
    echo "$username:$password:$days:$limitip:$port" >> /etc/udpzivpn/users.db
    
    echo -e "${YELLOW}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║             TRIAL ACCOUNT CREATED!           ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Format SSH UDP:                            ║"
    echo "║  ${GREEN}$IP:$port@$username:$password${YELLOW}              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Username : $username                        ║"
    echo "║  Password : $password                        ║" 
    echo "║  Expired  : $days Day                        ║"
    echo "║  Limit IP : $limitip                         ║"
    echo "║  Port     : $port                            ║"
    echo "║  Protocol : UDP                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

detail_account() {
    read -p "Enter username: " username
    user_data=$(grep "^$username:" /etc/udpzivpn/users.db 2>/dev/null)
    
    if [ -z "$user_data" ]; then
        echo -e "${RED}User not found!${NC}"
        return
    fi
    
    IFS=':' read -r username password days limitip port <<< "$user_data"
    IP=$(get_ip)
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               ACCOUNT DETAILS                ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Format SSH UDP:                            ║"
    echo "║  ${GREEN}$IP:$port@$username:$password${CYAN}                ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Username : $username                        ║"
    echo "║  Password : $password                        ║"
    echo "║  Expired  : $days Days                       ║"
    echo "║  Limit IP : $limitip                         ║"
    echo "║  Port     : $port                            ║"
    echo "║  Protocol : UDP                              ║"
    echo "║  Status   : Active                           ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

list_users() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               ALL USERS LIST                 ║"
    echo "╠══════════════════════════════════════════════╣"
    echo -e "${NC}"
    
    if [ ! -f "/etc/udpzivpn/users.db" ] || [ ! -s "/etc/udpzivpn/users.db" ]; then
        echo -e "${RED}No users found!${NC}"
        return
    fi
    
    IP=$(get_ip)
    count=1
    while IFS=: read -r username password days limitip port; do
        echo -e "${GREEN}$count. $IP:$port@$username:$password${NC}"
        echo -e "   Expired: $days days, Limit IP: $limitip"
        echo ""
        ((count++))
    done < "/etc/udpzivpn/users.db"
}

# Main menu loop
while true; do
    show_menu
    read -p "Select option: " choice
    case $choice in
        1) create_user ;;
        2) trial_account ;;
        3) echo -e "${YELLOW}Renew feature...${NC}" ;;
        4) echo -e "${YELLOW}Delete feature...${NC}" ;;
        5) detail_account ;;
        6) list_users ;;
        7) echo -e "${YELLOW}Lock/Unlock...${NC}" ;;
        8) systemctl status udpzivpn ;;
        9) systemctl restart udpzivpn ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
    read -p "Press Enter to continue..."
done
EOF

    chmod +x /usr/local/bin/udpzivpn-menu
}

setup_firewall() {
    echo -e "${YELLOW}[INFO] Configuring firewall...${NC}"
    ufw disable 2>/dev/null
    
    # Open semua port UDP yang digunakan
    for port in "${PORTS[@]}"; do
        iptables -I INPUT -p udp --dport $port -j ACCEPT 2>/dev/null
        echo -e "${GREEN}Port $port UDP opened${NC}"
    done
}

finalize_installation() {
    # Buat directory config
    mkdir -p /etc/udpzivpn
    touch /etc/udpzivpn/users.db
    
    # Start service
    systemctl start udpzivpn
    
    # Get public IP
    IP=$(get_public_ip)
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║        UDP ZIVPN INSTALLATION COMPLETE!      ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Management : udpzivpn-menu                  ║"
    echo "║  Format     : $IP:port@user:pass             ║"
    echo "║  Ports      : 443,53,80,8080,2086,2087      ║"
    echo "║  Service    : systemctl status udpzivpn      ║"
    echo "║  OS Support : Ubuntu 18/20/22/24 & Debian    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main installation
main() {
    show_banner
    check_root
    install_dependencies
    get_public_ip
    download_binary
    create_service
    create_management_script
    setup_firewall
    finalize_installation
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           TEST CREATE TRIAL ACCOUNT          ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Auto test create trial account
    sleep 2
    bash /usr/local/bin/udpzivpn-menu
}

# Run main function
main
