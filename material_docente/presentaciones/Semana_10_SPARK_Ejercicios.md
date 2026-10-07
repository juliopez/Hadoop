# Guía Práctica 2 — Procesamiento estructurado con Apache Spark
## DataFrames, esquemas y Spark SQL

### Tiempo estimado
90 minutos.

### Modalidad
Trabajo práctico individual.

### Propósito de la guía

Aplicar las capacidades de procesamiento estructurado de Apache Spark mediante **DataFrames y Spark SQL**, utilizando Scala y PySpark para seleccionar, filtrar, transformar y analizar datos.

Durante la guía se retomará el conjunto de 100.000 ventas utilizado anteriormente. Los datos continuarán almacenados en **HDFS**, pero ahora Spark los representará mediante una estructura tabular con columnas y tipos de datos.

Esto permitirá avanzar desde:

```text
RDD
 ↓
colección distribuida
```

hacia:

```text
DataFrame
 ↓
datos distribuidos + estructura
 ↓
columnas + tipos de datos
```

---

## Antes de comenzar

Continuaremos respetando la responsabilidad de cada componente de nuestra infraestructura:

| Tecnología   | Contenedor     | Función durante la guía                            |
| ------------ | -------------- | -------------------------------------------------- |
| HDFS         | `namenode`     | Almacenar y verificar los archivos                 |
| Apache Hive  | `hive-server`  | Consultar la tabla mediante HiveQL                 |
| Apache Spark | `spark-master` | Procesar los datos mediante DataFrames y Spark SQL |

Recuerde:

```text
HDFS  → namenode
Hive  → hive-server
Spark → spark-master
```

En esta guía trabajaremos principalmente desde `spark-master`, ya que el objetivo será utilizar las capacidades estructuradas de Spark.

---

## Del RDD al DataFrame

En la guía anterior trabajamos principalmente con RDD:

```text
HDFS
  │
  ▼
ventas_hive.csv
  │
  ▼
RDD[String]
  │
  ▼
map / filter / reduceByKey
```

Ahora utilizaremos una abstracción de mayor nivel:

```text
HDFS
  │
  ▼
ventas_hive.csv
  │
  ▼
DataFrame
  │
  ├── id_venta
  ├── fecha
  ├── cliente
  ├── ciudad
  ├── categoria
  └── monto
```

Esto permitirá trabajar con los datos utilizando nombres de columnas en lugar de posiciones como:

```text
x[3]
x[4]
x[5]
```

Además, podremos utilizar **Spark SQL** para realizar consultas utilizando una sintaxis similar a la utilizada anteriormente con HiveQL.

---

# Nivel 1 — Básico

Los primeros cinco ejercicios permitirán crear DataFrames, reconocer su esquema y realizar operaciones básicas sobre datos estructurados.

---

## Ejercicio 1 — Crear nuestro primer DataFrame

### Objetivo

Crear un DataFrame sencillo y reconocer sus principales características.

Ingrese al contenedor Spark:

```bash
sudo docker exec -it spark-master bash
```

Luego:

```bash
cd /spark/bin
```

Configure Python 3:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3
```

Inicie PySpark:

```bash
./pyspark --master spark://spark-master:7077
```

Espere hasta visualizar:

```text
>>>
```

---

### Crear los datos

Ejecute:

```python
datos = [
    (1, "Ana", "Santiago", 150000.0),
    (2, "Luis", "Valparaiso", 85000.0),
    (3, "Carla", "Concepcion", 210000.0),
    (4, "Pedro", "Santiago", 95000.0),
    (5, "Maria", "Temuco", 180000.0)
]
```

Ahora defina los nombres de las columnas:

```python
columnas = ["id", "cliente", "ciudad", "monto"]
```

Construya el DataFrame:

```python
df = spark.createDataFrame(datos, columnas)
```

Visualícelo:

```python
df.show()
```

### Observe

A diferencia de un RDD, ahora Spark puede representar los datos utilizando una estructura tabular:

```text
+---+-------+----------+--------+
| id|cliente|    ciudad|   monto|
+---+-------+----------+--------+
|  1|    Ana|  Santiago|150000.0|
|  2|   Luis|Valparaiso| 85000.0|
|  3|  Carla|Concepcion|210000.0|
|  4|  Pedro|  Santiago| 95000.0|
|  5|  Maria|    Temuco|180000.0|
+---+-------+----------+--------+
```

### Interprete

Responda:

1. ¿Cuántas filas posee el DataFrame?
2. ¿Cuántas columnas posee?
3. ¿Qué ventaja observa respecto de trabajar con posiciones como `x[0]`, `x[1]` o `x[2]`?

> **Idea clave:** un DataFrame representa datos distribuidos organizados mediante filas y columnas con una estructura conocida.

---

## Ejercicio 2 — Examinar el esquema de un DataFrame

### Objetivo

Comprender que un DataFrame no solamente posee nombres de columnas, sino también información sobre los tipos de datos.

Ejecute:

```python
df.printSchema()
```

Observe el resultado.

Encontrará una estructura similar a:

```text
root
 |-- id: long
 |-- cliente: string
 |-- ciudad: string
 |-- monto: double
```

Spark ha asociado cada columna con un determinado tipo de dato.

Podemos representarlo como:

```text
DataFrame
   │
   ├── id       → long
   ├── cliente  → string
   ├── ciudad   → string
   └── monto    → double
```

### Consulte también

Ejecute:

```python
df.columns
```

Luego:

```python
df.dtypes
```

Compare la información obtenida.

### Interprete

Complete:

| Columna   | Tipo       |
| --------- | ---------- |
| `id`      | __________ |
| `cliente` | __________ |
| `ciudad`  | __________ |
| `monto`   | __________ |

### Reflexione

En la guía anterior, al trabajar con:

```python
linea.split(",")
```

Spark no sabía automáticamente que determinada posición representaba un monto.

¿Por qué disponer de un **schema** puede resultar ventajoso cuando necesitamos analizar grandes conjuntos de datos?

---

## Ejercicio 3 — Seleccionar columnas

### Objetivo

Utilizar nombres de columnas para seleccionar información de un DataFrame.

Visualice solamente:

```text
cliente
ciudad
```

utilizando:

```python
df.select("cliente", "ciudad").show()
```

Ahora seleccione:

```text
cliente
monto
```

Construya usted mismo la instrucción.

---

### Seleccionar utilizando objetos Column

Spark también permite escribir:

```python
df.select(df.cliente, df.monto).show()
```

Ambas formas trabajan sobre las columnas del DataFrame.

Conceptualmente:

```text
DataFrame original

id | cliente | ciudad | monto
         │              │
         └──────┬───────┘
                ▼
             select
                │
                ▼
       cliente | monto
```

### Interprete

Responda:

1. ¿`select` modifica el DataFrame original?
2. ¿Qué principio estudiado anteriormente vuelve a aparecer?
3. ¿Qué ventaja proporciona utilizar `"monto"` en lugar de una posición como `x[3]`?

> Al igual que los RDD, los DataFrames se utilizan mediante transformaciones que producen nuevas representaciones de los datos sin modificar el conjunto original.

---

## Ejercicio 4 — Filtrar filas utilizando columnas

### Objetivo

Aplicar condiciones sobre columnas de un DataFrame.

Queremos identificar las ventas cuyo monto sea superior a:

```text
$100.000
```

Ejecute:

```python
df.filter(df.monto > 100000).show()
```

Observe los registros obtenidos.

Ahora pruebe:

```python
df.filter(df.ciudad == "Santiago").show()
```

### Combine condiciones

Construya una expresión que permita responder:

> ¿Qué registros corresponden a Santiago y poseen un monto superior a $100.000?

Puede combinar condiciones utilizando:

```python
&
```

Recuerde encerrar cada condición entre paréntesis.

---

### Compare con la Guía 1

Anteriormente utilizábamos:

```python
rdd.filter(lambda x: ...)
```

Ahora utilizamos:

```python
df.filter(df.monto > ...)
```

Conceptualmente ambas operaciones realizan un filtrado, pero el DataFrame conoce la estructura de los datos.

### Interprete

¿Qué expresión resulta más cercana al problema que estamos intentando resolver?

```text
x[3] > 100000
```

o:

```text
monto > 100000
```

Explique brevemente por qué.

---

## Ejercicio 5 — Crear una columna derivada

### Objetivo

Generar nueva información a partir de las columnas existentes.

Supongamos que deseamos calcular un recargo hipotético del 10 % sobre cada monto.

Utilice:

```python
from pyspark.sql.functions import col
```

Ahora ejecute:

```python
df_recargo = df.withColumn(
    "monto_recargo",
    col("monto") * 1.10
)
```

Visualice:

```python
df_recargo.show()
```

Observe que ahora existe una nueva columna:

```text
id
cliente
ciudad
monto
monto_recargo
```

### Compruebe el DataFrame original

Ejecute:

```python
df.show()
```

¿Aparece `monto_recargo`?

Explique por qué.

---

## Desafío breve

A partir del DataFrame original, cree una nueva columna denominada:

```text
monto_miles
```

que represente:

```text
monto / 1000
```

Visualice solamente:

```text
cliente
monto
monto_miles
```

No se entrega la instrucción completa.

---

# Reflexión del Nivel 1

Responda brevemente:

1. ¿Qué es un DataFrame?
2. ¿Qué información contiene su schema?
3. ¿Qué diferencia práctica observa entre acceder a `x[3]` en un RDD y utilizar `df.monto` en un DataFrame?
4. ¿Qué hacen `select` y `filter`?
5. ¿`withColumn` modifica el DataFrame original?
6. ¿Qué característica estudiada con los RDD continúa presente en los DataFrames?

---

## Resultado esperado del Nivel 1

Al finalizar estos cinco ejercicios debería poder interpretar:

```text
                     DataFrame
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
            Filas                 Schema
                                    │
                         ┌──────────┼──────────┐
                         ▼          ▼          ▼
                      Columnas    Nombres     Tipos
                         │
                         ▼
              ┌──────────┼──────────┐
              ▼          ▼          ▼
            select     filter   withColumn
```

Hasta ahora hemos utilizado solamente un pequeño DataFrame creado manualmente.

En el siguiente nivel sustituiremos estos cinco registros por las **100.000 ventas almacenadas en HDFS**:

```text
                 HDFS
                   │
                   ▼
           ventas_hive.csv
                   │
                   ▼
             Spark Reader
                   │
                   ▼
               DataFrame
                   │
                   ▼
          100.000 registros
                   │
            ┌──────┴──────┐
            ▼             ▼
       Agregaciones    Spark SQL
```

A partir de ese momento comenzaremos a comprobar la principal ventaja del procesamiento estructurado de Spark: analizar grandes conjuntos de datos utilizando **columnas, esquemas y expresiones SQL**.

---

# Nivel 2 — Intermedio

En este nivel utilizaremos las **100.000 ventas almacenadas en HDFS** para construir un DataFrame y realizar operaciones de análisis estructurado.

El recorrido será:

```text
HDFS
  │
  ▼
ventas_hive.csv
  │
  ▼
Spark
  │
  ▼
DataFrame
  │
  ├── Schema
  ├── select / filter
  ├── groupBy / agg
  └── Spark SQL
```

A diferencia del nivel anterior, los datos ya no serán creados manualmente. Spark deberá leerlos desde nuestra infraestructura Big Data.

---

## Ejercicio 6 — Verificar el archivo desde HDFS

### Objetivo

Comprobar la existencia y estructura del conjunto de datos antes de procesarlo mediante Spark.

Si continúa dentro de PySpark, salga utilizando:

```python
exit()
```

Luego salga del contenedor:

```bash
exit
```

Ingrese al contenedor responsable de HDFS:

```bash
sudo docker exec -it namenode bash
```

Recuerde:

```text
HDFS  → namenode
Hive  → hive-server
Spark → spark-master
```

### Localizar el archivo

Ejecute:

```bash
hdfs dfs -ls -h /curso/hive/datos_ventas/
```

Debería encontrar:

```text
ventas_hive.csv
```

Ahora visualice una pequeña muestra:

```bash
hdfs dfs -cat /curso/hive/datos_ventas/ventas_hive.csv | head -5
```

Cada registro posee seis campos:

```text
id_venta,fecha,cliente,ciudad,categoria,monto
```

> **Importante:** el archivo no posee una fila de encabezado. Los nombres anteriores describen la estructura de los registros, pero no forman parte del archivo.

### Interprete

Identifique:

1. ¿Dónde se encuentra físicamente el conjunto de datos?
2. ¿Cuántos campos posee cada registro?
3. ¿Qué campo debería ser numérico para realizar operaciones como suma o promedio?

---

## Ejercicio 7 — Crear un DataFrame desde HDFS

### Objetivo

Leer un archivo CSV almacenado en HDFS y representarlo mediante un DataFrame Spark.

Salga de `namenode`:

```bash
exit
```

Ingrese al contenedor Spark:

```bash
sudo docker exec -it spark-master bash
```

Diríjase a:

```bash
cd /spark/bin
```

Configure Python 3:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3
```

Inicie PySpark:

```bash
./pyspark --master spark://spark-master:7077
```

---

### Leer el archivo

Ejecute:

```python
ventas_df = (
    spark.read
    .option("header", "false")
    .option("inferSchema", "true")
    .csv("hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv")
)
```

Visualice algunos registros:

```python
ventas_df.show(5)
```

Observe que Spark asignó automáticamente nombres similares a:

```text
_c0
_c1
_c2
_c3
_c4
_c5
```

¿Por qué ocurrió esto?

Porque nuestro archivo CSV **no posee encabezado**.

---

### Asignar nombres a las columnas

Ejecute:

```python
ventas_df = ventas_df.toDF(
    "id_venta",
    "fecha",
    "cliente",
    "ciudad",
    "categoria",
    "monto"
)
```

Ahora:

```python
ventas_df.show(5)
```

Compruebe la cantidad de registros:

```python
ventas_df.count()
```

Resultado esperado:

```text
100000
```

### Interprete

Hemos pasado de:

```text
ventas_hive.csv
        │
        ▼
líneas de texto
```

a:

```text
DataFrame

id_venta | fecha | cliente | ciudad | categoria | monto
```

Spark conoce ahora una estructura para trabajar con los datos.

---

## Ejercicio 8 — Examinar y controlar el Schema

### Objetivo

Examinar los tipos de datos detectados por Spark y comprender la diferencia entre inferir y definir un esquema.

Ejecute:

```python
ventas_df.printSchema()
```

Observe cuidadosamente los tipos asignados.

También puede ejecutar:

```python
ventas_df.dtypes
```

### Analice

Compruebe especialmente:

```text
id_venta
fecha
monto
```

Responda:

1. ¿Qué tipo asignó Spark a `id_venta`?
2. ¿Qué tipo asignó a `monto`?
3. ¿Cómo interpretó `fecha`?
4. ¿Qué significa que Spark haya "inferido" estos tipos?

---

### Inferir no es lo mismo que definir

En el ejercicio anterior utilizamos:

```python
.option("inferSchema", "true")
```

Esto solicita a Spark que examine los datos para determinar sus tipos.

En un escenario donde conocemos previamente la estructura, también podemos definir explícitamente el schema.

Importe:

```python
from pyspark.sql.types import (
    StructType,
    StructField,
    IntegerType,
    StringType,
    DoubleType
)
```

Construya:

```python
schema_ventas = StructType([
    StructField("id_venta", IntegerType(), True),
    StructField("fecha", StringType(), True),
    StructField("cliente", StringType(), True),
    StructField("ciudad", StringType(), True),
    StructField("categoria", StringType(), True),
    StructField("monto", DoubleType(), True)
])
```

Ahora cree un segundo DataFrame:

```python
ventas_schema_df = (
    spark.read
    .option("header", "false")
    .schema(schema_ventas)
    .csv("hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv")
)
```

Compruebe:

```python
ventas_schema_df.printSchema()
```

### Compare

```text
Opción A
CSV → inferSchema → DataFrame

Opción B
CSV → schema definido → DataFrame
```

### Reflexione

¿Qué ventaja puede tener definir explícitamente el schema cuando conocemos de antemano la estructura de millones de registros?

> **Idea clave:** un schema explícito entrega a Spark la estructura esperada y evita depender de un proceso de inferencia para determinar los tipos de datos.

Para los ejercicios siguientes utilizaremos:

```text
ventas_schema_df
```

---

## Ejercicio 9 — Agrupar y agregar datos

### Objetivo

Realizar operaciones analíticas utilizando columnas estructuradas del DataFrame.

Queremos responder:

> **¿Cuántas ventas existen en cada categoría?**

Ejecute:

```python
ventas_schema_df.groupBy("categoria").count().show()
```

Observe el resultado.

Conceptualmente:

```text
100.000 ventas
      │
      ▼
groupBy("categoria")
      │
      ├── Tecnologia
      ├── Hogar
      ├── Vestuario
      ├── Alimentos
      └── Deportes
      │
      ▼
    count
```

---

### Calcular el monto total por categoría

Importe:

```python
from pyspark.sql.functions import sum, avg
```

Ahora ejecute:

```python
ventas_schema_df.groupBy("categoria") \
    .agg(sum("monto").alias("total_ventas")) \
    .show()
```

Observe los resultados.

Calcule ahora el **monto promedio** por categoría utilizando:

```text
avg
```

Construya usted mismo la instrucción.

---

### Realizar varias agregaciones

Podemos calcular más de una medida por grupo:

```python
ventas_schema_df.groupBy("categoria").agg(
    sum("monto").alias("total_ventas"),
    avg("monto").alias("promedio_venta")
).show()
```

### Compare con la Guía 1

Anteriormente utilizamos RDD:

```text
(categoria, monto)
       │
       ▼
  reduceByKey
```

Ahora:

```text
DataFrame
   │
   ▼
groupBy("categoria")
   │
   ▼
agg(sum("monto"))
```

Ambos enfoques pueden responder una pregunta similar, pero la segunda expresión trabaja directamente con la estructura de los datos.

### Interprete

Responda:

1. ¿Qué función cumple `groupBy`?
2. ¿Qué función cumple `agg`?
3. ¿Para qué utilizamos `alias`?
4. ¿Qué operación de la Guía 1 cumplía un propósito comparable a esta agregación por clave?

---

## Ejercicio 10 — Consultar un DataFrame mediante Spark SQL

### Objetivo

Utilizar SQL sobre un DataFrame Spark y relacionar las operaciones de la API DataFrame con expresiones SQL.

Hasta ahora hemos utilizado instrucciones como:

```python
ventas_schema_df.groupBy("categoria") \
    .agg(sum("monto").alias("total_ventas")) \
    .show()
```

Spark también permite expresar una consulta mediante SQL.

Para ello primero debemos registrar nuestro DataFrame como una **vista temporal**.

Ejecute:

```python
ventas_schema_df.createOrReplaceTempView("ventas")
```

Ahora Spark SQL puede referirse a:

```text
ventas
```

como una estructura consultable durante nuestra sesión Spark.

---

### Primera consulta Spark SQL

Ejecute:

```python
spark.sql("""
    SELECT categoria,
           COUNT(*) AS cantidad_ventas
    FROM ventas
    GROUP BY categoria
""").show()
```

Compare este resultado con:

```python
ventas_schema_df.groupBy("categoria").count().show()
```

Los resultados deberían ser equivalentes.

---

### Segunda consulta

Responda mediante Spark SQL:

> **¿Cuál es el monto total vendido por categoría?**

Utilice:

```sql
SELECT
GROUP BY
SUM()
```

Construya usted mismo la consulta.

---

### Tercera consulta

Responda:

> **¿Cuál es el monto promedio de las ventas realizadas en cada ciudad?**

Utilice:

```sql
SELECT
AVG()
GROUP BY
```

No se entrega la consulta completa.

---

## DataFrame API versus Spark SQL

Observe:

### DataFrame API

```python
ventas_schema_df.groupBy("categoria").agg(
    sum("monto").alias("total_ventas")
).show()
```

### Spark SQL

```sql
SELECT categoria,
       SUM(monto) AS total_ventas
FROM ventas
GROUP BY categoria
```

Ambas formas trabajan sobre el mismo motor Spark:

```text
             DataFrame
                 │
        ┌────────┴────────┐
        ▼                 ▼
  DataFrame API       Spark SQL
        │                 │
        └────────┬────────┘
                 ▼
              Spark
                 │
                 ▼
        procesamiento
         distribuido
```

---

## ¿Qué es la vista temporal?

La instrucción:

```python
ventas_schema_df.createOrReplaceTempView("ventas")
```

**no crea una nueva tabla Hive ni duplica `ventas_hive.csv` en HDFS.**

Crea una vista asociada a la sesión Spark actual que permite consultar el DataFrame mediante SQL.

Por lo tanto:

```text
ventas_hive.csv
      │
      ▼
     HDFS
      │
      ▼
DataFrame Spark
      │
      ▼
vista temporal "ventas"
      │
      ▼
Spark SQL
```

Si finalizamos la sesión Spark, esta vista temporal deja de existir.

---

## Observe el clúster

Mantenga abierta la interfaz **Spark Master**:

```text
http://localhost:8080
```

> **Recuerde:** si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la **IP pública de su instancia**.

Ejecute algunas de las consultas anteriores y observe la aplicación Spark.

Relacione conceptualmente:

```text
Spark SQL
    │
    ▼
DataFrame
    │
    ▼
plan de ejecución
    │
    ▼
   Job
    │
    ▼
  Tasks
```

---

# Reflexión del Nivel 2

Responda brevemente:

1. ¿Dónde se encuentran almacenadas físicamente las 100.000 ventas?
2. ¿Qué diferencia existe entre `inferSchema` y definir explícitamente un schema?
3. ¿Qué ventaja proporciona `groupBy` sobre el procesamiento manual de posiciones dentro de cada registro?
4. ¿Qué permite realizar `createOrReplaceTempView()`?
5. ¿La vista temporal `ventas` corresponde a una tabla almacenada en Hive?
6. ¿Qué relación existe entre DataFrame API y Spark SQL?
7. ¿Qué ocurre con la vista temporal cuando finaliza la sesión Spark?

---

## Resultado esperado del Nivel 2

Al finalizar estos ejercicios debería poder interpretar el siguiente flujo:

```text
                       HDFS
                         │
                         ▼
                 ventas_hive.csv
                         │
                         ▼
                  Spark Reader
                         │
                         ▼
                     Schema
                         │
                         ▼
                    DataFrame
                         │
            ┌────────────┼────────────┐
            ▼            ▼            ▼
         select        filter      groupBy
                                      │
                                      ▼
                                     agg
                         │
                         ▼
                 Vista temporal
                    "ventas"
                         │
                         ▼
                    Spark SQL
                         │
                         ▼
                     Resultado
```

En este punto Spark ya puede trabajar con las 100.000 ventas utilizando dos formas complementarias:

```text
DataFrame API
      │
      ├──────────────┐
      │              │
      ▼              ▼
   select         groupBy
   filter           agg

         o

      Spark SQL
          │
          ▼
 SELECT / WHERE
 GROUP BY / SUM
```

En el **Nivel 3** utilizaremos ambas alternativas para resolver problemas analíticos más completos y posteriormente incorporaremos nuevamente **Apache Hive**, comparando una misma consulta realizada mediante:

```text
                    HDFS
                      │
              ventas_hive.csv
                      │
           ┌──────────┴──────────┐
           ▼                     ▼
         Hive                  Spark
           │                     │
        HiveQL             DataFrame
                                 │
                                 ▼
                            Spark SQL
```

Esto permitirá distinguir con claridad algo importante: **Spark SQL utiliza SQL, pero eso no significa que esté utilizando Hive para ejecutar nuestras consultas**.

---

# Nivel 3 — Avanzado

En este nivel utilizaremos las **100.000 ventas almacenadas en HDFS** para resolver problemas analíticos mediante DataFrames y Spark SQL.

El nivel culminará comparando dos motores que trabajan sobre los mismos datos:

```text
                     HDFS
                       │
                       ▼
               ventas_hive.csv
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
          Hive                  Spark
            │                     │
         HiveQL              DataFrame
                                  │
                                  ▼
                              Spark SQL
```

Recuerde que utilizaremos:

```text
ventas_schema_df
```

como DataFrame principal y:

```text
ventas
```

como vista temporal para Spark SQL.

---

## Ejercicio 11 — Filtrar y agregar mediante DataFrame API

### Objetivo

Combinar filtros y agregaciones para responder una pregunta analítica utilizando DataFrame API.

Queremos responder:

> **¿Cuál es el monto total vendido por ciudad considerando solamente las ventas de la categoría Tecnología?**

### Planifique

Antes de escribir código, determine qué operaciones necesita:

```text
100.000 ventas
      │
      ▼
filtrar categoria = Tecnologia
      │
      ▼
agrupar por ciudad
      │
      ▼
sumar monto
      │
      ▼
resultado
```

Construya la solución utilizando:

```text
filter
groupBy
agg
sum
```

No se entrega la instrucción completa.

### Verifique

El resultado debe contener:

```text
ciudad | total_ventas
```

y solamente debe considerar registros cuya categoría sea:

```text
Tecnologia
```

### Ordenar el resultado

Para facilitar su interpretación, ordene el resultado desde el mayor monto total al menor.

Puede investigar/utilizar:

```python
.orderBy(...)
```

junto con:

```python
from pyspark.sql.functions import desc
```

### Interprete

Responda:

1. ¿Qué operación redujo inicialmente el conjunto de registros?
2. ¿Qué operación creó los grupos?
3. ¿Qué función realizó la agregación?
4. ¿El ordenamiento modifica el DataFrame original?

---

## Ejercicio 12 — Resolver el mismo problema mediante Spark SQL

### Objetivo

Comprobar que un mismo problema analítico puede expresarse mediante DataFrame API o mediante Spark SQL.

Utilice la vista temporal:

```text
ventas
```

Resuelva nuevamente:

> **¿Cuál es el monto total vendido por ciudad considerando solamente las ventas de la categoría Tecnología?**

Construya una consulta utilizando:

```sql
SELECT
FROM
WHERE
GROUP BY
ORDER BY
SUM()
```

No se entrega la consulta completa.

### Compare

Ahora dispone de dos soluciones:

```text
                 MISMO PROBLEMA
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
       DataFrame API         Spark SQL
             │                   │
             ▼                   ▼
filter + groupBy         WHERE + GROUP BY
             │                   │
             ▼                   ▼
           agg                  SUM
             │                   │
             └─────────┬─────────┘
                       ▼
                mismo resultado
```

Complete:

| DataFrame API | Spark SQL  |
| ------------- | ---------- |
| `filter`      | __________ |
| `groupBy`     | __________ |
| `sum`         | __________ |
| `orderBy`     | __________ |

### Reflexione

¿Spark SQL constituye un motor completamente diferente de DataFrame API?

Explique brevemente qué elemento permanece común en ambas alternativas.

---

## Ejercicio 13 — Analizar ventas por año y mes

### Objetivo

Crear información derivada a partir de una columna existente y utilizarla para realizar una agregación.

Actualmente:

```text
fecha → String
```

con valores en formato:

```text
YYYY-MM-DD
```

Por ejemplo:

```text
2025-07-18
```

Queremos responder:

> **¿Cuál fue el monto total vendido en cada mes de 2025?**

### Paso 1. Convertir la fecha

Importe:

```python
from pyspark.sql.functions import to_date, month
```

Cree una nueva columna:

```python
ventas_fecha_df = ventas_schema_df.withColumn(
    "fecha_date",
    to_date("fecha", "yyyy-MM-dd")
)
```

Compruebe:

```python
ventas_fecha_df.select(
    "fecha",
    "fecha_date"
).show(5)
```

Examine ahora:

```python
ventas_fecha_df.printSchema()
```

Observe la diferencia entre:

```text
fecha      → string
fecha_date → date
```

### Paso 2. Obtener el mes

Agregue una columna denominada:

```text
mes
```

utilizando la función:

```text
month()
```

Construya usted mismo la instrucción.

### Paso 3. Agregar las ventas

Responda:

> ¿Cuál fue el monto total vendido durante cada mes?

Su resultado debe tener una estructura equivalente a:

```text
mes | total_ventas
```

y encontrarse ordenado cronológicamente.

### Interprete

Observe el recorrido:

```text
fecha
  │
  │ to_date
  ▼
fecha_date
  │
  │ month
  ▼
 mes
  │
  │ groupBy
  ▼
SUM(monto)
```

¿Por qué resulta más apropiado trabajar con una columna de tipo `date` que tratar permanentemente la fecha como un texto?

---

## Ejercicio 14 — Comparar Spark SQL con HiveQL

### Objetivo

Resolver la misma pregunta analítica mediante Spark SQL y Apache Hive para distinguir el papel de cada tecnología.

Utilizaremos:

> **¿Cuál es el monto promedio de venta por ciudad?**

---

### Parte A — Resolver mediante Spark SQL

Asegúrese de disponer de la vista temporal:

```python
ventas_schema_df.createOrReplaceTempView("ventas")
```

Construya una consulta Spark SQL que utilice:

```sql
SELECT
AVG()
FROM
GROUP BY
```

Registre el resultado.

---

### Parte B — Resolver mediante Hive

Finalice la sesión PySpark:

```python
exit()
```

Salga del contenedor:

```bash
exit
```

Ingrese ahora al componente responsable de Hive:

```bash
sudo docker exec -it hive-server bash
```

Inicie Hive:

```bash
hive
```

Seleccione:

```sql
USE curso_bigdata;
```

Compruebe:

```sql
SHOW TABLES;
```

Debe encontrar:

```text
ventas_hive
```

Construya ahora una consulta HiveQL que responda exactamente la misma pregunta:

> **¿Cuál es el monto promedio de venta por ciudad?**

Registre el resultado.

---

## Compare los resultados

Conceptualmente hemos realizado:

```text
                      HDFS
                        │
                        ▼
                ventas_hive.csv
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
          Hive                    Spark
            │                       │
     ventas_hive               DataFrame
            │                       │
            ▼                       ▼
         HiveQL                 Spark SQL
            │                       │
        AVG(monto)              AVG(monto)
        GROUP BY                GROUP BY
            │                       │
            └───────────┬───────────┘
                        ▼
                resultados
                equivalentes
```

### Complete

| Característica                                 | Hive                | Spark      |
| ---------------------------------------------- | ------------------- | ---------- |
| Datos físicos                                  | HDFS                | HDFS       |
| Representación utilizada                       | Tabla `ventas_hive` | __________ |
| Lenguaje de consulta                           | HiveQL              | __________ |
| Utiliza Hive Metastore en nuestra arquitectura | Sí                  | __________ |
| Motor que procesa la consulta                  | Hive                | __________ |

### Pregunta fundamental

Si las consultas HiveQL y Spark SQL poseen una sintaxis muy similar:

> **¿Significa esto que Spark SQL está ejecutando la consulta mediante Hive?**

Justifique su respuesta considerando nuestra infraestructura.

> **Importante:** en nuestra infraestructura actual Spark no está conectado al Hive Metastore. Ambos motores acceden a los mismos datos almacenados en HDFS, pero lo hacen mediante mecanismos diferentes.

---

## Ejercicio 15 — Desafío integrador

### Objetivo

Diseñar de manera autónoma un pequeño análisis utilizando DataFrames y Spark SQL.

Trabajaremos nuevamente con:

```text
hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv
```

### Problema

La organización desea conocer el comportamiento de sus ventas de mayor valor.

Responda:

> **¿Cuáles son las categorías con mayor monto total vendido, considerando solamente las ventas superiores a $250.000?**

El resultado deberá mostrar:

```text
categoria | cantidad_ventas | total_ventas | promedio_venta
```

y deberá encontrarse ordenado desde el mayor al menor:

```text
total_ventas
```

---

## Parte A — Planifique

Complete conceptualmente el procesamiento:

```text
HDFS
  │
  ▼
ventas_hive.csv
  │
  ▼
____________________
  │
  ▼
Schema
  │
  ▼
____________________
  │
  ▼
monto > 250000
  │
  ▼
____________________
  │
  ▼
categoria
  │
  ├── cantidad
  ├── suma
  └── promedio
  │
  ▼
____________________
  │
  ▼
resultado ordenado
```

---

## Parte B — Resuelva mediante DataFrame API

Construya una solución que incluya:

* lectura de HDFS;
* schema;
* `filter`;
* `groupBy`;
* agregaciones;
* alias;
* ordenamiento.

No se entrega el código completo.

---

## Parte C — Resuelva mediante Spark SQL

Registre el DataFrame como una vista temporal.

Construya una consulta que utilice:

```sql
SELECT
COUNT()
SUM()
AVG()
WHERE
GROUP BY
ORDER BY
```

Compare los resultados obtenidos mediante ambas alternativas.

---

## Parte D — Observe la ejecución

Mientras ejecuta el análisis, observe la interfaz **Spark Master**:

```text
http://localhost:8080
```

> **Recuerde:** si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la **IP pública de su instancia**.

Relacione el análisis realizado con:

```text
DataFrame / Spark SQL
          │
          ▼
    Plan de ejecución
          │
          ▼
         Job
          │
          ▼
        Stages
          │
          ▼
         Tasks
          │
          ▼
       Executor
          │
          ▼
        Worker
```

---

## Evidencia final

Registre:

1. resultado obtenido mediante DataFrame API;
2. resultado obtenido mediante Spark SQL;
3. número de registros del DataFrame inicial;
4. schema utilizado;
5. operaciones de filtrado;
6. operaciones de agrupación y agregación;
7. una breve explicación de por qué ambos métodos producen resultados equivalentes.

---

# Cierre de la Guía Práctica 2

Durante esta guía avanzamos desde el procesamiento mediante RDD hacia el procesamiento estructurado de Apache Spark.

En la Guía 1 trabajamos principalmente con:

```text
RDD
 │
 ├── map
 ├── filter
 └── reduceByKey
```

Ahora incorporamos:

```text
DataFrame
 │
 ├── Schema
 ├── Columnas
 ├── select
 ├── filter
 ├── withColumn
 ├── groupBy
 └── agg
```

y posteriormente:

```text
DataFrame
    │
    ▼
Vista temporal
    │
    ▼
Spark SQL
```

---

## Evolución del procesamiento

El recorrido de las dos guías puede representarse como:

```text
                    HDFS
                      │
                      ▼
              ventas_hive.csv
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼                   ▼
          Hive                Spark
            │                   │
            ▼             ┌─────┴─────┐
         HiveQL           ▼           ▼
                         RDD      DataFrame
                          │           │
                     map/filter      Schema
                     reduceByKey      │
                                      ▼
                                  Spark SQL
```

---

# RDD versus DataFrame

| Característica     | RDD                            | DataFrame                            |
| ------------------ | ------------------------------ | ------------------------------------ |
| Abstracción        | Colección distribuida          | Datos estructurados distribuidos     |
| Estructura tabular | No necesariamente              | Sí                                   |
| Schema             | No                             | Sí                                   |
| Acceso típico      | Elementos/posiciones           | Columnas                             |
| Operaciones        | `map`, `filter`, `reduceByKey` | `select`, `filter`, `groupBy`, `agg` |
| Consultas SQL      | No directamente                | Sí, mediante Spark SQL               |

No debe interpretarse esta comparación como que un RDD "dejó de existir" cuando utilizamos DataFrames. Ambos pertenecen al ecosistema Spark, pero ofrecen **niveles de abstracción diferentes** para resolver problemas.

---

# HiveQL versus Spark SQL

También comprobamos que:

```text
HiveQL ≠ Spark SQL
```

aunque visualmente podamos escribir consultas muy similares:

```sql
SELECT ciudad,
       AVG(monto)
FROM ventas
GROUP BY ciudad;
```

En nuestra infraestructura:

```text
Hive
 │
 ├── tabla ventas_hive
 ├── Hive Metastore
 └── HDFS
```

mientras:

```text
Spark
 │
 ├── DataFrame
 ├── vista temporal
 ├── Spark SQL
 └── HDFS
```

Los datos físicos pueden ser los mismos, pero las capas de procesamiento y metadatos no necesariamente lo son.

---

# Ideas fundamentales

Al finalizar esta guía debe poder explicar que:

* un **DataFrame** representa datos distribuidos organizados mediante filas, columnas y un schema;
* el **schema** describe nombres y tipos de las columnas;
* Spark puede inferir un schema o utilizar uno definido explícitamente;
* `select`, `filter`, `withColumn`, `groupBy` y `agg` permiten manipular DataFrames;
* una **vista temporal** permite consultar un DataFrame mediante Spark SQL;
* crear una vista temporal no crea automáticamente una tabla Hive;
* **DataFrame API y Spark SQL** son dos formas de expresar procesamiento estructurado sobre Spark;
* **HiveQL y Spark SQL pueden utilizar sintaxis semejante sin ser el mismo motor**;
* HDFS continúa siendo la capa de almacenamiento compartida por los componentes utilizados durante nuestras actividades.

---

# Síntesis de las dos guías

Después de completar las Guías Prácticas 1 y 2, el recorrido desarrollado es:

```text
                        BIG DATA
                           │
                           ▼
                          HDFS
                           │
                           ▼
                   ventas_hive.csv
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
            HIVE                       SPARK
              │                         │
              ▼                ┌────────┴────────┐
           HiveQL              ▼                 ▼
                              RDD            DataFrame
                               │                 │
                        Transformaciones       Schema
                        Acciones                │
                        Particiones             ▼
                        Lazy Evaluation     Spark SQL
                               │                 │
                               └────────┬────────┘
                                        ▼
                              Procesamiento
                               distribuido
```

Con esto hemos pasado desde **almacenar grandes volúmenes de datos**, a **estructurarlos y consultarlos**, y finalmente a **procesarlos de forma distribuida mediante diferentes niveles de abstracción de Apache Spark**.


