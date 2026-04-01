#!/bin/bash
# scripts/dev.sh - Script principal de desarrollo

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
CONTAINER_NAME="arche_dev"
DB_USER="admin"
DB_NAME="arche"
DB_PORT="5433"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo ""
    echo -e "${GREEN}./scripts/dev.sh up${NC}       - Iniciar PostgreSQL"
    echo -e "${GREEN}./scripts/dev.sh down${NC}     - Detener PostgreSQL"
    echo -e "${GREEN}./scripts/dev.sh shell${NC}    - Acceder al shell con herramientas"
    echo -e "${GREEN}./scripts/dev.sh psql${NC}     - Conectar a PostgreSQL"
    echo -e "${GREEN}./scripts/dev.sh logs${NC}     - Ver logs en tiempo real"
    echo -e "${GREEN}./scripts/dev.sh status${NC}   - Ver estado de la base de datos"
    echo -e "${GREEN}./scripts/dev.sh backup${NC}   - Crear backup"
    echo -e "${GREEN}./scripts/dev.sh restore${NC}  - Restaurar backup"
    echo -e "${GREEN}./scripts/dev.sh seed${NC}     - Cargar datos de prueba"
    echo -e "${GREEN}./scripts/dev.sh clean${NC}    - Limpiar todo (datos incluidos)"
    echo -e "${GREEN}./scripts/dev.sh restart${NC}  - Reiniciar PostgreSQL"
    echo ""
}

# Iniciar PostgreSQL
up() {
    echo -e "${GREEN}🚀 Iniciando PostgreSQL...${NC}"
    docker compose -f $COMPOSE_FILE --env-file $ENV_FILE up -d
    sleep 2
    echo -e "${GREEN}✅ PostgreSQL iniciado${NC}"
    echo -e "${BLUE}   Puerto:        $DB_PORT${NC}"
    echo -e "${BLUE}   Usuario:       $DB_USER${NC}"
    echo -e "${BLUE}   Base de datos: $DB_NAME${NC}"
    echo -e "${YELLOW}   Para conectar: ./scripts/dev.sh psql${NC}"
}

# Detener PostgreSQL
down() {
    echo -e "${YELLOW}Deteniendo PostgreSQL...${NC}"
    docker compose -f $COMPOSE_FILE down
    echo -e "${GREEN}✅ PostgreSQL detenido${NC}"
}

# Acceder al shell con herramientas
shell() {
    echo -e "${BLUE}🔧 Accediendo al shell de desarrollo...${NC}"

    # Verificar si el contenedor está corriendo
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo -e "${RED}❌ El contenedor no está corriendo. Ejecuta primero: ./scripts/dev.sh up${NC}"
        exit 1
    fi

    # Acceder e instalar herramientas si es necesario
    docker exec -it $CONTAINER_NAME sh -c "
        if ! command -v vim >/dev/null 2>&1; then
            echo 'Instalando herramientas de desarrollo...'
            apk add --no-cache vim htop curl bash tree postgresql-client
            echo 'Herramientas instaladas'
        fi
        echo ''
        echo '═══════════════════════════════════════════════════════'
        echo '🐘 Shell de Desarrollo - PostgreSQL (arche)'
        echo '═══════════════════════════════════════════════════════'
        echo ''
        echo ' Comandos útiles:'
        echo '  psql -U admin -d arche         → Conectar a PostgreSQL'
        echo '  pg_isready                     → Verificar estado'
        echo '  vim archivo.conf               → Editar configuraciones'
        echo '  htop                           → Monitor de recursos'
        echo ''
        echo 'Para salir: exit'
        echo '═══════════════════════════════════════════════════════'
        echo ''
        exec sh
    "
}

# Conectar a PostgreSQL
psql() {
    echo -e "${BLUE}🐘 Conectando a PostgreSQL...${NC}"
    docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
}

# Ver logs
logs() {
    echo -e "${BLUE}📄 Mostrando logs (Ctrl+C para salir)...${NC}"
    docker compose -f $COMPOSE_FILE logs -f postgres
}

# Ver estado
status() {
    echo -e "${BLUE}Estado de PostgreSQL:${NC}"
    docker exec $CONTAINER_NAME pg_isready
    echo ""
    echo -e "${BLUE}Bases de datos:${NC}"
    docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "\l"
    echo ""
    echo -e "${BLUE}Conexiones activas:${NC}"
    docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT count(*) FROM pg_stat_activity;"
}

# Crear backup
backup() {
    echo -e "${BLUE}Creando backup...${NC}"
    mkdir -p ./backups
    BACKUP_FILE="./backups/backup_$(date +%Y%m%d_%H%M%S).sql"
    docker exec -e PGPASSWORD=$(grep POSTGRES_PASSWORD $ENV_FILE | cut -d= -f2) \
        $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME > $BACKUP_FILE
    echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE${NC}"
}

# Restaurar backup
restore() {
    echo -e "${BLUE}Restaurar backup${NC}"
    echo -e "${YELLOW}Backups disponibles:${NC}"
    ls -1 ./backups/*.sql 2>/dev/null || echo "No hay backups"
    echo ""
    read -p "Nombre del archivo (ej: backup_20240331_120000.sql): " FILE
    if [ -f "./backups/$FILE" ]; then
        docker exec -i -e PGPASSWORD=$(grep POSTGRES_PASSWORD $ENV_FILE | cut -d= -f2) \
            $CONTAINER_NAME psql -U $DB_USER $DB_NAME < "./backups/$FILE"
        echo -e "${GREEN}✅ Backup restaurado${NC}"
    else
        echo -e "${RED}❌ Archivo no encontrado${NC}"
    fi
}

# Cargar datos de prueba (usa seed-data del docker-compose con profile manual)
seed() {
    echo -e "${BLUE}🌱 Cargando datos de prueba...${NC}"
    if [ -d "./seed-data" ] && ls ./seed-data/*.sql 2>/dev/null | grep -q .; then
        docker compose -f $COMPOSE_FILE --env-file $ENV_FILE --profile manual up seed-data
        echo -e "${GREEN}✅ Datos de prueba cargados${NC}"
    else
        echo -e "${RED}❌ No se encontraron archivos .sql en ./seed-data/${NC}"
        echo -e "${YELLOW}💡 Crea archivos .sql en la carpeta ./seed-data/${NC}"
    fi
}

# Limpiar todo
clean() {
    echo -e "${RED}⚠️  Esto eliminará TODOS los datos. ¿Estás seguro? (yes/no)${NC}"
    read confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}🗑️  Deteniendo contenedores...${NC}"
        docker compose -f $COMPOSE_FILE down -v
        echo -e "${YELLOW}🗑️  Eliminando datos locales...${NC}"
        rm -rf ./postgres_data
        rm -rf ./backups
        echo -e "${GREEN}✅ Todo limpiado${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

# Reiniciar
restart() {
    echo -e "${YELLOW}🔄 Reiniciando PostgreSQL...${NC}"
    down
    sleep 2
    up
}

# Comando principal
case "$1" in
    up)       up ;;
    down)     down ;;
    shell)    shell ;;
    psql)     psql ;;
    logs)     logs ;;
    status)   status ;;
    backup)   backup ;;
    restore)  restore ;;
    seed)     seed ;;
    clean)    clean ;;
    restart)  restart ;;
    help|--help|-h|*)
        show_help ;;
esac