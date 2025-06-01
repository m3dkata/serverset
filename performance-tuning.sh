#!/bin/bash
# Performance Tuning / Оптимизация на производителността

log "Оптимизация на производителността..."

# Optimize SSD performance / Оптимизация на SSD производителността
log "Оптимизация на SSD..."
echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-nvme-scheduler.rules
echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"' >> /etc/udev/rules.d/60-nvme-scheduler.rules

# Optimize kernel parameters / Оптимизация на kernel параметри
cat >> /etc/sysctl.conf << EOF

# Performance optimizations / Оптимизации за производителност
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 65536 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF

# Apply sysctl changes / Прилагане на sysctl промените
sysctl -p

# Optimize Docker / Оптимизация на Docker
log "Оптимизация на Docker..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "data-root": "/data/docker"
}
EOF

systemctl restart docker

log "Оптимизацията завърши успешно!"