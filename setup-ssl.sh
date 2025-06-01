#!/bin/bash
# SSL Certificate Setup / Настройка на SSL сертификати

read -p "Въведете вашия домейн (напр. server.example.com): " DOMAIN
read -p "Въведете вашия email: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    error "Домейн и email са задължителни!"
    exit 1
fi

log "Настройка на SSL сертификат за $DOMAIN..."

# Install Certbot / Инсталиране на Certbot
apt install -y certbot

# Install Nginx for reverse proxy / Инсталиране на Nginx
apt install -y nginx

# Configure Nginx / Настройка на Nginx
cat > /etc/nginx/sites-available/coolify << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/coolify /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Get SSL certificate / Получаване на SSL сертификат
certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive

# Setup auto-renewal / Настройка на автоматично подновяване
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

log "SSL сертификатът е настроен успешно!"
log "Достъп към Coolify: https://$DOMAIN"