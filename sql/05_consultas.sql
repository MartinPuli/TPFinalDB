-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: consultas de ejemplo
-- Requiere 01_schema.sql + 02_datos_ejemplo.sql
-- (las consultas 12 y 13 usan vistas de 03_vistas.sql)
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

-- ------------------------------------------------------------
-- 9) Pasajeros frecuentes: cantidad de pasajes activos por pasajero.
-- ------------------------------------------------------------
SELECT  pj.id_pasajero,
        CONCAT(pj.nombre, ' ', pj.apellido) AS pasajero,
        COUNT(*) AS pasajes
FROM    pasaje p
JOIN    pasajero pj ON pj.id_pasajero = p.id_pasajero
WHERE   p.estado IN ('reservado','confirmado','utilizado')
GROUP BY pj.id_pasajero, pasajero
HAVING  COUNT(*) >= 1
ORDER BY pasajes DESC, pasajero;

-- ------------------------------------------------------------
-- 10) Ruta mas vendida (pasajes activos por ruta).
-- ------------------------------------------------------------
SELECT  CONCAT(r.cod_aeropuerto_org, '-', r.cod_aeropuerto_dst) AS ruta,
        COUNT(p.id_pasaje) AS pasajes_vendidos
FROM    ruta r
JOIN    vuelo v ON v.id_ruta = r.id_ruta
LEFT JOIN pasaje p ON p.id_vuelo = v.id_vuelo
                  AND p.estado IN ('reservado','confirmado','utilizado')
GROUP BY r.id_ruta, ruta
ORDER BY pasajes_vendidos DESC;

-- ------------------------------------------------------------
-- 11) Ranking de servicios adicionales mas contratados
--     (funcion de ventana RANK()).
-- ------------------------------------------------------------
SELECT  s.nombre AS servicio,
        SUM(ps.cantidad)                         AS unidades,
        SUM(ps.cantidad * ps.precio_aplicado)    AS recaudado,
        RANK() OVER (ORDER BY SUM(ps.cantidad) DESC) AS ranking
FROM    pasaje_servicio ps
JOIN    servicio_adicional s ON s.id_servicio = ps.id_servicio
JOIN    pasaje p ON p.id_pasaje = ps.id_pasaje
WHERE   p.estado <> 'cancelado'
GROUP BY s.id_servicio, s.nombre
ORDER BY ranking;

-- ------------------------------------------------------------
-- 12) Reservas cuyo monto NO esta cubierto por pagos aprobados
--     (usa la vista v_reserva_estado_pago).
-- ------------------------------------------------------------
SELECT  codigo_reserva,
        estado,
        monto_total,
        pagos_aprobados,
        saldo_pendiente
FROM    v_reserva_estado_pago
WHERE   situacion_pago = 'No cubierta'
ORDER BY saldo_pendiente DESC;

-- ------------------------------------------------------------
-- 13) Vuelos con ocupacion mayor o igual al 50% (usa v_ocupacion_vuelo).
-- ------------------------------------------------------------
SELECT  numero_vuelo,
        capacidad_maxima,
        pasajes_activos,
        porcentaje_ocupacion
FROM    v_ocupacion_vuelo
WHERE   porcentaje_ocupacion >= 50
ORDER BY porcentaje_ocupacion DESC;

-- ------------------------------------------------------------
-- 14) Pasajeros con pasaje confirmado que aun NO hicieron check-in
--     para un vuelo (anti-join con NOT EXISTS).
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        CONCAT(pj.nombre, ' ', pj.apellido) AS pasajero,
        p.codigo_ticket
FROM    pasaje p
JOIN    vuelo v    ON v.id_vuelo = p.id_vuelo
JOIN    pasajero pj ON pj.id_pasajero = p.id_pasajero
WHERE   v.numero_vuelo = 'LC100'
  AND   p.estado = 'confirmado'
  AND   NOT EXISTS (SELECT 1 FROM checkin c WHERE c.id_pasaje = p.id_pasaje)
ORDER BY pasajero;

-- ------------------------------------------------------------
-- 15) Precio promedio y total de pasajes (confirmados/utilizados) por vuelo.
-- ------------------------------------------------------------
SELECT  v.numero_vuelo,
        COUNT(p.id_pasaje)            AS pasajes,
        ROUND(AVG(p.precio_base), 2)  AS precio_promedio,
        SUM(p.precio_base)            AS total_pasajes
FROM    vuelo v
JOIN    pasaje p ON p.id_vuelo = v.id_vuelo
                AND p.estado IN ('confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo
ORDER BY total_pasajes DESC;

-- ------------------------------------------------------------
-- 16) Empleados y cantidad de vuelos en los que participan
--     (LEFT JOIN para incluir a los que no tienen asignaciones).
-- ------------------------------------------------------------
SELECT  e.legajo,
        e.nombre,
        e.rol,
        COUNT(ve.id_vuelo) AS vuelos_asignados
FROM    empleado e
LEFT JOIN vuelo_empleado ve ON ve.legajo = e.legajo
GROUP BY e.legajo, e.nombre, e.rol
ORDER BY vuelos_asignados DESC, e.legajo;

-- ------------------------------------------------------------
-- 17) Movimiento por aeropuerto: salidas y llegadas programadas
--     (subconsultas correlacionadas).
-- ------------------------------------------------------------
SELECT  a.codigo_iata,
        a.ciudad,
        (SELECT COUNT(*) FROM vuelo v JOIN ruta r ON r.id_ruta = v.id_ruta
          WHERE r.cod_aeropuerto_org = a.codigo_iata) AS salidas,
        (SELECT COUNT(*) FROM vuelo v JOIN ruta r ON r.id_ruta = v.id_ruta
          WHERE r.cod_aeropuerto_dst = a.codigo_iata) AS llegadas
FROM    aeropuerto a
ORDER BY salidas DESC, llegadas DESC, a.codigo_iata;

-- ------------------------------------------------------------
-- 18) Ranking de vuelos por ocupacion usando CTE + funcion de ventana.
-- ------------------------------------------------------------
WITH ocupacion AS (
  SELECT  v.numero_vuelo,
          COUNT(p.id_pasaje)  AS activos,
          an.capacidad_maxima AS capacidad
  FROM    vuelo v
  JOIN    aeronave an ON an.matricula = v.matricula_aeronave
  LEFT JOIN pasaje p ON p.id_vuelo = v.id_vuelo
                    AND p.estado IN ('reservado','confirmado','utilizado')
  GROUP BY v.id_vuelo, v.numero_vuelo, an.capacidad_maxima
)
SELECT  numero_vuelo,
        activos,
        capacidad,
        ROUND(100 * activos / capacidad, 1) AS porcentaje_ocupacion,
        RANK() OVER (ORDER BY activos / capacidad DESC) AS ranking
FROM    ocupacion
ORDER BY ranking, numero_vuelo;
