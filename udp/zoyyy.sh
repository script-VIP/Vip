#!/bin/bash
# =============================================
#   ZIVPN UDP Manager
#   By: Custom Script (based on ZIVPN official binary)
#   OS: Ubuntu 20.04 / 22.04 / 24.04
# =============================================

# === KONFIGURASI BOT TELEGRAM (LANGSUNG AKTIF) ===
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
MAGENTA='\033[0;35m'
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
BACKUP_CONFIG="$ZIVPN_DIR/backup.conf"

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

set_domain() {
    banner
    echo -e "${BOLD}${YELLOW}[ SET DOMAIN ]${NC}"
    echo ""
    
    init_backup_config
    
    local current_domain="$DOMAIN"
    echo -e "  Domain saat ini: ${CYAN}${current_domain:-Belum diatur}${NC}"
    echo ""
    read -rp "$(echo -e "${WHITE}Masukkan domain baru (contoh: vpn.example.com) : ${NC}")" new_domain
    
    if [[ -z "$new_domain" ]]; then
        echo -e "${YELLOW}Domain tidak diubah.${NC}"
    else
        DOMAIN="$new_domain"
        save_backup_config
        echo -e "${GREEN}Domain berhasil diubah menjadi: ${CYAN}$new_domain${NC}"
    fi
    
    echo ""
    press_enter
}

get_domain() {
    local ip=$(get_ip)
    local domain=""
    domain=$(dig +short -x "$ip" 2>/dev/null | head -n1 | sed 's/\.$//')
    if [[ -z "$domain" ]]; then
        domain="$ip"
    fi
    echo "$domain"
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
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]
}

# === FUNGSI TELEGRAM ===

send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="HTML" > /dev/null 2>&1
}

send_telegram_file() {
    local file="$1"
    local caption="$2"
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
        local domain=$(get_domain)
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

# === FUNGSI USER DB DENGAN LIMIT IP ===
# Format users.db: PASSWORD|EXPIRED|LIMIT_IP
# Contoh: akuganteng123|2025-06-30|3

load_users() {
    if [[ ! -f "$USERS_DB" ]]; then
        touch "$USERS_DB"
    fi
}

user_exists() {
    local password="$1"
    grep -q "^$password|" "$USERS_DB" 2>/dev/null
}

get_user_expiry() {
    local password="$1"
    grep "^$password|" "$USERS_DB" | cut -d'|' -f2
}

get_user_limit() {
    local password="$1"
    grep "^$password|" "$USERS_DB" | cut -d'|' -f3
}

update_config_json() {
    # Ambil semua password dari users.db yang belum expired
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r pass expiry limit; do
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

# === FUNGSI BACKUP ===

setup_auto_backup() {
    # Hapus cron auto backup yang lama
    crontab -l 2>/dev/null | grep -v "zivpn-auto-backup" | crontab -
    
    # Buat script auto backup
    cat > /usr/local/bin/zivpn-auto-backup.sh <<'EOF'
#!/bin/bash
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
USERS_DB="$ZIVPN_DIR/users.db"
CONFIG_FILE="$ZIVPN_DIR/config.json"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"

# Konfigurasi Telegram
BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
CHAT_ID="6198984094"

# Fungsi kirim ke Telegram
send_telegram_file() {
    local file="$1"
    local caption="$2"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" > /dev/null 2>&1
}

# Ambil info server
IP_ADDRESS=$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
DOMAIN_NAME=$(dig +short -x "$IP_ADDRESS" 2>/dev/null | head -n1 | sed 's/\.$//')
[ -z "$DOMAIN_NAME" ] && DOMAIN_NAME="$IP_ADDRESS"
ISP_NAME=$(curl -s ipinfo.io/org 2>/dev/null | cut -d' ' -f2- || echo "Unknown")
CITY_NAME=$(curl -s ipinfo.io/city 2>/dev/null || echo "Unknown")
DATE_NOW=$(date +"%Y-%m-%d %H:%M:%S")
FILE_DATE=$(date +"%Y%m%d-%H%M%S")

# Buat direktori backup
mkdir -p "$BACKUP_DIR"

# Buat file backup
BACKUP_FILE="$BACKUP_DIR/zivpn-backup-$FILE_DATE.tar.gz"
tar -czf "$BACKUP_FILE" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null

# Hitung jumlah user
if [ -f "$USERS_DB" ]; then
    USER_COUNT=$(wc -l < "$USERS_DB")
else
    USER_COUNT=0
fi

# Hitung ukuran file
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

# Buat caption
CAPTION="✅ <b>AUTO BACKUP ZIVPN</b>
══════════════════════════════════════════
<b>Waktu Backup :</b> $DATE_NOW
<b>IP Address   :</b> $IP_ADDRESS
<b>Domain       :</b> $DOMAIN_NAME
<b>ISP          :</b> $ISP_NAME
<b>Lokasi       :</b> $CITY_NAME
<b>Jumlah User  :</b> $USER_COUNT User
<b>Ukuran File  :</b> $FILE_SIZE
<b>Nama File    :</b> $(basename $BACKUP_FILE)
══════════════════════════════════════════
Auto backup dijalankan setiap 6 jam"

# Kirim ke Telegram
send_telegram_file "$BACKUP_FILE" "$CAPTION"

# Hapus backup lama (simpan 7 backup terakhir)
cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
EOF

    chmod +x /usr/local/bin/zivpn-auto-backup.sh
    
    # Setup cron setiap 6 jam
    (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/zivpn-auto-backup.sh") | crontab -
    
    echo -e "${GREEN}Auto backup diatur setiap 6 jam dengan info lengkap IP, Domain, dan Tanggal${NC}"
}

backup_now() {
    banner
    echo -e "${BOLD}${YELLOW}[ BACKUP MANUAL ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    # Ambil info server
    local ip=$(get_ip)
    local domain=$(get_domain)
    local isp=$(get_isp)
    local city=$(get_city)
    local date_now=$(date +"%Y-%m-%d %H:%M:%S")
    local file_date=$(date +"%Y%m%d-%H%M%S")
    
    # Buat file backup
    local backup_file="$BACKUP_DIR/zivpn-backup-$file_date.tar.gz"
    echo -e "${BLUE}[1/2]${NC} Membuat file backup..."
    tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    # Hitung jumlah user
    local user_count=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    local file_size=$(du -h "$backup_file" | cut -f1)
    
    echo -e "${GREEN}    ✓ Backup berhasil dibuat: $(basename $backup_file)${NC}"
    echo -e "${BLUE}[2/2]${NC} Mengirim ke Telegram..."
    
    # Buat caption
    local caption="✅ <b>BACKUP MANUAL ZIVPN</b>
══════════════════════════════════════════
<b>Waktu Backup :</b> $date_now
<b>IP Address   :</b> $ip
<b>Domain       :</b> $domain
<b>ISP          :</b> $isp
<b>Lokasi       :</b> $city
<b>Jumlah User  :</b> $user_count User
<b>Ukuran File  :</b> $file_size
<b>Nama File    :</b> $(basename $backup_file)
══════════════════════════════════════════"
    
    send_telegram_file "$backup_file" "$caption"
    
    echo -e "${GREEN}    ✓ Backup terkirim ke Telegram${NC}"
    
    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ BACKUP BERHASIL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  File    : ${CYAN}$(basename $backup_file)${NC}"
    echo -e "  Ukuran  : ${YELLOW}$file_size${NC}"
    echo -e "  User    : ${GREEN}$user_count${NC}"
    echo -e "  Waktu   : ${YELLOW}$date_now${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    # Hapus backup lama (simpan 7 backup terakhir)
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
    
    echo ""
    press_enter
}

# === FUNGSI CEK USER ONLINE ===

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
    while IFS='|' read -r pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            [[ "$limit" == "0" ]] && disp="Unlimited" || disp="$limit Device"
            echo -e "  ${GREEN}✓${NC} $pass (Limit: $disp)"
            ((active++))
        fi
    done < "$USERS_DB" 2>/dev/null
    
    echo ""
    echo -e "  ${WHITE}Total User Aktif: ${GREEN}$active${NC}"
    echo "────────────────────────────────────────"
    
    press_enter
}

# === TAMBAH USER (USERNAME/PASSWORD DIGABUNG, LIMIT IP, EXPIRED) ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users

    read -rp "$(echo -e "${WHITE}Username/Password : ${NC}")" base_password
    if [[ -z "$base_password" ]]; then
        echo -e "${RED}[!] Nama/katakunci tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    # Generate 3 digit angka random
    random_num=$((RANDOM % 900 + 100))
    password="${base_password}${random_num}"

    # Cek apakah password sudah digunakan
    if user_exists "$password"; then
        echo -e "${YELLOW}[!] Password '$password' sudah digunakan, generate ulang...${NC}"
        while user_exists "$password"; do
            random_num=$((RANDOM % 900 + 100))
            password="${base_password}${random_num}"
        done
        echo -e "${GREEN}    ✓ Password baru: $password${NC}"
    fi

    read -rp "$(echo -e "${WHITE}Limit IP : ${NC}")" limit_ip
    if ! [[ "$limit_ip" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Expired (hari)    : ${NC}")" days
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    # Hitung tanggal expired
    if [[ "$days" -eq 0 ]]; then
        expiry="unlimited"
        expe="Unlimited"
        masa_aktif="Selamanya"
        limit_display="Unlimited"
    else
        expiry=$(date -d "+$days days" +%Y-%m-%d)
        tgl=$(date -d "+$days days" +"%d")
        bln=$(date -d "+$days days" +"%b")
        thn=$(date -d "+$days days" +"%Y")
        expe="$tgl $bln, $thn"
        masa_aktif="$days hari"
        [[ "$limit_ip" -eq 0 ]] && limit_display="Unlimited" || limit_display="$limit_ip Device"
    fi

    # Tanggal hari ini
    tgl2=$(date +"%d")
    bln2=$(date +"%b")
    thn2=$(date +"%Y")
    tnggl="$tgl2 $bln2, $thn2"

    # Simpan ke database (password|expiry|limit)
    echo "$password|$expiry|$limit_ip" >> "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}ZIVPN UDP${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"

    if [[ -n "$DOMAIN" ]]; then
        echo -e "  Domain      : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  Domain      : ${RED}Belum diatur${NC}"
        echo -e "  IP Server   : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "  Password    : ${YELLOW}$password${NC}"
    echo -e "  Limit IP    : ${MAGENTA}$limit_display${NC}"
    echo -e "  Sarver      : ${CYAN}$(get_city)${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  Tanggal Buat: ${GREEN}$tnggl${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$expe${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$masa_aktif${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. klik negaranya bebas ( Sg premium 5 )"
    echo -e "  4. Klik Garis tiga ( dipojok kiri atas )"
    echo -e "  5. Klik Udp tunnel setting"

    if [[ -n "$DOMAIN" ]]; then
        echo -e "  6. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  6. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$password${NC}"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    # Kirim notifikasi ke Telegram
    send_telegram "✅ USER BARU
══════════════════════
Password : $password
Limit IP : $limit_display
Expired  : $expe
Server   : $(get_domain)"
    
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

    list_users_simple
    echo ""
    read -rp "$(echo -e "${WHITE}Password user yang ingin dihapus : ${NC}")" password

    if ! user_exists "$password"; then
        echo -e "${RED}[!] Password '$password' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${RED}Yakin hapus user dengan password '$password'? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$password|/d" "$USERS_DB"
        update_config_json
        echo -e "${GREEN}  ✓ User dengan password '$password' berhasil dihapus!${NC}"
        send_telegram "🗑 USER DIHAPUS\nPassword: $password"
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi

    press_enter
}

# === LIST USER ===

list_users_simple() {
    echo -e "${WHITE}Daftar password user:${NC}"
    local i=1
    while IFS='|' read -r pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$USERS_DB"
}

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
    printf "${WHITE}%-20s %-15s %-10s %-10s${NC}\n" "PASSWORD" "EXPIRED" "LIMIT" "STATUS"
    echo -e "${WHITE}─────────────────────────────────────────────────────────${NC}"

    while IFS='|' read -r pass expiry limit; do
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
    done < "$USERS_DB"

    echo -e "${WHITE}─────────────────────────────────────────────────────────${NC}"
    
    local total=$(wc -l < "$USERS_DB")
    echo -e "  Total User: ${GREEN}$total${NC}"
    
    press_enter
}

# === PERPANJANG USER ===

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

    list_users_simple
    echo ""
    read -rp "$(echo -e "${WHITE}Password user : ${NC}")" password

    if ! user_exists "$password"; then
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

    local old_expiry=$(get_user_expiry "$password")
    local limit=$(get_user_limit "$password")

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

    sed -i "s/^$password|$old_expiry|$limit/$password|$new_expiry|$limit/" "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User dengan password '$password' berhasil diperpanjang!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  Expired baru : ${YELLOW}$exp_display${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    send_telegram "🔄 USER DIPERPANJANG\nPassword: $password\nExpired: $exp_display"
    
    echo ""
    press_enter
}

# === UBAH LIMIT IP ===

change_limit() {
    banner
    echo -e "${BOLD}${YELLOW}[ UBAH LIMIT IP ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}[!] Belum ada user yang terdaftar.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar user dengan limit saat ini:${NC}"
    local i=1
    while IFS='|' read -r pass expiry limit; do
        [[ "$limit" == "0" ]] && disp="Unlimited" || disp="$limit Device"
        echo -e "  ${CYAN}$i.${NC} $pass - Limit: ${YELLOW}$disp${NC}"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user yang akan diubah limitnya : ${NC}")" password

    if ! user_exists "$password"; then
        echo -e "${RED}[!] Password '$password' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    local expiry=$(get_user_expiry "$password")

    read -rp "$(echo -e "${WHITE}Limit IP baru (0=unlimited) : ${NC}")" new_limit
    if ! [[ "$new_limit" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    sed -i "s/^$password|$expiry|.*/$password|$expiry|$new_limit/" "$USERS_DB"
    update_config_json

    [[ "$new_limit" == "0" ]] && disp="Unlimited" || disp="$new_limit Device"
    echo ""
    echo -e "${GREEN}  ✓ Limit IP untuk '$password' berhasil diubah menjadi $disp${NC}"
    
    press_enter
}

# === HAPUS USER EXPIRED ===

clean_expired() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER EXPIRED ]${NC}"
    echo ""
    load_users

    local today=$(date +%Y-%m-%d)
    local count=0
    local tmpfile=$(mktemp)
    local deleted_users=""

    while IFS='|' read -r pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass (expired: $expiry)"
            ((count++))
            deleted_users="$deleted_users\n- $pass"
        else
            echo "$pass|$expiry|$limit" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}  ✓ $count user expired berhasil dihapus!${NC}"
        send_telegram "🧹 CLEAN EXPIRED\n$count user expired dihapus:$deleted_users"
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
        send_telegram "🔄 SERVICE RESTART\nService ZIVPN UDP direstart"
    else
        echo -e "${RED}  ✗ Service gagal restart!${NC}"
    fi
    echo ""
    press_enter
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
    apt-get install -y wget curl openssl iptables ufw cron tar net-tools dnsutils > /dev/null 2>&1
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
    setup_auto_backup

    # Setup cron untuk auto-hapus expired user
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
TMPFILE=$(mktemp)

while IFS='|' read -r pass expiry limit; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        continue
    else
        echo "$pass|$expiry|$limit" >> "$TMPFILE"
    fi
done < "$USERS_DB"

mv "$TMPFILE" "$USERS_DB"

# Rebuild config
passwords=()
while IFS='|' read -r pass expiry limit; do
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
CRONEOF
    chmod +x /usr/local/bin/zivpn-cron.sh

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
    send_telegram "✅ ZIVPN INSTALLED
══════════════════════
IP     : $(get_ip)
Domain : $(get_domain)
ISP    : $(get_isp)
Waktu  : $(date +"%d %B %Y %H:%M")"
    
    echo ""
    press_enter
}

# === RESTORE BACKUP ===

restore_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Tidak ada file backup ditemukan.${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}Daftar backup tersedia:${NC}"
    local i=1
    local backups=()
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(basename "$backup" | sed 's/zivpn-backup-//; s/.tar.gz//' | sed 's/-/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        backups+=("$backup")
        ((i++))
    done
    
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih nomor backup [0=batal] : ${NC}")" choice
    
    if [[ "$choice" -eq 0 ]]; then
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
        
        # Kirim notifikasi
        send_telegram "✅ RESTORE BACKUP\nFile: $(basename "$selected")"
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
    rm -f /usr/local/bin/zivpn-auto-backup.sh
    sed -i "/alias zivpn=/d" /root/.bashrc 2>/dev/null
    rm -rf "$ZIVPN_DIR"

    systemctl daemon-reload

    echo "Menghapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -

    echo ""
    echo -e "${GREEN}Uninstall selesai!${NC}"
    
    send_telegram "❌ ZIVPN UNINSTALL\nIP: $(get_ip)"
    
    sleep 2
    exit 0
}

# === MENU UTAMA ===

main_menu() {
    while true; do
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
            echo -e "  ${GREEN}1${WHITE}. Tambah User"
            echo -e "  ${RED}2${WHITE}. Hapus User"
            echo -e "  ${CYAN}3${WHITE}. Daftar User"
            echo -e "  ${YELLOW}4${WHITE}. Perpanjang User"
            echo -e "  ${GREEN}5${WHITE}. Setting Domain"
            echo -e "  ${PURPLE}6${WHITE}. Ubah Limit IP"
            echo ""
            echo -e "  ${MAGENTA}7${WHITE}. Cek User Online"
            echo -e "  ${BLUE}8${WHITE}. Hapus User Expired"
            echo -e "  ${BLUE}9${WHITE}. Status Service"
            echo -e "  ${BLUE}10${WHITE}. Restart Service"
            
            echo -e "  ${GREEN}11${WHITE}. Backup Manual"
            echo -e "  ${YELLOW}12${WHITE}. Restore Backup"
            
            echo -e "  ${CYAN}13${WHITE}. Update Script"
            echo -e "  ${RED}14${WHITE}. Uninstall ZIVPN"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [1-14] : ${NC}")" choice

            case $choice in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) set_domain ;;
                6) change_limit ;;
                7) check_online_users ;;
                8) clean_expired ;;
                9) status_service ;;
                10) restart_service ;;
                11) backup_now ;;
                12) restore_backup ;;
                13) update_script ;;
                14) uninstall_zivpn ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; menu ;;
            esac
        fi
    done
}

# === ENTRY POINT ===

check_root
main_menu
