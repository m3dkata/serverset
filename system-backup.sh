#!/bin/bash
# Bootable, space-efficient backup using fsarchiver
# Place this script at /usr/local/bin/system-backup.sh and make it executable

set -e

LOG_FILE="/var/log/system-backup.log"
BACKUP_BASE="/mnt/backup/system"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_BASE/full_${DATE}.fsa"

log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

setup_cron_job() {
    echo "=== Настройка на автоматичен backup (cron) ==="
    echo "Изберете периодичност:"
    echo "  1) Всеки ден"
    echo "  2) Всяка седмица (изберете ден)"
    read -p "Избор (1/2): " PERIOD

    if [[ "$PERIOD" == "1" ]]; then
        read -p "Час (0-23): " HOUR
        read -p "Минута (0-59): " MIN
        CRON_EXPR="$MIN $HOUR * * *"
        DESC="всеки ден в $HOUR:$MIN"
    elif [[ "$PERIOD" == "2" ]]; then
        echo "Изберете ден от седмицата:"
        echo "  0) Неделя"
        echo "  1) Понеделник"
        echo "  2) Вторник"
        echo "  3) Сряда"
        echo "  4) Четвъртък"
        echo "  5) Петък"
        echo "  6) Събота"
        read -p "Ден (0-6): " DOW
        read -p "Час (0-23): " HOUR
        read -p "Минута (0-59): " MIN
        CRON_EXPR="$MIN $HOUR * * $DOW"
        DESC="всяка седмица в $HOUR:$MIN, ден $DOW"
    else
        echo "Невалиден избор."
        return 1
    fi

    # Remove any previous system-backup.sh cron jobs
    crontab -l 2>/dev/null | grep -v 'system-backup.sh' > /tmp/cron.tmp.$$
    echo "$CRON_EXPR /usr/local/bin/system-backup.sh" >> /tmp/cron.tmp.$$
    crontab /tmp/cron.tmp.$$
    rm /tmp/cron.tmp.$$

    echo "✅ Автоматичният backup е настроен: $DESC"
}

if [[ "$1" == "--setup-cron" ]]; then
    setup_cron_job
    exit 0
fi

log_backup "== Започване на fsarchiver backup =="
mkdir -p "$BACKUP_BASE"

# Save RAID and partition info for restore
lsblk -f > "$BACKUP_BASE/lsblk_${DATE}.txt"
blkid > "$BACKUP_BASE/blkid_${DATE}.txt"
mdadm --detail --scan > "$BACKUP_BASE/mdadm-scan_${DATE}.conf"
cp /etc/mdadm/mdadm.conf "$BACKUP_BASE/mdadm_${DATE}.conf" 2>/dev/null || true

# Ensure fsarchiver is installed
if ! command -v fsarchiver >/dev/null 2>&1; then
    log_backup "fsarchiver не е инсталиран. Инсталиране..."
    apt update
    apt install -y fsarchiver
fi

# Run fsarchiver (replace /dev/md0 with your root/RAID device if needed)
log_backup "Стартиране на fsarchiver savefs..."
fsarchiver savefs -A "$BACKUP_FILE" /dev/md0

log_backup "== Backup завърши успешно: $BACKUP_FILE =="

# Cleanup old backups (keep last 2 full backups)
log_backup "Изчистване на стари backups (запазване на последните 2)..."
ls -t "$BACKUP_BASE"/full_*.fsa 2>/dev/null | tail -n +3 | xargs -r rm -f

log_backup "Backup скриптът приключи."
