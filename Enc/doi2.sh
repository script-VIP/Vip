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
    echo "║         Fixed Version                ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

# Check if sudo is needed
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        SUDO_CMD=""
        print_info "Running as root user"
    else
        SUDO_CMD="sudo"
        print_info "Running as normal user (using sudo)"
    fi
}

# Install dependencies
install_deps() {
    print_step "Installing system dependencies..."
    
    $SUDO_CMD apt update
    $SUDO_CMD apt install -y git python3 python3-pip python3-venv python3-dev \
        libjpeg-dev zlib1g-dev libfreetype6-dev
}

# Fix Python compatibility issues
fix_python_issues() {
    cd me-cli
    
    # Check Python version and fix compatibility
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    print_info "Python version: $PYTHON_VERSION"
    
    # Create virtual environment
    python3 -m venv venv
    
    # Activate venv
    source venv/bin/activate
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install compatible package versions
    print_info "Installing compatible package versions..."
    
    # Install packages without specific versions to avoid conflicts
    pip install python-dotenv requests colorama pillow ascii_magic pyfiglet pycryptodome cryptography --no-cache-dir
    
    # If there are still issues, try alternative packages
    if [ $? -ne 0 ]; then
        print_info "Trying alternative installation method..."
        pip install python-dotenv requests colorama pillow ascii_magic pyfiglet pycryptodome cryptography --break-system-packages
    fi
    
    # Install from requirements.txt if exists
    if [ -f "requirements.txt" ]; then
        print_info "Installing from requirements.txt..."
        pip install -r requirements.txt --no-cache-dir
    fi
    
    deactivate
    cd ..
}

# Fix the Type Error in encrypt.py
fix_type_error() {
    cd me-cli
    
    # Check if encrypt.py has the type error
    if [ -f "app/client/encrypt.py" ]; then
        print_info "Fixing type error in encrypt.py..."
        
        # Backup original file
        cp app/client/encrypt.py app/client/encrypt.py.backup
        
        # Fix the type annotation issue for older Python versions
        sed -i 's/iv_hex16: str | None = None/iv_hex16: str = None/g' app/client/encrypt.py
        sed -i 's/urlsafe_b64: bool = False) -> str:/urlsafe_b64: bool = False) -> str:/g' app/client/encrypt.py
        
        print_success "Type error fixed"
    fi
    
    cd ..
}

# Test installation
test_installation() {
    cd me-cli
    
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        
        print_info "Testing Python packages..."
        python3 -c "import requests; print('✅ requests OK')" 2>/dev/null && print_success "requests working" || print_error "requests failed"
        python3 -c "import PIL; print('✅ Pillow OK')" 2>/dev/null && print_success "Pillow working" || print_error "Pillow failed"
        python3 -c "import cryptography; print('✅ cryptography OK')" 2>/dev/null && print_success "cryptography working" || print_error "cryptography failed"
        
        # Test main.py
        if python3 -c "from app.client.encrypt import build_encrypted_field; print('✅ encrypt OK')" 2>/dev/null; then
            print_success "encrypt module working"
        else
            print_error "encrypt module has issues - applying fix"
            fix_type_error
        fi
        
        deactivate
    else
        print_error "Virtual environment not found"
    fi
    
    cd ..
}

# Main installation
install_dor() {
    display_banner
    
    echo -e "${YELLOW}🚀 Starting DOR CLI Installation...${END}"
    echo -e "${RED}⚠️  DON'T SKIP ANY STEP!${END}"
    echo
    
    # Check sudo requirements
    check_sudo
    
    # Step 1: Update system
    print_step "1. Updating system packages..."
    $SUDO_CMD apt update && $SUDO_CMD apt upgrade -y
    echo
    
    # Step 2: Install dependencies
    print_step "2. Installing dependencies..."
    install_deps
    echo
    
    # Step 3: Clone repository
    print_step "3. Cloning DOR CLI repository..."
    if [ -d "me-cli" ]; then
        echo -e "${YELLOW}Folder me-cli exists, removing...${END}"
        rm -rf me-cli
    fi
    git clone https://github.com/purplemashu/me-cli
    echo
    
    # Step 4: Install Python packages
    print_step "4. Installing Python packages..."
    fix_python_issues
    echo
    
    # Step 5: Fix known issues
    print_step "5. Fixing compatibility issues..."
    fix_type_error
    echo
    
    # Step 6: Create run scripts
    print_step "6. Creating run scripts..."
    
    cat > run_dor.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if [ -d "me-cli" ] && [ -f "me-cli/venv/bin/activate" ]; then
    cd me-cli
    source venv/bin/activate
    python3 main.py
    deactivate
else
    echo "Error: DOR CLI not properly installed"
    echo "Please run the installer again"
    exit 1
fi
EOF

    chmod +x run_dor.sh
    
    # Step 7: Create .env template
    print_step "7. Creating environment file..."
    cd me-cli
    if [ ! -f ".env" ]; then
        cat > .env << 'EOF'
# DOR CLI Environment Variables
# Copy content from: https://rentry.co/me-cli
# Paste your variables below:

EOF
        print_success ".env template created"
    else
        print_info ".env already exists"
    fi
    cd ..
    
    # Step 8: Test installation
    print_step "8. Testing installation..."
    test_installation
    echo
    
    echo
    echo -e "${GREEN}========================================${END}"
    print_success "🎉 DOR CLI INSTALLATION COMPLETED!"
    echo -e "${GREEN}========================================${END}"
    echo
    echo -e "${YELLOW}📋 NEXT STEPS:${END}"
    echo -e "1. ${CYAN}Setup environment variables:${END}"
    echo -e "   ${BLUE}nano me-cli/.env${END}"
    echo -e "2. ${CYAN}Copy content from:${END}"
    echo -e "   ${BLUE}https://rentry.co/me-cli${END}"
    echo -e "3. ${CYAN}Run DOR CLI:${END}"
    echo -e "   ${BLUE}./run_dor.sh${END}"
    echo
    echo -e "${YELLOW}📍 LOCATION:${END}"
    echo -e "${BLUE}$(pwd)/me-cli/${END}"
    echo
    echo -e "${YELLOW}🛠️  TROUBLESHOOTING:${END}"
    echo -e "If you see errors, run: ${CYAN}./run_dor.sh${END} again"
    echo -e "Or reinstall with: ${CYAN}rm -rf me-cli && ./$(basename "$0")${END}"
    echo
}

# Run the installation
install_dor
