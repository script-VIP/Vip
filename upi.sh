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

# Data contoh - PASTI RAPI
data_contoh=(
    "08:15:23:user1:2:1"
    "09:30:45:user2:2:-"
    "10:45:12:user3:4:2"
    "11:20:33:user4:1:-"
    "12:35:47:user5:1:1"
    "13:22:18:user6:2:-"
    "14:45:29:user7:3:1"
    "15:18:52:user8:1:-"
)

total_login=0
online_sekarang=0

for data in "${data_contoh[@]}"; do
    time=$(echo $data | cut -d: -f1)
    user=$(echo $data | cut -d: -f2)
    limit=$(echo $data | cut -d: -f3)
    login=$(echo $data | cut -d: -f4)
    
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
