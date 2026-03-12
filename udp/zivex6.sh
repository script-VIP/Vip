#!/bin/bash
# =============================================
#   ZIVPN EXPRESS MANAGER - SIMPLE VERSION
#   Store: Zivpn Express
#   Update: wget -O zivex.sh https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zivex.sh && chmod +x zivex.sh && bash zivex.sh
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

# Buat direktori
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
NC='\033[0m'
BOLD='\033[1m'

# === TELEGRAM CONFIG ===
if [ -f "$TG_FILE" ]; then
  source "$TG_FILE"
else
  BOT_TOKEN="8504261570:AAF5rtJ2wW9nrS6EOMyScB5ZGnZcL8sRcXA"
  CHAT_ID="6198984094"
  cat > "$TG_FILE" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF
  chmod 600 "$TG_FILE"
fi

# === FUNGSI UTILITAS ===
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERROR: Script harus dijalankan sebagai root${NC}"
        exit 1
    fi
}

get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}'
}

get_location() {
    curl -s ipinfo.io/city 2>/dev/null || echo "Unknown"
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
    read -r
}

# === UPDATE CONFIG DARI DATABASE ===
update_config_json() {
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

# === FUNGSI TELEGRAM (TANPA MARKDOWN) ===
send_telegram() {
    local message="$1"
    [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ] && return 1
    
    # Kirim sebagai teks biasa
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" > /dev/null 2>&1
}

# === FUNGSI HITUNG SISA HARI ===
hitung_sisa_hari() {
    local expiry="$1"
    local today_epoch=$(date +%s)
    local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
    local diff_seconds=$((exp_epoch - today_epoch))
    local diff_hari=$((diff_seconds / 86400))
    local sisa_jam=$(( (diff_seconds % 86400) / 3600 ))
    local sisa_menit=$(( (diff_seconds % 3600) / 60 ))
    
    # Pembulatan ke atas
    if [[ $sisa_jam -gt 0 ]] || [[ $sisa_menit -gt 0 ]]; then
        echo $((diff_hari + 1))
    else
        echo $diff_hari
    fi
}

# === BACKUP LANGSUNG (SIMPLE) ===
backup_langsung() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            BACKUP LANGSUNG KE TELEGRAM${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user untuk di-backup${NC}"
        press_enter
        return
    fi
    
    echo -e "${GREEN}Menyiapkan backup...${NC}"
    
    local today_epoch=$(date +%s)
    local message=""
    
    # Header
    message="📁 BACKUP ZIVPN EXPRESS
Waktu  : $(date +"%d %B %Y %H:%M")
Domain : $DOMAIN
IP     : $(get_ip)
═══════════════════
"
    
    local current_limit=""
    local total_user=0
    local limit_section=""
    
    while IFS='|' read -r user pass expiry limit; do
        # Skip expired
        if [[ "$expiry" != "unlimited" ]]; then
            local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            if [[ $exp_epoch -lt $today_epoch ]]; then
                continue
            fi
        fi
        
        # Jika limit berubah, tambahkan section sebelumnya
        if [[ "$limit" != "$current_limit" ]] && [[ -n "$current_limit" ]]; then
            message="${message}${limit_section}"
            limit_section=""
        fi
        
        # Jika limit baru, buat header limit
        if [[ "$limit" != "$current_limit" ]]; then
            current_limit="$limit"
            limit_section="Limit IP: $limit\n"
        fi
        
        # Hitung sisa hari
        if [[ "$expiry" == "unlimited" ]]; then
            limit_section="${limit_section}$pass 0\n"
        else
            local sisa_hari=$(hitung_sisa_hari "$expiry")
            limit_section="${limit_section}$pass $sisa_hari\n"
        fi
        ((total_user++))
        
    done < "$DB"
    
    # Tambahkan section terakhir
    if [[ -n "$limit_section" ]]; then
        message="${message}${limit_section}═══════════════════\n"
    fi
    
    # Footer
    message="${message}Total User: $total_user"
    
    echo -e "${GREEN}Mengirim ke Telegram...${NC}"
    
    # Kirim per bagian jika terlalu panjang
    if [[ ${#message} -gt 4000 ]]; then
        echo "${message}" > /tmp/backup_temp.txt
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@/tmp/backup_temp.txt \
            -F caption="📁 BACKUP ZIVPN EXPRESS" > /dev/null 2>&1
        rm -f /tmp/backup_temp.txt
    else
        # Kirim langsung
        send_telegram "$message"
    fi
    
    echo -e "${GREEN}✓ Backup terkirim${NC}"
    sleep 2
}

# === AUTO BACKUP ===
auto_backup() {
    source "$TG_FILE" 2>/dev/null
    
    local today_epoch=$(date +%s)
    local message=""
    
    # Header
    message="📁 BACKUP ZIVPN EXPRESS
Waktu  : $(date +"%d %B %Y %H:%M")
Domain : $DOMAIN
IP     : $(get_ip)
═══════════════════
"
    
    local current_limit=""
    local total_user=0
    local limit_section=""
    
    while IFS='|' read -r user pass expiry limit; do
        # Skip expired
        if [[ "$expiry" != "unlimited" ]]; then
            local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            if [[ $exp_epoch -lt $today_epoch ]]; then
                continue
            fi
        fi
        
        # Jika limit berubah, tambahkan section sebelumnya
        if [[ "$limit" != "$current_limit" ]] && [[ -n "$current_limit" ]]; then
            message="${message}${limit_section}"
            limit_section=""
        fi
        
        # Jika limit baru, buat header limit
        if [[ "$limit" != "$current_limit" ]]; then
            current_limit="$limit"
            limit_section="Limit IP: $limit\n"
        fi
        
        # Hitung sisa hari
        if [[ "$expiry" == "unlimited" ]]; then
            limit_section="${limit_section}$pass 0\n"
        else
            local sisa_hari=$(hitung_sisa_hari "$expiry")
            limit_section="${limit_section}$pass $sisa_hari\n"
        fi
        ((total_user++))
        
    done < "$DB"
    
    # Tambahkan section terakhir
    if [[ -n "$limit_section" ]]; then
        message="${message}${limit_section}═══════════════════\n"
    fi
    
    # Footer
    message="${message}Total User: $total_user"
    
    # Kirim
    send_telegram "$message"
}

# === SETUP AUTO BACKUP ===
setup_autobackup() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            SETUP AUTO BACKUP TELEGRAM${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Cek cron yang ada
    local cron_exists=$(crontab -l 2>/dev/null | grep -c "zivex.sh.*--autobackup")
    
    if [[ $cron_exists -gt 0 ]]; then
        local jadwal=$(crontab -l | grep "zivex.sh.*--autobackup" | head -1)
        echo -e "${GREEN}Status: AKTIF${NC}"
        echo -e "Jadwal: ${YELLOW}$jadwal${NC}"
        echo ""
        echo "1. Nonaktifkan Auto Backup"
        echo "2. Setiap 6 jam"
        echo "3. Setiap 12 jam"
        echo "4. Setiap 24 jam (Jam 23:00)"
        echo "5. Custom jam"
        echo "6. Kembali"
        echo ""
        read -rp "Pilih: " opt
        
        case $opt in
            1)
                crontab -l | grep -v "zivex.sh.*--autobackup" | crontab -
                echo -e "${GREEN}Auto Backup dinonaktifkan${NC}"
                sleep 2
                ;;
            2)
                crontab -l | grep -v "zivex.sh.*--autobackup" | crontab -
                (crontab -l 2>/dev/null; echo "0 */6 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap 6 jam${NC}"
                sleep 2
                ;;
            3)
                crontab -l | grep -v "zivex.sh.*--autobackup" | crontab -
                (crontab -l 2>/dev/null; echo "0 */12 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap 12 jam${NC}"
                sleep 2
                ;;
            4)
                crontab -l | grep -v "zivex.sh.*--autobackup" | crontab -
                (crontab -l 2>/dev/null; echo "0 23 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap hari jam 23:00${NC}"
                sleep 2
                ;;
            5)
                read -rp "Masukkan jam (0-23): " hour
                if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
                    crontab -l | grep -v "zivex.sh.*--autobackup" | crontab -
                    (crontab -l 2>/dev/null; echo "0 $hour * * * /root/zivex.sh --autobackup") | crontab -
                    echo -e "${GREEN}Auto Backup aktif setiap hari jam $hour:00${NC}"
                else
                    echo -e "${RED}Jam tidak valid${NC}"
                fi
                sleep 2
                ;;
        esac
    else
        echo -e "${RED}Status: NONAKTIF${NC}"
        echo ""
        echo "1. Setiap 6 jam"
        echo "2. Setiap 12 jam"
        echo "3. Setiap 24 jam (Jam 23:00)"
        echo "4. Custom jam"
        echo "5. Kembali"
        echo ""
        read -rp "Pilih: " opt
        
        case $opt in
            1)
                (crontab -l 2>/dev/null; echo "0 */6 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap 6 jam${NC}"
                sleep 2
                ;;
            2)
                (crontab -l 2>/dev/null; echo "0 */12 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap 12 jam${NC}"
                sleep 2
                ;;
            3)
                (crontab -l 2>/dev/null; echo "0 23 * * * /root/zivex.sh --autobackup") | crontab -
                echo -e "${GREEN}Auto Backup aktif setiap hari jam 23:00${NC}"
                sleep 2
                ;;
            4)
                read -rp "Masukkan jam (0-23): " hour
                if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
                    (crontab -l 2>/dev/null; echo "0 $hour * * * /root/zivex.sh --autobackup") | crontab -
                    echo -e "${GREEN}Auto Backup aktif setiap hari jam $hour:00${NC}"
                else
                    echo -e "${RED}Jam tidak valid${NC}"
                fi
                sleep 2
                ;;
        esac
    fi
}

# === GANTI TOKEN ===
ganti_token() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              GANTI TOKEN TELEGRAM${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "Token saat ini: ${CYAN}${BOT_TOKEN:0:10}...${NC}"
    echo -e "Chat ID saat ini: ${CYAN}$CHAT_ID${NC}"
    echo ""
    
    read -rp "Token baru: " new_token
    read -rp "Chat ID baru: " new_chatid
    
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
    echo -e "${GREEN}✓ Token berhasil diupdate${NC}"
    
    # Test kirim
    echo -e "${YELLOW}Mengirim pesan test...${NC}"
    send_telegram "✅ Token Updated - ZIVPN Express berhasil terhubung!"
    sleep 2
}

# === RESTORE DARI FILE ===
restore_dari_file() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              RESTORE DARI FILE${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "File backup di $BACKUP_DIR:"
    ls -lh "$BACKUP_DIR"/*.txt 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    
    read -rp "Masukkan nama file: " filename
    local file_path="$BACKUP_DIR/$filename"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}File tidak ditemukan${NC}"
        press_enter
        return
    fi
    
    # Backup database lama
    cp "$DB" "$BACKUP_DIR/db_before_restore_$(date +%Y%m%d_%H%M%S).db"
    
    # Proses restore
    local current_limit="2"
    local restored=0
    local skipped=0
    
    while read line; do
        # Skip baris yang bukan data user
        if [[ "$line" =~ ^📁 ]] || [[ "$line" =~ ^Waktu ]] || [[ "$line" =~ ^Domain ]] || [[ "$line" =~ ^IP ]] || [[ "$line" =~ ^════ ]] || [[ "$line" =~ ^Total ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Cek Limit IP
        if [[ "$line" =~ ^Limit[[:space:]]IP:[[:space:]]([0-9]+)$ ]]; then
            current_limit="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Parse user
        local arr=($line)
        if [[ ${#arr[@]} -ge 2 ]]; then
            local name="${arr[0]}"
            local days="${arr[1]}"
            
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                continue
            fi
            
            local password="$name"
            
            if grep -q "|$password|" "$DB" 2>/dev/null; then
                ((skipped++))
                continue
            fi
            
            if [[ "$days" == "0" ]]; then
                exp="unlimited"
            else
                exp=$(date -d "+$days days" +"%Y-%m-%d")
            fi
            
            echo "user_$password|$password|$exp|$current_limit" >> "$DB"
            ((restored++))
        fi
    done < "$file_path"
    
    if [[ $restored -gt 0 ]]; then
        update_config_json
        echo -e "${GREEN}✓ Restore selesai: $restored user (Skip: $skipped)${NC}"
    else
        echo -e "${YELLOW}Tidak ada user yang direstore${NC}"
    fi
    
    press_enter
}

# === RESTORE DARI LINK ===
restore_dari_link() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              RESTORE DARI LINK${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -rp "URL file backup: " file_url
    local file_path="/tmp/restore.txt"
    
    echo "Mengunduh..."
    wget -q "$file_url" -O "$file_path"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Gagal download${NC}"
        press_enter
        return
    fi
    
    # Backup database lama
    cp "$DB" "$BACKUP_DIR/db_before_restore_$(date +%Y%m%d_%H%M%S).db"
    
    # Proses restore
    local current_limit="2"
    local restored=0
    local skipped=0
    
    while read line; do
        if [[ "$line" =~ ^📁 ]] || [[ "$line" =~ ^Waktu ]] || [[ "$line" =~ ^Domain ]] || [[ "$line" =~ ^IP ]] || [[ "$line" =~ ^════ ]] || [[ "$line" =~ ^Total ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^Limit[[:space:]]IP:[[:space:]]([0-9]+)$ ]]; then
            current_limit="${BASH_REMATCH[1]}"
            continue
        fi
        
        local arr=($line)
        if [[ ${#arr[@]} -ge 2 ]]; then
            local name="${arr[0]}"
            local days="${arr[1]}"
            
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                continue
            fi
            
            local password="$name"
            
            if grep -q "|$password|" "$DB" 2>/dev/null; then
                ((skipped++))
                continue
            fi
            
            if [[ "$days" == "0" ]]; then
                exp="unlimited"
            else
                exp=$(date -d "+$days days" +"%Y-%m-%d")
            fi
            
            echo "user_$password|$password|$exp|$current_limit" >> "$DB"
            ((restored++))
        fi
    done < "$file_path"
    
    rm -f "$file_path"
    
    if [[ $restored -gt 0 ]]; then
        update_config_json
        echo -e "${GREEN}✓ Restore selesai: $restored user (Skip: $skipped)${NC}"
    fi
    
    press_enter
}

# === RESTORE DARI TELEGRAM ===
restore_dari_telegram() {
    clear
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              RESTORE DARI TELEGRAM${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -rp "File ID/Path: " file_id
    local file_path="/tmp/restore.txt"
    local url="https://api.telegram.org/file/bot$BOT_TOKEN/$file_id"
    
    echo "Mengunduh..."
    wget -q "$url" -O "$file_path"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Gagal download${NC}"
        press_enter
        return
    fi
    
    # Backup database lama
    cp "$DB" "$BACKUP_DIR/db_before_restore_$(date +%Y%m%d_%H%M%S).db"
    
    # Proses restore
    local current_limit="2"
    local restored=0
    local skipped=0
    
    while read line; do
        if [[ "$line" =~ ^📁 ]] || [[ "$line" =~ ^Waktu ]] || [[ "$line" =~ ^Domain ]] || [[ "$line" =~ ^IP ]] || [[ "$line" =~ ^════ ]] || [[ "$line" =~ ^Total ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^Limit[[:space:]]IP:[[:space:]]([0-9]+)$ ]]; then
            current_limit="${BASH_REMATCH[1]}"
            continue
        fi
        
        local arr=($line)
        if [[ ${#arr[@]} -ge 2 ]]; then
            local name="${arr[0]}"
            local days="${arr[1]}"
            
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                continue
            fi
            
            local password="$name"
            
            if grep -q "|$password|" "$DB" 2>/dev/null; then
                ((skipped++))
                continue
            fi
            
            if [[ "$days" == "0" ]]; then
                exp="unlimited"
            else
                exp=$(date -d "+$days days" +"%Y-%m-%d")
            fi
            
            echo "user_$password|$password|$exp|$current_limit" >> "$DB"
            ((restored++))
        fi
    done < "$file_path"
    
    rm -f "$file_path"
    
    if [[ $restored -gt 0 ]]; then
        update_config_json
        echo -e "${GREEN}✓ Restore selesai: $restored user (Skip: $skipped)${NC}"
    fi
    
    press_enter
}

# === BANNER ===
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
    echo -e "${WHITE}  ════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}         ZIVPN EXPRESS - UDP TUNNEL${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════════${NC}"
    
    if [[ -f "$ZIVPN_BIN" ]]; then
        local ip=$(get_ip)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        local total_user=$(wc -l < "$DB" 2>/dev/null || echo "0")
        local online=$(netstat -un 2>/dev/null | grep -c :5667 2>/dev/null || echo "0")
        
        echo -e "  ${WHITE}Status   :${NC} $([[ "$status" == "active" ]] && echo "${GREEN}AKTIF${NC}" || echo "${RED}MATI${NC}")"
        echo -e "  ${WHITE}IP       :${NC} ${CYAN}$ip${NC}"
        echo -e "  ${WHITE}Domain   :${NC} ${CYAN}$DOMAIN${NC}"
        echo -e "  ${WHITE}Total User:${NC} ${GREEN}$total_user${NC}"
        echo -e "  ${WHITE}Online   :${NC} ${GREEN}$online${NC} koneksi"
    fi
    echo -e "${WHITE}  ════════════════════════════════════════════${NC}"
    echo ""
}

# === CREATE AKUN RANDOM 2 DIGIT ===
create_account() {
    banner
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              CREATE AKUN BARU${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -rp "Nama/prefix: " PREFIX
    [ -z "$PREFIX" ] && PREFIX="user"
    
    read -rp "Limit IP [2]: " LIMIT
    [ -z "$LIMIT" ] && LIMIT=2
    if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Limit IP harus angka${NC}"
        press_enter
        return
    fi
    
    read -rp "Masa aktif hari [30]: " DAYS
    [ -z "$DAYS" ] && DAYS=30
    if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Masa aktif harus angka${NC}"
        press_enter
        return
    fi
    
    # Generate 2 digit random
    local RANDOM2=$(printf "%02d" $((RANDOM % 100)))
    local PASSWORD="${PREFIX}${RANDOM2}"
    
    # Cek duplikasi
    while grep -q "|$PASSWORD|" "$DB" 2>/dev/null; do
        RANDOM2=$(printf "%02d" $((RANDOM % 100)))
        PASSWORD="${PREFIX}${RANDOM2}"
    done
    
    # Hitung expired
    if [[ "$DAYS" == "0" ]]; then
        EXPIRED="unlimited"
        EXP_DATE="Unlimited"
    else
        EXPIRED=$(date -d "+$DAYS days" +"%Y-%m-%d")
        EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
    fi
    
    local CREATE_DATE=$(date +"%d %b, %Y")
    local LOKASI=$(get_location)
    
    # Simpan ke database
    echo "user_$PASSWORD|$PASSWORD|$EXPIRED|$LIMIT" >> "$DB"
    update_config_json
    
    # Tampilkan hasil
    echo ""
    echo -e "${GREEN}✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════════════${NC}"
    echo -e "  ${CYAN}ZIVPN EXPRESS${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  Domain      : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  IP Server   : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "  Password    : ${YELLOW}$PASSWORD${NC}"
    echo -e "  Limit IP    : ${PURPLE}$([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")${NC}"
    echo -e "  Server      : ${CYAN}$LOKASI${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    echo -e "  Tanggal Buat: ${GREEN}$CREATE_DATE${NC}"
    echo -e "  Tanggal Exp : ${YELLOW}$EXP_DATE${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}$DAYS hari${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Klik Garis tiga pojok kiri atas"
    echo -e "  4. Klik Udp tunnel setting"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  5. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  5. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$PASSWORD${NC}"
    echo -e "  6. Pilih negara bebas rekom $LOKASI"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}════════════════════════════════════════════════════════${NC}"
    
    send_telegram "✅ AKUN ZIVPN EXPRESS BARU\nPassword : $PASSWORD\nLimit IP : $LIMIT Device\nExpired  : $EXP_DATE\nServer   : $LOKASI"
    
    press_enter
}

# === CREATE MASS ACCOUNTS ===
create_mass() {
    banner
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              CREATE MASS ACCOUNTS${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "Cara input:"
    echo -e "  1. Masukkan LIMIT IP untuk semua user"
    echo -e "  2. Input user: ${YELLOW}nama masaaktif${NC}"
    echo -e "  3. Ketik ${GREEN}selesai${NC} untuk mengakhiri"
    echo ""
    echo -e "Contoh:"
    echo -e "  Limit IP: 2"
    echo -e "  ahsan 25"
    echo -e "  kekey 25"
    echo -e "  selesai"
    echo ""
    
    read -rp "Limit IP untuk semua user [2]: " global_limit
    [ -z "$global_limit" ] && global_limit=2
    if ! [[ "$global_limit" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Limit IP harus angka${NC}"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${GREEN}Limit IP: $([ "$global_limit" == "0" ] && echo "Unlimited" || echo "$global_limit Device")${NC}"
    echo -e "Input user (nama masaaktif):"
    echo ""
    
    local success=0
    local failed=0
    
    while true; do
        read -rp "Input: " input
        
        if [[ "$input" == "selesai" ]]; then
            break
        fi
        
        if [[ -z "$input" ]]; then
            continue
        fi
        
        local arr=($input)
        if [[ ${#arr[@]} -lt 2 ]]; then
            echo -e "${RED}Format salah! Gunakan: nama masaaktif${NC}"
            ((failed++))
            continue
        fi
        
        local name="${arr[0]}"
        local days="${arr[1]}"
        
        if ! [[ "$days" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Masa aktif harus angka${NC}"
            ((failed++))
            continue
        fi
        
        local password="$name"
        
        if grep -q "|$password|" "$DB" 2>/dev/null; then
            echo -e "${RED}Password $password sudah ada${NC}"
            ((failed++))
            continue
        fi
        
        if [[ "$days" == "0" ]]; then
            exp="unlimited"
        else
            exp=$(date -d "+$days days" +"%Y-%m-%d")
        fi
        
        echo "user_$password|$password|$exp|$global_limit" >> "$DB"
        echo -e "${GREEN}✓ $name → $password $days hari${NC}"
        ((success++))
    done
    
    echo ""
    if [[ $success -gt 0 ]]; then
        update_config_json
        echo -e "${GREEN}✓ BERHASIL MEMBUAT $success AKUN${NC}"
    fi
    
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}✗ Gagal: $failed akun${NC}"
    fi
    
    press_enter
}

# === CEK USER ONLINE ===
cek_online() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              CEK USER ONLINE${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! command -v netstat &> /dev/null; then
        apt-get install -y net-tools > /dev/null 2>&1
    fi
    
    local connections=$(netstat -un 2>/dev/null | grep :5667 | grep -v "127.0.0.1" | grep -v "::1")
    
    if [[ -z "$connections" ]]; then
        echo -e "${YELLOW}Tidak ada user online${NC}"
        press_enter
        return
    fi
    
    echo -e "USER ONLINE:"
    echo -e "────────────────────"
    
    local total=0
    while read -r ip; do
        if [[ -n "$ip" ]]; then
            local count=$(echo "$connections" | grep -c "$ip")
            echo -e "$ip - $count device"
            total=$((total + count))
        fi
    done < <(echo "$connections" | awk '{print $5}' | cut -d: -f1 | sort -u)
    
    echo -e "────────────────────"
    echo -e "Total: $total koneksi"
    
    press_enter
}

# === LIST USER ===
list_user() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              DAFTAR USER${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user${NC}"
        press_enter
        return
    fi
    
    local today_epoch=$(date +%s)
    local aktif=0
    local expired=0
    
    printf "%-20s %-8s %-12s %s\n" "PASSWORD" "LIMIT" "SISA" "STATUS"
    echo -e "────────────────────────────────────────────"
    
    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]]; then
            printf "%-20s %-8s %-12s %s\n" "$pass" "$limit" "∞" "Aktif"
            ((aktif++))
        else
            local sisa_hari=$(hitung_sisa_hari "$expiry")
            if [[ $sisa_hari -gt 0 ]]; then
                printf "%-20s %-8s %-12s %s\n" "$pass" "$limit" "$sisa_hari hari" "Aktif"
                ((aktif++))
            else
                printf "%-20s %-8s %-12s %s\n" "$pass" "$limit" "-" "Expired"
                ((expired++))
            fi
        fi
    done < "$DB"
    
    echo -e "────────────────────────────────────────────"
    echo -e "Total: $(wc -l < "$DB") | Aktif: $aktif | Expired: $expired"
    
    press_enter
}

# === HAPUS USER ===
hapus_user() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              HAPUS USER${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user${NC}"
        press_enter
        return
    fi
    
    echo -e "Daftar password:"
    local i=1
    while IFS='|' read -r user pass expiry limit; do
        echo -e "  $i. $pass"
        ((i++))
    done < "$DB"
    
    echo ""
    read -rp "Password yang dihapus: " pass
    
    if ! grep -q "|$pass|" "$DB"; then
        echo -e "${RED}Password tidak ditemukan${NC}"
        press_enter
        return
    fi
    
    read -rp "Yakin hapus $pass? y/N: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/|$pass|/d" "$DB"
        update_config_json
        echo -e "${GREEN}✓ User $pass dihapus${NC}"
        send_telegram "🗑 User Dihapus\nPassword: $pass"
    fi
    
    press_enter
}

# === HAPUS EXPIRED ===
hapus_expired() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              HAPUS USER EXPIRED${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local today=$(date +%Y-%m-%d)
    local tmp=$(mktemp)
    local count=0
    
    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ $pass expired $expiry${NC}"
            ((count++))
        else
            echo "$user|$pass|$expiry|$limit" >> "$tmp"
        fi
    done < "$DB"
    
    if [[ $count -gt 0 ]]; then
        mv "$tmp" "$DB"
        update_config_json
        echo ""
        echo -e "${GREEN}✓ $count user expired dihapus${NC}"
        send_telegram "🧹 HAPUS EXPIRED\n$count user dihapus"
    else
        rm -f "$tmp"
        echo -e "${YELLOW}Tidak ada user expired${NC}"
    fi
    
    press_enter
}

# === SET DOMAIN ===
set_domain() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              SET DOMAIN${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "Domain saat ini: ${CYAN}$DOMAIN${NC}"
    echo ""
    read -rp "Domain baru: " new_domain
    
    if [[ -n "$new_domain" ]]; then
        DOMAIN="$new_domain"
        echo "$DOMAIN" > "$DOMAIN_FILE"
        echo -e "${GREEN}✓ Domain diubah${NC}"
    fi
    
    press_enter
}

# === INSTALL ULANG ===
install_ulang() {
    clear
    
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}              INSTALL ULANG ZIVPN${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "1. Install baru - Hapus semua data"
    echo -e "2. Update saja - Pertahankan data"
    echo ""
    read -rp "Pilih 1/2: " mode
    
    if [[ "$mode" == "1" ]]; then
        read -rp "Yakin hapus semua data? y/N: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            systemctl stop zivpn.service 2>/dev/null
            rm -rf "$ZIVPN_DIR"
            rm -f "$ZIVPN_BIN"
            rm -f "$SERVICE_FILE"
        else
            return
        fi
    fi
    
    echo "Menginstall..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl ufw cron jq net-tools > /dev/null 2>&1
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" -O "$ZIVPN_BIN"
    else
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64" -O "$ZIVPN_BIN"
    fi
    chmod +x "$ZIVPN_BIN"
    
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=$ZIVPN_BIN server -c $CONFIG
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    update_config_json
    
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Install selesai${NC}"
    press_enter
}

# === RESTART SERVICE ===
restart_service() {
    systemctl restart zivpn.service
    echo -e "${GREEN}✓ Service direstart${NC}"
    sleep 2
}

# === UNINSTALL ===
uninstall() {
    clear
    echo -e "${BOLD}${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}              UNINSTALL ZIVPN${NC}"
    echo -e "${BOLD}${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -rp "Yakin uninstall? y/N: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        systemctl stop zivpn.service
        systemctl disable zivpn.service > /dev/null 2>&1
        rm -f "$SERVICE_FILE"
        rm -f "$ZIVPN_BIN"
        rm -rf "$ZIVPN_DIR"
        systemctl daemon-reload
        echo -e "${GREEN}✓ Uninstall selesai${NC}"
        sleep 2
        exit 0
    fi
}

# === UPDATE SCRIPT ===
update_script() {
    echo "Mengupdate..."
    wget -O /root/zivex.sh https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zivex.sh > /dev/null 2>&1
    chmod +x /root/zivex.sh
    echo "✓ Selesai, jalankan ulang"
    sleep 2
    exec bash /root/zivex.sh
}

# === BACKUP MENU ===
backup_menu() {
    while true; do
        clear
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}              BACKUP & RESTORE${NC}"
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. Backup Langsung ke Telegram"
        echo -e "  ${GREEN}2${NC}. Setup Auto Backup"
        echo -e "  ${CYAN}3${NC}. Restore dari File"
        echo -e "  ${CYAN}4${NC}. Restore dari Link"
        echo -e "  ${CYAN}5${NC}. Restore dari Telegram"
        echo -e "  ${RED}0${NC}. Kembali"
        echo ""
        read -rp "Pilih: " bk_choice
        
        case $bk_choice in
            1) backup_langsung ;;
            2) setup_autobackup ;;
            3) restore_dari_file ;;
            4) restore_dari_link ;;
            5) restore_dari_telegram ;;
            0) break ;;
        esac
    done
}

# === MENU UTAMA ===
main_menu() {
    while true; do
        banner
        
        if [[ ! -f "$ZIVPN_BIN" ]]; then
            echo -e "${RED}ZIVPN BELUM TERINSTAL${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN"
            echo -e "  ${CYAN}2${NC}. Set Domain"
            echo -e "  ${YELLOW}3${NC}. Ganti Token"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "Pilih: " choice
            
            case $choice in
                1) install_ulang ;;
                2) set_domain ;;
                3) ganti_token ;;
                0) exit 0 ;;
            esac
        else
            echo -e "  ${GREEN}1${NC}. Create Akun (Random 2 Digit)"
            echo -e "  ${GREEN}2${NC}. Create Mass Accounts"
            echo -e "  ${CYAN}3${NC}. Cek User Online"
            echo -e "  ${CYAN}4${NC}. List User"
            echo -e "  ${RED}5${NC}. Hapus User"
            echo -e "  ${RED}6${NC}. Hapus Expired"
            echo -e "  ${BLUE}7${NC}. Set Domain"
            echo -e "  ${PURPLE}8${NC}. Backup & Restore"
            echo -e "  ${YELLOW}9${NC}. Ganti Token"
            echo -e "  ${GREEN}10${NC}. Install Ulang"
            echo -e "  ${CYAN}11${NC}. Restart Service"
            echo -e "  ${RED}12${NC}. Update Script"
            echo -e "  ${RED}13${NC}. Uninstall"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "Pilih: " choice
            
            case $choice in
                1) create_account ;;
                2) create_mass ;;
                3) cek_online ;;
                4) list_user ;;
                5) hapus_user ;;
                6) hapus_expired ;;
                7) set_domain ;;
                8) backup_menu ;;
                9) ganti_token ;;
                10) install_ulang ;;
                11) restart_service ;;
                12) update_script ;;
                13) uninstall ;;
                0) exit 0 ;;
            esac
        fi
    done
}

# === AUTO BACKUP MODE ===
if [[ "$1" == "--autobackup" ]]; then
    auto_backup
    exit 0
fi

# === START ===
check_root
main_menu
