-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: consultas de ejemplo
-- Requiere 01_schema.sql + 02_datos_ejemplo.sql
-- ============================================================
USE aerolinea_lowcost;

-- ------------------------------------------------------------
-- 1) Busqueda de vuelos disponibles entre dos aeropuertos en una fecha,
--    mostrando disponibilidad (capacidad - pasajes activos).
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        org.codigo_iata AS origen,
        dst.codigo_iata AS destino,
        v.fecha_hora_salida,
        v.estado,
        v.precio_base,
        an.capacidad_maxima,
        an.capacidad_maxima - COUNT(p.id_pasaje) AS asientos_disponibles
FROM    vuelo v
JOIN    ruta r       ON r.id_ruta = v.id_ruta
JOIN    aeropuerto org ON org.codigo_iata = r.cod_aeropuerto_org
JOIN    aeropuerto dst ON dst.codigo_iata = r.cod_aeropuerto_dst
JOIN    aeronave an  ON an.matricula = v.matricula_aeronave
LEFT JOIN pasaje p   ON p.id_vuelo = v.id_vuelo
                     AND p.estado IN ('reservado','confirmado','utilizado')
WHERE   r.cod_aeropuerto_org = 'AEP'
  AND   r.cod_aeropuerto_dst = 'COR'
  AND   DATE(v.fecha_hora_salida) = '2026-07-10'
  AND   v.estado <> 'cancelado'
GROUP BY v.id_vuelo, org.codigo_iata, dst.codigo_iata,
         v.numero_vuelo, v.fecha_hora_salida, v.estado, v.precio_base, an.capacidad_maxima;

-- ------------------------------------------------------------
-- 2) Detalle completo de una reserva: pasajes, pasajeros y vuelos.
-- ------------------------------------------------------------
SELECT  res.codigo_reserva,
        res.estado AS estado_reserva,
        pas.codigo_ticket,
        CONCAT(pj.nombre, ' ', pj.apellido) AS pasajero,
        v.numero_vuelo,
        v.fecha_hora_salida,
        CONCAT(a.fila, a.letra) AS asiento,
        pas.estado AS estado_pasaje,
        pas.precio_base
FROM    reserva res
JOIN    pasaje pas ON pas.id_reserva = res.id_reserva
JOIN    pasajero pj ON pj.id_pasajero = pas.id_pasajero
JOIN    vuelo v ON v.id_vuelo = pas.id_vuelo
LEFT JOIN asiento a ON a.id_asiento = pas.id_asiento
WHERE   res.codigo_reserva = 'RSV0001';

-- ------------------------------------------------------------
-- 3) Servicios adicionales contratados por pasaje, con subtotal.
-- ------------------------------------------------------------
SELECT  pas.codigo_ticket,
        s.nombre AS servicio,
        ps.cantidad,
        ps.precio_aplicado,
        ps.cantidad * ps.precio_aplicado AS subtotal
FROM    pasaje_servicio ps
JOIN    pasaje pas ON pas.id_pasaje = ps.id_pasaje
JOIN    servicio_adicional s ON s.id_servicio = ps.id_servicio
ORDER BY pas.codigo_ticket, s.nombre;

-- ------------------------------------------------------------
-- 4) Total cobrado por reserva: pasajes + servicios, comparado contra
--    los pagos aprobados (permite ver si esta cubierta).
-- ------------------------------------------------------------
SELECT  res.codigo_reserva,
        res.estado,
        res.monto_total,
        COALESCE(pg.total_aprobado, 0) AS pagos_aprobados,
        CASE WHEN COALESCE(pg.total_aprobado, 0) >= res.monto_total
             THEN 'Cubierta' ELSE 'No cubierta' END AS situacion_pago
FROM    reserva res
LEFT JOIN (
        SELECT id_reserva, SUM(monto) AS total_aprobado
        FROM   pago
        WHERE  estado = 'aprobado'
        GROUP BY id_reserva
) pg ON pg.id_reserva = res.id_reserva
ORDER BY res.codigo_reserva;

-- ------------------------------------------------------------
-- 5) Ocupacion por vuelo: pasajes activos vs capacidad.
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        an.matricula,
        an.capacidad_maxima,
        COUNT(p.id_pasaje) AS pasajes_activos,
        ROUND(100 * COUNT(p.id_pasaje) / an.capacidad_maxima, 1) AS porcentaje_ocupacion
FROM    vuelo v
JOIN    aeronave an ON an.matricula = v.matricula_aeronave
LEFT JOIN pasaje p ON p.id_vuelo = v.id_vuelo
                   AND p.estado IN ('reservado','confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo, an.matricula, an.capacidad_maxima
ORDER BY porcentaje_ocupacion DESC;

-- ------------------------------------------------------------
-- 6) Tripulacion asignada a un vuelo.
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        e.legajo,
        e.nombre,
        ve.funcion
FROM    vuelo_empleado ve
JOIN    vuelo v   ON v.id_vuelo = ve.id_vuelo
JOIN    empleado e ON e.legajo = ve.legajo
WHERE   v.numero_vuelo = 'LC100'
ORDER BY FIELD(ve.funcion, 'piloto','copiloto','tripulante_cabina');

-- ------------------------------------------------------------
-- 7) Pasajeros que ya realizaron el check-in para un vuelo.
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        CONCAT(pj.nombre, ' ', pj.apellido) AS pasajero,
        c.fecha_hora AS fecha_checkin,
        c.tarjeta_embarque
FROM    checkin c
JOIN    pasaje p  ON p.id_pasaje = c.id_pasaje
JOIN    pasajero pj ON pj.id_pasajero = p.id_pasajero
JOIN    vuelo v   ON v.id_vuelo = p.id_vuelo
WHERE   v.numero_vuelo = 'LC100'
ORDER BY c.fecha_hora;

-- ------------------------------------------------------------
-- 8) Ingresos confirmados por vuelo (solo pasajes de reservas con pago
--    aprobado), incluyendo ingresos por servicios adicionales.
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        SUM(p.precio_base) AS ingresos_pasajes,
        COALESCE(SUM(serv.total_servicios), 0) AS ingresos_servicios,
        SUM(p.precio_base) + COALESCE(SUM(serv.total_servicios), 0) AS ingresos_totales
FROM    pasaje p
JOIN    vuelo v ON v.id_vuelo = p.id_vuelo
JOIN    reserva r ON r.id_reserva = p.id_reserva
LEFT JOIN (
        SELECT id_pasaje, SUM(cantidad * precio_aplicado) AS total_servicios
        FROM   pasaje_servicio
        GROUP BY id_pasaje
) serv ON serv.id_pasaje = p.id_pasaje
WHERE   r.estado = 'confirmada'
  AND   p.estado IN ('confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo
ORDER BY ingresos_totales DESC;
