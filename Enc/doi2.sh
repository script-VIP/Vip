#!/bin/bash

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
END='\033[0m'

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Do not run this script as root!${END}"
    echo -e "${BLUE}🧋 Run as normal user and use sudo when needed${END}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting DOR CLI Installation...${END}"

# Update system
echo -e "${CYAN}Updating system packages...${END}"
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo -e "${CYAN}Installing dependencies...${END}"
sudo apt install -y git python3 python3-pip python3-venv python3-dev \
    libjpeg-dev zlib1g-dev libfreetype6-dev

# Clone repository
echo -e "${CYAN}Cloning repository...${END}"
if [ -d "me-cli" ]; then
    rm -rf me-cli
fi
git clone https://github.com/purplemashu/me-cli
cd me-cli

# Create virtual environment
echo -e "${CYAN}Creating virtual environment...${END}"
python3 -m venv venv
source venv/bin/activate

# Install Python packages
echo -e "${CYAN}Installing Python packages...${END}"
pip install --upgrade pip
pip install python-dotenv requests colorama pillow ascii_magic pyfiglet pycryptodome cryptography

# Create .env if not exists
if [ ! -f ".env" ]; then
    echo -e "${CYAN}Creating .env template...${END}"
    cat > .env << 'EOF'
# DOR CLI Environment Variables
# Copy content from: https://rentry.co/me-cli
# Paste your variables below:

EOF
fi

cd ..

# Create run script
echo -e "${CYAN}Creating run script...${END}"
cat > run_dor.sh << 'EOF'
#!/bin/bash
cd me-cli
source venv/bin/activate
python3 main.py
deactivate
EOF

chmod +x run_dor.sh

echo -e "${GREEN}🎉 Installation completed!${END}"
echo -e "${YELLOW}Next steps:${END}"
echo -e "1. Edit environment variables: ${CYAN}nano me-cli/.env${END}"
echo -e "2. Copy content from: ${CYAN}https://rentry.co/me-cli${END}"
echo -e "3. Run with: ${CYAN}./run_dor.sh${END}"
