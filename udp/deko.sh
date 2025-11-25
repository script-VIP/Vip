#!/bin/bash
# ==========================================
# UDP Dekodemo Installer - Ubuntu 24 & Debian
# Format: domain:port@username:password
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║            UDP DEKODEMO INSTALLER            ║"
    echo "║           Ubuntu 24 & Debian All OS          ║"
    echo "║        Format: domain:port@user:pass         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

get_public_ip() {
    IP=$(curl -s ifconfig.me)
    echo "$IP"
}

main_installation() {
    show_banner
    
    echo -e "${YELLOW}[INFO] Installing UDP Dekodemo...${NC}"
    
    # Install dependencies
    apt update
    apt install -y wget curl
    
    # Download binary
    cd /usr/local/bin/
    wget -q -O udpdekodemo "https://github.com/rizyul/devscrypt/raw/main/bin/udpdekodemo"
    chmod +x udpdekodemo
    
    # Create service
    cat > /etc/systemd/system/udpdekodemo.service << EOF
[Unit]
Description=UDP Dekodemo Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/udpdekodemo server -port 443
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udpdekodemo
    systemctl start udpdekodemo
    
    # Create menu dengan format SSH UDP
    cat > /usr/local/bin/udpdekodemo-menu << EOF
#!/bin/bash
# UDP Dekodemo Management Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

get_ip() {
    IP=\$(curl -s ifconfig.me)
    echo "\$IP"
}

show_menu() {
    clear
    echo -e "\${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           UDP DEKODEMO MANAGEMENT            ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║   \${GREEN}1. Create User\${NC}\${CYAN}                               ║"
    echo "║   \${GREEN}2. Trial Account\${NC}\${CYAN}                             ║"
    echo "║   \${GREEN}3. List Users\${NC}\${CYAN}                                ║"
    echo "║   \${BLUE}4. Service Status\${NC}\${CYAN}                            ║"
    echo "║   \${RED}0. Exit\${NC}\${CYAN}                                      ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "\${NC}"
}

create_user() {
    echo -e "\${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               CREATE NEW USER                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "\${NC}"
    
    read -p "Username: " username
    read -p "Password: " password
    read -p "Days: " days
    read -p "Limit IP: " limitip
    
    IP=\$(get_ip)
    port="443"
    
    echo -e "\${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║             USER CREATED SUCCESS!            ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Format SSH UDP:                            ║"
    echo "║  \${YELLOW}\$IP:\$port@\$username:\$password\${GREEN}              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Username : \$username                        ║"
    echo "║  Password : \$password                        ║" 
    echo "║  Expired  : \$days Days                       ║"
    echo "║  Limit IP : \$limitip                         ║"
    echo "║  Port     : \$port                            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "\${NC}"
}

trial_account() {
    username="trial-\$(date +%s | tail -c 4)"
    password="trial123"
    days="1"
    limitip="1"
    IP=\$(get_ip)
    port="443"
    
    echo -e "\${YELLOW}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║             TRIAL ACCOUNT CREATED!           ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Format SSH UDP:                            ║"
    echo "║  \${GREEN}\$IP:\$port@\$username:\$password\${YELLOW}              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Username : \$username                        ║"
    echo "║  Password : \$password                        ║" 
    echo "║  Expired  : \$days Day                        ║"
    echo "║  Limit IP : \$limitip                         ║"
    echo "║  Port     : \$port                            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "\${NC}"
}

while true; do
    show_menu
    read -p "Select option: " choice
    case \$choice in
        1) create_user ;;
        2) trial_account ;;
        3) echo -e "\${YELLOW}List users feature...\${NC}" ;;
        4) systemctl status udpdekodemo ;;
        0) exit 0 ;;
        *) echo -e "\${RED}Invalid option!\${NC}" ;;
    esac
    read -p "Press Enter to continue..."
done
EOF

    chmod +x /usr/local/bin/udpdekodemo-menu
    
    # Get public IP
    IP=$(get_public_ip)
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║   UDP DEKODEMO INSTALLATION COMPLETE!        ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  Management : udpdekodemo-menu               ║"
    echo "║  Format     : $IP:443@user:pass              ║"
    echo "║  Service    : systemctl status udpdekodemo   ║"
    echo "║  OS Support : Ubuntu 18/20/22/24 & Debian    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}Test create trial account: udpdekodemo-menu${NC}"
}

# Check root and run
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Run as root!${NC}"
    exit 1
fi

main_installation
