"""
Controller para el DocType 'Asignación de Equipo'

Este archivo contiene la lógica de negocio del lado del servidor (backend).
Todas las validaciones y cálculos se ejecutan en Python antes de guardar en la base de datos.
"""

import frappe
from frappe import _
from frappe.model.document import Document
from frappe.utils import nowdate, getdate, add_days
import requests


class AsignaciondeEquipo(Document):
    """
    Clase Controller para el DocType 'Asignación de Equipo'
    
    Esta clase hereda de Document y define el comportamiento del DocType.
    Los métodos especiales (validate, before_save, etc.) se ejecutan automáticamente
    en momentos específicos del ciclo de vida del documento.
    """
    
    def validate(self):
        """
        Método que se ejecuta ANTES de guardar el documento.
        
        Aquí van todas las validaciones de negocio.
        Si alguna validación falla, se lanza una excepción y el guardado se cancela.
        """
        self.validar_empleado_existe()
        self.validar_numero_serie()
        self.validar_numero_serie_unico()
        self.validar_fechas()
        self.establecer_valores_por_defecto()

    def validar_empleado_existe(self):
        """
        Valida que el empleado exista en el sistema.
        
        Verifica en la tabla Employee si el empleado seleccionado existe.
        Si no existe, lanza una excepción de tipo ValidationError.
        """
        if self.empleado and not frappe.db.exists("Employee", self.empleado):
            frappe.throw(
                _("El empleado {0} no existe en el sistema").format(self.empleado),
                exc=frappe.ValidationError
            )

    def before_save(self):
        """
        Método que se ejecuta justo ANTES de guardar en la base de datos.
        
        Útil para normalizar datos o hacer transformaciones automáticas.
        """
        # Convertir número de serie a mayúsculas para mantener consistencia
        if self.numero_serie:
            self.numero_serie = self.numero_serie.upper()
        
    def validar_numero_serie(self):
        """
        Valida que el número de serie cumpla con el formato requerido.
        
        Reglas:
        - No puede estar vacío
        - No puede contener solo espacios
        - Debe tener al menos 5 caracteres
        """
        if not self.numero_serie:
            frappe.throw(_("El Número de Serie es obligatorio"))

        if self.numero_serie.strip() == "":
            frappe.throw(
                _("El Número de Serie no puede contener solo espacios"),
                title=_("Número de Serie Inválido")
            )

        if len(self.numero_serie.strip()) < 5:
            frappe.throw(
                _("El Número de Serie debe tener al menos 5 caracteres."),
                exc=frappe.ValidationError
            )
    
    def validar_numero_serie_unico(self):
        """
        Valida que el número de serie sea único en el sistema.
        
        Busca en la base de datos si existe otro documento con el mismo número de serie.
        Excluye el documento actual (si está en modo edición) y los documentos cancelados.
        """
        filtros = {
            "numero_serie": self.numero_serie,
            "docstatus": ["<", 2]  # Excluir documentos cancelados (docstatus = 2)
        }
        
        # Si estamos editando (no es nuevo), excluir el documento actual de la búsqueda
        if not self.is_new():
            filtros["name"] = ["!=", self.name]
        
        if frappe.db.exists("Asignacion de Equipo", filtros):
            frappe.throw(
                _("El Número de Serie ya existe"),
                exc=frappe.ValidationError
            )
    
    def validar_fechas(self):
        """
        Valida la coherencia de las fechas del documento.
        
        Reglas:
        - La fecha de asignación no puede ser futura
        - La fecha de devolución debe ser posterior a la fecha de asignación
        - Si el estado es "Devuelto", debe tener fecha de devolución
        """
        # Validar que la fecha de asignación no sea futura
        if self.fecha_asignacion:
            if getdate(self.fecha_asignacion) > getdate(nowdate()):
                frappe.throw(
                    _("La Fecha de Asignación no puede ser mayor a la fecha actual."),
                    title=_("Fecha Inválida")
                )
        
        # Validar que la fecha de devolución sea posterior a la asignación
        if self.fecha_devolucion and self.fecha_asignacion:
            if getdate(self.fecha_devolucion) < getdate(self.fecha_asignacion):
                frappe.throw(
                    _("La Fecha de Devolución no puede ser anterior a la Fecha de Asignación."),
                    title=_("Fechas Incoherentes")
                )
        
        # Si el estado es "Devuelto", validar que tenga fecha de devolución
        estado_actual = getattr(self, 'estado', None)
        if estado_actual == "Devuelto" and not self.fecha_devolucion:
            frappe.throw(
                _("Debe especificar la Fecha de Devolución para equipos en estado 'Devuelto'."),
                title=_("Fecha de Devolución Requerida")
            )
    
    def establecer_valores_por_defecto(self):
        """
        Establece valores por defecto para campos opcionales.
        
        Si ciertos campos están vacíos, se establecen valores automáticos:
        - fecha_asignacion: fecha actual
        - estado: "Asignado"
        - fecha_devolucion: fecha actual (solo si el estado es "Devuelto")
        """
        if not self.fecha_asignacion:
            self.fecha_asignacion = nowdate()
        
        if not getattr(self, 'estado', None):
            self.estado = "Asignado"
        
        if self.estado == "Devuelto" and not self.fecha_devolucion:
            self.fecha_devolucion = nowdate()
    
    def calcular_dias_asignacion(self):
        """
        Calcula los días que el equipo ha estado asignado.
        
        Returns:
            int: Número de días entre la fecha de asignación y la fecha de devolución
                 (o la fecha actual si no se ha devuelto)
        """
        if not self.fecha_asignacion:
            return 0
        
        fecha_inicio = getdate(self.fecha_asignacion)
        
        # Si tiene fecha de devolución, calcular hasta esa fecha
        if self.fecha_devolucion:
            fecha_fin = getdate(self.fecha_devolucion)
        else:
            # Si no, calcular hasta hoy
            fecha_fin = getdate(nowdate())
        
        dias = (fecha_fin - fecha_inicio).days
        return dias if dias >= 0 else 0
    
    def esta_en_garantia(self, dias_garantia=365):
        """
        Verifica si el equipo todavía está en garantía.
        
        Args:
            dias_garantia (int): Duración de la garantía en días. Por defecto 365 (1 año).
        
        Returns:
            bool: True si está en garantía, False si no
        """
        if not self.fecha_asignacion:
            return False
        
        fecha_asignacion = getdate(self.fecha_asignacion)
        fecha_vencimiento_garantia = add_days(fecha_asignacion, dias_garantia)
        fecha_hoy = getdate(nowdate())
        
        return fecha_hoy <= fecha_vencimiento_garantia

    @frappe.whitelist()
    def verificar_garantia_externa(self):
        """
        Verifica la garantía del equipo llamando a una API externa.
        
        Este método puede ser llamado desde el cliente (JavaScript) mediante frappe.call().
        El decorador @frappe.whitelist() permite que sea accesible desde el navegador.
        
        Returns:
            dict: Diccionario con el resultado de la verificación:
                - status: "success" o "error"
                - message: Mensaje descriptivo
                - data: Información de la garantía (si es exitoso)
        """
        if not self.numero_serie:
            return {
                "status": "error",
                "message": "No se puede verificar garantía sin número de serie",
                "data": None
            }
        
        try:
            # Llamar a API externa (ejemplo con JSONPlaceholder)
            api_url = "https://jsonplaceholder.typicode.com/posts/1"
            response = requests.get(api_url, timeout=5)
            response.raise_for_status()  # Lanza excepción si el status code no es 200
            
            return {
                "status": "success",
                "message": f"Verificación exitosa para {self.numero_serie}",
                "data": {
                    "numero_serie": self.numero_serie,
                    "en_garantia": self.esta_en_garantia(),
                    "dias_asignacion": self.calcular_dias_asignacion(),
                    "api_response": response.json(),
                    "fecha_consulta": nowdate()
                }
            }
        
        except Exception as e:
            # Registrar el error en los logs de Frappe
            frappe.log_error(f"Error en Garantía: {str(e)}")
            return {
                "status": "error",
                "message": "Ocurrió un error inesperado.",
                "data": None
            }


# ===================================================================================
# FUNCIONES GLOBALES (No asociadas a la clase)
# ===================================================================================

@frappe.whitelist()
def verificar_disponibilidad_equipo(numero_serie):
    """
    Verifica si un equipo está disponible para ser asignado.
    
    Esta es una función global (no es un método de la clase) que puede ser
    llamada desde cualquier parte del sistema, incluyendo el navegador.
    
    Args:
        numero_serie (str): El número de serie del equipo a verificar
    
    Returns:
        dict: Diccionario con información sobre la disponibilidad:
            - disponible (bool): True si está disponible, False si no
            - mensaje (str): Mensaje descriptivo
            - asignacion (str): ID de la asignación activa (si existe)
    """
    # Buscar si existe una asignación activa para este número de serie
    asignacion_activa = frappe.db.get_value(
        "Asignacion de Equipo",
        filters={
            "numero_serie": numero_serie,
            "estado": "Asignado",
            "docstatus": ["<", 2]  # Excluir cancelados
        },
        fieldname=["name", "empleado"],
        as_dict=True
    )
    
    if asignacion_activa:
        return {
            "disponible": False,
            "mensaje": f"Equipo actualmente asignado al empleado {asignacion_activa.empleado}",
            "asignacion": asignacion_activa.name
        }
    else:
        return {
            "disponible": True,
            "mensaje": "Equipo disponible para asignación",
            "asignacion": None
        }