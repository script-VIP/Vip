#!/bin/bash

# Warna 
NC='\033[0m'
r='\033[1;91m'
g='\033[1;92m'
y='\033[1;93m'
u='\033[0;35m'
c='\033[0;96m'
w='\033[1;97m'

# Variabel Cloudflare
EMAILCF="imanfals51@gmail.com"
KEY="0f9ed4286475de79bae2b91e9af4f8af9fed9"

# Validasi token
if [[ -z "$EMAILCF" || -z "$KEY" ]]; then
  echo -e "${r}Email dan API Token tidak ditemukan!${NC}"
  exit 1
fi

mkdir -p /etc/.data /etc/.wc

# Inisialisasi file bug.txt dengan bug-bug lengkap
if [ ! -f /etc/.wc/bug.txt ] || [ ! -s /etc/.wc/bug.txt ]; then
  cat > /etc/.wc/bug.txt << 'EOF'
ava.game.naver.com
graph.instagram.com
investors.spotify.com
zaintest.vuclip.com
quiz.vidio.com
support.zoom.us
www.ruangguru.com
blog.webex.com
live.iflix.com
chat.sociomile.com
support.udemy.com
creativeservices.netflix.com
cf-vod.nimo.tv
www.genflix.co.id
poe.garena.com
ovo.id
midtrans.com
api24-normal.tiktokv.com
EOF
  echo -e "${g}File bug.txt telah diinisialisasi dengan bug default.${NC}"
fi

# Fungsi utilitas
get_account_id() {
  response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json")

  AKUNID=$(echo "$response" | jq -r '.result[0].id')
}

get_zone_id() {
  ZONE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json" | jq -r .result[0].id)
}

generate_random() {
  WORKER_NAME="$(tr -dc a-j0-9 </dev/urandom | head -c4)-$(tr -dc a-z0-9 </dev/urandom | head -c8)-$(tr -dc a-z0-9 </dev/urandom | head -c5)"
}

buat_worker() {
  generate_random
  get_account_id

  SCRIPT="
  addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
  })

  async function handleRequest(request) {
    return new Response('Hello World!', { status: 200 })
  }"

  URL="https://api.cloudflare.com/client/v4/accounts/$AKUNID/workers/scripts/$WORKER_NAME"

  curl -s -o /dev/null -X PUT \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/javascript" \
    --data "$SCRIPT" "$URL"

  echo "$WORKER_NAME"
}

hapus_worker() {
  get_account_id
  curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$AKUNID/workers/scripts/$1" \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" >/dev/null
}

pointing_cname() {
  domain_sub="$1"
  DOMAIN=$(echo "$domain_sub" | cut -d "." -f2-)
  SUB=$(echo "$domain_sub" | cut -d "." -f1)
  SUB_DOMAIN="*.${SUB}.${DOMAIN}"

  get_zone_id

  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${SUB_DOMAIN}" \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [[ "${#RECORD_ID}" -le 10 ]]; then
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
      -H "X-Auth-Email: $EMAILCF" \
      -H "X-Auth-Key: $KEY" \
      -H "Content-Type: application/json" \
      --data '{"type":"CNAME","name":"'${SUB_DOMAIN}'","content":"'${domain_sub}'","ttl":120,"proxied":false}' >/dev/null
  else
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD_ID}" \
      -H "X-Auth-Email: $EMAILCF" \
      -H "X-Auth-Key: $KEY" \
      -H "Content-Type: application/json" \
      --data '{"type":"CNAME","name":"'${SUB_DOMAIN}'","content":"'${domain_sub}'","ttl":120,"proxied":false}' >/dev/null
  fi
}

add_domain_worker() {
  get_account_id
  DATA=$(cat <<EOF
{
  "hostname": "$2",
  "service": "$1",
  "environment": "production"
}
EOF
)

  curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$AKUNID/workers/domains/records" \
    -H "X-Auth-Email: $EMAILCF" \
    -H "X-Auth-Key: $KEY" \
    -H "Content-Type: application/json" \
    -d "$DATA" >/dev/null
}

add_wc() {
  read -p "Masukkan domain utama (tanpa bug): " domain
  [[ -z "$domain" || "$domain" == "x" ]] && echo "Dibatalkan." && return

  echo "Membuat worker..."
  worker=$(buat_worker)
  echo "Worker: $worker"

  echo "Pointing CNAME *.${domain} ..."
  pointing_cname "$domain"

  echo "Menambahkan bug ke worker..."
  if [[ ! -f /etc/.wc/bug.txt ]]; then
    echo -e "${r}File bug.txt tidak ditemukan!${NC}"
    return
  fi

  while IFS= read -r bug; do
    [[ -z "$bug" ]] && continue
    add_domain_worker "$worker" "${bug}.${domain}"
    echo "✓ ${bug}.${domain}"
  done < /etc/.wc/bug.txt

  echo "Menghapus worker setelah assign domain..."
  hapus_worker "$worker"

  echo -e "${g}Selesai pointing wildcard untuk domain: $domain${NC}"
}

edit_bug() {
  echo -e "${y}Edit daftar bug (gunakan nano):${NC}"
  echo -e "${c}Silahkan tambah bug dibawah kalo udah ctrl x y enter${NC}"
  echo
  nano /etc/.wc/bug.txt
}

view_bug() {
  echo -e "${y}Daftar bug saat ini:${NC}"
  echo -e "${c}=================================${NC}"
  if [ -f /etc/.wc/bug.txt ] && [ -s /etc/.wc/bug.txt ]; then
    cat /etc/.wc/bug.txt
  else
    echo -e "${r}Tidak ada bug yang terdaftar${NC}"
  fi
  echo -e "${c}=================================${NC}"
  echo -e "${g}Total bug: $(wc -l < /etc/.wc/bug.txt)${NC}"
  echo
  read -p "Tekan Enter untuk kembali ke menu..."
}

BIRU="\033[38;2;0;191;255m"
HIJAU="\033[38;2;173;255;47m"
PUTIH="\033[38;2;255;255;255m"
CYANS="\033[38;2;35;235;195m"
GOLD="\033[38;2;255;215;0m"
RESET="\033[0m"

main_menu() {
  clear
  printf "${BIRU}────────────────────────────────────────${RESET}\n"
  echo -e "\033[0;35m        Pointing Domain Wildcard           ${RESET}"
  printf "${BIRU}────────────────────────────────────────${RESET}\n"
  echo -e "${PUTIH} 1) ${PUTIH}Tambah/Edit Bug"
  echo -e "${PUTIH} 2) ${PUTIH}Lihat Daftar Bug"
  echo -e "${PUTIH} 3) ${PUTIH}Pointing Domain Wildcard"
  echo -e "${PUTIH} x) EXIT ${RESET}"
  printf "${BIRU}────────────────────────────────────────${RESET}\n"
  echo
  read -p "Pilih 1/2/3 atau 'x' untuk keluar: " pilih
  case "$pilih" in
    1) edit_bug ;;
    2) view_bug ;;
    3) add_wc ;;
    x|X) exit 0 ;;
    *) echo -e "${r}Pilihan tidak valid!${NC}" && sleep 1 && main_menu ;;
  esac
  main_menu
}

# Start
main_menu
