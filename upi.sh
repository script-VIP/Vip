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
NC='\033[0m'

# =============================================
# SYSTEM VARIABLES
# =============================================
MYIP=$(curl -sS ipv4.icanhazip.com)
author=$(cat /etc/xray/username 2>/dev/null || echo "SCRIPTUN-VIP")

# =============================================
# BANDWIDTH CALCULATION
# =============================================
calculate_bandwidth() {
    local vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*')
    local today_rx today_tx month_rx month_tx
    
    today_rx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $2}' | sed 's/,//g')
    today_tx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $5}' | sed 's/,//g')
    
    local bulan=$(date +%b)
    local tahun=$(date +%Y)
    month_rx=$(vnstat -i ${vnstat_profile} -m | grep "$bulan $tahun" | awk '{print $3}' | sed 's/,//g')
    month_tx=$(vnstat -i ${vnstat_profile} -m | grep "$bulan $tahun" | awk '{print $6}' | sed 's/,//g')
    
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
    
    echo "$today_display $today_unit;$month_display $month_unit"
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
# ACCOUNT COUNT
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
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                   👑 Author: $author                       ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "Unknown")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not Set")
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}$(cat /usr/bin/user 2>/dev/null || echo "Unknown")${NC}"
    echo -e "${CYAN}│ ${YELLOW}🖥️ OS      ${NC}: ${WHITE}$os_info${NC}"
    echo -e "${CYAN}│ ${YELLOW}💾 RAM     ${NC}: ${WHITE}${ram}MB${NC}"
    echo -e "${CYAN}│ ${YELLOW}🌐 IP VPS  ${NC}: ${WHITE}$MYIP${NC}"
    echo -e "${CYAN}│ ${YELLOW}🏢 ISP     ${NC}: ${WHITE}$isp${NC}"
    echo -e "${CYAN}│ ${YELLOW}🔗 Domain  ${NC}: ${WHITE}$domain${NC}"
    echo -e "${CYAN}│ ${YELLOW}⏰ Active  ${NC}: ${GREEN}$(((d1 - d2) / 86400)) Days${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_service_status() {
    echo -e "${PURPLE}╭─ SERVICE STATUS ───────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│ ${CYAN}🔄 HAPROXY ${NC}: $(get_service_status haproxy systemctl)  ${PURPLE}│ ${CYAN}🌐 NGINX   ${NC}: $(get_service_status nginx systemctl)  ${PURPLE}│ ${CYAN}⚡ SSHWS ${NC}: $(get_service_status ws systemctl)   ${PURPLE}│${NC}"
    echo -e "${PURPLE}│ ${CYAN}🚀 XRAY    ${NC}: $(get_service_status xray systemctl)  ${PURPLE}│ ${CYAN}🔐 SSH     ${NC}: $(get_service_status ssh service)  ${PURPLE}│ ${CYAN}🐻 DROP   ${NC}: $(get_service_status dropbear service) ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰─────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_accounts() {
    IFS=';' read -r ssh_count vmess_count vless_count trojan_count shadowsocks_count noob_count <<< "$(count_accounts)"
    IFS=';' read -r today_bw monthly_bw <<< "$(calculate_bandwidth)"
    
    echo -e "${GREEN}╭─ ACCOUNT SUMMARY ──────────────────────────────────────────╮${NC}"
    echo -e "${GREEN}│ ${YELLOW}[1] SSH OVPN     ${NC}: ${WHITE}$ssh_count User${NC}"
    echo -e "${GREEN}│ ${YELLOW}[2] VMESS        ${NC}: ${WHITE}$vmess_count User${NC}"
    echo -e "${GREEN}│ ${YELLOW}[3] VLESS        ${NC}: ${WHITE}$vless_count User${NC}"
    echo -e "${GREEN}│ ${YELLOW}[4] TROJAN       ${NC}: ${WHITE}$trojan_count User${NC}"
    echo -e "${GREEN}│ ${YELLOW}[5] SHADOWSOCK   ${NC}: ${WHITE}$shadowsocks_count User${NC}"
    echo -e "${GREEN}│ ${YELLOW}[6] NOOBZVPN     ${NC}: ${WHITE}$noob_count User${NC}"
    echo -e "${GREEN}╰────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_bandwidth() {
    IFS=';' read -r today_bw monthly_bw <<< "$(calculate_bandwidth)"
    
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   📊 TODAY: ${GREEN}$today_bw${YELLOW}    📈 MONTHLY: ${GREEN}$monthly_bw${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_menu() {
    echo -e "${RED}╭─ MAIN MENU ─────────────────────────────────────────────────╮${NC}"
    echo -e "${RED}│ ${YELLOW}[7] Menu System      ${RED}│ ${YELLOW}[10] Menu Backup     ${RED}│${NC}"
    echo -e "${RED}│ ${YELLOW}[8] Bot Telegram     ${RED}│ ${YELLOW}[11] Info VPS        ${RED}│${NC}"
    echo -e "${RED}│ ${YELLOW}[9] Restart Server   ${RED}│ ${YELLOW}[12] Menu Admin      ${RED}│${NC}"
    echo -e "${RED}╰─────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

# =============================================
# MAIN EXECUTION
# =============================================
d1=$(date -d "$(cat /usr/bin/e 2>/dev/null || echo $(date +%Y-%m-%d))" +%s 2>/dev/null || date +%s)
d2=$(date -d "$(date +%Y-%m-%d)" +%s)

print_header
print_system_info
print_service_status
print_accounts
print_bandwidth
print_menu

echo -e "${GREEN}👉 Select menu option: ${NC}\c"
read -p "" menu_option

case $menu_option in
    1) echo "SSH Menu" ;;
    2) echo "VMESS Menu" ;;
    3) echo "VLESS Menu" ;;
    4) echo "Trojan Menu" ;;
    5) echo "Shadowsocks Menu" ;;
    6) echo "NoobzVPN Menu" ;;
    7) echo "System Menu" ;;
    8) echo "Bot Telegram" ;;
    9) echo "Restart Server" ;;
    10) echo "Backup Menu" ;;
    11) echo "VPS Info" ;;
    12) echo "Admin Menu" ;;
    *) echo "Invalid option" ;;
esac# BANDWIDTH CALCULATION FUNCTIONS
# =============================================
calculate_bandwidth() {
    local vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*')
    local today_rx today_tx month_rx month_tx
    
    # Today's bandwidth
    today_rx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $2}' | sed 's/,//g')
    today_tx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $5}' | sed 's/,//g')
    
    # Monthly bandwidth  
    local bulan=$(date +%b)
    local tahun=$(date +%Y)
    month_rx=$(vnstat -i ${vnstat_profile} -m | grep "$bulan $tahun" | awk '{print $3}' | sed 's/,//g')
    month_tx=$(vnstat -i ${vnstat_profile} -m | grep "$bulan $tahun" | awk '{print $6}' | sed 's/,//g')
    
    # Convert to appropriate units
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
    
    echo "$today_display $today_unit;$month_display $month_unit"
}

# =============================================
# SERVICE STATUS FUNCTIONS
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
        echo -e "${GREEN}● RUNNING${NC}"
    else
        echo -e "${RED}● STOPPED${NC}"
    fi
}

# =============================================
# ACCOUNT COUNT FUNCTIONS
# =============================================
count_accounts() {
    # SSH Accounts
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    
    # Xray Accounts (adjust paths as needed)
    vmess_count=$(grep -c "^### " "/etc/xray/config.json" 2>/dev/null || echo 0)
    vless_count=$(grep -c "^#& " "/etc/xray/config.json" 2>/dev/null || echo 0)
    trojan_count=$(grep -c "^#! " "/etc/xray/config.json" 2>/dev/null || echo 0)
    shadowsocks_count=$(grep -c "^#!# " "/etc/xray/config.json" 2>/dev/null || echo 0)
    noob_count=$(grep -c "^### " "/etc/xray/noob" 2>/dev/null || echo 0)
    
    echo "$ssh_count;$((vmess_count/2));$((vless_count/2));$((trojan_count/2));$shadowsocks_count;$noob_count"
}

# =============================================
# DISPLAY FUNCTIONS - MODERN DESIGN
# =============================================

print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}${BG_BLUE}${WHITE}                     🚀 J u i c e S S H  P r e m i u m                     ${NC}${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}${BG_BLUE}${WHITE}                         👑 Author: $author                         ${NC}${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "Unknown")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not Set")
    
    echo -e "${PURPLE}🖥️  SYSTEM INFORMATION${NC}"
    echo -e "${CYAN}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ ${YELLOW}📛 Username${NC}    : ${WHITE}$(cat /usr/bin/user 2>/dev/null || echo "Unknown")${NC}"
    echo -e "${CYAN}│ ${YELLOW}🖥️  OS${NC}         : ${WHITE}$os_info${NC}"
    echo -e "${CYAN}│ ${YELLOW}💾 RAM${NC}         : ${WHITE}${ram}MB${NC}"
    echo -e "${CYAN}│ ${YELLOW}🌐 IP VPS${NC}      : ${WHITE}$MYIP${NC}"
    echo -e "${CYAN}│ ${YELLOW}🏢 ISP${NC}         : ${WHITE}$isp${NC}"
    echo -e "${CYAN}│ ${YELLOW}🔗 Domain${NC}      : ${WHITE}$domain${NC}"
    echo -e "${CYAN}│ ${YELLOW}⏰ Active${NC}      : ${GREEN}$(((d1 - d2) / 86400)) Days${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_service_status() {
    echo -e "${GREEN}🔧 SERVICE STATUS${NC}"
    echo -e "${YELLOW}┌──────────────────────┬──────────────────────┬──────────────────────┐${NC}"
    
    # Row 1
    echo -e "${YELLOW}│${NC} ${CYAN}🔄 HAPROXY${NC} : $(get_service_status haproxy systemctl) ${YELLOW}│${NC} ${CYAN}🌐 NGINX${NC}   : $(get_service_status nginx systemctl) ${YELLOW}│${NC} ${CYAN}⚡ SSHWS${NC}   : $(get_service_status ws systemctl) ${YELLOW}│${NC}"
    
    # Row 2  
    echo -e "${YELLOW}│${NC} ${CYAN}🚀 XRAY${NC}    : $(get_service_status xray systemctl) ${YELLOW}│${NC} ${CYAN}🔐 SSH${NC}     : $(get_service_status ssh service) ${YELLOW}│${NC} ${CYAN}🐻 DROPBEAR${NC}: $(get_service_status dropbear service) ${YELLOW}│${NC}"
    
    echo -e "${YELLOW}└──────────────────────┴──────────────────────┴──────────────────────┘${NC}"
    echo ""
}

print_accounts() {
    IFS=';' read -r ssh_count vmess_count vless_count trojan_count shadowsocks_count noob_count <<< "$(count_accounts)"
    IFS=';' read -r today_bw monthly_bw <<< "$(calculate_bandwidth)"
    
    echo -e "${ORANGE}👥 ACCOUNT SUMMARY & BANDWIDTH${NC}"
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${NC}"
    
    # Row 1
    echo -e "${PINK}║${NC} ${YELLOW}[1]${NC} ${WHITE}SSH OVPN${NC}     ${GREEN}➜ $ssh_count Users${NC}        ${PINK}║${NC} ${YELLOW}[4]${NC} ${WHITE}TROJAN${NC}      ${GREEN}➜ $trojan_count Users${NC}     ${PINK}║${NC}"
    
    # Row 2
    echo -e "${PINK}║${NC} ${YELLOW}[2]${NC} ${WHITE}VMESS${NC}        ${GREEN}➜ $vmess_count Users${NC}        ${PINK}║${NC} ${YELLOW}[5]${NC} ${WHITE}SHADOWSOCK${NC} ${GREEN}➜ $shadowsocks_count Users${NC} ${PINK}║${NC}"
    
    # Row 3  
    echo -e "${PINK}║${NC} ${YELLOW}[3]${NC} ${WHITE}VLESS${NC}        ${GREEN}➜ $vless_count Users${NC}        ${PINK}║${NC} ${YELLOW}[6]${NC} ${WHITE}NOOBZVPN${NC}    ${GREEN}➜ $noob_count Users${NC}       ${PINK}║${NC}"
    
    echo -e "${PINK}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PINK}║${NC} ${CYAN}📊 TODAY: ${GREEN}$today_bw${NC}    ${CYAN}📈 MONTHLY: ${GREEN}$monthly_bw${NC}                          ${PINK}║${NC}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    echo -e "${RED}🎯 MAIN MENU OPTIONS${NC}"
    echo -e "${BLUE}╔═══════════════════════════╦════════════════════════════╗${NC}"
    
    # Column 1
    echo -e "${BLUE}║${NC} ${YELLOW}[7]${NC} ${WHITE}🛠️  MENU SYSTEM${NC}        ${BLUE}║${NC} ${YELLOW}[10]${NC} ${WHITE}💾 MENU BACKUP${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}[8]${NC} ${WHITE}🤖 BOT TELEGRAM${NC}       ${BLUE}║${NC} ${YELLOW}[11]${NC} ${WHITE}ℹ️  INFO VPS${NC}           ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} ${YELLOW}[9]${NC} ${WHITE}🔄 RESTART SERVER${NC}     ${BLUE}║${NC} ${YELLOW}[12]${NC} ${WHITE}👑 MENU ADMIN${NC}         ${BLUE}║${NC}"
    
    echo -e "${BLUE}╚═══════════════════════════╩════════════════════════════╝${NC}"
    echo ""
}

# =============================================
# MAIN EXECUTION
# =============================================

# Initialize date variables for active days calculation
d1=$(date -d "$(cat /usr/bin/e 2>/dev/null || echo $(date +%Y-%m-%d))" +%s 2>/dev/null || date +%s)
d2=$(date -d "$(date +%Y-%m-%d)" +%s)
active_days=$(( (d1 - d2) / 86400 ))

# Main display sequence
print_header
print_system_info
print_service_status
print_accounts
print_menu

# User input
echo -e "${GREEN}${BLINK}👉${NC}${WHITE} Select menu option: ${NC}\c"
read -p "" menu_option

# Menu handling (placeholder - add your actual functions)
case $menu_option in
    1) echo "SSH Menu" ;;
    2) echo "VMESS Menu" ;;
    3) echo "VLESS Menu" ;;
    4) echo "Trojan Menu" ;;
    5) echo "Shadowsocks Menu" ;;
    6) echo "NoobzVPN Menu" ;;
    7) echo "System Menu" ;;
    8) echo "Bot Telegram" ;;
    9) echo "Restart Server" ;;
    10) echo "Backup Menu" ;;
    11) echo "VPS Info" ;;
    12) echo "Admin Menu" ;;
    *) echo "Invalid option" ;;
esac            
            echo -e "    $(printf '%-9s %-12s %-10s %-15s' "$waktu" "$user" "$limit" "$status")"
            ((total_login++))
        fi
    done
fi

