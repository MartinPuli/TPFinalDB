-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Archivo: procedimientos y funciones almacenadas
-- Requiere 01_schema.sql + 02_datos_ejemplo.sql
-- ============================================================
USE aerolinea_lowcost;

DROP FUNCTION  IF EXISTS fn_asientos_disponibles;
DROP PROCEDURE IF EXISTS sp_vender_pasaje;
DROP PROCEDURE IF EXISTS sp_confirmar_reserva;
DROP PROCEDURE IF EXISTS sp_registrar_checkin;
DROP PROCEDURE IF EXISTS sp_cancelar_pasaje;

DELIMITER $$

-- ------------------------------------------------------------
-- fn_asientos_disponibles: asientos libres de un vuelo
-- (capacidad de la aeronave - pasajes activos).
-- ------------------------------------------------------------
CREATE FUNCTION fn_asientos_disponibles(p_id_vuelo INT)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_capacidad INT;
  DECLARE v_ocupados  INT;

  SELECT a.capacidad_maxima INTO v_capacidad
  FROM   vuelo v
  JOIN   aeronave a ON a.matricula = v.matricula_aeronave
  WHERE  v.id_vuelo = p_id_vuelo;

  SELECT COUNT(*) INTO v_ocupados
  FROM   pasaje
  WHERE  id_vuelo = p_id_vuelo
    AND  estado IN ('reservado','confirmado','utilizado');

  RETURN COALESCE(v_capacidad, 0) - v_ocupados;
END$$

-- ------------------------------------------------------------
-- sp_vender_pasaje: agrega un pasaje a una reserva. Los triggers
-- validan capacidad y asiento, y recalculan el monto de la reserva.
-- Devuelve el id del pasaje creado y le asigna un codigo de ticket.
-- ------------------------------------------------------------
CREATE PROCEDURE sp_vender_pasaje(
  IN  p_id_reserva  INT,
  IN  p_id_pasajero INT,
  IN  p_id_vuelo    INT,
  IN  p_id_asiento  INT,
  IN  p_precio_base DECIMAL(10,2),
  OUT p_id_pasaje   INT)
BEGIN
  INSERT INTO pasaje (codigo_ticket, id_reserva, id_pasajero, id_vuelo, id_asiento, estado, precio_base)
  VALUES (CONCAT('TMP-', LPAD(FLOOR(RAND() * 1000000000), 10, '0')),
          p_id_reserva, p_id_pasajero, p_id_vuelo, p_id_asiento, 'reservado', p_precio_base);

  SET p_id_pasaje = LAST_INSERT_ID();

  UPDATE pasaje
  SET    codigo_ticket = CONCAT('TK', LPAD(p_id_pasaje, 7, '0'))
  WHERE  id_pasaje = p_id_pasaje;
END$$

-- ------------------------------------------------------------
-- sp_confirmar_reserva: confirma una reserva (y sus pasajes).
-- El trigger trg_reserva_bu rechaza la operacion si los pagos
-- aprobados no cubren el monto total.
-- ------------------------------------------------------------
CREATE PROCEDURE sp_confirmar_reserva(IN p_id_reserva INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM reserva WHERE id_reserva = p_id_reserva) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva indicada no existe.';
  END IF;

  UPDATE reserva SET estado = 'confirmada' WHERE id_reserva = p_id_reserva;

  UPDATE pasaje SET estado = 'confirmado'
  WHERE  id_reserva = p_id_reserva AND estado = 'reservado';
END$$

-- ------------------------------------------------------------
-- sp_registrar_checkin: genera el check-in de un pasaje confirmado.
-- ------------------------------------------------------------
CREATE PROCEDURE sp_registrar_checkin(IN p_id_pasaje INT)
BEGIN
  DECLARE v_estado VARCHAR(20);

  SELECT estado INTO v_estado FROM pasaje WHERE id_pasaje = p_id_pasaje;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El pasaje indicado no existe.';
  END IF;
  IF v_estado <> 'confirmado' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede hacer check-in de pasajes confirmados.';
  END IF;

  INSERT INTO checkin (id_pasaje, tarjeta_embarque)
  VALUES (p_id_pasaje, CONCAT('BP-', LPAD(p_id_pasaje, 6, '0')));
END$$

-- ------------------------------------------------------------
-- sp_cancelar_pasaje: cancela un pasaje y libera su asiento. El
-- monto de la reserva se recalcula solo (excluye los cancelados).
-- ------------------------------------------------------------
CREATE PROCEDURE sp_cancelar_pasaje(IN p_id_pasaje INT)
BEGIN
  UPDATE pasaje
  SET    estado = 'cancelado',
         id_asiento = NULL
  WHERE  id_pasaje = p_id_pasaje;
END$$

DELIMITER ;

-- ============================================================
-- Ejemplos de uso
-- ============================================================

-- Funciones (consulta directa, no modifican datos):
SELECT fn_asientos_disponibles(1) AS libres_LC100,
       fn_asientos_disponibles(3) AS libres_LC200,
       fn_total_reserva(1)        AS total_RSV0001;

-- Procedimiento dentro de una transaccion que se revierte, para
-- demostrar el comportamiento sin alterar los datos de ejemplo.
START TRANSACTION;
CALL sp_vender_pasaje(2, 7, 3, NULL, 52000.00, @nuevo_pasaje);
SELECT @nuevo_pasaje           AS id_pasaje_nuevo,
       fn_asientos_disponibles(3) AS libres_LC200_tras_venta;
ROLLBACK;

-- Otros ejemplos de invocacion (descomentar para ejecutar):
-- CALL sp_confirmar_reserva(2);     -- falla: pagos aprobados no cubren el monto
-- CALL sp_registrar_checkin(2);     -- registra el check-in del pasaje 2 (Ana)
-- CALL sp_cancelar_pasaje(6);       -- cancela el pasaje 6 y recalcula la reserva 5
