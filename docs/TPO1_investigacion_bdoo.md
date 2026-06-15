# TPO Nro 1 — Trabajo de investigación y muestreo bibliográfico

## Bases de Datos Orientadas a Objetos (BDOO)

> **Materia:** _________________________  **Comisión:** ___________
> **Docente:** _________________________  **Fecha de entrega:** ___/___/______
> **Grupo:** 6  **Integrantes:** _________________________________________

---

## 1. Introducción

Las bases de datos orientadas a objetos (BDOO, en inglés *OODB*) surgen a fines
de la década de 1980 como respuesta a las limitaciones del modelo relacional
para representar **datos complejos y estructurados** propios de aplicaciones como
el diseño asistido por computadora (CAD/CAM), los sistemas de información
geográfica, la ingeniería de software, la multimedia o las aplicaciones
científicas.

El modelo relacional organiza la información en tablas planas (filas y columnas)
y funciona muy bien para datos tabulares y transaccionales. Sin embargo, cuando
una aplicación está escrita en un lenguaje orientado a objetos (Java, C++,
C#, Smalltalk), aparece el fenómeno conocido como **desajuste de impedancia
objeto-relacional** (*object-relational impedance mismatch*): el programador
trabaja con objetos —que tienen identidad, estado, comportamiento, herencia y
relaciones— pero debe traducirlos constantemente a filas y columnas para
guardarlos, y reconstruirlos al leerlos. Esa traducción genera código repetitivo
y costos de mantenimiento.

Una base de datos orientada a objetos propone **eliminar esa traducción**:
almacenar directamente los objetos del lenguaje de programación, conservando su
estructura, sus relaciones y su identidad, de modo que la persistencia sea casi
transparente para el desarrollador. El presente trabajo investiga el modelo de
datos orientado a objetos, sus características, los estándares que lo formalizan,
sus ventajas y desventajas frente al modelo relacional, y los principales
productos y casos de uso.

## 2. ¿Qué es una base de datos orientada a objetos?

Una BDOO es un sistema de gestión de bases de datos (SGBD) que **integra las
capacidades de un SGBD** (persistencia, concurrencia, recuperación ante fallos,
consultas, integridad) **con el modelo de objetos** de un lenguaje de
programación orientado a objetos. En lugar de tablas, la unidad de
almacenamiento es el **objeto**.

Esto implica que conceptos del paradigma de objetos pasan a ser conceptos de la
base de datos:

- **Objeto e identidad (OID).** Cada objeto posee un identificador único
  (*Object Identifier*) generado por el sistema, independiente de los valores de
  sus atributos. Dos objetos con los mismos valores siguen siendo distintos.
  Esto contrasta con el modelo relacional, donde la identidad se basa en una
  clave primaria (valores de columnas).
- **Atributos y estado.** El objeto guarda su estado en atributos, que pueden ser
  tipos simples u **objetos complejos** (otros objetos, colecciones, listas,
  conjuntos).
- **Clases y tipos.** Los objetos se agrupan en clases que definen su estructura
  y comportamiento.
- **Encapsulamiento.** El estado se accede a través de métodos (comportamiento),
  ocultando la representación interna.
- **Herencia.** Las clases se organizan en jerarquías; una subclase hereda
  atributos y métodos de su superclase (por ejemplo, `Piloto` y
  `TripulanteCabina` heredan de `Empleado`).
- **Polimorfismo y ligadura tardía.** Un mismo método puede comportarse distinto
  según la clase concreta del objeto.
- **Relaciones por referencia.** En vez de claves foráneas, los objetos se
  vinculan mediante referencias directas y colecciones (un `Vuelo` contiene una
  colección de `Pasaje`, y cada `Pasaje` referencia a su `Pasajero`).

## 3. El "Manifiesto de los Sistemas de Bases de Datos Orientadas a Objetos"

En 1989, Atkinson, Bancilhon, DeWitt, Dittrich, Maier y Zdonik publicaron *The
Object-Oriented Database System Manifesto*, que intentó fijar las
características mínimas que debe cumplir un sistema para ser considerado una BDOO.
El manifiesto distingue **reglas obligatorias** ("reglas de oro").

**Características que aportan la orientación a objetos:**

1. **Objetos complejos:** soporte de objetos construidos a partir de otros
   (conjuntos, listas, tuplas).
2. **Identidad de objeto:** cada objeto tiene un OID propio.
3. **Encapsulamiento:** separación entre interfaz e implementación.
4. **Tipos y clases:** soporte del concepto de tipo o clase.
5. **Jerarquías de tipos/clases:** herencia.
6. **Sobrecarga, redefinición (overriding) y ligadura tardía.**
7. **Completitud computacional:** el lenguaje de manipulación debe ser un
   lenguaje de programación de propósito general.
8. **Extensibilidad:** el usuario puede definir nuevos tipos, indistinguibles de
   los predefinidos.

**Características que aportan las capacidades de base de datos:**

9. **Persistencia** de los objetos.
10. **Gestión de almacenamiento secundario** (índices, *buffers*, etc.).
11. **Concurrencia** (control de accesos simultáneos).
12. **Recuperación** ante fallos.
13. **Facilidad de consulta** *ad hoc* (un lenguaje de consultas).

El manifiesto también enumera características **opcionales** (herencia múltiple,
chequeo de tipos, distribución, versionado) y **abiertas** (paradigma de
programación, sistema de tipos, uniformidad), que cada producto puede o no
incorporar.

## 4. El estándar ODMG

Para evitar que cada producto definiera su propio modelo, el **Object Data
Management Group (ODMG)** publicó un estándar (cuya última versión es **ODMG
3.0**, año 2000). El estándar define:

- **Modelo de objetos:** la base conceptual común.
- **ODL (*Object Definition Language*):** lenguaje para definir el esquema
  (clases, atributos, relaciones), independiente del lenguaje de programación.
- **OQL (*Object Query Language*):** lenguaje de consultas declarativo con
  sintaxis similar a SQL pero capaz de navegar referencias entre objetos y
  devolver objetos o colecciones.
- **Bindings de lenguajes:** integración con C++, Java y Smalltalk para manipular
  los objetos persistentes desde el código.

Ejemplo conceptual de una consulta **OQL** que recupera los pasajeros de un vuelo:

```sql
SELECT p.pasajero.apellido
FROM   Vuelos v, v.pasajes p
WHERE  v.numeroVuelo = "LC100";
```

A diferencia de SQL, OQL permite "navegar" por las referencias
(`v.pasajes`, `p.pasajero`) sin necesidad de *joins* explícitos por claves.

## 5. Comparación con el modelo relacional

| Aspecto | Modelo relacional | Modelo orientado a objetos |
|---|---|---|
| Unidad de almacenamiento | Tabla (filas y columnas) | Objeto |
| Identidad | Clave primaria (por valor) | OID generado por el sistema |
| Relaciones | Claves foráneas + *joins* | Referencias y colecciones (navegación) |
| Tipos de datos | Simples / atómicos (1FN) | Complejos, anidados, definidos por el usuario |
| Herencia | No nativa (se simula) | Nativa |
| Comportamiento | Externo (en la aplicación) | Métodos dentro del objeto |
| Lenguaje de consulta | SQL (maduro, estándar) | OQL (menos difundido) |
| Desajuste de impedancia | Alto | Bajo / nulo |
| Madurez y herramientas | Muy alta | Limitada / de nicho |
| Estandarización | ISO SQL, muy fuerte | ODMG, más débil |

## 6. Bases de datos objeto-relacionales (enfoque híbrido)

Como punto intermedio surgieron los **SGBD objeto-relacionales** (ORDBMS), que
extienden el modelo relacional con características de objetos: tipos definidos por
el usuario, tipos compuestos, herencia de tablas, arreglos y referencias. El
trabajo de Stonebraker sobre POSTGRES fue pionero, y hoy **PostgreSQL** y los
tipos objeto de Oracle son ejemplos representativos. Este enfoque buscó capturar
parte de la expresividad de los objetos sin abandonar la base relacional madura,
y en la práctica fue mucho más adoptado que las BDOO puras.

## 7. Ventajas y desventajas

**Ventajas**

- Eliminan o reducen el desajuste de impedancia objeto-relacional.
- Representan de forma natural datos complejos, anidados y con relaciones ricas.
- Navegación por referencias muy eficiente (sin *joins* costosos).
- Soporte nativo de herencia, encapsulamiento y comportamiento.

**Desventajas**

- Menor madurez, estandarización más débil y comunidad más reducida que SQL.
- Curva de aprendizaje y herramientas (reporting, BI) menos desarrolladas.
- Acoplamiento al lenguaje de programación.
- Menor portabilidad y dificultad para consultas *ad hoc* genéricas.
- El modelo relacional y los ORM (Hibernate, JPA, Entity Framework) cubrieron
  gran parte de la necesidad que motivó a las BDOO, frenando su adopción masiva.

## 8. Productos representativos

- **db4o** — base de datos de objetos embebida para Java y .NET (código abierto).
- **ObjectDB** — BDOO para Java, compatible con JPA/JDO.
- **GemStone/S** — sistema de objetos persistentes para Smalltalk.
- **Versant Object Database** y **Objectivity/DB** — orientadas a alto volumen y
  aplicaciones técnicas/científicas.
- **ObjectStore** — pionera, usada en aplicaciones de ingeniería.
- **InterSystems Caché / IRIS** — modelo "post-relacional" multimodelo.

## 9. Aplicación al dominio del TP (aerolínea low cost)

El dominio modelado en el TPO Nro 2 puede pensarse también en términos de
objetos. Donde el modelo relacional usa **tablas y claves foráneas**, una BDOO
usaría **clases y referencias**:

```
class Aeropuerto { codigoIata; nombre; ciudad; pais; }

class Ruta { Aeropuerto origen; Aeropuerto destino; }

class Vuelo {
    numeroVuelo; fechaHoraSalida; estado; precioBase;
    Ruta ruta;
    Aeronave aeronave;
    set<Pasaje>   pasajes;       // colección, no FK
    set<Empleado> tripulacion;   // relación N:M directa
}

class Pasaje {
    codigoTicket; estado; precioBase;
    Pasajero pasajero;           // referencia, no clave foránea
    Asiento  asiento;
    set<ServicioContratado> servicios;
    CheckIn  checkin;            // 0..1
}

// Herencia: en una BDOO se modela de forma nativa
class Empleado { legajo; nombre; }
class Piloto            extends Empleado { }
class TripulanteCabina  extends Empleado { }
```

Diferencias clave respecto del modelo relacional entregado:

- **`vuelo_empleado` y `pasaje_servicio`** (tablas asociativas) desaparecen como
  tablas: pasan a ser **colecciones** dentro de los objetos `Vuelo` y `Pasaje`.
  Sin embargo, los atributos de la asociación (`funcion`, `cantidad`,
  `precio_aplicado`) obligan a usar igualmente una clase intermedia
  (`AsignacionTripulacion`, `ServicioContratado`).
- La **herencia** de `Empleado` se expresa de forma directa, sin la columna
  discriminadora `rol` que usamos en el modelo relacional.
- Las **reglas de negocio** (no superar la capacidad de la aeronave, asiento
  único por vuelo) podrían implementarse como **métodos** de la clase `Vuelo`,
  en lugar de *triggers* y *constraints* SQL.

Esta comparación muestra por qué, para un sistema **transaccional y comercial**
como la venta de pasajes —con reportes, consultas *ad hoc* y necesidad de
herramientas maduras— el **modelo relacional sigue siendo la opción más
conveniente**, que es la que adoptamos en el TPO Nro 2.

## 10. Conclusión

Las bases de datos orientadas a objetos representaron un avance conceptual
importante al acercar el almacenamiento al paradigma de objetos y resolver el
desajuste de impedancia. Su modelo es muy adecuado para datos complejos y
aplicaciones técnicas. No obstante, la madurez, la estandarización (SQL) y el
ecosistema del modelo relacional —sumados a la aparición de los mapeadores
objeto-relacionales y de los SGBD objeto-relacionales— hicieron que las BDOO
quedaran como una solución de **nicho**. Para el dominio de una aerolínea low
cost, fuertemente transaccional y con necesidad de reportes y consultas, el
modelo relacional resulta la elección más sólida, sin perjuicio de aprovechar
ideas del paradigma de objetos en la capa de aplicación.

## 11. Bibliografía (muestreo bibliográfico)

1. Atkinson, M., Bancilhon, F., DeWitt, D., Dittrich, K., Maier, D., & Zdonik, S.
   (1989). *The Object-Oriented Database System Manifesto*. Proceedings of the
   First International Conference on Deductive and Object-Oriented Databases
   (DOOD), Kyoto, Japón.
2. Cattell, R. G. G., & Barry, D. K. (Eds.). (2000). *The Object Data Standard:
   ODMG 3.0*. Morgan Kaufmann.
3. Elmasri, R., & Navathe, S. B. *Fundamentals of Database Systems*. Pearson
   (capítulos sobre bases de datos orientadas a objetos y objeto-relacionales).
4. Date, C. J. *An Introduction to Database Systems*. Addison-Wesley.
5. Silberschatz, A., Korth, H. F., & Sudarshan, S. *Database System Concepts*.
   McGraw-Hill (capítulo de bases de datos basadas en objetos).
6. Bertino, E., & Martino, L. (1993). *Object-Oriented Database Systems: Concepts
   and Architectures*. Addison-Wesley.
7. Loomis, M. E. S. (1995). *Object Databases: The Essentials*. Addison-Wesley.
8. Stonebraker, M., & Moore, D. (1996). *Object-Relational DBMSs: The Next Great
   Wave*. Morgan Kaufmann.

> *Nota:* completar/verificar edición y año según el ejemplar consultado por el
> grupo al citar en la entrega final.
