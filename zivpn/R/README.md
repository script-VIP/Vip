
# ZIVPN UDP Manager 🚀

Script manajemen untuk menginstall dan mengelola ZIVPN UDP Server di VPS Ubuntu. Mendukung manajemen user dengan masa berlaku, auto-expired, dan monitoring service.

## 📋 Daftar Isi
- [Fitur](#fitur)
- [Requirements](#requirements)
- [Instalasi](#instalasi)
- [Cara Penggunaan](#cara-penggunaan)
- [Menu Options](#menu-options)
- [Konfigurasi](#konfigurasi)
- [Troubleshooting](#troubleshooting)
- [Update](#update)
- [Uninstall](#uninstall)
- [Lisensi](#lisensi)

## ✨ Fitur

- ✅ Install ZIVPN UDP Server otomatis
- ✅ Manajemen user (Tambah, Hapus, List, Perpanjang)
- ✅ Masa berlaku user (expired date)
- ✅ Auto-hapus user expired (via cron setiap jam 00:00)
- ✅ Monitoring service status
- ✅ Restart service
- ✅ Live log viewer
- ✅ Informasi server
- ✅ Update script otomatis dari GitHub
- ✅ Support Ubuntu 20.04 / 22.04 / 24.04
- ✅ Support arsitektur AMD64 & ARM64

## 📦 Requirements

- **OS**: Ubuntu 20.04 / 22.04 / 24.04
- **RAM**: Minimal 512 MB
- **Storage**: Minimal 2 GB
- **Architecture**: x86_64 (AMD64) atau ARM64
- **Akses**: Root

## 🔧 Instalasi

### 1. Download Script Instalasi

```bash
wget -O installziv.sh "https://github.com/script-VIP/Vip/raw/main/zivpn/installziv.sh"
# atau
curl -o installziv.sh "https://github.com/script-VIP/Vip/raw/main/zivpn/installziv.sh"
```

### 2. Beri Izin Eksekusi

```bash
chmod +x installziv.sh
```

### 3. Jalankan Instalasi

```bash
sudo bash installziv.sh
```

Proses instalasi akan:
- Update sistem
- Install dependencies
- Download binary ZIVPN
- Generate SSL certificate
- Setup systemd service
- Konfigurasi firewall
- Setup cron job
- Download menu script

### 4. Selesai Instalasi

Setelah instalasi selesai, Anda akan melihat informasi:
- IP VPS
- Port UDP (5667 & 6000-19999)
- Status service
- Cara koneksi ke ZIVPN App

## 🚀 Cara Penggunaan

### Akses Menu Manajemen

Setelah instalasi, Anda bisa mengakses menu dengan 3 cara:

```bash
# Cara 1 - Ketik perintah (harus login ulang atau source bashrc)
menuziv

# Cara 2 - Alias zivpn
zivpn

# Cara 3 - Langsung panggil script
bash /usr/local/bin/menuziv
```

Jika perintah `menuziv` tidak ditemukan, jalankan:
```bash
source /root/.bashrc
```

### Download Manual Menu Script

Jika perlu mendownload ulang menu script:

```bash
wget -O /usr/local/bin/menuziv "https://github.com/script-VIP/Vip/raw/main/zivpn/menu.sh"
chmod +x /usr/local/bin/menuziv
```

## 📑 Menu Options

### Main Menu

```
╔═══════════════════════════════════════╗
║         MENU MANAJEMEN ZIVPN UDP      ║
╠═══════════════════════════════════════╣
║  1. Tambah User                       ║
║  2. Hapus User                        ║
║  3. Daftar User                       ║
║  4. Perpanjang User                    ║
║  5. Hapus User Expired                 ║
║                                        ║
║  6. Status Service                     ║
║  7. Restart Service                    ║
║  8. Lihat Log                          ║
║  9. Info Server                        ║
║                                        ║
║  10. Update Script                     ║
║  11. Uninstall ZIVPN                   ║
║  0. Keluar                             ║
╚═══════════════════════════════════════╝
```

### Detail Menu

#### 1. **Tambah User**
- Masukkan username
- Masukkan password
- Pilih masa berlaku (7, 14, 30, 60, 90 hari, custom, atau unlimited)
- Konfigurasi otomatis diupdate

#### 2. **Hapus User**
- Lihat daftar user
- Pilih user yang akan dihapus
- Konfirmasi penghapusan

#### 3. **Daftar User**
Menampilkan semua user dengan informasi:
- Username
- Password
- Tanggal expired
- Status (Aktif/Expired)

#### 4. **Perpanjang User**
- Pilih user
- Tambah masa berlaku

#### 5. **Hapus User Expired**
Membersihkan semua user yang sudah melewati masa berlaku

#### 6. **Status Service**
Menampilkan status lengkap service ZIVPN

#### 7. **Restart Service**
Merestart service ZIVPN

#### 8. **Lihat Log**
Menampilkan 20 log terakhir secara realtime

#### 9. **Info Server**
Menampilkan informasi lengkap server:
- IP VPS
- Port UDP
- Lokasi file config
- Penggunaan CPU & RAM
- Uptime
- Cara koneksi

#### 10. **Update Script**
Update script ke versi terbaru dari GitHub

#### 11. **Uninstall ZIVPN**
Menghapus ZIVPN UDP beserta semua konfigurasi

## ⚙️ Konfigurasi

### File Penting

| File | Lokasi | Keterangan |
|------|--------|------------|
| Binary | `/usr/local/bin/zivpn` | Executable ZIVPN |
| Config | `/etc/zivpn/config.json` | Konfigurasi server |
| Database | `/etc/zivpn/users.db` | Database user |
| Sertifikat | `/etc/zivpn/zivpn.crt` | SSL Certificate |
| Private Key | `/etc/zivpn/zivpn.key` | SSL Private Key |
| Service | `/etc/systemd/system/zivpn.service` | Systemd service |
| Cron Script | `/usr/local/bin/zivpn-cron.sh` | Auto-hapus expired |
| Menu Script | `/usr/local/bin/menuziv` | Script menu |

### Port yang Digunakan

- **22/tcp**: SSH
- **5667/udp**: Port utama ZIVPN
- **6000-19999/udp**: Range port yang diredirect ke 5667

### Format Database User

```
username|password|YYYY-MM-DD
username2|pass2|unlimited
```

Contoh:
```
budi|rahasia123|2025-06-30
siti|pass456|unlimited
```

## 🔍 Troubleshooting

### 1. Service Tidak Jalan

```bash
# Cek status
systemctl status zivpn.service

# Lihat log
journalctl -u zivpn.service -n 50

# Restart service
systemctl restart zivpn.service
```

### 2. User Tidak Bisa Connect

```bash
# Cek apakah user ada dan belum expired
menuziv  # lalu pilih menu 3

# Cek firewall
ufw status

# Cek apakah service aktif
systemctl is-active zivpn.service
```

### 3. Port Tidak Bisa Diakses

```bash
# Cek iptables
iptables -t nat -L -n -v

# Cek apakah port terbuka
netstat -tulpn | grep 5667
```

### 4. Script Menu Tidak Jalan

```bash
# Download ulang
wget -O /usr/local/bin/menuziv "https://github.com/script-VIP/Vip/raw/main/zivpn/menu.sh"
chmod +x /usr/local/bin/menuziv

# Jalankan
bash /usr/local/bin/menuziv
```

### 5. Alias Tidak Bekerja

```bash
# Tambahkan manual
echo "alias menuziv='bash /usr/local/bin/menuziv'" >> /root/.bashrc
echo "alias zivpn='bash /usr/local/bin/menuziv'" >> /root/.bashrc
source /root/.bashrc
```

## 🔄 Update

### Update Manual

```bash
# Update install script
wget -O /root/installziv.sh "https://github.com/script-VIP/Vip/raw/main/zivpn/installziv.sh"
chmod +x /root/installziv.sh

# Update menu script
wget -O /usr/local/bin/menuziv "https://github.com/script-VIP/Vip/raw/main/zivpn/menu.sh"
chmod +x /usr/local/bin/menuziv
```

### Update via Menu
1. Jalankan `menuziv`
2. Pilih menu `10. Update Script`
3. Script akan otomatis diupdate

## 🗑️ Uninstall

### Via Menu
1. Jalankan `menuziv`
2. Pilih menu `11. Uninstall ZIVPN`
3. Konfirmasi dengan `y`

### Manual
```bash
# Stop & disable service
systemctl stop zivpn.service
systemctl disable zivpn.service

# Hapus file
rm -f /etc/systemd/system/zivpn.service
rm -f /usr/local/bin/zivpn
rm -f /usr/local/bin/zivpn-cron.sh
rm -rf /etc/zivpn

# Hapus cron
crontab -l | grep -v "zivpn-cron" | crontab -

# Reload systemd
systemctl daemon-reload
```

## 📝 Catatan Penting

1. **Root Akses**: Semua perintah harus dijalankan sebagai root
2. **Firewall**: Script otomatis mengaktifkan UFW
3. **Backup**: Backup file `/etc/zivpn/users.db` sebelum uninstall
4. **Restart Service**: Setiap perubahan user otomatis merestart service
5. **Auto Expired**: Cron berjalan setiap jam 00:00 untuk hapus user expired

## 🆘 Bantuan

Jika menemui kendala:
1. Cek log dengan `journalctl -u zivpn.service -f`
2. Pastikan firewall tidak memblokir port
3. Pastikan VPS support UDP
4. Cek koneksi internet VPS

## 📚 Sumber Daya

- [GitHub Repository](https://github.com/script-VIP/Vip/tree/main/zivpn)
- [ZIVPN Official](https://zivpn.com)
- [Report Bug](https://github.com/script-VIP/Vip/issues)

## 📄 Lisensi

Script ini dibuat untuk kemudahan manajemen ZIVPN UDP. Gunakan dengan bijak dan sesuai ketentuan yang berlaku.

---

**Dibuat dengan ❤️ untuk pengguna ZIVPN**

*Last Updated: 2024*
```

## Cara Upload ke GitHub

### 1. Buat file README.md di repository

```bash
# Clone repository (jika belum)
git clone https://github.com/script-VIP/Vip.git
cd Vip

# Buat folder zivpn
mkdir -p zivpn

# Buat file README.md
nano zivpn/README.md
# Paste konten README di atas

# Save dengan Ctrl+X, Y, Enter
```

### 2. Upload script instalasi

```bash
# Pindahkan atau buat file installziv.sh
nano zivpn/installziv.sh
# Paste isi instal.sh dari jawaban sebelumnya

# Beri izin
chmod +x zivpn/installziv.sh
```

### 3. Upload script menu

```bash
nano zivpn/menu.sh
# Paste isi menuziv.sh dari jawaban sebelumnya

chmod +x zivpn/menu.sh
```

### 4. Commit dan push

```bash
git add zivpn/
git commit -m "Add ZIVPN UDP Manager scripts"
git push origin main
```

### 5. Raw URLs untuk digunakan

Setelah push, raw URLs akan tersedia di:
- **Install Script**: `https://github.com/script-VIP/Vip/raw/main/zivpn/installziv.sh`
- **Menu Script**: `https://github.com/script-VIP/Vip/raw/main/zivpn/menu.sh`
