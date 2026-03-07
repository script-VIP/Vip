#!/bin/bash
# ZiVPN Manager - Clean Version

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_DIR="/etc/zivpn"
PASSWD_FILE="$CONFIG_DIR/passwd.txt"

# Cek root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Harus root!${NC}"
    exit 1
fi

while true; do
    clear
    echo -e "${BLUE}╔════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        ZIVPN MANAGER          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════╝${NC}"
    echo ""
    
    # Cek status
    if systemctl is-active --quiet zivpn.service; then
        echo -e " Service: ${GREEN}● Running${NC}"
    else
        echo -e " Service: ${RED}● Stopped${NC}"
    fi
    echo ""
    
    echo " 1) Lihat Status Detail"
    echo " 2) Tambah Akun"
    echo " 3) Hapus Akun"
    echo " 4) List Akun"
    echo " 5) Restart Service"
    echo " 6) Backup Akun"
    echo " 7) Restore Akun"
    echo " 8) Fix Error"
    echo " 9) Uninstall"
    echo " 0) Exit"
    echo ""
    read -p " Pilih menu: " menu
    
    case $menu in
        1)
            clear
            systemctl status zivpn.service --no-pager
            echo ""
            iptables -t nat -L -n | grep -E "6000|5667"
            ;;
        2)
            read -p "Password: " pass
            read -p "Expired (hari): " exp
            if grep -q "^$pass$" $PASSWD_FILE 2>/dev/null; then
                echo -e "${RED}Password sudah ada!${NC}"
            else
                echo "$pass" >> $PASSWD_FILE
                echo "$pass:$(date -d "+$exp days" +%Y-%m-%d)" >> $CONFIG_DIR/expiry.txt
                systemctl restart zivpn.service
                echo -e "${GREEN}✅ Akun ditambahkan${NC}"
            fi
            ;;
        3)
            read -p "Password: " pass
            sed -i "/^$pass$/d" $PASSWD_FILE
            sed -i "/^$pass:/d" $CONFIG_DIR/expiry.txt 2>/dev/null
            systemctl restart zivpn.service
            echo -e "${GREEN}✅ Akun dihapus${NC}"
            ;;
        4)
            clear
            echo "=== DAFTAR AKUN ==="
            echo ""
            if [[ -f $PASSWD_FILE ]]; then
                cat $PASSWD_FILE
                echo ""
                echo "Total: $(wc -l < $PASSWD_FILE) akun"
            else
                echo "Belum ada akun"
            fi
            ;;
        5)
            systemctl restart zivpn.service
            echo -e "${GREEN}✅ Service restarted${NC}"
            ;;
        6)
            cp $PASSWD_FILE /root/zivpn-backup.txt
            echo -e "${GREEN}✅ Backup di /root/zivpn-backup.txt${NC}"
            ;;
        7)
            if [[ -f /root/zivpn-backup.txt ]]; then
                cp /root/zivpn-backup.txt $PASSWD_FILE
                systemctl restart zivpn.service
                echo -e "${GREEN}✅ Restore berhasil${NC}"
            else
                echo -e "${RED}File backup tidak ada${NC}"
            fi
            ;;
        8)
            echo "🔧 Fixing..."
            iptables -t nat -F
            iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-port 5667
            systemctl restart zivpn.service
            echo -e "${GREEN}✅ Fix selesai${NC}"
            ;;
        9)
            read -p "Yakin uninstall? (y/n): " confirm
            if [[ $confirm == "y" ]]; then
                systemctl stop zivpn.service
                systemctl disable zivpn.service
                rm -f /usr/local/bin/zivpn
                rm -f /usr/local/bin/zivpn-manager
                rm -rf /etc/zivpn
                rm -f /etc/systemd/system/zivpn.service
                systemctl daemon-reload
                echo -e "${GREEN}✅ Uninstall selesai${NC}"
                exit 0
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid${NC}"
            ;;
    esac
    read -p "Tekan Enter..."
done
