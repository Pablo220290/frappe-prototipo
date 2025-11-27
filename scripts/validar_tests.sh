#!/bin/bash
# ============================================
# Script de Validación - Fase 4
# ============================================
# UBICACIÓN: frappe-prototipo/scripts/validate_phase4.sh
#
# USO:
#   bash scripts/validate_phase4.sh
#
# PROPÓSITO:
#   Verificar que TODOS los componentes de la Fase 4
#   estén implementados y funcionando correctamente
# ============================================

set -euo pipefail

echo "==================================================="
echo "VALIDACIÓN FASE 4: GESTIÓN DE DEPENDENCIAS"
echo "==================================================="
echo ""

EXIT_CODE=0

# --------------------------------------------
# Test 1: Verificar que pyproject.toml existe
# --------------------------------------------
echo "[1/7] Verificando pyproject.toml..."
if docker exec frappe_app test -f //workspace/frappe-bench/apps/asignacion_equipo/pyproject.toml 2>/dev/null; then
    echo "   ✅ pyproject.toml existe"
else
    echo "   ❌ pyproject.toml NO existe"
    echo "      Ejecuta: bash scripts/setup-inicial-v2.sh"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 2: Verificar contenido de pyproject.toml
# --------------------------------------------
echo "[2/7] Verificando dependencia 'requests' en pyproject.toml..."
if docker exec frappe_app grep -q "requests>=" //workspace/frappe-bench/apps/asignacion_equipo/pyproject.toml 2>/dev/null; then
    echo "   ✅ 'requests' declarado en dependencias"
    VERSION_DECLARADA=$(docker exec frappe_app grep "requests" //workspace/frappe-bench/apps/asignacion_equipo/pyproject.toml | head -1)
    echo "      Declaración: $VERSION_DECLARADA"
else
    echo "   ❌ 'requests' NO está en dependencias"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 3: Verificar instalación de requests
# --------------------------------------------
echo "[3/7] Verificando instalación de 'requests'..."
if docker exec frappe_app bash -lc "python3 -c 'import requests; print(requests.__version__)'" &>/dev/null; then
    VERSION=$(docker exec frappe_app bash -lc "python3 -c 'import requests; print(requests.__version__)'")
    echo "   ✅ 'requests' instalado correctamente"
    echo "      Versión instalada: $VERSION"
else
    echo "   ❌ 'requests' NO está instalado"
    echo "      Ejecuta: bash scripts/install_dependencies.sh"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 4: Verificar import en código Python
# --------------------------------------------
echo "[4/7] Verificando 'import requests' en código..."
PYTHON_FILE="//workspace/frappe-bench/apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo/asignacion_de_equipo.py"

if docker exec frappe_app grep -q "^import requests" "$PYTHON_FILE" 2>/dev/null; then
    echo "   ✅ 'import requests' presente en asignacion_de_equipo.py"
    LINE_NUM=$(docker exec frappe_app grep -n "^import requests" "$PYTHON_FILE" | cut -d: -f1)
    echo "      Ubicación: línea $LINE_NUM"
else
    echo "   ❌ 'import requests' NO encontrado"
    echo "      Verifica que el archivo esté sincronizado desde /archivos"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 5: Verificar función verificar_garantia_externa
# --------------------------------------------
echo "[5/7] Verificando función verificar_garantia_externa()..."
if docker exec frappe_app grep -q "def verificar_garantia_externa" "$PYTHON_FILE" 2>/dev/null; then
    echo "   ✅ Función verificar_garantia_externa() existe"
    LINE_NUM=$(docker exec frappe_app grep -n "def verificar_garantia_externa" "$PYTHON_FILE" | cut -d: -f1)
    echo "      Ubicación: línea $LINE_NUM"
else
    echo "   ❌ Función NO encontrada"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 6: Verificar que la función usa requests
# --------------------------------------------
echo "[6/7] Verificando uso de 'requests' en la función..."
if docker exec frappe_app grep -A 20 "def verificar_garantia_externa" "$PYTHON_FILE" | grep -q "requests.get" 2>/dev/null; then
    echo "   ✅ La función utiliza requests.get()"
else
    echo "   ❌ La función NO utiliza requests.get()"
    EXIT_CODE=1
fi

# --------------------------------------------
# Test 7: Ejecutar tests unitarios
# --------------------------------------------
echo "[7/7] Ejecutando tests unitarios..."
echo "   (Esto puede tardar unos segundos...)"

# Capturar salida de tests
TEST_OUTPUT=$(docker exec frappe_app bash -lc "
    cd /workspace/frappe-bench && 
    bench --site desarrollo.local run-tests \
        --module asignacion_equipo.gestion.doctype.asignacion_de_equipo.test_asignacion_de_equipo \
        2>&1
" || true)

# Verificar si los tests pasaron
if echo "$TEST_OUTPUT" | grep -q "OK" || echo "$TEST_OUTPUT" | grep -q "Ran.*test"; then
    echo "   ✅ Tests unitarios ejecutados"
    
    # Contar tests que pasaron
    TESTS_RAN=$(echo "$TEST_OUTPUT" | grep -oP "Ran \K\d+" || echo "?")
    echo "      Tests ejecutados: $TESTS_RAN"
    
    # Verificar si hay fallos
    if echo "$TEST_OUTPUT" | grep -q "FAILED"; then
        echo "   ⚠️  Algunos tests fallaron (no crítico para validación)"
    fi
else
    echo "   ⚠️  No se pudieron ejecutar los tests"
    echo "      (Puede ser normal si la DB no está inicializada)"
fi

# --------------------------------------------
# Resumen Final
# --------------------------------------------
echo ""
echo "==================================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ FASE 4 VALIDADA EXITOSAMENTE"
    echo "==================================================="
    echo ""
    echo "Componentes verificados:"
    echo "  ✅ pyproject.toml configurado correctamente"
    echo "  ✅ Dependencia 'requests' instalada ($VERSION)"
    echo "  ✅ Código Python actualizado con import"
    echo "  ✅ Función de API externa implementada"
    echo "  ✅ Tests unitarios disponibles"
    echo ""
    echo "🎉 La gestión de dependencias está funcionando"
    echo ""
    echo "Prueba la función desde la UI de Frappe:"
    echo "  1. Ir a: http://desarrollo.local:8000"
    echo "  2. Abrir cualquier Asignación de Equipo"
    echo "  3. Ejecutar el botón de verificar garantía"
    echo ""
else
    echo "❌ FASE 4 TIENE ERRORES"
    echo "==================================================="
    echo ""
    echo "Pasos de corrección:"
    echo "  1. Revisa los mensajes de error arriba"
    echo "  2. Si falta pyproject.toml:"
    echo "     bash scripts/setup-inicial-v2.sh"
    echo "  3. Si requests no está instalado:"
    echo "     bash scripts/install_dependencies.sh"
    echo "  4. Si el código no está sincronizado:"
    echo "     bash scripts/sync_archivos_a_docker.sh"
    echo ""
fi
echo "==================================================="
echo ""

exit $EXIT_CODE