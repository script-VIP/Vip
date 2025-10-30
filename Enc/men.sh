# Backup dulu
cp /usr/local/sbin/menu /usr/local/sbin/menu.backup

# Hapus file lama
rm -f /usr/local/sbin/menu

# Buat file baru
cat > /usr/local/sbin/menu << 'EOF'
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
BG_RED='\033[48;5;196m'
NC='\033[0m'

# =============================================
# SYSTEM VARIABLES
# =============================================
MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || echo "Unknown")
author=$(cat /etc/xray/username 2>/dev/null || echo "AIMAN-VPN")

# =============================================
# BANDWIDTH CALCULATION
# =============================================
calculate_bandwidth() {
    if command -v vnstat >/dev/null 2>&1; then
        vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*' 2>/dev/null)
        if [ -n "$vnstat_profile" ]; then
            vnstat -i "${vnstat_profile}" > /etc/t1 2>/dev/null
            
            todayd=$(vnstat -i "${vnstat_profile}" | grep today | awk '{print $8}' 2>/dev/null || echo "0")
            today_v=$(vnstat -i "${vnstat_profile}" | grep today | awk '{print $9}' 2>/dev/null || echo "MB")
            
            echo "$todayd $today_v"
        else
            echo "0 MB"
        fi
    else
        echo "0 MB"
    fi
}

bandwidth_info=$(calculate_bandwidth)
today_total=$(echo "$bandwidth_info" | awk '{print $1}')
today_unit=$(echo "$bandwidth_info" | awk '{print $2}')

# =============================================
# LICENSE & EXPIRY DATE
# =============================================
if [ -f "/usr/bin/e" ]; then
    exp_date=$(cat /usr/bin/e)
    today=$(date +%Y-%m-%d)
    
    if [[ $exp_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        d1=$(date -d "$exp_date" +%s 2>/dev/null)
        d2=$(date -d "$today" +%s)
        
        if [ -n "$d1" ] && [ -n "$d2" ]; then
            days_left=$(((d1 - d2) / 86400))
            
            if [ $days_left -lt 0 ]; then
                days_text="EXPIRED ($exp_date)"
                days_color="${RED}"
            elif [ $days_left -le 7 ]; then
                days_text="$days_left Days ($exp_date)"
                days_color="${YELLOW}"
            else
                days_text="$days_left Days ($exp_date)"
                days_color="${GREEN}"
            fi
        else
            days_text="INVALID DATE"
            days_color="${RED}"
        fi
    else
        days_text="$exp_date"
        days_color="${YELLOW}"
    fi
else
    days_text="NOT SET"
    days_color="${RED}"
fi

# =============================================
# SERVICE STATUS
# =============================================
get_service_status() {
    local service_name=$1
    
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        echo -e "${GREEN}●${NC}"
    elif /etc/init.d/"$service_name" status 2>/dev/null | grep -q "running"; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

# =============================================
# ACCOUNT COUNT
# =============================================
count_accounts() {
    # SSH Accounts
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    
    # Default values untuk Xray
    vmess_count=0
    vless_count=0
    trojan_count=0
    shadowsocks_count=0
    noob_count=0
    
    echo "$ssh_count $vmess_count $vless_count $trojan_count $shadowsocks_count $noob_count"
}

# =============================================
# DISPLAY FUNCTIONS
# =============================================
print_header() {
    clear
    echo -e "${ORANGE}═════════════════════════════════════════════════${NC}"
    echo -e " ${BG_RED}${WHITE}                   👑 $author                   ${NC}"
    echo -e "${ORANGE}═════════════════════════════════════════════════${NC}"
    echo -e ""
}

print_system_info() {
    local os_info=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo "Unknown OS")
    local ram=$(free -m 2>/dev/null | awk 'NR==2{print $2}' || echo "0")
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "Unknown ISP")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "No Domain")
    local username=$(cat /usr/bin/user 2>/dev/null || whoami)
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ───────────────────────────╮${NC}"
    printf "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$username"
    printf "${CYAN}│ ${YELLOW}🖥️ OS      ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$os_info"
    printf "${CYAN}│ ${YELLOW}💾 RAM     ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "${ram}MB"
    printf "${CYAN}│ ${YELLOW}🌐 IP VPS  ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$MYIP"
    printf "${CYAN}│ ${YELLOW}🏢 ISP     ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$isp"
    printf "${CYAN}│ ${YELLOW}🔗 Domain  ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$domain"
    printf "${CYAN}│ ${YELLOW}⏰ Expiry  ${NC}: %-34s ${CYAN}│${NC}\n" "$days_color$days_text${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_service_status() {
    echo -e "${PURPLE}╭─ SERVICE STATUS ───────────────────────────────╮${NC}"
    printf "${PURPLE}│ ${CYAN}🔄 HAPROXY ${NC}: %-1s ${PURPLE} │ ${CYAN}🌐 NGINX ${NC}: %-1s ${PURPLE} │ ${CYAN}⚡ SSHWS ${NC}: %-1s ${PURPLE} │${NC}\n" \
           "$(get_service_status haproxy)" "$(get_service_status nginx)" "$(get_service_status ws)"
    printf "${PURPLE}│ ${CYAN}🚀 XRAY    ${NC}: %-1s ${PURPLE} │ ${CYAN}🔐 SSH   ${NC}: %-1s ${PURPLE} │ ${CYAN}🐻 DROPB ${NC}: %-1s ${PURPLE} │${NC}\n" \
           "$(get_service_status xray)" "$(get_service_status ssh)" "$(get_service_status dropbear)"
    echo -e "${PURPLE}╰────────────────────────────────────────────────╯${NC}"
}

print_bandwidth() {
    echo -e "${GREEN}╭─ BANDWIDTH USAGE ──────────────────────────────╮${NC}"
    printf "${GREEN}│ ${YELLOW}📊 TODAY ${NC}: ${WHITE}%-10s ${GREEN}│${NC}\n" "$today_total $today_unit"
    echo -e "${GREEN}╰────────────────────────────────────────────────╯${NC}"
    echo -e ""
}

print_accounts() {
    accounts_data=$(count_accounts)
    ssh_count=$(echo $accounts_data | awk '{print $1}')
    vmess_count=$(echo $accounts_data | awk '{print $2}')
    vless_count=$(echo $accounts_data | awk '{print $3}')
    trojan_count=$(echo $accounts_data | awk '{print $4}')
    shadowsocks_count=$(echo $accounts_data | awk '{print $5}')
    noob_count=$(echo $accounts_data | awk '{print $6}')
    
    echo -e "${YELLOW}╭─ ACCOUNT SUMMARY ──────────────────────────────╮${NC}"
    echo -e "${YELLOW}│ ${WHITE}[1] SSH OVPN  ${NC}: ${GREEN}$(printf '%-3s' "$ssh_count") ${NC}       ${WHITE}[4] TROJAN    ${NC}: ${GREEN}$(printf '%-3s' "$trojan_count") ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ ${WHITE}[2] VMESS     ${NC}: ${GREEN}$(printf '%-3s' "$vmess_count") ${NC}       ${WHITE}[5] SHADOWS   ${NC}: ${GREEN}$(printf '%-3s' "$shadowsocks_count") ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ ${WHITE}[3] VLESS     ${NC}: ${GREEN}$(printf '%-3s' "$vless_count") ${NC}       ${WHITE}[6] NOOBZVPN  ${NC}: ${GREEN}$(printf '%-3s' "$noob_count") ${YELLOW}│${NC}"
    echo -e "${YELLOW}╰────────────────────────────────────────────────╯${NC}"
}

print_menu() {
    echo -e "${RED}╭─ MAIN MENU ────────────────────────────────────╮${NC}"
    echo -e "${RED}│ ${WHITE}[7] Menu System        ${RED}│  ${WHITE}[10] Menu DorXL      ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[8] Bot Telegram       ${RED}│  ${WHITE}[11] Backup-Res      ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[9] Bot WhatsApp       ${RED}│  ${WHITE}[12] Restart Server  ${RED}│${NC}"
    echo -e "${RED}╰────────────────────────────────────────────────╯${NC}"
    echo -e ""
}

# =============================================
# MENU FUNCTIONS (Placeholder)
# =============================================
m-ssh() {
    echo -e "${GREEN}Loading SSH Menu...${NC}"
    sleep 2
    # Tambahkan command SSH menu di sini
}

m-xray() {
    echo -e "${GREEN}Loading Xray VMESS Menu...${NC}"
    sleep 2
    # Tambahkan command Xray menu di sini
}

m-xray2() {
    echo -e "${GREEN}Loading Xray VLESS Menu...${NC}"
    sleep 2
    # Tambahkan command Xray2 menu di sini
}

m-tro() {
    echo -e "${GREEN}Loading Trojan Menu...${NC}"
    sleep 2
    # Tambahkan command Trojan menu di sini
}

m-ssr() {
    echo -e "${GREEN}Loading Shadowsocks Menu...${NC}"
    sleep 2
    # Tambahkan command Shadowsocks menu di sini
}

m-noobz() {
    echo -e "${GREEN}Loading NoobzVPN Menu...${NC}"
    sleep 2
    # Tambahkan command NoobzVPN menu di sini
}

m-ftr2() {
    echo -e "${GREEN}Loading System Menu...${NC}"
    sleep 2
    # Tambahkan command System menu di sini
}

m-bot() {
    echo -e "${GREEN}Loading Telegram Bot Menu...${NC}"
    sleep 2
    # Tambahkan command Telegram Bot menu di sini
}

botwa() {
    echo -e "${GREEN}Loading WhatsApp Bot...${NC}"
    sleep 2
    # Tambahkan command WhatsApp Bot di sini
}

m-bkp() {
    echo -e "${GREEN}Loading Backup Menu...${NC}"
    sleep 2
    # Tambahkan command Backup menu di sini
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

read -p "  Select menu option :  " hallo

case $hallo in
    1) m-ssh ;;
    2) m-xray ;;
    3) m-xray2 ;;
    4) m-tro ;;
    5) m-ssr ;;
    6) m-noobz ;;
    7) m-ftr2 ;;
    8) m-bot ;;
    9) botwa ;;
    10) echo -e "${YELLOW}Downloading DorXL menu...${NC}" 
        wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/mdo.sh -O /tmp/mdo.sh && chmod +x /tmp/mdo.sh && bash /tmp/mdo.sh ;;
    11) m-bkp ;;
    12) echo -e "${RED}Restarting server...${NC}" ; sleep 2 ; reboot ;;
    *) echo -e "${RED}Invalid option!${NC}" ; sleep 2 ;;
esac
EOF

# Berikan permission
chmod +x /usr/local/sbin/menu

# Jalankan menu
menu
