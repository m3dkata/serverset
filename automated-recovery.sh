#!/bin/bash
# Automated Disaster Recovery Script (fsarchiver-based, user-friendly)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${CYAN}[INFO] $1${NC}"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Този скрипт трябва да се изпълни като root"
        exit 1
    fi
}

install_tools() {
    for pkg in fsarchiver mdadm; do
        if ! command -v $pkg >/dev/null 2>&1; then
            warn "$pkg не е инсталиран. Инсталиране..."
            apt update
            apt install -y $pkg
        fi
    done
}

mount_backup() {
    if [ ! -d "/mnt/backup" ]; then
        mkdir -p /mnt/backup
    fi
    if ! mountpoint -q /mnt/backup; then
        echo "Моля монтирайте backup диска (например: mount /dev/sdX /mnt/backup)"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        read -p "Натиснете Enter след като backup дискът е монтиран..." dummy
    fi
    if [ ! -d "/mnt/backup/system" ]; then
        error "Backup директорията не съществува!"
        exit 1
    fi
}

select_backup() {
    echo -e "${CYAN}📋 НАЛИЧНИ BACKUPS:${NC}"
    mapfile -t BACKUPS < <(ls -t /mnt/backup/system/full_*.fsa 2>/dev/null)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        error "Няма налични fsarchiver backups!"
        exit 1
    fi
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) $(basename "${BACKUPS[$i]}")"
    done
    read -p "Изберете backup за възстановяване (номер): " BNUM
    BACKUP_IMAGE="${BACKUPS[$((BNUM-1))]}"
    if [ ! -f "$BACKUP_IMAGE" ]; then
        error "Backup файлът не съществува!"
        exit 1
    fi
}

setup_raid() {
    echo -e "${CYAN}💾 RAID1 НАСТРОЙКА:${NC}"
    lsblk -o NAME,SIZE,TYPE,MODEL
    read -p "Създаване на нов RAID1? (yes/no): " RAIDCREATE
    if [ "$RAIDCREATE" = "yes" ]; then
        read -p "Първи NVMe диск (например nvme0n1): " D1
        read -p "Втори NVMe диск (например nvme1n1): " D2
        mdadm --stop /dev/md0 2>/dev/null || true
        mdadm --zero-superblock "/dev/$D1" 2>/dev/null || true
        mdadm --zero-superblock "/dev/$D2" 2>/dev/null || true
        mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 "/dev/$D1" "/dev/$D2"
        mkfs.ext4 /dev/md0
        TARGET_DEVICE="/dev/md0"
    else
        read -p "Въведете целевото устройство за възстановяване (например /dev/md0): " TARGET_DEVICE
        mkfs.ext4 "$TARGET_DEVICE"
    fi
}

restore_fsarchiver() {
    log "Възстановяване на backup с fsarchiver..."
    fsarchiver restfs "$BACKUP_IMAGE" id=0,dest="$TARGET_DEVICE"
    log "Възстановяването завърши."
}

expand_fs() {
    log "Разширяване на файловата система (ако е нужно)..."
    resize2fs "$TARGET_DEVICE"
}

mount_and_chroot() {
    log "Монтиране и chroot за финална настройка..."
    mount "$TARGET_DEVICE" /mnt
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys

    # Copy mdadm config if present
    for conf in $(ls /mnt/backup/system/mdadm*.conf 2>/dev/null); do
        cp "$conf" /mnt/etc/mdadm/mdadm.conf
    done

    cat <<EOF
${CYAN}
Влизате в chroot среда за финална настройка:
  - Ще се изпълнят:
      mdadm --detail --scan >> /etc/mdadm/mdadm.conf
      update-initramfs -u
      grub-install /dev/nvme0n1   # или друг boot диск
      update-grub
      exit
${NC}
EOF

    chroot /mnt /bin/bash -c "
        mdadm --detail --scan >> /etc/mdadm/mdadm.conf
        update-initramfs -u
        echo
        echo '===> Въведете устройството за grub-install (например /dev/nvme0n1):'
        read -p 'grub-install device: ' GRUBDEV
        grub-install \$GRUBDEV
        update-grub
        echo 'Готово! Излезте с exit.'
    "
}

cleanup_and_reboot() {
    log "Демонтиране..."
    umount /mnt/dev
    umount /mnt/proc
    umount /mnt/sys
    umount /mnt
    read -p "Рестартиране сега? (yes/no): " REBOOT
    if [ "$REBOOT" = "yes" ]; then
        reboot
    else
        log "Възстановяването е завършено. Можете да рестартирате ръчно."
    fi
}

main() {
    require_root
    install_tools
    mount_backup
    select_backup
    setup_raid
    restore_fsarchiver
    expand_fs
    mount_and_chroot
    cleanup_and_reboot
}

main "$@"
