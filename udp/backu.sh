#!/bin/bash
set -euo pipefail
clear

 
  clear
  echo "======================================"
  echo " RESTORE ZIVPN"
  echo "======================================"
  echo "1) Restore dari Google Drive (nama file)"
  echo "2) Restore dari Telegram (file path)"
  echo "0) Back"
  echo "======================================"
  read -rp "Pilih: " rmode

 case $rmode in
  1)
    # === CEK RCLONE DULU ===
    if ! command -v rclone >/dev/null 2>&1; then
      echo "❌ rclone tidak tersedia di VPS ini"
      echo "Restore Google Drive tidak bisa digunakan"
      sleep 2
      return
    fi

    clear
    echo "Daftar backup di Google Drive:"
    echo "----------------------------------"
    rclone ls gdrive:ZIVPN-BACKUP
    echo "----------------------------------"
    read -rp "Masukkan nama file backup: " FILE

    [ -z "$FILE" ] && echo "❌ Nama file kosong!" && sleep 2 && return

    rclone copy "gdrive:ZIVPN-BACKUP/$FILE" /root/

    if [[ ! -f "/root/$FILE" ]]; then
      echo "❌ Download gagal dari Google Drive!"
      sleep 2
      return
    fi
    ;;
  2)
    clear
    read -rp "Masukkan File Path Telegram (contoh: documents/file_18.zip): " FILE_PATH

    [ -z "$FILE_PATH" ] && echo "❌ File path kosong!" && sleep 2 && return

    FILE="/root/telegram-restore.zip"
    wget -qO "$FILE" "https://api.telegram.org/file/bot$BOT_TOKEN/$FILE_PATH"

    if [[ ! -f "$FILE" ]]; then
      echo "❌ Download dari Telegram gagal!"
      sleep 2
      return
    fi
    ;;
  0)
    return
    ;;
  *)
    restore_zivpn_drive
    ;;
  esac

  echo "🔄 Restore data..."
  unzip -o "$FILE" -d / >/dev/null 2>&1
  rm -f "$FILE"
  systemctl restart zivpn

  echo "✅ Restore selesai, ZIVPN direstart"
  read -p "Press Enter..."
