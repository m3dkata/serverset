#!/bin/bash
# Create Emergency Contact Card / Създаване на карта за спешни случаи

cat > /mnt/backup/EMERGENCY-CONTACT-CARD.txt << EOF
╔══════════════════════════════════════════════════════════════╗
║                    СПЕШНА ИНФОРМАЦИЯ                        ║
╚══════════════════════════════════════════════════════════════╝

📅 Дата на инсталация: $(date)
🖥️  Сървър IP: $(hostname -I | awk '{print $1}')
🏠 Hostname: $(hostname)

🔑 ВАЖНИ ПАРОЛИ:
   • Root парола: [ЗАПИШЕТЕ ТУКА]
   • Coolify admin: [ЗАПИШЕТЕ ТУКА]
   • Backup encryption: [ЗАПИШЕТЕ ТУКА]

🌐 ДОСТЪП:
   • SSH: ssh $(whoami)@$(hostname -I | awk '{print $1}')
   • Coolify: http://$(hostname -I | awk '{print $1}'):8000
   • Backup location: /mnt/backup/

🔧 СПЕШНИ КОМАНДИ:
   • Статус: dashboard
   • RAID проблем: raid-manager.sh status
   • Backup сега: system-backup.sh
   • Възстановяване: emergency-restore.sh
   • Проверка: verify-setup.sh

💾 ХАРДУЕР:
   • CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)
   • RAM: $(free -h | grep Mem | awk '{print $2}')
   • NVMe дискове: 2x в RAID1
   • Backup диск: $(lsblk | grep sda | awk '{print $4}')

📞 КОНТАКТИ:
   • Системен админ: [ВАШИЯ ТЕЛЕФОН]
   • Email: [ВАШИЯ EMAIL]
   • Техническа поддръжка: [ПОДДРЪЖКА]

🆘 ПРИ АВАРИЯ:
   1. Не паникувайте!
   2. Проверете RAID: cat /proc/mdstat
   3. Проверете backups: ls /mnt/backup/system/
   4. Свържете се с техническата поддръжка
   5. Документирайте проблема

📚 ДОКУМЕНТАЦИЯ:
   • Recovery guide: /mnt/backup/recovery-docs/
   • Troubleshooting: troubleshooting-guide.sh
   • Hardware info: /mnt/backup/recovery-docs/hardware-inventory.txt

⚠️  ВАЖНО: Запазете това на сигурно място!
EOF

echo "Спешната карта е създадена: /mnt/backup/EMERGENCY-CONTACT-CARD.txt"
echo "Моля попълнете паролите и контактите!"