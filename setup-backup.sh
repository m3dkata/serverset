#!/bin/bash
# Backup System Setup / Настройка на система за резервни копия

log "Настройка на система за резервни копия..."

# Prepare backup drive / Подготовка на backup диска
log "Подготовка на backup диска..."
mkfs.ext4 $BACKUP_DRIVE
mkdir -p /mnt/backup
mount $BACKUP_DRIVE /mnt/backup

# Add backup drive to fstab / Добавяне на backup диска към fstab
echo "$BACKUP_DRIVE /mnt/backup ext4 defaults 0 2" >> /etc/fstab

# Create backup directories / Създаване на директории за backup
mkdir -p /mnt/backup/{system,data,logs}

log "Backup диск настроен успешно!"