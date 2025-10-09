#!/bin/bash

# Fix expired script
function fix_expired() {
    clear
    echo -e "─────────────────────────────────────────────"
    echo -e "           FIX EXPIRED SCRIPT"
    echo -e "─────────────────────────────────────────────"
    
    # Stop service yang terkait
    systemctl stop izin 2>/dev/null
    systemctl disable izin 2>/dev/null
    
    # Hapus file izin lama
    rm -f /root/izin
    rm -f /usr/local/bin/izin
    rm -f /etc/systemd/system/izin.service
    
    # Download izin script terbaru
    echo -e "📥 Downloading izin script..."
    wget -q -O /root/izin https://raw.githubusercontent.com/script-VIP/izin/main/ip
    chmod +x /root/izin
    
    # Buat symlink
    ln -sf /root/izin /usr/local/bin/izin 2>/dev/null
    
    # Hapus cron job lama
    crontab -l | grep -v 'izin' | crontab -
    
    # Clear cache dan restart services
    systemctl daemon-reload
    systemctl reset-failed
    
    echo -e "✅ Izin script telah diperbarui"
    echo -e "🔄 Restarting services..."
    
    # Restart service penting
    systemctl restart nginx 2>/dev/null
    systemctl restart xray 2>/dev/null
    systemctl restart haproxy 2>/dev/null
    
    echo -e "🎯 Fix expired script completed!"
    sleep 3
}

# Alternative fix dengan method berbeda
function fix_expired_alt() {
    clear
    echo -e "─────────────────────────────────────────────"
    echo -e "         FIX EXPIRED SCRIPT (ALTERNATIVE)"
    echo -e "─────────────────────────────────────────────"
    
    # Method 1: Force reinstall izin
    curl -s https://raw.githubusercontent.com/script-VIP/izin/main/ip > /tmp/izin_new
    chmod +x /tmp/izin_new
    /tmp/izin_new
    
    # Method 2: Clear systemd cache
    systemctl daemon-reload
    systemctl reset-failed
    
    # Method 3: Update timezone dan time
    timedatectl set-timezone Asia/Jakarta
    systemctl restart systemd-timedated
    
    echo -e "✅ Alternative fix applied"
    sleep 3
}

# Fix dengan manual IP update
function fix_manual_ip() {
    clear
    echo -e "─────────────────────────────────────────────"
    echo -e "           MANUAL IP FIX"
    echo -e "─────────────────────────────────────────────"
    
    # Get current IP
    MYIP=$(curl -s ifconfig.me)
    echo -e "🌐 Current IP: $MYIP"
    
    # Update IP di berbagai lokasi
    echo "$MYIP" > /etc/xray/ipvps
    echo "$MYIP" > /var/lib/izin/ipvps
    mkdir -p /var/lib/izin
    echo "$MYIP" > /var/lib/izin/ipvps
    
    # Restart services
    systemctl restart nginx 2>/dev/null
    systemctl restart xray 2>/dev/null
    
    echo -e "✅ Manual IP update completed"
    sleep 3
}

# Comprehensive fix
function fix_comprehensive() {
    clear
    echo -e "─────────────────────────────────────────────"
    echo -e "         COMPREHENSIVE FIX"
    echo -e "─────────────────────────────────────────────"
    
    echo -e "🔧 Step 1: Cleaning old files..."
    rm -rf /var/lib/izin
    rm -f /root/izin
    rm -f /usr/local/bin/izin
    
    echo -e "🔧 Step 2: Downloading new izin..."
    wget -q -O /root/izin https://raw.githubusercontent.com/script-VIP/izin/main/ip
    chmod +x /root/izin
    
    echo -e "🔧 Step 3: Setting up directories..."
    mkdir -p /var/lib/izin
    echo "$(curl -s ifconfig.me)" > /var/lib/izin/ipvps
    echo "$(curl -s ifconfig.me)" > /etc/xray/ipvps
    
    echo -e "🔧 Step 4: Restarting services..."
    systemctl daemon-reload
    systemctl restart nginx 2>/dev/null
    systemctl restart xray 2>/dev/null
    
    echo -e "✅ Comprehensive fix completed!"
    sleep 3
}

# Main fix function yang bisa dipanggil dari menu
function fix_expired_main() {
    echo -e "Pilih metode fix:"
    echo -e "1) Standard Fix"
    echo -e "2) Alternative Fix" 
    echo -e "3) Manual IP Fix"
    echo -e "4) Comprehensive Fix"
    echo -e "0) Back"
    
    read -p "Pilih [1-4]: " fix_choice
    
    case $fix_choice in
        1) fix_expired ;;
        2) fix_expired_alt ;;
        3) fix_manual_ip ;;
        4) fix_comprehensive ;;
        0) return ;;
        *) fix_expired ;;
    esac
}

# Untuk menambahkan di menu, tambahkan opsi ini:
# [41] Fix Expired Script

# Dan di case statement tambahkan:
# 41) clear ; fix_expired_main ;;
