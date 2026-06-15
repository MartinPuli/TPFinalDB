# Modelo relacional — Aerolínea Low Cost

Pasaje del modelo conceptual a tablas. Convención: <ins>subrayado</ins> = clave
primaria (PK); *cursiva* = clave foránea (FK).

- **aeropuerto** (<ins>codigo_iata</ins>, nombre, ciudad, pais)
- **ruta** (<ins>id_ruta</ins>, *cod_aeropuerto_org*, *cod_aeropuerto_dst*)
  - UNIQUE (cod_aeropuerto_org, cod_aeropuerto_dst); CHECK origen ≠ destino
- **aeronave** (<ins>matricula</ins>, modelo, capacidad_maxima, estado_operativo)
- **asiento** (<ins>id_asiento</ins>, *matricula_aeronave*, fila, letra, tipo)
  - UNIQUE (matricula_aeronave, fila, letra)
- **vuelo** (<ins>id_vuelo</ins>, numero_vuelo, *id_ruta*, *matricula_aeronave*,
  fecha_hora_salida, fecha_hora_llegada, estado, precio_base)
  - UNIQUE (numero_vuelo, fecha_hora_salida); matricula_aeronave NOT NULL
- **empleado** (<ins>legajo</ins>, nombre, rol)
- **vuelo_empleado** (<ins>*id_vuelo*</ins>, <ins>*legajo*</ins>, funcion)
- **pasajero** (<ins>id_pasajero</ins>, nombre, apellido, email)
  - UNIQUE (email)
- **reserva** (<ins>id_reserva</ins>, codigo_reserva, *id_pasajero_titular*,
  fecha_emision, estado, monto_total)
  - UNIQUE (codigo_reserva)
- **pasaje** (<ins>id_pasaje</ins>, codigo_ticket, *id_reserva*, *id_pasajero*,
  *id_vuelo*, *id_asiento*, estado, precio_base)
  - UNIQUE (codigo_ticket); UNIQUE (id_vuelo, id_asiento)
- **servicio_adicional** (<ins>id_servicio</ins>, nombre, descripcion, precio_base)
  - UNIQUE (nombre)
- **pasaje_servicio** (<ins>*id_pasaje*</ins>, <ins>*id_servicio*</ins>,
  cantidad, precio_aplicado)
- **checkin** (<ins>id_checkin</ins>, *id_pasaje*, fecha_hora, tarjeta_embarque)
  - UNIQUE (id_pasaje)
- **pago** (<ins>id_pago</ins>, *id_reserva*, monto, medio_pago, estado, fecha)

## Mapa de claves foráneas

| Tabla | Columna(s) FK | Referencia |
|---|---|---|
| ruta | cod_aeropuerto_org | aeropuerto(codigo_iata) |
| ruta | cod_aeropuerto_dst | aeropuerto(codigo_iata) |
| asiento | matricula_aeronave | aeronave(matricula) |
| vuelo | id_ruta | ruta(id_ruta) |
| vuelo | matricula_aeronave | aeronave(matricula) |
| vuelo_empleado | id_vuelo | vuelo(id_vuelo) |
| vuelo_empleado | legajo | empleado(legajo) |
| reserva | id_pasajero_titular | pasajero(id_pasajero) |
| pasaje | id_reserva | reserva(id_reserva) |
| pasaje | id_pasajero | pasajero(id_pasajero) |
| pasaje | id_vuelo | vuelo(id_vuelo) |
| pasaje | id_asiento | asiento(id_asiento) |
| pasaje_servicio | id_pasaje | pasaje(id_pasaje) |
| pasaje_servicio | id_servicio | servicio_adicional(id_servicio) |
| checkin | id_pasaje | pasaje(id_pasaje) |
| pago | id_reserva | reserva(id_reserva) |

## Reglas de negocio y cómo se garantizan

| Regla | Mecanismo en el modelo |
|---|---|
| Reserva con ≥ 1 pasaje | FK obligatoria `pasaje.id_reserva` + validación de aplicación/trigger (la cardinalidad mínima no se fuerza en DDL puro). |
| Pasaje = 1 pasajero + 1 vuelo | FK `id_pasajero` e `id_vuelo` NOT NULL. |
| Vuelo necesita aeronave para venderse | `vuelo.matricula_aeronave` NOT NULL + FK. |
| No superar capacidad de la aeronave | Trigger `trg_pasaje_capacidad` (BEFORE INSERT/UPDATE). |
| Asiento no duplicado por vuelo | UNIQUE (id_vuelo, id_asiento) + trigger que valida que el asiento pertenezca a la aeronave del vuelo. |
| Servicio con cantidad y precio aplicado | Columnas `cantidad` y `precio_aplicado` en `pasaje_servicio`. |
| Reserva confirmada solo con pago aprobado | Procedimiento/validación sobre `pago.estado = 'aprobado'` (ver consultas). |

> Las cardinalidades mínimas (ej.: "una reserva debe tener al menos un pasaje")
> y la confirmación por pago aprobado se resuelven a nivel de lógica de negocio
> o triggers diferidos, ya que el SQL estándar no permite expresarlas como
> constraints declarativas simples.
