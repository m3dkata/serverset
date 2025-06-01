#!/bin/bash
# Disk Health Monitor / Мониторинг на здравето на дисковете

LOG_FILE="/var/log/disk-health.log"

log_disk() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log_disk "Започване на проверка на дисковете..."

# Check SMART status for all drives / Проверка на SMART статуса
for drive in /dev/nvme0n1 /dev/nvme1n1 /dev/sda; do
    if [ -e "$drive" ]; then
        log_disk "Проверка на $drive..."
        
        # SMART test
        smartctl -H "$drive" | grep -q "PASSED"
        if [ $? -eq 0 ]; then
            log_disk "✅ $drive - SMART тест преминат"
        else
            log_disk "❌ $drive - SMART тест неуспешен!"
            echo "SMART грешка на $drive - $(date)" | mail -s "Disk Health Alert" root 2>/dev/null || true
        fi
        
        # Temperature check / Проверка на температурата
        temp=$(smartctl -A "$drive" | grep -i temperature | awk '{print $10}' | head -1)
        if [ -n "$temp" ] && [ "$temp" -gt 60 ]; then
            log_disk "⚠️  $drive - Висока температура: ${temp}°C"
        fi
    fi
done

# Check RAID rebuild status / Проверка на RAID rebuild статуса
if grep -q "recovery\|resync" /proc/mdstat; then
    progress=$(grep -A 1 "recovery\|resync" /proc/mdstat | grep -o '\[[0-9]*%\]')
    log_disk "🔄 RAID rebuild в ход: $progress"
fi

log_disk "Проверката на дисковете завърши."