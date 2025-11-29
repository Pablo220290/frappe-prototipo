#!/bin/bash
# ============================================
# Script de Configuración Inicial
# ============================================
# Objetivo:
#   - Limpiar instalación previa
#   - Levantar MariaDB + Redis (via docker-compose)
#   - Inicializar bench + sitio desarrollo.local
#   - Crear módulo "gestion"
#   - Crear DocType automáticamente con todos los campos
#   - Levantar el contenedor frappe_app con bench start
#   - Configurar hosts de Windows (opcional)
# ============================================

set -euo pipefail

echo "==================================================="
echo "CONFIGURACION FRAPPE - PROTOTIPO DIDACTICO"
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
echo "[1/9] Validando prerequisitos..."

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
# 3) Limpiar instalación previa
# --------------------------------------------
echo "[2/9] Limpiando instalación previa..."

docker-compose down -v 2>/dev/null || true

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
echo "[3/9] Iniciando servicios de base de datos..."

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
echo "[4/9] Inicializando Frappe Bench y sitio 'desarrollo.local'..."
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
# 6) Crear app personalizada asignacion_equipo (SIN bench new-app)
# --------------------------------------------
echo "[5/9] Creando app personalizada 'asignacion_equipo'..."

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace/frappe-bench/apps
        
        APP_NAME="asignacion_equipo"
        
        echo ">>> Creando estructura de la app manualmente..."
        
        mkdir -p ${APP_NAME}/${APP_NAME}
        
        # __init__.py raíz
        cat > ${APP_NAME}/${APP_NAME}/__init__.py << "INITPY"
__version__ = "0.0.1"
INITPY
        
        # hooks.py
        cat > ${APP_NAME}/${APP_NAME}/hooks.py << "HOOKS"
app_name = "asignacion_equipo"
app_title = "Asignacion Equipo"
app_publisher = "Equipo Desarrollo"
app_description = "App para gestión de asignación de equipos a empleados"
app_email = "dev@empresa.com"
app_license = "MIT"
HOOKS
        
        # modules.txt vacío
        touch ${APP_NAME}/${APP_NAME}/modules.txt
        
        # patches.txt vacío
        touch ${APP_NAME}/${APP_NAME}/patches.txt
        
        # __init__.py del paquete principal
        touch ${APP_NAME}/__init__.py
        
        # setup.py mínimo
        cat > ${APP_NAME}/setup.py << "SETUP"
from setuptools import setup, find_packages
setup(
    name="asignacion_equipo",
    version="0.0.1",
    packages=find_packages(),
    zip_safe=False,
    include_package_data=True,
)
SETUP
        
        echo ">>> Verificando estructura creada..."
        ls -la ${APP_NAME}/
        ls -la ${APP_NAME}/${APP_NAME}/
        
        echo "✅ App asignacion_equipo creada manualmente"
    '

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error al crear la app asignacion_equipo"
    exit 1
fi

echo "✅ App asignacion_equipo creada"
echo ""

# --------------------------------------------
# 7) Instalar dependencias y configurar app
# --------------------------------------------
echo "[6/9] Configurando app asignacion_equipo..."

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace/frappe-bench
        
        echo ">>> Paso 7.0: Creando README.md de la app..."
        cat > apps/asignacion_equipo/README.md << "README_APP"
# Asignacion Equipo

App para gestión de asignación de equipos a empleados.

## Características
- Vinculación con módulo Employee (HRMS)
- Verificación de garantías vía API REST
- Validaciones de número de serie
README_APP

        echo ">>> Paso 7.1: Creando pyproject.toml con requests..."
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
        echo ">>> Paso 7.2: Instalando dependencias de asignacion_equipo..."
        cd apps/asignacion_equipo
        pip install -e . --break-system-packages
        cd ../..
        
        echo ""
        echo ">>> Paso 7.3: Verificando instalación de requests..."
        python3 -c "import requests; print(f\"✅ requests {requests.__version__} instalado correctamente\")" || {
            echo "❌ Error al instalar requests"
            exit 1
        }
        
        echo ""
        echo ">>> Paso 7.4: Instalando asignacion_equipo en el sitio..."
        bench --site desarrollo.local install-app asignacion_equipo
    '

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error al configurar la app"
    exit 1
fi

echo ""
echo "✅ App configurada correctamente"
echo ""

# --------------------------------------------
# 8) Crear módulo "gestion"
# --------------------------------------------
echo "[7/9] Creando módulo 'gestion' en asignacion_equipo..."

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

# --------------------------------------------
# 9) Crear DocType 'Asignacion de Equipo'
# --------------------------------------------
echo "[8/9] Creando DocType 'Asignacion de Equipo' automáticamente..."
echo "    (Esta es la fase clave del prototipo didáctico)"
echo ""

docker-compose run --rm \
    frappe \
    bash -lc '
        set -e
        cd /workspace/frappe-bench
        
        echo ">>> Paso 9.1: Creando estructura de directorios del DocType..."
        DOCTYPE_PATH="apps/asignacion_equipo/asignacion_equipo/gestion/doctype/asignacion_de_equipo"
        mkdir -p "$DOCTYPE_PATH"
        
        echo ">>> Paso 9.2: Creando __init__.py del DocType..."
        touch "$DOCTYPE_PATH/__init__.py"
        
        echo ">>> Paso 9.3: Creando asignacion_de_equipo.json (DEFINICIÓN DEL DOCTYPE)..."
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
        echo ">>> Paso 9.4: Verificando que el JSON es válido..."
        python3 -c "import json; json.load(open(\"$DOCTYPE_PATH/asignacion_de_equipo.json\"))" && \
            echo "✅ JSON válido" || { echo "❌ JSON inválido"; exit 1; }
        
        echo ""
        echo ">>> Paso 9.5: Sincronizando DocType con la base de datos..."
        bench --site desarrollo.local migrate
        
        echo ""
        echo ">>> Paso 9.6: Verificando que el DocType existe en la base de datos..."
        bench --site desarrollo.local console << "PYTHON_CHECK"
import frappe
frappe.init(site="desarrollo.local")
frappe.connect()

if frappe.db.exists("DocType", "Asignacion de Equipo"):
    print("✅ DocType Asignacion de Equipo creado exitosamente en la base de datos")
    meta = frappe.get_meta("Asignacion de Equipo")
    campos_criticos = ["empleado", "numero_serie", "tipo_equipo", "fecha_asignacion", "estado"]
    
    for campo in campos_criticos:
        if meta.has_field(campo):
            print(f"  ✅ Campo {campo} existe")
        else:
            print(f"  ❌ Campo {campo} NO existe")
            raise Exception(f"Campo crítico {campo} no encontrado")
    
    print("")
    print("🎉 TODOS LOS CAMPOS CRÍTICOS VERIFICADOS")
else:
    raise Exception("❌ DocType Asignacion de Equipo NO fue creado")

frappe.destroy()
PYTHON_CHECK
        
        if [ $? -ne 0 ]; then
            echo ""
            echo "❌ ERROR: El DocType no se creó correctamente"
            exit 1
        fi
        
        echo ""
        echo ">>> Paso 9.7: Verificando estructura completa del DocType..."
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
# 10) Levantar servidor Frappe
# --------------------------------------------
echo "[9/9] Levantando servidor Frappe..."

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
# Validación final
# --------------------------------------------
echo "==================================================="
echo "VALIDANDO INSTALACIÓN"
echo "==================================================="

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
echo " ✅ INSTALACION COMPLETADA"
echo "==================================================="
echo ""
echo "📊 RESUMEN DE LO INSTALADO:"
echo ""
echo "   ✅ Frappe Framework v15"
echo "   ✅ ERPNext v15"
echo "   ✅ HRMS v15"
echo "   ✅ App personalizada: asignacion_equipo"
echo "   ✅ Módulo: gestion"
echo "   ✅ DocType 'Asignacion de Equipo' completo y funcional"
echo "   ✅ Dependencia requests>=2.31.0 instalada"
echo ""
echo "📚 PRÓXIMOS PASOS:"
echo ""
echo "   1. Copiar archivos del DocType desde el repositorio:"
echo "      → asignacion_de_equipo.py (Controller)"
echo "      → asignacion_de_equipo.js (Client Script)"
echo "      → test_asignacion_de_equipo.py (Tests)"
echo ""
echo "   2. Acceder a Frappe:"
echo "      → http://localhost:8000"
echo "      → Usuario: Administrator"
echo "      → Contraseña: Admin@2025"
echo ""
echo "   3. Buscar 'Asignacion de Equipo' y crear un registro de prueba"
echo ""
echo "==================================================="