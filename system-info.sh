#!/bin/bash
# Detailed System Information / Подробна системна информация

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   СИСТЕМНА ИНФОРМАЦИЯ                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Hardware Info / Хардуерна информация
echo ""
echo "🖥️  ХАРДУЕР:"
echo "   CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "   Cores: $(nproc) cores"
echo "   RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "   Architecture: $(uname -m)"

# Storage Info / Информация за съхранение
echo ""
echo "💾 СЪХРАНЕНИЕ:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -E "NAME|nvme|sd|md"

# RAID Detailed Status / Подробен RAID статус
echo ""
echo "🔄 RAID ПОДРОБНОСТИ:"
if [ -f /proc/mdstat ]; then
    cat /proc/mdstat
    echo ""
    if [ -e /dev/md0 ]; then
        mdadm --detail /dev/md0 | grep -E "State|Active Devices|Working Devices|Failed Devices"
    fi
else
    echo "   RAID не е конфигуриран"
fi

# Network Info / Мрежова информация
echo ""
echo "🌐 МРЕЖА:"
ip route | grep default | awk '{print "   Gateway: " $3 " via " $5}'
echo "   IP адреси:"
ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "     " $2}'

# Service Status / Статус на услугите
echo ""
echo "🔧 УСЛУГИ:"
services=("docker" "nginx" "ssh" "cron")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "   ✅ $service"
    else
        echo "   ❌ $service"
    fi
done

# Docker Containers / Docker контейнери
echo ""
echo "🐳 DOCKER КОНТЕЙНЕРИ:"
if systemctl is-active --quiet docker; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
else
    echo "   Docker не работи"
fi

# Disk Usage Details / Подробности за използването на дискове
echo ""
echo "📊 ИЗПОЛЗВАНЕ НА ДИСКОВЕ:"
df -h | grep -E "Filesystem|/dev/md|/mnt|/data"

# Last Backup Info / Информация за последното backup
echo ""
echo "💾 BACKUP ИНФОРМАЦИЯ:"
if [ -d "/mnt/backup/system" ]; then
    echo "   Последно backup: $(ls -t /mnt/backup/system/ | head -1)"
    echo "   Общо backups: $(ls /mnt/backup/system/ | wc -l)"
    echo "   Backup размер: $(du -sh /mnt/backup/system/ | awk '{print $1}')"
else
    echo "   Backup директорията не съществува"
fi

# System Load / Системно натоварване
echo ""
echo "⚡ ПРОИЗВОДИТЕЛНОСТ:"
echo "   Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "   CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "   Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"

# Temperature (if available) / Температура (ако е налична)
echo ""
echo "🌡️  ТЕМПЕРАТУРА:"
if command -v sensors >/dev/null 2>&1; then
    sensors | grep -E "Core|temp" | head -5
else
    echo "   sensors не е инсталиран"
fi