#!/bin/bash
# ServerSet - Interactive Ubuntu Server Management Tool
# Version: 3.1
# Usage: git clone https://github.com/m3dkata/serverset.git && chmod +x serverset/*.sh && ./serverset/serverset.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
SCRIPT_VERSION="3.1"
SCRIPT_DIR="/usr/local/bin"
CONFIG_FILE="/etc/serverset.conf"

# Utility functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Този скрипт трябва да се изпълни като root"
        echo "Използвайте: sudo ./serverset.sh"
        exit 1
    fi
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# ServerSet Configuration
DRIVE1="$DRIVE1"
DRIVE2="$DRIVE2"
BACKUP_DRIVE="$BACKUP_DRIVE"
ADMIN_EMAIL="$ADMIN_EMAIL"
DOMAIN="$DOMAIN"
INSTALLED="$INSTALLED"
INSTALL_DATE="$(date)"
EOF
}

# Main menu
show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                     ${CYAN}SERVERSET v$SCRIPT_VERSION${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}              ${YELLOW}Ubuntu Server Management Tool${NC}                ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$INSTALLED" = "true" ]; then
        echo -e "${GREEN}✅ Системата е инсталирана и готова${NC}"
        echo -e "${BLUE}📅 Инсталирана на: $INSTALL_DATE${NC}"
    else
        echo -e "${YELLOW}⚠️  Системата не е инсталирана${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}🔧 ИНСТАЛАЦИЯ И НАСТРОЙКА:${NC}"
    echo "  1)  Пълна инсталация (RAID1 + Coolify + Backup)"
    echo "  2)  Само RAID1 настройка"
    echo "  3)  Само Coolify инсталация"
    echo "  4)  Само Backup система"
    echo "  5)  Засилване на сигурността"
    echo ""
    
    echo -e "${CYAN}📊 МОНИТОРИНГ И СТАТУС:${NC}"
    echo "  6)  Сървърно табло (Dashboard)"
    echo "  7)  RAID статус и управление"
    echo "  8)  Системна информация"
    echo "  9)  Проверка на настройката"
    echo "  10) Health check"
    echo ""
    
    echo -e "${CYAN}💾 BACKUP И ВЪЗСТАНОВЯВАНЕ:${NC}"
    echo "  11) Ръчно backup"
    echo "  12) Аварийно възстановяване"
    echo "  13) Управление на backups"
    echo "  14) Тестване на restore"
    echo ""
    
    echo -e "${CYAN}🚀 COOLIFY УПРАВЛЕНИЕ:${NC}"
    echo "  15) Coolify статус"
    echo "  16) Рестартиране на Coolify"
    echo "  17) Coolify логове"
    echo "  18) Coolify ръководство за настройка"
    echo ""
    
    echo -e "${CYAN}🔒 СИГУРНОСТ И SSL:${NC}"
    echo "  19) SSL сертификат настройка"
    echo "  20) Firewall управление"
    echo "  21) Fail2ban статус"
    echo "  22) Security audit"
    echo ""
    
    echo -e "${CYAN}🛠️  ПОДДРЪЖКА:${NC}"
    echo "  23) Седмична поддръжка"
    echo "  24) Актуализиране на системата"
    echo "  25) Docker изчистване"
    echo "  26) Проверка на дисковете"
    echo "  27) Performance мониторинг"
    echo ""
    
    echo -e "${CYAN}📚 ДОКУМЕНТАЦИЯ И ПОМОЩ:${NC}"
    echo "  28) Бързи команди"
    echo "  29) Troubleshooting ръководство"
    echo "  30) Календар за поддръжка"
    echo "  31) Създаване на спешна карта"
    echo "  32) Recovery документация"
    echo ""
    
    echo -e "${CYAN}⚙️  НАСТРОЙКИ:${NC}"
    echo "  33) Конфигурация на системата"
    echo "  34) Актуализиране на ServerSet"
    echo "  35) Деинсталиране"
    echo ""
    
    echo -e "${RED}  0)  Изход${NC}"
    echo ""
    echo -n "Изберете опция (0-35): "
}

# Function implementations
full_installation() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                 ${YELLOW}ПЪЛНА ИНСТАЛАЦИЯ${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$INSTALLED" = "true" ]; then
        warn "Системата вече е инсталирана!"
        read -p "Искате ли да преинсталирате? (yes/no): " REINSTALL
        if [ "$REINSTALL" != "yes" ]; then
            return
        fi
    fi
    
    # Get configuration
    echo -e "${CYAN}🔧 НАСТРОЙКА НА ДИСКОВЕ:${NC}"
    lsblk
    echo ""
    read -p "Въведете първия NVMe диск (напр. /dev/nvme0n1): " DRIVE1
    read -p "Въведете втория NVMe диск (напр. /dev/nvme1n1): " DRIVE2
    read -p "Въведете HDD за backup (напр. /dev/sda): " BACKUP_DRIVE
    read -p "Въведете email за известия (optional): " ADMIN_EMAIL
    read -p "Въведете домейн (optional): " DOMAIN
    
    warn "ВНИМАНИЕ: Всички данни на посочените дискове ще бъдат изтрити!"
    read -p "Продължаване? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Операцията е отказана."
        return
    fi
    
    # Start installation
    log "Започване на пълната инсталация..."
    
    # Step 1: System Update
    log "Стъпка 1/10: Актуализиране на системата..."
    apt update && apt upgrade -y
    
    # Step 2: Install packages
    log "Стъпка 2/10: Инсталиране на пакети..."
    apt install -y curl wget git htop nano vim unzip software-properties-common \
        apt-transport-https ca-certificates gnupg lsb-release mdadm rsync cron \
        smartmontools hdparm mailutils postfix ufw fail2ban bc
    
    # Step 3: Configure locale
    log "Стъпка 3/10: Настройка на български език..."
    locale-gen bg_BG.UTF-8
    update-locale LANG=bg_BG.UTF-8
    timedatectl set-timezone Europe/Sofia
    
    # Step 4: Install Docker
    log "Стъпка 4/10: Инсталиране на Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
    
    # Step 5: Setup RAID1
    log "Стъпка 5/10: Настройка на RAID1..."
    setup_raid
    
    # Step 6: Setup backup
    log "Стъпка 6/10: Настройка на backup..."
    setup_backup
    
    # Step 7: Security
    log "Стъпка 7/10: Засилване на сигурността..."
    setup_security
    
    # Step 8: Install Coolify
    log "Стъпка 8/10: Инсталиране на Coolify..."
    install_coolify
    
    # Step 9: Create scripts
    log "Стъпка 9/10: Създаване на скриптове..."
    create_all_scripts
    
    # Step 10: Final setup
    log "Стъпка 10/10: Финални настройки..."
    setup_cron_jobs
    create_aliases
    
    # Mark as installed
    INSTALLED="true"
    save_config
    
    show_success_message
}

setup_raid() {
    log "Създаване на RAID1 масив..."
    mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 $DRIVE1 $DRIVE2 --assume-clean
    mkfs.ext4 /dev/md0
    mkdir -p /data
    mount /dev/md0 /data
    echo "/dev/md0 /data ext4 defaults 0 2" >> /etc/fstab
    mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    update-initramfs -u
    log "RAID1 настроен успешно!"
}

setup_backup() {
    log "Настройка на backup диска..."
    mkfs.ext4 $BACKUP_DRIVE
    mkdir -p /mnt/backup
    mount $BACKUP_DRIVE /mnt/backup
    echo "$BACKUP_DRIVE /mnt/backup ext4 defaults 0 2" >> /etc/fstab
    mkdir -p /mnt/backup/{system,data,logs,recovery-docs}
    log "Backup система настроена успешно!"
}

setup_security() {
    log "Настройка на firewall..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 8000/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    log "Настройка на fail2ban..."
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
    log "Сигурността е засилена успешно!"
}

install_coolify() {
    log "Изтегляне и инсталиране на Coolify..."
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
    log "Coolify инсталиран успешно!"
}

create_all_scripts() {
    # System Backup Script
    cat > "$SCRIPT_DIR/system-backup.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/system-backup.log"
BACKUP_DIR="/mnt/backup/system/$(date +%Y%m%d_%H%M%S)"

log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_backup "Започване на системно backup..."
mkdir -p "$BACKUP_DIR"

# Backup system image
log_backup "Създаване на системен образ..."
dd if=/dev/md0 bs=64K | gzip > "$BACKUP_DIR/system-image.gz"

# Backup configs
log_backup "Backup на конфигурации..."
tar -czf "$BACKUP_DIR/configs.tar.gz" /etc/ /data/coolify/ 2>/dev/null || true

# Cleanup old backups
log_backup "Изчистване на стари backups..."
ls -t /mnt/backup/system/ | tail -n +6 | xargs -r rm -rf

log_backup "Backup завърши успешно!"
EOF

    # Health Check Script
    cat > "$SCRIPT_DIR/health-check.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/health-check.log"

log_health() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Check RAID
if ! grep -q "md0.*active.*raid1" /proc/mdstat; then
    log_health "КРИТИЧНО: RAID проблем!"
fi

# Check disk space
df -h | grep -E "/data|/mnt/backup" | while read line; do
    usage=$(echo $line | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 85 ]]; then
        log_health "ПРЕДУПРЕЖДЕНИЕ: Високо използване: $line"
    fi
done

# Check Coolify
if ! curl -f http://localhost:8000 >/dev/null 2>&1; then
    log_health "ПРЕДУПРЕЖДЕНИЕ: Coolify не отговаря"
fi

log_health "Health check завърши."
EOF

    # RAID Manager Script
    cat > "$SCRIPT_DIR/raid-manager.sh" << 'EOF'
#!/bin/bash

show_status() {
    echo "=== RAID СТАТУС ==="
    cat /proc/mdstat
    echo ""
    mdadm --detail /dev/md0
}

replace_disk() {
    echo "=== ЗАМЯНА НА ДИСК ==="
    cat /proc/mdstat
    echo ""
    read -p "Неизправен диск: " FAILED_DISK
    read -p "Нов диск: " NEW_DISK
    
    mdadm --manage /dev/md0 --remove $FAILED_DISK
    mdadm --manage /dev/md0 --add $NEW_DISK
    echo "Rebuild започна. Проверете: watch cat /proc/mdstat"
}

case "$1" in
    status) show_status ;;
    replace) replace_disk ;;
    *) echo "Употреба: $0 {status|replace}" ;;
esac
EOF

    # Server Dashboard Script
    cat > "$SCRIPT_DIR/server-dashboard.sh" << 'EOF'
#!/bin/bash
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    СЪРВЪРНО ТАБЛО                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🖥️  СИСТЕМА:"
echo "   Време: $(date)"
echo "   Uptime: $(uptime -p)"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "💾 ПАМЕТ:"
free -h | grep -E "Mem|Swap"
echo ""

echo "💿 ДИСКОВЕ:"
df -h | grep -E "Filesystem|/dev/md0|/mnt"
echo ""

echo "🔄 RAID:"
if [ -f /proc/mdstat ]; then
    grep -A 3 "md0" /proc/mdstat || echo "   RAID не е намерен"
fi
echo ""

echo "🐳 DOCKER:"
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker работи"
    echo "   Контейнери: $(docker ps -q | wc -l) активни"
else
    echo "   ❌ Docker не работи"
fi
echo ""

echo "🚀 COOLIFY:"
if curl -f http://localhost:8000 >/dev/null 2>&1; then
    echo "   ✅ Coolify работи - http://$(hostname -I | awk '{print $1}'):8000"
else
    echo "   ❌ Coolify не отговаря"
fi
EOF

    # Emergency Restore Script
    cat > "$SCRIPT_DIR/emergency-restore.sh" << 'EOF'
#!/bin/bash
echo "=== АВАРИЙНО ВЪЗСТАНОВЯВАНЕ ==="
echo "Налични backups:"
ls -la /mnt/backup/system/ | grep "^d" | tail -10
echo ""
read -p "Backup дата (YYYYMMDD_HHMMSS): " BACKUP_DATE

BACKUP_PATH="/mnt/backup/system/$BACKUP_DATE"
if [ ! -d "$BACKUP_PATH" ]; then
    echo "ГРЕШКА: Backup не съществува!"
    exit 1
fi

echo "ВНИМАНИЕ: Това ще презапише системата!"
read -p "Потвърждение (YES): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    exit 1
fi

systemctl stop docker
gunzip -c "$BACKUP_PATH/system-image.gz" | dd of=/dev/md0 bs=64K status=progress
echo "Възстановяването завърши! Рестартирайте: sudo reboot"
EOF

    chmod +x "$SCRIPT_DIR"/*.sh
}

setup_cron_jobs() {
    (crontab -l 2>/dev/null; echo "0 15 * * 6 $SCRIPT_DIR/system-backup.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * $SCRIPT_DIR/health-check.sh") | crontab -
}

create_aliases() {
    cat >> /root/.bashrc << 'EOF'

# ServerSet aliases
alias dashboard='server-dashboard.sh'
alias raidstatus='raid-manager.sh status'
alias backup='system-backup.sh'
alias serverset='/usr/local/bin/serverset.sh'
EOF
}

show_dashboard() {
    $SCRIPT_DIR/server-dashboard.sh
    echo ""
    read -p "Натиснете Enter за връщане в менюто..."
}

show_raid_status() {
    clear
    echo -e "${CYAN}🔄 RAID СТАТУС И УПРАВЛЕНИЕ${NC}"
    echo ""
    echo "1) Показване на RAID статус"
    echo "2) Замяна на неизправен диск"
    echo "3) Детайлна RAID информация"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1) $SCRIPT_DIR/raid-manager.sh status; read -p "Enter за продължаване..." ;;
        2) $SCRIPT_DIR/raid-manager.sh replace; read -p "Enter за продължаване..." ;;
        3) mdadm --detail /dev/md0; read -p "Enter за продължаване..." ;;
        0) return ;;
    esac
}

show_system_info() {
    clear
    echo -e "${CYAN}📊 СИСТЕМНА ИНФОРМАЦИЯ${NC}"
    echo ""
    
    echo "🖥️  ХАРДУЕР:"
    echo "   CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "   Cores: $(nproc)"
    echo "   RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo ""
    
    echo "💾 СЪХРАНЕНИЕ:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "NAME|nvme|sd|md"
    echo ""
    
    echo "🌐 МРЕЖА:"
    echo "   IP: $(hostname -I | awk '{print $1}')"
    echo "   Gateway: $(ip route | grep default | awk '{print $3}')"
    echo ""
    
    echo "🔧 УСЛУГИ:"
    for service in docker nginx ssh cron ufw fail2ban; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo "   ✅ $service"
        else
            echo "   ❌ $service"
        fi
    done
    echo ""
    
    read -p "Натиснете Enter за връщане..."
}

verify_setup() {
    clear
    echo -e "${CYAN}🔍 ПРОВЕРКА НА НАСТРОЙКАТА${NC}"
    echo ""
    
    ERRORS=0
    
    # Check RAID
    if grep -q "md0.*active.*raid1" /proc/mdstat; then
        echo "✅ RAID1 работи"
    else
        echo "❌ RAID проблем"
        ((ERRORS++))
    fi
    
    # Check mounts
    if mountpoint -q /data && mountpoint -q /mnt/backup; then
        echo "✅ Дискове монтирани"
    else
        echo "❌ Проблем с монтирането"
        ((ERRORS++))
    fi
    
    # Check Docker
    if systemctl is-active --quiet docker; then
        echo "✅ Docker работи"
    else
        echo "❌ Docker не работи"
        ((ERRORS++))
    fi
    
    # Check Coolify
    if curl -f http://localhost:8000 >/dev/null 2>&1; then
        echo "✅ Coolify отговаря"
    else
        echo "⚠️  Coolify не отговаря"
    fi
    
    # Check scripts
    for script in system-backup.sh health-check.sh raid-manager.sh; do
        if [ -x "$SCRIPT_DIR/$script" ]; then
            echo "✅ $script"
        else
            echo "❌ $script липсва"
            ((ERRORS++))
        fi
    done
    
    # Check cron
    if crontab -l | grep -q system-backup.sh; then
        echo "✅ Backup cron настроен"
    else
        echo "❌ Backup cron липсва"
        ((ERRORS++))
    fi
    
    echo ""
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}🎉 Всички проверки преминаха успешно!${NC}"
    else
        echo -e "${RED}⚠️  Намерени са $ERRORS проблема${NC}"
    fi
    
    read -p "Натиснете Enter за връщане..."
}

manual_backup() {
    clear
    echo -e "${CYAN}💾 РЪЧНО BACKUP${NC}"
    echo ""
    
    if [ ! -f "$SCRIPT_DIR/system-backup.sh" ]; then
        error "Backup скриптът не е намерен!"
        read -p "Enter за продължаване..."
        return
    fi
    
    log "Стартиране на ръчно backup..."
    $SCRIPT_DIR/system-backup.sh
    
    echo ""
    log "Backup завърши! Проверете /mnt/backup/system/"
    read -p "Натиснете Enter за връщане..."
}

emergency_restore() {
    clear
    echo -e "${RED}🆘 АВАРИЙНО ВЪЗСТАНОВЯВАНЕ${NC}"
    echo ""
    
    warn "ВНИМАНИЕ: Това ще презапише цялата система!"
    read -p "Продължаване? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        $SCRIPT_DIR/emergency-restore.sh
    fi
    
    read -p "Натиснете Enter за връщане..."
}

check_coolify_installation() {
    if [ -d "/data/coolify" ] && [ -f "/data/coolify/docker-compose.yml" ]; then
        return 0  # Coolify is installed
    else
        return 1  # Coolify is not installed
    fi
}

coolify_management() {
    clear
    echo -e "${CYAN}🚀 COOLIFY УПРАВЛЕНИЕ${NC}"
    echo ""
    echo "1) Coolify статус"
    echo "2) Рестартиране на Coolify"
    echo "3) Coolify логове"
    echo "4) Спиране на Coolify"
    echo "5) Стартиране на Coolify"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1)
            if curl -f http://localhost:8000 >/dev/null 2>&1; then
                echo "✅ Coolify работи на http://$(hostname -I | awk '{print $1}'):8000"
            else
                echo "❌ Coolify не отговаря"
            fi
            ;;
        2)
            if [ -d "/data/coolify" ] && [ -f "/data/coolify/docker-compose.yml" ]; then
                log "Рестартиране на Coolify..."
                cd /data/coolify && docker compose restart
            else
                error "Coolify не е инсталиран или конфигурацията не е намерена!"
                echo "Пътят /data/coolify/docker-compose.yml не съществува."
            fi
            ;;
        3)
            if [ -d "/data/coolify" ] && [ -f "/data/coolify/docker-compose.yml" ]; then
                log "Показване на Coolify логове..."
                echo "Натиснете Ctrl+C за изход от логовете"
                sleep 2
                cd /data/coolify && docker compose logs -f
            else
                error "Coolify не е инсталиран или конфигурацията не е намерена!"
                echo "Пътят /data/coolify/docker-compose.yml не съществува."
                echo ""
                echo "Възможни причини:"
                echo "1. Coolify не е инсталиран - използвайте опция 3 от главното меню"
                echo "2. Coolify е инсталиран в друга директория"
                echo "3. Проблем при инсталацията"
                echo ""
                echo "За проверка на Docker контейнери:"
                docker ps -a | grep -i coolify || echo "Няма Coolify контейнери"
            fi
            ;;
        4)
            if [ -d "/data/coolify" ] && [ -f "/data/coolify/docker-compose.yml" ]; then
                log "Спиране на Coolify..."
                cd /data/coolify && docker compose stop
            else
                error "Coolify не е инсталиран или конфигурацията не е намерена!"
            fi
            ;;
        5)
            if [ -d "/data/coolify" ] && [ -f "/data/coolify/docker-compose.yml" ]; then
                log "Стартиране на Coolify..."
                cd /data/coolify && docker compose up -d
            else
                error "Coolify не е инсталиран или конфигурацията не е намерена!"
            fi
            ;;
        0) return ;;
    esac
    
    read -p "Натиснете Enter за продължаване..."
}


ssl_setup() {
    clear
    echo -e "${CYAN}🔒 SSL СЕРТИФИКАТ НАСТРОЙКА${NC}"
    echo ""
    
    read -p "Домейн: " domain
    read -p "Email: " email
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        error "Домейн и email са задължителни!"
        read -p "Enter за продължаване..."
        return
    fi
    
    log "Инсталиране на Certbot..."
    apt install -y certbot nginx
    
    log "Настройка на Nginx..."
    cat > /etc/nginx/sites-available/coolify << EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/coolify /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl restart nginx
    
    log "Получаване на SSL сертификат..."
    certbot --nginx -d $domain --email $email --agree-tos --non-interactive
    
    log "SSL сертификатът е настроен! Достъп: https://$domain"
    read -p "Натиснете Enter за връщане..."
}

show_quick_commands() {
    clear
    echo -e "${CYAN}📋 БЪРЗИ КОМАНДИ${NC}"
    echo ""
    echo "🖥️  СИСТЕМНИ:"
    echo "   dashboard                - Сървърно табло"
    echo "   serverset               - Това меню"
    echo "   raidstatus              - RAID статус"
    echo "   backup                  - Ръчно backup"
    echo ""
    echo "🔄 RAID:"
    echo "   raid-manager.sh status  - RAID статус"
    echo "   raid-manager.sh replace - Замяна на диск"
    echo "   cat /proc/mdstat        - Бърз RAID статус"
    echo ""
    echo "🐳 DOCKER:"
    echo "   docker ps               - Контейнери"
    echo "   docker logs [name]      - Логове"
    echo "   docker system prune -f  - Изчистване"
    echo ""
    echo "🚀 COOLIFY:"
    echo "   cd /data/coolify && docker compose logs -f"
    echo "   cd /data/coolify && docker compose restart"
    echo ""
    echo "📊 МОНИТОРИНГ:"
    echo "   htop                    - Процеси"
    echo "   df -h                   - Дискове"
    echo "   free -h                 - Памет"
    echo ""
    read -p "Натиснете Enter за връщане..."
}

weekly_maintenance() {
    clear
    echo -e "${CYAN}🛠️  СЕДМИЧНА ПОДДРЪЖКА${NC}"
    echo ""
    
    log "Актуализиране на пакети..."
    apt update && apt upgrade -y
    
    log "Изчистване на кеш..."
    apt autoremove -y
    apt autoclean
    
    log "Docker изчистване..."
    docker system prune -f
    docker volume prune -f
    
    log "Проверка на дисковото пространство..."
    df -h | grep -E "/data|/mnt/backup" | while read line; do
        usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        if [[ $usage -gt 80 ]]; then
            warn "Високо използване: $line"
        fi
    done
    
    log "Ротация на логове..."
    logrotate /etc/logrotate.conf
    
    log "Актуализиране на Coolify..."
    cd /data/coolify && docker compose pull && docker compose up -d
    
    log "Седмичната поддръжка завърши!"
    read -p "Натиснете Enter за връщане..."
}

show_troubleshooting() {
    clear
    echo -e "${CYAN}🔧 ОТСТРАНЯВАНЕ НА ПРОБЛЕМИ${NC}"
    echo ""
    echo "🚀 COOLIFY НЕ СЕ ЗАРЕЖДА:"
    echo "   1. systemctl status docker"
    echo "   2. cd /data/coolify && docker compose restart"
    echo "   3. cd /data/coolify && docker compose logs -f"
    echo ""
    echo "🔄 RAID ПОКАЗВА 'DEGRADED':"
    echo "   1. cat /proc/mdstat"
    echo "   2. mdadm --detail /dev/md0"
    echo "   3. raid-manager.sh replace"
    echo ""
    echo "💾 BACKUP НЕ РАБОТИ:"
    echo "   1. df -h /mnt/backup"
    echo "   2. crontab -l"
    echo "   3. system-backup.sh"
    echo ""
    echo "🐳 DOCKER ПРОБЛЕМИ:"
    echo "   1. docker logs CONTAINER_NAME"
    echo "   2. docker stats"
    echo "   3. docker restart CONTAINER_NAME"
    echo ""
    echo "🌐 МРЕЖОВИ ПРОБЛЕМИ:"
    echo "   1. ping google.com"
    echo "   2. ufw status"
    echo "   3. ss -tulpn"
    echo ""
    echo "💿 ДИСКОВОТО ПРОСТРАНСТВО СВЪРШВА:"
    echo "   1. df -h"
    echo "   2. du -sh /* | sort -hr"
    echo "   3. docker system prune -a"
    echo ""
    read -p "Натиснете Enter за връщане..."
}

system_configuration() {
    clear
    echo -e "${CYAN}⚙️  КОНФИГУРАЦИЯ НА СИСТЕМАТА${NC}"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "Текуща конфигурация:"
        echo "  DRIVE1: $DRIVE1"
        echo "  DRIVE2: $DRIVE2"
        echo "  BACKUP_DRIVE: $BACKUP_DRIVE"
        echo "  ADMIN_EMAIL: $ADMIN_EMAIL"
        echo "  DOMAIN: $DOMAIN"
        echo "  INSTALLED: $INSTALLED"
        echo ""
    fi
    
    echo "1) Промяна на email"
    echo "2) Промяна на домейн"
    echo "3) Показване на пълната конфигурация"
    echo "4) Нулиране на конфигурацията"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1)
            read -p "Нов email: " new_email
            ADMIN_EMAIL="$new_email"
            save_config
            log "Email обновен!"
            ;;
        2)
            read -p "Нов домейн: " new_domain
            DOMAIN="$new_domain"
            save_config
            log "Домейн обновен!"
            ;;
        3)
            cat "$CONFIG_FILE"
            ;;
        4)
            rm -f "$CONFIG_FILE"
            INSTALLED=""
            log "Конфигурацията е нулирана!"
            ;;
        0) return ;;
    esac
    
    read -p "Натиснете Enter за продължаване..."
}
# Add this function before update_serverset()
check_internet() {
    log "Проверка на интернет връзката..."
    
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error "Няма интернет връзка!"
        return 1
    fi
    
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        error "GitHub не е достъпен!"
        return 1
    fi
    
    log "Интернет връзката е OK"
    return 0
}


update_serverset() {
    clear
    echo -e "${CYAN}🔄 АКТУАЛИЗИРАНЕ НА SERVERSET${NC}"
    echo ""
    
    # Check internet connectivity
    if ! check_internet; then
        read -p "Натиснете Enter за връщане..."
        return
    fi
    
    log "Проверка за актуализации..."
    
    # Backup current version
    BACKUP_DIR="/tmp/serverset-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup current serverset and all scripts
    cp "$0" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$SCRIPT_DIR"/*.sh "$BACKUP_DIR/" 2>/dev/null || true
    
    log "Backup създаден в: $BACKUP_DIR"
    
    # Create temporary directory for new files
    TEMP_DIR="/tmp/serverset-update"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # All shell scripts in your repository
    SCRIPTS=(
        "serverset.sh"
        "complete-setup.sh"
        "coolify-setup-guide.sh"
        "create-emergency-card.sh"
        "create-recovery-docs.sh"
        "disk-health-monitor.sh"
        "emergency-restore.sh"
        "final-optimization.sh"
        "final-validation.sh"
        "health-check.sh"
        "install-coolify.sh"
        "installation-summary.sh"
        "maintenance-calendar.sh"
        "performance-tuning.sh"
        "post-install-checklist.sh"
        "quick-commands.sh"
        "raid-manager.sh"
        "security-hardening.sh"
        "server-dashboard.sh"
        "setup-backup.sh"
        "setup-cron.sh"
        "setup-raid.sh"
        "setup-server.sh"
        "setup-ssl.sh"
        "success-banner.sh"
        "system-backup.sh"
        "system-info.sh"
        "troubleshooting-guide.sh"
        "verify-setup.sh"
        "weekly-maintenance.sh"
    )
    
    # Download all scripts from GitHub
    log "Изтегляне на скриптове от GitHub..."
    
    DOWNLOADED_COUNT=0
    FAILED_COUNT=0
    
    for script in "${SCRIPTS[@]}"; do
        echo -n "  Изтегляне на $script... "
        
        if wget -q -O "$TEMP_DIR/$script" "https://raw.githubusercontent.com/m3dkata/serverset/main/$script"; then
            echo -e "${GREEN}✅${NC}"
            ((DOWNLOADED_COUNT++))
        else
            echo -e "${RED}❌${NC}"
            ((FAILED_COUNT++))
        fi
    done
    
    echo ""
    log "Изтеглени: $DOWNLOADED_COUNT файла"
    if [ $FAILED_COUNT -gt 0 ]; then
        warn "Неуспешни: $FAILED_COUNT файла"
    fi
    
    # Check if main script was downloaded successfully
    if [ ! -f "$TEMP_DIR/serverset.sh" ]; then
        error "Основният скрипт не беше изтеглен!"
        rm -rf "$TEMP_DIR"
        read -p "Натиснете Enter за връщане..."
        return
    fi
    
    # Get new version
    NEW_VERSION=$(grep "SCRIPT_VERSION=" "$TEMP_DIR/serverset.sh" | head -1 | cut -d'"' -f2)
    
    if [ -z "$NEW_VERSION" ]; then
        error "Не може да се определи новата версия!"
        rm -rf "$TEMP_DIR"
        read -p "Натиснете Enter за връщане..."
        return
    fi
    
    echo ""
    echo -e "${BLUE}Текуща версия: ${YELLOW}$SCRIPT_VERSION${NC}"
    echo -e "${BLUE}Нова версия: ${GREEN}$NEW_VERSION${NC}"
    echo ""
    
    # Show downloaded files
    echo -e "${CYAN}Изтеглени файлове:${NC}"
    ls -la "$TEMP_DIR/" | grep "\.sh$" | awk '{printf "  %-30s %s\n", $9, $5" bytes"}'
    echo ""
    
    if [ "$NEW_VERSION" != "$SCRIPT_VERSION" ]; then
        log "Намерена нова версия: $NEW_VERSION"
        read -p "Актуализиране на всички скриптове? (yes/no): " confirm
    else
        log "Същата версия, но може да има актуализирани скриптове"
        read -p "Принудително актуализиране на всички скриптове? (yes/no): " confirm
    fi
    
    if [ "$confirm" = "yes" ]; then
        log "Актуализиране на файловете..."
        
        UPDATED_COUNT=0
        
        # Update all downloaded scripts
        for script in "${SCRIPTS[@]}"; do
            if [ -f "$TEMP_DIR/$script" ]; then
                # Make executable
                chmod +x "$TEMP_DIR/$script"
                
                if [ "$script" = "serverset.sh" ]; then
                    # Update main script (current running script and the one in SCRIPT_DIR)
                    cp "$TEMP_DIR/$script" "$0"
                    cp "$TEMP_DIR/$script" "$SCRIPT_DIR/$script"
                    echo -e "  ${GREEN}✅ $script (main script)${NC}"
                else
                    # Update other scripts
                    cp "$TEMP_DIR/$script" "$SCRIPT_DIR/$script"
                    echo -e "  ${GREEN}✅ $script${NC}"
                fi
                ((UPDATED_COUNT++))
            fi
        done
        
        echo ""
        log "Актуализирани $UPDATED_COUNT скрипта!"
        log "Backup на старите файлове: $BACKUP_DIR"
        
        # Update configuration to reflect new version
        if [ "$NEW_VERSION" != "$SCRIPT_VERSION" ]; then
            SCRIPT_VERSION="$NEW_VERSION"
            save_config
        fi
        
        echo ""
        echo -e "${GREEN}🎉 АКТУАЛИЗИРАНЕТО ЗАВЪРШИ УСПЕШНО! 🎉${NC}"
        echo ""
        echo -e "${CYAN}Какво е ново:${NC}"
        echo "• Всички скриптове са актуализирани"
        echo "• Нови функции и подобрения"
        echo "• Поправки на грешки"
        echo "• Подобрена сигурност и стабилност"
        echo ""
        echo -e "${YELLOW}Важно:${NC}"
        echo "• Backup файлове: $BACKUP_DIR"
        echo "• Всички скриптове са готови за използване"
        echo "• Конфигурацията е запазена"
        echo ""
        
        read -p "Рестартиране на ServerSet с новата версия? (yes/no): " restart
        
        if [ "$restart" = "yes" ]; then
            rm -rf "$TEMP_DIR"
            log "Рестартиране с нова версия..."
            sleep 2
            exec "$0"
        fi
    else
        log "Актуализирането е отказано"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    read -p "Натиснете Enter за връщане..."
}



uninstall_system() {
    clear
    echo -e "${RED}🗑️  ДЕИНСТАЛИРАНЕ${NC}"
    echo ""
    
    warn "ВНИМАНИЕ: Това ще премахне цялата ServerSet конфигурация!"
    warn "RAID и данните няма да бъдат засегнати."
    echo ""
    read -p "Сигурни ли сте? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        return
    fi
    
    log "Премахване на cron задачи..."
    crontab -l | grep -v "system-backup.sh\|health-check.sh" | crontab -
    
    log "Премахване на скриптове..."
    rm -f "$SCRIPT_DIR"/system-backup.sh
    rm -f "$SCRIPT_DIR"/health-check.sh
    rm -f "$SCRIPT_DIR"/raid-manager.sh
    rm -f "$SCRIPT_DIR"/server-dashboard.sh
    rm -f "$SCRIPT_DIR"/emergency-restore.sh
    
    log "Премахване на конфигурация..."
    rm -f "$CONFIG_FILE"
    
    log "Премахване на псевдоними..."
    sed -i '/# ServerSet aliases/,+10d' /root/.bashrc
    
    log "Деинсталирането завърши!"
    echo ""
    echo "За пълно премахване на системата:"
    echo "1. Спрете Coolify: cd /data/coolify && docker compose down"
    echo "2. Премахнете RAID: mdadm --stop /dev/md0"
    echo "3. Форматирайте дисковете ръчно"
    
    read -p "Натиснете Enter за изход..."
    exit 0
}

show_success_message() {
    clear
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║    🎉 ПОЗДРАВЛЕНИЯ! ВАШИЯТ СЪРВЪР Е ГОТОВ! 🎉              ║
    ║                                                              ║
    ║  ✅ Ubuntu Server с RAID1                                   ║
    ║  ✅ Coolify за управление на приложения                     ║
    ║  ✅ Автоматични backups всяка събота в 15:00               ║
    ║  ✅ Ежедневни health checks в 02:00                        ║
    ║  ✅ Мониторинг и сигурност                                  ║
    ║  ✅ Пълна документация                                      ║
    ║                                                              ║
    ║  🚀 Готов за производство!                                  ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    echo -e "${CYAN}🌐 ДОСТЪП ДО COOLIFY:${NC}"
    echo "    http://$(hostname -I | awk '{print $1}'):8000"
    echo ""
    echo -e "${CYAN}📋 БЪРЗИ КОМАНДИ:${NC}"
    echo "    dashboard          - Статус на сървъра"
    echo "    serverset          - Това меню"
    echo "    raidstatus         - RAID статус"
    echo "    backup             - Ръчно backup"
    echo ""
    echo -e "${CYAN}🔔 СЛЕДВАЩИ СТЪПКИ:${NC}"
    echo "    1. Създайте admin акаунт в Coolify"
    echo "    2. Тествайте backup системата"
    echo "    3. Настройте домейн и SSL (ако имате)"
    echo ""
    
    read -p "Натиснете Enter за връщане в менюто..."
}

# Main execution
main() {
    check_root
    load_config
    
    # Install serverset command globally
    if [ ! -f "$SCRIPT_DIR/serverset.sh" ]; then
        cp "$0" "$SCRIPT_DIR/serverset.sh"
        chmod +x "$SCRIPT_DIR/serverset.sh"
        
        # Add to PATH if not already there
        if ! grep -q "serverset" /root/.bashrc; then
            echo 'alias serverset="/usr/local/bin/serverset.sh"' >> /root/.bashrc
        fi
    fi
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) full_installation ;;
            2) setup_raid ;;
            3) install_coolify ;;
            4) setup_backup ;;
            5) setup_security ;;
            6) show_dashboard ;;
            7) show_raid_status ;;
            8) show_system_info ;;
            9) verify_setup ;;
            10) $SCRIPT_DIR/health-check.sh; read -p "Enter..." ;;
            11) manual_backup ;;
            12) emergency_restore ;;
            13) ls -la /mnt/backup/system/; read -p "Enter..." ;;
            14) echo "Test restore функция в разработка"; read -p "Enter..." ;;
            15) coolify_management ;;
            16) 
                if check_coolify_installation; then
                    cd /data/coolify && docker compose restart
                    log "Coolify рестартиран!"
                else
                    error "Coolify не е инсталиран!"
                fi
                read -p "Enter..." 
                ;;
            17) 
                if check_coolify_installation; then
                    echo "Натиснете Ctrl+C за изход от логовете"
                    sleep 2
                    cd /data/coolify && docker compose logs -f
                else
                    error "Coolify не е инсталиран!"
                    echo "Използвайте опция 3 за инсталиране на Coolify"
                    read -p "Enter..."
                fi
                ;;
            18) 
                if check_coolify_installation; then
                    echo "Отворете: http://$(hostname -I | awk '{print $1}'):8000"
                else
                    echo "Coolify не е инсталиран! Използвайте опция 3 за инсталиране."
                fi
                read -p "Enter..." 
                ;;
            19) ssl_setup ;;
            20) ufw status verbose; read -p "Enter..." ;;
            21) fail2ban-client status; read -p "Enter..." ;;
            22) echo "Security audit в разработка"; read -p "Enter..." ;;
            23) weekly_maintenance ;;
            24) apt update && apt upgrade; read -p "Enter..." ;;
            25) docker system prune -af; read -p "Enter..." ;;
            26) smartctl -H /dev/nvme0n1 /dev/nvme1n1; read -p "Enter..." ;;
            27) htop ;;
            28) show_quick_commands ;;
            29) show_troubleshooting ;;
            30) echo "Календар за поддръжка в разработка"; read -p "Enter..." ;;
            31) cat /mnt/backup/EMERGENCY-CONTACT-CARD.txt 2>/dev/null || echo "Картата не е създадена"; read -p "Enter..." ;;
            32) ls /mnt/backup/recovery-docs/ 2>/dev/null || echo "Документацията не е създадена"; read -p "Enter..." ;;
            33) system_configuration ;;
            34) update_serverset ;;
            35) uninstall_system ;;
            0) 
                echo -e "${GREEN}Благодарим, че използвате ServerSet!${NC}"
                exit 0
                ;;
            *)
                error "Невалиден избор! Моля изберете 0-35."
                sleep 2
                ;;
        esac
    done
}

# Start the application
main "$@"


