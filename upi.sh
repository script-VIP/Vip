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
BG_RED='\033[48;5;196m'
BG_GREEN='\033[48;5;46m'
BG_BLUE='\033[48;5;33m'
BG_YELLOW='\033[48;5;226m'
NC='\033[0m'

# =============================================
# SYSTEM VARIABLES
# =============================================
MYIP=$(curl -sS ipv4.icanhazip.com)
author=$(cat /etc/xray/username 2>/dev/null || echo "AIMAN-VPN")

# =============================================
# BANDWIDTH CALCULATION - FIXED
# =============================================
calculate_bandwidth() {
    local vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*')
    local today_rx today_tx month_rx month_tx
    
    # Today's bandwidth
    today_rx=$(vnstat -i ${vnstat_profile} 2>/dev/null | grep today | awk '{print $2}' | sed 's/,//g' | grep -E '^[0-9]+$' || echo "0")
    today_tx=$(vnstat -i ${vnstat_profile} 2>/dev/null | grep today | awk '{print $5}' | sed 's/,//g' | grep -E '^[0-9]+$' || echo "0")
    
    # Monthly bandwidth
    local bulan=$(date +%b)
    local tahun=$(date +%Y)
    month_rx=$(vnstat -i ${vnstat_profile} -m 2>/dev/null | grep "$bulan $tahun" | awk '{print $3}' | sed 's/,//g' | grep -E '^[0-9]+$' || echo "0")
    month_tx=$(vnstat -i ${vnstat_profile} -m 2>/dev/null | grep "$bulan $tahun" | awk '{print $6}' | sed 's/,//g' | grep -E '^[0-9]+$' || echo "0")
    
    today_total=$((today_rx + today_tx))
    month_total=$((month_rx + month_tx))
    
    # Format today
    if [ $today_total -gt 1048576 ]; then
        today_display=$(echo "scale=2; $today_total/1048576" | bc)
        today_unit="TB"
    elif [ $today_total -gt 1024 ]; then
        today_display=$(echo "scale=2; $today_total/1024" | bc)
        today_unit="GB"
    else
        today_display=$today_total
        today_unit="MB"
    fi
    
    # Format monthly
    if [ $month_total -gt 1048576 ]; then
        month_display=$(echo "scale=2; $month_total/1048576" | bc)
        month_unit="TB"
    elif [ $month_total -gt 1024 ]; then
        month_display=$(echo "scale=2; $month_total/1024" | bc)
        month_unit="GB"
    else
        month_display=$month_total
        month_unit="MB"
    fi
    
    echo "${today_display} ${today_unit};${month_display} ${month_unit}"
}

# =============================================
# SERVICE STATUS
# =============================================
get_service_status() {
    local service_name=$1
    local service_type=$2
    
    if [ "$service_type" == "systemctl" ]; then
        status=$(systemctl is-active $service_name 2>/dev/null)
    else
        status=$($service_name status 2>/dev/null | grep -o "running\|active" | head -1)
    fi
    
    if [ "$status" == "running" ] || [ "$status" == "active" ]; then
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
    vmess_count=$(grep -c "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)
    vless_count=$(grep -c "^#& " "/etc/xray/config.json" 2>/dev/null || echo 0)
    trojan_count=$(grep -c "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)
    shadowsocks_count=$(grep -c "^#!# " "/etc/xray/config.json" 2>/dev/null || echo 0)
    noob_count=$(grep -c "^### " "/etc/xray/noob" 2>/dev/null || echo 0)
    
    echo "$ssh_count;$((vmess_count/2));$((vless_count/2));$((trojan_count/2));$shadowsocks_count;$noob_count"
}

# =============================================
# DISPLAY FUNCTIONS
# =============================================

print_header() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BG_BLUE}${WHITE}                  🚀 J u i c e S S H                  ${NC}"
    echo -e "${BG_BLUE}${WHITE}                  👑 A u t h o r : $author                  ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo ""
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
    echo -e "${CYAN}│ ${YELLOW}⏰ Active  ${NC}: ${GREEN}$(((d1 - d2) / 86400)) Days${NC}"
    echo -e "${CYAN}╰───────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_service_status() {
    echo -e "${PURPLE}╭─ SERVICE STATUS ─────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│ ${CYAN}🔄 HAPROXY ${NC}: $(get_service_status haproxy systemctl)  ${PURPLE}│ ${CYAN}🌐 NGINX ${NC}: $(get_service_status nginx systemctl)  ${PURPLE}│ ${CYAN}⚡ SSHWS ${NC}: $(get_service_status ws systemctl) ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ ${CYAN}🚀 XRAY    ${NC}: $(get_service_status xray systemctl)  ${PURPLE}│ ${CYAN}🔐 SSH   ${NC}: $(get_service_status ssh service)  ${PURPLE}│ ${CYAN}🐻 DROP  ${NC}: $(get_service_status dropbear service) ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰───────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_bandwidth() {
    IFS=';' read -r today_bw monthly_bw <<< "$(calculate_bandwidth)"
    
    echo -e "${GREEN}╭─ BANDWIDTH USAGE ────────────────────────────────╮${NC}"
    echo -e "${GREEN}│ ${YELLOW}📊 TODAY${NC}   : ${WHITE}$today_bw${NC}"
    echo -e "${GREEN}│ ${YELLOW}📈 MONTHLY${NC} : ${WHITE}$monthly_bw${NC}"
    echo -e "${GREEN}╰───────────────────────────────────────────────────╯${NC}"
    echo ""
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
    echo ""
}

print_menu() {
    echo -e "${RED}╭─ MAIN MENU ───────────────────────────────────────╮${NC}"
    echo -e "${RED}│ ${WHITE}[7] Menu System    ${RED}│ ${WHITE}[10] Menu Backup   ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[8] Bot Telegram   ${RED}│ ${WHITE}[11] Info VPS      ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[9] Restart Server ${RED}│ ${WHITE}[12] Menu Admin    ${RED}│${NC}"
    echo -e "${RED}╰───────────────────────────────────────────────────╯${NC}"
    echo ""
}

# =============================================
# MENU FUNCTIONS - FROM YOUR ORIGINAL SCRIPT
# =============================================
m-ssh() { echo "SSH Menu"; }
m-xray() { echo "VMESS Menu"; }
m-xray2() { echo "VLESS Menu"; }
m-tro() { echo "Trojan Menu"; }
m-ssr() { echo "Shadowsocks Menu"; }
m-noobz() { echo "NoobzVPN Menu"; }
m-ftr2() { echo "System Menu"; }
m-bot() { echo "Bot Telegram"; }
m-bkp() { echo "Backup Menu"; }
m-adm() { echo "Admin Menu"; }
Rename() { echo "Rename Menu"; }
add-ip-bot() { echo "Add IP Bot"; }
cekudp() { echo "Check UDP"; }

# =============================================
# MAIN EXECUTION
# =============================================
# Initialize date variables
d1=$(date -d "$(cat /usr/bin/e 2>/dev/null || echo $(date -d "+30 days" +%Y-%m-%d))" +%s 2>/dev/null)
d2=$(date -d "$(date +%Y-%m-%d)" +%s)
if [ -z "$d1" ]; then
    d1=$((d2 + 2592000)) # 30 days from now
fi

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
    9) reset ;;
    10) m-bkp ;;
    11) wget -qO- bench.sh | bash ;;
    12) m-adm ;;
    *) echo "Invalid option" ;;
esac
