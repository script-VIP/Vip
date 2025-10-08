#!/bin/bash

# Color Definitions
BLUE_CYAN='\e[5;36m'
WHITE_BE='\e[5;37m'
GREEN_BE='\e[5;32m'
PURPLE='\033[35m'
YELLOW='\e[33m'
WHITE="\033[97;1m"
GREEN="\033[92;1m"
CYAN="\033[96;1m"
RED="\033[91;1m"
BG_BLUE="\033[44;1m"
BG_GREEN="\033[42;1m"
BG_RED="\033[41;1m"
BG_PURPLE="\033[45;1m"
BG_CYAN="\033[46;1m"
BG_YELLOW="\033[43;1m"
NC='\e[0m'

# Line Definitions
LONG_LINE="${BLUE_CYAN}———————————————————————————————————————————${NC}"
SHORT_LINE="${CYAN}——————————————${NC}"
DOUBLE_LINE="${BLUE_CYAN}═══════════════════════════════════════════════${NC}"
SIDE_LINE="${BLUE_CYAN}│${NC}"

clear

function print_success() {
    if [[ 0 -eq $? ]]; then
        echo -e "${LONG_LINE}"
        echo -e "${GREEN}✓ $1 berhasil dipasang${NC}"
        echo -e "${LONG_LINE}"
        sleep 2
    fi
}

function print_error() {
    echo -e "${LONG_LINE}"
    echo -e "${RED}✗ $1${NC}"
    echo -e "${LONG_LINE}"
    sleep 2
}

# Header Functions
function header_main() {
    echo -e "${SIDE_LINE} ${BG_BLUE}            MENU UTAMA SCRIPT            ${NC} ${SIDE_LINE}"
}

function header_system() {
    echo -e "${SIDE_LINE} ${BG_BLUE}              MENU SYSTEM               ${NC} ${SIDE_LINE}"
}

function header_fix() {
    echo -e "${SIDE_LINE} ${BG_GREEN}               MENU FIX                 ${NC} ${SIDE_LINE}"
}

function header_admin() {
    echo -e "${SIDE_LINE} ${BG_RED}            ONLY FOR ADMIN              ${NC} ${SIDE_LINE}"
}

function header_clear() {
    echo -e "${SIDE_LINE} ${BG_PURPLE}             MENU CLEANUP              ${NC} ${SIDE_LINE}"
}

function header_info() {
    echo -e "${SIDE_LINE} ${BG_CYAN}              INFORMATION               ${NC} ${SIDE_LINE}"
}

function header_other() {
    echo -e "${SIDE_LINE} ${BG_YELLOW}                OTHER                  ${NC} ${SIDE_LINE}"
}

# Rename Function
function Rename() {
    clear
    echo -e "${DOUBLE_LINE}"
    echo -e "${SIDE_LINE} ${CYAN}         Welcome To Script Vpn Express         ${NC} ${SIDE_LINE}"
    echo -e "${DOUBLE_LINE}"
    echo ""
    sleep 2
    
    echo -e "${SHORT_LINE}"
    echo -e "${SIDE_LINE} ${GREEN}          Please Select an Option           ${NC} ${SIDE_LINE}"
    echo -e "${SHORT_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}1)${NC} Rename Script                      ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}2)${NC} Default Name                       ${SIDE_LINE}"
    echo -e "${SHORT_LINE}"
    
    read -p "  ${SIDE_LINE} Please select option 1-2 or Any Button (Default): " host
    echo ""
    
    if [[ $host == "1" ]]; then
        clear
        echo -e "${DOUBLE_LINE}"
        echo -e "${SIDE_LINE} ${GREEN}           CHANGE SCRIPT NAME            ${NC} ${SIDE_LINE}"
        echo -e "${DOUBLE_LINE}"
        echo ""
        read -p "  ${SIDE_LINE} INPUT YOUR NAME : " host1
        read -p "  ${SIDE_LINE} INPUT ADMIN PASS : " host11
        
        rm /etc/xray/username
        if [[ $host11 == "123Admin" ]]; then
            echo $host1 >> /etc/xray/username
            echo ""
            clear
            print_success "Rename Script"
            sleep 3
            menu
        else
            echo "VPN EXPRESS" > /etc/xray/username
            clear
            print_error "Permission Denied - Invalid Admin Password"
            sleep 3
            show_owner_info
        fi
    elif [[ $host == "2" ]]; then
        rm /etc/xray/username
        echo "VPN EXPRESS" > /etc/xray/username
        clear
        print_success "Script Name Set to Default"
        sleep 3
        menu
    fi
}

function show_owner_info() {
    clear
    echo -e "${DOUBLE_LINE}"
    echo -e "${SIDE_LINE} ${BG_RED}        404 NOT FOUND AUTOSCRIPT          ${NC} ${SIDE_LINE}"
    echo -e "${DOUBLE_LINE}"
    echo -e "${SIDE_LINE}                                                 ${SIDE_LINE}"
    echo -e "${SIDE_LINE}        ${RED}PERMISSION DENIED !${NC}                   ${SIDE_LINE}"
    echo -e "${SIDE_LINE}  ${YELLOW}Buy access permissions for scripts${NC}       ${SIDE_LINE}"
    echo -e "${SIDE_LINE}        ${YELLOW}Contact Admin :${NC}                    ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}WhatsApp${NC} wa.me/628981874211              ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}Telegram${NC} t.me/AimanVpnExpress            ${SIDE_LINE}"
    echo -e "${DOUBLE_LINE}"
    sleep 3
    print_success "Script Name Default"
    sleep 2
    menu
}

# Banner Function
function Banner(){
    clear
    echo -e "${DOUBLE_LINE}"
    header_main
    echo -e "${DOUBLE_LINE}"
}

# Main Menu Display dengan layout 2 kolom
function Menu_Lambofgod() {
    # Kategori SYSTEM (1-10)
    echo -e "${SHORT_LINE}"
    header_system
    echo -e "${SHORT_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}1)${NC} Running Service        ${GREEN}6)${NC} Spesifikasi VPS       ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}2)${NC} Change Domain          ${GREEN}7)${NC} Auto Reboot           ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}3)${NC} Change Banner          ${GREEN}8)${NC} SpeedTest             ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}4)${NC} Update Script          ${GREEN}9)${NC} Monitoring            ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}5)${NC} Check Bandwidth        ${GREEN}10)${NC} Restart Service      ${SIDE_LINE}"
    
    # Kategori FIX (11-20)
    echo -e "${SHORT_LINE}"
    header_fix
    echo -e "${SHORT_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}11)${NC} Fix Domain            ${GREEN}16)${NC} Fix Epro             ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}12)${NC} Fix Haproxy           ${GREEN}17)${NC} Fix Udp              ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}13)${NC} Fix Xray              ${GREEN}18)${NC} Clear Logs           ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}14)${NC} Fix Bot Tele          ${GREEN}19)${NC} Clear Cache          ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}15)${NC} Fix nginx             ${GREEN}20)${NC} Clear Cache File     ${SIDE_LINE}"
    
    # Kategori ADMIN & TOOLS (21-30)
    echo -e "${SHORT_LINE}"
    header_admin
    echo -e "${SHORT_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}21)${NC} Force Reboot          ${GREEN}26)${NC} Change Name          ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}22)${NC} Limit Speed           ${GREEN}27)${NC} Wildcard             ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}23)${NC} Enable Anti Ddos      ${GREEN}28)${NC} Menu Rebuild         ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}24)${NC} Info Port Payload     ${GREEN}29)${NC} Bot WhatsApp         ${SIDE_LINE}"
    echo -e "${SIDE_LINE}   ${GREEN}25)${NC} Developer Script      ${GREEN}30)${NC} Menu Admin Only      ${SIDE_LINE}"
    
    echo -e "${LONG_LINE}"
    echo -e "${SIDE_LINE}   ${RED}0)${NC} Back to Main Menu                                  ${SIDE_LINE}"
    echo -e "${LONG_LINE}"
    echo -e ""
}

function Select_Menu() {
    read -p "  ${SIDE_LINE} Select From Options [0-30]: " NB
    case $NB in
        # SYSTEM (1-10)
        1) clear ; run ;;
        2) clear ; change-domain ;;
        3) clear ; nano /etc/banner.txt ;;
        4) clear ; wget -q https://raw.githubusercontent.com/AngIMAN/express/main/update.sh && chmod +x update.sh && ./update.sh ;;
        5) clear ; bw ;;
        6) clear ; wget -qO- bench.sh | bash ;;
        7) clear ; autoreboot ;;
        8) clear ; speedtest ;;
        9) clear ; gotop ;; 
        10) clear ; reset ;;
        
        # FIX (11-20)
        11) clear ; fixcert ;;
        12) clear ; fixhap ;;
        13) clear ; fixxray ;;
        14) clear ; fixakunbot ;;
        15) clear ; fixnginx ;;
        16) clear ; wget -O /usr/bin/ws "https://raw.githubusercontent.com/AngIMAN/express/main/Fls/ws" >/dev/null 2>&1 && wget -O /usr/bin/tun.conf "https://raw.githubusercontent.com/AngIMAN/express/main/Cfg/tun.conf" >/dev/null 2>&1 && wget -O /etc/systemd/system/ws.service "https://raw.githubusercontent.com/AngIMAN/express/main/Fls/ws.service" >/dev/null 2>&1 && chmod +x /etc/systemd/system/ws.service && chmod +x /usr/bin/ws && chmod 644 /usr/bin/tun.conf && systemctl disable ws && systemctl stop ws && systemctl enable ws && systemctl start ws && systemctl restart ws ;;
        17) clear ; fixudp ;;
        18) clear ; delet-cache-file ;;
        19) clear ; clearcache ;;
        20) clear ; clearlog ;;
        
        # ADMIN & TOOLS (21-30)
        21) clear ; reboot ;;
        22) clear ; limitspeed ;;
        23) clear ; anti-ddos ;;
        24) clear ; Info_Port ;;
        25) clear ; about ;;
        26) clear ; Rename ;;
        27) clear ; wild ;;
        28) clear ; m-rebuild ;;
        29) clear ; botwa ;;
        30) clear ; m-adm ;;
        
        0) clear ; menu ;;
        *) clear ; menu ;;
    esac
}

# Main Execution
Banner
Menu_Lambofgod
Select_Menu
