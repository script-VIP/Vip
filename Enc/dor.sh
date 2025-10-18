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
        STATUS_TEXT="${GREEN}Terinstall${END}"
    else
        STATUS_ICON="❌"
        STATUS_TEXT="${RED}Belum Install${END}"
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

run_command() {
    local cmd="$1"
    local desc="$2"
    
    print_info "$desc"
    echo -e "${YELLOW}╰→ \$ $cmd${END}"
    echo -e "${CYAN}----------------------------------------${END}"
    
    # Execute command and capture output
    if eval "$cmd" 2>&1 | while IFS= read -r line; do
        echo -e "${WHITE}$line${END}"
    done; then
        print_success "Berhasil: $desc"
        return 0
    else
        print_error "Gagal: $desc"
        return 1
    fi
    echo
}

install_me_cli() {
    clear_screen
    echo -e "${CYAN}🚀 MEMULAI INSTALASI ME-CLI...${END}"
    echo -e "${YELLOW}Pastikan koneksi internet stabil!${END}"
    echo
    echo -e "${RED}⚠️  JANGAN SKIP SATU COMMAND PUN!${END}"
    echo
    
    # Confirmation
    echo -e "${YELLOW}Apakah Anda yakin ingin melanjutkan instalasi? (y/N): ${END}"
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Instalasi dibatalkan!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 1: Update system
    if ! run_command "apt update && apt full-upgrade -y" "Update system packages"; then
        print_error "Gagal update system!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 2: Install Git
    if ! run_command "pkg install git -y" "Install Git"; then
        print_error "Gagal install Git!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 3: Install Python
    if ! run_command "pkg install python -y" "Install Python"; then
        print_error "Gagal install Python!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 4: Install Pillow
    if ! run_command "apt install python-pillow -y" "Install Python Pillow"; then
        print_warning "Pillow mungkin sudah terinstall, lanjutkan..."
    fi
    
    # Step 5: Clone repository
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Folder $INSTALL_DIR sudah ada, menghapus..."
        rm -rf "$INSTALL_DIR"
    fi
    
    if ! run_command "git clone $REPO_URL" "Clone repository me-cli"; then
        print_error "Gagal clone repository!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 6: Install requirements
    if [ -d "$INSTALL_DIR" ]; then
        if ! run_command "cd $INSTALL_DIR && pip install -r requirements.txt" "Install Python requirements"; then
            print_warning "Coba install requirements manual..."
            run_command "cd $INSTALL_DIR && pip install requests colorama pillow python-dotenv" "Install packages manual"
        fi
    else
        print_error "Folder $INSTALL_DIR tidak ditemukan!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    # Step 7: Test run
    print_info "Testing instalasi..."
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        print_success "File $SCRIPT_NAME ditemukan!"
        echo -e "${YELLOW}Menjalankan test...${END}"
        
        # Try to run the script
        cd "$INSTALL_DIR"
        if python --version > /dev/null 2>&1; then
            print_success "Python berhasil diakses"
            if timeout 10s python -c "print('Test berhasil!')" 2>/dev/null; then
                print_success "Script siap dijalankan!"
            else
                print_warning "Script mungkin butuh environment variables"
            fi
        else
            print_error "Python tidak bisa diakses"
        fi
        cd ..
    else
        print_error "File $SCRIPT_NAME tidak ditemukan!"
    fi
    
    # Final message
    echo
    echo -e "${GREEN}========================================${END}"
    print_success "🎉 INSTALASI SELESAI!"
    echo -e "${GREEN}========================================${END}"
    echo
    echo -e "${CYAN}📋 Langkah selanjutnya:${END}"
    echo -e "${WHITE}1. Setup Environment Variables (Menu 4)${END}"
    echo -e "${WHITE}2. Jalankan me-cli (Menu 3)${END}"
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
    
    # Update from git
    if run_command "cd $INSTALL_DIR && git pull --rebase" "Update dari GitHub"; then
        print_success "Update code berhasil"
    else
        print_warning "Coba metode alternatif..."
        run_command "cd $INSTALL_DIR && git fetch --all && git reset --hard origin/main" "Force update"
    fi
    
    # Update requirements
    if run_command "cd $INSTALL_DIR && pip install -r requirements.txt" "Update dependencies"; then
        print_success "Update dependencies berhasil"
    else
        print_warning "Coba update pip manual"
        run_command "cd $INSTALL_DIR && pip install --upgrade pip" "Update pip"
        run_command "cd $INSTALL_DIR && pip install -r requirements.txt --force-reinstall" "Reinstall requirements"
    fi
    
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
    python "$SCRIPT_NAME"
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
    termux-open-url "https://rentry.co/me-cli" 2>/dev/null || \
    xdg-open "https://rentry.co/me-cli" 2>/dev/null || \
    echo -e "${RED}Tidak bisa membuka browser, buka manual: https://rentry.co/me-cli${END}"
    
    echo
    echo -e "${YELLOW}Setelah selesai setup, tekan Enter untuk kembali...${END}"
    read
}

show_info() {
    clear_screen
    echo -e "${CYAN}ℹ️  INFO & BANTUAN${END}"
    echo
    echo -e "${GREEN}📚 First Time Install (WAJIB URUT):${END}"
    echo -e "${WHITE}1. apt update && apt full-upgrade${END}"
    echo -e "${WHITE}2. pkg install git${END}"
    echo -e "${WHITE}3. pkg install python${END}"
    echo -e "${WHITE}4. apt install python-pillow${END}"
    echo -e "${WHITE}5. git clone https://github.com/purplemashu/me-cli${END}"
    echo -e "${WHITE}6. cd me-cli && pip install -r requirements.txt${END}"
    echo -e "${WHITE}7. python main.py${END}"
    echo
    echo -e "${RED}🚫 JANGAN SKIP SATU COMMAND PUN!${END}"
    echo -e "${YELLOW}Banyak yang sok paham & skip command, akhirnya stuck!${END}"
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
