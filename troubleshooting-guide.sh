#!/bin/bash
# Troubleshooting Guide / Ръководство за отстраняване на проблеми

cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              ОТСТРАНЯВАНЕ НА ПРОБЛЕМИ                       ║
╚══════════════════════════════════════════════════════════════╝

🔧 ПРОБЛЕМ: Coolify не се зарежда
   РЕШЕНИЕ:
   1. Проверете Docker: systemctl status docker
   2. Рестартирайте Coolify: cd /data/coolify && docker compose restart
   3. Проверете логовете: cd /data/coolify && docker compose logs -f
   4. Проверете порта: ss -tulpn | grep 8000

🔄 ПРОБЛЕМ: RAID показва "degraded"
   РЕШЕНИЕ:
   1. Проверете статуса: cat /proc/mdstat
   2. Идентифицирайте неизправния диск: mdadm --detail /dev/md0
   3. Заменете диска: raid-manager.sh replace
   4. Изчакайте rebuild: watch cat /proc/mdstat

💾 ПРОБЛЕМ: Backup не работи
   РЕШЕНИЕ:
   1. Проверете backup диска: df -h /mnt/backup
   2. Проверете cron: crontab -l
   3. Тествайте ръчно: system-backup.sh
   4. Проверете логовете: tail -f /var/log/system-backup.log

🐳 ПРОБЛЕМ: Docker контейнер не стартира
   РЕШЕНИЕ:
   1. Проверете логовете: docker logs CONTAINER_NAME
   2. Проверете ресурсите: docker stats
   3. Рестартирайте контейнера: docker restart CONTAINER_NAME
   4. Проверете образа: docker images

🌐 ПРОБЛЕМ: Мрежови проблеми
   РЕШЕНИЕ:
   1. Проверете връзката: ping google.com
   2. Проверете DNS: nslookup google.com
   3. Проверете firewall: ufw status
   4. Проверете портовете: ss -tulpn

💿 ПРОБЛЕМ: Дисковото пространство свършва
   РЕШЕНИЕ:
   1. Проверете използването: df -h
   2. Намерете големи файлове: du -sh /* | sort -hr
   3. Изчистете Docker: docker system prune -a
   4. Изчистете логове: journalctl --vacuum-time=7d

🔒 ПРОБЛЕМ: SSH достъп блокиран
   РЕШЕНИЕ:
   1. Проверете fail2ban: fail2ban-client status sshd
   2. Разблокирайте IP: fail2ban-client set sshd unbanip YOUR_IP
   3. Проверете SSH конфигурацията: /etc/ssh/sshd_config
   4. Рестартирайте SSH: systemctl restart ssh

⚡ ПРОБЛЕМ: Бавна производителност
   РЕШЕНИЕ:
   1. Проверете CPU: htop
   2. Проверете I/O: iotop
   3. Проверете мрежата: nethogs
   4. Оптимизирайте: performance-tuning.sh

🔍 ОБЩИ КОМАНДИ ЗА ДИАГНОСТИКА:
   • system-info.sh           - Системна информация
   • verify-setup.sh          - Проверка на настройката
   • dashboard                - Общ статус
   • journalctl -f            - Системни логове
   • dmesg | tail             - Kernel съобщения

📞 КОГАТО НИЩО НЕ ПОМАГА:
   1. Направете backup: system-backup.sh
   2. Документирайте проблема
   3. Проверете /var/log/ за грешки
   4. Рестартирайте системата: sudo reboot
EOF