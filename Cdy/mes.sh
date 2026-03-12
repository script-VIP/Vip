#!/bin/bash
clear
red() { echo -e "\\033[32;1m${*}\\033[0m"; }
clear

# IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
echo -e "\e[32mloading...\e[0m"
clear
red() { echo -e "\\033[32;1m${*}\\033[0m"; }

# Get Bot
CHATID=$(grep -E "^#bot# " "/etc/bot/.bot.db" | cut -d ' ' -f 3)
KEY=$(grep -E "^#bot# " "/etc/bot/.bot.db" | cut -d ' ' -f 2)
export TIME="10"
export URL="https://api.telegram.org/bot$KEY/sendMessage"
clear

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")
data_ip="https://raw.githubusercontent.com/script-VIP/izin/main/ip"
checking_sc() {
  useexp=$(wget -qO- $data_ip | grep $ipsaya | awk '{print $3}')
  if [[ $date_list < $useexp ]]; then
    echo -ne
  else
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e "\033[42m          404 NOT FOUND AUTOSCRIPT          \033[0m"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    echo -e ""
    echo -e "            \033[91;1mPERMISSION DENIED !\033[0m"
    echo -e "   \033[0;33mYour VPS\033[0m $ipsaya \033[0;33mHas been Banned\033[0m"
    echo -e "     \033[0;33mBuy access permissions for scripts\033[0m"
    echo -e "             \033[0;33mContact Admin :\033[0m"
    echo -e "      \033[2;32mWhatsApp\033[0m wa.me/628981874211"
    echo -e "      \033[2;32mTelegram\033[0m t.me/AimanVpnExpress"
    echo -e "\033[1;93m────────────────────────────────────────────\033[0m"
    exit
  fi
}
checking_sc
clear
export TIME="10"
IP=$(curl -sS ipv4.icanhazip.com)
ISP=$(cat /etc/xray/isp)
CITY=$(cat /etc/xray/city)
domain=$(cat /etc/xray/domain)
nama=$(cat /etc/xray/username)
clear

# Function baris
function baris_panjang() {
  echo -e "\033[5;36m ◇━━━━━━━━━━━━━━━◇ \033[0m"
}

function Lunatic_Banner() {
  clear
  echo -e "\033[95;1m $nama           \033[0m"
  baris_panjang
}

# Loading function
loading() {
  local pid=$1
  local delay=0.1
  local spin='-\|/'

  while ps -p $pid > /dev/null; do
    local temp=${spin#?}
    printf "[%c] " "$spin"
    local spin=$temp${spin%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done

  printf "    \b\b\b\b\b\b"
}

# =============================================
#  CREATE MASS SSH ACCOUNTS (PASSWORD 1 UNTUK SEMUA)
# =============================================
create_mass_ssh() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      CREATE MASS SSH ACCOUNTS"
  echo -e "   ————————————————————————"
  echo -e ""
  echo -e "Cara input:"
  echo -e "  1. Masukkan PASSWORD untuk semua user (1 password)"
  echo -e "  2. Masukkan LIMIT IP untuk semua user"
  echo -e "  3. Masukkan LIMIT QUOTA untuk semua user (GB)"
  echo -e "  4. Input user: ${YELLOW}username masaaktif${NC}"
  echo -e "  5. Ketik ${GREEN}selesai${NC} untuk mengakhiri"
  echo -e ""
  echo -e "Contoh:"
  echo -e "  Password    : 123"
  echo -e "  Limit IP    : 2"
  echo -e "  Limit Quota : 10"
  echo -e "  user1 30"
  echo -e "  user2 45"
  echo -e "  user3 60"
  echo -e "  selesai"
  echo -e ""
  
  # Input password global
  read -p "  Password untuk semua user : " global_pass
  if [[ -z "$global_pass" ]]; then
    echo -e "\033[91;1mPassword tidak boleh kosong!\033[0m"
    sleep 2
    create_mass_ssh
    return
  fi
  
  # Input limit IP global
  read -p "  Limit IP untuk semua user (0=unlimited) : " global_iplimit
  if ! [[ "$global_iplimit" =~ ^[0-9]+$ ]]; then
    echo -e "\033[91;1mLimit IP harus angka!\033[0m"
    sleep 2
    create_mass_ssh
    return
  fi
  
  # Input limit quota global
  read -p "  Limit Quota untuk semua user (GB, 0=unlimited) : " global_quota
  if ! [[ "$global_quota" =~ ^[0-9]+$ ]]; then
    echo -e "\033[91;1mLimit Quota harus angka!\033[0m"
    sleep 2
    create_mass_ssh
    return
  fi
  
  echo -e ""
  echo -e "\033[32;1m✓ Password: $global_pass\033[0m"
  echo -e "\033[32;1m✓ Limit IP: $([ "$global_iplimit" == "0" ] && echo "Unlimited" || echo "$global_iplimit Device")\033[0m"
  echo -e "\033[32;1m✓ Limit Quota: $([ "$global_quota" == "0" ] && echo "Unlimited" || echo "$global_quota GB")\033[0m"
  echo -e ""
  echo -e "Silahkan input user (username masaaktif):"
  echo -e ""
  
  # Arrays untuk menyimpan hasil
  local created_users=()
  local failed_users=()
  local success=0
  local failed=0
  
  while true; do
    read -p "  Input: " input
    
    if [[ "$input" == "selesai" ]]; then
      break
    fi
    
    if [[ -z "$input" ]]; then
      continue
    fi
    
    # Parse input (username masaaktif)
    local arr=($input)
    if [[ ${#arr[@]} -lt 2 ]]; then
      echo -e "    \033[91;1m✗ Format salah! Gunakan: username masaaktif\033[0m"
      ((failed++))
      failed_users+=("$input (format salah)")
      continue
    fi
    
    local Login="${arr[0]}"
    local masaaktif="${arr[1]}"
    
    # Validasi masaaktif harus angka
    if ! [[ "$masaaktif" =~ ^[0-9]+$ ]]; then
      echo -e "    \033[91;1m✗ Masa aktif harus angka!\033[0m"
      ((failed++))
      failed_users+=("$Login (masa aktif bukan angka)")
      continue
    fi
    
    # Cek apakah username sudah ada
    if id "$Login" &>/dev/null; then
      echo -e "    \033[91;1m✗ Username $Login sudah ada!\033[0m"
      ((failed++))
      failed_users+=("$Login (username sudah ada)")
      continue
    fi
    
    # Buat user dengan password yang sama
    useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login
    echo -e "$global_pass\n$global_pass\n" | passwd $Login &> /dev/null
    
    # Set limit IP
    if [[ $global_iplimit -gt 0 ]]; then
      mkdir -p /etc/kyt/limit/ssh/ip/
      echo -e "$global_iplimit" > /etc/kyt/limit/ssh/ip/$Login
    fi
    
    # Set limit Quota
    if [[ $global_quota -gt 0 ]]; then
      local quota_bytes=$(($global_quota * 1024 * 1024 * 1024))
      echo "$quota_bytes" > /etc/ssh/${Login}
    fi
    
    # Simpan ke database
    mkdir -p /etc/ssh
    touch /etc/ssh/.ssh.db
    
    local expi=$(date -d "$masaaktif days" +"%Y-%m-%d")
    
    # Cek apakah sudah ada di database
    if grep -q "^#ssh#.*${Login}" /etc/ssh/.ssh.db; then
      sed -i "/\b${Login}\b/d" /etc/ssh/.ssh.db
    fi
    
    echo "#ssh# ${Login} ${global_pass} ${global_quota} ${global_iplimit} ${expi}" >> /etc/ssh/.ssh.db
    
    echo -e "    \033[32;1m✓ ${Login} (${masaaktif} hari, Limit: $([ "$global_iplimit" == "0" ] && echo "Unlimited" || echo "$global_iplimit IP"), Quota: $([ "$global_quota" == "0" ] && echo "Unlimited" || echo "$global_quota GB")\033[0m"
    
    created_users+=("$Login|$masaaktif")
    ((success++))
  done
  
  echo -e ""
  
  if [[ $success -gt 0 ]]; then
    # Tampilkan ringkasan
    echo -e "\033[5;36m ◇━━━━━━━━━━━━━━━◇ \033[0m"
    echo -e "\033[37;1;7m    BERHASIL MEMBUAT $success AKUN    \033[0m"
    echo -e "\033[5;36m ◇━━━━━━━━━━━━━━━◇ \033[0m"
    echo -e ""
    echo -e "PASSWORD UNTUK SEMUA USER: \033[32;1m$global_pass\033[0m"
    echo -e "────────────────────────────────"
    echo -e "DAFTAR USERNAME:"
    echo -e "────────────────────"
    for user_data in "${created_users[@]}"; do
      IFS='|' read -r user days <<< "$user_data"
      echo -e "  $user - $days hari"
    done
    echo -e "────────────────────"
    echo -e "Limit IP   : $([ "$global_iplimit" == "0" ] && echo "Unlimited" || echo "$global_iplimit Device")"
    echo -e "Limit Quota: $([ "$global_quota" == "0" ] && echo "Unlimited" || echo "$global_quota GB")"
    echo -e "\033[5;36m ◇━━━━━━━━━━━━━━━◇ \033[0m"
    echo -e ""
    
    # Kirim notifikasi ke Telegram
    local tgl=$(date +"%d %b, %Y")
    
    local list_user=""
    for user_data in "${created_users[@]}"; do
      IFS='|' read -r user days <<< "$user_data"
      list_user="$list_user\n- $user ($days hari)"
    done
    
    local TEKS_NOTIF="
◇━━━━━━━━━━━━━━━━━◇
*MASS CREATE SSH BERHASIL*
◇━━━━━━━━━━━━━━━━━◇
Total    : $success Akun
Password : \`$global_pass\`
Limit IP : $([ "$global_iplimit" == "0" ] && echo "Unlimited" || echo "$global_iplimit Device")
Limit Quota : $([ "$global_quota" == "0" ] && echo "Unlimited" || echo "$global_quota GB")
Server   : $CITY - $ISP
Domain   : $domain
Tanggal  : $tgl
◇━━━━━━━━━━━━━━━━━◇
*DAFTAR USERNAME:* $list_user
◇━━━━━━━━━━━━━━━━━◇
$nama"
    
    curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEKS_NOTIF&parse_mode=markdown" $URL >/dev/null
  fi
  
  if [[ $failed -gt 0 ]]; then
    echo -e "\033[91;1m✗ Gagal: $failed akun\033[0m"
    for failed in "${failed_users[@]}"; do
      echo -e "    • $failed"
    done
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Tekan enter untuk kembali ke menu..."
  m-ssh
}

# =============================================
#  CREATE SINGLE SSH ACCOUNT
# =============================================
create_single_ssh() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      CREATE SSH ACCOUNT"
  echo -e "   ————————————————————————"
  echo -e ""
  
  read -p "  Username    : " Login
  read -p "  Password    : " Pass
  read -p "  Limit IP    : " iplimit
  read -p "  Limit Quota (GB) : " Quota
  read -p "  Active For  : " masaaktif
  echo ""
  echo -e "\033[2;32mCreate.....\033[0m"
  
  # Validasi
  if [[ -z "$Login" || -z "$Pass" || -z "$iplimit" || -z "$Quota" || -z "$masaaktif" ]]; then
    echo -e "\033[91;1mSemua field harus diisi!\033[0m"
    sleep 2
    create_single_ssh
    return
  fi
  
  if ! [[ "$iplimit" =~ ^[0-9]+$ ]] || ! [[ "$Quota" =~ ^[0-9]+$ ]] || ! [[ "$masaaktif" =~ ^[0-9]+$ ]]; then
    echo -e "\033[91;1mLimit IP, Quota dan masa aktif harus angka!\033[0m"
    sleep 2
    create_single_ssh
    return
  fi
  
  if id "$Login" &>/dev/null; then
    echo -e "\033[91;1mUsername $Login sudah ada!\033[0m"
    sleep 2
    create_single_ssh
    return
  fi
  
  # Buat user
  useradd -e $(date -d "$masaaktif days" +"%Y-%m-%d") -s /bin/false -M $Login
  echo -e "$Pass\n$Pass\n" | passwd $Login &> /dev/null
  
  # Set limit IP
  if [[ $iplimit -gt 0 ]]; then
    mkdir -p /etc/kyt/limit/ssh/ip/
    echo -e "$iplimit" > /etc/kyt/limit/ssh/ip/$Login
  fi
  
  # Set limit Quota
  if [[ $Quota -gt 0 ]]; then
    local quota_bytes=$(($Quota * 1024 * 1024 * 1024))
    echo "$quota_bytes" > /etc/ssh/${Login}
  fi
  
  # Simpan ke database
  mkdir -p /etc/ssh
  touch /etc/ssh/.ssh.db
  
  local expi=$(date -d "$masaaktif days" +"%Y-%m-%d")
  
  if grep -q "^#ssh#.*${Login}" /etc/ssh/.ssh.db; then
    sed -i "/\b${Login}\b/d" /etc/ssh/.ssh.db
  fi
  
  echo "#ssh# ${Login} ${Pass} ${Quota} ${iplimit} ${expi}" >> /etc/ssh/.ssh.db
  
  # Hitung tanggal
  tgl=$(date -d "$masaaktif days" +"%d")
  bln=$(date -d "$masaaktif days" +"%b")
  thn=$(date -d "$masaaktif days" +"%Y")
  expe="$tgl $bln, $thn"
  tgl2=$(date +"%d")
  bln2=$(date +"%b")
  thn2=$(date +"%Y")
  tnggl="$tgl2 $bln2, $thn2"
  
  clear
  
  # Kirim notifikasi ke Telegram
  TEXT="
━━━━━━━━━━━━━━━━━━
DETAIL SSH PREMIUM
━━━━━━━━━━━━━━━━━━
Username         :  $Login
Password         :  $Pass
━━━━━━━━━━━━━━━━━━
Host             : $domain
Port OpenSSH     : 443, 80, 22
Port Dropbear    : 443, 109
Port SSH WS      : 80, 8080, 8081-9999
Port SSH UDP     : 1-65535
Port SSH SSL WS  : 443
Port SSL/TLS     : 400-900
Port OVPN WS SSL : 443
Port OVPN SSL    : 443
Port OVPN TCP    : 443, 1194
Port OVPN UDP    : 2200
BadVPN UDP       : 7100, 7300, 7300
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH WS: <code>$domain:80@$Login:$Pass</code>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH SSL: <code>$domain:443@$Login:$Pass</code>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH UDP: <code>$domain:1-65535@$Login:$Pass</code>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVPN Download : https://$domain:81/
━━━━━━━━━━━━━━━━━━
Limit IP        : $iplimit Device
Limit Quota     : $Quota GB
Aktif Selama    : $masaaktif Hari
Dibuat Pada     : $tnggl
Berakhir Pada   : $expe
━━━━━━━━━━━━━━━━━━
"

  curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null

  TEXT2="<code>◇━━━━━━━━━━━━━━━━━◇
*_PEMBELIAN BERHASIL_*
◇━━━━━━━━━━━━━━━━━◇
-» PRODUK : SSH
-» REGION : $CITY
-» USER  : $Login
-» LIMIT IP : $iplimit
-» QUOTA : $Quota GB
-» AKTIF : $masaaktif HARI
-» TGL EXP : $expe
◇━━━━━━━━━━━━━━━━━◇
$nama </code>"
  
  curl -s --max-time $TIME -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT2&parse_mode=html" $URL >/dev/null
  
  # Tampilkan hasil
  echo -e " "
  echo -e " "
  echo -e " \033[37;1;7m TERIMAKASIH SUDAH ORDER KA 😇 \033[0m"
  baris_panjang
  echo -e " \033[37;1;7m Berikut Detail Akun SSH mu👇\033[0m"
  baris_panjang
  echo -e "\033[5;36m Username : $Login \033[0m"
  echo -e "\033[5;36m Password : $Pass \033[0m"
  echo -e "\033[5;36m Limit Ip : ${iplimit} Device \033[0m"
  echo -e "\033[5;36m Limit Quota : ${Quota} GB \033[0m"
  echo -e "\033[5;36m Domain   : $domain \033[0m"
  echo -e "\033[5;36m Server   : $CITY $ISP \033[0m "
  baris_panjang
  echo -e "\033[5;36m Ssh : $domain:80@$Login:$Pass \033[0m"
  echo -e "\033[5;36m Ssl : $domain:443@$Login:$Pass \033[0m"
  echo -e "\033[5;36m Udp : $domain:1-2200@$Login:$Pass\033[0m"
  baris_panjang
  echo -e "\033[33m Active For : $masaaktif Days \033[0m"
  echo -e "\033[33m Create On  : $tnggl \033[0m"
  echo -e "\033[33m Expired On : $expe \033[0m"
  baris_panjang
  echo -e "\033[5;36m Info Port & Payload : f62et.mssg.me/ \033[0m"
  echo -e " OpenVpn   : $domain:81/ "
  echo -e " Account   : $domain:81/ssh-$Login.txt "
  baris_panjang
  echo -e ""
  read -n 1 -s -r -p "Tekan enter untuk kembali ke menu..."
  m-ssh
}

# =============================================
#  MENU SSH
# =============================================
menu_ssh() {
  while true; do
    Lunatic_Banner
    echo -e "   ————————————————————————"
    echo -e "      MENU SSH ACCOUNTS"
    echo -e "   ————————————————————————"
    echo -e ""
    echo -e "  ${GREEN}1${NC}. Create Single SSH Account"
    echo -e "  ${GREEN}2${NC}. Create Mass SSH Accounts (1 Password)"
    echo -e "  ${CYAN}3${NC}. List SSH Users"
    echo -e "  ${RED}4${NC}. Delete SSH User"
    echo -e "  ${RED}5${NC}. Renew SSH User"
    echo -e "  ${RED}6${NC}. Check User Online"
    echo -e "  ${RED}0${NC}. Back to Main Menu"
    echo -e ""
    read -p "  Pilih menu : " choice
    
    case $choice in
      1) create_single_ssh ;;
      2) create_mass_ssh ;;
      3) list_ssh_users ;;
      4) delete_ssh_user ;;
      5) renew_ssh_user ;;
      6) check_ssh_online ;;
      0) m-ssh ;;
      *) echo -e "\033[91;1mPilihan tidak valid!\033[0m"; sleep 1 ;;
    esac
  done
}

# === LIST SSH USERS ===
list_ssh_users() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      LIST SSH USERS"
  echo -e "   ————————————————————————"
  echo -e ""
  
  if [[ ! -f /etc/ssh/.ssh.db ]] || [[ ! -s /etc/ssh/.ssh.db ]]; then
    echo -e "\033[33mBelum ada user SSH\033[0m"
    read -n 1 -s -r -p "Tekan enter untuk kembali..."
    menu_ssh
    return
  fi
  
  printf "%-15s %-10s %-10s %-10s %s\n" "USERNAME" "PASSWORD" "LIMIT IP" "QUOTA" "EXPIRED"
  echo -e "──────────────────────────────────────────────────"
  
  local today=$(date +%s)
  
  while read -r line; do
    if [[ "$line" =~ ^#ssh# ]]; then
      local user=$(echo "$line" | awk '{print $3}')
      local pass=$(echo "$line" | awk '{print $4}')
      local quota=$(echo "$line" | awk '{print $5}')
      local iplimit=$(echo "$line" | awk '{print $6}')
      local exp=$(echo "$line" | awk '{print $7}')
      
      local exp_epoch=$(date -d "$exp" +%s 2>/dev/null)
      local sisa=$(( (exp_epoch - today) / 86400 ))
      
      if [[ $sisa -lt 0 ]]; then
        printf "%-15s %-10s %-10s %-10s %s\n" "$user" "$pass" "$iplimit" "$quota GB" "Expired"
      else
        printf "%-15s %-10s %-10s %-10s %s\n" "$user" "$pass" "$iplimit" "$quota GB" "$sisa hari"
      fi
    fi
  done < /etc/ssh/.ssh.db
  
  echo -e "──────────────────────────────────────────────────"
  read -n 1 -s -r -p "Tekan enter untuk kembali..."
  menu_ssh
}

# === DELETE SSH USER ===
delete_ssh_user() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      DELETE SSH USER"
  echo -e "   ————————————————————————"
  echo -e ""
  
  read -p "  Username : " user
  
  if ! id "$user" &>/dev/null; then
    echo -e "\033[91;1mUser $user tidak ditemukan!\033[0m"
    sleep 2
    menu_ssh
    return
  fi
  
  userdel -f "$user"
  rm -f /etc/kyt/limit/ssh/ip/$user
  rm -f /etc/ssh/$user
  sed -i "/\b$user\b/d" /etc/ssh/.ssh.db
  
  echo -e "\033[32;1m✓ User $user berhasil dihapus\033[0m"
  sleep 2
  menu_ssh
}

# === RENEW SSH USER ===
renew_ssh_user() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      RENEW SSH USER"
  echo -e "   ————————————————————————"
  echo -e ""
  
  read -p "  Username : " user
  read -p "  Tambah hari : " days
  
  if ! id "$user" &>/dev/null; then
    echo -e "\033[91;1mUser $user tidak ditemukan!\033[0m"
    sleep 2
    menu_ssh
    return
  fi
  
  if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\033[91;1mHari harus angka!\033[0m"
    sleep 2
    menu_ssh
    return
  fi
  
  local current_exp=$(chage -l "$user" | grep "Account expires" | awk -F": " '{print $2}')
  local new_exp=$(date -d "$current_exp +$days days" +"%Y-%m-%d")
  
  usermod -e "$new_exp" "$user"
  
  # Update database
  sed -i "/\b$user\b/d" /etc/ssh/.ssh.db
  local pass=$(grep "$user" /etc/shadow | awk -F: '{print $2}')
  local quota=$(cat /etc/ssh/$user 2>/dev/null || echo "0")
  local iplimit=$(cat /etc/kyt/limit/ssh/ip/$user 2>/dev/null || echo "0")
  echo "#ssh# $user $pass $quota $iplimit $new_exp" >> /etc/ssh/.ssh.db
  
  echo -e "\033[32;1m✓ User $user diperpanjang $days hari\033[0m"
  sleep 2
  menu_ssh
}

# === CHECK SSH ONLINE ===
check_ssh_online() {
  Lunatic_Banner
  echo -e "   ————————————————————————"
  echo -e "      SSH ONLINE USERS"
  echo -e "   ————————————————————————"
  echo -e ""
  
  local online=$(netstat -tnpa | grep -E "ESTABLISHED.*sshd" | grep -v "127.0.0.1" | wc -l)
  
  if [[ $online -eq 0 ]]; then
    echo -e "\033[33mTidak ada user online\033[0m"
  else
    echo -e "Total: $online koneksi"
    echo -e ""
    echo -e "DETAIL:"
    netstat -tnpa | grep -E "ESTABLISHED.*sshd" | grep -v "127.0.0.1" | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | while read count ip; do
      echo -e "  $ip - $count koneksi"
    done
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Tekan enter untuk kembali..."
  menu_ssh
}

# === START ===
menu_ssh
