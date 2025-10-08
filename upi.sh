#!/bin/bash

g="\033[92;1m"
RED="\033[31m"
NC="\033[0m"
y="\033[1;93m"
ungu="\033[0;35m"
cyan="\033[0;36m"
clear

echo -e "  ${y}────────────────────────────────────────────────────${NC}"
echo -e "               ️ ${g}RIWAYAT LOGIN 24 JAM${NC}  ️"
echo -e "  ${y}────────────────────────────────────────────────────${NC}"
echo -e "    ${ungu}   TIME      USERNAME      LIMIT IP    LOGIN IP ${NC}"
echo -e "  ${y}────────────────────────────────────────────────────${NC}"

total_login=0

# Ambil riwayat login 24 jam dari auth.log
if [[ -f "/var/log/auth.log" ]]; then
    grep "Accepted" /var/log/auth.log | \
    grep "$(date -d '24 hours ago' '+%b %e')" | \
    while read line; do
        
        waktu=$(echo "$line" | awk '{print $3}')
        user=$(echo "$line" | awk '{print $9}')
        ip=$(echo "$line" | awk '{print $11}')
        
        if [[ -n "$user" && -n "$ip" ]]; then
            limit=$(cat /etc/kyt/limit/ssh/ip/$user 2>/dev/null || echo "2")
            
            if cek-ssh 2>/dev/null | grep -q "$user"; then
                status="${g}1 IP${NC}"
            else
                status="${RED}-${NC}"
            fi
            
            echo -e "    $(printf '%-9s %-12s %-10s %-15s' "$waktu" "$user" "$limit" "$status")"
            ((total_login++))
        fi
    done
fi

online_sekarang=$(cek-ssh 2>/dev/null | grep -c -v "USER" 2>/dev/null || echo "0")

echo -e "  ${y}────────────────────────────────────────────────────${NC}"
echo -e "    ${cyan}TOTAL LOGIN 24J: $total_login ${NC} | ${g}ONLINE SEKARANG: $online_sekarang${NC}"
echo -e "  ${y}────────────────────────────────────────────────────${NC}"    
    if [[ "$login" == "-" ]]; then
        status="${RED}-${NC}"
    else
        status="${g}$login IP${NC}"
        ((online_sekarang++))
    fi
    
    ((total_login++))
    echo -e "    $(printf '%-9s %-12s %-10s %-15s' "$time" "$user" "$limit" "$status")"
done

echo -e "  ${y}────────────────────────────────────────────────────${NC}"
echo -e "    ${cyan}TOTAL LOGIN: $total_login ${NC} | ${g}ONLINE SEKARANG: $online_sekarang${NC}"
echo -e "  ${y}────────────────────────────────────────────────────${NC}"
