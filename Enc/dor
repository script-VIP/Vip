#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
END='\033[0m'

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

print_step() {
    print_color "$CYAN" "📦 $1"
}

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║           DOR CLI INSTALLER          ║"
    echo "║         First Time Setup             ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

# Main installation
install_dor() {
    display_banner
    
    echo -e "${YELLOW}🚀 Starting DOR CLI Installation...${END}"
    echo -e "${RED}⚠️  DON'T SKIP ANY STEP!${END}"
    echo
    
    # Step 1: Update system
    print_step "1. Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo
    
    # Step 2: Install Git
    print_step "2. Installing Git..."
    sudo apt install git -y
    echo
    
    # Step 3: Install Python and virtual environment
    print_step "3. Installing Python3 and virtual environment..."
    sudo apt install python3 python3-pip python3-venv -y
    echo
    
    # Step 4: Install system dependencies
    print_step "4. Installing system dependencies for Pillow..."
    sudo apt install python3-dev libjpeg-dev zlib1g-dev libfreetype6-dev -y
    echo
    
    # Step 5: Clone repository
    print_step "5. Cloning DOR CLI repository..."
    if [ -d "me-cli-sunset" ]; then
        echo -e "${YELLOW}Folder me-cli-sunset exists, removing...${END}"
        rm -rf me-cli-sunset
    fi
    git clone https://github.com/purplemashu/me-cli-sunset
    echo
    
    # Step 6: Create virtual environment
    print_step "6. Creating Python virtual environment..."
    cd me-cli-sunset
    python3 -m venv venv
    echo
    
    # Step 7: Install all Python packages
    print_step "7. Installing all required Python packages..."
    source venv/bin/activate
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install packages one by one
    packages=(
        "python-dotenv"
        "requests"
        "colorama" 
        "pillow"
        "ascii_magic"
        "pyfiglet"
        "pycryptodome"
        "cryptography"
    )
    
    for package in "${packages[@]}"; do
        print_info "Installing $package..."
        pip install "$package"
    done
    
    # Try requirements.txt if exists
    if [ -f "requirements.txt" ]; then
        print_info "Installing from requirements.txt..."
        pip install -r requirements.txt
    fi
    
    deactivate
    cd ..
    echo
    
    # Step 8: Create run scripts
    print_step "8. Creating run scripts..."
    
    # Script 1: run_dor.sh (with venv)
    cat > run_dor.sh << 'EOF'
#!/bin/bash
cd me-cli-sunset
source venv/bin/activate
python3 main.py
deactivate
EOF

    # Script 2: python_main.py (direct python)
    cat > python_main.py << 'EOF'
#!/bin/bash
cd me-cli-sunset
source venv/bin/activate
python3 main.py
deactivate
EOF

    chmod +x run_dor.sh python_main.py
    
    # Step 9: Create .env template
    print_step "9. Creating environment file..."
    cd me-cli-sunset
    if [ ! -f ".env" ]; then
        cat > .env << 'EOF'
# DOR CLI Environment Variables
# Copy content from: https://rentry.co/me-sunset
# Paste your variables below:

EOF
        print_success ".env template created"
    else
        print_info ".env already exists"
    fi
    cd ..
    
    echo
    echo -e "${GREEN}========================================${END}"
    print_success "🎉 DOR CLI INSTALLATION COMPLETED!"
    echo -e "${GREEN}========================================${END}"
    echo
    echo -e "${YELLOW}📋 NEXT STEPS:${END}"
    echo -e "1. ${CYAN}Setup environment variables:${END}"
    echo -e "   ${BLUE}nano me-cli-sunset/.env${END}"
    echo -e "2. ${CYAN}Copy content from:${END}"
    echo -e "   ${BLUE}https://rentry.co/me-sunset${END}"
    echo -e "3. ${CYAN}Run DOR CLI:${END}"
    echo -e "   ${BLUE}./run_dor.sh${END} (recommended)"
    echo -e "   ${BLUE}./python_main.py${END} (alternative)"
    echo
    echo -e "${YELLOW}📍 LOCATION:${END}"
    echo -e "${BLUE}$(pwd)/me-cli-sunset/${END}"
    echo
}

# Run the installation
install_dor
