#!/bin/bash
# System Backup Script / Скрипт за системно резервно копие

BACKUP_DIR="/mnt/backup/system"
LOG_FILE="/var/log/system-backup.log"
DATE=$(date +%Y%m%d_%H%M%S)

# Logging function
log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_backup "Започване на системно резервно копие..."

# Create backup directory for this date
mkdir -p "$BACKUP_DIR/$DATE"

# Backup system files / Резервно копие на системни файлове
log_backup "Резервно копие на системни файлове..."
rsync -avH --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
      --exclude='/tmp/*' --exclude='/mnt/*' --exclude='/media/*' \
      --exclude='/var/cache/*' --exclude='/var/tmp/*' \
      / "$BACKUP_DIR/$DATE/system/" 2>&1 | tee -a $LOG_FILE

# Backup RAID configuration / Резервно копие на RAID конфигурацията
log_backup "Резервно копие на RAID конфигурация..."
cp /etc/mdadm/mdadm.conf "$BACKUP_DIR/$DATE/"
mdadm --detail --scan > "$BACKUP_DIR/$DATE/mdadm-scan.conf"

# Backup Docker data / Резервно копие на Docker данни
log_backup "Резервно копие на Docker данни..."
if [ -d "/var/lib/docker" ]; then
    rsync -av /var/lib/docker/ "$BACKUP_DIR/$DATE/docker/" 2>&1 | tee -a $LOG_FILE
fi

# Backup Coolify data / Резервно копие на Coolify данни
log_backup "Резервно копие на Coolify данни..."
if [ -d "/data/coolify" ]; then
    rsync -av /data/coolify/ "$BACKUP_DIR/$DATE/coolify/" 2>&1 | tee -a $LOG_FILE
fi

# Create system image / Създаване на системен образ
log_backup "Създаване на системен образ..."
dd if=/dev/md0 bs=64K | gzip > "$BACKUP_DIR/$DATE/system-image.gz" 2>&1 | tee -a $LOG_FILE

# Clean old backups (keep last 4 weeks) / Изчистване на стари backup-и
log_backup "Изчистване на стари резервни копия..."
find "$BACKUP_DIR" -type d -name "20*" -mtime +28 -exec rm -rf {} \; 2>/dev/null

# Create restore script / Създаване на скрипт за възстановяване
cat > "$BACKUP_DIR/$DATE/restore.sh" << 'EOF'
#!/bin/bash
# System Restore Script / Скрипт за възстановяване на системата

BACKUP_DATE=$(basename $(dirname $(readlink -f $0)))
BACKUP_DIR="/mnt/backup/system/$BACKUP_DATE"

echo "Възстановяване на система от $BACKUP_DATE"
echo "ВНИМАНИЕ: Това ще презапише текущата система!"
read -p "Продължаване? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Отказано."
    exit 1
fi

# Restore system image
echo "Възстановяване на системен образ..."
gunzip -c "$BACKUP_DIR/system-image.gz" | dd of=/dev/md0 bs=64K

echo "Възстановяването завърши. Рестартирайте системата."
EOF

chmod +x "$BACKUP_DIR/$DATE/restore.sh"

log_backup "Системното резервно копие завърши успешно!"

# Send notification (optional) / Изпращане на известие
if command -v mail &> /dev/null; then
    echo "Системното резервно копие завърши успешно на $(date)" | mail -s "Backup Complete" root
fi