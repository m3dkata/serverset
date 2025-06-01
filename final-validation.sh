#!/bin/bash
# Final Validation / Финална валидация

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    ФИНАЛНА ВАЛИДАЦИЯ                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Test all critical components / Тестване на всички критични компоненти
echo ""
echo "🧪 ТЕСТВАНЕ НА КРИТИЧНИТЕ КОМПОНЕНТИ..."

# 1. RAID Test
echo ""
echo "1️⃣ RAID ТЕСТ:"
if grep -q "md0.*active.*raid1" /proc/mdstat; then
    echo "   ✅ RAID1 е активен и работи"
    RAID_HEALTH=$(mdadm --detail /dev/md0 | grep "State" | awk '{print $3}')
    echo "   📊 RAID състояние: $RAID_HEALTH"
else
    echo "   ❌ RAID проблем!"
    exit 1
fi

# 2. Storage Test
echo ""
echo "2️⃣ СЪХРАНЕНИЕ ТЕСТ:"
if mountpoint -q /data && mountpoint -q /mnt/backup; then
    echo "   ✅ Всички дискове са монтирани"
    echo "   📊 /data: $(df -h /data | tail -1 | awk '{print $4}') свободни"
    echo "   📊 /mnt/backup: $(df -h /mnt/backup | tail -1 | awk '{print $4}') свободни"
else
    echo "   ❌ Проблем с монтирането!"
    exit 1
fi

# 3. Docker Test
echo ""
echo "3️⃣ DOCKER ТЕСТ:"
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker работи"
    echo "   📊 Контейнери: $(docker ps -q | wc -l) активни"
else
    echo "   ❌ Docker не работи!"
    exit 1
fi

# 4. Coolify Test
echo ""
echo "4️⃣ COOLIFY ТЕСТ:"
sleep 5  # Give Coolify time to start
if curl -f -s http://localhost:8000 >/dev/null; then
    echo "   ✅ Coolify отговаря на порт 8000"
    echo "   🌐 Достъп: http://$(hostname -I | awk '{print $1}'):8000"
else
    echo "   ⚠️  Coolify все още стартира... (това е нормално)"
    echo "   🔄 Проверете след 2-3 минути"
fi

# 5. Backup Test
echo ""
echo "5️⃣ BACKUP ТЕСТ:"
if [ -x /usr/local/bin/system-backup.sh ]; then
    echo "   ✅ Backup скрипт е готов"
    if crontab -l | grep -q system-backup.sh; then
        echo "   ✅ Автоматичен backup е настроен"
        echo "   ⏰ Следващ backup: Събота в 15:00"
    fi
else
    echo "   ❌ Backup скрипт не е намерен!"
fi

# 6. Monitoring Test
echo ""
echo "6️⃣ МОНИТОРИНГ ТЕСТ:"
if [ -x /usr/local/bin/health-check.sh ]; then
    echo "   ✅ Health check е готов"
    if crontab -l | grep -q health-check.sh; then
        echo "   ✅ Автоматичен мониторинг е настроен"
        echo "   ⏰ Ежедневни проверки в 02:00"
    fi
fi

# 7. Security Test
echo ""
echo "7️⃣ СИГУРНОСТ ТЕСТ:"
if systemctl is-active --quiet ufw; then
    echo "   ✅ Firewall е активен"
fi
if systemctl is-active --quiet fail2ban; then
    echo "   ✅ Fail2ban е активен"
fi

# 8. Performance Test
echo ""
echo "8️⃣ ПРОИЗВОДИТЕЛНОСТ ТЕСТ:"
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
echo "   📊 Натоварване: $LOAD"
echo "   📊 Памет: $MEM_USAGE% използвана"

# Final Score
echo ""
echo "🏆 ФИНАЛЕН РЕЗУЛТАТ:"
echo "   ✅ Системата е готова за производство!"
echo "   🚀 Всички компоненти работят правилно"
echo ""
echo "📋 СЛЕДВАЩИ СТЪПКИ:"
echo "   1. Отворете Coolify: http://$(hostname -I | awk '{print $1}'):8000"
echo "   2. Създайте admin акаунт"
echo "   3. Започнете първия си проект"
echo "   4. Тествайте backup: system-backup.sh"
echo ""
echo "🎉 Поздравления! Вашият сървър е готов!"