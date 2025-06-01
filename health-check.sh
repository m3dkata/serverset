#!/bin/bash
# System Health Check / Проверка на здравето на системата

LOG_FILE="/var/log/health-check.log"

log_health() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_health "Започване на проверка на здравето..."

# Check RAID status / Проверка на RAID статуса
log_health "Проверка на RAID статус..."
if ! cat /proc/mdstat | grep -q "raid1"; then
    log_health "ГРЕШКА: RAID1 не е активен!"
    echo "RAID1 проблем на $(date)" | mail -s "RAID Alert" root 2>/dev/null || true
fi

# Check disk space / Проверка на дисковото пространство
log_health "Проверка на дисковото пространство..."
df -h | while read line; do
    usage=$(echo $line | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 85 ]]; then
        log_health "ПРЕДУПРЕЖДЕНИЕ: Диск $line е $usage% пълен"
    fi
done

# Check Docker status / Проверка на Docker статуса
log_health "Проверка на Docker..."
if ! systemctl is-active --quiet docker; then
    log_health "ГРЕШКА: Docker не работи!"
    systemctl start docker
fi

# Check Coolify status / Проверка на Coolify статуса
log_health "Проверка на Coolify..."
if ! curl -f http://localhost:8000 >/dev/null 2>&1; then
    log_health "ПРЕДУПРЕЖДЕНИЕ: Coolify може да не работи правилно"
fi

log_health "Проверката на здравето завърши."