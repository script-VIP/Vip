#!/bin/bash
# Script untuk restore akun Xray tanpa hapus yang existing

echo "=== RESTORE XRAY ACCOUNTS ==="

# 1. Backup database yang sekarang
BACKUP_DIR="/backup_accounts_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -f /etc/vmess/.vmess.db $BACKUP_DIR/vmess.db.backup 2>/dev/null
cp -f /etc/vless/.vless.db $BACKUP_DIR/vless.db.backup 2>/dev/null
cp -f /etc/trojan/.trojan.db $BACKUP_DIR/trojan.db.backup 2>/dev/null
cp -f /etc/shadowsocks/.shadowsocks.db $BACKUP_DIR/shadowsocks.db.backup 2>/dev/null
cp -f /etc/ssh/.ssh.db $BACKUP_DIR/ssh.db.backup 2>/dev/null

echo "Backup created in: $BACKUP_DIR"

# 2. Cek jika database kosong atau rusak
check_db() {
    local db_file=$1
    local db_type=$2
    
    if [ ! -f "$db_file" ] || [ ! -s "$db_file" ]; then
        echo "⚠️  Database $db_type kosong/rusak"
        return 1
    fi
    
    # Cek format (harus ada "###" di awal)
    if ! head -1 "$db_file" | grep -q "^###"; then
        echo "⚠️  Format database $db_type salah"
        return 1
    fi
    
    echo "✅ Database $db_type OK"
    return 0
}

# 3. Restore database template jika rusak
restore_db_template() {
    local db_file=$1
    local db_type=$2
    
    echo "🔄 Restore template untuk $db_type..."
    
    case $db_type in
        "vmess")
            echo -e "### XRAY VMESS USER LIST\n& plughin Account" > "$db_file"
            ;;
        "vless")
            echo -e "### XRAY VLESS USER LIST\n& plughin Account" > "$db_file"
            ;;
        "trojan")
            echo -e "### XRAY TROJAN USER LIST\n& plughin Account" > "$db_file"
            ;;
        "shadowsocks")
            echo -e "### XRAY SHADOWSOCKS USER LIST\n& plughin Account" > "$db_file"
            ;;
        "ssh")
            echo -e "### SSH USER LIST\n& plughin Account" > "$db_file"
            ;;
    esac
    
    chmod 644 "$db_file"
}

# 4. Proses semua database
databases=(
    "/etc/vmess/.vmess.db:vmess"
    "/etc/vless/.vless.db:vless"
    "/etc/trojan/.trojan.db:trojan"
    "/etc/shadowsocks/.shadowsocks.db:shadowsocks"
    "/etc/ssh/.ssh.db:ssh"
)

for db_entry in "${databases[@]}"; do
    db_file="${db_entry%%:*}"
    db_type="${db_entry##*:}"
    
    mkdir -p "$(dirname "$db_file")"
    
    if ! check_db "$db_file" "$db_type"; then
        restore_db_template "$db_file" "$db_type"
    fi
done

# 5. Sync dengan config.json Xray
echo "🔄 Sync database dengan Xray config..."
systemctl stop xray

# Buat script sync manual
cat > /tmp/sync_xray.sh << 'EOF'
#!/bin/bash
# Sync akun dari database ke system

# Cek jumlah akun
echo "=== JUMLAH AKUN SAAT INI ==="
echo "VMESS: $(grep -c "^### " /etc/vmess/.vmess.db 2>/dev/null || echo 0)"
echo "VLESS: $(grep -c "^### " /etc/vless/.vless.db 2>/dev/null || echo 0)"
echo "TROJAN: $(grep -c "^### " /etc/trojan/.trojan.db 2>/dev/null || echo 0)"
echo "SSH: $(grep -c "^### " /etc/ssh/.ssh.db 2>/dev/null || echo 0)"

# Cek di config.json
echo "=== AKUN DI CONFIG.JSON ==="
grep -o '"email": "[^"]*"' /etc/xray/config.json | wc -l | xargs echo "Total: "
EOF

chmod +x /tmp/sync_xray.sh
bash /tmp/sync_xray.sh

# 6. Restart Xray dengan mode debug
echo "🔄 Restart Xray dengan log detail..."
systemctl daemon-reload
systemctl restart xray

# 7. Cek status
echo ""
echo "=== STATUS AKHIR ==="
sleep 3
systemctl status xray --no-pager | head -10
echo ""
echo "Log terakhir:"
tail -5 /var/log/xray/access.log 2>/dev/null || echo "No access log yet"

# 8. Tips tambahan
echo ""
echo "=== TIPS ==="
echo "1. Untuk tambah akun manual: gunakan command 'add-xxx'"
echo "2. Cek semua akun: 'menu' -> pilih list user"
echo "3. Backup database: 'cp /etc/vmess/.vmess.db /backup/'"
echo ""
echo "✅ Proses selesai!"
