#!/bin/bash
# Server Dashboard / Сървърно табло

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    СЪРВЪРНО ТАБЛО                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# System Info / Системна информация
echo "🖥️  СИСТЕМА:"
echo "   Време: $(date)"
echo "   Uptime: $(uptime -p)"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Memory Info / Информация за паметта
echo "💾 ПАМЕТ:"
free -h | grep -E "Mem|Swap"
echo ""

# Disk Usage / Използване на дискове
echo "💿 ДИСКОВЕ:"
df -h | grep -E "Filesystem|/dev/md0|/mnt"
echo ""

# RAID Status / RAID статус
echo "🔄 RAID СТАТУС:"
if [ -f /proc/mdstat ]; then
    grep -A 3 "md0" /proc/mdstat || echo "   RAID не е намерен"
else
    echo "   RAID не е конфигуриран"
fi
echo ""

# Docker Status / Docker статус
echo "🐳 DOCKER:"
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker работи"
    echo "   Контейнери: $(docker ps --format 'table {{.Names}}\t{{.Status}}' | tail -n +2 | wc -l) активни"
else
    echo "   ❌ Docker не работи"
fi
echo ""

# Coolify Status / Coolify статус
echo "🌐 WEB INTERFACES:"
if curl -f http://localhost:8000 >/dev/null 2>&1; then
    echo "   ✅ Coolify работи - http://$(hostname -I | awk '{print $1}'):8000"
else
    echo "   ❌ Coolify не отговаря"
fi

if systemctl is-active --quiet cockpit; then
    echo "   ✅ Cockpit работи - https://$(hostname -I | awk '{print $1}'):9090"
else
    echo "   ❌ Cockpit не отговаря"
fi
echo ""

# Last Backup / Последно backup
echo "💾 ПОСЛЕДНО BACKUP:"
if [ -d "/mnt/backup/system" ]; then
    LAST_BACKUP=$(ls -t /mnt/backup/system/ | head -1)
    if [ -n "$LAST_BACKUP" ]; then
        echo "   📅 $LAST_BACKUP"
    else
        echo "   ❌ Няма backup-и"
    fi
else
    echo "   ❌ Backup директорията не съществува"
fi
echo ""

# Network / Мрежа
echo "🌐 МРЕЖА:"
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -3
echo ""

echo "Използвайте следните команди:"
echo "  raid-manager.sh status  - RAID статус"
echo "  system-backup.sh        - Ръчно backup"
echo "  server-dashboard.sh     - Това табло"