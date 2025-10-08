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
# BANDWIDTH CALCULATION - FIXED
# =============================================
get_bandwidth() {
    # Simple bandwidth calculation
    today_rx=$(vnstat -d | grep $(date +"%d") | head -1 | awk '{print $2}' 2>/dev/null | sed 's/,//g' | grep -E '^[0-9.]+$' || echo "0")
    today_tx=$(vnstat -d | grep $(date +"%d") | head -1 | awk '{print $5}' 2>/dev/null | sed 's/,//g' | grep -E '^[0-9.]+$' || echo "0")
    
    # Convert to integer
    today_rx=${today_rx%.*}
    today_tx=${today_tx%.*}
    
    today_total=$((today_rx + today_tx))
    
    if [ $today_total -gt 1024 ]; then
        today_display=$(echo "scale=2; $today_total/1024" | bc 2>/dev/null || echo "0")
        today_unit="GB"
    else
        today_display=$today_total
        today_unit="MB"
    fi
    
    # Monthly
    month_rx=$(vnstat -m | grep $(date +"%b") | head -1 | awk '{print $3}' 2>/dev/null | sed 's/,//g' | grep -E '^[0-9.]+$' || echo "0")
    month_tx=$(vnstat -m | grep $(date +"%b") | head -1 | awk '{print $6}' 2>/dev/null | sed 's/,//g' | grep -E '^[0-9.]+$' || echo "0")
    
    month_rx=${month_rx%.*}
    month_tx=${month_tx%.*}
    
    month_total=$((month_rx + month_tx))
    
    if [ $month_total -gt 1024 ]; then
        month_display=$(echo "scale=2; $month_total/1024" | bc 2>/dev/null || echo "0")
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
    elif /etc/init.d/$service_name status 2>/dev/null | grep -q "running"; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

# =============================================
# ACCOUNT COUNT - FIXED
# =============================================
count_accounts() {
    # SSH Accounts
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    
    # Xray Accounts - using safer calculation
    if [ -f "/etc/xray/config.json" ]; then
        vmess_count=$(grep -c "^### " "/etc/xray/config.json" 2>/dev/null)
        vmess_count=$((vmess_count / 2))
        
        vless_count=$(grep -c "^#& " "/etc/xray/config.json" 2>/dev/null)
        vless_count=$((vless_count / 2))
        
        trojan_count=$(grep -c "^#! " "/etc/xray/config.json" 2>/dev/null)
        trojan_count=$((trojan_count / 2))
        
        shadowsocks_count=$(grep -c "^#!# " "/etc/xray/config.json" 2>/dev/null)
    else
        vmess_count=0
        vless_count=0
        trojan_count=0
        shadowsocks_count=0
    fi
    
    # NoobzVPN
    if [ -f "/etc/xray/noob" ]; then
        noob_count=$(grep -c "^### " "/etc/xray/noob" 2>/dev/null)
    else
        noob_count=0
    fi
    
    echo "$ssh_count $vmess_count $vless_count $trojan_count $shadowsocks_count $noob_count"
}

# =============================================
# DISPLAY FUNCTIONS
# =============================================

print_header() {
    clear
    echo -e "${ORANGE}════════════════════════════════════════════════════${NC}"
    echo -e "${BG_RED}${WHITE}                  👑  $author                  ${NC}"
    echo -e "${ORANGE}════════════════════════════════════════════════════${NC}"
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "DigitalOcean, LLC")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "sg3.myyy.my.id")
    local username=$(cat /usr/bin/user 2>/dev/null || echo "Sg3")
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ──────────────────────────────╮${NC}"
    echo -e "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}$username${NC}"
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
    bandwidth_data=$(get_bandwidth)
    today_bw=$(echo "$bandwidth_data" | cut -d';' -f1)
    monthly_bw=$(echo "$bandwidth_data" | cut -d';' -f2)
    
    echo -e "${GREEN}╭─ BANDWIDTH USAGE ────────────────────────────────╮${NC}"
    echo -e "${GREEN}│ ${YELLOW}📊 TODAY${NC}   : ${WHITE}$today_bw${NC}"
    echo -e "${GREEN}│ ${YELLOW}📈 MONTHLY${NC} : ${WHITE}$monthly_bw${NC}"
    echo -e "${GREEN}╰───────────────────────────────────────────────────╯${NC}"
}

print_accounts() {
    accounts_data=$(count_accounts)
    ssh_count=$(echo $accounts_data | awk '{print $1}')
    vmess_count=$(echo $accounts_data | awk '{print $2}')
    vless_count=$(echo $accounts_data | awk '{print $3}')
    trojan_count=$(echo $accounts_data | awk '{print $4}')
    shadowsocks_count=$(echo $accounts_data | awk '{print $5}')
    noob_count=$(echo $accounts_data | awk '{print $6}')
    
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
# MENU FUNCTIONS - SIMPLE WORKING
# =============================================
menu-ssh() {
    echo -e "${GREEN}Opening SSH Menu...${NC}"
    # Your SSH menu script here
    /usr/bin/menu-ssh
}

menu-vmess() {
    echo -e "${GREEN}Opening VMESS Menu...${NC}"
    # Your VMESS menu script here
    /usr/bin/menu-vmess
}

menu-vless() {
    echo -e "${GREEN}Opening VLESS Menu...${NC}"
    # Your VLESS menu script here
    /usr/bin/menu-vless
}

menu-trojan() {
    echo -e "${GREEN}Opening Trojan Menu...${NC}"
    # Your Trojan menu script here
    /usr/bin/menu-trojan
}

menu-ss() {
    echo -e "${GREEN}Opening Shadowsocks Menu...${NC}"
    # Your Shadowsocks menu script here
    /usr/bin/menu-ss
}

menu-set() {
    echo -e "${GREEN}Opening System Menu...${NC}"
    # Your System menu script here
    /usr/bin/menu-set
}

menu-backup() {
    echo -e "${GREEN}Opening Backup Menu...${NC}"
    # Your Backup menu script here
    /usr/bin/menu-backup
}

menu() {
    echo -e "${GREEN}Opening Admin Menu...${NC}"
    # Your Admin menu script here
    /usr/bin/menu
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
    1) menu-ssh ;;
    2) menu-vmess ;;
    3) menu-vless ;;
    4) menu-trojan ;;
    5) menu-ss ;;
    6) echo -e "${GREEN}Opening NoobzVPN Menu...${NC}" ;;
    7) menu-set ;;
    8) echo -e "${GREEN}Opening Bot Telegram...${NC}" ;;
    9) reboot ;;
    10) menu-backup ;;
    11) speedtest ;;
    12) menu ;;
    *) echo -e "${RED}Invalid option!${NC}" ;;
esac
