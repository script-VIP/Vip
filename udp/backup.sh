#!/bin/bash
set -euo pipefail
clear

BASE="/etc/yinn-zivpn"
pause(){ read -rp "Enter..." _; }

while true; do
  clear
  echo "=== BACKUP / RESTORE ==="
  echo "1) Backup $BASE -> /root/yinn-zivpn-backup-*.tar.gz"
  echo "2) Restore dari file .tar.gz"
  echo "0) Back"
  echo
  read -rp "Selected ⟩ " c
  case "$c" in
    1)
      outp="/root/yinn-zivpn-backup-$(date +%F-%H%M%S).tar.gz"
      tar -czf "$outp" -C /etc yinn-zivpn 2>/dev/null
      echo "✅ Backup: $outp"
      pause
      ;;
    2)
      read -rp "Path backup: " pth
      [[ -f "$pth" ]] || { echo "File tidak ada."; pause; continue; }
      systemctl stop zivpn.service 2>/dev/null || true
      tar -xzf "$pth" -C / 2>/dev/null
      systemctl daemon-reload 2>/dev/null || true
      systemctl restart zivpn.service 2>/dev/null || true
      echo "✅ Restore OK"
      pause
      ;;
    0) exit 0 ;;
    *) ;;
  esac
done
