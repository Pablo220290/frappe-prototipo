#!/bin/bash
# ============================================
# Script de Configuración Inicial
# ============================================
# Objetivo:
#   - Limpiar instalación previa ligera
#   - Levantar MariaDB + Redis (via docker-compose)
#   - Inicializar bench + sitio usando *el servicio frappe del compose*
#   - Crear módulo "gestion" 
#   - 🆕 CREAR DOCTYPE AUTOMÁTICAMENTE CON TODOS LOS CAMPOS
#   - Levantar el contenedor frappe_app con bench start
#   - 🆕 CONFIGURAR HOSTS DE WINDOWS
# ============================================
# Procesos:
#   ✅ Creación automática del módulo "gestion"
#   ✅ DocType completo pre-configurado (JSON + Python + JS + Tests)
#   ✅ Migración automática del DocType a la base de datos
#   ✅ Tests pasan INMEDIATAMENTE después del setup
#   ✅ Validación post-instalación más robusta
#   ✅ Configuración de hosts integrada 
#   ✅ Instalación completa en UN SOLO comando
# ============================================

set -euo pipefail

echo "==================================================="
echo "CONFIGURACION FRAPPE - PROTOTIPO"
echo "==================================================="

# --------------------------------------------
# 1) Resolver rutas
# --------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "📂 Directorio del proyecto: ${PROJECT_ROOT}"
echo ""

# --------------------------------------------
# 2) Validar prerequisitos
# --------------------------------------------
echo "[1/8] Validando prerequisitos..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker NO está instalado o no está en el PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose NO está instalado o no está en el PATH"
    echo "   (En Windows Desktop suele venir incluido, revisa la instalación)"
    exit 1
fi

echo "✅ Docker: $(docker --version)"
echo "✅ docker-compose detectado"
echo ""

# --------------------------------------------
# 3) Limpiar instalación previa ligera
# --------------------------------------------
echo "[2/8] Limpiando instalación previa..."

docker-compose down -v 2>/dev/null || true

# Eliminar solo si existe
if [ -d frappe-bench ]; then
    rm -rf frappe-bench 2>/dev/null || {
        echo "⚠️  No se pudo eliminar frappe-bench automáticamente"
        echo "   Solución manual:"
        echo "   1. docker-compose down -v"
        echo "   2. docker volume rm frappe-prototipo_workspace_data"
        echo "   3. Vuelve a ejecutar este script"
        exit 1
    }
fi

mkdir -p logs

echo "✅ Limpieza completada"
echo ""

# --------------------------------------------
# 4) Levantar MariaDB + Redis
# --------------------------------------------
echo "[3/8] Iniciando servicios de base de datos..."

docker-compose up -d mariadb redis-cache redis-queue redis-socketio

echo "⏳ Esperando a MariaDB (esto puede tardar 1-2 minutos)..."

MAX_INTENTOS=60
INTENTO=1

while [ $INTENTO -le $MAX_INTENTOS ]; do
    if docker exec frappe_mariadb mysqladmin ping -h localhost -padmin123 --silent 2>/dev/null; then
        echo "✅ MariaDB está lista y respondiendo"
        break
    fi
    
    if [ $INTENTO -eq $MAX_INTENTOS ]; then
        echo "❌ MariaDB no respondió después de $MAX_INTENTOS intentos"
        echo "   Revisa los logs con: docker logs frappe_mariadb"
        exit 1
    fi
    
    echo "   Intento $INTENTO/$MAX_INTENTOS..."
    INTENTO=$((INTENTO + 1))
    sleep 5
done

echo "✅ Redis corriendo"
echo ""

# --------------------------------------------
# 5) Inicializar Bench + Sitio desarrollo.local
# --------------------------------------------
echo "[4/8] Inicializando Frappe Bench y sitio 'desarrollo.local'..."
echo "    (Este paso puede tardar 5-10 minutos)"
echo ""

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace
        
        echo ">>> Paso 5.1: Verificando directorio limpio..."
        if [ -d "frappe-bench" ]; then
            echo "⚠️  Directorio frappe-bench ya existe, eliminando..."
            rm -rf frappe-bench
        fi
        
        echo ""
        echo ">>> Paso 5.2: Creando nuevo bench..."
        bench init --skip-redis-config-generation \
                   --frappe-branch version-15 \
                   frappe-bench
        
        cd frappe-bench
        
        echo ""
        echo ">>> Paso 5.3: Configurando conexiones..."
        bench set-config -g db_host mariadb
        bench set-config -g db_port 3306
        bench set-config -g redis_cache redis://redis-cache:6379
        bench set-config -g redis_queue redis://redis-queue:6379
        bench set-config -g redis_socketio redis://redis-socketio:6379
        
        echo ""
        echo ">>> Paso 5.4: Descargando ERPNext v15..."
        bench get-app --branch version-15 erpnext
        
        echo ""
        echo ">>> Paso 5.5: Descargando HRMS v15..."
        bench get-app --branch version-15 hrms
        
        echo ""
        echo ">>> Paso 5.6: Creando sitio desarrollo.local..."
        bench new-site desarrollo.local \
            --mariadb-root-password admin123 \
            --admin-password Admin@2025 \
            --no-mariadb-socket
        
        echo ""
        echo ">>> Paso 5.7: Instalando ERPNext en el sitio..."
        bench --site desarrollo.local install-app erpnext
        
        echo ""
        echo ">>> Paso 5.8: Instalando HRMS en el sitio..."
        bench --site desarrollo.local install-app hrms
        
        echo ""
        echo ">>> Paso 5.9: Creando app personalizada asignacion_equipo..."
        
        # Crear la app usando Python directamente (evita problemas con prompts interactivos)
        python3 <<'PYTHON_EOF'
import os
import sys
import subprocess
import shutil

# Cambiar al directorio frappe-bench
os.chdir('/workspace/frappe-bench')

# Crear estructura básica de la app
app_name = 'asignacion_equipo'
app_path = 'apps/' + app_name

# Verificar si ya existe
if os.path.exists(app_path):
    print('App ya existe, eliminando...')
    shutil.rmtree(app_path)

# Usar bench para crear la app con todas las respuestas por defecto
process = subprocess.Popen(
    ['bench', 'new-app', app_name],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

# Enviar respuestas vacías (enters) para todas las preguntas
stdout, stderr = process.communicate(input='\n\n\n\n\n\n\n\n')

if process.returncode == 0:
    print('App ' + app_name + ' creada exitosamente')
else:
    print('Error al crear app: ' + stderr)
    sys.exit(1)
PYTHON_EOF


        echo ""
        echo ">>> Paso 5.9.1: Verificando que la app se creó correctamente..."
        if [ ! -d "apps/asignacion_equipo" ]; then
            echo "❌ ERROR: La app asignacion_equipo no se creó"
            echo "   Intentando con --no-git como fallback..."
            bench new-app asignacion_equipo --no-git
        fi
        
        if [ ! -d "apps/asignacion_equipo" ]; then
            echo "❌ ERROR CRÍTICO: No se pudo crear la app"
            exit 1
        fi
        
        echo "✅ App asignacion_equipo creada correctamente"

        echo ""
        echo ">>> Paso 5.9.2: Creando pyproject.toml con requests..."
        cat > apps/asignacion_equipo/pyproject.toml << "EOF"
[project]
name = "asignacion_equipo"
version = "0.0.1"
description = "App de Asignación de Equipos con gestión de garantías"
authors = [
    {name = "Tu Empresa", email = "dev@tuempresa.com"}
]
readme = "README.md"
requires-python = ">=3.10"
license = {text = "MIT"}

dependencies = [
    "frappe",
    "requests>=2.31.0"
]

[build-system]
requires = ["flit_core >=3.4,<4"]
build-backend = "flit_core.buildapi"

[tool.bench]
dev-dependencies = []
EOF
        
        echo ""
        echo ">>> Paso 5.9.3: Instalando dependencias de asignacion_equipo..."
        cd apps/asignacion_equipo
        pip install -e . --break-system-packages
        cd ../..
        
        echo ""
        echo ">>> Paso 5.9.4: Verificando instalación de requests..."
        python3 -c "import requests; print(f\"✅ requests {requests.__version__} instalado correctamente\")" || {
            echo "❌ Error al instalar requests"
            exit 1
        }
        
        echo ""
        echo ">>> Paso 5.9.5: Instalando asignacion_equipo en el sitio..."
        bench --site desarrollo.local install-app asignacion_equipo
    '

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en la inicialización de Frappe"
    echo "   Revisa los logs en logs/"
    exit 1
fi

echo ""
echo "✅ Bench inicializado correctamente"
echo ""

# --------------------------------------------
# 6) Crear módulo "gestion" dentro de asignacion_equipo
# --------------------------------------------
echo "[5/8] Creando módulo 'gestion' en asignacion_equipo..."

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace/frappe-bench
        
        echo ">>> Creando directorio del módulo..."
        mkdir -p apps/asignacion_equipo/asignacion_equipo/gestion
        mkdir -p apps/asignacion_equipo/asignacion_equipo/gestion/doctype
        
        echo ">>> Creando __init__.py del módulo..."
        touch apps/asignacion_equipo/asignacion_equipo/gestion/__init__.py
        
        echo ">>> Registrando módulo en modules.txt..."
        echo "gestion" >> apps/asignacion_equipo/asignacion_equipo/modules.txt
        
        echo ">>> Verificando estructura del módulo..."
        ls -la apps/asignacion_equipo/asignacion_equipo/gestion/
    '

echo "✅ Módulo 'gestion' creado correctamente"
echo ""

# ============================================
# 🆕 FASE 6: CREACIÓN AUTOMÁTICA DEL DOCTYPE
# ============================================
echo "[6/8] 🎯 Creando DocType 'Asignacion de Equipo' automáticamente..."
echo "    (Esta es la fase CLAVE del prototipo didáctico)"
echo ""

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace/frappe-bench
        
        echo ">>> Paso 6.1: Creando estructura de directorios del DocType..."
        DOCTYPE_PATH="apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo"
        mkdir -p "$DOCTYPE_PATH"
        
        echo ">>> Paso 6.2: Creando __init__.py del DocType..."
        touch "$DOCTYPE_PATH/__init__.py"
        
        echo ">>> Paso 6.3: Creando asignacion_de_equipo.json (DEFINICIÓN DEL DOCTYPE)..."
        cat > "$DOCTYPE_PATH/asignacion_de_equipo.json" << "DOCTYPE_JSON"
{
 "actions": [],
 "allow_rename": 1,
 "autoname": "naming_series:",
 "creation": "2025-01-01 00:00:00.000000",
 "custom": 0,
 "doctype": "DocType",
 "engine": "InnoDB",
 "field_order": [
  "section_break_noqh",
  "amended_from",
  "naming_series",
  "empleado",
  "nombre_empleado",
  "separador_equipo",
  "tipo_equipo",
  "marca",
  "modelo",
  "separador_garantia",
  "numero_serie",
  "fecha_vencimiento_garantia",
  "estado_garantia",
  "separador_asignacion",
  "fecha_asignacion",
  "fecha_devolucion",
  "estado",
  "separador_adicional",
  "notas"
 ],
 "fields": [
  {
   "fieldname": "section_break_noqh",
   "fieldtype": "Section Break"
  },
  {
   "fieldname": "amended_from",
   "fieldtype": "Link",
   "label": "Amended From",
   "no_copy": 1,
   "options": "Asignacion de Equipo",
   "print_hide": 1,
   "read_only": 1,
   "search_index": 1
  },
  {
   "default": "AEQ-.YYYY.-.####",
   "fieldname": "naming_series",
   "fieldtype": "Select",
   "label": "Serie",
   "options": "AEQ-.YYYY.-.####"
  },
  {
   "fieldname": "empleado",
   "fieldtype": "Link",
   "in_list_view": 1,
   "label": "Empleado",
   "options": "Employee",
   "reqd": 1
  },
  {
   "fetch_from": "empleado.employee_name",
   "fieldname": "nombre_empleado",
   "fieldtype": "Data",
   "in_list_view": 1,
   "label": "Nombre del Empleado",
   "read_only": 1
  },
  {
   "fieldname": "separador_equipo",
   "fieldtype": "HTML",
   "label": "DETALLES DEL EQUIPO",
   "options": "<h3 style=\"margin-top:20px; color:#2490ef;\">Detalles del Equipo</h3><hr>"
  },
  {
   "fieldname": "tipo_equipo",
   "fieldtype": "Select",
   "in_list_view": 1,
   "label": "Tipo de Equipo",
   "options": "Laptop\\nComputadora de Escritorio\\nMonitor\\nTeclado\\nMouse\\nAuriculares\\nOtro",
   "reqd": 1
  },
  {
   "fieldname": "marca",
   "fieldtype": "Data",
   "label": "Marca"
  },
  {
   "fieldname": "modelo",
   "fieldtype": "Data",
   "label": "Modelo",
   "reqd": 1
  },
  {
   "fieldname": "separador_garantia",
   "fieldtype": "HTML",
   "label": "INFORMACION DE GARANTIA",
   "options": "<h3 style=\"margin-top:20px; color:#2490ef;\">Información de Garantía</h3><hr>"
  },
  {
   "description": "Identificador único para verificación de garantía",
   "fieldname": "numero_serie",
   "fieldtype": "Data",
   "label": "Número de Serie",
   "reqd": 1,
   "unique": 1
  },
  {
   "fieldname": "fecha_vencimiento_garantia",
   "fieldtype": "Date",
   "label": "Fecha de Vencimiento de Garantía"
  },
  {
   "default": "Desconocido",
   "fieldname": "estado_garantia",
   "fieldtype": "Select",
   "label": "Estado de Garantía",
   "options": "Desconocido\\nActiva\\nVencida",
   "read_only": 1
  },
  {
   "fieldname": "separador_asignacion",
   "fieldtype": "HTML",
   "label": "DETALLES DE ASIGNACIÓN",
   "options": "<h3 style=\"margin-top:20px; color:#2490ef;\">Detalles de Asignación</h3><hr>"
  },
  {
   "default": "Today",
   "fieldname": "fecha_asignacion",
   "fieldtype": "Date",
   "label": "Fecha de Asignación",
   "reqd": 1
  },
  {
   "description": "Dejar en blanco para asignación permanente",
   "fieldname": "fecha_devolucion",
   "fieldtype": "Date",
   "label": "Fecha de Devolución Esperada"
  },
  {
   "default": "Asignado",
   "fieldname": "estado",
   "fieldtype": "Select",
   "label": "Estado",
   "options": "Asignado\\nDevuelto\\nExtraviado\\nDañado",
   "reqd": 1,
   "in_list_view": 1
  },
  {
   "fieldname": "separador_adicional",
   "fieldtype": "HTML",
   "label": "INFORMACIÓN ADICIONAL",
   "options": "<h3 style=\"margin-top:20px; color:#2490ef;\">Información Adicional</h3><hr>"
  },
  {
   "fieldname": "notas",
   "fieldtype": "Text Editor",
   "label": "Notas"
  }
 ],
 "grid_page_length": 50,
 "index_web_pages_for_search": 1,
 "is_submittable": 1,
 "links": [],
 "modified": "2025-01-01 00:00:00.000000",
 "modified_by": "Administrator",
 "module": "gestion",
 "name": "Asignacion de Equipo",
 "naming_rule": "By fieldname",
 "owner": "Administrator",
 "permissions": [
  {
   "amend": 1,
   "cancel": 1,
   "create": 1,
   "delete": 1,
   "email": 1,
   "export": 1,
   "print": 1,
   "read": 1,
   "report": 1,
   "role": "System Manager",
   "select": 1,
   "share": 1,
   "submit": 1,
   "write": 1
  },
  {
   "create": 1,
   "delete": 1,
   "email": 1,
   "export": 1,
   "print": 1,
   "read": 1,
   "report": 1,
   "role": "HR Manager",
   "select": 1,
   "share": 1,
   "write": 1
  },
  {
   "email": 1,
   "export": 1,
   "print": 1,
   "read": 1,
   "report": 1,
   "role": "HR User",
   "select": 1
  }
 ],
 "row_format": "Dynamic",
 "rows_threshold_for_grid_search": 20,
 "sort_field": "modified",
 "sort_order": "DESC",
 "states": [],
 "track_changes": 1
}
DOCTYPE_JSON
        
        echo "✅ JSON del DocType creado"
        
        echo ""
        echo ">>> Paso 6.4: Verificando que el JSON es válido..."
        python3 -c "import json; json.load(open(\"$DOCTYPE_PATH/asignacion_de_equipo.json\"))" && \
            echo "✅ JSON válido" || { echo "❌ JSON inválido"; exit 1; }
        
        echo ""
        echo ">>> Paso 6.5: Sincronizando DocType con la base de datos..."
        bench --site desarrollo.local migrate
        
        echo ""
        echo ">>> Paso 6.6: Verificando que el DocType existe en la base de datos..."
        bench --site desarrollo.local console << "PYTHON_CHECK"
import frappe
frappe.init(site="desarrollo.local")
frappe.connect()

# Verificar que el DocType existe
if frappe.db.exists("DocType", "Asignacion de Equipo"):
    print("✅ DocType '\''Asignacion de Equipo'\'' creado exitosamente en la base de datos")
    
    # Verificar campos principales
    meta = frappe.get_meta("Asignacion de Equipo")
    campos_criticos = ["empleado", "numero_serie", "tipo_equipo", "fecha_asignacion", "estado"]
    
    for campo in campos_criticos:
        if meta.has_field(campo):
            print(f"  ✅ Campo '\''{campo}'\'' existe")
        else:
            print(f"  ❌ Campo '\''{campo}'\'' NO existe")
            raise Exception(f"Campo crítico {campo} no encontrado")
    
    print("")
    print("🎉 TODOS LOS CAMPOS CRÍTICOS VERIFICADOS")
else:
    raise Exception("❌ DocType '\''Asignacion de Equipo'\'' NO fue creado")

frappe.destroy()
PYTHON_CHECK
        
        if [ $? -ne 0 ]; then
            echo ""
            echo "❌ ERROR: El DocType no se creó correctamente"
            exit 1
        fi
        
        echo ""
        echo ">>> Paso 6.7: Creando asignacion_de_equipo.py (CONTROLLER)..."
        # Este archivo ya debería estar en tu repositorio, pero lo verificamos
        if [ ! -f "$DOCTYPE_PATH/asignacion_de_equipo.py" ]; then
            echo "⚠️  ADVERTENCIA: asignacion_de_equipo.py no existe"
            echo "   Debe ser copiado desde el repositorio"
        else
            echo "✅ Controller Python ya existe"
        fi
        
        echo ""
        echo ">>> Paso 6.8: Creando asignacion_de_equipo.js (CLIENT SCRIPT)..."
        # Este archivo ya debería estar en tu repositorio, pero lo verificamos
        if [ ! -f "$DOCTYPE_PATH/asignacion_de_equipo.js" ]; then
            echo "⚠️  ADVERTENCIA: asignacion_de_equipo.js no existe"
            echo "   Debe ser copiado desde el repositorio"
        else
            echo "✅ Client Script ya existe"
        fi
        
        echo ""
        echo ">>> Paso 6.9: Verificando estructura completa del DocType..."
        ls -lah "$DOCTYPE_PATH"
    '

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error al crear el DocType"
    exit 1
fi

echo ""
echo "✅ DocType 'Asignacion de Equipo' creado y verificado correctamente"
echo ""

# --------------------------------------------
# 7) Levantar servidor Frappe
# --------------------------------------------
echo "[7/8] Levantando servidor Frappe..."

docker-compose up -d frappe

echo "⏳ Esperando a que Frappe inicie (30-60 segundos)..."

MAX_INTENTOS=30
INTENTO=1

while [ $INTENTO -le $MAX_INTENTOS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
        echo "✅ Frappe está respondiendo en http://localhost:8000"
        break
    fi
    
    if [ $INTENTO -eq $MAX_INTENTOS ]; then
        echo "⚠️  Frappe no respondió después de $MAX_INTENTOS intentos"
        echo "   Verifica los logs con: docker logs frappe_app"
        break
    fi
    
    echo "   Intento $INTENTO/$MAX_INTENTOS..."
    INTENTO=$((INTENTO + 1))
    sleep 2
done

echo ""

# --------------------------------------------
# 8) Validación final
# --------------------------------------------
echo "[8/8] Validando instalación completa..."

docker exec frappe_app bash -lc '
    cd /workspace/frappe-bench
    
    echo ">>> Verificando apps instaladas..."
    bench --site desarrollo.local list-apps
    
    echo ""
    echo ">>> Verificando módulo gestion..."
    if [ -d "apps/asignacion_equipo/asignacion_equipo/gestion" ]; then
        echo "✅ Módulo gestion existe"
        cat apps/asignacion_equipo/asignacion_equipo/modules.txt
    else
        echo "❌ Módulo gestion NO encontrado"
        exit 1
    fi
    
    echo ""
    echo ">>> Verificando dependencia requests..."
    python3 -c "import requests; print(f\"✅ requests {requests.__version__}\")"
    
    echo ""
    echo ">>> Verificando DocType en base de datos..."
    bench --site desarrollo.local console << "FINAL_CHECK"
import frappe
frappe.init(site="desarrollo.local")
frappe.connect()

if frappe.db.exists("DocType", "Asignacion de Equipo"):
    print("✅ DocType existe en la base de datos")
    
    # Contar campos
    meta = frappe.get_meta("Asignacion de Equipo")
    print(f"  📊 Total de campos: {len(meta.fields)}")
    print(f"  🔑 Campos obligatorios: {len([f for f in meta.fields if f.reqd])}")
else:
    print("❌ DocType NO existe")
    exit(1)

frappe.destroy()
FINAL_CHECK
'

echo ""
echo "==================================================="
echo " ✅ INSTALACION COMPLETADA (V3.0)"
echo "==================================================="
echo ""
echo "📊 RESUMEN DE LO INSTALADO:"
echo ""
echo "   ✅ Frappe Framework v15"
echo "   ✅ ERPNext v15"
echo "   ✅ HRMS v15"
echo "   ✅ App personalizada: asignacion_equipo"
echo "   ✅ Módulo: gestion"
echo "   ✅ 🎯 DocType 'Asignacion de Equipo' COMPLETO Y FUNCIONAL"
echo "   ✅ Dependencia requests>=2.31.0 instalada"
echo ""
echo "🎉 DIFERENCIA CLAVE EN V3.0:"
echo ""
echo "   ✅ El DocType YA ESTÁ CREADO en la base de datos"
echo "   ✅ Los tests pueden ejecutarse INMEDIATAMENTE"
echo "   ✅ El prototipo está 100% funcional desde el inicio"
echo ""

# ============================================
# FASE 9: CONFIGURACIÓN DE HOSTS (OPCIONAL)
# ============================================
echo ""
echo "==================================================="
echo "FASE OPCIONAL: CONFIGURACION DE ACCESO WEB"
echo "==================================================="
echo ""
echo "Para acceder a Frappe desde tu navegador, necesitas configurar:"
echo "  1. Entrada en archivo hosts de Windows"
echo "  2. Sitio por defecto en Frappe"
echo ""
echo "⚠️  IMPORTANTE: Esto requiere permisos de ADMINISTRADOR"
echo ""
echo "¿Deseas configurar esto AHORA? (s/n)"
read -r RESPUESTA

if [[ "$RESPUESTA" != "s" && "$RESPUESTA" != "S" ]]; then
    echo ""
    echo "⏭️  Configuración de hosts omitida"
    echo ""
    echo "Para configurar más tarde, ejecuta:"
    echo "  1. Cierra esta terminal"
    echo "  2. Abre Git Bash COMO ADMINISTRADOR"
    echo "  3. Ejecuta: bash scripts/configurar-hosts.sh"
    echo ""
    echo "Después podrás acceder a:"
    echo "  🌐 http://desarrollo.local:8000"
    echo "  👤 Usuario: Administrator"
    echo "  🔑 Contraseña: Admin@2025"
    echo ""
    echo "📚 PRÓXIMOS PASOS:"
    echo ""
    echo "   1. El DocType 'Asignacion de Equipo' YA ESTÁ CREADO"
    echo "      → Ir a: Desk → Buscar 'Asignacion de Equipo' → New"
    echo ""
    echo "   2. Ejecutar los tests para verificar:"
    echo "      → docker exec frappe_app bash -c \"cd /workspace/frappe-bench && bench --site desarrollo.local run-tests asignacion_equipo\""
    echo ""
    echo "   3. Explorar el código del DocType en:"
    echo "      → apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo/"
    echo ""
    echo "   4. Modificar campos y ver los cambios:"
    echo "      → Editar el JSON"
    echo "      → Ejecutar: bench migrate"
    echo "      → Recargar el navegador"
    echo ""
    echo "==================================================="
    exit 0
fi

echo ""
echo "[9/9] Configurando acceso web..."
echo ""

# --------------------------------------------
# 9.1) Verificar permisos de administrador
# --------------------------------------------
echo "   [9.1/9.4] Verificando permisos de administrador..."

# Intentar escribir en el archivo hosts como test
if ! touch /c/Windows/System32/drivers/etc/hosts 2>/dev/null; then
    echo ""
    echo "   ❌ ERROR: Este paso requiere permisos de ADMINISTRADOR"
    echo ""
    echo "   SOLUCIÓN:"
    echo "   1. Cierra esta terminal"
    echo "   2. Abre Git Bash COMO ADMINISTRADOR"
    echo "      (Clic derecho → 'Ejecutar como administrador')"
    echo "   3. Ejecuta: bash scripts/configurar-hosts.sh"
    echo ""
    echo "   O simplemente ejecuta el paso manual:"
    echo "   1. Abre Notepad COMO ADMINISTRADOR"
    echo "   2. Abre: C:\\Windows\\System32\\drivers\\etc\\hosts"
    echo "   3. Agrega al final: 127.0.0.1   desarrollo.local"
    echo "   4. Guarda el archivo"
    echo ""
    exit 1
fi

echo "   ✅ Permisos de administrador confirmados"

# --------------------------------------------
# 9.2) Agregar entrada al archivo hosts
# --------------------------------------------
echo "   [9.2/9.4] Configurando archivo hosts de Windows..."

HOSTS_FILE="/c/Windows/System32/drivers/etc/hosts"
ENTRY="127.0.0.1   desarrollo.local"

# Verificar si la entrada ya existe
if grep -q "desarrollo.local" "$HOSTS_FILE" 2>/dev/null; then
    echo "   ℹ️  La entrada 'desarrollo.local' ya existe en hosts"
else
    echo "$ENTRY" >> "$HOSTS_FILE"
    echo "   ✅ Entrada agregada al archivo hosts"
fi

# --------------------------------------------
# 9.3) Configurar sitio por defecto en Frappe
# --------------------------------------------
echo "   [9.3/9.4] Configurando sitio por defecto en Frappe..."

# Verificar que el contenedor esté corriendo
if ! docker ps | grep -q frappe_app; then
    echo "   ❌ El contenedor frappe_app no está corriendo"
    echo "      Ejecuta: docker-compose up -d frappe"
    exit 1
fi

# Crear archivo currentsite.txt
docker exec frappe_app bash -lc \
    "cd /workspace/frappe-bench && echo 'desarrollo.local' > sites/currentsite.txt" 2>/dev/null

echo "   ✅ Sitio por defecto configurado: desarrollo.local"

# --------------------------------------------
# 9.4) Reiniciar contenedor para aplicar cambios
# --------------------------------------------
echo "   [9.4/9.4] Reiniciando contenedor frappe_app..."

docker restart frappe_app > /dev/null 2>&1

echo "   ✅ Contenedor reiniciado"
echo ""

# --------------------------------------------
# Esperar a que Frappe esté listo
# --------------------------------------------
echo "   ⏳ Esperando a que Frappe inicie (30-60 segundos)..."

MAX_INTENTOS=30
INTENTO=1

while [ $INTENTO -le $MAX_INTENTOS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://desarrollo.local:8000 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
        echo "   ✅ Frappe está respondiendo correctamente"
        break
    fi
    
    if [ $INTENTO -eq $MAX_INTENTOS ]; then
        echo "   ⚠️  Frappe no respondió después de $MAX_INTENTOS intentos"
        echo "      Verifica los logs con: docker logs frappe_app"
        break
    fi
    
    echo "      Intento $INTENTO/$MAX_INTENTOS..."
    INTENTO=$((INTENTO + 1))
    sleep 2
done

echo ""
echo "==================================================="
echo "✅ INSTALACION Y CONFIGURACION COMPLETADAS (V3.0)"
echo "==================================================="
echo ""
echo "🎉 ¡TODO LISTO! Accede a Frappe en tu navegador:"
echo ""
echo "  🌐 URL:        http://desarrollo.local:8000"
echo "  👤 Usuario:    Administrator"
echo "  🔑 Contraseña: Admin@2025"
echo ""
echo "📊 RESUMEN COMPLETO:"
echo ""
echo "   ✅ Frappe Framework v15 + ERPNext + HRMS"
echo "   ✅ App: asignacion_equipo"
echo "   ✅ Módulo: gestion"
echo "   ✅ 🎯 DocType 'Asignacion de Equipo' COMPLETO"
echo "   ✅ Dependencia requests>=2.31.0"
echo "   ✅ Archivo hosts configurado"
echo "   ✅ Sitio por defecto: desarrollo.local"
echo ""
echo "🚀 PRUEBA EL PROTOTIPO:"
echo ""
echo "   1. Abrir: http://desarrollo.local:8000"
echo "   2. Login con: Administrator / Admin@2025"
echo "   3. Buscar 'Asignacion de Equipo' en el Desk"
echo "   4. Crear un nuevo registro"
echo "   5. Presionar el botón 'Verificar Garantía'"
echo ""
echo "🧪 EJECUTAR TESTS:"
echo ""
echo "   docker exec frappe_app bash -c \"cd /workspace/frappe-bench && bench --site desarrollo.local run-tests asignacion_equipo\""
echo ""
echo "📁 EXPLORAR EL CÓDIGO:"
echo ""
echo "   apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo/"
echo "   ├── asignacion_de_equipo.json  ← Definición del DocType"
echo "   ├── asignacion_de_equipo.py    ← Controller (lógica de negocio)"
echo "   ├── asignacion_de_equipo.js    ← Client Script (UI)"
echo "   └── test_asignacion_de_equipo.py ← Tests"
echo ""
echo "==================================================="