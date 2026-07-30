# Anexo C. Principales comandos de Apache Spark (PySpark)

## Introducción

Este anexo reúne los comandos básicos de **PySpark** utilizados con mayor frecuencia durante el desarrollo de aplicaciones de procesamiento distribuido. Su propósito es servir como material de consulta rápida durante los laboratorios del curso y en el desarrollo de proyectos de Big Data.

Los ejemplos presentados consideran el uso de **PySpark**, la API de Apache Spark para Python, utilizada a lo largo de este libro.

---

# A.1 Creación de una sesión Spark

Crear una nueva sesión de trabajo.

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MiAplicacion") \
    .getOrCreate()
```

Verificar la versión instalada.

```python
spark.version
```

Finalizar la sesión.

```python
spark.stop()
```

---

# A.2 Lectura de archivos

## Leer un archivo CSV

```python
df = spark.read.csv(
    "ventas.csv",
    header=True,
    inferSchema=True
)
```

---

## Leer un archivo JSON

```python
df = spark.read.json("datos.json")
```

---

## Leer archivos Parquet

```python
df = spark.read.parquet("ventas.parquet")
```

---

## Leer tablas Hive

```python
df = spark.table("ventas")
```

---

# A.3 Exploración de DataFrames

Mostrar registros.

```python
df.show()
```

Mostrar un número específico de registros.

```python
df.show(20)
```

Visualizar la estructura del DataFrame.

```python
df.printSchema()
```

Obtener los nombres de las columnas.

```python
df.columns
```

Contar registros.

```python
df.count()
```

Describir variables numéricas.

```python
df.describe().show()
```

---

# A.4 Selección de columnas

Seleccionar columnas.

```python
df.select(
    "producto",
    "precio"
)
```

Seleccionar múltiples columnas.

```python
df.select(
    "producto",
    "cantidad",
    "precio"
)
```

Eliminar columnas.

```python
df.drop("precio")
```

Renombrar columnas.

```python
df.withColumnRenamed(
    "precio",
    "precio_unitario"
)
```

---

# A.5 Filtrado de datos

Filtrar registros.

```python
df.filter(
    df.precio > 1000
)
```

Utilizando SQL.

```python
df.where(
    "precio > 1000"
)
```

Condiciones múltiples.

```python
df.filter(
    (df.precio > 1000) &
    (df.cantidad >= 5)
)
```

---

# A.6 Ordenamiento

Orden ascendente.

```python
df.orderBy("precio")
```

Orden descendente.

```python
df.orderBy(
    df.precio.desc()
)
```

---

# A.7 Creación de columnas

Agregar una nueva columna.

```python
from pyspark.sql.functions import col

df = df.withColumn(
    "total",
    col("cantidad") *
    col("precio")
)
```

Agregar IVA.

```python
df = df.withColumn(
    "iva",
    col("total") * 0.19
)
```

---

# A.8 Funciones de agregación

Importar funciones.

```python
from pyspark.sql.functions import *
```

Suma.

```python
df.groupBy("ciudad") \
  .agg(sum("total"))
```

Promedio.

```python
df.groupBy("categoria") \
  .agg(avg("precio"))
```

Máximo.

```python
df.groupBy("categoria") \
  .agg(max("precio"))
```

Mínimo.

```python
df.groupBy("categoria") \
  .agg(min("precio"))
```

Cantidad de registros.

```python
df.groupBy("categoria") \
  .count()
```

---

# A.9 Agrupamiento

Agrupar datos.

```python
df.groupBy("categoria")
```

Agrupar múltiples columnas.

```python
df.groupBy(
    "categoria",
    "ciudad"
)
```

---

# A.10 Eliminación de duplicados

Eliminar registros repetidos.

```python
df.dropDuplicates()
```

Eliminar duplicados considerando columnas específicas.

```python
df.dropDuplicates(
    ["producto"]
)
```

---

# A.11 Tratamiento de valores nulos

Eliminar registros con valores nulos.

```python
df.na.drop()
```

Reemplazar valores nulos.

```python
df.na.fill(0)
```

Reemplazar texto.

```python
df.na.fill("Sin dato")
```

---

# A.12 Unión de DataFrames

Unión interna.

```python
df1.join(
    df2,
    "id"
)
```

Unión izquierda.

```python
df1.join(
    df2,
    "id",
    "left"
)
```

Unión completa.

```python
df1.join(
    df2,
    "id",
    "outer"
)
```

---

# A.13 Ordenamiento y limitación

Primeros registros.

```python
df.limit(10)
```

Primer registro.

```python
df.first()
```

Recuperar registros.

```python
df.take(5)
```

---

# A.14 Escritura de archivos

Guardar como CSV.

```python
df.write.csv(
    "salida"
)
```

Guardar sobrescribiendo.

```python
df.write.mode(
    "overwrite"
).csv("salida")
```

Guardar como Parquet.

```python
df.write.parquet(
    "ventas.parquet"
)
```

Guardar como tabla Hive.

```python
df.write.saveAsTable(
    "ventas"
)
```

---

# A.15 Consultas SQL

Crear vista temporal.

```python
df.createOrReplaceTempView(
    "ventas"
)
```

Ejecutar consulta SQL.

```python
spark.sql("""
SELECT ciudad,
       SUM(total)
FROM ventas
GROUP BY ciudad
""")
```

---

# A.16 Funciones útiles

Cantidad de filas.

```python
df.count()
```

Cantidad de columnas.

```python
len(df.columns)
```

Mostrar esquema.

```python
df.schema
```

Mostrar tipos de datos.

```python
df.dtypes
```

Convertir a Pandas.

```python
df.toPandas()
```

---

# A.17 Ejecución de aplicaciones Spark

Ejecutar un programa PySpark.

```bash
spark-submit programa.py
```

Ejecutar indicando el maestro.

```bash
spark-submit \
--master local[*] \
programa.py
```

Ejecutar sobre un clúster Standalone.

```bash
spark-submit \
--master spark://master:7077 \
programa.py
```

Ejecutar sobre YARN.

```bash
spark-submit \
--master yarn \
programa.py
```

---

# A.18 Resumen de los comandos más utilizados

| Categoría | Comandos principales |
|-----------|----------------------|
| Crear sesión | `SparkSession.builder()` |
| Leer datos | `read.csv()`, `read.json()`, `read.parquet()` |
| Explorar datos | `show()`, `printSchema()`, `count()`, `describe()` |
| Seleccionar columnas | `select()`, `drop()`, `withColumnRenamed()` |
| Filtrar datos | `filter()`, `where()` |
| Ordenar | `orderBy()` |
| Crear columnas | `withColumn()` |
| Agrupar | `groupBy()`, `agg()` |
| Funciones agregadas | `sum()`, `avg()`, `min()`, `max()`, `count()` |
| Uniones | `join()` |
| Eliminar duplicados | `dropDuplicates()` |
| Valores nulos | `na.drop()`, `na.fill()` |
| Guardar resultados | `write.csv()`, `write.parquet()`, `saveAsTable()` |
| SQL | `createOrReplaceTempView()`, `spark.sql()` |
| Ejecutar aplicaciones | `spark-submit` |

---

## Consulta rápida

Este anexo resume los comandos fundamentales de **PySpark** utilizados durante los laboratorios y ejemplos del libro. No reemplaza la documentación oficial de Apache Spark, pero constituye una referencia práctica para el desarrollo de actividades de procesamiento distribuido, consultas analíticas y manipulación de DataFrames en entornos Big Data.
