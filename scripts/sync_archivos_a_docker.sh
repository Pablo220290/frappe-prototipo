#!/bin/bash
# ============================================
# Script de Sincronización de Archivos
# ============================================
# UBICACIÓN: frappe-prototipo/scripts/sync_archivos_a_docker.sh
#
# USO:
#   bash scripts/sync_archivos_a_docker.sh
#
# PROPÓSITO:
#   Copiar archivos desde /archivos (backup local)
#   hacia el contenedor Docker en la ubicación correcta
# ============================================

set -euo pipefail

echo "==================================================="
echo "SINCRONIZACIÓN DE ARCHIVOS AL DOCKER"
echo "==================================================="
echo ""

# Verificar que el contenedor está corriendo
if ! docker ps | grep -q frappe_app; then
    echo "❌ El contenedor frappe_app no está corriendo"
    echo "   Ejecuta primero: docker-compose up -d frappe"
    exit 1
fi

# Resolver rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "[1/4] Verificando archivos locales..."

# Verificar que los archivos existen localmente
ARCHIVOS_LOCAL="${PROJECT_ROOT}/archivos"

if [ ! -d "$ARCHIVOS_LOCAL" ]; then
    echo "❌ Directorio /archivos no existe"
    echo "   Ubicación esperada: ${ARCHIVOS_LOCAL}"
    exit 1
fi

# Array de archivos a sincronizar
declare -a ARCHIVOS=(
    "asignacion_de_equipo.py"
    "asignacion_de_equipo.js"
    "test_asignacion_de_equipo.py"
)

# Verificar que cada archivo existe
for archivo in "${ARCHIVOS[@]}"; do
    if [ ! -f "${ARCHIVOS_LOCAL}/${archivo}" ]; then
        echo "⚠️  Archivo no encontrado: ${archivo}"
    else
        echo "   ✅ ${archivo}"
    fi
done

echo ""
echo "[2/4] Copiando archivos al contenedor..."

# Ruta destino dentro del contenedor
DESTINO="/workspace/frappe-bench/apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo"

# Verificar que el destino existe en el contenedor
if ! docker exec frappe_app test -d "$DESTINO"; then
    echo "❌ El directorio destino no existe en el contenedor"
    echo "   Ubicación esperada: ${DESTINO}"
    echo "   Ejecuta primero: bash scripts/setup-inicial-v2.sh"
    exit 1
fi

# Copiar cada archivo
for archivo in "${ARCHIVOS[@]}"; do
    if [ -f "${ARCHIVOS_LOCAL}/${archivo}" ]; then
        docker cp "${ARCHIVOS_LOCAL}/${archivo}" "frappe_app:${DESTINO}/${archivo}"
        echo "   ✅ ${archivo} copiado"
    fi
done

echo ""
echo "[3/4] Ajustando permisos..."

# Ajustar permisos dentro del contenedor
docker exec frappe_app bash -c "
    chown -R frappe:frappe ${DESTINO}
    chmod 644 ${DESTINO}/*.py
    chmod 644 ${DESTINO}/*.js
"

echo "   ✅ Permisos ajustados"

echo ""
echo "[4/4] Verificando sincronización..."

# Verificar que los archivos existen en el contenedor
docker exec frappe_app bash -c "
    cd ${DESTINO}
    echo '   Archivos en contenedor:'
    ls -lh asignacion_de_equipo.* test_asignacion_de_equipo.py 2>/dev/null | awk '{print \"      \" \$9 \" (\" \$5 \")\"}' || echo '      ❌ Archivos no encontrados'
"

echo ""
echo "==================================================="
echo "✅ SINCRONIZACIÓN COMPLETADA"
echo "==================================================="
echo ""
echo "Los archivos locales de /archivos han sido copiados a:"
echo "  ${DESTINO}"
echo ""
echo "Siguiente paso:"
echo "  1. Reiniciar el contenedor para aplicar cambios:"
echo "     docker restart frappe_app"
echo ""
echo "  2. O ejecutar bench desde el contenedor:"
echo "     docker exec -it frappe_app bash -lc 'cd /workspace/frappe-bench && bench restart'"
echo ""