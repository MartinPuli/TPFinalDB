# Modelo conceptual (DER) — Aerolínea Low Cost

Diagrama Entidad-Relación del dominio. Se muestran las entidades, sus atributos
principales y las cardinalidades. Las entidades **PASAJE_SERVICIO** y
**VUELO_EMPLEADO** son asociativas (resuelven relaciones N:M con atributos).

```mermaid
erDiagram
    AEROPUERTO {
        char codigo_iata PK
        string nombre
        string ciudad
        string pais
    }
    RUTA {
        int id_ruta PK
        char cod_aeropuerto_org FK
        char cod_aeropuerto_dst FK
    }
    AERONAVE {
        string matricula PK
        string modelo
        int capacidad_maxima
        enum estado_operativo
    }
    ASIENTO {
        int id_asiento PK
        string matricula_aeronave FK
        int fila
        char letra
        enum tipo
    }
    VUELO {
        int id_vuelo PK
        string numero_vuelo
        int id_ruta FK
        string matricula_aeronave FK
        datetime fecha_hora_salida
        enum estado
        decimal precio_base
    }
    EMPLEADO {
        int legajo PK
        string nombre
        enum rol
    }
    VUELO_EMPLEADO {
        int id_vuelo PK,FK
        int legajo PK,FK
        enum funcion
    }
    PASAJERO {
        int id_pasajero PK
        string nombre
        string apellido
        string email
    }
    RESERVA {
        int id_reserva PK
        string codigo_reserva
        int id_pasajero_titular FK
        datetime fecha_emision
        enum estado
        decimal monto_total
    }
    PASAJE {
        int id_pasaje PK
        string codigo_ticket
        int id_reserva FK
        int id_pasajero FK
        int id_vuelo FK
        int id_asiento FK
        enum estado
        decimal precio_base
    }
    SERVICIO_ADICIONAL {
        int id_servicio PK
        string nombre
        string descripcion
        decimal precio_base
    }
    PASAJE_SERVICIO {
        int id_pasaje PK,FK
        int id_servicio PK,FK
        int cantidad
        decimal precio_aplicado
    }
    CHECKIN {
        int id_checkin PK
        int id_pasaje FK
        datetime fecha_hora
        string tarjeta_embarque
    }
    PAGO {
        int id_pago PK
        int id_reserva FK
        decimal monto
        enum medio_pago
        enum estado
        datetime fecha
    }

    AEROPUERTO ||--o{ RUTA : "es origen de"
    AEROPUERTO ||--o{ RUTA : "es destino de"
    RUTA ||--o{ VUELO : "se programa en"
    AERONAVE ||--o{ VUELO : "opera"
    AERONAVE ||--|{ ASIENTO : "posee"
    VUELO ||--o{ VUELO_EMPLEADO : "asigna"
    EMPLEADO ||--o{ VUELO_EMPLEADO : "participa en"
    PASAJERO ||--o{ RESERVA : "es titular de"
    RESERVA ||--|{ PASAJE : "incluye"
    PASAJERO ||--o{ PASAJE : "viaja en"
    VUELO ||--o{ PASAJE : "transporta"
    ASIENTO |o--o| PASAJE : "se asigna a"
    PASAJE ||--o{ PASAJE_SERVICIO : "contrata"
    SERVICIO_ADICIONAL ||--o{ PASAJE_SERVICIO : "se ofrece en"
    PASAJE ||--o| CHECKIN : "genera"
    RESERVA ||--o{ PAGO : "recibe"
```

## Cardinalidades (notación mín..máx)

| Relación | Lado A | Lado B |
|---|---|---|
| Aeropuerto–Ruta (origen) | Aeropuerto (1,1) | Ruta (0,N) |
| Aeropuerto–Ruta (destino) | Aeropuerto (1,1) | Ruta (0,N) |
| Ruta–Vuelo | Ruta (1,1) | Vuelo (0,N) |
| Aeronave–Vuelo | Aeronave (1,1) | Vuelo (0,N) |
| Aeronave–Asiento | Aeronave (1,1) | Asiento (1,N) |
| Vuelo–Empleado (asociativa) | Vuelo (0,N) | Empleado (0,N) |
| Pasajero–Reserva (titular) | Pasajero (1,1) | Reserva (0,N) |
| Reserva–Pasaje | Reserva (1,1) | Pasaje (1,N) |
| Pasajero–Pasaje | Pasajero (1,1) | Pasaje (0,N) |
| Vuelo–Pasaje | Vuelo (1,1) | Pasaje (0,N) |
| Asiento–Pasaje | Asiento (0,1) | Pasaje (0,1) |
| Pasaje–Servicio (asociativa) | Pasaje (0,N) | Servicio Adicional (0,N) |
| Pasaje–Check-in | Pasaje (1,1) | Check-in (0,1) |
| Reserva–Pago | Reserva (1,1) | Pago (0,N) |

## Observaciones de diseño

- **Ruta** conecta dos aeropuertos distintos (origen ≠ destino). Un mismo
  aeropuerto puede aparecer como origen o destino en muchas rutas, por eso hay
  dos relaciones separadas hacia `AEROPUERTO`.
- **Vuelo** requiere una aeronave asignada de forma obligatoria (1,1) para poder
  venderse; esto se modela con la FK `matricula_aeronave NOT NULL`.
- **Asiento–Pasaje** es 1:1 *dentro de un vuelo*: un pasaje puede tener 0 o 1
  asiento, y un asiento puede estar asignado a lo sumo a 1 pasaje en ese vuelo
  (se garantiza con `UNIQUE(id_vuelo, id_asiento)`).
- **Pasaje–Check-in** es 1:0..1: cada pasaje genera como máximo un check-in
  (`UNIQUE(id_pasaje)` en `CHECKIN`).
- Las entidades asociativas **PASAJE_SERVICIO** y **VUELO_EMPLEADO** llevan
  atributos propios (`cantidad`/`precio_aplicado` y `funcion` respectivamente).
