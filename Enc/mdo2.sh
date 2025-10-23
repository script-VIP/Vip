#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
MAGENTA='\033[95m'
ORANGE='\033[38;5;208m'
PURPLE='\033[38;5;165m'
BOLD='\033[1m'
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

print_warning() {
    print_color "$YELLOW" "⚠️  $1"
}

print_info() {
    print_color "$CYAN" "🧋 $1"
}

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                  ${CYAN}MENU DOR DOR${PURPLE}                   ║"
    echo "║               ${ORANGE}Multi Version${PURPLE}                   ║"
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

# Fix Python type errors
fix_python_errors() {
    if [ -d "me-cli" ]; then
        cd me-cli
        
        # Fix engsel.py
        if [ -f "app/client/engsel.py" ]; then
            if grep -q "bool | None" "app/client/engsel.py"; then
                print_info "Fixing type errors in engsel.py..."
                sed -i 's/bool | None/typing.Optional[bool]/g' app/client/engsel.py
                sed -i 's/from typing import/from typing import Optional, /g' app/client/engsel.py
                if ! grep -q "import typing" "app/client/engsel.py"; then
                    sed -i '1s/^/import typing\n/' app/client/engsel.py
                fi
            fi
        fi
        
        # Fix encrypt.py
        if [ -f "app/client/encrypt.py" ]; then
            if grep -q "str | None" "app/client/encrypt.py"; then
                print_info "Fixing type errors in encrypt.py..."
                sed -i 's/str | None/typing.Optional[str]/g' app/client/encrypt.py
                sed -i 's/from typing import/from typing import Optional, /g' app/client/encrypt.py
                if ! grep -q "import typing" "app/client/encrypt.py"; then
                    sed -i '1s/^/import typing\n/' app/client/encrypt.py
                fi
            fi
        fi
        
        cd ..
    fi
}

install_dor() {
    echo -e "${ORANGE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                 INSTALL DOR                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${YELLOW}🚀 Installing DOR...${END}"
    echo
    wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/doi.sh
    chmod +x doi.sh
    ./doi.sh
    rm -f doi.sh
    
    # Fix errors after installation
    fix_python_errors
}

run_menu_v1() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
    fi
    
    # Fix errors before running
    fix_python_errors
    
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
        return
    fi
    
    # Fix errors before running
    fix_python_errors
    
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                  MENU V2                     ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${CYAN}🚀 Starting DOR V2...${END}"
    echo -e "${YELLOW}Press ${RED}Ctrl+C${YELLOW} to stop${END}"
    echo
    ./run_dor.sh
}

setup_environment() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
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
        return
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

# Fix all errors function
fix_all_errors() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
    fi
    
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                FIX ERRORS                    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    fix_python_errors
    print_success "All Python type errors fixed!"
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
    
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                   MAIN MENU                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${END}"
    
    echo -e "${STATUS_BOX}┌────────────────────────────────────────────┐${END}"
    echo -e "${STATUS_BOX}│           ${BOLD}STATUS: $STATUS_DISPLAY${STATUS_BOX}           │${END}"
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
    echo -e "  ${RED}${BOLD}0.${END} ${RED}❌ EXIT${END}"
    echo
    echo -e "${GREEN}══════════════════════════════════════════════${END}"
    echo -n -e "${CYAN}${BOLD}Enter your choice (0-7): ${END}"
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
            7) fix_all_errors ;;
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
                print_error "Invalid choice! Please select 0-7"
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
