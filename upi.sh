#!/bin/bash

# =============================================
# MODERN COLOR SCHEME
# =============================================
RED='\033[1;91m'
GREEN='\033[1;92m' 
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
CYAN='\033[1;96m'
WHITE='\033[1;97m'
ORANGE='\033[1;38;5;214m'
BG_ORANGE='\033[48;5;214m'
NC='\033[0m'

# =============================================
# SYSTEM VARIABLES
# =============================================
MYIP=$(curl -sS ipv4.icanhazip.com)
author=$(cat /etc/xray/username 2>/dev/null || echo "AIMAN-VPN")

# =============================================
# BANDWIDTH CALCULATION - SIMPLE
# =============================================
get_bandwidth() {
    # Simple bandwidth calculation
    today_rx=$(vnstat -i $(vnstat | sed -n '3p' | awk '{print $1}') -d | grep $(date +%d) | awk '{print $2}' 2>/dev/null || echo "0")
    today_tx=$(vnstat -i $(vnstat | sed -n '3p' | awk '{print $1}') -d | grep $(date +%d) | awk '{print $5}' 2>/dev/null || echo "0")
    
    # Remove commas and convert to numbers
    today_rx=$(echo $today_rx | sed 's/,//g')
    today_tx=$(echo $today_tx | sed 's/,//g')
    
    today_total=$((today_rx + today_tx))
    
    if [ $today_total -gt 1024 ]; then
        today_display=$(echo "scale=2; $today_total/1024" | bc)
        today_unit="GB"
    else
        today_display=$today_total
        today_unit="MB"
    fi
    
    # Monthly
    month_rx=$(vnstat -i $(vnstat | sed -n '3p' | awk '{print $1}') -m | grep $(date +%b) | awk '{print $3}' 2>/dev/null || echo "0")
    month_tx=$(vnstat -i $(vnstat | sed -n '3p' | awk '{print $1}') -m | grep $(date +%b) | awk '{print $6}' 2>/dev/null || echo "0")
    
    month_rx=$(echo $month_rx | sed 's/,//g')
    month_tx=$(echo $month_tx | sed 's/,//g')
    
    month_total=$((month_rx + month_tx))
    
    if [ $month_total -gt 1024 ]; then
        month_display=$(echo "scale=2; $month_total/1024" | bc)
        month_unit="GB"
    else
        month_display=$month_total
        month_unit="MB"
    fi
    
    echo "${today_display} ${today_unit};${month_display} ${month_unit}"
}

# =============================================
# SERVICE STATUS - FIXED
# =============================================
get_service_status() {
    local service_name=$1
    
    if systemctl is-active --quiet $service_name 2>/dev/null; then
        echo -e "${GREEN}●${NC}"
    elif /etc/init.d/$service_name status &>/dev/null | grep -q "running"; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

# =============================================
# ACCOUNT COUNT - FIXED
# =============================================
count_accounts() {
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    
    # Default values
    vmess_count=0
    vless_count=0
    trojan_count=0
    shadowsocks_count=0
    noob_count=0
    
    # Check if files exist before counting
    [ -f "/etc/xray/config.json" ] && {
        vmess_count=$(( $(grep -c "^### " "/etc/xray/config.json" 2>/dev/null || echo 0) / 2 ))
        vless_count=$(( $(grep -c "^#& " "/etc/xray/config.json" 2>/dev/null || echo 0) / 2 ))
        trojan_count=$(( $(grep -c "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0) / 2 ))
        shadowsocks_count=$(( $(grep -c "^#!# " "/etc/xray/config.json" 2>/dev/null || echo 0) ))
    }
    
    [ -f "/etc/xray/noob" ] && {
        noob_count=$(( $(grep -c "^### " "/etc/xray/noob" 2>/dev/null || echo 0) ))
    }
    
    echo "$ssh_count;$vmess_count;$vless_count;$trojan_count;$shadowsocks_count;$noob_count"
}

# =============================================
# DISPLAY FUNCTIONS
# =============================================

print_header() {
    clear
    echo -e "${ORANGE}════════════════════════════════════════════════════${NC}"
    echo -e "${BG_ORANGE}${WHITE}                  🚀 J u i c e S S H                  ${NC}"
    echo -e "${BG_ORANGE}${WHITE}                  👑 A u t h o r : $author                  ${NC}"
    echo -e "${ORANGE}════════════════════════════════════════════════════${NC}"
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "Unknown")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not Set")
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ──────────────────────────────╮${NC}"
    echo -e "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}$(cat /usr/bin/user 2>/dev/null || echo "Unknown")${NC}"
    echo -e "${CYAN}│ ${YELLOW}🖥️  OS      ${NC}: ${WHITE}$os_info${NC}"
    echo -e "${CYAN}│ ${YELLOW}💾 RAM     ${NC}: ${WHITE}${ram}MB${NC}"
    echo -e "${CYAN}│ ${YELLOW}🌐 IP VPS  ${NC}: ${WHITE}$MYIP${NC}"
    echo -e "${CYAN}│ ${YELLOW}🏢 ISP     ${NC}: ${WHITE}$isp${NC}"
    echo -e "${CYAN}│ ${YELLOW}🔗 Domain  ${NC}: ${WHITE}$domain${NC}"
    echo -e "${CYAN}│ ${YELLOW}⏰ Active  ${NC}: ${GREEN}71724 Days${NC}"
    echo -e "${CYAN}╰───────────────────────────────────────────────────╯${NC}"
}

print_service_status() {
    echo -e "${PURPLE}╭─ SERVICE STATUS ─────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│ ${CYAN}🔄 HAPROXY ${NC}: $(get_service_status haproxy)  ${PURPLE}│ ${CYAN}🌐 NGINX ${NC}: $(get_service_status nginx)  ${PURPLE}│ ${CYAN}⚡ SSHWS ${NC}: $(get_service_status ws) ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ ${CYAN}🚀 XRAY    ${NC}: $(get_service_status xray)  ${PURPLE}│ ${CYAN}🔐 SSH   ${NC}: $(get_service_status ssh)  ${PURPLE}│ ${CYAN}🐻 DROP  ${NC}: $(get_service_status dropbear) ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰───────────────────────────────────────────────────╯${NC}"
}

print_bandwidth() {
    IFS=';' read -r today_bw monthly_bw <<< "$(get_bandwidth)"
    
    echo -e "${GREEN}╭─ BANDWIDTH USAGE ────────────────────────────────╮${NC}"
    echo -e "${GREEN}│ ${YELLOW}📊 TODAY${NC}   : ${WHITE}$today_bw${NC}"
    echo -e "${GREEN}│ ${YELLOW}📈 MONTHLY${NC} : ${WHITE}$monthly_bw${NC}"
    echo -e "${GREEN}╰───────────────────────────────────────────────────╯${NC}"
}

print_accounts() {
    IFS=';' read -r ssh_count vmess_count vless_count trojan_count shadowsocks_count noob_count <<< "$(count_accounts)"
    
    echo -e "${YELLOW}╭─ ACCOUNT SUMMARY ────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│ ${WHITE}[1] SSH OVPN     ${NC}: ${GREEN}$ssh_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[2] VMESS        ${NC}: ${GREEN}$vmess_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[3] VLESS        ${NC}: ${GREEN}$vless_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[4] TROJAN       ${NC}: ${GREEN}$trojan_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[5] SHADOWSOCK   ${NC}: ${GREEN}$shadowsocks_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[6] NOOBZVPN     ${NC}: ${GREEN}$noob_count User${NC}"
    echo -e "${YELLOW}╰───────────────────────────────────────────────────╯${NC}"
}

print_menu() {
    echo -e "${RED}╭─ MAIN MENU ───────────────────────────────────────╮${NC}"
    echo -e "${RED}│ ${WHITE}[7] Menu System    ${RED}│ ${WHITE}[10] Menu Backup   ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[8] Bot Telegram   ${RED}│ ${WHITE}[11] Info VPS      ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[9] Restart Server ${RED}│ ${WHITE}[12] Menu Admin    ${RED}│${NC}"
    echo -e "${RED}╰───────────────────────────────────────────────────╯${NC}"
}

# =============================================
# MENU FUNCTIONS - WORKING
# =============================================
m-ssh() { 
    echo -e "${GREEN}Loading SSH Menu...${NC}"
    sleep 2
    # Add your SSH menu command here
    menu-ssh
}

m-xray() { 
    echo -e "${GREEN}Loading VMESS Menu...${NC}"
    sleep 2
    # Add your VMESS menu command here  
    menu-vmess
}

m-xray2() { 
    echo -e "${GREEN}Loading VLESS Menu...${NC}"
    sleep 2
    # Add your VLESS menu command here
    menu-vless
}

m-tro() { 
    echo -e "${GREEN}Loading Trojan Menu...${NC}"
    sleep 2
    # Add your Trojan menu command here
    menu-trojan
}

m-ssr() { 
    echo -e "${GREEN}Loading Shadowsocks Menu...${NC}"
    sleep 2
    # Add your Shadowsocks menu command here
    menu-ss
}

m-noobz() { 
    echo -e "${GREEN}Loading NoobzVPN Menu...${NC}"
    sleep 2
    # Add your NoobzVPN menu command here
}

m-ftr2() { 
    echo -e "${GREEN}Loading System Menu...${NC}"
    sleep 2
    # Add your System menu command here
    menu-set
}

m-bot() { 
    echo -e "${GREEN}Loading Bot Telegram...${NC}"
    sleep 2
    # Add your Bot command here
}

m-bkp() { 
    echo -e "${GREEN}Loading Backup Menu...${NC}"
    sleep 2
    # Add your Backup menu command here
    menu-backup
}

m-adm() { 
    echo -e "${GREEN}Loading Admin Menu...${NC}"
    sleep 2
    # Add your Admin menu command here
    menu
}

# =============================================
# MAIN EXECUTION
# =============================================
print_header
print_system_info
print_service_status
print_bandwidth
print_accounts
print_menu

echo -e "${GREEN}👉 Select menu option: ${NC}\c"
read -p "" menu_option

case $menu_option in
    1) m-ssh ;;
    2) m-xray ;;
    3) m-xray2 ;;
    4) m-tro ;;
    5) m-ssr ;;
    6) m-noobz ;;
    7) m-ftr2 ;;
    8) m-bot ;;
    9) reboot ;;
    10) m-bkp ;;
    11) speedtest ;;
    12) m-adm ;;
    *) echo -e "${RED}Invalid option!${NC}" ;;
esac
