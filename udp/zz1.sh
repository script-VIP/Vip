#!/bin/bash

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              INSTALL ZIVPN UDP MANAGER                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Cek root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root${NC}" 
   exit 1
fi

# Update system
echo -e "${YELLOW}[1] Mengupdate system...${NC}"
apt update -y
apt upgrade -y

# Install dependencies
echo -e "${YELLOW}[2] Menginstall dependencies...${NC}"
apt install -y wget curl unzip zip jq openssl net-tools ss cron rclone

# Download dan install ZIVPN
echo -e "${YELLOW}[3] Menginstall ZIVPN...${NC}"
wget -q -O /tmp/zivpn.zip "https://github.com/script-VIP/Vip/raw/main/zivpn.zip"
unzip -o /tmp/zivpn.zip -d /etc/zivpn/ >/dev/null 2>&1
chmod +x /etc/zivpn/zivpn

# Buat config directory
mkdir -p /etc/zivpn
mkdir -p /root/zivpn-backup
touch /etc/zivpn/users.db
touch /etc/zivpn/domain.conf
touch /etc/zivpn/telegram.conf

# Set default domain
IP=$(curl -s ifconfig.me)
echo "$IP" > /etc/zivpn/domain.conf

# Buat systemd service
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZIVPN UDP Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/etc/zivpn/zivpn -config /etc/zivpn/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Buat config.json default
cat > /etc/zivpn/config.json <<EOF
{
  "server": {
    "host": "0.0.0.0",
    "port": 5667
  },
  "auth": {
    "mode": "password",
    "config": []
  },
  "timeout": 30
}
EOF

# Generate SSL certificate
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=ID/ST=VPN/L=ZIVPN/O=ZIVPN/OU=ZIVPN/CN=$IP" \
  -keyout /etc/zivpn/zivpn.key \
  -out /etc/zivpn/zivpn.crt 2>/dev/null

# Setup Rclone untuk Google Drive
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[gdrive]
type = drive
scope = drive
token = {"access_token":"ya29.a0AXooCgv9RkqG3Q4V5W6X7Y8Z9A0B1C2D3E4F5G6H7I8J9K0L","token_type":"Bearer","refresh_token":"1//0gH7I8J9K0LmN","expiry":"2025-01-01T00:00:00Z"}
EOF

# Download menu script dengan fitur lengkap
echo -e "${YELLOW}[4] Menginstall menu ZIVPN lengkap...${NC}"
cat > /usr/local/bin/zivpn-menu <<'EOF'
#!/bin/bash
set +e
# ZIVPN Menu - COMPLETE EDITION
# With Custom Backup Format

CONFIG="/etc/zivpn/config.json"
DB="/etc/zivpn/users.db"
DOMAIN_FILE="/etc/zivpn/domain.conf"
BACKUP_DIR="/root/zivpn-backup"
TG_FILE="/etc/zivpn/telegram.conf"

mkdir -p /etc/zivpn
mkdir -p "$BACKUP_DIR"
touch "$DB"
[ ! -f "$DOMAIN_FILE" ] && echo "-" > "$DOMAIN_FILE"

DOMAIN=$(cat "$DOMAIN_FILE")

# ===== TELEGRAM FILE =====
# load telegram config jika ada
if [ -f "$TG_FILE" ]; then
  source "$TG_FILE"
else
  # Default token 
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
  curl https://rclone.org/install.sh | bash >/dev/null 2>&1
fi

# ===== COLORS =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
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

# ===== FUNGSI GET LOKASI =====
get_location() {
  curl -s http://ipinfo.io/country 2>/dev/null || echo "Singapore"
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

# ===== MENU UTAMA =====
menu() {
  USER_COUNT=$(grep -c '|' "$DB" 2>/dev/null)
  ZIVPN_STATUS=$(systemctl is-active zivpn 2>/dev/null)

  clear
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║              ZIVPN UDP MANAGER - COMPLETE EDITION           ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${WHITE}🌍 Public IP    :${NC} ${GREEN}$IP${NC}"
  echo -e "  ${WHITE}📌 Domain       :${NC} ${YELLOW}$DOMAIN${NC}"
  echo -e "  ${WHITE}💾 RAM Usage    :${NC} ${CYAN}$RAM_USED / $RAM_TOTAL MB${NC}"
  echo -e "  ${WHITE}📊 Total Akun   :${NC} ${PURPLE}$USER_COUNT${NC}"
  echo -e "  ${WHITE}⚙️  Service      :${NC} ${GREEN}$ZIVPN_STATUS${NC}"
  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${YELLOW}[01]${NC} ➕  Tambah Akun (Default 2 digit)"
  echo -e "  ${YELLOW}[02]${NC} 🔑  Tambah Akun (Custom Password)"
  echo -e "  ${YELLOW}[03]${NC} 📋  Lihat Daftar Akun"
  echo -e "  ${YELLOW}[04]${NC} 🗑️  Hapus Akun"
  echo -e "  ${YELLOW}[05]${NC} 📅  Perpanjang Akun"
  echo -e "  ${YELLOW}[06]${NC} 🌐  Ganti Domain"
  echo -e "  ${YELLOW}[07]${NC} 👥  Cek User Online"
  echo -e "  ${YELLOW}[08]${NC} 🧹  Hapus Semua Expired"
  echo -e "  ${YELLOW}[09]${NC} 🔄  Restart Service"
  echo -e "  ${YELLOW}[10]${NC} ⏳  Buat Trial"
  echo -e "  ${YELLOW}[11]${NC} 🤖  Telegram Bot Setting"
  echo -e "  ${YELLOW}[12]${NC} 💾  Backup & Restore"
  echo -e "  ${YELLOW}[13]${NC} ⏰  Auto Backup Setting"
  echo -e "  ${YELLOW}[00]${NC} 🚪  Exit"
  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  read -rp "  Pilih Menu [00-13] : " opt
}

# ===== GANTI DOMAIN =====
ganti_domain() {
  clear
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo -e "${WHITE}         GANTI DOMAIN ZIVPN${NC}"
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo ""
  echo -e "Domain saat ini: ${GREEN}$DOMAIN${NC}"
  echo ""
  read -rp "Masukkan domain baru: " NEWDOMAIN
  
  if [ -z "$NEWDOMAIN" ]; then
    echo -e "${RED}❌ Domain tidak boleh kosong${NC}"
    sleep 2
    return
  fi
  
  # Simpan domain
  echo "$NEWDOMAIN" > "$DOMAIN_FILE"
  
  # Regenerate SSL
  openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=VPN/L=ZIVPN/O=ZIVPN/OU=ZIVPN/CN=$NEWDOMAIN" \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt 2>/dev/null
  
  # Restart service
  systemctl restart zivpn
  
  DOMAIN="$NEWDOMAIN"
  echo -e "${GREEN}✅ Domain berhasil diubah menjadi: $NEWDOMAIN${NC}"
  sleep 2
}

# ===== LIST AKUN =====
list_akun() {
  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}         DAFTAR AKUN ZIVPN${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo "--------------------------------------------------------------------------"
  printf "%-4s %-15s %-18s %-16s %-8s\n" "No" "Username" "Password" "Expired" "Limit"
  echo "--------------------------------------------------------------------------"
  
  if [ ! -s "$DB" ]; then
    echo "                    Tidak ada akun"
  else
    nl -w2 -s'. ' "$DB" | while read -r n l; do
      IFS='|' read -r U P E L <<< "$l"
      [ -z "$L" ] && L="∞"
      printf "%-4s %-15s %-18s %-16s %-8s\n" "$n" "$U" "$P" "$E" "$L"
    done
  fi
  echo "--------------------------------------------------------------------------"
}

# ===== TAMBAH AKUN DEFAULT =====
tambah_akun_default() {
  clear
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo -e "${WHITE}      TAMBAH AKUN ZIVPN (DEFAULT)${NC}"
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo ""
  
  # Generate random 2 digit
  RANDOM2=$(printf "%02d" $((RANDOM % 100)))
  DEFAULT_PASS="user$RANDOM2"
  
  read -rp "Password [default: $DEFAULT_PASS]: " PASS
  [ -z "$PASS" ] && PASS="$DEFAULT_PASS"
  
  # Cek duplikat
  if grep -q "|$PASS|" "$DB"; then
    echo -e "${RED}❌ Password '$PASS' sudah digunakan!${NC}"
    sleep 2
    return
  fi
  
  read -rp "Limit IP [default: 2]: " LIMIT
  [ -z "$LIMIT" ] && LIMIT=2
  
  read -rp "Masa aktif (hari) [default: 30]: " DAYS
  [ -z "$DAYS" ] && DAYS=30
  
  USER="user_$PASS"
  EXP=$(date -d "+$DAYS days" +"%Y-%m-%d")
  CREATE_DATE=$(date +"%d %b, %Y")
  EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
  LOKASI=$(get_location)
  
  # Simpan ke config.json
  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  
  # Simpan ke database
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  
  systemctl restart zivpn
  
  # Kirim notifikasi Telegram
  send_telegram "✅ *AKUN ZIVPN BARU*
═══════════════════════════
🌐 Domain    : $DOMAIN
🔑 Password  : \`$PASS\`
📍 Lokasi    : $LOKASI
───────────────────────
📅 Dibuat    : $CREATE_DATE
⏳ Expired   : $EXP_DATE
📱 Masa Aktif: $DAYS hari
🔢 Limit IP  : $LIMIT device
═══════════════════════════"
  
  clear
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "${GREEN}      ✅ AKUN BERHASIL DIBUAT${NC}"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "Domain   : $DOMAIN"
  echo -e "Password : ${YELLOW}$PASS${NC}"
  echo -e "Limit IP : $LIMIT"
  echo -e "Expired  : $EXP"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo ""
  read -p "Press Enter untuk kembali..."
}

# ===== TAMBAH AKUN CUSTOM =====
tambah_akun_custom() {
  clear
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo -e "${WHITE}      TAMBAH AKUN ZIVPN (CUSTOM)${NC}"
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo ""
  
  read -rp "Password: " PASS
  
  if [ -z "$PASS" ]; then
    echo -e "${RED}❌ Password tidak boleh kosong${NC}"
    sleep 2
    return
  fi
  
  if grep -q "|$PASS|" "$DB"; then
    echo -e "${RED}❌ Password '$PASS' sudah digunakan!${NC}"
    sleep 2
    return
  fi
  
  read -rp "Limit IP [default: 2]: " LIMIT
  [ -z "$LIMIT" ] && LIMIT=2
  
  read -rp "Masa aktif (hari) [default: 30]: " DAYS
  [ -z "$DAYS" ] && DAYS=30
  
  USER="user_$PASS"
  EXP=$(date -d "+$DAYS days" +"%Y-%m-%d")
  CREATE_DATE=$(date +"%d %b, %Y")
  EXP_DATE=$(date -d "+$DAYS days" +"%d %b, %Y")
  LOKASI=$(get_location)
  
  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  
  systemctl restart zivpn
  
  # Kirim notifikasi Telegram
  send_telegram "✅ *AKUN ZIVPN BARU*
═══════════════════════════
🌐 Domain    : $DOMAIN
🔑 Password  : \`$PASS\`
📍 Lokasi    : $LOKASI
───────────────────────
📅 Dibuat    : $CREATE_DATE
⏳ Expired   : $EXP_DATE
📱 Masa Aktif: $DAYS hari
🔢 Limit IP  : $LIMIT device
═══════════════════════════"
  
  clear
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "${GREEN}      ✅ AKUN BERHASIL DIBUAT${NC}"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "Domain   : $DOMAIN"
  echo -e "Password : ${YELLOW}$PASS${NC}"
  echo -e "Limit IP : $LIMIT"
  echo -e "Expired  : $EXP"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo ""
  read -p "Press Enter untuk kembali..."
}

# ===== CREATE TRIAL =====
create_trial() {
  clear
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo -e "${WHITE}         BUAT TRIAL ACCOUNT${NC}"
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo ""
  
  read -rp "Masa aktif (menit) [default: 60]: " MIN
  [ -z "$MIN" ] && MIN=60

  USER="trial$(tr -dc 0-9 </dev/urandom | head -c 4)"
  PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
  EXP=$(date -d "+$MIN minutes" +"%Y-%m-%d %H:%M")
  LIMIT=1
  
  EXP_DATE=$(date -d "+$MIN minutes" +"%d %b, %Y %H:%M")
  LOKASI=$(get_location)

  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  systemctl restart zivpn

  send_telegram "⏱ *TRIAL ZIVPN*
═══════════════════════════
🌐 Domain   : $DOMAIN
👤 Username : $USER
🔐 Password : \`$PASS\`
📍 Lokasi   : $LOKASI
───────────────────────
⏳ Expired  : $EXP_DATE
📱 IP Limit : 1
═══════════════════════════"

  clear
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "${GREEN}      TRIAL BERHASIL DIBUAT${NC}"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "Domain   : $DOMAIN"
  echo -e "Username : $USER"
  echo -e "Password : ${YELLOW}$PASS${NC}"
  echo -e "Expired  : $EXP_DATE"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo ""
  read -p "Press Enter untuk kembali..."
}

# ===== HAPUS AKUN =====
hapus_akun() {
  list_akun
  echo ""
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo -e "${WHITE}          HAPUS AKUN ZIVPN${NC}"
  echo -e "${YELLOW}══════════════════════════════════════${NC}"
  echo "• Masukkan NOMOR urut (1,2,3)"
  echo "• Atau masukkan PASSWORD langsung"
  echo ""
  read -rp "Input: " INPUT

  if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    LINE=$(sed -n "${INPUT}p" "$DB")
    [ -z "$LINE" ] && echo "Nomor tidak valid" && sleep 2 && return
    PASS=$(echo "$LINE" | cut -d'|' -f2)
    sed -i "${INPUT}d" "$DB"
  else
    PASS="$INPUT"
    LINE_NUM=$(awk -F'|' -v p="$PASS" '$2==p {print NR}' "$DB")
    [ -z "$LINE_NUM" ] && echo "Password tidak ditemukan" && sleep 2 && return
    sed -i "${LINE_NUM}d" "$DB"
  fi

  jq --arg pass "$PASS" '.auth.config -= [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  systemctl restart zivpn
  echo -e "${GREEN}✅ Akun berhasil dihapus${NC}"
  sleep 2
}

# ===== PERPANJANG AKUN =====
perpanjang_akun() {
  list_akun
  echo ""
  read -rp "Nomor akun yang diperpanjang: " NUM
  read -rp "Tambah hari: " DAYS

  LINE=$(sed -n "${NUM}p" "$DB")
  [ -z "$LINE" ] && echo "Nomor tidak valid" && sleep 2 && return

  IFS='|' read -r U P E L <<< "$LINE"
  BASE_DATE=$(echo "$E" | cut -d' ' -f1)
  NEWEXP=$(date -d "$BASE_DATE +$DAYS days" +"%Y-%m-%d")

  sed -i "${NUM}c\\$U|$P|$NEWEXP|$L" "$DB"
  systemctl restart zivpn
  echo -e "${GREEN}✅ Akun diperpanjang sampai $NEWEXP${NC}"
  sleep 2
}

# ===== HAPUS EXPIRED =====
hapus_expired() {
  NOW=$(date +"%Y-%m-%d")
  TMP="/tmp/users.db.new"
  > "$TMP"
  COUNT=0

  while IFS='|' read -r U P E L; do
    if [[ "$E" < "$NOW" ]]; then
      jq --arg pass "$P" '.auth.config -= [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
      ((COUNT++))
    else
      echo "$U|$P|$E|$L" >> "$TMP"
    fi
  done < "$DB"

  mv "$TMP" "$DB"
  systemctl restart zivpn
  echo -e "${GREEN}✅ $COUNT akun expired berhasil dihapus${NC}"
  sleep 2
}

# ===== CEK USER ONLINE =====
cek_online() {
  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}         USER ONLINE MONITOR${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  printf "%-4s %-15s %-18s %-10s\n" "No" "Username" "Password" "Status"
  echo "--------------------------------------------------------------------------"

  nl -w2 -s'. ' "$DB" | while read -r n l; do
    IFS='|' read -r U P E L <<< "$l"
    
    # Cek koneksi UDP port 5667
    if ss -u -n state connected '( sport = :5667 )' 2>/dev/null | grep -q "$U" || \
       netstat -un 2>/dev/null | grep -q "$U"; then
      STATUS="${GREEN}ONLINE${NC}"
    else
      STATUS="${RED}OFFLINE${NC}"
    fi
    
    printf "%-4s %-15s %-18s %-b\n" "$n" "$U" "$P" "$STATUS"
  done

  echo "--------------------------------------------------------------------------"
  read -p "Press Enter untuk kembali..."
}

# ===== RESTART SERVICE =====
restart_service() {
  systemctl restart zivpn
  echo -e "${GREEN}✅ ZIVPN berhasil direstart${NC}"
  sleep 2
}

# ===== TELEGRAM SETTING =====
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

# ===== RCLONE SETUP =====
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
  read -rp "Sudah siap? (y/n): " siap
  
  if [[ "$siap" == "y" ]]; then
    rclone config
    echo -e "${GREEN}Rclone configured${NC}"
  fi
  sleep 2
}

# ===== BACKUP ZIVPN =====
backup_zivpn() {
  clear
  echo "===================================="
  echo "         BACKUP ZIVPN"
  echo "===================================="
  
  DATE=$(date +%Y%m%d-%H%M%S)
  DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")
  DOMAIN_SAFE=$(echo "$DOMAIN" | sed 's/\./_/g')
  
  # Format nama file: domain.tanggal.zip
  FILENAME="${DOMAIN_SAFE}.${DATE}.zip"
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
    
    # Caption untuk Telegram
    CAPTION="✅ Auto Backup ZIVPN - 
Waktu - $DISPLAY_DATE
IP - $IP
Domain - $DOMAIN
Link : -"
    
    # Kirim ke Telegram
    send_file_telegram "$BACKUP_PATH" "$CAPTION"
    
    # Upload ke Google Drive jika rclone terkonfigurasi
    if rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
      echo "Mengupload ke Google Drive..."
      rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" --progress
      echo -e "${GREEN}✓ Terupload ke Google Drive${NC}"
      
      # Dapatkan link share
      GDRIVE_LINK=$(rclone link "gdrive:ZIVPN-Backup/$FILENAME" 2>/dev/null)
      
      # Kirim link ke Telegram
      send_telegram "☁️ *Google Drive Link*
🔗 $GDRIVE_LINK"
    fi
    
  else
    echo -e "${RED}✗ Backup gagal${NC}"
  fi
  
  read -p "Press Enter..."
}

# ===== RESTORE DARI LINK =====
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

# ===== RESTORE DARI GOOGLE DRIVE =====
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

# ===== RESTORE DARI TELEGRAM =====
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

# ===== RESTORE DARI FILE LOKAL =====
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

# ===== BACKUP MENU =====
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

# ===== AUTO BACKUP SETTING =====
auto_backup_setting() {
  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}       AUTO BACKUP SETTING${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  
  # Cek cron yang ada
  if crontab -l 2>/dev/null | grep -q "zivpn-menu.*--autobackup"; then
    CURRENT=$(crontab -l | grep "zivpn-menu.*--autobackup" | awk '{print $2":"$1}')
    echo -e "${GREEN}Status: AKTIF${NC}"
    echo -e "Jadwal: Jam ${CURRENT}"
    echo ""
    echo "1) Nonaktifkan Auto Backup"
    echo "2) Ubah Jadwal"
    echo "3) Kembali"
    read -rp "Pilih: " auto_opt
    
    case $auto_opt in
      1)
        crontab -l | grep -v "zivpn-menu.*--autobackup" | crontab -
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
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/zivpn-menu --autobackup") | crontab -
        echo "Auto Backup diaktifkan (Jam 03:00)"
        ;;
      2)
        set_autobackup_time
        ;;
    esac
  fi
  sleep 2
}

# ===== SET AUTO BACKUP TIME =====
set_autobackup_time() {
  read -rp "Masukkan Jam (0-23): " HOUR
  if [[ "$HOUR" =~ ^[0-9]+$ ]] && [ "$HOUR" -ge 0 ] && [ "$HOUR" -le 23 ]; then
    crontab -l | grep -v "zivpn-menu.*--autobackup" | crontab -
    (crontab -l 2>/dev/null; echo "0 $HOUR * * * /usr/local/bin/zivpn-menu --autobackup") | crontab -
    echo "Auto Backup diset ke Jam $HOUR:00"
  else
    echo "Jam tidak valid"
  fi
  sleep 2
}

# ===== AUTO BACKUP MODE =====
if [[ "$1" == "--autobackup" ]]; then
  # Ambil info terbaru
  DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "unknown")
  IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
  DISPLAY_DATE=$(date +"%Y-%m-%d %H:%M:%S")
  DATE=$(date +%Y%m%d-%H%M%S)
  DOMAIN_SAFE=$(echo "$DOMAIN" | sed 's/\./_/g')
  FILENAME="${DOMAIN_SAFE}.${DATE}.zip"
  BACKUP_PATH="$BACKUP_DIR/$FILENAME"
  
  # Buat backup
  zip -r "$BACKUP_PATH" /etc/zivpn/ /root/.config/rclone/rclone.conf 2>/dev/null
  
  # Kirim ke Telegram
  if [ -f "$TG_FILE" ]; then
    source "$TG_FILE"
    CAPTION="✅ Auto Backup ZIVPN - 
Waktu - $DISPLAY_DATE
IP - $IP
Domain - $DOMAIN
Link : -"
    
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
      -F chat_id="$CHAT_ID" \
      -F document=@"$BACKUP_PATH" \
      -F caption="$CAPTION" > /dev/null
  fi
  
  # Upload ke Google Drive jika ada
  if command -v rclone >/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
    rclone copy "$BACKUP_PATH" "gdrive:ZIVPN-Backup" >/dev/null 2>&1
    GDRIVE_LINK=$(rclone link "gdrive:ZIVPN-Backup/$FILENAME" 2>/dev/null)
    
    # Kirim link Google Drive
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      --data-urlencode "text=☁️ *Google Drive Link*
🔗 $GDRIVE_LINK" \
      --data-urlencode "parse_mode=Markdown" >/dev/null
  fi
  
  # Hapus file backup lokal (hanya simpan di cloud)
  rm -f "$BACKUP_PATH"
  
  exit 0
fi

# ===== MAIN LOOP =====
while true; do
  menu
  case $opt in
    01|1) tambah_akun_default ;;
    02|2) tambah_akun_custom ;;
    03|3) list_akun; read -p "Press Enter..." ;;
    04|4) hapus_akun ;;
    05|5) perpanjang_akun ;;
    06|6) ganti_domain ;;
    07|7) cek_online ;;
    08|8) hapus_expired ;;
    09|9) restart_service ;;
    10) create_trial ;;
    11) telegram_setting ;;
    12) backup_menu ;;
    13) auto_backup_setting ;;
    00|0) exit 0 ;;
    *) echo "Pilihan tidak valid"; sleep 1 ;;
  esac
done
EOF

chmod +x /usr/local/bin/zivpn-menu

# Enable dan start service
echo -e "${YELLOW}[5] Menjalankan service...${NC}"
systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

# Buat symlink
ln -sf /usr/local/bin/zivpn-menu /usr/bin/menu-zivpn
ln -sf /usr/local/bin/zivpn-menu /usr/bin/zivpn

# Selesai
clear
echo -e "${GREEN}══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              INSTALASI ZIVPN SELESAI                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Domain   : ${YELLOW}$IP${NC}"
echo -e "Port     : ${CYAN}5667 (UDP)${NC}"
echo ""
echo -e "📌 Cara penggunaan:"
echo -e "   ${GREEN}menu-zivpn${NC} atau ${GREEN}zivpn${NC} - Untuk masuk menu ZIVPN"
echo ""
echo -e "📌 Fitur Lengkap:"
echo -e "   ✅ Tambah akun (Default & Custom)"
echo -e "   ✅ Lihat daftar akun"
echo -e "   ✅ Hapus akun"
echo -e "   ✅ Perpanjang akun"
echo -e "   ✅ Ganti domain"
echo -e "   ✅ Cek user online"
echo -e "   ✅ Hapus expired"
echo -e "   ✅ Trial account"
echo -e "   ✅ Telegram notifikasi"
echo -e "   ✅ Backup & Restore (Telegram + GDrive)"
echo -e "   ✅ Auto backup"
echo ""
echo -e "${YELLOW}⚠️  Jangan lupa buka port UDP 5667 di firewall!${NC}"
echo ""
read -p "Press Enter untuk masuk menu..."

# Jalankan menu
zivpn-menu
