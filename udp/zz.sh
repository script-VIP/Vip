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
apt install -y wget curl unzip zip jq openssl net-tools ss

# Download dan install ZIVPN
echo -e "${YELLOW}[3] Menginstall ZIVPN...${NC}"
wget -q -O /tmp/zivpn.zip "https://github.com/script-VIP/Vip/raw/main/zivpn.zip"
unzip -o /tmp/zivpn.zip -d /etc/zivpn/ >/dev/null 2>&1
chmod +x /etc/zivpn/zivpn

# Buat config directory
mkdir -p /etc/zivpn
touch /etc/zivpn/users.db
touch /etc/zivpn/domain.conf

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

# Download menu script
echo -e "${YELLOW}[4] Menginstall menu ZIVPN...${NC}"
cat > /usr/local/bin/zivpn-menu <<'EOF'
#!/bin/bash
# ZIVPN Menu Script
CONFIG="/etc/zivpn/config.json"
DB="/etc/zivpn/users.db"
DOMAIN_FILE="/etc/zivpn/domain.conf"
DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "-")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ===== FUNGSI GANTI DOMAIN =====
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
  
  # Simpan ke config.json
  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  
  # Simpan ke database
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  
  systemctl restart zivpn
  
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
  
  jq --arg pass "$PASS" '.auth.config += [$pass]' "$CONFIG" > /tmp/z.json && mv /tmp/z.json "$CONFIG"
  echo "$USER|$PASS|$EXP|$LIMIT" >> "$DB"
  
  systemctl restart zivpn
  
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

# ===== CEK STATUS =====
cek_status() {
  clear
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  echo -e "${WHITE}         STATUS ZIVPN${NC}"
  echo -e "${CYAN}══════════════════════════════════════${NC}"
  
  STATUS=$(systemctl is-active zivpn)
  if [ "$STATUS" = "active" ]; then
    echo -e "Service   : ${GREEN}● ACTIVE${NC}"
  else
    echo -e "Service   : ${RED}○ INACTIVE${NC}"
  fi
  
  echo -e "Domain    : ${YELLOW}$DOMAIN${NC}"
  echo -e "Port      : ${CYAN}5667 (UDP)${NC}"
  echo -e "Total Akun: $(grep -c '|' "$DB" 2>/dev/null)"
  
  echo ""
  systemctl status zivpn --no-pager
  echo ""
  read -p "Press Enter untuk kembali..."
}

# ===== MAIN MENU =====
while true; do
  clear
  TOTAL_AKUN=$(grep -c '|' "$DB" 2>/dev/null)
  STATUS_SERVICE=$(systemctl is-active zivpn 2>/dev/null)
  
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║              ZIVPN UDP MANAGER - COMPLETE EDITION           ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${WHITE}Domain    :${NC} ${GREEN}$DOMAIN${NC}"
  echo -e "  ${WHITE}Status    :${NC} $([ "$STATUS_SERVICE" = "active" ] && echo "${GREEN}● ACTIVE${NC}" || echo "${RED}○ INACTIVE${NC}")"
  echo -e "  ${WHITE}Total Akun:${NC} ${YELLOW}$TOTAL_AKUN${NC}"
  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${YELLOW}[1]${NC} ➕  Tambah Akun (Default 2 digit)"
  echo -e "  ${YELLOW}[2]${NC} 🔑  Tambah Akun (Custom Password)"
  echo -e "  ${YELLOW}[3]${NC} 📋  Lihat Daftar Akun"
  echo -e "  ${YELLOW}[4]${NC} 🗑️  Hapus Akun"
  echo -e "  ${YELLOW}[5]${NC} 📅  Perpanjang Akun"
  echo -e "  ${YELLOW}[6]${NC} 🌐  Ganti Domain"
  echo -e "  ${YELLOW}[7]${NC} 👥  Cek User Online"
  echo -e "  ${YELLOW}[8]${NC} 🧹  Hapus Semua Expired"
  echo -e "  ${YELLOW}[9]${NC} 🔄  Restart Service"
  echo -e "  ${YELLOW}[10]${NC} 📊  Status Service"
  echo -e "  ${YELLOW}[0]${NC} 🚪  Exit"
  echo ""
  echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  read -rp "  Pilih Menu [0-10] : " menu
  
  case $menu in
    1) tambah_akun_default ;;
    2) tambah_akun_custom ;;
    3) list_akun; read -p "Press Enter..." ;;
    4) hapus_akun ;;
    5) perpanjang_akun ;;
    6) ganti_domain ;;
    7) cek_online ;;
    8) hapus_expired ;;
    9) restart_service ;;
    10) cek_status ;;
    0) exit 0 ;;
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
echo -e "📌 Fitur:"
echo -e "   ✅ Tambah akun (Default & Custom)"
echo -e "   ✅ Lihat daftar akun"
echo -e "   ✅ Hapus akun"
echo -e "   ✅ Perpanjang akun"
echo -e "   ✅ Ganti domain"
echo -e "   ✅ Cek user online"
echo -e "   ✅ Hapus expired"
echo -e "   ✅ Restart service"
echo -e "   ✅ Status service"
echo ""
echo -e "${YELLOW}⚠️  Jangan lupa buka port UDP 5667 di firewall!${NC}"
echo ""
read -p "Press Enter untuk masuk menu..."

# Jalankan menu
zivpn-menu
