#!/bin/bash

# Color Definitions
BLUE_CYAN='\033[1;96m'
WHITE_BE='\033[1;97m'
GREEN_BE='\033[1;92m'
PURPLE='\033[1;95m'
YELLOW='\033[1;93m'
WHITE="\033[1;97m"
GREEN="\033[1;92m"
CYAN="\033[1;96m"
RED="\033[1;91m"
ORANGE='\033[1;33m'
NC='\033[0m'

clear

function print_success() {
    if [[ 0 -eq $? ]]; then
        echo -e "${GREEN}✓ $1 berhasil dipasang${NC}"
        sleep 2
    fi
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
    sleep 2
}

# Banner Function
function Banner(){
    clear
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e "${CYAN}           SCRIPT VPN EXPRESS${NC}"
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo ""
}

# Main Menu Display 
function Menu_Lambofgod() {
    # Header dengan garis seperti contoh
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────╯${NC}"
    echo -e "          ${CYAN}╭─ SYSTEM MENU ───────────────────────────────╮${NC}"
    echo -e "          ${GREEN}│ [1] Running Service${NC}    ${GREEN}│  [6] Spesifikasi VPS${NC}      ${GREEN}│${NC}"
    echo -e "          ${GREEN}│ [2] Change Domain${NC}      ${GREEN}│  [7] Auto Reboot${NC}          ${GREEN}│${NC}"
    echo -e "          ${GREEN}│ [3] Change Banner${NC}      ${GREEN}│  [8] SpeedTest${NC}            ${GREEN}│${NC}"
    echo -e "          ${GREEN}│ [4] Update Script${NC}      ${GREEN}│  [9] Monitoring${NC}           ${GREEN}│${NC}"
    echo -e "          ${GREEN}│ [5] Check Bandwidth${NC}    ${GREEN}│  [10] Restart Service${NC}     ${GREEN}│${NC}"
    echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Fix Menu
    echo -e "          ${CYAN}╭─ FIX MENU ───────────────────────────────────╮${NC}"
    echo -e "          ${PURPLE}│ [11] Fix Domain${NC}       ${PURPLE}│  [16] Fix Epro${NC}            ${PURPLE}│${NC}"
    echo -e "          ${PURPLE}│ [12] Fix Haproxy${NC}      ${PURPLE}│  [17] Fix Udp${NC}             ${PURPLE}│${NC}"
    echo -e "          ${PURPLE}│ [13] Fix Xray${NC}         ${PURPLE}│  [18] Clear Logs${NC}          ${PURPLE}│${NC}"
    echo -e "          ${PURPLE}│ [14] Fix Bot Tele${NC}     ${PURPLE}│  [19] Clear Cache${NC}         ${PURPLE}│${NC}"
    echo -e "          ${PURPLE}│ [15] Fix nginx${NC}        ${PURPLE}│  [20] Clear Cache File${NC}    ${PURPLE}│${NC}"
    echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Admin & Tools Menu
    echo -e "          ${CYAN}╭─ ADMIN & TOOLS ──────────────────────────────╮${NC}"
    echo -e "          ${ORANGE}│ [21] Force Reboot${NC}     ${ORANGE}│  [26] Change Name${NC}         ${ORANGE}│${NC}"
    echo -e "          ${ORANGE}│ [22] Limit Speed${NC}      ${ORANGE}│  [27] Wildcard${NC}            ${ORANGE}│${NC}"
    echo -e "          ${ORANGE}│ [23] Enable Anti Ddos${NC} ${ORANGE}│  [28] Menu Rebuild${NC}        ${ORANGE}│${NC}"
    echo -e "          ${ORANGE}│ [24] Info Port Payload${NC}${ORANGE}│  [29] Bot WhatsApp${NC}        ${ORANGE}│${NC}"
    echo -e "          ${ORANGE}│ [25] Developer Script${NC} ${ORANGE}│  [30] Menu Admin Only${NC}     ${ORANGE}│${NC}"
    echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Exit Option
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e "          ${RED}[0] Back to Main Menu${NC}"
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e ""
}

function Select_Menu() {
    read -p " Select menu option : " NB
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

# Rename Function dengan tampilan baru
function Rename() {
    clear
    Banner
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────╯${NC}"
    echo -e "          ${CYAN}╭─ CHANGE SCRIPT NAME ────────────────────────╮${NC}"
    echo -e "          ${YELLOW}│ [1] Rename Script${NC}                            ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│ [2] Default Name${NC}                             ${YELLOW}│${NC}"
    echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    read -p " Select option : " host
    
    if [[ $host == "1" ]]; then
        echo -e "          ${CYAN}╭─ INPUT DETAILS ─────────────────────────────────╮${NC}"
        read -p " │ Input Your Name : " host1
        read -p " │ Input Admin Pass : " host11
        echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
        
        rm /etc/xray/username
        if [[ $host11 == "123Admin" ]]; then
            echo $host1 >> /etc/xray/username
            print_success "Script Renamed Successfully"
        else
            echo "VPN EXPRESS" > /etc/xray/username
            print_error "Invalid Admin Password - Using Default Name"
        fi
    elif [[ $host == "2" ]]; then
        rm /etc/xray/username
        echo "VPN EXPRESS" > /etc/xray/username
        print_success "Script Name Set to Default"
    fi
    sleep 3
    menu
}

function show_owner_info() {
    clear
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e "${RED}          404 NOT FOUND AUTOSCRIPT${NC}"
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e "          ${CYAN}╭─ PERMISSION DENIED ─────────────────────────╮${NC}"
    echo -e "          ${YELLOW}│${NC}                                            ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}        ${RED}PERMISSION DENIED !${NC}                   ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}  ${ORANGE}Buy access permissions for scripts${NC}       ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}        ${ORANGE}Contact Admin :${NC}                    ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}   ${GREEN}WhatsApp${NC} wa.me/628981874211              ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}   ${GREEN}Telegram${NC} t.me/AimanVpnExpress            ${YELLOW}│${NC}"
    echo -e "          ${YELLOW}│${NC}                                            ${YELLOW}│${NC}"
    echo -e "          ${CYAN}╰────────────────────────────────────────────────╯${NC}"
    sleep 3
    print_success "Script Name Default"
    sleep 2
    menu
}

# Main Execution
Banner
Menu_Lambofgod
Select_Menu
