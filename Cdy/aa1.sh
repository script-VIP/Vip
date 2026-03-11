#!/bin/bash
# ======================================================
#   HOKAGE LEGEND: ZIVPN MANAGER V7.0 (AUTO-FIX DB)
# ======================================================

# --- WARNA & VAR ---
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
PURPLE='\e[1;35m'
NC='\e[0m'
BLINK_RED='\e[5;31m'
BLINK_GREEN='\e[5;32m'

CONFIG_FILE="/etc/zivpn/config.json"
USER_DB="/etc/zivpn/user-db.json"
SSH_DB="/etc/ssh/.ssh.db"
ZIVPN_SERVICE="zivpn.service"
UDP_SERVICE="udp-custom.service"

# --- CEK DEPENDENSI & INIT DATABASE ---
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install jq -y >/dev/null 2>&1
fi

# Fix: Buat file database jika belum ada untuk mencegah error jq
if [[ ! -f "$USER_DB" ]]; then
    echo "{}" > "$USER_DB"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p /etc/zivpn
    echo '{"auth": {"config": []}}' > "$CONFIG_FILE"
fi

# --- HEADER ---
function header() {
    clear
    DOM=$(cat /etc/xray/domain 2>/dev/null || echo "IP-Only")
    MYIP=$(wget -qO- icanhazip.com)
    RAM=$(free -m | grep Mem | awk '{print $3"/"$2" MB"}')
    UPTIME=$(uptime -p | cut -d " " -f 2-10)
    
    # --- LOGIKA STATUS ZIVPN ---
    if systemctl is-active --quiet "$ZIVPN_SERVICE"; then
        ZIVPN_STATUS="${GREEN}🟢${NC} ${BLINK_GREEN}ONLINE${NC}"
    else
        ZIVPN_STATUS="${RED}🔴 OFFLINE${NC}"
    fi
    # ---------------------------
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}      ⚡ ZIVPN ULTIMATE MANAGER V7.0 ⚡           ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}🖥️  VPS IP    :${NC} $MYIP"
    echo -e "  ${GREEN}🌐  Domain    :${NC} $DOM"
    echo -e "  ${GREEN}💾  RAM Usage :${NC} $RAM"
    echo -e "  ${GREEN}⏳  Uptime    :${NC} $UPTIME"
    echo -e "  ${GREEN}🚀  Status    :${NC} $ZIVPN_STATUS"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- 1. MONITOR USER (AUTO SYNC) ---
function monitor_users() {
    header
    echo -e "              📊  MONITOR USER (SISA HARI)              "
    echo -e "${CYAN}--------------------------------------------------${NC}"
    printf "${YELLOW}%-4s %-16s %-12s %-15s${NC}\n" "No" "Username" "Expired" "Status"
    
    n=1
    today_sec=$(date +%s)
    NEED_RESTART=0

    # Pastikan DB ada sebelum loop
    [[ ! -f "$USER_DB" ]] && echo "{}" > "$USER_DB"

    # --- LOOPING SYSTEM USERS (/etc/passwd) ---
    while IFS=: read -r username _ uid _ _ _ shell; do
        # Filter: Hanya User Biasa (UID >= 1000) dan bukan 'nobody'
        if [[ "$uid" -ge 1000 && "$username" != "nobody" && "$username" != "zi" ]]; then
            
            # 1. CEK EXPIRED (DARI SYSTEM CHAGE)
            exp_str=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
            
            if [[ "$exp_str" == *"never"* || -z "$exp_str" ]]; then 
                exp_display="Unlimited"
                status_text="${GREEN}ACTIVE${NC}"
                exp_db="2099-12-31"
            else
                exp_sec=$(date -d "$exp_str" +%s 2>/dev/null)
                exp_db=$(date -d "$exp_str" +"%Y-%m-%d" 2>/dev/null)
                
                if [[ -n "$exp_sec" ]]; then
                    diff=$(( (exp_sec - today_sec) / 86400 ))
                    exp_display=$(date -d "$exp_str" +"%Y-%m-%d")
                    
                    if [ "$diff" -lt 0 ]; then
                        status_text="${RED}EXPIRED${NC}"
                    elif [ "$diff" -eq 0 ]; then
                        status_text="${BLINK_RED}HARI INI${NC}"
                    else
                        status_text="${GREEN}$diff Hari Lagi${NC}"
                    fi
                else
                    exp_display="Error"
                    status_text="${RED}Unknown${NC}"
                fi
            fi

            # 2. AUTO-FIX: SYNC KE ZIVPN CONFIG
            # Jika user ada di SSH tapi belum ada di ZiVPN, tambahkan otomatis.
            if ! jq -e ".auth.config | index(\"$username\")" "$CONFIG_FILE" > /dev/null 2>&1; then
                  jq --arg u "$username" '.auth.config += [$u]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                  NEED_RESTART=1
            fi

            # 3. AUTO-FIX: SYNC KE USER-DB (Tanpa Error)
            if [[ -n "$exp_db" ]]; then
                jq --arg u "$username" --arg e "$exp_db" '.[$u] = {exp: $e}' "$USER_DB" > "${USER_DB}.tmp" && mv "${USER_DB}.tmp" "$USER_DB"
            fi

            # 4. TAMPILKAN BARIS
            printf "%-4s %-16s %-12s %-15b\n" "$n" "${username:0:16}" "$exp_display" "$status_text"
            ((n++))
        fi
    done < /etc/passwd

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Restart otomatis jika ada user baru yang disinkronkan
    if [ "$NEED_RESTART" -eq 1 ]; then
        echo -e " ${YELLOW}[INFO] Mendeteksi user baru. Merestart ZiVPN...${NC}"
        systemctl restart zivpn
        echo -e " ${GREEN}[OK] Sinkronisasi selesai.${NC}"
    fi

    read -n 1 -s -r -p "Tekan Enter untuk kembali..."
}

# --- 2. HAPUS USER ---
function delete_user() {
    header
    read -p " Masukkan Username: " username
    [ -z "$username" ] && return
    
    # Hapus dari Config ZiVPN
    jq --arg u "$username" '.auth.config -= [$u]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    # Hapus dari Metadata DB
    jq --arg u "$username" 'del(.[$u])' "$USER_DB" > "${USER_DB}.tmp" && mv "${USER_DB}.tmp" "$USER_DB"
    
    # Hapus System User
    userdel -f "$username" &>/dev/null
    
    systemctl restart "$ZIVPN_SERVICE"
    echo -e "${GREEN} ✅ User $username berhasil dihapus total.${NC}"; sleep 2
}

# --- 3. RESTART ---
function restart_menu() {
    header
    echo -e " [1] Restart ZiVPN\n [2] Restart UDP Custom\n [0] Kembali"
    read -p " Pilih: " rs
    case $rs in
        1) systemctl restart "$ZIVPN_SERVICE" ;;
        2) systemctl restart "$UDP_SERVICE" ;;
    esac
}

# --- 4. AUTO DELETE EXPIRED ---
function auto_delete_expired() {
    header
    echo -e "      🗑️  AUTO DELETE EXPIRED USERS (SYSTEM SCAN) 🗑️"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    
    today_sec=$(date +%s)
    deleted_count=0

    # Scan System User langsung (/etc/passwd)
    while IFS=: read -r username _ uid _ _ _ shell; do
        if [[ "$uid" -ge 1000 && "$username" != "nobody" && "$username" != "zi" ]]; then
            
            exp_str=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
            
            if [[ "$exp_str" != *"never"* && -n "$exp_str" ]]; then
                exp_sec=$(date -d "$exp_str" +%s 2>/dev/null)
                
                # Jika Expired Time < Waktu Sekarang
                if [[ "$exp_sec" -lt "$today_sec" ]]; then
                    echo -e " ${RED}➤ MENGHAPUS: $username (Expired: $exp_str)${NC}"
                    
                    # Hapus Total
                    jq --arg u "$username" '.auth.config -= [$u]' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                    jq --arg u "$username" 'del(.[$u])' "$USER_DB" > "${USER_DB}.tmp" && mv "${USER_DB}.tmp" "$USER_DB"
                    userdel -f "$username" &>/dev/null
                    
                    ((deleted_count++))
                fi
            fi
        fi
    done < /etc/passwd

    echo -e "${CYAN}--------------------------------------------------${NC}"
    if [ "$deleted_count" -gt 0 ]; then
        echo -e "${GREEN} ✅ Berhasil menghapus $deleted_count user.${NC}"
        systemctl restart "$ZIVPN_SERVICE"
    else
        echo -e "${GREEN} ✅ Tidak ada user expired.${NC}"
    fi
    read -n 1 -s -r -p "Tekan Enter untuk kembali..."
}

# --- MENU UTAMA ---
while true; do
    header
    echo -e " ${GREEN}[01]${NC} Monitor Sisa Hari (Akun)"
    echo -e " ${GREEN}[02]${NC} Hapus User (Manual)"
    echo -e " ${GREEN}[03]${NC} Restart Service"
    echo -e " ${RED}[04]${NC} HAPUS USER EXPIRED OTOMATIS"
    echo -e " ${GREEN}[00]${NC} Keluar"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p " Pilih: " opt
    case $opt in
        1|01) monitor_users ;;
        2|02) delete_user ;;
        3|03) restart_menu ;;
        4|04) auto_delete_expired ;;
        0|00) exit 0 ;;
        *) echo "Pilihan salah" ; sleep 1 ;;
    esac
done
