#!/bin/bash
set +e
# ZIVPN Menu - COMPLETE EDITION
# Backup: Telegram | Google Drive (rclone) | Link URL | Local File

CONFIG="/etc/zivpn/config.json"
DB="/etc/zivpn/users.db"
DOMAIN_FILE="/etc/zivpn/domain.conf"
BACKUP_DIR="/root/zivpn-backup"

mkdir -p /etc/zivpn
mkdir -p "$BACKUP_DIR"
touch "$DB"
[ ! -f "$DOMAIN_FILE" ] && echo "-" > "$DOMAIN_FILE"

DOMAIN=$(cat "$DOMAIN_FILE")

# ===== TELEGRAM FILE =====
TG_FILE="/etc/zivpn/telegram.conf"

# load telegram config jika ada
if [ -f "$TG_FILE" ]; then
  source "$TG_FILE"
else
  # Default token (ganti sesuai kebutuhan)
  BOT_TOKEN="7340219400:AAHjx6z99gf5MiBb7m3HK-JJ-cRBAQwp_28"
  CHAT_ID="6198984094"
fi

# ===== ENSURE JQ =====
if ! command -v jq >/dev/null 2>&1; then
  apt update -y >/dev/null 2>&1
  apt install -y jq >/dev/null 2>&1
fi

# ===== ENSURE ZIP & UNZIP =====
if ! command -v zip >/dev/null 2>&1; then
  apt install -y zip >/dev/null 2>&1
fi

if ! command -v unzip >/dev/null 2>&1; then
  apt install -y unzip >/dev/null 2>&1
fi

# ===== ENSURE RCLONE =====
if ! command -v rclone >/dev/null 2>&1; then
  echo "Menginstall rclone..."
  curl https://rclone.org/install.sh | bash >/dev/null 2>&1
fi

# ===== COLORS =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ===== SYSTEM INFO =====
OS=$(lsb_release -ds 2>/dev/null | tr -d '"')
IP=$(curl -s ifconfig.me)
UPTIME=$(uptime -p)
CPU=$(nproc)
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
ZIVPN_STATUS=$(systemctl is-active zivpn 2>/dev/null)

# ===== FUNGSI MENU UTAMA =====
menu() {
  USER_COUNT=$(grep -c '|' "$DB" 2>/dev/null)
  ZIVPN_STATUS=$(systemctl is-active zivpn 2>/dev/null)

  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}        Z I V P N   M A N A G E R ${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${GREEN} OS      ${NC}: $OS"
  echo -e "${GREEN} Domain  ${NC}: ${YELLOW}$DOMAIN${NC}"
  echo -e "${GREEN} IP      ${NC}: $IP"
  echo -e "${GREEN} Uptime  ${NC}: $UPTIME"
  echo -e "${GREEN} CPU     ${NC}: $CPU Cores"
  echo -e "${GREEN} RAM     ${NC}: $RAM_USED / $RAM_TOTAL MB"
  echo -e "${GREEN} Disk    ${NC}: $DISK_USED / $DISK_TOTAL"
  echo -e "${GREEN} ZIVPN   ${NC}: ${YELLOW}$ZIVPN_STATUS${NC}"
  echo -e "${GREEN} Users   ${NC}: ${YELLOW}$USER_COUNT${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${YELLOW} 1${NC}) Create Account"
  echo -e "${YELLOW} 2${NC}) List Accounts"
  echo -e "${YELLOW} 3${NC}) Delete Account"
  echo -e "${YELLOW} 4${NC}) Renew Account"
  echo -e "${YELLOW} 5${NC}) Restart ZIVPN"
  echo -e "${YELLOW} 6${NC}) Delete All Expired"
  echo -e "${YELLOW} 7${NC}) Check User Online"
  echo -e "${YELLOW} 8${NC}) Change Domain"
  echo -e "${YELLOW} 9${NC}) Create Trial"
  echo -e "${YELLOW}10${NC}) Telegram Bot Setting"
  echo -e "${YELLOW}11${NC}) Backup & Restore"
  echo -e "${YELLOW}12${NC}) Auto Backup Setting"
  echo -e "${RED} 0${NC}) Exit"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  read -rp " Select Menu : " opt
}

# ===== FUNGSI LIST AKUN =====
list_accounts() {
  clear
  echo "--------------------------------------------------------------------------"
  printf "%-4s %-15s %-18s %-16s %-8s\n" "No" "Username" "Password" "Expired" "Limit"
  echo "--------------------------------------------------------------------------"
  nl -w2 -s'. ' "$DB" | while read -r n l; do
    IFS='|' read -r U P E L <<< "$l"
    [ -z "$L" ] && L="∞"
    printf "%-4s %-15s %-18s %-16s %-8s\n" "$n" "$U" "$P" "$E" "$L"
  done
  echo "--------------------------------------------------------------------------"
}

# ===== FUNGSI SEND TELEGRAM =====
send_telegram() {
  [ -z "$BOT_TOKEN" ] && return
  [ -z "$CHAT_ID" ] && return

  TEXT="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    --data-urlencode "text=$TEXT" \
    --data-urlencode "parse_mode=Markdown" >/dev/null 2>&1 &
}

# ===== FUNGSI SEND FILE TELEGRAM =====
send_file_telegram() {
  local file="$1"
  local caption="$2"
  
  [ -z "$BOT_TOKEN" ] && return 1
  [ -z "$CHAT_ID" ] && return 1
  [ ! -f "$file" ] && return 1
  
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$file" \
    -F caption="$caption" > /dev/null
}

# ===== FUNGSI CREATE ACCOUNT =====
create_account() {
  while true; do
    read -rp " Username : " USER
    [ -z "$USER" ] && echo "Username tidak boleh kosong!" && continue
    if grep -q "^$USER|" "$DB"; then
      echo "❌ Username '$USER' sudah ada!"
      continue
    fi
    break
  done

  read -rp " Duration (days) : " DAYS
  read -rp " IP Limit (1/2/3, 0=unlimit) : " LIMIT
  [ "$LIMIT" = "0" ] && LIMIT="∞"

  PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
  EXP=$(date -d "$DAYS days +1 day" +"%Y-%m-%d 00:00")

  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"

  systemctl restart zivpn

  send_telegram "📢 *AKUN BARU ZIVPN*
────────────────────
🌐 Domain    : $DOMAIN
👤 Username  : $USER
🔐 Password  : $PASS
⏳ Expired   : $EXP
📱 IP Limit  : $LIMIT
────────────────────"

  clear
  echo -e "${GREEN}ACCOUNT CREATED${NC}"
  echo " Domain    : $DOMAIN"
  echo " Username  : $USER"
  echo " Password  : $PASS"
  echo " Expired   : $EXP"
  echo " IP Limit  : $LIMIT"
  read -p "Press Enter..."
}

# ===== FUNGSI CREATE TRIAL =====
create_trial() {
  read -rp " Trial duration (minutes): " MIN
  [[ -z "$MIN" || "$MIN" -le 0 ]] && return

  USER="trial$(tr -dc 0-9 </dev/urandom | head -c 4)"
  PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  EXP=$(date -d "+$MIN minutes" +"%Y-%m-%d %H:%M")
  LIMIT=1

  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  systemctl restart zivpn

  send_telegram "⏱ *TRIAL ZIVPN*
────────────────────
🌐 Domain   : $DOMAIN
👤 Username : $USER
🔐 Password : $PASS
⏳ Expired  : $EXP
📱 IP Limit : 1
────────────────────"

  clear
  echo -e "${GREEN}TRIAL CREATED${NC}"
  echo " Domain   : $DOMAIN"
  echo " Username : $USER"
  echo " Password : $PASS"
  echo " Expired  : $EXP"
  read -p "Press Enter..."
}

# ===== FUNGSI DELETE ACCOUNT =====
delete_account() {
  list_accounts
  echo
  read -rp " Input Username / Password : " INPUT

  if grep -q "$INPUT" "$DB"; then
    grep -v "$INPUT" "$DB" > /tmp/db.tmp && mv /tmp/db.tmp "$DB"
    echo -e "${GREEN}Account deleted${NC}"
    systemctl restart zivpn
  else
    echo -e "${RED}Account not found${NC}"
  fi
  sleep 2
}

# ===== FUNGSI RENEW ACCOUNT =====
renew_account() {
  list_accounts
  echo
  read -rp " Renew account number : " NUM
  read -rp " Extend days : " DAYS

  LINE=$(sed -n "${NUM}p" "$DB")
  [ -z "$LINE" ] && echo "Invalid number" && sleep 2 && return

  IFS='|' read -r U P E L <<< "$LINE"
  BASE_DATE=$(echo "$E" | cut -d' ' -f1)
  NEWEXP=$(date -d "$BASE_DATE +$DAYS days +1 day" +"%Y-%m-%d 00:00")

  sed -i "${NUM}c\\$U|$P|$NEWEXP|$L" "$DB"
  systemctl restart zivpn
  echo -e "${GREEN}Account renewed${NC}"
  sleep 2
}

# ===== FUNGSI DELETE EXPIRED =====
delete_all_expired() {
  NOW=$(date +"%Y-%m-%d %H:%M")
  TMP="/tmp/zivpn-clean.db"
  > "$TMP"

  while IFS='|' read -r U P E L; do
    if [[ "$E" < "$NOW" ]]; then
      jq --arg pass "$P" '.auth.config -= [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
    else
      echo "$U|$P|$E|$L" >> "$TMP"
    fi
  done < "$DB"

  mv "$TMP" "$DB"
  systemctl restart zivpn
  echo -e "${GREEN}Expired accounts deleted${NC}"
  sleep 2
}

# ===== FUNGSI CHECK ONLINE =====
check_online() {
  clear
  echo "USER ONLINE MONITOR"
  echo "--------------------------------------------------"
  printf "%-15s %-18s %-10s\n" "Username" "Password" "Status"
  echo "--------------------------------------------------"

  while IFS='|' read -r U P E L; do
    if ss -u -n state connected '( sport = :5667 )' | grep -q "$U" 2>/dev/null; then
      STATUS="ONLINE"
    else
      STATUS="OFFLINE"
    fi
    printf "%-15s %-18s %-10s\n" "$U" "$P" "$STATUS"
  done < "$DB"

  echo "--------------------------------------------------"
  read -p "Press Enter..."
}

# ===== FUNGSI RESTART =====
restart_zivpn() {
  systemctl restart zivpn
  echo -e "${GREEN}ZIVPN restarted${NC}"
  sleep 2
}

# ===== FUNGSI CHANGE DOMAIN =====
change_domain() {
  read -rp " New Domain : " NEWDOMAIN
  [ -z "$NEWDOMAIN" ] && return
  echo "$NEWDOMAIN" > "$DOMAIN_FILE"

  openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=VPN/L=ZIVPN/O=ZIVPN/OU=ZIVPN/CN=$NEWDOMAIN" \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt 2>/dev/null

  systemctl restart zivpn
  DOMAIN="$NEWDOMAIN"
  echo -e "${GREEN}Domain updated${NC}"
  sleep 2
}

# ===== FUNGSI TELEGRAM SETTING =====
telegram_setting() {
  clear
  echo "===================================="
  echo "   TELEGRAM BOT NOTIFICATION SETUP"
  echo "===================================="
  read -rp "Input Bot Token : " BOT_TOKEN
  read -rp "Input Chat ID   : " CHAT_ID

  if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
    echo "Bot Token & Chat ID tidak boleh kosong!"
    sleep 2
    return
  fi

  cat > "$TG_FILE" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF

  chmod 600 "$TG_FILE"
  echo "Telegram Bot berhasil disimpan!"
  sleep 2
}

# ===== FUNGSI RCLONE SETUP =====
rclone_setup() {
  clear
  echo "===================================="
  echo "     RCLONE GOOGLE DRIVE SETUP"
  echo "===================================="
  echo "Ikuti langkah berikut untuk menghubungkan Google Drive:"
  echo ""
  echo "1. Jalankan perintah: rclone config"
  echo "2. Pilih 'n' untuk remote baru"
  echo "3. Nama remote: gdrive"
  echo "4. Pilih 'drive' sebagai tipe"
  echo "5. Ikuti petunjuk untuk login ke Google"
  echo ""
  read -p "Sudah siap? (y/n): " siap
  
  if [[ "$siap" == "y" ]]; then
    rclone config
    echo -e "${GREEN}Rclone configured${NC}"
  fi
  sleep 2
}

# ===== FUNGSI BACKUP =====
backup_zivpn() {
  clear
  echo "===================================="
  echo "         BACKUP ZIVPN"
  echo "===================================="
  
  DATE=$(date +%Y%m%d-%H%M%S)
  FILENAME="zivpn-backup-$DOMAIN-$DATE.zip"
  BACKUP_PATH="$BACKUP_DIR/$FILENAME"
  
  echo "Membuat backup..."
  
  # Backup file penting
  zip -r "$BACKUP_PATH" \
    /etc/zivpn/users.db \
    /etc/zivpn/config.json \
    /etc/zivpn/domain.conf \
    /etc/zivpn/zivpn.crt \
    /etc/zivpn/zivpn.key \
    /etc/zivpn/telegram.conf \
    /root/.config/rclone/rclone.conf 2>/dev/null
  
  if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    echo -e "${GREEN}✓ Backup berhasil: $FILENAME ($SIZE)${NC}"
    
    # Kirim ke Telegram
    send_file_telegram "$BACKUP_PATH" "✅ *Backup ZIVPN* 
📁 File: $FILENAME
📦 Size: $SIZE
🌐 Domain: $DOMAIN
🕐 Waktu: $(date +'%Y-%m-%d %H:%M:%S')"
    
    # Upload ke Google Drive jika rclone terkonfigurasi
    if rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
      echo "Mengupload ke Google Drive..."
      rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" --progress
      echo -e "${GREEN}✓ Terupload ke Google Drive${NC}"
      
      # Dapatkan link share
      GDRIVE_LINK=$(rclone link "gdrive:ZIVPN-Backup/$FILENAME" 2>/dev/null)
      send_telegram "☁️ *Google Drive Link*
🔗 $GDRIVE_LINK"
    fi
    
    # Hapus file lokal setelah backup
    read -rp "Hapus file backup lokal? (y/n): " hapus
    if [[ "$hapus" == "y" ]]; then
      rm -f "$BACKUP_PATH"
      echo "File lokal dihapus"
    fi
    
  else
    echo -e "${RED}✗ Backup gagal${NC}"
  fi
  
  read -p "Press Enter..."
}

# ===== FUNGSI RESTORE DARI LINK =====
restore_from_link() {
  clear
  echo "===================================="
  echo "      RESTORE DARI LINK URL"
  echo "===================================="
  read -rp "Masukkan URL file backup: " URL
  
  if [ -z "$URL" ]; then
    echo "URL kosong!"
    sleep 2
    return
  fi
  
  FILENAME=$(basename "$URL")
  DOWNLOAD_PATH="/tmp/$FILENAME"
  
  echo "Mengunduh file..."
  wget -q --show-progress "$URL" -O "$DOWNLOAD_PATH"
  
  if [ ! -f "$DOWNLOAD_PATH" ]; then
    echo -e "${RED}✗ Download gagal${NC}"
    sleep 2
    return
  fi
  
  echo "Ekstrak file..."
  unzip -o "$DOWNLOAD_PATH" -d /tmp/restore/ >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
    cp -rf /tmp/restore/root/.config/rclone/rclone.conf /root/.config/rclone/ 2>/dev/null
    rm -rf /tmp/restore
    systemctl restart zivpn
    echo -e "${GREEN}✓ Restore berhasil${NC}"
    send_telegram "🔄 *Restore dari Link*
🔗 $URL
✅ Selesai"
  else
    echo -e "${RED}✗ Restore gagal${NC}"
  fi
  
  rm -f "$DOWNLOAD_PATH"
  read -p "Press Enter..."
}

# ===== FUNGSI RESTORE DARI GOOGLE DRIVE =====
restore_from_drive() {
  clear
  echo "===================================="
  echo "   RESTORE DARI GOOGLE DRIVE"
  echo "===================================="
  
  if ! rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
    echo -e "${RED}Google Drive belum terkonfigurasi${NC}"
    read -rp "Konfigurasi sekarang? (y/n): " config
    if [[ "$config" == "y" ]]; then
      rclone_setup
    fi
    return
  fi
  
  echo "Daftar backup di Google Drive:"
  echo "----------------------------------"
  rclone ls "gdrive:ZIVPN-Backup"
  echo "----------------------------------"
  read -rp "Masukkan nama file backup: " FILE
  
  if [ -z "$FILE" ]; then
    return
  fi
  
  echo "Mendownload dari Google Drive..."
  rclone copy "gdrive:ZIVPN-Backup/$FILE" /tmp/ --progress
  
  if [ ! -f "/tmp/$FILE" ]; then
    echo -e "${RED}✗ Download gagal${NC}"
    sleep 2
    return
  fi
  
  unzip -o "/tmp/$FILE" -d /tmp/restore/ >/dev/null 2>&1
  cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
  rm -rf /tmp/restore "/tmp/$FILE"
  systemctl restart zivpn
  
  echo -e "${GREEN}✓ Restore berhasil${NC}"
  send_telegram "🔄 *Restore dari Google Drive*
📁 File: $FILE
✅ Selesai"
  
  read -p "Press Enter..."
}

# ===== FUNGSI RESTORE DARI TELEGRAM =====
restore_from_telegram() {
  clear
  echo "===================================="
  echo "    RESTORE DARI TELEGRAM"
  echo "===================================="
  echo "Cara dapat file path:"
  echo "1. Buka chat dengan bot"
  echo "2. Cari pesan backup sebelumnya"
  echo "3. File path ada di pesan"
  echo ""
  read -rp "Masukkan File Path: " FILE_PATH
  
  if [ -z "$FILE_PATH" ]; then
    return
  fi
  
  echo "Mendownload dari Telegram..."
  wget -q --show-progress "https://api.telegram.org/file/bot$BOT_TOKEN/$FILE_PATH" -O /tmp/telegram-backup.zip
  
  if [ ! -f "/tmp/telegram-backup.zip" ]; then
    echo -e "${RED}✗ Download gagal${NC}"
    sleep 2
    return
  fi
  
  unzip -o /tmp/telegram-backup.zip -d /tmp/restore/ >/dev/null 2>&1
  cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
  rm -rf /tmp/restore /tmp/telegram-backup.zip
  systemctl restart zivpn
  
  echo -e "${GREEN}✓ Restore berhasil${NC}"
  send_telegram "🔄 *Restore dari Telegram*
📁 File Path: $FILE_PATH
✅ Selesai"
  
  read -p "Press Enter..."
}

# ===== FUNGSI RESTORE DARI FILE LOKAL =====
restore_from_local() {
  clear
  echo "===================================="
  echo "    RESTORE DARI FILE LOKAL"
  echo "===================================="
  
  echo "File backup di $BACKUP_DIR:"
  echo "----------------------------------"
  ls -lh "$BACKUP_DIR" | grep .zip
  echo "----------------------------------"
  
  read -rp "Masukkan nama file: " FILE
  
  if [ ! -f "$BACKUP_DIR/$FILE" ]; then
    echo -e "${RED}File tidak ditemukan${NC}"
    sleep 2
    return
  fi
  
  unzip -o "$BACKUP_DIR/$FILE" -d /tmp/restore/ >/dev/null 2>&1
  cp -rf /tmp/restore/etc/zivpn/* /etc/zivpn/ 2>/dev/null
  rm -rf /tmp/restore
  systemctl restart zivpn
  
  echo -e "${GREEN}✓ Restore berhasil${NC}"
  read -p "Press Enter..."
}

# ===== FUNGSI BACKUP MENU =====
backup_menu() {
  while true; do
    clear
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${WHITE}       BACKUP & RESTORE MENU${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${YELLOW} 1${NC}) Backup Sekarang (Telegram + GDrive)"
    echo -e "${YELLOW} 2${NC}) Restore dari Google Drive"
    echo -e "${YELLOW} 3${NC}) Restore dari Link URL"
    echo -e "${YELLOW} 4${NC}) Restore dari Telegram"
    echo -e "${YELLOW} 5${NC}) Restore dari File Lokal"
    echo -e "${YELLOW} 6${NC}) Setup Google Drive (rclone)"
    echo -e "${YELLOW} 7${NC}) Lihat Daftar Backup"
    echo -e "${RED} 0${NC}) Kembali"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    read -rp " Pilih Menu : " bk_opt
    
    case $bk_opt in
      1) backup_zivpn ;;
      2) restore_from_drive ;;
      3) restore_from_link ;;
      4) restore_from_telegram ;;
      5) restore_from_local ;;
      6) rclone_setup ;;
      7) ls -lh "$BACKUP_DIR"; read -p "Press Enter..." ;;
      0) break ;;
      *) echo "Pilihan tidak valid"; sleep 1 ;;
    esac
  done
}

# ===== FUNGSI AUTO BACKUP SETTING =====
auto_backup_setting() {
  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}       AUTO BACKUP SETTING${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  
  # Cek cron yang ada
  if crontab -l 2>/dev/null | grep -q "zivpn-backup"; then
    CURRENT=$(crontab -l | grep "zivpn-backup" | awk '{print $2":"$1}')
    echo -e "${GREEN}Status: AKTIF${NC}"
    echo -e "Jadwal: Jam $CURRENT"
    echo ""
    echo "1) Nonaktifkan Auto Backup"
    echo "2) Ubah Jadwal"
    echo "3) Kembali"
    read -rp "Pilih: " auto_opt
    
    case $auto_opt in
      1)
        crontab -l | grep -v "zivpn-backup" | crontab -
        echo "Auto Backup dinonaktifkan"
        ;;
      2)
        set_autobackup_time
        ;;
    esac
  else
    echo -e "${RED}Status: NONAKTIF${NC}"
    echo ""
    echo "1) Aktifkan Auto Backup (Jam 03:00)"
    echo "2) Set Jadwal Manual"
    echo "3) Kembali"
    read -rp "Pilih: " auto_opt
    
    case $auto_opt in
      1)
        (crontab -l 2>/dev/null; echo "0 3 * * * /root/zivpn-menu --autobackup") | crontab -
        echo "Auto Backup diaktifkan (Jam 03:00)"
        ;;
      2)
        set_autobackup_time
        ;;
    esac
  fi
  sleep 2
}

set_autobackup_time() {
  read -rp "Masukkan Jam (0-23): " HOUR
  if [[ "$HOUR" =~ ^[0-9]+$ ]] && [ "$HOUR" -ge 0 ] && [ "$HOUR" -le 23 ]; then
    crontab -l | grep -v "zivpn-backup" | crontab -
    (crontab -l 2>/dev/null; echo "0 $HOUR * * * /root/zivpn-menu --autobackup") | crontab -
    echo "Auto Backup diset ke Jam $HOUR:00"
  else
    echo "Jam tidak valid"
  fi
  sleep 2
}

# ===== AUTO BACKUP MODE =====
if [[ "$1" == "--autobackup" ]]; then
  DATE=$(date +%Y%m%d-%H%M%S)
  FILENAME="zivpn-backup-auto-$DOMAIN-$DATE.zip"
  BACKUP_PATH="$BACKUP_DIR/$FILENAME"
  
  zip -r "$BACKUP_PATH" /etc/zivpn/ /root/.config/rclone/rclone.conf 2>/dev/null
  
  # Kirim ke Telegram
  if [ -f "$TG_FILE" ]; then
    source "$TG_FILE"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
      -F chat_id="$CHAT_ID" \
      -F document=@"$BACKUP_PATH" \
      -F caption="🔄 *Auto Backup ZIVPN*
📁 File: $FILENAME
🌐 Domain: $DOMAIN
🕐 Waktu: $(date +'%Y-%m-%d %H:%M:%S')" > /dev/null
  fi
  
  # Upload ke Google Drive jika ada
  if command -v rclone >/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
    rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" >/dev/null 2>&1
  fi
  
  # Hapus file lama (lebih dari 7 hari)
  find "$BACKUP_DIR" -name "*.zip" -type f -mtime +7 -delete
  rm -f "$BACKUP_PATH"
  exit 0
fi

# ===== MAIN LOOP =====
while true; do
  menu
  case $opt in
    1) create_account ;;
    2) list_accounts; read -p "Press Enter..." ;;
    3) delete_account ;;
    4) renew_account ;;
    5) restart_zivpn ;;
    6) delete_all_expired ;;
    7) check_online ;;
    8) change_domain ;;
    9) create_trial ;;
    10) telegram_setting ;;
    11) backup_menu ;;
    12) auto_backup_setting ;;
    0) exit 0 ;;
    *) echo "Pilihan tidak valid"; sleep 1 ;;
  esac
done
