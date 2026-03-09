#!/bin/bash
# === RESTORE VIA LINK (VERSI CEPAT) ===

restore_link() {
    clear
    echo -e "${YELLOW}[ RESTORE VIA LINK ]${NC}"
    echo ""
    
    read -rp "Masukkan link backup: " link
    
    if [[ -z "$link" ]]; then
        echo -e "${RED}Link tidak boleh kosong!${NC}"
        sleep 2
        return
    fi
    
    echo -e "${YELLOW}Downloading backup...${NC}"
    
    # Download file
    wget -O /tmp/backup.tar.gz "$link"
    
    if [[ ! -f /tmp/backup.tar.gz ]]; then
        echo -e "${RED}Gagal download! Cek link${NC}"
        sleep 2
        return
    fi
    
    # Backup data lama
    cp /etc/zivpn/users.db /etc/zivpn/users.db.bak 2>/dev/null
    
    # Extract
    tar -xzf /tmp/backup.tar.gz -C /
    
    # Restart service
    systemctl restart zivpn.service
    
    echo -e "${GREEN}✓ Restore berhasil!${NC}"
    echo -e "File lama dibackup: /etc/zivpn/users.db.bak"
    sleep 3
}
