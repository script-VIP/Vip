#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER - ZIVON BOT
#   Fitur: Mass Create, Backup Sisa Hari, Restore
#   Token: 8504261570:AAF5rtJ2wW9nrS6EOMyScB5ZGnZcL8sRcXA
#   OS: Ubuntu 20.04 / 22.04 / 24.04
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

send_file_telegram() {
    local file="$1"
    local caption="$2"
    [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ] && return 1
    [ ! -f "$file" ] && return 1
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" \
        -F parse_mode="Markdown" > /dev/null 2>&1
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
#  FITUR 1: CREATE MASS ACCOUNTS (GLOBAL LIMIT)
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
    echo -e "${WHITE}│${NC}  Dedi 23                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Sera 12                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Weni3 3                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  selesai                                                              ${WHITE}│${NC}"
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
    echo -e "${WHITE}Silahkan input user (nama masaaktif):${NC}"
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
#  FITUR 2: BACKUP (SISA MASA AKTIF)
# =============================================
backup_accounts() {
    banner
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
    echo "# Contoh: Dedi 23 (sisa 23 hari)" >> "$tmp_file"
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
    
    local line_num=0
    while IFS= read -r line; do
        if [[ $line_num -lt 15 ]]; then
            if [[ "$line" == \#* ]]; then
                echo -e "${WHITE}│${CYAN}  $line${NC} ${WHITE}│${NC}"
            elif [[ "$line" == "Limit IP:"* ]]; then
                echo -e "${WHITE}│${YELLOW}  $line${NC} ${WHITE}│${NC}"
            else
                echo -e "${WHITE}│${GREEN}  $line${NC} ${WHITE}│${NC}"
            fi
        fi
        ((line_num++))
    done < "$tmp_file"
    
    if [[ $line_num -gt 15 ]]; then
        echo -e "${WHITE}│${NC}  ... dan $((line_num - 15)) baris lainnya                ${WHITE}│${NC}"
    fi
    
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
    
    echo -e "${GREEN}✓ File backup disimpan:${NC}"
    echo -e "  ${CYAN}$backup_path${NC}"
    echo ""
    
    # Hitung statistik
    local total_group=$(grep -c "Limit IP:" "$backup_path")
    
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${YELLOW}  STATISTIK BACKUP:${NC}                                              ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC}  Total User    : ${GREEN}$total_user_backup${NC}                                         ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Group Limit   : ${GREEN}$total_group${NC}                                         ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  File Name     : ${CYAN}$filename${NC}                      ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Opsi upload
    echo -e "${YELLOW}Upload ke:${NC}"
    echo -e "  ${GREEN}1${NC}. Telegram"
    echo -e "  ${GREEN}2${NC}. Lihat isi file lengkap"
    echo -e "  ${RED}0${NC}. Selesai"
    echo ""
    read -rp "Pilih [0-2]: " up_choice
    
    case $up_choice in
        1)
            echo "Mengupload ke Telegram..."
            local caption="📁 *BACKUP AKUN ZIVPN*
Domain: $DOMAIN
Tanggal: $(date +"%d %B %Y %H:%M")
Total User: $total_user_backup
Group Limit: $total_group

*Format File:*
- Limit IP: [angka]
- nama sisa_hari

File ini bisa langsung digunakan untuk CREATE ulang"
            send_file_telegram "$backup_path" "$caption"
            echo -e "${GREEN}✓ Terkirim ke Telegram!${NC}"
            sleep 2
            ;;
        2)
            echo ""
            echo -e "${WHITE}╔════════════════════════════════════════════════════════╗${NC}"
            echo -e "${WHITE}║${CYAN}                   ISI FILE BACKUP                     ${WHITE}║${NC}"
            echo -e "${WHITE}╚════════════════════════════════════════════════════════╝${NC}"
            echo ""
            cat "$backup_path"
            echo ""
            press_enter
            ;;
    esac
}

# =============================================
#  FITUR 3: CREATE FROM BACKUP FILE
#  (LANGSUNG PAKAI SISA HARI)
# =============================================
create_from_backup() {
    banner
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║        CREATE AKUN DARI FILE BACKUP (SISA HARI)        ║${NC}"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${GREEN}  FILE BACKUP = LANGSUNG DIPAKAI CREATE${NC}                         ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Contoh isi file:                                            ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Limit IP: 2                                                 ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Dedi 23    → Create: Dedi, masa aktif 23 hari              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Sera 12    → Create: Sera, masa aktif 12 hari              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Weni3 3    → Create: Weni3, masa aktif 3 hari              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}                                                              ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Limit IP: 1                                                 ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Asa 32     → Create: Asa, masa aktif 32 hari               ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Kimi2 34   → Create: Kimi2, masa aktif 34 hari             ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}Pilih sumber file backup:${NC}"
    echo -e "  ${GREEN}1${NC}. File Lokal (dari $BACKUP_DIR)"
    echo -e "  ${GREEN}2${NC}. Link URL"
    echo -e "  ${GREEN}3${NC}. Telegram"
    echo -e "  ${RED}0${NC}. Kembali"
    echo ""
    read -rp "Pilih [0-3]: " src_choice
    
    local file_path=""
    
    case $src_choice in
        1)
            echo ""
            echo "File di $BACKUP_DIR:"
            echo "----------------------------------------"
            ls -lh "$BACKUP_DIR"/*.txt 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' | head -10
            echo "----------------------------------------"
            echo ""
            read -rp "Masukkan nama file: " filename
            file_path="$BACKUP_DIR/$filename"
            if [[ ! -f "$file_path" ]]; then
                echo -e "${RED}File tidak ditemukan!${NC}"
                press_enter
                return
            fi
            ;;
        2)
            echo ""
            read -rp "Masukkan URL file: " file_url
            file_path="/tmp/restore_$$.txt"
            echo "Mengunduh file..."
            wget -q --show-progress "$file_url" -O "$file_path"
            if [[ ! -f "$file_path" ]] || [[ ! -s "$file_path" ]]; then
                echo -e "${RED}Gagal mengunduh file!${NC}"
                rm -f "$file_path"
                press_enter
                return
            fi
            echo -e "${GREEN}✓ Download berhasil${NC}"
            ;;
        3)
            echo ""
            echo "Cara dapat file path dari Telegram:"
            echo "1. Buka chat dengan bot"
            echo "2. Cari file backup yang dikirim"
            echo "3. Klik file → Copy link/file path"
            echo ""
            read -rp "Masukkan File ID/Path: " file_id
            file_path="/tmp/restore_$$.txt"
            echo "Mengunduh dari Telegram..."
            local download_url="https://api.telegram.org/file/bot$BOT_TOKEN/$file_id"
            wget -q --show-progress "$download_url" -O "$file_path"
            if [[ ! -f "$file_path" ]] || [[ ! -s "$file_path" ]]; then
                echo -e "${RED}Gagal mengunduh file!${NC}"
                rm -f "$file_path"
                press_enter
                return
            fi
            echo -e "${GREEN}✓ Download berhasil${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            return
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Memproses file backup...${NC}"
    echo ""
    
    # Tampilkan preview file
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}                    PREVIEW FILE BACKUP                    ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    local line_num=0
    while IFS= read -r line; do
        if [[ $line_num -lt 8 ]]; then
            if [[ "$line" == \#* ]]; then
                echo -e "${WHITE}│${CYAN}  $line${NC} ${WHITE}│${NC}"
            elif [[ "$line" == "Limit IP:"* ]]; then
                echo -e "${WHITE}│${YELLOW}  $line${NC} ${WHITE}│${NC}"
            elif [[ -n "$line" ]]; then
                echo -e "${WHITE}│${GREEN}  $line${NC} ${WHITE}│${NC}"
            fi
        fi
        ((line_num++))
    done < "$file_path"
    
    if [[ $line_num -gt 8 ]]; then
        echo -e "${WHITE}│${NC}  ... dan $((line_num - 8)) baris lainnya                ${WHITE}│${NC}"
    fi
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    read -rp "Lanjutkan create akun dari file ini? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Dibatalkan.${NC}"
        rm -f "$file_path"
        press_enter
        return
    fi
    
    # Proses file
    local current_limit="2"
    local restored=0
    local skipped=0
    local failed=0
    local created_list=()
    
    echo ""
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${CYAN}                    PROSES CREATE AKUN                     ${WHITE}│${NC}"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────┤${NC}"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip komentar dan baris kosong
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Cek baris Limit IP
        if [[ "$line" =~ ^Limit[[:space:]]IP:[[:space:]]([0-9]+)$ ]]; then
            current_limit="${BASH_REMATCH[1]}"
            local limit_display="$([ "$current_limit" == "0" ] && echo "Unlimited" || echo "$current_limit Device")"
            echo -e "${WHITE}│${YELLOW}  → Set Limit IP: $limit_display${NC}        ${WHITE}│${NC}"
            continue
        fi
        
        # Parse user (nama sisa_hari)
        local arr=($line)
        if [[ ${#arr[@]} -ge 2 ]]; then
            local name="${arr[0]}"
            local days="${arr[1]}"
            
            # Validasi days harus angka
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                echo -e "${WHITE}│${RED}  ✗ $line (masa aktif bukan angka)${NC}        ${WHITE}│${NC}"
                ((failed++))
                continue
            fi
            
            # Password = nama
            local password="$name"
            
            # Cek duplikasi
            if grep -q "|$password|" "$DB" 2>/dev/null; then
                echo -e "${WHITE}│${YELLOW}  ⚠ $password sudah ada, dilewati${NC}        ${WHITE}│${NC}"
                ((skipped++))
                continue
            fi
            
            # Hitung expired dari HARI INI + days
            local exp=""
            if [[ "$days" == "0" ]]; then
                exp="unlimited"
            else
                exp=$(date -d "+$days days" +"%Y-%m-%d")
            fi
            
            # Simpan ke database
            echo "user_$password|$password|$exp|$current_limit" >> "$DB"
            echo -e "${WHITE}│${GREEN}  ✓ $password (${days} hari, limit: $current_limit)${NC}   ${WHITE}│${NC}"
            ((restored++))
            created_list+=("$name|$password|$days")
        fi
    done < "$file_path"
    
    echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    if [[ $restored -gt 0 ]]; then
        # Update config
        update_config_json
        
        # Tampilkan ringkasan
        echo -e "${WHITE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║${GREEN}                 CREATE SELESAI                       ${WHITE}║${NC}"
        echo -e "${WHITE}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${WHITE}║${NC}  Berhasil : ${GREEN}$restored user${NC}                               ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC}  Dilewati : ${YELLOW}$skipped user${NC} (sudah ada)                     ${WHITE}║${NC}"
        echo -e "${WHITE}║${NC}  Gagal    : ${RED}$failed user${NC}                                   ${WHITE}║${NC}"
        echo -e "${WHITE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Tampilkan daftar yang berhasil
        echo -e "${CYAN}Daftar Password Baru:${NC}"
        for item in "${created_list[@]}"; do
            IFS='|' read -r name pass days <<< "$item"
            echo -e "  ${GREEN}✓${NC} $name → ${CYAN}$pass${NC} (${days} hari)"
        done
        echo ""
        
        # Kirim notifikasi
        local location=$(get_location)
        local list_pass=""
        for item in "${created_list[@]}"; do
            IFS='|' read -r name pass days <<< "$item"
            list_pass="$list_pass\n- $name : \`$pass\` (${days} hari)"
        done
        
        send_telegram "🔄 *CREATE DARI FILE BACKUP*
Berhasil : $restored user
Dilewati : $skipped user
Server   : $location
══════════════════════
Daftar Baru:$list_pass"
    fi
    
    # Bersihkan
    rm -f "$file_path"
    
    echo ""
    press_enter
}

# =============================================
#  FITUR 4: LIST USERS
# =============================================
list_users() {
    banner
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║                     DAFTAR USER                         ║${NC}"
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
    
    printf "${WHITE}%-20s %-15s %-10s %s${NC}\n" "PASSWORD" "EXPIRED" "LIMIT" "STATUS"
    echo -e "${WHITE}──────────────────────────────────────────────────────${NC}"
    
    while IFS='|' read -r user pass expiry limit; do
        # Hitung sisa hari
        local sisa_hari=""
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"
            exp_display="Unlimited"
            sisa_hari="∞"
            ((aktif++))
        else
            local exp_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            local diff_days=$(( (exp_epoch - today_epoch) / 86400 ))
            
            if [[ $diff_days -ge 0 ]]; then
                status="${GREEN}Aktif${NC}"
                exp_display="$expiry"
                sisa_hari="${diff_days} hari"
                ((aktif++))
            else
                status="${RED}Expired${NC}"
                exp_display="$expiry"
                sisa_hari="Expired"
                ((expired++))
            fi
        fi
        
        limit_display="$([ "$limit" == "0" ] && echo "∞" || echo "$limit")"
        
        printf "%-20s %-15s %-10s " "$pass" "$exp_display" "$limit_display"
        echo -e "$status"
    done < "$DB"
    
    echo -e "${WHITE}──────────────────────────────────────────────────────${NC}"
    echo -e "Total: ${GREEN}$(wc -l < "$DB")${NC} user | Aktif: ${GREEN}$aktif${NC} | Expired: ${RED}$expired${NC}"
    
    press_enter
}

# =============================================
#  FITUR 5: HAPUS USER
# =============================================
delete_user() {
    banner
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
#  FITUR 6: SET DOMAIN
# =============================================
set_domain() {
    banner
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
#  FITUR 7: HAPUS EXPIRED
# =============================================
clean_expired() {
    banner
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
#  FITUR 8: RESTART SERVICE
# =============================================
restart_service() {
    banner
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
#  FITUR 9: INSTALL ZIVPN
# =============================================
install_zivpn() {
    banner
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
    apt-get install -y wget curl openssl ufw cron jq zip unzip > /dev/null 2>&1
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
#  FITUR 10: UNINSTALL
# =============================================
uninstall_zivpn() {
    banner
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
            echo -e "  ${GREEN}1${NC}. Create Mass Accounts (Global Limit)"
            echo -e "  ${GREEN}2${NC}. Backup Accounts (Sisa Hari)"
            echo -e "  ${GREEN}3${NC}. Create dari File Backup"
            echo -e "  ${CYAN}4${NC}. List Users"
            echo -e "  ${RED}5${NC}. Hapus User"
            echo -e "  ${YELLOW}6${NC}. Hapus Expired"
            echo -e "  ${BLUE}7${NC}. Set Domain"
            echo -e "  ${PURPLE}8${NC}. Restart Service"
            echo -e "  ${RED}9${NC}. Uninstall ZIVPN"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "Pilih menu: " choice
            
            case $choice in
                1) create_mass_accounts ;;
                2) backup_accounts ;;
                3) create_from_backup ;;
                4) list_users ;;
                5) delete_user ;;
                6) clean_expired ;;
                7) set_domain ;;
                8) restart_service ;;
                9) uninstall_zivpn ;;
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
