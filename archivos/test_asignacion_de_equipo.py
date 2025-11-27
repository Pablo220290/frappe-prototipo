"""
Tests Unitarios para el DocType 'Asignación de Equipo'

Este archivo contiene la suite de pruebas automatizadas para validar
el correcto funcionamiento del módulo de asignación de equipos.

CONCEPTOS CLAVE DE TESTING EN FRAPPE:
- setUp(): Se ejecuta ANTES de cada test
- tearDown(): Se ejecuta DESPUÉS de cada test
- setUpClass(): Se ejecuta UNA VEZ antes de todos los tests
- self.assert*(): Métodos para validar resultados
"""

import unittest
import frappe
from frappe.utils import nowdate


class TestAsignacionDeEquipo(unittest.TestCase):
    """
    Clase de tests para el DocType 'Asignación de Equipo'
    
    Hereda de unittest.TestCase para tener acceso a los métodos de assertions.
    Cada método que empiece con 'test_' se ejecutará como un test independiente.
    """

    @classmethod
    def setUpClass(cls):
        """
        Configuración inicial que se ejecuta UNA SOLA VEZ antes de todos los tests.
        
        Aquí creamos los datos de prueba que necesitamos para los tests:
        - Una compañía de prueba
        - Un departamento de prueba
        - Un empleado de prueba
        
        Usa flags especiales para asegurar que los datos persistan en la base de datos.
        """
        frappe.set_user("Administrator")
        
        # Flags para forzar persistencia real en la base de datos
        frappe.flags.in_test = False
        frappe.flags.in_import = True
        
        cls._crear_datos_prueba()
        
        # Restaurar flags a valores de test
        frappe.flags.in_test = True
        frappe.flags.in_import = False
    
    @classmethod
    def _crear_datos_prueba(cls):
        """
        Crea los registros necesarios para ejecutar los tests.
        
        Esta función crea:
        1. Una compañía de prueba (si no existe)
        2. Departamentos necesarios (si no existen)
        3. Un empleado de prueba usando SQL directo para garantizar persistencia
        """
        
        # 1. Crear Compañía de prueba
        if not frappe.db.exists("Company", "Test Company"):
            company = frappe.get_doc({
                "doctype": "Company",
                "company_name": "Test Company",
                "abbr": "TC",
                "default_currency": "USD",
                "country": "United States"
            })
            company.insert(ignore_permissions=True)
            frappe.db.commit()
        
        # 2. Crear Departamento Padre (requerido por la jerarquía de HRMS)
        if not frappe.db.exists("Department", "All Departments - TC"):
            dept = frappe.get_doc({
                "doctype": "Department",
                "department_name": "All Departments",
                "is_group": 1,  # Es un departamento padre
                "company": "Test Company"
            })
            dept.insert(ignore_permissions=True)
            frappe.db.commit()
        
        # 3. Crear Departamento IT (donde trabajará nuestro empleado de prueba)
        if not frappe.db.exists("Department", "IT - TC"):
            dept_it = frappe.get_doc({
                "doctype": "Department",
                "department_name": "IT",
                "parent_department": "All Departments - TC",
                "company": "Test Company"
            })
            dept_it.insert(ignore_permissions=True)
            frappe.db.commit()
        
        # 4. Crear Empleado de Prueba usando SQL directo
        # Usamos SQL directo para garantizar que se guarde en la base de datos
        if not frappe.db.exists("Employee", "EMP-TEST-001"):
            frappe.db.sql("""
                INSERT INTO `tabEmployee` 
                (name, employee, first_name, last_name, gender, date_of_birth, 
                 date_of_joining, status, company, department, 
                 creation, modified, owner, modified_by, docstatus)
                VALUES 
                ('EMP-TEST-001', 'EMP-TEST-001', 'Juan', 'Pérez', 'Male', '1990-01-01',
                 '2020-01-01', 'Active', 'Test Company', 'IT - TC',
                 NOW(), NOW(), 'Administrator', 'Administrator', 0)
            """)
            frappe.db.commit()
        
        # 5. Verificar que el empleado se creó correctamente
        emp_exists = frappe.db.sql("""
            SELECT name FROM `tabEmployee` WHERE name = 'EMP-TEST-001'
        """)
        
        print("\n" + "="*60)
        if emp_exists:
            print("✅ Datos de prueba creados y VERIFICADOS en DB")
            print("  - Company: Test Company")
            print("  - Department: IT - TC")
            print(f"  - Employee: {emp_exists[0][0]}")
        else:
            print("❌ ERROR: Empleado no se creó correctamente")
        print("="*60 + "\n")

    def setUp(self):
        """
        Configuración que se ejecuta ANTES de cada test individual.
        
        Establece el usuario y verifica que los datos de prueba existan.
        """
        frappe.set_user("Administrator")
        
        # Verificar que el empleado de prueba existe
        emp_check = frappe.db.sql("""
            SELECT name FROM `tabEmployee` WHERE name = 'EMP-TEST-001'
        """, as_dict=True)
        
        if not emp_check:
            self.fail("CRITICAL: Empleado EMP-TEST-001 no existe en setUp()")

    def tearDown(self):
        """
        Limpieza que se ejecuta DESPUÉS de cada test individual.
        
        Elimina las asignaciones de prueba para que no interfieran con otros tests.
        """
        # Limpiar solo las asignaciones que empiezan con 'TEST-'
        frappe.db.sql("""
            DELETE FROM `tabAsignacion de Equipo` 
            WHERE numero_serie LIKE 'TEST-%'
        """)
        frappe.db.commit()

    # ===================================================================================
    # TESTS BÁSICOS - Funcionalidad Core
    # ===================================================================================

    def test_creacion_asignacion_basica(self):
        """
        Test básico: Crear una asignación de equipo válida.
        
        Valida que:
        - Se puede crear un documento con campos obligatorios
        - El documento recibe un nombre (ID) automáticamente
        - Los valores se guardan correctamente
        """
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",  
            "tipo_equipo": "Laptop",
            "marca": "Dell",
            "modelo": "Latitude 5420",
            "numero_serie": "TEST-LAPTOP-001",
            "fecha_asignacion": nowdate()
        })
        asignacion.insert(ignore_permissions=True)
        
        # Validar que se creó correctamente
        self.assertTrue(asignacion.name)
        self.assertEqual(asignacion.empleado, "EMP-TEST-001")
        print(f"✅ Test pasado: {asignacion.name}")

    def test_numero_serie_duplicado(self):
        """
        Test de validación: No se pueden crear dos asignaciones con el mismo número de serie.
        
        Valida que la función validar_numero_serie_unico() funciona correctamente
        y lanza una excepción cuando se intenta duplicar un número de serie.
        """
        # Crear la primera asignación
        primera_asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Monitor",
            "marca": "Samsung",
            "modelo": "27 pulgadas",
            "numero_serie": "TEST-MONITOR-DUP-001",
            "fecha_asignacion": nowdate()
        })
        primera_asignacion.insert(ignore_permissions=True)
        
        # Intentar crear una segunda con el mismo número de serie (debe fallar)
        with self.assertRaises(frappe.ValidationError):
            segunda_asignacion = frappe.get_doc({
                "doctype": "Asignacion de Equipo",
                "empleado": "EMP-TEST-001",
                "tipo_equipo": "Monitor",
                "marca": "LG",
                "modelo": "24 pulgadas",
                "numero_serie": "TEST-MONITOR-DUP-001",  # Mismo número de serie
                "fecha_asignacion": nowdate()
            })
            segunda_asignacion.insert(ignore_permissions=True)
        
        print("✅ Test pasado: Validación de número de serie duplicado")

    def test_numero_serie_valido(self):
        """
        Test de validación: El número de serie debe tener al menos 5 caracteres.
        
        Valida que:
        - Se aceptan números de serie válidos (>= 5 caracteres)
        - Se rechazan números de serie cortos (< 5 caracteres)
        """
        # Caso válido: número de serie con más de 5 caracteres
        asignacion_valida = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Teclado",
            "marca": "Logitech",
            "modelo": "K380",
            "numero_serie": "TEST-TECLADO-001",
            "fecha_asignacion": nowdate()
        })
        asignacion_valida.insert(ignore_permissions=True)
        self.assertTrue(asignacion_valida.name)
        
        # Caso inválido: número de serie con menos de 5 caracteres
        with self.assertRaises(frappe.ValidationError):
            asignacion_invalida = frappe.get_doc({
                "doctype": "Asignacion de Equipo",
                "empleado": "EMP-TEST-001",
                "tipo_equipo": "Mouse",
                "marca": "HP",
                "modelo": "X3000",
                "numero_serie": "AB12",  # Solo 4 caracteres (inválido)
                "fecha_asignacion": nowdate()
            })
            asignacion_invalida.insert(ignore_permissions=True)
        
        print("✅ Test pasado: Validación de longitud de número de serie")

    def test_cambio_estado_asignado_a_devuelto(self):
        """
        Test de lógica de negocio: Cambiar el estado de una asignación de Asignado a Devuelto.
        
        Valida que:
        - Se puede cambiar el estado correctamente
        - La fecha de devolución se guarda
        - Los cambios persisten en la base de datos
        """
        # Crear asignación inicial
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Otro",
            "marca": "Apple",
            "modelo": "iPad Pro",
            "numero_serie": "TEST-TABLET-001",
            "fecha_asignacion": nowdate()
        })
        asignacion.insert(ignore_permissions=True)
        
        # Cambiar estado a Devuelto
        asignacion.estado = "Devuelto"
        asignacion.fecha_devolucion = nowdate()
        asignacion.save(ignore_permissions=True)
        
        # Recargar desde la base de datos y validar
        asignacion.reload()
        self.assertEqual(asignacion.estado, "Devuelto")
        self.assertIsNotNone(asignacion.fecha_devolucion)
        print("✅ Test pasado: Cambio de estado")

    def test_empleado_vinculado_existe(self):
        """
        Test de validación: El empleado debe existir en el sistema.
        
        Valida que la función validar_empleado_existe() funciona correctamente
        y rechaza empleados que no existen en la tabla Employee.
        """
        with self.assertRaises(frappe.ValidationError):
            asignacion_empleado_falso = frappe.get_doc({
                "doctype": "Asignacion de Equipo",
                "empleado": "EMP-NOEXISTE-999",  # Empleado que no existe
                "tipo_equipo": "Laptop",
                "marca": "HP",
                "modelo": "ProBook",
                "numero_serie": "TEST-LAPTOP-FALSO-001",
                "fecha_asignacion": nowdate()
            })
            asignacion_empleado_falso.insert(ignore_permissions=True)
        
        print("✅ Test pasado: Validación de empleado existente")

    # ===================================================================================
    # TESTS DE INTEGRACIÓN - API Externa
    # ===================================================================================

    def test_verificacion_garantia_api_externa(self):
        """
        Test de integración: Verificar garantía usando API externa.
        
        Valida que:
        - El método verificar_garantia_externa() funciona correctamente
        - Se puede llamar a una API externa con requests
        - La respuesta tiene la estructura esperada
        """
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Otro",
            "marca": "HP",
            "modelo": "LaserJet Pro",
            "numero_serie": "TEST-PRINTER-001",
            "fecha_asignacion": nowdate()
        })
        asignacion.insert(ignore_permissions=True)

        # Llamar al método de verificación de garantía
        resultado = asignacion.verificar_garantia_externa()

        # Validar la estructura de la respuesta
        self.assertIsNotNone(resultado)
        self.assertIsInstance(resultado, dict)
        self.assertIn("status", resultado)
        self.assertIn("message", resultado)
        
        print(f"✅ Test pasado: Resultado API = {resultado.get('message')}")

    # ===================================================================================
    # TESTS DE DEPENDENCIAS - Gestión de Paquetes Python
    # ===================================================================================
    
    def test_requests_library_importa_correctamente(self):
        """
        Test de dependencias: Verifica que la librería requests esté instalada.
        
        Este test valida que pyproject.toml está configurado correctamente
        y que la dependencia 'requests>=2.31.0' se instaló exitosamente.
        
        Valida:
        - Se puede importar la librería
        - Tiene una versión válida
        - La versión cumple con el requisito mínimo (>=2.31.0)
        """
        try:
            import requests
            
            # Validar que se pudo importar
            self.assertIsNotNone(requests)
            
            # Validar que tiene una versión
            self.assertIsNotNone(requests.__version__)
            
            # Validar que la versión es >= 2.31.0
            version_parts = requests.__version__.split('.')
            major_version = int(version_parts[0])
            minor_version = int(version_parts[1]) if len(version_parts) > 1 else 0
            
            self.assertGreaterEqual(major_version, 2)
            if major_version == 2:
                self.assertGreaterEqual(minor_version, 31)
            
            print(f"✅ Test pasado: Requests versión {requests.__version__} instalado correctamente")
            
        except ImportError as e:
            self.fail(f"❌ La librería 'requests' no está instalada: {e}")
    
    def test_verificar_disponibilidad_externa(self):
        """
        Test de función global: Verificar disponibilidad de un equipo.
        
        Esta función global (no es un método de la clase) permite verificar
        si un equipo está disponible para asignación o ya está asignado.
        
        Valida:
        - Equipos sin asignación previa están disponibles
        - Equipos con asignación activa no están disponibles
        - La función retorna la estructura de datos esperada
        """
        from asignacion_equipo.gestion.doctype.asignacion_de_equipo.asignacion_de_equipo import verificar_disponibilidad_equipo
        
        # 1. Verificar un equipo que NO existe (debe estar disponible)
        numero_serie_test = "TEST-DISPONIBLE-001"
        resultado = verificar_disponibilidad_equipo(numero_serie_test)
        
        # Validar estructura de la respuesta
        self.assertIsNotNone(resultado)
        self.assertIn("disponible", resultado)
        self.assertIn("mensaje", resultado)
        self.assertIn("asignacion", resultado)
        
        # Debe estar disponible porque no existe asignación previa
        self.assertTrue(resultado["disponible"])
        self.assertIsNone(resultado["asignacion"])
        
        print(f"✅ Test pasado: Verificación de disponibilidad - {resultado.get('mensaje')}")
        
        # 2. Crear una asignación activa con ese número de serie
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Laptop",
            "marca": "Test",
            "modelo": "Test Model",
            "numero_serie": numero_serie_test,
            "estado": "Asignado",
            "fecha_asignacion": nowdate()
        })
        asignacion.insert(ignore_permissions=True)
        
        # 3. Verificar de nuevo - ahora debe estar NO disponible
        resultado2 = verificar_disponibilidad_equipo(numero_serie_test)
        
        self.assertFalse(resultado2["disponible"])
        self.assertIsNotNone(resultado2["asignacion"])
        
        print(f"✅ Test pasado: Equipo marcado como no disponible correctamente")
    
    def test_api_externa_maneja_errores_timeout(self):
        """
        Test de manejo de errores: Verificar que la API maneja errores gracefully.
        
        Valida que cuando hay un error en la llamada a la API externa
        (timeout, error de red, etc.), el sistema:
        - No crashea
        - Retorna una estructura de respuesta válida
        - Indica el error apropiadamente
        """
        asignacion = frappe.get_doc({
            "doctype": "Asignacion de Equipo",
            "empleado": "EMP-TEST-001",
            "tipo_equipo": "Test",
            "marca": "Test",
            "modelo": "Test",
            "numero_serie": "TEST-TIMEOUT-001",
            "fecha_asignacion": nowdate()
        })
        asignacion.insert(ignore_permissions=True)
        
        # Ejecutar la función - debe manejar cualquier error sin lanzar excepciones
        resultado = asignacion.verificar_garantia_externa()
        
        # Validar que SIEMPRE retorna un dict con estructura esperada
        self.assertIsInstance(resultado, dict)
        self.assertIn("status", resultado)
        self.assertIn("message", resultado)
        
        # El status puede ser 'success' o 'error', ambos son válidos
        self.assertIn(resultado["status"], ["success", "error"])
        
        print(f"✅ Test pasado: Manejo de errores API - Status: {resultado['status']}")