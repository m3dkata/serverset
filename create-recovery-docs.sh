#!/bin/bash
# Create Recovery Documentation / Създаване на документация за възстановяване

DOCS_DIR="/mnt/backup/recovery-docs"
mkdir -p "$DOCS_DIR"

cat > "$DOCS_DIR/disaster-recovery-guide.md" << 'EOF'
# Ръководство за Аварийно Възстановяване

## Сценарий 1: Отказ на един NVMe диск

### Симптоми:
- RAID статусът показва "degraded"
- Един от дисковете е маркиран като "failed"

### Стъпки за възстановяване:
1. Проверете RAID статуса:
   ```bash
   cat /proc/mdstat
   mdadm --detail /dev/md0