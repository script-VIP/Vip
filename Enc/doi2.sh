#!/bin/bash

# Colors - using tput for better compatibility
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
END=$(tput sgr0)

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
    echo "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║           DOR CLI INSTALLER          ║"
    echo "║      Debian/Ubuntu Universal Setup   ║"
    echo "╚══════════════════════════════════════╝"
    echo "${END}"
}

# Detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        OS_PRETTY_NAME="$PRETTY_NAME"
    else
        OS_NAME="unknown"
        OS_VERSION="unknown"
        OS_PRETTY_NAME="Unknown Linux Distribution"
    fi
}

# Check if Debian-based
is_debian_based() {
    if [ -f /etc/debian_version ] || [ "$OS_NAME" = "ubuntu" ] || [ "$OS_NAME" = "debian" ] || [ "$OS_NAME" = "linuxmint" ]; then
        return 0
    else
        return 1
    fi
}

# Install specific dependencies based on OS
install_os_specific_deps() {
    print_info "Detected: $OS_PRETTY_NAME"
    
    case $OS_NAME in
        "ubuntu")
            case $OS_VERSION in
                "20.04")
                    print_step "Installing Ubuntu 20.04 specific dependencies..."
                    sudo apt install -y python3.8-venv python3.8-dev
                    ;;
                "22.04")
                    print_step "Installing Ubuntu 22.04 specific dependencies..."
                    sudo apt install -y python3.10-venv python3.10-dev
                    ;;
                "24.04")
                    print_step "Installing Ubuntu 24.04 specific dependencies..."
                    sudo apt install -y python3.12-venv python3.12-dev
                    ;;
                *)
                    print_step "Installing generic Ubuntu Python packages..."
                    sudo apt install -y python3-venv python3-dev
                    ;;
            esac
            ;;
        "debian")
            case $OS_VERSION in
                "10"|"11")
                    print_step "Installing Debian $OS_VERSION specific dependencies..."
                    sudo apt install -y python3-venv python3-dev
                    ;;
                "12")
                    print_step "Installing Debian $OS_VERSION specific dependencies..."
                    sudo apt install -y python3-venv python3-dev python3-full
                    ;;
                *)
                    print_step "Installing generic Debian Python packages..."
                    sudo apt install -y python3-venv python3-dev python3-full
                    ;;
            esac
            ;;
        "linuxmint")
            print_step "Installing Linux Mint specific dependencies..."
            sudo apt install -y python3-venv python3-dev python3-full
            ;;
        *)
            print_step "Installing generic Python development packages..."
            sudo apt install -y python3-venv python3-dev python3-full
            ;;
    esac
}

# Check and install missing dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for essential commands
    for cmd in git python3; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for pip3
    if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
        missing_deps+=("pip3")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All essential dependencies are available"
        return 0
    else
        print_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Safe directory operations
safe_directory_cleanup() {
    if [ -d "me-cli" ]; then
        print_info "Removing existing me-cli directory..."
        rm -rf me-cli
        if [ $? -eq 0 ]; then
            print_success "Directory cleaned up"
        else
            print_error "Failed to remove directory"
            return 1
        fi
    fi
    return 0
}

# Safe git clone with retry
safe_git_clone() {
    local repo_url="$1"
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        print_info "Attempting to clone repository (attempt $((retry_count + 1))/$max_retries)..."
        git clone "$repo_url"
        
        if [ $? -eq 0 ]; then
            print_success "Repository cloned successfully"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_error "Clone failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    print_error "Failed to clone repository after $max_retries attempts"
    return 1
}

# Create virtual environment with fallback
create_venv() {
    local python_cmd="python3"
    
    # Try to find the best python command
    for version in 3.12 3.11 3.10 3.9 3.8; do
        if command -v "python${version}" &> /dev/null; then
            python_cmd="python${version}"
            break
        fi
    done
    
    print_info "Using $python_cmd for virtual environment"
    
    if $python_cmd -m venv venv; then
        print_success "Virtual environment created"
        return 0
    else
        print_error "Failed to create virtual environment with $python_cmd"
        
        # Fallback: try with --without-pip
        print_info "Trying fallback method without pip..."
        if $python_cmd -m venv --without-pip venv; then
            print_success "Virtual environment created without pip"
            return 0
        else
            return 1
        fi
    fi
}

# Install pip in venv if missing
ensure_pip_in_venv() {
    source venv/bin/activate
    
    if ! python -m pip --version &> /dev/null; then
        print_info "Installing pip in virtual environment..."
        
        # Download and install pip
        curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        if python get-pip.py; then
            print_success "Pip installed in virtual environment"
            rm get-pip.py
        else
            print_error "Failed to install pip in virtual environment"
            rm get-pip.py
            return 1
        fi
    else
        print_success "Pip is available in virtual environment"
    fi
    
    deactivate
}

# Install Python packages with better error handling
install_python_packages() {
    source venv/bin/activate
    
    # Upgrade pip first with timeout
    print_info "Upgrading pip..."
    python -m pip install --timeout 30 --retries 3 --upgrade pip
    
    if [ $? -ne 0 ]; then
        print_error "Failed to upgrade pip, continuing anyway..."
    fi
    
    # Install packages one by one with better error handling
    local packages=(
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
        if python -m pip install --timeout 60 --retries 3 "$package"; then
            print_success "✓ $package installed"
        else
            print_error "Failed to install $package"
            # Continue with other packages
        fi
    done
    
    # Try requirements.txt if exists
    if [ -f "requirements.txt" ]; then
        print_info "Installing from requirements.txt..."
        if python -m pip install --timeout 60 --retries 3 -r requirements.txt; then
            print_success "Requirements.txt installed"
        else
            print_error "Some packages from requirements.txt failed to install"
        fi
    fi
    
    deactivate
}

# Check if running as root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root!"
        print_info "Run as normal user and use sudo when needed"
        exit 1
    fi
}

# Main installation
install_dor() {
    display_banner
    
    # Detect OS first
    detect_os
    
    # Check if Debian-based
    if ! is_debian_based; then
        print_error "This script is designed for Debian-based distributions (Debian, Ubuntu, Mint, etc.)"
        print_info "Detected: $OS_PRETTY_NAME"
        exit 1
    fi
    
    # Check not running as root
    check_not_root
    
    echo "${YELLOW}🚀 Starting Universal DOR CLI Installation...${END}"
    echo "${RED}⚠️  DON'T SKIP ANY STEP!${END}"
    echo
    
    # Check system
    print_step "1. Checking system compatibility..."
    check_dependencies
    
    # Step 1: Update system
    print_step "2. Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    if [ $? -eq 0 ]; then
        print_success "System updated successfully"
    else
        print_error "System update failed, continuing anyway..."
    fi
    echo
    
    # Step 2: Install Git if missing
    print_step "3. Ensuring Git is installed..."
    if ! command -v git &> /dev/null; then
        sudo apt install git -y
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi
    echo
    
    # Step 3: Install Python and OS-specific dependencies
    print_step "4. Installing Python and OS-specific dependencies..."
    install_os_specific_deps
    echo
    
    # Step 4: Install system dependencies
    print_step "5. Installing system dependencies..."
    sudo apt install -y \
        python3-dev \
        libjpeg-dev \
        zlib1g-dev \
        libfreetype6-dev \
        libssl-dev \
        libffi-dev \
        curl \
        wget
    
    if [ $? -eq 0 ]; then
        print_success "System dependencies installed"
    else
        print_error "Some system dependencies failed to install"
    fi
    echo
    
    # Step 5: Clone repository safely
    print_step "6. Cloning DOR CLI repository..."
    safe_directory_cleanup
    if safe_git_clone "https://github.com/purplemashu/me-cli"; then
        cd me-cli
    else
        print_error "Cannot continue without repository"
        exit 1
    fi
    echo
    
    # Step 6: Create virtual environment
    print_step "7. Creating Python virtual environment..."
    if create_venv; then
        print_success "Virtual environment ready"
    else
        print_error "Virtual environment creation failed, trying alternative method..."
        # Final fallback
        if python3 -m venv venv || python3 -m venv --without-pip venv; then
            print_success "Virtual environment created with final fallback"
        else
            print_error "Cannot create virtual environment, exiting..."
            exit 1
        fi
    fi
    echo
    
    # Step 7: Ensure pip is available in venv
    print_step "8. Ensuring pip is available in virtual environment..."
    ensure_pip_in_venv
    echo
    
    # Step 8: Install all Python packages
    print_step "9. Installing all required Python packages..."
    install_python_packages
    cd ..
    echo
    
    # Step 9: Create run scripts
    print_step "10. Creating run scripts..."
    
    # Script 1: run_dor.sh (with venv)
    cat > run_dor.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/me-cli"
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    python3 main.py
    deactivate
else
    echo "Error: Virtual environment not found"
    echo "Please run the installer again"
    exit 1
fi
EOF

    # Script 2: python_main.py (direct python)
    cat > python_main.py << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/me-cli"
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    python3 main.py
    deactivate
else
    echo "Error: Virtual environment not found"
    exit 1
fi
EOF

    chmod +x run_dor.sh python_main.py
    print_success "Run scripts created and made executable"
    
    # Step 10: Create .env template
    print_step "11. Creating environment file..."
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
    echo "${GREEN}========================================${END}"
    print_success "🎉 UNIVERSAL DOR CLI INSTALLATION COMPLETED!"
    echo "${GREEN}========================================${END}"
    echo
    echo "${YELLOW}📋 NEXT STEPS:${END}"
    echo "1. ${CYAN}Setup environment variables:${END}"
    echo "   ${BLUE}nano me-cli/.env${END}"
    echo "2. ${CYAN}Copy content from:${END}"
    echo "   ${BLUE}https://rentry.co/me-cli${END}"
    echo "3. ${CYAN}Run DOR CLI:${END}"
    echo "   ${BLUE}./run_dor.sh${END} (recommended)"
    echo "   ${BLUE}./python_main.py${END} (alternative)"
    echo
    echo "${YELLOW}📍 LOCATION:${END}"
    echo "${BLUE}$(pwd)/me-cli/${END}"
    echo
    echo "${YELLOW}🛠️  TROUBLESHOOTING:${END}"
    echo "If you encounter issues:"
    echo "1. Check if all dependencies are installed"
    echo "2. Verify Python version compatibility"
    echo "3. Check internet connection for package downloads"
    echo "4. Run: sudo apt update && sudo apt install -f"
    echo
    echo "${YELLOW}📝 SUPPORTED DISTROS:${END}"
    echo "✅ Ubuntu 20.04, 22.04, 24.04"
    echo "✅ Debian 10, 11, 12" 
    echo "✅ Linux Mint"
    echo "✅ Other Debian-based distributions"
    echo
}

# Run the installation
install_dor
