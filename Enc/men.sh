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
MYIP=$(curl -sS ipv4.icanhazip.com)
author=$(cat /etc/xray/username 2>/dev/null || echo "AIMAN-VPN")
# =============================================
# BANDWIDTH CALCULATION - ORIGINAL CODE
# =============================================
vnstat_profile=$(vnstat | sed -n '3p' | awk '{print $1}' | grep -o '[^:]*')
vnstat -i ${vnstat_profile} >/etc/t1
bulan=$(date +%b)
tahun=$(date +%y)
ba=$(curl -s https://pastebin.com/raw/0gWiX6hE)
todayd=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $8}')
today_v=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $9}')
today_rx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $2}')
today_rxv=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $3}')
today_tx=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $5}')
today_txv=$(vnstat -i ${vnstat_profile} | grep today | awk '{print $6}')
if [ "$(grep -wc ${bulan} /etc/t1)" != '0' ]; then
bulan=$(date +%b)
month=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $9}')
month_v=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $10}')
month_rx=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $3}')
month_rxv=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $4}')
month_tx=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $6}')
month_txv=$(vnstat -i ${vnstat_profile} | grep "$bulan $ba$tahun" | awk '{print $7}')
else
bulan2=$(date +%Y-%m)
month=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $8}')
month_v=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $9}')
month_rx=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $2}')
month_rxv=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $3}')
month_tx=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $5}')
month_txv=$(vnstat -i ${vnstat_profile} | grep "$bulan2 " | awk '{print $6}')
fi
if [ "$(grep -wc yesterday /etc/t1)" != '0' ]; then
yesterday=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $8}')
yesterday_v=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $9}')
yesterday_rx=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $2}')
yesterday_rxv=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $3}')
yesterday_tx=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $5}')
yesterday_txv=$(vnstat -i ${vnstat_profile} | grep yesterday | awk '{print $6}')
else
yesterday=NULL
yesterday_v=NULL
yesterday_rx=NULL
yesterday_rxv=NULL
yesterday_tx=NULL
yesterday_txv=NULL
fi

today_total=$(awk "BEGIN {print $today_tx + $today_rx}")
today_unit="MB"
if [ $(echo "$today_total > 1024*1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024 / 1024}")
  today_unit="GB"
fi
if [ $(echo "$today_total > 1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024}")
  today_unit="TB"
fi

if [ $(echo "$today_total > 1024*1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024 / 1024}")
  today_unit="GB"
fi
if [ $(echo "$today_total > 1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024}")
  today_unit="TB"
fi

if [ $(echo "$today_total > 1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024}")
  today_unit="GB"
fi

if [ $(echo "$today_total > 1024" | bc) -eq 1 ]; then
  today_total=$(awk "BEGIN {print $today_total / 1024}")
  today_unit="TB"
fi

month_total=$(awk "BEGIN {print $month_tx + $month_rx}")
month_unit="MB"
if [ $(echo "$month_total > 1024*1024*1024" | bc) -eq 1 ]; then
  month_total=$(awk "BEGIN {print $month_total / 1024 / 1024 / 1024}")
  month_unit="TB"
elif [ $(echo "$month_total > 1024*1024" | bc) -eq 1 ]; then
  month_total=$(awk "BEGIN {print $month_total / 1024 / 1024}")
  month_unit="GB"
fi
clear
######################################
# // DETAIL ORDER IZIN IP
#username=$(cat /usr/bin/user)
oid=$(cat /usr/bin/ver)
#exp=$(cat /usr/bin/e)
######################################
clear
# =============================================
# LICENSE & EXPIRY DATE
# =============================================
# Cek file yang berisi tanggal expired
if [ -f "/usr/bin/e" ]; then
    exp_date=$(cat /usr/bin/e)
    # Format tanggal: YYYY-MM-DD atau DD-MM-YYYY
    if [[ $exp_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        valid="$exp_date"
    elif [[ $exp_date =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
        valid=$(date -d "$exp_date" +%Y-%m-%d 2>/dev/null || echo "$exp_date")
    else
        valid="$exp_date"
    fi
else
    valid="2024-12-31"  # Default fallback
fi

# Tanggal hari ini
today=$(date +%Y-%m-%d)

# // DAYS LEFT CALCULATION
if [[ $valid =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    d1=$(date -d "$valid" +%s 2>/dev/null)
    d2=$(date -d "$today" +%s)
    
    if [ -n "$d1" ] && [ -n "$d2" ]; then
        days_left=$(((d1 - d2) / 86400))
        
        # Pisahkan teks dan warna untuk printf formatting
        if [ $days_left -lt 0 ] || [ $days_left -eq 0 ]; then
            days_text="EXPIRED ($valid)"
            days_color="${RED}"
        elif [ $days_left -le 7 ]; then
            days_text="$days_left Days ($valid)"
            days_color="${YELLOW}"
        else
            days_text="$days_left Days ($valid)"
            days_color="${GREEN}"
        fi
    else
        days_text="INVALID DATE"
        days_color="${RED}"
    fi
else
    days_text="INVALID FORMAT"
    days_color="${RED}"
fi
# =============================================
# SERVICE STATUS
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
# ACCOUNT COUNT
# =============================================
count_accounts() {
    # SSH Accounts
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)
    
    # Xray Accounts
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
    echo -e "${ORANGE} ═════════════════════════════════════════════════${NC}"
    echo -e " ${BG_RED}${WHITE}                   👑 $author                   ${NC}"
    echo -e "${ORANGE} ═════════════════════════════════════════════════${NC}"
echo -e ""
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "DigitalOcean, LLC")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "sg3.myyy.my.id")
    local username=$(cat /usr/bin/user 2>/dev/null || echo "Sg3")
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ───────────────────────────╮${NC}"
    printf "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$username"
    printf "${CYAN}│ ${YELLOW}🖥️ OS      ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$os_info"
    printf "${CYAN}│ ${YELLOW}💾 RAM     ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "${ram} MB"
    printf "${CYAN}│ ${YELLOW}🌐 IP VPS  ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$MYIP"
    printf "${CYAN}│ ${YELLOW}🏢 ISP     ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$isp"
    printf "${CYAN}│ ${YELLOW}🔗 Domain  ${NC}: ${WHITE}%-34s ${CYAN}│${NC}\n" "$domain"
    echo -e "${CYAN}│ ${YELLOW}⏰ Expiry  ${NC}: $days_color $days_text"
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
    printf "${GREEN}│ ${YELLOW}📊 TODAY ${NC}: ${WHITE}%-7s ${YELLOW}   MONTHLY ${NC}: ${WHITE}%-7s ${GREEN} ${NC}\n" "$today_total $today_txv" "$month_total $month_txv"
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
1) m-ssh ;; # menu ssh
2) m-xray ;; # menu vmess 
3) m-xray2 ;; # menu vless 
4) m-tro ;; # menu trojan 
5) m-ssr ;; # menu shadowsock
6) m-noobz ;; # menu noobzvpn
7) m-ftr2 ;; # menu system 
8) m-bot ;; # menu bot telegram
9) botwa ;; # bot wa
10) wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/mdo.sh && chmod +x mdo.sh && ./mdo.sh ;; # menu dor
11) m-bkp ;; # wildc
12) clear ; reset ;; # menu
*) exit ;;
esac
