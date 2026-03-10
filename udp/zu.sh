#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - PREMIUM EDITION
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
USERS_JSON="$ZIVPN_DIR/users.json"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
LIMIT_FILE="$ZIVPN_DIR/limits.db"
LOGIN_LOG="$ZIVPN_DIR/login.log"

# === Theme Configuration ===
THEME_CONFIG="$ZIVPN_DIR/theme.conf"
THEME_CMD="cat"

# === FUNGSI UTILITAS ===

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root!"
        echo -e "Gunakan: ${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{for(i=1;i<=NF;i++) if($i !~ /:/) {print $i; exit}}'
}

get_domain() {
    if [[ -f "$DOMAIN_FILE" ]]; then
        cat "$DOMAIN_FILE"
    else
        get_ip
    fi
}

is_installed() {
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]
}

# === Load Theme ===
load_theme() {
    if [ -f "$THEME_CONFIG" ] && [ -s "$THEME_CONFIG" ]; then
        THEME=$(cat "$THEME_CONFIG")
        case $THEME in
            rainbow)
                if command -v lolcat &> /dev/null; then
                    THEME_CMD="lolcat"
                else
                    THEME_CMD="cat"
                fi
                ;;
            red) THEME_CMD="cat";;
            green) THEME_CMD="cat";;
            yellow) THEME_CMD="cat";;
            blue) THEME_CMD="cat";;
            none) THEME_CMD="cat";;
            *) THEME_CMD="cat";;
        esac
    fi
}

# === Generate Random 3 Digit ===
random_3digit() {
    printf "%03d" $((RANDOM % 900 + 100))
}

# === Banner Function ===
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
    echo -e "${YELLOW}         UDP MANAGER - PREMIUM EDITION${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    if is_installed; then
        local domain=$(get_domain)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        if [[ "$status" == "active" ]]; then
            echo -e "  Status    : ${GREEN}● AKTIF${NC}"
        else
            echo -e "  Status    : ${RED}● MATI${NC}"
        fi
        echo -e "  Domain    : ${CYAN}$domain${NC}"
        echo -e "  Port      : ${CYAN}1-65535 (UDP)${NC}"
    fi
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    echo ""
}

# === FUNGSI USER DB ===
load_users() {
    if [[ ! -f "$USERS_DB" ]]; then
        touch "$USERS_DB"
    fi
    if [[ ! -f "$LIMIT_FILE" ]]; then
        touch "$LIMIT_FILE"
    fi
    if [[ ! -f "$LOGIN_LOG" ]]; then
        touch "$LOGIN_LOG"
    fi
    if [[ ! -f "$USERS_JSON" ]]; then
        echo "[]" > "$USERS_JSON"
    fi
}

# Format users.db: USERNAME|PASSWORD|EXPIRY_DATE|LIMIT_IP|CREATED_DATE
user_exists() {
    local username="$1"
    grep -q "^$username|" "$USERS_DB" 2>/dev/null
}

get_user_pass() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f2
}

get_user_expiry() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f3
}

get_user_limit() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f4
}

get_user_created() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f5
}

update_config_json() {
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r uname pass expiry limit created; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            passwords+=("\"$pass\"")
        fi
    done < "$USERS_DB"

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
    
    # Update JSON format for future use
    echo "[" > "$USERS_JSON.tmp"
    local first=true
    while IFS='|' read -r uname pass expiry limit created; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            continue
        fi
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$USERS_JSON.tmp"
        fi
        cat >> "$USERS_JSON.tmp" <<EOF
  {
    "username": "$uname",
    "password": "$pass",
    "expiry": "$expiry",
    "limit": $limit,
    "created": "$created"
  }
EOF
    done < "$USERS_DB"
    echo "" >> "$USERS_JSON.tmp"
    echo "]" >> "$USERS_JSON.tmp"
    mv "$USERS_JSON.tmp" "$USERS_JSON"

    systemctl restart zivpn.service 2>/dev/null
}

# === CEK USER ONLINE ===
check_online_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ CEK USER ONLINE ]${NC}"
    echo ""

    if [[ ! -f "$LOGIN_LOG" ]]; then
        echo -e "${YELLOW}Belum ada data login.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}USERNAME          | IP ADDRESS       | LOGIN TIME          | STATUS${NC}"
    echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"

    local now=$(date +%s)
    local active_users=()
    
    while read line; do
        local username=$(echo "$line" | cut -d'|' -f1)
        local ip=$(echo "$line" | cut -d'|' -f2)
        local time=$(echo "$line" | cut -d'|' -f3)
        local timestamp=$(echo "$line" | cut -d'|' -f4)
        
        # Cek apakah masih aktif (dalam 5 menit terakhir)
        local diff=$((now - timestamp))
        if [[ $diff -lt 300 ]]; then
            printf "%-18s | %-15s | %-19s | ${GREEN}Online${NC}\n" "$username" "$ip" "$time"
            active_users+=("$username")
        fi
    done < "$LOGIN_LOG"

    echo -e "${WHITE}─────────────────────────────────────────────────────────────────${NC}"
    echo -e "Total Online: ${GREEN}${#active_users[@]}${NC} user"
    echo ""
    press_enter
}

# === TAMBAH USER ===
add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users

    read -rp "$(echo -e "${WHITE}Username : ${NC}")" username
    if [[ -z "$username" ]]; then
        echo -e "${RED}[!] Username tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    if user_exists "$username"; then
        echo -e "${RED}[!] User '$username' sudah ada!${NC}"
        press_enter
        return
    fi

    # Generate password dengan 3 digit random di belakang
    read -rp "$(echo -e "${WHITE}Password (tanpa 3 digit random) : ${NC}")" basepass
    if [[ -z "$basepass" ]]; then
        basepass="user"
    fi
    local random=$(random_3digit)
    local password="${basepass}${random}"
    
    echo -e "${GREEN}Password akan menjadi: ${CYAN}$password${NC}"
    
    # Limit IP
    read -rp "$(echo -e "${WHITE}Limit IP (contoh: 2) : ${NC}")" limit_ip
    if [[ -z "$limit_ip" || ! "$limit_ip" =~ ^[0-9]+$ ]]; then
        limit_ip=2
        echo -e "${YELLOW}Menggunakan default limit: 2 IP${NC}"
    fi

    # Masa aktif (hari)
    read -rp "$(echo -e "${WHITE}Masa aktif (hari) : ${NC}")" days
    if [[ -z "$days" || ! "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    # Lokasi
    read -rp "$(echo -e "${WHITE}Lokasi (contoh: Singapore) : ${NC}")" lokasi
    if [[ -z "$lokasi" ]]; then
        lokasi="Singapore"
    fi

    local created=$(date +%d\ %b,\ %Y)
    local expiry=$(date -d "+$days days" +%Y-%m-%d)
    local expiry_display=$(date -d "+$days days" +%d\ %b,\ %Y)

    # Simpan ke database
    echo "$username|$password|$expiry|$limit_ip|$created" >> "$USERS_DB"
    update_config_json

    # Tampilkan hasil dengan format yang diminta
    local domain=$(get_domain)
    
    echo ""
    echo -e "${WHITE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}════════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}ZIVPN UDP${NC}"
    echo -e "${WHITE}════════════════════════════════════════════${NC}"
    echo -e "  Domain      : ${CYAN}$domain${NC}"
    echo -e "  Password    : ${CYAN}$password${NC}"
    echo -e "  Lokasi      : ${CYAN}$lokasi${NC}"
    echo -e "  Limit IP    : ${CYAN}$limit_ip Device${NC}"
    echo -e "  ────────────────"
    echo -e "  Tanggal Buat: ${YELLOW}$created${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$expiry_display${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$days hari${NC}"
    echo -e "────────────────"
    echo -e "  ${WHITE}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "────────────────"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Pilih negara bebas si (saran $lokasi premium 5)"
    echo -e "  4. Klik Garis tiga (dipojok kiri atas)"
    echo -e "  5. Klik Udp tunnel setting"
    echo -e "  6. UDP Server  : ${CYAN}$domain${NC}"
    echo -e "     UDP Password: ${CYAN}$password${NC}"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}════════════════════════════════════════════${NC}"
    echo ""
    
    press_enter
}

# === GANTI DOMAIN ===
change_domain() {
    banner
    echo -e "${BOLD}${YELLOW}[ GANTI DOMAIN ]${NC}"
    echo ""
    
    local current=$(get_domain)
    echo -e "Domain saat ini: ${CYAN}$current${NC}"
    echo ""
    
    read -rp "$(echo -e "${WHITE}Masukkan domain baru : ${NC}")" new_domain
    if [[ -z "$new_domain" ]]; then
        echo -e "${RED}[!] Domain tidak boleh kosong!${NC}"
        press_enter
        return
    fi
    
    echo "$new_domain" > "$DOMAIN_FILE"
    echo -e "${GREEN}✓ Domain berhasil diubah menjadi: ${CYAN}$new_domain${NC}"
    echo ""
    press_enter
}

# === LIST USER ===
list_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    local today=$(date +%Y-%m-%d)
    printf "${WHITE}%-15s | %-15s | %-12s | %-8s | %-12s | %-8s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "LIMIT" "CREATED" "STATUS"
    echo -e "${WHITE}──────────────────────────────────────────────────────────────────────${NC}"

    while IFS='|' read -r uname pass expiry limit created; do
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="${GREEN}Unlimited${NC}"
        elif [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="${YELLOW}$expiry${NC}"
        else
            status="${RED}Expired${NC}"
            exp_display="${RED}$expiry${NC}"
        fi
        
        # Hitung online count
        local online_count=0
        if [[ -f "$LOGIN_LOG" ]]; then
            local now=$(date +%s)
            while read line; do
                local log_user=$(echo "$line" | cut -d'|' -f1)
                local log_time=$(echo "$line" | cut -d'|' -f4)
                if [[ "$log_user" == "$uname" ]] && [[ $((now - log_time)) -lt 300 ]]; then
                    ((online_count++))
                fi
            done < "$LOGIN_LOG"
        fi
        
        local limit_display="$limit"
        if [[ $online_count -gt 0 ]]; then
            limit_display="${CYAN}$online_count/$limit${NC}"
        fi
        
        printf "%-15s | %-15s | %-12s | ${NC}%-8s${NC} | %-12s | " "$uname" "$pass" "$(echo -e $exp_display)" "$limit_display" "$created"
        echo -e "$status"
    done < "$USERS_DB"

    echo -e "${WHITE}──────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    press_enter
}

# === HAPUS USER ===
delete_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry limit created; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Nama user yang ingin dihapus : ${NC}")" username

    if ! user_exists "$username"; then
        echo -e "${RED}[!] User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${RED}Yakin hapus user '$username'? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$username|/d" "$USERS_DB"
        # Hapus juga dari login log
        sed -i "/^$username|/d" "$LOGIN_LOG" 2>/dev/null
        update_config_json
        echo -e "${GREEN}  ✓ User '$username' berhasil dihapus!${NC}"
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi

    press_enter
}

# === RENEW USER ===
renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry limit created; do
        echo -e "  ${CYAN}$i.${NC} $uname (Exp: $expiry)"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Nama user : ${NC}")" username

    if ! user_exists "$username"; then
        echo -e "${RED}[!] User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Tambah hari : ${NC}")" days
    if [[ -z "$days" || ! "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    local old_data=$(grep "^$username|" "$USERS_DB")
    local pass=$(echo "$old_data" | cut -d'|' -f2)
    local old_expiry=$(echo "$old_data" | cut -d'|' -f3)
    local limit=$(echo "$old_data" | cut -d'|' -f4)
    local created=$(echo "$old_data" | cut -d'|' -f5)
    
    local new_expiry=$(date -d "$old_expiry +$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
    
    sed -i "s/^$username|$pass|$old_expiry|$limit|$created/$username|$pass|$new_expiry|$limit|$created/" "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${GREEN}  ✓ User '$username' berhasil diperpanjang!${NC}"
    echo -e "  Expired baru : ${CYAN}$new_expiry${NC}"
    echo ""
    press_enter
}

# === RESET LOGIN LOG ===
reset_login_log() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESET LOGIN LOG ]${NC}"
    echo ""
    
    read -rp "$(echo -e "${RED}Yakin reset semua data login? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        > "$LOGIN_LOG"
        echo -e "${GREEN}  ✓ Data login berhasil direset!${NC}"
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi
    
    press_enter
}

# === STATUS SERVICE ===
status_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ STATUS SERVICE ]${NC}"
    echo ""
    systemctl status zivpn.service --no-pager
    echo ""
    press_enter
}

# === RESTART SERVICE ===
restart_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTART SERVICE ]${NC}"
    echo ""
    systemctl restart zivpn.service
    sleep 1
    local status=$(systemctl is-active zivpn.service)
    if [[ "$status" == "active" ]]; then
        echo -e "${GREEN}  ✓ Service berhasil di-restart!${NC}"
    else
        echo -e "${RED}  ✗ Service gagal restart. Cek log: journalctl -u zivpn.service${NC}"
    fi
    echo ""
    press_enter
}

# === INSTALLASI ===
install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN UDP SERVER ]${NC}"
    echo ""

    if is_installed; then
        echo -e "${YELLOW}[!] ZIVPN UDP sudah terinstall!${NC}"
        press_enter
        return
    fi

    # Minta domain
    read -rp "$(echo -e "${WHITE}Masukkan domain untuk server : ${NC}")" domain
    if [[ -z "$domain" ]]; then
        domain=$(get_ip)
        echo -e "${YELLOW}Menggunakan IP: $domain${NC}"
    fi
    echo "$domain" > "$DOMAIN_FILE"

    echo -e "${BLUE}[1/7]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron jq figlet > /dev/null 2>&1
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
        press_enter
        return
    fi

    wget -q "$BINARY_URL" -O "$ZIVPN_BIN"
    if [[ ! -f "$ZIVPN_BIN" ]]; then
        echo -e "${RED}[ERROR] Gagal download binary!${NC}"
        press_enter
        return
    fi
    chmod +x "$ZIVPN_BIN"
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[3/7]${NC} Generate sertifikat SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=$domain" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[4/7]${NC} Membuat config dan database user..."
    touch "$USERS_DB"
    touch "$LIMIT_FILE"
    touch "$LOGIN_LOG"
    echo "[]" > "$USERS_JSON"
    echo "rainbow" > "$THEME_CONFIG"
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

    # Setup cron untuk auto-hapus expired
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -
    (crontab -l 2>/dev/null; echo "*/5 * * * * bash /usr/local/bin/zivpn-cleanlog.sh") | crontab -

    # Cron script untuk hapus expired
    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
CHANGED=0

if [[ ! -f "$USERS_DB" ]]; then exit 0; fi

TMPFILE=$(mktemp)
while IFS='|' read -r uname pass expiry limit created; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        CHANGED=1
    else
        echo "$uname|$pass|$expiry|$limit|$created" >> "$TMPFILE"
    fi
done < "$USERS_DB"

if [[ $CHANGED -eq 1 ]]; then
    mv "$TMPFILE" "$USERS_DB"
    passwords=()
    while IFS='|' read -r uname pass expiry limit created; do
        passwords+=("\"$pass\"")
    done < "$USERS_DB"
    pass_list=$(IFS=','; echo "${passwords[*]:-\"zivpn\"}")
    cat > /etc/zivpn/config.json <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
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

    # Script untuk clean login log yang sudah lama
    cat > /usr/local/bin/zivpn-cleanlog.sh <<'LOGEOF'
#!/bin/bash
LOGIN_LOG="/etc/zivpn/login.log"
if [[ -f "$LOGIN_LOG" ]]; then
    NOW=$(date +%s)
    TMPFILE=$(mktemp)
    while IFS='|' read -r user ip time timestamp; do
        DIFF=$((NOW - timestamp))
        if [[ $DIFF -lt 600 ]]; then # Hapus yang lebih dari 10 menit
            echo "$user|$ip|$time|$timestamp" >> "$TMPFILE"
        fi
    done < "$LOGIN_LOG"
    mv "$TMPFILE" "$LOGIN_LOG"
fi
LOGEOF

    chmod +x /usr/local/bin/zivpn-cron.sh
    chmod +x /usr/local/bin/zivpn-cleanlog.sh

    # Pasang script ini sebagai command
    cp "$(realpath $0)" /usr/local/bin/zivpn 2>/dev/null
    chmod +x /usr/local/bin/zivpn 2>/dev/null
    
    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  Domain    : ${CYAN}$domain${NC}"
    echo -e "  Port      : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "  Status    : ${GREEN}$(systemctl is-active zivpn.service)${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}  Ketik ${BOLD}zivpn${NC}${GREEN} untuk membuka menu${NC}"
    echo ""
    press_enter
}

# === UNINSTALL ===
uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN UDP ]${NC}"
    echo ""
    read -rp "$(echo -e "${RED}Yakin ingin uninstall? Semua data akan hilang! [y/N] : ${NC}")" confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  Dibatalkan.${NC}"
        press_enter
        return
    fi

    echo -e "  Menghentikan service..."
    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1

    echo -e "  Menghapus file..."
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -f /usr/local/bin/zivpn-cron.sh
    rm -f /usr/local/bin/zivpn-cleanlog.sh
    rm -f /usr/local/bin/zivpn
    rm -rf "$ZIVPN_DIR"

    systemctl daemon-reload

    echo -e "  Hapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn-cron" | crontab -
    crontab -l 2>/dev/null | grep -v "zivpn-cleanlog" | crontab -

    echo ""
    echo -e "${GREEN}  ✓ ZIVPN UDP berhasil diuninstall!${NC}"
    echo ""
    sleep 2
    exit 0
}

# === MENU UTAMA ===
main_menu() {
    while true; do
        load_theme
        banner

        if ! is_installed; then
            echo -e "${RED}  [!] ZIVPN belum terinstall!${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [1] : ${NC}")" choice
            case $choice in
                1) install_zivpn ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        else
            echo -e "  ${GREEN}1${NC}. ➕ Tambah User"
            echo -e "  ${CYAN}2${NC}. 📋 Daftar User"
            echo -e "  ${RED}3${NC}. 🗑️ Hapus User"
            echo -e "  ${YELLOW}4${NC}. 🔄 Perpanjang User"
            echo -e "  ${PURPLE}5${NC}. 👥 Cek User Online"
            echo ""
            echo -e "  ${BLUE}6${NC}. 🌐 Ganti Domain"
            echo -e "  ${BLUE}7${NC}. 📊 Status Service"
            echo -e "  ${BLUE}8${NC}. 🔄 Restart Service"
            echo -e "  ${BLUE}9${NC}. 🧹 Reset Login Log"
            echo ""
            echo -e "  ${GREEN}10${NC}. 💾 Backup/Restore"
            echo -e "  ${RED}11${NC}. ❌ Uninstall ZIVPN"
            echo -e "  ${WHITE}0${NC}. 🚪 Exit"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu : ${NC}")" choice

            case $choice in
                1) add_user ;;
                2) list_users ;;
                3) delete_user ;;
                4) renew_user ;;
                5) check_online_users ;;
                6) change_domain ;;
                7) status_service ;;
                8) restart_service ;;
                9) reset_login_log ;;
                10) backup_restore ;;
                11) uninstall_zivpn ;;
                0) exit 0 ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === BACKUP RESTORE (sederhana) ===
backup_restore() {
    banner
    echo -e "${BOLD}${YELLOW}[ BACKUP / RESTORE ]${NC}"
    echo ""
    echo -e "  ${WHITE}1. Backup Data${NC}"
    echo -e "  ${WHITE}2. Restore Data${NC}"
    echo -e "  ${WHITE}0. Kembali${NC}"
    echo ""
    read -rp "$(echo -e "  ${WHITE}Pilih : ${NC}")" choice
    
    case $choice in
        1)
            local backup_file="/root/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" -C /etc zivpn 2>/dev/null
            echo -e "${GREEN}  ✓ Backup created: $backup_file${NC}"
            ;;
        2)
            read -rp "$(echo -e "${WHITE}Masukkan path file backup : ${NC}")" restore_file
            if [[ -f "$restore_file" ]]; then
                systemctl stop zivpn.service
                tar -xzf "$restore_file" -C /etc 2>/dev/null
                systemctl start zivpn.service
                echo -e "${GREEN}  ✓ Restore completed${NC}"
            else
                echo -e "${RED}  ✗ File tidak ditemukan!${NC}"
            fi
            ;;
        0) return ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
    esac
    press_enter
}

# === ENTRY POINT ===
check_root
main_menu
