# Semana 7 — Introducción a Apache Hive

## 1. De HDFS a Hive: el siguiente paso

Durante las semanas anteriores hemos trabajado con **Hadoop Distributed File System (HDFS)**. Hemos aprendido que HDFS permite almacenar grandes volúmenes de información distribuyendo los archivos en bloques y almacenándolos en uno o más DataNodes, mientras el NameNode mantiene los metadatos necesarios para administrar el sistema de archivos.

También hemos aprendido a interactuar directamente con HDFS mediante comandos como:

```bash
hdfs dfs -ls
hdfs dfs -mkdir
hdfs dfs -put
hdfs dfs -get
hdfs dfs -mv
hdfs dfs -rm
```

Esto nos permitió comprender una parte fundamental del ecosistema Hadoop: **cómo almacenar y administrar datos distribuidos**.

Sin embargo, aparece inmediatamente una nueva pregunta:

> **¿Cómo podemos analizar los datos que hemos almacenado en HDFS?**

Supongamos que tenemos un archivo con millones de registros de ventas:

```text
fecha,producto,categoria,region,cantidad,precio
2026-01-03,Notebook,Tecnologia,Norte,2,750000
2026-01-03,Mouse,Tecnologia,Centro,5,18000
2026-01-04,Monitor,Tecnologia,Sur,3,210000
...
```

El archivo puede estar perfectamente almacenado en HDFS, pero HDFS **no es un sistema de análisis de datos**.

HDFS sabe almacenar, distribuir y recuperar archivos. No proporciona por sí mismo una interfaz declarativa como SQL para responder preguntas del tipo:

* ¿Cuántas ventas existen?
* ¿Cuál es el total vendido por región?
* ¿Qué categoría presenta mayores ingresos?
* ¿Cuál es el precio promedio de los productos?
* ¿Cuántas transacciones se realizaron cada mes?

Para responder estas preguntas necesitamos una capa adicional.

Aquí aparece **Apache Hive**.

---

# 2. ¿Qué es Apache Hive?

**Apache Hive** es un sistema de *data warehouse* distribuido que permite consultar y administrar grandes conjuntos de datos almacenados en sistemas distribuidos mediante una interfaz similar a SQL.

Su característica más importante puede resumirse así:

> **Hive permite utilizar una sintaxis similar a SQL para trabajar con grandes volúmenes de datos almacenados en el ecosistema Hadoop.**

Por ejemplo, si tenemos información de ventas almacenada en HDFS, podríamos realizar una consulta como:

```sql
SELECT region, SUM(total)
FROM ventas
GROUP BY region;
```

Desde la perspectiva del usuario, la operación se parece considerablemente a trabajar con una base de datos relacional.

Pero detrás de esta aparente simplicidad existe una arquitectura diferente.

Hive debe interpretar la consulta, conocer dónde se encuentran los datos, generar un plan de ejecución y utilizar un motor de procesamiento para realizar las operaciones necesarias.

Por ello, una primera idea que debemos conservar durante toda esta unidad es:

> **Hive proporciona una abstracción de alto nivel sobre datos almacenados en sistemas distribuidos.**

---

# 3. ¿Por qué fue necesario crear Hive?

Para comprender Hive debemos regresar a los primeros años de Hadoop.

Hadoop permitió resolver un problema fundamental: almacenar y procesar cantidades de información que resultaban difíciles de manejar mediante una sola máquina.

HDFS resolvía el problema del **almacenamiento distribuido**.

MapReduce permitía realizar **procesamiento distribuido**.

Sin embargo, utilizar MapReduce directamente requería escribir programas relativamente complejos.

Para un desarrollador esto podía resultar razonable.

Para un analista acostumbrado a SQL, no.

Imagine una organización con analistas que durante años habían trabajado utilizando consultas como:

```sql
SELECT categoria, COUNT(*)
FROM productos
GROUP BY categoria;
```

En un entorno basado directamente en MapReduce, una operación conceptualmente sencilla podía requerir implementar diferentes etapas de procesamiento.

Esto generaba una importante barrera de entrada.

El problema dejó de ser solamente:

> ¿Cómo procesamos grandes cantidades de datos?

y pasó a ser también:

> ¿Cómo permitimos que personas que conocen SQL puedan analizar esos datos sin tener que programar directamente procesos distribuidos?

Hive nació precisamente para responder a esta necesidad.

---

# 4. El origen de Hive

Hive comenzó a desarrollarse en **Facebook alrededor de 2007**.

En aquella época Facebook experimentaba un crecimiento extraordinariamente rápido de sus datos.

La organización utilizaba Hadoop para almacenar y procesar grandes cantidades de información, pero apareció un problema práctico: muchos analistas estaban familiarizados con SQL, pero no necesariamente con Java o con la programación directa de trabajos MapReduce.

Era necesario crear una interfaz que redujera esa complejidad.

La solución fue desarrollar una capa que permitiera expresar operaciones analíticas mediante un lenguaje parecido a SQL y traducirlas posteriormente a operaciones ejecutables sobre la infraestructura Hadoop.

De esta necesidad nació **Hive**.

Posteriormente, el proyecto pasó a formar parte del ecosistema de la **Apache Software Foundation**.

La historia de Hive muestra un patrón frecuente en informática:

> Una tecnología puede ser técnicamente poderosa, pero si utilizarla requiere demasiado conocimiento especializado, aparece la necesidad de construir una nueva capa de abstracción.

Hive es precisamente esa capa dentro del ecosistema Hadoop.

---

# 5. HiveQL: SQL para el ecosistema Hadoop

Hive utiliza un lenguaje denominado **Hive Query Language (HiveQL o HQL)**.

Su sintaxis está fuertemente inspirada en SQL.

Por ejemplo:

```sql
SELECT *
FROM ventas;
```

Podemos filtrar información:

```sql
SELECT *
FROM ventas
WHERE region = 'Valparaiso';
```

Podemos realizar agregaciones:

```sql
SELECT region, COUNT(*)
FROM ventas
GROUP BY region;
```

También podemos calcular valores:

```sql
SELECT region, SUM(cantidad * precio)
FROM ventas
GROUP BY region;
```

Esto disminuye considerablemente la barrera de entrada para usuarios familiarizados con bases de datos relacionales.

Sin embargo, debemos evitar una confusión importante:

> **Que Hive utilice un lenguaje parecido a SQL no significa que funcione exactamente igual que una base de datos relacional tradicional.**

Comprender esta diferencia será fundamental.

---

# 6. Hive no reemplaza a HDFS

Uno de los errores conceptuales más frecuentes al comenzar a trabajar con Hive consiste en pensar:

> "Antes los archivos estaban en HDFS y ahora los vamos a guardar en Hive".

Esta idea es incorrecta.

Hive y HDFS cumplen funciones diferentes.

Podemos simplificarlo así:

```text
HDFS
│
│ almacena los datos
│
▼
ARCHIVOS
│
│ Hive proporciona estructura
│ y mecanismos de consulta
│
▼
HIVE
│
│ permite realizar consultas
│ similares a SQL
│
▼
RESULTADOS
```

HDFS continúa siendo responsable del almacenamiento distribuido.

Hive agrega una **capa lógica** que permite interpretar esos datos mediante estructuras similares a tablas.

Por tanto:

> **HDFS almacena los datos; Hive permite estructurarlos y consultarlos.**

---

# 7. Del archivo a la tabla

Este concepto es probablemente el cambio mental más importante de esta semana.

Hasta ahora hemos trabajado pensando principalmente en:

```text
archivo
↓
bloques
↓
DataNode
```

Con Hive comenzaremos a pensar en:

```text
archivo
↓
estructura
↓
tabla
↓
consulta
↓
resultado
```

Supongamos que tenemos:

```text
ventas.csv
```

con:

```text
2026-01-03,Notebook,Tecnologia,2,750000
2026-01-03,Mouse,Tecnologia,5,18000
2026-01-04,Monitor,Tecnologia,3,210000
```

Hive puede proporcionar una estructura lógica como:

| fecha      | producto | categoria  | cantidad | precio |
| ---------- | -------- | ---------- | -------: | -----: |
| 2026-01-03 | Notebook | Tecnologia |        2 | 750000 |
| 2026-01-03 | Mouse    | Tecnologia |        5 |  18000 |
| 2026-01-04 | Monitor  | Tecnologia |        3 | 210000 |

Ahora podemos consultar esos datos mediante HiveQL.

El archivo continúa existiendo, pero Hive nos permite **interpretarlo como una estructura tabular**.

---

# 8. Schema-on-read

Aquí aparece uno de los conceptos más importantes asociados históricamente a Hive:

## Schema-on-read

En una base de datos relacional tradicional normalmente definimos primero una estructura:

```text
TABLA
├── columna
├── tipo
├── columna
└── tipo
```

y posteriormente insertamos datos compatibles con ella.

Este enfoque suele denominarse:

**schema-on-write**.

Simplificando:

```text
definir estructura
        ↓
validar datos
        ↓
almacenar
```

En muchos escenarios asociados a Hadoop, los datos pueden almacenarse primero y su estructura lógica aplicarse posteriormente cuando son consultados.

```text
almacenar datos
        ↓
definir/usar estructura
        ↓
interpretar al consultar
```

Esto se asocia al concepto:

**schema-on-read**.

La diferencia es importante porque proporciona flexibilidad para trabajar con grandes cantidades de información proveniente de fuentes heterogéneas.

---

# 9. Una tabla de Hive no debe imaginarse como un Excel gigante

Cuando observamos:

```sql
CREATE TABLE ventas (...)
```

es fácil imaginar que Hive crea algo equivalente a una tabla tradicional donde cada registro queda físicamente almacenado dentro de una estructura propia de la base de datos.

Esa representación mental puede resultar engañosa.

Una forma más apropiada de imaginarlo es:

```text
TABLA HIVE
      │
      │ describe
      ▼
estructura de los datos
      │
      │ apunta hacia
      ▼
ARCHIVOS
      │
      │ almacenados en
      ▼
HDFS
```

La tabla proporciona información sobre **cómo interpretar los datos**.

Por ejemplo:

* nombre de las columnas;
* tipos de datos;
* formato;
* ubicación;
* particiones;
* otras propiedades.

---

# 10. Los metadatos vuelven a aparecer

Durante HDFS aprendimos que el **NameNode administra metadatos**.

Ahora volveremos a encontrar el concepto de metadatos, pero en otro nivel.

Hive necesita recordar información como:

```text
tabla: ventas

columnas:
    fecha
    producto
    categoria
    cantidad
    precio

tipos:
    string
    string
    string
    int
    double

ubicación:
    /datos/ventas/

formato:
    CSV
```

Esta información no corresponde necesariamente a los datos propiamente tales.

Son **datos acerca de los datos**.

Hive mantiene esta información mediante un componente denominado **Metastore**.

---

# 11. El Hive Metastore

El **Hive Metastore** constituye uno de los componentes fundamentales de Hive.

Almacena información sobre las estructuras utilizadas por Hive.

Por ejemplo:

* bases de datos;
* tablas;
* columnas;
* tipos de datos;
* ubicaciones;
* particiones;
* propiedades de almacenamiento.

Podemos representarlo conceptualmente así:

```text
                 HIVE
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
     METASTORE             HDFS
         │                   │
   "qué significan"       "datos"
     los datos
```

Esta separación es fundamental.

**HDFS contiene los datos.**

**El Metastore contiene información que permite a Hive interpretarlos.**

---

# 12. Una analogía sencilla

Imagine una biblioteca enorme.

Los libros representan nuestros datos.

```text
BIBLIOTECA
│
├── libro
├── libro
├── libro
├── libro
└── libro
```

HDFS sería equivalente al sistema que permite almacenar físicamente los libros.

Pero encontrar información sería complicado si solamente supiéramos dónde existen miles o millones de libros.

Necesitamos un catálogo.

Ese catálogo podría indicarnos:

```text
Título
Autor
Categoría
Ubicación
Año
Idioma
```

El **Metastore** cumple una función conceptualmente similar.

No contiene necesariamente el contenido completo de los datos.

Contiene información que permite **comprender y localizar las estructuras asociadas a esos datos**.

---

# 13. ¿Qué ocurre cuando ejecutamos una consulta?

Supongamos que escribimos:

```sql
SELECT region, SUM(total)
FROM ventas
GROUP BY region;
```

Desde nuestra perspectiva simplemente hemos escrito una consulta.

Internamente ocurre un proceso mucho más complejo.

Una representación simplificada sería:

```text
USUARIO
   │
   │ HiveQL
   ▼
HIVE
   │
   ▼
PARSER / COMPILER
   │
   ▼
PLAN DE EJECUCIÓN
   │
   ▼
MOTOR DE EJECUCIÓN
   │
   ▼
DATOS
   │
   ▼
RESULTADO
```

Hive analiza la consulta y determina qué operaciones son necesarias para obtener el resultado.

El usuario no necesita programar manualmente todas esas operaciones.

Esta es precisamente la abstracción que hace a Hive útil.

---

# 14. Hive como traductor

Una manera pedagógicamente útil de comprender Hive es imaginarlo como un **traductor**.

El usuario piensa:

```sql
SELECT categoria, COUNT(*)
FROM ventas
GROUP BY categoria;
```

Hive debe transformar esa intención declarativa en operaciones que puedan ejecutarse sobre los datos.

Podemos representarlo así:

```text
LO QUE QUIERO
      │
      ▼
    HiveQL
      │
      ▼
     HIVE
      │
      ▼
¿CÓMO EJECUTARLO?
      │
      ▼
motor de procesamiento
      │
      ▼
    datos
```

Esto nos permite introducir una diferencia importante entre dos estilos de trabajo.

### Imperativo

Indicamos detalladamente **cómo** realizar una operación.

### Declarativo

Indicamos principalmente **qué resultado queremos obtener**.

SQL y HiveQL son fundamentalmente declarativos.

---

# 15. Hive y MapReduce

Históricamente, Hive traducía muchas consultas en **trabajos MapReduce**.

Esta característica fue fundamental porque permitía utilizar Hadoop sin escribir directamente programas MapReduce.

Conceptualmente:

```text
HiveQL
   ↓
Hive
   ↓
MapReduce
   ↓
HDFS
```

Sin embargo, el ecosistema Hadoop evolucionó.

Con el tiempo Hive comenzó a utilizar motores de ejecución más eficientes, particularmente **Apache Tez**, y también puede integrarse con otros motores según la arquitectura utilizada.

Por ello, actualmente sería incorrecto definir Hive simplemente como:

> "un programa que transforma SQL en MapReduce".

Esa descripción sirve para comprender su origen histórico, pero resulta demasiado limitada para describir arquitecturas modernas.

La idea más general es:

> **Hive transforma consultas declarativas en planes de ejecución que son procesados sobre infraestructura distribuida.**

---

# 16. Arquitectura conceptual de Hive

Una representación simplificada puede ser:

```text
                USUARIO
                   │
                   │ HiveQL
                   ▼
              ┌─────────┐
              │  HIVE   │
              └────┬────┘
                   │
        ┌──────────┼───────────┐
        │          │           │
        ▼          ▼           ▼
     Parser     Compiler    Metastore
        │          │           │
        └──────┬───┘           │
               ▼               │
        Plan de ejecución      │
               │               │
               ▼               │
       Motor de ejecución      │
               │               │
               └───────┬───────┘
                       ▼
                     HDFS
                       │
                       ▼
                   RESULTADO
```

No necesitamos memorizar cada componente en esta primera aproximación.

Lo importante es comprender el flujo:

> **consulta → interpretación → planificación → ejecución → datos → resultado**

---

# 17. Bases de datos y tablas

Hive organiza lógicamente la información utilizando conceptos familiares para quienes conocen SQL.

Podemos crear una base de datos:

```sql
CREATE DATABASE empresa;
```

Seleccionarla:

```sql
USE empresa;
```

y posteriormente crear tablas:

```sql
CREATE TABLE ventas (
    fecha STRING,
    producto STRING,
    categoria STRING,
    cantidad INT,
    precio DOUBLE
);
```

Podemos inspeccionar las tablas:

```sql
SHOW TABLES;
```

y consultar su estructura:

```sql
DESCRIBE ventas;
```

Este lenguaje familiar permite comenzar a trabajar rápidamente con información almacenada en el ecosistema Hadoop.

---

# 18. Tablas internas y externas

Hive distingue diferentes formas de relacionar tablas y datos.

Una distinción especialmente importante es:

* **Managed Tables**;
* **External Tables**.

## Managed Table

En una tabla administrada, Hive tiene un mayor grado de control sobre los datos asociados a la tabla.

Conceptualmente:

```text
HIVE
 │
 ├── metadatos
 │
 └── administra datos
```

## External Table

En una tabla externa, los datos existen independientemente de la definición de la tabla.

```text
HDFS
 │
 └── datos existentes
        ▲
        │
HIVE ───┘
define cómo interpretarlos
```

Esta segunda situación será especialmente interesante para nosotros porque ya sabemos almacenar archivos directamente en HDFS.

Podemos tener primero:

```text
HDFS
└── /datos/ventas/
       └── ventas.csv
```

y posteriormente crear una estructura Hive que permita consultar esos datos.

---

# 19. ¿Qué sucede al eliminar una tabla?

Esta pregunta permite comprender mejor la diferencia anterior.

Supongamos que tenemos datos importantes almacenados en HDFS y una tabla externa que los referencia.

Si eliminamos la definición de la tabla, conceptualmente queremos poder conservar los datos originales.

Esta separación resulta muy útil cuando:

* diferentes herramientas utilizan los mismos datos;
* los archivos tienen un ciclo de vida independiente;
* no queremos que eliminar una estructura lógica implique necesariamente eliminar la información almacenada.

Por eso las tablas externas han sido históricamente muy relevantes dentro de arquitecturas basadas en Hadoop.

---

# 20. Formatos de datos

Hive puede trabajar con diferentes formatos.

Entre ellos podemos encontrar:

* texto;
* CSV;
* JSON, mediante mecanismos apropiados;
* ORC;
* Parquet;
* Avro.

No todos los formatos presentan las mismas características.

Un CSV es sencillo y comprensible:

```text
2026-01-01,Notebook,2,750000
2026-01-02,Mouse,5,18000
```

pero para grandes volúmenes de información pueden utilizarse formatos diseñados para procesamiento analítico.

Por ejemplo:

**ORC** y **Parquet** son formatos columnares.

En lugar de pensar únicamente en registros completos:

```text
fila 1
fila 2
fila 3
```

los formatos columnares organizan la información de manera que determinadas consultas analíticas puedan leer más eficientemente solo las columnas necesarias.

Este tema será relevante posteriormente cuando estudiemos optimización.

---

# 21. Particiones

Supongamos que tenemos datos correspondientes a varios años:

```text
ventas
├── 2023
├── 2024
├── 2025
└── 2026
```

Si queremos consultar solamente:

```sql
WHERE anio = 2026
```

¿tendría sentido revisar todos los datos desde 2023?

No necesariamente.

Hive permite utilizar **particiones**.

Por ejemplo:

```text
ventas/
├── anio=2024/
├── anio=2025/
└── anio=2026/
```

Una consulta:

```sql
SELECT *
FROM ventas
WHERE anio = 2026;
```

puede aprovechar esa organización para evitar procesar información innecesaria.

La idea fundamental es:

> **Particionar significa organizar físicamente los datos utilizando una o más variables que permitan reducir la cantidad de información que debe examinarse.**

---

# 22. Bucketing

Hive también dispone del concepto de **bucketing**.

Mientras las particiones separan los datos de acuerdo con determinados valores, los *buckets* permiten distribuir registros dentro de un número determinado de grupos mediante una función aplicada sobre una columna.

No necesitamos profundizar todavía en su implementación.

En esta primera aproximación basta distinguir:

```text
PARTITIONING
separa por valores
ejemplo: año

BUCKETING
distribuye en N grupos
ejemplo: hash(id_cliente)
```

Ambos mecanismos pueden contribuir a organizar grandes cantidades de información de manera más eficiente.

---

# 23. Hive no fue diseñado para todo

Hive posee ventajas importantes, pero también debemos comprender sus limitaciones.

Hive fue diseñado principalmente para procesamiento analítico de grandes volúmenes de datos.

Es especialmente apropiado para:

* consultas analíticas;
* agregaciones;
* procesamiento por lotes;
* ETL;
* exploración de grandes datasets;
* construcción de estructuras de *data warehouse*.

No fue concebido originalmente para escenarios que requieren:

* respuestas de milisegundos;
* gran cantidad de actualizaciones individuales;
* procesamiento transaccional tradicional registro por registro;
* aplicaciones OLTP de alta concurrencia.

Esta diferencia puede resumirse así:

```text
BASE DE DATOS TRANSACCIONAL
       ↓
muchas operaciones pequeñas
       ↓
respuesta rápida

HIVE
       ↓
grandes cantidades de datos
       ↓
procesamiento analítico
```

---

# 24. Hive frente a una base de datos relacional tradicional

| Característica        | Base de datos relacional tradicional  | Hive                                                  |
| --------------------- | ------------------------------------- | ----------------------------------------------------- |
| Orientación principal | Transaccional/analítica según sistema | Analítica                                             |
| Lenguaje              | SQL                                   | HiveQL                                                |
| Datos                 | Tablas gestionadas por el DBMS        | Frecuentemente archivos en almacenamiento distribuido |
| Esquema               | Principalmente schema-on-write        | Fuertemente asociado a schema-on-read                 |
| Escala                | Depende de la arquitectura            | Diseñado para grandes volúmenes distribuidos          |
| Latencia              | Puede ser muy baja                    | Históricamente mayor                                  |
| Procesamiento         | Motor DBMS                            | Motores de ejecución distribuida                      |
| Uso típico            | Aplicaciones y consultas              | Data warehouse, ETL y analítica masiva                |

La tabla simplifica considerablemente ambas tecnologías, pero permite identificar la diferencia conceptual.

---

# 25. Ventajas de Hive

## 25.1 Utiliza un lenguaje familiar

Las personas que conocen SQL pueden adaptarse relativamente rápido a HiveQL.

---

## 25.2 Oculta parte de la complejidad distribuida

El usuario puede expresar:

```sql
SELECT region, AVG(precio)
FROM ventas
GROUP BY region;
```

sin programar directamente todos los mecanismos necesarios para distribuir el procesamiento.

---

## 25.3 Permite trabajar con grandes volúmenes de datos

Hive fue diseñado precisamente para escenarios donde los datasets pueden crecer considerablemente.

---

## 25.4 Se integra con el ecosistema Hadoop

Hive puede trabajar sobre datos almacenados en infraestructura distribuida y relacionarse con otros componentes del ecosistema.

---

## 25.5 Permite separar datos y estructura lógica

Los archivos pueden existir independientemente de determinadas definiciones de tablas, especialmente mediante tablas externas.

---

## 25.6 Facilita tareas de ETL y analítica

Operaciones de filtrado, agregación, transformación y generación de nuevos datasets pueden expresarse mediante HiveQL.

---

# 26. Limitaciones de Hive

También debemos evitar presentar Hive como una solución universal.

Entre sus limitaciones históricas y conceptuales encontramos:

* mayor latencia que sistemas orientados a consultas interactivas rápidas;
* dependencia de infraestructura distribuida;
* menor adecuación para cargas OLTP;
* rendimiento muy dependiente de cómo se organizan los datos;
* necesidad de comprender particiones, formatos y arquitectura para obtener buen desempeño.

Por tanto:

> **Hive es potente cuando el problema corresponde al tipo de procesamiento para el cual fue diseñado.**

---

# 27. ¿Dónde está realmente una tabla?

Esta pregunta será central durante nuestros ejercicios.

Si ejecutamos:

```sql
SHOW TABLES;
```

podemos observar:

```text
clientes
productos
ventas
```

Pero eso no significa necesariamente que exista un objeto físico llamado `ventas` que contenga mágicamente toda la información.

Debemos comenzar a pensar en dos capas:

```text
CAPA LÓGICA
──────────────────
Hive
tabla ventas
columnas
tipos
particiones
metadatos

        ↓

CAPA FÍSICA
──────────────────
almacenamiento
archivos
directorios
bloques
```

Esta separación entre **estructura lógica** y **almacenamiento físico** será uno de los conceptos más importantes de la semana.

---

# 28. Lo que ya sabemos de HDFS sigue siendo importante

Aprender Hive no significa abandonar HDFS.

Al contrario.

Nuestro conocimiento previo ahora adquiere más sentido.

Cuando Hive consulta información almacenada en HDFS, debajo de la tabla continúan existiendo:

```text
ARCHIVOS
    ↓
BLOQUES
    ↓
DATANODES
```

El NameNode continúa administrando los metadatos propios del sistema de archivos.

Ahora agregamos otra capa:

```text
HIVE
   ↓
METASTORE
   ↓
TABLAS / COLUMNAS / TIPOS
   ↓
HDFS
   ↓
ARCHIVOS
   ↓
BLOQUES
   ↓
DATANODES
```

Observe que aparecen **dos niveles distintos de metadatos**.

Esto es importante.

---

# 29. NameNode y Metastore no son lo mismo

El **NameNode** conoce información relacionada con HDFS:

* archivos;
* directorios;
* bloques;
* ubicaciones;
* propiedades del sistema de archivos.

El **Hive Metastore** conoce información relacionada con Hive:

* tablas;
* columnas;
* tipos;
* particiones;
* formatos;
* ubicación lógica asociada a las tablas.

Podemos resumirlo:

```text
NAMENODE
"¿Dónde están los archivos y sus bloques?"

METASTORE
"¿Cómo debe Hive interpretar esos datos?"
```

Confundir estos dos componentes produce muchos errores conceptuales.

---

# 30. Del almacenamiento al análisis

Podemos representar nuestro aprendizaje hasta ahora mediante una secuencia.

### Semana 1

Comprendimos el problema del crecimiento de los datos:

```text
crecimiento de datos
        ↓
limitaciones del procesamiento tradicional
```

### Semana 2

Estudiamos Hadoop:

```text
scale-up
   ↓
limitaciones
   ↓
scale-out
   ↓
Hadoop
```

### Semanas 4 y 5

Trabajamos con HDFS:

```text
archivo
   ↓
bloques
   ↓
distribución
   ↓
replicación
   ↓
almacenamiento distribuido
```

### Semana 7

Agregamos Hive:

```text
datos almacenados
       ↓
estructura
       ↓
tablas
       ↓
HiveQL
       ↓
análisis
```

Estamos avanzando, por tanto, desde **almacenar grandes cantidades de datos** hacia **consultarlas y analizarlas**.

---

# 31. Un ejemplo completo

Supongamos que disponemos de:

```text
ventas_2026.csv
```

con millones de registros.

### Paso 1 — El archivo llega a nuestra infraestructura

```text
Computador
    ↓
AWS EC2
```

### Paso 2 — Llega al entorno donde trabajamos con Hadoop

```text
AWS EC2
    ↓
contenedor
```

### Paso 3 — Se incorpora a HDFS

```text
contenedor
    ↓
HDFS
```

### Paso 4 — HDFS lo almacena

```text
ventas_2026.csv
       ↓
     bloques
       ↓
   DataNode(s)
```

### Paso 5 — Hive proporciona estructura

Conceptualmente:

```sql
CREATE EXTERNAL TABLE ventas (...)
LOCATION '/datos/ventas/';
```

### Paso 6 — Consultamos

```sql
SELECT region, SUM(total)
FROM ventas
GROUP BY region;
```

### Paso 7 — Obtenemos información

```text
Norte      154000000
Centro     328000000
Sur        121000000
```

Esta secuencia resume la relación que debemos comprender:

> **infraestructura → almacenamiento → estructura → consulta → información**

---

# 32. Una nueva frontera conceptual

Durante HDFS utilizamos una idea que resultó especialmente útil:

> Cada frontera requiere comprender dónde estamos trabajando.

Distinguimos:

```text
PC
────────────
EC2
────────────
CONTENEDOR
────────────
HDFS
```

Con Hive debemos agregar una nueva capa conceptual:

```text
USUARIO
   │
   ▼
HIVE / HiveQL
   │
   ▼
METADATOS
   │
   ▼
HDFS
   │
   ▼
ARCHIVOS
   │
   ▼
BLOQUES
```

Ya no solamente preguntaremos:

> **¿Dónde está mi archivo?**

Ahora también debemos preguntarnos:

> **¿Cómo está interpretando Hive ese archivo?**

---

# 33. Preguntas que debemos aprender a responder

Al finalizar nuestra introducción a Hive deberíamos poder responder preguntas como:

1. ¿Qué problema resuelve Hive?
2. ¿Por qué surgió dentro del ecosistema Hadoop?
3. ¿Cuál es la relación entre Hive y HDFS?
4. ¿Qué es HiveQL?
5. ¿Qué significa *schema-on-read*?
6. ¿Qué función cumple el Hive Metastore?
7. ¿Cuál es la diferencia entre el NameNode y el Metastore?
8. ¿Qué representa una tabla de Hive?
9. ¿Cuál es la diferencia conceptual entre una tabla administrada y una tabla externa?
10. ¿Qué ocurre cuando ejecutamos una consulta HiveQL?
11. ¿Por qué Hive no debe considerarse simplemente una base de datos relacional tradicional?
12. ¿Para qué tipos de problemas resulta apropiado Hive?

---

# 34. Modelo mental que debemos conservar

Antes de comenzar la práctica, debemos conservar esta representación:

```text
                HIVE
                  │
             "consultar"
                  │
                  ▼
              HiveQL
                  │
                  ▼
              Metastore
          "cómo interpretar"
                  │
                  ▼
                HDFS
             "almacenar"
                  │
                  ▼
               archivos
                  │
                  ▼
                bloques
                  │
                  ▼
              DataNodes
```

Podemos reducir todo el modelo a tres preguntas:

```text
HDFS
¿Dónde están los datos?

HIVE METASTORE
¿Qué significan y cómo están estructurados?

HIVEQL
¿Qué quiero saber de ellos?
```

---

# 35. La idea central de la semana

Durante HDFS aprendimos a pensar en **almacenamiento distribuido**.

Con Hive comenzaremos a pensar en **datos estructurados lógicamente sobre almacenamiento distribuido**.

El cambio puede resumirse así:

```text
ANTES

archivo
  ↓
HDFS
  ↓
bloques
  ↓
almacenamiento


AHORA

archivo
  ↓
HDFS
  ↓
Hive
  ↓
tabla
  ↓
consulta
  ↓
información
```

Hive no elimina la complejidad del procesamiento distribuido.

La **abstrae**.

Y esa abstracción es precisamente una de las razones por las que Hive se convirtió en una pieza importante del ecosistema Hadoop.

> **HDFS nos permitió aprender a almacenar datos distribuidos. Hive nos permitirá comenzar a hacer preguntas sobre esos datos.**

