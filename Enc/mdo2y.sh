#!/bin/bash
# Backup config lama
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

# Download config yang diperbaiki
cat > /etc/haproxy/haproxy.cfg << EOF
global
    daemon
    maxconn 256
    user haproxy
    group haproxy

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend ssh-ssl
    bind *:443 ssl crt /etc/haproxy/hap.pem
    default_backend nginx-https

backend nginx-https
    server nginx-https 127.0.0.1:8443

frontend ssh-tcp
    bind *:80
    default_backend nginx-http

backend nginx-http  
    server nginx-http 127.0.0.1:8181
EOF}

display_banner() {
    clear_screen
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                  ${CYAN}MENU DOR DOR${PURPLE}                   ║"
    echo "║            ${ORANGE}Universal Ubuntu/Debian${PURPLE}            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    echo
}

check_status() {
    if [ -d "me-cli" ] && [ -f "me-cli/main.py" ] && [ -d "me-cli/venv" ]; then
        echo "active"
    else
        echo "off"
    fi
}

# Fix ALL Python type errors for all versions
fix_all_python_errors() {
    if [ -d "me-cli" ]; then
        cd me-cli
        
        print_info "Scanning and fixing Python type errors..."
        
        # Find all Python files and fix Union types
        find . -name "*.py" -type f | while read file; do
            if grep -q ":[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*|[[:space:]]*None[[:space:]]*=" "$file"; then
                print_info "Fixing: $file"
                
                # Fix patterns like: variable: type | None = None
                sed -i 's/\(:[[:space:]]*\)\([a-zA-Z_][a-zA-Z0-9_]*\)\([[:space:]]*\)|\([[:space:]]*\)None\([[:space:]]*\)=/\1typing.Optional[\2]\5=/g' "$file"
                
                # Fix patterns like: variable: type | None
                sed -i 's/\(:[[:space:]]*\)\([a-zA-Z_][a-zA-Z0-9_]*\)\([[:space:]]*\)|\([[:space:]]*\)None/\1typing.Optional[\2]/g' "$file"
                
                # Fix patterns like: -> type | None
                sed -i 's/->\([[:space:]]*\)\([a-zA-Z_][a-zA-Z0-9_]*\)\([[:space:]]*\)|\([[:space:]]*\)None/->\1typing.Optional[\2]/g' "$file"
                
                # Add typing import if needed
                if grep -q "typing.Optional" "$file" && ! grep -q "import typing" "$file" && ! grep -q "from typing import" "$file"; then
                    sed -i '1s/^/import typing\n/' "$file"
                fi
                
                # Add Optional to existing typing imports
                if grep -q "from typing import" "$file" && ! grep -q "Optional" "$file"; then
                    sed -i 's/from typing import/from typing import Optional, /g' "$file"
                fi
            fi
        done
        
        # Fix specific known problematic files
        fix_specific_files
        
        print_success "All Python type errors fixed!"
        cd ..
    fi
}

# Fix specific files that are known to have issues
fix_specific_files() {
    # Fix engsel.py
    if [ -f "app/client/engsel.py" ]; then
        print_info "Fixing engsel.py..."
        
        # Fix all Union types
        sed -i 's/bool | None/typing.Optional[bool]/g' app/client/engsel.py
        sed -i 's/str | None/typing.Optional[str]/g' app/client/engsel.py
        sed -i 's/int | None/typing.Optional[int]/g' app/client/engsel.py
        sed -i 's/list | None/typing.Optional[list]/g' app/client/engsel.py
        sed -i 's/dict | None/typing.Optional[dict]/g' app/client/engsel.py
        
        # Ensure typing imports
        if ! grep -q "import typing" app/client/engsel.py && ! grep -q "from typing import" app/client/engsel.py; then
            sed -i '1s/^/import typing\n/' app/client/engsel.py
        elif grep -q "from typing import" app/client/engsel.py && ! grep -q "Optional" app/client/engsel.py; then
            sed -i 's/from typing import/from typing import Optional, /g' app/client/engsel.py
        fi
    fi
    
    # Fix encrypt.py
    if [ -f "app/client/encrypt.py" ]; then
        print_info "Fixing encrypt.py..."
        
        sed -i 's/str | None/typing.Optional[str]/g' app/client/encrypt.py
        sed -i 's/bool | None/typing.Optional[bool]/g' app/client/encrypt.py
        
        if ! grep -q "import typing" app/client/encrypt.py && ! grep -q "from typing import" app/client/encrypt.py; then
            sed -i '1s/^/import typing\n/' app/client/encrypt.py
        elif grep -q "from typing import" app/client/encrypt.py && ! grep -q "Optional" app/client/encrypt.py; then
            sed -i 's/from typing import/from typing import Optional, /g' app/client/encrypt.py
        fi
    fi
}

# Install DOR dengan fix otomatis
install_dor() {
    echo -e "${ORANGE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                 INSTALL DOR                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${YELLOW}🚀 Installing DOR...${END}"
    echo
    
    # Download installer
    wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/doi.sh
    chmod +x doi.sh
    
    # Run installer
    ./doi.sh
    
    # Fix errors setelah install
    print_info "Applying compatibility fixes..."
    fix_all_python_errors
    
    rm -f doi.sh
    print_success "Installation completed with fixes!"
}

run_menu_v1() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return 1
    fi
    
    # Fix errors sebelum run
    fix_all_python_errors
    
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                  MENU V1                     ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${GREEN}🚀 Starting DOR V1...${END}"
    echo -e "${YELLOW}Press ${RED}Ctrl+C${YELLOW} to stop${END}"
    echo
    cd me-cli
    source venv/bin/activate
    python3 main.py
    deactivate
    cd ..
}

run_menu_v2() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return 1
    fi
    
    # Fix errors sebelum run
    fix_all_python_errors
    
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                  MENU V2                     ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${CYAN}🚀 Starting DOR V2...${END}"
    echo -e "${YELLOW}Press ${RED}Ctrl+C${YELLOW} to stop${END}"
    echo
    
    if [ -f "./run_dor.sh" ]; then
        ./run_dor.sh
    else
        # Fallback ke V1
        run_menu_v1
    fi
}

setup_environment() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return 1
    fi
    
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║               SETUP ENVIRONMENT              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${MAGENTA}⚙️  Setting up environment variables...${END}"
    echo -e "${BLUE}Editing: ${YELLOW}me-cli/.env${END}"
    echo
    nano me-cli/.env
    print_success "Environment updated!"
}

copy_content() {
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                COPY CONTENT                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${BLUE}📋 Copy from: ${CYAN}https://rentry.co/me-cli${END}"
    echo
    echo -e "${YELLOW}Opening browser...${END}"
    xdg-open "https://rentry.co/me-cli" 2>/dev/null || echo -e "${RED}❌ Cannot open browser automatically${END}"
    echo -e "${GREEN}✅ Please copy the content manually${END}"
}

view_files() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return 1
    fi
    
    echo -e "${ORANGE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                 VIEW FILES                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${ORANGE}📁 DOR Files Location:${END}"
    echo -e "${CYAN}$(pwd)/me-cli/${END}"
    echo
    echo -e "${YELLOW}File List:${END}"
    echo -e "${GREEN}══════════════════════════════════════════════${END}"
    ls -la me-cli/
    echo -e "${GREEN}══════════════════════════════════════════════${END}"
    echo -e "${BLUE}Total files: ${MAGENTA}$(find me-cli -type f | wc -l)${END}"
}

# Test Python compatibility
test_python_compatibility() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return 1
    fi
    
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║              TEST COMPATIBILITY              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    cd me-cli
    source venv/bin/activate
    
    echo -e "${CYAN}Python Version:${END}"
    python3 --version
    
    echo -e "${CYAN}Testing imports...${END}"
    if python3 -c "
import requests
import PIL
import cryptography
from app.client.encrypt import build_encrypted_field
from app.client.engsel import EngselClient
print('✅ All imports successful')
" 2>/dev/null; then
        print_success "Compatibility test PASSED"
    else
        print_error "Compatibility test FAILED"
        print_info "Running auto-fix..."
        fix_all_python_errors
    fi
    
    deactivate
    cd ..
}

show_menu() {
    status=$(check_status)
    
    if [ "$status" = "active" ]; then
        STATUS_DISPLAY="${GREEN}${BOLD}🟢 ACTIVE${END}"
        STATUS_BOX="${GREEN}"
    else
        STATUS_DISPLAY="${RED}${BOLD}🔴 OFF${END}"
        STATUS_BOX="${RED}"
    fi
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_INFO="$PRETTY_NAME"
    else
        OS_INFO="Unknown Linux"
    fi
    
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                   MAIN MENU                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${STATUS_BOX}┌────────────────────────────────────────────┐${END}"
    echo -e "${STATUS_BOX}│           ${BOLD}STATUS: $STATUS_DISPLAY${STATUS_BOX}           │${END}"
    echo -e "${STATUS_BOX}│           ${BOLD}OS: $OS_INFO${STATUS_BOX}     │${END}"
    echo -e "${STATUS_BOX}└────────────────────────────────────────────┘${END}"
    echo
    
    echo -e "${PURPLE}${BOLD}Please select an option: ${END}"
    echo
    echo -e "  ${GREEN}${BOLD}1.${END} ${GREEN}🚀 INSTALL DOR ${END}"
    echo -e "  ${CYAN}${BOLD}2.${END} ${CYAN}🚀 MENU V1 ${END}"
    echo -e "  ${BLUE}${BOLD}3.${END} ${BLUE}🚀 MENU V2 ${END}"
    echo -e "  ${MAGENTA}${BOLD}4.${END} ${MAGENTA}⚙️  SETUP ENVIRONMENT ${END}"
    echo -e "  ${ORANGE}${BOLD}5.${END} ${ORANGE}📋 COPY CONTENT ${END}"
    echo -e "  ${YELLOW}${BOLD}6.${END} ${YELLOW}📁 VIEW FILES ${END}"
    echo -e "  ${RED}${BOLD}7.${END} ${RED}🔧 FIX ERRORS ${END}"
    echo -e "  ${BLUE}${BOLD}8.${END} ${BLUE}🧪 TEST COMPATIBILITY ${END}"
    echo -e "  ${RED}${BOLD}0.${END} ${RED}❌ EXIT${END}"
    echo
    echo -e "${GREEN}══════════════════════════════════════════════${END}"
    echo -n -e "${CYAN}${BOLD}Enter your choice (0-8): ${END}"
}

main() {
    while true; do
        clear_screen
        display_banner
        show_menu
        read choice
        
        case $choice in
            1) install_dor ;;
            2) run_menu_v1 ;;
            3) run_menu_v2 ;;
            4) setup_environment ;;
            5) copy_content ;;
            6) view_files ;;
            7) fix_all_python_errors ;;
            8) test_python_compatibility ;;
            0) 
                echo
                echo -e "${GREEN}${BOLD}"
                echo "╔══════════════════════════════════════════════╗"
                echo "║                 THANK YOU                    ║"
                echo "║                 GOODBYE! 👋                  ║"
                echo "╚══════════════════════════════════════════════╝"
                echo -e "${END}"
                exit 0
                ;;
            *) 
                echo
                print_error "Invalid choice! Please select 0-8"
                sleep 2 
                ;;
        esac
        
        echo
        echo -e "${YELLOW}${BOLD}Press Enter to continue...${END}"
        read
    done
}

trap 'echo -e "\n${RED}${BOLD}❌ Operation stopped by user${END}"; exit 1' INT
main
