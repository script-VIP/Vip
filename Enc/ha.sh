#!/bin/bash

# HAPROXY TEMPORARY SETUP SCRIPT
# Usage: ./haproxy-temp-fix.sh

RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
NC='\033[0m'

# Config variables
HAPROXY_CFG="/etc/haproxy/haproxy.cfg"
BACKUP_CFG="/etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)"
TEMP_CFG="/etc/haproxy/haproxy.cfg.temp"

echo -e "${GREEN}=== HAProxy Temporary Setup ===${NC}"

# Check if HAProxy is installed
if ! command -v haproxy &> /dev/null; then
    echo -e "${RED}HAProxy is not installed!${NC}"
    echo "Installing HAProxy..."
    apt-get update && apt-get install -y haproxy
fi

# Backup original config
echo -e "${YELLOW}Backing up original config to $BACKUP_CFG${NC}"
cp "$HAPROXY_CFG" "$BACKUP_CFG"

# Create temporary configuration
cat > "$TEMP_CFG" << 'EOF'
global
    daemon
    maxconn 4000
    user haproxy
    group haproxy

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    log global
    option httplog
    option dontlognull
    retries 3

# Frontend for HTTP traffic
frontend http_front
    bind *:80
    bind *:443
    mode http
    option forwardfor
    default_backend http_back

# Backend servers
backend http_back
    mode http
    balance roundrobin
    option httpchk GET /
    server web1 127.0.0.1:8080 check maxconn 100
    server web2 127.0.0.1:8081 check maxconn 100 backup

# Stats page for monitoring
listen stats
    bind *:1936
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
    stats auth admin:password123
EOF

echo -e "${GREEN}Temporary configuration created at $TEMP_CFG${NC}"

# Test configuration
echo -e "${YELLOW}Testing configuration...${NC}"
if haproxy -f "$TEMP_CFG" -c; then
    echo -e "${GREEN}Configuration test passed!${NC}"
    
    # Replace current config
    cp "$TEMP_CFG" "$HAPROXY_CFG"
    
    # Restart HAProxy
    echo -e "${YELLOW}Restarting HAProxy...${NC}"
    systemctl restart haproxy || service haproxy restart
    
    # Check status
    if systemctl is-active --quiet haproxy; then
        echo -e "${GREEN}HAProxy is running successfully!${NC}"
        echo -e "${BLUE}Stats page: http://your-server:1936/${NC}"
        echo -e "${BLUE}Username: admin${NC}"
        echo -e "${BLUE}Password: password123${NC}"
    else
        echo -e "${RED}HAProxy failed to start!${NC}"
        echo "Restoring backup..."
        cp "$BACKUP_CFG" "$HAPROXY_CFG"
        systemctl restart haproxy
    fi
else
    echo -e "${RED}Configuration test failed!${NC}"
    echo "Restoring backup configuration..."
    cp "$BACKUP_CFG" "$HAPROXY_CFG"
fi

echo -e "${GREEN}=== Setup Complete ===${NC}"
