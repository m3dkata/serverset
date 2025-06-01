#!/bin/bash
# Coolify Setup Guide / Ръководство за настройка на Coolify

cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                ПЪРВОНАЧАЛНА НАСТРОЙКА НА COOLIFY            ║
╚══════════════════════════════════════════════════════════════╝

🚀 СТЪПКА 1: Първи достъп
   1. Отворете: http://YOUR_SERVER_IP:8000
   2. Създайте admin акаунт
   3. Влезте в системата

🔧 СТЪПКА 2: Основна настройка
   1. Settings → General → Server Settings
   2. Настройте Server Name
   3. Настройте Default Domain (ако имате)

🌐 СТЪПКА 3: Настройка на домейн (опционално)
   1. Settings → Domains
   2. Добавете вашия домейн
   3. Настройте DNS записи:
      A record: your-domain.com → YOUR_SERVER_IP
      CNAME: *.your-domain.com → your-domain.com

🔒 СТЪПКА 4: SSL сертификати
   1. Settings → SSL
   2. Enable Let's Encrypt
   3. Или използвайте: setup-ssl.sh

📦 СТЪПКА 5: Първо приложение
   1. Projects → New Project
   2. Изберете тип приложение:
      • Git Repository (GitHub/GitLab)
      • Docker Image
      • Docker Compose

🔍 СТЪПКА 6: Мониторинг
   1. Dashboard → Resources
   2. Проверете CPU/Memory usage
   3. Настройте alerts

💾 СТЪПКА 7: Backup настройки
   1. Settings → Backup
   2. Настройте S3 или local backup
   3. Тествайте backup процеса

🛡️  СТЪПКА 8: Сигурност
   1. Settings → Security
   2. Enable 2FA
   3. Настройте IP whitelist (ако е нужно)

📧 СТЪПКА 9: Известия
   1. Settings → Notifications
   2. Настройте email/Slack/Discord
   3. Тествайте известията

🔄 СТЪПКА 10: Автоматизация
   1. Settings → Webhooks
   2. Настройте auto-deploy от Git
   3. Настройте health checks

ПОЛЕЗНИ ВРЪЗКИ:
📖 Документация: https://coolify.io/docs
💬 Discord: https://discord.gg/coolify
🐛 GitHub: https://github.com/coollabsio/coolify

ПРИМЕРНИ ПРИЛОЖЕНИЯ ЗА ТЕСТВАНЕ:
• Static Website: https://github.com/username/static-site
• Node.js App: https://github.com/username/node-app
• WordPress: Docker image wordpress:latest
• Database: PostgreSQL, MySQL, Redis
EOF