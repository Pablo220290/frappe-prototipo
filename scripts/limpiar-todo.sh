# ============================================
# Script de LIMPIEZA TOTAL
# ============================================

set -euo pipefail

# Resolver rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "==================================================="
echo "LIMPIEZA TOTAL DEL PROYECTO"
echo "==================================================="
echo ""
echo "ADVERTENCIA: Esto eliminara TODOS los datos previos"
echo "Presiona Ctrl+C para cancelar o Enter para continuar"
read

echo ""
echo "Deteniendo contenedores..."
docker-compose down -v 2>/dev/null || true

echo ""
echo "Eliminando directorios en ${PROJECT_ROOT} ..."
rm -rf "${PROJECT_ROOT}/frappe-bench" 2>/dev/null || true
rm -rf "${PROJECT_ROOT}/logs" 2>/dev/null || true

# Basura histórica de intentos anteriores
rm -rf "${PROJECT_ROOT}/apps" 2>/dev/null || true
rm -rf "${PROJECT_ROOT}/sites" 2>/dev/null || true
rm -rf "${PROJECT_ROOT}/apps;C" 2>/dev/null || true
rm -rf "${PROJECT_ROOT}/sites;C" 2>/dev/null || true
rm -rf "${PROJECT_ROOT}/frappe-bench;C" 2>/dev/null || true

mkdir -p "${PROJECT_ROOT}/logs"

echo ""
echo "==================================================="
echo "LIMPIEZA COMPLETADA"
echo "==================================================="
echo ""
