# Acceso al shell con herramientas
#!/bin/bash
# scripts/shell.sh - Acceso rápido al shell con herramientas

# Cargar variables de entorno
if [ -f "../.env.dev" ]; then
    source ../.env.dev
fi

CONTAINER_NAME="${CONTAINER_NAME:-postgres_dev}"

# Verificar si el contenedor está corriendo
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "El contenedor no está corriendo. Ejecuta: ./scripts/dev.sh up"
    exit 1
fi

echo "🔧 Accediendo al shell de desarrollo..."
echo ""

# Acceder e instalar herramientas automáticamente
docker exec -it $CONTAINER_NAME sh -c "
    # Instalar herramientas si no están
    if ! command -v vim >/dev/null 2>&1; then
        echo 'Instalando herramientas...'
        apk add --no-cache vim htop curl bash tree postgresql-client
        echo 'Herramientas listas'
        echo ''
    fi
    
    # Mostrar ayuda
    echo '═══════════════════════════════════════════'
    echo '🐘 Shell de Desarrollo - PostgreSQL'
    echo '═══════════════════════════════════════════'
    echo ''
    echo '  Comandos útiles:'
    echo '  psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}  → Conectar a DB'
    echo '  pg_isready                  → Verificar estado'
    echo '  vim                         → Editor de texto'
    echo '  htop                        → Monitor de recursos'
    echo '  exit                        → Salir'
    echo '═══════════════════════════════════════════'
    echo ''
    
    exec sh
"