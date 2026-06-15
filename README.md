# TP Final — Base de Datos · Aerolínea Low Cost

Trabajos Prácticos Obligatorios — **Grupo 6**.
Dominio elegido: **funcionamiento de una aerolínea low cost** dedicada a la
comercialización de vuelos de pasajeros a través de una plataforma digital.

El sistema registra la venta de pasajes y la relación entre **pasajeros,
reservas, vuelos, pagos, servicios contratados, asientos, check-in, aeronaves,
rutas, aeropuertos y empleados** asignados a cada vuelo.

## Datos de la entrega

> **Materia:** _________________________  **Comisión:** ___________
> **Docente:** _________________________  **Fecha de entrega:** ___/___/______
> **Grupo:** 6
> **Integrantes:** ______________________________________________________
>
> *(Completar estos datos antes de entregar.)*

## Contenido del repositorio

Este repositorio cubre los dos trabajos prácticos obligatorios:

### TPO Nro 1 — Investigación y muestreo bibliográfico

| Archivo | Descripción |
|---|---|
| [`docs/TPO1_investigacion_bdoo.md`](docs/TPO1_investigacion_bdoo.md) | Trabajo de investigación sobre **bases de datos orientadas a objetos**, con comparación contra el modelo relacional, aplicación al dominio y bibliografía. |

### TPO Nro 2 — Modelo de datos del sistema de información

| Archivo | Descripción |
|---|---|
| [`docs/01_relevamiento.md`](docs/01_relevamiento.md) | Relevamiento narrativo, entidades y reglas de negocio. |
| [`docs/02_modelo_conceptual.md`](docs/02_modelo_conceptual.md) | Modelo conceptual (DER) con entidades, atributos y cardinalidades. |
| [`docs/03_modelo_relacional.md`](docs/03_modelo_relacional.md) | Pasaje a tablas: claves primarias, foráneas y notación relacional. |
| [`sql/01_schema.sql`](sql/01_schema.sql) | Script DDL para MySQL 8.0+ (tablas, constraints y triggers). |
| [`sql/02_datos_ejemplo.sql`](sql/02_datos_ejemplo.sql) | Datos de prueba representativos del dominio. |
| [`sql/03_consultas.sql`](sql/03_consultas.sql) | Consultas SQL de ejemplo sobre el modelo. |

## Motor de base de datos

El script está escrito para **MySQL 8.0+** (motor `InnoDB`, `CHECK`
constraints, `ENUM`, `SIGNAL` en triggers).

## Cómo ejecutarlo

```bash
# 1) Crear el esquema (DROP + CREATE de la base aerolinea_lowcost)
mysql -u root -p < sql/01_schema.sql

# 2) Cargar datos de ejemplo
mysql -u root -p aerolinea_lowcost < sql/02_datos_ejemplo.sql

# 3) Probar las consultas
mysql -u root -p aerolinea_lowcost < sql/03_consultas.sql
```

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
