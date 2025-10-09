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
    echo -e "${CYAN}╭─ SYSTEM MENU ───────────────────────────────────╮${NC}"
    echo -e "${GREEN}│ [1] Running Service${NC}     ${GREEN}│  [11] Auto Reboot${NC}          ${GREEN}│${NC}"
    echo -e "${GREEN}│ [2] Change Domain${NC}       ${GREEN}│  [12] SpeedTest${NC}            ${GREEN}│${NC}"
    echo -e "${GREEN}│ [3] Change Banner${NC}       ${GREEN}│  [13] Monitoring${NC}           ${GREEN}│${NC}"
    echo -e "${GREEN}│ [4] Update Script${NC}       ${GREEN}│  [14] Restart Service${NC}      ${GREEN}│${NC}"
    echo -e "${GREEN}│ [5] Check Bandwidth${NC}     ${GREEN}│  [15] Spesifikasi VPS${NC}      ${GREEN}│${NC}"
    echo -e "${GREEN}│ [6] Menu Panel${NC}          ${GREEN}│  [16] Cek VPS Online${NC}       ${GREEN}│${NC}"
    echo -e "${GREEN}│ [7] Auto Backup${NC}         ${GREEN}│  [17] Update Neofetch${NC}      ${GREEN}│${NC}"
    echo -e "${GREEN}│ [8] Cek Bandwidth${NC}       ${GREEN}│  [18] Menu Bot${NC}             ${GREEN}│${NC}"
    echo -e "${GREEN}│ [9] Bot Telegram${NC}        ${GREEN}│  [19] Info VPS${NC}             ${GREEN}│${NC}"
    echo -e "${GREEN}│ [10] Restart Server${NC}     ${GREEN}│  [20] Menu Backup${NC}          ${GREEN}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Fix Menu
    echo -e "${CYAN}╭─ FIX MENU ─────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│ [21] Fix Domain${NC}        ${PURPLE}│  [26] Fix Epro${NC}             ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ [22] Fix Haproxy${NC}       ${PURPLE}│  [27] Fix Udp${NC}              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ [23] Fix Xray${NC}          ${PURPLE}│  [28] Clear Logs${NC}           ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ [24] Fix Bot Tele${NC}      ${PURPLE}│  [29] Clear Cache${NC}          ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ [25] Fix nginx${NC}         ${PURPLE}│  [30] Clear Cache File${NC}     ${PURPLE}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Admin & Tools Menu
    echo -e "${CYAN}╭─ ADMIN & TOOLS ────────────────────────────────╮${NC}"
    echo -e "${ORANGE}│ [31] Force Reboot${NC}      ${ORANGE}│  [36] Change Name${NC}          ${ORANGE}│${NC}"
    echo -e "${ORANGE}│ [32] Limit Speed${NC}       ${ORANGE}│  [37] Wildcard${NC}             ${ORANGE}│${NC}"
    echo -e "${ORANGE}│ [33] Enable Anti Ddos${NC}  ${ORANGE}│  [38] Menu Rebuild${NC}         ${ORANGE}│${NC}"
    echo -e "${ORANGE}│ [34] Info Port Payload${NC} ${ORANGE}│  [39] Bot WhatsApp${NC}         ${ORANGE}│${NC}"
    echo -e "${ORANGE}│ [35] Developer Script${NC}  ${ORANGE}│  [40] Menu Admin Only${NC}      ${ORANGE}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Exit Option
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e "${RED}[0] Back to Main Menu${NC}"
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────${NC}"
    echo -e ""
}

function Select_Menu() {
    read -p " Select menu option : " NB
    case $NB in
        # SYSTEM (1-20)
        1) clear ; run ;;
        2) clear ; change-domain ;;
        3) clear ; nano /etc/banner.txt ;;
        4) clear ; wget -q https://raw.githubusercontent.com/AngIMAN/express/main/update.sh && chmod +x update.sh && ./update.sh ;;
        5) clear ; bw ;;
        6) clear ; m-panel ;;
        7) clear ; auto_backup ;;
        8) clear ; bw ;;
        9) clear ; bot_telegram ;;
        10) clear ; restart_server ;;
        11) clear ; autoreboot ;;
        12) clear ; speedtest ;;
        13) clear ; monitoring ;;
        14) clear ; restart_service ;;
        15) clear ; wget -qO- bench.sh | bash ;;
        16) clear ; cek_vps_online ;;
        17) clear ; neo ;;
        18) clear ; menu-bot ;;
        19) clear ; info_vps ;;
        20) clear ; menu_backup ;;
        
        # FIX (21-30)
        21) clear ; fixcert ;;
        22) clear ; fixhap ;;
        23) clear ; fixxray ;;
        24) clear ; fixakunbot ;;
        25) clear ; fixnginx ;;
        26) clear ; wget -O /usr/bin/ws "https://raw.githubusercontent.com/AngIMAN/express/main/Fls/ws" >/dev/null 2>&1 && wget -O /usr/bin/tun.conf "https://raw.githubusercontent.com/AngIMAN/express/main/Cfg/tun.conf" >/dev/null 2>&1 && wget -O /etc/systemd/system/ws.service "https://raw.githubusercontent.com/AngIMAN/express/main/Fls/ws.service" >/dev/null 2>&1 && chmod +x /etc/systemd/system/ws.service && chmod +x /usr/bin/ws && chmod 644 /usr/bin/tun.conf && systemctl disable ws && systemctl stop ws && systemctl enable ws && systemctl start ws && systemctl restart ws ;;
        27) clear ; fixudp ;;
        28) clear ; delet-cache-file ;;
        29) clear ; clearcache ;;
        30) clear ; clearlog ;;
        
        # ADMIN & TOOLS (31-40)
        31) clear ; reboot ;;
        32) clear ; limitspeed ;;
        33) clear ; anti-ddos ;;
        34) clear ; Info_Port ;;
        35) clear ; about ;;
        36) clear ; Rename ;;
        37) clear ; wild ;;
        38) clear ; m-rebuild ;;
        39) clear ; botwa ;;
        40) clear ; m-adm ;;
        
        0) clear ; menu ;;
        *) clear ; menu ;;
    esac
}

# Rename Function dengan tampilan baru
function Rename() {
    clear
    Banner
    echo -e "${BLUE_CYAN}─────────────────────────────────────────────╯${NC}"
    echo -e "${CYAN}╭─ CHANGE SCRIPT NAME ───────────────────────────╮${NC}"
    echo -e "${YELLOW}│ [1] Rename Script${NC}                           ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ [2] Default Name${NC}                            ${YELLOW}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
    
    read -p " Select option : " host
    
    if [[ $host == "1" ]]; then
        echo -e "${CYAN}╭─ INPUT DETAILS ────────────────────────────────╮${NC}"
        read -p " │ Input Your Name : " host1
        read -p " │ Input Admin Pass : " host11
        echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
        
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
    echo -e "${CYAN}╭─ PERMISSION DENIED ────────────────────────────╮${NC}"
    echo -e "${YELLOW}│${NC}                                            ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}        ${RED}PERMISSION DENIED !${NC}                   ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}  ${ORANGE}Buy access permissions for scripts${NC}       ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}        ${ORANGE}Contact Admin :${NC}                    ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   ${GREEN}WhatsApp${NC} wa.me/628981874211              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}   ${GREEN}Telegram${NC} t.me/AimanVpnExpress            ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC}                                            ${YELLOW}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    sleep 3
    print_success "Script Name Default"
    sleep 2
    menu
}

# Main Execution
Banner
Menu_Lambofgod
Select_Menu
