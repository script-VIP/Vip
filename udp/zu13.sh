#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - FULL FIXED VERSION
#   By: Custom Script
#   OS: Ubuntu 20.04/22.04/24.04
# =============================================

# === PATH ===
ZIVPN_DIR="/etc/zivpn"
USERS_DB_JSON="$ZIVPN_DIR/users.db.json"
CONFIG_FILE="$ZIVPN_DIR/config.json"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"

# === WARNA ===
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'
PURPLE='\033[0;35m'; NC='\033[0m'

# === FUNGSI GET IP ===
get_ip() {
    local ip=""
    if command -v curl &> /dev/null; then
        ip=$(curl -4 -s --connect-timeout 2 ifconfig.me 2>/dev/null)
        [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 2 icanhazip.com 2>/dev/null)
        [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 2 api.ipify.org 2>/dev/null)
    fi
    [ -z "$ip" ] && ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

# === FUNGSI GET INFO VPS ===
get_vps_info() {
    IP=$(get_ip)
    [ -f "$DOMAIN_FILE" ] && DOMAIN=$(cat "$DOMAIN_FILE") || DOMAIN="$IP"
    
    if command -v free &> /dev/null; then
        RAM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
        RAM_USED=$(free -m | grep Mem | awk '{print $3}')
        RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))
        RAM_INFO="${RAM_USED}MB/${RAM_TOTAL}MB (${RAM_PERCENT}%)"
    else
        RAM_INFO="N/A"
    fi
    
    if [ -f "$USERS_DB_JSON" ]; then
        TOTAL_AKUN=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    else
        TOTAL_AKUN="0"
        echo "[]" > "$USERS_DB_JSON"
    fi
    
    if systemctl is-active --quiet zivpn.service 2>/dev/null; then
        SERVICE_STATUS="${GREEN}Running${NC}"
    else
        SERVICE_STATUS="${RED}Stopped${NC}"
    fi
}

# === FUNGSI TAMPILAN HEADER ===
show_header() {
    get_vps_info
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              ZIVPN UDP MANAGER - FULL FIXED                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}🌍 Public IP    :${NC} ${GREEN}$IP${NC}"
    echo -e "  ${WHITE}📌 Domain       :${NC} ${YELLOW}$DOMAIN${NC}"
    echo -e "  ${WHITE}💾 RAM Usage    :${NC} ${CYAN}$RAM_INFO${NC}"
    echo -e "  ${WHITE}📊 Total Akun   :${NC} ${PURPLE}$TOTAL_AKUN${NC}"
    echo -e "  ${WHITE}⚙️  Service      :${NC} $SERVICE_STATUS"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# === FUNGSI TAMPILAN MENU ===
show_menu() {
    echo -e "  ${YELLOW}[01]${NC} ➕  Tambah Akun Reguler"
    echo -e "  ${YELLOW}[02]${NC} ⏳  Tambah Akun Trial"
    echo -e "  ${YELLOW}[03]${NC} 📋  Lihat Daftar Akun"
    echo -e "  ${YELLOW}[04]${NC} 🗑️  Hapus Akun"
    echo -e "  ${YELLOW}[05]${NC} 📅  Edit Masa Aktif"
    echo -e "  ${YELLOW}[06]${NC} 🔑  Edit Password"
    echo -e "  ${YELLOW}[07]${NC} 👥  Cek User Online"
    echo -e "  ${YELLOW}[08]${NC} 💾  Backup & Restore"
    echo -e "  ${YELLOW}[09]${NC} 🌐  Change Domain"
    echo -e "  ${YELLOW}[10]${NC} 🔄  Restart Service"
    echo -e "  ${YELLOW}[11]${NC} ⚙️  Install Ulang"
    echo -e "  ${YELLOW}[12]${NC} ❌  Uninstall"
    echo -e "  ${YELLOW}[00]${NC} 🚪  Exit"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# === FUNGSI GENERATE PASSWORD ===
generate_password() { printf "%02d" $((RANDOM % 100)); }

# === FUNGSI SYNC CONFIG ===
sync_config() {
    [ ! -f "$USERS_DB_JSON" ] && echo "[]" > "$USERS_DB_JSON"
    systemctl restart zivpn.service 2>/dev/null
}

# === FUNGSI SEND NOTIF TELEGRAM ===
send_notification() {
    local message="$1"
    [ -f "$BOT_CONFIG" ] && source "$BOT_CONFIG"
    [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ] && 
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
         -d "chat_id=${CHAT_ID}" -d "text=${message}" -d "parse_mode=HTML" > /dev/null
}

# === FUNGSI TAMBAH AKUN REGULER ===
add_account() {
    show_header
    echo -e "${YELLOW}»»» TAMBAH AKUN REGULER «««${NC}\n"
    
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="user${RANDOM_NUM}"
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter pakai default]: " password
    [ -z "$password" ] && password="$DEFAULT_PASS"
    
    read -p "Limit IP [default: 3]: " limit_ip
    [ -z "$limit_ip" ] && limit_ip=3
    
    read -p "Masa aktif (hari) [default: 30]: " duration
    [ -z "$duration" ] && duration=30
    
    username="user_${password}"
    expiry_timestamp=$(date -d "+$duration days" +%s)
    create_date=$(date +"%d %b, %Y")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y")
    
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || get_ip)
    
    jq --arg user "$username" --arg pass "$password" --argjson expiry "$expiry_timestamp" \
       --arg limit "$limit_ip" --arg created "$create_date" \
       '. += [{
           username: $user, password: $pass, expiry_timestamp: $expiry,
           limit_ip: $limit, created_date: $created
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" 2>/dev/null && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    clear
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Tanggal Buat:${NC} $create_date"
    echo -e "  ${WHITE}Tanggal Exp :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration hari"
    echo -e "  ${WHITE}Limit IP    :${NC} $limit_ip device"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    sync_config
    echo ""; read -p "Press Enter untuk kembali..."
}

# === FUNGSI TAMBAH TRIAL ===
add_trial() {
    show_header
    echo -e "${YELLOW}»»» TAMBAH AKUN TRIAL «««${NC}\n"
    
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="trial${RANDOM_NUM}"
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter pakai default]: " password
    [ -z "$password" ] && password="$DEFAULT_PASS"
    
    read -p "Masa aktif (menit) [default: 60]: " duration
    [ -z "$duration" ] && duration=60
    
    username="trial_${password}"
    expiry_timestamp=$(date -d "+$duration minutes" +%s)
    create_date=$(date +"%d %b, %Y %H:%M")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y %H:%M")
    
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || get_ip)
    
    jq --arg user "$username" --arg pass "$password" --argjson expiry "$expiry_timestamp" \
       '. += [{
           username: $user, password: $pass, expiry_timestamp: $expiry,
           limit_ip: "1", created_date: "'$create_date'"
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" 2>/dev/null && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    clear
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    ✓ TRIAL ACCOUNT${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Dibuat      :${NC} $create_date"
    echo -e "  ${WHITE}Expired     :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration menit"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    sync_config
    echo ""; read -p "Press Enter untuk kembali..."
}

# === FUNGSI LIST AKUN ===
list_accounts() {
    show_header
    echo -e "${YELLOW}»»» DAFTAR AKUN «««${NC}\n"
    
    [ ! -f "$USERS_DB_JSON" ] && echo "[]" > "$USERS_DB_JSON"
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun.${NC}"
    else
        printf "${BLUE}%-4s | %-12s | %-12s | %-10s${NC}\n" "No" "Password" "Expired" "Status"
        echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
        
        now=$(date +%s)
        for i in $(seq 0 $((TOTAL-1))); do
            password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
            expiry=$(jq -r ".[$i].expiry_timestamp" "$USERS_DB_JSON" 2>/dev/null)
            expiry_date=$(date -d "@$expiry" +"%Y-%m-%d" 2>/dev/null)
            remaining=$((expiry - now))
            
            if [ $remaining -le 0 ]; then status="${RED}EXPIRED${NC}"
            elif [ $((remaining / 86400)) -gt 0 ]; then status="${GREEN}$((remaining/86400))h${NC}"
            elif [ $((remaining / 3600)) -gt 0 ]; then status="${GREEN}$((remaining/3600))j${NC}"
            else status="${GREEN}$((remaining/60))m${NC}"
            fi
            
            printf "  %-2d  | %-12s | %-12s | %b\n" $((i+1)) "$password" "$expiry_date" "$status"
        done
    fi
    
    echo ""; read -p "Press Enter untuk kembali..."
}

# === FUNGSI HAPUS AKUN ===
delete_account() {
    show_header
    echo -e "${YELLOW}»»» HAPUS AKUN «««${NC}\n"
    
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}Belum ada akun${NC}"
        sleep 2
        return
    fi
    
    echo -e "${WHITE}Daftar Password:${NC}"
    for i in $(seq 0 $((TOTAL-1))); do
        password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
        echo "  $((i+1)). $password"
    done
    echo ""
    
    read -p "Masukkan password: " password
    [ -z "$password" ] && { echo -e "${RED}Password tidak boleh kosong${NC}"; sleep 2; return; }
    
    jq --arg pass "$password" 'del(.[] | select(.password == $pass))' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    echo -e "${GREEN}[✓] Akun dihapus${NC}"
    sync_config
    sleep 2
}

# === FUNGSI EDIT MASA AKTIF ===
edit_expiry() {
    show_header
    echo -e "${YELLOW}»»» EDIT MASA AKTIF «««${NC}\n"
    read -p "Password: " pass
    current=$(jq -r --arg p "$pass" '.[] | select(.password == $p) | .expiry_timestamp' "$USERS_DB_JSON" 2>/dev/null)
    [ -z "$current" ] && { echo -e "${RED}Password tidak ditemukan${NC}"; sleep 2; return; }
    echo -e "Expired saat ini: $(date -d "@$current" +"%d %b %Y")"
    read -p "Tambahan hari: " days
    [ -z "$days" ] && { echo "Batal"; sleep 2; return; }
    new=$((current + days * 86400))
    jq --arg p "$pass" --argjson n "$new" '(.[] | select(.password == $p) | .expiry_timestamp) = $n' "$USERS_DB_JSON" > tmp && mv tmp "$USERS_DB_JSON"
    echo -e "${GREEN}[✓] Diperpanjang $days hari${NC}"
    sync_config
    sleep 2
}

# === FUNGSI EDIT PASSWORD ===
edit_password() {
    show_header
    echo -e "${YELLOW}»»» EDIT PASSWORD «««${NC}\n"
    read -p "Password lama: " old
    jq -e --arg o "$old" '.[] | select(.password == $o)' "$USERS_DB_JSON" > /dev/null 2>&1 || { echo -e "${RED}Tidak ditemukan${NC}"; sleep 2; return; }
    read -p "Password baru: " new
    jq --arg o "$old" --arg n "$new" '(.[] | select(.password == $o) | .password) = $n' "$USERS_DB_JSON" > tmp && mv tmp "$USERS_DB_JSON"
    echo -e "${GREEN}[✓] Password diubah${NC}"
    sync_config
    sleep 2
}

# === FUNGSI CEK USER ONLINE ===
check_online() {
    show_header
    echo -e "${YELLOW}»»» USER ONLINE «««${NC}\n"
    if command -v netstat &> /dev/null; then
        netstat -an 2>/dev/null | grep ESTABLISHED | grep -E ":80|:443" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 || echo "Tidak ada koneksi"
    else
        echo "netstat tidak tersedia"
    fi
    echo ""; read -p "Press Enter..."
}

# === FUNGSI RESTART SERVICE ===
restart_service() {
    show_header
    echo -e "${YELLOW}»»» RESTART SERVICE «««${NC}\n"
    systemctl restart zivpn.service 2>/dev/null
    systemctl restart udp-custom.service 2>/dev/null
    echo -e "${GREEN}[✓] Service direstart${NC}"
    sleep 2
}

# === FUNGSI GANTI DOMAIN ===
change_domain() {
    show_header
    echo -e "${YELLOW}»»» GANTI DOMAIN «««${NC}\n"
    current=$(cat "$DOMAIN_FILE" 2>/dev/null || get_ip)
    echo -e "${WHITE}Domain saat ini:${NC} $current\n"
    read -p "Domain baru: " new_domain
    if [ -n "$new_domain" ]; then
        echo "$new_domain" > "$DOMAIN_FILE"
        echo -e "${GREEN}[✓] Domain diubah${NC}"
    else
        echo -e "${RED}[✗] Domain tidak boleh kosong${NC}"
    fi
    sleep 2
}

# === FUNGSI BACKUP CREATE ===
backup_create() {
    show_header
    echo -e "${YELLOW}»»» BUAT BACKUP «««${NC}\n"
    
    BACKUP_DIR="$ZIVPN_DIR/backup"
    mkdir -p "$BACKUP_DIR"
    
    DOMAIN_NAME=$(cat "$DOMAIN_FILE" 2>/dev/null | sed 's/\./_/g' || get_ip | sed 's/\./_/g')
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/${DOMAIN_NAME}.${DATE}.tar.gz"
    
    tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup: $(basename "$BACKUP_FILE")${NC}"
        # Kirim ke Telegram
        [ -f "$BOT_CONFIG" ] && source "$BOT_CONFIG"
        [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ] && 
        curl -s -F document=@"$BACKUP_FILE" \
             -F caption="✅ Backup ZIVPN - $(date +'%Y-%m-%d %H:%M:%S')" \
             "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}" > /dev/null
    else
        echo -e "${RED}[✗] Gagal backup${NC}"
    fi
    
    echo ""; read -p "Press Enter..."
}

# === FUNGSI BACKUP LIST ===
backup_list() {
    show_header
    echo -e "${YELLOW}»»» DAFTAR BACKUP «««${NC}\n"
    if [ -d "$ZIVPN_DIR/backup" ]; then
        ls -lh "$ZIVPN_DIR/backup/" | grep tar.gz || echo "Belum ada backup"
    else
        echo "Belum ada backup"
    fi
    echo ""; read -p "Press Enter..."
}

# === FUNGSI BACKUP RESTORE FILE ===
backup_restore() {
    show_header
    echo -e "${YELLOW}»»» RESTORE DARI FILE «««${NC}\n"
    
    [ ! -d "$ZIVPN_DIR/backup" ] && { echo "Belum ada backup"; sleep 2; return; }
    
    ls "$ZIVPN_DIR/backup/" | grep tar.gz | nl -w2 -s'. '
    echo ""
    read -p "Nama file: " filename
    
    [ ! -f "$ZIVPN_DIR/backup/$filename" ] && { echo "File tidak ditemukan"; sleep 2; return; }
    
    tar -xzf "$ZIVPN_DIR/backup/$filename" -C "$ZIVPN_DIR" 2>/dev/null
    echo -e "${GREEN}[✓] Restore selesai${NC}"
    systemctl restart zivpn.service 2>/dev/null
    sleep 2
}

# === FUNGSI RESTORE DARI LINK (FULLY FIXED) ===
restore_from_link() {
    show_header
    echo -e "${YELLOW}»»» RESTORE DARI LINK «««${NC}\n"
    read -p "URL backup: " backup_url
    
    [ -z "$backup_url" ] && { echo -e "${RED}[✗] URL kosong${NC}"; sleep 2; return; }
    
    TEMP_DIR="/tmp/zivpn_restore_$$"
    mkdir -p "$TEMP_DIR/extract"
    
    echo -e "${YELLOW}Mengunduh...${NC}"
    if ! wget -q --show-progress "$backup_url" -O "$TEMP_DIR/backup.file"; then
        echo -e "${RED}[✗] Gagal download${NC}"
        rm -rf "$TEMP_DIR"
        sleep 2
        return
    fi
    
    # Ekstrak file
    echo -e "${YELLOW}Mengekstrak...${NC}"
    if [[ "$backup_url" == *.zip ]]; then
        unzip -q "$TEMP_DIR/backup.file" -d "$TEMP_DIR/extract"
    else
        tar -xzf "$TEMP_DIR/backup.file" -C "$TEMP_DIR/extract" 2>/dev/null
    fi
    
    # Cari file users.db.json
    echo -e "${YELLOW}Mencari file konfigurasi...${NC}"
    CONFIG_PATH=""
    
    # Cari di berbagai lokasi
    POSSIBLE_PATHS=(
        "$TEMP_DIR/extract/users.db.json"
        "$TEMP_DIR/extract/etc/zivpn/users.db.json"
        "$TEMP_DIR/extract/root/zivpn/users.db.json"
        "$TEMP_DIR/extract/home/zivpn/users.db.json"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            CONFIG_PATH=$(dirname "$path")
            echo -e "${GREEN}[✓] File ditemukan di: $CONFIG_PATH${NC}"
            break
        fi
    done
    
    # Jika tidak ditemukan, cari dengan find
    if [ -z "$CONFIG_PATH" ]; then
        FOUND_FILE=$(find "$TEMP_DIR/extract" -type f -name "users.db.json" 2>/dev/null | head -1)
        if [ -n "$FOUND_FILE" ]; then
            CONFIG_PATH=$(dirname "$FOUND_FILE")
            echo -e "${GREEN}[✓] File ditemukan di: $CONFIG_PATH${NC}"
        fi
    fi
    
    # Jika masih tidak ditemukan
    if [ -z "$CONFIG_PATH" ]; then
        echo -e "${RED}[✗] File users.db.json tidak ditemukan!${NC}"
        echo -e "${YELLOW}Isi directory:${NC}"
        ls -la "$TEMP_DIR/extract" | head -20
        rm -rf "$TEMP_DIR"
        sleep 3
        return
    fi
    
    # Tampilkan info backup
    echo ""
    echo -e "${WHITE}Informasi Backup:${NC}"
    
    # Domain
    if [ -f "$CONFIG_PATH/domain.txt" ]; then
        BACKUP_DOMAIN=$(cat "$CONFIG_PATH/domain.txt")
        echo -e "  ${WHITE}Domain Backup:${NC} $BACKUP_DOMAIN"
    fi
    
    # Jumlah akun
    JUMLAH_AKUN=$(jq length "$CONFIG_PATH/users.db.json" 2>/dev/null || echo "0")
    echo -e "  ${WHITE}Jumlah Akun  :${NC} $JUMLAH_AKUN"
    
    # Tampilkan contoh password
    if [ "$JUMLAH_AKUN" -gt 0 ]; then
        echo -e "  ${WHITE}Contoh Password:${NC}"
        jq -r '.[] | .password' "$CONFIG_PATH/users.db.json" 2>/dev/null | head -3 | sed 's/^/    - /'
    fi
    
    echo ""
    read -p "Yakin restore? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$TEMP_DIR"
        return
    fi
    
    # Backup data lama
    echo -e "${YELLOW}Membackup data lama...${NC}"
    BACKUP_LAMA="$ZIVPN_DIR/backup/sebelum_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
    mkdir -p "$ZIVPN_DIR/backup"
    tar -czf "$BACKUP_LAMA" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
    echo -e "${GREEN}[✓] Backup data lama: $(basename "$BACKUP_LAMA")${NC}"
    
    # RESTORE FILE
    echo -e "${YELLOW}Merestore file...${NC}"
    
    # Copy semua file dari CONFIG_PATH ke ZIVPN_DIR
    cp -rf "$CONFIG_PATH"/* "$ZIVPN_DIR/" 2>/dev/null
    cp -rf "$CONFIG_PATH"/.[!.]* "$ZIVPN_DIR/" 2>/dev/null
    
    # Kalau ada folder etc/zivpn, copy isinya
    if [ -d "$CONFIG_PATH/etc/zivpn" ]; then
        cp -rf "$CONFIG_PATH/etc/zivpn"/* "$ZIVPN_DIR/" 2>/dev/null
    fi
    
    echo -e "${GREEN}[✓] Restore selesai${NC}"
    
    # Restart service
    echo -e "${YELLOW}Merestart service...${NC}"
    systemctl restart zivpn.service 2>/dev/null
    systemctl restart udp-custom.service 2>/dev/null
    echo -e "${GREEN}[✓] Service direstart${NC}"
    
    # Kirim notifikasi
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
            IP=$(get_ip)
            DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "$IP")
            message="🔄 <b>RESTORE DARI LINK</b>%0A"
            message+="════════════════════════════════%0A"
            message+="<b>Waktu</b>   : $(date +'%Y-%m-%d %H:%M:%S')%0A"
            message+="<b>Domain</b>  : $DOMAIN%0A"
            message+="<b>Jumlah Akun</b>: $JUMLAH_AKUN%0A"
            message+="════════════════════════════════%0A"
            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                 -d "chat_id=${CHAT_ID}" -d "text=${message}" -d "parse_mode=HTML" > /dev/null
        fi
    fi
    
    # Bersihkan
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}[✓] Selesai${NC}"
    echo ""
    read -p "Press Enter..."
}

# === FUNGSI KONFIGURASI BOT ===
config_bot() {
    show_header
    echo -e "${YELLOW}»»» KONFIGURASI BOT «««${NC}\n"
    
    [ -f "$BOT_CONFIG" ] && source "$BOT_CONFIG"
    echo -e "${WHITE}Token:${NC} ${BOT_TOKEN:0:10}... ${WHITE}Chat ID:${NC} $CHAT_ID\n"
    
    read -p "Token baru [Enter skip]: " new_token
    read -p "Chat ID baru [Enter skip]: " new_chat_id
    
    [ -n "$new_token" ] && BOT_TOKEN="$new_token"
    [ -n "$new_chat_id" ] && CHAT_ID="$new_chat_id"
    
    cat > "$BOT_CONFIG" << EOF
#!/bin/bash
BOT_TOKEN='$BOT_TOKEN'
CHAT_ID='$CHAT_ID'
EOF
    
    echo -e "${GREEN}[✓] Konfigurasi disimpan${NC}"
    sleep 2
}

# === FUNGSI AUTO BACKUP SETTINGS ===
auto_backup_settings() {
    show_header
    echo -e "${YELLOW}»»» AUTO BACKUP «««${NC}\n"
    
    if [ -f "/etc/cron.d/zivpn-autobackup" ]; then
        echo -e "${GREEN}Status: AKTIF${NC}"
        echo "  1. Nonaktifkan"
        echo "  2. Backup Sekarang"
        echo "  3. Kembali"
        read -p "Pilih: " choice
        [ "$choice" == "1" ] && rm -f /etc/cron.d/zivpn-autobackup && echo "Auto backup dinonaktifkan"
        [ "$choice" == "2" ] && /usr/local/bin/zivpn-autobackup.sh
    else
        echo -e "${RED}Status: NONAKTIF${NC}"
        echo "  1. Aktifkan (setiap 6 jam)"
        read -p "Pilih: " choice
        [ "$choice" == "1" ] && echo "0 */6 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup && echo "Auto backup diaktifkan"
    fi
    sleep 2
}

# === FUNGSI BACKUP MENU ===
backup_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}»»» BACKUP & RESTORE MENU «««${NC}\n"
        echo "  1. Buat Backup"
        echo "  2. Lihat Daftar Backup"
        echo "  3. Restore dari File"
        echo "  4. Restore dari Link"
        echo "  5. Konfigurasi Bot"
        echo "  6. Pengaturan Auto Backup"
        echo "  7. Kembali"
        echo ""
        read -p "Pilih [1-7]: " subchoice
        
        case $subchoice in
            1) backup_create ;;
            2) backup_list ;;
            3) backup_restore ;;
            4) restore_from_link ;;
            5) config_bot ;;
            6) auto_backup_settings ;;
            7) return ;;
            *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
        esac
    done
}

# === FUNGSI INSTALL ULANG ===
reinstall_zivpn() {
    show_header
    echo -e "${YELLOW}»»» INSTALL ULANG «««${NC}\n"
    
    echo "  1. Install Ulang (Data Pengguna Tetap)"
    echo "  2. Install Ulang (Reset Semua Data)"
    echo "  3. Kembali"
    read -p "Pilih: " choice
    
    case $choice in
        1)
            [ -f "$USERS_DB_JSON" ] && cp "$USERS_DB_JSON" "$USERS_DB_JSON.backup"
            wget -qO /usr/local/bin/zivpn "https://github.com/zivpn/udp-zivpn/releases/download/v1.0.0/zivpn-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" 2>/dev/null
            chmod +x /usr/local/bin/zivpn
            [ -f "$USERS_DB_JSON.backup" ] && mv "$USERS_DB_JSON.backup" "$USERS_DB_JSON"
            systemctl restart zivpn.service 2>/dev/null
            echo -e "${GREEN}[✓] Install ulang selesai${NC}"
            ;;
        2)
            read -p "Buat backup? (y/N): " bk
            [[ "$bk" =~ ^[Yy]$ ]] && tar -czf "/root/zivpn_backup_$(date +%Y%m%d).tar.gz" "$ZIVPN_DIR" 2>/dev/null
            rm -rf "$ZIVPN_DIR"/* 2>/dev/null
            echo "[]" > "$USERS_DB_JSON"
            wget -qO /usr/local/bin/zivpn "https://github.com/zivpn/udp-zivpn/releases/download/v1.0.0/zivpn-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" 2>/dev/null
            chmod +x /usr/local/bin/zivpn
            echo "$(get_ip)" > "$DOMAIN_FILE"
            systemctl restart zivpn.service 2>/dev/null
            echo -e "${GREEN}[✓] Reset selesai${NC}"
            ;;
        3) return ;;
    esac
    sleep 2
}

# === FUNGSI UNINSTALL ===
uninstall_zivpn() {
    show_header
    echo -e "${RED}»»» UNINSTALL «««${NC}\n"
    echo "  1. Uninstall (Data Tetap)"
    echo "  2. Uninstall (Hapus Semua)"
    echo "  3. Kembali"
    read -p "Pilih: " choice
    
    case $choice in
        1)
            systemctl stop zivpn.service 2>/dev/null
            systemctl disable zivpn.service 2>/dev/null
            rm -f /etc/systemd/system/zivpn.service
            rm -f /usr/local/bin/zivpn
            systemctl daemon-reload
            echo -e "${GREEN}[✓] Uninstall selesai, data di $ZIVPN_DIR${NC}"
            ;;
        2)
            systemctl stop zivpn.service 2>/dev/null
            systemctl disable zivpn.service 2>/dev/null
            rm -f /etc/systemd/system/zivpn.service
            rm -f /usr/local/bin/zivpn
            rm -rf "$ZIVPN_DIR"
            systemctl daemon-reload
            echo -e "${GREEN}[✓] Uninstall selesai, semua data dihapus${NC}"
            ;;
        3) return ;;
    esac
    echo ""; read -p "Press Enter..."
}

# === FUNGSI AUTO BACKUP SCRIPT ===
create_autobackup_script() {
    cat > "/usr/local/bin/zivpn-autobackup.sh" << 'EOF'
#!/bin/bash
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"
mkdir -p "$BACKUP_DIR"
DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null | sed 's/\./_/g' || curl -s ifconfig.me 2>/dev/null | sed 's/\./_/g' || echo "vps")
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DOMAIN}.${DATE}.tar.gz"
tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
[ -f "$BOT_CONFIG" ] && source "$BOT_CONFIG"
[ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ] && curl -s -F document=@"$BACKUP_FILE" -F caption="✅ Auto Backup - $(date +'%Y-%m-%d %H:%M:%S')" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}" > /dev/null
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -delete
EOF
    chmod +x "/usr/local/bin/zivpn-autobackup.sh"
}

# === MAIN PROGRAM ===
[ ! -f "$USERS_DB_JSON" ] && echo "[]" > "$USERS_DB_JSON"
[ ! -f "$DOMAIN_FILE" ] && get_ip > "$DOMAIN_FILE"
create_autobackup_script

while true; do
    show_header
    show_menu
    read -p "Pilih menu [00-12]: " choice
    
    case $choice in
        01|1) add_account ;;
        02|2) add_trial ;;
        03|3) list_accounts ;;
        04|4) delete_account ;;
        05|5) edit_expiry ;;
        06|6) edit_password ;;
        07|7) check_online ;;
        08|8) backup_menu ;;
        09|9) change_domain ;;
        10) restart_service ;;
        11) reinstall_zivpn ;;
        12) uninstall_zivpn ;;
        00|0) clear; echo "Terima kasih!"; exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid${NC}"; sleep 1 ;;
    esac
done
