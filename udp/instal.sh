#!/bin/bash
# ==========================================
# Ultimate UDP VPN Auto Installer
# Install All: ZIVPN + Dekodemo
# Support: Ubuntu 18/20/22/24 & Debian All
# ==========================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Banner dengan kotak
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║           ULTIMATE UDP VPN INSTALLER         ║"
    echo "║              AUTO INSTALL ALL                ║"
    echo "║           ZIVPN + DEKODEMO                  ║"
    echo "║     Ubuntu 18/20/22/24 & Debian All OS       ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║           ERROR: RUN AS ROOT!                ║${NC}"
        echo -e "${RED}║   Gunakan: sudo -i atau su root              ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    echo -e "${YELLOW}[INFO] Detecting OS...${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    fi
    echo -e "${GREEN}[SUCCESS] OS: $OS $VER${NC}"
}

# Update system
update_system() {
    echo -e "${YELLOW}[INFO] Updating system packages...${NC}"
    apt-get update
    apt-get upgrade -y
    apt-get install -y wget curl git nano ufw build-essential
}

# Install UDP ZIVPN
install_udpzivpn() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║             INSTALLING UDP ZIVPN             ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
    
    # Download script
    wget -q -O udpzivpn.sh "https://raw.githubusercontent.com/rizyul/devscrypt/main/udpzivpn.sh"
    chmod +x udpzivpn.sh
    bash udpzivpn.sh
}

# Install UDP Dekodemo
install_udpdekodemo() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           INSTALLING UDP DEKODEMO            ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
    
    # Download script
    wget -q -O udpdekodemo.sh "https://raw.githubusercontent.com/rizyul/devscrypt/main/udpdekodemo.sh"
    chmod +x udpdekodemo.sh
    bash udpdekodemo.sh
}

# Fix common issues
fix_issues() {
    echo -e "${YELLOW}[INFO] Fixing common issues...${NC}"
    chmod +x /usr/local/bin/*.sh 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    apt-get autoremove -y
    apt-get clean
}

# Show final info
show_final_info() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║         INSTALLATION COMPLETE!              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  ✅ UDP ZIVPN Installed                     ║"
    echo "║  ✅ UDP DEKODEMO Installed                  ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  MANAGEMENT COMMANDS:                       ║"
    echo "║  🔸 UDP ZIVPN: udpzivpn-menu               ║"
    echo "║  🔸 UDP DEKODEMO: udpdekodemo-menu         ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  SERVICE STATUS:                            ║"
    echo "║  🔸 systemctl status udpzivpn               ║"
    echo "║  🔸 systemctl status udpdekodemo            ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║  FORMAT AKUN: IP:PORT@USERNAME:PASSWORD     ║"
    echo "║  Example: 103.105.112.1:443@vipuser:pass123 ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Show public IP
    IP=$(curl -s ifconfig.me)
    echo -e "${CYAN}Public IP Server: $IP${NC}"
    echo -e "${YELLOW}Test buat akun trial: udpzivpn-menu${NC}"
}

# Main execution
main() {
    show_banner
    check_root
    detect_os
    update_system
    
    # Auto install all
    install_udpzivpn
    install_udpdekodemo
    fix_issues
    show_final_info
}

# Run main function
main
