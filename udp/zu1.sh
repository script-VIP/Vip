#!/bin/bash
set +e
# =============================================
#   ZIVPN UDP Manager - SWEATER PINK EDITION
#   By: Custom Script
#   OS: Ubuntu 20.04 / 22.04 / 24.04
# =============================================

# === KONFIGURASI BOT TELEGRAM (LANGSUNG AKTIF) ===
BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
CHAT_ID="6198984094"

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
CONFIG="$ZIVPN_DIR/config.json"
USERS_DB="$ZIVPN_DIR/users.db"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
BACKUP_DIR="/root/backup-zivpn"
DOMAIN_FILE="$ZIVPN_DIR/domain.conf"
TG_FILE="$ZIVPN_DIR/telegram.conf"

# === BUAT DIREKTORI ===
mkdir -p "$ZIVPN_DIR"
mkdir -p "$BACKUP_DIR"
[ ! -f "$DOMAIN_FILE" ] && echo "-" > "$DOMAIN_FILE"

# === LOAD DOMAIN ===
DOMAIN=$(cat "$DOMAIN_FILE")

# === LOAD TELEGRAM CONFIG ===
if [ -f "$TG_FILE" ]; then
  source "$TG_FILE"
fi

# === ENSURE DEPENDENCIES ===
for pkg in jq zip unzip curl wget net-tools dnsutils; do
  if ! command -v $pkg >/dev/null 2>&1; then
    apt update -y >/dev/null 2>&1
    apt install -y $pkg >/dev/null 2>&1
  fi
done

# === ENSURE RCLONE ===
if ! command -v rclone >/dev/null 2>&1; then
  curl https://rclone.org/install.sh | bash >/dev/null 2>&1
fi

# === SYSTEM INFO ===
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
    echo "${used_ram}MB/${total_ram}MB"
}

get_cpu() {
    nproc
}

get_os() {
    lsb_release -d 2>/dev/null | cut -d':' -f2 | xargs
}

get_uptime() {
    uptime -p | sed 's/up //'
}

# === TELEGRAM FUNCTION ===
send_telegram() {
    [ -z "$BOT_TOKEN" ] && return
    [ -z "$CHAT_ID" ] && return
    local TEXT="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        --data-urlencode "text=$TEXT" \
        --data-urlencode "parse_mode=Markdown" >/dev/null 2>&1
}

send_telegram_file() {
    [ -z "$BOT_TOKEN" ] && return
    [ -z "$CHAT_ID" ] && return
    local file="$1"
    local caption="$2"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" >/dev/null 2>&1
}

# === UPDATE CONFIG JSON ===
update_config_json() {
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            passwords+=("\"$pass\"")
        fi
    done < "$USERS_DB" 2>/dev/null

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

# === BANNER ===
banner() {
    clear
    IP=$(get_ip)
    DOMAIN=$(cat "$DOMAIN_FILE")
    ISP=$(get_isp)
    CITY=$(get_city)
    RAM=$(get_ram)
    CPU=$(get_cpu)
    OS=$(get_os)
    UPTIME=$(get_uptime)
    STATUS=$(systemctl is-active zivpn.service 2>/dev/null)
    USER_COUNT=$(grep -c '|' "$USERS_DB" 2>/dev/null || echo "0")
    
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}     Z I V P N   S W E A T E R   P I N K${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${GREEN} OS      ${NC}: $OS"
    echo -e "${GREEN} Domain  ${NC}: ${YELLOW}$DOMAIN${NC}"
    echo -e "${GREEN} IP      ${NC}: $IP"
    echo -e "${GREEN} Uptime  ${NC}: $UPTIME"
    echo -e "${GREEN} CPU     ${NC}: $CPU Core"
    echo -e "${GREEN} RAM     ${NC}: $RAM"
    echo -e "${GREEN} ISP     ${NC}: $ISP"
    echo -e "${GREEN} Lokasi  ${NC}: $CITY"
    echo -e "${GREEN} ZIVPN   ${NC}: ${YELLOW}$STATUS${NC}"
    echo -e "${GREEN} Users   ${NC}: ${YELLOW}$USER_COUNT${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan [ENTER] untuk kembali...${NC}"
    read -r
}

# === CREATE ACCOUNT ===
create_account() {
    clear
    echo -e "${BOLD}${YELLOW}[ CREATE ACCOUNT ]${NC}"
    echo ""

    while true; do
        read -rp " Username : " USER
        [ -z "$USER" ] && echo "Username tidak boleh kosong!" && continue
        if grep -q "^$USER|" "$USERS_DB"; then
            echo "❌ Username '$USER' sudah ada!"
            continue
        fi
        break
    done

    read -rp " Duration (days) : " DAYS
    read -rp " IP Limit (0=unlimited) : " LIMIT
    
    PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    EXP=$(date -d "$DAYS days +1 day" +"%Y-%m-%d 00:00")

    jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
    echo "$USER|$PASS|$EXP|$LIMIT" >> "$USERS_DB"

    systemctl restart zivpn

    send_telegram "📢 *PEMBELIAN BERHASIL*
────────────────────
🌐 Domain   : $DOMAIN
👤 Username : $USER
🔐 Password : $PASS
⏳ Expired  : $EXP
📆 Hari     : $DAYS Hari
📱 Limit IP : $LIMIT
────────────────────"

    clear
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ACCOUNT CREATED SUCCESSFULLY${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "  Domain   : ${CYAN}$DOMAIN${NC}"
    echo -e "  Username : ${YELLOW}$USER${NC}"
    echo -e "  Password : ${YELLOW}$PASS${NC}"
    echo -e "  Expired  : ${GREEN}$EXP${NC}"
    echo -e "  Limit IP : ${CYAN}$LIMIT${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    read -p "Press Enter..."
}

# === CREATE TRIAL ===
create_trial() {
    clear
    echo -e "${BOLD}${YELLOW}[ CREATE TRIAL ]${NC}"
    echo ""
    read -rp " Trial duration (minutes): " MIN
    [[ -z "$MIN" || "$MIN" -le 0 ]] && return

    USER="trial$(tr -dc 0-9 </dev/urandom | head -c 4)"
    PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
    EXP=$(date -d "+$MIN minutes" +"%Y-%m-%d %H:%M")
    LIMIT=1

    jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
    echo "$USER|$PASS|$EXP|$LIMIT" >> "$USERS_DB"
    systemctl restart zivpn

    send_telegram "⏱ *TRIAL ACCOUNT*
────────────────────
🌐 Domain   : $DOMAIN
👤 Username : $USER
🔐 Password : $PASS
⏳ Expired  : $EXP
📱 IP Limit : 1
────────────────────"

    clear
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ TRIAL CREATED${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "  Domain   : ${CYAN}$DOMAIN${NC}"
    echo -e "  Username : ${YELLOW}$USER${NC}"
    echo -e "  Password : ${YELLOW}$PASS${NC}"
    echo -e "  Expired  : ${GREEN}$EXP${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    read -p "Press Enter..."
}

# === LIST ACCOUNTS ===
list_accounts() {
    clear
    echo -e "${BOLD}${YELLOW}[ LIST ACCOUNTS ]${NC}"
    echo "─────────────────────────────────────────────────────────────────"
    printf "${WHITE}%-4s %-15s %-20s %-18s %-8s${NC}\n" "No" "Username" "Password" "Expired" "Limit"
    echo "─────────────────────────────────────────────────────────────────"
    
    if [[ ! -f "$USERS_DB" || ! -s "$USERS_DB" ]]; then
        echo "  Tidak ada user terdaftar"
    else
        nl -w2 -s'. ' "$USERS_DB" | while read -r n l; do
            IFS='|' read -r U P E L <<< "$l"
            [ -z "$L" ] && L="∞"
            printf "%-4s %-15s %-20s %-18s %-8s\n" "$n" "$U" "$P" "$E" "$L"
        done
    fi
    
    echo "─────────────────────────────────────────────────────────────────"
    read -p "Press Enter..."
}

# === DELETE ACCOUNT ===
delete_account() {
    list_accounts
    echo ""
    echo -e "${RED}[ DELETE ACCOUNT ]${NC}"
    echo "───────────────────────────────────"
    echo "• Input NUMBER (1,2,3...)"
    echo "• Atau input USERNAME"
    echo "───────────────────────────────────"
    read -rp " Input : " INPUT

    if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
        LINE=$(sed -n "${INPUT}p" "$USERS_DB" 2>/dev/null)
        [ -z "$LINE" ] && echo "Nomor tidak valid!" && sleep 2 && return
        PASS=$(echo "$LINE" | awk -F'|' '{print $2}')
        sed -i "${INPUT}d" "$USERS_DB"
    else
        USERNAME="$INPUT"
        LINE_NUM=$(awk -F'|' -v u="$USERNAME" '$1==u {print NR}' "$USERS_DB")
        [ -z "$LINE_NUM" ] && echo "Username tidak ditemukan!" && sleep 2 && return
        PASS=$(awk -F'|' -v u="$USERNAME" '$1==u {print $2}' "$USERS_DB")
        sed -i "${LINE_NUM}d" "$USERS_DB"
    fi

    jq --arg pass "$PASS" '.auth.config -= [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
    systemctl restart zivpn

    echo -e "${GREEN}Account deleted successfully!${NC}"
    sleep 2
}

# === RENEW ACCOUNT ===
renew_account() {
    list_accounts
    echo ""
    read -rp " Renew account number : " NUM
    read -rp " Extend days : " DAYS

    LINE=$(sed -n "${NUM}p" "$USERS_DB" 2>/dev/null)
    [ -z "$LINE" ] && echo "Nomor tidak valid!" && sleep 2 && return

    IFS='|' read -r U P E L <<< "$LINE"
    BASE_DATE=$(echo "$E" | cut -d' ' -f1)
    NEWEXP=$(date -d "$BASE_DATE +$DAYS days +1 day" +"%Y-%m-%d 00:00")

    sed -i "${NUM}c\\$U|$P|$NEWEXP|$L" "$USERS_DB"
    systemctl restart zivpn

    echo -e "${GREEN}Account renewed successfully!${NC}"
    sleep 2
}

# === DELETE ALL EXPIRED ===
delete_all_expired() {
    clear
    echo -e "${BOLD}${YELLOW}[ DELETE EXPIRED ACCOUNTS ]${NC}"
    echo ""
    
    if [[ ! -f "$USERS_DB" ]]; then
        echo -e "${YELLOW}Tidak ada database user${NC}"
        sleep 2
        return
    fi
    
    NOW=$(date +"%Y-%m-%d %H:%M")
    TMP="/tmp/zivpn-clean.db"
    > "$TMP"
    COUNT=0

    while IFS='|' read -r U P E L; do
        if [[ "$E" < "$NOW" ]]; then
            jq --arg pass "$P" '.auth.config -= [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
            ((COUNT++))
        else
            echo "$U|$P|$E|$L" >> "$TMP"
        fi
    done < "$USERS_DB"

    mv "$TMP" "$USERS_DB"
    systemctl restart zivpn

    echo -e "${GREEN}✓ $COUNT expired accounts deleted${NC}"
    sleep 2
}

# === CHECK USER USAGE ===
check_usage() {
    clear
    echo -e "${BOLD}${YELLOW}[ USER USAGE MONITOR ]${NC}"
    echo "─────────────────────────────────────────────────────"
    printf "%-15s %-20s %-8s %-10s\n" "Username" "Password" "Limit" "Status"
    echo "─────────────────────────────────────────────────────"

    if [[ ! -f "$USERS_DB" ]]; then
        echo "  Tidak ada user terdaftar"
    else
        while IFS='|' read -r U P E L; do
            [ -z "$L" ] && L="∞"
            if ss -un state connected "( sport = :5667 )" 2>/dev/null | grep -q .; then
                STATUS="${GREEN}ONLINE${NC}"
            else
                STATUS="${RED}OFFLINE${NC}"
            fi
            printf "%-15s %-20s %-8s %b\n" "$U" "$P" "$L" "$STATUS"
        done < "$USERS_DB"
    fi

    echo "─────────────────────────────────────────────────────"
    TOTAL_IP=$(ss -un state connected "( sport = :5667 )" 2>/dev/null | wc -l)
    echo "Total Koneksi Server: $TOTAL_IP"
    read -p "Press Enter..."
}

# === CHANGE DOMAIN ===
change_domain() {
    clear
    echo -e "${BOLD}${YELLOW}[ CHANGE DOMAIN ]${NC}"
    echo ""
    echo -e "  Domain saat ini: ${CYAN}$(cat "$DOMAIN_FILE")${NC}"
    echo ""
    read -rp "  New Domain : " NEWDOMAIN
    [ -z "$NEWDOMAIN" ] && return

    echo "$NEWDOMAIN" > "$DOMAIN_FILE"

    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=ID/ST=VPN/L=ZIVPN/O=ZIVPN/OU=ZIVPN/CN=$NEWDOMAIN" \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" 2>/dev/null

    systemctl restart zivpn
    DOMAIN="$NEWDOMAIN"

    echo -e "${GREEN}Domain updated successfully!${NC}"
    sleep 2
}

# === TELEGRAM SETTING ===
telegram_setting() {
    clear
    echo -e "${BOLD}${YELLOW}[ TELEGRAM BOT SETTING ]${NC}"
    echo "══════════════════════════════════════"
    echo ""
    read -rp " Input Bot Token : " NEW_BOT_TOKEN
    read -rp " Input Chat ID   : " NEW_CHAT_ID

    if [[ -z "$NEW_BOT_TOKEN" || -z "$NEW_CHAT_ID" ]]; then
        echo -e "${RED}Bot Token & Chat ID tidak boleh kosong!${NC}"
        sleep 2
        return
    fi

    cat > "$TG_FILE" <<EOF
BOT_TOKEN="$NEW_BOT_TOKEN"
CHAT_ID="$NEW_CHAT_ID"
EOF

    chmod 600 "$TG_FILE"
    source "$TG_FILE"

    echo -e "${GREEN}Telegram Bot berhasil disimpan!${NC}"
    echo "Bot Token : $NEW_BOT_TOKEN"
    echo "Chat ID   : $NEW_CHAT_ID"
    sleep 2
}

# === BACKUP FUNCTIONS ===
backup_zivpn_drive() {
    clear
    echo -e "${BOLD}${YELLOW}[ BACKUP ZIVPN ]${NC}"
    echo ""
    
    DATE=$(date +%Y%m%d-%H%M)
    FILE="$BACKUP_DIR/zivpn-backup-$DATE.zip"
    REMOTE="gdrive:ZIVPN-BACKUP"

    echo -e "${BLUE}[1/3]${NC} Membuat file backup..."
    zip -r "$FILE" \
        "$USERS_DB" \
        "$CONFIG" \
        "$DOMAIN_FILE" \
        "$CERT_FILE" \
        "$KEY_FILE" \
        "$TG_FILE" \
        /root/.config/rclone/rclone.conf 2>/dev/null

    # Hitung jumlah user
    USER_COUNT=$(grep -c '|' "$USERS_DB" 2>/dev/null || echo "0")
    FILE_SIZE=$(du -h "$FILE" | cut -f1)

    echo -e "${GREEN}    ✓ Backup berhasil dibuat${NC}"
    echo -e "${BLUE}[2/3]${NC} Mengirim ke Telegram..."

    # Upload ke file.io untuk mendapatkan link
    UPLOAD_RESPONSE=$(curl -s -F "file=@$FILE" https://file.io)
    LINK=$(echo "$UPLOAD_RESPONSE" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)

    # Simpan link
    echo "$(date +"%Y-%m-%d") - $LINK" >> "$BACKUP_DIR/backup-links.txt"

    # Buat caption
    local caption="✅ *BACKUP ZIVPN SUKSES*
════════════════════════
Waktu Backup : $(date +"%Y-%m-%d %H:%M:%S")
IP Address   : $(get_ip)
Domain       : $(cat "$DOMAIN_FILE")
Jumlah User  : $USER_COUNT User
Ukuran File  : $FILE_SIZE
Link Download: $LINK
════════════════════════"

    send_telegram_file "$FILE" "$caption"
    
    echo -e "${GREEN}    ✓ Backup terkirim ke Telegram${NC}"
    echo -e "${BLUE}[3/3]${NC} Upload ke Google Drive..."

    # Upload ke Google Drive jika rclone tersedia
    DRIVE_STATUS=""
    if command -v rclone >/dev/null 2>&1; then
        if rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
            rclone mkdir "$REMOTE" 2>/dev/null
            rclone copy "$FILE" "$REMOTE" 2>/dev/null
            DRIVE_STATUS="✓ Google Drive: ZIVPN-BACKUP"
        fi
    fi

    echo ""
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ BACKUP BERHASIL!${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "  File    : ${CYAN}$(basename "$FILE")${NC}"
    echo -e "  Ukuran  : ${YELLOW}$FILE_SIZE${NC}"
    echo -e "  User    : ${GREEN}$USER_COUNT${NC}"
    echo -e "  Link    : ${CYAN}$LINK${NC}"
    if [[ -n "$DRIVE_STATUS" ]]; then
        echo -e "  $DRIVE_STATUS"
    fi
    echo -e "${GREEN}══════════════════════════════════════${NC}"

    # Hapus backup lama (simpan 7 backup terakhir)
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f

    press_enter
}

restore_zivpn_drive() {
    clear
    echo -e "${BOLD}${YELLOW}[ RESTORE ZIVPN ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${WHITE}Pilih sumber backup:${NC}"
    echo -e "  ${CYAN}1${NC}. Dari file lokal"
    echo -e "  ${CYAN}2${NC}. Dari link download"
    echo -e "  ${CYAN}3${NC}. Lihat daftar link backup"
    echo ""
    read -rp "Pilih [1-3] : " restore_choice
    
    case $restore_choice in
        1)
            local backups=($(ls -t "$BACKUP_DIR"/*.zip 2>/dev/null))
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
            backup_file="/tmp/zivpn-restore.zip"
            
            # Deteksi jika link Google Drive
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
                wget -q "$backup_link" -O "$backup_file"
            fi
            
            if [[ ! -f "$backup_file" || ! -s "$backup_file" ]]; then
                echo -e "${RED}Gagal download backup!${NC}"
                press_enter
                return
            fi
            echo -e "${GREEN}Download selesai!${NC}"
            ;;
        3)
            if [[ -f "$BACKUP_DIR/backup-links.txt" ]]; then
                echo -e "${WHITE}Daftar link backup sebelumnya:${NC}"
                echo "────────────────────────────────"
                cat "$BACKUP_DIR/backup-links.txt"
                echo "────────────────────────────────"
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
    echo -e "${RED}PERHATIAN: Restore akan menimpa semua data yang ada!${NC}"
    read -rp "Yakin ingin restore? [y/N] : " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore dibatalkan.${NC}"
        [[ "$restore_choice" == "2" ]] && rm -f "$backup_file"
        press_enter
        return
    fi
    
    # Backup data lama
    local old_backup="$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).zip"
    echo -e "${BLUE}[1/3]${NC} Backup data lama..."
    zip -r "$old_backup" "$USERS_DB" "$CONFIG" "$DOMAIN_FILE" "$CERT_FILE" "$KEY_FILE" "$TG_FILE" 2>/dev/null
    
    echo -e "${BLUE}[2/3]${NC} Menghentikan service..."
    systemctl stop zivpn.service
    
    echo -e "${BLUE}[3/3]${NC} Merestore backup..."
    unzip -o "$backup_file" -d / >/dev/null 2>&1
    
    echo -e "${YELLOW}Menjalankan ulang service...${NC}"
    systemctl start zivpn.service
    
    # Reload domain
    DOMAIN=$(cat "$DOMAIN_FILE")
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ RESTORE BERHASIL!${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "  File backup lama: ${CYAN}$old_backup${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    
    send_telegram "✅ *RESTORE BACKUP*
════════════════════════
File: $(basename "$backup_file")
Waktu: $(date +"%Y-%m-%d %H:%M:%S")
════════════════════════"
    
    [[ "$restore_choice" == "2" ]] && rm -f "$backup_file"
    press_enter
}

# === AUTO BACKUP SETUP ===
setup_auto_backup() {
    crontab -l 2>/dev/null | grep -v "zivpn-menu" | crontab -
    
    echo -e "${WHITE}Pilih jam auto backup (0-23):${NC}"
    read -rp "Jam (contoh: 3 untuk jam 3 pagi) : " HOUR

    if ! [[ "$HOUR" =~ ^[0-9]+$ ]] || [ "$HOUR" -gt 23 ]; then
        echo -e "${RED}Jam tidak valid, menggunakan default jam 3 pagi${NC}"
        HOUR=3
    fi

    crontab -l 2>/dev/null | grep -v "zivpn-menu" > /tmp/cron.tmp
    echo "0 $HOUR * * * /usr/bin/zivpn-menu --autobackup" >> /tmp/cron.tmp
    crontab /tmp/cron.tmp
    rm -f /tmp/cron.tmp

    echo -e "${GREEN}Auto backup diaktifkan setiap jam $HOUR:00${NC}"
    sleep 2
}

disable_auto_backup() {
    crontab -l 2>/dev/null | grep -v "zivpn-menu" | crontab -
    echo -e "${YELLOW}Auto backup dimatikan${NC}"
    sleep 2
}

# === BACKUP & RESTORE MENU ===
backup_restore_menu() {
    while true; do
        clear
        echo -e "${BOLD}${YELLOW}[ BACKUP & RESTORE MENU ]${NC}"
        echo -e "${CYAN}══════════════════════════════════════${NC}"
        echo -e "  ${GREEN}1${NC}. Backup Sekarang"
        echo -e "  ${GREEN}2${NC}. Restore Backup"
        echo -e "  ${GREEN}3${NC}. Aktifkan Auto Backup"
        echo -e "  ${GREEN}4${NC}. Nonaktifkan Auto Backup"
        echo -e "  ${GREEN}5${NC}. Lihat Daftar Link Backup"
        echo -e "  ${RED}0${NC}. Kembali"
        echo -e "${CYAN}══════════════════════════════════════${NC}"
        read -rp "Pilih menu : " br_choice

        case $br_choice in
            1) backup_zivpn_drive ;;
            2) restore_zivpn_drive ;;
            3) setup_auto_backup ;;
            4) disable_auto_backup ;;
            5) 
                if [[ -f "$BACKUP_DIR/backup-links.txt" ]]; then
                    clear
                    echo -e "${BOLD}${YELLOW}[ DAFTAR LINK BACKUP ]${NC}"
                    echo "────────────────────────────────"
                    cat "$BACKUP_DIR/backup-links.txt"
                    echo "────────────────────────────────"
                else
                    echo -e "${YELLOW}Belum ada riwayat link backup.${NC}"
                fi
                press_enter
                ;;
            0) return ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# === AUTO BACKUP MODE ===
if [[ "$1" == "--autobackup" ]]; then
    backup_zivpn_drive
    exit 0
fi

# === INSTALL ZIVPN ===
install_zivpn() {
    clear
    echo -e "${BOLD}${YELLOW}[ INSTALL ZIVPN UDP ]${NC}"
    echo ""

    if [[ -f "$ZIVPN_BIN" && -f "$CONFIG" ]]; then
        echo -e "${YELLOW}ZIVPN sudah terinstall!${NC}"
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

    # Setup cron hapus expired (jam 3 pagi)
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/zivpn-cron.sh") | crontab -

    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
CONFIG="/etc/zivpn/config.json"
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

cat > "$CONFIG" <<EOF
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
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "  IP      : ${CYAN}$(get_ip)${NC}"
    echo -e "  Domain  : ${CYAN}$(get_domain)${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo ""

    cp "$(realpath $0)" /usr/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/bin/zivpn-menu 2>/dev/null
    echo "alias zivpn='zivpn-menu'" >> /root/.bashrc 2>/dev/null
    
    send_telegram "✅ *ZIVPN INSTALLED*
══════════════════════
IP     : $(get_ip)
Domain : $(get_domain)
Waktu  : $(date +"%d %B %Y %H:%M")
══════════════════════"
    
    press_enter
}

# === UNINSTALL ===
uninstall_zivpn() {
    clear
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN ]${NC}"
    echo ""
    read -rp "Yakin ingin uninstall? [y/N] : " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -f /usr/local/bin/zivpn-cron.sh
    rm -f /usr/bin/zivpn-menu
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -

    echo -e "${GREEN}Uninstall selesai!${NC}"
    send_telegram "❌ *ZIVPN UNINSTALL*\nIP: $(get_ip)"
    sleep 2
    exit 0
}

# === UPDATE SCRIPT ===
update_script() {
    clear
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}"
    echo ""

    local SCRIPT_URL="https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zs.sh"
    local SCRIPT_PATH="/usr/bin/zivpn-menu"
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
        exec zivpn-menu
    fi

    press_enter
}

# === RESTART SERVICE ===
restart_service() {
    clear
    echo -e "${BOLD}${YELLOW}[ RESTART SERVICE ]${NC}"
    echo ""
    systemctl restart zivpn.service
    sleep 1
    if systemctl is-active zivpn.service > /dev/null; then
        echo -e "${GREEN}✓ Service berhasil di-restart!${NC}"
        send_telegram "🔄 *SERVICE RESTART*\nService ZIVPN UDP direstart"
    else
        echo -e "${RED}✗ Service gagal restart!${NC}"
    fi
    press_enter
}

# === STATUS SERVICE ===
status_service() {
    clear
    echo -e "${BOLD}${YELLOW}[ STATUS SERVICE ]${NC}"
    echo ""
    systemctl status zivpn.service --no-pager
    press_enter
}

# === CHECK ROOT ===
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] Script ini harus dijalankan sebagai root!${NC}"
    exit 1
fi

# === MAIN MENU ===
while true; do
    banner

    if [[ ! -f "$ZIVPN_BIN" || ! -f "$CONFIG" ]]; then
        echo -e "${RED}  [!] ZIVPN belum terinstall!${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
        echo ""
        read -rp "Pilih menu [1] : " choice
        case $choice in
            1) install_zivpn ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    else
        echo -e "  ${GREEN}1${WHITE}. Create Account"
        echo -e "  ${GREEN}2${WHITE}. Create Trial"
        echo -e "  ${CYAN}3${WHITE}. List Accounts"
        echo -e "  ${RED}4${WHITE}. Delete Account"
        echo -e "  ${YELLOW}5${WHITE}. Renew Account"
        echo -e "  ${MAGENTA}6${WHITE}. Delete Expired"
        echo -e "  ${BLUE}7${WHITE}. Check User Usage"
        echo -e "  ${GREEN}8${WHITE}. Change Domain"
        echo -e "  ${PURPLE}9${WHITE}. Telegram Setting"
        echo -e "  ${CYAN}10${WHITE}. Backup & Restore"
        echo -e "  ${BLUE}11${WHITE}. Restart Service"
        echo -e "  ${BLUE}12${WHITE}. Status Service"
        echo -e "  ${GREEN}13${WHITE}. Update Script"
        echo -e "  ${RED}14${WHITE}. Uninstall ZIVPN"
        echo -e "  ${RED}0${WHITE}. Exit"
        echo ""
        read -rp "Pilih menu [0-14] : " choice

        case $choice in
            1) create_account ;;
            2) create_trial ;;
            3) list_accounts ;;
            4) delete_account ;;
            5) renew_account ;;
            6) delete_all_expired ;;
            7) check_usage ;;
            8) change_domain ;;
            9) telegram_setting ;;
            10) backup_restore_menu ;;
            11) restart_service ;;
            12) status_service ;;
            13) update_script ;;
            14) uninstall_zivpn ;;
            0) exit ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    fi
done
