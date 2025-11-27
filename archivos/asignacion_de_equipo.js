/**
 * CLIENT SCRIPT - Asignación de Equipo
 * =====================================
 * 
 * Este archivo controla el comportamiento del formulario en el navegador.
 * Los Client Scripts se ejecutan en el navegador del usuario, no en el servidor.
 * 
 * CONCEPTOS CLAVE:
 * ---------------
 * - frm: Objeto que representa el formulario actual
 * - frm.doc: Los datos del documento actual
 * - frappe.call(): Llama a métodos Python del servidor
 * - __(): Función para traducir texto
 */

// ===================================================================================
// EVENTOS DEL FORMULARIO
// ===================================================================================

frappe.ui.form.on('Asignación de Equipo', {
    
    /**
     * refresh: Se ejecuta al cargar/actualizar el formulario
     * Es el evento más usado para configurar la interfaz
     */
    refresh: function(frm) {
        // Agregar botón "Verificar Garantía" solo si el documento ya existe
        if (!frm.is_new()) {
            frm.add_custom_button(__('Verificar Garantía'), function() {
                verificar_garantia_equipo(frm);
            }, __('Acciones'));
        }
        
        // Aplicar indicador visual según el estado
        aplicar_indicador_estado(frm);
        
        // Controlar visibilidad de campos según lógica de negocio
        controlar_visibilidad_campos(frm);
    },
    
    /**
     * onload: Se ejecuta UNA VEZ al cargar el formulario
     * Útil para configuración inicial que no necesita repetirse
     */
    onload: function(frm) {
        // Configurar filtros para mostrar solo empleados activos
        frm.set_query('empleado', function() {
            return {
                filters: { 'status': 'Active' }
            };
        });
    },
    
    /**
     * before_save: Se ejecuta ANTES de guardar
     * Permite validaciones del lado del cliente
     */
    before_save: function(frm) {
        // Validar que número de serie no esté vacío
        if (!frm.doc.numero_serie || frm.doc.numero_serie.trim() === '') {
            frappe.msgprint({
                title: __('Campo Obligatorio'),
                indicator: 'red',
                message: __('El Número de Serie es obligatorio.')
            });
            return false; // Cancelar el guardado
        }
        
        // Convertir número de serie a mayúsculas
        if (frm.doc.numero_serie) {
            frm.set_value('numero_serie', frm.doc.numero_serie.toUpperCase());
        }
    },
    
    /**
     * empleado: Se ejecuta cuando el usuario selecciona un empleado
     * Útil para cargar información adicional o validar
     */
    empleado: function(frm) {
        if (frm.doc.empleado) {
            // Verificar cuántos equipos tiene asignados este empleado
            frappe.call({
                method: 'frappe.client.get_count',
                args: {
                    doctype: 'Asignación de Equipo',
                    filters: {
                        empleado: frm.doc.empleado,
                        estado: 'Activa'
                    }
                },
                callback: function(r) {
                    if (r.message > 0) {
                        frappe.show_alert({
                            message: __('Este empleado tiene {0} equipo(s) asignado(s)', [r.message]),
                            indicator: 'blue'
                        }, 5);
                    }
                }
            });
        }
    },
    
    /**
     * estado: Se ejecuta cuando cambia el estado de la asignación
     */
    estado: function(frm) {
        // Actualizar visibilidad de campos según el nuevo estado
        controlar_visibilidad_campos(frm);
        
        // Aplicar nuevo indicador visual
        aplicar_indicador_estado(frm);
    },
    
    /**
     * tipo_de_equipo: Se ejecuta cuando cambia el tipo de equipo
     */
    tipo_de_equipo: function(frm) {
        // Mostrar mensaje informativo según el tipo
        if (frm.doc.tipo_de_equipo === 'Laptop') {
            frappe.show_alert({
                message: __('Recuerde verificar que la laptop incluya cargador'),
                indicator: 'blue'
            }, 3);
        }
    }
});


// ===================================================================================
// FUNCIONES AUXILIARES
// ===================================================================================

/**
 * Verifica la garantía del equipo llamando a un método del servidor
 * 
 * @param {Object} frm - El objeto formulario
 */
function verificar_garantia_equipo(frm) {
    // Validar que tengamos número de serie
    if (!frm.doc.numero_serie) {
        frappe.msgprint(__('Debe guardar el documento antes de verificar la garantía.'));
        return;
    }
    
    // Mostrar indicador de carga
    frappe.show_alert({
        message: __('Verificando garantía...'),
        indicator: 'blue'
    }, 3);
    
    // Llamar al método Python en el servidor
    frappe.call({
        method: 'verificar_garantia', // Método en el archivo .py
        doc: frm.doc, // Enviar el documento actual
        callback: function(r) {
            if (r.message) {
                mostrar_resultado_garantia(r.message);
            }
        },
        error: function(r) {
            frappe.msgprint({
                title: __('Error'),
                indicator: 'red',
                message: __('No se pudo verificar la garantía. Intente más tarde.')
            });
        }
    });
}

/**
 * Muestra el resultado de la verificación de garantía en un diálogo
 * 
 * @param {Object} datos - Respuesta del servidor con información de la garantía
 */
function mostrar_resultado_garantia(datos) {
    // Crear un diálogo modal para mostrar el resultado
    let dialog = new frappe.ui.Dialog({
        title: __('Resultado de Verificación de Garantía'),
        fields: [
            {
                fieldtype: 'HTML',
                fieldname: 'resultado_html'
            }
        ],
        primary_action_label: __('Cerrar'),
        primary_action: function() {
            dialog.hide();
        }
    });
    
    // Construir HTML con la información
    let estado_garantia = datos.en_garantia ? 
        '<span style="color: #28a745;">✓ ACTIVA</span>' : 
        '<span style="color: #dc3545;">✗ VENCIDA</span>';
    
    let html = `
        <div style="padding: 15px;">
            <table class="table table-bordered">
                <tr>
                    <th style="width: 40%;">${__('Número de Serie')}</th>
                    <td><strong>${datos.numero_serie || 'N/A'}</strong></td>
                </tr>
                <tr>
                    <th>${__('Estado de Garantía')}</th>
                    <td>${estado_garantia}</td>
                </tr>
                <tr>
                    <th>${__('Marca')}</th>
                    <td>${datos.marca || 'N/A'}</td>
                </tr>
                <tr>
                    <th>${__('Modelo')}</th>
                    <td>${datos.modelo || 'N/A'}</td>
                </tr>
                <tr>
                    <th>${__('Días de Uso')}</th>
                    <td>${datos.dias_uso || 0} días</td>
                </tr>
            </table>
            
            <p style="margin-top: 15px; font-size: 12px; color: #666;">
                <em>${__('Consulta realizada')}: ${frappe.datetime.now_datetime()}</em>
            </p>
        </div>
    `;
    
    // Inyectar el HTML en el diálogo y mostrarlo
    dialog.fields_dict.resultado_html.$wrapper.html(html);
    dialog.show();
    
    // Mostrar también una alerta rápida
    frappe.show_alert({
        message: datos.en_garantia ? 
            __('✓ Equipo en garantía') : 
            __('✗ Garantía vencida'),
        indicator: datos.en_garantia ? 'green' : 'orange'
    }, 5);
}

/**
 * Aplica un indicador visual de color según el estado del equipo
 * 
 * @param {Object} frm - El objeto formulario
 */
function aplicar_indicador_estado(frm) {
    if (!frm.doc.estado) return;
    
    // Mapeo de estados a colores del sistema
    let indicadores = {
        'Activa': 'blue',      // Azul para activa
        'Devuelta': 'green',   // Verde para devuelta
        'Extraviada': 'red',   // Rojo para extraviada
        'Dañada': 'orange'     // Naranja para dañada
    };
    
    let color = indicadores[frm.doc.estado] || 'gray';
    
    // Establecer el indicador en la barra superior del formulario
    frm.page.set_indicator(frm.doc.estado, color);
}

/**
 * Muestra u oculta campos según la lógica de negocio
 * 
 * @param {Object} frm - El objeto formulario
 */
function controlar_visibilidad_campos(frm) {
    // Por ejemplo: mostrar campo de notas solo si hay un problema
    if (frm.doc.estado === 'Dañada' || frm.doc.estado === 'Extraviada') {
        frm.set_df_property('notas', 'reqd', 1); // Hacer obligatorio
    } else {
        frm.set_df_property('notas', 'reqd', 0); // No obligatorio
    }
}


/**
 * DEBUGGING EN EL NAVEGADOR:
 * 
 * 1. Abrir DevTools (F12)
 * 2. Ir a la pestaña "Console"
 * 3. Usar console.log() para depurar:
 *    console.log('Valor:', frm.doc.numero_serie);
 * 
 * OBJETOS GLOBALES ÚTILES:
 * 
 * - frappe.call()        → Llamar métodos del servidor
 * - frappe.msgprint()    → Mostrar mensaje al usuario
 * - frappe.show_alert()  → Mostrar alerta temporal
 * - frappe.datetime      → Utilidades para fechas
 * - cur_frm              → El formulario actual (mismo que frm)
 * 
 * DOCUMENTACIÓN:
 * https://frappeframework.com/docs/user/en/desk/scripting/form-scripts
 */