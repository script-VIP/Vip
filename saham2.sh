#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 PUSH BOT SAHAM KE GITHUB${NC}"
echo -e "${GREEN}========================================${NC}"

# Update dan install git
echo -e "${YELLOW}📦 Menginstall git...${NC}"
sudo apt update
sudo apt install git -y

# Konfigurasi git
echo -e "${YELLOW}🔧 Konfigurasi git...${NC}"
read -p "Masukkan nama GitHub Anda: " git_name
read -p "Masukkan email GitHub Anda: " git_email
read -p "Masukkan URL repository GitHub Anda: " git_url

git config --global user.name "$git_name"
git config --global user.email "$git_email"

# Clone repository
echo -e "${YELLOW}📥 Clone repository...${NC}"
git clone "$git_url"
repo_name=$(basename "$git_url" .git)
cd "$repo_name"

# Cari file bot
echo -e "${YELLOW}🔍 Mencari file bot saham.py...${NC}"
if [ -f ~/saham.py ]; then
    cp ~/saham.py .
    echo -e "${GREEN}✅ File saham.py ditemukan dan di-copy${NC}"
elif [ -f /root/saham.py ]; then
    cp /root/saham.py .
    echo -e "${GREEN}✅ File saham.py ditemukan dan di-copy${NC}"
else
    read -p "Masukkan lokasi lengkap file saham.py: " file_path
    cp "$file_path" .
fi

# Perbaiki import pandas_ta
echo -e "${YELLOW}🔧 Memperbaiki import pandas_ta...${NC}"
sed -i 's/import pandas_ta as ta/import ta/g' saham.py
echo -e "${GREEN}✅ Import diperbaiki${NC}"

# Git add, commit, push
echo -e "${YELLOW}📤 Push ke GitHub...${NC}"
git add saham.py
git commit -m "Add stock bot indonesia - fix import ta"
git push origin main

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ SELESAI! Bot sudah di-push ke GitHub${NC}"
echo -e "${GREEN}========================================${NC}"
