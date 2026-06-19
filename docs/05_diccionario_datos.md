# Diccionario de datos — Aerolínea Low Cost

Descripción de cada tabla y columna del esquema (`sql/01_schema.sql`).
Convenciones: **PK** = clave primaria, **FK** = clave foránea, **UQ** = parte de
una restricción UNIQUE, **NN** = NOT NULL.

## aeropuerto
Aeropuertos operados o conectados por la aerolínea.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| codigo_iata | CHAR(3) | PK, NN | Código IATA (ej.: AEP, EZE). |
| nombre | VARCHAR(120) | NN | Nombre del aeropuerto. |
| ciudad | VARCHAR(80) | NN | Ciudad donde se ubica. |
| pais | VARCHAR(80) | NN | País. |

## ruta
Conexión dirigida entre dos aeropuertos (origen → destino).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_ruta | INT | PK, NN, AUTO_INCREMENT | Identificador de la ruta. |
| cod_aeropuerto_org | CHAR(3) | FK→aeropuerto, NN, UQ | Aeropuerto de origen. |
| cod_aeropuerto_dst | CHAR(3) | FK→aeropuerto, NN, UQ | Aeropuerto de destino. |

CHECK: origen ≠ destino. UNIQUE (org, dst).

## aeronave
Flota de la aerolínea.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| matricula | VARCHAR(10) | PK, NN | Matrícula (ej.: LV-ABC). |
| modelo | VARCHAR(60) | NN | Modelo de la aeronave. |
| capacidad_maxima | INT | NN, CHECK > 0 | Cantidad máxima de pasajeros. |
| estado_operativo | ENUM | NN, default `operativa` | `operativa` \| `en_mantenimiento` \| `fuera_servicio`. |

## asiento
Asientos físicos de cada aeronave.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_asiento | INT | PK, NN, AUTO_INCREMENT | Identificador del asiento. |
| matricula_aeronave | VARCHAR(10) | FK→aeronave (CASCADE), NN, UQ | Aeronave a la que pertenece. |
| fila | INT | NN, UQ, CHECK > 0 | Número de fila. |
| letra | CHAR(1) | NN, UQ | Letra del asiento (A, B, …). |
| tipo | ENUM | NN, default `comun` | `comun` \| `espacio_extra` \| `salida_emergencia`. |

UNIQUE (matricula_aeronave, fila, letra).

## vuelo
Vuelo programado sobre una ruta, operado por una aeronave.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_vuelo | INT | PK, NN, AUTO_INCREMENT | Identificador del vuelo. |
| numero_vuelo | VARCHAR(10) | NN, UQ | Número comercial (ej.: LC100). |
| id_ruta | INT | FK→ruta, NN | Ruta que cubre. |
| matricula_aeronave | VARCHAR(10) | FK→aeronave, NN | Aeronave asignada (obligatoria). |
| fecha_hora_salida | DATETIME | NN, UQ | Fecha y hora de salida. |
| fecha_hora_llegada | DATETIME | NULL | Fecha y hora de llegada (estimada). |
| estado | ENUM | NN, default `programado` | `programado` \| `demorado` \| `cancelado` \| `finalizado`. |
| precio_base | DECIMAL(10,2) | NN, CHECK ≥ 0 | Tarifa base del vuelo. |

UNIQUE (numero_vuelo, fecha_hora_salida). CHECK (llegada IS NULL OR llegada > salida).

## empleado
Personal de la aerolínea.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| legajo | INT | PK, NN | Legajo del empleado. |
| nombre | VARCHAR(120) | NN | Nombre completo. |
| rol | ENUM | NN | `piloto` \| `copiloto` \| `tripulante_cabina` \| `administrativo` \| `atencion_cliente`. |

## vuelo_empleado
Asignación de empleados a vuelos (asociativa N:M).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_vuelo | INT | PK, FK→vuelo (CASCADE), NN | Vuelo. |
| legajo | INT | PK, FK→empleado, NN | Empleado. |
| funcion | ENUM | NN | `piloto` \| `copiloto` \| `tripulante_cabina` en ese vuelo. |

## pasajero
Personas que viajan.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_pasajero | INT | PK, NN, AUTO_INCREMENT | Identificador del pasajero. |
| nombre | VARCHAR(80) | NN | Nombre. |
| apellido | VARCHAR(80) | NN | Apellido. |
| email | VARCHAR(120) | NN, UQ | Correo electrónico (único). |

## reserva
Operación de compra de un pasajero titular.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_reserva | INT | PK, NN, AUTO_INCREMENT | Identificador de la reserva. |
| codigo_reserva | VARCHAR(10) | NN, UQ | Código alfanumérico (ej.: RSV0001). |
| id_pasajero_titular | INT | FK→pasajero, NN | Pasajero que realiza la compra. |
| fecha_emision | DATETIME | NN, default NOW | Fecha de emisión. |
| estado | ENUM | NN, default `pendiente` | `pendiente` \| `confirmada` \| `cancelada`. |
| monto_total | DECIMAL(10,2) | NN, default 0, CHECK ≥ 0 | **Derivado**: pasajes + servicios no cancelados (lo mantienen los triggers). |

## pasaje
Ticket de un pasajero para un vuelo.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_pasaje | INT | PK, NN, AUTO_INCREMENT | Identificador del pasaje. |
| codigo_ticket | VARCHAR(15) | NN, UQ | Código del ticket (ej.: TK0000001). |
| id_reserva | INT | FK→reserva (CASCADE), NN | Reserva a la que pertenece. |
| id_pasajero | INT | FK→pasajero, NN, UQ | Pasajero que viaja. |
| id_vuelo | INT | FK→vuelo, NN, UQ | Vuelo. |
| id_asiento | INT | FK→asiento, NULL, UQ | Asiento asignado (opcional). |
| estado | ENUM | NN, default `reservado` | `reservado` \| `confirmado` \| `cancelado` \| `utilizado`. |
| precio_base | DECIMAL(10,2) | NN, CHECK ≥ 0 | Precio del pasaje al comprarlo. |

UNIQUE (id_vuelo, id_asiento) — un asiento por vuelo.
UNIQUE (id_vuelo, id_pasajero) — un pasaje por pasajero y vuelo.

## servicio_adicional
Catálogo de servicios opcionales.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_servicio | INT | PK, NN, AUTO_INCREMENT | Identificador del servicio. |
| nombre | VARCHAR(80) | NN, UQ | Nombre del servicio. |
| descripcion | VARCHAR(255) | NULL | Descripción. |
| precio_base | DECIMAL(10,2) | NN, CHECK ≥ 0 | Precio de lista actual. |

## pasaje_servicio
Servicios contratados en cada pasaje (asociativa N:M).

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_pasaje | INT | PK, FK→pasaje (CASCADE), NN | Pasaje. |
| id_servicio | INT | PK, FK→servicio_adicional, NN | Servicio contratado. |
| cantidad | INT | NN, default 1, CHECK > 0 | Unidades contratadas. |
| precio_aplicado | DECIMAL(10,2) | NN, CHECK ≥ 0 | Precio al momento de la compra (valor histórico). |

## checkin
Check-in realizado para un pasaje.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_checkin | INT | PK, NN, AUTO_INCREMENT | Identificador del check-in. |
| id_pasaje | INT | FK→pasaje (CASCADE), NN, UQ | Pasaje (uno por pasaje). |
| fecha_hora | DATETIME | NN, default NOW | Momento del check-in. |
| tarjeta_embarque | VARCHAR(30) | NN | Identificador de la tarjeta de embarque. |

## pago
Pagos asociados a una reserva.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| id_pago | INT | PK, NN, AUTO_INCREMENT | Identificador del pago. |
| id_reserva | INT | FK→reserva (CASCADE), NN | Reserva pagada. |
| monto | DECIMAL(10,2) | NN, CHECK > 0 | Importe del pago. |
| medio_pago | ENUM | NN | `tarjeta_credito` \| `tarjeta_debito` \| `transferencia` \| `billetera_virtual`. |
| estado | ENUM | NN, default `pendiente` | `pendiente` \| `aprobado` \| `rechazado`. |
| fecha | DATETIME | NN, default NOW | Fecha del pago. |

## Objetos de programación

### Función
- **fn_total_reserva(id_reserva)** → DECIMAL: total de una reserva (pasajes no
  cancelados + servicios). Fuente de verdad de `reserva.monto_total`.
- **fn_asientos_disponibles(id_vuelo)** → INT: capacidad − pasajes activos.

### Triggers
- **trg_pasaje_bi / trg_pasaje_bu** (BEFORE INSERT/UPDATE en pasaje): validan
  capacidad de la aeronave y que el asiento pertenezca al avión del vuelo.
- **trg_pasaje_ai / au / ad** (AFTER en pasaje): recalculan `reserva.monto_total`.
- **trg_ps_ai / au / ad** (AFTER en pasaje_servicio): recalculan `reserva.monto_total`.
- **trg_reserva_bu** (BEFORE UPDATE en reserva): impide confirmar si los pagos
  aprobados no cubren el monto.

### Procedimientos
- **sp_vender_pasaje(...)**: agrega un pasaje a una reserva y genera su ticket.
- **sp_confirmar_reserva(id_reserva)**: confirma la reserva y sus pasajes.
- **sp_registrar_checkin(id_pasaje)**: registra el check-in de un pasaje confirmado.
- **sp_cancelar_pasaje(id_pasaje)**: cancela un pasaje y libera su asiento.

### Vistas
`v_vuelo_disponibilidad`, `v_reserva_detalle`, `v_reserva_estado_pago`,
`v_ocupacion_vuelo`, `v_ingresos_vuelo`, `v_tripulacion_vuelo`
(definidas en `sql/03_vistas.sql`).
