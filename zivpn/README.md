
# 🚀 VIP Script Collection

Kumpulan script premium untuk berbagai keperluan VPS.

## 📋 Daftar Script

| Script | Deskripsi | Cara Pakai |
|--------|-----------|------------|
| **ZiVPN** | UDP Tunnel VPN Server | `bash <(wget -qO- https://raw.githubusercontent.com/script-VIP/Vip/main/install.sh)` |

---

## 📦 ZiVPN UDP Server

<p align="center">
  <img src="zivpn.png" width="420">
</p>

UDP server installation untuk aplikasi **ZiVPN Tunnel (UDP)**.

### ✨ Fitur
- Auto detect arsitektur VPS (amd64/arm/arm64)
- Auto download & install binary
- Auto setup systemd service
- Auto configure UFW & NAT
- Auto alias command `menu`

### 📥 Instalasi
```bash
apt update -y && wget -q https://raw.githubusercontent.com/script-VIP/Vip/main/install.sh -O /usr/local/bin/install.sh && chmod +x /usr/local/bin/install.sh && /usr/local/bin/install.sh
```

### 🔧 Fix Service
```bash
wget -q https://raw.githubusercontent.com/script-VIP/Vip/main/fix-zivpn.sh -O /usr/local/bin/fix-zivpn.sh && chmod +x /usr/local/bin/fix-zivpn.sh && /usr/local/bin/fix-zivpn.sh
```

### 📦 Update Menu
```bash
wget -q https://raw.githubusercontent.com/script-VIP/Vip/main/update.sh -O /usr/local/bin/update.sh && chmod +x /usr/local/bin/update.sh && /usr/local/bin/update.sh
```

### 🧹 Uninstall
```bash
wget -q https://raw.githubusercontent.com/script-VIP/Vip/main/uninstall.sh -O /usr/local/bin/uninstall.sh && chmod +x /usr/local/bin/uninstall.sh && /usr/local/bin/uninstall.sh
```

### 🖥️ Supported Architecture
| Architecture | Binary |
|-------------|--------|
| x86_64 (AMD64) | `zi2.sh` |
| ARM 32-bit | `zi.sh` |
| ARM 64-bit | `zi3.sh` |

### ⚙️ Default Config
| Setting | Value |
|---------|-------|
| Port | 5667 UDP |
| Range | 6000-19999 |
| Password | `zi` |
| Service | `zivpn.service` |
| Config | `/etc/zivpn/config.json` |

### 📱 Client App
[ZiVPN Tunnel di Google Play](https://play.google.com/store/apps/details?id=com.zi.zivpn)

### 📞 Support
- Telegram: @script_VIP

---

## ⚠️ Notes
- Wajib root
- Support Debian/Ubuntu
- Jalankan `menu` setelah instalasi

---

### 🎉 Happy Tunneling!
```

## README-api.md (Dokumentasi API)

```markdown
# 📡 REST API ZIVPN

Dokumentasi API untuk mengelola akun ZiVPN secara terprogram.

## 🔌 Base URL
```
http://<IP_VPS_ANDA>:5888
```

## 🔑 Autentikasi
Setiap request WAJIB menyertakan parameter `auth`:
```
?auth=YOUR_API_KEY
```

## 📌 Cara Mendapatkan API Key
1. Jalankan `menu` di VPS
2. Pilih opsi **Generate API Auth Key**
3. Simpan key yang muncul

## 🚀 Endpoints

### 1. Create Account
```
GET /create/zivpn?auth=KEY&password=USER&exp=30
POST /create/zivpn
```
**Parameter:**
- `password`: Username/password akun
- `exp`: Masa aktif (hari)

### 2. Delete Account
```
GET /delete/zivpn?auth=KEY&password=USER
POST /delete/zivpn
```

### 3. Renew Account
```
GET /renew/zivpn?auth=KEY&password=USER&exp=15
POST /renew/zivpn
```

### 4. Trial Account
```
GET /trial/zivpn?auth=KEY&exp=60
POST /trial/zivpn
```
- `exp`: Masa aktif dalam **menit**

## 📋 Contoh Penggunaan

### Via cURL
```bash
# Create akun
curl "http://103.31.204.32:5888/create/zivpn?auth=abc123&password=user1&exp=30"

# Delete akun
curl "http://103.31.204.32:5888/delete/zivpn?auth=abc123&password=user1"

# Renew akun
curl "http://103.31.204.32:5888/renew/zivpn?auth=abc123&password=user1&exp=15"

# Trial akun (60 menit)
curl "http://103.31.204.32:5888/trial/zivpn?auth=abc123&exp=60"
```

### Via Python
```python
import requests

API_KEY = "abc123"
VPS_IP = "103.31.204.32"

# Create
r = requests.get(f"http://{VPS_IP}:5888/create/zivpn", params={
    "auth": API_KEY,
    "password": "user1",
    "exp": 30
})
print(r.json())

# Delete
r = requests.get(f"http://{VPS_IP}:5888/delete/zivpn", params={
    "auth": API_KEY,
    "password": "user1"
})
print(r.json())
```

### Via PHP
```php
<?php
$api_key = "abc123";
$vps_ip = "103.31.204.32";

// Create account
$url = "http://{$vps_ip}:5888/create/zivpn?" . http_build_query([
    'auth' => $api_key,
    'password' => 'user1',
    'exp' => 30
]);

$response = file_get_contents($url);
$data = json_decode($response, true);
print_r($data);
?>
```

## 📤 Response Format

### Sukses
```json
{
  "status": "success",
  "message": "Account 'user1' created, expires in 30 days"
}
```

### Error
```json
{
  "status": "error",
  "message": "Password already exists"
}
```

## ⚠️ Catatan
- API berjalan di port **5888**
- Service API otomatis jalan setelah instalasi
- Jika lupa API Key, generate ulang via menu
- Port 5888 harus terbuka di firewall

## 🔒 Keamanan
- Ganti API Key secara berkala
- Jangan share API Key ke orang lain
- Gunakan HTTPS jika ada domain
- Batasi akses IP jika perlu

---

📞 Support: @script_VIP
```
