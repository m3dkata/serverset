#!/bin/bash
# Smart System Backup with Rotation
# Keeps: 2 full backups + 4 incremental backups

LOG_FILE="/var/log/system-backup.log"
BACKUP_BASE="/mnt/backup/system"
CONFIG_FILE="/etc/serverset.conf"

# Load configuration
source "$CONFIG_FILE" 2>/dev/null || true

log_backup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Check available space
check_space() {
    AVAILABLE=$(df /mnt/backup | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))
    
    log_backup "Налично пространство: ${AVAILABLE_GB}GB"
    
    if [ $AVAILABLE_GB -lt 100 ]; then
        log_backup "ПРЕДУПРЕЖДЕНИЕ: Малко свободно място!"
        cleanup_old_backups
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log_backup "Изчистване на стари backups..."
    
    # Keep only last 2 full backups
    ls -t "$BACKUP_BASE"/full_* 2>/dev/null | tail -n +3 | xargs -r rm -rf
    
    # Keep only last 4 incremental backups  
    ls -t "$BACKUP_BASE"/incr_* 2>/dev/null | tail -n +5 | xargs -r rm -rf
    
    log_backup "Стари backups изчистени"
}

# Determine backup type
get_backup_type() {
    FULL_COUNT=$(ls -1 "$BACKUP_BASE"/full_* 2>/dev/null | wc -l)
    LAST_FULL=$(ls -t "$BACKUP_BASE"/full_* 2>/dev/null | head -1)
    
    if [ $FULL_COUNT -eq 0 ]; then
        echo "full"
    elif [ $FULL_COUNT -ge 2 ]; then
        echo "incremental"
    else
        # Check if last full backup is older than 2 weeks
        if [ -n "$LAST_FULL" ]; then
            LAST_FULL_DATE=$(basename "$LAST_FULL" | cut -d'_' -f2)
            DAYS_OLD=$(( ($(date +%s) - $(date -d "$LAST_FULL_DATE" +%s)) / 86400 ))
            
            if [ $DAYS_OLD -gt 14 ]; then
                echo "full"
            else
                echo "incremental"
            fi
        else
            echo "full"
        fi
    fi
}

# Full backup
do_full_backup() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_BASE/full_$DATE"
    
    log_backup "Започване на пълно backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Create system image
    log_backup "Създаване на системен образ..."
    dd if=/dev/md0 bs=64K status=progress | gzip > "$BACKUP_DIR/system-image.gz"
    
    # Backup configurations
    log_backup "Backup на конфигурации..."
    mkdir -p "$BACKUP_DIR/configs"
    tar -czf "$BACKUP_DIR/configs/etc.tar.gz" /etc/ 2>/dev/null || true
    tar -czf "$BACKUP_DIR/configs/coolify.tar.gz" /data/coolify/ 2>/dev/null || true
    
    # RAID configuration
    cp /etc/mdadm/mdadm.conf "$BACKUP_DIR/" 2>/dev/null || true
    mdadm --detail --scan > "$BACKUP_DIR/mdadm-scan.conf"
    
    # Create restore info
    cat > "$BACKUP_DIR/restore-info.txt" << EOF
Backup Type: Full System Image
Date: $(date)
RAID Device: /dev/md0
System Size: $(df -h /dev/md0 | tail -1 | awk '{print $2}')
Compressed Size: $(du -h "$BACKUP_DIR/system-image.gz" | cut -f1)
Drives: $DRIVE1, $DRIVE2
EOF
    
    log_backup "Пълното backup завърши: $BACKUP_DIR"
}

# Incremental backup
do_incremental_backup() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$BACKUP_BASE/incr_$DATE"
    LAST_FULL=$(ls -t "$BACKUP_BASE"/full_* 2>/dev/null | head -1)
    
    if [ -z "$LAST_FULL" ]; then
        log_backup "Няма пълно backup! Правя пълно backup..."
        do_full_backup
        return
    fi
    
    log_backup "Започване на инкрементално backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Find changes since last full backup
    REFERENCE_DATE=$(basename "$LAST_FULL" | cut -d'_' -f2-3 | tr '_' ' ')
    
    # Backup only changed files
    log_backup "Backup на променени файлове от $REFERENCE_DATE..."
    
    # System files changed since last full backup
    find /etc /data/coolify /var/lib/docker -newer "$LAST_FULL/restore-info.txt" -type f 2>/dev/null | \
    tar -czf "$BACKUP_DIR/changed-files.tar.gz" -T - 2>/dev/null || true
    
    # Database dumps and important configs
    tar -czf "$BACKUP_DIR/current-configs.tar.gz" /etc/ /data/coolify/ 2>/dev/null || true
    
    # Docker container states
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > "$BACKUP_DIR/docker-containers.txt"
    
    # Create restore info
    cat > "$BACKUP_DIR/restore-info.txt" << EOF
Backup Type: Incremental
Date: $(date)
Reference Full Backup: $(basename "$LAST_FULL")
Changed Files: $(tar -tzf "$BACKUP_DIR/changed-files.tar.gz" 2>/dev/null | wc -l)
EOF
    
    log_backup "Инкременталното backup завърши: $BACKUP_DIR"
}

# Main backup logic
main() {
    log_backup "Започване на автоматично backup..."
    
    # Check space first
    check_space
    
    # Determine backup type
    BACKUP_TYPE=$(get_backup_type)
    log_backup "Тип backup: $BACKUP_TYPE"
    
    # Perform backup
    if [ "$BACKUP_TYPE" = "full" ]; then
        do_full_backup
    else
        do_incremental_backup
    fi
    
    # Cleanup after backup
    cleanup_old_backups
    
    # Final space check
    AVAILABLE=$(df /mnt/backup | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))
    log_backup "Останало пространство: ${AVAILABLE_GB}GB"
    
    log_backup "Backup завърши успешно!"
}

main "$@"
