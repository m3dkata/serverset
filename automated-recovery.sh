#!/bin/bash
# Automated Disaster Recovery Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Check if running from live USB
check_environment() {
    if [ ! -d "/mnt/backup" ]; then
        error "Backup диск не е монтиран!"
        echo "Моля монтирайте backup диска първо:"
        echo "mkdir -p /mnt/backup"
        echo "mount /dev/sdX /mnt/backup"
        exit 1
    fi
    
    if [ ! -d "/mnt/backup/system" ]; then
        error "Backup директорията не съществува!"
        exit 1
    fi
}

# List available backups
list_backups() {
    echo -e "${CYAN}📋 НАЛИЧНИ BACKUPS:${NC}"
    echo ""
    
    echo "ПЪЛНИ BACKUPS:"
    ls -la /mnt/backup/system/full_* 2>/dev/null | while read line; do
        backup_name=$(echo "$line" | awk '{print $9}')
        backup_date=$(basename "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
        backup_size=$(echo "$line" | awk '{print $5}')
        
        if [ -f "$backup_name/system-image.gz" ]; then
            image_size=$(du -h "$backup_name/system-image.gz" | cut -f1)
            echo "  ✅ $backup_date - Образ: $image_size"
        fi
    done
    
    echo ""
    echo "ИНКРЕМЕНТАЛНИ BACKUPS:"
    ls -la /mnt/backup/system/incr_* 2>/dev/null | while read line; do
        backup_name=$(echo "$line" | awk '{print $9}')
        backup_date=$(basename "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
        echo "  📁 $backup_date - Инкрементален"
    done
    
    echo ""
}

# Detect drives
detect_drives() {
    echo -e "${CYAN}🔍 ОТКРИВАНЕ НА ДИСКОВЕ:${NC}"
    echo ""
    
    lsblk -o NAME,SIZE,TYPE,MODEL | grep -E "nvme|ssd"
    echo ""
    
    NVME_DRIVES=($(lsblk -ndo NAME | grep nvme))
    
    if [ ${#NVME_DRIVES[@]} -lt 2 ]; then
        warn "Намерени са по-малко от 2 NVMe диска!"
        echo "Налични дискове: ${NVME_DRIVES[@]}"
    fi
    
    echo "Намерени NVMe дискове: ${NVME_DRIVES[@]}"
}

# Setup RAID or single disk
setup_storage() {
    echo -e "${CYAN}💾 НАСТРОЙКА НА СЪХРАНЕНИЕ:${NC}"
    echo ""
    echo "1) Създаване на нов RAID1 (препоръчително)"
    echo "2) Възстановяване на един диск"
    echo "3) Възстановяване на съществуващ RAID"
    echo ""
    read -p "Избор (1-3): " storage_choice
    
    case $storage_choice in
        1)
            setup_new_raid
            TARGET_DEVICE="/dev/md0"
            ;;
        2)
            setup_single_disk
            ;;
        3)
            setup_existing_raid
            TARGET_DEVICE="/dev/md0"
            ;;
        *)
            error "Невалиден избор!"
            exit 1
            ;;
    esac
}

# Create new RAID1
setup_new_raid() {
    echo ""
    echo "Налични дискове:"
    lsblk -o NAME,SIZE,TYPE,MODEL
    echo ""
    
    read -p "Първи NVMe диск (напр. nvme0n1): " DRIVE1
    read -p "Втори NVMe диск (напр. nvme1n1): " DRIVE2
    
    DRIVE1="/dev/$DRIVE1"
    DRIVE2="/dev/$DRIVE2"
    
    warn "ВНИМАНИЕ: Всички данни на $DRIVE1 и $DRIVE2 ще бъдат изтрити!"
    read -p "Продължаване? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
    
    log "Създаване на RAID1..."
    
    # Stop any existing RAID
    mdadm --stop /dev/md0 2>/dev/null || true
    
    # Clear superblocks
    mdadm --zero-superblock "$DRIVE1" 2>/dev/null || true
    mdadm --zero-superblock "$DRIVE2" 2>/dev/null || true
    
    # Create new RAID
    mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 "$DRIVE1" "$DRIVE2" --assume-clean
    
    log "RAID1 създаден успешно!"
}

# Setup single disk
setup_single_disk() {
    echo ""
    echo "Налични дискове:"
    lsblk -o NAME,SIZE,TYPE,MODEL
    echo ""
    
    read -p "Избор на диск (напр. nvme0n1): " DISK
    TARGET_DEVICE="/dev/$DISK"
    
    warn "ВНИМАНИЕ: Всички данни на $TARGET_DEVICE ще бъдат изтрити!"
    read -p "Продължаване? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
    
    log "Ще се използва $TARGET_DEVICE"
}

# Setup existing RAID
setup_existing_raid() {
    log "Проверка за съществуващ RAID..."
    
    if mdadm --detail /dev/md0 >/dev/null 2>&1; then
        log "Намерен съществуващ RAID:"
        mdadm --detail /dev/md0
        
        read -p "Използване на съществуващия RAID? (yes/no): " use_existing
        if [ "$use_existing" != "yes" ]; then
            setup_new_raid
        fi
    else
        warn "Няма съществуващ RAID! Създаване на нов..."
        setup_new_raid
    fi
}

# Select backup to restore
select_backup() {
    echo -e "${CYAN}📋 ИЗБОР НА BACKUP:${NC}"
    echo ""
    
    # List full backups with numbers
    FULL_BACKUPS=($(ls -t /mnt/backup/system/full_* 2>/dev/null))
    
    if [ ${#FULL_BACKUPS[@]} -eq 0 ]; then
        error "Няма налични пълни backups!"
        exit 1
    fi
    
    echo "НАЛИЧНИ ПЪЛНИ BACKUPS:"
    for i in "${!FULL_BACKUPS[@]}"; do
        backup_path="${FULL_BACKUPS[$i]}"
        backup_name=$(basename "$backup_path")
        backup_date=$(echo "$backup_name" | cut -d'_' -f2-3 | tr '_' ' ')
        
        if [ -f "$backup_path/system-image.gz" ]; then
            image_size=$(du -h "$backup_path/system-image.gz" | cut -f1)
            echo "  $((i+1))) $backup_date - Размер: $image_size"
        fi
    done
    
    echo ""
    read -p "Избор на backup (1-${#FULL_BACKUPS[@]}): " backup_choice
    
    if [[ "$backup_choice" -lt 1 || "$backup_choice" -gt ${#FULL_BACKUPS[@]} ]]; then
        error "Невалиден избор!"
        exit 1
    fi
    
    SELECTED_BACKUP="${FULL_BACKUPS[$((backup_choice-1))]}"
    BACKUP_IMAGE="$SELECTED_BACKUP/system-image.gz"
    
    if [ ! -f "$BACKUP_IMAGE" ]; then
        error "Backup образът не съществува: $BACKUP_IMAGE"
        exit 1
    fi
    
    log "Избран backup: $(basename "$SELECTED_BACKUP")"
}

# Verify backup integrity
verify_backup() {
    echo -e "${CYAN}🔍 ПРОВЕРКА НА BACKUP:${NC}"
    echo ""
    
    log "Проверка на целостта на backup..."
    
    # Check if backup image exists and is not empty
    if [ ! -s "$BACKUP_IMAGE" ]; then
        error "Backup образът е празен или не съществува!"
        exit 1
    fi
    
    # Test gzip integrity
    if ! gzip -t "$BACKUP_IMAGE"; then
        error "Backup образът е повреден!"
        exit 1
    fi
    
    # Show backup info
    if [ -f "$SELECTED_BACKUP/restore-info.txt" ]; then
        echo "ИНФОРМАЦИЯ ЗА BACKUP:"
        cat "$SELECTED_BACKUP/restore-info.txt"
        echo ""
    fi
    
    # Calculate sizes
    BACKUP_SIZE=$(du -h "$BACKUP_IMAGE" | cut -f1)
    TARGET_SIZE=$(lsblk -bno SIZE "$TARGET_DEVICE" | head -1)
    TARGET_SIZE_GB=$((TARGET_SIZE / 1024 / 1024 / 1024))
    
    log "Backup размер: $BACKUP_SIZE"
    log "Целеви диск: $TARGET_SIZE_GB GB"
    
    echo ""
    warn "ПОСЛЕДНО ПРЕДУПРЕЖДЕНИЕ!"
    warn "Това ще презапише напълно $TARGET_DEVICE"
    warn "Всички данни ще бъдат загубени!"
    echo ""
    
    read -p "Потвърждение за възстановяване (YES): " final_confirm
    
    if [ "$final_confirm" != "YES" ]; then
        log "Възстановяването е отказано"
        exit 0
    fi
}

# Perform the restore
perform_restore() {
    echo -e "${CYAN}🔄 ВЪЗСТАНОВЯВАНЕ НА СИСТЕМАТА:${NC}"
    echo ""
    
    log "Започване на възстановяването..."
    log "Източник: $BACKUP_IMAGE"
    log "Цел: $TARGET_DEVICE"
    
    # Stop any services that might interfere
    systemctl stop docker 2>/dev/null || true
    
    # Unmount target if mounted
    umount "$TARGET_DEVICE"* 2>/dev/null || true
    
    # Start restore with progress
    log "Възстановяване в ход... (това може да отнеме време)"
    
    if gunzip -c "$BACKUP_IMAGE" | pv | dd of="$TARGET_DEVICE" bs=64K oflag=direct; then
        log "Възстановяването завърши успешно!"
    else
        error "Възстановяването неуспешно!"
        exit 1
    fi
    
    # Sync to ensure all data is written
    sync
    
    log "Синхронизиране на данните..."
    sleep 3
}

# Post-restore configuration
post_restore_config() {
    echo -e "${CYAN}⚙️ ФИНАЛНА НАСТРОЙКА:${NC}"
    echo ""
    
    # If we restored to a new RAID, update RAID config
    if [ "$TARGET_DEVICE" = "/dev/md0" ]; then
        log "Актуализиране на RAID конфигурацията..."
        
        # Mount the restored system temporarily
        mkdir -p /mnt/restored
        mount "$TARGET_DEVICE" /mnt/restored
        
        # Update RAID config in the restored system
        if [ -f "$SELECTED_BACKUP/mdadm-scan.conf" ]; then
            cp "$SELECTED_BACKUP/mdadm-scan.conf" /mnt/restored/etc/mdadm/mdadm.conf
        fi
        
        # Update initramfs
        chroot /mnt/restored update-initramfs -u
        
        umount /mnt/restored
        rmdir /mnt/restored
    fi
    
    log "Финалната настройка завърши!"
}

# Verification after restore
verify_restore() {
    echo -e "${CYAN}✅ ПРОВЕРКА СЛЕД ВЪЗСТАНОВЯВАНЕ:${NC}"
    echo ""
    
    # Mount and check basic structure
    mkdir -p /mnt/check
    mount "$TARGET_DEVICE" /mnt/check
    
    log "Проверка на възстановената система..."
    
    # Check critical directories
    CRITICAL_DIRS=("/mnt/check/boot" "/mnt/check/etc" "/mnt/check/usr" "/mnt/check/var")
    
    for dir in "${CRITICAL_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "  ✅ $(basename "$dir")"
        else
            echo "  ❌ $(basename "$dir") - ЛИПСВА!"
        fi
    done
    
    # Check if GRUB is present
    if [ -d "/mnt/check/boot/grub" ]; then
        echo "  ✅ GRUB bootloader"
    else
        echo "  ❌ GRUB bootloader - ЛИПСВА!"
    fi
    
    # Check ServerSet scripts
    if [ -f "/mnt/check/usr/local/bin/serverset.sh" ]; then
        echo "  ✅ ServerSet скриптове"
    else
        echo "  ⚠️  ServerSet скриптове - може да липсват"
    fi
    
    umount /mnt/check
    rmdir /mnt/check
    
    echo ""
    log "Проверката завърши!"
}

# Show completion message
show_completion() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║           🎉 ВЪЗСТАНОВЯВАНЕТО ЗАВЪРШИ УСПЕШНО! 🎉           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    echo -e "${GREEN}✅ Системата е възстановена успешно!${NC}"
    echo ""
    echo -e "${CYAN}📋 СЛЕДВАЩИ СТЪПКИ:${NC}"
    echo "  1. Премахнете Live USB"
    echo "  2. Рестартирайте системата"
    echo "  3. Системата ще стартира нормално"
    echo "  4. Всички данни и настройки са запазени"
    echo ""
    echo -e "${CYAN}🔧 СЛЕД РЕСТАРТИРАНЕ:${NC}"
    echo "  • Проверете: serverset → опция 9 (Проверка на настройката)"
    echo "  • Стартирайте: dashboard"
    echo "  • Тествайте Coolify: http://YOUR_IP:8000"
    echo ""
    echo -e "${YELLOW}💡 СЪВЕТ:${NC} Направете нов backup след като потвърдите, че всичко работи!"
    echo ""
    
    read -p "Рестартиране сега? (yes/no): " reboot_now
    
    if [ "$reboot_now" = "yes" ]; then
        log "Рестартиране..."
        reboot
    else
        log "Готово! Рестартирайте ръчно когато сте готови."
    fi
}

# Main recovery process
main() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              АВТОМАТИЧНО ВЪЗСТАНОВЯВАНЕ                     ║
║                                                              ║
║                   ServerSet Recovery                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

    echo ""
    warn "ВНИМАНИЕ: Този скрипт ще презапише дискове!"
    warn "Уверете се, че имате правилните backups!"
    echo ""
    
    read -p "Продължаване? (yes/no): " start_recovery
    
    if [ "$start_recovery" != "yes" ]; then
        log "Възстановяването е отказано"
        exit 0
    fi
    
    # Step-by-step recovery
    log "Стъпка 1/8: Проверка на средата..."
    check_environment
    
    log "Стъпка 2/8: Показване на backups..."
    list_backups
    
    log "Стъпка 3/8: Откриване на дискове..."
    detect_drives
    
    log "Стъпка 4/8: Настройка на съхранение..."
    setup_storage
    
    log "Стъпка 5/8: Избор на backup..."
    select_backup
    
    log "Стъпка 6/8: Проверка на backup..."
    verify_backup
    
    log "Стъпка 7/8: Възстановяване..."
    perform_restore
    
    log "Стъпка 8/8: Финална настройка..."
    post_restore_config
    verify_restore
    
    show_completion
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "Този скрипт трябва да се изпълни като root"
    exit 1
fi

# Install required tools if missing
if ! command -v pv >/dev/null; then
    log "Инсталиране на pv за progress bar..."
    apt update && apt install -y pv
fi

# Start recovery
main "$@"

