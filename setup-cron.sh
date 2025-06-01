#!/bin/bash
# Setup Cron Jobs / Настройка на Cron задачи

log "Настройка на автоматични задачи..."

# Make backup script executable / Правене на backup скрипта изпълним
chmod +x /usr/local/bin/system-backup.sh

# Add cron job for Saturday 15:00 / Добавяне на cron задача за събота 15:00
(crontab -l 2>/dev/null; echo "0 15 * * 6 /usr/local/bin/system-backup.sh") | crontab -

# Add daily health check / Добавяне на ежедневна проверка
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/health-check.sh") | crontab -

log "Cron задачите са настроени:"
log "- Системно backup: всяка събота в 15:00"
log "- Проверка на здравето: всеки ден в 02:00"