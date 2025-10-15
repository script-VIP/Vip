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
echo "║           SCAN HOST TO IP            ║"
echo "║        MULTI METHOD SCANNING         ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

read -p "Masukkan Host/Domain: " host_name

if [[ -z "$host_name" ]]; then
    echo -e "${RED}Error: Host/Domain tidak boleh kosong!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[+] Scanning Host: $host_name${NC}"
echo -e "${BLUE}──────────────────────────────────────${NC}"

# Method 1: Dig command
echo -e "\n${GREEN}[METHOD 1 - DIG]${NC}"
dig_result=$(dig +short "$host_name" | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$")
if [[ -n "$dig_result" ]]; then
    echo "$dig_result" | while read ip; do
        echo -e "${CYAN}• $ip${NC}"
    done
else
    echo -e "${RED}Tidak ditemukan IP via DIG${NC}"
fi

# Method 2: nslookup
echo -e "\n${GREEN}[METHOD 2 - NSLOOKUP]${NC}"
nslookup_result=$(nslookup "$host_name" 2>/dev/null | grep "Address:" | grep -v "#" | awk '{print $2}')
if [[ -n "$nslookup_result" ]]; then
    echo "$nslookup_result" | while read ip; do
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "${CYAN}• $ip${NC}"
        fi
    done
else
    echo -e "${RED}Tidak ditemukan IP via NSLOOKUP${NC}"
fi

# Method 3: host command
echo -e "\n${GREEN}[METHOD 3 - HOST]${NC}"
host_result=$(host "$host_name" 2>/dev/null | grep "has address" | awk '{print $4}')
if [[ -n "$host_result" ]]; then
    echo "$host_result" | while read ip; do
        echo -e "${CYAN}• $ip${NC}"
    done
else
    echo -e "${RED}Tidak ditemukan IP via HOST${NC}"
fi

# Method 4: ping (hanya untuk test koneksi)
echo -e "\n${GREEN}[METHOD 4 - PING TEST]${NC}"
ping_result=$(ping -c 2 -W 1 "$host_name" 2>/dev/null | grep "from" | head -1)
if [[ -n "$ping_result" ]]; then
    echo -e "${GREEN}✓ Host dapat dijangkau${NC}"
    # Extract IP from ping result
    ping_ip=$(echo "$ping_result" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
    if [[ -n "$ping_ip" ]]; then
        echo -e "${CYAN}• IP from PING: $ping_ip${NC}"
    fi
else
    echo -e "${RED}✗ Host tidak dapat dijangkau${NC}"
fi

# Cloudflare Detection
echo -e "\n${GREEN}[CLOUDFLARE DETECTION]${NC}"
cf_ip=$(dig +short "$host_name" | grep -E "104\.16|104\.17|104\.18|104\.19|104\.20|104\.21|104\.22|104\.23|104\.24|104\.25|104\.26|104\.27|104\.28|104\.29|104\.30|104\.31" | head -1)
if [[ -n "$cf_ip" ]]; then
    echo -e "${GREEN}✓ Host menggunakan Cloudflare${NC}"
    echo -e "${YELLOW}↳ Cloudflare IP: $cf_ip${NC}"
    
    # Try to get real IP (behind Cloudflare)
    echo -e "\n${GREEN}[TRYING TO FIND REAL IP]${NC}"
    echo -e "${YELLOW}Mencari IP asli di balik Cloudflare...${NC}"
    
    # Check common subdomains that might reveal real IP
    subdomains=("direct" "cpanel" "ftp" "mail" "webmail" "admin" "server" "ns1" "ns2")
    for sub in "${subdomains[@]}"; do
        subdomain_ip=$(dig +short "$sub.$host_name" | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | head -1)
        if [[ -n "$subdomain_ip" && ! $subdomain_ip =~ ^104\. ]]; then
            echo -e "${GREEN}✓ Found via $sub.$host_name: $subdomain_ip${NC}"
        fi
    done
else
    echo -e "${RED}✗ Host tidak menggunakan Cloudflare${NC}"
fi

# Summary
echo -e "\n${GREEN}[SUMMARY]${NC}"
echo -e "${BLUE}──────────────────────────────────────${NC}"
all_ips=$(echo -e "$dig_result\n$nslookup_result\n$host_result\n$ping_ip" | sort -u | grep -v '^$')
if [[ -n "$all_ips" ]]; then
    echo -e "${CYAN}IP Address yang ditemukan:${NC}"
    echo "$all_ips" | while read ip; do
        echo -e "${YELLOW}• $ip${NC}"
    done
else
    echo -e "${RED}Tidak ada IP yang ditemukan${NC}"
fi

echo -e "\n${GREEN}Scan selesai!${NC}"
