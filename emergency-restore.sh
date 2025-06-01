#!/bin/bash
# Quick Emergency Restore (simplified version)

echo "=== БЪРЗО АВАРИЙНО ВЪЗСТАНОВЯВАНЕ ==="
echo ""
echo "За пълно автоматично възстановяване използвайте:"
echo "  automated-recovery.sh"
echo ""
echo "Този скрипт е за бързо възстановяване на работеща система."
echo ""

# Check if backup drive is mounted
if [ ! -d "/mnt/backup/system" ]; then
    echo "ГРЕШКА: Backup диск не е монтиран!"
    echo "Монтирайте го първо: mount /dev/sdX /mnt/backup"
    exit 1
fi

echo "Налични backups:"
ls -la /mnt/backup/system/full_* | while read line; do
    backup_name=$(echo "$line" | awk '{print $9}')
    backup_date=$(basename "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
    if [ -f "$backup_name/system-image.gz" ]; then
        image_size=$(du -h "$backup_name/system-image.gz" | cut -f1)
        echo "  📁 $backup_date - $image_size"
    fi
done

echo ""
read -p "Backup дата (YYYYMMDD_HHMMSS): " BACKUP_DATE

BACKUP_PATH="/mnt/backup/system/full_$BACKUP_DATE"
if [ ! -d "$BACKUP_PATH" ]; then
    echo "ГРЕШКА: Backup не съществува!"
    exit 1
fi

if [ ! -f "$BACKUP_PATH/system-image.gz" ]; then
    echo "ГРЕШКА: System image не съществува!"
    exit 1
fi

echo ""
echo "ВНИМАНИЕ: Това ще презапише /dev/md0!"
read -p "Потвърждение (YES): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
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
echo "Възстановяването завърши! Рестартирайте: sudo reboot"
