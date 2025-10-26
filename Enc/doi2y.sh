#!/bin/bash

# Color definitions
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
yell='\e[33m'
red='\e[31m'
green='\e[32m'
blue='\e[34m'
PURPLE='\e[35m'
cyan='\e[36m'
Lred='\e[91m'
Lgreen='\e[92m'
yellow='\e[93m'
NC='\e[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
LIGHT='\033[0;37m'
grenbo="\e[92;1m"
BlueCyan='\e[36;1m'
Xark='\e[0m'
ungu='\e[35;1m'

# Function definitions
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

# Loading animation
duration=6
frames=("██10%" "█████35%" "█████████65%" "█████████████80%" "█████████████████████90%" "█████████████████████████100%")
num_frames=${#frames[@]}
num_iterations=$((duration))

Loading_Animasi() {
    for ((i = 0; i < num_iterations; i++)); do
        clear
        index=$((i % num_frames))
        color_code=$((31 + i % 7))
        echo ""
        echo ""
        echo ""
        echo -e "\e[1;${color_code}m ${frames[$index]}\e[0m"
        sleep 0.5
    done
}

Loading_Succes() {
    clear
    echo -e "\033[5;32mSucces\033[0m"
    sleep 1
    clear
}

# Main script
REPO="https://raw.githubusercontent.com/AngIMAN/sc/main/Cfg/"

clear
echo -e "${BlueCyan} ------------------------- ${Xark}"
echo -e "${ungu}             FIXHAP            ${Xark}"
echo -e "${BlueCyan} ------------------------- ${Xark}"
echo -e ""
read -p " Input Your Domain : " -e domain

Loading_Animasi
Loading_Succes

# Backup original files first
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup 2>/dev/null
cp /etc/nginx/conf.d/xray.conf /etc/nginx/conf.d/xray.conf.backup 2>/dev/null

rm -fr /etc/xray/domain
echo "${domain}" > /etc/xray/domain

systemctl stop haproxy
systemctl stop nginx

# Download configuration files
wget -O /etc/haproxy/haproxy.cfg "${REPO}haproxy.cfg" >/dev/null 2>&1
wget -O /etc/nginx/conf.d/xray.conf "${REPO}xray.conf" >/dev/null 2>&1

# Replace domain in config files
sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg
sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf

# Download nginx config
curl -s "${REPO}nginx.conf" > /etc/nginx/nginx.conf

# Create certificate file (fix this part)
if [ -f /etc/xray/xray.crt ] && [ -f /etc/xray/xray.key ]; then
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    chmod 600 /etc/haproxy/hap.pem
else
    echo "Certificate files not found!"
    exit 1
fi

# Test configurations before restarting
echo "Testing nginx configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "Nginx configuration test failed!"
    exit 1
fi

echo "Testing haproxy configuration..."
haproxy -c -f /etc/haproxy/haproxy.cfg
if [ $? -ne 0 ]; then
    echo "HAProxy configuration test failed!"
    exit 1
fi

# Restart services
systemctl restart nginx
systemctl restart haproxy

# Check status
echo "Checking service status..."
systemctl status nginx --no-pager -l
systemctl status haproxy --no-pager -l
