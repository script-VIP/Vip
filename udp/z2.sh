#!/bin/bash
# =============================================
#   ZIVPN UDP Manager + Auto Backup Bot
#   By: Custom Script
# =============================================

# === KONFIGURASI BOT TELEGRAM ===
BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
CHAT_ID="6198984094"

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
BACKUP_DIR="$ZIVPN_DIR/backup"

# === AMBIL DATA SERVER (SEKALI SAJA) ===
echo -e "${YELLOW}Mengambil informasi server...${NC}"
IP_ADDRESS=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
DOMAIN_NAME=$(dig +short -x "$IP_ADDRESS" 2>/dev/null | head -n1 | sed 's/\.$//')
[ -z "$DOMAIN_NAME" ] && DOMAIN_NAME="$IP_ADDRESS"
ISP_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=isp" 2>/dev/null || echo "Unknown ISP")
COUNTRY_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=country" 2>/dev/null || echo "Unknown")
CITY_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=city" 2>/dev/null || echo "Unknown")
clear

# === FUNGSI UTILITAS ===

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Jalankan sebagai root!"
        exit 1
    fi
}

send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null 2>&1
}

send_telegram_file() {
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$1" \
        -F caption="$2" > /dev/null 2>&1
}

backup_system() {
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" -C /etc zivpn/ 2>/dev/null
    
    local file_size=$(du -h "$backup_file" | cut -f1)
    local user_count=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    
    # Hapus backup lama (simpan 7 terakhir)
    cd "$BACKUP_DIR" 2>/dev/null && ls -t | tail -n +8 | xargs -r rm -f
    
    # Kirim ke Telegram
    local caption="✅ AUTO BACKUP
══════════════════════
Waktu: $(date +"%d %B %Y %H:%M")
Ukuran: $file_size
User: $user_count"
    
    send_telegram_file "$backup_file" "$caption"
}

is_installed() {
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]
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
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            UDP Manager for ZIVPN App${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    
    local status=$(systemctl is-active zivpn.service 2>/dev/null)
    if [[ "$status" == "active" ]]; then
        echo -e "  Status  : ${GREEN}● AKTIF${NC}"
    else
        echo -e "  Status  : ${RED}● MATI${NC}"
    fi
    echo -e "  IP VPS  : ${CYAN}$IP_ADDRESS${NC}"
    echo -e "  Domain  : ${CYAN}$DOMAIN_NAME${NC}"
    echo -e "  ISP     : ${YELLOW}$ISP_NAME${NC}"
    echo -e "  Lokasi  : ${YELLOW}$CITY_NAME, $COUNTRY_NAME${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    echo ""
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan ENTER untuk kembali...${NC}"
    read -r
}

# === FUNGSI USER DB ===

load_users() {
    [[ ! -f "$USERS_DB" ]] && touch "$USERS_DB"
}

user_exists() {
    grep -q "^$1|" "$USERS_DB" 2>/dev/null
}

update_config_json() {
    local today=$(date +%Y-%m-%d)
    local passwords=()
    
    while IFS='|' read -r uname pass expiry; do
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
    systemctl restart zivpn.service 2>/dev/null
}

generate_user_info() {
    local username="$1"
    local password="$2"
    local expiry="$3"
    
    cat <<EOF
Terima kasih sudah order kak😇
═ ═══ ═
UDP ZIVPN
══════════════════════════════════════════
  Label    : $username
  Expired  : $expiry
  UDP Server  : $DOMAIN_NAME
  UDP Password: $password
══════════════════════════════════════════ >  TUTORIAL
*⚙️ LOGIN KE APK ZIVPN*
*🔍 Garis tiga (pojok kiri atas)*
*🛠 UDP Tunnel Setting*
*Udp Server.    :* $DOMAIN_NAME 
*Udp Password :* $password ✅ Apply
✅ Centang UDP
✅ Servernya Singapore premium 5 (terserah bebas) 
> ▶ START
EOF
}

# === INSTALL ===

install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN UDP SERVER ]${NC}"
    echo ""

    if is_installed; then
        echo -e "${YELLOW}ZIVPN UDP sudah terinstall!${NC}"
        press_enter
        return
    fi

    echo -e "${BLUE}[1/6]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron dnsutils > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[2/6]${NC} Download binary ZIVPN UDP..."
    mkdir -p "$ZIVPN_DIR" "$BACKUP_DIR"

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

    echo -e "${BLUE}[3/6]${NC} Generate sertifikat SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[4/6]${NC} Membuat config dan database user..."
    touch "$USERS_DB"
    update_config_json
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[5/6]${NC} Membuat systemd service..."
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

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    systemctl start zivpn.service
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[6/6]${NC} Setup firewall..."
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    # Setup auto backup
    (crontab -l 2>/dev/null; echo "0 */6 * * * bash /usr/local/bin/zivpn-menu --backup") | crontab -

    # Setup auto hapus expired
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
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
    passwords=()
    while IFS='|' read -r uname pass expiry; do
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
    chmod +x /usr/local/bin/zivpn-cron.sh

    # Buat alias
    cp "$(realpath $0)" /usr/local/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/local/bin/zivpn-menu 2>/dev/null
    if ! grep -q "zivpn-menu" /root/.bashrc 2>/dev/null; then
        echo "alias zivpn='bash /usr/local/bin/zivpn-menu'" >> /root/.bashrc
    fi

    echo ""
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    echo -e "  UDP Server  : ${CYAN}$DOMAIN_NAME${NC}"
    echo -e "  Password    : ${CYAN}[buat via menu Tambah User]${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════${NC}"
    echo -e "  Ketik ${BOLD}zivpn${NC} untuk buka menu"
    
    send_telegram "✅ ZIVPN UDP berhasil diinstall! Server: $DOMAIN_NAME"
    
    echo ""
    press_enter
}

# === TAMBAH USER ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users

    read -rp "Nama user: " username
    if [[ -z "$username" ]]; then
        echo -e "${RED}Nama user tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    if user_exists "$username"; then
        echo -e "${RED}User '$username' sudah ada!${NC}"
        press_enter
        return
    fi

    read -rp "Password: " password
    if [[ -z "$password" ]]; then
        echo -e "${RED}Password tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Expired:${NC}"
    echo "1. 7 hari"
    echo "2. 14 hari"
    echo "3. 30 hari"
    echo "4. 60 hari"
    echo "5. 90 hari"
    echo "6. Custom hari"
    echo "7. Unlimited"
    echo ""
    read -rp "Pilih [1-7]: " exp_choice

    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6)
            read -rp "Jumlah hari: " days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Masukkan angka yang valid!${NC}"
                press_enter
                return
            fi
            ;;
        7) days=0 ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            press_enter
            return
            ;;
    esac

    if [[ "$days" -eq 0 ]]; then
        expiry="unlimited"
    else
        expiry=$(date -d "+$days days" +%Y-%m-%d)
    fi

    echo "$username|$password|$expiry" >> "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User berhasil ditambahkan!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    if [[ "$expiry" == "unlimited" ]]; then
        exp_display="Unlimited"
    else
        exp_display=$(date -d "$expiry" +"%d %B %Y")
    fi
    
    generate_user_info "$username" "$password" "$exp_display"
    
    send_telegram "✅ USER BARU
══════════════════════
Username: $username
Password: $password
Expired : $exp_display"
    
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
        echo -e "${YELLOW}Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "Nama user yang ingin dihapus: " username

    if ! user_exists "$username"; then
        echo -e "${RED}User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "Yakin hapus user '$username'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$username|/d" "$USERS_DB"
        update_config_json
        echo -e "${GREEN}User '$username' berhasil dihapus!${NC}"
        send_telegram "🗑 User dihapus: $username"
    else
        echo -e "${YELLOW}Dibatalkan.${NC}"
    fi

    press_enter
}

# === LIST USER ===

list_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    local today=$(date +%Y-%m-%d)
    printf "${WHITE}%-15s %-15s %-12s %s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}─────────────────────────────────────────────────${NC}"

    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="Unlimited"
        elif [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="$expiry"
        else
            status="${RED}Expired${NC}"
            exp_display="$expiry"
        fi
        printf "%-15s %-15s %-12s " "$uname" "$pass" "$exp_display"
        echo -e "$status"
    done < "$USERS_DB"

    echo ""
    press_enter
}

# === PERPANJANG USER ===

renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "Nama user: " username

    if ! user_exists "$username"; then
        echo -e "${RED}User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Perpanjang:${NC}"
    echo "1. 7 hari"
    echo "2. 14 hari"
    echo "3. 30 hari"
    echo "4. 60 hari"
    echo "5. 90 hari"
    echo "6. Custom hari"
    echo "7. Unlimited"
    echo ""
    read -rp "Pilih [1-7]: " exp_choice

    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6)
            read -rp "Jumlah hari: " days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Masukkan angka yang valid!${NC}"
                press_enter
                return
            fi
            ;;
        7) days=0 ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            press_enter
            return
            ;;
    esac

    local old_expiry=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f3)
    local pass=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f2)

    if [[ "$days" -eq 0 ]]; then
        new_expiry="unlimited"
    else
        local today=$(date +%Y-%m-%d)
        if [[ "$old_expiry" == "unlimited" ]] || [[ "$old_expiry" > "$today" ]]; then
            new_expiry=$(date -d "$old_expiry +$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
        else
            new_expiry=$(date -d "+$days days" +%Y-%m-%d)
        fi
    fi

    sed -i "s/^$username|$pass|$old_expiry/$username|$pass|$new_expiry/" "$USERS_DB"
    update_config_json

    if [[ "$new_expiry" == "unlimited" ]]; then
        exp_display="Unlimited"
    else
        exp_display=$(date -d "$new_expiry" +"%d %B %Y")
    fi

    echo ""
    echo -e "${GREEN}User '$username' berhasil diperpanjang!${NC}"
    echo -e "Expired baru: ${CYAN}$exp_display${NC}"
    
    send_telegram "🔄 User diperpanjang: $username (Exp: $exp_display)"
    
    echo ""
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
        echo -e "${GREEN}Service berhasil di-restart!${NC}"
        send_telegram "🔄 Service ZIVPN UDP direstart"
    else
        echo -e "${RED}Service gagal restart. Cek log: journalctl -u zivpn.service${NC}"
    fi
    echo ""
    press_enter
}

# === HAPUS EXPIRED ===

clean_expired() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER EXPIRED ]${NC}"
    echo ""
    load_users

    local today=$(date +%Y-%m-%d)
    local count=0
    local tmpfile=$(mktemp)

    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $uname"
            ((count++))
        else
            echo "$uname|$pass|$expiry" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}$count user expired berhasil dihapus!${NC}"
        send_telegram "🧹 $count user expired telah dihapus"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}Tidak ada user expired.${NC}"
    fi

    echo ""
    press_enter
}

# === INFO SERVER ===

info_server() {
    clear
    echo -e "${BOLD}${YELLOW}[ INFORMASI SERVER ]${NC}"
    echo ""
    
    echo "SERVER INFORMATION"
    echo "══════════════════════════════════════════"
    echo "Hostname    : $(hostname)"
    echo "IP Address  : $IP_ADDRESS"
    echo "Domain      : $DOMAIN_NAME"
    echo "ISP         : $ISP_NAME"
    echo "Lokasi      : $CITY_NAME, $COUNTRY_NAME"
    echo "OS          : $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel      : $(uname -r)"
    echo "CPU         : $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
    echo "RAM         : $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk        : $(df -h / | awk 'NR==2 {print $2}')"
    echo "Uptime      : $(uptime -p | sed 's/up //')"
    echo "══════════════════════════════════════════"
    
    echo ""
    echo -e "${WHITE}SERVICE STATUS:${NC}"
    echo "══════════════════════════════════════════"
    echo "ZIVPN Service : $(systemctl is-active zivpn.service)"
    echo "══════════════════════════════════════════"
    
    echo ""
    local total_user=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    local active_user=0
    local today=$(date +%Y-%m-%d)
    
    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            ((active_user++))
        fi
    done < "$USERS_DB" 2>/dev/null
    
    echo "Total User    : $total_user"
    echo "User Aktif    : $active_user"
    echo "══════════════════════════════════════════"
    
    press_enter
}

# === MANUAL BACKUP ===

manual_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ MANUAL BACKUP ]${NC}"
    echo ""
    
    backup_system
    
    echo -e "${GREEN}Backup berhasil dibuat dan dikirim ke Telegram!${NC}"
    echo -e "Lokasi backup: $BACKUP_DIR"
    
    press_enter
}

# === LIST BACKUP ===

list_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR BACKUP ]${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
        echo -e "${YELLOW}Belum ada file backup.${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}File backup tersedia:${NC}"
    echo "══════════════════════════════════════════"
    
    local i=1
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(echo "$filename" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        ((i++))
    done
    
    echo "══════════════════════════════════════════"
    
    press_enter
}

# === RESTORE BACKUP ===

restore_backup() {
    clear
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
        echo -e "${RED}Tidak ada file backup ditemukan!${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}Daftar Backup Tersedia:${NC}"
    echo "══════════════════════════════════════════"
    
    local i=1
    local backups=()
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(echo "$filename" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        backups+=("$backup")
        ((i++))
    done
    
    echo ""
    read -rp "Pilih nomor backup [0 untuk batal]: " choice
    
    if [[ "$choice" -eq 0 ]]; then
        echo -e "${YELLOW}Dibatalkan.${NC}"
        press_enter
        return
    fi
    
    if [[ "$choice" -gt 0 && "$choice" -le ${#backups[@]} ]]; then
        local selected="${backups[$((choice-1))]}"
        echo -e "${YELLOW}Menghentikan service...${NC}"
        systemctl stop zivpn.service
        
        echo -e "${YELLOW}Merestore backup...${NC}"
        tar -xzf "$selected" -C /
        
        echo -e "${YELLOW}Menjalankan ulang service...${NC}"
        systemctl start zivpn.service
        
        echo -e "${GREEN}Restore backup berhasil!${NC}"
        
        send_telegram "✅ Restore backup: $(basename "$selected")"
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi
    
    press_enter
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}"
    echo ""

    local SCRIPT_URL="https://raw.githubusercontent.com/ZaeniMiptah/Zivpn/main/zivpn-manager.sh"
    local SCRIPT_PATH=$(realpath "$0")

    echo "Mengecek update dari GitHub..."
    local tmp=$(mktemp)
    wget -q "$SCRIPT_URL" -O "$tmp"

    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}Gagal download update!${NC}"
        rm -f "$tmp"
        press_enter
        return
    fi

    if diff -q "$tmp" "$SCRIPT_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}Script sudah versi terbaru!${NC}"
        rm -f "$tmp"
    else
        cp "$tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        rm -f "$tmp"
        echo -e "${GREEN}Script berhasil diupdate!${NC}"
        echo -e "${YELLOW}Silakan jalankan ulang script.${NC}"
        echo ""
        press_enter
        exec bash "$SCRIPT_PATH"
    fi

    echo ""
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN UDP ]${NC}"
    echo ""
    read -rp "Yakin ingin uninstall? Semua data akan hilang! [y/N]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Dibatalkan.${NC}"
        press_enter
        return
    fi

    echo "Menghentikan service..."
    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1

    echo "Menghapus file..."
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -f /usr/local/bin/zivpn-cron.sh
    rm -f /usr/local/bin/zivpn-menu
    sed -i "/alias zivpn=/d" /root/.bashrc 2>/dev/null
    rm -rf "$ZIVPN_DIR"

    systemctl daemon-reload

    echo "Menghapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -

    echo ""
    echo -e "${GREEN}ZIVPN UDP berhasil diuninstall!${NC}"
    
    send_telegram "❌ ZIVPN UDP telah diuninstall"
    
    echo ""
    sleep 2
    exit 0
}

# === BACKUP MENU ===

backup_menu() {
    while true; do
        banner
        echo -e "${BOLD}${YELLOW}[ MENU BACKUP & RESTORE ]${NC}"
        echo ""
        echo "1. Backup Manual (Kirim ke Telegram)"
        echo "2. Daftar Backup"
        echo "3. Restore Backup"
        echo "4. Kembali ke Menu Utama"
        echo ""
        read -rp "Pilih [1-4]: " choice

        case $choice in
            1) manual_backup ;;
            2) list_backup ;;
            3) restore_backup ;;
            4) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# === MENU UTAMA ===

main_menu() {
    while true; do
        banner

        if ! is_installed; then
            echo "1. Install ZIVPN UDP"
            echo "2. Info Server"
            echo "3. Update Script"
            echo ""
            read -rp "Pilih [1-3]: " choice
            case $choice in
                1) install_zivpn ;;
                2) info_server ;;
                3) update_script ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        else
            echo "1. Tambah User"
            echo "2. Hapus User"
            echo "3. Daftar User"
            echo "4. Perpanjang User"
            echo "5. Hapus User Expired"
            echo ""
            echo "6. Status Service"
            echo "7. Restart Service"
            echo ""
            echo "8. Info Server"
            echo "9. Backup & Restore"
            echo ""
            echo "10. Update Script"
            echo "11. Uninstall ZIVPN"
            echo ""
            read -rp "Pilih [1-11]: " choice

            case $choice in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) clean_expired ;;
                6) status_service ;;
                7) restart_service ;;
                8) info_server ;;
                9) backup_menu ;;
                10) update_script ;;
                11) uninstall_zivpn ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === ENTRY POINT ===

if [[ "$1" == "--backup" ]]; then
    backup_system
    exit 0
fi

check_root
main_menu
