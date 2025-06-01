#!/bin/bash
# Weekly Maintenance / Седмична поддръжка

LOG_FILE="/var/log/weekly-maintenance.log"

log_maint() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_maint "Започване на седмична поддръжка..."

# Update system packages / Актуализиране на системни пакети
log_maint "Актуализиране на пакети..."
apt update && apt upgrade -y

# Clean package cache / Изчистване на кеша на пакетите
log_maint "Изчистване на кеш..."
apt autoremove -y
apt autoclean

# Docker cleanup / Изчистване на Docker
log_maint "Изчистване на Docker..."
docker system prune -f
docker volume prune -f

# Check disk space / Проверка на дисковото пространство
log_maint "Проверка на дисковото пространство..."
df -h | grep -E "/data|/mnt/backup" | while read line; do
    usage=$(echo $line | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 80 ]]; then
        log_maint "ПРЕДУПРЕЖДЕНИЕ: $line"
    fi
done

# Rotate logs / Ротация на логове
log_maint "Ротация на логове..."
logrotate /etc/logrotate.conf

# Update Coolify / Актуализиране на Coolify
log_maint "Проверка за Coolify актуализации..."
cd /data/coolify && docker compose pull && docker compose up -d

log_maint "Седмичната поддръжка завърши."