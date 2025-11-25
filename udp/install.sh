#!/bin/bash
# ==========================================
# Ultimate UDP VPN Installer
# Support: Ubuntu 18/20/22/24 & Debian All Version
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
    echo "║     Ubuntu 18/20/22/24 & Debian All OS       ║"
    echo "║           Support: ZIVPN & Dekodemo          ║"
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

# Main menu
show_menu() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║             UDP VPN INSTALLATION MENU        ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║   ${GREEN}1. Install UDP ZIVPN${PURPLE}                       ║"
    echo "║   ${GREEN}2. Install UDP Dekodemo${PURPLE}                    ║"
    echo "║   ${CYAN}3. Install Both (ZIVPN + Dekodemo)${PURPLE}         ║"
    echo "║   ${YELLOW}4. Fix Common Issues${PURPLE}                      ║"
    echo "║   ${RED}5. Uninstall All${PURPLE}                            ║"
    echo "║   ${BLUE}0. Exit${PURPLE}                                    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

install_udpzivpn() {
    echo -e "${YELLOW}[INFO] Installing UDP ZIVPN...${NC}"
    wget -q -O udpzivpn.sh "https://raw.githubusercontent.com/rizyul/devscrypt/main/udpzivpn.sh"
    chmod +x udpzivpn.sh
    bash udpzivpn.sh
}

install_udpdekodemo() {
    echo -e "${YELLOW}[INFO] Installing UDP Dekodemo...${NC}"
    wget -q -O udpdekodemo.sh "https://raw.githubusercontent.com/rizyul/devscrypt/main/udpdekodemo.sh"
    chmod +x udpdekodemo.sh
    bash udpdekodemo.sh
}

fix_issues() {
    echo -e "${YELLOW}[INFO] Fixing common issues...${NC}"
    chmod +x /usr/local/bin/*.sh 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    apt-get autoremove -y
    apt-get clean
    echo -e "${GREEN}[SUCCESS] Issues fixed!${NC}"
}

uninstall_all() {
    echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          WARNING: UNINSTALL ALL!             ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop udpzivpn 2>/dev/null
        systemctl stop udpdekodemo 2>/dev/null
        rm -f /usr/local/bin/udpzivpn.sh
        rm -f /usr/local/bin/udpdekodemo.sh
        rm -f /etc/systemd/system/udpzivpn.service
        rm -f /etc/systemd/system/udpdekodemo.service
        echo -e "${GREEN}[SUCCESS] All UDP VPN removed!${NC}"
    fi
}

# Main execution
show_banner
check_root
detect_os
update_system

while true; do
    show_menu
    read -p "Select option [0-5]: " option
    case $option in
        1) install_udpzivpn ;;
        2) install_udpdekodemo ;;
        3) 
            install_udpzivpn
            install_udpdekodemo
            ;;
        4) fix_issues ;;
        5) uninstall_all ;;
        0) 
            echo -e "${GREEN}Thank you! Goodbye!${NC}"
            exit 0
            ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
    read -p "Press Enter to continue..."
done
