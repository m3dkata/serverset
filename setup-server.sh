#!/bin/bash
# Ubuntu Server Setup with RAID1, Coolify, and Automated Backups
# Скрипт за настройка на Ubuntu сървър с RAID1, Coolify и автоматични резервни копия

set -e

# Colors for output / Цветове за изхода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function / Функция за логване
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if running as root / Проверка дали се изпълнява като root
if [[ $EUID -ne 0 ]]; then
   error "Този скрипт трябва да се изпълни като root"
   exit 1
fi

log "Започване на настройката на сървъра..."

# Update system / Актуализиране на системата
log "Актуализиране на системата..."
apt update && apt upgrade -y

# Install essential packages / Инсталиране на основни пакети
log "Инсталиране на необходими пакети..."
apt install -y \
    curl \
    wget \
    git \
    htop \
    nano \
    vim \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    mdadm \
    rsync \
    cron \
    smartmontools \
    hdparm

# Configure locale to Bulgarian / Настройка на български език
log "Настройка на български език..."
locale-gen bg_BG.UTF-8
update-locale LANG=bg_BG.UTF-8

# Install Docker / Инсталиране на Docker
log "Инсталиране на Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker / Стартиране и активиране на Docker
systemctl start docker
systemctl enable docker

# Add user to docker group / Добавяне на потребител към docker групата
usermod -aG docker $SUDO_USER 2>/dev/null || true

log "Docker инсталиран успешно!"