#!/bin/bash
# =============================================
#   MENU ZIVPN UDP MANAGER
#   Version: 3.0 (Dengan Backup & Restore)
#   By: Custom Script
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
BACKUP_DIR="/root/zivpn-backup"

# === FUNGSI UTILITAS ===
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}'
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
    echo -e "${YELLOW}         MENU MANAJEMEN ZIVPN UDP${NC}"
    echo -e "${WHITE}  ════════════════════════════════════════${NC}"

    if ! is_installed; then
        echo -e "${RED}  [!] ZIVPN BELUM TERINSTAL!${NC}"
        echo -e "${YELLOW}  Jalankan instal.sh terlebih dahulu${NC}"
    else
        local ip=$(get_ip)
        local status=$(systemctl is-active zivpn.service 2>/dev/null)
        if [[ "$status" == "active" ]]; then
            echo -e "  Status  : ${GREEN}● AKTIF${NC}"
        else
            echo -e "  Status  : ${RED}● MATI${NC}"
        fi
        echo -e "  IP VPS  : ${CYAN}$ip${NC}"
        echo -e "  Port    : ${CYAN}5667 / 6000-19999 (UDP)${NC}"
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
    local today=$(date +%Y-%m-%d)
    local passwords=()

    while IFS='|' read -r uname pass expiry; do
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

# === FUNGSI BACKUP & RESTORE ===
backup_data() {
    banner
    echo -e "${BOLD}${YELLOW}[ BACKUP DATA ZIVPN ]${NC}"
    echo ""

    if ! is_installed; then
        echo -e "${RED}[!] ZIVPN belum terinstall!${NC}"
        press_enter
        return
    fi

    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/zivpn-backup-$timestamp.tar.gz"

    echo -e "${BLUE}Membuat backup...${NC}"
    tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null

    if [[ $? -eq 0 && -f "$backup_file" ]]; then
        local file_size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}  ✓ Backup berhasil dibuat!${NC}"
        echo -e "  Lokasi: ${CYAN}$backup_file${NC}"
        echo -e "  Ukuran: ${YELLOW}$file_size${NC}"
        echo "$backup_file" >> "$BACKUP_DIR/backup-list.txt"
    else
        echo -e "${RED}  ✗ Backup gagal!${NC}"
    fi

    echo ""
    press_enter
}

restore_data() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTORE DATA ZIVPN ]${NC}"
    echo ""

    if ! is_installed; then
        echo -e "${RED}[!] ZIVPN belum terinstall!${NC}"
        press_enter
        return
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${RED}[!] Folder backup tidak ditemukan!${NC}"
        press_enter
        return
    fi

    local backups=($(ls "$BACKUP_DIR"/zivpn-backup-*.tar.gz 2>/dev/null))
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] Tidak ada file backup ditemukan.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar Backup Tersedia:${NC}"
    echo -e "${WHITE}──────────────────────────────────${NC}"
    local i=1
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local file_date=$(echo "$filename" | sed 's/zivpn-backup-\(.*\)\.tar\.gz/\1/')
        local file_size=$(du -h "$backup" | cut -f1)
        echo -e "  ${CYAN}$i.${NC} $file_date"
        echo -e "     ${WHITE}File:${NC} $filename"
        echo -e "     ${WHITE}Size:${NC} $file_size"
        echo ""
        ((i++))
    done

    echo -e "${WHITE}──────────────────────────────────${NC}"
    echo -e "  ${GREEN}b.${NC} Kembali"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih nomor backup [1-${#backups[@]}] : ${NC}")" choice

    [[ "$choice" == "b" || "$choice" == "B" ]] && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#backups[@]} ]]; then
        local selected="${backups[$((choice-1))]}"
        echo ""
        read -rp "$(echo -e "${RED}Yakin ingin restore? [y/N] : ${NC}")" confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Melakukan restore...${NC}"
            local current_backup="$BACKUP_DIR/current-before-restore-$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$current_backup" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
            tar -xzf "$selected" -C /

            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}  ✓ Restore berhasil!${NC}"
                systemctl restart zivpn.service
                local user_count=$(grep -c "^" "$USERS_DB" 2>/dev/null || echo "0")
                echo -e "  Jumlah user: ${CYAN}$user_count${NC}"
            else
                echo -e "${RED}  ✗ Restore gagal!${NC}"
            fi
        fi
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi

    echo ""
    press_enter
}

list_backups() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR FILE BACKUP ]${NC}"
    echo ""

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}[!] Folder backup belum ada.${NC}"
        mkdir -p "$BACKUP_DIR"
        press_enter
        return
    fi

    local backups=($(ls "$BACKUP_DIR"/zivpn-backup-*.tar.gz 2>/dev/null))
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] Belum ada file backup.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}╔════════════════════════════════════════════════════════╗${NC}"
    printf "${WHITE}║ %-3s ║ %-19s ║ %-10s ║ %-15s ║${NC}\n" "No" "Tanggal Backup" "Ukuran" "Jumlah User"
    echo -e "${WHITE}╠════════════════════════════════════════════════════════╣${NC}"

    local i=1
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local file_date=$(echo "$filename" | sed 's/zivpn-backup-\(.*\)\.tar\.gz/\1/' | sed 's/_/ /')
        local file_size=$(du -h "$backup" | cut -f1)
        local temp_dir=$(mktemp -d)
        tar -xzf "$backup" -C "$temp_dir" etc/zivpn/users.db 2>/dev/null
        if [[ -f "$temp_dir/etc/zivpn/users.db" ]]; then
            local user_count=$(grep -c "^" "$temp_dir/etc/zivpn/users.db")
        else
            local user_count="N/A"
        fi
        rm -rf "$temp_dir"
        printf "║ ${CYAN}%-3s${NC} ║ %-19s ║ %-10s ║ %-15s ║\n" "$i." "$file_date" "$file_size" "$user_count"
        ((i++))
    done

    echo -e "${WHITE}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "  Total backup: ${CYAN}${#backups[@]}${NC} file"
    echo -e "  Lokasi backup: ${YELLOW}$BACKUP_DIR${NC}"
    echo ""
    press_enter
}

delete_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS FILE BACKUP ]${NC}"
    echo ""

    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}[!] Folder backup tidak ditemukan.${NC}"
        press_enter
        return
    fi

    local backups=($(ls "$BACKUP_DIR"/zivpn-backup-*.tar.gz 2>/dev/null))
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] Tidak ada file backup.${NC}"
        press_enter
        return
    fi

    echo -e "${WHITE}Daftar Backup:${NC}"
    echo -e "${WHITE}──────────────────────────────────${NC}"
    local i=1
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local file_size=$(du -h "$backup" | cut -f1)
        echo -e "  ${CYAN}$i.${NC} $filename ${WHITE}($file_size)${NC}"
        ((i++))
    done

    echo -e "${WHITE}──────────────────────────────────${NC}"
    echo -e "  ${RED}a.${NC} Hapus SEMUA backup"
    echo -e "  ${GREEN}b.${NC} Kembali"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih nomor backup [1-${#backups[@]}] / a/b : ${NC}")" choice

    case $choice in
        [bB]) return ;;
        [aA])
            read -rp "$(echo -e "${RED}Yakin hapus SEMUA backup? [y/N] : ${NC}")" confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$BACKUP_DIR"/zivpn-backup-*.tar.gz
                rm -f "$BACKUP_DIR"/backup-list.txt
                echo -e "${GREEN}  ✓ Semua backup berhasil dihapus!${NC}"
            fi
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#backups[@]} ]]; then
                local selected="${backups[$((choice-1))]}"
                local filename=$(basename "$selected")
                read -rp "$(echo -e "${RED}Yakin hapus backup $filename? [y/N] : ${NC}")" confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$selected"
                    sed -i "\|$selected|d" "$BACKUP_DIR/backup-list.txt" 2>/dev/null
                    echo -e "${GREEN}  ✓ Backup berhasil dihapus!${NC}"
                fi
            else
                echo -e "${RED}Pilihan tidak valid!${NC}"
            fi
            ;;
    esac
    echo ""
    press_enter
}

setup_auto_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ SETUP AUTO BACKUP ]${NC}"
    echo ""

    if ! command -v crontab &> /dev/null; then
        apt-get install -y cron > /dev/null 2>&1
    fi

    cat > /usr/local/bin/zivpn-autobackup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/zivpn-backup"
USERS_DB="/etc/zivpn/users.db"
CONFIG_FILE="/etc/zivpn/config.json"
CERT_FILE="/etc/zivpn/zivpn.crt"
KEY_FILE="/etc/zivpn/zivpn.key"
mkdir -p "$BACKUP_DIR"
backup_file="$BACKUP_DIR/zivpn-auto-$(date +%Y%m%d).tar.gz"
tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
find "$BACKUP_DIR" -name "zivpn-auto-*.tar.gz" -type f -mtime +7 -delete
EOF
    chmod +x /usr/local/bin/zivpn-autobackup.sh

    echo -e "${WHITE}Pilih jadwal auto backup:${NC}"
    echo -e "  ${CYAN}1${NC}. Setiap hari (jam 02:00)"
    echo -e "  ${CYAN}2${NC}. Setiap minggu (Minggu jam 02:00)"
    echo -e "  ${CYAN}3${NC}. Setiap bulan (tanggal 1 jam 02:00)"
    echo -e "  ${CYAN}4${NC}. Matikan auto backup"
    echo -e "  ${GREEN}5${NC}. Kembali"
    echo ""
    read -rp "$(echo -e "${WHITE}Pilih [1-5] : ${NC}")" choice

    crontab -l 2>/dev/null | grep -v "zivpn-autobackup" | crontab -
    case $choice in
        1) (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/zivpn-autobackup.sh") | crontab - && echo -e "${GREEN}  ✓ Auto backup setiap hari diaktifkan!${NC}" ;;
        2) (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/zivpn-autobackup.sh") | crontab - && echo -e "${GREEN}  ✓ Auto backup setiap minggu diaktifkan!${NC}" ;;
        3) (crontab -l 2>/dev/null; echo "0 2 1 * * /usr/local/bin/zivpn-autobackup.sh") | crontab - && echo -e "${GREEN}  ✓ Auto backup setiap bulan diaktifkan!${NC}" ;;
        4) echo -e "${YELLOW}  Auto backup dimatikan.${NC}" ;;
        5) return ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}"; return ;;
    esac
    echo ""
    press_enter
}

# === FUNGSI USER MANAGEMENT ===
add_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ TAMBAH USER ]${NC}"
    echo ""
    load_users

    read -rp "$(echo -e "${WHITE}Nama user   : ${NC}")" username
    [[ -z "$username" ]] && { echo -e "${RED}[!] Nama user tidak boleh kosong!${NC}"; press_enter; return; }
    user_exists "$username" && { echo -e "${RED}[!] User '$username' sudah ada!${NC}"; press_enter; return; }

    read -rp "$(echo -e "${WHITE}Password    : ${NC}")" password
    [[ -z "$password" ]] && { echo -e "${RED}[!] Password tidak boleh kosong!${NC}"; press_enter; return; }

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
            ! [[ "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}[!] Masukkan angka yang valid!${NC}"; press_enter; return; }
            ;;
        7) days=0 ;;
        *) echo -e "${RED}[!] Pilihan tidak valid!${NC}"; press_enter; return ;;
    esac

    [[ "$days" -eq 0 ]] && expiry="unlimited" || expiry=$(date -d "+$days days" +%Y-%m-%d)
    echo "$username|$password|$expiry" >> "$USERS_DB"
    update_config_json

    echo ""
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ User berhasil ditambahkan!${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo -e "  Label    : ${CYAN}$username${NC}"
    [[ "$expiry" == "unlimited" ]] && echo -e "  Expired  : ${GREEN}Unlimited${NC}" || echo -e "  Expired  : ${YELLOW}$expiry${NC}"
    echo -e "${WHITE}──────────────────────────────────────────${NC}"
    echo -e "${YELLOW}  UDP Server  : ${CYAN}$(get_ip)${NC}"
    echo -e "  UDP Password: ${CYAN}$password${NC}"
    echo -e "${WHITE}══════════════════════════════════════════${NC}"
    echo ""
    press_enter
}

delete_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ HAPUS USER ]${NC}"
    echo ""
    load_users
    [[ ! -s "$USERS_DB" ]] && { echo -e "${YELLOW}[!] Belum ada user.${NC}"; press_enter; return; }

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    echo ""
    read -rp "$(echo -e "${WHITE}Nama user : ${NC}")" username
    ! user_exists "$username" && { echo -e "${RED}[!] User tidak ditemukan!${NC}"; press_enter; return; }

    read -rp "$(echo -e "${RED}Yakin hapus user '$username'? [y/N] : ${NC}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^$username|/d" "$USERS_DB"
        update_config_json
        echo -e "${GREEN}  ✓ User '$username' berhasil dihapus!${NC}"
    fi
    press_enter
}

list_users() {
    banner
    echo -e "${BOLD}${YELLOW}[ DAFTAR USER ]${NC}"
    echo ""
    load_users
    [[ ! -s "$USERS_DB" ]] && { echo -e "${YELLOW}[!] Belum ada user.${NC}"; press_enter; return; }

    local today=$(date +%Y-%m-%d)
    printf "${WHITE}%-20s %-20s %-15s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}──────────────────────────────────────────────────────────${NC}"
    while IFS='|' read -r uname pass expiry; do
        if [[ "$expiry" == "unlimited" ]]; then
            status="${GREEN}Aktif${NC}"; exp_display="${GREEN}Unlimited${NC}"
        elif [[ "$expiry" > "$today" ]] || [[ "$expiry" == "$today" ]]; then
            status="${GREEN}Aktif${NC}"; exp_display="${YELLOW}$expiry${NC}"
        else
            status="${RED}Expired${NC}"; exp_display="${RED}$expiry${NC}"
        fi
        printf "%-20s %-20s %-24s " "$uname" "$pass" "$(echo -e $exp_display)"
        echo -e "$status"
    done < "$USERS_DB"
    echo ""
    press_enter
}

renew_user() {
    banner
    echo -e "${BOLD}${YELLOW}[ PERPANJANG USER ]${NC}"
    echo ""
    load_users
    [[ ! -s "$USERS_DB" ]] && { echo -e "${YELLOW}[!] Belum ada user.${NC}"; press_enter; return; }

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
    echo ""
    read -rp "$(echo -e "${WHITE}Nama user : ${NC}")" username
    ! user_exists "$username" && { echo -e "${RED}[!] User tidak ditemukan!${NC}"; press_enter; return; }

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
            ! [[ "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}[!] Masukkan angka valid!${NC}"; press_enter; return; }
            ;;
        7) days=0 ;;
        *) echo -e "${RED}[!] Pilihan tidak valid!${NC}"; press_enter; return ;;
    esac

    local old_expiry=$(get_user_expiry "$username")
    local pass=$(get_user_pass "$username")
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

    sed -i "s/^$username|$pass|$old_expiry/$username|$pass|$new_expiry/" "$USERS_DB"
    update_config_json
    echo ""
    echo -e "${GREEN}  ✓ User '$username' diperpanjang!${NC}"
    echo -e "  Expired baru : ${CYAN}$new_expiry${NC}"
    echo ""
    press_enter
}

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
            echo -e "  ${RED}✗ Dihapus:${NC} $uname"
            ((count++))
        else
            echo "$uname|$pass|$expiry" >> "$tmpfile"
        fi
    done < "$USERS_DB"

    if [[ $count -gt 0 ]]; then
        mv "$tmpfile" "$USERS_DB"
        update_config_json
        echo ""
        echo -e "${GREEN}  ✓ $count user expired dihapus!${NC}"
    else
        rm -f "$tmpfile"
        echo -e "${YELLOW}  Tidak ada user expired.${NC}"
    fi
    echo ""
    press_enter
}

status_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ STATUS SERVICE ]${NC}"
    echo ""
    systemctl status zivpn.service --no-pager -l
    echo ""
    press_enter
}

restart_service() {
    banner
    echo -e "${BOLD}${YELLOW}[ RESTART SERVICE ]${NC}"
    echo ""
    systemctl restart zivpn.service
    sleep 1
    systemctl is-active zivpn.service &>/dev/null && echo -e "${GREEN}  ✓ Service restarted!${NC}" || echo -e "${RED}  ✗ Gagal restart!${NC}"
    echo ""
    press_enter
}

view_logs() {
    banner
    echo -e "${BOLD}${YELLOW}[ LOG ZIVPN UDP ]${NC}"
    echo ""
    echo -e "${WHITE}Menampilkan log (Ctrl+C untuk keluar):${NC}"
    echo ""
    journalctl -u zivpn.service -n 20 -f --no-pager
    echo ""
    press_enter
}

server_info() {
    banner
    echo -e "${BOLD}${YELLOW}[ INFORMASI SERVER ]${NC}"
    echo ""
    echo -e "${WHITE}IP VPS        :${NC} ${CYAN}$(get_ip)${NC}"
    echo -e "${WHITE}Port UDP      :${NC} ${CYAN}5667 / 6000-19999${NC}"
    echo -e "${WHITE}Service status:${NC} $(systemctl is-active zivpn.service)"
    echo -e "${WHITE}CPU Usage     :${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "${WHITE}RAM Usage     :${NC} $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    [[ -d "$BACKUP_DIR" ]] && echo -e "${WHITE}Total backup  :${NC} ${CYAN}$(ls "$BACKUP_DIR"/zivpn-backup-*.tar.gz 2>/dev/null | wc -l)${NC} file"
    echo ""
    press_enter
}

update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE SCRIPT ]${NC}"
    echo ""
    local url="https://raw.githubusercontent.com/script-VIP/Vip/main/zivpn/menuu.sh"
    local tmp=$(mktemp)
    wget -q "$url" -O "$tmp"
    if [[ -s "$tmp" ]]; then
        cp "$tmp" "$0"
        chmod +x "$0"
        echo -e "${GREEN}  ✓ Script berhasil diupdate!${NC}"
        echo -e "${YELLOW}  Jalankan ulang script.${NC}"
        rm -f "$tmp"
        exit 0
    else
        echo -e "${RED}  ✗ Gagal update!${NC}"
        rm -f "$tmp"
    fi
    echo ""
    press_enter
}

uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN UDP ]${NC}"
    echo ""
    read -rp "$(echo -e "${YELLOW}Buat backup? [Y/n] : ${NC}")" bk
    [[ ! "$bk" =~ ^[Nn]$ ]] && backup_data
    read -rp "$(echo -e "${RED}Yakin uninstall? [y/N] : ${NC}")" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo -e "${YELLOW}Dibatalkan.${NC}"; press_enter; return; }

    systemctl stop zivpn.service &>/dev/null
    systemctl disable zivpn.service &>/dev/null
    rm -f "$SERVICE_FILE" "$ZIVPN_BIN" /usr/local/bin/zivpn-cron.sh /usr/local/bin/zivpn-autobackup.sh
    rm -rf "$ZIVPN_DIR"
    read -rp "$(echo -e "${YELLOW}Hapus backup? [y/N] : ${NC}")" del_bk
    [[ "$del_bk" =~ ^[Yy]$ ]] && rm -rf "$BACKUP_DIR"
    systemctl daemon-reload
    crontab -l 2>/dev/null | grep -v "zivpn" | crontab -
    echo -e "${GREEN}  ✓ Uninstall selesai!${NC}"
    sleep 2
    exit 0
}

backup_menu() {
    while true; do
        banner
        echo -e "${BOLD}${YELLOW}[ MENU BACKUP & RESTORE ]${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. Backup Data"
        echo -e "  ${CYAN}2${NC}. Restore Data"
        echo -e "  ${BLUE}3${NC}. Lihat Daftar Backup"
        echo -e "  ${RED}4${NC}. Hapus Backup"
        echo -e "  ${YELLOW}5${NC}. Setup Auto Backup"
        echo -e "  ${WHITE}0${NC}. Kembali"
        echo ""
        read -rp "$(echo -e "${WHITE}Pilih menu : ${NC}")" ch
        [[ -z "$ch" ]] && continue
        case $ch in
            1) backup_data ;;
            2) restore_data ;;
            3) list_backups ;;
            4) delete_backup ;;
            5) setup_auto_backup ;;
            0) break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# === MENU UTAMA ===
main_menu() {
    while true; do
        banner

        if ! is_installed; then
            echo -e "${RED}  [!] ZIVPN BELUM TERINSTAL!${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            read -rp "$(echo -e "${WHITE}Pilih menu : ${NC}")" ch
            [[ -z "$ch" ]] && continue
            case $ch in
                1)
                    if [[ -f "/root/installziv.sh" ]]; then
                        bash /root/installziv.sh
                    else
                        wget -qO- https://raw.githubusercontent.com/script-VIP/Vip/main/zivpn/installziv.sh | bash
                    fi
                    ;;
                0) exit 0 ;;
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
            echo -e "  ${BLUE}8${NC}. Lihat Log"
            echo -e "  ${CYAN}9${NC}. Info Server"
            echo ""
            echo -e "  ${GREEN}10${NC}. Menu Backup & Restore"
            echo -e "  ${GREEN}11${NC}. Update Script"
            echo -e "  ${RED}12${NC}. Uninstall ZIVPN"
            echo -e "  ${WHITE}0${NC}. Keluar"
            echo ""
            read -rp "$(echo -e "${WHITE}Pilih menu [0-12] : ${NC}")" ch
            [[ -z "$ch" ]] && continue

            case $ch in
                1) add_user ;;
                2) delete_user ;;
                3) list_users ;;
                4) renew_user ;;
                5) clean_expired ;;
                6) status_service ;;
                7) restart_service ;;
                8) view_logs ;;
                9) server_info ;;
                10) backup_menu ;;
                11) update_script ;;
                12) uninstall_zivpn ;;
                0) echo -e "${GREEN}Terima kasih!${NC}"; exit 0 ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === START ===
check_root
main_menu
