# Prototipo Didáctico: Sistema de Asignación de Equipos en Frappe

![Frappe](https://img.shields.io/badge/Frappe-v15-blue)
![Python](https://img.shields.io/badge/Python-3.10+-green)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Características Principales](#-características-principales)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación Rápida](#-instalación-rápida)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Uso del Sistema](#-uso-del-sistema)
- [Ejecución de Pruebas](#-ejecución-de-pruebas)
- [Documentación Adicional](#-documentación-adicional)
- [Soporte y Contacto](#-soporte-y-contacto)

---

## 🎯 Descripción del Proyecto

Este es un **prototipo didáctico** desarrollado para demostrar las capacidades del Framework Frappe aplicadas a la gestión de Recursos Humanos. El proyecto implementa un módulo completo de **Asignación de Equipos** que permite:

- Vincular equipos tecnológicos (laptops, teléfonos, tablets) a empleados
- Gestionar el ciclo de vida completo de las asignaciones (ABM)
- Integrar servicios externos mediante APIs REST
- Validar datos tanto en cliente como en servidor
- Mantener un historial de cambios y estados

### 🎓 Propósito Educativo

Este proyecto ha sido diseñado específicamente como **material de referencia** para equipos que desean:

1. Aprender los conceptos fundamentales de Frappe Framework
2. Entender las mejores prácticas de desarrollo en Python
3. Implementar integraciones con APIs externas
4. Escribir pruebas unitarias efectivas
5. Configurar entornos de desarrollo profesionales con Docker

---

## ✨ Características Principales

### Funcionalidades del Sistema

- ✅ **Gestión de Asignaciones**: CRUD completo para asignaciones de equipos
- 🔗 **Integración con HRMS**: Vinculación directa con el módulo de empleados de Frappe
- 🌐 **Llamadas a API Externa**: Verificación de garantías mediante servicio web REST
- 🛡️ **Validaciones Robustas**: Validación en cliente y servidor con mensajes claros
- 📊 **Estados de Workflow**: Control de estados (Activa, Devuelta, Extraviada, Dañada)
- 🔍 **Búsquedas Inteligentes**: Filtros y búsquedas optimizadas
- 📝 **Auditoría Completa**: Registro automático de todos los cambios

### Características Técnicas

- 🐳 **Dockerizado**: Entorno completamente contenerizado y reproducible
- 🧪 **Tests Unitarios**: Suite completa de 9 pruebas unitarias
- 📦 **Gestión de Dependencias**: Uso de `pyproject.toml` para dependencias Python
- 🎨 **UI Profesional**: Interfaz limpia y responsive
- 📚 **Código Documentado**: Comentarios explicativos en español
- 🔒 **Seguridad**: Validaciones de permisos y datos sensibles

---

## 📦 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

### Software Requerido

| Software       | Versión Mínima | Verificación             |
| -------------- | -------------- | ------------------------ |
| Docker         | 20.10+         | `docker --version`       |
| Docker Compose | 2.0+           | `docker compose version` |
| Git            | 2.30+          | `git --version`          |

### Requisitos del Sistema

- **RAM**: Mínimo 8GB (recomendado 16GB)
- **Disco**: 20GB de espacio libre
- **CPU**: 4 cores recomendado
- **OS**: Linux, macOS, o Windows con WSL2

### Puertos Requeridos

El sistema utiliza los siguientes puertos (deben estar disponibles):

- `8000`: Frappe (Frontend)
- `9000`: Frappe (Socket.IO)
- `3306`: MariaDB
- `6379`: Redis Cache
- `6380`: Redis Queue

---

## 🚀 Instalación Rápida

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/Pablo220290/frappe-prototipo.git
cd asignacion-equipos-frappe
```

### Paso 2: Configurar el Entorno

```bash
# Dar permisos de ejecución al script de instalación
chmod +x scripts/setup-inicial.sh

# Ejecutar el script de instalación automatizada
./scripts/setup-inicial.sh
```

Este script realizará automáticamente:

- ✅ Configuración de `/etc/hosts`
- ✅ Construcción de contenedores Docker
- ✅ Instalación de Frappe, ERPNext y HRMS
- ✅ Creación del sitio `desarrollo.local`
- ✅ Instalación de la aplicación personalizada
- ✅ Instalación de dependencias Python (`requests`)
- ✅ Migración de base de datos
- ✅ Creación de usuario administrador

⏱️ **Tiempo estimado**: 45-60 minutos

### Paso 3: Acceder al Sistema

Una vez completada la instalación:

```
URL: http://desarrollo.local:8000
Usuario: Administrator
Contraseña: Admin@2025
```

---

## 📁 Estructura del Proyecto

```
asignacion-equipos-frappe/
├── frappe_docker/                  # Configuración Docker
│   ├── compose.yaml               # Definición de servicios
│   └── development/               # Archivos de desarrollo
│
├── apps/                          # Aplicaciones Frappe
│   └── asignacion_equipo/        # Nuestra app personalizada
│       ├── asignacion_equipo/    # Módulo principal
│       │   ├── gestion/          # Módulo de gestión
│       │   │   ├── doctype/      # DocTypes
│       │   │   │   └── asignacion_de_equipo/
│       │   │   │       ├── asignacion_de_equipo.py      # Controller (Backend)
│       │   │   │       ├── asignacion_de_equipo.js      # Client Script (Frontend)
│       │   │   │       ├── asignacion_de_equipo.json    # Definición del DocType
│       │   │   │       └── test_asignacion_de_equipo.py # Tests Unitarios
│       │   │   └── __init__.py
│       │   ├── hooks.py          # Configuración de hooks
│       │   └── __init__.py
│       ├── pyproject.toml        # Dependencias Python
│       └── setup.py              # Setup de la aplicación
│
├── scripts/                       # Scripts de automatización
│   ├── setup-inicial.sh       # Instalación completa
│   ├── sync_archivos_a_docker.sh # Sincronización de código
│   ├── validar_tests.sh        # Validación de dependencias
│   └── limpiar-todo.sh          # Limpieza del entorno
│
├── docs/                          # Documentación
│   └── Guía-Información.md      # Guía técnica completa
│
└── README.md                      # Este archivo
```

---

## 🎮 Uso del Sistema

### Crear una Nueva Asignación

1. **Navegar al módulo**:

   - Ir a: `Gestion > Asignación de Equipo > Nuevo`

2. **Completar los datos obligatorios**:

   - **Empleado**: Seleccionar del listado
   - **Tipo de Equipo**: Laptop, Teléfono o Tablet
   - **Número de Serie**: Alfanumérico único
   - **Fecha de Asignación**: Por defecto la fecha actual

3. **Datos opcionales**:

   - Marca y Modelo del equipo
   - Notas adicionales

4. **Guardar**: El sistema validará automáticamente:
   - ✅ Número de serie único
   - ✅ Formato válido del número de serie
   - ✅ Empleado activo en el sistema
   - ✅ Todos los campos obligatorios completos

### Verificar Garantía (Integración con API)

1. Abrir una asignación existente
2. Hacer clic en el botón **"Verificar Garantía"**
3. El sistema:
   - Llamará a una API externa (JSONPlaceholder)
   - Mostrará un mensaje de éxito o error
   - Registrará la verificación en los logs

### Cambiar Estado de una Asignación

Los estados disponibles son:

- **Activa**: El equipo está en uso por el empleado
- **Devuelta**: El equipo fue devuelto
- **Extraviada**: El equipo se ha perdido
- **Dañada**: El equipo tiene daños

Para cambiar el estado:

1. Abrir la asignación
2. Modificar el campo "Estado"
3. Guardar (se validará la transición)

---

## 🧪 Ejecución de Pruebas

### Suite Completa de Tests

El proyecto incluye **9 pruebas unitarias** que cubren:

- ✅ Creación de asignaciones válidas
- ✅ Validaciones de campos obligatorios
- ✅ Validaciones de unicidad (número de serie)
- ✅ Validaciones de formato
- ✅ Transiciones de estado
- ✅ Integración con API externa

### Ejecutar Todas las Pruebas

```bash
# Desde el host
./scripts/validar_tests.sh

# O manualmente dentro del contenedor
docker exec -it frappe-bench-1 bash
cd /workspace/development/apps/asignacion_equipo
bench --site desarrollo.local run-tests --app asignacion_equipo
```

### Ejecutar una Prueba Específica

```bash
docker exec -it frappe-bench-1 bash
cd /workspace/development/apps/asignacion_equipo
bench --site desarrollo.local run-tests \
  --app asignacion_equipo \
  --module asignacion_equipo.gestion.doctype.asignacion_de_equipo.test_asignacion_de_equipo \
  --test test_crear_asignacion_valida
```

### Interpretar Resultados

```
✅ OK: Prueba pasó correctamente
❌ FAIL: La prueba falló (se muestra el error)
⚠️  ERROR: Error en la ejecución de la prueba
```

---

## 📚 Documentación Adicional

### Documentos Disponibles

| Documento                                         | Descripción                                     | Audiencia       |
| ------------------------------------------------- | ----------------------------------------------- | --------------- |
| [`Guía-Información.md`](docs/Guía-Información.md) | Guía Informativa del Proyecto                   | Todo el equipo  |
| [`README.md`](README.md)                          | Vista general del proyecto e instalación rápida | Nuevos usuarios |

### Recursos Externos

- [Documentación Oficial de Frappe](https://frappeframework.com/docs)
- [Documentación de Frappe HR](https://docs.erpnext.com/docs/user/manual/en/human-resources)
- [API Reference de Frappe](https://frappeframework.com/docs/user/en/api)
- [Guía de Python para Frappe](https://frappeframework.com/docs/user/en/python-api)

---

## 🛠️ Comandos Útiles

### Gestión del Entorno

```bash
# Iniciar los servicios
docker compose -f frappe_docker/compose.yaml up -d

# Detener los servicios
docker compose -f frappe_docker/compose.yaml down

# Ver logs en tiempo real
docker compose -f frappe_docker/compose.yaml logs -f frappe

# Reiniciar un servicio específico
docker compose -f frappe_docker/compose.yaml restart frappe

# Acceder al contenedor de Frappe
docker exec -it frappe-bench-1 bash
```

### Desarrollo

```bash
# Sincronizar cambios de código (después de modificar archivos)
./scripts/sync_archivos_a_docker.sh

# Ejecutar migraciones después de cambios en DocTypes
docker exec -it frappe-bench-1 bench --site desarrollo.local migrate

# Ver logs de errores
docker exec -it frappe-bench-1 tail -f /workspace/development/sites/desarrollo.local/logs/web.error.log

# Limpiar caché
docker exec -it frappe-bench-1 bench --site desarrollo.local clear-cache
```

### Base de Datos

```bash
# Hacer backup de la base de datos
docker exec -it frappe-bench-1 bench --site desarrollo.local backup

# Acceder a la consola de MariaDB
docker exec -it mariadb bash
mysql -u root -p123
use _a19bb9a7e67f4daa;
```

### Limpieza Completa

```bash
# ⚠️ ADVERTENCIA: Esto eliminará TODOS los datos
./scripts/limpiar-todo.sh
```

---

## 🔧 Solución de Problemas

### El sitio no carga (Error 502/404)

```bash
# Verificar que todos los servicios están corriendo
docker compose -f frappe_docker/compose.yaml ps

# Reiniciar el servicio de Frappe
docker compose -f frappe_docker/compose.yaml restart frappe

# Verificar logs de error
docker compose -f frappe_docker/compose.yaml logs frappe
```

### Error "Site desarrollo.local does not exist"

```bash
# Verificar sitios disponibles
docker exec -it frappe-bench-1 bench --site desarrollo.local list-sites

# Si no existe, ejecutar setup-inicial.sh nuevamente
./scripts/setup-inicial.sh
```

### Los tests fallan

```bash
# Limpiar caché y ejecutar nuevamente
docker exec -it frappe-bench-1 bench --site desarrollo.local clear-cache
docker exec -it frappe-bench-1 bench --site desarrollo.local migrate
./scripts/validar_tests.sh
```

### Cambios en el código no se reflejan

```bash
# Sincronizar archivos y reiniciar
./scripts/sync_archivos_a_docker.sh
docker compose -f frappe_docker/compose.yaml restart frappe
docker exec -it frappe-bench-1 bench --site desarrollo.local clear-cache
```

---

## 📅 Historial de Versiones

| Versión | Fecha   | Cambios                       |
| ------- | ------- | ----------------------------- |
| 1.0.0   | 2025-11 | Release inicial del prototipo |

---

```bash
./scripts/setup-inicial.sh
```

Y en 60 minutos tendrás un entorno completo funcionando.
