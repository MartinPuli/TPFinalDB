# Modelo relacional — Aerolínea Low Cost

Pasaje del modelo conceptual a tablas. Convención: <ins>subrayado</ins> = clave
primaria (PK); *cursiva* = clave foránea (FK).

- **aeropuerto** (<ins>codigo_iata</ins>, nombre, ciudad, pais)
- **ruta** (<ins>id_ruta</ins>, *cod_aeropuerto_org*, *cod_aeropuerto_dst*)
  - UNIQUE (cod_aeropuerto_org, cod_aeropuerto_dst); CHECK origen ≠ destino
- **aeronave** (<ins>matricula</ins>, modelo, capacidad_maxima, estado_operativo)
  - CHECK capacidad_maxima > 0
- **asiento** (<ins>id_asiento</ins>, *matricula_aeronave*, fila, letra, tipo)
  - UNIQUE (matricula_aeronave, fila, letra); CHECK fila > 0
- **vuelo** (<ins>id_vuelo</ins>, numero_vuelo, *id_ruta*, *matricula_aeronave*,
  fecha_hora_salida, fecha_hora_llegada, estado, precio_base)
  - UNIQUE (numero_vuelo, fecha_hora_salida); matricula_aeronave NOT NULL
  - CHECK precio_base ≥ 0; CHECK (llegada IS NULL OR llegada > salida)
- **empleado** (<ins>legajo</ins>, nombre, rol)
- **vuelo_empleado** (<ins>*id_vuelo*</ins>, <ins>*legajo*</ins>, funcion)
- **pasajero** (<ins>id_pasajero</ins>, nombre, apellido, email)
  - UNIQUE (email)
- **reserva** (<ins>id_reserva</ins>, codigo_reserva, *id_pasajero_titular*,
  fecha_emision, estado, monto_total)
  - UNIQUE (codigo_reserva); CHECK monto_total ≥ 0
  - `monto_total` es un atributo **derivado** mantenido por triggers (ver abajo).
- **pasaje** (<ins>id_pasaje</ins>, codigo_ticket, *id_reserva*, *id_pasajero*,
  *id_vuelo*, *id_asiento*, estado, precio_base)
  - UNIQUE (codigo_ticket); UNIQUE (id_vuelo, id_asiento); UNIQUE (id_vuelo, id_pasajero)
  - CHECK precio_base ≥ 0
- **servicio_adicional** (<ins>id_servicio</ins>, nombre, descripcion, precio_base)
  - UNIQUE (nombre); CHECK precio_base ≥ 0
- **pasaje_servicio** (<ins>*id_pasaje*</ins>, <ins>*id_servicio*</ins>,
  cantidad, precio_aplicado)
  - CHECK cantidad > 0; CHECK precio_aplicado ≥ 0
- **checkin** (<ins>id_checkin</ins>, *id_pasaje*, fecha_hora, tarjeta_embarque)
  - UNIQUE (id_pasaje)
- **pago** (<ins>id_pago</ins>, *id_reserva*, monto, medio_pago, estado, fecha)
  - CHECK monto > 0

## Mapa de claves foráneas

| Tabla | Columna(s) FK | Referencia | ON DELETE |
|---|---|---|---|
| ruta | cod_aeropuerto_org | aeropuerto(codigo_iata) | RESTRICT |
| ruta | cod_aeropuerto_dst | aeropuerto(codigo_iata) | RESTRICT |
| asiento | matricula_aeronave | aeronave(matricula) | CASCADE |
| vuelo | id_ruta | ruta(id_ruta) | RESTRICT |
| vuelo | matricula_aeronave | aeronave(matricula) | RESTRICT |
| vuelo_empleado | id_vuelo | vuelo(id_vuelo) | CASCADE |
| vuelo_empleado | legajo | empleado(legajo) | RESTRICT |
| reserva | id_pasajero_titular | pasajero(id_pasajero) | RESTRICT |
| pasaje | id_reserva | reserva(id_reserva) | CASCADE |
| pasaje | id_pasajero | pasajero(id_pasajero) | RESTRICT |
| pasaje | id_vuelo | vuelo(id_vuelo) | RESTRICT |
| pasaje | id_asiento | asiento(id_asiento) | RESTRICT |
| pasaje_servicio | id_pasaje | pasaje(id_pasaje) | CASCADE |
| pasaje_servicio | id_servicio | servicio_adicional(id_servicio) | RESTRICT |
| checkin | id_pasaje | pasaje(id_pasaje) | CASCADE |
| pago | id_reserva | reserva(id_reserva) | CASCADE |

> `ON DELETE CASCADE` se aplica a las entidades **dependientes** (un asiento no
> existe sin su aeronave; un pasaje, su check-in y sus servicios no existen sin
> la reserva/pasaje). El resto queda en `RESTRICT` para no borrar datos maestros
> por accidente.

## Índices adicionales

Además de los índices automáticos de PK, UNIQUE y FK, se agregan:

| Índice | Tabla / columnas | Sirve para |
|---|---|---|
| idx_vuelo_salida | vuelo(fecha_hora_salida) | Búsqueda de vuelos por fecha. |
| idx_pasaje_vuelo_estado | pasaje(id_vuelo, estado) | Conteo de pasajes activos (capacidad/ocupación). |
| idx_pago_reserva_estado | pago(id_reserva, estado) | Suma de pagos aprobados por reserva. |

## Reglas de negocio y cómo se garantizan

| Regla | Mecanismo en el modelo |
|---|---|
| Pasaje = 1 pasajero + 1 vuelo | FK `id_pasajero` e `id_vuelo` NOT NULL. |
| Un pasajero no se repite en un mismo vuelo | UNIQUE (id_vuelo, id_pasajero). |
| Vuelo necesita aeronave para venderse | `vuelo.matricula_aeronave` NOT NULL + FK. |
| No superar capacidad de la aeronave | Triggers `trg_pasaje_bi` / `trg_pasaje_bu` (BEFORE INSERT/UPDATE). |
| Asiento no duplicado por vuelo | UNIQUE (id_vuelo, id_asiento). |
| Asiento debe pertenecer a la aeronave del vuelo | Validación en los triggers de pasaje. |
| Servicio con cantidad y precio aplicado | Columnas `cantidad` y `precio_aplicado` en `pasaje_servicio`. |
| `monto_total` siempre consistente | Función `fn_total_reserva` + triggers `trg_pasaje_a*` y `trg_ps_a*` que recalculan ante cada cambio de pasajes o servicios. |
| Reserva confirmada solo con pago aprobado suficiente | Trigger `trg_reserva_bu` (BEFORE UPDATE): bloquea el pase a `confirmada` si la suma de pagos `aprobado` no cubre `monto_total`. |
| Llegada posterior a la salida | CHECK `chk_vuelo_fechas`. |

### Sobre la cardinalidad mínima "una reserva con al menos un pasaje"

El SQL declarativo no permite exigir que una reserva tenga ≥ 1 pasaje en el
mismo instante de su inserción (sería una dependencia circular: la reserva
existe antes que sus pasajes). Se resuelve a nivel de **lógica de negocio**: la
reserva nace en estado `pendiente` y solo se `confirma` cuando ya tiene pasajes
y pago aprobado (procedimiento `sp_confirmar_reserva`). Una reserva sin pasajes
queda con `monto_total = 0` y nunca llega a confirmarse.
