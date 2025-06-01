#!/bin/bash
# Final System Optimization / Финална оптимизация на системата

echo "Прилагане на финални оптимизации..."

# Create swap file if not exists / Създаване на swap файл
if [ ! -f /swapfile ]; then
    echo "Създаване на swap файл..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Optimize systemd services / Оптимизация на systemd услуги
echo "Оптимизация на systemd услуги..."
systemctl disable snapd 2>/dev/null || true
systemctl disable bluetooth 2>/dev/null || true
systemctl disable cups 2>/dev/null || true

# Set timezone to Sofia / Настройка на часова зона
timedatectl set-timezone Europe/Sofia

# Configure automatic updates / Настройка на автоматични актуализации
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Create useful aliases / Създаване на полезни псевдоними
cat >> /root/.bashrc << 'EOF'

# Custom aliases for server management
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias histg='history | grep'
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'

# Server specific aliases
alias logs='cd /var/log'
alias coolify='cd /data/coolify'
alias backup-dir='cd /mnt/backup'
alias check-raid='cat /proc/mdstat'
alias docker-clean='docker system prune -af'
alias update-system='apt update && apt upgrade'
EOF

echo "Финалната оптимизация завърши успешно!"