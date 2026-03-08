#!/bin/bash
# =============================================
#   ZIVPN UDP Manager + Auto Backup
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

# === SIMPAN DATA SERVER (DIAMBIL 1 KALI) ===
IP_ADDRESS=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
DOMAIN_NAME=$(dig +short -x "$IP_ADDRESS" 2>/dev/null | head -n1 | sed 's/\.$//')
[[ -z "$DOMAIN_NAME" ]] && DOMAIN_NAME="$IP_ADDRESS"
ISP_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=isp" 2>/dev/null || echo "Unknown ISP")
COUNTRY_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=country" 2>/dev/null || echo "Unknown")
CITY_NAME=$(curl -s "http://ip-api.com/line/$IP_ADDRESS?fields=city" 2>/dev/null || echo "Unknown")

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
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
    
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
    echo -e "${WHITE}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}      UDP Manager for ZIVPN App${NC}"
    echo -e "${WHITE}════════════════════════════════════════${NC}"
    
    local status=$(systemctl is-active zivpn.service 2>/dev/null)
    [[ "$status" == "active" ]] && status="${GREEN}● AKTIF${NC}" || status="${RED}● MATI${NC}"
    
    echo -e "  Status  : $status"
    echo -e "  IP VPS  : ${CYAN}$IP_ADDRESS${NC}"
    echo -e "  Domain  : ${CYAN}$DOMAIN_NAME${NC}"
    echo -e "  ISP     : ${YELLOW}$ISP_NAME${NC}"
    echo -e "  Lokasi  : ${YELLOW}$CITY_NAME, $COUNTRY_NAME${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999${NC}"
    echo -e "${WHITE}════════════════════════════════════════${NC}"
    echo ""
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan [ENTER] untuk kembali...${NC}"
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
        [[ "$expiry" == "unlimited" || "$expiry" > "$today" || "$expiry" == "$today" ]] && passwords+=("\"$pass\"")
    done < "$USERS_DB"
    
    [[ ${#passwords[@]} -eq 0 ]] && local pass_list="\"zivpn\"" || local pass_list=$(IFS=','; echo "${passwords[*]}")
    
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
    cat <<EOF
Terima kasih sudah order kak😇
═ ═══ ═
UDP ZIVPN
══════════════════════════════════════════
  Label    : $1
  Expired  : $3
  UDP Server  : $DOMAIN_NAME
  UDP Password: $2
══════════════════════════════════════════ >  TUTORIAL
*⚙️ LOGIN KE APK ZIVPN*
*🔍 Garis tiga (pojok kiri atas)*
*🛠 UDP Tunnel Setting*
*Udp Server.    :* $DOMAIN_NAME 
*Udp Password :* $2 ✅ Apply
✅ Centang UDP
✅ Servernya Singapore premium 5 (terserah bebas) 
> ▶ START
EOF
}

# === INSTALL ===

install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN ]${NC}\n"
    
    if is_installed; then
        echo -e "${YELLOW}Sudah terinstall!${NC}"
        press_enter
        return
    fi
    
    echo -e "${BLUE}[1/5]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron dnsutils > /dev/null 2>&1
    
    echo -e "${BLUE}[2/5]${NC} Download binary..."
    mkdir -p "$ZIVPN_DIR" "$BACKUP_DIR"
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" -O "$ZIVPN_BIN"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64" -O "$ZIVPN_BIN"
    else
        echo -e "${RED}Arsitektur tidak didukung!${NC}"
        press_enter
        return
    fi
    
    chmod +x "$ZIVPN_BIN"
    
    echo -e "${BLUE}[3/5]${NC} Generate SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    
    echo -e "${BLUE}[4/5]${NC} Setup config..."
    touch "$USERS_DB"
    update_config_json
    
    echo -e "${BLUE}[5/5]${NC} Setup service & firewall..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=$ZIVPN_BIN server -c $CONFIG_FILE
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    systemctl start zivpn.service
    
    # Firewall
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    
    # Auto backup setiap 6 jam
    (crontab -l 2>/dev/null; echo "0 */6 * * * bash /usr/local/bin/zivpn-menu --backup") | crontab -
    
    # Auto hapus expired setiap hari
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -
    
    # Cron script
    cat > /usr/local/bin/zivpn-cron.sh <<'EOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
TMPFILE=$(mktemp)

while IFS='|' read -r uname pass expiry; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        continue
    else
        echo "$uname|$pass|$expiry" >> "$TMPFILE"
    fi
done < "$USERS_DB"

mv "$TMPFILE" "$USERS_DB"

passwords=()
while IFS='|' read -r uname pass expiry; do
    passwords+=("\"$pass\"")
done < "$USERS_DB"
pass_list=$(IFS=','; echo "${passwords[*]:-\"zivpn\"}")

cat > /etc/zivpn/config.json <<EOL
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
EOL
systemctl restart zivpn.service
EOF
    chmod +x /usr/local/bin/zivpn-cron.sh
    
    # Buat alias
    cp "$(realpath $0)" /usr/local/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/local/bin/zivpn-menu 2>/dev/null
    echo "alias zivpn='bash /usr/local/bin/zivpn-menu'" >> /root/.bashrc 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ INSTALL BERHASIL!${NC}"
    echo -e "${WHITE}════════════════════════════════════════${NC}"
    echo -e "UDP Server: ${CYAN}$DOMAIN_NAME${NC}"
    echo -e "Password  : ${CYAN}buat via menu Tambah User${NC}"
    echo -e "${WHITE}════════════════════════════════════════${NC}"
    
    send_telegram "✅ ZIVPN installed on $DOMAIN_NAME"
    press_enter
}

# === TAMBAH USER ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}\n"
    load_users
    
    read -rp "Nama user: " username
    [[ -z "$username" ]] && echo -e "${RED}Nama tidak boleh kosong!${NC}" && press_enter && return
    user_exists "$username" && echo -e "${RED}User sudah ada!${NC}" && press_enter && return
    
    read -rp "Password: " password
    [[ -z "$password" ]] && echo -e "${RED}Password tidak boleh kosong!${NC}" && press_enter && return
    
    echo -e "\n${WHITE}Expired:${NC}"
    echo "1. 7 hari"
    echo "2. 14 hari"
    echo "3. 30 hari"
    echo "4. 60 hari"
    echo "5. 90 hari"
    echo "6. Custom hari"
    echo "7. Unlimited"
    read -rp "Pilih [1-7]: " exp_choice
    
    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6) read -rp "Jumlah hari: " days
           [[ ! "$days" =~ ^[0-9]+$ ]] && echo -e "${RED}Angka tidak valid!${NC}" && press_enter && return ;;
        7) days=0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" && press_enter && return ;;
    esac
    
    [[ $days -eq 0 ]] && expiry="unlimited" || expiry=$(date -d "+$days days" +%Y-%m-%d)
    
    echo "$username|$password|$expiry" >> "$USERS_DB"
    update_config_json
    
    echo ""
    [[ $expiry == "unlimited" ]] && exp_display="Unlimited" || exp_display=$(date -d "$expiry" +"%d %B %Y")
    
    generate_user_info "$username" "$password" "$exp_display"
    
    send_telegram "✅ User baru: $username (Exp: $exp_display)"
    press_enter
}

# === HAPUS USER ===

delete_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER ]${NC}\n"
    load_users
    
    [[ ! -s "$USERS_DB" ]] && echo -e "${YELLOW}Belum ada user!${NC}" && press_enter && return
    
    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "Nama user yang dihapus: " username
    ! user_exists "$username" && echo -e "${RED}User tidak ditemukan!${NC}" && press_enter && return
    
    read -rp "Yakin hapus $username? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && sed -i "/^$username|/d" "$USERS_DB" && update_config_json && echo -e "${GREEN}User dihapus!${NC}" && send_telegram "🗑 User dihapus: $username"
    
    press_enter
}

# === LIST USER ===

list_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR USER ]${NC}\n"
    load_users
    
    [[ ! -s "$USERS_DB" ]] && echo -e "${YELLOW}Belum ada user!${NC}" && press_enter && return
    
    local today=$(date +%Y-%m-%d)
    printf "${WHITE}%-15s %-15s %-12s %s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}─────────────────────────────────────────${NC}"
    
    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="Unlimited"
        elif [[ "$expiry" > "$today" || "$expiry" == "$today" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="$expiry"
        else
            status="${RED}Expired${NC}"
            exp_display="$expiry"
        fi
        printf "%-15s %-15s %-12s " "$uname" "$pass" "$exp_display"
        echo -e "$status"
    done < "$USERS_DB"
    
    press_enter
}

# === PERPANJANG USER ===

renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}\n"
    load_users
    
    [[ ! -s "$USERS_DB" ]] && echo -e "${YELLOW}Belum ada user!${NC}" && press_enter && return
    
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "Nama user: " username
    ! user_exists "$username" && echo -e "${RED}User tidak ditemukan!${NC}" && press_enter && return
    
    echo -e "\n${WHITE}Perpanjang:${NC}"
    echo "1. 7 hari"
    echo "2. 14 hari"
    echo "3. 30 hari"
    echo "4. 60 hari"
    echo "5. 90 hari"
    echo "6. Custom hari"
    echo "7. Unlimited"
    read -rp "Pilih [1-7]: " exp_choice
    
    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6) read -rp "Jumlah hari: " days
           [[ ! "$days" =~ ^[0-9]+$ ]] && echo -e "${RED}Angka tidak valid!${NC}" && press_enter && return ;;
        7) days=0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}" && press_enter && return ;;
    esac
    
    local old_expiry=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f3)
    local pass=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f2)
    
    if [[ $days -eq 0 ]]; then
        new_expiry="unlimited"
    else
        local today=$(date +%Y-%m-%d)
        if [[ "$old_expiry" == "unlimited" || "$old_expiry" > "$today" ]]; then
            new_expiry=$(date -d "$old_expiry +$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
        else
            new_expiry=$(date -d "+$days days" +%Y-%m-%d)
        fi
    fi
    
    sed -i "s/^$username|$pass|$old_expiry/$username|$pass|$new_expiry/" "$USERS_DB"
    update_config_json
    
    [[ "$new_expiry" == "unlimited" ]] && exp_display="Unlimited" || exp_display=$(date -d "$new_expiry" +"%d %B %Y")
    
    echo -e "\n${GREEN}✓ User diperpanjang sampai $exp_display${NC}"
    send_telegram "🔄 User diperpanjang: $username (Exp: $exp_display)"
    press_enter
}

# === STATUS SERVICE ===

status_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ STATUS SERVICE ]${NC}\n"
    systemctl status zivpn.service --no-pager
    press_enter
}

# === RESTART SERVICE ===

restart_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTART SERVICE ]${NC}\n"
    systemctl restart zivpn.service
    echo -e "${GREEN}✓ Service direstart${NC}"
    send_telegram "🔄 Service direstart"
    press_enter
}

# === HAPUS EXPIRED ===

clean_expired() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS EXPIRED ]${NC}\n"
    load_users
    
    local today=$(date +%Y-%m-%d)
    local tmpfile=$(mktemp)
    local count=0
    
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
        echo -e "\n${GREEN}✓ $count user expired dihapus${NC}"
        send_telegram "🧹 $count user expired dihapus"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}Tidak ada user expired${NC}"
    fi
    
    press_enter
}

# === INFO SERVER ===

info_server() {
    clear
    echo -e "${BOLD}${YELLOW}[ INFO SERVER ]${NC}\n"
    echo "SERVER INFORMATION"
    echo "══════════════════════════════════════════"
    echo "Hostname    : $(hostname)"
    echo "IP Address  : $IP_ADDRESS"
    echo "Domain      : $DOMAIN_NAME"
    echo "ISP         : $ISP_NAME"
    echo "Lokasi      : $CITY_NAME, $COUNTRY_NAME"
    echo "OS          : $(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel      : $(uname -r)"
    echo "RAM         : $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk        : $(df -h / | awk 'NR==2 {print $2}')"
    echo "Uptime      : $(uptime -p | sed 's/up //')"
    echo "══════════════════════════════════════════"
    
    local total=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    local active=0
    local today=$(date +%Y-%m-%d)
    
    while IFS='|' read -r uname pass expiry; do
        [[ "$expiry" == "unlimited" || "$expiry" > "$today" || "$expiry" == "$today" ]] && ((active++))
    done < "$USERS_DB" 2>/dev/null
    
    echo "Total User  : $total"
    echo "User Aktif  : $active"
    echo "══════════════════════════════════════════"
    
    press_enter
}

# === MANUAL BACKUP ===

manual_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ MANUAL BACKUP ]${NC}\n"
    backup_system
    echo -e "${GREEN}✓ Backup selesai & terkirim ke Telegram${NC}"
    press_enter
}

# === LIST BACKUP ===

list_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR BACKUP ]${NC}\n"
    
    [[ ! -d "$BACKUP_DIR" || -z "$(ls -A "$BACKUP_DIR")" ]] && echo -e "${YELLOW}Belum ada backup${NC}" && press_enter && return
    
    echo -e "${WHITE}File backup:${NC}"
    echo "══════════════════════════════════════════"
    
    local i=1
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(basename "$backup" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        ((i++))
    done
    
    press_enter
}

# === RESTORE BACKUP ===

restore_backup() {
    clear
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}\n"
    
    [[ ! -d "$BACKUP_DIR" || -z "$(ls -A "$BACKUP_DIR")" ]] && echo -e "${RED}Tidak ada backup!${NC}" && press_enter && return
    
    local i=1
    local backups=()
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(basename "$backup" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        backups+=("$backup")
        ((i++))
    done
    
    echo ""
    read -rp "Pilih nomor [0=batal]: " choice
    [[ "$choice" -eq 0 ]] && return
    [[ "$choice" -gt 0 && "$choice" -le ${#backups[@]} ]] || { echo -e "${RED}Pilihan tidak valid!${NC}"; press_enter; return; }
    
    local selected="${backups[$((choice-1))]}"
    systemctl stop zivpn.service
    tar -xzf "$selected" -C /
    systemctl start zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil!${NC}"
    send_telegram "✅ Restore backup: $(basename "$selected")"
    press_enter
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}\n"
    
    local SCRIPT_URL="https://raw.githubusercontent.com/ZaeniMiptah/Zivpn/main/zivpn-manager.sh"
    local SCRIPT_PATH=$(realpath "$0")
    local tmp=$(mktemp)
    
    wget -q "$SCRIPT_URL" -O "$tmp"
    
    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}Gagal download update!${NC}"
        rm -f "$tmp"
        press_enter
        return
    fi
    
    if diff -q "$tmp" "$SCRIPT_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}Script sudah versi terbaru${NC}"
        rm -f "$tmp"
    else
        cp "$tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        rm -f "$tmp"
        echo -e "${GREEN}✓ Script diupdate! Jalankan ulang.${NC}"
        press_enter
        exec bash "$SCRIPT_PATH"
    fi
    
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ]${NC}\n"
    read -rp "Yakin uninstall? [y/N]: " confirm
    
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo -e "${YELLOW}Dibatalkan${NC}" && press_enter && return
    
    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1
    rm -f "$SERVICE_FILE" "$ZIVPN_BIN" /usr/local/bin/zivpn-cron.sh /usr/local/bin/zivpn-menu
    sed -i "/alias zivpn=/d" /root/.bashrc 2>/dev/null
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -
    
    echo -e "${GREEN}✓ Uninstall selesai${NC}"
    send_telegram "❌ ZIVPN diuninstall"
    sleep 2
    exit 0
}

# === BACKUP MENU ===

backup_menu() {
    while true; do
        banner
        echo -e "${BOLD}${YELLOW}[ MENU BACKUP ]${NC}\n"
        echo "1. Backup Manual (Kirim Telegram)"
        echo "2. Daftar Backup"
        echo "3. Restore Backup"
        echo "4. Kembali"
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

# === MAIN MENU ===

main_menu() {
    while true; do
        banner
        
        if ! is_installed; then
            echo "1. Install ZIVPN"
            echo "2. Info Server"
            echo "3. Update Script"
            echo ""
            read -rp "Pilih: " choice
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
            echo "5. Hapus Expired"
            echo "6. Status Service"
            echo "7. Restart Service"
            echo "8. Info Server"
            echo "9. Backup & Restore"
            echo "10. Update Script"
            echo "11. Uninstall"
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

# === START ===

if [[ "$1" == "--backup" ]]; then
    backup_system
    exit 0
fi

check_root
main_menu
