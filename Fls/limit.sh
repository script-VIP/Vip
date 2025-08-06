#!/bin/bash
REPOSLIM="https://raw.githubusercontent.com/Ilham24022001/Gantengzz/main/"
wget -q -O /usr/bin/limit-ip "${REPOSLIM}install/limit-ip"
chmod +x /usr/bin/*
cd /usr/bin
sed -i 's/\r//' limit-ip
cd
systemctl daemon-reload
wget -q -O /etc/systemd/system/limitvmess.service "${REPOSLIM}Fls/limitvmess.service" && chmod +x limitvmess.service >/dev/null 2>&1
wget -q -O /etc/systemd/system/limitvless.service "${REPOSLIM}Fls/limitvless.service" && chmod +x limitvless.service >/dev/null 2>&1
wget -q -O /etc/systemd/system/limittrojan.service "${REPOSLIM}Fls/limittrojan.service" && chmod +x limittrojan.service >/dev/null 2>&1
wget -q -O /etc/systemd/system/limitshadowsocks.service "${REPOSLIM}Fls/limitshadowsocks.service" && chmod +x limitshadowsocks.service >/dev/null 2>&1
wget -q -O /etc/xray/limit.vmess "${REPOSLIM}Fls/vmess" >/dev/null 2>&1
wget -q -O /etc/xray/limit.vless "${REPOSLIM}Fls/vless" >/dev/null 2>&1
wget -q -O /etc/xray/limit.trojan "${REPOSLIM}Fls/trojan" >/dev/null 2>&1
wget -q -O /etc/xray/limit.shadowsocks "${REPOSLIM}Fls/shadowsocks" >/dev/null 2>&1
chmod +x /etc/xray/limit.vmess
chmod +x /etc/xray/limit.vless
chmod +x /etc/xray/limit.trojan
chmod +x /etc/xray/limit.shadowsocks
systemctl daemon-reload
systemctl enable --now limitvmess
systemctl enable --now limitvless
systemctl enable --now limittrojan
systemctl enable --now limitshadowsocks
systemctl start limitvmess
systemctl start limitvless
systemctl start limittrojan
systemctl start limitshadowsocks