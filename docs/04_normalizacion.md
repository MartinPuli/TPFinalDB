# Análisis de normalización — Aerolínea Low Cost

Se analiza el modelo relacional verificando que cada tabla cumpla las formas
normales hasta la **Forma Normal de Boyce-Codd (FNBC)**. Para cada relación se
listan sus dependencias funcionales (DF) y se justifica el nivel alcanzado.

Notación: `X → Y` significa "X determina funcionalmente a Y". Las claves
candidatas se indican entre llaves.

## Repaso de las formas normales

- **1FN:** todos los atributos son atómicos (sin grupos repetitivos ni
  multivaluados) y existe una clave que identifica cada fila.
- **2FN:** está en 1FN y ningún atributo no primo depende **parcialmente** de
  una clave candidata (relevante solo si hay claves compuestas).
- **3FN:** está en 2FN y no hay dependencias **transitivas** (ningún atributo no
  primo depende de otro atributo no primo).
- **FNBC:** para toda DF no trivial `X → Y`, `X` es **superclave**. Es una 3FN
  más estricta.

## Análisis por relación

### aeropuerto
Clave: {codigo_iata}. DF: `codigo_iata → nombre, ciudad, pais`.
Todos los atributos dependen de la clave completa; no hay otras DF. **FNBC.**

### ruta
Clave: {id_ruta}; clave candidata alternativa {cod_aeropuerto_org,
cod_aeropuerto_dst} (UNIQUE). DF:
`id_ruta → cod_aeropuerto_org, cod_aeropuerto_dst` y
`{cod_aeropuerto_org, cod_aeropuerto_dst} → id_ruta`.
Ambos determinantes son superclaves. **FNBC.**

### aeronave
Clave: {matricula}. DF:
`matricula → modelo, capacidad_maxima, estado_operativo`. **FNBC.**

### asiento
Clave: {id_asiento}; candidata alternativa {matricula_aeronave, fila, letra}. DF:
`id_asiento → matricula_aeronave, fila, letra, tipo` y
`{matricula_aeronave, fila, letra} → id_asiento, tipo`.
Ambos determinantes son superclaves. **FNBC.**

### vuelo
Clave: {id_vuelo}; candidata alternativa {numero_vuelo, fecha_hora_salida}. DF:
`id_vuelo → numero_vuelo, id_ruta, matricula_aeronave, fecha_hora_salida,
fecha_hora_llegada, estado, precio_base`.
No hay dependencias transitivas: el precio, la ruta y la aeronave dependen del
vuelo puntual, no entre sí. **FNBC.**

> Nota: `precio_base` es el precio del vuelo concreto (puede variar por fecha o
> demanda), por eso depende de `id_vuelo` y no de la ruta.

### empleado
Clave: {legajo}. DF: `legajo → nombre, rol`. **FNBC.**

### vuelo_empleado  (asociativa)
Clave: {id_vuelo, legajo}. DF:
`{id_vuelo, legajo} → funcion`.
`funcion` depende de la clave compuesta completa (qué función cumple *ese*
empleado en *ese* vuelo), no de una parte. No hay dependencias parciales ni
transitivas. **FNBC.**

### pasajero
Clave: {id_pasajero}; candidata alternativa {email} (UNIQUE). DF:
`id_pasajero → nombre, apellido, email` y `email → id_pasajero, nombre,
apellido`. Ambos determinantes son superclaves. **FNBC.**

### reserva
Clave: {id_reserva}; candidata alternativa {codigo_reserva}. DF:
`id_reserva → codigo_reserva, id_pasajero_titular, fecha_emision, estado,
monto_total`.
`monto_total` es un atributo **derivado** (ver sección siguiente); ignorándolo,
el resto depende solo de la clave. **FNBC.**

### pasaje
Clave: {id_pasaje}; candidata alternativa {codigo_ticket}. DF:
`id_pasaje → codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento,
estado, precio_base`.
Las restricciones UNIQUE (id_vuelo, id_asiento) y UNIQUE (id_vuelo, id_pasajero)
son claves candidatas adicionales (superclaves). No hay atributos no primos que
dependan entre sí. **FNBC.**

### servicio_adicional
Clave: {id_servicio}; candidata alternativa {nombre}. DF:
`id_servicio → nombre, descripcion, precio_base` y `nombre → id_servicio,
descripcion, precio_base`. Ambos son superclaves. **FNBC.**

### pasaje_servicio  (asociativa)
Clave: {id_pasaje, id_servicio}. DF:
`{id_pasaje, id_servicio} → cantidad, precio_aplicado`.
Se guarda `precio_aplicado` (precio al momento de la compra) en lugar de
referenciar `servicio_adicional.precio_base`, justamente para **evitar una
dependencia transitiva** y conservar el valor histórico. **FNBC.**

### checkin
Clave: {id_checkin}; candidata alternativa {id_pasaje} (UNIQUE). DF:
`id_checkin → id_pasaje, fecha_hora, tarjeta_embarque` y
`id_pasaje → id_checkin, fecha_hora, tarjeta_embarque`. Superclaves. **FNBC.**

### pago
Clave: {id_pago}. DF:
`id_pago → id_reserva, monto, medio_pago, estado, fecha`. **FNBC.**

## Conclusión

Todas las relaciones están en **FNBC**. El diseño evita las anomalías típicas:

- **Inserción:** se puede dar de alta una aeronave sin vuelos, un servicio sin
  contrataciones, etc.
- **Actualización:** cambiar el nombre de un aeropuerto o de un servicio se hace
  en un único lugar.
- **Eliminación:** borrar la última contratación de un servicio no elimina el
  servicio del catálogo.

La separación de las relaciones asociativas (`vuelo_empleado`,
`pasaje_servicio`) resuelve las relaciones N:M sin introducir atributos
multivaluados, manteniendo la 1FN.

## Caso especial: el atributo derivado `reserva.monto_total`

`monto_total` **podría omitirse** sin perder información, ya que es calculable
como la suma de los pasajes no cancelados más sus servicios
(`fn_total_reserva`). Mantenerlo almacenado es una **desnormalización
controlada y deliberada**, con la siguiente justificación y salvaguarda:

- **Motivo:** es un valor consultado con muchísima frecuencia (listados de
  reservas, validación de pagos, reportes). Recalcularlo en cada lectura sería
  costoso.
- **Riesgo de la desnormalización:** que el valor almacenado quede inconsistente
  con los datos de origen (anomalía de actualización).
- **Salvaguarda:** la consistencia **no se delega al usuario**. Los triggers
  `trg_pasaje_ai/au/ad` y `trg_ps_ai/au/ad` recalculan `monto_total` mediante
  `fn_total_reserva` ante cualquier alta, baja o cambio de pasajes o servicios.
  Así se obtiene el rendimiento de un dato materializado sin las anomalías que
  la normalización busca evitar.

Si se prefiriera un modelo estrictamente normalizado, bastaría con eliminar la
columna `monto_total` y los seis triggers de mantenimiento, y usar
`fn_total_reserva(id_reserva)` (o la vista `v_reserva_estado_pago`) cada vez que
se necesite el total.
