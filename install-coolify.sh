#!/bin/bash
# Coolify Installation / Инсталиране на Coolify

log "Инсталиране на Coolify..."

# Download and install Coolify / Изтегляне и инсталиране на Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

log "Coolify инсталиран успешно!"
log "Достъп към Coolify: http://your-server-ip:8000"