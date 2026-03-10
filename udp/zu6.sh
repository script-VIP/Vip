#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - COMPLETE EDITION
#   Dengan Menu Backup & Restart Service
# =============================================

# === PATH ===
ZIVPN_DIR="/etc/zivpn"
USERS_DB_JSON="$ZIVPN_DIR/users.db.json"
CONFIG_FILE="$ZIVPN_DIR/config.json"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# === FUNGSI CEK ROOT ===
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[✗] Script harus dijalankan sebagai root!${NC}"
        exit 1
    fi
}

# === FUNGSI GET INFO VPS ===
get_vps_info() {
    # Domain
    if [ -f "$DOMAIN_FILE" ]; then
        DOMAIN=$(cat "$DOMAIN_FILE")
    else
        DOMAIN=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    fi
    
    # IP
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    # RAM
    if command -v free &> /dev/null; then
        RAM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
        RAM_USED=$(free -m | grep Mem | awk '{print $3}')
        RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))
        RAM_INFO="${RAM_USED}MB/${RAM_TOTAL}MB (${RAM_PERCENT}%)"
    else
        RAM_INFO="N/A"
    fi
    
    # OS
    if [ -f /etc/os-release ]; then
        OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"' | cut -d' ' -f1,2)
    else
        OS="Ubuntu"
    fi
    
    # Total Akun
    if [ -f "$USERS_DB_JSON" ]; then
        TOTAL_AKUN=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    else
        TOTAL_AKUN="0"
        echo "[]" > "$USERS_DB_JSON"
    fi
    
    # Status Service
    if systemctl is-active --quiet zivpn.service; then
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
    echo -e "${BLUE}║                    ZIVPN UDP MANAGER v2.0                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}🌍 Public IP    :${NC} ${GREEN}$IP${NC}"
    echo -e "  ${WHITE}📌 Domain       :${NC} ${YELLOW}$DOMAIN${NC}"
    echo -e "  ${WHITE}💾 RAM Usage    :${NC} ${CYAN}$RAM_INFO${NC}"
    echo -e "  ${WHITE}🖥️  OS           :${NC} $OS"
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
    echo -e "  ${YELLOW}[10]${NC} 🔄  Restart Service ZIVPN"
    echo -e "  ${YELLOW}[11]${NC} ❌  Uninstall ZIVPN"
    echo -e "  ${YELLOW}[00]${NC} 🚪  Exit"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# === FUNGSI RESTART SERVICE ===
restart_service() {
    show_header
    echo -e "${YELLOW}»»» RESTART SERVICE ZIVPN «««${NC}"
    echo ""
    
    echo -e "${WHITE}Merestart ZIVPN service...${NC}"
    systemctl restart zivpn.service
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Service ZIVPN berhasil direstart${NC}"
    else
        echo -e "${RED}[✗] Gagal merestart service ZIVPN${NC}"
    fi
    
    # Restart UDP Custom jika ada
    if systemctl list-unit-files | grep -q udp-custom.service; then
        echo -e "${WHITE}Merestart UDP Custom service...${NC}"
        systemctl restart udp-custom.service
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[✓] Service UDP Custom berhasil direstart${NC}"
        else
            echo -e "${RED}[✗] Gagal merestart service UDP Custom${NC}"
        fi
    fi
    
    echo ""
    sleep 2
}

# === FUNGSI GENERATE PASSWORD RANDOM 2 DIGIT ===
generate_password() {
    printf "%02d" $((RANDOM % 100))
}

# === FUNGSI GET LOKASI ===
get_location() {
    curl -s http://ipinfo.io/country 2>/dev/null || echo "Indonesia"
}

# === FUNGSI SYNC CONFIG ===
sync_config() {
    if [ -f "$USERS_DB_JSON" ] && [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
        passwords_json=$(jq '[.[].password]' "$USERS_DB_JSON" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$passwords_json" ]; then
            jq --argjson passwords "$passwords_json" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null
            systemctl restart zivpn.service > /dev/null 2>&1
        fi
    fi
}

# === FUNGSI SEND NOTIF TELEGRAM ===
send_notification() {
    local message="$1"
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                 -d "chat_id=${CHAT_ID}" \
                 -d "text=${message}" \
                 -d "parse_mode=HTML" > /dev/null
        fi
    fi
}

# === FUNGSI SEND FILE KE TELEGRAM ===
send_file() {
    local file_path="$1"
    local caption="$2"
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
                 -F "chat_id=${CHAT_ID}" \
                 -F "document=@${file_path}" \
                 -F "caption=${caption}" > /dev/null
            echo -e "${GREEN}[✓] File terkirim ke Telegram${NC}"
        else
            echo -e "${RED}[✗] Bot token atau Chat ID belum diatur!${NC}"
        fi
    else
        echo -e "${RED}[✗] File konfigurasi bot tidak ditemukan!${NC}"
        echo -e "${YELLOW}Silakan atur bot dulu di menu Backup [08] -> [4]${NC}"
    fi
}

# === FUNGSI TAMBAH AKUN REGULER ===
add_account() {
    show_header
    echo -e "${YELLOW}»»» TAMBAH AKUN REGULER «««${NC}"
    echo ""
    
    # Generate random password
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="user${RANDOM_NUM}"
    
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter pakai default]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    # Cek password sudah ada
    if jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        echo -e "${RED}[✗] Password '$password' sudah digunakan!${NC}"
        sleep 2
        return
    fi
    
    read -p "Limit IP [default: 3]: " limit_ip
    [[ -z "$limit_ip" ]] && limit_ip=3
    
    read -p "Masa aktif (hari) [default: 30]: " duration
    [[ -z "$duration" ]] && duration=30
    
    # Hitung expired
    username="user_${password}"
    expiry_timestamp=$(date -d "+$duration days" +%s)
    create_date=$(date +"%d %b, %Y")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y")
    
    # Get domain dan lokasi
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    # Simpan ke database
    jq --arg user "$username" \
       --arg pass "$password" \
       --argjson expiry "$expiry_timestamp" \
       --arg limit "$limit_ip" \
       --arg created "$create_date" \
       '. += [{
           username: $user,
           password: $pass,
           expiry_timestamp: $expiry,
           limit_ip: $limit,
           created_date: $created
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" 2>/dev/null && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    clear
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                       ZIVPN UDP${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}Lokasi      :${NC} $LOKASI"
    echo -e "  ${WHITE}────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Tanggal Buat:${NC} $create_date"
    echo -e "  ${WHITE}Tanggal Exp :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration hari"
    echo -e "  ${WHITE}Limit IP    :${NC} $limit_ip device"
    echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}              TUTORIAL ZIVPN APP / UDP TUNNEL${NC}"
    echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Pilih negara bebas (saran $LOKASI)"
    echo -e "  4. Klik Garis tiga (pojok kiri atas)"
    echo -e "  5. Klik Udp tunnel setting"
    echo -e "  6. UDP Server  : $DOMAIN"
    echo -e "     UDP Password: $password"
    echo -e "  7. Klik APPLY → START"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    # Kirim notifikasi Telegram
    message="════════════════════════════════%0A"
    message+="  ✅ <b>AKUN ZIVPN BARU</b>%0A"
    message+="════════════════════════════════%0A"
    message+="<b>Domain</b>      : <code>${DOMAIN}</code>%0A"
    message+="<b>Password</b>    : <code>${password}</code>%0A"
    message+="<b>Lokasi</b>      : ${LOKASI}%0A"
    message+="────────────────────────────────%0A"
    message+="<b>Dibuat</b>       : ${create_date}%0A"
    message+="<b>Expired</b>      : ${expiry_date}%0A"
    message+="<b>Masa Aktif</b>   : ${duration} hari%0A"
    message+="<b>Limit IP</b>     : ${limit_ip} device%0A"
    message+="════════════════════════════════%0A"
    
    send_notification "$message"
    sync_config
    
    echo ""
    read -p "Press Enter untuk kembali ke menu..."
}

# === FUNGSI TAMBAH TRIAL ===
add_trial() {
    show_header
    echo -e "${YELLOW}»»» TAMBAH AKUN TRIAL «««${NC}"
    echo ""
    
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="trial${RANDOM_NUM}"
    
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter pakai default]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    read -p "Masa aktif (menit) [default: 60]: " duration
    [[ -z "$duration" ]] && duration=60
    
    username="trial_${password}"
    expiry_timestamp=$(date -d "+$duration minutes" +%s)
    create_date=$(date +"%d %b, %Y %H:%M")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y %H:%M")
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    jq --arg user "$username" \
       --arg pass "$password" \
       --argjson expiry "$expiry_timestamp" \
       '. += [{
           username: $user,
           password: $pass,
           expiry_timestamp: $expiry,
           limit_ip: "1",
           created_date: "'$create_date'"
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" 2>/dev/null && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    clear
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    ✓ TRIAL ACCOUNT${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}Lokasi      :${NC} $LOKASI"
    echo -e "  ${WHITE}────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Dibuat      :${NC} $create_date"
    echo -e "  ${WHITE}Expired     :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration menit"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    
    sync_config
    echo ""
    read -p "Press Enter untuk kembali ke menu..."
}

# === FUNGSI LIST AKUN ===
list_accounts() {
    show_header
    echo -e "${YELLOW}»»» DAFTAR AKUN «««${NC}"
    echo ""
    
    # Cek apakah file ada dan tidak kosong
    if [ ! -f "$USERS_DB_JSON" ]; then
        echo "[]" > "$USERS_DB_JSON"
    fi
    
    # Hitung jumlah akun
    jq length "$USERS_DB_JSON" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[]" > "$USERS_DB_JSON"
    fi
    
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun. Silakan tambah akun dulu.${NC}"
    else
        printf "${BLUE}%-4s | %-12s | %-15s | %-12s | %-10s${NC}\n" "No" "Password" "Username" "Expired" "Status"
        echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${NC}"
        
        now=$(date +%s)
        
        # Loop melalui setiap akun
        for i in $(seq 0 $((TOTAL-1))); do
            password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
            username=$(jq -r ".[$i].username" "$USERS_DB_JSON" 2>/dev/null)
            expiry=$(jq -r ".[$i].expiry_timestamp" "$USERS_DB_JSON" 2>/dev/null)
            
            # Format tanggal expired
            if [ "$expiry" != "null" ] && [ -n "$expiry" ]; then
                expiry_date=$(date -d "@$expiry" +"%Y-%m-%d" 2>/dev/null)
                if [ -z "$expiry_date" ]; then
                    expiry_date="N/A"
                fi
            else
                expiry_date="N/A"
            fi
            
            # Hitung status
            remaining=$((expiry - now))
            if [ $remaining -le 0 ]; then
                status="${RED}EXPIRED${NC}"
            else
                days=$((remaining / 86400))
                hours=$(((remaining % 86400) / 3600))
                if [ $days -gt 0 ]; then
                    status="${GREEN}${days}h${NC}"
                elif [ $hours -gt 0 ]; then
                    status="${GREEN}${hours}j${NC}"
                else
                    mins=$((remaining / 60))
                    status="${GREEN}${mins}m${NC}"
                fi
            fi
            
            printf "  %-2d  | %-12s | %-15s | %-12s | %b\n" $((i+1)) "$password" "$username" "$expiry_date" "$status"
        done
    fi
    
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p "Press Enter untuk kembali ke menu..."
}

# === FUNGSI HAPUS AKUN ===
delete_account() {
    show_header
    echo -e "${YELLOW}»»» HAPUS AKUN «««${NC}"
    echo ""
    
    # Cek apakah ada akun
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun untuk dihapus.${NC}"
        echo ""
        read -p "Press Enter untuk kembali ke menu..."
        return
    fi
    
    # Tampilkan daftar akun sederhana
    echo -e "${WHITE}Daftar Password yang tersedia:${NC}"
    for i in $(seq 0 $((TOTAL-1))); do
        password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
        echo "  $((i+1)). $password"
    done
    echo ""
    
    read -p "Masukkan password yang akan dihapus: " password
    
    if [ -z "$password" ]; then
        echo -e "${RED}[✗] Password tidak boleh kosong!${NC}"
        sleep 2
        return
    fi
    
    # Cek apakah password ada
    FOUND=$(jq --arg pass "$password" '[.[] | select(.password == $pass)] | length' "$USERS_DB_JSON" 2>/dev/null)
    
    if [ "$FOUND" -eq 0 ]; then
        echo -e "${RED}[✗] Password '$password' tidak ditemukan!${NC}"
        sleep 2
        return
    fi
    
    # Dapatkan username untuk konfirmasi
    username=$(jq -r --arg pass "$password" '.[] | select(.password == $pass) | .username' "$USERS_DB_JSON" 2>/dev/null | head -1)
    
    # Konfirmasi
    echo -e "${YELLOW}Anda akan menghapus akun dengan password: $password (user: $username)${NC}"
    read -p "Yakin ingin menghapus? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Hapus akun
        jq --arg pass "$password" 'del(.[] | select(.password == $pass))' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
        echo -e "${GREEN}[✓] Akun dengan password '$password' berhasil dihapus!${NC}"
        sync_config
    else
        echo -e "${YELLOW}Penghapusan dibatalkan.${NC}"
    fi
    
    sleep 2
}

# === FUNGSI EDIT MASA AKTIF ===
edit_expiry() {
    show_header
    echo -e "${YELLOW}»»» EDIT MASA AKTIF «««${NC}"
    echo ""
    
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun untuk diedit.${NC}"
        echo ""
        read -p "Press Enter untuk kembali ke menu..."
        return
    fi
    
    # Tampilkan daftar akun
    echo -e "${WHITE}Daftar Password yang tersedia:${NC}"
    for i in $(seq 0 $((TOTAL-1))); do
        password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
        echo "  $((i+1)). $password"
    done
    echo ""
    
    read -p "Masukkan password: " password
    
    if ! jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        echo -e "${RED}[✗] Password '$password' tidak ditemukan!${NC}"
        sleep 2
        return
    fi
    
    current_expiry=$(jq -r --arg pass "$password" '.[] | select(.password == $pass) | .expiry_timestamp' "$USERS_DB_JSON")
    current_date=$(date -d "@$current_expiry" +"%d %b, %Y" 2>/dev/null)
    echo -e "${WHITE}Masa aktif saat ini:${NC} $current_date"
    
    read -p "Tambahan hari: " days
    
    if [ -z "$days" ] || [ "$days" -eq 0 ] 2>/dev/null; then
        echo -e "${RED}[✗] Jumlah hari tidak valid!${NC}"
        sleep 2
        return
    fi
    
    new_expiry=$((current_expiry + days * 86400))
    new_date=$(date -d "@$new_expiry" +"%d %b, %Y" 2>/dev/null)
    
    jq --arg pass "$password" --argjson new_expiry "$new_expiry" \
       '(.[] | select(.password == $pass) | .expiry_timestamp) = $new_expiry' \
       "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    echo -e "${GREEN}[✓] Masa aktif diperpanjang $days hari!${NC}"
    echo -e "${WHITE}Expired baru:${NC} $new_date"
    sync_config
    sleep 2
}

# === FUNGSI EDIT PASSWORD ===
edit_password() {
    show_header
    echo -e "${YELLOW}»»» EDIT PASSWORD «««${NC}"
    echo ""
    
    TOTAL=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun untuk diedit.${NC}"
        echo ""
        read -p "Press Enter untuk kembali ke menu..."
        return
    fi
    
    # Tampilkan daftar akun
    echo -e "${WHITE}Daftar Password yang tersedia:${NC}"
    for i in $(seq 0 $((TOTAL-1))); do
        password=$(jq -r ".[$i].password" "$USERS_DB_JSON" 2>/dev/null)
        echo "  $((i+1)). $password"
    done
    echo ""
    
    read -p "Masukkan password lama: " old_pass
    
    if ! jq -e --arg pass "$old_pass" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        echo -e "${RED}[✗] Password '$old_pass' tidak ditemukan!${NC}"
        sleep 2
        return
    fi
    
    read -p "Masukkan password baru: " new_pass
    
    jq --arg old "$old_pass" --arg new "$new_pass" \
       '(.[] | select(.password == $old) | .password) = $new' \
       "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    echo -e "${GREEN}[✓] Password berhasil diubah!${NC}"
    sync_config
    sleep 2
}

# === FUNGSI CEK USER ONLINE ===
check_online() {
    show_header
    echo -e "${YELLOW}»»» USER ONLINE «««${NC}"
    echo ""
    
    if command -v netstat &> /dev/null; then
        echo -e "${WHITE}Koneksi aktif (ESTABLISHED):${NC}"
        echo ""
        CONNECTIONS=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -E ":80|:443" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr)
        
        if [ -z "$CONNECTIONS" ]; then
            echo -e "  ${YELLOW}Tidak ada koneksi aktif${NC}"
        else
            echo "$CONNECTIONS" | while read count ip; do
                # Cari username berdasarkan IP (jika ada)
                USERNAME="Unknown"
                echo -e "  ${GREEN}$count${NC} koneksi dari ${YELLOW}$ip${NC} (${WHITE}$USERNAME${NC})"
            done
        fi
    else
        echo -e "${RED}netstat tidak tersedia. Install dengan: apt install net-tools${NC}"
    fi
    
    echo ""
    read -p "Press Enter untuk kembali ke menu..."
}

# === FUNGSI GANTI DOMAIN ===
change_domain() {
    show_header
    echo -e "${YELLOW}»»» GANTI DOMAIN «««${NC}"
    echo ""
    
    current=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur")
    echo -e "${WHITE}Domain saat ini:${NC} $current"
    echo ""
    
    read -p "Masukkan domain baru: " new_domain
    
    if [ -n "$new_domain" ]; then
        echo "$new_domain" > "$DOMAIN_FILE"
        echo -e "${GREEN}[✓] Domain diubah ke: $new_domain${NC}"
        
        # Update certificate
        if [ -f "$ZIVPN_DIR/zivpn.key" ] && [ -f "$ZIVPN_DIR/zivpn.crt" ]; then
            openssl req -x509 -newkey rsa:2048 -nodes \
                -keyout "$ZIVPN_DIR/zivpn.key" \
                -out "$ZIVPN_DIR/zivpn.crt" \
                -days 3650 \
                -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZIVPN/OU=UDP/CN=$new_domain" \
                -sha256 2>/dev/null
            echo -e "${GREEN}[✓] Sertifikat SSL diperbarui${NC}"
        fi
        
        systemctl restart zivpn.service > /dev/null 2>&1
        systemctl restart udp-custom.service > /dev/null 2>&1
    else
        echo -e "${RED}[✗] Domain tidak boleh kosong!${NC}"
    fi
    
    sleep 2
}

# === FUNGSI BACKUP SUBMENU ===
backup_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}»»» BACKUP & RESTORE MENU «««${NC}"
        echo ""
        echo "  1. Buat Backup"
        echo "  2. Lihat Daftar Backup"
        echo "  3. Restore dari File"
        echo "  4. Restore dari Link"
        echo "  5. Konfigurasi Bot Telegram"
        echo "  6. Pengaturan Auto Backup"
        echo "  7. Kembali ke Menu Utama"
        echo ""
        read -p "Pilih [1-6]: " subchoice
        
        case $subchoice in
            1) backup_create ;;
            2) backup_list ;;
            3) backup_restore ;;
            4) restore_from_link
            5) config_bot ;;
            6) auto_backup_settings ;;
            7) return ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# === FUNGSI BUAT BACKUP ===
backup_create() {
    show_header
    echo -e "${YELLOW}»»» BUAT BACKUP «««${NC}"
    echo ""
    
    # Buat direktori backup
    BACKUP_DIR="$ZIVPN_DIR/backup"
    mkdir -p "$BACKUP_DIR"
    
    # Dapatkan domain untuk nama file
    if [ -f "$DOMAIN_FILE" ]; then
        DOMAIN_NAME=$(cat "$DOMAIN_FILE" | sed 's/\./_/g')
    else
        DOMAIN_NAME=$(curl -s ifconfig.me 2>/dev/null | sed 's/\./_/g' || echo "vps")
    fi
    
    # Dapatkan IP
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    # Format tanggal: YYYYMMDD_HHMMSS
    DATE=$(date +"%Y%m%d_%H%M%S")
    DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Nama file backup: domain.tanggal.tar.gz
    BACKUP_FILENAME="${DOMAIN_NAME}.${DATE}.tar.gz"
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME"
    
    # Buat backup
    echo -e "${YELLOW}Membuat backup...${NC}"
    tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup berhasil dibuat:${NC}"
        echo -e "     ${WHITE}$BACKUP_FILENAME${NC}"
        
        # Hitung ukuran file
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "     Ukuran: ${CYAN}$SIZE${NC}"
        
        # Kirim ke Telegram
        echo ""
        echo -e "${YELLOW}Mengirim ke Telegram...${NC}"
        
        # Buat caption dengan informasi lengkap
        CAPTION="✅ Auto Backup ZIVPN - 
Waktu - ${DISPLAY_DATE}
IP - ${IP}
Domain - ${DOMAIN_NAME//_/.}"
        
        send_file "$BACKUP_FILE" "$CAPTION"
    else
        echo -e "${RED}[✗] Gagal membuat backup!${NC}"
    fi
    
    echo ""
    read -p "Press Enter untuk kembali..."
}
# === FUNGSI RESTORE DARI LINK (SUPPORT ZIP DAN TAR.GZ) ===
restore_from_link() {
    show_header
    echo -e "${YELLOW}»»» RESTORE DARI LINK «««${NC}"
    echo ""
    echo -e "${WHITE}Masukkan URL file backup (support .zip atau .tar.gz):${NC}"
    echo -e "${CYAN}Contoh ZIP   : https://filename.web.id/backup.zip${NC}"
    echo -e "${CYAN}Contoh TAR.GZ: https://filename.web.id/backup.tar.gz${NC}"
    echo ""
    read -p "URL: " backup_url
    
    if [ -z "$backup_url" ]; then
        echo -e "${RED}[✗] URL tidak boleh kosong!${NC}"
        sleep 2
        return
    fi
    
    # Validasi URL
    if [[ ! "$backup_url" =~ ^https?:// ]]; then
        echo -e "${RED}[✗] Format URL tidak valid! Gunakan http:// atau https://${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Mengunduh file backup...${NC}"
    
    # Buat direktori temp
    TEMP_DIR="/tmp/zivpn_restore_$$"
    mkdir -p "$TEMP_DIR"
    mkdir -p "$TEMP_DIR/extract"
    
    # Download file
    FILENAME=$(basename "$backup_url")
    
    # Tampilkan progress download
    if wget --timeout=30 --tries=3 -q --show-progress "$backup_url" -O "$TEMP_DIR/$FILENAME"; then
        echo -e "${GREEN}[✓] File berhasil diunduh: $FILENAME${NC}"
        
        # Cek ukuran file
        FILE_SIZE=$(du -h "$TEMP_DIR/$FILENAME" | cut -f1)
        echo -e "     Ukuran: ${CYAN}$FILE_SIZE${NC}"
        
        # Cek tipe file berdasarkan ekstensi
        if [[ "$FILENAME" == *.zip ]]; then
            # Unzip file
            echo -e "${YELLOW}Mengekstrak file ZIP...${NC}"
            if unzip -q "$TEMP_DIR/$FILENAME" -d "$TEMP_DIR/extract"; then
                echo -e "${GREEN}[✓] Ekstraksi ZIP berhasil${NC}"
            else
                echo -e "${RED}[✗] Gagal mengekstrak file ZIP!${NC}"
                rm -rf "$TEMP_DIR"
                sleep 2
                return
            fi
            
        elif [[ "$FILENAME" == *.tar.gz ]] || [[ "$FILENAME" == *.tgz ]]; then
            # Extract tar.gz
            echo -e "${YELLOW}Mengekstrak file TAR.GZ...${NC}"
            if tar -xzf "$TEMP_DIR/$FILENAME" -C "$TEMP_DIR/extract" 2>/dev/null; then
                echo -e "${GREEN}[✓] Ekstraksi TAR.GZ berhasil${NC}"
            else
                echo -e "${RED}[✗] Gagal mengekstrak file TAR.GZ!${NC}"
                rm -rf "$TEMP_DIR"
                sleep 2
                return
            fi
            
        else
            echo -e "${RED}[✗] Format file tidak didukung! Gunakan .zip atau .tar.gz${NC}"
            echo -e "${YELLOW}File yang didownload: $FILENAME${NC}"
            rm -rf "$TEMP_DIR"
            sleep 2
            return
        fi
        
        # Cari file konfigurasi di dalam hasil extract
        echo -e "${YELLOW}Mencari file konfigurasi...${NC}"
        
        # Cek beberapa kemungkinan lokasi
        if [ -f "$TEMP_DIR/extract/users.db.json" ]; then
            CONFIG_PATH="$TEMP_DIR/extract"
            echo -e "${GREEN}[✓] File users.db.json ditemukan${NC}"
            
        elif [ -f "$TEMP_DIR/extract/etc/zivpn/users.db.json" ]; then
            CONFIG_PATH="$TEMP_DIR/extract/etc/zivpn"
            echo -e "${GREEN}[✓] File users.db.json ditemukan di folder etc/zivpn${NC}"
            
        else
            # Cari dengan find (rekursif)
            FOUND_FILE=$(find "$TEMP_DIR/extract" -name "users.db.json" -type f | head -1)
            if [ -n "$FOUND_FILE" ]; then
                CONFIG_PATH=$(dirname "$FOUND_FILE")
                echo -e "${GREEN}[✓] File users.db.json ditemukan di: $CONFIG_PATH${NC}"
            else
                echo -e "${RED}[✗] File users.db.json tidak ditemukan dalam backup!${NC}"
                echo -e "${YELLOW}Isi direktori backup:${NC}"
                ls -la "$TEMP_DIR/extract"
                rm -rf "$TEMP_DIR"
                sleep 3
                return
            fi
        fi
        
        # Tampilkan info backup
        echo ""
        echo -e "${WHITE}Informasi Backup:${NC}"
        
        # Cek file domain
        if [ -f "$CONFIG_PATH/domain.txt" ]; then
            BACKUP_DOMAIN=$(cat "$CONFIG_PATH/domain.txt")
            echo -e "  ${WHITE}Domain Backup:${NC} $BACKUP_DOMAIN"
        fi
        
        # Hitung jumlah akun
        if [ -f "$CONFIG_PATH/users.db.json" ]; then
            JUMLAH_AKUN=$(jq length "$CONFIG_PATH/users.db.json" 2>/dev/null || echo "0")
            echo -e "  ${WHITE}Jumlah Akun  :${NC} $JUMLAH_AKUN"
        fi
        
        # Tampilkan daftar file
        echo -e "  ${WHITE}File penting :${NC}"
        ls -la "$CONFIG_PATH" | grep -E "users.db.json|config.json|domain.txt" | awk '{print "    " $9}'
        
        echo ""
        echo -e "${YELLOW}PERINGATAN: Restore akan menimpa semua data saat ini!${NC}"
        read -p "Yakin ingin melanjutkan restore? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${YELLOW}Melakukan restore...${NC}"
            
            # Backup data lama (opsional)
            BACKUP_LAMA="$ZIVPN_DIR/backup/sebelum_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
            echo -e "${WHITE}Membuat backup data lama:${NC} $(basename "$BACKUP_LAMA")"
            tar -czf "$BACKUP_LAMA" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
            
            # Copy file dari backup ke direktori ZIVPN
            cp -rf "$CONFIG_PATH"/* "$ZIVPN_DIR/" 2>/dev/null
            cp -rf "$CONFIG_PATH"/.[!.]* "$ZIVPN_DIR/" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] Restore berhasil!${NC}"
                
                # Restart service
                echo -e "${WHITE}Merestart service...${NC}"
                systemctl restart zivpn.service > /dev/null 2>&1
                systemctl restart udp-custom.service > /dev/null 2>&1
                echo -e "${GREEN}[✓] Service direstart${NC}"
                
                # Kirim notifikasi ke Telegram
                if [ -f "$BOT_CONFIG" ]; then
                    source "$BOT_CONFIG"
                    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
                        IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                        DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")
                        
                        message="🔄 <b>RESTORE DARI LINK</b>%0A"
                        message+="════════════════════════════════%0A"
                        message+="<b>Waktu</b>   : $(date +'%Y-%m-%d %H:%M:%S')%0A"
                        message+="<b>IP</b>      : $IP%0A"
                        message+="<b>Domain</b>  : $DOMAIN%0A"
                        message+="<b>Sumber</b>  : $backup_url%0A"
                        message+="════════════════════════════════%0A"
                        
                        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                             -d "chat_id=${CHAT_ID}" \
                             -d "text=${message}" \
                             -d "parse_mode=HTML" > /dev/null
                    fi
                fi
            else
                echo -e "${RED}[✗] Gagal melakukan restore!${NC}"
            fi
        else
            echo -e "${YELLOW}Restore dibatalkan${NC}"
        fi
        
        # Bersihkan temporary files
        echo -e "${WHITE}Membersihkan file temporary...${NC}"
        rm -rf "$TEMP_DIR"
        echo -e "${GREEN}[✓] Selesai${NC}"
        
    else
        echo -e "${RED}[✗] Gagal mengunduh file!${NC}"
        echo -e "${YELLOW}Periksa koneksi internet dan pastikan URL valid${NC}"
        rm -rf "$TEMP_DIR"
    fi
    
    echo ""
    read -p "Press Enter untuk kembali..."
}
# === FUNGSI LIHAT DAFTAR BACKUP ===
backup_list() {
    show_header
    echo -e "${YELLOW}»»» DAFTAR BACKUP «««${NC}"
    echo ""
    
    if [ -d "$ZIVPN_DIR/backup" ] && [ "$(ls -A $ZIVPN_DIR/backup 2>/dev/null)" ]; then
        echo -e "${WHITE}File backup tersedia:${NC}"
        echo ""
        
        # Tampilkan daftar backup dengan ukuran dan tanggal
        ls -lh "$ZIVPN_DIR/backup/" | grep tar.gz | awk '{
            printf "  %s (%s) - %s %s\n", $9, $5, $6, $7
        }'
        
        # Hitung total dan ukuran
        TOTAL=$(ls "$ZIVPN_DIR/backup/" | grep tar.gz | wc -l)
        TOTAL_SIZE=$(du -sh "$ZIVPN_DIR/backup/" | cut -f1)
        echo ""
        echo -e "  ${WHITE}Total:${NC} $TOTAL file (${CYAN}$TOTAL_SIZE${NC})"
    else
        echo -e "${YELLOW}  Belum ada backup${NC}"
    fi
    
    echo ""
    read -p "Press Enter untuk kembali..."
}

# === FUNGSI RESTORE BACKUP ===
backup_restore() {
    show_header
    echo -e "${YELLOW}»»» RESTORE BACKUP «««${NC}"
    echo ""
    
    if [ ! -d "$ZIVPN_DIR/backup" ] || [ -z "$(ls -A $ZIVPN_DIR/backup 2>/dev/null | grep tar.gz)" ]; then
        echo -e "${RED}  Tidak ada file backup!${NC}"
        echo ""
        read -p "Press Enter untuk kembali..."
        return
    fi
    
    echo -e "${WHITE}Pilih file backup:${NC}"
    echo ""
    
    # Tampilkan daftar backup dengan nomor
    ls "$ZIVPN_DIR/backup/" | grep tar.gz | nl -w2 -s'. '
    
    echo ""
    read -p "Masukkan nomor atau nama file backup: " input
    
    # Cek apakah input berupa nomor
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        filename=$(ls "$ZIVPN_DIR/backup/" | grep tar.gz | sed -n "${input}p")
    else
        filename="$input"
    fi
    
    if [ -f "$ZIVPN_DIR/backup/$filename" ]; then
        echo ""
        echo -e "${YELLOW}PERINGATAN: Restore akan menimpa semua data saat ini!${NC}"
        read -p "Yakin ingin melanjutkan? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Merestore backup...${NC}"
            tar -xzf "$ZIVPN_DIR/backup/$filename" -C "$ZIVPN_DIR" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] Restore selesai${NC}"
                systemctl restart zivpn.service > /dev/null 2>&1
                systemctl restart udp-custom.service > /dev/null 2>&1
                echo -e "${GREEN}[✓] Service direstart${NC}"
            else
                echo -e "${RED}[✗] Gagal merestore backup!${NC}"
            fi
        else
            echo -e "${YELLOW}Restore dibatalkan${NC}"
        fi
    else
        echo -e "${RED}[✗] File tidak ditemukan!${NC}"
    fi
    
    echo ""
    read -p "Press Enter untuk kembali..."
}

# === FUNGSI KONFIGURASI BOT ===
config_bot() {
    show_header
    echo -e "${YELLOW}»»» KONFIGURASI BOT TELEGRAM «««${NC}"
    echo ""
    
    # Token default dari instalasi
    DEFAULT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
    DEFAULT_CHAT="6198984094"
    
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        echo -e "${WHITE}Token saat ini:${NC} ${BOT_TOKEN:0:10}...${BOT_TOKEN: -5}"
        echo -e "${WHITE}Chat ID saat ini:${NC} $CHAT_ID"
    else
        echo -e "${WHITE}Token default: ${CYAN}$DEFAULT_TOKEN${NC}"
        echo -e "${WHITE}Chat ID default: ${CYAN}$DEFAULT_CHAT${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Kosongkan jika tidak ingin mengubah${NC}"
    echo ""
    read -p "Bot Token [Enter jika tidak diubah]: " new_token
    read -p "Chat ID [Enter jika tidak diubah]: " new_chat_id
    
    # Pakai nilai baru jika diisi, jika tidak pakai nilai lama atau default
    if [ -n "$new_token" ]; then
        BOT_TOKEN="$new_token"
    elif [ -z "$BOT_TOKEN" ]; then
        BOT_TOKEN="$DEFAULT_TOKEN"
    fi
    
    if [ -n "$new_chat_id" ]; then
        CHAT_ID="$new_chat_id"
    elif [ -z "$CHAT_ID" ]; then
        CHAT_ID="$DEFAULT_CHAT"
    fi
    
    # Simpan konfigurasi
    cat > "$BOT_CONFIG" << EOF
#!/bin/bash
BOT_TOKEN='$BOT_TOKEN'
CHAT_ID='$CHAT_ID'
EOF
    
    echo -e "${GREEN}[✓] Konfigurasi bot disimpan${NC}"
    
    # Test notifikasi
    echo ""
    echo -e "${YELLOW}Mengirim test notifikasi...${NC}"
    send_notification "✅ <b>Test Notifikasi</b>%0ABot ZIVPN berhasil dikonfigurasi!"
    
    sleep 2
}

# === FUNGSI AUTO BACKUP SETTINGS ===
auto_backup_settings() {
    show_header
    echo -e "${YELLOW}»»» PENGATURAN AUTO BACKUP «««${NC}"
    echo ""
    
    # Cek status auto backup
    if [ -f "/etc/cron.d/zivpn-autobackup" ]; then
        CURRENT_SCHEDULE=$(grep "zivpn-autobackup" /etc/cron.d/zivpn-autobackup | awk '{print $2}')
        
        if [ "$CURRENT_SCHEDULE" = "23" ]; then
            STATUS="Setiap hari jam 23:00"
            CURRENT="23:00"
        elif [ "$CURRENT_SCHEDULE" = "*/1" ]; then
            STATUS="Setiap 1 jam"
            CURRENT="1 Jam"
        elif [ "$CURRENT_SCHEDULE" = "*/6" ]; then
            STATUS="Setiap 6 jam"
            CURRENT="6 Jam"
        elif [ "$CURRENT_SCHEDULE" = "*/12" ]; then
            STATUS="Setiap 12 jam"
            CURRENT="12 Jam"
        elif [ "$CURRENT_SCHEDULE" = "0" ]; then
            STATUS="Setiap hari jam 00:00"
            CURRENT="00:00"
        else
            STATUS="Setiap 6 jam"
            CURRENT="6 Jam"
        fi
        
        echo -e "${GREEN}Status: AKTIF${NC}"
        echo -e "${WHITE}Jadwal saat ini:${NC} $STATUS"
        echo ""
        echo "  1. Nonaktifkan Auto Backup"
        echo "  2. Ubah Jadwal Backup"
        echo "  3. Backup Sekarang"
        echo "  4. Kembali"
        read -p "Pilih: " choice
        
        case $choice in
            1)
                rm -f /etc/cron.d/zivpn-autobackup
                echo -e "${GREEN}[✓] Auto backup dinonaktifkan${NC}"
                sleep 2
                ;;
            2)
                set_auto_backup_schedule
                ;;
            3)
                /usr/local/bin/zivpn-autobackup.sh
                echo -e "${GREEN}[✓] Backup manual selesai${NC}"
                sleep 2
                ;;
        esac
    else
        echo -e "${RED}Status: NONAKTIF${NC}"
        echo ""
        echo "  1. Aktifkan Auto Backup"
        echo "  2. Kembali"
        read -p "Pilih: " choice
        
        if [ "$choice" == "1" ]; then
            set_auto_backup_schedule
        fi
    fi
}

# === FUNGSI SET JADWAL AUTO BACKUP ===
set_auto_backup_schedule() {
    echo ""
    echo -e "${YELLOW}Pilih Jadwal Backup:${NC}"
    echo "  1. Setiap 1 jam"
    echo "  2. Setiap 6 jam"
    echo "  3. Setiap 12 jam"
    echo "  4. Setiap hari jam 00:00"
    echo "  5. Setiap hari jam 23:00"
    echo "  6. Kembali"
    read -p "Pilih [1-6]: " sched_choice
    
    case $sched_choice in
        1)
            echo "0 */1 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}[✓] Auto backup diaktifkan (Setiap 1 jam)${NC}"
            ;;
        2)
            echo "0 */6 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}[✓] Auto backup diaktifkan (Setiap 6 jam)${NC}"
            ;;
        3)
            echo "0 */12 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}[✓] Auto backup diaktifkan (Setiap 12 jam)${NC}"
            ;;
        4)
            echo "0 0 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}[✓] Auto backup diaktifkan (Setiap hari jam 00:00)${NC}"
            ;;
        5)
            echo "0 23 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}[✓] Auto backup diaktifkan (Setiap hari jam 23:00)${NC}"
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            return
            ;;
    esac
    
    # Jalankan backup pertama
    /usr/local/bin/zivpn-autobackup.sh
    sleep 2
}

# === FUNGSI UNINSTALL ===
uninstall() {
    show_header
    echo -e "${RED}»»» UNINSTALL ZIVPN «««${NC}"
    echo ""
    echo -e "${YELLOW}Peringatan: Semua data akan dihapus!${NC}"
    echo ""
    read -p "Yakin ingin uninstall? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${WHITE}Menghentikan services...${NC}"
        systemctl stop zivpn.service udp-custom.service 2>/dev/null
        systemctl disable zivpn.service udp-custom.service 2>/dev/null
        
        echo -e "${WHITE}Menghapus file...${NC}"
        rm -f /etc/systemd/system/zivpn.service
        rm -f /etc/systemd/system/udp-custom.service
        rm -f /usr/local/bin/zivpn
        rm -f /usr/local/bin/zivpn-menu
        rm -f /usr/local/bin/zivpn-autobackup.sh
        rm -f /etc/cron.d/zivpn-autobackup
        
        read -p "Hapus semua data konfigurasi? (y/N): " rm_data
        if [[ "$rm_data" =~ ^[Yy]$ ]]; then
            rm -rf "$ZIVPN_DIR"
            rm -rf /var/log/zivpn
            echo -e "${GREEN}[✓] Semua data dihapus${NC}"
        fi
        
        systemctl daemon-reload
        echo -e "${GREEN}[✓] Uninstall selesai${NC}"
        exit 0
    fi
}

# === FUNGSI AUTO BACKUP SCRIPT ===
create_autobackup_script() {
    cat > "/usr/local/bin/zivpn-autobackup.sh" << 'EOF'
#!/bin/bash
# Auto Backup Script untuk ZIVPN

ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"
MAX_BACKUPS=10

# Buat direktori backup jika belum ada
mkdir -p "$BACKUP_DIR"

# Dapatkan domain untuk nama file
if [ -f "$DOMAIN_FILE" ]; then
    DOMAIN_NAME=$(cat "$DOMAIN_FILE" | sed 's/\./_/g')
    DOMAIN_ORIG=$(cat "$DOMAIN_FILE")
else
    DOMAIN_NAME=$(curl -s ifconfig.me 2>/dev/null | sed 's/\./_/g' || echo "vps")
    DOMAIN_ORIG="$DOMAIN_NAME"
fi

# Dapatkan IP
IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# Format tanggal: YYYYMMDD_HHMMSS
DATE=$(date +"%Y%m%d_%H%M%S")
DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Nama file backup: domain.tanggal.tar.gz
BACKUP_FILENAME="${DOMAIN_NAME}.${DATE}.tar.gz"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME"

# Buat backup
tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null

if [ $? -eq 0 ]; then
    # Hapus backup lama (simpan hanya 10 terakhir)
    cd "$BACKUP_DIR"
    ls -t *.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm
    
    # Kirim ke Telegram jika dikonfigurasi
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
            CAPTION="✅ Auto Backup ZIVPN - 
Waktu - ${DISPLAY_DATE}
IP - ${IP}
Domain - ${DOMAIN_ORIG}"
            
            curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
                 -F "chat_id=${CHAT_ID}" \
                 -F "document=@${BACKUP_FILE}" \
                 -F "caption=${CAPTION}" > /dev/null
        fi
    fi
fi
EOF

    chmod +x "/usr/local/bin/zivpn-autobackup.sh"
}

# === MAIN PROGRAM ===
check_root

# Buat database jika belum ada
if [ ! -f "$USERS_DB_JSON" ]; then
    echo "[]" > "$USERS_DB_JSON"
fi

# Buat auto backup script
create_autobackup_script

# Loop utama
while true; do
    show_header
    show_menu
    read -p "Pilih menu [00-11]: " choice
    
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
        11) uninstall ;;
        00|0) 
            clear
            echo -e "${GREEN}Terima kasih!${NC}"
            exit 0 
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
