-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: vistas
-- Requiere 01_schema.sql (las vistas no dependen de los datos).
-- ============================================================
USE aerolinea_lowcost;

-- ------------------------------------------------------------
-- v_vuelo_disponibilidad
-- Vuelos con su ruta, capacidad, pasajes activos y asientos libres.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_vuelo_disponibilidad AS
SELECT  v.id_vuelo,
        v.numero_vuelo,
        org.codigo_iata                     AS origen,
        dst.codigo_iata                     AS destino,
        v.fecha_hora_salida,
        v.estado,
        v.precio_base,
        an.matricula,
        an.capacidad_maxima,
        COUNT(p.id_pasaje)                  AS pasajes_activos,
        an.capacidad_maxima - COUNT(p.id_pasaje) AS asientos_disponibles
FROM    vuelo v
JOIN    ruta r        ON r.id_ruta = v.id_ruta
JOIN    aeropuerto org ON org.codigo_iata = r.cod_aeropuerto_org
JOIN    aeropuerto dst ON dst.codigo_iata = r.cod_aeropuerto_dst
JOIN    aeronave an   ON an.matricula = v.matricula_aeronave
LEFT JOIN pasaje p    ON p.id_vuelo = v.id_vuelo
                     AND p.estado IN ('reservado','confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo, org.codigo_iata, dst.codigo_iata,
         v.fecha_hora_salida, v.estado, v.precio_base, an.matricula, an.capacidad_maxima;

-- ------------------------------------------------------------
-- v_reserva_detalle
-- Una fila por pasaje, con su reserva, pasajero, vuelo y asiento.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_reserva_detalle AS
SELECT  res.id_reserva,
        res.codigo_reserva,
        res.estado                          AS estado_reserva,
        CONCAT(tit.nombre, ' ', tit.apellido) AS titular,
        pas.id_pasaje,
        pas.codigo_ticket,
        CONCAT(pj.nombre, ' ', pj.apellido) AS pasajero,
        v.numero_vuelo,
        v.fecha_hora_salida,
        CONCAT(a.fila, a.letra)             AS asiento,
        pas.estado                          AS estado_pasaje,
        pas.precio_base
FROM    reserva res
JOIN    pasajero tit ON tit.id_pasajero = res.id_pasajero_titular
JOIN    pasaje pas   ON pas.id_reserva = res.id_reserva
JOIN    pasajero pj  ON pj.id_pasajero = pas.id_pasajero
JOIN    vuelo v      ON v.id_vuelo = pas.id_vuelo
LEFT JOIN asiento a  ON a.id_asiento = pas.id_asiento;

-- ------------------------------------------------------------
-- v_reserva_estado_pago
-- Estado de cobro de cada reserva: monto total vs pagos aprobados.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_reserva_estado_pago AS
SELECT  res.id_reserva,
        res.codigo_reserva,
        res.estado,
        res.monto_total,
        COALESCE(pg.total_aprobado, 0)      AS pagos_aprobados,
        res.monto_total - COALESCE(pg.total_aprobado, 0) AS saldo_pendiente,
        CASE WHEN COALESCE(pg.total_aprobado, 0) >= res.monto_total
             THEN 'Cubierta' ELSE 'No cubierta' END AS situacion_pago
FROM    reserva res
LEFT JOIN (
        SELECT id_reserva, SUM(monto) AS total_aprobado
        FROM   pago
        WHERE  estado = 'aprobado'
        GROUP BY id_reserva
) pg ON pg.id_reserva = res.id_reserva;

-- ------------------------------------------------------------
-- v_ocupacion_vuelo
-- Ocupacion (pasajes activos / capacidad) por vuelo.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_ocupacion_vuelo AS
SELECT  v.id_vuelo,
        v.numero_vuelo,
        an.matricula,
        an.capacidad_maxima,
        COUNT(p.id_pasaje) AS pasajes_activos,
        ROUND(100 * COUNT(p.id_pasaje) / an.capacidad_maxima, 1) AS porcentaje_ocupacion
FROM    vuelo v
JOIN    aeronave an ON an.matricula = v.matricula_aeronave
LEFT JOIN pasaje p  ON p.id_vuelo = v.id_vuelo
                   AND p.estado IN ('reservado','confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo, an.matricula, an.capacidad_maxima;

-- ------------------------------------------------------------
-- v_ingresos_vuelo
-- Ingresos por vuelo (pasajes + servicios) considerando solo pasajes
-- de reservas confirmadas y en estado confirmado/utilizado.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_ingresos_vuelo AS
SELECT  v.id_vuelo,
        v.numero_vuelo,
        SUM(p.precio_base)                            AS ingresos_pasajes,
        COALESCE(SUM(serv.total_servicios), 0)        AS ingresos_servicios,
        SUM(p.precio_base) + COALESCE(SUM(serv.total_servicios), 0) AS ingresos_totales
FROM    pasaje p
JOIN    vuelo v   ON v.id_vuelo = p.id_vuelo
JOIN    reserva r ON r.id_reserva = p.id_reserva
LEFT JOIN (
        SELECT id_pasaje, SUM(cantidad * precio_aplicado) AS total_servicios
        FROM   pasaje_servicio
        GROUP BY id_pasaje
) serv ON serv.id_pasaje = p.id_pasaje
WHERE   r.estado = 'confirmada'
  AND   p.estado IN ('confirmado','utilizado')
GROUP BY v.id_vuelo, v.numero_vuelo;

-- ------------------------------------------------------------
-- v_tripulacion_vuelo
-- Empleados asignados a cada vuelo con su funcion.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_tripulacion_vuelo AS
SELECT  v.id_vuelo,
        v.numero_vuelo,
        e.legajo,
        e.nombre,
        ve.funcion
FROM    vuelo_empleado ve
JOIN    vuelo v    ON v.id_vuelo = ve.id_vuelo
JOIN    empleado e ON e.legajo = ve.legajo;

-- ============================================================
-- Ejemplos de uso de las vistas
-- ============================================================
SELECT * FROM v_vuelo_disponibilidad   ORDER BY fecha_hora_salida;
SELECT * FROM v_reserva_detalle        WHERE codigo_reserva = 'RSV0001';
SELECT * FROM v_reserva_estado_pago    ORDER BY codigo_reserva;
SELECT * FROM v_ocupacion_vuelo        ORDER BY porcentaje_ocupacion DESC;
SELECT * FROM v_ingresos_vuelo         ORDER BY ingresos_totales DESC;
SELECT * FROM v_tripulacion_vuelo      WHERE numero_vuelo = 'LC100';
