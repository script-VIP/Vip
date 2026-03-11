#!/bin/bash
# =============================================
#   ZIVPN UDP Manager
#   By: Custom Script (based on ZIVPN official binary)
#   OS: Ubuntu 20.04 / 22.00 / 24.04
# =============================================

# === KONFIGURASI DASAR ===
CONFIG="/etc/zivpn/config.json"
DB="/etc/zivpn/users.db"
DOMAIN_FILE="/etc/zivpn/domain.conf"
BACKUP_DIR="/root/zivpn-backup"
TG_FILE="/etc/zivpn/telegram.conf"
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
SERVICE_FILE="/etc/systemd/system/zivpn.service"

# Buat direktori yang diperlukan
mkdir -p /etc/zivpn
mkdir -p "$BACKUP_DIR"
touch "$DB"
[ ! -f "$DOMAIN_FILE" ] && echo "-" > "$DOMAIN_FILE"

# Load domain
DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# === LOAD TELEGRAM CONFIG ===
if [ -f "$TG_FILE" ]; then
  source "$TG_FILE"
else
  # Default token 
  BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
  CHAT_ID="6198984094"
  # Simpan default
  cat > "$TG_FILE" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF
  chmod 600 "$TG_FILE"
fi

# === ENSURE JQ ===
if ! command -v jq >/dev/null 2>&1; then
  apt update -y >/dev/null 2>&1
  apt install -y jq >/dev/null 2>&1
fi

# === ENSURE ZIP & UNZIP ===
if ! command -v zip >/dev/null 2>&1; then
  apt install -y zip >/dev/null 2>&1
fi

if ! command -v unzip >/dev/null 2>&1; then
  apt install -y unzip >/dev/null 2>&1
fi

# === ENSURE RCLONE ===
if ! command -v rclone >/dev/null 2>&1; then
  curl https://rclone.org/install.sh | bash >/dev/null 2>&1
fi

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

get_location() {
    curl -s ipinfo.io/city 2>/dev/null || echo "Unknown"
}

get_isp() {
    curl -s ipinfo.io/org 2>/dev/null | cut -d' ' -f2- || echo "Unknown"
}

get_city() {
    curl -s ipinfo.io/city 2>/dev/null || echo "Unknown"
}

get_ram() {
    local total_ram=$(free -m | awk '/Mem:/ {print $2}')
    local used_ram=$(free -m | awk '/Mem:/ {print $3}')
    local ram_percent=$((used_ram * 100 / total_ram))
    
    if [[ $ram_percent -lt 50 ]]; then
        echo -e "${GREEN}${used_ram}MB/${total_ram}MB${NC}"
    elif [[ $ram_percent -lt 80 ]]; then
        echo -e "${YELLOW}${used_ram}MB/${total_ram}MB${NC}"
    else
        echo -e "${RED}${used_ram}MB/${total_ram}MB${NC}"
    fi
}

get_cpu() {
    local cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs | cut -d' ' -f1-4)
    local cpu_cores=$(nproc)
    echo "${cpu_model} (${cpu_cores} Core)"
}

get_uptime() {
    local uptime=$(uptime -p | sed 's/up //')
    echo "$uptime"
}

get_os() {
    lsb_release -d | cut -d':' -f2 | xargs
}

is_installed() {
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG" ]]
}

# === FUNGSI TELEGRAM ===

send_telegram() {
    local message="$1"
    [ -z "$BOT_TOKEN" ] && return 1
    [ -z "$CHAT_ID" ] && return 1
    
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="Markdown" > /dev/null 2>&1
}

send_file_telegram() {
    local file="$1"
    local caption="$2"
    
    [ -z "$BOT_TOKEN" ] && return 1
    [ -z "$CHAT_ID" ] && return 1
    [ ! -f "$file" ] && return 1
    
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" > /dev/null 2>&1
}

# === FUNGSI BANNER ===

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
    echo -e "${YELLOW}         UDP Manager for ZIVPN App${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    
    if is_installed; then
        local ip=$(get_ip)
        local domain=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")
        local isp=$(get_isp)
        local city=$(get_city)
        local ram=$(get_ram)
        local cpu=$(get_cpu)
        local os=$(get_os)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        
        echo -e "  ${WHITE}Status   :${NC} $([[ "$status" == "active" ]] && echo "${GREEN}● AKTIF${NC}" || echo "${RED}● MATI${NC}")"
        echo -e "  ${WHITE}IP       :${NC} ${CYAN}$ip${NC}"
        echo -e "  ${WHITE}Domain   :${NC} ${CYAN}$domain${NC}"
        echo -e "  ${WHITE}ISP      :${NC} ${YELLOW}$isp${NC}"
        echo -e "  ${WHITE}Kota     :${NC} ${YELLOW}$city${NC}"
        echo -e "  ${WHITE}RAM      :${NC} $ram"
        echo -e "  ${WHITE}CPU      :${NC} ${YELLOW}$cpu${NC}"
        echo -e "  ${WHITE}OS       :${NC} ${YELLOW}$os${NC}"
        echo -e "  ${WHITE}Port     :${NC} ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    fi
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    echo ""
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan [ENTER] untuk kembali ke menu...${NC}"
    read -r
}

# === FUNGSI DOMAIN ===

set_domain() {
    banner
    echo -e "${BOLD}${YELLOW}[ SET DOMAIN ]${NC}"
    echo ""
    
    local current_domain="$DOMAIN"
    echo -e "  Domain saat ini: ${CYAN}${current_domain:-Belum diatur}${NC}"
    echo ""
    read -rp "$(echo -e "${WHITE}Masukkan domain baru (contoh: vpn.example.com) : ${NC}")" new_domain
    
    if [[ -z "$new_domain" ]]; then
        echo -e "${YELLOW}Domain tidak diubah.${NC}"
    else
        DOMAIN="$new_domain"
        echo "$DOMAIN" > "$DOMAIN_FILE"
        echo -e "${GREEN}Domain berhasil diubah menjadi: ${CYAN}$new_domain${NC}"
    fi
    
    echo ""
    press_enter
}

# === FUNGSI UPDATE CONFIG ===

update_config_json() {
    # Ambil semua password dari users.db yang belum expired
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            passwords+=("\"$pass\"")
        fi
    done < "$DB" 2>/dev/null

    if [[ ${#passwords[@]} -eq 0 ]]; then
        local pass_list="\"zivpn\""
    else
        local pass_list=$(IFS=','; echo "${passwords[*]}")
    fi

    cat > "$CONFIG" <<EOF
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

# === CREATE ACCOUNT DEFAULT (DENGAN ANGKA DI BELAKANG) ===
create_account_default() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER - DEFAULT 2 DIGIT ]${NC}"
    echo ""
    
    # Generate 2 digit random
    RANDOM2=$(printf "%02d" $((RANDOM % 100)))
    
    read -rp "$(echo -e "${WHITE}Masukkan nama/prefix [default: user] : ${NC}")" PREFIX
    [ -z "$PREFIX" ] && PREFIX="user"
    
    # Generate password: prefix + 2 digit random
    PASSWORD="${PREFIX}${RANDOM2}"
    
    # Cek apakah password sudah ada
    if grep -q "|$PASSWORD|" "$DB" 2>/dev/null; then
        echo -e "${YELLOW}[!] Password '$PASSWORD' sudah digunakan, generate ulang...${NC}"
        while grep -q "|$PASSWORD|" "$DB" 2>/dev/null; do
            RANDOM2=$(printf "%02d" $((RANDOM % 100)))
            PASSWORD="${PREFIX}${RANDOM2}"
        done
        echo -e "${GREEN}    ✓ Password baru: $PASSWORD${NC}"
    fi
    
    read -rp "$(echo -e "${WHITE}Limit IP [default: 2] : ${NC}")" LIMIT
    [ -z "$LIMIT" ] && LIMIT=2
    
    read -rp "$(echo -e "${WHITE}Masa aktif (hari) [default: 30] : ${NC}")" DAYS
    [ -z "$DAYS" ] && DAYS=30
    
    # Username (untuk display)
    USER="user_$PASSWORD"
    
    # Hitung expired
    if [[ "$DAYS" == "0" ]]; then
        EXP="unlimited"
        EXP_DATE="Unlimited"
    else
        EXP=$(date -d "+$DAYS days" +"%Y-%m-%d")
        EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
    fi
    
    CREATE_DATE=$(date +"%d %b, %Y")
    
    # Dapatkan lokasi
    LOKASI=$(get_location)
    
    # Simpan ke database (format: USER|PASSWORD|EXPIRED|LIMIT)
    echo "$USER|$PASSWORD|$EXP|$LIMIT" >> "$DB"
    
    # Update config
    update_config_json
    
    # Tampilkan hasil
    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}ZIVPN UDP${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  Domain      : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  Domain      : ${RED}Belum diatur${NC}"
        echo -e "  IP Server   : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "  Password    : ${YELLOW}$PASSWORD${NC}"
    echo -e "  Limit IP    : ${MAGENTA}$([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")${NC}"
    echo -e "  Server      : ${CYAN}$LOKASI${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  Tanggal Buat: ${GREEN}$CREATE_DATE${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$EXP_DATE${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$([ "$DAYS" == "0" ] && echo "Selamanya" || echo "$DAYS hari")${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. klik negaranya bebas ( Sg premium 5 )"
    echo -e "  4. Klik Garis tiga ( dipojok kiri atas )"
    echo -e "  5. Klik Udp tunnel setting"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  6. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  6. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$PASSWORD${NC}"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    # Kirim notifikasi ke Telegram
    send_telegram "✅ *AKUN ZIVPN BARU*
══════════════════════
Password : \`$PASSWORD\`
Limit IP : $([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")
Expired  : $EXP_DATE
Server   : $LOKASI"
    
    echo ""
    press_enter
}

# === CREATE ACCOUNT CUSTOM ===
create_account_custom() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER - CUSTOM PASSWORD ]${NC}"
    echo ""
    
    read -rp "$(echo -e "${WHITE}Password : ${NC}")" PASSWORD
    
    # Validasi password tidak kosong
    if [ -z "$PASSWORD" ]; then
        echo -e "${RED}[!] Password tidak boleh kosong!${NC}"
        sleep 2
        return
    fi
    
    # Cek apakah password sudah ada
    if grep -q "|$PASSWORD|" "$DB" 2>/dev/null; then
        echo -e "${RED}[!] Password '$PASSWORD' sudah digunakan!${NC}"
        sleep 2
        return
    fi
    
    read -rp "$(echo -e "${WHITE}Limit IP [default: 2] : ${NC}")" LIMIT
    [ -z "$LIMIT" ] && LIMIT=2
    
    read -rp "$(echo -e "${WHITE}Masa aktif (hari) [default: 30] : ${NC}")" DAYS
    [ -z "$DAYS" ] && DAYS=30
    
    # Username (untuk display)
    USER="user_$PASSWORD"
    
    # Hitung expired
    if [[ "$DAYS" == "0" ]]; then
        EXP="unlimited"
        EXP_DATE="Unlimited"
    else
        EXP=$(date -d "+$DAYS days" +"%Y-%m-%d")
        EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
    fi
    
    CREATE_DATE=$(date +"%d %b, %Y")
    
    # Dapatkan lokasi
    LOKASI=$(get_location)
    
    # Simpan ke database (format: USER|PASSWORD|EXPIRED|LIMIT)
    echo "$USER|$PASSWORD|$EXP|$LIMIT" >> "$DB"
    
    # Update config
    update_config_json
    
    # Tampilkan hasil
    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}ZIVPN UDP${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  Domain      : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  Domain      : ${RED}Belum diatur${NC}"
        echo -e "  IP Server   : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "  Password    : ${YELLOW}$PASSWORD${NC}"
    echo -e "  Limit IP    : ${MAGENTA}$([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")${NC}"
    echo -e "  Server      : ${CYAN}$LOKASI${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  Tanggal Buat: ${GREEN}$CREATE_DATE${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$EXP_DATE${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$([ "$DAYS" == "0" ] && echo "Selamanya" || echo "$DAYS hari")${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. klik negaranya bebas ( Sg premium 5 )"
    echo -e "  4. Klik Garis tiga ( dipojok kiri atas )"
    echo -e "  5. Klik Udp tunnel setting"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  6. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  6. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$PASSWORD${NC}"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    # Kirim notifikasi ke Telegram
    send_telegram "✅ *AKUN ZIVPN BARU*
══════════════════════
Password : \`$PASSWORD\`
Limit IP : $([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")
Expired  : $EXP_DATE
Server   : $LOKASI"
    
    echo ""
    press_enter
}

# === HAPUS USER ===

delete_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER ]${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar password user:${NC}"
    local i=1
    while IFS='|' read -r user pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user yang ingin dihapus : ${NC}")" password

    if ! grep -q "|$password|" "$DB" 2>/dev/null; then
        echo -e "${RED}[!] Password '$password' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${RED}Yakin hapus user dengan password '$password'? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/|$password|/d" "$DB"
        update_config_json
        echo -e "${GREEN}  ✓ User dengan password '$password' berhasil dihapus!${NC}"
        send_telegram "🗑 *USER DIHAPUS*\nPassword: \`$password\`"
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi

    press_enter
}

# === LIST USER ===

list_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR USER ]${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    local today=$(date +%Y-%m-%d)
    printf "${WHITE}%-20s %-15s %-10s %-10s${NC}\n" "PASSWORD" "EXPIRED" "LIMIT" "STATUS"
    echo -e "${WHITE}─────────────────────────────────────────────────────────${NC}"

    while IFS='|' read -r user pass expiry limit; do
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
        
        if [[ "$limit" == "0" ]]; then
            limit_display="${GREEN}∞${NC}"
        else
            limit_display="${CYAN}$limit${NC}"
        fi
        
        printf "%-20s %-15s %-10s " "$pass" "$(echo -e $exp_display)" "$(echo -e $limit_display)"
        echo -e "$status"
    done < "$DB"

    echo -e "${WHITE}─────────────────────────────────────────────────────────${NC}"
    
    local total=$(wc -l < "$DB")
    echo -e "  Total User: ${GREEN}$total${NC}"
    
    press_enter
}

# === PERPANJANG USER ===

renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar password user:${NC}"
    local i=1
    while IFS='|' read -r user pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user : ${NC}")" password

    if ! grep -q "|$password|" "$DB" 2>/dev/null; then
        echo -e "${RED}[!] Password '$password' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Perpanjang (masukkan angka hari) :${NC}"
    echo -e "  ${CYAN}Contoh: 30 untuk tambah 30 hari, 0 untuk Unlimited${NC}"
    echo ""
    read -rp "$(echo -e "${WHITE}Jumlah hari tambahan (0 = unlimited) : ${NC}")" days

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    # Ambil data user
    local old_data=$(grep "|$password|" "$DB")
    local old_user=$(echo "$old_data" | cut -d'|' -f1)
    local old_expiry=$(echo "$old_data" | cut -d'|' -f3)
    local limit=$(echo "$old_data" | cut -d'|' -f4)

    if [[ "$days" -eq 0 ]]; then
        new_expiry="unlimited"
        exp_display="Unlimited"
    else
        local today=$(date +%Y-%m-%d)
        if [[ "$old_expiry" == "unlimited" ]] || [[ "$old_expiry" > "$today" ]]; then
            new_expiry=$(date -d "$old_expiry +$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
        else
            new_expiry=$(date -d "+$days days" +%Y-%m-%d)
        fi
        exp_display=$(date -d "$new_expiry" +"%d %B %Y")
    fi

    # Hapus data lama dan tambah baru
    sed -i "/|$password|/d" "$DB"
    echo "$old_user|$password|$new_expiry|$limit" >> "$DB"
    
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User dengan password '$password' berhasil diperpanjang!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  Expired baru : ${YELLOW}$exp_display${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    send_telegram "🔄 *USER DIPERPANJANG*\nPassword: \`$password\`\nExpired: $exp_display"
    
    echo ""
    press_enter
}

# === UBAH LIMIT IP ===

change_limit() {
    banner
    echo -e "${BOLD}${YELLOW}[ UBAH LIMIT IP ]${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user dengan limit saat ini:${NC}"
    local i=1
    while IFS='|' read -r user pass expiry limit; do
        [[ "$limit" == "0" ]] && disp="Unlimited" || disp="$limit Device"
        echo -e "  ${CYAN}$i.${NC} $pass - Limit: ${YELLOW}$disp${NC}"
        ((i++))
    done < "$DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user yang akan diubah limitnya : ${NC}")" password

    if ! grep -q "|$password|" "$DB" 2>/dev/null; then
        echo -e "${RED}[!] Password '$password' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    # Ambil data user
    local old_data=$(grep "|$password|" "$DB")
    local old_user=$(echo "$old_data" | cut -d'|' -f1)
    local expiry=$(echo "$old_data" | cut -d'|' -f3)

    read -rp "$(echo -e "${WHITE}Limit IP baru (0=unlimited) : ${NC}")" new_limit
    if ! [[ "$new_limit" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    # Hapus data lama dan tambah baru
    sed -i "/|$password|/d" "$DB"
    echo "$old_user|$password|$expiry|$new_limit" >> "$DB"
    
    update_config_json

    [[ "$new_limit" == "0" ]] && disp="Unlimited" || disp="$new_limit Device"
    echo ""
    echo -e "${GREEN}  ✓ Limit IP untuk '$password' berhasil diubah menjadi $disp${NC}"
    
    press_enter
}

# === CEK USER ONLINE ===

check_online_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ CEK USER ONLINE ]${NC}"
    echo ""
    
    echo -e "${WHITE}Mengecek koneksi UDP yang aktif...${NC}"
    echo ""
    echo "────────────────────────────────────────"
    
    # Cek koneksi dari netstat
    local connections=$(netstat -un 2>/dev/null | grep -c :5667)
    
    if [[ $connections -gt 0 ]]; then
        echo -e "  ${GREEN}Total Koneksi Aktif : $connections${NC}"
        echo ""
        echo -e "${WHITE}Detail Koneksi:${NC}"
        netstat -un 2>/dev/null | grep :5667 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | while read count ip; do
            echo -e "  ${CYAN}$ip${NC} - ${YELLOW}$count koneksi${NC}"
        done
    else
        echo -e "  ${YELLOW}Tidak ada koneksi aktif saat ini${NC}"
    fi
    
    echo "────────────────────────────────────────"
    echo -e "${WHITE}User Terdaftar:${NC}"
    
    local today=$(date +%Y-%m-%d)
    local active=0
    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            [[ "$limit" == "0" ]] && disp="Unlimited" || disp="$limit Device"
            echo -e "  ${GREEN}✓${NC} $pass (Limit: $disp)"
            ((active++))
        fi
    done < "$DB" 2>/dev/null
    
    echo ""
    echo -e "  ${WHITE}Total User Aktif: ${GREEN}$active${NC}"
    echo "────────────────────────────────────────"
    
    press_enter
}

# === HAPUS USER EXPIRED ===

clean_expired() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER EXPIRED ]${NC}"
    echo ""
    
    local today=$(date +%Y-%m-%d)
    local count=0
    local tmpfile=$(mktemp)
    local deleted_users=""

    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass (expired: $expiry)"
            ((count++))
            deleted_users="$deleted_users\n- $pass"
        else
            echo "$user|$pass|$expiry|$limit" >> "$tmpfile"
        fi
    done < "$DB" 2>/dev/null

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$DB"
        update_config_json
        echo ""
        echo -e "${GREEN}  ✓ $count user expired berhasil dihapus!${NC}"
        send_telegram "🧹 *CLEAN EXPIRED*\n$count user expired dihapus:$deleted_users"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}  Tidak ada user expired.${NC}"
    fi

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
    if systemctl is-active zivpn.service > /dev/null; then
        echo -e "${GREEN}  ✓ Service berhasil di-restart!${NC}"
        send_telegram "🔄 *SERVICE RESTART*\nService ZIVPN UDP direstart"
    else
        echo -e "${RED}  ✗ Service gagal restart!${NC}"
    fi
    echo ""
    press_enter
}

# === TELEGRAM SETTING ===
telegram_setting() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}   TELEGRAM BOT NOTIFICATION SETUP${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    echo -e "Bot Token saat ini: ${YELLOW}${BOT_TOKEN:0:10}...${NC}"
    echo -e "Chat ID saat ini  : ${YELLOW}$CHAT_ID${NC}"
    echo ""
    
    read -rp "Input Bot Token baru (Enter biarkan): " new_token
    read -rp "Input Chat ID baru (Enter biarkan): " new_chatid

    if [[ -n "$new_token" ]]; then
        BOT_TOKEN="$new_token"
    fi
    
    if [[ -n "$new_chatid" ]]; then
        CHAT_ID="$new_chatid"
    fi

    cat > "$TG_FILE" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF

    chmod 600 "$TG_FILE"
    
    echo ""
    echo -e "${GREEN}✓ Telegram Bot berhasil disimpan!${NC}"
    
    # Test kirim pesan
    echo -e "${YELLOW}Mengirim pesan test...${NC}"
    send_telegram "✅ *Telegram Bot Connected*\nZIVPN Manager berhasil terhubung!"
    
    sleep 2
}

# === RCLONE SETUP ===
rclone_setup() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}     RCLONE GOOGLE DRIVE SETUP${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    echo "Ikuti langkah berikut untuk menghubungkan Google Drive:"
    echo ""
    echo "1. Jalankan perintah: rclone config"
    echo "2. Pilih 'n' untuk remote baru"
    echo "3. Nama remote: gdrive"
    echo "4. Pilih 'drive' sebagai tipe"
    echo "5. Ikuti petunjuk untuk login ke Google"
    echo ""
    read -rp "Sudah siap? (y/n): " siap
    
    if [[ "$siap" == "y" ]]; then
        rclone config
        echo -e "${GREEN}Rclone configured${NC}"
    fi
    sleep 2
}

# === BACKUP ZIVPN ===
backup_zivpn() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}         BACKUP ZIVPN${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    DATE=$(date +%Y%m%d-%H%M%S)
    DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    IP=$(get_ip)
    DOMAIN_SAFE=$(echo "$DOMAIN" | sed 's/\./_/g')
    
    # Format nama file: domain.tanggal.zip
    FILENAME="${DOMAIN_SAFE}.${DATE}.zip"
    BACKUP_PATH="$BACKUP_DIR/$FILENAME"
    
    echo "Membuat backup..."
    
    # Backup file penting
    zip -r "$BACKUP_PATH" \
        /etc/zivpn/users.db \
        /etc/zivpn/config.json \
        /etc/zivpn/domain.conf \
        /etc/zivpn/zivpn.crt \
        /etc/zivpn/zivpn.key \
        /etc/zivpn/telegram.conf \
        /root/.config/rclone/rclone.conf 2>/dev/null
    
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        USER_COUNT=$(wc -l < "$DB" 2>/dev/null || echo "0")
        
        echo -e "${GREEN}✓ Backup berhasil: $FILENAME ($SIZE)${NC}"
        echo ""
        
        # Caption untuk Telegram
        CAPTION="✅ *Auto Backup ZIVPN* 
══════════════════════
Waktu : $DISPLAY_DATE
IP    : $IP
Domain: $DOMAIN
User  : $USER_COUNT user
Size  : $SIZE"
        
        # Kirim ke Telegram
        echo "Mengirim ke Telegram..."
        send_file_telegram "$BACKUP_PATH" "$CAPTION"
        echo -e "${GREEN}✓ Terkirim ke Telegram${NC}"
        
        # Upload ke Google Drive jika rclone terkonfigurasi
        if rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
            echo "Mengupload ke Google Drive..."
            rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" --progress
            
            # Dapatkan link share
            GDRIVE_LINK=$(rclone link "gdrive:ZIVPN-Backup/$FILENAME" 2>/dev/null)
            
            if [ -n "$GDRIVE_LINK" ]; then
                echo -e "${GREEN}✓ Terupload ke Google Drive${NC}"
                
                # Kirim link ke Telegram
                send_telegram "☁️ *Google Drive Link*
🔗 $GDRIVE_LINK"
            fi
        fi
        
        echo ""
        echo -e "${WHITE}══════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ BACKUP BERHASIL!${NC}"
        echo -e "${WHITE}══════════════════════════════════════════${NC}"
        echo -e "  File    : ${CYAN}$FILENAME${NC}"
        echo -e "  Ukuran  : ${YELLOW}$SIZE${NC}"
        echo -e "  User    : ${GREEN}$USER_COUNT${NC}"
        echo -e "  Waktu   : ${YELLOW}$DISPLAY_DATE${NC}"
        echo -e "${WHITE}══════════════════════════════════════════${NC}"
        
    else
        echo -e "${RED}✗ Backup gagal${NC}"
    fi
    
    echo ""
    press_enter
}

# === RESTORE DARI LINK ===
restore_from_link() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}      RESTORE DARI LINK URL${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    read -rp "Masukkan URL file backup: " URL
    
    if [ -z "$URL" ]; then
        echo "URL kosong!"
        sleep 2
        return
    fi
    
    FILENAME=$(basename "$URL")
    DOWNLOAD_PATH="/tmp/$FILENAME"
    
    echo "Mengunduh file..."
    wget -q --show-progress "$URL" -O "$DOWNLOAD_PATH"
    
    if [ ! -f "$DOWNLOAD_PATH" ]; then
        echo -e "${RED}✗ Download gagal${NC}"
        sleep 2
        return
    fi
    
    echo "Menghentikan service..."
    systemctl stop zivpn.service
    
    echo "Ekstrak file..."
    unzip -o "$DOWNLOAD_PATH" -d /tmp/restore/ >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
        cp -rf /tmp/restore/root/.config/rclone/rclone.conf /root/.config/rclone/ 2>/dev/null
        rm -rf /tmp/restore
        
        # Update domain variable
        DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")
        
        systemctl start zivpn.service
        
        echo -e "${GREEN}✓ Restore berhasil${NC}"
        send_telegram "🔄 *Restore dari Link*
🔗 $URL
✅ Selesai"
    else
        echo -e "${RED}✗ Restore gagal${NC}"
        systemctl start zivpn.service
    fi
    
    rm -f "$DOWNLOAD_PATH"
    echo ""
    press_enter
}

# === RESTORE DARI GOOGLE DRIVE ===
restore_from_drive() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}   RESTORE DARI GOOGLE DRIVE${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    if ! rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
        echo -e "${RED}Google Drive belum terkonfigurasi${NC}"
        read -rp "Konfigurasi sekarang? (y/n): " config
        if [[ "$config" == "y" ]]; then
            rclone_setup
        fi
        return
    fi
    
    echo "Daftar backup di Google Drive:"
    echo "----------------------------------"
    rclone ls "gdrive:ZIVPN-Backup"
    echo "----------------------------------"
    read -rp "Masukkan nama file backup: " FILE
    
    if [ -z "$FILE" ]; then
        return
    fi
    
    echo "Mendownload dari Google Drive..."
    rclone copy "gdrive:ZIVPN-Backup/$FILE" /tmp/ --progress
    
    if [ ! -f "/tmp/$FILE" ]; then
        echo -e "${RED}✗ Download gagal${NC}"
        sleep 2
        return
    fi
    
    echo "Menghentikan service..."
    systemctl stop zivpn.service
    
    unzip -o "/tmp/$FILE" -d /tmp/restore/ >/dev/null 2>&1
    cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
    rm -rf /tmp/restore "/tmp/$FILE"
    
    # Update domain variable
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")
    
    systemctl start zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil${NC}"
    send_telegram "🔄 *Restore dari Google Drive*
📁 File: $FILE
✅ Selesai"
    
    echo ""
    press_enter
}

# === RESTORE DARI TELEGRAM ===
restore_from_telegram() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}    RESTORE DARI TELEGRAM${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    echo "Cara dapat file path:"
    echo "1. Buka chat dengan bot"
    echo "2. Cari pesan backup sebelumnya"
    echo "3. File path ada di pesan (contoh: documents/file_123.zip)"
    echo ""
    read -rp "Masukkan File Path: " FILE_PATH
    
    if [ -z "$FILE_PATH" ]; then
        return
    fi
    
    echo "Mendownload dari Telegram..."
    wget -q --show-progress "https://api.telegram.org/file/bot$BOT_TOKEN/$FILE_PATH" -O /tmp/telegram-backup.zip
    
    if [ ! -f "/tmp/telegram-backup.zip" ]; then
        echo -e "${RED}✗ Download gagal${NC}"
        sleep 2
        return
    fi
    
    echo "Menghentikan service..."
    systemctl stop zivpn.service
    
    unzip -o /tmp/telegram-backup.zip -d /tmp/restore/ >/dev/null 2>&1
    cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
    rm -rf /tmp/restore /tmp/telegram-backup.zip
    
    # Update domain variable
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")
    
    systemctl start zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil${NC}"
    send_telegram "🔄 *Restore dari Telegram*
📁 File Path: $FILE_PATH
✅ Selesai"
    
    echo ""
    press_enter
}

# === RESTORE DARI FILE LOKAL ===
restore_from_local() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}    RESTORE DARI FILE LOKAL${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    echo "File backup di $BACKUP_DIR:"
    echo "----------------------------------"
    ls -lh "$BACKUP_DIR" | grep .zip
    echo "----------------------------------"
    
    read -rp "Masukkan nama file: " FILE
    
    if [ ! -f "$BACKUP_DIR/$FILE" ]; then
        echo -e "${RED}File tidak ditemukan${NC}"
        sleep 2
        return
    fi
    
    echo "Menghentikan service..."
    systemctl stop zivpn.service
    
    unzip -o "$BACKUP_DIR/$FILE" -d /tmp/restore/ >/dev/null 2>&1
    cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
    rm -rf /tmp/restore
    
    # Update domain variable
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")
    
    systemctl start zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil${NC}"
    
    echo ""
    press_enter
}

# === BACKUP MENU ===
backup_menu() {
    while true; do
        clear
        echo -e "${CYAN}══════════════════════════════════════${NC}"
        echo -e "${WHITE}       BACKUP & RESTORE MENU${NC}"
        echo -e "${CYAN}══════════════════════════════════════${NC}"
        echo -e "${YELLOW} 1${NC}) Backup Sekarang (Telegram + GDrive)"
        echo -e "${YELLOW} 2${NC}) Restore dari Google Drive"
        echo -e "${YELLOW} 3${NC}) Restore dari Link URL"
        echo -e "${YELLOW} 4${NC}) Restore dari Telegram"
        echo -e "${YELLOW} 5${NC}) Restore dari File Lokal"
        echo -e "${YELLOW} 6${NC}) Setup Google Drive (rclone)"
        echo -e "${YELLOW} 7${NC}) Lihat Daftar Backup"
        echo -e "${RED} 0${NC}) Kembali"
        echo -e "${CYAN}══════════════════════════════════════${NC}"
        read -rp " Pilih Menu : " bk_opt
        
        case $bk_opt in
            1) backup_zivpn ;;
            2) restore_from_drive ;;
            3) restore_from_link ;;
            4) restore_from_telegram ;;
            5) restore_from_local ;;
            6) rclone_setup ;;
            7) ls -lh "$BACKUP_DIR"; echo ""; press_enter ;;
            0) break ;;
            *) echo "Pilihan tidak valid"; sleep 1 ;;
        esac
    done
}

# === AUTO BACKUP SETTING ===
auto_backup_setting() {
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}       AUTO BACKUP SETTING${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo ""
    
    # Cek cron yang ada
    if crontab -l 2>/dev/null | grep -q "zivpn-menu.*--autobackup"; then
        CURRENT=$(crontab -l | grep "zivpn-menu.*--autobackup" | awk '{print "Jam " $2 ":00"}' | head -1)
        echo -e "${GREEN}Status: AKTIF${NC}"
        echo -e "Jadwal: ${YELLOW}$CURRENT${NC}"
        echo ""
        echo "1) Nonaktifkan Auto Backup"
        echo "2) Ubah Jadwal"
        echo "3) Kembali"
        read -rp "Pilih: " auto_opt
        
        case $auto_opt in
            1)
                crontab -l | grep -v "zivpn-menu.*--autobackup" | crontab -
                echo "Auto Backup dinonaktifkan"
                sleep 2
                ;;
            2)
                set_autobackup_time
                ;;
        esac
    else
        echo -e "${RED}Status: NONAKTIF${NC}"
        echo ""
        echo "1) Aktifkan Auto Backup (Jam 03:00)"
        echo "2) Set Jadwal Manual"
        echo "3) Kembali"
        read -rp "Pilih: " auto_opt
        
        case $auto_opt in
            1)
                (crontab -l 2>/dev/null; echo "0 3 * * * /root/zivpn-menu --autobackup") | crontab -
                echo "Auto Backup diaktifkan (Jam 03:00)"
                sleep 2
                ;;
            2)
                set_autobackup_time
                ;;
        esac
    fi
}

# === SET AUTO BACKUP TIME ===
set_autobackup_time() {
    read -rp "Masukkan Jam (0-23): " HOUR
    if [[ "$HOUR" =~ ^[0-9]+$ ]] && [ "$HOUR" -ge 0 ] && [ "$HOUR" -le 23 ]; then
        crontab -l | grep -v "zivpn-menu.*--autobackup" | crontab -
        (crontab -l 2>/dev/null; echo "0 $HOUR * * * /root/zivpn-menu --autobackup") | crontab -
        echo "Auto Backup diset ke Jam $HOUR:00"
    else
        echo "Jam tidak valid"
    fi
    sleep 2
}

# === INSTALL ===

install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN UDP SERVER ]${NC}"
    echo ""

    if is_installed; then
        echo -e "${YELLOW}[!] ZIVPN UDP sudah terinstall!${NC}"
        press_enter
        return
    fi

    echo -e "${BLUE}[1/6]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron tar net-tools dnsutils jq zip unzip > /dev/null 2>&1
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
    touch "$DB"
    echo "-" > "$DOMAIN_FILE"
    
    # Buat config awal
    cat > "$CONFIG" <<EOF
{
  "listen": ":5667",
  "cert": "$CERT_FILE",
  "key": "$KEY_FILE",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": ["zivpn"]
  }
}
EOF
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
ExecStart=$ZIVPN_BIN server -c $CONFIG
Restart=always
RestartSec=3

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

    # Setup cron untuk auto-hapus expired user
    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
DB="/etc/zivpn/users.db"
CONFIG="/etc/zivpn/config.json"
CERT_FILE="/etc/zivpn/zivpn.crt"
KEY_FILE="/etc/zivpn/zivpn.key"

TODAY=$(date +%Y-%m-%d)
TMPFILE=$(mktemp)

while IFS='|' read -r user pass expiry limit; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        continue
    else
        echo "$user|$pass|$expiry|$limit" >> "$TMPFILE"
    fi
done < "$DB"

mv "$TMPFILE" "$DB"

# Rebuild config
passwords=()
while IFS='|' read -r user pass expiry limit; do
    if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$TODAY" ]] || [[ "$expiry" == "$TODAY" ]]; then
        passwords+=("\"$pass\"")
    fi
done < "$DB"

if [[ ${#passwords[@]} -eq 0 ]]; then
    pass_list="\"zivpn\""
else
    pass_list=$(IFS=','; echo "${passwords[*]}")
fi

cat > "$CONFIG" <<EOF
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
CRONEOF
    chmod +x /usr/local/bin/zivpn-cron.sh
    
    (crontab -l 2>/dev/null; echo "0 0 * * * /usr/local/bin/zivpn-cron.sh") | crontab -

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  IP      : ${CYAN}$(get_ip)${NC}"
    echo -e "  Domain  : ${CYAN}$(get_domain)${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "  Status  : ${GREEN}$(systemctl is-active zivpn.service)${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""

    # Pasang shortcut
    cp "$(realpath $0)" /usr/local/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/local/bin/zivpn-menu 2>/dev/null
    echo "alias zivpn='bash /usr/local/bin/zivpn-menu'" >> /root/.bashrc 2>/dev/null
    echo -e "${GREEN}  Tip: Ketik ${BOLD}zivpn${NC}${GREEN} kapanpun untuk buka menu ini${NC}"
    
    # Kirim notifikasi install
    send_telegram "✅ *ZIVPN INSTALLED*
══════════════════════
IP     : $(get_ip)
Domain : $DOMAIN
ISP    : $(get_isp)
Waktu  : $(date +"%d %B %Y %H:%M")"
    
    echo ""
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN ]${NC}"
    echo ""
    read -rp "$(echo -e "${RED}Yakin ingin uninstall? Semua data akan hilang! [y/N] : ${NC}")" confirm

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
    echo -e "${GREEN}Uninstall selesai!${NC}"
    
    send_telegram "❌ *ZIVPN UNINSTALL*\nIP: $(get_ip)"
    
    sleep 2
    exit 0
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}"
    echo ""

    local SCRIPT_URL="https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zoyyy.sh"
    local SCRIPT_PATH=$(realpath "$0")
    local tmp=$(mktemp)

    echo "Mengecek update..."
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
        echo -e "${YELLOW}Jalankan ulang script.${NC}"
        press_enter
        exec bash "$SCRIPT_PATH"
    fi

    press_enter
}

# === MENU UTAMA ===

main_menu() {
    while true; do
        banner

        if ! is_installed; then
            echo -e "${RED}  [!] ZIVPN belum terinstall!${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
            echo -e "  ${CYAN}2${NC}. Setting Telegram"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu : ${NC}")" choice
            case $choice in
                1) install_zivpn ;;
                2) telegram_setting ;;
                0) exit 0 ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        else
            echo -e "  ${GREEN}1${WHITE}. Tambah User (Default 2 digit)"
            echo -e "  ${GREEN}2${WHITE}. Tambah User (Custom Password)"
            echo -e "  ${RED}3${WHITE}. Hapus User"
            echo -e "  ${CYAN}4${WHITE}. Daftar User"
            echo -e "  ${YELLOW}5${WHITE}. Perpanjang User"
            echo -e "  ${PURPLE}6${WHITE}. Ubah Limit IP"
            echo -e "  ${MAGENTA}7${WHITE}. Cek User Online"
            echo -e "  ${BLUE}8${WHITE}. Hapus User Expired"
            echo ""
            echo -e "  ${YELLOW}9${WHITE}. Setting Domain"
            echo -e "  ${CYAN}10${WHITE}. Backup & Restore Menu"
            echo -e "  ${GREEN}11${WHITE}. Auto Backup Setting"
            echo -e "  ${BLUE}12${WHITE}. Setting Telegram"
            echo -e "  ${CYAN}13${WHITE}. Status Service"
            echo -e "  ${CYAN}14${WHITE}. Restart Service"
            echo -e "  ${GREEN}15${WHITE}. Update Script"
            echo -e "  ${RED}16${WHITE}. Uninstall ZIVPN"
            echo -e "  ${RED}0${WHITE}. Keluar"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu : ${NC}")" choice

            case $choice in
                1) create_account_default ;;
                2) create_account_custom ;;
                3) delete_user ;;
                4) list_users ;;
                5) renew_user ;;
                6) change_limit ;;
                7) check_online_users ;;
                8) clean_expired ;;
                9) set_domain ;;
                10) backup_menu ;;
                11) auto_backup_setting ;;
                12) telegram_setting ;;
                13) status_service ;;
                14) restart_service ;;
                15) update_script ;;
                16) uninstall_zivpn ;;
                0) exit 0 ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === AUTO BACKUP MODE ===
if [[ "$1" == "--autobackup" ]]; then
    # Load config
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "unknown")
    IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    DATE=$(date +%Y%m%d-%H%M%S)
    DOMAIN_SAFE=$(echo "$DOMAIN" | sed 's/\./_/g')
    FILENAME="${DOMAIN_SAFE}.${DATE}.zip"
    BACKUP_PATH="$BACKUP_DIR/$FILENAME"
    
    # Buat backup
    zip -r "$BACKUP_PATH" \
        /etc/zivpn/users.db \
        /etc/zivpn/config.json \
        /etc/zivpn/domain.conf \
        /etc/zivpn/zivpn.crt \
        /etc/zivpn/zivpn.key \
        /etc/zivpn/telegram.conf \
        /root/.config/rclone/rclone.conf 2>/dev/null
    
    # Kirim ke Telegram
    if [ -f "$TG_FILE" ]; then
        source "$TG_FILE"
        USER_COUNT=$(wc -l < "$DB" 2>/dev/null || echo "0")
        SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        
        CAPTION="✅ *Auto Backup ZIVPN* 
══════════════════════
Waktu : $DISPLAY_DATE
IP    : $IP
Domain: $DOMAIN
User  : $USER_COUNT user
Size  : $SIZE"
        
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$BACKUP_PATH" \
            -F caption="$CAPTION" \
            -F parse_mode="Markdown" > /dev/null
    fi
    
    # Upload ke Google Drive jika ada
    if command -v rclone >/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
        rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" >/dev/null 2>&1
        
        # Kirim link Google Drive
        if [ -f "$TG_FILE" ]; then
            GDRIVE_LINK=$(rclone link "gdrive:ZIVPN-Backup/$FILENAME" 2>/dev/null)
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d chat_id="$CHAT_ID" \
                --data-urlencode "text=☁️ *Google Drive Link*
🔗 $GDRIVE_LINK" \
                --data-urlencode "parse_mode=Markdown" >/dev/null
        fi
    fi
    
    # Hapus file backup lokal (hanya simpan di cloud)
    rm -f "$BACKUP_PATH"
    
    exit 0
fi

# === ENTRY POINT ===

check_root
main_menu
