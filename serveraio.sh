#!/bin/bash
# ServerSet All-in-One - Simplified Ubuntu Server Management Tool
# Version: 4.0
# Usage: wget -O serverset.sh https://your-domain.com/serverset.sh && chmod +x serverset.sh && ./serverset.sh

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
SCRIPT_VERSION="4.0"
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

# Detect and display available drives
detect_drives() {
    clear
    echo -e "${CYAN}💿 НАЛИЧНИ ДИСКОВЕ:${NC}"
    echo ""
    
    # Show all drives with details
    echo "ВСИЧКИ ДИСКОВЕ:"
    lsblk -o NAME,SIZE,TYPE,MODEL,MOUNTPOINT | grep -E "NAME|disk"
    echo ""
    
    # Detect NVMe drives
    NVME_DRIVES=($(lsblk -ndo NAME | grep nvme))
    if [ ${#NVME_DRIVES[@]} -gt 0 ]; then
        echo -e "${GREEN}📀 NVMe ДИСКОВЕ (за RAID1):${NC}"
        for drive in "${NVME_DRIVES[@]}"; do
            size=$(lsblk -ndo SIZE /dev/$drive)
            model=$(lsblk -ndo MODEL /dev/$drive 2>/dev/null || echo "Unknown")
            echo "  • /dev/$drive - $size - $model"
        done
        echo ""
    fi
    
    # Detect SATA/HDD drives
    SATA_DRIVES=($(lsblk -ndo NAME | grep -E "^sd[a-z]$"))
    if [ ${#SATA_DRIVES[@]} -gt 0 ]; then
        echo -e "${BLUE}💾 SATA/HDD ДИСКОВЕ (за backup):${NC}"
        for drive in "${SATA_DRIVES[@]}"; do
            size=$(lsblk -ndo SIZE /dev/$drive)
            model=$(lsblk -ndo MODEL /dev/$drive 2>/dev/null || echo "Unknown")
            echo "  • /dev/$drive - $size - $model"
        done
        echo ""
    fi
    
    # Auto-suggest drives
    if [ ${#NVME_DRIVES[@]} -ge 2 ]; then
        SUGGESTED_DRIVE1="/dev/${NVME_DRIVES[0]}"
        SUGGESTED_DRIVE2="/dev/${NVME_DRIVES[1]}"
        echo -e "${GREEN}💡 ПРЕПОРЪЧАНИ ЗА RAID1:${NC}"
        echo "  Диск 1: $SUGGESTED_DRIVE1"
        echo "  Диск 2: $SUGGESTED_DRIVE2"
        echo ""
    fi
    
    if [ ${#SATA_DRIVES[@]} -ge 1 ]; then
        SUGGESTED_BACKUP="/dev/${SATA_DRIVES[0]}"
        echo -e "${BLUE}💡 ПРЕПОРЪЧАН ЗА BACKUP:${NC}"
        echo "  Backup: $SUGGESTED_BACKUP"
        echo ""
    fi
}

# Interactive drive selection
select_drives() {
    detect_drives
    
    echo -e "${CYAN}🔧 ИЗБОР НА ДИСКОВЕ:${NC}"
    echo ""
    
    # RAID drives selection
    if [ -n "$SUGGESTED_DRIVE1" ] && [ -n "$SUGGESTED_DRIVE2" ]; then
        read -p "Първи NVMe диск [$SUGGESTED_DRIVE1]: " DRIVE1
        DRIVE1=${DRIVE1:-$SUGGESTED_DRIVE1}
        
        read -p "Втори NVMe диск [$SUGGESTED_DRIVE2]: " DRIVE2
        DRIVE2=${DRIVE2:-$SUGGESTED_DRIVE2}
    else
        echo "Въведете ръчно NVMe дисковете:"
        read -p "Първи NVMe диск (напр. /dev/nvme0n1): " DRIVE1
        read -p "Втори NVMe диск (напр. /dev/nvme1n1): " DRIVE2
    fi
    
    # Backup drive selection
    if [ -n "$SUGGESTED_BACKUP" ]; then
        read -p "Backup диск [$SUGGESTED_BACKUP]: " BACKUP_DRIVE
        BACKUP_DRIVE=${BACKUP_DRIVE:-$SUGGESTED_BACKUP}
    else
        read -p "Backup диск (напр. /dev/sda): " BACKUP_DRIVE
    fi
    
    # Validate selections
    for drive in "$DRIVE1" "$DRIVE2" "$BACKUP_DRIVE"; do
        if [ ! -b "$drive" ]; then
            error "Диск $drive не съществува!"
            return 1
        fi
    done
    
    if [ "$DRIVE1" = "$DRIVE2" ]; then
        error "RAID дисковете не могат да бъдат еднакви!"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ ИЗБРАНИ ДИСКОВЕ:${NC}"
    echo "  RAID1: $DRIVE1 + $DRIVE2"
    echo "  Backup: $BACKUP_DRIVE"
    echo ""
}

# Main menu
show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                  ${CYAN}SERVERSET v$SCRIPT_VERSION${NC} - All-in-One              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}              ${YELLOW}Ubuntu Server Management Tool${NC}                ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$INSTALLED" = "true" ]; then
        echo -e "${GREEN}✅ Системата е инсталирана и готова${NC}"
        echo -e "${BLUE}📅 Инсталирана на: $INSTALL_DATE${NC}"
        if [ -n "$DRIVE1" ] && [ -n "$DRIVE2" ]; then
            echo -e "${BLUE}💿 RAID1: $DRIVE1 + $DRIVE2${NC}"
        fi
        if [ -n "$BACKUP_DRIVE" ]; then
            echo -e "${BLUE}💾 Backup: $BACKUP_DRIVE${NC}"
        fi
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
    echo "  16) Само Cockpit инсталация"
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
    echo "  12) Автоматично възстановяване"
    echo "  13) Управление на backups"
    echo "  14) Бързо възстановяване"
    echo "  15) Проверка на backup space"
    echo ""
    
    echo -e "${CYAN}🔒 СИГУРНОСТ И SSL:${NC}"
    echo "  19) SSL сертификат настройка"
    echo "  20) Firewall управление"
    echo "  21) Fail2ban статус"
    echo "  22) Security audit"
    echo ""
    
    echo -e "${RED}  0)  Изход${NC}"
    echo ""
    echo -n "Изберете опция (0-23): "
}

# Full installation with automatic drive detection
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
    
    # Drive selection
    if ! select_drives; then
        error "Грешка при избора на дискове!"
        read -p "Enter за продължаване..."
        return
    fi
    
    # Get additional configuration
    echo -e "${CYAN}📧 ДОПЪЛНИТЕЛНА НАСТРОЙКА:${NC}"
    read -p "Email за известия (optional): " ADMIN_EMAIL
    read -p "Домейн (optional): " DOMAIN
    echo ""
    
    warn "ВНИМАНИЕ: Всички данни на посочените дискове ще бъдат изтрити!"
    echo "Дискове за форматиране:"
    echo "  • $DRIVE1 (RAID1)"
    echo "  • $DRIVE2 (RAID1)"
    echo "  • $BACKUP_DRIVE (Backup)"
    echo ""
    read -p "Продължаване? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Операцията е отказана."
        return
    fi
    
    # Start installation
    log "Започване на пълната инсталация..."
    
    # Step 1: System Update
    log "Стъпка 1/11: Актуализиране на системата..."
    apt update && apt upgrade -y
    
    # Step 2: Install packages
    log "Стъпка 2/11: Инсталиране на пакети..."
    apt install -y curl wget git htop nano vim unzip software-properties-common \
        apt-transport-https ca-certificates gnupg lsb-release mdadm rsync cron \
        smartmontools hdparm mailutils postfix ufw fail2ban bc pv
    
    # Step 3: Configure locale
    log "Стъпка 3/11: Настройка на български език..."
    locale-gen bg_BG.UTF-8
    update-locale LANG=bg_BG.UTF-8
    timedatectl set-timezone Europe/Sofia
    
    # Step 4: Install Docker
    log "Стъпка 4/11: Инсталиране на Docker..."
    install_docker
    
    # Step 5: Setup RAID1
    log "Стъпка 5/11: Настройка на RAID1..."
    setup_raid
    
    # Step 6: Setup backup
    log "Стъпка 6/11: Настройка на backup..."
    setup_backup
    
    # Step 7: Security
    log "Стъпка 7/11: Засилване на сигурността..."
    setup_security
    
    # Step 8: Install Coolify
    log "Стъпка 8/11: Инсталиране на Coolify..."
    install_coolify
    
    # Step 9: Install Cockpit
    log "Стъпка 9/11: Инсталиране на Cockpit..."
    install_cockpit
    
    # Step 10: Create scripts
    log "Стъпка 10/11: Създаване на скриптове..."
    create_all_scripts
    
    # Step 11: Final setup
    log "Стъпка 11/11: Финални настройки..."
    setup_cron_jobs
    create_aliases
    
    # Mark as installed
    INSTALLED="true"
    save_config
    
    show_success_message
}

# Install Docker
install_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
}

# Setup RAID1
setup_raid() {
    if ! select_drives; then
        return 1
    fi
    
    log "Създаване на RAID1 масив..."
    
    # Stop any existing RAID
    mdadm --stop /dev/md0 2>/dev/null || true
    
    # Clear superblocks
    mdadm --zero-superblock "$DRIVE1" 2>/dev/null || true
    mdadm --zero-superblock "$DRIVE2" 2>/dev/null || true
    
    # Create RAID1 array
    mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 "$DRIVE1" "$DRIVE2" --assume-clean
    
    # Wait a moment for the array to initialize
    sleep 5
    
    # Create filesystem
    mkfs.ext4 /dev/md0
    
    # Create mount point and mount
    mkdir -p /data
    mount /dev/md0 /data
    
    # Add to fstab
    echo "/dev/md0 /data ext4 defaults 0 2" >> /etc/fstab
    
    # Save RAID configuration
    mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    update-initramfs -u
    
    log "RAID1 настроен успешно!"
}

# Setup backup system
setup_backup() {
    if [ -z "$BACKUP_DRIVE" ]; then
        if ! select_drives; then
            return 1
        fi
    fi
    
    log "Настройка на backup диска..."
    
    # Format backup drive
    mkfs.ext4 "$BACKUP_DRIVE"
    
    # Create mount point and mount
    mkdir -p /mnt/backup
    mount "$BACKUP_DRIVE" /mnt/backup
    
    # Add to fstab
    echo "$BACKUP_DRIVE /mnt/backup ext4 defaults 0 2" >> /etc/fstab
    
    # Create backup directories
    mkdir -p /mnt/backup/{system,data,logs,recovery-docs}
    
    log "Backup система настроена успешно!"
}

# Setup security
setup_security() {
    log "Настройка на firewall..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 8000/tcp  # Coolify
    ufw allow 9090/tcp  # Cockpit
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

# Install Coolify
install_coolify() {
    log "Изтегляне и инсталиране на Coolify..."
    
    # Ensure /data exists and is mounted
    if ! mountpoint -q /data; then
        error "RAID диска не е монтиран! Настройте RAID първо."
        return 1
    fi
    
    # Install Coolify
    curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
    
    log "Coolify инсталиран успешно!"
}

# Create all management scripts
create_all_scripts() {
    # System Backup Script
    cat > "$SCRIPT_DIR/system-backup.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/system-backup.log"
BACKUP_DIR="/mnt/backup/system/full_$(date +%Y%m%d_%H%M%S)"

log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_backup "Започване на системно backup..."
mkdir -p "$BACKUP_DIR"

# Create backup info
cat > "$BACKUP_DIR/backup-info.txt" << EOL
Backup Date: $(date)
Hostname: $(hostname)
RAID Device: /dev/md0
System Size: $(df -h /data | tail -1 | awk '{print $2}')
Used Space: $(df -h /data | tail -1 | awk '{print $3}')
EOL

# Backup system image with progress
log_backup "Създаване на системен образ..."
if command -v pv >/dev/null; then
    dd if=/dev/md0 bs=64K | pv | gzip > "$BACKUP_DIR/system-image.gz"
else
    dd if=/dev/md0 bs=64K status=progress | gzip > "$BACKUP_DIR/system-image.gz"
fi

# Backup configs
log_backup "Backup на конфигурации..."
tar -czf "$BACKUP_DIR/configs.tar.gz" /etc/ /data/coolify/ 2>/dev/null || true

# Backup RAID config
mdadm --detail --scan > "$BACKUP_DIR/mdadm-scan.conf"

# Cleanup old backups (keep last 3)
log_backup "Изчистване на стари backups..."
ls -t /mnt/backup/system/full_* | tail -n +4 | xargs -r rm -rf

log_backup "Backup завърши успешно!"
EOF

    # Health Check Script
    cat > "$SCRIPT_DIR/health-check.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/health-check.log"

log_health() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_health "Започване на health check..."

# Check RAID
if ! grep -q "md0.*active.*raid1" /proc/mdstat; then
    log_health "КРИТИЧНО: RAID проблем!"
    echo "RAID проблем на $(hostname) - $(date)" | mail -s "RAID Alert" root 2>/dev/null || true
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

# Check Docker
if ! systemctl is-active --quiet docker; then
    log_health "КРИТИЧНО: Docker не работи!"
    systemctl start docker
fi

log_health "Health check завърши."
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
echo ""

echo "💾 ПОСЛЕДНО BACKUP:"
if [ -d "/mnt/backup/system" ]; then
    LAST_BACKUP=$(ls -t /mnt/backup/system/full_* 2>/dev/null | head -1)
    if [ -n "$LAST_BACKUP" ]; then
        echo "   📅 $(basename "$LAST_BACKUP" | cut -d'_' -f2-3 | tr '_' ' ')"
    else
        echo "   ❌ Няма backup-и"
    fi
fi
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
    echo "Налични дискове:"
    lsblk -o NAME,SIZE,TYPE,MODEL | grep -E "NAME|nvme|sd"
    echo ""
    
    read -p "Неизправен диск (напр. /dev/nvme0n1): " FAILED_DISK
    read -p "Нов диск (напр. /dev/nvme2n1): " NEW_DISK
    
    if [ ! -b "$FAILED_DISK" ] || [ ! -b "$NEW_DISK" ]; then
        echo "ГРЕШКА: Невалидни дискове!"
        return 1
    fi
    
    echo "ВНИМАНИЕ: Това ще премахне $FAILED_DISK и добави $NEW_DISK"
    read -p "Продължаване? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        mdadm --manage /dev/md0 --remove "$FAILED_DISK"
        mdadm --manage /dev/md0 --add "$NEW_DISK"
        echo "Rebuild започна. Проверете: watch cat /proc/mdstat"
    fi
}

case "$1" in
    status) show_status ;;
    replace) replace_disk ;;
    *) echo "Употреба: $0 {status|replace}" ;;
esac
EOF

    # Emergency Restore Script
    cat > "$SCRIPT_DIR/emergency-restore.sh" << 'EOF'
#!/bin/bash
echo "=== БЪРЗО ВЪЗСТАНОВЯВАНЕ ==="
echo ""

if [ ! -d "/mnt/backup/system" ]; then
    echo "ГРЕШКА: Backup директорията не е достъпна!"
    echo "Монтирайте backup диска първо."
    exit 1
fi

echo "Налични backups:"
ls -la /mnt/backup/system/full_* 2>/dev/null | while read line; do
    backup_name=$(echo "$line" | awk '{print $9}')
    if [ -d "$backup_name" ]; then
        backup_date=$(basename "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
        if [ -f "$backup_name/system-image.gz" ]; then
            image_size=$(du -sh "$backup_name/system-image.gz" | cut -f1)
            echo "  📁 $backup_date - $image_size"
        fi
    fi
done

echo ""
read -p "Backup дата (YYYYMMDD_HHMMSS): " BACKUP_DATE

BACKUP_PATH="/mnt/backup/system/full_$BACKUP_DATE"
if [ ! -d "$BACKUP_PATH" ] || [ ! -f "$BACKUP_PATH/system-image.gz" ]; then
    echo "ГРЕШКА: Backup не съществува или е повреден!"
    exit 1
fi

echo ""
echo "ВНИМАНИЕ: Това ще презапише /dev/md0!"
echo "Backup: $BACKUP_PATH"
read -p "Потвърждение (YES): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Операцията е отказана."
    exit 1
fi

echo "Спиране на услуги..."
systemctl stop docker 2>/dev/null || true

echo "Възстановяване в ход..."
if command -v pv >/dev/null; then
    gunzip -c "$BACKUP_PATH/system-image.gz" | pv | dd of=/dev/md0 bs=64K oflag=direct
else
    gunzip -c "$BACKUP_PATH/system-image.gz" | dd of=/dev/md0 bs=64K status=progress
fi

sync
echo ""
echo "✅ Възстановяването завърши! Рестартирайте: sudo reboot"
EOF

    # Backup Space Manager
    cat > "$SCRIPT_DIR/backup-space-manager.sh" << 'EOF'
#!/bin/bash

show_space() {
    echo "=== BACKUP SPACE АНАЛИЗ ==="
    echo ""
    df -h /mnt/backup
    echo ""
    echo "BACKUP ФАЙЛОВЕ:"
    du -sh /mnt/backup/system/full_* 2>/dev/null | sort -hr
    echo ""
    echo "ОБЩО:"
    du -sh /mnt/backup/system/ 2>/dev/null
}

cleanup_old() {
    echo "=== ИЗЧИСТВАНЕ НА СТАРИ BACKUPS ==="
    echo ""
    echo "Текущи backups:"
    ls -t /mnt/backup/system/full_* 2>/dev/null | head -5
    echo ""
    read -p "Запази последните N backups [3]: " KEEP
    KEEP=${KEEP:-3}
    
    echo "Изчистване на backups по-стари от последните $KEEP..."
    ls -t /mnt/backup/system/full_* 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -rf
    echo "Готово!"
}

case "$1" in
    space) show_space ;;
    cleanup) cleanup_old ;;
    *) 
        echo "Употреба: $0 {space|cleanup}"
        echo ""
        show_space
        ;;
esac
EOF

    chmod +x "$SCRIPT_DIR"/*.sh
}

# Setup cron jobs
setup_cron_jobs() {
    # Remove old cron jobs
    crontab -l 2>/dev/null | grep -v "system-backup.sh\|health-check.sh" | crontab -
    
    # Add new cron jobs
    (crontab -l 2>/dev/null; echo "0 15 * * 6 $SCRIPT_DIR/system-backup.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 2 * * * $SCRIPT_DIR/health-check.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 4 1 * * $SCRIPT_DIR/backup-space-manager.sh cleanup") | crontab -
}

# Install Cockpit
install_cockpit() {
    log "Инсталиране на Cockpit Web Console..."
    
    # Install Cockpit and plugins
    apt install -y cockpit cockpit-machines cockpit-podman cockpit-storaged \
        cockpit-networkmanager cockpit-packagekit cockpit-sosreport \
        cockpit-system cockpit-tests cockpit-ws cockpit-bridge
    
    # Enable and start Cockpit
    systemctl enable --now cockpit.socket
    
    # Configure firewall for Cockpit
    ufw allow 9090/tcp
    
    log "Cockpit инсталиран успешно! Достъп: https://$(hostname -I | awk '{print $1}'):9090"
}

# Create aliases
create_aliases() {
    cat >> /root/.bashrc << 'EOF'

# ServerSet aliases
alias dashboard='server-dashboard.sh'
alias raidstatus='raid-manager.sh status'
alias backup='system-backup.sh'
alias serverset='/usr/local/bin/serverset.sh'
alias drives='lsblk -o NAME,SIZE,TYPE,MODEL,MOUNTPOINT'
alias space='backup-space-manager.sh space'
EOF
}

# Show dashboard
show_dashboard() {
    $SCRIPT_DIR/server-dashboard.sh
    echo ""
    read -p "Натиснете Enter за връщане в менюто..."
}

# RAID status and management
show_raid_status() {
    clear
    echo -e "${CYAN}🔄 RAID СТАТУС И УПРАВЛЕНИЕ${NC}"
    echo ""
    
    if [ ! -f /proc/mdstat ]; then
        error "RAID не е настроен!"
        read -p "Enter за продължаване..."
        return
    fi
    
    echo "1) Показване на RAID статус"
    echo "2) Замяна на неизправен диск"
    echo "3) Детайлна RAID информация"
    echo "4) RAID rebuild статус"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1) 
            $SCRIPT_DIR/raid-manager.sh status
            read -p "Enter за продължаване..." 
            ;;
        2) 
            $SCRIPT_DIR/raid-manager.sh replace
            read -p "Enter за продължаване..." 
            ;;
        3) 
            mdadm --detail /dev/md0
            read -p "Enter за продължаване..." 
            ;;
        4)
            echo "RAID Rebuild статус:"
            watch -n 2 'cat /proc/mdstat'
            ;;
        0) return ;;
    esac
}

# System information
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
    echo "   Всички дискове:"
    lsblk -o NAME,SIZE,TYPE,MODEL,MOUNTPOINT | grep -E "NAME|nvme|sd|md"
    echo ""
    
    if [ -f /proc/mdstat ]; then
        echo "   RAID статус:"
        grep -A 2 "md0" /proc/mdstat || echo "   Няма RAID"
        echo ""
    fi
    
    echo "🌐 МРЕЖА:"
    echo "   IP: $(hostname -I | awk '{print $1}')"
    echo "   Gateway: $(ip route | grep default | awk '{print $3}')"
    echo ""
    
    echo "🔧 УСЛУГИ:"
    for service in docker ssh cron ufw fail2ban; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo "   ✅ $service"
        else
            echo "   ❌ $service"
        fi
    done
    echo ""
    
    read -p "Натиснете Enter за връщане..."
}

# Verify setup
verify_setup() {
    clear
    echo -e "${CYAN}🔍 ПРОВЕРКА НА НАСТРОЙКАТА${NC}"
    echo ""
    
    ERRORS=0
    
    # Check RAID
    if [ -f /proc/mdstat ] && grep -q "md0.*active.*raid1" /proc/mdstat; then
        echo "✅ RAID1 работи"
    else
        echo "❌ RAID проблем"
        ((ERRORS++))
    fi
    
    # Check mounts
    if mountpoint -q /data 2>/dev/null; then
        echo "✅ RAID диск монтиран (/data)"
    else
        echo "❌ RAID диск не е монтиран"
        ((ERRORS++))
    fi
    
    if mountpoint -q /mnt/backup 2>/dev/null; then
        echo "✅ Backup диск монтиран (/mnt/backup)"
    else
        echo "❌ Backup диск не е монтиран"
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
        echo "⚠️  Coolify не отговаря (може да стартира)"
    fi
     # Check Cockpit
    if systemctl is-active --quiet cockpit; then
        echo "✅ Cockpit работи"
    else
        echo "⚠️  Cockpit не отговаря"
    fi
    # Check scripts
    for script in system-backup.sh health-check.sh raid-manager.sh server-dashboard.sh; do
        if [ -x "$SCRIPT_DIR/$script" ]; then
            echo "✅ $script"
        else
            echo "❌ $script липсва"
            ((ERRORS++))
        fi
    done
    
    # Check cron
    if crontab -l 2>/dev/null | grep -q system-backup.sh; then
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

# Manual backup
manual_backup() {
    clear
    echo -e "${CYAN}💾 РЪЧНО BACKUP${NC}"
    echo ""
    
    if [ ! -f "$SCRIPT_DIR/system-backup.sh" ]; then
        error "Backup скриптът не е намерен!"
        read -p "Enter за продължаване..."
        return
    fi
    
    if ! mountpoint -q /mnt/backup; then
        error "Backup диска не е монтиран!"
        read -p "Enter за продължаване..."
        return
    fi
    
    # Show current space
    echo "ТЕКУЩО BACKUP ПРОСТРАНСТВО:"
    df -h /mnt/backup
    echo ""
    
    log "Стартиране на ръчно backup..."
    $SCRIPT_DIR/system-backup.sh
    
    echo ""
    log "Backup завърши! Проверете /mnt/backup/system/"
    read -p "Натиснете Enter за връщане..."
}

# Automated recovery
automated_recovery() {
    clear
    echo -e "${RED}🔄 АВТОМАТИЧНО ВЪЗСТАНОВЯВАНЕ${NC}"
    echo ""
    
    warn "ВНИМАНИЕ: Това ще презапише цялата система!"
    echo ""
    
    # Check if backup drive is mounted
    if ! mountpoint -q /mnt/backup; then
        echo "Backup диска не е монтиран. Опитвам се да го монтирам..."
        
        # Try to detect and mount backup drive
        for drive in /dev/sd[a-z]; do
            if [ -b "$drive" ]; then
                echo "Опитвам $drive..."
                mkdir -p /mnt/backup
                if mount "$drive" /mnt/backup 2>/dev/null; then
                    log "Backup диска е монтиран от $drive"
                    break
                fi
            fi
        done
        
        if ! mountpoint -q /mnt/backup; then
            error "Не мога да намеря backup диска!"
            read -p "Enter за продължаване..."
            return
        fi
    fi
    
    # Show available backups
    echo "НАЛИЧНИ BACKUPS:"
    if [ -d "/mnt/backup/system" ]; then
        ls -la /mnt/backup/system/full_* 2>/dev/null | while read line; do
            backup_name=$(echo "$line" | awk '{print $9}')
            if [ -d "$backup_name" ]; then
                backup_date=$(basename "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
                if [ -f "$backup_name/system-image.gz" ]; then
                    image_size=$(du -sh "$backup_name/system-image.gz" | cut -f1)
                    echo "  📁 $backup_date - $image_size"
                fi
            fi
        done
    else
        error "Няма backup директория!"
        read -p "Enter за продължаване..."
        return
    fi
    
    echo ""
    read -p "Продължаване с възстановяването? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        $SCRIPT_DIR/emergency-restore.sh
    fi
    
    read -p "Натиснете Enter за връщане..."
}

# Backup management
backup_management() {
    clear
    echo -e "${CYAN}💾 УПРАВЛЕНИЕ НА BACKUPS${NC}"
    echo ""
    
    if ! mountpoint -q /mnt/backup; then
        error "Backup диска не е монтиран!"
        read -p "Enter за продължаване..."
        return
    fi
    
    echo "1) Показване на всички backups"
    echo "2) Изчистване на стари backups"
    echo "3) Проверка на backup space"
    echo "4) Тест на backup целост"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1)
            echo ""
            echo "ВСИЧКИ BACKUPS:"
            ls -lah /mnt/backup/system/ 2>/dev/null || echo "Няма backups"
            ;;
        2)
            $SCRIPT_DIR/backup-space-manager.sh cleanup
            ;;
        3)
            $SCRIPT_DIR/backup-space-manager.sh space
            ;;
        4)
            echo ""
            echo "ТЕСТ НА BACKUP ЦЕЛОСТ:"
            for backup in /mnt/backup/system/full_*/system-image.gz; do
                if [ -f "$backup" ]; then
                    backup_name=$(basename "$(dirname "$backup")")
                    echo -n "Проверка на $backup_name... "
                    if gzip -t "$backup" 2>/dev/null; then
                        echo -e "${GREEN}✅${NC}"
                    else
                        echo -e "${RED}❌ ПОВРЕДЕН!${NC}"
                    fi
                fi
            done
            ;;
        0) return ;;
    esac
    
    read -p "Enter за продължаване..."
}

# Quick restore
quick_restore() {
    clear
    echo -e "${RED}⚡ БЪРЗО ВЪЗСТАНОВЯВАНЕ${NC}"
    echo ""
    
    warn "Бързо възстановяване от последния backup"
    read -p "Продължаване? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        # Find latest backup
        LATEST_BACKUP=$(ls -t /mnt/backup/system/full_* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            BACKUP_DATE=$(basename "$LATEST_BACKUP" | cut -d'_' -f2-3)
            echo "$BACKUP_DATE" | $SCRIPT_DIR/emergency-restore.sh
        else
            error "Няма налични backups!"
        fi
    fi
    
    read -p "Натиснете Enter за връщане..."
}

# SSL setup
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

# Firewall management
firewall_management() {
    clear
    echo -e "${CYAN}🔥 FIREWALL УПРАВЛЕНИЕ${NC}"
    echo ""
    
    echo "ТЕКУЩ СТАТУС:"
    ufw status verbose
    echo ""
    
    echo "1) Показване на правила"
    echo "2) Добавяне на правило"
    echo "3) Премахване на правило"
    echo "4) Рестартиране на firewall"
    echo "0) Назад"
    echo ""
    read -p "Избор: " choice
    
    case $choice in
        1) ufw status numbered ;;
        2) 
            read -p "Порт/Услуга: " port
            ufw allow "$port"
            ;;
        3)
            ufw status numbered
            read -p "Номер на правило: " rule_num
            ufw delete "$rule_num"
            ;;
        4)
            ufw --force disable
            ufw --force enable
            ;;
        0) return ;;
    esac
    
        read -p "Enter за продължаване..."
}

# Security audit
security_audit() {
    clear
    echo -e "${CYAN}🔒 SECURITY AUDIT${NC}"
    echo ""
    
    log "Започване на security audit..."
    
    echo "🔥 FIREWALL:"
    if systemctl is-active --quiet ufw; then
        echo "   ✅ UFW е активен"
        open_ports=$(ufw status | grep -c "ALLOW")
        echo "   📊 Отворени портове: $open_ports"
    else
        echo "   ❌ UFW не е активен"
    fi
    echo ""
    
    echo "🛡️  FAIL2BAN:"
    if systemctl is-active --quiet fail2ban; then
        echo "   ✅ Fail2ban е активен"
        banned_ips=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" | wc -w)
        echo "   📊 Блокирани IP-та: $((banned_ips - 4))"
    else
        echo "   ❌ Fail2ban не е активен"
    fi
    echo ""
    
    echo "🔐 SSH НАСТРОЙКИ:"
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
        echo "   ✅ Root login забранен"
    else
        echo "   ⚠️  Root login разрешен"
    fi
    
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo "   ✅ Password auth забранен"
    else
        echo "   ⚠️  Password auth разрешен"
    fi
    echo ""
    
    echo "🔄 АКТУАЛИЗАЦИИ:"
    updates=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ $updates -gt 1 ]; then
        echo "   ⚠️  $((updates - 1)) налични актуализации"
    else
        echo "   ✅ Системата е актуална"
    fi
    echo ""
    
    echo "👥 ПОТРЕБИТЕЛИ:"
    echo "   Активни сесии: $(who | wc -l)"
    echo "   Последни входове:"
    last -n 5 | head -5
    
    read -p "Натиснете Enter за връщане..."
}

# Show success message
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
    ║  ✅ Месечно изчистване на backups                           ║
    ║  ✅ Мониторинг и сигурност                                  ║
    ║  ✅ Автоматично възстановяване                              ║
    ║                                                              ║
    ║  🚀 Готов за производство!                                  ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    echo -e "${CYAN}🌐 WEB ДОСТЪП:${NC}"
    echo "    Coolify: http://$(hostname -I | awk '{print $1}'):8000"
    echo "    Cockpit: https://$(hostname -I | awk '{print $1}'):9090"
    echo ""
    echo -e "${CYAN}📋 БЪРЗИ КОМАНДИ:${NC}"
    echo "    dashboard          - Статус на сървъра"
    echo "    serverset          - Това меню"
    echo "    raidstatus         - RAID статус"
    echo "    backup             - Ръчно backup"
    echo "    drives             - Показване на дискове"
    echo "    space              - Backup space статус"
    echo ""
    echo -e "${CYAN}💿 КОНФИГУРИРАНИ ДИСКОВЕ:${NC}"
    echo "    RAID1: $DRIVE1 + $DRIVE2 → /data"
    echo "    Backup: $BACKUP_DRIVE → /mnt/backup"
    echo ""
    echo -e "${CYAN}🔔 СЛЕДВАЩИ СТЪПКИ:${NC}"
    echo "    1. Създайте admin акаунт в Coolify"
    echo "    2. Тествайте backup: backup"
    echo "    3. Настройте домейн и SSL (опция 19)"
    echo "    4. Проверете dashboard"
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
            16) install_cockpit ;;
            6) show_dashboard ;;
            7) show_raid_status ;;
            8) show_system_info ;;
            9) verify_setup ;;
            10) $SCRIPT_DIR/health-check.sh 2>/dev/null || echo "Health check скриптът не е намерен"; read -p "Enter..." ;;
            11) manual_backup ;;
            12) automated_recovery ;;
            13) backup_management ;;
            14) quick_restore ;;
            15) $SCRIPT_DIR/backup-space-manager.sh 2>/dev/null || echo "Space manager не е намерен"; read -p "Enter..." ;;
            19) ssl_setup ;;
            20) firewall_management ;;
            21) 
                echo "FAIL2BAN СТАТУС:"
                fail2ban-client status 2>/dev/null || echo "Fail2ban не е инсталиран"
                read -p "Enter..." 
                ;;
            22) security_audit ;;
            0) 
                echo -e "${GREEN}Благодарим, че използвате ServerSet!${NC}"
                exit 0
                ;;
            *)
                error "Невалиден избор! Моля изберете 0-22."
                sleep 2
                ;;
        esac
    done
}

# Start the application
main "$@"


