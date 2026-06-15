# Relevamiento narrativo — Aerolínea Low Cost

## Introducción del dominio

El dominio elegido es el funcionamiento de una **aerolínea low cost** dedicada a
la comercialización de vuelos de pasajeros. La empresa opera principalmente
mediante una plataforma digital, desde la cual los usuarios pueden buscar vuelos
disponibles, realizar reservas, pagar sus pasajes, contratar servicios
adicionales y efectuar el check-in antes del viaje.

El modelo low cost se caracteriza por ofrecer una **tarifa base accesible**,
donde el pasaje incluye únicamente el derecho a viajar en un vuelo determinado.
A diferencia de una aerolínea tradicional, varios servicios se ofrecen como
**prestaciones opcionales**: selección de asiento, equipaje adicional, embarque
prioritario, seguro de viaje o cambios flexibles.

Por este motivo, el sistema debe registrar no solo la venta de pasajes, sino
también la relación entre pasajeros, reservas, vuelos, pagos, servicios
contratados, asientos, check-in, aeronaves, rutas, aeropuertos y empleados
asignados a cada vuelo.

## Relevamiento narrativo

La empresa relevada es una aerolínea low cost que ofrece vuelos comerciales
dentro del país y hacia algunos destinos regionales. Su operación se apoya en
una plataforma web y una aplicación móvil, donde los pasajeros realizan la mayor
parte del proceso de compra y gestión de sus viajes.

**Búsqueda de vuelos.** El proceso comienza cuando una persona ingresa a la
plataforma para buscar vuelos indicando un aeropuerto de origen, un aeropuerto
de destino y una fecha de salida (y opcionalmente una fecha de regreso). El
sistema consulta los vuelos programados y muestra el número de vuelo, la fecha y
horario de salida, el estado del vuelo, el precio base y la disponibilidad.

**Rutas y aeropuertos.** Cada vuelo se encuentra asociado a una **ruta**. Una
ruta representa la conexión entre dos aeropuertos específicos: uno de origen y
otro de destino (por ejemplo, Buenos Aires–Córdoba o Mendoza–Santiago de Chile).
Sobre una misma ruta pueden programarse muchos vuelos en distintos días y
horarios, y un mismo aeropuerto puede participar en varias rutas, tanto como
aeropuerto de salida como de llegada.

**Aeronaves.** Para que un vuelo pueda estar disponible para la venta, debe
tener asignada una **aeronave**. Cada aeronave posee una matrícula que la
identifica, un modelo, una capacidad máxima de pasajeros y un estado operativo.
Una misma aeronave puede operar muchos vuelos a lo largo del tiempo, pero cada
vuelo puntual es realizado por una única aeronave. La cantidad de pasajes
confirmados para un vuelo **no puede superar la capacidad** de la aeronave
asignada.

**Pasajeros y reservas.** Cuando el pasajero decide avanzar con la compra,
ingresa sus datos personales o inicia sesión. De cada pasajero se almacena
nombre, apellido y correo electrónico. Un pasajero puede realizar muchas
reservas. La **reserva** representa la operación de compra iniciada por un
pasajero titular y contiene un código de reserva, una fecha de emisión, un
estado y un monto total.

**Pasajes.** Una reserva puede incluir uno o más **pasajes**, contemplando tanto
el caso de quien compra únicamente su propio pasaje como el de quien compra para
varios acompañantes. Cada pasaje corresponde a un pasajero específico y a un
vuelo determinado, y posee un código de ticket, un estado (reservado,
confirmado, cancelado o utilizado) y un precio base.

**Servicios adicionales.** Durante la compra el pasajero puede contratar
servicios adicionales opcionales (equipaje despachado, equipaje de mano extra,
selección de asiento, embarque prioritario, seguro de viaje). Cada servicio
tiene nombre, descripción y precio base. Como un mismo pasaje puede incluir
varios servicios y un mismo servicio puede contratarse en muchos pasajes, esta
relación se registra de manera independiente, guardando la **cantidad** y el
**precio aplicado** al momento de la compra (el valor puede cambiar por
promociones o políticas comerciales).

**Asientos.** Cada aeronave cuenta con un conjunto de **asientos** identificados
por fila y letra (8A, 12C, 21F). Los asientos pertenecen a una aeronave y pueden
tener distintos tipos (común, mayor espacio, salida de emergencia). El pasajero
puede seleccionar un asiento durante la compra (si contrata ese servicio) o
recibir uno automáticamente al hacer el check-in. Un mismo asiento no puede
asignarse a más de un pasaje dentro del mismo vuelo.

**Pagos.** Calculado el monto total de la reserva, el pasajero realiza el
**pago** mediante alguno de los medios habilitados (tarjeta de crédito, débito,
transferencia bancaria o billetera virtual). De cada pago se registra el monto
abonado, el medio y su estado. Una reserva puede tener más de un pago (intentos
rechazados, pagos pendientes o complementarios). La reserva se considera
**confirmada** solo cuando existe un pago aprobado suficiente.

**Check-in.** Antes de viajar, el pasajero realiza el **check-in**, que confirma
que utilizará el pasaje y permite generar la tarjeta de embarque. El check-in
queda asociado a un pasaje específico y registra fecha y hora. Cada pasaje puede
tener como máximo un check-in asociado.

**Operación interna.** Cada vuelo requiere la participación de **empleados**
(pilotos, copilotos y tripulantes de cabina). De cada empleado se registra su
legajo, nombre y rol. Un empleado puede participar en muchos vuelos y cada vuelo
necesita varios empleados asignados, por lo que se registra qué empleados forman
parte de cada vuelo y qué función cumplen en esa operación específica. El
personal administrativo carga y mantiene aeropuertos, rutas, aeronaves, vuelos,
asientos, servicios y precios, y modifica el estado de un vuelo (programado,
demorado, cancelado o finalizado). El área de atención al cliente consulta
reservas, verifica pagos y gestiona cambios o cancelaciones.

## Entidades identificadas

- **Pasajero**
- **Reserva**
- **Pago**
- **Pasaje**
- **Check-in**
- **Servicio Adicional**
- **Aeronave**
- **Asiento**
- **Vuelo**
- **Empleado**
- **Aeropuerto**
- **Ruta**

Entidades **asociativas** (relaciones N:M con atributos propios):

- **Pasaje–Servicio** (contratación de servicios adicionales por pasaje).
- **Vuelo–Empleado** (asignación de empleados a vuelos).

## Reglas de negocio

1. Una reserva debe incluir **al menos un pasaje**.
2. Cada pasaje corresponde a **un único pasajero** y a **un único vuelo**.
3. Un vuelo debe tener una **aeronave asignada** para poder venderse.
4. La cantidad de pasajes activos de un vuelo **no puede superar la capacidad**
   de la aeronave asignada.
5. Un **asiento no puede asignarse dos veces** dentro del mismo vuelo.
6. Los servicios adicionales son opcionales; si se contratan, se registran con
   su **cantidad y precio aplicado**.
7. Una reserva solo puede considerarse **confirmada** si existe un pago aprobado
   que cubra el monto correspondiente.
