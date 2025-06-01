#!/bin/bash
# Setup Verification / Проверка на настройката

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ПРОВЕРКА НА НАСТРОЙКАТА                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"

ERRORS=0

check_service() {
    if systemctl is-active --quiet $1; then
        echo "✅ $1 работи"
    else
        echo "❌ $1 НЕ работи"
        ((ERRORS++))
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1 съществува"
    else
        echo "❌ $1 НЕ съществува"
        ((ERRORS++))
    fi
}

check_mount() {
    if mountpoint -q "$1"; then
        echo "✅ $1 е монтиран"
    else
        echo "❌ $1 НЕ е монтиран"
        ((ERRORS++))
    fi
}

echo ""
echo "🔧 ПРОВЕРКА НА УСЛУГИТЕ:"
check_service "docker"
check_service "ssh"
check_service "cron"

echo ""
echo "💾 ПРОВЕРКА НА МОНТИРАНЕТО:"
check_mount "/data"
check_mount "/mnt/backup"

echo ""
echo "🔄 ПРОВЕРКА НА RAID:"
if [ -e /dev/md0 ]; then
    echo "✅ RAID устройство съществува"
    if grep -q "md0.*active" /proc/mdstat; then
        echo "✅ RAID е активен"
    else
        echo "❌ RAID НЕ е активен"
        ((ERRORS++))
    fi
else
    echo "❌ RAID устройство НЕ съществува"
    ((ERRORS++))
fi

echo ""
echo "📝 ПРОВЕРКА НА СКРИПТОВЕТЕ:"
scripts=(
    "/usr/local/bin/system-backup.sh"
    "/usr/local/bin/health-check.sh"
    "/usr/local/bin/raid-manager.sh"
    "/usr/local/bin/server-dashboard.sh"
)

for script in "${scripts[@]}"; do
    check_file "$script"
done

echo ""
echo "⏰ ПРОВЕРКА НА CRON ЗАДАЧИТЕ:"
if crontab -l | grep -q "system-backup.sh"; then
    echo "✅ Backup cron задача настроена"
else
    echo "❌ Backup cron задача НЕ е настроена"
    ((ERRORS++))
fi

if crontab -l | grep -q "health-check.sh"; then
    echo "✅ Health check cron задача настроена"
else
    echo "❌ Health check cron задача НЕ е настроена"
    ((ERRORS++))
fi

echo ""
echo "🚀 ПРОВЕРКА НА COOLIFY:"
if curl -f http://localhost:8000 >/dev/null 2>&1; then
    echo "✅ Coolify отговаря на порт 8000"
else
    echo "❌ Coolify НЕ отговаря"
    ((ERRORS++))
fi

echo ""
echo "🐳 ПРОВЕРКА НА DOCKER:"
if docker info >/dev/null 2>&1; then
    echo "✅ Docker работи правилно"
    echo "   Контейнери: $(docker ps -q | wc -l) работещи"
else
    echo "❌ Docker има проблеми"
    ((ERRORS++))
fi

echo ""
echo "📊 РЕЗУЛТАТ:"
if [ $ERRORS -eq 0 ]; then
    echo "🎉 Всички проверки преминаха успешно!"
    echo "   Системата е готова за използване."
else
    echo "⚠️  Намерени са $ERRORS проблема."
    echo "   Моля прегледайте грешките по-горе."
fi

echo ""
echo "📋 СЛЕДВАЩИ СТЪПКИ:"
echo "1. Отворете Coolify: http://$(hostname -I | awk '{print $1}'):8000"
echo "2. Създайте първия си проект"
echo "3. Настройте домейн и SSL (ако е необходимо)"
echo "4. Тествайте backup системата"
