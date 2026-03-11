#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIG GITHUB REPO AUTOSCRIPT
# =========================
GITHUB_USER="YINNSTORE"
GITHUB_REPO="yinn-zivpn-autosc"
BRANCH="main"
REPO_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${BRANCH}"

# =========================
# PERMISSION SOURCE
# =========================
PERM_URL="https://raw.githubusercontent.com/script-VIP/izin/main/ip"

# =========================
# PATHS
# =========================
WORKDIR="/usr/local/yinn-zivpn"
SCRIPTS_DIR="${WORKDIR}/scripts"

BASE="/etc/yinn-zivpn"
CONF_DIR="${BASE}"
USERS_DIR="${BASE}/users"

BIN="/usr/local/bin/zivpn"
SVC_FILE="/etc/systemd/system/zivpn.service"

# =========================
# COLORS
# =========================
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
NC='\e[0m'
purple="\e[0;33m"
green='\e[0;32m'
GRAY="\e[1;30m"

# =========================
# TTY SAFE INPUT (ANTI PIPE)
# =========================
TTY="/dev/tty"
have_tty() { [[ -r "$TTY" ]]; }

tty_read() { # usage: tty_read varname
  local __var="$1"
  if have_tty; then
    IFS= read -r "$__var" < "$TTY"
  else
    # no tty (rare) -> empty input
    printf -v "$__var" '%s' ""
  fi
}

tty_read_prompt() { # usage: tty_read_prompt "Prompt: " varname
  local __prompt="$1"
  local __var="$2"
  if have_tty; then
    printf "%b" "$__prompt" > "$TTY"
    IFS= read -r "$__var" < "$TTY"
  else
    printf -v "$__var" '%s' ""
  fi
}

tty_pause_enter() {
  if have_tty; then
    printf "%b" "$1" > "$TTY"
    IFS= read -r _ < "$TTY"
  fi
}

# =========================
# HELPERS
# =========================
need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo -e "${ERROR} Run as root"
    exit 1
  fi
}

get_ip() {
  curl -sS ipv4.icanhazip.com 2>/dev/null || true
}

get_server_date() {
  local data_server date_list
  data_server="$(curl -v --insecure --silent https://google.com/ 2>&1 | grep -i '^< date:' | sed -e 's/< Date: //I' | tr -d '\r' || true)"
  date_list="$(date +"%Y-%m-%d" -d "$data_server" 2>/dev/null || date +"%Y-%m-%d")"
  echo "$date_list"
}

is_supported_arch() {
  [[ "$(uname -m | awk '{print $1}')" == "x86_64" ]]
}

is_supported_os() {
  local osid
  osid="$(. /etc/os-release && echo "$ID")"
  [[ "$osid" == "ubuntu" || "$osid" == "debian" ]]
}

virt_check() {
  if [[ "$(systemd-detect-virt 2>/dev/null || true)" == "openvz" ]]; then
    echo -e "${ERROR} OpenVZ is not supported"
    exit 1
  fi
}

print_banner() {
  clear; clear; clear
  echo -e "${YELLOW}----------------------------------------------------------${NC}"
  echo -e " WELCOME TO AUTOSCRIPT ZIVPN ${YELLOW}(${NC}${green}YINN STORE EDITION${NC}${YELLOW})${NC}"
  echo -e " PROSES PENGECEKAN VPS & PERMISSION !!"
  echo -e "${purple}----------------------------------------------------------${NC}"
  echo -e " ›AUTHOR : ${green}YINN STORE${NC} ${YELLOW}(${NC}${green}ZIVPN${NC}${YELLOW})${NC}"
  echo -e " ›TEAM   : YINN STORE ${YELLOW}(${NC} 2026 ${YELLOW})${NC}"
  echo -e "${YELLOW}----------------------------------------------------------${NC}"
  echo ""
  sleep 1
}

install_pkgs() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y \
    bash curl wget jq openssl ca-certificates \
    iproute2 net-tools vnstat \
    iptables cron tzdata \
    unzip git \
    speedtest-cli \
    lolcat >/dev/null 2>&1 || true

  timedatectl set-timezone Asia/Jakarta >/dev/null 2>&1 || true
  systemctl enable vnstat >/dev/null 2>&1 || true
  systemctl restart vnstat >/dev/null 2>&1 || true
}

fetch_file() {
  local rel="$1"
  local out="$2"
  curl -fsSL "${REPO_RAW_BASE}/${rel}" -o "${out}"
}

setup_scripts() {
  mkdir -p "${SCRIPTS_DIR}"
  fetch_file "scripts/menu.sh"         "${SCRIPTS_DIR}/menu.sh"
  fetch_file "scripts/user_manager.sh" "${SCRIPTS_DIR}/user_manager.sh"
  fetch_file "scripts/settings.sh"     "${SCRIPTS_DIR}/settings.sh"
  fetch_file "scripts/backup.sh"       "${SCRIPTS_DIR}/backup.sh"
  fetch_file "scripts/bandwidth.sh"    "${SCRIPTS_DIR}/bandwidth.sh"
  fetch_file "scripts/speedtest.sh"    "${SCRIPTS_DIR}/speedtest.sh"
  chmod +x "${SCRIPTS_DIR}/"*.sh
}

setup_command_menu() {
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/sbin/menu
  ln -sf "${SCRIPTS_DIR}/menu.sh" /usr/local/bin/menu

  if [[ -f /root/.bashrc ]] && ! grep -q "/usr/local/sbin" /root/.bashrc; then
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.bashrc
  fi
  if [[ -f /root/.profile ]] && ! grep -q "/usr/local/sbin" /root/.profile; then
    echo 'export PATH="/usr/local/sbin:/usr/local/bin:$PATH"' >> /root/.profile
  fi
}

# =========================
# PERMISSION PARSER UNIVERSAL
# =========================
perm_parse_line() {
  local line ip
  line="$1"
  ip="$2"
  line="$(echo "$line" | tr -d '\r')"

  local exp
  exp="$(echo "$line" | grep -Eo '(lifetime|Lifetime|[0-9]{4}-[0-9]{2}-[0-9]{2})' | head -n1 || true)"

  local user=""
  if echo "$line" | grep -qE '^\s*###\s+'; then
    user="$(echo "$line" | awk '{print $2}' | tr -d '\r' || true)"
  fi

  if [[ -z "$user" ]]; then
    user="$(echo "$line" | awk -v ip="$ip" -v exp="$exp" '
      {
        for(i=1;i<=NF;i++){
          t=$i
          gsub(/\r/,"",t)
          if(t=="###") continue
          if(t==ip) continue
          if(exp!="" && t==exp) continue
          if(t ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) continue
          if(t=="lifetime" || t=="Lifetime") continue
          print t; exit
        }
      }' || true)"
  fi

  echo "${user}|${exp}"
}

permission_check() {
  local myip server_date reg line parsed username useexp

  myip="$(get_ip)"
  server_date="$(get_server_date)"

  if [[ -z "${myip:-}" ]]; then
    echo -e "${ERROR} IP tidak terdeteksi"
    exit 1
  fi

  reg="$(curl -fsSL "$PERM_URL" || true)"
  line="$(echo "$reg" | grep -F "$myip" | head -n1 || true)"

  echo -e "${OK} IP Address ( ${green}${myip}${NC} )"
  echo -e "${OK} Server Date ( ${green}${server_date}${NC} )"

  if [[ -z "${line:-}" ]]; then
    echo -e "${ERROR} VPS anda tidak memiliki akses untuk script"
    exit 1
  fi

  parsed="$(perm_parse_line "$line" "$myip")"
  username="${parsed%%|*}"
  useexp="${parsed##*|}"

  [[ -z "${username:-}" ]] && username="UNKNOWN"

  if [[ -z "${useexp:-}" ]]; then
    echo -e "${ERROR} Data permission tidak valid (expiry tidak ketemu)"
    echo -e "${ERROR} Line: $line"
    exit 1
  fi

  echo -e "${OK} Username ( ${green}${username}${NC} )"
  echo -e "${OK} Expired  ( ${green}${useexp}${NC} )"

  echo "$username" >/usr/bin/user 2>/dev/null || true
  echo "$useexp" >/usr/bin/e 2>/dev/null || true

  if [[ "$useexp" == "lifetime" || "$useexp" == "Lifetime" ]]; then
    echo -e "${OK} Permission ( ${green}LIFETIME${NC} )"
    return 0
  fi

  if [[ "$server_date" < "$useexp" ]]; then
    echo -e "${OK} Permission ( ${green}ACTIVE${NC} )"
  else
    echo -e "${ERROR} Permission EXPIRED (Exp: ${useexp})"
    exit 1
  fi
}

precheck() {
  print_banner
  need_root
  virt_check

  if is_supported_arch; then
    echo -e "${OK} Architecture Supported ( ${green}$(uname -m)${NC} )"
  else
    echo -e "${ERROR} Architecture Not Supported ( $(uname -m) )"
    exit 1
  fi

  if is_supported_os; then
    echo -e "${OK} OS Supported ( ${green}$(grep -w PRETTY_NAME /etc/os-release | head -n1 | cut -d= -f2- | tr -d '"')${NC} )"
  else
    echo -e "${ERROR} OS Not Supported"
    exit 1
  fi

  permission_check

  echo ""
  tty_pause_enter "$(echo -e "${OK} Tekan ENTER untuk memulai instalasi...\n")"

  clear
  echo -e "${Green}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " INSTALLATION STARTED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${NC}"
  sleep 1
}

input_domain() {
  mkdir -p "${CONF_DIR}" "${USERS_DIR}" >/dev/null 2>&1
  clear
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e " ${green}AUTOSCRIPT ZIVPN - YINN STORE${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  local d
  tty_read_prompt "Input Domain (wajib): " d
  if [[ -z "${d:-}" ]]; then
    echo -e "${ERROR} Domain kosong"
    exit 1
  fi
  echo -n "$d" > "${CONF_DIR}/domain"
}

install_core() {
  local d url def
  d="$(cat "${CONF_DIR}/domain" 2>/dev/null || true)"

  def="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"

  echo ""
  tty_read_prompt "Core URL (Enter=default): " url
  [[ -z "${url:-}" ]] && url="$def"

  echo -e "${OK} Download core..."
  curl -fsSL "$url" -o "$BIN"
  chmod +x "$BIN"

  echo -e "${OK} Write config..."
  cat > "${CONF_DIR}/config.json" <<'EOF'
{
  "listen": ":5667",
  "server_name": "ZiVPN",
  "log_level": "info"
}
EOF

  echo -e "${OK} Generate SSL self-signed..."
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=JawaBarat/L=Jampang/O=YinnStore/OU=ZiVPN/CN=${d}" \
    -keyout "${CONF_DIR}/zivpn.key" -out "${CONF_DIR}/zivpn.crt" >/dev/null 2>&1

  echo -e "${OK} Write systemd..."
  cat > "$SVC_FILE" <<EOF
[Unit]
Description=ZiVPN UDP Core (YinnStore)
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${CONF_DIR}
ExecStart=${BIN} server -c ${CONF_DIR}/config.json
Restart=always
RestartSec=2
LimitNOFILE=65535
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable zivpn.service >/dev/null 2>&1
  systemctl restart zivpn.service >/dev/null 2>&1
}

final_info() {
  echo ""
  echo "------------------------------------------------------------"
  echo "✅ INSTALL SELESAI"
  echo "Command : menu"
  echo "Service : systemctl status zivpn.service"
  echo "Domain  : $(cat "${CONF_DIR}/domain" 2>/dev/null || echo '-')"
  echo "User    : $(cat /usr/bin/user 2>/dev/null || echo '-')"
  echo "Exp     : $(cat /usr/bin/e 2>/dev/null || echo '-')"
  echo "------------------------------------------------------------"
  echo ""
}

main() {
  precheck

  echo -e "${OK} Installing packages..."
  install_pkgs

  echo -e "${OK} Installing menu & scripts..."
  setup_scripts
  setup_command_menu

  echo -e "${OK} Setup domain..."
  input_domain

  echo -e "${OK} Installing ZiVPN core..."
  install_core

  hash -r || true
  final_info

  echo -e "${Green}Launching Menu...${NC}"
  sleep 2

  menu
}

main "$@"
