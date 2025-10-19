#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
MAGENTA='\033[95m'
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

clear_screen() {
    clear
}

display_banner() {
    clear_screen
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════╗"
    echo "║             MENU DOR DOR             ║"
    echo "║            Multi Version             ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${END}"
}

check_status() {
    if [ -d "me-cli" ] && [ -f "me-cli/main.py" ] && [ -d "me-cli/venv" ]; then
        echo "active"
    else
        echo "off"
    fi
}

install_dor() {
    echo -e "${YELLOW}🚀 Installing DOR...${END}"
    wget -q https://raw.githubusercontent.com/Script-VIP/Vip/main/Enc/doy.sh
    chmod +x doy.sh
    ./doy.sh
    rm -f doy.sh
}

run_menu_v1() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
    fi
    
    echo -e "${GREEN}🚀 Starting DOR V1...${END}"
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
    
    echo -e "${CYAN}🚀 Starting DOR V2...${END}"
    ./run_dor.sh
}

setup_environment() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
    fi
    
    echo -e "${YELLOW}⚙️  Setup Environment...${END}"
    nano me-cli/.env
}

copy_content() {
    echo -e "${YELLOW}📋 Copy Content...${END}"
    echo -e "${BLUE}Open: https://rentry.co/me-cli${END}"
    xdg-open "https://rentry.co/me-cli" 2>/dev/null || echo -e "${RED}Open manually${END}"
}

view_files() {
    if [ "$(check_status)" = "off" ]; then
        print_error "DOR not installed!"
        return
    fi
    
    echo -e "${YELLOW}📁 View Files...${END}"
    ls -la me-cli/
}

show_menu() {
    status=$(check_status)
    
    if [ "$status" = "active" ]; then
        STATUS_DISPLAY="${GREEN}🟢 ACTIVE${END}"
    else
        STATUS_DISPLAY="${RED}🔴 OFF${END}"
    fi
    
    echo -e "${CYAN}📋 MENU DOR DOR:${END}"
    echo
    echo -e "Status: $STATUS_DISPLAY"
    echo
    echo -e "1. 🚀 INSTALL DOR"
    echo -e "2. 🚀 MENU V1"
    echo -e "3. 🚀 MENU V2"
    echo -e "4. ⚙️  SETUP ENVIRONMENT"
    echo -e "5. 📋 COPY CONTENT"
    echo -e "6. 📁 VIEW FILES"
    echo -e "0. ❌ EXIT"
    echo
    echo -n -e "${YELLOW}Select option (0-6): ${END}"
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
            0) 
                echo -e "${GREEN}👋 Goodbye!${END}"
                exit 0 
                ;;
            *) menu ;;
        esac
        
        echo
        echo -e "${YELLOW}Press Enter to continue...${END}"
        read
    done
}

trap 'echo -e "\n${RED}❌ Stopped${END}"; exit 1' INT
main
