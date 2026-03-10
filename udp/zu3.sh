#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - LITE VERSION
#   Auto Backup + Domain + Random Password
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
NC='\033[0m'

# === FUNGSI UTILITAS ===
print_msg() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# === FUNGSI TELEGRAM ===
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
        # Extract passwords to array
        passwords_json=$(jq '[.[].password]' "$USERS_DB_JSON" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$passwords_json" ]; then
            # Update config
            jq --argjson passwords "$passwords_json" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null
            # Restart service
            systemctl restart zivpn.service > /dev/null 2>&1
        fi
    fi
}

# === FUNGSI TAMBAH AKUN ===
add_account() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          TAMBAH AKUN REGULER${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    # Generate random password (2 digit angka)
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="user${RANDOM_NUM}"
    
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter untuk pakai default]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    # Check if password already exists
    if jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        print_error "Password '$password' sudah digunakan!"
        sleep 2
        return
    fi
    
    read -p "Limit IP [default: 3]: " limit_ip
    [[ -z "$limit_ip" ]] && limit_ip=3
    
    read -p "Masa aktif (hari) [default: 30]: " duration
    [[ -z "$duration" ]] && duration=30
    
    # Generate username from password (for internal use)
    username="user_${password}"
    
    expiry_timestamp=$(date -d "+$duration days" +%s)
    create_date=$(date +"%d %b, %Y")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y")
    
    # Get domain and location
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    # Add to database
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
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    # TAMPILAN OUTPUT
    clear
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  ZIVPN UDP${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}Lokasi      :${NC} $LOKASI"
    echo -e "  ${WHITE}────────────────${NC}"
    echo -e "  ${WHITE}Tanggal Buat:${NC} $create_date"
    echo -e "  ${WHITE}Tanggal Exp :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration hari"
    echo -e "  ${WHITE}Limit IP    :${NC} $limit_ip device"
    echo -e "${GREEN}───────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${GREEN}───────────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Pilih negara bebas (saran $LOKASI)"
    echo -e "  4. Klik Garis tiga (pojok kiri atas)"
    echo -e "  5. Klik Udp tunnel setting"
    echo -e "  6. UDP Server  : $DOMAIN"
    echo -e "     UDP Password: $password"
    echo -e "  7. Klik APPLY → START"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    
    # Send Telegram notification
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
    read -p "Press [Enter] untuk kembali ke menu..."
}

# === FUNGSI TAMBAH AKUN TRIAL ===
add_trial() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          TAMBAH AKUN TRIAL${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    # Generate random password
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="trial${RANDOM_NUM}"
    
    echo -e "${WHITE}Password default: ${GREEN}$DEFAULT_PASS${NC}"
    read -p "Password [Enter untuk pakai default]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    read -p "Masa aktif (menit) [default: 60]: " duration
    [[ -z "$duration" ]] && duration=60
    
    username="trial_${password}"
    expiry_timestamp=$(date -d "+$duration minutes" +%s)
    create_date=$(date +"%d %b, %Y %H:%M")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y %H:%M")
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    # Add to database
    jq --arg user "$username" \
       --arg pass "$password" \
       --argjson expiry "$expiry_timestamp" \
       '. += [{
           username: $user,
           password: $pass,
           expiry_timestamp: $expiry,
           limit_ip: "1",
           created_date: $create_date
       }]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    clear
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ TRIAL ACCOUNT${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "  ${WHITE}Password    :${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}Lokasi      :${NC} $LOKASI"
    echo -e "  ${WHITE}────────────────${NC}"
    echo -e "  ${WHITE}Dibuat      :${NC} $create_date"
    echo -e "  ${WHITE}Expired     :${NC} $expiry_date"
    echo -e "  ${WHITE}Masa Aktif  :${NC} $duration menit"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    
    sync_config
    echo ""
    read -p "Press [Enter] untuk kembali ke menu..."
}

# === FUNGSI LIST AKUN ===
list_accounts() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                         DAFTAR AKUN${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    printf "${YELLOW}%-15s | %-10s | %-15s | %-20s${NC}\n" "Password" "Username" "Expired" "Status"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────${NC}"
    
    now=$(date +%s)
    
    if [ ! -s "$USERS_DB_JSON" ] || [ "$(jq length "$USERS_DB_JSON")" -eq 0 ]; then
        echo -e "${RED}  Belum ada akun${NC}"
    else
        jq -r --argjson now "$now" '.[] | 
        (.expiry_timestamp - $now) as $remaining |
        if $remaining <= 0 then
            status="❌ EXPIRED"
        else
            days = ($remaining / 86400 | floor)
            hours = (($remaining % 86400) / 3600 | floor)
            mins = (($remaining % 3600) / 60 | floor)
            if days > 0 then
                status = "✅ \(days) hari"
            elif hours > 0 then
                status = "✅ \(hours) jam"
            else
                status = "✅ \(mins) mnt"
            end
        end |
        "\(.password)|\(.username)|\(.expiry_timestamp|strftime("%Y-%m-%d"))|\(status)"' "$USERS_DB_JSON" 2>/dev/null | 
        while IFS='|' read -r pass user expiry status; do
            printf "${WHITE}%-15s | %-10s | %-15s | ${NC}%b\n" "$pass" "$user" "$expiry" "$status"
        done
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press [Enter] untuk kembali ke menu..."
}

# === FUNGSI HAPUS AKUN ===
delete_account() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          HAPUS AKUN${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    read -p "Masukkan password yang akan dihapus: " password
    
    if ! jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        print_error "Password '$password' tidak ditemukan!"
        sleep 2
        return
    fi
    
    # Get username for confirmation message
    username=$(jq -r --arg pass "$password" '.[] | select(.password == $pass) | .username' "$USERS_DB_JSON")
    
    jq --arg pass "$password" 'del(.[] | select(.password == $pass))' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    print_msg "Akun dengan password '$password' (user: $username) berhasil dihapus!"
    sync_config
    sleep 2
}

# === FUNGSI PERPANJANG MASA AKTIF ===
extend_expiry() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          PERPANJANG MASA AKTIF${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    read -p "Masukkan password: " password
    
    if ! jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null 2>&1; then
        print_error "Password '$password' tidak ditemukan!"
        sleep 2
        return
    fi
    
    # Get current expiry
    current_expiry=$(jq -r --arg pass "$password" '.[] | select(.password == $pass) | .expiry_timestamp' "$USERS_DB_JSON")
    current_date=$(date -d "@$current_expiry" +"%d %b, %Y")
    echo -e "${WHITE}Masa aktif saat ini:${NC} $current_date"
    
    read -p "Tambahan hari: " days
    
    if [ -z "$days" ] || [ "$days" -eq 0 ] 2>/dev/null; then
        print_error "Jumlah hari tidak valid!"
        sleep 2
        return
    fi
    
    new_expiry=$((current_expiry + days * 86400))
    new_date=$(date -d "@$new_expiry" +"%d %b, %Y")
    
    jq --arg pass "$password" --argjson new_expiry "$new_expiry" \
       '(.[] | select(.password == $pass) | .expiry_timestamp) = $new_expiry' \
       "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    print_msg "Masa aktif diperpanjang $days hari!"
    echo -e "${WHITE}Expired baru:${NC} $new_date"
    sync_config
    sleep 2
}

# === FUNGSI CEK ONLINE USER ===
check_online() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}          ONLINE USERS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    
    if command -v netstat &> /dev/null; then
        echo -e "${YELLOW}Koneksi aktif dalam 5 menit terakhir:${NC}"
        netstat -an 2>/dev/null | grep ESTABLISHED | grep -E ":80|:443" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -20
    else
        echo -e "${RED}netstat tidak tersedia${NC}"
    fi
    
    echo ""
    read -p "Press [Enter] untuk kembali ke menu..."
}

# === FUNGSI VPS INFO ===
vps_info() {
    clear
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}          VPS INFORMATION${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    
    # Domain & IP
    echo -e "${WHITE}Domain      :${NC} $DOMAIN"
    echo -e "${WHITE}IP Address  :${NC} $IP"
    
    # RAM
    if command -v free &> /dev/null; then
        RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
        RAM_USED=$(free -h | grep Mem | awk '{print $3}')
        RAM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
        echo -e "${WHITE}RAM Usage   :${NC} $RAM_USED / $RAM_TOTAL ($RAM_PERCENT%)"
    fi
    
    # CPU Load
    if [ -f /proc/loadavg ]; then
        CPU_LOAD=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
        echo -e "${WHITE}Load Average:${NC} $CPU_LOAD"
    fi
    
    # Disk
    if command -v df &> /dev/null; then
        DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
        DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
        DISK_PERCENT=$(df -h / | tail -1 | awk '{print $5}')
        echo -e "${WHITE}Disk Usage  :${NC} $DISK_USED / $DISK_TOTAL ($DISK_PERCENT)"
    fi
    
    # Uptime
    if command -v uptime &> /dev/null; then
        UPTIME=$(uptime -p | sed 's/up //')
        echo -e "${WHITE}Uptime      :${NC} $UPTIME"
    fi
    
    # OS
    if [ -f /etc/os-release ]; then
        OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
        echo -e "${WHITE}OS          :${NC} $OS"
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press [Enter] untuk kembali ke menu..."
}

# === FUNGSI GANTI DOMAIN ===
change_domain() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          GANTI DOMAIN${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    current=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Belum diatur")
    echo -e "${WHITE}Domain saat ini:${NC} $current"
    echo ""
    
    read -p "Masukkan domain baru: " new_domain
    
    if [ -n "$new_domain" ]; then
        echo "$new_domain" > "$DOMAIN_FILE"
        print_msg "Domain diubah ke: $new_domain"
        
        # Update certificate
        if [ -f "$ZIVPN_DIR/zivpn.key" ] && [ -f "$ZIVPN_DIR/zivpn.crt" ]; then
            openssl req -x509 -newkey rsa:2048 -nodes \
                -keyout "$ZIVPN_DIR/zivpn.key" \
                -out "$ZIVPN_DIR/zivpn.crt" \
                -days 3650 \
                -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZIVPN/OU=UDP/CN=$new_domain" \
                -sha256 2>/dev/null
            print_msg "Sertifikat SSL diperbarui"
        fi
        
        # Restart services
        systemctl restart zivpn.service > /dev/null 2>&1
        systemctl restart udp-custom.service > /dev/null 2>&1
    else
        print_error "Domain tidak boleh kosong!"
    fi
    
    sleep 2
}

# === FUNGSI BACKUP ===
backup_data() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          BACKUP / RESTORE${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo "1. Buat Backup"
    echo "2. Lihat Daftar Backup"
    echo "3. Restore dari File"
    echo "4. Kembali"
    echo ""
    read -p "Pilih [1-4]: " subchoice
    
    case $subchoice in
        1)
            BACKUP_DIR="$ZIVPN_DIR/backup"
            mkdir -p "$BACKUP_DIR"
            BACKUP_FILE="$BACKUP_DIR/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" . 2>/dev/null
            print_msg "Backup dibuat: $(basename "$BACKUP_FILE")"
            
            # Send to Telegram if configured
            if [ -f "$BOT_CONFIG" ]; then
                source "$BOT_CONFIG"
                if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
                    curl -s -F document=@"$BACKUP_FILE" \
                         -F caption="Backup ZIVPN $(date +'%Y-%m-%d %H:%M:%S')" \
                         "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}" > /dev/null
                    print_msg "Backup dikirim ke Telegram"
                fi
            fi
            ;;
        2)
            echo ""
            echo -e "${WHITE}File backup tersedia:${NC}"
            ls -lh "$ZIVPN_DIR/backup/" 2>/dev/null | grep tar.gz || echo "Belum ada backup"
            ;;
        3)
            echo ""
            echo -e "${WHITE}File backup:${NC}"
            ls "$ZIVPN_DIR/backup/" 2>/dev/null | grep tar.gz || echo "Belum ada backup"
            echo ""
            read -p "Nama file backup: " filename
            if [ -f "$ZIVPN_DIR/backup/$filename" ]; then
                tar -xzf "$ZIVPN_DIR/backup/$filename" -C "$ZIVPN_DIR" 2>/dev/null
                print_msg "Restore selesai"
                systemctl restart zivpn.service > /dev/null 2>&1
            else
                print_error "File tidak ditemukan!"
            fi
            ;;
        *) return ;;
    esac
    
    echo ""
    read -p "Press [Enter] untuk kembali..."
}

# === FUNGSI KONFIGURASI BOT ===
config_bot() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          KONFIGURASI BOT TELEGRAM${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        echo -e "${WHITE}Token saat ini:${NC} ${BOT_TOKEN:0:10}...${BOT_TOKEN: -5}"
        echo -e "${WHITE}Chat ID saat ini:${NC} $CHAT_ID"
    fi
    
    echo ""
    read -p "Bot Token [Enter jika tidak diubah]: " new_token
    read -p "Chat ID [Enter jika tidak diubah]: " new_chat_id
    
    if [ -n "$new_token" ]; then
        BOT_TOKEN="$new_token"
    fi
    if [ -n "$new_chat_id" ]; then
        CHAT_ID="$new_chat_id"
    fi
    
    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
        cat > "$BOT_CONFIG" << EOF
#!/bin/bash
BOT_TOKEN='$BOT_TOKEN'
CHAT_ID='$CHAT_ID'
EOF
        print_msg "Konfigurasi bot disimpan"
    fi
    
    sleep 2
}

# === FUNGSI AUTO BACKUP ===
auto_backup_settings() {
    clear
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}          PENGATURAN AUTO BACKUP${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
    
    if [ -f "/etc/cron.d/zivpn-autobackup" ]; then
        echo -e "${GREEN}Status: AKTIF (setiap 6 jam)${NC}"
        echo ""
        echo "1. Nonaktifkan"
        echo "2. Backup Sekarang"
        echo "3. Kembali"
        read -p "Pilih: " choice
        
        case $choice in
            1)
                rm -f /etc/cron.d/zivpn-autobackup
                print_msg "Auto backup dinonaktifkan"
                ;;
            2)
                /usr/local/bin/zivpn-autobackup.sh
                print_msg "Backup manual selesai"
                ;;
        esac
    else
        echo -e "${RED}Status: NONAKTIF${NC}"
        echo ""
        echo "1. Aktifkan (setiap 6 jam)"
        echo "2. Kembali"
        read -p "Pilih: " choice
        
        if [ "$choice" == "1" ]; then
            echo "0 */6 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            print_msg "Auto backup diaktifkan"
            /usr/local/bin/zivpn-autobackup.sh
        fi
    fi
    
    sleep 2
}

# === FUNGSI UNINSTALL ===
uninstall() {
    clear
    echo -e "${RED}═══════════════════════════════════════════════${NC}"
    echo -e "${RED}          UNINSTALL ZIVPN${NC}"
    echo -e "${RED}═══════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Peringatan: Semua data akan dihapus!${NC}"
    echo ""
    read -p "Yakin ingin uninstall? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
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
            echo -e "${GREEN}Semua data dihapus${NC}"
        fi
        
        systemctl daemon-reload
        echo -e "${GREEN}Uninstall selesai${NC}"
        exit 0
    fi
}

# === MENU UTAMA ===
show_menu() {
    clear
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    TOTAL_AKUN=$(jq length "$USERS_DB_JSON" 2>/dev/null || echo "0")
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         ZIVPN UDP MANAGER - LITE            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Domain :${NC} $DOMAIN"
    echo -e "${WHITE}IP     :${NC} $IP"
    echo -e "${WHITE}Akun   :${NC} $TOTAL_AKUN"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "  ${YELLOW}[1]${NC} ➕  Tambah Akun Reguler"
    echo -e "  ${YELLOW}[2]${NC} ⏳  Tambah Akun Trial"
    echo -e "  ${YELLOW}[3]${NC} 📋  Lihat Daftar Akun"
    echo -e "  ${YELLOW}[4]${NC} 🗑️  Hapus Akun"
    echo -e "  ${YELLOW}[5]${NC} 📅  Perpanjang Masa Aktif"
    echo -e "  ${YELLOW}[6]${NC} 👥  Cek Online User"
    echo -e "  ${YELLOW}[7]${NC} ℹ️  Info VPS"
    echo -e "  ${YELLOW}[8]${NC} 🌐  Ganti Domain"
    echo -e "  ${YELLOW}[9]${NC} 💾  Backup/Restore"
    echo -e "  ${YELLOW}[10]${NC} 🤖  Konfigurasi Bot"
    echo -e "  ${YELLOW}[11]${NC} ⏰  Auto Backup Settings"
    echo -e "  ${YELLOW}[12]${NC} ❌  Uninstall"
    echo -e "  ${YELLOW}[0]${NC} 🚪  Keluar"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -n -e "${WHITE}Pilih menu [0-12]: ${NC}"
}

# === MAIN LOOP ===
while true; do
    show_menu
    read choice
    
    case $choice in
        1) add_account ;;
        2) add_trial ;;
        3) list_accounts ;;
        4) delete_account ;;
        5) extend_expiry ;;
        6) check_online ;;
        7) vps_info ;;
        8) change_domain ;;
        9) backup_data ;;
        10) config_bot ;;
        11) auto_backup_settings ;;
        12) uninstall ;;
        0) 
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
