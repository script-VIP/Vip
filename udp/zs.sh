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
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        if [[ "$status" == "active" ]]; then
            echo -e "  Status  : ${GREEN}● AKTIF${NC}"
        else
            echo -e "  Status  : ${RED}● MATI${NC}"
        fi
        echo -e "  IP VPS  : ${CYAN}$ip${NC}"
        echo -e "  Port    : ${CYAN}1-65535 (UDP)${NC}"
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

    echo -e "${BLUE}[1/6]${NC} Update sistem..."
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl openssl iptables ufw cron > /dev/null 2>&1
    echo -e "${GREEN}    ✓ Selesai${NC}"

    echo -e "${BLUE}[2/6]${NC} Download binary ZIVPN UDP..."
    mkdir -p "$ZIVPN_DIR"

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

    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(S+)' | head -1)
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
    echo -e "  IP VPS  : ${CYAN}$(get_ip)${NC}"
    echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
    echo -e "  Status  : ${GREEN}$(systemctl is-active zivpn.service)${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}  Cara connect di ZIVPN App:${NC}"
    echo -e "  1. Buka ZIVPN → centang ${BOLD}UDP Tunnel${NC}"
    echo -e "  2. UDP Server  : ${CYAN}$(get_ip)${NC}"
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
    echo -e "  Label    : ${CYAN}$username${NC}"
    if [[ "$expiry" == "unlimited" ]]; then
        echo -e "  Expired  : ${GREEN}Unlimited${NC}"
    else
        echo -e "  Expired  : ${YELLOW}$expiry${NC}"
    fi
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "${YELLOW}  Cara connect di ZIVPN App (UDP Tunnel):${NC}"
    echo -e "  UDP Server  : ${CYAN}$(get_ip)${NC}"
    echo -e "  UDP Password: ${CYAN}$password${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
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

    echo ""
    echo -e "${GREEN}  ✓ User '$username' berhasil diperpanjang!${NC}"
    echo -e "  Expired baru : ${CYAN}$new_expiry${NC}"
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
    local SCRIPT_URL="https://raw.githubusercontent.com/wget -qO- https://raw.githubusercontent.com/script-VIP/Vip/main/udp/zs.sh"
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
            echo -e "  ${GREEN}8${NC}. Update Script"
            echo -e "  ${RED}9${NC}. Uninstall ZIVPN"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [1-9] : ${NC}")" choice

            case $choice in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) clean_expired ;;
                6) status_service ;;
                7) restart_service ;;
                8) update_script ;;
                9) uninstall_zivpn ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === ENTRY POINT ===

check_root
main_menu
