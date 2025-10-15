#!/bin/bash

# Backup config lama
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%s)

# Tulis ulang nginx.conf fix ogg
cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    types {
        audio/ogg            ogg;
        video/ogg            ogv;
        application/ogg      oga ogx;
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Test dan restart nginx
nginx -t && systemctl restart nginx

# Cek status nginx
if systemctl is-active --quiet nginx; then
  echo "✅ Nginx berhasil diperbaiki dan aktif."
else
  echo "❌ Nginx gagal dijalankan. Periksa log /etc/nginx/nginx.conf"
fi
