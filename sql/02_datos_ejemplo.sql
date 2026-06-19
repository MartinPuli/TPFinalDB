-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: datos de ejemplo
-- Requiere haber ejecutado 01_schema.sql
--
-- Nota: reserva.monto_total NO se carga a mano. Se calcula solo
-- mediante los triggers a partir de los pasajes y servicios. Los
-- pagos se generan a partir de ese monto para garantizar que los
-- datos queden siempre consistentes.
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
  ('LV-ABC', 'Airbus A320',    4, 'operativa'),          -- capacidad baja a proposito (demo de regla de capacidad)
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
  (3, 1001, 'piloto'), (3, 1002, 'copiloto'), (3, 1003, 'tripulante_cabina'), (3, 1004, 'tripulante_cabina'),
  (4, 1001, 'piloto'), (4, 1002, 'copiloto'), (4, 1003, 'tripulante_cabina');

-- ---------- PASAJEROS ----------
INSERT INTO pasajero (nombre, apellido, email) VALUES
  ('Juan',    'Perez',  'juan.perez@mail.com'),     -- 1
  ('Ana',     'Gomez',  'ana.gomez@mail.com'),      -- 2
  ('Carlos',  'Lopez',  'carlos.lopez@mail.com'),   -- 3
  ('Valeria', 'Diaz',   'valeria.diaz@mail.com'),   -- 4
  ('Lucia',   'Mendez', 'lucia.mendez@mail.com'),   -- 5
  ('Martin',  'Rios',   'martin.rios@mail.com'),    -- 6
  ('Sofia',   'Luna',   'sofia.luna@mail.com');     -- 7

-- ---------- SERVICIOS ADICIONALES ----------
INSERT INTO servicio_adicional (nombre, descripcion, precio_base) VALUES
  ('Equipaje despachado',    'Valija de hasta 23 kg en bodega',   12000.00),  -- 1
  ('Equipaje de mano extra', 'Bolso de mano adicional',            6000.00),  -- 2
  ('Seleccion de asiento',   'Eleccion anticipada de asiento',     4500.00),  -- 3
  ('Embarque prioritario',   'Abordaje en el primer grupo',        3000.00),  -- 4
  ('Seguro de viaje',        'Cobertura medica y de cancelacion',  8000.00);  -- 5

-- ---------- RESERVAS ----------
-- Se insertan en estado 'pendiente' y con monto_total 0: los triggers
-- recalculan el monto al cargar pasajes y servicios. La confirmacion se
-- hace al final, una vez registrados los pagos aprobados.
INSERT INTO reserva (codigo_reserva, id_pasajero_titular, fecha_emision) VALUES
  ('RSV0001', 1, '2026-06-01 12:00:00'),   -- 1 Juan: el y Ana en LC100
  ('RSV0002', 3, '2026-06-02 09:30:00'),   -- 2 Carlos: LC200 (quedara pendiente)
  ('RSV0003', 4, '2026-06-03 16:45:00'),   -- 3 Valeria: LC100
  ('RSV0004', 5, '2026-06-04 10:15:00'),   -- 4 Lucia: LC100 (completa el avion)
  ('RSV0005', 6, '2026-06-05 20:05:00'),   -- 5 Martin: LC200
  ('RSV0006', 7, '2026-06-06 08:40:00');   -- 6 Sofia: LC300 (con un pasaje cancelado)

-- ---------- PASAJES ----------
-- Reserva 1 (LC100, LV-ABC): Juan asiento 1 (1A), Ana asiento 2 (1B).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000001', 1, 1, 1, 1,    'confirmado', 35000.00),   -- 1
  ('TK0000002', 1, 2, 1, 2,    'confirmado', 35000.00);   -- 2
-- Reserva 2 (LC200): Carlos sin asiento elegido aun.
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000003', 2, 3, 3, NULL, 'reservado',  52000.00);   -- 3
-- Reserva 3 (LC100): Valeria asiento 3 (2A).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000004', 3, 4, 1, 3,    'confirmado', 35000.00);   -- 4
-- Reserva 4 (LC100): Lucia asiento 4 (2B). Con esto el vuelo queda 4/4 (lleno).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000005', 4, 5, 1, 4,    'confirmado', 35000.00);   -- 5
-- Reserva 5 (LC200): Martin asiento 7 (2A de LV-XYZ).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000006', 5, 6, 3, 7,    'confirmado', 52000.00);   -- 6
-- Reserva 6 (LC300): Sofia asiento 9 (3A) confirmada; Martin habia reservado
-- pero su pasaje fue cancelado (no suma al monto ni ocupa capacidad).
INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base) VALUES
  ('TK0000007', 6, 7, 4, 9,    'confirmado', 48000.00),   -- 7
  ('TK0000008', 6, 6, 4, NULL, 'cancelado',  48000.00);   -- 8

-- ---------- SERVICIOS CONTRATADOS POR PASAJE ----------
INSERT INTO pasaje_servicio (id_pasaje, id_servicio, cantidad, precio_aplicado) VALUES
  (1, 1, 1, 12000.00), (1, 3, 1, 4500.00),   -- Juan: equipaje + seleccion de asiento
  (2, 3, 1, 4500.00),                         -- Ana: seleccion de asiento
  (3, 1, 1, 12000.00), (3, 5, 1, 8000.00),   -- Carlos: equipaje + seguro
  (4, 3, 1, 4500.00),                         -- Valeria: seleccion de asiento
  (5, 4, 1, 3000.00),                         -- Lucia: embarque prioritario
  (6, 1, 1, 12000.00), (6, 3, 1, 4500.00),   -- Martin: equipaje + seleccion de asiento
  (7, 5, 1, 8000.00),  (7, 3, 1, 4500.00);   -- Sofia: seguro + seleccion de asiento

-- ---------- PAGOS ----------
-- El monto de cada pago se toma del monto_total ya calculado por los
-- triggers, de modo que siempre cubra exactamente la reserva.
-- Reserva 1: un intento rechazado y luego un pago aprobado.
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 1, monto_total, 'tarjeta_credito', 'rechazado', '2026-06-01 12:01:00' FROM reserva WHERE id_reserva = 1;
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 1, monto_total, 'tarjeta_debito',  'aprobado',  '2026-06-01 12:05:00' FROM reserva WHERE id_reserva = 1;
-- Reserva 2: solo un pago pendiente -> la reserva no se confirma.
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 2, monto_total, 'billetera_virtual', 'pendiente', '2026-06-02 09:31:00' FROM reserva WHERE id_reserva = 2;
-- Reservas 3 a 6: pago aprobado por el total.
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 3, monto_total, 'transferencia',   'aprobado', '2026-06-03 16:50:00' FROM reserva WHERE id_reserva = 3;
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 4, monto_total, 'tarjeta_credito', 'aprobado', '2026-06-04 10:20:00' FROM reserva WHERE id_reserva = 4;
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 5, monto_total, 'tarjeta_debito',  'aprobado', '2026-06-05 20:10:00' FROM reserva WHERE id_reserva = 5;
INSERT INTO pago (id_reserva, monto, medio_pago, estado, fecha)
  SELECT 6, monto_total, 'transferencia',   'aprobado', '2026-06-06 08:45:00' FROM reserva WHERE id_reserva = 6;

-- ---------- CONFIRMACION DE RESERVAS ----------
-- El trigger trg_reserva_bu valida que existan pagos aprobados que cubran
-- el monto. La reserva 2 queda 'pendiente' por no tener pago aprobado.
UPDATE reserva SET estado = 'confirmada' WHERE id_reserva IN (1, 3, 4, 5, 6);

-- ---------- CHECK-IN ----------
-- Juan, Valeria y Lucia ya hicieron check-in para LC100 (Ana todavia no).
INSERT INTO checkin (id_pasaje, fecha_hora, tarjeta_embarque) VALUES
  (1, '2026-07-09 10:00:00', 'BP-LC100-1A'),
  (4, '2026-07-09 11:30:00', 'BP-LC100-2A'),
  (5, '2026-07-09 12:15:00', 'BP-LC100-2B');

-- ============================================================
-- DEMOSTRACION DE REGLAS (descomentar para ver el error esperado)
-- ============================================================
-- (a) Capacidad superada: LC100 ya esta 4/4. Un 5to pasaje activo debe fallar.
-- INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base)
--   VALUES ('TK0000099', 2, 7, 1, NULL, 'reservado', 35000.00);
--   -> ERROR 1644: se supera la capacidad de la aeronave del vuelo.
--
-- (b) Asiento de otra aeronave: el asiento 7 pertenece a LV-XYZ, no a LV-ABC (LC100).
-- INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base)
--   VALUES ('TK0000098', 2, 7, 1, 7, 'reservado', 35000.00);
--   -> ERROR 1644: el asiento asignado no pertenece a la aeronave del vuelo.
--
-- (c) Confirmar sin pago aprobado: la reserva 2 solo tiene un pago pendiente.
-- UPDATE reserva SET estado = 'confirmada' WHERE id_reserva = 2;
--   -> ERROR 1644: los pagos aprobados no cubren el monto total.
