-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: datos de ejemplo
-- Requiere haber ejecutado 01_schema.sql
-- ============================================================
USE aerolinea_lowcost;

-- ---------- AEROPUERTOS ----------
INSERT INTO aeropuerto (codigo_iata, nombre, ciudad, pais) VALUES
  ('AEP', 'Aeroparque Jorge Newbery', 'Buenos Aires', 'Argentina'),
  ('EZE', 'Ministro Pistarini',       'Buenos Aires', 'Argentina'),
  ('COR', 'Ingeniero Taravella',      'Cordoba',      'Argentina'),
  ('MDZ', 'El Plumerillo',            'Mendoza',      'Argentina'),
  ('BRC', 'Teniente Candelaria',      'Bariloche',    'Argentina'),
  ('SCL', 'Arturo Merino Benitez',    'Santiago',     'Chile');

-- ---------- RUTAS ----------
INSERT INTO ruta (cod_aeropuerto_org, cod_aeropuerto_dst) VALUES
  ('AEP', 'COR'),   -- 1
  ('COR', 'AEP'),   -- 2
  ('AEP', 'BRC'),   -- 3
  ('MDZ', 'SCL'),   -- 4
  ('EZE', 'SCL');   -- 5

-- ---------- AERONAVES ----------
INSERT INTO aeronave (matricula, modelo, capacidad_maxima, estado_operativo) VALUES
  ('LV-ABC', 'Airbus A320',   4, 'operativa'),          -- capacidad baja a proposito (demo de regla de capacidad)
  ('LV-XYZ', 'Boeing 737-800', 6, 'operativa'),
  ('LV-MNT', 'Embraer E190',   3, 'en_mantenimiento');

-- ---------- ASIENTOS ----------
-- Aeronave LV-ABC (capacidad 4): filas 1 y 2, letras A/B
INSERT INTO asiento (matricula_aeronave, fila, letra, tipo) VALUES
  ('LV-ABC', 1, 'A', 'espacio_extra'),   -- 1
  ('LV-ABC', 1, 'B', 'espacio_extra'),   -- 2
  ('LV-ABC', 2, 'A', 'comun'),           -- 3
  ('LV-ABC', 2, 'B', 'comun');           -- 4
-- Aeronave LV-XYZ (capacidad 6)
INSERT INTO asiento (matricula_aeronave, fila, letra, tipo) VALUES
  ('LV-XYZ', 1, 'A', 'salida_emergencia'),  -- 5
  ('LV-XYZ', 1, 'B', 'salida_emergencia'),  -- 6
  ('LV-XYZ', 2, 'A', 'comun'),              -- 7
  ('LV-XYZ', 2, 'B', 'comun'),              -- 8
  ('LV-XYZ', 3, 'A', 'comun'),              -- 9
  ('LV-XYZ', 3, 'B', 'comun');              -- 10

-- ---------- EMPLEADOS ----------
INSERT INTO empleado (legajo, nombre, rol) VALUES
  (1001, 'Lucia Fernandez',  'piloto'),
  (1002, 'Diego Sosa',       'copiloto'),
  (1003, 'Marina Quiroga',   'tripulante_cabina'),
  (1004, 'Pablo Ramirez',    'tripulante_cabina'),
  (2001, 'Sofia Acosta',     'administrativo'),
  (2002, 'Hernan Vega',      'atencion_cliente');

-- ---------- VUELOS ----------
INSERT INTO vuelo (numero_vuelo, id_ruta, matricula_aeronave, fecha_hora_salida, fecha_hora_llegada, estado, precio_base) VALUES
  ('LC100', 1, 'LV-ABC', '2026-07-10 08:00:00', '2026-07-10 09:30:00', 'programado', 35000.00),  -- 1 AEP->COR
  ('LC101', 2, 'LV-ABC', '2026-07-10 18:00:00', '2026-07-10 19:30:00', 'programado', 35000.00),  -- 2 COR->AEP
  ('LC200', 3, 'LV-XYZ', '2026-07-12 06:30:00', '2026-07-12 09:00:00', 'programado', 52000.00),  -- 3 AEP->BRC
  ('LC300', 4, 'LV-XYZ', '2026-07-15 10:00:00', '2026-07-15 11:00:00', 'demorado',   48000.00);  -- 4 MDZ->SCL

-- ---------- TRIPULACION ASIGNADA (vuelo_empleado) ----------
INSERT INTO vuelo_empleado (id_vuelo, legajo, funcion) VALUES
  (1, 1001, 'piloto'), (1, 1002, 'copiloto'), (1, 1003, 'tripulante_cabina'),
  (2, 1001, 'piloto'), (2, 1002, 'copiloto'), (2, 1004, 'tripulante_cabina'),
  (3, 1001, 'piloto'), (3, 1002, 'copiloto'), (3, 1003, 'tripulante_cabina'), (3, 1004, 'tripulante_cabina');

-- ---------- PASAJEROS ----------
INSERT INTO pasajero (nombre, apellido, email) VALUES
  ('Juan',    'Perez',     'juan.perez@mail.com'),     -- 1
  ('Ana',     'Gomez',     'ana.gomez@mail.com'),      -- 2
  ('Carlos',  'Lopez',     'carlos.lopez@mail.com'),   -- 3
  ('Valeria', 'Diaz',      'valeria.diaz@mail.com');   -- 4

-- ---------- SERVICIOS ADICIONALES ----------
INSERT INTO servicio_adicional (nombre, descripcion, precio_base) VALUES
  ('Equipaje despachado',  'Valija de hasta 23 kg en bodega',       12000.00),  -- 1
  ('Equipaje de mano extra','Bolso de mano adicional',               6000.00),  -- 2
  ('Seleccion de asiento', 'Eleccion anticipada de asiento',         4500.00),  -- 3
  ('Embarque prioritario', 'Abordaje en el primer grupo',            3000.00),  -- 4
  ('Seguro de viaje',      'Cobertura medica y de cancelacion',      8000.00);  -- 5

-- ---------- RESERVAS ----------
-- Reserva 1: Juan (titular) compra para si mismo y para Ana (acompanante) en LC100.
INSERT INTO reserva (codigo_reserva, id_pasajero_titular, fecha_emision, estado, monto_total) VALUES
  ('RSV0001', 1, '2026-06-01 12:00:00', 'confirmada', 86000.00);   -- 1
-- Reserva 2: Carlos compra un pasaje a Bariloche (LC200), pendiente de pago aprobado.
INSERT INTO reserva (codigo_reserva, id_pasajero_titular, fecha_emision, estado, monto_total) VALUES
  ('RSV0002', 3, '2026-06-02 09:30:00', 'pendiente', 56500.00);    -- 2
-- Reserva 3: Valeria compra a Cordoba (LC100).
INSERT INTO reserva (codigo_reserva, id_pasajero_titular, fecha_emision, estado, monto_total) VALUES
  ('RSV0003', 4, '2026-06-03 16:45:00', 'confirmada', 39500.00);   -- 3

-- ---------- PASAJES ----------
-- Reserva 1 (LC100, aeronave LV-ABC): Juan asiento 1 (1A), Ana asiento 2 (1B).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000001', 1, 1, 1, 1, 'confirmado', 35000.00),   -- 1
  ('TK0000002', 1, 2, 1, 2, 'confirmado', 35000.00);   -- 2
-- Reserva 2 (LC200): Carlos sin asiento elegido aun.
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000003', 2, 3, 3, NULL, 'reservado', 52000.00); -- 3
-- Reserva 3 (LC100): Valeria asiento 3 (2A).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000004', 3, 4, 1, 3, 'confirmado', 35000.00);   -- 4

-- ---------- SERVICIOS CONTRATADOS POR PASAJE ----------
-- Juan: equipaje despachado + seleccion de asiento.
INSERT INTO pasaje_servicio (id_pasaje, id_servicio, cantidad, precio_aplicado) VALUES
  (1, 1, 1, 12000.00),
  (1, 3, 1, 4500.00);
-- Ana: seleccion de asiento.
INSERT INTO pasaje_servicio (id_pasaje, id_servicio, cantidad, precio_aplicado) VALUES
  (2, 3, 1, 4500.00);
-- Carlos: equipaje despachado + seguro de viaje.
INSERT INTO pasaje_servicio (id_pasaje, id_servicio, cantidad, precio_aplicado) VALUES
  (3, 1, 1, 12000.00),
  (3, 5, 1, 8000.00);
-- Valeria: seleccion de asiento.
INSERT INTO pasaje_servicio (id_pasaje, id_servicio, cantidad, precio_aplicado) VALUES
  (4, 3, 1, 4500.00);

-- ---------- PAGOS ----------
-- Reserva 1: un intento rechazado y luego un pago aprobado (confirma la reserva).
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha) VALUES
  (1, 86000.00, 'tarjeta_credito', 'rechazado', '2026-06-01 12:01:00'),
  (1, 86000.00, 'tarjeta_debito',  'aprobado',  '2026-06-01 12:05:00');
-- Reserva 2: solo pago pendiente -> sigue pendiente.
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha) VALUES
  (2, 56500.00, 'billetera_virtual', 'pendiente', '2026-06-02 09:31:00');
-- Reserva 3: pago aprobado por transferencia.
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha) VALUES
  (3, 39500.00, 'transferencia', 'aprobado', '2026-06-03 16:50:00');

-- ---------- CHECK-IN ----------
-- Juan y Valeria ya hicieron check-in para el vuelo LC100.
INSERT INTO checkin (id_pasaje, fecha_hora, tarjeta_embarque) VALUES
  (1, '2026-07-09 10:00:00', 'BP-LC100-1A'),
  (4, '2026-07-09 11:30:00', 'BP-LC100-2A');
