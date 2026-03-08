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
    
    # Buat folder backup
    mkdir -p "$BACKUP_DIR"
    
    # Generate nama file backup dengan timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/zivpn-backup-$timestamp.tar.gz"
    
    echo -e "${BLUE}Membuat backup...${NC}"
    
    # Backup file-file penting
    tar -czf "$backup_file" \
        "$USERS_DB" \
        "$CONFIG_FILE" \
        "$CERT_FILE" \
        "$KEY_FILE" 2>/dev/null
    
    if [[ $? -eq 0 && -f "$backup_file" ]]; then
        local file_size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}  ✓ Backup berhasil dibuat!${NC}"
        echo -e "  Lokasi: ${CYAN}$backup_file${NC}"
        echo -e "  Ukuran: ${YELLOW}$file_size${NC}"
        echo -e "  Waktu : ${YELLOW}$timestamp${NC}"
        
        # Simpan daftar backup
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
    
    # Cek apakah ada file backup
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${RED}[!] Folder backup tidak ditemukan!${NC}"
        press_enter
        return
    fi
    
    # Cari semua file backup
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
    
    if [[ "$choice" == "b" || "$choice" == "B" ]]; then
        return
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#backups[@]} ]]; then
        local selected="${backups[$((choice-1))]}"
        
        echo ""
        echo -e "${YELLOW}Peringatan: Restore akan menimpa data yang ada!${NC}"
        read -rp "$(echo -e "${RED}Yakin ingin restore? [y/N] : ${NC}")" confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Melakukan restore...${NC}"
            
            # Backup data saat ini dulu (just in case)
            local current_backup="$BACKUP_DIR/current-before-restore-$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$current_backup" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
            
            # Extract backup
            tar -xzf "$selected" -C /
            
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}  ✓ Restore berhasil!${NC}"
                # Restart service
                systemctl restart zivpn.service
                echo -e "${GREEN}  ✓ Service direstart${NC}"
                
                # Tampilkan info
                local user_count=$(grep -c "^" "$USERS_DB" 2>/dev/null || echo "0")
                echo -e "  Jumlah user: ${CYAN}$user_count${NC}"
            else
                echo -e "${RED}  ✗ Restore gagal!${NC}"
            fi
        else
            echo -e "${YELLOW}Restore dibatalkan.${NC}"
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
        
        # Hitung jumlah user di backup (dengan extract sementara)
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
    echo ""
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
        [bB])
            return
            ;;
        [aA])
            echo ""
            read -rp "$(echo -e "${RED}Yakin hapus SEMUA backup? [y/N] : ${NC}")" confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$BACKUP_DIR"/zivpn-backup-*.tar.gz
                rm -f "$BACKUP_DIR"/backup-list.txt
                echo -e "${GREEN}  ✓ Semua backup berhasil dihapus!${NC}"
            else
                echo -e "${YELLOW}Dibatalkan.${NC}"
            fi
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#backups[@]} ]]; then
                local selected="${backups[$((choice-1))]}"
                local filename=$(basename "$selected")
                
                echo ""
                read -rp "$(echo -e "${RED}Yakin hapus backup $filename? [y/N] : ${NC}")" confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$selected"
                    # Update backup list
                    sed -i "\|$selected|d" "$BACKUP_DIR/backup-list.txt" 2>/dev/null
                    echo -e "${GREEN}  ✓ Backup berhasil dihapus!${NC}"
                else
                    echo -e "${YELLOW}Dibatalkan.${NC}"
                fi
            else
                echo -e "${RED}Pilihan tidak valid!${NC}"
            fi
            ;;
    esac
    
    echo ""
    press_enter
}

# === FUNGSI BACKUP OTOMATIS ===
auto_backup() {
    # Fungsi untuk cron job
    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/zivpn-auto-$(date +%Y%m%d).tar.gz"
    tar -czf "$backup_file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    # Hapus backup lebih dari 7 hari
    find "$BACKUP_DIR" -name "zivpn-auto-*.tar.gz" -type f -mtime +7 -delete
}

setup_auto_backup() {
    banner
    echo -e "${BOLD}${YELLOW}[ SETUP AUTO BACKUP ]${NC}"
    echo ""
    
    # Cek apakah cron sudah terinstall
    if ! command -v crontab &> /dev/null; then
        apt-get install -y cron > /dev/null 2>&1
    fi
    
    # Buat script auto backup
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

# Hapus backup lebih dari 7 hari
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
    
    # Hapus cron job yang ada
    crontab -l 2>/dev/null | grep -v "zivpn-autobackup" | crontab -
    
    case $choice in
        1)
            (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/zivpn-autobackup.sh") | crontab -
            echo -e "${GREEN}  ✓ Auto backup setiap hari (02:00) diaktifkan!${NC}"
            ;;
        2)
            (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/zivpn-autobackup.sh") | crontab -
            echo -e "${GREEN}  ✓ Auto backup setiap minggu (Minggu 02:00) diaktifkan!${NC}"
            ;;
        3)
            (crontab -l 2>/dev/null; echo "0 2 1 * * /usr/local/bin/zivpn-autobackup.sh") | crontab -
            echo -e "${GREEN}  ✓ Auto backup setiap bulan (tanggal 1 02:00) diaktifkan!${NC}"
            ;;
        4)
            echo -e "${YELLOW}  Auto backup dimatikan.${NC}"
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            return
            ;;
    esac
    
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
    echo -e "${YELLOW}  Cara connect di ZIVPN App:${NC}"
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

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
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

    echo -e "${WHITE}Daftar user:${NC}"
    local i=1
    while IFS='|' read -r uname pass expiry; do
        echo -e "  ${CYAN}$i.${NC} $uname"
        ((i++))
    done < "$USERS_DB"
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
    systemctl status zivpn.service --no-pager -l
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

# === LIHAT LOG ===
view_logs() {
    banner
    echo -e "${BOLD}${YELLOW}[ LOG ZIVPN UDP ]${NC}"
    echo ""
    echo -e "${WHITE}Menampilkan 20 log terakhir (tekan Ctrl+C untuk keluar):${NC}"
    echo ""
    journalctl -u zivpn.service -n 20 -f --no-pager
    echo ""
    press_enter
}

# === INFO SERVER ===
server_info() {
    banner
    echo -e "${BOLD}${YELLOW}[ INFORMASI SERVER ]${NC}"
    echo ""
    echo -e "${WHITE}IP VPS        :${NC} ${CYAN}$(get_ip)${NC}"
    echo -e "${WHITE}Port UDP      :${NC} ${CYAN}5667 (langsung) / 6000-19999 (redirect)${NC}"
    echo -e "${WHITE}Config file   :${NC} $CONFIG_FILE"
    echo -e "${WHITE}Database user :${NC} $USERS_DB"
    echo -e "${WHITE}Backup folder :${NC} $BACKUP_DIR"
    echo -e "${WHITE}Service status:${NC} $(systemctl is-active zivpn.service)"
    echo -e "${WHITE}CPU Usage     :${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "${WHITE}RAM Usage     :${NC} $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo -e "${WHITE}Uptime        :${NC} $(uptime -p | sed 's/up //')"
    
    # Cek jumlah backup
    if [[ -d "$BACKUP_DIR" ]]; then
        local backup_count=$(ls "$BACKUP_DIR"/zivpn-backup-*.tar.gz 2>/dev/null | wc -l)
        echo -e "${WHITE}Total backup  :${NC} ${CYAN}$backup_count${NC} file"
    fi
    
    echo ""
    echo -e "${WHITE}Cara connect di ZIVPN App:${NC}"
    echo -e "  1. Buka ZIVPN → centang ${BOLD}UDP Tunnel${NC}"
    echo -e "  2. UDP Server  : ${CYAN}$(get_ip)${NC}"
    echo -e "  3. UDP Password: ${CYAN}[sesuai password user]${NC}"
    echo -e "  4. Tap APPLY → START"
    echo ""
    press_enter
}

# === UPDATE SCRIPT ===
update_script() {
    banner
    echo -e "${BOLD}${YELLOW}[ UPDATE MENU SCRIPT ]${NC}"
    echo ""

    local SCRIPT_URL="https://raw.githubusercontent.com/script-VIP/Vip/main/menu.sh"
    local SCRIPT_PATH="/usr/local/bin/menuziv"

    echo -e "  Mengecek update menu script..."
    local tmp_menu=$(mktemp)
    wget -q "$SCRIPT_URL" -O "$tmp_menu"

    if [[ ! -s "$tmp_menu" ]]; then
        echo -e "${RED}  [!] Gagal download update!${NC}"
        rm -f "$tmp_menu"
    else
        if [[ -f "$SCRIPT_PATH" ]]; then
            if diff -q "$tmp_menu" "$SCRIPT_PATH" > /dev/null 2>&1; then
                echo -e "${GREEN}  ✓ Menu script sudah versi terbaru!${NC}"
            else
                cp "$tmp_menu" "$SCRIPT_PATH"
                chmod +x "$SCRIPT_PATH"
                echo -e "${GREEN}  ✓ Menu script berhasil diupdate!${NC}"
            fi
        else
            cp "$tmp_menu" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo -e "${GREEN}  ✓ Menu script berhasil didownload!${NC}"
        fi
        rm -f "$tmp_menu"
    fi

    echo ""
    press_enter
}

# === UNINSTALL ===
uninstall_zivpn() {
    banner
    echo -e "${BOLD}${RED}[ UNINSTALL ZIVPN UDP ]${NC}"
    echo ""
    
    # Tanya backup dulu
    read -rp "$(echo -e "${YELLOW}Buat backup sebelum uninstall? [Y/n] : ${NC}")" backup_first
    if [[ ! "$backup_first" =~ ^[Nn]$ ]]; then
        backup_data
    fi
    
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
    rm -f /usr/local/bin/zivpn-autobackup.sh
    rm -rf "$ZIVPN_DIR"
    
    # Tanya apakah mau hapus backup juga
    echo ""
    read -rp "$(echo -e "${YELLOW}Hapus juga folder backup? [y/N] : ${NC}")" del_backup
    if [[ "$del_backup" =~ ^[Yy]$ ]]; then
        rm -rf "$BACKUP_DIR"
        echo -e "  Backup dihapus."
    fi

    systemctl daemon-reload

    echo -e "  Hapus cron..."
    crontab -l 2>/dev/null | grep -v "zivpn-cron" | grep -v "zivpn-autobackup" | crontab -

    echo ""
    echo -e "${GREEN}  ✓ ZIVPN UDP berhasil diuninstall!${NC}"
    echo -e "${YELLOW}  Keluar dari menu...${NC}"
    echo ""
    sleep 2
    exit 0
}

# === MENU BACKUP ===
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
        echo -e "  ${WHITE}0${NC}. Kembali ke Menu Utama"
        echo ""
        echo -e "${WHITE}  ────────────────────────────────────────${NC}"
        read -rp "$(echo -e "  ${WHITE}Pilih menu [0-5] : ${NC}")" choice

        case $choice in
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
            echo -e "${RED}  [!] ZIVPN belum terinstall!${NC}"
            echo ""
            echo -e "  ${GREEN}1${NC}. Install ZIVPN UDP"
            echo -e "  ${RED}0${NC}. Keluar"
            echo ""
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu : ${NC}")" choice
            case $choice in
                1) 
                    if [[ -f "/root/installziv.sh" ]]; then
                        bash /root/installziv.sh
                    else
                        echo -e "${RED}File installziv.sh tidak ditemukan!${NC}"
                        sleep 2
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
            echo -e "${WHITE}  ────────────────────────────────────────${NC}"
            read -rp "$(echo -e "  ${WHITE}Pilih menu [0-12] : ${NC}")" choice

            case $choice in
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
                0) 
                    echo -e "${GREEN}Terima kasih!${NC}"
                    exit 0 
                    ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# === START ===
check_root
main_menu
