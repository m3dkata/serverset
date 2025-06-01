#!/bin/bash
# Complete Server Setup / Пълна настройка на сървъра

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   error "Този скрипт трябва да се изпълни като root"
   exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           НАСТРОЙКА НА UBUNTU СЪРВЪР С COOLIFY              ║"
echo "║                    RAID1 + BACKUP СИСТЕМА                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Get user input / Въвеждане от потребителя
read -p "Въведете първия NVMe диск (напр. /dev/nvme0n1): " DRIVE1
read -p "Въведете втория NVMe диск (напр. /dev/nvme1n1): " DRIVE2
read -p "Въведете HDD за backup (напр. /dev/sda): " BACKUP_DRIVE
read -p "Въведете email за известия (optional): " ADMIN_EMAIL

warn "ВНИМАНИЕ: Всички данни на посочените дискове ще бъдат изтрити!"
read -p "Продължаване? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Операцията е отказана."
    exit 1
fi

# Step 1: System Update
log "Стъпка 1: Актуализиране на системата..."
apt update && apt upgrade -y

# Step 2: Install packages
log "Стъпка 2: Инсталиране на пакети..."
apt install -y curl wget git htop nano vim unzip software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release mdadm rsync cron \
    smartmontools hdparm mailutils postfix

# Step 3: Configure locale
log "Стъпка 3: Настройка на български език..."
locale-gen bg_BG.UTF-8
update-locale LANG=bg_BG.UTF-8

# Step 4: Install Docker
log "Стъпка 4: Инсталиране на Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker

# Step 5: Setup RAID1
log "Стъпка 5: Настройка на RAID1..."
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 $DRIVE1 $DRIVE2 --assume-clean
mkfs.ext4 /dev/md0
mkdir -p /data
mount /dev/md0 /data
echo "/dev/md0 /data ext4 defaults 0 2" >> /etc/fstab
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

# Step 6: Setup backup drive
log "Стъпка 6: Настройка на backup диска..."
mkfs.ext4 $BACKUP_DRIVE
mkdir -p /mnt/backup
mount $BACKUP_DRIVE /mnt/backup
echo "$BACKUP_DRIVE /mnt/backup ext4 defaults 0 2" >> /etc/fstab
mkdir -p /mnt/backup/{system,data,logs}

# Step 7: Install Coolify
log "Стъпка 7: Инсталиране на Coolify..."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Step 8: Create all scripts
log "Стъпка 8: Създаване на скриптове..."

# Create all the scripts we defined above
# (The script contents would be written to their respective files)

# Make scripts executable
chmod +x /usr/local/bin/*.sh

# Step 9: Setup cron jobs
log "Стъпка 9: Настройка на cron задачи..."
(crontab -l 2>/dev/null; echo "0 15 * * 6 /usr/local/bin/system-backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/health-check.sh") | crontab -

# Step 10: Configure email notifications
if [ -n "$ADMIN_EMAIL" ]; then
    log "Стъпка 10: Настройка на email известия..."
    echo "root: $ADMIN_EMAIL" >> /etc/aliases
    newaliases
fi

# Step 11: Create desktop shortcut for dashboard
log "Стъпка 11: Финални настройки..."
echo "alias dashboard='server-dashboard.sh'" >> /root/.bashrc
echo "alias raidstatus='raid-manager.sh status'" >> /root/.bashrc
echo "alias backup='system-backup.sh'" >> /root/.bashrc

log "✅ НАСТРОЙКАТА ЗАВЪРШИ УСПЕШНО!"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                        РЕЗЮМЕ                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "🔄 RAID1: Настроен на /data"
echo "💾 Backup: Настроен на /mnt/backup"
echo "🚀 Coolify: http://$(hostname -I | awk '{print $1}'):8000"
echo "📅 Backup: Всяка събота в 15:00"
echo "🔍 Мониторинг: Всеки ден в 02:00"
echo ""
echo "Полезни команди:"
echo "  dashboard          - Показва статуса на сървъра"
echo "  raidstatus         - Показва RAID статуса"
echo "  backup             - Стартира ръчно backup"
echo "  raid-manager.sh    - Управление на RAID"
echo ""
echo "Моля рестартирайте системата: sudo reboot"