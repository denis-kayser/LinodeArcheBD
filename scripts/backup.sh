#!/bin/bash
# scripts/backup.sh - Script de backup

CONTAINER_NAME="arche_dev"
DB_USER="admin"
DB_NAME="arche"
DB_PASSWORD="secreet"
BACKUP_DIR="./backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"
LOG_FILE="$BACKUP_DIR/cron.log"

# Crear directorio si no existe
mkdir -p $BACKUP_DIR

echo "Creando backup de PostgreSQL..."

# Verificar contenedor
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Error: PostgreSQL no está corriendo"
    exit 1
fi

# Crear backup
docker exec -e PGPASSWORD=$DB_PASSWORD $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME > $BACKUP_FILE

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "Backup completado: $BACKUP_FILE"
    # Mantener solo los últimos 7 backups
    ls -t $BACKUP_DIR/backup_*.sql | tail -n +8 | xargs -r rm
    echo "Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
else
    echo "Error al crear backup"
    exit 1
fi

# ─────────────────────────────────────────────
# CRONJOB - Para activarlo ejecuta:
#   crontab -e
# Y agrega esta línea (backup todos los días a las 2am):
#   0 2 * * * /ruta/tu_proyecto/scripts/backup.sh >> /ruta/tu_proyecto/backups/cron.log 2>&1
#
# Para verificar que el cron está activo:
#   crontab -l
#
# Para ver el log del cron:
#   tail -f ./backups/cron.log
# ─────────────────────────────────────────────

# TEST del cron (corre el backup y guarda en cron.log para verificar que funciona)
# Ejecuta esto UNA VEZ manualmente para probar:
#   ./scripts/backup.sh >> ./backups/cron.log 2>&1 && tail -5 ./backups/cron.log