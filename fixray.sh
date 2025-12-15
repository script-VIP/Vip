#!/bin/bash

# Stop all services
systemctl stop xray
systemctl stop nginx
systemctl stop haproxy
systemctl stop udp-custom
systemctl stop noobzvpns
systemctl stop ws

# Fix permissions
chown -R www-data:www-data /etc/xray
chmod 644 /etc/xray/*.json
chmod 600 /etc/xray/*.key

# Recreate SSL if needed
domain=$(cat /etc/xray/domain 2>/dev/null)
if [ -n "$domain" ]; then
    systemctl stop nginx
    /root/.acme.sh/acme.sh --installcert -d $domain \
        --fullchainpath /etc/xray/xray.crt \
        --keypath /etc/xray/xray.key --ecc
    chmod 600 /etc/xray/xray.key
    cat /etc/xray/xray.crt /etc/xray/xray.key | tee /etc/haproxy/hap.pem
fi

# Fix config files
wget -qO /etc/xray/config.json "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/config.json"
wget -qO /etc/haproxy/haproxy.cfg "https://raw.githubusercontent.com/script-VIP/Vip/main/Cfg/haproxy.cfg"
sed -i "s/xxx/$(cat /etc/xray/domain)/g" /etc/haproxy/haproxy.cfg

# Reset iptables
iptables -F
iptables -X
netfilter-persistent save
netfilter-persistent reload

# Restart services
systemctl daemon-reload
systemctl start xray
systemctl start nginx
systemctl start haproxy
systemctl start udp-custom
systemctl start noobzvpns
systemctl start ws

# Check status
echo "=== Status Services ==="
systemctl status xray --no-pager
echo ""
echo "=== Log Xray (terakhir 10 baris) ==="
tail -10 /var/log/xray/error.log
