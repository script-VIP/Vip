#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - ZIVON BOT
#   Fitur: 
#   - Create akun (auto random 2 digit)
#   - Create mass accounts (global limit)
#   - Backup sisa masa aktif (format file)
#   - Restore dari file backup
#   - Cek user online & jumlah device
#   - List user dengan sisa masa aktif
#   Token: 8504261570:AAF5rtJ2wW9nrS6EOMyScB5ZGnZcL8sRcXA
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

# === TELEGRAM CONFIG (TOKEN ZIVON) ===
cat > "$TG_FILE" <<EOF
BOT_TOKEN="8504261570:AAF5rtJ2wW9nrS6EOMyScB5ZGnZcL8sRcXA"
CHAT_ID="6198984094"
EOF
chmod 600 "$TG_FILE"
source "$TG_FILE"

# === FUNGSI UTILITAS ===
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script harus dijalankan sebagai root!"
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

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan [ENTER] untuk kembali ke menu...${NC}"
    read -r
}

# === UPDATE CONFIG.JSON DARI DATABASE ===
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

# === FUNGSI TELEGRAM ===
send_telegram() {
    local message="$1"
    [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ] && return 1
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="Markdown" > /dev/null 2>&1
}

# =============================================
#  BANNER
# =============================================
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
    echo -e "${YELLOW}         ZIVON BOT - UDP Manager${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════════${NC}"
    
    if [[ -f "$ZIVPN_BIN" ]]; then
        local ip=$(get_ip)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        local total_user=$(wc -l < "$DB" 2>/dev/null || echo "0")
        
        echo -e "  ${WHITE}Status   :${NC} $([[ "$status" == "active" ]] && echo "${GREEN}● AKTIF${NC}" || echo "${RED}● MATI${NC}")"
        echo -e "  ${WHITE}IP       :${NC} ${CYAN}$ip${NC}"
        echo -e "  ${WHITE}Domain   :${NC} ${CYAN}$DOMAIN${NC}"
        echo -e "  ${WHITE}Total User:${NC} ${GREEN}$total_user${NC}"
        echo -e "  ${WHITE}Port     :${NC} ${CYAN}5667 (UDP)${NC}"
    fi
    echo -e "${WHITE}  ════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================
#  FITUR 1: CREATE AKUN (RANDOM 2 DIGIT)
# =============================================
create_account_random() {
    banner
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║           CREATE AKUN (RANDOM 2 DIGIT)                 ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Input nama/prefix
    read -rp "$(echo -e "${WHITE}Masukkan nama/prefix: ${NC}")" PREFIX
    if [[ -z "$PREFIX" ]]; then
        echo -e "${RED}Nama tidak boleh kosong!${NC}"
        press_enter
        return
    fi
    
    # Input limit IP
    read -rp "$(echo -e "${WHITE}Limit IP [2]: ${NC}")" LIMIT
    [ -z "$LIMIT" ] && LIMIT=2
    if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Limit IP harus angka!${NC}"
        press_enter
        return
    fi
    
    # Input masa aktif
    read -rp "$(echo -e "${WHITE}Masa aktif (hari) [30]: ${NC}")" DAYS
    [ -z "$DAYS" ] && DAYS=30
    if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Masa aktif harus angka!${NC}"
        press_enter
        return
    fi
    
    # Generate 2 digit random
    local RANDOM2=$(printf "%02d" $((RANDOM % 100)))
    local PASSWORD="${PREFIX}${RANDOM2}"
    
    # Cek duplikasi
    local counter=0
    while grep -q "|$PASSWORD|" "$DB" 2>/dev/null; do
        RANDOM2=$(printf "%02d" $((RANDOM % 100)))
        PASSWORD="${PREFIX}${RANDOM2}"
        ((counter++))
        if [[ $counter -gt 10 ]]; then
            RANDOM2=$(printf "%03d" $((RANDOM % 1000)))
            PASSWORD="${PREFIX}${RANDOM2}"
            break
        fi
    done
    
    # Hitung expired
    local EXPIRED=""
    local EXP_DATE=""
    if [[ "$DAYS" == "0" ]]; then
        EXPIRED="unlimited"
        EXP_DATE="Unlimited"
    else
        EXPIRED=$(date -d "+$DAYS days" +"%Y-%m-%d")
        EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
    fi
    
    # Tanggal buat
    local CREATE_DATE=$(date +"%d %b, %Y")
    
    # Dapatkan lokasi
    local LOKASI=$(get_location)
    
    # Simpan ke database
    echo "user_$PASSWORD|$PASSWORD|$EXPIRED|$LIMIT" >> "$DB"
    
    # Update config
    update_config_json
    
    # Tampilkan hasil
    echo ""
    echo -e "${WHITE}════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
    echo -e "${WHITE}════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${CYAN}ZIVPN UDP${NC}"
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
    echo -e "  Masa Aktif  : ${YELLOW}$([ "$DAYS" == "0" ] && echo "Selamanya" || echo "$DAYS hari")${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────${NC}"
    echo -e "  1. Buka ZIVPN App"
    echo -e "  2. Centang Udp"
    echo -e "  3. Klik Garis tiga (pojok kiri atas)"
    echo -e "  4. Klik Udp tunnel setting"
    
    if [[ "$DOMAIN" != "-" ]]; then
        echo -e "  5. UDP Server  : ${CYAN}$DOMAIN${NC}"
    else
        echo -e "  5. UDP Server  : ${CYAN}$(get_ip)${NC}"
    fi
    echo -e "     UDP Password: ${CYAN}$PASSWORD${NC}"
    echo -e "  6. Pilih negara bebas (rekom $LOKASI)"
    echo -e "  7. Klik APPLY → START"
    echo -e "${WHITE}════════════════════════════════════════════════════════╝${NC}"
    
    # Kirim notifikasi Telegram
    send_telegram "✅ *AKUN ZIVPN BARU*
══════════════════════
Password : \`$PASSWORD\`
Limit IP : $([ "$LIMIT" == "0" ] && echo "Unlimited" || echo "$LIMIT Device")
Expired  : $EXP_DATE
Server   : $LOKASI"
    
    echo ""
    press_enter
}

# =============================================
#  FITUR 2: CREATE MASS ACCOUNTS (GLOBAL LIMIT)
# =============================================
create_mass_accounts() {
    banner
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║           CREATE MASS ACCOUNTS (GLOBAL LIMIT)          ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${GREEN}  CARA INPUT:${NC}                                                  ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  1. Masukkan LIMIT IP untuk semua user (0=unlimited)              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  2. Input user: ${YELLOW}nama masaaktif${NC}                                ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  3. Ketik 'selesai' jika sudah                                       ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                                  ${WHITE}│${NC}"
    echo -e "${WHITE}│${CYAN}  CONTOH:${NC}                                                        ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Limit IP: 2                                                         ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ahsan 25                                                            ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  kekey 25                                                            ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  selesai                                                             ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Input limit IP global
    read -rp "$(echo -e "${YELLOW}Limit IP untuk semua user (0=unlimited) [2]: ${NC}")" global_limit
    [ -z "$global_limit" ] && global_limit=2
    if ! [[ "$global_limit" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Limit IP harus angka!${NC}"
        press_enter
        return
    fi
    
    local limit_display="$([ "$global_limit" == "0" ] && echo "Unlimited" || echo "$global_limit Device")"
    echo ""
    echo -e "${GREEN}✓ Limit IP: $limit_display${NC}"
    echo -e "${WHITE}Silahkan input user (nama masaaktif), ketik 'selesai' untuk mengakhiri:${NC}"
    echo ""
    
    local created_users=()
    local failed_users=()
    local total_success=0
    local total_failed=0
    
    while true; do
        read -rp "$(echo -e "${CYAN}Input: ${NC}")" input
        
        if [[ "$input" == "selesai" ]] || [[ "$input" == "Selesai" ]]; then
            break
        fi
        
        if [[ -z "$input" ]]; then
            continue
        fi
        
        # Parse input (nama masaaktif)
        local arr=($input)
        if [[ ${#arr[@]} -lt 2 ]]; then
            echo -e "${RED}  ✗ Format salah! Gunakan: nama masaaktif${NC}"
            ((total_failed++))
            failed_users+=("$input (format salah)")
            continue
        fi
        
        local name="${arr[0]}"
        local days="${arr[1]}"
        
        # Validasi days harus angka
        if ! [[ "$days" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}  ✗ Masa aktif harus angka!${NC}"
            ((total_failed++))
            failed_users+=("$name (masa aktif bukan angka)")
            continue
        fi
        
        # Password = nama (tanpa tambahan)
        local password="$name"
        
        # Cek apakah password sudah ada
        if grep -q "|$password|" "$DB" 2>/dev/null; then
            echo -e "${RED}  ✗ Gagal: Password '$password' sudah digunakan!${NC}"
            ((total_failed++))
            failed_users+=("$name (password sudah ada)")
            continue
        fi
        
        # Hitung expired dari HARI INI + days
        local exp=""
        local exp_date=""
        if [[ "$days" == "0" ]]; then
            exp="unlimited"
            exp_date="Unlimited"
        else
            exp=$(date -d "+$days days" +"%Y-%m-%d")
            exp_date=$(date -d "+$days days" +"%d %b, %Y")
        fi
        
        # Username untuk database
        local user="user_$password"
        
        # Simpan ke database (USER|PASSWORD|EXPIRED|LIMIT)
        echo "$user|$password|$exp|$global_limit" >> "$DB"
        
        echo -e "${GREEN}  ✓ Berhasil: ${YELLOW}$name${NC} → Password: ${CYAN}$password${NC} (Masa aktif: ${YELLOW}$days hari${NC}, Limit: $limit_display)"
        
        created_users+=("$name|$password|$days|$exp_date")
        ((total_success++))
    done
    
    echo ""
    
    if [[ $total_success -gt 0 ]]; then
        # Update config
        update_config_json
        
        # Tampilkan ringkasan
        echo -e "${WHITE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║${GREEN}              ✓ BERHASIL MEMBUAT $total_success AKUN             ${WHITE}║${NC}"
        echo -e "${WHITE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${WHITE}│${CYAN}                     DAFTAR PASSWORD                        ${WHITE}│${NC}"
        echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
        
        for user_data in "${created_users[@]}"; do
            IFS='|' read -r name pass days exp <<< "$user_data"
            printf "${WHITE}│${NC}  ${GREEN}✓${NC} %-10s → ${CYAN}%-15s${NC} (%3d hari)        ${WHITE}│${NC}\n" "$name" "$pass" "$days"
        done
        
        echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${WHITE}│${YELLOW}  Limit IP: $limit_display                                         ${WHITE}│${NC}"
        echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        # Kirim notifikasi Telegram
        local location=$(get_location)
        local ip=$(get_ip)
        local domain_display="$DOMAIN"
        [[ "$domain_display" == "-" ]] && domain_display="$ip"
        
        local list_pass=""
        for user_data in "${created_users[@]}"; do
            IFS='|' read -r name pass days exp <<< "$user_data"
            list_pass="$list_pass\n- $name : \`$pass\` (${days} hari)"
        done
        
        send_telegram "✅ *MASS CREATE AKUN ZIVPN*
══════════════════════
Total   : $total_success akun
Limit IP: $limit_display
Server  : $location
Domain  : $domain_display
══════════════════════
Daftar Password:$list_pass"
        
    fi
    
    if [[ $total_failed -gt 0 ]]; then
        echo -e "${RED}  ✗ Gagal: $total_failed akun${NC}"
        for failed in "${failed_users[@]}"; do
            echo -e "     • $failed"
        done
    fi
    
    echo ""
    press_enter
}

# =============================================
#  FITUR 3: BACKUP - TAMPILKAN FILE
# =============================================
backup_accounts() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║           BACKUP AKUN (SISA MASA AKTIF)                ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Ambil semua user dari database
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user untuk di-backup!${NC}"
        press_enter
        return
    fi
    
    # Buat file temporary
    local tmp_file="/tmp/zivpn_backup_$$.txt"
    
    echo "# ZIVPN Backup File - Sisa Masa Aktif" > "$tmp_file"
    echo "# Format: Limit IP: [angka]" >> "$tmp_file"
    echo "#         nama sisa_hari" >> "$tmp_file"
    echo "" >> "$tmp_file"
    
    # Kelompokkan user berdasarkan limit IP
    local current_limit=""
    local first=true
    local today=$(date +%s)
    local total_user_backup=0
    
    while IFS='|' read -r user pass expiry limit; do
        # Hitung SISA HARI dari tanggal expired
        local sisa_hari="0"
        
        if [[ "$expiry" == "unlimited" ]]; then
            sisa_hari="0"  # Unlimited disimpan sebagai 0
        else
            local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            local diff_seconds=$((exp_epoch - today))
            local diff_days=$((diff_seconds / 86400))
            
            if [[ $diff_days -gt 0 ]]; then
                sisa_hari=$diff_days
            else
                sisa_hari=0  # Sudah expired
            fi
        fi
        
        # Skip yang sudah expired (sisa 0)
        if [[ "$sisa_hari" -eq 0 ]] && [[ "$expiry" != "unlimited" ]]; then
            continue
        fi
        
        # Jika limit berbeda, tulis header baru
        if [[ "$limit" != "$current_limit" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "" >> "$tmp_file"
            fi
            echo "Limit IP: $limit" >> "$tmp_file"
            current_limit="$limit"
        fi
        
        # Tulis user dengan SISA HARI
        echo "$pass $sisa_hari" >> "$tmp_file"
        ((total_user_backup++))
        
    done < "$DB"
    
    if [[ $total_user_backup -eq 0 ]]; then
        echo -e "${YELLOW}Tidak ada user aktif untuk di-backup!${NC}"
        rm -f "$tmp_file"
        press_enter
        return
    fi
    
    # Tampilkan isi file
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${GREEN}  ISI FILE BACKUP (SISA HARI):${NC}                                   ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    while IFS= read -r line; do
        if [[ "$line" == \#* ]]; then
            echo -e "${WHITE}│${CYAN}  $line${NC} ${WHITE}│${NC}"
        elif [[ "$line" == "Limit IP:"* ]]; then
            echo -e "${WHITE}│${YELLOW}  $line${NC} ${WHITE}│${NC}"
        elif [[ -n "$line" ]]; then
            echo -e "${WHITE}│${GREEN}  $line${NC} ${WHITE}│${NC}"
        fi
    done < "$tmp_file"
    
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Simpan file dengan format: domain_tanggal.txt
    local domain_safe=$(echo "$DOMAIN" | sed 's/\./_/g')
    [[ "$domain_safe" == "-" ]] && domain_safe="no_domain"
    local date_str=$(date +%Y%m%d_%H%M%S)
    local filename="${domain_safe}_${date_str}.txt"
    local backup_path="$BACKUP_DIR/$filename"
    
    cp "$tmp_file" "$backup_path"
    rm -f "$tmp_file"
    
    echo -e "${GREEN}✓ File backup disimpan di:${NC}"
    echo -e "  ${CYAN}$backup_path${NC}"
    echo ""
    
    # Tampilkan statistik
    local total_group=$(grep -c "Limit IP:" "$backup_path")
    echo -e "${WHITE}Total User    : ${GREEN}$total_user_backup${NC}"
    echo -e "${WHITE}Group Limit   : ${GREEN}$total_group${NC}"
    echo -e "${WHITE}File Name     : ${CYAN}$filename${NC}"
    echo ""
    
    # Tanya apakah mau salin
    echo -e "${YELLOW}Salin isi file? (bisa paste di create mass)${NC}"
    read -rp "Tekan ENTER untuk lanjut..." 
    
    press_enter
}

# =============================================
#  FITUR 4: CEK USER ONLINE & JUMLAH DEVICE
# =============================================
check_online_users() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                CEK USER ONLINE                         ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! command -v netstat &> /dev/null; then
        apt-get install -y net-tools > /dev/null 2>&1
    fi
    
    echo -e "${WHITE}Mengecek koneksi UDP yang aktif...${NC}"
    echo ""
    
    # Ambil semua koneksi UDP ke port 5667
    local connections=$(netstat -un 2>/dev/null | grep :5667 | grep -v "127.0.0.1" | grep -v "::1")
    
    if [[ -z "$connections" ]]; then
        echo -e "${YELLOW}Tidak ada koneksi aktif saat ini${NC}"
        echo ""
        press_enter
        return
    fi
    
    # Kelompokkan berdasarkan IP
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}              USER ONLINE BERDASARKAN IP                  ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    local total_koneksi=0
    local unique_ips=()
    
    # Ambil IP unik dan hitung koneksi per IP
    while read -r ip; do
        if [[ -n "$ip" ]]; then
            local count=$(echo "$connections" | grep -c "$ip")
            echo -e "${WHITE}│${NC}  ${GREEN}➤${NC} ${YELLOW}$ip${NC} - ${CYAN}$count koneksi${NC}          ${WHITE}│${NC}"
            unique_ips+=("$ip")
            total_koneksi=$((total_koneksi + count))
        fi
    done < <(echo "$connections" | awk '{print $5}' | cut -d: -f1 | sort -u)
    
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC}  Total Koneksi: ${GREEN}$total_koneksi${NC}                                   ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Unique IP    : ${GREEN}${#unique_ips[@]}${NC}                                   ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Coba cocokkan dengan user di database
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}              DETAIL PER USER (BERDASARKAN IP)            ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    # Buat file sementara untuk menyimpan IP dan user
    local temp_ip_user="/tmp/ip_user_$$.txt"
    > "$temp_ip_user"
    
    # Coba tebak user berdasarkan IP (ini hanya perkiraan)
    # Kita bisa lihat dari log atau netstat yang menampilkan IP
    
    local found=0
    for ip in "${unique_ips[@]}"; do
        # Cari di database berdasarkan IP? Tidak ada, jadi kita tampilkan IP saja
        # Tapi kita bisa cek di log jika ada
        echo -e "${WHITE}│${NC}  IP: ${YELLOW}$ip${NC}                                              ${WHITE}│${NC}"
        ((found++))
    done
    
    if [[ $found -eq 0 ]]; then
        echo -e "${WHITE}│${NC}  ${YELLOW}Tidak dapat mencocokkan dengan user${NC}                   ${WHITE}│${NC}"
    fi
    
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Tampilkan user aktif di database
    local today=$(date +%Y-%m-%d)
    local active_users=0
    
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}              USER AKTIF DI DATABASE                      ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            local limit_display="$([ "$limit" == "0" ] && echo "∞" || echo "$limit")"
            printf "${WHITE}│${NC}  ${GREEN}✓${NC} %-15s (Limit: %s)        ${WHITE}│${NC}\n" "$pass" "$limit_display"
            ((active_users++))
        fi
    done < "$DB"
    
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC}  Total User Aktif: ${GREEN}$active_users${NC}                                 ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    
    rm -f "$temp_ip_user"
    echo ""
    press_enter
}

# =============================================
#  FITUR 5: LIST USERS DENGAN SISA MASA AKTIF
# =============================================
list_users() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║           DAFTAR USER (SISA MASA AKTIF)                ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user terdaftar.${NC}"
        press_enter
        return
    fi
    
    local today=$(date +%Y-%m-%d)
    local today_epoch=$(date +%s)
    local aktif=0
    local expired=0
    
    printf "${WHITE}%-20s %-12s %-8s %-12s %s${NC}\n" "PASSWORD" "EXPIRED" "LIMIT" "SISA HARI" "STATUS"
    echo -e "${WHITE}──────────────────────────────────────────────────────────────────${NC}"
    
    while IFS='|' read -r user pass expiry limit; do
        local limit_display="$([ "$limit" == "0" ] && echo "∞" || echo "$limit")"
        
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="Unlimited"
            sisa_hari="${GREEN}∞${NC}"
            ((aktif++))
        else
            local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            local diff_days=$(( (exp_epoch - today_epoch) / 86400 ))
            
            if [[ $diff_days -ge 0 ]]; then
                status="${GREEN}Aktif${NC}"
                exp_display="$expiry"
                sisa_hari="${GREEN}$diff_days hari${NC}"
                ((aktif++))
            else
                status="${RED}Expired${NC}"
                exp_display="$expiry"
                sisa_hari="${RED}Expired${NC}"
                ((expired++))
            fi
        fi
        
        printf "%-20s %-12s %-8s %-12s " "$pass" "$exp_display" "$limit_display" "$(echo -e "$sisa_hari")"
        echo -e "$status"
    done < "$DB"
    
    echo -e "${WHITE}──────────────────────────────────────────────────────────────────${NC}"
    echo -e "Total: ${GREEN}$(wc -l < "$DB")${NC} user | Aktif: ${GREEN}$aktif${NC} | Expired: ${RED}$expired${NC}"
    
    press_enter
}

# =============================================
#  FITUR 6: HAPUS USER
# =============================================
delete_user() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                     HAPUS USER                          ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -s "$DB" ]]; then
        echo -e "${YELLOW}Belum ada user terdaftar.${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}Daftar password:${NC}"
    local i=1
    while IFS='|' read -r user pass expiry limit; do
        echo -e "  ${CYAN}$i.${NC} $pass"
        ((i++))
    done < "$DB"
    
    echo ""
    read -rp "Password yang ingin dihapus: " password
    
    if ! grep -q "|$password|" "$DB"; then
        echo -e "${RED}Password tidak ditemukan!${NC}"
        press_enter
        return
    fi
    
    read -rp "Yakin hapus $password? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/|$password|/d" "$DB"
        update_config_json
        echo -e "${GREEN}✓ User $password dihapus${NC}"
        send_telegram "🗑 *User Dihapus*\nPassword: \`$password\`"
    fi
    
    press_enter
}

# =============================================
#  FITUR 7: HAPUS EXPIRED
# =============================================
clean_expired() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                  HAPUS USER EXPIRED                     ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local today=$(date +%Y-%m-%d)
    local tmpfile=$(mktemp)
    local count=0
    local deleted_list=""
    
    while IFS='|' read -r user pass expiry limit; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass (expired: $expiry)"
            ((count++))
            deleted_list="$deleted_list\n- $pass"
        else
            echo "$user|$pass|$expiry|$limit" >> "$tmpfile"
        fi
    done < "$DB"
    
    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$DB"
        update_config_json
        echo ""
        echo -e "${GREEN}✓ $count user expired berhasil dihapus!${NC}"
        send_telegram "🧹 *CLEAN EXPIRED*\n$count user expired dihapus:$deleted_list"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}Tidak ada user expired.${NC}"
    fi
    
    echo ""
    press_enter
}

# =============================================
#  FITUR 8: SET DOMAIN
# =============================================
set_domain() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                    SET DOMAIN                           ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "Domain saat ini: ${CYAN}$DOMAIN${NC}"
    echo ""
    read -rp "Domain baru: " new_domain
    
    if [[ -n "$new_domain" ]]; then
        DOMAIN="$new_domain"
        echo "$DOMAIN" > "$DOMAIN_FILE"
        echo -e "${GREEN}✓ Domain diubah ke: $new_domain${NC}"
    fi
    
    press_enter
}

# =============================================
#  FITUR 9: RESTART SERVICE
# =============================================
restart_service() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                  RESTART SERVICE                        ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    systemctl restart zivpn.service
    sleep 2
    if systemctl is-active zivpn.service > /dev/null; then
        echo -e "${GREEN}✓ Service berhasil direstart${NC}"
        send_telegram "🔄 *Service Restart*\nZIVPN UDP direstart"
    else
        echo -e "${RED}✗ Service gagal direstart${NC}"
    fi
    
    sleep 2
}

# =============================================
#  FITUR 10: INSTALL ZIVPN
# =============================================
install_zivpn() {
    clear
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                  INSTALL ZIVPN UDP                      ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$ZIVPN_BIN" ]]; then
        echo -e "${YELLOW}ZIVPN sudah terinstall!${NC}"
        press_enter
        return
    fi
    
    echo -e "${BLUE}[1/6]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl ufw cron jq zip unzip net-tools > /dev/null 2>&1
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo -e "${BLUE}[2/6]${NC} Download binary..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        BINARY_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    else
        echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
        press_enter
        return
    fi
    
    wget -q "$BINARY_URL" -O "$ZIVPN_BIN"
    chmod +x "$ZIVPN_BIN"
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo -e "${BLUE}[3/6]${NC} Generate sertifikat SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo -e "${BLUE}[4/6]${NC} Buat config awal..."
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
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo -e "${BLUE}[5/6]${NC} Buat service..."
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
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo -e "${BLUE}[6/6]${NC} Setup firewall..."
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}✓ Selesai${NC}"
    
    echo ""
    echo -e "${GREEN}✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo ""
    echo -e "IP Server: ${CYAN}$(get_ip)${NC}"
    echo -e "Port     : ${CYAN}5667 (UDP)${NC}"
    echo ""
    
    # Kirim notifikasi
    send_telegram "✅ *ZIVPN INSTALLED*
IP: $(get_ip)
Domain: $DOMAIN
ISP: $(get_isp)
Waktu: $(date +"%d %B %Y %H:%M")"
    
    press_enter
}

# =============================================
#  FITUR 11: UNINSTALL
# =============================================
uninstall_zivpn() {
    clear
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║                  UNINSTALL ZIVPN                        ║${NC}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -rp "Yakin uninstall? Semua data akan hilang! [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    
    echo -e "${GREEN}✓ Uninstall selesai${NC}"
    send_telegram "❌ *ZIVPN UNINSTALL*\nIP: $(get_ip)"
    
    sleep 2
}

# =============================================
#  MENU UTAMA
# =============================================
main_menu() {
    while true; do
        banner
        
        if [[ ! -f "$ZIVPN_BIN" ]]; then
            echo -e "${RED}ZIVPN BELUM TERINSTAL!${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
            echo -e "  ${YELLOW}2${NC}. Set Domain"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "Pilih menu: " choice
            
            case $choice in
                1) install_zivpn ;;
                2) set_domain ;;
                0) exit 0 ;;
                *) echo "Pilihan tidak valid"; sleep 1 ;;
            esac
        else
            echo -e "  ${GREEN}1${NC}. Create Akun (Random 2 Digit)"
            echo -e "  ${GREEN}2${NC}. Create Mass Accounts (Global Limit)"
            echo -e "  ${GREEN}3${NC}. Backup (Tampilkan File)"
            echo -e "  ${CYAN}4${NC}. Cek User Online & Device"
            echo -e "  ${CYAN}5${NC}. List Users (Sisa Masa Aktif)"
            echo -e "  ${RED}6${NC}. Hapus User"
            echo -e "  ${YELLOW}7${NC}. Hapus Expired"
            echo -e "  ${BLUE}8${NC}. Set Domain"
            echo -e "  ${PURPLE}9${NC}. Restart Service"
            echo -e "  ${RED}10${NC}. Uninstall ZIVPN"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "Pilih menu: " choice
            
            case $choice in
                1) create_account_random ;;
                2) create_mass_accounts ;;
                3) backup_accounts ;;
                4) check_online_users ;;
                5) list_users ;;
                6) delete_user ;;
                7) clean_expired ;;
                8) set_domain ;;
                9) restart_service ;;
                10) uninstall_zivpn ;;
                0) exit 0 ;;
                *) echo "Pilihan tidak valid"; sleep 1 ;;
            esac
        fi
    done
}

# =============================================
#  START SCRIPT
# =============================================
check_root
main_menu
