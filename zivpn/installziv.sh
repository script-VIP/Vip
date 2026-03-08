!/bin/bash
# =============================================
#   INSTALL ZIVPN UDP MANAGER
#   By: Custom Script
#   OS: Ubuntu 20.04 / 22.04 / 24.04
# =============================================

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# === PATH ===
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
CONFIG_FILE="$ZIVPN_DIR/config.json"
USERS_DB="$ZIVPN_DIR/users.db"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
MENU_SCRIPT="/usr/local/bin/menuziv"

# === FUNGSI UTILITAS ===
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root!"
        echo -e "Gunakan: ${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}'
}

banner() {
    clear
    echo -e "${CYAN}"
    echo -e "  ███████╗██╗██╗   ██╗██████╗ ███╗   ██╗"
    echo -e "  ╚══███╔╝██║██║   ██║██╔══██╗████╗  ██║"
    echo -e "    ███╔╝ ██║██║   ██║██████╔╝██╔██╗ ██║"
    echo -e "   ███╔╝  ██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║"
    echo -e "  ███████╗██║ ╚████╔╝ ██║     ██║ ╚████║"
    echo -e "  ╚══════╝╚═╝  ╚═══╝  ╚═╝     ╚═╝  ╚═══╝"
    echo -e "${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         INSTALLER ZIVPN UDP MANAGER${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    echo ""
}

update_config_json() {
    local today=$(date +%Y-%m-%d)
    local passwords=()

    if [[ -f "$USERS_DB" ]]; then
        while IFS='|' read -r uname pass expiry; do
            if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
                passwords+=("\"$pass\"")
            fi
        done < "$USERS_DB"
    fi

    if [[ ${#passwords[@]} -eq 0 ]]; then
        local pass_list="\"zivpn\""
    else
        local pass_list=$(IFS=','; echo "${passwords[*]}")
    fi

    cat > "$CONFIG_FILE" <<EOF
{
  "listen": ":5667",
  "cert": "$CERT_FILE",
  "key": "$KEY_FILE",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [$pass_list]
  }
}
EOF
}

install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ MEMULAI INSTALASI ZIVPN UDP ]${NC}"
    echo ""

    echo -e "${BLUE}[1/7]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[2/7]${NC} Download binary ZIVPN UDP..."
    mkdir -p "$ZIVPN_DIR"

    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    else
        echo -e "${RED}[ERROR] Arsitektur tidak didukung: $ARCH${NC}"
        exit 1
    fi

    wget -q "$BINARY_URL" -O "$ZIVPN_BIN"
    if [[ ! -f "$ZIVPN_BIN" ]]; then
        echo -e "${RED}[ERROR] Gagal download binary!${NC}"
        exit 1
    fi
    chmod +x "$ZIVPN_BIN"
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[3/7]${NC} Generate sertifikat SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[4/7]${NC} Membuat config dan database user..."
    touch "$USERS_DB"
    update_config_json
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[5/7]${NC} Membuat systemd service..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN server -c $CONFIG_FILE
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    systemctl start zivpn.service
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[6/7]${NC} Setup firewall & iptables..."
    sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
    sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1

    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null

    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[7/7]${NC} Setup cron & menu script..."
    # Setup cron untuk auto-hapus expired user
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

    # Buat script cron
    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
CONFIG_FILE="/etc/zivpn/config.json"
CERT_FILE="/etc/zivpn/zivpn.crt"
KEY_FILE="/etc/zivpn/zivpn.key"
CHANGED=0

if [[ ! -f "$USERS_DB" ]]; then exit 0; fi

TMPFILE=$(mktemp)
while IFS='|' read -r uname pass expiry; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        CHANGED=1
    else
        echo "$uname|$pass|$expiry" >> "$TMPFILE"
    fi
done < "$USERS_DB"

if [[ $CHANGED -eq 1 ]]; then
    mv "$TMPFILE" "$USERS_DB"
    # Rebuild config.json
    passwords=()
    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$TODAY" ]] || [[ "$expiry" == "$TODAY" ]]; then
            passwords+=("\"$pass\"")
        fi
    done < "$USERS_DB"
    
    if [[ ${#passwords[@]} -eq 0 ]]; then
        pass_list="\"zivpn\""
    else
        pass_list=$(IFS=','; echo "${passwords[*]}")
    fi
    
    cat > "$CONFIG_FILE" <<EOF
{
  "listen": ":5667",
  "cert": "$CERT_FILE",
  "key": "$KEY_FILE",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [$pass_list]
  }
}
EOF
    systemctl restart zivpn.service
else
    rm -f "$TMPFILE"
fi
CRONEOF
    chmod +x /usr/local/bin/zivpn-cron.sh

    # Download menu script
    echo -e "${BLUE}     Download menu script...${NC}"
    curl -s -o "$MENU_SCRIPT" "https://raw.githubusercontent.com/ZaeniMiptah/Zivpn/main/menuziv.sh" 2>/dev/null || \
    wget -q -O "$MENU_SCRIPT" "https://raw.githubusercontent.com/ZaeniMiptah/Zivpn/main/menuziv.sh" 2>/dev/null
    
    if [[ -f "$MENU_SCRIPT" ]]; then
        chmod +x "$MENU_SCRIPT"
        echo -e "${GREEN}    ✓ Menu script terdownload${NC}"
    else
        # Buat menu script sederhana jika download gagal
        cat > "$MENU_SCRIPT" <<'MENUEOF'
#!/bin/bash
# Simple fallback menu
bash /root/instal.sh
MENUEOF
        chmod +x "$MENU_SCRIPT"
    fi

    # Buat alias
    if ! grep -q "alias menuziv" /root/.bashrc 2>/dev/null; then
        echo "alias menuziv='bash /usr/local/bin/menuziv'" >> /root/.bashrc
    fi
    
    if ! grep -q "alias zivpn" /root/.bashrc 2>/dev/null; then
        echo "alias zivpn='bash /usr/local/bin/menuziv'" >> /root/.bashrc
    fi

    echo -e "${GREEN}    ✓ Selesai${NC}"
    echo ""

    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  IP VPS  : ${CYAN}$(get_ip)${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "  Status  : ${GREEN}$(systemctl is-active zivpn.service)${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}  Cara connect di ZIVPN App:${NC}"
    echo -e "  1. Buka ZIVPN → centang ${BOLD}UDP Tunnel${NC}"
    echo -e "  2. UDP Server  : ${CYAN}$(get_ip)${NC}"
    echo -e "  3. UDP Password: ${CYAN}[buat via menu]${NC}"
    echo -e "  4. Tap APPLY → START"
    echo ""
    echo -e "${GREEN}  Untuk manajemen user, ketik: ${BOLD}menuziv${NC} ${GREEN}atau ${BOLD}zivpn${NC}"
    echo -e "${GREEN}  Silakan jalankan: ${BOLD}source /root/.bashrc${NC} ${GREEN}lalu ketik menuziv${NC}"
    echo ""
}

# === MAIN ===
check_root

# Cek apakah sudah terinstall
if [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]; then
    echo ""
    echo -e "${YELLOW}[!] ZIVPN UDP sudah terinstall!${NC}"
    echo -e "${GREEN}  Untuk manajemen user, ketik: menuziv${NC}"
    echo -e "${GREEN}  Atau jalankan: bash /usr/local/bin/menuziv${NC}"
    echo ""
    exit 0
fi

# Jalankan instalasi
install_zivpn

# Tawarkan untuk langsung masuk menu
echo ""
read -rp "$(echo -e "${YELLOW}Langsung buka menu manajemen? [y/N] : ${NC}")" start_menu
if [[ "$start_menu" =~ ^[Yy]$ ]]; then
    exec bash "$MENU_SCRIPT"
fi
