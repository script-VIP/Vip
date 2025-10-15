#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║          SCAN IP TO DOMAIN           ║"
echo "║      & CLOUDFLARE DETECTION          ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

read -p "Masukkan IP Address: " ip_address

if [[ -z "$ip_address" ]]; then
    echo -e "${RED}Error: IP Address tidak boleh kosong!${NC}"
    exit 1
fi

# Validasi format IP
if ! [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Format IP Address tidak valid!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[+] Scanning IP: $ip_address${NC}"
echo -e "${BLUE}──────────────────────────────────────${NC}"

# Reverse DNS lookup untuk mendapatkan domain
echo -e "\n${GREEN}[DOMAIN TERKAIT]${NC}"
domains=$(dig +short -x "$ip_address" 2>/dev/null)

if [[ -z "$domains" ]]; then
    echo -e "${RED}Tidak ada domain yang terkait dengan IP $ip_address${NC}"
else
    echo "$domains" | while read domain; do
        if [[ -n "$domain" ]]; then
            echo -e "${CYAN}• $domain${NC}"
            
            # Check Cloudflare
            cf_check=$(dig +short "$domain" | grep -E "104\.16|104\.17|104\.18|104\.19|104\.20|104\.21|104\.22|104\.23|104\.24|104\.25|104\.26|104\.27|104\.28|104\.29|104\.30|104\.31" | head -1)
            if [[ -n "$cf_check" ]]; then
                echo -e "  ${GREEN}↳ CLOUDFLARE: ON${NC}"
            else
                echo -e "  ${RED}↳ CLOUDFLARE: OFF${NC}"
            fi
            
            # Check IP domain
            domain_ip=$(dig +short "$domain" | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | head -1)
            if [[ -n "$domain_ip" ]]; then
                echo -e "  ${YELLOW}↳ IP: $domain_ip${NC}"
            fi
            echo ""
        fi
    done
fi

# Additional scanning dengan whois
echo -e "\n${GREEN}[WHOIS INFORMATION]${NC}"
echo -e "${BLUE}──────────────────────────────────────${NC}"
whois_result=$(whois "$ip_address" 2>/dev/null | grep -E "netname|descr|country|org-name" | head -10)
if [[ -n "$whois_result" ]]; then
    echo "$whois_result"
else
    echo -e "${YELLOW}Informasi whois tidak tersedia${NC}"
fi

# Check jika IP adalah Cloudflare IP
echo -e "\n${GREEN}[CLOUDFLARE CHECK]${NC}"
echo -e "${BLUE}──────────────────────────────────────${NC}"
is_cf_ip=$(whois "$ip_address" 2>/dev/null | grep -i "cloudflare")
if [[ -n "$is_cf_ip" ]]; then
    echo -e "${GREEN}✓ IP ini adalah Cloudflare IP${NC}"
else
    echo -e "${RED}✗ IP ini bukan Cloudflare IP${NC}"
fi

echo -e "\n${GREEN}Scan selesai!${NC}"
