#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
END='\033[0m'

# Config
REPO_URL="https://github.com/purplemashu/me-cli"
INSTALL_DIR="me-cli"

print_color() {
    echo -e "${1}${2}${END}"
}

print_success() {
    print_color "$GREEN" "✅ $1"
}

print_error() {
    print_color "$RED" "❌ $1"
}

print_info() {
    print_color "$BLUE" "🧋 $1"
}

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║           INSTALL DOR CLI            ║"
    echo "║        Auto Install & Update         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

install_dor() {
    clear_screen
    display_banner
    
    echo -e "${YELLOW}🚀 Memulai instalasi DOR CLI...${END}"
    echo
    
    # Hapus instalasi lama
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Menghapus instalasi lama...${END}"
        rm -rf "$INSTALL_DIR"
    fi
    
    # Step 1: Update system
    echo -e "${BLUE}1. Update system...${END}"
    sudo apt update && sudo apt upgrade -y
    echo
    
    # Step 2: Install Git
    echo -e "${BLUE}2. Install Git...${END}"
    sudo apt install git -y
    echo
    
    # Step 3: Install Python
    echo -e "${BLUE}3. Install Python...${END}"
    sudo apt install python3 python3-pip -y
    
    # Buat alias python
    if ! command -v python &> /dev/null; then
        sudo ln -s /usr/bin/python3 /usr/bin/python
    fi
    echo
    
    # Step 4: Install dependencies system
    echo -e "${BLUE}4. Install system dependencies...${END}"
    sudo apt install python3-pil python3-dev libssl-dev libffi-dev -y
    echo
    
    # Step 5: Clone repository
    echo -e "${BLUE}5. Clone repository...${END}"
    git clone "$REPO_URL"
    echo
    
    # Step 6: Install Python packages
    echo -e "${BLUE}6. Install Python packages...${END}"
    cd "$INSTALL_DIR"
    
    # Upgrade pip
    pip3 install --upgrade pip
    
    # Install semua packages yang diperlukan
    pip3 install requests colorama pillow python-dotenv
    pip3 install ascii_magic pyfiglet
    pip3 install pycryptodome cryptography
    
    # Coba install requirements.txt
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
    fi
    
    cd ..
    
    echo
    echo -e "${GREEN}🎉 DOR CLI BERHASIL DIINSTALL!${END}"
    echo -e "${BLUE}Lokasi: $(pwd)/$INSTALL_DIR${END}"
    echo
    echo -e "${YELLOW}Langkah selanjutnya:${END}"
    echo -e "1. Setup environment variables"
    echo -e "2. Jalankan: cd me-cli && python3 main.py"
    echo
}

update_dor() {
    clear_screen
    display_banner
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}DOR CLI belum terinstall!${END}"
        return
    fi
    
    echo -e "${YELLOW}🔄 Update DOR CLI...${END}"
    echo
    
    cd "$INSTALL_DIR"
    
    # Update dari GitHub
    echo -e "${BLUE}Update dari GitHub...${END}"
    git pull --rebase
    
    # Update packages
    echo -e "${BLUE}Update Python packages...${END}"
    pip3 install --upgrade pip
    pip3 install requests colorama pillow python-dotenv ascii_magic pyfiglet pycryptodome cryptography --upgrade
    
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt --upgrade
    fi
    
    cd ..
    
    echo
    echo -e "${GREEN}✅ Update selesai!${END}"
    echo
}

show_menu() {
    echo -e "${GREEN}📋 MENU INSTALL:${END}"
    echo
    echo -e "1. 📥 INSTALL DOR CLI"
    echo -e "2. 🔄 UPDATE DOR CLI"
    echo -e "3. 🚀 JALANKAN DOR CLI"
    echo -e "4. 🚀 MENU DOR CLI"
    echo -e "0. ❌ KELUAR"
    echo
    echo -n -e "${YELLOW}Pilih menu (0-3): ${END}"
}
run_dor() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}Install DOR CLI dulu!${END}"
        return
    fi
    
    echo -e "${YELLOW}🚀 Menjalankan DOR CLI...${END}"
    echo -e "${BLUE}Tekan Ctrl+C untuk berhenti${END}"
    echo
    
    cd "$INSTALL_DIR"
    python3 main.py
    cd ..
    
    echo
}

main() {
    while true; do
        clear_screen
        display_banner
        show_menu
        read choice
        
        case $choice in
            1) install_dor ;;
            2) update_dor ;;
            3) run_dor ;;
            4) wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/dom.sh && chmod +x dom.sh && ./dom.sh;;
            0) menu ;;
        esac
        
        echo
        echo -e "${YELLOW}Tekan Enter untuk melanjutkan...${END}"
        read
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}❌ Dihentikan${END}"; exit 1' INT

# Run
main
