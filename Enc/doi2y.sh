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
    echo "║           Tested Version             ║"
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

# Install Python packages with proper handling
install_python_packages() {
    cd me-cli
    
    # Create virtual environment
    python3 -m venv venv
    
    # Activate venv
    source venv/bin/activate
    
    # Upgrade pip first without warnings
    pip install --upgrade pip --no-warn-script-location
    
    # Install packages without specific versions to avoid conflicts
    print_info "Installing Python packages..."
    
    pip install --no-cache-dir --no-warn-script-location \
        python-dotenv \
        requests \
        colorama \
        pillow \
        ascii_magic \
        pyfiglet \
        pycryptodome \
        cryptography
    
    # Skip requirements.txt to avoid version conflicts
    print_info "Skipping requirements.txt to avoid version conflicts"
    
    deactivate
    cd ..
}

# Fix the Type Error in encrypt.py for older Python versions
fix_type_error() {
    cd me-cli
    
    if [ -f "app/client/encrypt.py" ]; then
        print_info "Checking for type errors in encrypt.py..."
        
        # Check if the file contains the problematic syntax
        if grep -q "str | None" "app/client/encrypt.py"; then
            print_info "Fixing type annotations for older Python version..."
            
            # Backup original file
            cp app/client/encrypt.py app/client/encrypt.py.backup
            
            # Fix type annotations (union types not supported in Python < 3.10)
            sed -i 's/str | None/typing.Optional[str]/g' app/client/encrypt.py
            sed -i 's/from typing import/from typing import Optional, /g' app/client/encrypt.py
            
            # Add typing import if not present
            if ! grep -q "import typing" "app/client/encrypt.py"; then
                sed -i '1s/^/import typing\n/' app/client/encrypt.py
            fi
            
            print_success "Type annotations fixed"
        else
            print_info "No type errors found"
        fi
    fi
    
    cd ..
}

# Test the installation
test_installation() {
    cd me-cli
    
    print_info "Testing installation..."
    
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        
        # Test basic imports
        if python3 -c "import requests; import PIL; import cryptography; print('Basic imports OK')" 2>/dev/null; then
            print_success "Basic packages working"
        else
            print_error "Basic packages failed"
        fi
        
        # Test the specific encrypt module
        if python3 -c "from app.client.encrypt import build_encrypted_field; print('Encrypt module OK')" 2>/dev/null; then
            print_success "Encrypt module working"
        else
            print_error "Encrypt module has issues"
            # Try to fix again
            fix_type_error
        fi
        
        deactivate
    else
        print_error "Virtual environment not found"
        return 1
    fi
    
    cd ..
    return 0
}

# Create menu script
create_menu() {
    print_step "Creating menu scripts..."
    
    # Main run script
    cat > run_dor.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/me-cli"

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    python3 main.py
    deactivate
else
    echo "Error: Virtual environment not found!"
    echo "Please make sure the installation completed successfully."
    exit 1
fi
EOF

    # Alternative script
    cat > python_main.py << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/me-cli"

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    python3 main.py
    deactivate
else
    echo "Error: Virtual environment not found!"
    echo "Please run the installer first!"
    exit 1
fi
EOF

    # Simple one-click script
    cat > start_dor.sh << 'EOF'
#!/bin/bash
cd me-cli
source venv/bin/activate
python3 main.py
deactivate
EOF

    # Make all executable
    chmod +x run_dor.sh python_main.py start_dor.sh
    print_success "Menu scripts created"
}

# Create desktop shortcut (optional)
create_desktop_shortcut() {
    if [ -d "$HOME/Desktop" ]; then
        print_step "Creating desktop shortcut..."
        
        cat > "$HOME/Desktop/DOR_CLI.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=DOR CLI
Comment=DOR Command Line Interface
Exec=$PWD/run_dor.sh
Icon=utilities-terminal
Terminal=true
StartupNotify=false
Categories=Utility;
EOF
        
        chmod +x "$HOME/Desktop/DOR_CLI.desktop"
        print_success "Desktop shortcut created"
    fi
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
    if [ $? -ne 0 ]; then
        print_error "Failed to clone repository"
        exit 1
    fi
    echo
    
    # Step 4: Fix type errors before installation
    print_step "4. Fixing compatibility issues..."
    fix_type_error
    echo
    
    # Step 5: Install Python packages
    print_step "5. Installing Python packages..."
    install_python_packages
    echo
    
    # Step 6: Create menu scripts
    create_menu
    
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
    
    # Step 8: Create desktop shortcut
    create_desktop_shortcut
    
    # Step 9: Test installation
    print_step "8. Testing installation..."
    if test_installation; then
        print_success "Installation test passed"
    else
        print_error "Installation test failed"
        echo -e "${YELLOW}But continuing anyway...${END}"
    fi
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
    echo
    echo -e "${YELLOW}🚀 LAUNCH OPTIONS:${END}"
    echo -e "   ${GREEN}./run_dor.sh${END}        (Recommended)"
    echo -e "   ${GREEN}./python_main.py${END}    (Alternative)" 
    echo -e "   ${GREEN}./start_dor.sh${END}      (Simple)"
    echo
    if [ -f "$HOME/Desktop/DOR_CLI.desktop" ]; then
        echo -e "   ${GREEN}Desktop Shortcut${END}   (Double-click)"
    fi
    echo
    echo -e "${YELLOW}📍 LOCATION:${END}"
    echo -e "${BLUE}$(pwd)/me-cli/${END}"
    echo
}

# Run the installation
install_dor
