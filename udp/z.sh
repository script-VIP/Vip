#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER + AUTO BACKUP BOT
#   By: Custom Script
#   OS: Ubuntu 20.04 / 22.04 / 24.04
#   Fitur: Auto Backup ke Telegram, Info Server
# =============================================

# === KONFIGURASI BOT TELEGRAM ===
BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
CHAT_ID="6198984094"
BACKUP_URL="https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
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
LOG_FILE="$ZIVPN_DIR/backup.log"

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
    local ip=$(get_ip)
    local domain=""
    
    # Coba resolve domain dari IP
    domain=$(dig +short -x "$ip" 2>/dev/null | head -n1 | sed 's/\.$//')
    if [[ -z "$domain" ]]; then
        domain=$(nslookup "$ip" 2>/dev/null | grep 'name =' | awk '{print $4}' | sed 's/\.$//')
    fi
    if [[ -z "$domain" ]]; then
        domain="$ip" # Fallback ke IP jika tidak ada domain
    fi
    
    echo "$domain"
}

get_isp() {
    curl -s "http://ip-api.com/line/$(get_ip)?fields=isp" 2>/dev/null || echo "Unknown ISP"
}

get_country() {
    curl -s "http://ip-api.com/line/$(get_ip)?fields=country" 2>/dev/null || echo "Unknown"
}

get_city() {
    curl -s "http://ip-api.com/line/$(get_ip)?fields=city" 2>/dev/null || echo "Unknown"
}

get_server_info() {
    local ip=$(get_ip)
    local domain=$(get_domain)
    local isp=$(get_isp)
    local country=$(get_country)
    local city=$(get_city)
    local hostname=$(hostname)
    local uptime=$(uptime -p | sed 's/up //')
    local os=$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
    local kernel=$(uname -r)
    local cpu=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    local ram=$(free -h | grep Mem | awk '{print $2}')
    local swap=$(free -h | grep Swap | awk '{print $2}')
    local disk=$(df -h / | awk 'NR==2 {print $2}')
    
    echo "SERVER INFORMATION"
    echo "══════════════════════════════════════════"
    echo "Hostname    : $hostname"
    echo "IP Address  : $ip"
    echo "Domain      : $domain"
    echo "ISP         : $isp"
    echo "Lokasi      : $city, $country"
    echo "OS          : $os"
    echo "Kernel      : $kernel"
    echo "CPU         : $cpu"
    echo "RAM         : $ram"
    echo "Swap        : $swap"
    echo "Disk        : $disk"
    echo "Uptime      : $uptime"
    echo "══════════════════════════════════════════"
}

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
    curl -s -X POST "$BACKUP_URL" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$file" \
        -F caption="$caption" > /dev/null 2>&1
}

backup_system() {
    local backup_time=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/zivpn_backup_$backup_time.tar.gz"
    local message=""
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup semua konfigurasi dan database
    tar -czf "$backup_file" -C /etc zivpn/ 2>/dev/null
    
    # Informasi backup
    local file_size=$(du -h "$backup_file" | cut -f1)
    local user_count=$(wc -l < "$USERS_DB")
    
    # Hapus backup lama (simpan 7 backup terakhir)
    cd "$BACKUP_DIR" && ls -t | tail -n +8 | xargs -r rm -f
    
    # Kirim ke Telegram
    message=$(cat <<EOF
✅ <b>AUTO BACKUP BERHASIL</b>
══════════════════════════════════════════
Waktu    : $(date +"%d %B %Y %H:%M:%S")
Ukuran   : $file_size
Total User : $user_count
══════════════════════════════════════════
EOF
)
    
    send_telegram_file "$backup_file" "$message"
    echo "$(date): Backup created: $backup_file ($file_size)" >> "$LOG_FILE"
    
    # Juga kirim info server
    send_server_info
}

send_server_info() {
    local ip=$(get_ip)
    local domain=$(get_domain)
    local isp=$(get_isp)
    local country=$(get_country)
    local city=$(get_city)
    local hostname=$(hostname)
    local status=$(systemctl is-active zivpn.service)
    
    if [[ "$status" == "active" ]]; then
        status="${GREEN}● AKTIF${NC}"
    else
        status="${RED}● MATI${NC}"
    fi
    
    local message=$(cat <<EOF
📡 <b>SERVER INFORMATION</b>
══════════════════════════════════════════
Hostname    : $hostname
IP Address  : $ip
Domain      : $domain
ISP         : $isp
Lokasi      : $city, $country
Status VPN  : $status
══════════════════════════════════════════
EOF
)
    
    send_telegram "$message"
}

restore_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTORE BACKUP ]${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
        echo -e "${RED}[!] Tidak ada file backup ditemukan!${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}Daftar Backup Tersedia:${NC}"
    echo "══════════════════════════════════════════"
    
    local i=1
    local backups=()
    for backup in $(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null); do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(echo "$filename" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
        echo -e "  ${CYAN}$i.${NC} $date - $size"
        backups+=("$backup")
        ((i++))
    done
    
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih nomor backup yang akan direstore [0 untuk batal]: ${NC}")" choice
    
    if [[ "$choice" -eq 0 ]]; then
        echo -e "${YELLOW}Dibatalkan.${NC}"
        press_enter
        return
    fi
    
    if [[ "$choice" -gt 0 && "$choice" -le ${#backups[@]} ]]; then
        local selected="${backups[$((choice-1))]}"
        echo -e "${YELLOW}Menghentikan service...${NC}"
        systemctl stop zivpn.service
        
        echo -e "${YELLOW}Merestore backup...${NC}"
        tar -xzf "$selected" -C /
        
        echo -e "${YELLOW}Menjalankan ulang service...${NC}"
        systemctl start zivpn.service
        
        echo -e "${GREEN}✓ Restore backup berhasil!${NC}"
        
        # Kirim notifikasi ke Telegram
        send_telegram "✅ Restore backup berhasil dilakukan dari file: $(basename "$selected")"
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi
    
    press_enter
}

setup_auto_backup() {
    local cron_job="0 */6 * * * bash /usr/local/bin/zivpn-menu --backup"
    
    if crontab -l 2>/dev/null | grep -q "zivpn.*--backup"; then
        echo -e "${YELLOW}Auto backup sudah terinstall!${NC}"
    else
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo -e "${GREEN}✓ Auto backup diinstall (setiap 6 jam)${NC}"
    fi
}

generate_user_info() {
    local username="$1"
    local password="$2"
    local expiry="$3"
    local domain=$(get_domain)
    local ip=$(get_ip)
    local isp=$(get_isp)
    local country=$(get_country)
    
    cat <<EOF
Terima kasih sudah order kak😇
═ ═══ ═
UDP ZIVPN
══════════════════════════════════════════
  Label    : $username
  UDP Server  : $domain
  UDP Password: $password
  Expired  : $expiry
  ISP        : $isp
  Lokasi     : $country
══════════════════════════════════════════ >  TUTORIAL
*⚙️ LOGIN KE APK ZIVPN*
*🔍 Garis tiga (pojok kiri atas)*
*🛠 UDP Tunnel Setting*
*Udp Server.    :* $domain 
*Udp Password :* $password
✅ Apply
✅ Centang UDP
✅ Servernya Singapore premium 5 (terserah bebas) 
> ▶ START
EOF
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
    
    # Tampilkan info server
    local ip=$(get_ip)
    local domain=$(get_domain)
    local isp=$(get_isp)
    local country=$(get_country)
    local city=$(get_city)
    local status=$(systemctl is-active zivpn.service 2>/dev/null)
    
    if [[ "$status" == "active" ]]; then
        echo -e "  Status  : ${GREEN}● AKTIF${NC}"
    else
        echo -e "  Status  : ${RED}● MATI${NC}"
    fi
    echo -e "  IP VPS  : ${CYAN}$ip${NC}"
    echo -e "  Domain  : ${CYAN}$domain${NC}"
    echo -e "  ISP     : ${YELLOW}$isp${NC}"
    echo -e "  Lokasi  : ${YELLOW}$city, $country${NC}"
    echo -e "  Port    : ${CYAN}1-65535 (UDP)${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"
    echo ""
}

press_enter() {
    echo ""
    echo -e "${YELLOW}Tekan [ENTER] untuk kembali ke menu...${NC}"
    read -r
}

# === FUNGSI USER DB ===
# Format users.db: USERNAME|PASSWORD|TANGGAL_EXPIRED(YYYY-MM-DD)
# Contoh: budi|pass123|2025-06-30

load_users() {
    if [[ ! -f "$USERS_DB" ]]; then
        touch "$USERS_DB"
    fi
}

user_exists() {
    local username="$1"
    grep -q "^$username|" "$USERS_DB" 2>/dev/null
}

get_user_pass() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f2
}

get_user_expiry() {
    local username="$1"
    grep "^$username|" "$USERS_DB" | cut -d'|' -f3
}

update_config_json() {
    # Ambil semua password dari users.db yang belum expired
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r uname pass expiry; do
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

    echo -e "${BLUE}[1/7]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron dnsutils > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[2/7]${NC} Download binary ZIVPN UDP..."
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

    echo -e "${BLUE}[3/7]${NC} Generate sertifikat SSL..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=ZIVPN/CN=zivpn" \
        -keyout "$KEY_FILE" -out "$CERT_FILE" > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[4/7]${NC} Membuat config dan database user..."
    touch "$USERS_DB"
    update_config_json
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[5/7]${NC} Membuat systemd service..."
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

    echo -e "${BLUE}[6/7]${NC} Setup firewall & iptables..."
    sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
    sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1

    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(S+)' | head -1)
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null

    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[7/7]${NC} Setup auto backup dan cron..."
    # Setup auto backup setiap 6 jam
    setup_auto_backup
    
    # Setup cron untuk auto-hapus expired user (setiap hari jam 00:00)
    (crontab -l 2>/dev/null; echo "0 0 * * * bash /usr/local/bin/zivpn-cron.sh") | crontab -

    cat > /usr/local/bin/zivpn-cron.sh <<'CRONEOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
USERS_DB="/etc/zivpn/users.db"
CHANGED=0

if [[ ! -f "$USERS_DB" ]]; then exit 0; fi

TMPFILE=$(mktemp)
while IFS='|' read -r uname pass expiry; do
    if [[ "$expiry" != "unlimited" && "$expiry" < "$TODAY" ]]; then
        CHANGED=1
    else
        echo "$uname|$pass|$expiry" >> "$TMPFILE"
    fi
done < "$USERS_DB"

if [[ $CHANGED -eq 1 ]]; then
    mv "$TMPFILE" "$USERS_DB"
    # Rebuild config.json
    passwords=()
    while IFS='|' read -r uname pass expiry; do
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
    get_server_info
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Cara connect di ZIVPN App:${NC}"
    echo -e "  1. Buka ZIVPN → centang ${BOLD}UDP Tunnel${NC}"
    echo -e "  2. UDP Server  : ${CYAN}$(get_domain)${NC}"
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
    
    # Kirim notifikasi ke Telegram
    send_telegram "✅ ZIVPN UDP berhasil diinstall! Server: $(get_domain)"
    
    echo ""
    press_enter
}

# === TAMBAH USER ===

add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users

    read -rp "$(echo -e "${WHITE}Nama user   : ${NC}")" username
    if [[ -z "$username" ]]; then
        echo -e "${RED}[!] Nama user tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    if user_exists "$username"; then
        echo -e "${RED}[!] User '$username' sudah ada!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${WHITE}Password    : ${NC}")" password
    if [[ -z "$password" ]]; then
        echo -e "${RED}[!] Password tidak boleh kosong!${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Expired     :${NC}"
    echo -e "  ${CYAN}1${NC}. 7 hari"
    echo -e "  ${CYAN}2${NC}. 14 hari"
    echo -e "  ${CYAN}3${NC}. 30 hari"
    echo -e "  ${CYAN}4${NC}. 60 hari"
    echo -e "  ${CYAN}5${NC}. 90 hari"
    echo -e "  ${CYAN}6${NC}. Custom hari"
    echo -e "  ${CYAN}7${NC}. Unlimited"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-7] : ${NC}")" exp_choice

    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6)
            read -rp "$(echo -e "${WHITE}Jumlah hari : ${NC}")" days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
                press_enter
                return
            fi
            ;;
        7) days=0 ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            press_enter
            return
            ;;
    esac

    if [[ "$days" -eq 0 ]]; then
        expiry="unlimited"
    else
        expiry=$(date -d "+$days days" +%Y-%m-%d)
    fi

    echo "$username|$password|$expiry" >> "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User berhasil ditambahkan!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    
    if [[ "$expiry" == "unlimited" ]]; then
        exp_display="Unlimited"
    else
        exp_display=$(date -d "$expiry" +"%d %B %Y")
    fi
    
    generate_user_info "$username" "$password" "$exp_display"
    
    # Kirim info user ke Telegram
    local telegram_msg=$(cat <<EOF
✅ <b>USER BARU DITAMBAHKAN</b>
══════════════════════════════════════════
Username  : $username
Password  : $password
Expired   : $exp_display
══════════════════════════════════════════
EOF
)
    send_telegram "$telegram_msg"
    
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
    read -rp "$(echo -e "${WHITE}Nama user yang ingin dihapus : ${NC}")" username

    if ! user_exists "$username"; then
        echo -e "${RED}[!] User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    read -rp "$(echo -e "${RED}Yakin hapus user '$username'? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$username|/d" "$USERS_DB"
        update_config_json
        echo -e "${GREEN}  ✓ User '$username' berhasil dihapus!${NC}"
        send_telegram "🗑 User dihapus: $username"
    else
        echo -e "${YELLOW}  Dibatalkan.${NC}"
    fi

    press_enter
}

# === LIST USER ===

list_users_simple() {
    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
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
    printf "${WHITE}%-20s %-20s %-15s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}──────────────────────────────────────────────────────────${NC}"

    while IFS='|' read -r uname pass expiry; do
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
        printf "%-20s %-20s %-24s " "$uname" "$pass" "$(echo -e $exp_display)"
        echo -e "$status"
    done < "$USERS_DB"

    echo -e "${WHITE}──────────────────────────────────────────────────────────${NC}"
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
    read -rp "$(echo -e "${WHITE}Nama user   : ${NC}")" username

    if ! user_exists "$username"; then
        echo -e "${RED}[!] User '$username' tidak ditemukan!${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Perpanjang  :${NC}"
    echo -e "  ${CYAN}1${NC}. 7 hari"
    echo -e "  ${CYAN}2${NC}. 14 hari"
    echo -e "  ${CYAN}3${NC}. 30 hari"
    echo -e "  ${CYAN}4${NC}. 60 hari"
    echo -e "  ${CYAN}5${NC}. 90 hari"
    echo -e "  ${CYAN}6${NC}. Custom hari"
    echo -e "  ${CYAN}7${NC}. Unlimited"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-7] : ${NC}")" exp_choice

    case $exp_choice in
        1) days=7 ;;
        2) days=14 ;;
        3) days=30 ;;
        4) days=60 ;;
        5) days=90 ;;
        6)
            read -rp "$(echo -e "${WHITE}Jumlah hari : ${NC}")" days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}[!] Masukkan angka yang valid!${NC}"
                press_enter
                return
            fi
            ;;
        7) days=0 ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid!${NC}"
            press_enter
            return
            ;;
    esac

    local old_expiry=$(get_user_expiry "$username")
    local pass=$(get_user_pass "$username")

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

    sed -i "s/^$username|$pass|$old_expiry/$username|$pass|$new_expiry/" "$USERS_DB"
    update_config_json

    if [[ "$new_expiry" == "unlimited" ]]; then
        exp_display="Unlimited"
    else
        exp_display=$(date -d "$new_expiry" +"%d %B %Y")
    fi

    echo ""
    echo -e "${GREEN}  ✓ User '$username' berhasil diperpanjang!${NC}"
    echo -e "  Expired baru : ${CYAN}$exp_display${NC}"
    
    # Kirim notifikasi ke Telegram
    send_telegram "🔄 User diperpanjang: $username (Exp: $exp_display)"
    
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
    
    # Tampilkan info resource
    echo -e "${WHITE}RESOURCE USAGE:${NC}"
    echo "══════════════════════════════════════════"
    echo "CPU Usage  : $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo "RAM Usage  : $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "Disk Usage : $(df -h / | awk 'NR==2 {print $3"/"$2 " ("$5")"}')"
    echo "══════════════════════════════════════════"
    
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
        send_telegram "🔄 Service ZIVPN UDP direstart"
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

    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" != "unlimited" && "$expiry" < "$today" ]]; then
            echo -e "  ${RED}✗ Dihapus:${NC} $uname (expired: $expiry)"
            ((count++))
        else
            echo "$uname|$pass|$expiry" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}  ✓ $count user expired berhasil dihapus!${NC}"
        send_telegram "🧹 $count user expired telah dihapus"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}  Tidak ada user expired.${NC}"
    fi

    echo ""
    press_enter
}

# === INFO SERVER ===

info_server() {
    banner
    echo -e "${BOLD}${YELLOW}[ INFORMASI SERVER LENGKAP ]${NC}"
    echo ""
    get_server_info
    
    # Tampilkan info service
    echo ""
    echo -e "${WHITE}SERVICE STATUS:${NC}"
    echo "══════════════════════════════════════════"
    echo "ZIVPN Service : $(systemctl is-active zivpn.service)"
    echo "Uptime        : $(systemctl show zivpn.service -p ActiveEnterTimestamp | cut -d= -f2)"
    echo "══════════════════════════════════════════"
    
    # Tampilkan info user
    echo ""
    local total_user=$(wc -l < "$USERS_DB" 2>/dev/null || echo "0")
    local active_user=0
    local today=$(date +%Y-%m-%d)
    
    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]] || [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            ((active_user++))
        fi
    done < "$USERS_DB" 2>/dev/null
    
    echo "Total User    : $total_user"
    echo "User Aktif    : $active_user"
    echo "══════════════════════════════════════════"
    
    press_enter
}

# === MANUAL BACKUP ===

manual_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ MANUAL BACKUP ]${NC}"
    echo ""
    
    backup_system
    
    echo -e "${GREEN}  ✓ Backup manual berhasil dibuat dan dikirim ke Telegram!${NC}"
    echo -e "  Lokasi backup: $BACKUP_DIR"
    
    press_enter
}

# === LIST BACKUP ===

list_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR BACKUP ]${NC}"
    echo ""
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
        echo -e "${YELLOW}[!] Belum ada file backup.${NC}"
        press_enter
        return
    fi
    
    echo -e "${WHITE}File backup tersedia:${NC}"
    echo "══════════════════════════════════════════"
    
    local i=1
    for backup in $(ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sort -r); do
        if [[ -f "$backup" ]]; then
            local filename=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(echo "$filename" | sed 's/zivpn_backup_//; s/.tar.gz//' | sed 's/_/ /')
            echo -e "  ${CYAN}$i.${NC} $date - $size"
            ((i++))
        fi
    done
    
    echo "══════════════════════════════════════════"
    
    press_enter
}

# === UPDATE SCRIPT ===

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE ZIVPN MANAGER ]${NC}"
    echo ""

    # Ganti URL ini dengan URL raw script GitHub kamu nanti
    local SCRIPT_URL="https://raw.githubusercontent.com/ZaeniMiptah/Zivpn/main/zivpn-manager.sh"
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
    sed -i "/alias zivpn=/d" /root/.bashrc 2>/dev/null
    rm -rf "$ZIVPN_DIR"

    systemctl daemon-reload

    echo -e "  Hapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn-cron" | crontab -
    crontab -l 2>/dev/null | grep -v "zivpn.*--backup" | crontab -

    echo ""
    echo -e "${GREEN}  ✓ ZIVPN UDP berhasil diuninstall!${NC}"
    
    # Kirim notifikasi ke Telegram
    send_telegram "❌ ZIVPN UDP telah diuninstall dari server"
    
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
            echo -e "  ${CYAN}2${NC}. Info Server"
            echo -e "  ${BLUE}3${NC}. Update Script"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [1-3] : ${NC}")" choice
            case $choice in
                1) install_zivpn ;;
                2) info_server ;;
                3) update_script ;;
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
            echo -e "  ${GREEN}8${NC}. Info Server"
            echo -e "  ${YELLOW}9${NC}. Backup & Restore"
            echo ""
            echo -e "  ${BLUE}10${NC}. Update Script"
            echo -e "  ${RED}11${NC}. Uninstall ZIVPN"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "  ${WHITE}Pilih menu [1-11] : ${NC}")" choice

            case $choice in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) clean_expired ;;
                6) status_service ;;
                7) restart_service ;;
                8) info_server ;;
                9) backup_menu ;;
                10) update_script ;;
                11) uninstall_zivpn ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}";;
            esac
        fi
    done
}

# === BACKUP MENU ===

backup_menu() {
    while true; do
        banner
        echo -e "${BOLD}${YELLOW}[ MENU BACKUP & RESTORE ]${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. Backup Manual (Kirim ke Telegram)"
        echo -e "  ${CYAN}2${NC}. Daftar Backup"
        echo -e "  ${YELLOW}3${NC}. Restore Backup"
        echo -e "  ${BLUE}4${NC}. Kembali ke Menu Utama"
        echo ""
        echo -e "${WHITE}  ────────────────────────────────────────${NC}"
        read -rp "$(echo -e "  ${WHITE}Pilih menu [1-4] : ${NC}")" choice

        case $choice in
            1) manual_backup ;;
            2) list_backup ;;
            3) restore_backup ;;
            4) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}" ;;
        esac
    done
}

# === ENTRY POINT ===

# Handle command line arguments
if [[ "$1" == "--backup" ]]; then
    # Jalankan backup otomatis
    backup_system
    exit 0
fi

main_menu
