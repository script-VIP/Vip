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
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        
        echo -e "  ${WHITE}Status   :${NC} $([[ "$status" == "active" ]] && echo "${GREEN}● AKTIF${NC}" || echo "${RED}● MATI${NC}")"
        echo -e "  ${WHITE}IP       :${NC} ${CYAN}$ip${NC}"
        echo -e "  ${WHITE}Domain   :${NC} ${CYAN}$domain${NC}"
        echo -e "  ${WHITE}ISP      :${NC} ${YELLOW}$isp${NC}"
        echo -e "  ${WHITE}Lokasi   :${NC} ${YELLOW}$city${NC}"
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
    clear
    echo -e "${YELLOW}[ SET DOMAIN MANUAL ]${NC}"
    echo ""
    
    if [[ ! -f "$BACKUP_CONFIG" ]]; then
        echo "DOMAIN=\"\"" > "$BACKUP_CONFIG"
    fi
    
    source "$BACKUP_CONFIG"
    echo -e "Domain saat ini: ${CYAN}${DOMAIN:-Belum diatur}${NC}"
    echo ""
    read -rp "Masukkan domain baru: " new_domain
    
    if [[ -n "$new_domain" ]]; then
        echo "DOMAIN=\"$new_domain\"" > "$BACKUP_CONFIG"
        echo -e "${GREEN}Domain berhasil disimpan!${NC}"
    else
        echo -e "${YELLOW}Domain tidak diubah.${NC}"
    fi
    
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
    clear
    echo -e "${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users
    source "$BACKUP_CONFIG" 2>/dev/null

    read -rp "Masukkan nama/katakunci : " base_password
    if [[ -z "$base_password" ]]; then
        echo -e "${RED}[!] Tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    # Generate 3 digit angka random
    random_num=$((RANDOM % 900 + 100))
    password="${base_password}${random_num}"

    while user_exists "$password"; do
        random_num=$((RANDOM % 900 + 100))
        password="${base_password}${random_num}"
    done

    read -rp "Limit IP (0=unlimited) : " limit_ip
    if ! [[ "$limit_ip" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka!${NC}"
        press_enter
        return
    fi

    read -rp "Expired (hari) : " days
    
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

# === AUTO BACKUP ===

setup_auto_backup() {
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

USER_COUNT=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")

# Upload ke Google Drive (file.io sebagai alternatif)
UPLOAD_RESPONSE=$(curl -s -F "file=@$BACKUP_FILE" https://file.io)
LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)

# Buat caption sesuai permintaan
CAPTION="✅ BACKUP ZIVPN
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
    
    # Setup cron setiap 6 jam
    (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/zivpn-auto-backup.sh") | crontab -
    
    echo -e "${GREEN}Auto backup diaktifkan (setiap 6 jam)${NC}"
}

# === BACKUP MANUAL ===

backup_now() {
    clear
    echo -e "${YELLOW}[ BACKUP MANUAL ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    local ip=$(get_ip)
    local domain=$(get_domain)
    local date_now=$(date +"%Y-%m-%d")
    local file_date=$(date +"%Y%m%d-%H%M%S")
    
    local backup_file="$BACKUP_DIR/zivpn-backup-$file_date.tar.gz"
    echo "Membuat file backup..."
    tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    local user_count=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    
    echo "Upload ke Telegram..."
    
    # Upload ke file.io untuk dapat link
    UPLOAD_RESPONSE=$(curl -s -F "file=@$backup_file" https://file.io)
    LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
    
    # Buat caption sesuai permintaan
    local caption="✅ BACKUP ZIVPN
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
    
    echo -e "${GREEN}Backup selesai dan terkirim ke Telegram!${NC}"
    
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
    
    press_enter
}

# === RESTORE BACKUP ===

restore_backup() {
    clear
    echo -e "${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${WHITE}Pilih sumber backup:${NC}"
    echo -e "  ${CYAN}1${NC}. Dari file lokal"
    echo -e "  ${CYAN}2${NC}. Dari link download"
    echo -e "  ${CYAN}3${NC}. Lihat daftar link backup sebelumnya"
    echo ""
    read -rp "Pilih [1-3] : " restore_choice
    
    case $restore_choice in
        1)
            local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
            if [[ ${#backups[@]} -eq 0 ]]; then
                echo -e "${YELLOW}Tidak ada file backup lokal.${NC}"
                press_enter
                return
            fi
            
            echo -e "${WHITE}Pilih file backup:${NC}"
            for i in "${!backups[@]}"; do
                echo -e "  ${CYAN}$((i+1))${NC}. $(basename "${backups[$i]}")"
            done
            echo ""
            read -rp "Pilih nomor file : " file_num
            
            if [[ "$file_num" =~ ^[0-9]+$ ]] && [[ "$file_num" -le ${#backups[@]} ]]; then
                backup_file="${backups[$((file_num-1))]}"
            else
                echo -e "${RED}Pilihan tidak valid!${NC}"
                press_enter
                return
            fi
            ;;
        2)
            read -rp "Masukkan link download backup : " backup_link
            if [[ -z "$backup_link" ]]; then
                echo -e "${RED}Link tidak boleh kosong!${NC}"
                press_enter
                return
            fi
            
            echo -e "${YELLOW}Downloading backup...${NC}"
            backup_file="/tmp/backup-zivpn.tar.gz"
            wget -q "$backup_link" -O "$backup_file"
            
            if [[ ! -f "$backup_file" || ! -s "$backup_file" ]]; then
                echo -e "${RED}Gagal download backup! Cek link${NC}"
                press_enter
                return
            fi
            echo -e "${GREEN}Download selesai!${NC}"
            ;;
        3)
            if [[ -f "$BACKUP_DIR/backup-links.txt" ]]; then
                echo -e "${WHITE}Daftar link backup sebelumnya:${NC}"
                cat "$BACKUP_DIR/backup-links.txt"
            else
                echo -e "${YELLOW}Belum ada riwayat link backup.${NC}"
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
    echo -e "${RED}PERHATIAN: Restore akan menimpa semua data user yang ada!${NC}"
    read -rp "Yakin ingin restore? [y/N] : " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore dibatalkan.${NC}"
        press_enter
        return
    fi
    
    echo -e "${YELLOW}Menghentikan service...${NC}"
    systemctl stop zivpn.service
    
    echo -e "${YELLOW}Merestore backup...${NC}"
    tar -xzf "$backup_file" -C /
    
    echo -e "${YELLOW}Menjalankan ulang service...${NC}"
    systemctl start zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil!${NC}"
    
    send_telegram "✅ RESTORE BACKUP
◇━━━━━━━━━━━━━━◇
Backup telah direstore
File: $(basename "$backup_file")
◇━━━━━━━━━━━━━━◇"
    
    press_enter
}

# === HAPUS USER ===

delete_user() {
    clear
    echo -e "${YELLOW}[ HAPUS USER ]${NC}"
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
    read -rp "Password user yang ingin dihapus : " password

    if ! user_exists "$password"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "Yakin hapus? [y/N] : " confirm
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
    clear
    echo -e "${YELLOW}[ DAFTAR USER ]${NC}"
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
    clear
    echo -e "${YELLOW}[ PERPANJANG USER ]${NC}"
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
    read -rp "Password user : " password

    if ! user_exists "$password"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "Jumlah hari tambahan (0=unlimited) : " days

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Masukkan angka!${NC}"
        press_enter
        return
    fi

    local old_expiry=$(grep "^$password|" "$USERS_DB" | cut -d'|' -f2)
    local limit=$(grep "^$password|" "$USERS_DB" | cut -d'|' -f3)

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

    sed -i "s/^$password|$old_expiry|$limit/$password|$new_expiry|$limit/" "$USERS_DB"
    update_config_json

    echo -e "${GREEN}User '$password' berhasil diperpanjang!${NC}"
    
    send_telegram "🔄 USER DIPERPANJANG\nPassword: $password\nExpired: $new_expiry"
    
    press_enter
}

# === HAPUS EXPIRED ===

clean_expired() {
    clear
    echo -e "${YELLOW}[ HAPUS USER EXPIRED ]${NC}"
    echo ""
    load_users

    local today=$(date +%Y-%m-%d)
    local count=0
    local tmpfile=$(mktemp)

    while IFS='|' read -r pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass (expired: $expiry)"
            ((count++))
        else
            echo "$pass|$expiry|$limit" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}✓ $count user expired berhasil dihapus!${NC}"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}Tidak ada user expired.${NC}"
    fi

    press_enter
}

# === STATUS SERVICE ===

status_service() {
    clear
    echo -e "${YELLOW}[ STATUS SERVICE ]${NC}"
    echo ""
    systemctl status zivpn.service --no-pager
    press_enter
}

# === RESTART SERVICE ===

restart_service() {
    clear
    echo -e "${YELLOW}[ RESTART SERVICE ]${NC}"
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

# === INSTALL ===

install_zivpn() {
    clear
    echo -e "${YELLOW}[ INSTALL ZIVPN UDP ]${NC}"
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

    # Setup auto backup
    setup_auto_backup

    # Setup cron hapus expired (jam 3 malam)
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
    echo "Ketik 'zivpn' untuk buka menu"
    
    send_telegram "✅ ZIVPN INSTALLED
◇━━━━━━━━━━━━━━◇
IP     : $(get_ip)
Domain : $(get_domain)
ISP    : $(get_isp)
Waktu  : $(date +"%d %B %Y %H:%M")
◇━━━━━━━━━━━━━━◇"
    
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    clear
    echo -e "${RED}[ UNINSTALL ZIVPN ]${NC}"
    echo ""
    read -rp "Yakin ingin uninstall? [y/N] : " confirm

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

# === MENU UTAMA ===

menu() {
    clear
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
        echo "6. Hapus User Expired"
        echo "7. Status Service"
        echo "8. Restart Service"
        echo "9. Backup Manual"
        echo "10. Restore Backup"
        echo "11. Update Script"
        echo "12. Uninstall ZIVPN"
        echo ""
        read -rp "Pilih menu [1-12] : " choice

        case $choice in
            1) add_user ;;
            2) delete_user ;;
            3) list_users ;;
            4) renew_user ;;
            5) set_domain ;;
            6) clean_expired ;;
            7) status_service ;;
            8) restart_service ;;
            9) backup_now ;;
            10) restore_backup ;;
            11) echo "Update script..." ;;
            12) uninstall_zivpn ;;
            *) echo "Pilihan tidak valid!"; sleep 1 ;;
        esac
    fi
    
    menu
}

# === START ===

check_root
menu
