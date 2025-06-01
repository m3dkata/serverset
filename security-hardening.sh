#!/bin/bash
# Security Hardening / Засилване на сигурността

log "Засилване на сигурността..."

# Configure UFW firewall / Настройка на UFW firewall
log "Настройка на firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 8000/tcp  # Coolify
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Disable root SSH login / Забрана на root SSH достъп
log "Настройка на SSH сигурност..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# Install fail2ban / Инсталиране на fail2ban
log "Инсталиране на fail2ban..."
apt install -y fail2ban

# Configure fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Set up automatic security updates / Настройка на автоматични обновления
log "Настройка на автоматични обновления..."
apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades

log "Сигурността е засилена успешно!"