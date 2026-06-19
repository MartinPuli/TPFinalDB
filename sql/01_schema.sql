-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Motor: MySQL 8.0+  (compatible con MariaDB 10.4+)
-- Archivo: esquema (DDL) - tablas, restricciones, indices,
--          funcion auxiliar y triggers de integridad.
-- ============================================================

DROP DATABASE IF EXISTS aerolinea_lowcost;
CREATE DATABASE aerolinea_lowcost
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE aerolinea_lowcost;

-- ------------------------------------------------------------
-- AEROPUERTO
-- ------------------------------------------------------------
CREATE TABLE aeropuerto (
  codigo_iata CHAR(3)      NOT NULL,
  nombre      VARCHAR(120) NOT NULL,
  ciudad      VARCHAR(80)  NOT NULL,
  pais        VARCHAR(80)  NOT NULL,
  PRIMARY KEY (codigo_iata)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- RUTA  (conexion origen -> destino entre dos aeropuertos)
-- ------------------------------------------------------------
CREATE TABLE ruta (
  id_ruta            INT     NOT NULL AUTO_INCREMENT,
  cod_aeropuerto_org CHAR(3) NOT NULL,
  cod_aeropuerto_dst CHAR(3) NOT NULL,
  PRIMARY KEY (id_ruta),
  CONSTRAINT uq_ruta UNIQUE (cod_aeropuerto_org, cod_aeropuerto_dst),
  CONSTRAINT fk_ruta_org FOREIGN KEY (cod_aeropuerto_org) REFERENCES aeropuerto (codigo_iata),
  CONSTRAINT fk_ruta_dst FOREIGN KEY (cod_aeropuerto_dst) REFERENCES aeropuerto (codigo_iata),
  CONSTRAINT chk_ruta_distinto CHECK (cod_aeropuerto_org <> cod_aeropuerto_dst)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- AERONAVE
-- ------------------------------------------------------------
CREATE TABLE aeronave (
  matricula        VARCHAR(10) NOT NULL,
  modelo           VARCHAR(60) NOT NULL,
  capacidad_maxima INT         NOT NULL,
  estado_operativo ENUM('operativa','en_mantenimiento','fuera_servicio')
                   NOT NULL DEFAULT 'operativa',
  PRIMARY KEY (matricula),
  CONSTRAINT chk_aeronave_cap CHECK (capacidad_maxima > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ASIENTO  (pertenece a una aeronave; identificado por fila + letra)
-- ------------------------------------------------------------
CREATE TABLE asiento (
  id_asiento         INT         NOT NULL AUTO_INCREMENT,
  matricula_aeronave VARCHAR(10) NOT NULL,
  fila               INT         NOT NULL,
  letra              CHAR(1)     NOT NULL,
  tipo               ENUM('comun','espacio_extra','salida_emergencia')
                     NOT NULL DEFAULT 'comun',
  PRIMARY KEY (id_asiento),
  CONSTRAINT uq_asiento UNIQUE (matricula_aeronave, fila, letra),
  CONSTRAINT fk_asiento_aeronave FOREIGN KEY (matricula_aeronave)
             REFERENCES aeronave (matricula) ON DELETE CASCADE,
  CONSTRAINT chk_asiento_fila CHECK (fila > 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- VUELO  (requiere aeronave asignada para poder venderse)
-- ------------------------------------------------------------
CREATE TABLE vuelo (
  id_vuelo           INT          NOT NULL AUTO_INCREMENT,
  numero_vuelo       VARCHAR(10)  NOT NULL,
  id_ruta            INT          NOT NULL,
  matricula_aeronave VARCHAR(10)  NOT NULL,
  fecha_hora_salida  DATETIME     NOT NULL,
  fecha_hora_llegada DATETIME     NULL,
  estado             ENUM('programado','demorado','cancelado','finalizado')
                     NOT NULL DEFAULT 'programado',
  precio_base        DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_vuelo),
  CONSTRAINT uq_vuelo UNIQUE (numero_vuelo, fecha_hora_salida),
  CONSTRAINT fk_vuelo_ruta     FOREIGN KEY (id_ruta)            REFERENCES ruta (id_ruta),
  CONSTRAINT fk_vuelo_aeronave FOREIGN KEY (matricula_aeronave) REFERENCES aeronave (matricula),
  CONSTRAINT chk_vuelo_precio  CHECK (precio_base >= 0),
  -- La llegada, si se conoce, debe ser posterior a la salida.
  CONSTRAINT chk_vuelo_fechas  CHECK (fecha_hora_llegada IS NULL
                                      OR fecha_hora_llegada > fecha_hora_salida),
  INDEX idx_vuelo_salida (fecha_hora_salida)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- EMPLEADO
-- ------------------------------------------------------------
CREATE TABLE empleado (
  legajo INT          NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  rol    ENUM('piloto','copiloto','tripulante_cabina','administrativo','atencion_cliente')
         NOT NULL,
  PRIMARY KEY (legajo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- VUELO_EMPLEADO  (asociativa N:M con atributo funcion)
-- ------------------------------------------------------------
CREATE TABLE vuelo_empleado (
  id_vuelo INT NOT NULL,
  legajo   INT NOT NULL,
  funcion  ENUM('piloto','copiloto','tripulante_cabina') NOT NULL,
  PRIMARY KEY (id_vuelo, legajo),
  CONSTRAINT fk_ve_vuelo    FOREIGN KEY (id_vuelo) REFERENCES vuelo (id_vuelo) ON DELETE CASCADE,
  CONSTRAINT fk_ve_empleado FOREIGN KEY (legajo)   REFERENCES empleado (legajo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PASAJERO
-- ------------------------------------------------------------
CREATE TABLE pasajero (
  id_pasajero INT          NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(80)  NOT NULL,
  apellido    VARCHAR(80)  NOT NULL,
  email       VARCHAR(120) NOT NULL,
  PRIMARY KEY (id_pasajero),
  CONSTRAINT uq_pasajero_email UNIQUE (email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- RESERVA  (operacion de compra de un pasajero titular)
-- monto_total es un valor DERIVADO (suma de pasajes + servicios no
-- cancelados); se mantiene automaticamente por triggers, por eso se
-- inicializa en 0 y no debe cargarse a mano.
-- ------------------------------------------------------------
CREATE TABLE reserva (
  id_reserva          INT          NOT NULL AUTO_INCREMENT,
  codigo_reserva      VARCHAR(10)  NOT NULL,
  id_pasajero_titular INT          NOT NULL,
  fecha_emision       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado              ENUM('pendiente','confirmada','cancelada')
                      NOT NULL DEFAULT 'pendiente',
  monto_total         DECIMAL(10,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id_reserva),
  CONSTRAINT uq_reserva_codigo UNIQUE (codigo_reserva),
  CONSTRAINT fk_reserva_titular FOREIGN KEY (id_pasajero_titular) REFERENCES pasajero (id_pasajero),
  CONSTRAINT chk_reserva_monto CHECK (monto_total >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PASAJE  (un pasajero + un vuelo; opcionalmente un asiento)
-- ------------------------------------------------------------
CREATE TABLE pasaje (
  id_pasaje     INT          NOT NULL AUTO_INCREMENT,
  codigo_ticket VARCHAR(15)  NOT NULL,
  id_reserva    INT          NOT NULL,
  id_pasajero   INT          NOT NULL,
  id_vuelo      INT          NOT NULL,
  id_asiento    INT          NULL,
  estado        ENUM('reservado','confirmado','cancelado','utilizado')
                NOT NULL DEFAULT 'reservado',
  precio_base   DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_pasaje),
  CONSTRAINT uq_pasaje_ticket UNIQUE (codigo_ticket),
  -- Un asiento no puede asignarse dos veces dentro del mismo vuelo.
  -- (MySQL permite multiples NULL, por lo que varios pasajes sin asiento son validos.)
  CONSTRAINT uq_pasaje_asiento_vuelo UNIQUE (id_vuelo, id_asiento),
  -- Un mismo pasajero no puede tener mas de un pasaje en el mismo vuelo.
  CONSTRAINT uq_pasaje_pasajero_vuelo UNIQUE (id_vuelo, id_pasajero),
  CONSTRAINT fk_pasaje_reserva  FOREIGN KEY (id_reserva)  REFERENCES reserva (id_reserva) ON DELETE CASCADE,
  CONSTRAINT fk_pasaje_pasajero FOREIGN KEY (id_pasajero) REFERENCES pasajero (id_pasajero),
  CONSTRAINT fk_pasaje_vuelo    FOREIGN KEY (id_vuelo)    REFERENCES vuelo (id_vuelo),
  CONSTRAINT fk_pasaje_asiento  FOREIGN KEY (id_asiento)  REFERENCES asiento (id_asiento),
  CONSTRAINT chk_pasaje_precio  CHECK (precio_base >= 0),
  INDEX idx_pasaje_vuelo_estado (id_vuelo, estado)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- SERVICIO_ADICIONAL
-- ------------------------------------------------------------
CREATE TABLE servicio_adicional (
  id_servicio INT          NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(80)  NOT NULL,
  descripcion VARCHAR(255) NULL,
  precio_base DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_servicio),
  CONSTRAINT uq_servicio_nombre UNIQUE (nombre),
  CONSTRAINT chk_servicio_precio CHECK (precio_base >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PASAJE_SERVICIO  (asociativa N:M con cantidad y precio aplicado)
-- ------------------------------------------------------------
CREATE TABLE pasaje_servicio (
  id_pasaje       INT NOT NULL,
  id_servicio     INT NOT NULL,
  cantidad        INT NOT NULL DEFAULT 1,
  precio_aplicado DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_pasaje, id_servicio),
  CONSTRAINT fk_ps_pasaje   FOREIGN KEY (id_pasaje)   REFERENCES pasaje (id_pasaje) ON DELETE CASCADE,
  CONSTRAINT fk_ps_servicio FOREIGN KEY (id_servicio) REFERENCES servicio_adicional (id_servicio),
  CONSTRAINT chk_ps_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_ps_precio   CHECK (precio_aplicado >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- CHECKIN  (1:0..1 con pasaje)
-- ------------------------------------------------------------
CREATE TABLE checkin (
  id_checkin       INT         NOT NULL AUTO_INCREMENT,
  id_pasaje        INT         NOT NULL,
  fecha_hora       DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tarjeta_embarque VARCHAR(30) NOT NULL,
  PRIMARY KEY (id_checkin),
  CONSTRAINT uq_checkin_pasaje UNIQUE (id_pasaje),
  CONSTRAINT fk_checkin_pasaje FOREIGN KEY (id_pasaje) REFERENCES pasaje (id_pasaje) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- PAGO  (una reserva puede tener varios pagos)
-- ------------------------------------------------------------
CREATE TABLE pago (
  id_pago    INT          NOT NULL AUTO_INCREMENT,
  id_reserva INT          NOT NULL,
  monto      DECIMAL(10,2) NOT NULL,
  medio_pago ENUM('tarjeta_credito','tarjeta_debito','transferencia','billetera_virtual')
             NOT NULL,
  estado     ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
  fecha      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pago),
  CONSTRAINT fk_pago_reserva FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva) ON DELETE CASCADE,
  CONSTRAINT chk_pago_monto CHECK (monto > 0),
  INDEX idx_pago_reserva_estado (id_reserva, estado)
) ENGINE=InnoDB;

-- ============================================================
-- FUNCION AUXILIAR Y TRIGGERS
-- ============================================================
DELIMITER $$

-- ------------------------------------------------------------
-- fn_total_reserva: monto total de una reserva = suma de los
-- pasajes NO cancelados + suma de sus servicios contratados.
-- Es la fuente de verdad de reserva.monto_total.
-- ------------------------------------------------------------
CREATE FUNCTION fn_total_reserva(p_id_reserva INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
  DECLARE v_pasajes   DECIMAL(12,2);
  DECLARE v_servicios DECIMAL(12,2);

  SELECT COALESCE(SUM(precio_base), 0) INTO v_pasajes
  FROM   pasaje
  WHERE  id_reserva = p_id_reserva
    AND  estado <> 'cancelado';

  SELECT COALESCE(SUM(ps.cantidad * ps.precio_aplicado), 0) INTO v_servicios
  FROM   pasaje_servicio ps
  JOIN   pasaje p ON p.id_pasaje = ps.id_pasaje
  WHERE  p.id_reserva = p_id_reserva
    AND  p.estado <> 'cancelado';

  RETURN v_pasajes + v_servicios;
END$$

-- ------------------------------------------------------------
-- Capacidad y validacion de asiento al INSERTAR un pasaje.
-- Regla: los pasajes activos de un vuelo no pueden superar la
-- capacidad de la aeronave. Si se asigna asiento, debe pertenecer
-- a la aeronave que opera el vuelo.
-- ------------------------------------------------------------
CREATE TRIGGER trg_pasaje_bi
BEFORE INSERT ON pasaje
FOR EACH ROW
BEGIN
  DECLARE v_capacidad INT;
  DECLARE v_ocupados  INT;
  DECLARE v_matricula VARCHAR(10);

  SELECT a.capacidad_maxima, a.matricula
    INTO v_capacidad, v_matricula
  FROM vuelo v
  JOIN aeronave a ON a.matricula = v.matricula_aeronave
  WHERE v.id_vuelo = NEW.id_vuelo;

  -- El asiento, si se indica, debe pertenecer a la aeronave del vuelo.
  IF NEW.id_asiento IS NOT NULL
     AND (SELECT matricula_aeronave FROM asiento WHERE id_asiento = NEW.id_asiento) <> v_matricula THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El asiento asignado no pertenece a la aeronave que opera el vuelo.';
  END IF;

  -- Solo los pasajes activos (no cancelados) ocupan capacidad.
  IF NEW.estado IN ('reservado','confirmado','utilizado') THEN
    SELECT COUNT(*) INTO v_ocupados
    FROM pasaje
    WHERE id_vuelo = NEW.id_vuelo
      AND estado IN ('reservado','confirmado','utilizado');

    IF v_ocupados + 1 > v_capacidad THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede vender el pasaje: se supera la capacidad de la aeronave del vuelo.';
    END IF;
  END IF;
END$$

-- ------------------------------------------------------------
-- Misma validacion al ACTUALIZAR un pasaje (excluye su propia fila
-- del conteo para no contarse dos veces).
-- ------------------------------------------------------------
CREATE TRIGGER trg_pasaje_bu
BEFORE UPDATE ON pasaje
FOR EACH ROW
BEGIN
  DECLARE v_capacidad INT;
  DECLARE v_ocupados  INT;
  DECLARE v_matricula VARCHAR(10);

  SELECT a.capacidad_maxima, a.matricula
    INTO v_capacidad, v_matricula
  FROM vuelo v
  JOIN aeronave a ON a.matricula = v.matricula_aeronave
  WHERE v.id_vuelo = NEW.id_vuelo;

  IF NEW.id_asiento IS NOT NULL
     AND (SELECT matricula_aeronave FROM asiento WHERE id_asiento = NEW.id_asiento) <> v_matricula THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El asiento asignado no pertenece a la aeronave que opera el vuelo.';
  END IF;

  IF NEW.estado IN ('reservado','confirmado','utilizado') THEN
    SELECT COUNT(*) INTO v_ocupados
    FROM pasaje
    WHERE id_vuelo = NEW.id_vuelo
      AND id_pasaje <> NEW.id_pasaje
      AND estado IN ('reservado','confirmado','utilizado');

    IF v_ocupados + 1 > v_capacidad THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede actualizar el pasaje: se supera la capacidad de la aeronave del vuelo.';
    END IF;
  END IF;
END$$

-- ------------------------------------------------------------
-- Mantenimiento automatico de reserva.monto_total ante cambios en
-- los pasajes y en los servicios contratados.
-- ------------------------------------------------------------
CREATE TRIGGER trg_pasaje_ai
AFTER INSERT ON pasaje
FOR EACH ROW
BEGIN
  UPDATE reserva SET monto_total = fn_total_reserva(NEW.id_reserva)
  WHERE id_reserva = NEW.id_reserva;
END$$

CREATE TRIGGER trg_pasaje_au
AFTER UPDATE ON pasaje
FOR EACH ROW
BEGIN
  UPDATE reserva SET monto_total = fn_total_reserva(NEW.id_reserva)
  WHERE id_reserva = NEW.id_reserva;
  IF OLD.id_reserva <> NEW.id_reserva THEN
    UPDATE reserva SET monto_total = fn_total_reserva(OLD.id_reserva)
    WHERE id_reserva = OLD.id_reserva;
  END IF;
END$$

CREATE TRIGGER trg_pasaje_ad
AFTER DELETE ON pasaje
FOR EACH ROW
BEGIN
  UPDATE reserva SET monto_total = fn_total_reserva(OLD.id_reserva)
  WHERE id_reserva = OLD.id_reserva;
END$$

CREATE TRIGGER trg_ps_ai
AFTER INSERT ON pasaje_servicio
FOR EACH ROW
BEGIN
  DECLARE v_reserva INT;
  SELECT id_reserva INTO v_reserva FROM pasaje WHERE id_pasaje = NEW.id_pasaje;
  UPDATE reserva SET monto_total = fn_total_reserva(v_reserva) WHERE id_reserva = v_reserva;
END$$

CREATE TRIGGER trg_ps_au
AFTER UPDATE ON pasaje_servicio
FOR EACH ROW
BEGIN
  DECLARE v_reserva INT;
  SELECT id_reserva INTO v_reserva FROM pasaje WHERE id_pasaje = NEW.id_pasaje;
  UPDATE reserva SET monto_total = fn_total_reserva(v_reserva) WHERE id_reserva = v_reserva;
END$$

CREATE TRIGGER trg_ps_ad
AFTER DELETE ON pasaje_servicio
FOR EACH ROW
BEGIN
  DECLARE v_reserva INT;
  SELECT id_reserva INTO v_reserva FROM pasaje WHERE id_pasaje = OLD.id_pasaje;
  UPDATE reserva SET monto_total = fn_total_reserva(v_reserva) WHERE id_reserva = v_reserva;
END$$

-- ------------------------------------------------------------
-- Una reserva solo puede pasar a 'confirmada' si la suma de sus
-- pagos APROBADOS cubre el monto total.
-- ------------------------------------------------------------
CREATE TRIGGER trg_reserva_bu
BEFORE UPDATE ON reserva
FOR EACH ROW
BEGIN
  DECLARE v_pagado DECIMAL(12,2);
  IF NEW.estado = 'confirmada' AND OLD.estado <> 'confirmada' THEN
    SELECT COALESCE(SUM(monto), 0) INTO v_pagado
    FROM pago
    WHERE id_reserva = NEW.id_reserva
      AND estado = 'aprobado';

    IF v_pagado < NEW.monto_total THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede confirmar la reserva: los pagos aprobados no cubren el monto total.';
    END IF;
  END IF;
END$$

DELIMITER ;
