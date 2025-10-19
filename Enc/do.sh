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
    echo -e "${1}${2}${END}
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
    echo -e "${MAGENTA}${BOLD}
    echo "╔══════════════════════════════════════╗"
    echo "║              DOR MANAGER             ║"
    echo "║         Auto Install & Update        ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}
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
        STATUS_ICON="${GREEN}✅${END}
        STATUS_TEXT="${GREEN}Terinstall${END}
    else
        STATUS_ICON="${RED}❌${END}
        STATUS_TEXT="${RED}Belum Install${END}
    fi
    
    echo -e "${CYAN}📋 MENU UTAMA:${END}
    echo
    echo -e "1. ${GREEN}📥 INSTALL DOR${END}       $STATUS_ICON $STATUS_TEXT"
    echo -e "2. ${YELLOW}🔄 UPDATE DOR${END}
    echo -e "3. ${BLUE}🚀 JALANKAN DOR${END}
    echo -e "4. ${MAGENTA}⚙️  SETUP ENVIRONMENT${END}
    echo -e "5. ${WHITE}ℹ️  INFO & BANTUAN${END}
    echo -e "0. ${RED}❌ KELUAR${END}
    echo
    echo -n -e "${YELLOW}Pilih menu (0-5): ${END}
}

install_dor() {
    clear_screen
    echo -e "${CYAN}🚀 MEMULAI INSTALASI DOR...${END}
    echo -e "${RED}⚠️  JANGAN SKIP SATU COMMAND PUN!${END}
    echo
    
    # Confirmation
    echo -n -e "${YELLOW}Lanjutkan instalasi? (y/N): ${END}
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_warning "Instalasi dibatalkan!"
        return
    fi
    
    # Remove old installation
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Menghapus instalasi lama..."
        rm -rf "$INSTALL_DIR"
    fi
    
    echo -e "${CYAN}🧋 FIRST TIME SETUP:${END}
    echo
    
    # Step 1: Update system
    print_info "1. apt update && apt upgrade -y"
    echo -e "${YELLOW}Executing...${END}
    sudo apt update && sudo apt upgrade -y
    if [ $? -eq 0 ]; then
        print_success "System updated"
    else
        print_warning "Ada masalah, tapi lanjut..."
    fi
    echo
    
    # Step 2: Install Git
    print_info "2. apt install git -y"
    echo -e "${YELLOW}Executing...${END}
    sudo apt install git -y
    if [ $? -eq 0 ]; then
        print_success "Git installed"
    else
        print_error "Gagal install Git!"
        return 1
    fi
    echo
    
    # Step 3: Install Python
    print_info "3. apt install python3 python3-pip -y"
    echo -e "${YELLOW}Executing...${END}
    sudo apt install python3 python3-pip -y
    if [ $? -eq 0 ]; then
        print_success "Python3 installed"
        
        # Create python alias
        if ! command -v python &> /dev/null; then
            sudo ln -s /usr/bin/python3 /usr/bin/python
            print_success "Created python alias"
        fi
    else
        print_error "Gagal install Python3!"
        return 1
    fi
    echo
    
    # Step 4: Install system dependencies for Crypto
    print_info "4. Install system dependencies..."
    echo -e "${YELLOW}Executing...${END}
    sudo apt install python3-dev libssl-dev libffi-dev build-essential -y
    if [ $? -eq 0 ]; then
        print_success "System dependencies installed"
    else
        print_warning "Ada masalah dependencies, lanjut..."
    fi
    echo
    
    # Step 5: Install Pillow dependencies
    print_info "5. apt install python3-pil -y"
    echo -e "${YELLOW}Executing...${END}
    sudo apt install python3-pil -y
    if [ $? -eq 0 ]; then
        print_success "Pillow dependencies installed"
    else
        print_warning "Pillow mungkin bermasalah, lanjut..."
    fi
    echo
    
    # Step 6: Clone repository
    print_info "6. git clone $REPO_URL"
    echo -e "${YELLOW}Executing...${END}
    git clone "$REPO_URL"
    if [ $? -eq 0 ]; then
        print_success "Repository cloned"
    else
        print_error "Gagal clone repository!"
        return 1
    fi
    echo
    
    # Step 7: Install ALL Python packages - COMPLETE VERSION
    print_info "7. Install SEMUA Python packages..."
    cd "$INSTALL_DIR"
    
    # Upgrade pip first
    pip3 install --upgrade pip
    pip3 install --upgrade setuptools wheel
    
    # Install basic packages
    print_info "Installing basic packages..."
    pip3 install requests colorama pillow python-dotenv ascii_magic pyfiglet
    
    # Install Crypto packages
    print_info "Installing crypto packages..."
    pip3 install pycryptodome cryptography
    
    # Install additional packages yang biasanya diperlukan
    print_info "Installing additional packages..."
    pip3 install datetime pathlib json random time os sys base64 hashlib hmac urllib
    
    # Try to install from requirements.txt tanpa version
    if [ -f "requirements.txt" ]; then
        print_info "Mencoba install requirements.txt..."
        # Remove specific versions dan empty lines
        grep -v '==' requirements.txt | grep -v '^$' > requirements_simple.txt
        if [ -s requirements_simple.txt ]; then
            pip3 install -r requirements_simple.txt
        fi
        rm -f requirements_simple.txt
    fi
    
    cd ..
    print_success "Semua Python packages installed"
    echo
    
    # Step 8: Test ALL modules
    print_info "8. Testing SEMUA modules..."
    cd "$INSTALL_DIR"
    
    # Test basic modules
    if python3 -c "import requests, colorama, pillow, ascii_magic, pyfiglet; print('✅ Basic modules OK')" 2>/dev/null; then
        print_success "Basic modules work"
    else
        print_warning "Beberapa basic modules bermasalah"
    fi
    
    # Test crypto modules
    if python3 -c "from Crypto.Cipher import AES; import cryptography; print('✅ Crypto modules OK')" 2>/dev/null; then
        print_success "Crypto modules work"
    else
        print_error "Crypto modules bermasalah!"
        print_info "Mencoba install ulang crypto..."
        pip3 install --force-reinstall pycryptodome cryptography
    fi
    
    # Test run main.py
    print_info "Testing main.py..."
    timeout 10s python3 main.py --help 2>/dev/null && print_success "Main.py berhasil" || print_warning "Main.py ada warning"
    
    cd ..
    echo
    
    # Final verification
    if [ -f "$INSTALL_DIR/main.py" ]; then
        print_success "🎉 DOR BERHASIL DIINSTALL!"
        echo -e "${GREEN}Lokasi: $(pwd)/$INSTALL_DIR${END}
        
        # Show next steps
        echo
        echo -e "${YELLOW}📋 Langkah selanjutnya:${END}
        echo -e "${WHITE}1. Setup Environment (Menu 4) - WAJIB!${END}
        echo -e "${WHITE}2. Jalankan DOR (Menu 3)${END}
    else
        print_error "❌ Instalasi gagal!"
    fi
    
    echo
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
    read
}

update_dor() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "DOR belum terinstall!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
        read
        return
    fi
    
    echo -e "${CYAN}🔄 UPDATE DOR...${END}
    echo
    
    print_info "Update dari GitHub..."
    cd "$INSTALL_DIR"
    git pull --rebase
    cd ..
    echo
    
    print_info "Update SEMUA Python packages..."
    cd "$INSTALL_DIR"
    
    # Update semua packages
    pip3 install --upgrade pip
    pip3 install requests colorama pillow python-dotenv ascii_magic pyfiglet pycryptodome cryptography --upgrade
    
    # Update requirements jika ada
    if [ -f "requirements.txt" ]; then
        grep -v '==' requirements.txt | grep -v '^$' > requirements_simple.txt
        if [ -s requirements_simple.txt ]; then
            pip3 install -r requirements_simple.txt --upgrade
        fi
        rm -f requirements_simple.txt
    fi
    
    cd ..
    echo
    
    print_success "Update selesai!"
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
    read
}

run_dor() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install DOR dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
        read
        return
    fi
    
    echo -e "${CYAN}🚀 MENJALANKAN DOR...${END}
    echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${END}
    echo -e "${CYAN}========================================${END}
    echo
    
    # Check and install missing modules before run
    cd "$INSTALL_DIR"
    print_info "Checking modules..."
    if ! python3 -c "from Crypto.Cipher import AES" 2>/dev/null; then
        print_warning "Module Crypto missing, installing..."
        pip3 install pycryptodome
    fi
    
    if ! python3 -c "import cryptography" 2>/dev/null; then
        print_warning "Module cryptography missing, installing..."
        pip3 install cryptography
    fi
    cd ..
    
    # Run the script
    cd "$INSTALL_DIR"
    python3 main.py
    cd ..
    
    echo
    echo -e "${CYAN}========================================${END}
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
    read
}

setup_environment() {
    clear_screen
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Install DOR dulu!"
        echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
        read
        return
    fi
    
    echo -e "${CYAN}⚙️  SETUP ENVIRONMENT VARIABLES${END}
    echo
    echo -e "${GREEN}1. Buka: https://rentry.co/me-cli${END}
    echo -e "${GREEN}2. Copy semua text${END}
    echo -e "${GREEN}3. Buat file .env di folder me-cli${END}
    echo
    echo -e "${YELLOW}Command:${END}
    echo -e "${WHITE}nano me-cli/.env${END}
    echo
    echo -e "${YELLOW}Cara:${END}
    echo -e "${WHITE}- Paste text dari rentry.co${END}
    echo -e "${WHITE}- Ctrl+X → Y → Enter${END}
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk lanjut...${END}
    read
    
    # Create env file template
    cd "$INSTALL_DIR"
    if [ ! -f ".env" ]; then
        echo "# Add your environment variables here" > .env
        echo "# Copy from https://rentry.co/me-cli" >> .env
        print_info "File .env template dibuat, edit dengan: nano .env"
    else
        print_info "File .env sudah ada, edit dengan: nano .env"
    fi
    cd ..
    
    echo
    echo -e "${YELLOW}Setelah selesai, tekan Enter...${END}
    read
}

show_info() {
    clear_screen
    echo -e "${CYAN}ℹ️  INFO & BANTUAN${END}
    echo
    
    echo -e "${GREEN}🧋 FIRST TIME SETUP:${END}
    echo -e "${WHITE}apt update && apt upgrade -y${END}
    echo -e "${WHITE}apt install git -y${END}
    echo -e "${WHITE}apt install python3 python3-pip -y${END}
    echo -e "${WHITE}apt install python3-pil -y${END}
    echo -e "${WHITE}git clone https://github.com/purplemashu/me-cli${END}
    echo -e "${WHITE}cd me-cli && pip3 install -r requirements.txt${END}
    echo -e "${WHITE}python3 main.py${END}
    echo
    echo -e "${RED}🚫 JANGAN SKIP SATU COMMAND PUN!${END}
    echo
    echo -e "${GREEN}🔧 MODULES YANG DIPERLUKAN:${END}
    echo -e "${WHITE}• requests, colorama, pillow, python-dotenv${END}
    echo -e "${WHITE}• ascii_magic, pyfiglet${END}
    echo -e "${WHITE}• pycryptodome, cryptography (UNTUK CRYPTO)${END}
    echo
    echo -e "${YELLOW}🐛 FIX MODULE ERROR:${END}
    echo -e "${WHITE}cd me-cli${END}
    echo -e "${WHITE}pip3 install pycryptodome cryptography${END}
    echo
    echo -e "${GREEN}🔄 UPDATE:${END}
    echo -e "${WHITE}cd me-cli && git pull --rebase${END}
    echo -e "${WHITE}cd me-cli && pip3 install -r requirements.txt${END}
    echo
    echo -e "${GREEN}🔧 ENVIRONMENT:${END}
    echo -e "${WHITE}https://rentry.co/me-cli${END}
    echo
    
    echo -e "${YELLOW}Tekan Enter untuk kembali...${END}
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
                echo -e "${GREEN}👋 Sampai jumpa!${END}
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
