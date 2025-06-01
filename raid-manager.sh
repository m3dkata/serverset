#!/bin/bash
# RAID Management Script / Скрипт за управление на RAID

show_status() {
    echo "=== RAID СТАТУС ==="
    cat /proc/mdstat
    echo ""
    mdadm --detail /dev/md0
}

replace_disk() {
    echo "=== ЗАМЯНА НА ДИСК ==="
    echo "Текущ RAID статус:"
    cat /proc/mdstat
    echo ""
    
    read -p "Въведете неизправния диск (напр. /dev/nvme0n1): " FAILED_DISK
    read -p "Въведете новия диск (напр. /dev/nvme2n1): " NEW_DISK
    
    echo "Премахване на неизправния диск..."
    mdadm --manage /dev/md0 --remove $FAILED_DISK
    
    echo "Добавяне на новия диск..."
    mdadm --manage /dev/md0 --add $NEW_DISK
    
    echo "Започва rebuild процеса. Проверете статуса с: watch cat /proc/mdstat"
}

case "$1" in
    status)
        show_status
        ;;
    replace)
        replace_disk
        ;;
    *)
        echo "Употреба: $0 {status|replace}"
        echo "  status  - показва RAID статуса"
        echo "  replace - замества неизправен диск"
        exit 1
        ;;
esac