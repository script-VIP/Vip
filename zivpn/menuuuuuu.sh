#!/bin/bash
# =============================================
#   MENU ZIVPN UDP - SUPER FIX
# =============================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Cek root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} Jalankan sebagai root!"
    exit 1
fi

# Path
USERS_DB="/etc/zivpn/users.db"
CONFIG_FILE="/etc/zivpn/config.json"
CERT_FILE="/etc/zivpn/zivpn.crt"
KEY_FILE="/etc/zivpn/zivpn.key"

# Fungsi get IP
get_ip() {
    curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

# Update config
update_config() {
    passwords=()
    while IFS='|' read -r user pass exp; do
        passwords+=("\"$pass\"")
    done < "$USERS_DB" 2>/dev/null
    
    if [[ ${#passwords[@]} -eq 0 ]]; then
        pass_list="\"zivpn\""
    else
        pass_list=$(IFS=','; echo "${passwords[*]}")
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

# Cek instalasi
if [[ ! -f "$USERS_DB" ]]; then
    mkdir -p /etc/zivpn
    touch "$USERS_DB"
fi

# ========== MENU UTAMA ==========
while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      MENU ZIVPN UDP MANAGER     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. Tambah User"
    echo -e "  ${RED}2${NC}. Hapus User"
    echo -e "  ${CYAN}3${NC}. Lihat User"
    echo -e "  ${YELLOW}4${NC}. Restart Service"
    echo -e "  ${BLUE}5${NC}. Status Service"
    echo -e "  ${WHITE}0${NC}. Keluar"
    echo ""
    echo -e "${WHITE}────────────────────────────────${NC}"
    
    # READ INPUT DI SINI
    read -p "  Pilih menu [0-5] : " pilihan
    
    case $pilihan in
        1)  # TAMBAH USER
            clear
            echo -e "${YELLOW}--- TAMBAH USER ---${NC}"
            read -p "Username : " user
            read -p "Password : " pass
            read -p "Expired (hari) : " hari
            
            if [[ "$hari" =~ ^[0-9]+$ ]]; then
                exp=$(date -d "+$hari days" +%Y-%m-%d)
                echo "$user|$pass|$exp" >> "$USERS_DB"
                update_config
                echo -e "${GREEN}✓ User $user ditambahkan (exp: $exp)${NC}"
                echo -e "IP Server: $(get_ip)"
            else
                echo -e "${RED}Angka tidak valid!${NC}"
            fi
            read -p "Tekan Enter..."
            ;;
            
        2)  # HAPUS USER
            clear
            echo -e "${YELLOW}--- HAPUS USER ---${NC}"
            if [[ -s "$USERS_DB" ]]; then
                echo "Daftar User:"
                cat "$USERS_DB" | cut -d'|' -f1 | nl
                echo ""
                read -p "Nama user : " user
                if grep -q "^$user|" "$USERS_DB"; then
                    sed -i "/^$user|/d" "$USERS_DB"
                    update_config
                    echo -e "${GREEN}✓ User $user dihapus${NC}"
                else
                    echo -e "${RED}User tidak ada!${NC}"
                fi
            else
                echo -e "${RED}Belum ada user!${NC}"
            fi
            read -p "Tekan Enter..."
            ;;
            
        3)  # LIHAT USER
            clear
            echo -e "${CYAN}--- DAFTAR USER ---${NC}"
            if [[ -s "$USERS_DB" ]]; then
                printf "%-15s %-15s %-12s\n" "USERNAME" "PASSWORD" "EXPIRED"
                echo "----------------------------------------"
                cat "$USERS_DB" | while IFS='|' read -r u p e; do
                    printf "%-15s %-15s %-12s\n" "$u" "$p" "$e"
                done
            else
                echo -e "${YELLOW}Belum ada user.${NC}"
            fi
            read -p "Tekan Enter..."
            ;;
            
        4)  # RESTART SERVICE
            clear
            systemctl restart zivpn.service
            echo -e "${GREEN}✓ Service direstart${NC}"
            read -p "Tekan Enter..."
            ;;
            
        5)  # STATUS SERVICE
            clear
            systemctl status zivpn.service --no-pager
            read -p "Tekan Enter..."
            ;;
            
        0)  # KELUAR
            echo -e "${GREEN}Terima kasih!${NC}"
            exit 0
            ;;
            
        *)  # PILIHAN SALAH
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
