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
Exp2=$(curl -sS https://raw.githubusercontent.com/script-VIP/vip/main/ip | grep $MYIP | awk '{print $3}')
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
        
        if [ $days_left -lt 0 ]; then
            days_display="${RED}EXPIRED${NC}"
        elif [ $days_left -eq 0 ]; then
            days_display="${RED}LAST DAY${NC}"
        elif [ $days_left -le 7 ]; then
            days_display="${YELLOW}$days_left Days${NC}"
        else
            days_display="${GREEN}$days_left Days${NC}"
        fi
    else
        days_display="${RED}INVALID DATE${NC}"
    fi
else
    days_display="${RED}INVALID FORMAT${NC}"
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
    echo -e "${BG_RED} ${WHITE}                👑 $author                ${NC}"
    echo -e "${ORANGE} ═════════════════════════════════════════════════${NC}"
}

print_system_info() {
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    local ram=$(free -m | awk 'NR==2 {print $2}')
    local isp=$(cat /etc/xray/isp 2>/dev/null || echo "DigitalOcean, LLC")
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "sg3.myyy.my.id")
    local username=$(cat /usr/bin/user 2>/dev/null || echo "Sg3")
    
    echo -e "${CYAN}╭─ SYSTEM INFORMATION ───────────────────────────╮${NC}"
    echo -e "${CYAN}│ ${YELLOW}📛 User    ${NC}: ${WHITE}$username${NC}"
    echo -e "${CYAN}│ ${YELLOW}🖥️ OS      ${NC}: ${WHITE}$os_info${NC}"
    echo -e "${CYAN}│ ${YELLOW}💾 RAM     ${NC}: ${WHITE}${ram} MB${NC}"
    echo -e "${CYAN}│ ${YELLOW}🌐 IP VPS  ${NC}: ${WHITE}$MYIP${NC}"
    echo -e "${CYAN}│ ${YELLOW}🏢 ISP     ${NC}: ${WHITE}$isp${NC}"
    echo -e "${CYAN}│ ${YELLOW}🔗 Domain  ${NC}: ${WHITE}$domain${NC}"
    echo -e "${CYAN}│ ${YELLOW}⏰ Active  ${NC}: $days_display, $Exp2  ${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
}

print_service_status() {
    echo -e "${PURPLE}╭─ SERVICE STATUS ───────────────────────────────╮${NC}"
    echo -e "${PURPLE}│ ${CYAN}🔄 HAPROXY ${NC}: $(get_service_status haproxy)  ${PURPLE}│ ${CYAN}🌐 NGINX ${NC}: $(get_service_status nginx)  ${PURPLE}│ ${CYAN}⚡ SSHWS ${NC}: $(get_service_status ws) ${PURPLE}${NC}"
    echo -e "${PURPLE}│ ${CYAN}🚀 XRAY    ${NC}: $(get_service_status xray)  ${PURPLE}│ ${CYAN}🔐 SSH   ${NC}: $(get_service_status ssh)  ${PURPLE}│ ${CYAN}🐻 DROPB ${NC}: $(get_service_status dropbear) ${PURPLE}${NC}"
    echo -e "${PURPLE}╰────────────────────────────────────────────────╯"  
}
print_bandwidth() {
    echo -e "${GREEN}╭─ BANDWIDTH USAGE ──────────────────────────────╮${NC}"
    echo -e "${GREEN}│ ${YELLOW}📊 TODAY ${NC}    : ${WHITE}$today_total $today_txv${NC}"
    echo -e "${GREEN}│ ${YELLOW}📈 MONTHLY ${NC}  : ${WHITE}$month_total $month_txv${NC}"
    echo -e "${GREEN}╰────────────────────────────────────────────────╯${NC}"
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
    echo -e "${YELLOW}│ ${WHITE}[1] SSH OVPN     ${NC}: ${GREEN}$ssh_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[2] VMESS        ${NC}: ${GREEN}$vmess_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[3] VLESS        ${NC}: ${GREEN}$vless_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[4] TROJAN       ${NC}: ${GREEN}$trojan_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[5] SHADOWSOCK   ${NC}: ${GREEN}$shadowsocks_count User${NC}"
    echo -e "${YELLOW}│ ${WHITE}[6] NOOBZVPN     ${NC}: ${GREEN}$noob_count User${NC}"
    echo -e "${YELLOW}╰────────────────────────────────────────────────╯${NC}"
}

print_menu() {
    echo -e "${RED}╭─ MAIN MENU ────────────────────────────────────╮${NC}"
    echo -e "${RED}│ ${WHITE}[7] Menu System         ${RED}│  ${WHITE}[10] Menu Backup    ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[8] Bot Telegram        ${RED}│  ${WHITE}[11] Info VPS       ${RED}│${NC}"
    echo -e "${RED}│ ${WHITE}[9] Restart Server      ${RED}│  ${WHITE}[12] Menu Admin     ${RED}│${NC}"
    echo -e "${RED}╰────────────────────────────────────────────────╯${NC}"
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

read -p "👉 Select menu option :  " hallo


case $hallo in
1) m-ssh ;; # menu ssh
2) m-xray ;; # menu vmess 
3) m-xray2 ;; # menu vless 
4) m-tro ;; # menu trojan 
5) m-ssr ;; # menu shadowsock
6) m-noobz ;; # menu noobzvpn
7) m-ftr2 ;; # menu system 
8) m-bot ;; # menu bot telegram
9) clear ; reboot ;; # Restart
10) m-bkp ;; # menu backup
11) clear ; wget -qO- bench.sh | bash ;; # info vps
12) m-adm ;; # menu Admin
*) exit;;
esac
