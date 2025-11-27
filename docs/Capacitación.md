# Guía de Capacitación: Framework Frappe

## Sesión Intensiva de 3-4 Horas

---

## 📋 Información General

**Duración Total**: 3-4 horas (incluye descansos)  
**Nivel**: Junior a Intermedio en Python  
**Prerequisitos**: Conocimientos básicos de Python, Git y Docker  
**Formato**: Presencial o remoto con pantalla compartida

---

## 🎯 Objetivos de Aprendizaje

Al finalizar esta capacitación, los participantes podrán:

1. ✅ Explicar qué es Frappe Framework y cuándo usarlo
2. ✅ Crear un DocType personalizado desde cero
3. ✅ Implementar validaciones en cliente y servidor
4. ✅ Integrar servicios externos (APIs REST)
5. ✅ Escribir y ejecutar pruebas unitarias
6. ✅ Gestionar dependencias Python en Frappe
7. ✅ Depurar problemas comunes

---

## 📅 Agenda Detallada

### Módulo 1: Introducción y Conceptos (45 min)

- Presentación del proyecto y objetivos
- ¿Qué es Frappe Framework?
- Arquitectura de la solución
- Tour por el código del prototipo

### Módulo 2: Hands-On con DocTypes (60 min)

- Anatomía de un DocType
- Crear un DocType desde la UI
- Implementar lógica en el Controller
- Validaciones y lifecycle hooks

**🕐 Descanso (15 min)**

### Módulo 3: Integraciones y Client Scripts (45 min)

- Client Scripts en JavaScript
- Llamadas a APIs externas con requests
- Gestión de dependencias con pyproject.toml
- Depuración de errores

### Módulo 4: Testing y Mejores Prácticas (45 min)

- Escribir pruebas unitarias
- Ejecutar y depurar tests
- Patrones de código recomendados
- Comandos útiles de bench

### Módulo 5: Q&A y Ejercicio Práctico (30 min)

- Sesión de preguntas y respuestas
- Ejercicio guiado: Modificar el prototipo
- Próximos pasos y recursos

---

## 🎓 Módulo 1: Introducción y Conceptos (45 min)

### 1.1 Presentación (10 min)

**Mensaje de Bienvenida**:

"Bienvenidos a esta capacitación sobre Frappe Framework. Este no es un curso tradicional donde solo verán slides. Van a tener acceso a un código real, funcional y bien documentado que podrán usar como base para sus propios proyectos."

**Dinámica de la Sesión**:

- Interactiva: Pregunten en cualquier momento
- Práctica: Veremos código real, no teoría abstracta
- Didáctica: Cada decisión técnica tiene una explicación

### 1.2 ¿Qué es Frappe Framework? (15 min)

**Definición Simple**:

> Frappe es un framework full-stack en Python para crear aplicaciones empresariales. Piensen en él como "Django + Admin + REST API + Permisos + Auditoría" todo en uno.

**Casos de Uso Principales**:

- ✅ Sistemas ERP (Enterprise Resource Planning)
- ✅ CRM (Customer Relationship Management)
- ✅ HRMS (Human Resource Management System)
- ✅ Aplicaciones de gestión interna
- ❌ E-commerce con UI personalizada
- ❌ Landing pages y sitios de marketing
- ❌ Aplicaciones móviles nativas

**Componentes Clave**:

```
Frappe Framework
├── Backend (Python)
│   ├── ORM (Object-Relational Mapping)
│   ├── REST API (auto-generada)
│   └── Sistema de permisos
├── Frontend (JavaScript + Jinja)
│   ├── UI generada automáticamente
│   └── Client Scripts personalizables
└── Infraestructura
    ├── Job Queue (Redis)
    ├── Scheduler (Cron jobs)
    └── WebSocket (Real-time)
```

**Mostrar Diapositiva/Diagrama**: Arquitectura de 3 capas

### 1.3 Arquitectura de Nuestro Prototipo (10 min)

**Diagrama en Pizarra/Pantalla**:

```
┌─────────────────────────────────────────┐
│  Frontend (Navegador)                   │
│  ├── asignacion_de_equipo.js           │
│  └── UI Auto-generada por Frappe       │
└─────────────┬───────────────────────────┘
              │ HTTP/JSON
┌─────────────▼───────────────────────────┐
│  Backend (Python)                       │
│  ├── asignacion_de_equipo.py           │
│  │   ├── validate()                    │
│  │   ├── verificar_garantia()         │
│  │   └── validaciones custom          │
│  └── tests                             │
└─────────────┬───────────────────────────┘
              │ SQL
┌─────────────▼───────────────────────────┐
│  Base de Datos (MariaDB)                │
│  ├── Tabla: tabAsignacion de Equipo    │
│  └── Tabla: tabEmployee (HRMS)         │
└─────────────────────────────────────────┘
```

**Recorrer el Código en Vivo**:

```bash
# Mostrar estructura de directorios
tree apps/asignacion_equipo -L 3

# Explicar cada carpeta:
# - gestion/ : Módulo de negocio
# - doctype/ : Nuestros "modelos" o "entidades"
# - hooks.py : Configuración global
```

### 1.4 Tour por el Prototipo (10 min)

**Demo en Vivo** (http://desarrollo.local:8000):

1. **Login** como Administrator
2. **Navegar** a: Módulo "Gestion" > "Asignación de Equipo"
3. **Crear** una nueva asignación:

   - Seleccionar empleado
   - Tipo de equipo: Laptop
   - Número de serie: DEMO-001
   - Guardar

4. **Mostrar validaciones**:

   - Intentar guardar sin empleado → Error
   - Intentar número de serie duplicado → Error
   - Intentar número de serie inválido (< 3 chars) → Error

5. **Botón "Verificar Garantía"**:
   - Clic → Llamada a API → Mensaje de éxito

**Preguntas al Grupo**:

- "¿Qué les pareció la interfaz?"
- "¿Alguien notó algo particular en las validaciones?"

---

## 🛠️ Módulo 2: Hands-On con DocTypes (60 min)

### 2.1 Anatomía de un DocType (15 min)

**Concepto Clave**:

> Un DocType es la unidad fundamental en Frappe. Define TANTO la estructura de datos como el comportamiento.

**Los 3 Archivos de un DocType**:

| Archivo | Propósito                      | Se ejecuta en       |
| ------- | ------------------------------ | ------------------- |
| `.json` | Definición de campos, permisos | Servidor (metadata) |
| `.py`   | Lógica de negocio              | Servidor            |
| `.js`   | Interacciones UI               | Cliente (navegador) |

**Abrir en Editor**: `asignacion_de_equipo.json`

```json
{
  "fields": [
    {
      "fieldname": "empleado",
      "fieldtype": "Link", // ⭐ Crea relación FK
      "options": "Employee", // ⭐ Vincula a DocType Employee
      "label": "Empleado",
      "reqd": 1 // ⭐ Campo obligatorio
    },
    {
      "fieldname": "numero_serie",
      "fieldtype": "Data", // ⭐ Texto corto
      "label": "Número de Serie",
      "unique": 1, // ⭐ Valor único en BD
      "reqd": 1
    }
  ]
}
```

**Ejercicio en Grupo** (5 min):
"Si quisieran agregar un campo 'Valor de Compra' (número decimal), ¿cómo lo definirían?"

**Respuesta Esperada**:

```json
{
  "fieldname": "valor_compra",
  "fieldtype": "Currency",
  "label": "Valor de Compra",
  "reqd": 0
}
```

### 2.2 Crear un DocType desde la UI (20 min)

**Demo Paso a Paso**:

1. **Navegar** a: DocType List (barra de búsqueda: "DocType List")

2. **Nuevo DocType**:

   - Nombre: "Mantenimiento de Equipo"
   - Módulo: Gestion
   - Es Submittable: No
   - Tiene Workflow: No

3. **Agregar Campos**:

   ```
   Campo 1:
   - Label: Asignación
   - Type: Link
   - Options: Asignacion de Equipo
   - Required: Sí

   Campo 2:
   - Label: Fecha de Mantenimiento
   - Type: Date
   - Required: Sí

   Campo 3:
   - Label: Tipo de Mantenimiento
   - Type: Select
   - Options:
     Preventivo
     Correctivo
     Garantía

   Campo 4:
   - Label: Descripción
   - Type: Text Editor
   ```

4. **Guardar** el DocType

5. **Probar** crear un registro:
   - Ir a: Gestion > Mantenimiento de Equipo > Nuevo
   - Llenar campos
   - Guardar

**Punto de Aprendizaje**:
"Acaban de crear una tabla en la BD, un formulario, y una API REST sin escribir una sola línea de código. Esa es la potencia de Frappe."

### 2.3 Implementar Lógica en el Controller (15 min)

**Abrir en Editor**: `asignacion_de_equipo.py`

**Explicar el Patrón MVC en Frappe**:

```python
from frappe.model.document import Document

class AsignacionDeEquipo(Document):
    """
    Controller para el DocType 'Asignacion de Equipo'.
    Hereda de Document para tener acceso a métodos del ORM.
    """

    def validate(self):
        """
        Se ejecuta ANTES de guardar (INSERT/UPDATE).
        Aquí van todas las validaciones de negocio.
        """
        self.validar_numero_serie_unico()
        self.validar_formato_numero_serie()
        self.validar_empleado_activo()
```

**Analizar Validación de Unicidad**:

```python
def validar_numero_serie_unico(self):
    """Valida que el número de serie sea único en el sistema."""

    # 1. Buscar si existe otro documento con el mismo número de serie
    existing = frappe.db.exists(
        "Asignacion de Equipo",  # Nombre del DocType
        {
            "numero_serie": self.numero_serie,
            "name": ["!=", self.name]  # Excluir el documento actual
        }
    )

    # 2. Si existe, lanzar excepción
    if existing:
        frappe.throw(
            f"El número de serie {self.numero_serie} ya existe",
            frappe.DuplicateEntryError
        )
```

**Preguntas al Grupo**:

1. "¿Por qué es importante `["!=", self.name]`?"
2. "¿Qué pasa si no usamos `frappe.throw()`?"

### 2.4 Validaciones y Lifecycle Hooks (10 min)

**Explicar el Ciclo de Vida**:

```python
class AsignacionDeEquipo(Document):

    # ────────── ANTES DE GUARDAR ──────────

    def before_validate(self):
        """Preparar datos antes de validar"""
        pass

    def validate(self):
        """⭐ VALIDACIONES DE NEGOCIO"""
        self.validar_numero_serie_unico()

    def before_save(self):
        """Modificar datos justo antes de guardar"""
        pass

    # ────────── DESPUÉS DE GUARDAR ──────────

    def after_insert(self):
        """Solo en INSERT (documento nuevo)"""
        # Ejemplo: Enviar email de notificación
        pass

    def on_update(self):
        """En cada UPDATE"""
        pass

    # ────────── AL ELIMINAR ──────────

    def on_trash(self):
        """Antes de eliminar"""
        # Ejemplo: Validar que no tenga dependencias
        pass
```

**Ejercicio Rápido**:
"Si quisieran que al crear una asignación se envíe un email al empleado, ¿en qué método lo harían?"

**Respuesta**: `after_insert()`

---

## ☕ Descanso (15 min)

"Tomen un café, estiren las piernas. En 15 minutos continuamos con integraciones y JavaScript."

---

## 🌐 Módulo 3: Integraciones y Client Scripts (45 min)

### 3.1 Client Scripts en JavaScript (15 min)

**Concepto**:

> Los Client Scripts se ejecutan en el navegador y controlan la interacción con el usuario.

**Abrir en Editor**: `asignacion_de_equipo.js`

**Estructura Básica**:

```javascript
frappe.ui.form.on("Asignacion de Equipo", {
  // Se ejecuta cuando se carga/recarga el formulario
  refresh: function (frm) {
    configurar_botones(frm);
  },

  // Se ejecuta antes de guardar (validación cliente)
  validate: function (frm) {
    return validar_campos(frm);
  },

  // Se ejecuta cuando cambia el campo 'empleado'
  empleado: function (frm) {
    // Ejemplo: Cargar datos del empleado
    console.log("Empleado seleccionado:", frm.doc.empleado);
  },
});
```

**Demo: Agregar Validación en Cliente**:

```javascript
function validar_campos(frm) {
  // Validar longitud del número de serie
  if (frm.doc.numero_serie && frm.doc.numero_serie.length < 3) {
    frappe.msgprint({
      title: __("Error de Validación"),
      message: __("El número de serie debe tener al menos 3 caracteres"),
      indicator: "red",
    });

    // ⭐ Detener el guardado
    frappe.validated = false;
    return false;
  }

  return true;
}
```

**Mostrar en Navegador**:

1. Abrir una asignación
2. F12 → Console
3. Modificar número de serie a "AB"
4. Intentar guardar → Ver error

### 3.2 Llamadas a APIs Externas (20 min)

**Escenario**:

> "Necesitamos verificar la garantía de un equipo llamando a un servicio externo de nuestro proveedor."

**Paso 1: Instalar Dependencia `requests`**

**Explicar `pyproject.toml`**:

```toml
[project]
dependencies = [
    "frappe",
    "requests>=2.31.0"  # ⭐ Nuestra dependencia
]
```

**Instalar**:

```bash
bench --site desarrollo.local pip install requests>=2.31.0
```

**Paso 2: Método en Python**

```python
@frappe.whitelist()  # ⭐ CRÍTICO: Hace el método accesible desde JS
def verificar_garantia(self):
    """Verifica garantía con servicio externo."""

    try:
        import requests

        # Llamada GET a API externa (ejemplo con JSONPlaceholder)
        response = requests.get(
            f"https://jsonplaceholder.typicode.com/posts/1",
            timeout=5  # ⭐ Siempre usar timeout
        )

        if response.status_code == 200:
            data = response.json()
            return {
                "success": True,
                "message": f"Garantía válida. ID: {data.get('id')}"
            }
        else:
            return {
                "success": False,
                "message": f"Error HTTP: {response.status_code}"
            }

    except requests.exceptions.Timeout:
        frappe.throw("Timeout al conectar con servicio de garantías")

    except Exception as e:
        frappe.log_error(f"Error en verificar_garantia: {str(e)}")
        frappe.throw("Error al verificar garantía")
```

**Paso 3: Botón en JavaScript**

```javascript
function configurar_botones(frm) {
  // Solo mostrar si el documento ya existe
  if (!frm.is_new()) {
    frm.add_custom_button(
      __("Verificar Garantía"),
      function () {
        verificar_garantia_handler(frm);
      },
      __("Acciones") // Grupo opcional
    );
  }
}

function verificar_garantia_handler(frm) {
  // Mostrar indicador de carga
  frappe.show_alert(
    {
      message: __("Verificando garantía..."),
      indicator: "blue",
    },
    3
  );

  // Llamar método del servidor
  frappe.call({
    method: "verificar_garantia", // Nombre del método
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
      } else {
        frappe.show_alert(
          {
            message: "Error en la verificación",
            indicator: "red",
          },
          5
        );
      }
    },
  });
}
```

**Demo en Vivo**:

1. Sincronizar código: `./scripts/sync_archivos_a_docker.sh`
2. Reiniciar: `docker compose restart frappe`
3. Abrir asignación en navegador
4. Clic en "Verificar Garantía"
5. Ver mensaje de éxito

**Punto de Aprendizaje**:
"Acaban de ver una integración completa: Python + requests + JavaScript + UI. Este patrón se repite para cualquier integración externa."

### 3.3 Depuración de Errores (10 min)

**Técnicas de Debugging**:

**1. Logs en Python**:

```python
# En cualquier método del controller
import frappe

frappe.log("Mensaje de debug")
frappe.log_error("Mensaje de error", "Título del Error")

# Ver logs en archivo
# /workspace/development/sites/desarrollo.local/logs/web.log
```

**2. Console en JavaScript**:

```javascript
console.log("Valor del campo:", frm.doc.numero_serie);
console.table(frm.doc); // Mostrar todos los campos
debugger; // Breakpoint en navegador
```

**3. Consola de Frappe**:

```bash
docker exec -it frappe-bench-1 bench --site desarrollo.local console

# En la consola Python:
>>> import frappe
>>> doc = frappe.get_doc('Asignacion de Equipo', 'ACC-00001')
>>> print(doc.as_dict())
>>> doc.verificar_garantia()
```

**Demo**: Provocar un error y depurarlo.

---

## 🧪 Módulo 4: Testing y Mejores Prácticas (45 min)

### 4.1 Escribir Pruebas Unitarias (25 min)

**Filosofía de Testing**:

> "Un test no es solo para encontrar bugs. Es documentación ejecutable que demuestra cómo usar tu código."

**Estructura de un Test en Frappe**:

```python
import frappe
import unittest

class TestAsignacionDeEquipo(unittest.TestCase):

    def setUp(self):
        """Se ejecuta ANTES de cada test"""
        frappe.set_user("Administrator")

        # Crear datos de prueba
        self.empleado = frappe.get_doc({
            "doctype": "Employee",
            "first_name": "Test",
            "last_name": "User",
            "company": "_Test Company"
        }).insert()

    def tearDown(self):
        """Se ejecuta DESPUÉS de cada test"""
        frappe.db.rollback()  # ⭐ Deshace cambios

    def test_crear_asignacion_valida(self):
        """Test del caso feliz (happy path)"""
        # Arrange (Preparar)
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": self.empleado.name,
            "tipo_de_equipo": "Laptop",
            "numero_serie": "TEST-001"
        })

        # Act (Actuar)
        asignacion.insert()

        # Assert (Verificar)
        self.assertTrue(asignacion.name)
        self.assertEqual(asignacion.estado, "Activa")
```

**Analizar Test de Validación**:

```python
def test_validacion_numero_serie_unico(self):
    """Prueba que no se puedan crear dos asignaciones con el mismo número."""

    # Crear primera asignación
    asignacion1 = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": self.empleado.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "DUPLICADO-001"
    })
    asignacion1.insert()

    # Intentar crear segunda con mismo número
    asignacion2 = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": self.empleado.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "DUPLICADO-001"  # ⚠️ Mismo número
    })

    # Debe lanzar excepción DuplicateEntryError
    with self.assertRaises(frappe.DuplicateEntryError):
        asignacion2.insert()
```

**Ejercicio Guiado** (10 min):
"Vamos a escribir juntos un test para validar que no se pueda asignar un equipo a un empleado inactivo."

```python
def test_no_asignar_a_empleado_inactivo(self):
    """No se debe poder asignar equipo a empleado inactivo."""

    # Crear empleado inactivo
    empleado_inactivo = frappe.get_doc({
        "doctype": "Employee",
        "first_name": "Inactivo",
        "last_name": "Test",
        "status": "Inactive",  # ⭐ Estado inactivo
        "company": "_Test Company"
    }).insert()

    # Intentar crear asignación
    asignacion = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": empleado_inactivo.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "TEST-INACTIVE"
    })

    # Debe lanzar ValidationError
    with self.assertRaises(frappe.ValidationError):
        asignacion.insert()
```

### 4.2 Ejecutar y Depurar Tests (10 min)

**Comandos de Testing**:

```bash
# Ejecutar todos los tests de la app
bench --site desarrollo.local run-tests --app asignacion_equipo

# Ejecutar un módulo específico
bench --site desarrollo.local run-tests \
  --module asignacion_equipo.gestion.doctype.asignacion_de_equipo.test_asignacion_de_equipo

# Ejecutar un test específico
bench --site desarrollo.local run-tests \
  --test test_validacion_numero_serie_unico

# Modo verbose (ver más detalles)
bench --site desarrollo.local run-tests --app asignacion_equipo --verbose
```

**Interpretar Resultados**:

```
Ran 9 tests in 2.345s

OK  # ✅ Todos pasaron

─────────────────────────────────

FAILED (failures=1)  # ❌ Uno falló

FAIL: test_validacion_numero_serie_unico
AssertionError: DuplicateEntryError not raised
```

**Demo en Vivo**:

1. Ejecutar `./scripts/validate_phase4.sh`
2. Ver output de 9 tests
3. Provocar fallo (comentar validación)
4. Volver a ejecutar → Ver error
5. Restaurar código → Tests pasan

### 4.3 Mejores Prácticas (10 min)

**1. Nombrado de Variables y Funciones**:

```python
# ✅ BUENO: Descriptivo y claro
def validar_numero_serie_unico(self):
    numero_serie_existente = frappe.db.exists(...)

# ❌ MALO: Abreviaciones confusas
def val_num_ser(self):
    ns_ex = frappe.db.exists(...)
```

**2. Comentarios Útiles**:

```python
# ✅ BUENO: Explica el POR QUÉ
# Usamos timeout de 5s para evitar bloquear la UI si el servicio está caído
response = requests.get(url, timeout=5)

# ❌ MALO: Explica el QUÉ (obvio del código)
# Llama a get
response = requests.get(url)
```

**3. Manejo de Errores**:

```python
# ✅ BUENO: Específico y con logging
try:
    response = requests.get(url, timeout=5)
except requests.exceptions.Timeout:
    frappe.log_error("Timeout en API externa", "Verificar Garantía")
    frappe.throw("El servicio no responde. Intente más tarde.")
except requests.exceptions.RequestException as e:
    frappe.log_error(f"Error en request: {str(e)}")
    frappe.throw("Error de conexión")

# ❌ MALO: Catch genérico sin detalle
try:
    response = requests.get(url)
except:
    frappe.throw("Error")
```

**4. Uso de frappe.throw() vs raise**:

```python
# ✅ BUENO: frappe.throw() muestra mensaje al usuario
if not self.numero_serie:
    frappe.throw("El número de serie es obligatorio", frappe.MandatoryError)

# ❌ MALO: raise Exception no se muestra bien en UI
if not self.numero_serie:
    raise Exception("Error")
```

**5. Comandos de Desarrollo**:

```bash
# Después de modificar código Python/JS
./scripts/sync_archivos_a_docker.sh
docker compose restart frappe

# Después de modificar .json del DocType
bench --site desarrollo.local migrate

# Si algo no funciona (cache corrupto)
bench --site desarrollo.local clear-cache

# Ver logs en tiempo real
docker compose logs -f frappe
```

---

## 💡 Módulo 5: Q&A y Ejercicio Práctico (30 min)

### 5.1 Sesión de Preguntas (15 min)

**Preguntas Comunes**:

**Q1: "¿Cómo sé cuándo usar validación en cliente vs servidor?"**

**A**:

- **Cliente (JS)**: Validaciones simples de UX (longitud, formato visual)
- **Servidor (Python)**: Validaciones de negocio críticas (unicidad, permisos, cálculos)
- **Regla de oro**: SIEMPRE validar en servidor, el cliente es opcional

**Q2: "¿Cómo manejo transacciones en Frappe?"**

**A**:

```python
# Frappe maneja transacciones automáticamente
# Si un método lanza excepción, se hace ROLLBACK

def validate(self):
    # Si esto falla, no se guarda NADA
    self.validar_a()
    self.validar_b()
    # Todo o nada
```

**Q3: "¿Puedo usar async/await en Frappe?"**

**A**: Frappe usa arquitectura tradicional (no async). Para operaciones largas:

- Usa **Background Jobs** (Redis Queue)
- Usa **Webhooks** para callbacks

**Q4: "¿Cómo escalo Frappe en producción?"**

**A**:

- Múltiples workers de Gunicorn
- Redis para cache y queue
- Load balancer (Nginx)
- Separar DB en servidor dedicado

### 5.2 Ejercicio Práctico Guiado (15 min)

**Objetivo**: Agregar un campo calculado "Días de Uso" a nuestro DocType.

**Paso 1: Modificar el JSON**:

Ir a: DocType List > Asignacion de Equipo > Edit

Agregar campo:

```
Label: Días de Uso
Type: Int
Read Only: 1  (No editable)
```

**Paso 2: Implementar Cálculo en Python**:

```python
def before_save(self):
    """Calcular días de uso antes de guardar."""
    self.calcular_dias_uso()

def calcular_dias_uso(self):
    """Calcula días desde la fecha de asignación."""
    from datetime import date

    if self.fecha_asignacion:
        fecha_asig = self.fecha_asignacion
        if isinstance(fecha_asig, str):
            from frappe.utils import getdate
            fecha_asig = getdate(fecha_asig)

        dias = (date.today() - fecha_asig).days
        self.dias_uso = max(0, dias)  # No negativos
```

**Paso 3: Probar**:

1. Guardar cambios
2. Migrar: `bench --site desarrollo.local migrate`
3. Abrir una asignación
4. Modificar fecha de asignación a hace 30 días
5. Guardar
6. Ver que "Días de Uso" se calcula automáticamente

**Paso 4: Escribir Test**:

```python
def test_calcular_dias_uso(self):
    """Verifica que se calculen correctamente los días de uso."""
    from datetime import date, timedelta

    # Crear asignación con fecha hace 10 días
    fecha_hace_10_dias = date.today() - timedelta(days=10)

    asignacion = frappe.get_doc({
        "doctype": "Asignacion de Equipo",
        "empleado": self.empleado.name,
        "tipo_de_equipo": "Laptop",
        "numero_serie": "TEST-DIAS",
        "fecha_asignacion": fecha_hace_10_dias
    })
    asignacion.insert()

    # Verificar cálculo
    self.assertEqual(asignacion.dias_uso, 10)
```

---

## 📚 Recursos y Próximos Pasos

### Documentación

- **Este Prototipo**: Tu punto de partida
- **Documento Maestro**: Guía técnica completa
- **README**: Referencia rápida

### Comunidad y Soporte

- [Frappe Discuss](https://discuss.frappe.io/): Foro oficial
- [Frappe School](https://frappe.school/): Tutoriales en video
- [GitHub Frappe](https://github.com/frappe/frappe): Código fuente

### Plan de Aprendizaje Recomendado

**Semana 1-2**: Familiarización

- Explorar el prototipo
- Modificar validaciones existentes
- Ejecutar y entender los tests

**Semana 3-4**: Crear desde Cero

- Crear un DocType nuevo (ej: "Incidencia de Equipo")
- Implementar validaciones
- Escribir 3-5 tests

**Mes 2**: Integración

- Integrar con API externa real
- Crear un report personalizado
- Implementar un workflow

**Mes 3+**: Módulo Completo

- Diseñar módulo de RRHH completo
- Implementar con el equipo
- Poner en producción

---

## ✅ Checklist de Finalización

Al terminar esta capacitación, cada participante debe poder:

- [ ] Explicar qué es un DocType y sus componentes
- [ ] Crear un DocType desde la UI
- [ ] Implementar validaciones en `validate()`
- [ ] Escribir un Client Script con botones personalizados
- [ ] Hacer una llamada a API externa con `requests`
- [ ] Escribir y ejecutar un test unitario
- [ ] Depurar errores usando logs y console
- [ ] Sincronizar código con Docker
- [ ] Ejecutar migraciones después de cambios

---

## 📝 Formulario de Feedback

**Por favor completen antes de salir**:

1. ¿Qué concepto les resultó más difícil? (1-5)
2. ¿Qué parte fue más útil?
3. ¿Qué les gustaría profundizar en futuras sesiones?
4. Comentarios generales

---

## 🎉 Cierre

**Mensaje Final**:

"Han completado una capacitación intensiva de Frappe Framework. Ahora tienen:

✅ Un prototipo funcional que pueden usar como base  
✅ Conocimiento de los conceptos fundamentales  
✅ Herramientas para seguir aprendiendo

El verdadero aprendizaje viene de hacer. Su próximo paso es tomar este código, modificarlo, romperlo, arreglarlo. Así es como se vuelven expertos.

Recuerden: **Frappe no es perfecto, pero es poderoso**. Úsenlo para lo que está diseñado (aplicaciones empresariales) y les ahorrará meses de desarrollo.

¡Éxito en sus proyectos!"

---

**Materiales de Capacitación v1.0**  
**Enero 2025**  
**Consultor Senior Python/Frappe**
