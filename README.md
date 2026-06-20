# TP Final — Base de Datos · Aerolínea Low Cost

Trabajos Prácticos Obligatorios — **Grupo 6**.
Dominio elegido: **funcionamiento de una aerolínea low cost** dedicada a la
comercialización de vuelos de pasajeros a través de una plataforma digital.

El sistema registra la venta de pasajes y la relación entre **pasajeros,
reservas, vuelos, pagos, servicios contratados, asientos, check-in, aeronaves,
rutas, aeropuertos y empleados** asignados a cada vuelo.

## Datos de la entrega

| Campo | Dato |
|---|---|
| **Materia** | _(completar)_ |
| **Comisión** | _(completar)_ |
| **Docente** | _(completar)_ |
| **Grupo** | 6 |
| **Integrantes** | Martín Pulitano _(agregar compañeros del grupo)_ |
| **Fecha de entrega** | 20/06/2026 |

> Completá los campos marcados con _(completar)_ antes de entregar.

## Contenido del repositorio

Este repositorio cubre los dos trabajos prácticos obligatorios:

### TPO Nro 1 — Investigación y muestreo bibliográfico

| Archivo | Descripción |
|---|---|
| [`docs/TPO1_investigacion_bdoo.md`](docs/TPO1_investigacion_bdoo.md) | Trabajo de investigación sobre **bases de datos orientadas a objetos**, con comparación contra el modelo relacional, aplicación al dominio y bibliografía. |

### TPO Nro 2 — Modelo de datos del sistema de información

**Documentación**

| Archivo | Descripción |
|---|---|
| [`docs/01_relevamiento.md`](docs/01_relevamiento.md) | Relevamiento narrativo, entidades y reglas de negocio. |
| [`docs/02_modelo_conceptual.md`](docs/02_modelo_conceptual.md) | Modelo conceptual (DER) con entidades, atributos y cardinalidades. |
| [`docs/03_modelo_relacional.md`](docs/03_modelo_relacional.md) | Pasaje a tablas: claves primarias, foráneas, índices y reglas. |
| [`docs/04_normalizacion.md`](docs/04_normalizacion.md) | Análisis de normalización (hasta FNBC) tabla por tabla. |
| [`docs/05_diccionario_datos.md`](docs/05_diccionario_datos.md) | Diccionario de datos: cada tabla, columna y objeto del esquema. |
| [`docs/DER_aerolinea.drawio`](docs/DER_aerolinea.drawio) | Diagrama entidad-relación **editable** (draw.io / diagrams.net). También en [`.png`](docs/DER_aerolinea.png) y [`.svg`](docs/DER_aerolinea.svg). |

**Scripts SQL** (ejecutar en este orden)

| Archivo | Descripción |
|---|---|
| [`sql/01_schema.sql`](sql/01_schema.sql) | DDL para MySQL 8.0+ (tablas, constraints, índices, función y triggers). |
| [`sql/02_datos_ejemplo.sql`](sql/02_datos_ejemplo.sql) | Datos de prueba consistentes del dominio. |
| [`sql/03_vistas.sql`](sql/03_vistas.sql) | Vistas de consulta (disponibilidad, ocupación, ingresos, etc.). |
| [`sql/04_procedimientos.sql`](sql/04_procedimientos.sql) | Procedimientos y funciones almacenadas. |
| [`sql/05_consultas.sql`](sql/05_consultas.sql) | 18 consultas de ejemplo (joins, subconsultas, CTE, funciones de ventana). |

## Motor de base de datos

El script está escrito para **MySQL 8.0+** (motor `InnoDB`, `CHECK`
constraints, `ENUM`, `SIGNAL` en triggers).

## Cómo ejecutarlo

```bash
# 1) Crear el esquema (DROP + CREATE de la base aerolinea_lowcost)
mysql -u root -p < sql/01_schema.sql

# 2) Cargar datos de ejemplo
mysql -u root -p aerolinea_lowcost < sql/02_datos_ejemplo.sql

# 3) Crear las vistas
mysql -u root -p aerolinea_lowcost < sql/03_vistas.sql

# 4) Crear procedimientos y funciones
mysql -u root -p aerolinea_lowcost < sql/04_procedimientos.sql

# 5) Probar las consultas
mysql -u root -p aerolinea_lowcost < sql/05_consultas.sql
```

> Los cinco scripts fueron verificados ejecutándolos de punta a punta sobre
> MariaDB 11 / MySQL 8 sin errores. Las reglas de negocio (capacidad, asiento,
> confirmación por pago, pasajero único por vuelo, llegada > salida) se probaron
> y rechazan correctamente las operaciones inválidas.

## Reglas de negocio principales

1. Una reserva debe incluir **al menos un pasaje**.
2. Cada pasaje corresponde a **un único pasajero** y a **un único vuelo**.
3. Un vuelo debe tener una **aeronave asignada** para poder venderse.
4. La cantidad de pasajes activos de un vuelo **no puede superar la capacidad**
   de la aeronave asignada.
5. Un **asiento no puede asignarse dos veces** dentro del mismo vuelo.
6. Los servicios adicionales son opcionales, pero si se contratan se registran
   con su **cantidad y precio aplicado** al momento de la compra.
7. Una reserva solo se considera **confirmada** si existe un pago aprobado que
   cubra el monto correspondiente.
8. Un **mismo pasajero no puede tener dos pasajes en el mismo vuelo**.
9. La **llegada** de un vuelo, si se conoce, debe ser **posterior a la salida**.

El `monto_total` de cada reserva es un dato derivado que se mantiene
**automáticamente** mediante triggers (suma de pasajes no cancelados +
servicios); nunca se carga ni se actualiza a mano.
