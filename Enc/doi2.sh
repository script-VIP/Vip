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
    echo "║         Universal Setup              ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

# Check if sudo is needed
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        # Running as root, no sudo needed
        SUDO_CMD=""
        print_info "Running as root user"
    else
        # Not root, use sudo
        SUDO_CMD="sudo"
        print_info "Running as normal user (using sudo)"
    fi
}

# Detect and setup Python
setup_python() {
    # Try to detect available Python versions
    if command -v python3.12 &> /dev/null; then
        PYTHON_CMD="python3.12"
    elif command -v python3.11 &> /dev/null; then
        PYTHON_CMD="python3.11"
    elif command -v python3.10 &> /dev/null; then
        PYTHON_CMD="python3.10"
    elif command -v python3.9 &> /dev/null; then
        PYTHON_CMD="python3.9"
    elif command -v python3.8 &> /dev/null; then
        PYTHON_CMD="python3.8"
    else
        PYTHON_CMD="python3"
    fi
    
    print_info "Using $PYTHON_CMD for installation"
    echo "$PYTHON_CMD"
}

# Install dependencies
install_deps() {
    print_step "Installing system dependencies..."
    
    # Update package list
    $SUDO_CMD apt update
    
    # Install packages
    $SUDO_CMD apt install -y git python3 python3-pip python3-venv python3-dev \
        libjpeg-dev zlib1g-dev libfreetype6-dev
}

# Main installation
install_dor() {
    display_banner
    
    echo -e "${YELLOW}🚀 Starting DOR CLI Installation...${END}"
    echo -e "${RED}⚠️  DON'T SKIP ANY STEP!${END}"
    echo
    
    # Check sudo requirements
    check_sudo
    
    # Setup Python version
    PYTHON_CMD=$(setup_python)
    
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
    
    # Step 4: Create virtual environment
    print_step "4. Creating Python virtual environment..."
    cd me-cli
    $PYTHON_CMD -m venv venv
    echo
    
    # Step 5: Install Python packages
    print_step "5. Installing Python packages..."
    source venv/bin/activate
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install packages
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
    
    # Step 6: Create run scripts
    print_step "6. Creating run scripts..."
    
    # Main run script
    cat > run_dor.sh << 'EOF'
#!/bin/bash
cd me-cli
source venv/bin/activate
python3 main.py
deactivate
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
    echo -e "${YELLOW}👤 PRIVILEGES:${END}"
    if [ "$EUID" -eq 0 ]; then
        echo -e "Running as: ${RED}Root user${END}"
    else
        echo -e "Running as: ${GREEN}Normal user${END}"
    fi
    echo
}

# Run the installation
install_dor
