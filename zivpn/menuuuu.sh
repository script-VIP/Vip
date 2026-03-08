#!/bin/bash
# =============================================
#   MENU ZIVPN UDP - SIMPLE EDITION
#   Auto Backup: Setiap Jam 02:00
# =============================================

# === WARNA ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# === PATH ===
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
CONFIG_FILE="$ZIVPN_DIR/config.json"
USERS_DB="$ZIVPN_DIR/users.db"
CERT_FILE="$ZIVPN_DIR/zivpn.crt"
KEY_FILE="$ZIVPN_DIR/zivpn.key"
BACKUP_DIR="/root/zivpn-backup"

# === CEK ROOT ===
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Jalankan sebagai root!"
    exit 1
fi

# === FUNGSI ===
get_ip() {
    curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}'
}

is_installed() {
    [[ -f "$ZIVPN_BIN" && -f "$CONFIG_FILE" ]]
}

# === AUTO BACKUP SETUP ===
setup_auto_backup() {
    mkdir -p "$BACKUP_DIR"
    
    # Buat script backup
    cat > /usr/local/bin/zivpn-backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/zivpn-backup"
USERS_DB="/etc/zivpn/users.db"
CONFIG_FILE="/etc/zivpn/config.json"
CERT_FILE="/etc/zivpn/zivpn.crt"
KEY_FILE="/etc/zivpn/zivpn.key"

mkdir -p "$BACKUP_DIR"
DATE=$(date +%Y%m%d)
FILE="$BACKUP_DIR/backup-$DATE.tar.gz"

tar -czf "$FILE" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null

# Hapus backup lebih dari 7 hari
find "$BACKUP_DIR" -name "backup-*.tar.gz" -type f -mtime +7 -delete
EOF
    chmod +x /usr/local/bin/zivpn-backup.sh
    
    # Setup cron (setiap jam 02:00)
    crontab -l 2>/dev/null | grep -v "zivpn-backup" | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/zivpn-backup.sh") | crontab -
    
    echo -e "${GREEN}✓ Auto backup aktif (setiap jam 02:00)${NC}"
}

# === UPDATE CONFIG ===
update_config() {
    local passwords=()
    while IFS='|' read -r uname pass expiry; do
        passwords+=("\"$pass\"")
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

# === TAMBAH USER ===
add_user() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         TAMBAH USER${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    read -p "Username : " user
    read -p "Password : " pass
    read -p "Expired (hari) : " hari
    
    if [[ ! "$hari" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Angka tidak valid!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    exp=$(date -d "+$hari days" +%Y-%m-%d)
    echo "$user|$pass|$exp" >> "$USERS_DB"
    update_config
    
    echo -e "${GREEN}✓ User $user ditambahkan (exp: $exp)${NC}"
    echo -e "${YELLOW}IP Server: $(get_ip)${NC}"
    read -p "Tekan Enter..."
}

# === HAPUS USER ===
del_user() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         HAPUS USER${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    if [[ ! -f "$USERS_DB" || ! -s "$USERS_DB" ]]; then
        echo -e "${RED}Belum ada user!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    echo -e "${WHITE}Daftar User:${NC}"
    nl -s ". " "$USERS_DB" | cut -d'|' -f1
    echo ""
    read -p "Nama user : " user
    
    if grep -q "^$user|" "$USERS_DB"; then
        sed -i "/^$user|/d" "$USERS_DB"
        update_config
        echo -e "${GREEN}✓ User $user dihapus${NC}"
    else
        echo -e "${RED}User tidak ditemukan!${NC}"
    fi
    read -p "Tekan Enter..."
}

# === LIST USER ===
list_user() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         DAFTAR USER${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    if [[ ! -f "$USERS_DB" || ! -s "$USERS_DB" ]]; then
        echo -e "${RED}Belum ada user!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    printf "%-15s %-15s %-12s %s\n" "USERNAME" "PASSWORD" "EXPIRED" "STATUS"
    echo -e "${WHITE}──────────────────────────────────${NC}"
    
    today=$(date +%Y-%m-%d)
    while IFS='|' read -r user pass exp; do
        if [[ "$exp" > "$today" || "$exp" == "$today" ]]; then
            status="${GREEN}Aktif${NC}"
        else
            status="${RED}Expired${NC}"
        fi
        printf "%-15s %-15s %-12s %b\n" "$user" "$pass" "$exp" "$status"
    done < "$USERS_DB"
    
    echo ""
    read -p "Tekan Enter..."
}

# === BACKUP MANUAL ===
backup_manual() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         BACKUP MANUAL${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    mkdir -p "$BACKUP_DIR"
    file="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$file" "$USERS_DB" "$CONFIG_FILE" "$CERT_FILE" "$KEY_FILE" 2>/dev/null
    
    if [[ -f "$file" ]]; then
        size=$(du -h "$file" | cut -f1)
        echo -e "${GREEN}✓ Backup berhasil:${NC}"
        echo "  Lokasi: $file"
        echo "  Ukuran: $size"
    else
        echo -e "${RED}✗ Backup gagal!${NC}"
    fi
    read -p "Tekan Enter..."
}

# === RESTORE ===
restore() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         RESTORE BACKUP${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${RED}Folder backup tidak ada!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    backups=($(ls "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null))
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}Tidak ada file backup!${NC}"
        read -p "Tekan Enter..."
        return
    fi
    
    echo -e "${WHITE}Pilih backup:${NC}"
    for i in "${!backups[@]}"; do
        size=$(du -h "${backups[$i]}" | cut -f1)
        echo "  $((i+1)). $(basename ${backups[$i]}) ($size)"
    done
    echo ""
    read -p "Pilih nomor [1-${#backups[@]}] : " num
    
    if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 && "$num" -le ${#backups[@]} ]]; then
        tar -xzf "${backups[$((num-1))]}" -C /
        systemctl restart zivpn.service
        echo -e "${GREEN}✓ Restore selesai!${NC}"
    else
        echo -e "${RED}Pilihan tidak valid!${NC}"
    fi
    read -p "Tekan Enter..."
}

# === SERVICE ===
service_status() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         STATUS SERVICE${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    systemctl status zivpn.service --no-pager
    read -p "Tekan Enter..."
}

restart_service() {
    clear
    systemctl restart zivpn.service
    echo -e "${GREEN}✓ Service direstart${NC}"
    read -p "Tekan Enter..."
}

# === CLEAN EXPIRED ===
clean_expired() {
    clear
    today=$(date +%Y-%m-%d)
    tmp=$(mktemp)
    count=0
    
    while IFS='|' read -r user pass exp; do
        if [[ "$exp" < "$today" ]]; then
            ((count++))
        else
            echo "$user|$pass|$exp" >> "$tmp"
        fi
    done < "$USERS_DB"
    
    mv "$tmp" "$USERS_DB"
    update_config
    
    echo -e "${GREEN}✓ $count user expired dihapus${NC}"
    read -p "Tekan Enter..."
}

# === INSTALL ===
install_zivpn() {
    clear
    echo -e "${CYAN}════════════════════════════════════${NC}"
    echo -e "${YELLOW}         INSTALL ZIVPN${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
    
    wget -qO /tmp/install.sh https://raw.githubusercontent.com/script-VIP/Vip/main/zivpn/installziv.sh
    bash /tmp/install.sh
    setup_auto_backup
    read -p "Tekan Enter..."
}

# === MENU UTAMA ===
while true; do
    clear
    echo -e "${CYAN}╔════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      MENU ZIVPN UDP MANAGER       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════╝${NC}"
    
    if is_installed; then
        status=$(systemctl is-active zivpn.service)
        [[ "$status" == "active" ]] && stat="${GREEN}● AKTIF${NC}" || stat="${RED}● MATI${NC}"
        echo -e "  Status : $stat"
        echo -e "  IP     : ${CYAN}$(get_ip)${NC}"
        echo -e "${WHITE}────────────────────────────────────${NC}"
    fi
    
    echo -e "  ${GREEN}1${NC}. Tambah User"
    echo -e "  ${RED}2${NC}. Hapus User"
    echo -e "  ${CYAN}3${NC}. Lihat User"
    echo -e "  ${YELLOW}4${NC}. Hapus Expired"
    echo -e "  ${BLUE}5${NC}. Restart Service"
    echo -e "  ${PURPLE}6${NC}. Status Service"
    echo -e "  ${WHITE}7${NC}. Backup Manual"
    echo -e "  ${WHITE}8${NC}. Restore"
    echo -e "  ${GREEN}9${NC}. Install (jika belum)"
    echo -e "  ${RED}0${NC}. Keluar"
    echo -e "${WHITE}────────────────────────────────────${NC}"
    
    read -p "Pilih menu : " menu
    [[ -z "$menu" ]] && continue
    
    case $menu in
        1) add_user ;;
        2) del_user ;;
        3) list_user ;;
        4) clean_expired ;;
        5) restart_service ;;
        6) service_status ;;
        7) backup_manual ;;
        8) restore ;;
        9) install_zivpn ;;
        0) 
            echo -e "${GREEN}Bye!${NC}"
            exit 0 
            ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
