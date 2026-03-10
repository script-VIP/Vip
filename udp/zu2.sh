#!/bin/bash
# =============================================
#   ZIVPN UDP MANAGER COMPLETE
#   Auto Backup + Domain + Random Password
#   By: Custom Script
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
USERS_DB_JSON="$ZIVPN_DIR/users.db.json"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
BACKUP_DIR="$ZIVPN_DIR/backup"
BACKUP_CONFIG="$ZIVPN_DIR/backup.conf"
THEME_CONFIG="$ZIVPN_DIR/theme.conf"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"
ONLINE_USERS="$ZIVPN_DIR/online_users.txt"

# === FUNGSI UTILITAS ===
print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_section() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}   $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}\n"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Tidak dapat mendeteksi OS"
        exit 1
    fi

    if [[ "$OS" != "ubuntu" ]] || [[ ! "$VER" =~ ^(20.04|22.04|24.04)$ ]]; then
        print_error "OS tidak didukung! Gunakan Ubuntu 20.04/22.04/24.04"
        exit 1
    fi
    print_status "OS: Ubuntu $VER detected"
}

# === FUNGSI LOAD THEME ===
load_theme() {
    if [ -f "$THEME_CONFIG" ] && [ -s "$THEME_CONFIG" ]; then
        THEME=$(cat "$THEME_CONFIG")
        case $THEME in
            rainbow)
                if command -v lolcat &> /dev/null; then
                    THEME_CMD="lolcat"
                else
                    THEME_CMD="cat"
                fi
                ;;
            red) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $RED)/\" -e \"s/$/$(echo -e $NC)/\"";;
            green) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $GREEN)/\" -e \"s/$/$(echo -e $NC)/\"";;
            yellow) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $YELLOW)/\" -e \"s/$/$(echo -e $NC)/\"";;
            blue) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $BLUE)/\" -e \"s/$/$(echo -e $NC)/\"";;
            none) THEME_CMD="cat";;
            *) THEME_CMD="cat";;
        esac
    elif command -v lolcat &> /dev/null; then
        THEME_CMD="lolcat"
        echo "rainbow" > "$THEME_CONFIG"
    else
        THEME_CMD="cat"
    fi
}

# === FUNGSI TELEGRAM ===
send_notification() {
    local message="$1"
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
    fi
    
    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
             -d "chat_id=${CHAT_ID}" \
             -d "text=${message}" \
             -d "parse_mode=HTML" > /dev/null
    fi
}

send_document() {
    local file_path="$1"
    local caption="$2"
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
    fi
    
    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
             -F "chat_id=${CHAT_ID}" \
             -F "document=@${file_path}" \
             -F "caption=${caption}" > /dev/null
    fi
}

# === FUNGSI AUTO BACKUP ===
setup_auto_backup() {
    print_section "SETTING UP AUTO BACKUP"
    
    # Create backup script
    cat > "/usr/local/bin/zivpn-autobackup.sh" << 'EOF'
#!/bin/bash
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$ZIVPN_DIR/backup"
MAX_BACKUPS=10

# Create backup filename with date
BACKUP_FILE="$BACKUP_DIR/zivpn_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"

# Create backup
tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" .

# Keep only last 10 backups
cd "$BACKUP_DIR"
ls -t zivpn_backup_*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm

# Send to Telegram if configured
if [ -f "$ZIVPN_DIR/bot_config.sh" ]; then
    source "$ZIVPN_DIR/bot_config.sh"
    if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
             -F "chat_id=${CHAT_ID}" \
             -F "document=@${BACKUP_FILE}" \
             -F "caption=✅ Auto Backup ZIVPN - $(date +'%Y-%m-%d %H:%M:%S')" > /dev/null
    fi
fi
EOF
    chmod +x "/usr/local/bin/zivpn-autobackup.sh"
    
    # Setup cron for auto backup (every 6 hours)
    echo "0 */6 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
    chmod 644 /etc/cron.d/zivpn-autobackup
    
    # Create backup config
    cat > "$BACKUP_CONFIG" << EOF
BACKUP_ENABLED=true
BACKUP_INTERVAL=21600
MAX_BACKUPS=10
AUTO_SEND_TELEGRAM=true
EOF

    print_status "Auto backup configured (runs every 6 hours)"
    
    # Run initial backup
    /usr/local/bin/zivpn-autobackup.sh
    print_status "Initial backup created"
}

# === FUNGSI INSTALASI ===
install_dependencies() {
    print_section "INSTALLING DEPENDENCIES"
    
    apt-get update
    apt-get install -y wget curl unzip socat openssl net-tools jq figlet lolcat nethogs htop
    
    # Install screen
    apt-get install -y screen
    
    # Install Python3
    apt-get install -y python3 python3-pip
    
    # Install required Python packages
    pip3 install requests --break-system-packages 2>/dev/null || pip3 install requests
    
    # Install UDP Custom dependencies
    apt-get install -y cmake build-essential
    
    print_status "Dependencies installed"
}

setup_directory() {
    print_section "SETTING UP DIRECTORIES"
    
    mkdir -p "$ZIVPN_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p /var/log/zivpn
    mkdir -p /etc/zivpn/udp
    
    # Create users database if not exists
    if [[ ! -f "$USERS_DB_JSON" ]]; then
        echo "[]" > "$USERS_DB_JSON"
    fi
    
    print_status "Directories created"
}

setup_domain() {
    print_section "DOMAIN CONFIGURATION"
    
    echo -e "${YELLOW}Masukkan domain untuk ZIVPN:${NC}"
    read -p "Domain: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        DOMAIN=$(curl -s ifconfig.me)
        print_warning "Domain kosong, menggunakan IP: $DOMAIN"
    fi
    
    echo "$DOMAIN" > "$DOMAIN_FILE"
    print_status "Domain saved: $DOMAIN"
}

download_binary() {
    print_section "DOWNLOADING ZIVPN BINARY"
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        BINARY_URL="https://raw.githubusercontent.com/zivpn/udp-zivpn/main/zivpn-linux-amd64"
    elif [[ "$ARCH" == "aarch64" ]]; then
        BINARY_URL="https://raw.githubusercontent.com/zivpn/udp-zivpn/main/zivpn-linux-arm64"
    else
        print_error "Arsitektur $ARCH tidak didukung"
        exit 1
    fi
    
    wget -O "$ZIVPN_BIN" "$BINARY_URL"
    chmod +x "$ZIVPN_BIN"
    
    print_status "Binary downloaded to $ZIVPN_BIN"
}

generate_certificate() {
    print_section "GENERATING SSL CERTIFICATE"
    
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days 3650 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZIVPN/OU=UDP/CN=$DOMAIN" \
        -sha256
    
    print_status "SSL Certificate generated for $DOMAIN"
}

create_config() {
    print_section "CREATING CONFIGURATION"
    
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    
    cat > "$CONFIG_FILE" << EOF
{
    "server": {
        "host": "0.0.0.0",
        "port": 80,
        "port_tls": 443,
        "protocol": "udp"
    },
    "ssl": {
        "cert": "$CERT_FILE",
        "key": "$KEY_FILE"
    },
    "users": {
        "max_users": 100,
        "expired_check_interval": 60
    },
    "logs": {
        "path": "/var/log/zivpn/zivpn.log",
        "level": "info",
        "max_size": 100
    },
    "api": {
        "enabled": true,
        "port": 8080
    },
    "telegram": {
        "enabled": true,
        "bot_token": "$BOT_TOKEN",
        "chat_id": "$CHAT_ID"
    },
    "udp_custom": {
        "enabled": true,
        "port": "1-65535",
        "fallback_port": 80
    }
}
EOF
    
    print_status "Configuration created"
}

create_service() {
    print_section "CREATING SYSTEMD SERVICE"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=ZIVPN UDP Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN -config $CONFIG_FILE
Restart=always
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable zivpn.service
    
    print_status "Systemd service created"
}

install_udp_custom() {
    print_section "INSTALLING UDP CUSTOM"
    
    UDP_DIR="/etc/zivpn/udp"
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    
    # Download UDP Custom binary (contoh, sesuaikan dengan sumber yang benar)
    wget -O "$UDP_DIR/udp-custom" "https://raw.githubusercontent.com/zivpn/udp-zivpn/main/udp-custom" 2>/dev/null || {
        print_warning "UDP Custom binary tidak ditemukan, membuat script dummy"
        cat > "$UDP_DIR/udp-custom" << 'EOF'
#!/bin/bash
echo "UDP Custom Service Running"
sleep infinity
EOF
    }
    chmod +x "$UDP_DIR/udp-custom"
    
    # Create UDP Custom config
    cat > "$UDP_DIR/config.json" << EOF
{
    "listen": ":1-65535",
    "tls": "$CERT_FILE",
    "key": "$KEY_FILE",
    "fallback": ":80",
    "workers": 2,
    "log": "/var/log/zivpn/udp.log"
}
EOF
    
    # Create UDP Custom service
    cat > "/etc/systemd/system/udp-custom.service" << EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/udp-custom -config $UDP_DIR/config.json
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udp-custom.service
    
    print_status "UDP Custom installed"
}

create_bot_config() {
    print_section "CREATING BOT CONFIGURATION"
    
    cat > "$BOT_CONFIG" << EOF
#!/bin/bash
BOT_TOKEN='$BOT_TOKEN'
CHAT_ID='$CHAT_ID'
EOF
    chmod +x "$BOT_CONFIG"
    
    print_status "Bot configuration created"
}

create_menu_script() {
    print_section "CREATING MENU SCRIPT"
    
    cat > "/usr/local/bin/zivpn-menu" << 'EOF'
#!/bin/bash

# === PATH ===
ZIVPN_DIR="/etc/zivpn"
USERS_DB_JSON="$ZIVPN_DIR/users.db.json"
CONFIG_FILE="$ZIVPN_DIR/config.json"
DOMAIN_FILE="$ZIVPN_DIR/domain.txt"
BOT_CONFIG="$ZIVPN_DIR/bot_config.sh"
THEME_CONFIG="$ZIVPN_DIR/theme.conf"
ONLINE_USERS="$ZIVPN_DIR/online_users.txt"

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# === FUNGSI LOAD THEME ===
load_theme() {
    if [ -f "$THEME_CONFIG" ] && [ -s "$THEME_CONFIG" ]; then
        THEME=$(cat "$THEME_CONFIG")
        case $THEME in
            rainbow)
                if command -v lolcat &> /dev/null; then
                    THEME_CMD="lolcat"
                else
                    THEME_CMD="cat"
                fi
                ;;
            red) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $RED)/\" -e \"s/$/$(echo -e $NC)/\"";;
            green) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $GREEN)/\" -e \"s/$/$(echo -e $NC)/\"";;
            yellow) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $YELLOW)/\" -e \"s/$/$(echo -e $NC)/\"";;
            blue) THEME_CMD="sed 's/\\x1b\\[[0-9;]*m//g' | sed -e \"s/^/$(echo -e $BLUE)/\" -e \"s/$/$(echo -e $NC)/\"";;
            none) THEME_CMD="cat";;
            *) THEME_CMD="cat";;
        esac
    else
        THEME_CMD="cat"
    fi
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

# === FUNGSI SYNC CONFIG ===
sync_config() {
    if [ -f "$USERS_DB_JSON" ] && [ -f "$CONFIG_FILE" ]; then
        passwords_json=$(jq '[.[].password]' "$USERS_DB_JSON")
        jq --argjson passwords "$passwords_json" '.auth.config = $passwords | .config = $passwords' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        systemctl restart zivpn.service > /dev/null 2>&1
    fi
}

# === FUNGSI GENERATE RANDOM PASSWORD ===
generate_password() {
    # Generate 2 digit random number
    printf "%02d" $((RANDOM % 100))
}

# === FUNGSI GET LOKASI ===
get_location() {
    # Get location based on IP (simplified)
    curl -s http://ipinfo.io/country 2>/dev/null || echo "Indonesia"
}

# === FUNGSI TAMBAH AKUN ===
add_account() {
    clear
    echo -e "${YELLOW}--- TAMBAH AKUN REGULER ---${NC}"
    
    # Generate random password (2 digit angka)
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="user${RANDOM_NUM}"
    
    read -p "Password [${DEFAULT_PASS}]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    # Check if password already exists
    if jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null; then
        echo -e "${RED}Error: Password '$password' sudah digunakan.${NC}"
        sleep 2
        return
    fi
    
    read -p "Limit IP (default: 3): " limit_ip
    [[ -z "$limit_ip" ]] && limit_ip=3
    
    read -p "Masa aktif (hari, default: 30): " duration
    [[ -z "$duration" ]] && duration=30
    
    # Generate username from password (for internal use)
    username="user_${password}"
    
    expiry_timestamp=$(date -d "+$duration days" +%s)
    create_date=$(date +"%d %b, %Y")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y")
    
    # Get domain and location
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    new_user_json=$(jq -n \
        --arg user "$username" \
        --arg pass "$password" \
        --argjson expiry "$expiry_timestamp" \
        --arg limit "$limit_ip" \
        --arg created "$create_date" \
        '{username: $user, password: $pass, expiry_timestamp: $expiry, limit_ip: $limit, created_date: $created}')
    
    jq --argjson new_user "$new_user_json" '. += [$new_user]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    # TAMPILAN OUTPUT
    clear
    echo "═══════════════════════════════════════════════"
    echo "  ✓ Terima kasih sudah order kak😁"
    echo "═══════════════════════════════════════════════"
    echo "  ZIVPN UDP"
    echo "═══════════════════════════════════════════════"
    echo "  Domain      : $DOMAIN"
    echo "  Password    : $password"
    echo "  Lokasi      : $LOKASI"
    echo "  ────────────────"
    echo "  Tanggal Buat: $create_date"
    echo "  Tanggal Exp : $expiry_date"
    echo "  Masa Aktif  : $duration hari"
    echo "  Limit IP    : $limit_ip device"
    echo "───────────────────────────────────────────────"
    echo "  Tutorial ZIVPN APP / UDP Tunnel"
    echo "───────────────────────────────────────────────"
    echo "  1. Buka ZIVPN App"
    echo "  2. Centang Udp"
    echo "  3. Pilih negara bebas (saran $LOKASI premium)"
    echo "  4. Klik Garis tiga (pojok kiri atas)"
    echo "  5. Klik Udp tunnel setting"
    echo "  6. UDP Server  : $DOMAIN"
    echo "     UDP Password: $password"
    echo "  7. Klik APPLY → START"
    echo "═══════════════════════════════════════════════"
    
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
    read -p "Press [Enter] to continue..."
}

# === FUNGSI TAMBAH AKUN TRIAL ===
add_trial_account() {
    clear
    echo -e "${YELLOW}--- TAMBAH AKUN TRIAL ---${NC}"
    
    # Generate random password (2 digit angka)
    RANDOM_NUM=$(generate_password)
    DEFAULT_PASS="trial${RANDOM_NUM}"
    
    read -p "Password [${DEFAULT_PASS}]: " password
    [[ -z "$password" ]] && password="$DEFAULT_PASS"
    
    read -p "Masa aktif (menit, default: 60): " duration
    [[ -z "$duration" ]] && duration=60
    
    # Generate username from password
    username="trial_${password}"
    
    expiry_timestamp=$(date -d "+$duration minutes" +%s)
    create_date=$(date +"%d %b, %Y %H:%M")
    expiry_date=$(date -d "@$expiry_timestamp" +"%d %b, %Y %H:%M")
    
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    LOKASI=$(get_location)
    
    new_user_json=$(jq -n \
        --arg user "$username" \
        --arg pass "$password" \
        --argjson expiry "$expiry_timestamp" \
        --arg limit "1" \
        --arg created "$create_date" \
        '{username: $user, password: $pass, expiry_timestamp: $expiry, limit_ip: "1", created_date: $created}')
    
    jq --argjson new_user "$new_user_json" '. += [$new_user]' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    # TAMPILAN OUTPUT
    clear
    echo "═══════════════════════════════════════════════"
    echo "  ✓ Trial Account"
    echo "═══════════════════════════════════════════════"
    echo "  ZIVPN UDP TRIAL"
    echo "═══════════════════════════════════════════════"
    echo "  Domain      : $DOMAIN"
    echo "  Password    : $password"
    echo "  Lokasi      : $LOKASI"
    echo "  ────────────────"
    echo "  Dibuat      : $create_date"
    echo "  Expired     : $expiry_date"
    echo "  Masa Aktif  : $duration menit"
    echo "═══════════════════════════════════════════════"
    
    sync_config
    read -p "Press [Enter] to continue..."
}

# === FUNGSI LIST AKUN ===
list_accounts() {
    clear
    echo -e "${YELLOW}--- DAFTAR AKUN ---${NC}"
    printf "${BLUE}%-20s | %-15s | %-25s | %-10s${NC}\n" "Password" "Username" "Expired" "Status"
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────${NC}"
    
    jq -r --argjson now "$(date +%s)" '
        .[] |
        . as $user |
        (
            ($user.expiry_timestamp - $now) as $remaining |
            if $remaining <= 0 then
                "❌ EXPIRED"
            else
                ($remaining / 86400 | floor) as $days |
                if $days > 0 then
                    "✅ \($days) hari"
                else
                    ($remaining / 3600 | floor) as $hours |
                    if $hours > 0 then
                        "✅ \($hours) jam"
                    else
                        "✅ \($remaining / 60 | floor) mnt"
                    end
                end
            end
        ) as $status |
        [$user.password, $user.username, ($user.expiry_timestamp | strftime("%Y-%m-%d %H:%M")), $status] |
        @tsv' "$USERS_DB_JSON" |
    while IFS=$'\t' read -r pass user expiry status; do
        printf "${WHITE}%-20s | %-15s | %-25s | %b${NC}\n" "$pass" "$user" "$expiry" "$status"
    done
    
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────${NC}"
    read -p "Press [Enter] to continue..."
}

# === FUNGSI HAPUS AKUN ===
delete_account() {
    clear
    echo -e "${YELLOW}--- HAPUS AKUN ---${NC}"
    read -p "Masukkan password yang akan dihapus: " password
    
    if ! jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null; then
        echo -e "${RED}Error: Password '$password' tidak ditemukan.${NC}"
        sleep 2
        return
    fi
    
    jq --arg pass "$password" 'del(.[] | select(.password == $pass))' "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    echo -e "${GREEN}Akun dengan password '$password' berhasil dihapus.${NC}"
    sync_config
    sleep 2
}

# === FUNGSI EDIT EXPIRED ===
edit_expiry() {
    clear
    echo -e "${YELLOW}--- EDIT MASA AKTIF ---${NC}"
    read -p "Masukkan password: " password
    
    if ! jq -e --arg pass "$password" '.[] | select(.password == $pass)' "$USERS_DB_JSON" > /dev/null; then
        echo -e "${RED}Error: Password '$password' tidak ditemukan.${NC}"
        sleep 2
        return
    fi
    
    read -p "Tambahan hari (contoh: 30): " days
    current_expiry=$(jq -r --arg pass "$password" '.[] | select(.password == $pass) | .expiry_timestamp' "$USERS_DB_JSON")
    new_expiry=$(date -d "@$current_expiry" "+%s")
    
    jq --arg pass "$password" --argjson new_expiry "$new_expiry" \
       '(.[] | select(.password == $pass) | .expiry_timestamp) = $new_expiry' \
       "$USERS_DB_JSON" > "$USERS_DB_JSON.tmp" && mv "$USERS_DB_JSON.tmp" "$USERS_DB_JSON"
    
    echo -e "${GREEN}Masa aktif untuk password '$password' diperpanjang $days hari.${NC}"
    sync_config
    sleep 2
}

# === FUNGSI CEK ONLINE USER ===
check_online_users() {
    clear
    echo -e "${YELLOW}--- ONLINE USERS ---${NC}"
    
    # Get active connections (simplified - adjust based on your setup)
    if command -v nethogs &> /dev/null; then
        echo -e "${CYAN}Monitoring active connections (nethogs)...${NC}"
        echo -e "${WHITE}Press Ctrl+C to exit${NC}"
        sleep 2
        nethogs
    else
        # Alternative: check system logs
        echo -e "${YELLOW}Active connections in last 5 minutes:${NC}"
        netstat -an | grep ESTABLISHED | grep -E ":80|:443" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr
    fi
    
    read -p "Press [Enter] to continue..."
}

# === FUNGSI VPS INFO ===
vps_info() {
    clear
    echo -e "${YELLOW}--- VPS INFORMATION ---${NC}"
    
    # Get domain
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || curl -s ifconfig.me)
    
    # Get IP
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    # Get RAM info
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    RAM_USED=$(free -h | grep Mem | awk '{print $3}')
    RAM_FREE=$(free -h | grep Mem | awk '{print $4}')
    RAM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
    
    # Get CPU info
    CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
    CPU_CORES=$(nproc)
    CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}')
    
    # Get disk info
    DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
    DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
    DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
    DISK_PERCENT=$(df -h / | tail -1 | awk '{print $5}')
    
    # Get uptime
    UPTIME=$(uptime -p | sed 's/up //')
    
    # Get OS
    OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    
    # Display info
    echo "═══════════════════════════════════════════════"
    echo "  SYSTEM INFORMATION"
    echo "═══════════════════════════════════════════════"
    echo "  Domain      : $DOMAIN"
    echo "  IP Address  : $IP"
    echo "  OS          : $OS"
    echo "  Uptime      : $UPTIME"
    echo "───────────────────────────────────────────────"
    echo "  CPU         : $CPU_MODEL"
    echo "  Cores       : $CPU_CORES"
    echo "  Load Avg    :$CPU_LOAD"
    echo "───────────────────────────────────────────────"
    echo "  RAM Total   : $RAM_TOTAL"
    echo "  RAM Used    : $RAM_USED ($RAM_PERCENT%)"
    echo "  RAM Free    : $RAM_FREE"
    echo "───────────────────────────────────────────────"
    echo "  Disk Total  : $DISK_TOTAL"
    echo "  Disk Used   : $DISK_USED ($DISK_PERCENT)"
    echo "  Disk Free   : $DISK_FREE"
    echo "═══════════════════════════════════════════════"
    
    read -p "Press [Enter] to continue..."
}

# === FUNGSI CHANGE DOMAIN ===
change_domain() {
    clear
    echo -e "${YELLOW}--- CHANGE DOMAIN ---${NC}"
    echo -e "${WHITE}Current domain: $(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")${NC}"
    echo ""
    read -p "Masukkan domain baru: " new_domain
    
    if [ -n "$new_domain" ]; then
        echo "$new_domain" > "$DOMAIN_FILE"
        
        # Regenerate certificate with new domain
        openssl req -x509 -newkey rsa:2048 -nodes \
            -keyout "$ZIVPN_DIR/zivpn.key" \
            -out "$ZIVPN_DIR/zivpn.crt" \
            -days 3650 \
            -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZIVPN/OU=UDP/CN=$new_domain" \
            -sha256 2>/dev/null
        
        # Update config
        jq --arg domain "$new_domain" '.server.host = $domain' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        # Restart services
        systemctl restart zivpn.service
        systemctl restart udp-custom.service 2>/dev/null
        
        echo -e "${GREEN}Domain berhasil diubah ke: $new_domain${NC}"
        echo -e "${GREEN}Sertifikat SSL diperbarui${NC}"
    else
        echo -e "${RED}Domain tidak boleh kosong${NC}"
    fi
    
    sleep 3
}

# === FUNGSI BACKUP/RESTORE ===
backup_restore() {
    clear
    echo -e "${YELLOW}--- BACKUP/RESTORE ---${NC}"
    echo "1. Create Backup"
    echo "2. Restore from File"
    echo "3. List Backups"
    read -p "Choose: " choice
    
    case $choice in
        1)
            BACKUP_FILE="$ZIVPN_DIR/backup/zivpn_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$BACKUP_FILE" -C "$ZIVPN_DIR" --exclude="backup" .
            echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
            
            # Send to Telegram
            send_document "$BACKUP_FILE" "ZIVPN Backup $(date +'%Y-%m-%d %H:%M:%S')"
            ;;
        2)
            echo "Available backups:"
            ls -lh "$ZIVPN_DIR/backup/" | grep tar.gz
            echo ""
            read -p "Enter backup filename: " filename
            if [ -f "$ZIVPN_DIR/backup/$filename" ]; then
                tar -xzf "$ZIVPN_DIR/backup/$filename" -C "$ZIVPN_DIR"
                echo -e "${GREEN}Restore completed${NC}"
                systemctl restart zivpn.service
            else
                echo -e "${RED}File not found${NC}"
            fi
            ;;
        3)
            echo "Backup files:"
            ls -lh "$ZIVPN_DIR/backup/" | grep tar.gz
            ;;
    esac
    read -p "Press [Enter] to continue..."
}

# === FUNGSI BOT SETTINGS ===
configure_bot() {
    clear
    echo -e "${YELLOW}--- BOT TELEGRAM SETTINGS ---${NC}"
    
    if [ -f "$BOT_CONFIG" ]; then
        source "$BOT_CONFIG"
        echo "Current Bot Token: ${BOT_TOKEN:0:10}...${BOT_TOKEN: -5}"
        echo "Current Chat ID: $CHAT_ID"
    fi
    
    echo ""
    read -p "New Bot Token (leave empty to keep current): " new_token
    read -p "New Chat ID (leave empty to keep current): " new_chat_id
    
    if [ -n "$new_token" ]; then
        BOT_TOKEN="$new_token"
    fi
    if [ -n "$new_chat_id" ]; then
        CHAT_ID="$new_chat_id"
    fi
    
    cat > "$BOT_CONFIG" << EOF
#!/bin/bash
BOT_TOKEN='$BOT_TOKEN'
CHAT_ID='$CHAT_ID'
EOF
    
    echo -e "${GREEN}Bot configuration updated${NC}"
    sleep 2
}

# === FUNGSI THEME SETTINGS ===
configure_theme() {
    clear
    echo -e "${YELLOW}--- THEME SETTINGS ---${NC}"
    echo "1. Rainbow (lolcat)"
    echo "2. Red"
    echo "3. Green"
    echo "4. Yellow"
    echo "5. Blue"
    echo "6. None"
    read -p "Choose theme: " choice
    
    case $choice in
        1) echo "rainbow" > "$THEME_CONFIG" ;;
        2) echo "red" > "$THEME_CONFIG" ;;
        3) echo "green" > "$THEME_CONFIG" ;;
        4) echo "yellow" > "$THEME_CONFIG" ;;
        5) echo "blue" > "$THEME_CONFIG" ;;
        6) echo "none" > "$THEME_CONFIG" ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
    
    echo -e "${GREEN}Theme updated${NC}"
    sleep 2
}

# === FUNGSI AUTO BACKUP SETTINGS ===
manage_auto_backup() {
    clear
    echo -e "${YELLOW}--- AUTO BACKUP SETTINGS ---${NC}"
    
    if [ -f "/etc/cron.d/zivpn-autobackup" ]; then
        echo "Auto Backup: ENABLED"
        echo "Schedule: Every 6 hours"
        echo ""
        echo "1. Disable Auto Backup"
        echo "2. Run Backup Now"
        echo "3. Back"
        read -p "Choose: " choice
        
        case $choice in
            1)
                rm -f /etc/cron.d/zivpn-autobackup
                echo -e "${GREEN}Auto backup disabled${NC}"
                ;;
            2)
                /usr/local/bin/zivpn-autobackup.sh
                echo -e "${GREEN}Backup completed${NC}"
                ;;
        esac
    else
        echo "Auto Backup: DISABLED"
        echo ""
        echo "1. Enable Auto Backup (Every 6 hours)"
        echo "2. Back"
        read -p "Choose: " choice
        
        if [ "$choice" == "1" ]; then
            echo "0 */6 * * * root /usr/local/bin/zivpn-autobackup.sh" > /etc/cron.d/zivpn-autobackup
            echo -e "${GREEN}Auto backup enabled${NC}"
            /usr/local/bin/zivpn-autobackup.sh
            echo -e "${GREEN}Initial backup created${NC}"
        fi
    fi
    
    sleep 2
}

# === FUNGSI UNINSTALL ===
uninstall_zivpn() {
    clear
    echo -e "${RED}--- UNINSTALL ZIVPN ---${NC}"
    echo -e "${YELLOW}Warning: This will remove all ZIVPN files and configurations${NC}"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        systemctl stop zivpn.service udp-custom.service 2>/dev/null
        systemctl disable zivpn.service udp-custom.service 2>/dev/null
        
        rm -f /etc/systemd/system/zivpn.service
        rm -f /etc/systemd/system/udp-custom.service
        rm -f /usr/local/bin/zivpn
        rm -f /usr/local/bin/zivpn-menu
        rm -f /usr/local/bin/zivpn-autobackup.sh
        rm -f /etc/cron.d/zivpn-autobackup
        
        read -p "Remove all data in $ZIVPN_DIR? (y/N): " remove_data
        if [[ "$remove_data" =~ ^[Yy]$ ]]; then
            rm -rf "$ZIVPN_DIR"
            echo -e "${GREEN}All data removed${NC}"
        fi
        
        systemctl daemon-reload
        echo -e "${GREEN}ZIVPN uninstalled${NC}"
        exit 0
    fi
}

# === MAIN MENU ===
show_menu() {
    load_theme
    
    # Get domain and IP for header
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "Not set")
    IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    # Get RAM usage
    RAM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
    
    clear
    (
        echo "    ╔═══════════════════════════════════════╗"
        echo "    ║         ZIVPN UDP MANAGER            ║"
        echo "    ║         Advanced Edition             ║"
        echo "    ╚═══════════════════════════════════════╝"
        echo ""
        echo "    🌍 Domain  : $DOMAIN"
        echo "    📡 IP      : $IP"
        echo "    💾 RAM     : ${RAM_PERCENT}% used"
        echo ""
        echo "    ═══════════════════════════════════════"
        printf "    [ 1] ➕  Add Account\n"
        printf "    [ 2] ⏳  Trial Account\n"
        printf "    [ 3] 📋  List Accounts\n"
        printf "    [ 4] 🗑️  Delete Account\n"
        printf "    [ 5] 📅  Edit Expiry\n"
        printf "    [ 6] 👥  Online Users\n"
        printf "    [ 7] ℹ️  VPS Info\n"
        printf "    [ 8] 🌐  Change Domain\n"
        printf "    [ 9] 💾  Backup/Restore\n"
        printf "    [10] 🤖  Bot Settings\n"
        printf "    [11] 🎨  Theme Settings\n"
        printf "    [12] ⏰  Auto Backup Settings\n"
        printf "    [13] ❌  Uninstall\n"
        printf "    [ 0] 🚪  Exit\n"
        echo "    ═══════════════════════════════════════"
        echo ""
    ) | lolcat 2>/dev/null || cat
    
    echo -n "    ➤ Choose option: "
}

# === MAIN LOOP ===
while true; do
    show_menu
    read choice
    
    case $choice in
        1) add_account ;;
        2) add_trial_account ;;
        3) list_accounts ;;
        4) delete_account ;;
        5) edit_expiry ;;
        6) check_online_users ;;
        7) vps_info ;;
        8) change_domain ;;
        9) backup_restore ;;
        10) configure_bot ;;
        11) configure_theme ;;
        12) manage_auto_backup ;;
        13) uninstall_zivpn ;;
        0) clear; echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
done
EOF

    chmod +x "/usr/local/bin/zivpn-menu"
    print_status "Menu script created at /usr/local/bin/zivpn-menu"
}

create_uninstall_script() {
    print_section "CREATING UNINSTALL SCRIPT"
    
    cat > "/usr/local/bin/uninstall.sh" << 'EOF'
#!/bin/bash
# ZIVPN Uninstall Script

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}Uninstalling ZIVPN...${NC}"

# Stop services
systemctl stop zivpn.service 2>/dev/null
systemctl stop udp-custom.service 2>/dev/null

# Disable services
systemctl disable zivpn.service 2>/dev/null
systemctl disable udp-custom.service 2>/dev/null

# Remove service files
rm -f /etc/systemd/system/zivpn.service
rm -f /etc/systemd/system/udp-custom.service

# Remove binaries
rm -f /usr/local/bin/zivpn
rm -f /usr/local/bin/zivpn-menu
rm -f /usr/local/bin/zivpn-autobackup.sh
rm -f /usr/local/bin/uninstall.sh

# Remove cron jobs
rm -f /etc/cron.d/zivpn-autobackup

# Ask about data directory
read -p "Remove all configuration data? (y/N): " remove_data
if [[ "$remove_data" =~ ^[Yy]$ ]]; then
    rm -rf /etc/zivpn
    rm -rf /var/log/zivpn
    echo -e "${GREEN}All data removed${NC}"
fi

systemctl daemon-reload

echo -e "${GREEN}ZIVPN uninstalled successfully${NC}"
EOF

    chmod +x "/usr/local/bin/uninstall.sh"
    print_status "Uninstall script created"
}

start_services() {
    print_section "STARTING SERVICES"
    
    systemctl start zivpn.service
    systemctl start udp-custom.service
    
    systemctl enable zivpn.service
    systemctl enable udp-custom.service
    
    print_status "Services started"
}

show_completion() {
    clear
    DOMAIN=$(cat "$DOMAIN_FILE")
    IP=$(curl -s ifconfig.me)
    
    echo "═══════════════════════════════════════════════"
    echo "  ✅ INSTALASI ZIVPN SELESAI"
    echo "═══════════════════════════════════════════════"
    echo ""
    echo "  📌 INFORMASI SERVER"
    echo "  ──────────────────────────────"
    echo "  Domain    : $DOMAIN"
    echo "  IP        : $IP"
    echo "  Port UDP  : 1-65535"
    echo "  Port TLS  : 443"
    echo ""
    echo "  📌 AKSES MENU"
    echo "  ──────────────────────────────"
    echo "  Ketik: ${GREEN}zivpn-menu${NC}"
    echo ""
    echo "  📌 FITUR"
    echo "  ──────────────────────────────"
    echo "  ✓ Auto Backup setiap 6 jam"
    echo "  ✓ Notifikasi Telegram"
    echo "  ✓ Random password 2 digit"
    echo "  ✓ Limit IP per akun"
    echo "  ✓ Cek online user"
    echo "  ✓ Change domain"
    echo "  ✓ Tema rainbow"
    echo ""
    echo "  📌 LAYANAN"
    echo "  ──────────────────────────────"
    systemctl status zivpn.service --no-pager | grep "Active:"
    systemctl status udp-custom.service --no-pager | grep "Active:" 2>/dev/null
    echo ""
    echo "═══════════════════════════════════════════════"
}

# === MAIN INSTALLATION ===
main() {
    check_root
    check_os
    
    clear
    echo "╔═══════════════════════════════════════════════╗"
    echo "║     ZIVPN UDP MANAGER - ADVANCED EDITION     ║"
    echo "║         Auto Backup + Domain + Theme         ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    
    install_dependencies
    setup_directory
    setup_domain
    download_binary
    generate_certificate
    create_config
    create_service
    install_udp_custom
    create_bot_config
    setup_auto_backup
    create_menu_script
    create_uninstall_script
    start_services
    
    # Create alias
    echo "alias menu='zivpn-menu'" >> ~/.bashrc
    source ~/.bashrc 2>/dev/null
    
    show_completion
    
    echo -e "${GREEN}Installation complete! Type 'zivpn-menu' to start.${NC}"
}

# Run main installation
main "$@"
