#!/bin/bash

show_space() {
    echo "=== BACKUP SPACE АНАЛИЗ ==="
    echo ""
    df -h /mnt/backup
    echo ""
    echo "BACKUP ФАЙЛОВЕ:"
    du -sh /mnt/backup/system/full_* 2>/dev/null | sort -hr
    echo ""
    echo "ОБЩО:"
    du -sh /mnt/backup/system/ 2>/dev/null
}

cleanup_old() {
    echo "=== ИЗЧИСТВАНЕ НА СТАРИ BACKUPS ==="
    echo ""
    echo "Текущи backups:"
    ls -t /mnt/backup/system/full_* 2>/dev/null | head -5
    echo ""
    read -p "Запази последните N backups [3]: " KEEP
    KEEP=${KEEP:-3}
    
    echo "Изчистване на backups по-стари от последните $KEEP..."
    ls -t /mnt/backup/system/full_* 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -rf
    echo "Готово!"
}

case "$1" in
    space) show_space ;;
    cleanup) cleanup_old ;;
    *) 
        echo "Употреба: $0 {space|cleanup}"
        echo ""
        show_space
        ;;
esac