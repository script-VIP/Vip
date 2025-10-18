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
    # Reset status
    INSTALLED=0
    ENV_SETUP=0
    READY=0
    
    # Check if installed
    if [ -d "$INSTALL_DIR" ]; then
        INSTALLED=1
        # Check if env file exists
        if [ -f "$ENV_FILE" ]; then
            ENV_SETUP=1
        fi
        # Check if main.py exists and can run
        if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
            READY=1
        fi
    fi
}

show_menu() {
    check_status
    
    # Status display
    if [ $INSTALLED -eq 1 ]; then
        STATUS_ICON="${GREEN}✅${END}"
        STATUS_TEXT="${GREEN}Terinstall${END}"
    else
        STATUS_ICON="${RED}❌${END}"
        STATUS_TEXT="${RED}Belum Install${END}"
    fi
    
    echo -e "${CYAN}📋 MENU UTAMA:${END}"
    echo
    echo -e "1. ${GREEN}📥 INSTALL ME-CLI${END}       $STATUS_ICON $STATUS_TEXT"
    echo -e "2. ${YELLOW}🔄 UPDATE ME-CLI${END}"
    echo -e "3. ${BLUE}🚀 JALANKAN ME-CLI${END}"
    echo -e "4. ${MAGENTA}⚙️  SETUP ENVIRONMENT${END}"
    echo -e "5. ${CYAN}🎯 MENU DOR (python main.py)${END}"
    echo -e "6. ${WHITE}ℹ️  INFO & BANTUAN${END}"
    echo -e "0. ${RED}❌ KELUAR${END}"
    echo
    echo -n -e "${YELLOW}Pilih menu (0-6): ${END}"
}

run_command() {
    local cmd="$1"
    local desc="$2"
    
    print_info "$desc"
    echo -e "${YELLOW}╰→ \$ $cmd${END}"
    echo -e "${CYAN}----------------------------------------${END}"
    
    # Execute command
    if eval "$cmd > /dev/null 2>&1"; then
        print_success "Berhasil: $desc"
        echo
        return 0
    else
        print_error "Gagal: $desc"
        echo
        return 1
    fi
}

install_me_cli() {
    clear_screen
    echo -e "${CYAN}🚀 MEMULAI INSTALASI ME-CLI...${END}"
    echo -e "${RED}⚠️  JANGAN SKIP SATU COMMAND PUN!${END}"
    echo
    
    # Confirmation
    echo -n -e "${YELLOW}Apakah Anda yakin ingin melanjutkan instalasi? (y/N): ${END}"
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Instalasi dibatalkan!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Remove existing directory
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Menghapus folder lama..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Installation commands for Linux
    commands=(
        "sudo apt update && sudo apt upgrade -y"
        "sudo apt install git -y"
        "sudo apt install python3 python3-pip -y"
        "sudo apt install python3-pil -y"
        "git clone $REPO_URL"
        "cd $INSTALL_DIR && pip3 install -r requirements.txt"
    )
    
    descriptions=(
        "Update system packages"
        "Install Git"
        "Install Python3 dan pip3"
        "Install Python Pillow"
        "Clone repository me-cli"
        "Install Python requirements"
    )
    
    # Run all commands
    for i in "${!commands[@]}"; do
        cmd="${commands[$i]}"
        desc="${descriptions[$i]}"
        
        if ! run_command "$cmd" "$desc"; then
            print_warning "Lanjutkan ke step berikutnya..."
        fi
        sleep 1
    done
    
    # Verify installation
    print_info "Verifikasi instalasi..."
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        print_success "✅ ME-CLI berhasil diinstall!"
        echo -e "${GREEN}Lokasi: $(pwd)/$INSTALL_DIR${END}"
    else
        print_error "❌ Instalasi gagal! File main.py tidak ditemukan."
    fi
    
    echo
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
        "cd $INSTALL_DIR && pip3 install -r requirements.txt --upgrade"
    )
    
    for cmd in "${commands[@]}"; do
        if run_command "$cmd" "Update"; then
            print_success "Update berhasil"
        else
            print_warning "Ada masalah, tapi dilanjutkan..."
        fi
    done
    
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
    
    if [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        print_error "File $SCRIPT_NAME tidak ditemukan!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🚀 MENJALANKAN ME-CLI...${END}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${END}"
    echo -e "${CYAN}========================================${END}"
    echo
    
    # Run the script
    cd "$INSTALL_DIR"
    python3 "$SCRIPT_NAME"
    cd ..
    
    echo
    echo -e "${CYAN}========================================${END}"
    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${END}"
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
    echo -e "${GREEN}Langkah-langkah:${END}"
    echo -e "${WHITE}1. Buka: https://rentry.co/me-cli${END}"
    echo -e "${WHITE}2. Copy semua text yang ada${END}"
    echo -e "${WHITE}3. Buat file .env di folder me-cli${END}"
    echo
    echo -e "${YELLOW}Command untuk buat file:${END}"
    echo -e "${WHITE}nano $INSTALL_DIR/.env${END}"
    echo
    echo -e "${YELLOW}Setelah buka nano:${END}"
    echo -e "${WHITE}- Paste text dari rentry.co${END}"
    echo -e "${WHITE}- Tekan Ctrl+X${END}"
    echo -e "${WHITE}- Tekan Y untuk save${END}"
    echo -e "${WHITE}- Tekan Enter untuk konfirmasi${END}"
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk membuka browser...${END}"
    read
    xdg-open "https://rentry.co/me-cli" 2>/dev/null || echo -e "${RED}Buka manual: https://rentry.co/me-cli${END}"
    
    echo
    echo -e "${YELLOW}Setelah selesai setup, tekan Enter untuk kembali...${END}"
    read
}

show_dor_menu() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install me-cli dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🎯 MENU DOR - python main.py${END}"
    echo
    echo -e "${GREEN}Pilih opsi:${END}"
    echo -e "1. ${YELLOW}Jalankan normal (python main.py)${END}"
    echo -e "2. ${YELLOW}Jalankan dengan debug${END}"
    echo -e "3. ${YELLOW}Jalankan dengan options khusus${END}"
    echo -e "0. ${RED}Kembali ke menu utama${END}"
    echo
    echo -n -e "${YELLOW}Pilih opsi (0-3): ${END}"
    read -r dor_choice
    
    case $dor_choice in
        1)
            echo -e "${CYAN}🚀 Menjalankan: python main.py${END}"
            cd "$INSTALL_DIR"
            python3 main.py
            cd ..
            ;;
        2)
            echo -e "${CYAN}🐛 Menjalankan: python main.py --debug${END}"
            cd "$INSTALL_DIR"
            python3 main.py --debug
            cd ..
            ;;
        3)
            echo -n -e "${YELLOW}Masukkan options: ${END}"
            read -r options
            echo -e "${CYAN}🚀 Menjalankan: python main.py $options${END}"
            cd "$INSTALL_DIR"
            python3 main.py $options
            cd ..
            ;;
        0)
            return
            ;;
        *)
            print_error "Pilihan tidak valid!"
            ;;
    esac
    
    echo
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

show_info() {
    clear_screen
    echo -e "${CYAN}ℹ️  INFO & BANTUAN${END}"
    echo
    
    check_status
    echo -e "${GREEN}📊 STATUS SAAT INI:${END}"
    echo -e "Installed: $([ $INSTALLED -eq 1 ] && echo "✅" || echo "❌")"
    echo -e "Env Setup: $([ $ENV_SETUP -eq 1 ] && echo "✅" || echo "❌")"
    echo -e "Ready: $([ $READY -eq 1 ] && echo "✅" || echo "❌")"
    echo
    
    echo -e "${GREEN}📚 FIRST TIME INSTALL (WAJIB URUT):${END}"
    echo -e "${WHITE}1. sudo apt update && sudo apt upgrade -y${END}"
    echo -e "${WHITE}2. sudo apt install git -y${END}"
    echo -e "${WHITE}3. sudo apt install python3 python3-pip -y${END}"
    echo -e "${WHITE}4. sudo apt install python3-pil -y${END}"
    echo -e "${WHITE}5. git clone https://github.com/purplemashu/me-cli${END}"
    echo -e "${WHITE}6. cd me-cli && pip3 install -r requirements.txt${END}"
    echo -e "${WHITE}7. python3 main.py${END}"
    echo
    echo -e "${RED}🚫 JANGAN SKIP SATU COMMAND PUN!${END}"
    echo
    echo -e "${GREEN}🔄 UPDATE:${END}"
    echo -e "${WHITE}cd me-cli && git pull --rebase${END}"
    echo -e "${WHITE}cd me-cli && pip3 install -r requirements.txt${END}"
    echo
    echo -e "${GREEN}🔧 ENVIRONMENT:${END}"
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
        read -r choice
        
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
                show_dor_menu
                ;;
            6)
                show_info
                ;;
            0)
                echo -e "${GREEN}👋 Sampai jumpa!${END}"
                exit 0
                ;;
            *)
                print_error "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}❌ Dihentikan oleh user${END}"; exit 1' INT

# Run main function
main
