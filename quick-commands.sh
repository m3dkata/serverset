#!/bin/bash
# Quick Commands Reference / Справка за бързи команди

cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    БЪРЗИ КОМАНДИ                             ║
╚══════════════════════════════════════════════════════════════╝

🖥️  СИСТЕМНИ КОМАНДИ:
   dashboard                    - Показва статуса на сървъра
   system-info.sh              - Подробна системна информация
   verify-setup.sh             - Проверява настройката

🔄 RAID УПРАВЛЕНИЕ:
   raid-manager.sh status      - RAID статус
   raid-manager.sh replace     - Замяна на диск
   cat /proc/mdstat            - Бърз RAID статус

💾 BACKUP ОПЕРАЦИИ:
   system-backup.sh            - Ръчно backup
   emergency-restore.sh        - Аварийно възстановяване
   ls /mnt/backup/system/      - Списък с backups

🐳 DOCKER КОМАНДИ:
   docker ps                   - Работещи контейнери
   docker logs [container]     - Логове на контейнер
   docker system prune -f      - Изчистване на Docker

🚀 COOLIFY:
   cd /data/coolify && docker compose logs -f
   cd /data/coolify && docker compose restart

🔧 ПОДДРЪЖКА:
   weekly-maintenance.sh       - Седмична поддръжка
   performance-monitor.sh      - Проверка на производителността
   disk-health-monitor.sh      - Проверка на дисковете

📊 МОНИТОРИНГ:
   htop                        - Системни процеси
   iotop                       - Disk I/O
   nethogs                     - Мрежов трафик
   watch cat /proc/mdstat      - RAID статус в реално време

🔒 СИГУРНОСТ:
   fail2ban-client status      - Fail2ban статус
   ufw status                  - Firewall статус
   last                        - Последни входове

📝 ЛОГОВЕ:
   tail -f /var/log/system-backup.log
   tail -f /var/log/health-check.log
   tail -f /var/log/performance.log
   journalctl -f               - Системни логове

🌐 МРЕЖА:
   ip addr show                - IP адреси
   ss -tulpn                   - Отворени портове
   ping google.com             - Тест на интернет връзката

EOF