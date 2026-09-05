# Semana 7 — Guía de comandos Apache Hive

## 1. Introducción

Apache Hive permite consultar y analizar grandes volúmenes de datos utilizando un lenguaje similar a SQL denominado **HiveQL**.

Durante las semanas anteriores trabajamos directamente con HDFS. Aprendimos a crear directorios, cargar archivos, consultar su contenido, revisar bloques, analizar replicación y administrar datos mediante comandos como:

```bash
hdfs dfs -ls
hdfs dfs -put
hdfs dfs -get
hdfs dfs -du
```

Ahora incorporaremos una nueva capa sobre esa infraestructura.

En lugar de trabajar solamente con archivos:

```text
HDFS
│
├── ventas.csv
├── clientes.csv
└── productos.csv
```

podremos representar esos datos mediante estructuras lógicas similares a tablas:

```text
HIVE
│
├── tabla ventas
├── tabla clientes
└── tabla productos
        │
        ▼
       HDFS
```

Esto permitirá realizar consultas como:

```sql
SELECT *
FROM ventas;
```

o:

```sql
SELECT region, SUM(monto)
FROM ventas
GROUP BY region;
```

El objetivo de esta guía **no es memorizar instrucciones HiveQL**.

Lo importante será comprender:

* dónde estamos trabajando;
* qué operación estamos realizando;
* qué representa una tabla de Hive;
* dónde están almacenados los datos;
* qué relación existe entre Hive y HDFS;
* cómo verificar el efecto de nuestras operaciones.

Mantendremos la misma estrategia utilizada en HDFS:

> **Ejecutar → Verificar → Interpretar.**

---

# 2. La arquitectura real del laboratorio

Nuestra infraestructura no ejecuta Hive directamente sobre el computador del estudiante.

El recorrido será:

```text
COMPUTADOR PERSONAL
        │
        │ SSH
        ▼
AWS EC2
        │
        │ Docker
        ▼
CONTENEDOR hive-server
        │
        │ /opt/hive/bin
        ▼
CLIENTE HIVE
        │
        │ HiveQL
        ▼
HDFS
```

Por tanto, antes de ejecutar una consulta HiveQL debemos llegar correctamente hasta el entorno donde Hive se encuentra disponible.

---

# 3. Primer nivel: computador personal

Inicialmente estamos trabajando desde nuestro computador.

Desde aquí podemos utilizar, por ejemplo:

```bash
ssh
scp
```

para interactuar con la instancia EC2.

No estamos todavía dentro de AWS.

---

# 4. Conectarse a AWS EC2 mediante SSH

Para conectarnos necesitamos:

* archivo `.pem`;
* usuario de la instancia;
* IP pública o DNS público;
* instancia EC2 en ejecución;
* conectividad por SSH.

La estructura general es:

```bash
ssh -i archivo.pem usuario@DNS_PUBLICO
```

Ejemplo:

```bash
ssh -i bigdata.pem ubuntu@ec2-XX-XX-XX-XX.compute.amazonaws.com
```

Después de conectarnos, nuestro contexto cambia:

```text
PC
 │
 │ SSH
 ▼
EC2
```

---

# 5. Verificar que realmente estamos en EC2

Podemos ejecutar:

```bash
hostname
```

```bash
pwd
```

```bash
ls
```

La pregunta importante es:

> **¿Estoy todavía ejecutando comandos en mi computador o ya estoy dentro de EC2?**

---

# 6. Comprobar Docker

Dentro de EC2:

```bash
sudo docker ps
```

Este comando permite observar los contenedores activos.

Debemos identificar particularmente:

```text
hive-server
```

---

# 7. No asumir el nombre del contenedor

Antes de ejecutar:

```bash
sudo docker exec -it hive-server bash
```

es recomendable confirmar primero:

```bash
sudo docker ps
```

El objetivo es comprobar que:

* el contenedor existe;
* está activo;
* el nombre corresponde al esperado.

---

# 8. Ingresar al contenedor de Hive

Desde EC2:

```bash
sudo docker exec -it hive-server bash
```

Conceptualmente:

```text
AWS EC2
   │
   │ docker exec
   ▼
CONTENEDOR hive-server
```

Después de esta operación estamos dentro de un nuevo entorno Linux: el contenedor.

---

# 9. Verificar el cambio de contexto

Dentro del contenedor:

```bash
hostname
```

```bash
pwd
```

```bash
ls
```

El prompt debería ser diferente al utilizado directamente en EC2.

---

# 10. Localizar Hive dentro del contenedor

Según la infraestructura utilizada en el curso, Hive se encuentra bajo:

```text
/opt/hive
```

Podemos comprobar:

```bash
ls /opt/hive
```

y:

```bash
ls /opt/hive/bin
```

---

# 11. Ingresar al directorio de ejecutables

Ejecute:

```bash
cd /opt/hive/bin
```

Compruebe:

```bash
pwd
```

Debería observar:

```text
/opt/hive/bin
```

---

# 12. Iniciar Hive

Ejecute:

```bash
./hive
```

Después de algunos segundos deberíamos llegar al cliente interactivo de Hive.

---

# 13. Primera prueba de funcionamiento

Ejecute:

```sql
SHOW DATABASES;
```

Si Hive responde correctamente, normalmente aparecerá al menos:

```text
default
```

Ahora completamos el recorrido:

```text
PC
 ↓
SSH
 ↓
EC2
 ↓
docker exec
 ↓
hive-server
 ↓
/opt/hive/bin
 ↓
./hive
 ↓
HiveQL
```

---

# 14. Reconocer los distintos contextos

Durante esta semana trabajaremos al menos en cuatro niveles.

| Contexto   | Ejemplo                       |
| ---------- | ----------------------------- |
| PC         | `ssh`, `scp`                  |
| EC2        | `docker ps`, `docker exec`    |
| Contenedor | `ls`, `cd`, `hdfs dfs ...`    |
| Hive       | `SHOW TABLES;`, `SELECT ...;` |

No debemos mezclar comandos entre capas.

---

# 15. Tres lenguajes distintos

### Linux

```bash
ls
pwd
cat ventas.csv
```

### HDFS

```bash
hdfs dfs -ls /
hdfs dfs -put ventas.csv /datos/
```

### HiveQL

```sql
SHOW TABLES;

SELECT *
FROM ventas;
```

La sintaxis puede coexistir en una misma sesión, pero corresponde a tecnologías diferentes.

---

# 16. Hive no reemplaza a HDFS

Hive agrega una capa sobre el almacenamiento distribuido.

```text
HIVE
 │
 │ estructura y consulta
 ▼
HDFS
 │
 │ almacenamiento
 ▼
ARCHIVOS
 │
 ▼
BLOQUES
```

Por tanto:

> **HDFS almacena los datos; Hive permite describirlos y consultarlos.**

---

# 17. Consultar ayuda y explorar Hive

En entornos interactivos podemos consultar información y utilizar comandos de inspección.

Pero, al igual que en HDFS, la estrategia correcta no consiste en memorizar toda la sintaxis.

Debemos aprender a:

> **identificar qué queremos hacer y consultar la sintaxis apropiada cuando sea necesario.**

---

# 18. Consultar bases de datos: `SHOW DATABASES`

```sql
SHOW DATABASES;
```

Permite observar las bases de datos conocidas por Hive.

Normalmente aparecerá:

```text
default
```

---

# 19. Crear una base de datos

```sql
CREATE DATABASE curso_bigdata;
```

Después:

```sql
SHOW DATABASES;
```

También:

```sql
CREATE DATABASE IF NOT EXISTS curso_bigdata;
```

`IF NOT EXISTS` permite evitar errores cuando la base ya existe.

---

# 20. Seleccionar una base de datos

```sql
USE curso_bigdata;
```

Conceptualmente:

```text
HIVE
 │
 ▼
curso_bigdata
 │
 ├── ventas
 ├── clientes
 └── productos
```

---

# 21. Listar tablas

```sql
SHOW TABLES;
```

Este comando será una de nuestras principales herramientas de verificación.

Podemos pensar:

```text
HDFS                          HIVE
------------------------------------------------
hdfs dfs -ls /datos          SHOW TABLES;
```

No consultan lo mismo, pero ambos permiten explorar el entorno.

---

# 22. Crear nuestra primera tabla

Supongamos datos:

```text
1,Ana,Santiago,1500
2,Pedro,Valparaiso,2200
3,Carolina,Santiago,1800
4,Diego,Concepcion,3100
```

Creamos:

```sql
CREATE TABLE ventas (
    id INT,
    cliente STRING,
    ciudad STRING,
    monto DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';
```

---

# 23. ¿Qué estamos definiendo?

La instrucción anterior define:

```text
TABLA: ventas

id        INT
cliente   STRING
ciudad    STRING
monto     DOUBLE

separador: ,
```

Hive necesita esta información para interpretar los datos.

---

# 24. Tipos de datos básicos

Durante nuestras primeras prácticas utilizaremos principalmente:

| Tipo      | Uso                    |
| --------- | ---------------------- |
| `INT`     | enteros                |
| `BIGINT`  | enteros de mayor rango |
| `FLOAT`   | decimales              |
| `DOUBLE`  | decimales              |
| `STRING`  | texto                  |
| `BOOLEAN` | verdadero/falso        |
| `DATE`    | fechas                 |

Ejemplo:

```sql
CREATE TABLE estudiantes (
    id INT,
    nombre STRING,
    edad INT,
    promedio DOUBLE,
    activo BOOLEAN
);
```

---

# 25. Consultar estructura: `DESCRIBE`

Después de crear una tabla:

```sql
DESCRIBE ventas;
```

Podríamos observar:

```text
id          int
cliente     string
ciudad      string
monto       double
```

Aplicamos nuevamente:

```text
EJECUTAR
   ↓
VERIFICAR
   ↓
INTERPRETAR
```

---

# 26. Consultar información detallada: `DESCRIBE FORMATTED`

```sql
DESCRIBE FORMATTED ventas;
```

Esta instrucción entrega información adicional sobre:

* columnas;
* tipos;
* formato;
* propiedades;
* ubicación;
* almacenamiento.

Debemos aprender a identificar especialmente:

```text
Location
```

---

# 27. ¿Por qué `Location` es importante?

Porque permite responder:

> **¿Dónde están los datos asociados a esta tabla?**

Por ejemplo:

```text
/user/hive/warehouse/ventas
```

Después podemos investigar desde HDFS:

```bash
hdfs dfs -ls /user/hive/warehouse/
```

---

# 28. Datos y metadatos

Debemos separar:

```text
DATOS
1,Ana,Santiago,1500
```

de:

```text
METADATOS

tabla: ventas
id: INT
cliente: STRING
ciudad: STRING
monto: DOUBLE
separador: ,
location: ...
```

Hive utiliza los metadatos para interpretar los datos.

---

# 29. Hive Metastore

Hive necesita mantener información sobre:

* bases de datos;
* tablas;
* columnas;
* tipos;
* ubicaciones;
* formatos;
* particiones.

Esta información se administra mediante el **Hive Metastore**.

---

# 30. NameNode y Metastore no son lo mismo

### NameNode

Administra metadatos de HDFS:

```text
archivos
directorios
bloques
ubicaciones
```

### Hive Metastore

Administra metadatos de Hive:

```text
tablas
columnas
tipos
particiones
location
```

Una forma de recordarlo:

```text
NameNode:
¿Dónde están los archivos y bloques?

Metastore:
¿Cómo debe Hive interpretar esos datos?
```

---

# 31. Preparar un archivo local

Dentro del entorno correspondiente:

```bash
cat > ventas.csv <<EOF
1,Ana,Santiago,1500
2,Pedro,Valparaiso,2200
3,Carolina,Santiago,1800
4,Diego,Concepcion,3100
5,Laura,Valparaiso,2700
EOF
```

Compruebe:

```bash
cat ventas.csv
```

---

# 32. Pregunta fundamental: ¿dónde está el archivo?

Si utilizamos:

```bash
cat ventas.csv
```

estamos leyendo un archivo del sistema de archivos local del entorno actual.

Esto **no significa todavía que esté almacenado en HDFS**.

---

# 33. Crear una ubicación en HDFS

```bash
hdfs dfs -mkdir -p /curso/hive/ventas
```

Verificamos:

```bash
hdfs dfs -ls /curso/hive
```

---

# 34. Incorporar el archivo a HDFS

```bash
hdfs dfs -put ventas.csv /curso/hive/ventas/
```

Verificamos:

```bash
hdfs dfs -ls /curso/hive/ventas/
```

Ahora:

```text
ventas.csv
    ↓
HDFS
/curso/hive/ventas/
```

---

# 35. `LOAD DATA`

Hive también dispone de:

```sql
LOAD DATA LOCAL INPATH '/ruta/ventas.csv'
INTO TABLE ventas;
```

La palabra:

```text
LOCAL
```

indica que Hive buscará el archivo en el sistema de archivos local accesible desde el entorno correspondiente.

También puede utilizarse:

```sql
LOAD DATA INPATH '/ruta/hdfs'
INTO TABLE ventas;
```

Aquí debemos distinguir cuidadosamente **de dónde provienen los datos**.

---

# 36. Crear una tabla externa

Supongamos que ya tenemos:

```text
HDFS
/curso/hive/ventas/
└── ventas.csv
```

Podemos crear:

```sql
CREATE EXTERNAL TABLE ventas_externas (
    id INT,
    cliente STRING,
    ciudad STRING,
    monto DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/curso/hive/ventas/';
```

---

# 37. La importancia de `LOCATION`

```sql
LOCATION '/curso/hive/ventas/'
```

conecta la definición Hive con los datos almacenados en HDFS.

```text
HIVE
ventas_externas
      │
      │ LOCATION
      ▼
HDFS
/curso/hive/ventas/
      │
      └── ventas.csv
```

---

# 38. Verificar una tabla desde Hive

Después de crearla:

```sql
SHOW TABLES;
```

Luego:

```sql
DESCRIBE ventas_externas;
```

Y:

```sql
DESCRIBE FORMATTED ventas_externas;
```

Buscamos especialmente:

```text
Location
```

---

# 39. Verificar la misma estructura desde HDFS

```bash
hdfs dfs -ls /curso/hive/ventas/
```

Estamos observando los mismos datos desde otra capa.

```text
PERSPECTIVA HIVE         PERSPECTIVA HDFS

ventas_externas          /curso/hive/ventas/
                                  │
                                  └── ventas.csv
```

---

# 40. Consultar datos: `SELECT`

```sql
SELECT *
FROM ventas_externas;
```

El símbolo:

```text
*
```

indica todas las columnas.

Podemos seleccionar algunas:

```sql
SELECT cliente, monto
FROM ventas_externas;
```

---

# 41. Limitar resultados: `LIMIT`

Cuando una tabla contiene muchos registros:

```sql
SELECT *
FROM ventas_externas
LIMIT 5;
```

Esto será más apropiado para una primera inspección que recuperar toda la tabla.

---

# 42. Filtrar: `WHERE`

```sql
SELECT *
FROM ventas_externas
WHERE ciudad = 'Santiago';
```

También:

```sql
SELECT *
FROM ventas_externas
WHERE monto > 2000;
```

Operadores frecuentes:

```text
=
>
<
>=
<=
<>
```

---

# 43. Condiciones múltiples: `AND` y `OR`

```sql
SELECT *
FROM ventas_externas
WHERE ciudad = 'Valparaiso'
AND monto > 2000;
```

También:

```sql
SELECT *
FROM ventas_externas
WHERE ciudad = 'Santiago'
OR ciudad = 'Valparaiso';
```

---

# 44. Utilizar `IN`

```sql
SELECT *
FROM ventas_externas
WHERE ciudad IN ('Santiago', 'Valparaiso');
```

Esto puede resultar más legible que múltiples condiciones `OR`.

---

# 45. Utilizar `BETWEEN`

```sql
SELECT *
FROM ventas_externas
WHERE monto BETWEEN 1500 AND 2500;
```

Permite filtrar valores dentro de un rango.

---

# 46. Buscar patrones: `LIKE`

```sql
SELECT *
FROM ventas_externas
WHERE cliente LIKE 'A%';
```

Ejemplos:

```text
'A%'   → comienza con A
'%a'   → termina con a
'%ar%' → contiene ar
```

---

# 47. Valores nulos

```sql
SELECT *
FROM ventas_externas
WHERE monto IS NULL;
```

Y:

```sql
SELECT *
FROM ventas_externas
WHERE monto IS NOT NULL;
```

No utilizamos:

```sql
monto = NULL
```

para comprobar valores nulos.

---

# 48. Ordenar resultados: `ORDER BY`

```sql
SELECT *
FROM ventas_externas
ORDER BY monto;
```

Ascendente:

```sql
ORDER BY monto ASC;
```

Descendente:

```sql
ORDER BY monto DESC;
```

---

# 49. `ORDER BY` en un entorno distribuido

Hive trabaja sobre infraestructura diseñada para procesamiento distribuido.

Un orden global puede exigir coordinación adicional.

Por eso debemos comenzar a preguntarnos:

> **¿Cuál podría ser el costo de ordenar globalmente enormes cantidades de información distribuida?**

---

# 50. `SORT BY`

Hive también dispone de:

```sql
SELECT *
FROM ventas_externas
SORT BY monto;
```

Conceptualmente:

```text
ORDER BY
→ busca orden global

SORT BY
→ ordenamiento asociado al procesamiento distribuido
```

No profundizaremos todavía en su ejecución interna.

---

# 51. Funciones de agregación

Entre las funciones más frecuentes:

```text
COUNT()
SUM()
AVG()
MIN()
MAX()
```

### Contar

```sql
SELECT COUNT(*)
FROM ventas_externas;
```

### Sumar

```sql
SELECT SUM(monto)
FROM ventas_externas;
```

### Promedio

```sql
SELECT AVG(monto)
FROM ventas_externas;
```

### Mínimo y máximo

```sql
SELECT MIN(monto), MAX(monto)
FROM ventas_externas;
```

---

# 52. Agrupar: `GROUP BY`

```sql
SELECT ciudad, SUM(monto)
FROM ventas_externas
GROUP BY ciudad;
```

Conceptualmente:

```text
REGISTROS
   ↓
AGRUPAR
   ↓
CALCULAR
   ↓
RESULTADO
```

---

# 53. Filtrar grupos: `HAVING`

```sql
SELECT
    ciudad,
    SUM(monto) AS total
FROM ventas_externas
GROUP BY ciudad
HAVING SUM(monto) > 3000;
```

La secuencia conceptual:

```text
WHERE
 ↓
filtra registros
 ↓
GROUP BY
 ↓
agrupa
 ↓
HAVING
 ↓
filtra grupos
```

---

# 54. Alias con `AS`

```sql
SELECT
    ciudad,
    SUM(monto) AS total_ventas
FROM ventas_externas
GROUP BY ciudad;
```

Esto permite obtener nombres de columnas más descriptivos.

---

# 55. Crear una segunda tabla

```sql
CREATE TABLE ciudades (
    ciudad STRING,
    region STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';
```

Podemos tener:

```text
Santiago,Metropolitana
Valparaiso,Valparaiso
Concepcion,Biobio
```

---

# 56. Relacionar tablas: `JOIN`

```sql
SELECT
    v.cliente,
    v.ciudad,
    c.region,
    v.monto
FROM ventas_externas v
JOIN ciudades c
ON v.ciudad = c.ciudad;
```

Los alias:

```text
v → ventas_externas
c → ciudades
```

`JOIN` permite relacionar información de diferentes tablas.

---

# 57. Tablas administradas y externas

Debemos distinguir:

```text
MANAGED TABLE
```

de:

```text
EXTERNAL TABLE
```

En una tabla externa:

```text
HDFS
 │
 └── datos existentes
        ▲
        │
      HIVE
        │
        └── estructura lógica
```

---

# 58. ¿Qué ocurre al eliminar una tabla?

Antes de utilizar:

```sql
DROP TABLE ventas_externas;
```

debemos preguntarnos:

* ¿es una tabla externa?
* ¿es una tabla administrada?
* ¿qué esperamos que ocurra con los datos?
* ¿qué esperamos que ocurra con los metadatos?

---

# 59. Experimento con tabla externa

Supongamos:

```text
HDFS
/curso/hive/ventas/
└── ventas.csv
```

Creamos una tabla externa que apunta hacia esa ubicación.

Después ejecutamos:

```sql
DROP TABLE ventas_externas;
```

Verificamos:

```sql
SHOW TABLES;
```

Posteriormente:

```bash
hdfs dfs -ls /curso/hive/ventas/
```

La pregunta importante es:

> **¿Desapareció la definición de tabla, los datos, o ambos?**

---

# 60. Eliminar tablas

```sql
DROP TABLE ventas;
```

También:

```sql
DROP TABLE IF EXISTS ventas;
```

No debemos utilizar `DROP TABLE` mecánicamente sin comprender el efecto esperado.

---

# 61. Particionamiento

Podemos crear:

```sql
CREATE TABLE ventas_particionadas (
    id INT,
    cliente STRING,
    ciudad STRING,
    monto DOUBLE
)
PARTITIONED BY (anio INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';
```

Conceptualmente:

```text
ventas
│
├── anio=2024
├── anio=2025
└── anio=2026
```

---

# 62. ¿Por qué particionar?

Supongamos millones de registros correspondientes a:

```text
2024
2025
2026
```

Si necesitamos solamente 2026, una buena organización puede permitir evitar procesar datos innecesarios.

La idea es:

> **reducir la cantidad de información que debe examinarse.**

---

# 63. Consultar particiones

```sql
SHOW PARTITIONS ventas_particionadas;
```

Podríamos observar:

```text
anio=2024
anio=2025
anio=2026
```

Y consultar:

```sql
SELECT *
FROM ventas_particionadas
WHERE anio = 2026;
```

---

# 64. Observar particiones desde HDFS

Las particiones pueden reflejarse en una organización similar a:

```text
ventas_particionadas/
├── anio=2024/
├── anio=2025/
└── anio=2026/
```

Esto permite relacionar nuevamente:

```text
HIVE
estructura lógica

↕

HDFS
estructura de almacenamiento
```

---

# 65. Bucketing

Hive también posee el concepto de **bucketing**.

Conceptualmente:

```text
PARTITIONING
→ separa por determinados valores

BUCKETING
→ distribuye registros en N grupos
```

Por ejemplo:

```text
PARTITION
año=2026

BUCKET
hash(id_cliente) → grupo 1, 2, 3...
```

En esta primera semana solamente necesitamos reconocer el concepto.

---

# 66. Cambiar el nombre de una tabla

```sql
ALTER TABLE ventas
RENAME TO ventas_historicas;
```

Después:

```sql
SHOW TABLES;
```

---

# 67. Agregar columnas

```sql
ALTER TABLE ventas
ADD COLUMNS (
    vendedor STRING
);
```

Verificamos:

```sql
DESCRIBE ventas;
```

---

# 68. Modificar metadatos no significa modificar automáticamente los archivos

Si agregamos una columna mediante:

```sql
ALTER TABLE
```

estamos modificando la **definición de la tabla**.

No debemos asumir que los archivos originales son automáticamente reescritos.

Nuevamente:

```text
METADATOS ≠ DATOS
```

---

# 69. Flujo completo de trabajo

Podemos reunir todo en una secuencia.

### Paso 1 — Llegar a EC2

```bash
ssh -i archivo.pem usuario@DNS_PUBLICO
```

### Paso 2 — Ver contenedores

```bash
sudo docker ps
```

### Paso 3 — Entrar al contenedor

```bash
sudo docker exec -it hive-server bash
```

### Paso 4 — Llegar a Hive

```bash
cd /opt/hive/bin
./hive
```

### Paso 5 — Comprobar Hive

```sql
SHOW DATABASES;
```

### Paso 6 — Crear datos

```bash
ventas.csv
```

### Paso 7 — Llevarlos a HDFS

```bash
hdfs dfs -put ventas.csv /curso/hive/ventas/
```

### Paso 8 — Crear estructura Hive

```sql
CREATE EXTERNAL TABLE ...
LOCATION '/curso/hive/ventas/';
```

### Paso 9 — Verificar

```sql
SHOW TABLES;
DESCRIBE FORMATTED ventas;
```

### Paso 10 — Consultar

```sql
SELECT *
FROM ventas
LIMIT 10;
```

### Paso 11 — Analizar

```sql
SELECT ciudad, SUM(monto)
FROM ventas
GROUP BY ciudad;
```

### Paso 12 — Contrastar con HDFS

```bash
hdfs dfs -ls /curso/hive/ventas/
```

---

# 70. Flujo conceptual completo

```text
COMPUTADOR
    ↓
EC2
    ↓
DOCKER
    ↓
HIVE-SERVER
    ↓
HIVEQL
    ↓
METASTORE
    ↓
TABLA
    ↓
LOCATION
    ↓
HDFS
    ↓
ARCHIVOS
    ↓
BLOQUES
    ↓
DATANODES
```

---

# 71. Error frecuente: confundir EC2 con el contenedor

```bash
sudo docker exec -it hive-server bash
```

cambia nuestro entorno.

Antes:

```text
EC2
```

Después:

```text
contenedor hive-server
```

---

# 72. Error frecuente: asumir que entrar al contenedor significa estar en Hive

Después de:

```bash
sudo docker exec -it hive-server bash
```

aún estamos en Bash.

Debemos ejecutar:

```bash
cd /opt/hive/bin
./hive
```

---

# 73. Error frecuente: ejecutar HiveQL en Linux

Esto:

```sql
SHOW TABLES;
```

debe ejecutarse dentro de Hive.

No en Bash.

---

# 74. Error frecuente: ejecutar comandos Docker dentro de Hive

Esto:

```bash
docker ps
```

pertenece al host EC2.

No al cliente Hive.

---

# 75. Error frecuente: olvidar el punto y coma

Incorrecto:

```sql
SHOW TABLES
```

Correcto:

```sql
SHOW TABLES;
```

---

# 76. Error frecuente: confundir Hive con HDFS

```sql
SHOW TABLES;
```

muestra tablas conocidas por Hive.

```bash
hdfs dfs -ls /datos
```

muestra archivos y directorios HDFS.

No son equivalentes.

---

# 77. Error frecuente: definir mal el separador

Si los datos son:

```text
1,Ana,Santiago,1500
```

pero configuramos:

```sql
FIELDS TERMINATED BY ';'
```

Hive no interpretará correctamente las columnas.

Antes de crear la tabla:

> **inspeccione primero el archivo.**

---

# 78. Error frecuente: esquema no significa contenido

Crear:

```sql
CREATE TABLE ventas (...)
```

no implica necesariamente que ya existan registros.

```text
ESTRUCTURA ≠ DATOS
```

---

# 79. Error frecuente: no revisar `Location`

Con tablas externas:

```sql
DESCRIBE FORMATTED ventas;
```

Busque:

```text
Location
```

y compruébelo después desde HDFS.

---

# 80. Error frecuente: utilizar `DROP TABLE` sin analizar el tipo

Antes de eliminar:

```text
¿Managed?
¿External?
```

Después formule una hipótesis sobre qué ocurrirá.

Solo entonces ejecute y verifique.

---

# 81. Error frecuente: `SELECT *` sobre grandes datasets

Para inspección:

```sql
SELECT *
FROM ventas
LIMIT 10;
```

es generalmente más apropiado que recuperar millones de registros.

---

# 82. Estrategia de trabajo con Hive

Mantendremos:

> **Ejecutar → Verificar → Interpretar**

Pero ahora agregaremos:

> **Verificar desde Hive y, cuando sea relevante, verificar también desde HDFS.**

Ejemplo:

```sql
CREATE EXTERNAL TABLE ventas (...)
LOCATION '/datos/ventas/';
```

### Desde Hive

```sql
SHOW TABLES;
DESCRIBE FORMATTED ventas;
```

### Desde HDFS

```bash
hdfs dfs -ls /datos/ventas/
```

### Interpretar

* ¿qué creó Hive?
* ¿qué existía previamente?
* ¿dónde están los datos?
* ¿qué pertenece al Metastore?
* ¿qué pertenece a HDFS?

---

# 83. La pregunta fundamental cambia

Durante HDFS preguntábamos:

> **¿Dónde está mi archivo?**

Ahora agregamos:

> **¿Cómo está interpretando Hive ese archivo?**

Las dos preguntas son necesarias.

---

# 84. Lo aprendido en HDFS sigue siendo necesario

Podemos continuar utilizando:

```bash
hdfs dfs -ls
```

```bash
hdfs dfs -du -h
```

```bash
hdfs dfs -cat
```

para observar el almacenamiento.

Mientras Hive nos permite:

```sql
DESCRIBE
SELECT
GROUP BY
```

para trabajar desde una perspectiva estructurada.

---

# 85. Tabla rápida de acceso

| Objetivo                | Comando                                 |
| ----------------------- | --------------------------------------- |
| PC → EC2                | `ssh -i archivo.pem usuario@DNS`        |
| Ver contenedores        | `sudo docker ps`                        |
| Entrar a Hive container | `sudo docker exec -it hive-server bash` |
| Directorio Hive         | `cd /opt/hive/bin`                      |
| Iniciar Hive            | `./hive`                                |
| Verificar Hive          | `SHOW DATABASES;`                       |

---

# 86. Tabla rápida HiveQL

| Objetivo         | Comando                                        |
| ---------------- | ---------------------------------------------- |
| Bases de datos   | `SHOW DATABASES;`                              |
| Crear base       | `CREATE DATABASE nombre;`                      |
| Seleccionar base | `USE nombre;`                                  |
| Tablas           | `SHOW TABLES;`                                 |
| Crear tabla      | `CREATE TABLE ...;`                            |
| Tabla externa    | `CREATE EXTERNAL TABLE ... LOCATION '/ruta/';` |
| Estructura       | `DESCRIBE tabla;`                              |
| Detalle          | `DESCRIBE FORMATTED tabla;`                    |
| Consultar        | `SELECT ... FROM ...;`                         |
| Limitar          | `LIMIT N`                                      |
| Filtrar          | `WHERE`                                        |
| Rango            | `BETWEEN`                                      |
| Lista            | `IN`                                           |
| Patrones         | `LIKE`                                         |
| Ordenar          | `ORDER BY`                                     |
| Agrupar          | `GROUP BY`                                     |
| Filtrar grupos   | `HAVING`                                       |
| Contar           | `COUNT()`                                      |
| Sumar            | `SUM()`                                        |
| Promedio         | `AVG()`                                        |
| Mínimo           | `MIN()`                                        |
| Máximo           | `MAX()`                                        |
| Relacionar       | `JOIN ... ON ...`                              |
| Particiones      | `SHOW PARTITIONS tabla;`                       |
| Renombrar        | `ALTER TABLE ... RENAME TO ...;`               |
| Agregar columnas | `ALTER TABLE ... ADD COLUMNS ...;`             |
| Eliminar         | `DROP TABLE ...;`                              |

---

# 87. Tabla rápida Linux, HDFS y Hive

| Necesidad            | Tecnología | Ejemplo                            |
| -------------------- | ---------- | ---------------------------------- |
| Ver archivos locales | Linux      | `ls`                               |
| Leer archivo local   | Linux      | `cat ventas.csv`                   |
| Ver HDFS             | HDFS       | `hdfs dfs -ls /datos`              |
| Cargar HDFS          | HDFS       | `hdfs dfs -put ventas.csv /datos/` |
| Leer HDFS            | HDFS       | `hdfs dfs -cat /datos/ventas.csv`  |
| Ver tablas           | Hive       | `SHOW TABLES;`                     |
| Ver estructura       | Hive       | `DESCRIBE ventas;`                 |
| Ver ubicación        | Hive       | `DESCRIBE FORMATTED ventas;`       |
| Consultar            | Hive       | `SELECT * FROM ventas;`            |
| Analizar             | Hive       | `GROUP BY`, `SUM`, `AVG`           |

---

# 88. Modelo mental final

Debemos conservar dos recorridos.

### Recorrido operacional

```text
PC
 ↓
SSH
 ↓
EC2
 ↓
Docker
 ↓
hive-server
 ↓
./hive
 ↓
HiveQL
```

### Recorrido de los datos

```text
HiveQL
   ↓
Hive
   ↓
Metastore
   ↓
tabla
   ↓
Location
   ↓
HDFS
   ↓
archivo
   ↓
bloques
   ↓
DataNode
```

---

# 89. La idea central

Con HDFS aprendimos a pensar:

```text
ARCHIVO
   ↓
BLOQUES
   ↓
ALMACENAMIENTO DISTRIBUIDO
```

Con Hive agregamos:

```text
ARCHIVO
   ↓
HDFS
   ↓
TABLA
   ↓
HIVEQL
   ↓
CONSULTA
   ↓
INFORMACIÓN
```

Hive no reemplaza el almacenamiento distribuido.

**Lo abstrae mediante estructuras que permiten consultar los datos con un lenguaje declarativo.**

---

# 90. Lo importante de esta guía

No queremos memorizar una lista:

```text
ssh
docker exec
./hive
CREATE
SELECT
WHERE
GROUP BY
```

Queremos ser capaces de responder:

1. **¿Dónde estoy trabajando?**
2. **¿Qué sistema estoy consultando?**
3. **¿Dónde están los datos?**
4. **¿Qué metadatos utiliza Hive?**
5. **¿Qué operación quiero realizar?**
6. **¿Cómo verifico que ocurrió correctamente?**
7. **¿Qué relación existe entre la tabla Hive y los archivos HDFS?**

Cuando estas preguntas pueden responderse, Hive deja de ser simplemente una colección de comandos SQL y comienza a entenderse como **una capa de consulta y estructuración sobre el almacenamiento distribuido que ya conocemos**.

