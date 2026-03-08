#!/bin/bash
# =============================================
#   ZIVPN UDP Manager
#   By: Custom Script (based on ZIVPN official binary)
#   OS: Ubuntu 20.04 / 22.04 / 24.04
# =============================================

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
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
TELEGRAM_BOT_TOKEN_FILE="$ZIVPN_DIR/bot_token.conf"

# === FUNGSI UTILITAS ===

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root!"
        echo -e "Gunakan: ${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{for(i=1;i<=NF;i++) if($i !~ /:/) {print $i; exit}}'
}

get_domain() {
    if [[ -f "$BACKUP_CONFIG" ]]; then
        source "$BACKUP_CONFIG"
        echo "$DOMAIN"
    else
        echo ""
    fi
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

get_kernel() {
    uname -r
}

is_installed() {
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]
}

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
        local uptime=$(get_uptime)
        local os=$(get_os)
        local kernel=$(get_kernel)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        
        echo -e "  ${WHITE}Status   :${NC} $([[ "$status" == "active" ]] && echo "${GREEN}● AKTIF${NC}" || echo "${RED}● MATI${NC}")"
        echo -e "  ${WHITE}Domain   :${NC} ${CYAN}${domain:-Belum diatur}${NC}"
        echo -e "  ${WHITE}IP       :${NC} ${CYAN}$ip${NC}"
        echo -e "  ${WHITE}ISP      :${NC} ${YELLOW}$isp${NC}"
        echo -e "  ${WHITE}Kota     :${NC} ${YELLOW}$city${NC}"
        echo -e "  ${WHITE}RAM      :${NC} $ram"
        echo -e "  ${WHITE}CPU      :${NC} ${YELLOW}$cpu${NC}"
        echo -e "  ${WHITE}OS       :${NC} ${YELLOW}$os${NC}"
        echo -e "  ${WHITE}Kernel   :${NC} ${YELLOW}$kernel${NC}"
        echo -e "  ${WHITE}Uptime   :${NC} ${YELLOW}$uptime${NC}"
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

# === FUNGSI USER DB ===
# Format users.db: PASSWORD|TANGGAL_EXPIRED(YYYY-MM-DD)
# Contoh: pass123|2025-06-30

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

update_config_json() {
    # Ambil semua password dari users.db yang belum expired
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r pass expiry; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            passwords+=("\"$pass\"")
        fi
    done < "$USERS_DB"

    if [[ ${#passwords[@]} -eq 0 ]]; then
        # Kalau tidak ada user, pakai password default
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

init_backup_config() {
    if [[ ! -f "$BACKUP_CONFIG" ]]; then
        cat > "$BACKUP_CONFIG" <<EOF
# Konfigurasi Backup ZIVPN
DOMAIN=""
BACKUP_URL=""
BACKUP_TOKEN=""
AUTO_BACKUP_HOUR="2"
AUTO_BACKUP_MIN="0"
LAST_BACKUP=""
EOF
    fi
    source "$BACKUP_CONFIG"
}

save_backup_config() {
    cat > "$BACKUP_CONFIG" <<EOF
# Konfigurasi Backup ZIVPN
DOMAIN="$DOMAIN"
BACKUP_URL="$BACKUP_URL"
BACKUP_TOKEN="$BACKUP_TOKEN"
AUTO_BACKUP_HOUR="$AUTO_BACKUP_HOUR"
AUTO_BACKUP_MIN="$AUTO_BACKUP_MIN"
LAST_BACKUP="$LAST_BACKUP"
EOF
}

# === FUNGSI DOMAIN ===

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

create_backup() {
    local backup_file="$BACKUP_DIR/zivpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    # Buat file info backup
    cat > "$ZIVPN_DIR/backup-info.txt" <<EOF
BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BACKUP_IP=$(get_ip)
BACKUP_DOMAIN=$(get_domain)
BACKUP_VERSION=1.0
EOF

    # Backup semua file penting
    tar -czf "$backup_file" \
        "$USERS_DB" \
        "$CONFIG_FILE" \
        "$CERT_FILE" \
        "$KEY_FILE" \
        "$BACKUP_CONFIG" \
        "$ZIVPN_DIR/backup-info.txt" 2>/dev/null

    rm -f "$ZIVPN_DIR/backup-info.txt"
    
    echo "$backup_file"
}

upload_backup() {
    local backup_file="$1"
    local backup_name=$(basename "$backup_file")
    
    if [[ -z "$BACKUP_URL" || -z "$BACKUP_TOKEN" ]]; then
        echo -e "${RED}URL Backup atau Token belum dikonfigurasi!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Mengupload backup...${NC}"
    
    # Contoh upload ke file.io (gratis, file akan expired setelah 1 download atau 24 jam)
    local response=$(curl -s -F "file=@$backup_file" https://file.io)
    local link=$(echo "$response" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$link" ]]; then
        echo -e "${GREEN}Backup berhasil diupload!${NC}"
        echo -e "Link download: ${CYAN}$link${NC}"
        
        # Catat link backup
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $link" >> "$BACKUP_DIR/backup-links.txt"
        
        # Update LAST_BACKUP
        source "$BACKUP_CONFIG"
        LAST_BACKUP=$(date +"%Y-%m-%d %H:%M:%S")
        save_backup_config
        
        return 0
    else
        echo -e "${RED}Gagal upload backup!${NC}"
        return 1
    fi
}

backup_now() {
    banner
    echo -e "${BOLD}${YELLOW}[ BACKUP MANUAL ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${BLUE}[1/2]${NC} Membuat file backup..."
    local backup_file=$(create_backup)
    echo -e "${GREEN}    ✓ Backup berhasil dibuat: $(basename $backup_file)${NC}"
    
    echo -e "${BLUE}[2/2]${NC} Mengupload backup..."
    if upload_backup "$backup_file"; then
        echo ""
        echo -e "${WHITE}══════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✓ BACKUP BERHASIL!${NC}"
        echo -e "${WHITE}══════════════════════════════════════════${NC}"
        echo -e "  File    : ${CYAN}$(basename $backup_file)${NC}"
        echo -e "  Lokasi  : ${CYAN}$BACKUP_DIR${NC}"
        echo -e "  Waktu   : ${YELLOW}$(date +"%Y-%m-%d %H:%M:%S")${NC}"
    fi
    
    echo ""
    press_enter
}

restore_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${WHITE}Pilih sumber backup:${NC}"
    echo -e "  ${CYAN}1${NC}. Dari file lokal"
    echo -e "  ${CYAN}2${NC}. Dari link download"
    echo -e "  ${CYAN}3${NC}. Lihat daftar link backup sebelumnya"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-3] : ${NC}")" restore_choice
    
    case $restore_choice in
        1)
            # Cari file backup lokal
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
            read -rp "$(echo -e "${WHITE}Pilih nomor file : ${NC}")" file_num
            
            if [[ "$file_num" =~ ^[0-9]+$ ]] && [[ "$file_num" -le ${#backups[@]} ]]; then
                backup_file="${backups[$((file_num-1))]}"
            else
                echo -e "${RED}Pilihan tidak valid!${NC}"
                press_enter
                return
            fi
            ;;
        2)
            read -rp "$(echo -e "${WHITE}Masukkan link download backup : ${NC}")" backup_link
            if [[ -z "$backup_link" ]]; then
                echo -e "${RED}Link tidak boleh kosong!${NC}"
                press_enter
                return
            fi
            
            echo -e "${YELLOW}Downloading backup...${NC}"
            backup_file="$BACKUP_DIR/downloaded-backup.tar.gz"
            wget -q "$backup_link" -O "$backup_file"
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
    
    # Konfirmasi restore
    echo ""
    echo -e "${RED}PERHATIAN: Restore akan menimpa semua data user yang ada!${NC}"
    read -rp "$(echo -e "${RED}Yakin ingin restore? [y/N] : ${NC}")" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore dibatalkan.${NC}"
        press_enter
        return
    fi
    
    # Backup dulu data lama
    local old_backup="$BACKUP_DIR/pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
    create_backup > /dev/null
    mv "$(ls -t "$BACKUP_DIR"/*.tar.gz | head -1)" "$old_backup"
    
    # Extract backup
    echo -e "${BLUE}[1/3]${NC} Mengekstrak backup..."
    tar -xzf "$backup_file" -C / 2>/dev/null
    
    # Reload config
    echo -e "${BLUE}[2/3]${NC} Merestart service..."
    systemctl daemon-reload
    systemctl restart zivpn.service
    
    echo -e "${BLUE}[3/3]${NC} Memuat ulang konfigurasi backup..."
    init_backup_config
    
    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ RESTORE BERHASIL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  File backup lama disimpan di:"
    echo -e "  ${CYAN}$old_backup${NC}"
    echo ""
    press_enter
}

configure_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ KONFIGURASI BACKUP ]${NC}"
    echo ""
    
    init_backup_config
    
    echo -e "${WHITE}Konfigurasi saat ini:${NC}"
    echo -e "  Domain       : ${CYAN}${DOMAIN:-Belum diatur}${NC}"
    echo -e "  Backup URL   : ${CYAN}${BACKUP_URL:-Belum diatur}${NC}"
    echo -e "  Backup Token : ${CYAN}${BACKUP_TOKEN:-Belum diatur}${NC}"
    echo -e "  Auto Backup  : ${YELLOW}Setiap jam ${AUTO_BACKUP_HOUR}:${AUTO_BACKUP_MIN}${NC}"
    echo -e "  Last Backup  : ${YELLOW}${LAST_BACKUP:-Belum pernah}${NC}"
    echo ""
    
    echo -e "${WHITE}Pilih konfigurasi:${NC}"
    echo -e "  ${CYAN}1${NC}. Set Domain"
    echo -e "  ${CYAN}2${NC}. Set URL Backup"
    echo -e "  ${CYAN}3${NC}. Set Token Bot"
    echo -e "  ${CYAN}4${NC}. Set Waktu Auto Backup"
    echo -e "  ${CYAN}5${NC}. Ganti Token Bot Auto Backup"
    echo -e "  ${CYAN}6${NC}. Kembali"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-6] : ${NC}")" config_choice
    
    case $config_choice in
        1)
            read -rp "$(echo -e "${WHITE}Masukkan domain (contoh: vpn.example.com) : ${NC}")" new_domain
            if [[ -n "$new_domain" ]]; then
                DOMAIN="$new_domain"
                save_backup_config
                echo -e "${GREEN}Domain berhasil disimpan!${NC}"
            fi
            ;;
        2)
            read -rp "$(echo -e "${WHITE}Masukkan URL Backup (contoh: https://backup.example.com/upload) : ${NC}")" new_url
            if [[ -n "$new_url" ]]; then
                BACKUP_URL="$new_url"
                save_backup_config
                echo -e "${GREEN}URL Backup berhasil disimpan!${NC}"
            fi
            ;;
        3)
            read -rp "$(echo -e "${WHITE}Masukkan Token Bot : ${NC}")" new_token
            if [[ -n "$new_token" ]]; then
                BACKUP_TOKEN="$new_token"
                save_backup_config
                echo -e "${GREEN}Token Bot berhasil disimpan!${NC}"
            fi
            ;;
        4)
            read -rp "$(echo -e "${WHITE}Jam auto backup (0-23) : ${NC}")" new_hour
            if [[ "$new_hour" =~ ^[0-9]+$ ]] && [[ "$new_hour" -ge 0 && "$new_hour" -le 23 ]]; then
                AUTO_BACKUP_HOUR="$new_hour"
                read -rp "$(echo -e "${WHITE}Menit auto backup (0-59) : ${NC}")" new_min
                if [[ "$new_min" =~ ^[0-9]+$ ]] && [[ "$new_min" -ge 0 && "$new_min" -le 59 ]]; then
                    AUTO_BACKUP_MIN="$new_min"
                    save_backup_config
                    setup_auto_backup_cron
                    echo -e "${GREEN}Waktu auto backup berhasil disimpan!${NC}"
                fi
            else
                echo -e "${RED}Input tidak valid!${NC}"
            fi
            ;;
        5)
            read -rp "$(echo -e "${WHITE}Masukkan Token Bot baru untuk auto backup : ${NC}")" new_bot_token
            if [[ -n "$new_bot_token" ]]; then
                echo "$new_bot_token" > "$TELEGRAM_BOT_TOKEN_FILE"
                echo -e "${GREEN}Token Bot auto backup berhasil diganti!${NC}"
            fi
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            ;;
    esac
    
    sleep 1
    configure_backup
}

setup_auto_backup_cron() {
    init_backup_config
    
    # Hapus cron auto backup yang lama
    crontab -l 2>/dev/null | grep -v "zivpn-auto-backup" | crontab -
    
    # Buat script auto backup
    cat > /usr/local/bin/zivpn-auto-backup.sh <<'CRONEOF'
#!/bin/bash
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
BACKUP_CONFIG="$ZIVPN_DIR/backup.conf"
USERS_DB="$ZIVPN_DIR/users.db"
CONFIG_FILE="$ZIVPN_DIR/config.json"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
TELEGRAM_BOT_TOKEN_FILE="$ZIVPN_DIR/bot_token.conf"

source "$BACKUP_CONFIG"

# Fungsi kirim notifikasi ke Telegram
send_telegram_notif() {
    if [[ -f "$TELEGRAM_BOT_TOKEN_FILE" ]]; then
        BOT_TOKEN=$(cat "$TELEGRAM_BOT_TOKEN_FILE")
        CHAT_ID="$BACKUP_TOKEN"
        MESSAGE="$1"
        
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$MESSAGE" \
            -d parse_mode="HTML" > /dev/null 2>&1
    fi
}

# Buat backup
backup_file="$BACKUP_DIR/zivpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
mkdir -p "$BACKUP_DIR"

cat > "$ZIVPN_DIR/backup-info.txt" <<EOF
BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BACKUP_IP=$(curl -4 -s ifconfig.me)
BACKUP_DOMAIN=$DOMAIN
BACKUP_VERSION=1.0
EOF

tar -czf "$backup_file" \
    "$USERS_DB" \
    "$CONFIG_FILE" \
    "$CERT_FILE" \
    "$KEY_FILE" \
    "$BACKUP_CONFIG" \
    "$ZIVPN_DIR/backup-info.txt" 2>/dev/null

rm -f "$ZIVPN_DIR/backup-info.txt"

# Upload ke file.io
response=$(curl -s -F "file=@$backup_file" https://file.io)
link=$(echo "$response" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)

if [[ -n "$link" ]]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $link" >> "$BACKUP_DIR/backup-links.txt"
    
    # Update LAST_BACKUP
    sed -i "s/^LAST_BACKUP=.*/LAST_BACKUP=\"$(date +"%Y-%m-%d %H:%M:%S")\"/" "$BACKUP_CONFIG"
    
    # Kirim notifikasi
    send_telegram_notif "✅ <b>Backup ZIVPN Berhasil</b>
    
Waktu: $(date +"%Y-%m-%d %H:%M:%S")
IP: $(curl -4 -s ifconfig.me)
Domain: $DOMAIN
File: $(basename $backup_file)
Link Download: $link

Gunakan link di atas untuk restore jika diperlukan."
else
    send_telegram_notif "❌ <b>Backup ZIVPN Gagal</b>
    
Waktu: $(date +"%Y-%m-%d %H:%M:%S")
IP: $(curl -4 -s ifconfig.me)
Error: Gagal upload backup"
fi
CRONEOF
    
    chmod +x /usr/local/bin/zivpn-auto-backup.sh
    
    # Setup cron baru
    (crontab -l 2>/dev/null; echo "$AUTO_BACKUP_MIN $AUTO_BACKUP_HOUR * * * /usr/local/bin/zivpn-auto-backup.sh") | crontab -
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
    apt-get install -y wget curl openssl iptables ufw cron tar lsb-release coreutils > /dev/null 2>&1
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
    init_backup_config
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
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    systemctl start zivpn.service
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[6/6]${NC} Setup firewall & iptables..."
    sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
    sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1

    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null

    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    # Setup cron untuk auto-hapus expired user (setiap hari jam 00:00)
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
CHANGED=0

if [[ ! -f "$USERS_DB" ]]; then exit 0; fi

TMPFILE=$(mktemp)
while IFS='|' read -r pass expiry; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        CHANGED=1
    else
        echo "$pass|$expiry" >> "$TMPFILE"
    fi
done < "$USERS_DB"

if [[ $CHANGED -eq 1 ]]; then
    mv "$TMPFILE" "$USERS_DB"
    # Rebuild config.json
    passwords=()
    while IFS='|' read -r pass expiry; do
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
else
    rm -f "$TMPFILE"
fi
CRONEOF
    chmod +x /usr/local/bin/zivpn-cron.sh

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ ZIVPN UDP BERHASIL DIINSTALL!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  IP VPS  : ${CYAN}$(get_ip)${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "  Status  : ${GREEN}$(systemctl is-active zivpn.service)${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}  Jangan lupa setting domain via menu ${BOLD}13. Set Domain${NC}"
    echo -e "${YELLOW}  Cara connect di ZIVPN App:${NC}"
    echo -e "  1. Buka ZIVPN → centang ${BOLD}UDP Tunnel${NC}"
    echo -e "  2. UDP Server  : ${CYAN}[gunakan domain yang sudah diset]${NC}"
    echo -e "  3. UDP Password: ${CYAN}[buat dulu via menu Tambah User]${NC}"
    echo -e "  4. Tap APPLY → START"
    echo ""

    # Pasang shortcut 'zivpn' biar bisa dipanggil dari mana saja
    cp "$(realpath $0)" /usr/local/bin/zivpn-menu 2>/dev/null
    chmod +x /usr/local/bin/zivpn-menu 2>/dev/null
    if ! grep -q "zivpn-menu" /root/.bashrc 2>/dev/null; then
        echo "alias zivpn='bash /usr/local/bin/zivpn-menu'" >> /root/.bashrc
    fi
    echo -e "${GREEN}  Tip: Ketik ${BOLD}zivpn${NC}${GREEN} kapanpun untuk buka menu ini${NC}"
    echo ""
    press_enter
}

# === TAMBAH USER (TANPA USERNAME, PAKAI DOMAIN) ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users
    init_backup_config

    read -rp "$(echo -e "${WHITE}Password    : ${NC}")" password
    if [[ -z "$password" ]]; then
        echo -e "${RED}[!] Password tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    if user_exists "$password"; then
        echo -e "${RED}[!] Password '$password' sudah digunakan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Expired : ${NC}")" days
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
        press_enter
        return
    fi

    if [[ "$days" -eq 0 ]]; then
        expiry="unlimited"
    else
        expiry=$(date -d "+$days days" +%Y-%m-%d)
    fi

    echo "$password|$expiry" >> "$USERS_DB"
    update_config_json

    echo ""
echo -e "${WHITE}═════════════════${NC}"
echo -e "${GREEN}  ✓ Terima kasih sudah order kak😁${NC}"
echo -e "${WHITE}═════════════════${NC}"
echo -e "  ${CYAN}ZIVPN UDP${NC}"
echo -e "${WHITE}═════════════════${NC}"

# Informasi Server dan User
if [[ -n "$DOMAIN" ]]; then
    echo -e "  Domain      : ${CYAN}$DOMAIN${NC}"
else
    echo -e "  Domain      : ${RED}Belum diatur${NC}"
    echo -e "  IP Server   : ${CYAN}$(get_ip)${NC}"
fi
echo -e "  Password    : ${YELLOW}$password${NC}"
echo -e "  ISP Server  : ${CYAN}$(get_isp)${NC}"
echo -e "  Lokasi      : ${CYAN}$(get_city)${NC}"
echo -e "  ${WHITE}────────────────${NC}"
echo -e "  Tanggal Buat: ${GREEN}$(date +"%Y-%m-%d")${NC}"

if [[ "$expiry" == "unlimited" ]]; then
    echo -e "  Tanggal Exp : ${GREEN}Unlimited${NC}"
    echo -e "  Masa Aktif  : ${GREEN}Selamanya${NC}"
else
    echo -e "  Tanggal Exp : ${YELLOW}$expiry${NC}"
    echo -e "  Masa Aktif  : ${YELLOW}${days} hari${NC}"
fi

echo -e "${WHITE}────────────────${NC}"
echo -e "  ${YELLOW}Tutorial ZIVPN APP / UDP Tunnel${NC}"
echo -e "${WHITE}────────────────${NC}"
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
echo -e "${WHITE}═════════════════${NC}"
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
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi

    press_enter
}

# === LIST USER ===

list_users_simple() {
    echo -e "${WHITE}Daftar password user:${NC}"
    local i=1
    while IFS='|' read -r pass expiry; do
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
    printf "${WHITE}%-20s %-15s %-10s${NC}\n" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}─────────────────────────────────────────────${NC}"

    while IFS='|' read -r pass expiry; do
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
        printf "%-20s %-15s " "$pass" "$(echo -e $exp_display)"
        echo -e "$status"
    done < "$USERS_DB"

    echo -e "${WHITE}─────────────────────────────────────────────${NC}"
    echo ""
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

    if [[ "$days" -eq 0 ]]; then
        new_expiry="unlimited"
    else
        # Jika sudah expired, hitung dari hari ini
        local today=$(date +%Y-%m-%d)
        if [[ "$old_expiry" == "unlimited" ]] || [[ "$old_expiry" > "$today" ]]; then
            new_expiry=$(date -d "$old_expiry +$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
        else
            new_expiry=$(date -d "+$days days" +%Y-%m-%d)
        fi
    fi

    sed -i "s/^$password|$old_expiry/$password|$new_expiry/" "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User dengan password '$password' berhasil diperpanjang!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    if [[ "$new_expiry" == "unlimited" ]]; then
        echo -e "  Expired baru : ${GREEN}Unlimited${NC}"
    else
        echo -e "  Expired baru : ${YELLOW}$new_expiry${NC} (+${days} hari)"
    fi
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
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
    local status=$(systemctl is-active zivpn.service)
    if [[ "$status" == "active" ]]; then
        echo -e "${GREEN}  ✓ Service berhasil di-restart!${NC}"
    else
        echo -e "${RED}  ✗ Service gagal restart. Cek log: journalctl -u zivpn.service${NC}"
    fi
    echo ""
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

    while IFS='|' read -r pass expiry; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $pass (expired: $expiry)"
            ((count++))
        else
            echo "$pass|$expiry" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}  ✓ $count user expired berhasil dihapus!${NC}"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}  Tidak ada user expired.${NC}"
    fi

    echo ""
    press_enter
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE ZIVPN MANAGER ]${NC}"
    echo ""

    # Ganti URL ini dengan URL raw script GitHub kamu nanti
    local SCRIPT_URL="https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zivo.sh"
    local SCRIPT_PATH=$(realpath "$0")

    echo -e "  Mengecek update dari GitHub..."
    local tmp=$(mktemp)
    wget -q "$SCRIPT_URL" -O "$tmp"

    if [[ ! -s "$tmp" ]]; then
        echo -e "${RED}  [!] Gagal download update. Cek koneksi atau URL repo!${NC}"
        rm -f "$tmp"
        press_enter
        return
    fi

    # Cek apakah ada perubahan
    if diff -q "$tmp" "$SCRIPT_PATH" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Script sudah versi terbaru!${NC}"
        rm -f "$tmp"
    else
        cp "$tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        rm -f "$tmp"
        echo -e "${GREEN}  ✓ Script berhasil diupdate!${NC}"
        echo -e "${YELLOW}  Silakan jalankan ulang script.${NC}"
        echo ""
        press_enter
        exec bash "$SCRIPT_PATH"
    fi

    echo ""
    press_enter
}

# === UNINSTALL ===

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN UDP ]${NC}"
    echo ""
    read -rp "$(echo -e "${RED}Yakin ingin uninstall ZIVPN UDP? Semua data akan hilang! [y/N] : ${NC}")" confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  Dibatalkan.${NC}"
        press_enter
        return
    fi

    echo -e "  Menghentikan service..."
    systemctl stop zivpn.service
    systemctl disable zivpn.service > /dev/null 2>&1

    echo -e "  Menghapus file..."
    rm -f "$SERVICE_FILE"
    rm -f "$ZIVPN_BIN"
    rm -f /usr/local/bin/zivpn-cron.sh
    rm -f /usr/local/bin/zivpn-menu
    rm -f /usr/local/bin/zivpn-auto-backup.sh
    sed -i "/alias zivpn=/d" /root/.bashrc 2>/dev/null
    rm -rf "$ZIVPN_DIR"

    systemctl daemon-reload

    echo -e "  Hapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn-cron" | grep -v "zivpn-auto-backup" | crontab -

    echo ""
    echo -e "${GREEN}  ✓ ZIVPN UDP berhasil diuninstall!${NC}"
    echo -e "${YELLOW}  Keluar dari menu...${NC}"
    echo ""
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
            echo -e "  ${GREEN}1${NC}. Tambah User"
            echo -e "  ${RED}2${NC}. Hapus User"
            echo -e "  ${CYAN}3${NC}. Daftar User"
            echo -e "  ${YELLOW}4${NC}. Perpanjang User"
            echo -e "  ${PURPLE}5${NC}. Hapus User Expired"
            echo ""
            echo -e "  ${BLUE}6${NC}. Status Service"
            echo -e "  ${BLUE}7${NC}. Restart Service"
            echo ""
            echo -e "  ${MAGENTA}8${NC}. Backup Manual"
            echo -e "  ${MAGENTA}9${NC}. Restore Backup"
            echo -e "  ${MAGENTA}10${NC}. Konfigurasi Backup"
            echo ""
            echo -e "  ${GREEN}11${NC}. Update Script"
            echo -e "  ${RED}12${NC}. Uninstall ZIVPN"
            echo -e "  ${CYAN}13${NC}. Set Domain"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [1-13] : ${NC}")" choice

            case $choice in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) clean_expired ;;
                6) status_service ;;
                7) restart_service ;;
                8) backup_now ;;
                9) restore_backup ;;
                10) configure_backup ;;
                11) update_script ;;
                12) uninstall_zivpn ;;
                13) set_domain ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === ENTRY POINT ===

check_root
main_menu
