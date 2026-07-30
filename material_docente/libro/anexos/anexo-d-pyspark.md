# Anexo D. Principales comandos de PySpark

## Introducción

Este anexo reúne los comandos más utilizados durante el desarrollo de aplicaciones con **PySpark**. Su propósito es servir como una guía de consulta rápida para estudiantes y profesionales que trabajan con Apache Spark.

Los ejemplos presentados corresponden a la API de **DataFrames**, actualmente el modelo de programación recomendado por Apache Spark para el procesamiento distribuido de datos.

---

# D.1 Creación de la SparkSession

| Comando | Descripción |
|----------|-------------|
| `from pyspark.sql import SparkSession` | Importa la clase SparkSession. |
| `SparkSession.builder` | Inicia la configuración de la sesión. |
| `.appName("MiApp")` | Asigna nombre a la aplicación. |
| `.master("local[*]")` | Ejecuta Spark utilizando todos los núcleos locales. |
| `.getOrCreate()` | Crea o reutiliza una SparkSession existente. |
| `spark.stop()` | Finaliza la sesión de Spark. |
| `spark.version` | Muestra la versión instalada. |
| `spark.sparkContext.master` | Indica el modo de ejecución. |

---

# D.2 Lectura de datos

| Comando | Descripción |
|----------|-------------|
| `spark.read.csv()` | Lee archivos CSV. |
| `spark.read.json()` | Lee archivos JSON. |
| `spark.read.parquet()` | Lee archivos Parquet. |
| `spark.read.orc()` | Lee archivos ORC. |
| `header=True` | Utiliza la primera fila como encabezado. |
| `inferSchema=True` | Detecta automáticamente los tipos de datos. |
| `schema=` | Define manualmente el esquema. |

---

# D.3 Escritura de datos

| Comando | Descripción |
|----------|-------------|
| `write.csv()` | Guarda datos en CSV. |
| `write.parquet()` | Guarda datos en Parquet. |
| `write.json()` | Guarda datos en JSON. |
| `write.orc()` | Guarda datos en ORC. |
| `mode("overwrite")` | Reemplaza los datos existentes. |
| `mode("append")` | Agrega registros al destino. |
| `mode("ignore")` | Ignora la escritura si existe el destino. |
| `mode("error")` | Genera error si el destino existe. |

---

# D.4 Exploración de DataFrames

| Comando | Descripción |
|----------|-------------|
| `show()` | Visualiza registros. |
| `show(10)` | Muestra los primeros 10 registros. |
| `printSchema()` | Muestra el esquema. |
| `columns` | Lista los nombres de columnas. |
| `dtypes` | Lista tipos de datos. |
| `count()` | Cuenta registros. |
| `describe()` | Estadísticas descriptivas básicas. |
| `summary()` | Resumen estadístico ampliado. |

---

# D.5 Selección de columnas

| Comando | Descripción |
|----------|-------------|
| `select()` | Selecciona columnas. |
| `alias()` | Cambia temporalmente el nombre de una columna. |
| `col()` | Hace referencia a una columna. |
| `drop()` | Elimina columnas. |
| `withColumnRenamed()` | Cambia permanentemente el nombre de una columna. |

---

# D.6 Filtrado de datos

| Comando | Descripción |
|----------|-------------|
| `filter()` | Filtra registros. |
| `where()` | Equivalente a filter(). |
| `==` | Igualdad. |
| `!=` | Distinto. |
| `>` | Mayor que. |
| `<` | Menor que. |
| `>=` | Mayor o igual. |
| `<=` | Menor o igual. |
| `isin()` | Busca valores dentro de una lista. |
| `between()` | Filtra por rango. |

---

# D.7 Ordenamiento

| Comando | Descripción |
|----------|-------------|
| `orderBy()` | Ordena registros. |
| `sort()` | Equivalente a orderBy(). |
| `asc()` | Orden ascendente. |
| `desc()` | Orden descendente. |

---

# D.8 Agrupación y agregación

| Comando | Descripción |
|----------|-------------|
| `groupBy()` | Agrupa registros. |
| `agg()` | Ejecuta funciones de agregación. |
| `sum()` | Suma valores. |
| `avg()` | Calcula promedio. |
| `mean()` | Promedio. |
| `max()` | Valor máximo. |
| `min()` | Valor mínimo. |
| `count()` | Cuenta registros por grupo. |

---

# D.9 Joins

| Comando | Descripción |
|----------|-------------|
| `join()` | Une dos DataFrames. |
| `"inner"` | Unión interna. |
| `"left"` | Unión izquierda. |
| `"right"` | Unión derecha. |
| `"outer"` | Unión completa. |
| `"cross"` | Producto cartesiano. |

---

# D.10 Creación y modificación de columnas

| Comando | Descripción |
|----------|-------------|
| `withColumn()` | Agrega o modifica columnas. |
| `lit()` | Crea valores constantes. |
| `when()` | Expresión condicional. |
| `otherwise()` | Caso contrario en una condición. |
| `expr()` | Ejecuta expresiones SQL. |

---

# D.11 Funciones matemáticas

| Comando | Descripción |
|----------|-------------|
| `round()` | Redondea valores. |
| `abs()` | Valor absoluto. |
| `sqrt()` | Raíz cuadrada. |
| `pow()` | Potencia. |
| `ceil()` | Redondea hacia arriba. |
| `floor()` | Redondea hacia abajo. |

---

# D.12 Funciones de texto

| Comando | Descripción |
|----------|-------------|
| `upper()` | Convierte a mayúsculas. |
| `lower()` | Convierte a minúsculas. |
| `trim()` | Elimina espacios. |
| `length()` | Longitud del texto. |
| `concat()` | Concatena columnas. |
| `substring()` | Extrae parte de un texto. |
| `regexp_replace()` | Reemplaza utilizando expresiones regulares. |

---

# D.13 Funciones de fechas

| Comando | Descripción |
|----------|-------------|
| `current_date()` | Fecha actual. |
| `current_timestamp()` | Fecha y hora actual. |
| `year()` | Extrae el año. |
| `month()` | Extrae el mes. |
| `dayofmonth()` | Extrae el día. |
| `datediff()` | Diferencia entre fechas. |
| `date_add()` | Agrega días. |
| `date_sub()` | Resta días. |

---

# D.14 Manejo de valores nulos

| Comando | Descripción |
|----------|-------------|
| `dropna()` | Elimina registros con nulos. |
| `fillna()` | Reemplaza valores nulos. |
| `replace()` | Sustituye valores. |
| `isNull()` | Verifica valores nulos. |
| `isNotNull()` | Verifica valores no nulos. |

---

# D.15 Eliminación de duplicados

| Comando | Descripción |
|----------|-------------|
| `distinct()` | Elimina registros duplicados. |
| `dropDuplicates()` | Elimina duplicados considerando columnas específicas. |

---

# D.16 Acciones

| Comando | Descripción |
|----------|-------------|
| `show()` | Visualiza registros. |
| `count()` | Cuenta registros. |
| `collect()` | Devuelve los datos al controlador. |
| `first()` | Obtiene el primer registro. |
| `take(n)` | Obtiene los primeros n registros. |
| `head()` | Devuelve los primeros registros. |

---

# D.17 Persistencia

| Comando | Descripción |
|----------|-------------|
| `cache()` | Almacena en memoria. |
| `persist()` | Persistencia configurable. |
| `unpersist()` | Libera memoria. |

---

# D.18 Consultas SQL

| Comando | Descripción |
|----------|-------------|
| `createOrReplaceTempView()` | Crea una vista temporal. |
| `spark.sql()` | Ejecuta consultas SQL sobre DataFrames. |

Ejemplo:

```python
ventas.createOrReplaceTempView("ventas")

spark.sql("""
SELECT categoria,
       SUM(total) AS ventas
FROM ventas
GROUP BY categoria
""").show()
```

---

# D.19 Flujo básico de una aplicación PySpark

El siguiente esquema resume la secuencia típica utilizada en la mayoría de las aplicaciones desarrolladas con PySpark.

```text
Crear SparkSession
        │
        ▼
Leer datos
        │
        ▼
Crear DataFrame
        │
        ▼
Explorar información
        │
        ▼
Aplicar transformaciones
        │
        ▼
Ejecutar acciones
        │
        ▼
Guardar resultados
        │
        ▼
Finalizar SparkSession
```

---

# D.20 Recomendaciones para el desarrollo de aplicaciones PySpark

Durante el desarrollo de aplicaciones distribuidas se recomienda:

- Crear una única **SparkSession** por aplicación.
- Utilizar nombres descriptivos para los DataFrames.
- Verificar el esquema de los datos antes de procesarlos.
- Encadenar transformaciones antes de ejecutar una acción.
- Preferir formatos columnares como **Parquet** para almacenamiento analítico.
- Evitar el uso excesivo de `collect()`, ya que transfiere todos los datos al nodo controlador.
- Utilizar `cache()` únicamente cuando un DataFrame será reutilizado varias veces.
- Documentar el código y utilizar nombres de variables consistentes.
- Cerrar la SparkSession mediante `spark.stop()` al finalizar la aplicación.

---

Este anexo constituye una guía de referencia rápida para el desarrollo de aplicaciones con PySpark. Se recomienda utilizarlo como apoyo durante la realización de los laboratorios, proyectos y evaluaciones del curso, así como complemento de la documentación oficial de Apache Spark.
