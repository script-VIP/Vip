#!/bin/bash

# Colors
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
RED='\033[91m'
END='\033[0m'

INSTALL_DIR="me-cli"

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║             MENU DOR CLI             ║"
    echo "║              Quick Run               ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

check_install() {
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/main.py" ]; then
        return 0
    else
        return 1
    fi
}

show_menu() {
    echo -e "${GREEN}📋 MENU DOR:${END}"
    echo
    
    if check_install; then
        echo -e "Status: ${GREEN}✅ Terinstall${END}"
    else
        echo -e "Status: ${RED}❌ Belum Install${END}"
    fi
    
    echo
    echo -e "1. 🚀 JALANKAN DOR CLI"
    echo -e "2. ⚙️  SETUP ENVIRONMENT"
    echo -e "3. 📁 LIHAT FOLDER"
    echo -e "0. ❌ KELUAR"
    echo
    echo -n -e "${YELLOW}Pilih menu (0-3): ${END}"
}

run_dor() {
    if ! check_install; then
        echo -e "${RED}DOR CLI belum terinstall!${END}"
        echo -e "${BLUE}Jalankan install.sh terlebih dahulu${END}"
        return
    fi
    
    echo -e "${YELLOW}🚀 Menjalankan DOR CLI...${END}"
    echo -e "${BLUE}Tekan Ctrl+C untuk berhenti${END}"
    echo -e "${GREEN}========================================${END}"
    echo
    
    cd "$INSTALL_DIR"
    python3 main.py
    cd ..
    
    echo
    echo -e "${GREEN}========================================${END}"
}

setup_environment() {
    if ! check_install; then
        echo -e "${RED}Install DOR CLI dulu!${END}"
        return
    fi
    
    echo -e "${YELLOW}⚙️  Setup Environment Variables${END}"
    echo
    echo -e "${BLUE}1. Buka: https://rentry.co/me-cli${END}"
    echo -e "${BLUE}2. Copy semua text${END}"
    echo -e "${BLUE}3. Buat file .env di folder me-cli${END}"
    echo
    echo -e "${GREEN}Command:${END}"
    echo -e "nano me-cli/.env"
    echo
    echo -e "${YELLOW}Cara:${END}"
    echo -e "- Paste text dari rentry.co"
    echo -e "- Ctrl+X → Y → Enter"
    echo
    
    # Buat file .env jika belum ada
    cd "$INSTALL_DIR"
    if [ ! -f ".env" ]; then
        echo "# Environment variables" > .env
        echo "# Copy dari https://rentry.co/me-cli" >> .env
        echo -e "${GREEN}File .env template dibuat${END}"
    fi
    cd ..
    
    echo
    echo -e "${YELLOW}Setelah selesai, jalankan DOR CLI lagi${END}"
}

view_folder() {
    if ! check_install; then
        echo -e "${RED}DOR CLI belum terinstall!${END}"
        return
    fi
    
    echo -e "${YELLOW}📁 Isi Folder me-cli:${END}"
    echo
    ls -la "$INSTALL_DIR"
    echo
    echo -e "${BLUE}Total files: $(find "$INSTALL_DIR" -type f | wc -l)${END}"
}

main() {
    while true; do
        clear_screen
        display_banner
        show_menu
        read choice
        
        case $choice in
            1) run_dor ;;
            2) setup_environment ;;
            3) view_folder ;;
            0) 
                echo -e "${GREEN}👋 Sampai jumpa!${END}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Pilihan salah!${END}"
                sleep 2 
                ;;
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
