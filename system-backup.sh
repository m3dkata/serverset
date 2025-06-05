#!/bin/bash
# Bootable, space-efficient backup using fsarchiver with auto-mount/unmount for ransomware protection

set -e

BACKUP_DISK="/dev/sda"         # <--- CHANGE THIS if your backup disk is different!
BACKUP_MOUNT="/mnt/backup"
LOG_FILE="/var/log/system-backup.log"
BACKUP_BASE="$BACKUP_MOUNT/system"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_BASE/full_${DATE}.fsa"

log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mount_backup_disk() {
    if mountpoint -q "$BACKUP_MOUNT"; then
        log_backup "Backup дискът вече е монтиран."
    else
        log_backup "Монтиране на backup диск ($BACKUP_DISK)..."
        mkdir -p "$BACKUP_MOUNT"
        mount "$BACKUP_DISK" "$BACKUP_MOUNT"
        log_backup "Backup дискът е монтиран."
    fi
}

unmount_backup_disk() {
    if mountpoint -q "$BACKUP_MOUNT"; then
        log_backup "Демонтиране на backup диск..."
        umount "$BACKUP_MOUNT"
        log_backup "Backup дискът е демонтиран."
    else
        log_backup "Backup дискът вече е демонтиран."
    fi
}

setup_cron_job() {
    echo "=== Настройка на автоматичен backup (cron) ==="
    echo "1) Всеки ден"
    echo "2) Всяка седмица (изберете ден)"
    echo "3) Изход"
    read -p "Избор (1/2/3): " PERIOD

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
        echo "Изход."
        exit 0
    fi

    TMP_CRON=$(mktemp)
    crontab -l 2>/dev/null | grep -v 'system-backup.sh' > "$TMP_CRON" || true
    echo "$CRON_EXPR $(readlink -f "$0")" >> "$TMP_CRON"
    crontab "$TMP_CRON"
    rm "$TMP_CRON"
    echo "✅ Автоматичният backup е настроен: $DESC"
}

show_menu() {
    echo "=== Системен Backup Меню ==="
    echo "1) Стартирай backup сега"
    echo "2) Настрой/редактирай автоматичен backup (cron)"
    echo "3) Изход"
    read -p "Избор (1/2/3): " CHOICE
    case "$CHOICE" in
        1) run_backup ;;
        2) setup_cron_job ;;
        3) exit 0 ;;
        *) echo "Невалиден избор!"; exit 1 ;;
    esac
}

run_backup() {
    log_backup "== Започване на fsarchiver backup =="

    # Mount backup disk
    mount_backup_disk

    trap 'unmount_backup_disk' EXIT

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

    # Run fsarchiver with detailed output
    log_backup "Стартиране на fsarchiver savefs (детайлен режим)..."
    fsarchiver savefs -v -A "$BACKUP_FILE" /dev/md0

    log_backup "== Backup завърши успешно: $BACKUP_FILE =="

    # Cleanup old backups (keep last 2 full backups)
    log_backup "Изчистване на стари backups (запазване на последните 2)..."
    ls -t "$BACKUP_BASE"/full_*.fsa 2>/dev/null | tail -n +3 | xargs -r rm -f

    log_backup "Backup скриптът приключи."
}

if [[ -t 0 ]]; then
    show_menu
else
    run_backup
fi
