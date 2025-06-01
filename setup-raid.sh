#!/bin/bash
# RAID1 Setup Script / Скрипт за настройка на RAID1

# WARNING: This will destroy data on the drives!
# ВНИМАНИЕ: Това ще унищожи данните на дисковете!

log "Настройка на RAID1..."

# List available drives / Показване на налични дискове
log "Налични дискове:"
lsblk

warn "ВНИМАНИЕ: Моля въведете правилните устройства за вашите NVMe дискове"
read -p "Въведете първия NVMe диск (напр. /dev/nvme0n1): " DRIVE1
read -p "Въведете втория NVMe диск (напр. /dev/nvme1n1): " DRIVE2
read -p "Въведете HDD за backup (напр. /dev/sda): " BACKUP_DRIVE

# Create RAID1 array / Създаване на RAID1 масив
log "Създаване на RAID1 масив..."
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 $DRIVE1 $DRIVE2

# Wait for sync to complete / Изчакване за завършване на синхронизацията
log "Изчакване за синхронизация на RAID масива..."
while [ $(cat /proc/mdstat | grep -c "resync") -gt 0 ]; do
    echo "Синхронизация в ход..."
    sleep 10
done

# Create filesystem / Създаване на файлова система
log "Създаване на файлова система..."
mkfs.ext4 /dev/md0

# Create mount point and mount / Създаване на mount точка и монтиране
mkdir -p /mnt/raid1
mount /dev/md0 /mnt/raid1

# Add to fstab / Добавяне към fstab
echo "/dev/md0 /mnt/raid1 ext4 defaults 0 2" >> /etc/fstab

# Save RAID configuration / Запазване на RAID конфигурацията
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

log "RAID1 настроен успешно!"