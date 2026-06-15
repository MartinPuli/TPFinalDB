-- ============================================================
-- TP Final - Base de Datos
-- Dominio: Aerolinea Low Cost (Grupo 6)
-- Motor: MySQL 8.0+
-- Archivo: esquema (DDL) - tablas, constraints y triggers
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
  CONSTRAINT fk_asiento_aeronave FOREIGN KEY (matricula_aeronave) REFERENCES aeronave (matricula),
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
  CONSTRAINT chk_vuelo_precio  CHECK (precio_base >= 0)
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
  CONSTRAINT fk_ve_vuelo    FOREIGN KEY (id_vuelo) REFERENCES vuelo (id_vuelo),
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
  CONSTRAINT fk_pasaje_reserva  FOREIGN KEY (id_reserva)  REFERENCES reserva (id_reserva),
  CONSTRAINT fk_pasaje_pasajero FOREIGN KEY (id_pasajero) REFERENCES pasajero (id_pasajero),
  CONSTRAINT fk_pasaje_vuelo    FOREIGN KEY (id_vuelo)    REFERENCES vuelo (id_vuelo),
  CONSTRAINT fk_pasaje_asiento  FOREIGN KEY (id_asiento)  REFERENCES asiento (id_asiento),
  CONSTRAINT chk_pasaje_precio  CHECK (precio_base >= 0)
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
  CONSTRAINT fk_ps_pasaje   FOREIGN KEY (id_pasaje)   REFERENCES pasaje (id_pasaje),
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
  CONSTRAINT fk_checkin_pasaje FOREIGN KEY (id_pasaje) REFERENCES pasaje (id_pasaje)
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
  CONSTRAINT fk_pago_reserva FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva),
  CONSTRAINT chk_pago_monto CHECK (monto > 0)
) ENGINE=InnoDB;

-- ============================================================
-- TRIGGERS
-- ============================================================
-- Regla: la cantidad de pasajes activos de un vuelo no puede superar la
-- capacidad de la aeronave asignada. Ademas, si se asigna un asiento, este
-- debe pertenecer a la aeronave que opera el vuelo.
DELIMITER $$

CREATE TRIGGER trg_pasaje_capacidad_bi
BEFORE INSERT ON pasaje
FOR EACH ROW
BEGIN
  DECLARE v_capacidad INT;
  DECLARE v_ocupados  INT;
  DECLARE v_matricula VARCHAR(10);

  -- Solo cuentan los pasajes "activos" (no cancelados).
  IF NEW.estado IN ('reservado','confirmado','utilizado') THEN
    SELECT a.capacidad_maxima, a.matricula
      INTO v_capacidad, v_matricula
    FROM vuelo v
    JOIN aeronave a ON a.matricula = v.matricula_aeronave
    WHERE v.id_vuelo = NEW.id_vuelo;

    SELECT COUNT(*) INTO v_ocupados
    FROM pasaje p
    WHERE p.id_vuelo = NEW.id_vuelo
      AND p.estado IN ('reservado','confirmado','utilizado');

    IF v_ocupados + 1 > v_capacidad THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede vender el pasaje: se supera la capacidad de la aeronave del vuelo.';
    END IF;

    -- El asiento, si se indica, debe pertenecer a la aeronave del vuelo.
    IF NEW.id_asiento IS NOT NULL THEN
      IF (SELECT matricula_aeronave FROM asiento WHERE id_asiento = NEW.id_asiento) <> v_matricula THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'El asiento asignado no pertenece a la aeronave que opera el vuelo.';
      END IF;
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_pasaje_capacidad_bu
BEFORE UPDATE ON pasaje
FOR EACH ROW
BEGIN
  DECLARE v_capacidad INT;
  DECLARE v_ocupados  INT;
  DECLARE v_matricula VARCHAR(10);

  IF NEW.estado IN ('reservado','confirmado','utilizado') THEN
    SELECT a.capacidad_maxima, a.matricula
      INTO v_capacidad, v_matricula
    FROM vuelo v
    JOIN aeronave a ON a.matricula = v.matricula_aeronave
    WHERE v.id_vuelo = NEW.id_vuelo;

    -- Se excluye el propio pasaje del conteo.
    SELECT COUNT(*) INTO v_ocupados
    FROM pasaje p
    WHERE p.id_vuelo = NEW.id_vuelo
      AND p.id_pasaje <> NEW.id_pasaje
      AND p.estado IN ('reservado','confirmado','utilizado');

    IF v_ocupados + 1 > v_capacidad THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede actualizar el pasaje: se supera la capacidad de la aeronave del vuelo.';
    END IF;

    IF NEW.id_asiento IS NOT NULL THEN
      IF (SELECT matricula_aeronave FROM asiento WHERE id_asiento = NEW.id_asiento) <> v_matricula THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'El asiento asignado no pertenece a la aeronave que opera el vuelo.';
      END IF;
    END IF;
  END IF;
END$$

DELIMITER ;
