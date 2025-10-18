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
REPO_URL="https://github.com/purplemashu/me-cli"
INSTALL_DIR="me-cli"

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
    echo "║              DOR MANAGER             ║"
    echo "║         Auto Install & Update        ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

check_install() {
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/main.py" ]; then
        echo "1"
    else
        echo "0"
    fi
}

show_menu() {
    local installed=$(check_install)
    
    if [ "$installed" = "1" ]; then
        STATUS_ICON="${GREEN}✅${END}"
        STATUS_TEXT="${GREEN}Terinstall${END}"
    else
        STATUS_ICON="${RED}❌${END}"
        STATUS_TEXT="${RED}Belum Install${END}"
    fi
    
    echo -e "${CYAN}📋 MENU UTAMA:${END}"
    echo
    echo -e "1. ${GREEN}📥 INSTALL DOR${END}       $STATUS_ICON $STATUS_TEXT"
    echo -e "2. ${YELLOW}🔄 UPDATE DOR${END}"
    echo -e "3. ${BLUE}🚀 JALANKAN DOR${END} (cd me-cli && python3 main.py)"
    echo -e "4. ${MAGENTA}⚙️  SETUP ENVIRONMENT${END}"
    echo -e "5. ${WHITE}ℹ️  INFO & BANTUAN${END}"
    echo -e "0. ${RED}❌ KELUAR${END}"
    echo
    echo -n -e "${YELLOW}Pilih menu (0-5): ${END}"
}

install_dor() {
    clear_screen
    echo -e "${CYAN}🚀 MEMULAI INSTALASI DOR...${END}"
    echo
    
    # Remove old installation
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Menghapus instalasi lama..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Step-by-step installation
    print_info "1. Update system..."
    sudo apt update && sudo apt upgrade -y
    if [ $? -eq 0 ]; then
        print_success "System updated"
    else
        print_warning "Update system ada masalah, lanjut..."
    fi
    
    print_info "2. Install Git..."
    sudo apt install git -y
    if [ $? -eq 0 ]; then
        print_success "Git installed"
    else
        print_error "Gagal install Git!"
        return 1
    fi
    
    print_info "3. Install Python3..."
    sudo apt install python3 python3-pip -y
    if [ $? -eq 0 ]; then
        print_success "Python3 installed"
    else
        print_error "Gagal install Python3!"
        return 1
    fi
    
    # Create python alias if not exists
    if ! command -v python &> /dev/null; then
        sudo ln -s /usr/bin/python3 /usr/bin/python
        print_success "Created python alias"
    fi
    
    print_info "4. Clone repository..."
    git clone "$REPO_URL"
    if [ $? -eq 0 ]; then
        print_success "Repository cloned"
    else
        print_error "Gagal clone repository!"
        return 1
    fi
    
    print_info "5. Install Python packages..."
    cd "$INSTALL_DIR"
    
    # Upgrade pip first
    pip3 install --upgrade pip
    
    # Install basic packages without specific versions
    pip3 install requests colorama pillow python-dotenv
    
    # Try to install from requirements.txt but ignore version errors
    if [ -f "requirements.txt" ]; then
        print_info "Mencoba install requirements.txt..."
        # Remove specific versions from requirements.txt
        grep -v '==' requirements.txt > requirements_simple.txt
        pip3 install -r requirements_simple.txt
        rm -f requirements_simple.txt
    fi
    
    cd ..
    
    print_success "Python packages installed"
    
    # Verify installation
    if [ -f "$INSTALL_DIR/main.py" ]; then
        print_success "🎉 DOR BERHASIL DIINSTALL!"
        echo -e "${GREEN}Lokasi: $(pwd)/$INSTALL_DIR${END}"
        
        # Test Python
        echo
        print_info "Testing Python..."
        if python3 --version; then
            print_success "Python3 bekerja"
        fi
    else
        print_error "File main.py tidak ditemukan!"
    fi
    
    echo
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

update_dor() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "DOR belum terinstall!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🔄 UPDATE DOR...${END}"
    echo
    
    cd "$INSTALL_DIR"
    
    print_info "Update dari GitHub..."
    git pull --rebase
    
    print_info "Update Python packages..."
    pip3 install --upgrade pip
    pip3 install requests colorama pillow python-dotenv --upgrade
    
    # Try to update requirements.txt if exists
    if [ -f "requirements.txt" ]; then
        grep -v '==' requirements.txt > requirements_simple.txt
        pip3 install -r requirements_simple.txt --upgrade
        rm -f requirements_simple.txt
    fi
    
    cd ..
    
    print_success "Update selesai!"
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

run_dor() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install DOR dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}🚀 MENJALANKAN DOR...${END}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${END}"
    echo -e "${CYAN}========================================${END}"
    echo
    
    cd "$INSTALL_DIR"
    python3 main.py
    cd ..
    
    echo
    echo -e "${CYAN}========================================${END}"
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

setup_environment() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install DOR dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
        read
        return
    fi
    
    echo -e "${CYAN}⚙️  SETUP ENVIRONMENT${END}"
    echo
    echo -e "${GREEN}Langkah-langkah:${END}"
    echo -e "1. ${WHITE}Buka: https://rentry.co/me-cli${END}"
    echo -e "2. ${WHITE}Copy semua text${END}"
    echo -e "3. ${WHITE}Buat file .env di folder me-cli${END}"
    echo
    echo -e "${YELLOW}Command:${END}"
    echo -e "${WHITE}nano me-cli/.env${END}"
    echo
    echo -e "${YELLOW}Cara pakai nano:${END}"
    echo -e "${WHITE}- Paste text dari rentry.co${END}"
    echo -e "${WHITE}- Tekan Ctrl+X${END}"
    echo -e "${WHITE}- Tekan Y untuk simpan${END}"
    echo -e "${WHITE}- Tekan Enter untuk konfirmasi${END}"
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk buka browser...${END}"
    read
    xdg-open "https://rentry.co/me-cli" 2>/dev/null || \
    echo -e "${RED}Tidak bisa buka browser otomatis${END}"
    echo -e "${YELLOW}Buka manual: https://rentry.co/me-cli${END}"
    
    echo
    echo -e "${YELLOW}Setelah selesai, tekan Enter...${END}"
    read
}

show_info() {
    clear_screen
    echo -e "${CYAN}ℹ️  INFO & BANTUAN${END}"
    echo
    
    local installed=$(check_install)
    echo -e "${GREEN}📊 STATUS:${END}"
    if [ "$installed" = "1" ]; then
        echo -e "DOR: ${GREEN}✅ Terinstall${END}"
        
        # Check Python
        if command -v python3 &> /dev/null; then
            echo -e "Python3: ${GREEN}✅ Terinstall${END}"
        else
            echo -e "Python3: ${RED}❌ Tidak terinstall${END}"
        fi
        
        # Check main.py
        if [ -f "$INSTALL_DIR/main.py" ]; then
            echo -e "main.py: ${GREEN}✅ Ditemukan${END}"
        else
            echo -e "main.py: ${RED}❌ Tidak ditemukan${END}"
        fi
    else
        echo -e "DOR: ${RED}❌ Belum Install${END}"
    fi
    echo
    
    echo -e "${GREEN}🐛 MASALAH UMUM:${END}"
    echo -e "${WHITE}• Python: gunakan python3 bukan python${END}"
    echo -e "${WHITE}• Requirements: skip jika ada error version${END}"
    echo -e "${WHITE}• Environment: buat file .env di folder me-cli${END}"
    echo
    
    echo -e "${GREEN}📚 COMMAND MANUAL:${END}"
    echo -e "${WHITE}git clone https://github.com/purplemashu/me-cli${END}"
    echo -e "${WHITE}cd me-cli${END}"
    echo -e "${WHITE}pip3 install requests colorama pillow python-dotenv${END}"
    echo -e "${WHITE}python3 main.py${END}"
    echo
    
    echo -e "${GREEN}🔧 ENVIRONMENT:${END}"
    echo -e "${WHITE}https://rentry.co/me-cli${END}"
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}"
    read
}

# Main loop
main() {
    while true; do
        clear_screen
        display_banner
        show_menu
        read -r choice
        
        case $choice in
            1) install_dor ;;
            2) update_dor ;;
            3) run_dor ;;
            4) setup_environment ;;
            5) show_info ;;
            0) 
                echo -e "${GREEN}👋 Sampai jumpa!${END}"
                exit 0 
                ;;
            *) 
                print_error "Pilihan salah!"
                sleep 2 
                ;;
        esac
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${RED}❌ Dihentikan${END}"; exit 1' INT

# Run
main
