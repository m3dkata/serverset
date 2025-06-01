#!/bin/bash
# Emergency System Restore / Аварийно възстановяване на системата

echo "=== АВАРИЙНО ВЪЗСТАНОВЯВАНЕ НА СИСТЕМАТА ==="
echo "Този скрипт ще възстанови системата от последното резервно копие"
echo ""

# List available backups / Показване на налични backup-и
echo "Налични резервни копия:"
ls -la /mnt/backup/system/ | grep "^d" | tail -10

echo ""
read -p "Въведете датата на backup-а за възстановяване (YYYYMMDD_HHMMSS): " BACKUP_DATE

BACKUP_PATH="/mnt/backup/system/$BACKUP_DATE"

if [ ! -d "$BACKUP_PATH" ]; then
    echo "ГРЕШКА: Backup-ът $BACKUP_DATE не съществува!"
    exit 1
fi

echo ""
echo "ВНИМАНИЕ: Това ще презапише напълно текущата система!"
echo "Backup път: $BACKUP_PATH"
echo ""
read -p "Сигурни ли сте? Напишете 'YES' за потвърждение: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Операцията е отказана."
    exit 1
fi

echo "Започване на възстановяването..."

# Stop services / Спиране на услугите
echo "Спиране на услугите..."
systemctl stop docker
systemctl stop coolify 2>/dev/null || true

# Restore system image / Възстановяване на системния образ
echo "Възстановяване на системния образ... (това може да отнеме време)"
if [ -f "$BACKUP_PATH/system-image.gz" ]; then
    gunzip -c "$BACKUP_PATH/system-image.gz" | dd of=/dev/md0 bs=64K status=progress
else
    echo "ГРЕШКА: Системният образ не е намерен!"
    exit 1
fi

echo ""
echo "Възстановяването завърши успешно!"
echo "Моля рестартирайте системата: sudo reboot"