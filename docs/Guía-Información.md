# Documento Maestro: Prototipo de Asignación de Equipos en Frappe

## 📑 Índice

1. [Introducción](#1-introducción)
2. [Instalación y Configuración](#2-instalación-y-configuración)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Conceptos Clave de Frappe](#4-conceptos-clave-de-frappe)
5. [Análisis del Código](#5-análisis-del-código)
6. [Pruebas Unitarias](#6-pruebas-unitarias)
7. [Evaluación de Frappe Framework](#7-evaluación-de-frappe-framework)
8. [Mejores Prácticas](#8-mejores-prácticas)

---

## 1. Introducción

### 1.1 Objetivo del Documento

Este documento es tu **guía** para entender Frappe Framework. Cada sección explica no solo el QUÉ, sino también el POR QUÉ y el CÓMO de cada decisión técnica.

### 1.2 ¿Qué es este Prototipo?

Un sistema ABM (Alta, Baja, Modificación) para gestionar la asignación de equipos tecnológicos a empleados, que incluye:

- ✅ Validaciones cliente y servidor
- ✅ Integración con API externa (requests)
- ✅ Vinculación con módulo HRMS
- ✅ Suite de 9 tests unitarios
- ✅ Código documentado y didáctico

### 1.3 Para Quién es este Documento

- **Desarrolladores Python**: Aprenderás los fundamentos de Frappe
- **Arquitectos de Software**: Evaluarás la viabilidad de Frappe para tu organización
- **Tech Leads**: Entenderás cómo estructurar proyectos en Frappe

---

## 2. Instalación y Configuración

### 2.1 Instalación en 3 Pasos

```bash
# Paso 1: Clonar el repositorio
git clone https://github.com/Pablo220290/frappe-prototipo.git
cd asignacion-equipos-frappe

# Paso 2: Dar permisos y ejecutar
chmod +x scripts/setup-inicial.sh
./scripts/setup-inicial.sh

# Paso 3: Acceder al sistema
# URL: http://desarrollo.local:8000
# Usuario: Administrator
# Contraseña: Admin@2025
```

⏱️ **Tiempo**: 45-60 minutos

### 2.2 ¿Qué Hace el Script de Instalación?

```bash
# 1. Configura /etc/hosts para dominio local
echo "127.0.0.1 desarrollo.local" >> /etc/hosts

# 2. Levanta contenedores Docker (MariaDB, Redis, Frappe)
docker compose up -d

# 3. Instala Frappe + ERPNext + HRMS
bench get-app erpnext --branch version-15
bench get-app hrms --branch version-15

# 4. Crea sitio y nuestra app
bench new-site desarrollo.local
bench get-app asignacion_equipo

# 5. Instala dependencias Python
bench --site desarrollo.local pip install requests>=2.31.0

# 6. Migra base de datos
bench --site desarrollo.local migrate
```

### 2.3 Arquitectura de Contenedores

```
┌─────────────────────────────────────────────┐
│ frappe-bench-1 (Contenedor Principal)      │
│ ┌─────────────────────────────────────┐   │
│ │ Frappe v15 + ERPNext + HRMS         │   │
│ │ ├── asignacion_equipo (nuestra app) │   │
│ │ ├── Python 3.10                     │   │
│ │ └── requests (dependencia)          │   │
│ └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
           ↓ conecta a ↓
┌──────────────────┐  ┌──────────────────┐
│ mariadb          │  │ redis-cache      │
│ Puerto: 3306     │  │ redis-queue      │
└──────────────────┘  └──────────────────┘
```

---

## 3. Arquitectura del Sistema

### 3.1 Estructura de Directorios

```
asignacion_equipo/                    # App personalizada
└── asignacion_equipo/                # Módulo Python
    ├── gestion/                      # Módulo de negocio
    │   └── doctype/                  # DocTypes personalizados
    │       └── asignacion_de_equipo/ # Nuestro DocType
    │           ├── asignacion_de_equipo.json  # Definición (metadata)
    │           ├── asignacion_de_equipo.py    # Lógica servidor
    │           ├── asignacion_de_equipo.js    # Lógica cliente
    │           └── test_asignacion_de_equipo.py # Tests
    ├── hooks.py                      # Configuración global
    └── pyproject.toml               # Dependencias Python
```

### 3.2 Flujo de una Solicitud en Frappe

```
Usuario hace clic en "Guardar"
         ↓
1. CLIENT SCRIPT (JS) - asignacion_de_equipo.js
   - Valida campos obligatorios
   - Valida formato número de serie
   - Muestra mensajes de error
         ↓
2. Si validación cliente OK → Envía a servidor
         ↓
3. SERVER CONTROLLER (Python) - asignacion_de_equipo.py
   - método validate()
   - Valida unicidad número de serie
   - Valida empleado activo
   - Guarda en base de datos
         ↓
4. Base de Datos (MariaDB)
   - Guarda registro
   - Actualiza índices
         ↓
5. Respuesta al Cliente
   - Éxito: Recarga documento
   - Error: Muestra mensaje
```

---

## 4. Conceptos Clave de Frappe

### 4.1 ¿Qué es un DocType?

Un **DocType** es como una "clase" que define tanto la **estructura de datos** (tabla) como la **lógica de negocio** (código Python).

**Analogía**: Si piensas en Django → Model + View + Form combinados en uno.

**Componentes de un DocType**:

| Archivo    | Propósito                                     | Lenguaje   |
| ---------- | --------------------------------------------- | ---------- |
| `.json`    | Define campos, permisos, comportamiento       | JSON       |
| `.py`      | Lógica de servidor (validaciones, cálculos)   | Python     |
| `.js`      | Lógica de cliente (UI, validaciones frontend) | JavaScript |
| `test_.py` | Pruebas unitarias                             | Python     |

### 4.2 Ciclo de Vida de un Documento

```python
# Estos métodos se ejecutan automáticamente:

class AsignacionDeEquipo(Document):
    def before_validate(self):
        # Se ejecuta ANTES de validar
        pass

    def validate(self):
        # ⭐ AQUÍ van tus validaciones de negocio
        self.validar_numero_serie_unico()
        self.validar_empleado_activo()

    def before_save(self):
        # Se ejecuta ANTES de guardar en BD
        pass

    def after_insert(self):
        # Se ejecuta DESPUÉS de crear (INSERT)
        pass

    def on_update(self):
        # Se ejecuta DESPUÉS de actualizar (UPDATE)
        pass

    def on_trash(self):
        # Se ejecuta al eliminar
        pass
```

### 4.3 Vinculación entre DocTypes (Link)

```json
{
  "fieldname": "empleado",
  "fieldtype": "Link",
  "options": "Employee",
  "label": "Empleado"
}
```

Esto crea una **relación de clave foránea** automáticamente:

- ✅ Selector con autocompletado
- ✅ Validación de existencia
- ✅ Restricción de integridad referencial

### 4.4 Permisos en Frappe

```json
{
  "permissions": [
    {
      "role": "System Manager",
      "read": 1,
      "write": 1,
      "create": 1,
      "delete": 1
    },
    {
      "role": "HR Manager",
      "read": 1,
      "write": 1,
      "create": 1
    }
  ]
}
```

---

## 5. Análisis del Código

### 5.1 Controller Backend (asignacion_de_equipo.py)

**Validación de Unicidad del Número de Serie**:

```python
def validar_numero_serie_unico(self):
    """Valida que el número de serie sea único en el sistema."""

    # Buscar si existe otro documento con el mismo número de serie
    existing = frappe.db.exists(
        "Asignacion de Equipo",
        {
            "numero_serie": self.numero_serie,
            "name": ["!=", self.name]  # Excluir el documento actual
        }
    )

    if existing:
        frappe.throw(
            f"El número de serie {self.numero_serie} ya existe",
            frappe.DuplicateEntryError
        )
```

**Validación de Formato**:

```python
def validar_formato_numero_serie(self):
    """Valida que el número de serie tenga formato alfanumérico."""

    import re

    # Patrón: 3-20 caracteres alfanuméricos con guiones opcionales
    patron = r'^[A-Za-z0-9\-]{3,20}$'

    if not re.match(patron, self.numero_serie):
        frappe.throw(
            "El número de serie debe ser alfanumérico (3-20 caracteres)",
            frappe.ValidationError
        )
```

**Integración con API Externa**:

```python
@frappe.whitelist()  # ⭐ Hace el método accesible desde cliente
def verificar_garantia(self):
    """Simula verificación de garantía con servicio externo."""

    try:
        import requests

        # Llamada a API de prueba
        response = requests.get(
            f"https://jsonplaceholder.typicode.com/posts/{self.numero_serie[:2]}",
            timeout=5
        )

        if response.status_code == 200:
            return {
                "success": True,
                "message": "Garantía verificada correctamente"
            }
        else:
            return {
                "success": False,
                "message": f"Error: {response.status_code}"
            }

    except requests.exceptions.Timeout:
        frappe.throw("Timeout al conectar con servicio de garantías")
    except Exception as e:
        frappe.log_error(f"Error verificación: {str(e)}")
        frappe.throw("Error al verificar garantía")
```

**Puntos clave**:

- `@frappe.whitelist()` es ESENCIAL para llamar desde JavaScript
- `timeout=5` evita que el request cuelgue la aplicación
- `frappe.log_error()` registra en logs sin detener ejecución
- Manejo de excepciones específicas (Timeout vs genérico)

### 5.2 Client Script (asignacion_de_equipo.js)

**Botón Personalizado**:

```javascript
frappe.ui.form.on("Asignacion de Equipo", {
  refresh: function (frm) {
    // Solo mostrar botón si el documento ya está guardado
    if (!frm.is_new()) {
      frm.add_custom_button(__("Verificar Garantía"), function () {
        verificar_garantia_handler(frm);
      });
    }
  },
});
```

**Handler del Botón**:

```javascript
function verificar_garantia_handler(frm) {
  // Llamada al método del servidor
  frappe.call({
    method: "verificar_garantia", // Método en Python
    doc: frm.doc, // Documento actual
    callback: function (r) {
      if (r.message && r.message.success) {
        frappe.show_alert(
          {
            message: r.message.message,
            indicator: "green",
          },
          5
        );
      }
    },
  });
}
```

**Validación en Cliente**:

```javascript
validate: function(frm) {
    // Validación antes de enviar al servidor
    if (!frm.doc.numero_serie || frm.doc.numero_serie.length < 3) {
        frappe.msgprint(__('Número de serie debe tener al menos 3 caracteres'));
        frappe.validated = false;  // Detiene el guardado
    }
}
```

---

## 6. Pruebas Unitarias

### 6.1 Estructura de un Test en Frappe

```python
import frappe
import unittest

class TestAsignacionDeEquipo(unittest.TestCase):
    def setUp(self):
        """Se ejecuta ANTES de cada test"""
        frappe.set_user("Administrator")

    def tearDown(self):
        """Se ejecuta DESPUÉS de cada test"""
        frappe.db.rollback()  # Deshace cambios

    def test_ejemplo(self):
        """Cada test debe empezar con 'test_'"""
        # Arrange (Preparar)
        doc = frappe.get_doc({...})

        # Act (Actuar)
        doc.insert()

        # Assert (Verificar)
        self.assertTrue(doc.name)
```

### 6.2 Tests Implementados

| Test                                    | Objetivo                  | Cobertura         |
| --------------------------------------- | ------------------------- | ----------------- |
| `test_crear_asignacion_valida`          | Crear asignación completa | Path              |
| `test_validacion_empleado_requerido`    | Campo obligatorio         | Validación        |
| `test_validacion_tipo_equipo_requerido` | Campo obligatorio         | Validación        |
| `test_validacion_numero_serie_unico`    | Unicidad                  | Validación        |
| `test_validacion_formato_numero_serie`  | Formato alfanumérico      | Validación        |
| `test_vinculacion_con_employee`         | Link a HRMS               | Integración       |
| `test_estados_validos`                  | Transiciones de estado    | Lógica de negocio |
| `test_verificar_garantia_success`       | API externa OK            | Integración       |
| `test_verificar_garantia_timeout`       | API timeout               | Manejo de errores |

### 6.3 Ejemplo de Test: Número de Serie Único

```python
def test_validacion_numero_serie_unico(self):
    """Prueba que no se puedan crear dos asignaciones con el mismo número de serie."""

    # Crear primera asignación
    asignacion1 = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": self.empleado.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "TEST-12345"
    })
    asignacion1.insert()

    # Intentar crear segunda con mismo número de serie
    asignacion2 = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": self.empleado.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "TEST-12345"  # ⚠️ Duplicado
    })

    # Debe lanzar excepción
    with self.assertRaises(frappe.DuplicateEntryError):
        asignacion2.insert()
```

### 6.4 Ejecutar Tests

```bash
# Todos los tests
bench --site desarrollo.local run-tests --app asignacion_equipo

# Un test específico
bench --site desarrollo.local run-tests \
  --app asignacion_equipo \
  --test test_validacion_numero_serie_unico
```

---

## 7. Evaluación de Frappe Framework

### 7.1 Ventajas ✅

| Aspecto                 | Beneficio                       | Impacto                   |
| ----------------------- | ------------------------------- | ------------------------- |
| **Productividad**       | ABM automático, UI generada     | -70% tiempo desarrollo    |
| **Gestión de Permisos** | Sistema robusto incluido        | -80% código de seguridad  |
| **Auditoría**           | Logging automático de cambios   | Compliance out-of-the-box |
| **APIs REST**           | Endpoints auto-generados        | -90% código de API        |
| **Migraciones**         | Sistema de versiones automático | Cero errores de deploy    |
| **Modularidad**         | Apps independientes             | Fácil mantenimiento       |

### 7.2 Desventajas ⚠️

| Aspecto                  | Limitación                             | Mitigación                            |
| ------------------------ | -------------------------------------- | ------------------------------------- |
| **Curva de aprendizaje** | Conceptos específicos (DocType, hooks) | Este prototipo didáctico              |
| **Documentación**        | A veces desactualizada                 | Comunidad activa en Discuss           |
| **Debugging**            | Stack trace complejo                   | Usar `frappe.log()` liberalmente      |
| **Performance**          | ORM puede ser lento en volúmenes altos | Usar SQL directo cuando sea necesario |
| **Flexibilidad UI**      | Limitado a la estructura de Frappe     | Usar React/Vue para UIs custom        |

### 7.3 ¿Cuándo Usar Frappe?

**✅ SÍ usar Frappe cuando**:

- Necesitas aplicaciones de gestión empresarial (ERP, CRM, HRMS)
- Requieres ABM con permisos y auditoría
- El equipo tiene experiencia Python (o está dispuesto a aprender)
- Tienes recursos para desplegar en servidor (no es serverless)

**❌ NO usar Frappe cuando**:

- Necesitas UI altamente personalizada (e-commerce, landing pages)
- El proyecto es predominantemente frontend
- Requieres arquitectura serverless/microservicios
- Performance extremo es crítico (>10M registros)

---

## 8. Mejores Prácticas

### 8.1 Código Python

```python
# ✅ HACER
def validar_campo(self):
    """Docstring claro explicando qué hace."""
    if not self.campo:
        frappe.throw("Mensaje descriptivo", frappe.ValidationError)

# ❌ EVITAR
def val(self):
    if not self.campo: raise Exception("Error")
```

### 8.2 Client Scripts

```javascript
// ✅ HACER
frappe.ui.form.on('DocType', {
    refresh: function(frm) {
        // Lógica clara y separada en funciones
        configurar_botones(frm);
    }
});

// ❌ EVITAR
frappe.ui.form.on('DocType', {
    refresh: function(frm) {
        // Todo el código aquí sin organizar
        if(!frm.is_new()){frm.add_custom_button(...)}
    }
});
```

### 8.3 Tests

```python
# ✅ HACER
def test_validacion_especifica(self):
    """Test enfocado en UN comportamiento."""
    doc = self.crear_documento_test()
    with self.assertRaises(frappe.ValidationError):
        doc.insert()

# ❌ EVITAR
def test_todo(self):
    """Test que prueba 10 cosas a la vez."""
    # Código confuso que hace demasiado
```

### 8.4 Gestión de Dependencias

```toml
# pyproject.toml - SIEMPRE especificar versión mínima
[project]
dependencies = [
    "requests>=2.31.0",  # ✅ Versión específica
    "pandas",             # ❌ Sin versión = problemas
]
```

### 8.5 Comandos Esenciales

```bash
# Desarrollo diario
bench --site desarrollo.local migrate       # Después de cambiar .json
bench --site desarrollo.local clear-cache   # Si algo no funciona
bench --site desarrollo.local console       # Depurar en consola Python

# Producción
bench --site produccion backup              # Backup antes de deploy
bench --site produccion migrate             # Aplicar cambios
bench restart                               # Reiniciar servicios
```

---

## 9. Recursos Adicionales

| Recurso        | URL                      | Uso                 |
| -------------- | ------------------------ | ------------------- |
| Docs Oficiales | frappeframework.com/docs | Referencia completa |
| Foro Comunidad | discuss.frappe.io        | Resolver dudas      |
| Código Frappe  | github.com/frappe/frappe | Ver implementación  |

---

**Fecha**: Noviembre 2025  
**Versión**: 1.0
