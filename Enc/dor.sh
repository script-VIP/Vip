#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
MAGENTA='\033[95m'
CYAN='\033[96m'
WHITE='\033[97m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
END='\033[0m'

# Config
SCRIPT_NAME="main.py"
REPO_URL="https://github.com/purplemashu/me-cli"
INSTALL_DIR="me-cli"
ENV_FILE="$INSTALL_DIR/.env"

# Functions
print_color() {
    echo -e "${1}${2}${END}"
}

print_success() {
    print_color "$GREEN" "✅ $1"
}

print_error() {
    print_color "$RED" "❌ $1"
}

print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

print_info() {
    print_color "$BLUE" "🧋 $1"
}

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════╗"
    echo "║           ME-CLI MANAGER             ║"
    echo "║        Auto Install & Update         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

check_status() {
    if [ -d "$INSTALL_DIR" ]; then
        INSTALLED=1
        if [ -f "$ENV_FILE" ]; then
            ENV_SETUP=1
        else
            ENV_SETUP=0
        fi
        if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
            READY=1
        else
            READY=0
        fi
    else
        INSTALLED=0
        ENV_SETUP=0
        READY=0
    fi
}

show_menu() {
    check_status
    
    if [ $INSTALLED -eq 1 ]; then
        STATUS_ICON="✅"
        STATUS_TEXT="${GREEN}Aktif${END}"
    else
        STATUS_ICON="❌"
        STATUS_TEXT="${RED}Tidak Aktif${END}"
    fi
    
    echo -e "${CYAN}📋 MENU UTAMA:${END}"
    echo
    echo -e "1. ${GREEN}📥 INSTALL ME-CLI${END}       $STATUS_ICON $STATUS_TEXT"
    echo -e "2. ${YELLOW}🔄 UPDATE ME-CLI${END}"
    echo -e "3. ${BLUE}🚀 JALANKAN ME-CLI${END}"
    echo -e "4. ${MAGENTA}⚙️  SETUP ENVIRONMENT${END}"
    echo -e "5. ${CYAN}ℹ️  INFO & BANTUAN${END}"
    echo -e "0. ${RED}❌ KELUAR${END}"
    echo
    echo -n -e "${YELLOW}Pilih menu (0-5): ${END}"
}

install_me_cli() {
    clear_screen
    echo -e "${CYAN}🚀 MEMULAI INSTALASI ME-CLI...${END}"
    echo -e "${YELLOW}Pastikan koneksi internet stabil!${END}"
    echo
    
    commands=(
        "apt update && apt full-upgrade -y"
        "pkg install git -y"
        "pkg install python -y"
        "apt install python-pillow -y"
        "git clone $REPO_URL"
        "cd $INSTALL_DIR && pip install -r requirements.txt"
    )
    
    descriptions=(
        "Update system packages"
        "Install Git"
        "Install Python"
        "Install Python Pillow"
        "Clone repository me-cli"
        "Install Python requirements"
    )
    
    for i in "${!commands[@]}"; do
        cmd="${commands[$i]}"
        desc="${descriptions[$i]}"
        
        print_info "$desc..."
        echo -e "${YELLOW}\$ $cmd${END}"
        
        if eval "$cmd"; then
            print_success "Berhasil"
        else
            print_error "Gagal"
            print_warning "Lanjutkan ke step berikutnya..."
        fi
        
        echo
    done
    
    print_success "INSTALASI SELESAI!"
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${END}"
    read
}

update_me_cli() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "me-cli belum terinstall!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🔄 MEMPERBARUI ME-CLI...${END}"
    echo
    
    commands=(
        "cd $INSTALL_DIR && git pull --rebase"
        "cd $INSTALL_DIR && pip install -r requirements.txt"
    )
    
    for cmd in "${commands[@]}"; do
        echo -e "${YELLOW}\$ $cmd${END}"
        if eval "$cmd"; then
            print_success "Berhasil"
        else
            print_error "Gagal"
        fi
        echo
    done
    
    print_success "UPDATE SELESAI!"
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

run_me_cli() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "me-cli belum terinstall!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🚀 MENJALANKAN ME-CLI...${END}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${END}"
    echo
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        cd "$INSTALL_DIR" && python "$SCRIPT_NAME"
        cd ..
    else
        print_error "File $SCRIPT_NAME tidak ditemukan!"
    fi
    
    echo
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

setup_environment() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install me-cli dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}⚙️  SETUP ENVIRONMENT VARIABLES${END}"
    echo
    echo -e "${GREEN}1. Buka: ${WHITE}https://rentry.co/me-cli${END}"
    echo -e "${GREEN}2. Copy semua text${END}"
    echo -e "${GREEN}3. Buat file .env di folder me-cli${END}"
    echo
    echo -e "${YELLOW}Command manual:${END}"
    echo -e "${WHITE}nano $INSTALL_DIR/.env${END}"
    echo -e "${WHITE}# Paste content, lalu Ctrl+X → Y → Enter${END}"
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk membuka browser...${END}"
    read
    termux-open-url "https://rentry.co/me-cli"
    
    echo
    echo -e "${YELLOW}Setelah selesai setup, tekan Enter untuk kembali...${END}"
    read
}

show_info() {
    clear_screen
    echo -e "${CYAN}ℹ️  INFO & BANTUAN${END}"
    echo
    echo -e "${GREEN}📚 First Time Install:${END}"
    echo -e "${WHITE}apt update && apt full-upgrade${END}"
    echo -e "${WHITE}pkg install git${END}"
    echo -e "${WHITE}pkg install python${END}"
    echo -e "${WHITE}apt install python-pillow${END}"
    echo -e "${WHITE}git clone https://github.com/purplemashu/me-cli${END}"
    echo -e "${WHITE}cd me-cli && pip install -r requirements.txt${END}"
    echo -e "${WHITE}python main.py${END}"
    echo
    echo -e "${RED}🚫 JANGAN SKIP SATU COMMAND PUN!${END}"
    echo
    echo -e "${GREEN}🔄 Update:${END}"
    echo -e "${WHITE}cd me-cli && git pull --rebase${END}"
    echo -e "${WHITE}cd me-cli && pip install -r requirements.txt${END}"
    echo
    echo -e "${GREEN}🔧 Environment:${END}"
    echo -e "${WHITE}https://rentry.co/me-cli${END}"
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

# Main menu loop
main() {
    while true; do
        display_banner
        show_menu
        read choice
        
        case $choice in
            1)
                install_me_cli
                ;;
            2)
                update_me_cli
                ;;
            3)
                run_me_cli
                ;;
            4)
                setup_environment
                ;;
            5)
                show_info
                ;;
            0)
                echo -e "${GREEN}👋 Sampai jumpa!${END}"
                exit 0
                ;;
            *)
                print_error "Pilihan tidak valid!"
                sleep 1
                ;;
        esac
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}❌ Dihentikan oleh user${END}"; exit 1' INT

# Run main function
main
