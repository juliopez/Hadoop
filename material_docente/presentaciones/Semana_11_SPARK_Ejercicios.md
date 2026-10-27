# Guía Práctica 3 — Procesamiento avanzado y pipelines con Apache Spark

## Propósito

Integrar las capacidades trabajadas previamente en Apache Spark para construir flujos de procesamiento más completos, incorporando transformaciones encadenadas, persistencia de resultados en HDFS, formatos de almacenamiento, integración de múltiples DataFrames, particionamiento y reutilización de datos.

Al finalizar la guía, el estudiante deberá ser capaz de comprender el funcionamiento de un **pipeline batch completo**, desde la lectura de datos almacenados en HDFS hasta la persistencia de resultados procesados, y reconocer las limitaciones de este modelo cuando los datos comienzan a generarse continuamente.

## Organización de la guía

| Nivel | Ejercicios | Foco |
|---|---:|---|
| **Nivel 1 — Procesamiento y persistencia** | 1–5 | Transformaciones encadenadas, escritura en HDFS, CSV y Parquet |
| **Nivel 2 — Integración y optimización** | 6–10 | Múltiples DataFrames, joins, particiones y persistencia en memoria |
| **Nivel 3 — Pipeline avanzado y transición a streaming** | 11–15 | Pipeline integral, HDFS entrada/salida, batch y transición conceptual hacia Kafka |

## Conocimientos previos necesarios

Esta tercera guía continúa el trabajo desarrollado en las semanas 9 y 10. Antes de comenzar, debe poder realizar las siguientes tareas sin depender de instrucciones paso a paso:

- **Crear una `SparkSession`:** iniciar una aplicación PySpark y utilizar la sesión como punto de entrada para trabajar con datos estructurados.
- **Leer datos como DataFrames:** cargar archivos almacenados en HDFS, identificar sus columnas y comprobar su esquema y cantidad de registros.
- **Aplicar transformaciones:** seleccionar, filtrar y crear columnas derivadas; realizar agrupaciones y agregaciones mediante la DataFrame API.
- **Ejecutar un programa con `spark-submit`:** guardar el código en un archivo `.py`, ejecutarlo desde el contenedor `spark-master` y revisar sus resultados o errores.
- **Documentar decisiones técnicas:** incorporar comentarios en el código para explicar qué hace cada etapa, por qué se utiliza una operación y cómo se interpretan o validan los resultados.

Estos conocimientos se trabajaron especialmente en la **Guía Práctica 2 (semana 10)**, incluidos sus ejercicios de creación, ejecución y documentación de programas PySpark. En esta guía se utilizarán de manera integrada para construir y validar un pipeline; no se volverán a desarrollar desde cero.

---

## Antes de comenzar

Se mantienen las responsabilidades de los componentes utilizadas durante el curso:

```text
HDFS  → namenode
Spark → spark-master
```

Por tanto:

- las operaciones de administración y verificación de HDFS se realizan desde `namenode`;
- los programas PySpark se desarrollan y ejecutan desde `spark-master`;
- Spark puede leer y escribir datos directamente en HDFS mediante una URI como:

```text
hdfs://namenode:8020/...
```

La guía utilizará **PySpark** como lenguaje de programación y los programas deberán poder ejecutarse mediante `spark-submit`.

---

# Nivel 1 — Procesamiento y persistencia

## Ejercicio 1 — Construir una cadena de transformaciones

Hasta ahora se han realizado diferentes transformaciones sobre DataFrames. En este ejercicio deberá combinarlas para construir un flujo de procesamiento.

Utilice el conjunto de datos de ventas disponible en HDFS:

```text
hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv
```

Recuerde su estructura:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

Desde `spark-master`, cree un nuevo programa:

```bash
mkdir -p /tmp/curso_spark
cd /tmp/curso_spark
vi guia3_ejercicio1.py
```

Su programa deberá:

1. iniciar una `SparkSession`;
2. leer el archivo desde HDFS;
3. asignar correctamente los nombres y tipos de las columnas;
4. seleccionar únicamente las ventas cuyo `monto` sea superior a **$250.000**;
5. seleccionar las columnas `fecha`, `ciudad`, `categoria` y `monto`;
6. ordenar los registros según `monto`, de mayor a menor;
7. mostrar los primeros 20 resultados.

Ejecute el programa utilizando:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio1.py
```

### Analice

No queremos que el estudiante vea estas instrucciones como operaciones independientes. Represente conceptualmente lo que acaba de construir:

```text
HDFS
  ↓
lectura
  ↓
DataFrame
  ↓
filtro
  ↓
selección
  ↓
ordenamiento
  ↓
resultado
```

Responda:

**a.** ¿Qué diferencia observa entre realizar una transformación aislada y construir una secuencia de transformaciones?

**b.** ¿En qué momento Spark comienza realmente a ejecutar las transformaciones definidas en el programa?

**c.** Identifique cuál de las instrucciones utilizadas corresponde a una **acción** que obliga a Spark a producir un resultado.

### Observe la ejecución

Mientras ejecuta el programa, abra:

```text
http://localhost:8080
```

> **Recuerde:** si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la **IP pública de su instancia**.

Observe la aplicación mientras se encuentra activa e identifique los recursos disponibles en el clúster.

---

## Ejercicio 2 — Crear columnas derivadas y aplicar lógica condicional

En el ejercicio anterior construyó una secuencia de transformaciones sobre un DataFrame. Ahora incorporaremos una operación habitual en los procesos de transformación de datos: **crear nueva información a partir de columnas existentes**.

Continuaremos trabajando con el mismo conjunto de datos almacenado en HDFS:

```text
hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv
```

### 1. Cree un nuevo programa PySpark

Desde `spark-master`:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio2.py
```

El programa debe iniciar una `SparkSession` y cargar nuevamente el dataset desde HDFS utilizando el mismo esquema empleado en el ejercicio anterior.

### 2. Cree una columna derivada

A partir de la columna `monto`, cree una nueva columna denominada:

```text
nivel_venta
```

Utilice `when()` y `otherwise()` para clasificar cada venta según las siguientes reglas:

| Condición | `nivel_venta` |
|---|---|
| `monto < 100000` | `BAJA` |
| `monto >= 100000` y `monto < 300000` | `MEDIA` |
| `monto >= 300000` | `ALTA` |

Para ello necesitará importar las funciones correspondientes:

```python
from pyspark.sql.functions import when, col
```

La estructura de la transformación será similar a:

```python
df_transformado = df.withColumn(
    "nivel_venta",
    when(..., "BAJA")
    .when(..., "MEDIA")
    .otherwise("ALTA")
)
```

Complete las condiciones que faltan.

### 3. Compruebe la transformación

Muestre las siguientes columnas:

```text
id_venta
ciudad
categoria
monto
nivel_venta
```

y compruebe que las categorías asignadas sean coherentes con el valor de `monto`.

Posteriormente agrupe los datos por `nivel_venta` y determine:

- cantidad de ventas;
- monto promedio;
- monto mínimo;
- monto máximo.

Ordene el resultado según el monto promedio, de mayor a menor.

### 4. Ejecute el programa

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio2.py
```

Observe que ahora el flujo de procesamiento es más elaborado:

```text
HDFS
  │
  ▼
DataFrame original
  │
  ▼
withColumn()
  │
  ▼
nivel_venta
  │
  ▼
groupBy()
  │
  ▼
agg()
  │
  ▼
orderBy()
  │
  ▼
resultado
```

### 5. Analice

Responda dentro del código mediante comentarios:

**a.** ¿La columna `nivel_venta` existía originalmente en el archivo almacenado en HDFS?

**b.** ¿Qué función cumple `withColumn()` en este procesamiento?

**c.** ¿Por qué `nivel_venta` puede considerarse una **variable derivada**?

**d.** ¿Qué ventaja tiene incorporar una clasificación de este tipo durante el procesamiento en Spark en lugar de modificar manualmente el archivo de origen?

### 6. Prepare el siguiente paso

Hasta este momento, el resultado transformado existe como un DataFrame durante la ejecución de la aplicación:

```text
HDFS
  ↓
Spark
  ↓
DataFrame original
  ↓
transformaciones
  ↓
DataFrame transformado
  ↓
¿?
```

Cuando la aplicación termina, **no hemos almacenado todavía ese nuevo DataFrame como un nuevo conjunto de datos en HDFS**.

---

## Ejercicio 3 — Persistir resultados de Spark en HDFS

En los ejercicios anteriores, Spark leyó información almacenada en HDFS y construyó nuevos DataFrames mediante diferentes transformaciones. Sin embargo, esos resultados solo existían durante la ejecución de la aplicación.

Ahora realizaremos el proceso inverso: **Spark escribirá el resultado de su procesamiento en HDFS**.

El flujo que construiremos será:

```text
HDFS
  │
  ▼
datos originales
  │
  ▼
Spark
  │
  ▼
transformación
  │
  ▼
DataFrame resultado
  │
  ▼
write()
  │
  ▼
HDFS
```

### 1. Cree el programa PySpark

Desde `spark-master`:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio3.py
```

Utilice como punto de partida el programa desarrollado en el ejercicio anterior. El programa deberá:

1. iniciar una `SparkSession`;
2. leer `ventas_hive.csv` desde HDFS;
3. construir la columna `nivel_venta`;
4. generar un DataFrame con las columnas:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
nivel_venta
```

Esta vez, en lugar de limitarse a mostrar el resultado mediante `show()`, deberá **persistir el DataFrame transformado en HDFS**.

### 2. Defina el directorio de salida

Utilizaremos la siguiente ubicación:

```text
hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_csv
```

Incorpore al programa:

```python
ruta_salida = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_csv"

df_transformado.write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv(ruta_salida)
```

Observe que utilizamos:

```python
.mode("overwrite")
```

Esto permite volver a ejecutar el ejercicio reemplazando el resultado generado anteriormente.

> **Importante:** utilice `overwrite` solamente sobre el directorio de trabajo definido para este ejercicio. No lo aplique sobre directorios que contengan otros datos del curso.

### 3. Ejecute el programa

Desde `spark-master`:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio3.py
```

Hasta aquí, todas las operaciones corresponden a **Spark**, por lo que se realizan desde `spark-master`.

Ahora debemos comprobar qué escribió Spark en HDFS.

### 4. Verifique el resultado desde `namenode`

Salga de `spark-master` si todavía se encuentra dentro del contenedor y acceda a:

```bash
sudo docker exec -it namenode bash
```

Recuerde nuestra separación de responsabilidades:

```text
Spark → spark-master
HDFS  → namenode
```

Desde `namenode`, compruebe la existencia del directorio generado:

```bash
hdfs dfs -ls /curso/spark/guia3/
```

Luego inspeccione su contenido:

```bash
hdfs dfs -ls /curso/spark/guia3/ventas_clasificadas_csv/
```

No espere necesariamente encontrar:

```text
ventas_clasificadas.csv
```

En cambio, debería observar una estructura semejante a:

```text
/curso/spark/guia3/ventas_clasificadas_csv/
    ├── part-00000-....csv
    ├── part-00001-....csv
    ├── ...
    └── _SUCCESS
```

La cantidad exacta de archivos `part-*` puede variar según las **particiones utilizadas durante el procesamiento**.

### 5. Inspeccione los datos persistidos

Seleccione uno de los archivos `part-*` que obtuvo en su ejecución y examine sus primeras filas mediante HDFS.

Por ejemplo:

```bash
hdfs dfs -cat /curso/spark/guia3/ventas_clasificadas_csv/part-* | head
```

Compruebe que el resultado incluya la nueva columna:

```text
nivel_venta
```

Observe la diferencia:

```text
ANTES

HDFS
└── ventas_hive.csv
        │
        ▼
      Spark
        │
        ▼
 nivel_venta
        │
        ▼
     pantalla


AHORA

HDFS
└── ventas_hive.csv
        │
        ▼
      Spark
        │
        ▼
 nivel_venta
        │
        ▼
      write()
        │
        ▼
HDFS
└── ventas_clasificadas_csv/
       ├── part-...
       └── _SUCCESS
```

### 6. Analice

Responda mediante comentarios en su programa:

**a.** ¿Por qué Spark creó un **directorio** de salida en lugar de generar simplemente un archivo CSV?

**b.** ¿Qué relación existe entre los archivos `part-*` y el procesamiento distribuido realizado por Spark?

**c.** ¿Qué indica la presencia del archivo `_SUCCESS`?

**d.** ¿Cuál es la diferencia entre ejecutar `show()` sobre un DataFrame y utilizar `write()`?

**e.** Si volviera a ejecutar el programa sin utilizar `.mode("overwrite")`, ¿qué problema podría encontrar?

### 7. Concepto clave

Con este ejercicio hemos completado por primera vez un ciclo de procesamiento con **entrada y salida persistente**:

```text
             APACHE SPARK
                  │
       ┌──────────┴──────────┐
       │                     │
       ▼                     ▼
    LECTURA               ESCRITURA
       │                     │
       ▼                     ▼
     HDFS                   HDFS
datos originales      datos procesados
```

---

## Ejercicio 4 — Persistir datos en formato Parquet

En el ejercicio anterior almacenó el DataFrame transformado en HDFS utilizando **CSV**. Ahora persistiremos los mismos datos utilizando **Apache Parquet**, un formato especialmente apropiado para procesamiento analítico.

A diferencia de CSV, Parquet es un formato **columnar** y conserva información sobre el **esquema de los datos**.

El objetivo será construir:

```text
                    Spark
                      │
              DataFrame procesado
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
           CSV                Parquet
            │                   │
            └─────────┬─────────┘
                      ▼
                     HDFS
```

### 1. Cree el programa PySpark

Desde `spark-master`:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio4.py
```

Puede utilizar como base el programa desarrollado en el ejercicio anterior.

El programa deberá:

1. iniciar una `SparkSession`;
2. leer `ventas_hive.csv` desde HDFS;
3. construir nuevamente la columna `nivel_venta`;
4. conservar las columnas:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
nivel_venta
```

Esta vez almacenaremos el DataFrame en formato Parquet.

### 2. Escriba el DataFrame como Parquet

Defina una nueva ruta:

```text
hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_parquet
```

Agregue al programa:

```python
ruta_parquet = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_parquet"

df_transformado.write \
    .mode("overwrite") \
    .parquet(ruta_parquet)
```

Observe una primera diferencia respecto del ejercicio anterior.

Para CSV utilizamos:

```python
.option("header", "true")
```

Para Parquet no necesitamos definir un encabezado de esa manera, ya que el formato conserva información estructural sobre las columnas.

### 3. Ejecute el programa

Desde `spark-master`:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio4.py
```

Si la ejecución finaliza correctamente, Spark habrá escrito un nuevo conjunto de datos en HDFS.

### 4. Examine el resultado desde `namenode`

Acceda al contenedor responsable de HDFS:

```bash
sudo docker exec -it namenode bash
```

Compruebe el nuevo directorio:

```bash
hdfs dfs -ls /curso/spark/guia3/ventas_clasificadas_parquet/
```

Debería encontrar nuevamente una estructura semejante a:

```text
ventas_clasificadas_parquet/
    ├── part-00000-....parquet
    ├── part-00001-....parquet
    ├── ...
    └── _SUCCESS
```

Tenemos, por tanto, la misma idea de procesamiento distribuido:

```text
DataFrame
   │
   │ distribuido en particiones
   ▼
write.parquet()
   │
   ▼
HDFS
   │
   ├── part-00000...
   ├── part-00001...
   └── _SUCCESS
```

### 5. ¿Podemos utilizar `cat` para interpretar Parquet?

En el ejercicio anterior pudimos realizar:

```bash
hdfs dfs -cat /curso/spark/guia3/ventas_clasificadas_csv/part-* | head
```

No utilice ese procedimiento para intentar interpretar el contenido de Parquet.

CSV almacena información como **texto legible**. Parquet utiliza una representación binaria estructurada, por lo que observar sus bytes mediante `cat` no constituye una forma adecuada de inspeccionar los registros.

Esto introduce una diferencia importante:

| CSV | Parquet |
|---|---|
| Formato textual | Formato binario |
| Orientado a filas | Orientado a columnas |
| Fácil de inspeccionar como texto | Requiere una herramienta capaz de interpretar Parquet |
| El esquema debe definirse o inferirse al leer | Conserva información de esquema |
| Muy utilizado para intercambio | Especialmente útil para procesamiento analítico |

### 6. Compruebe el esquema almacenado

Regrese a `spark-master` y abra PySpark:

```bash
sudo docker exec -it spark-master bash

export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

cd /spark/bin
./pyspark --master spark://spark-master:7077
```

Lea directamente el resultado Parquet:

```python
ruta_parquet = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_parquet"

df_parquet = spark.read.parquet(ruta_parquet)
```

Examine su esquema:

```python
df_parquet.printSchema()
```

y posteriormente:

```python
df_parquet.show(10, False)
```

Compruebe que Spark recupera tanto los datos como sus tipos.

### 7. Compare con el CSV

Lea ahora el resultado CSV generado en el ejercicio anterior:

```python
ruta_csv = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_csv"

df_csv = spark.read \
    .option("header", "true") \
    .csv(ruta_csv)
```

Ejecute:

```python
df_csv.printSchema()
```

Compare este resultado con:

```python
df_parquet.printSchema()
```

Preste especial atención a `id_venta` y `monto`.

El objetivo no es memorizar una característica de Parquet, sino **observar experimentalmente una diferencia entre ambos formatos**.

### 8. Analice

Responda mediante comentarios en su programa:

**a.** ¿Qué diferencia observa entre el esquema recuperado desde CSV y el recuperado desde Parquet?

**b.** ¿Por qué Spark puede recuperar directamente los tipos de las columnas almacenadas en Parquet?

**c.** ¿Qué ventaja puede representar un formato columnar cuando un análisis necesita trabajar solamente con algunas columnas de un conjunto de datos de gran tamaño?

**d.** ¿Por qué no resulta apropiado utilizar `hdfs dfs -cat` para interpretar directamente los registros almacenados en Parquet?

**e.** ¿Significa esto que Parquet siempre debe reemplazar a CSV? Explique brevemente considerando que ambos formatos pueden cumplir propósitos diferentes.

### 9. Concepto clave

Ahora nuestro pipeline puede producir diferentes representaciones persistentes del mismo resultado:

```text
                    HDFS
                     │
                     ▼
               datos originales
                     │
                     ▼
                   Spark
                     │
             transformaciones
                     │
                     ▼
             DataFrame resultado
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
         CSV                 PARQUET
          │                     │
          └──────────┬──────────┘
                     ▼
                    HDFS
```

---

## Ejercicio 5 — Recuperar y validar datos persistidos en HDFS

En los ejercicios anteriores utilizó Spark para transformar un conjunto de datos y persistir el resultado en HDFS utilizando dos formatos diferentes: **CSV y Parquet**.

Ahora cerraremos el Nivel 1 comprobando que los datos persistidos pueden convertirse nuevamente en la **entrada de un proceso Spark**.

El ciclo completo será:

```text
HDFS
  ↓
datos originales
  ↓
Spark
  ↓
transformación
  ↓
persistencia
  ↓
HDFS
  ↓
recuperación
  ↓
Spark
  ↓
validación
```

El objetivo no será volver a realizar el procesamiento original, sino verificar que los productos generados anteriormente pueden **recuperarse, validarse y reutilizarse**.

### 1. Cree un nuevo programa PySpark

Desde `spark-master`:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio5.py
```

Inicie una `SparkSession` y defina las dos rutas generadas anteriormente:

```python
ruta_csv = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_csv"

ruta_parquet = "hdfs://namenode:8020/curso/spark/guia3/ventas_clasificadas_parquet"
```

### 2. Recupere el resultado almacenado como CSV

Lea el directorio CSV desde HDFS:

```python
df_csv = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(ruta_csv)
```

En este ejercicio incorporamos:

```python
.option("inferSchema", "true")
```

porque queremos que Spark intente determinar los tipos de las columnas almacenadas en CSV.

Compruebe:

```python
df_csv.printSchema()
df_csv.show(5, False)
```

y determine la cantidad de registros:

```python
cantidad_csv = df_csv.count()

print("Registros CSV:", cantidad_csv)
```

### 3. Recupere el resultado almacenado como Parquet

Lea ahora el segundo resultado:

```python
df_parquet = spark.read.parquet(ruta_parquet)
```

Compruebe nuevamente:

```python
df_parquet.printSchema()
df_parquet.show(5, False)

cantidad_parquet = df_parquet.count()

print("Registros Parquet:", cantidad_parquet)
```

Observe que para recuperar Parquet no fue necesario solicitar:

```text
header
inferSchema
```

La información necesaria para interpretar su estructura se encuentra incorporada en el propio formato.

### 4. Valide los resultados

Una validación básica consiste en comprobar que ambos conjuntos contienen la misma cantidad de registros.

Agregue:

```python
if cantidad_csv == cantidad_parquet:
    print("VALIDACIÓN: ambos conjuntos poseen la misma cantidad de registros.")
else:
    print("VALIDACIÓN: las cantidades de registros son diferentes.")
```

Sin embargo, tener la misma cantidad de filas **no demuestra por sí solo que los datos sean iguales**.

Realice una segunda comprobación.

Agrupe cada DataFrame según:

```text
nivel_venta
```

y obtenga la cantidad de registros de cada categoría.

Por ejemplo:

```python
df_csv.groupBy("nivel_venta").count().orderBy("nivel_venta").show()

df_parquet.groupBy("nivel_venta").count().orderBy("nivel_venta").show()
```

Compare los resultados obtenidos para:

```text
ALTA
BAJA
MEDIA
```

Las cantidades deberían coincidir entre ambas representaciones.

### 5. Compare el espacio utilizado en HDFS

Hasta ahora hemos comparado los datos desde Spark. Realizaremos ahora una comprobación directamente sobre HDFS.

Una vez finalizado el programa, acceda a `namenode`:

```bash
sudo docker exec -it namenode bash
```

Recuerde:

```text
Spark → spark-master
HDFS  → namenode
```

Consulte el espacio ocupado por la salida CSV:

```bash
hdfs dfs -du -h /curso/spark/guia3/ventas_clasificadas_csv
```

Realice la misma operación para Parquet:

```bash
hdfs dfs -du -h /curso/spark/guia3/ventas_clasificadas_parquet
```

Para observar el tamaño total de cada directorio puede utilizar:

```bash
hdfs dfs -du -s -h /curso/spark/guia3/ventas_clasificadas_csv
```

y:

```bash
hdfs dfs -du -s -h /curso/spark/guia3/ventas_clasificadas_parquet
```

Registre los valores obtenidos.

> No concluya que un formato siempre ocupará una cantidad fija o una determinada proporción menos que otro. Compare **los resultados obtenidos en este ejercicio** y explique lo observado.

### 6. Construya una pequeña validación analítica

Regrese a su programa PySpark.

Sobre ambos DataFrames calcule el **monto promedio por `nivel_venta`**.

Puede utilizar:

```python
from pyspark.sql.functions import avg
```

y construir una operación de este tipo:

```python
df_csv.groupBy("nivel_venta") \
    .agg(avg("monto").alias("monto_promedio")) \
    .orderBy("nivel_venta") \
    .show()
```

Realice la operación equivalente sobre `df_parquet`.

Compruebe si ambos resultados coinciden.

Con esto tendremos tres niveles de validación:

```text
CSV                     PARQUET
 │                         │
 └───────────┬─────────────┘
             ▼
        VALIDACIÓN
             │
     ┌───────┼────────┐
     ▼       ▼        ▼
 cantidad  grupos   promedio
 filas     categorías monto
```

### 7. Analice

Responda mediante comentarios dentro de su programa:

**a.** ¿Por qué fue necesario utilizar `inferSchema` al recuperar el CSV y no al recuperar el archivo Parquet?

**b.** ¿Es suficiente comprobar que dos DataFrames poseen la misma cantidad de registros para afirmar que contienen exactamente la misma información? Fundamente.

**c.** ¿Qué diferencias observó en el espacio utilizado en HDFS por las representaciones CSV y Parquet?

**d.** Considerando lo experimentado en los ejercicios 3, 4 y 5, ¿qué formato elegiría para almacenar resultados que posteriormente volverán a ser procesados analíticamente por Spark? Justifique su decisión.

**e.** ¿Qué ventaja representa que el resultado de un procesamiento Spark quede persistido en HDFS en lugar de existir solamente durante la ejecución de la aplicación?

---

# Cierre del Nivel 1 — Procesamiento y persistencia

Con este ejercicio hemos completado un ciclo que no habíamos desarrollado íntegramente en las guías anteriores:

```text
                 HDFS
                  │
                  ▼
             datos fuente
                  │
                  ▼
                Spark
                  │
                  ▼
           transformaciones
                  │
                  ▼
              DataFrame
                  │
         ┌────────┴────────┐
         ▼                 ▼
        CSV             Parquet
         │                 │
         └────────┬────────┘
                  ▼
                 HDFS
                  │
                  ▼
            recuperación
                  │
                  ▼
                Spark
                  │
                  ▼
             validación
```

Los cinco ejercicios del **Nivel 1** quedan así articulados:

| Ejercicio | Competencia desarrollada |
|---:|---|
| **1** | Encadenar transformaciones sobre un DataFrame |
| **2** | Crear información derivada mediante lógica condicional |
| **3** | Persistir resultados Spark en HDFS utilizando CSV |
| **4** | Persistir resultados en Parquet y comprender sus características |
| **5** | Recuperar, comparar y validar productos persistidos |

Hasta aquí hemos trabajado fundamentalmente con **un DataFrame**. El siguiente salto de complejidad será distinto.

# Nivel 2 — Integración y optimización

En el Nivel 1 trabajamos fundamentalmente con un único conjunto de datos: lo recuperamos desde HDFS, realizamos transformaciones y persistimos los resultados nuevamente en HDFS.

En este segundo nivel cambiaremos el problema. Un sistema de información normalmente no obtiene toda la información necesaria desde una única fuente. Por ello comenzaremos a trabajar con **dos DataFrames relacionados**.

La progresión será:

```text
             HDFS
              │
       ┌──────┴──────┐
       ▼             ▼
   Dataset A      Dataset B
       │             │
       ▼             ▼
 DataFrame A     DataFrame B
       │             │
       └──────┬──────┘
              ▼
             JOIN
              │
              ▼
      DataFrame integrado
              │
              ▼
        procesamiento
```

Durante los ejercicios 6–10 trabajaremos con integración mediante `join`, particionamiento y reutilización de resultados mediante `cache()` y `persist()`.

---

## Ejercicio 6 — Trabajar con dos fuentes de datos relacionadas

Hasta ahora nuestro conjunto de datos de ventas contiene:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

La columna `ciudad` permite identificar dónde ocurrió cada venta, pero no contiene información adicional sobre esa ubicación.

Suponga que ahora necesitamos responder preguntas como:

> ¿Cuánto se vende en cada región?

El dataset de ventas, por sí solo, **no contiene la variable `region`**.

Necesitaremos incorporar una segunda fuente.

### 1. Cree un dataset complementario

Trabajaremos con el siguiente archivo:

```text
ciudades.csv
```

Su contenido será:

```csv
ciudad,region,zona
Santiago,Metropolitana,Centro
Valparaiso,Valparaiso,Centro
Concepcion,Biobio,Sur
La Serena,Coquimbo,Norte
Puerto Montt,Los Lagos,Sur
Temuco,Araucania,Sur
Antofagasta,Antofagasta,Norte
```

Este dataset cumple una función diferente al de ventas:

```text
ventas_hive.csv                 ciudades.csv

id_venta                       ciudad
fecha                          region
cliente                        zona
ciudad ─────────────────────── ciudad
categoria
monto
```

La columna común es:

```text
ciudad
```

y será la **clave de relación** entre ambos conjuntos.

> En los ejercicios siguientes incorporaremos deliberadamente situaciones en las que no todos los registros encuentren correspondencia. Esto nos permitirá comprender las diferencias entre distintos tipos de `join`.

### 2. Cree el archivo

Desde su máquina anfitriona cree el archivo:

```bash
vi ciudades.csv
```

Incorpore:

```csv
ciudad,region,zona
Santiago,Metropolitana,Centro
Valparaiso,Valparaiso,Centro
Concepcion,Biobio,Sur
La Serena,Coquimbo,Norte
Puerto Montt,Los Lagos,Sur
Temuco,Araucania,Sur
Antofagasta,Antofagasta,Norte
```

Guarde el archivo.

Nuestro objetivo será llevarlo a:

```text
Equipo local
     │
     ▼
ciudades.csv
     │
     ▼
 namenode
     │
     ▼
   HDFS
```

### 3. Copie el archivo al contenedor `namenode`

Desde la máquina anfitriona:

```bash
sudo docker cp ciudades.csv namenode:/tmp/ciudades.csv
```

Compruebe que el archivo se encuentra disponible:

```bash
sudo docker exec -it namenode bash
```

Dentro de `namenode`:

```bash
ls -lh /tmp/ciudades.csv
```

Recuerde nuestra separación de responsabilidades:

```text
HDFS  → namenode
Spark → spark-master
```

Por ello, la incorporación del archivo a HDFS se realizará desde `namenode`.

### 4. Almacene el segundo dataset en HDFS

Cree un directorio para las fuentes que utilizaremos durante este nivel:

```bash
hdfs dfs -mkdir -p /curso/spark/guia3/fuentes
```

Copie el archivo:

```bash
hdfs dfs -put /tmp/ciudades.csv /curso/spark/guia3/fuentes/
```

Compruebe:

```bash
hdfs dfs -ls /curso/spark/guia3/fuentes/
```

También puede examinarlo:

```bash
hdfs dfs -cat /curso/spark/guia3/fuentes/ciudades.csv
```

Ahora tenemos dos fuentes disponibles en HDFS:

```text
HDFS
 │
 ├── /curso/hive/datos_ventas/ventas_hive.csv
 │
 └── /curso/spark/guia3/fuentes/ciudades.csv
```

### 5. Lea ambos datasets utilizando Spark

Salga de `namenode` y acceda a:

```bash
sudo docker exec -it spark-master bash
```

Cree:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio6.py
```

El programa deberá iniciar una `SparkSession` y cargar **ambas fuentes desde HDFS**.

Para el dataset de ciudades puede utilizar:

```python
ruta_ciudades = "hdfs://namenode:8020/curso/spark/guia3/fuentes/ciudades.csv"

df_ciudades = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(ruta_ciudades)
```

Para `ventas_hive.csv`, utilice el mismo procedimiento de lectura y esquema empleado en los ejercicios anteriores.

El resultado conceptual será:

```text
                    Spark
                      │
             ┌────────┴────────┐
             ▼                 ▼
        df_ventas        df_ciudades
             │                 │
       100.000 ventas      ciudades
             │                 │
             └──── ciudad ─────┘
```

Todavía **no realice el `join`**.

El objetivo de este ejercicio es comprender primero las dos fuentes que posteriormente integraremos.

### 6. Inspeccione los DataFrames

Sobre `df_ventas`, ejecute:

```python
df_ventas.printSchema()
df_ventas.show(5, False)
```

Sobre `df_ciudades`:

```python
df_ciudades.printSchema()
df_ciudades.show(10, False)
```

Determine además la cantidad de registros:

```python
print("Cantidad de ventas:", df_ventas.count())
print("Cantidad de ciudades:", df_ciudades.count())
```

Ahora identifique los valores distintos de `ciudad` existentes en el DataFrame de ventas:

```python
df_ventas.select("ciudad").distinct().orderBy("ciudad").show()
```

y compárelos con:

```python
df_ciudades.select("ciudad").distinct().orderBy("ciudad").show()
```

No se limite a comprobar que ambos DataFrames poseen una columna llamada `ciudad`. Observe también **qué valores contiene esa columna en cada fuente**.

### 7. Ejecute el programa

Desde `spark-master`:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio6.py
```

Compruebe que ambas fuentes pueden ser procesadas correctamente.

### 8. Analice

Responda mediante comentarios dentro de su programa:

**a.** ¿Por qué el dataset `ventas_hive.csv` no permite por sí solo determinar las ventas correspondientes a cada región?

**b.** ¿Qué información aporta `ciudades.csv` que no estaba disponible en el DataFrame de ventas?

**c.** ¿Qué columna permite establecer una relación entre ambos DataFrames?

**d.** ¿Es suficiente que dos DataFrames posean una columna con el mismo nombre para asegurar que todos sus registros podrán relacionarse correctamente? Explique considerando los valores contenidos en esa columna.

**e.** ¿Por qué puede resultar preferible mantener información como `region` y `zona` en una fuente separada en lugar de repetirla en cada una de las 100.000 ventas?

### 9. Concepto clave

Por primera vez en nuestras guías tenemos **dos DataFrames independientes que describen aspectos relacionados de un mismo problema**:

```text
df_ventas
────────────────
id_venta
fecha
cliente
ciudad ───────────────┐
categoria             │
monto                 │
                      │
                      │
df_ciudades           │
────────────────      │
ciudad ◄──────────────┘
region
zona
```

Spark todavía los considera objetos independientes.

Nuestro siguiente problema será construir:

```text
id_venta | fecha | cliente | ciudad | categoria | monto | region | zona
```

Para obtenerlo necesitaremos realizar una operación de **integración entre DataFrames**.

---

## Ejercicio 7 — Integrar DataFrames mediante `inner join`

En el ejercicio anterior cargó dos fuentes independientes desde HDFS. Ahora utilizaremos la columna `ciudad` para construir un nuevo DataFrame que combine información proveniente de ambas fuentes.

El objetivo será obtener:

```text
id_venta | fecha | cliente | ciudad | categoria | monto | region | zona
```

### 1. ¿Qué hace un `inner join`?

Un `inner join` conserva solamente aquellos registros para los cuales existe una correspondencia entre ambos DataFrames según la condición establecida.

```text
DataFrame A              DataFrame B
     │                         │
     └────── ciudad ───────────┘
               │
               ▼
          INNER JOIN
               │
               ▼
     solo coincidencias
```

### 2. Cree el programa

Desde `spark-master`:

```bash
cd /tmp/curso_spark
vi guia3_ejercicio7.py
```

Utilice como punto de partida el ejercicio anterior. El programa deberá cargar ambas fuentes, comprobar sus cantidades, realizar un `inner join` y validar el resultado.

### 3. Realice el `inner join`

```python
df_integrado = df_ventas.join(
    df_ciudades,
    on="ciudad",
    how="inner"
)
```

Examine:

```python
df_integrado.printSchema()
df_integrado.show(20, False)
```

### 4. Compare las cantidades de registros

```python
cantidad_ventas = df_ventas.count()
cantidad_integradas = df_integrado.count()

print("Ventas originales:", cantidad_ventas)
print("Ventas después del inner join:", cantidad_integradas)

diferencia = cantidad_ventas - cantidad_integradas
print("Ventas sin correspondencia:", diferencia)
```

No dé por supuesto que el resultado tendrá necesariamente las mismas 100.000 filas.

### 5. Identifique qué ciudades participaron en el resultado

```python
df_integrado.select(
    "ciudad",
    "region",
    "zona"
).distinct().orderBy("ciudad").show(50, False)

df_ventas.select("ciudad").distinct().orderBy("ciudad").show(50, False)
```

### 6. Utilice la información incorporada

Responda:

> **¿Cuál es el monto total y promedio de ventas por región?**

Importe:

```python
from pyspark.sql.functions import count, sum, avg
```

A partir de `df_integrado`, agrupe por `region` y calcule cantidad de ventas, monto total y monto promedio. Ordene por `monto_total` de mayor a menor.

### 7. Ejecute el programa

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio7.py
```

### 8. Analice

**a.** ¿Qué función cumple `on="ciudad"`?

**b.** ¿Qué registros conserva un `inner join`?

**c.** ¿Por qué es importante comparar la cantidad de registros antes y después de un `join`?

**d.** Si una ciudad existe en `df_ventas` pero no en `df_ciudades`, ¿qué ocurre con sus ventas?

**e.** ¿Por qué ahora podemos calcular ventas por `region`?

### 9. Advertencia sobre los `join`

Un `join` no garantiza automáticamente que la integración sea correcta. Si `df_ciudades` tuviera accidentalmente una ciudad duplicada, una venta podría encontrar más de una correspondencia.

```text
¿La clave existe?
       ↓
¿Los valores coinciden?
       ↓
¿La clave debería ser única?
       ↓
¿Cambió la cantidad de registros?
       ↓
¿El resultado tiene sentido?
```

---

## Ejercicio 8 — Conservar registros mediante `left join` e identificar datos sin correspondencia

Ahora cambiaremos el requerimiento:

> **Necesitamos conservar todas las ventas, incluso cuando una ciudad no tenga información disponible en `df_ciudades`.**

Para resolverlo utilizaremos un **`left join`**.

```text
INNER JOIN                         LEFT JOIN

df_ventas    df_ciudades          df_ventas    df_ciudades
    │             │                   │             │
    └──────┬──────┘                   └──────┬──────┘
           ▼                                 ▼
     coincidencias                   TODAS las ventas
           │                                 │
           ▼                                 ▼
 registros sin                       si no existe
 coincidencia                        correspondencia
 desaparecen                         → valores NULL
```

### 1. Cree el programa

```bash
cd /tmp/curso_spark
vi guia3_ejercicio8.py
```

### 2. Realice nuevamente el `inner join`

```python
df_inner = df_ventas.join(
    df_ciudades,
    on="ciudad",
    how="inner"
)
```

### 3. Realice un `left join`

```python
df_left = df_ventas.join(
    df_ciudades,
    on="ciudad",
    how="left"
)
```

Examine:

```python
df_left.printSchema()
df_left.show(20, False)
```

### 4. Compare las cantidades

```python
cantidad_original = df_ventas.count()
cantidad_inner = df_inner.count()
cantidad_left = df_left.count()

print("Ventas originales:", cantidad_original)
print("Resultado INNER JOIN:", cantidad_inner)
print("Resultado LEFT JOIN:", cantidad_left)
```

Si `df_ciudades` posee una única fila para cada ciudad, el `left join` debería conservar la cantidad de registros del DataFrame de ventas.

### 5. ¿Cómo representa Spark una correspondencia inexistente?

Cuando una venta no encuentra su ciudad, el registro permanece y las columnas provenientes del DataFrame derecho quedan en `NULL`.

### 6. Identifique registros sin correspondencia

```python
from pyspark.sql.functions import col

df_sin_correspondencia = df_left.filter(
    col("region").isNull()
)

cantidad_sin_correspondencia = df_sin_correspondencia.count()
print("Ventas sin correspondencia:", cantidad_sin_correspondencia)

df_sin_correspondencia.select(
    "id_venta",
    "fecha",
    "ciudad",
    "categoria",
    "monto",
    "region",
    "zona"
).show(20, False)

df_sin_correspondencia \
    .groupBy("ciudad") \
    .count() \
    .orderBy("ciudad") \
    .show(50, False)
```

### 7. Calcule el porcentaje sin correspondencia

```python
porcentaje_sin_correspondencia = (
    cantidad_sin_correspondencia / cantidad_original
) * 100

print(
    "Porcentaje sin correspondencia:",
    porcentaje_sin_correspondencia
)
```

### 8. Compare `inner join` y `left join`

```python
print(
    "Registros excluidos por INNER JOIN:",
    cantidad_original - cantidad_inner
)

print(
    "Registros sin correspondencia detectados mediante LEFT JOIN:",
    cantidad_sin_correspondencia
)
```

### 9. Analice

**a.** ¿Cuál es la principal diferencia entre `inner join` y `left join`?

**b.** ¿Por qué el `left join` permite detectar registros sin correspondencia?

**c.** ¿Qué representan los valores `NULL` de `region` y `zona`?

**d.** Si la prioridad fuera conservar todas las transacciones originales, ¿qué join sería más apropiado?

**e.** ¿Por qué una diferencia en la cantidad de registros debe investigarse?

**f.** ¿Qué problema produciría que `df_ciudades` tuviera dos registros para una misma ciudad?

### 10. Concepto clave

```text
realizar JOIN
     ↓
contar registros
     ↓
buscar NULL
     ↓
identificar claves
sin correspondencia
     ↓
dimensionar el problema
     ↓
validar resultado
```

---

## Ejercicio 9 — Particionamiento de DataFrames con `repartition()` y `coalesce()`

Un DataFrame de Spark distribuye sus registros en particiones que pueden ser procesadas por los ejecutores.

```text
                 DataFrame
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
         P1        P2        P3
```

Experimentaremos con `repartition()` y `coalesce()`.

### 1. Cree el programa

```bash
cd /tmp/curso_spark
vi guia3_ejercicio9.py
```

### 2. Observe las particiones iniciales

```python
particiones_iniciales = df_ventas.rdd.getNumPartitions()
print("Particiones iniciales:", particiones_iniciales)
```

No asuma una cantidad específica: obtenga el valor de su propia ejecución.

### 3. Utilice `repartition()`

```python
df_reparticionado = df_ventas.repartition(4)

print(
    "Particiones después de repartition(4):",
    df_reparticionado.rdd.getNumPartitions()
)
```

`repartition()` redistribuye los registros y puede implicar un **shuffle**.

### 4. Reduzca las particiones mediante `coalesce()`

```python
df_reducido = df_reparticionado.coalesce(2)

print(
    "Particiones después de coalesce(2):",
    df_reducido.rdd.getNumPartitions()
)
```

En términos generales, `coalesce()` se utiliza especialmente para reducir el número de particiones, procurando evitar una redistribución completa cuando es posible.

### 5. Compare ambas operaciones

```text
DataFrame original       → N particiones
repartition(4)           → 4 particiones
coalesce(2)              → 2 particiones
```

No interprete que más particiones sea siempre mejor ni que menos particiones sea siempre mejor.

En nuestra infraestructura disponemos de **un Spark Worker**, pero esto no significa que un DataFrame deba tener una sola partición. Las particiones son **unidades lógicas de trabajo** y no equivalen al número de Workers ni al número de DataNodes.

### 6. Relacione particiones con la escritura en HDFS

```python
ruta_salida = "hdfs://namenode:8020/curso/spark/guia3/ventas_reparticionadas"

df_reparticionado.write \
    .mode("overwrite") \
    .parquet(ruta_salida)
```

### 7. Ejecute el programa

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio9.py
```

### 8. Verifique el resultado en HDFS

```bash
sudo docker exec -it namenode bash
hdfs dfs -ls /curso/spark/guia3/ventas_reparticionadas/
```

Observe los archivos `part-*`.

No confunda una **partición Spark** con un **bloque HDFS**: son conceptos diferentes.

### 9. Experimente con `coalesce()`

```python
df_reducido.write \
    .mode("overwrite") \
    .parquet(
        "hdfs://namenode:8020/curso/spark/guia3/ventas_coalesce"
    )
```

Desde `namenode`:

```bash
hdfs dfs -ls /curso/spark/guia3/ventas_coalesce/
```

Compare la cantidad de archivos `part-*`.

### 10. Analice

**a.** ¿Cuántas particiones tenía originalmente `df_ventas`?

**b.** ¿Qué ocurrió después de `repartition(4)`?

**c.** ¿Qué ocurrió después de `coalesce(2)`?

**d.** ¿Cuál es la principal diferencia conceptual entre ambas operaciones?

**e.** ¿Qué es un shuffle y por qué tiene costo?

**f.** ¿Qué relación observó entre particiones y archivos `part-*`?

**g.** ¿Por qué cuatro particiones no implican cuatro Spark Workers o cuatro DataNodes?

### 11. Concepto clave

```text
¿Qué hace Spark?
      +
¿Cómo se distribuyen los datos?
```

La distribución de los datos forma parte del modelo de procesamiento distribuido.

---

## Ejercicio 10 — Reutilizar DataFrames mediante `cache()` y `persist()`

Ahora analizaremos qué ocurre cuando necesitamos utilizar varias veces el mismo DataFrame procesado.

Spark utiliza **evaluación perezosa (*lazy evaluation*)**. Si reutilizamos reiteradamente un DataFrame derivado, Spark puede necesitar volver a ejecutar las operaciones necesarias para obtenerlo.

Utilizaremos:

```python
cache()
persist()
```

### 1. El problema

```text
fuentes
   ↓
join
   ↓
filter
   ↓
select
   ↓
df_procesado
   │
   ├────────► análisis A
   ├────────► análisis B
   └────────► análisis C
```

> Aquí *persistencia* no significa guardar permanentemente en HDFS. `cache()` y `persist()` permiten conservar temporalmente datos procesados durante una aplicación Spark.

### 2. Cree el programa

```bash
cd /tmp/curso_spark
vi guia3_ejercicio10.py
```

### 3. Construya el DataFrame que será reutilizado

```python
df_integrado = df_ventas.join(
    df_ciudades,
    on="ciudad",
    how="left"
)

from pyspark.sql.functions import col

df_procesado = df_integrado \
    .filter(col("monto") > 100000) \
    .select(
        "id_venta",
        "fecha",
        "cliente",
        "ciudad",
        "categoria",
        "monto",
        "region",
        "zona"
    )
```

### 4. Utilice el mismo DataFrame en varios análisis

Realice tres análisis:

- **A — Ventas por región:** cantidad y monto promedio.
- **B — Ventas por categoría:** cantidad y monto total.
- **C — Ventas por zona:** cantidad y monto promedio.

Puede utilizar:

```python
from pyspark.sql.functions import count, sum, avg
```

### 5. Incorpore `cache()`

```python
df_procesado.cache()

cantidad = df_procesado.count()

print(
    "Registros almacenados para reutilización:",
    cantidad
)
```

`cache()` solicita almacenamiento, pero la evaluación perezosa continúa. `count()` actúa como acción y materializa el procesamiento.

### 6. Ejecute nuevamente los tres análisis

Conceptualmente:

```text
fuentes
   ↓
join
   ↓
filter
   ↓
select
   ↓
df_procesado
   ↓
 cache
   ↓
materialización
   │
   ├────────► análisis A
   ├────────► análisis B
   └────────► análisis C
```

No concluya que `cache()` debe utilizarse sobre todos los DataFrames. Mantener datos disponibles consume recursos.

### 7. Compruebe si el DataFrame está almacenado

```python
print(
    "¿Está almacenado?:",
    df_procesado.is_cached
)
```

### 8. Diferencie `cache()` de `persist()`

```python
from pyspark import StorageLevel

df_procesado.unpersist()

df_procesado.persist(
    StorageLevel.MEMORY_AND_DISK
)

df_procesado.count()
```

`cache()` proporciona un mecanismo conveniente de reutilización. `persist(StorageLevel...)` permite especificar una estrategia de almacenamiento.

### 9. Libere los recursos

```python
df_procesado.unpersist()

print(
    "¿Está almacenado después de unpersist()?:",
    df_procesado.is_cached
)
```

### 10. Ejecute el programa

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  guia3_ejercicio10.py
```

### 11. Analice

**a.** ¿Por qué `df_procesado` es un buen candidato para `cache()` o `persist()`?

**b.** ¿Por qué utilizamos `count()` después de `cache()`?

**c.** ¿Qué relación existe con *lazy evaluation*?

**d.** ¿Cuál es la diferencia entre `cache()`/`persist()` y escribir Parquet en HDFS?

**e.** ¿Por qué no sería recomendable aplicar `cache()` indiscriminadamente?

**f.** ¿Qué función cumple `unpersist()`?

**g.** ¿Qué ventaja ofrece `persist()` respecto de utilizar únicamente `cache()`?

---

# Cierre del Nivel 2 — Integración y optimización

Durante este nivel hemos pasado de trabajar con una única fuente a construir procesos que integran y administran múltiples DataFrames:

| Ejercicio | Competencia desarrollada |
|---:|---|
| **6** | Cargar y analizar dos fuentes relacionadas |
| **7** | Integrar DataFrames mediante `inner join` |
| **8** | Conservar registros mediante `left join` y detectar correspondencias ausentes |
| **9** | Comprender y modificar el particionamiento mediante `repartition()` y `coalesce()` |
| **10** | Reutilizar resultados intermedios mediante `cache()` y `persist()` |

La progresión acumulada permite construir:

```text
                 HDFS
                  │
          ┌───────┴───────┐
          ▼               ▼
       fuente A         fuente B
          │               │
          ▼               ▼
      DataFrame A     DataFrame B
          │               │
          └───────┬───────┘
                  ▼
                 JOIN
                  │
                  ▼
           transformaciones
                  │
                  ▼
            particiones
                  │
                  ▼
          cache / persist
                  │
          ┌───────┼───────┐
          ▼       ▼       ▼
       análisis análisis análisis
```

---

# Nivel 3 — Pipeline avanzado y transición al procesamiento continuo

En los niveles anteriores desarrollamos progresivamente las principales operaciones necesarias para procesar datos con Spark.

En el **Nivel 1** trabajamos con transformación y persistencia:

```text
HDFS
  ↓
Spark
  ↓
DataFrame
  ↓
transformaciones
  ↓
CSV / Parquet
  ↓
HDFS
```

En el **Nivel 2** incorporamos integración y elementos relacionados con la eficiencia del procesamiento:

```text
múltiples fuentes
       ↓
  DataFrames
       ↓
     JOIN
       ↓
transformaciones
       ↓
particionamiento
       ↓
cache / persist
```

En este último nivel integraremos estas capacidades en un **pipeline de datos completo** y utilizaremos ese pipeline para comprender la diferencia entre el procesamiento por lotes y un escenario en el que los datos se generan continuamente.

La progresión será:

```text
Ejercicio 11
múltiples fuentes
       ↓
Ejercicio 12
integración + transformación + agregación
       ↓
Ejercicio 13
persistencia del producto analítico
       ↓
Ejercicio 14
ejecución y validación del pipeline completo
       ↓
Ejercicio 15
¿qué ocurre si los datos llegan continuamente?
       ↓
Apache Kafka
```

---

# Ejercicio 11 — Construir la entrada de un pipeline con múltiples fuentes desde HDFS

Hasta ahora hemos utilizado diferentes operaciones de Spark de manera relativamente independiente. A partir de este ejercicio cambiaremos nuestra perspectiva.

Ya no pensaremos solamente:

> ¿Cómo realizo un `join`?

o:

> ¿Cómo filtro un DataFrame?

Pensaremos en un problema más amplio:

> **¿Cómo construimos un proceso reproducible que reciba datos desde diferentes fuentes, los prepare y los deje disponibles para las siguientes etapas de procesamiento?**

Este proceso será nuestro primer **pipeline de datos**.

## 1. ¿Qué entenderemos por pipeline?

En esta guía utilizaremos el término **pipeline de datos** para representar una secuencia organizada de etapas mediante las cuales los datos son obtenidos, procesados y finalmente convertidos en un producto útil.

```text
FUENTES
   ↓
LECTURA
   ↓
VALIDACIÓN
   ↓
INTEGRACIÓN
   ↓
TRANSFORMACIÓN
   ↓
AGREGACIÓN
   ↓
PERSISTENCIA
   ↓
RESULTADO
```

En nuestro caso construiremos progresivamente:

```text
HDFS
 │
 ├── ventas_hive.csv
 │
 └── ciudades.csv
          │
          ▼
        Spark
          │
    ┌─────┴─────┐
    ▼           ▼
df_ventas   df_ciudades
    │           │
    └─────┬─────┘
          ▼
      integración
          ↓
    transformación
          ↓
      agregación
          ↓
        Parquet
          ↓
         HDFS
```

En este ejercicio construiremos y validaremos específicamente la **entrada del pipeline**.

## 2. Verifique las fuentes antes de procesarlas

Recuerde nuestra separación de responsabilidades:

```text
HDFS  → namenode
Spark → spark-master
```

Ingrese a:

```bash
sudo docker exec -it namenode bash
```

Compruebe la fuente principal:

```bash
hdfs dfs -ls /curso/hive/datos_ventas/
```

Debería encontrar `ventas_hive.csv`.

Compruebe también la fuente complementaria creada en el Nivel 2:

```bash
hdfs dfs -ls /curso/spark/guia3/fuentes/
```

Debería encontrar `ciudades.csv`.

## 3. Cree el programa del pipeline

Salga de `namenode` y acceda a:

```bash
sudo docker exec -it spark-master bash
```

Cree un nuevo directorio:

```bash
mkdir -p /tmp/curso_spark/nivel3
cd /tmp/curso_spark/nivel3
vi pipeline_ventas.py
```

A diferencia de ejercicios anteriores, **utilizaremos este mismo programa durante los ejercicios 11–14**. El pipeline será construido incrementalmente.

## 4. Inicie la aplicación Spark

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType,
    StructField,
    IntegerType,
    StringType,
    DoubleType
)

spark = SparkSession.builder \
    .appName("PipelineVentasGuia3") \
    .getOrCreate()
```

## 5. Defina explícitamente las fuentes

```python
ruta_ventas = (
    "hdfs://namenode:8020/"
    "curso/hive/datos_ventas/ventas_hive.csv"
)

ruta_ciudades = (
    "hdfs://namenode:8020/"
    "curso/spark/guia3/fuentes/ciudades.csv"
)
```

El programa no depende de archivos almacenados dentro de `spark-master`: las entradas permanecen en HDFS.

## 6. Defina el esquema de las ventas

```python
schema_ventas = StructType([
    StructField("id_venta", IntegerType(), True),
    StructField("fecha", StringType(), True),
    StructField("cliente", StringType(), True),
    StructField("ciudad", StringType(), True),
    StructField("categoria", StringType(), True),
    StructField("monto", DoubleType(), True)
])

df_ventas = spark.read \
    .schema(schema_ventas) \
    .option("header", "false") \
    .csv(ruta_ventas)
```

## 7. Cargue la segunda fuente

```python
df_ciudades = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(ruta_ciudades)
```

Todavía **no realice el `join`**. Primero debemos comprobar que las entradas son válidas.

## 8. Valide las estructuras

```python
print("\n=== ESQUEMA: VENTAS ===")
df_ventas.printSchema()

print("\n=== ESQUEMA: CIUDADES ===")
df_ciudades.printSchema()

print("\n=== MUESTRA: VENTAS ===")
df_ventas.show(5, False)

print("\n=== MUESTRA: CIUDADES ===")
df_ciudades.show(10, False)
```

Antes de integrar necesitamos comprobar:

```text
¿La fuente existe?
       ↓
¿Spark puede leerla?
       ↓
¿Las columnas esperadas existen?
       ↓
¿Los tipos son razonables?
       ↓
¿Los registros parecen coherentes?
```

## 9. Valide la cantidad de registros

```python
cantidad_ventas = df_ventas.count()
cantidad_ciudades = df_ciudades.count()

print("\n=== VALIDACIÓN DE ENTRADAS ===")
print("Cantidad de ventas:", cantidad_ventas)
print("Cantidad de ciudades:", cantidad_ciudades)
```

Para `df_ventas` esperamos recuperar **100000 registros**.

## 10. Valide la clave que permitirá integrar las fuentes

Posteriormente utilizaremos `ciudad` como clave de relación.

```python
print("\n=== CIUDADES PRESENTES EN VENTAS ===")

df_ventas \
    .select("ciudad") \
    .distinct() \
    .orderBy("ciudad") \
    .show(50, False)

print("\n=== CIUDADES PRESENTES EN REFERENCIA ===")

df_ciudades \
    .select("ciudad") \
    .distinct() \
    .orderBy("ciudad") \
    .show(50, False)
```

## 11. Incorpore una validación automática básica

```python
if cantidad_ventas == 0:
    raise ValueError(
        "El pipeline no puede continuar: "
        "el dataset de ventas está vacío."
    )

if cantidad_ciudades == 0:
    raise ValueError(
        "El pipeline no puede continuar: "
        "el dataset de ciudades está vacío."
    )
```

La lógica cambia desde `leer → continuar siempre` hacia `leer → validar → continuar o detener`.

## 12. Finalice temporalmente el programa

```python
print(
    "\nEntradas del pipeline cargadas "
    "y validadas correctamente."
)

spark.stop()
```

En el ejercicio siguiente eliminaremos temporalmente `spark.stop()` de esa posición y continuaremos construyendo nuevas etapas.

## 13. Ejecute el pipeline

Desde `spark-master`:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  pipeline_ventas.py
```

## 14. Observe la aplicación Spark

Mientras la aplicación se encuentre activa, puede observar Spark Master desde:

```text
http://localhost:8080
```

> **Recuerde:** si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la **IP pública de su instancia**.

## 15. Analice

Responda mediante comentarios dentro de `pipeline_ventas.py`:

a. ¿Por qué podemos considerar que este programa comienza a comportarse como un pipeline y no simplemente como una colección de instrucciones aisladas?

b. ¿Por qué las fuentes se almacenan en HDFS en lugar de copiarlas directamente al contenedor `spark-master`?

c. ¿Qué función cumple el esquema explícito utilizado para `ventas_hive.csv`?

d. ¿Por qué es conveniente validar las fuentes antes de realizar el `join`?

e. ¿Qué debería hacer un pipeline si una de sus fuentes obligatorias contiene cero registros?

f. ¿Por qué resulta útil examinar los valores de `ciudad` antes de integrar ambos DataFrames?

## 16. Concepto clave

```text
ENTRADAS             ← Ejercicio 11
   ↓
INTEGRACIÓN          ← próximo
   ↓
TRANSFORMACIÓN       ← próximo
   ↓
AGREGACIÓN           ← próximo
   ↓
PERSISTENCIA
   ↓
VALIDACIÓN FINAL
```

---

# Ejercicio 12 — Integrar, transformar y agregar datos en un único pipeline

En el ejercicio anterior construimos la entrada del pipeline. Ahora ampliaremos el mismo archivo `pipeline_ventas.py`.

El objetivo será encadenar:

```text
INTEGRAR
   ↓
TRANSFORMAR
   ↓
AGREGAR
```

Al finalizar tendremos un **producto analítico en memoria**, preparado para ser persistido.

## 1. Continúe trabajando sobre `pipeline_ventas.py`

```bash
cd /tmp/curso_spark/nivel3
vi pipeline_ventas.py
```

Mantenga el mensaje final del ejercicio anterior, pero elimine por ahora `spark.stop()`. El cierre debe quedar al final del pipeline completo.

## 2. Etapa de integración

Utilice un `left join` para conservar todas las ventas originales:

```python
df_integrado = df_ventas.join(
    df_ciudades,
    on="ciudad",
    how="left"
)
```

## 3. Valide inmediatamente el `join`

```python
cantidad_integrada = df_integrado.count()

print("\n=== VALIDACIÓN DEL JOIN ===")
print("Ventas antes del join:", cantidad_ventas)
print("Registros después del join:", cantidad_integrada)

if cantidad_integrada != cantidad_ventas:
    raise ValueError(
        "Validación fallida: la cantidad de registros "
        "cambió después del left join."
    )
```

Esta regla supone que el dataset de referencia contiene una única fila por ciudad.

## 4. Detecte correspondencias ausentes

Amplíe los imports:

```python
from pyspark.sql.functions import (
    col,
    when,
    count,
    sum,
    avg,
    round
)
```

Determine:

```python
df_sin_region = df_integrado.filter(
    col("region").isNull()
)

cantidad_sin_region = df_sin_region.count()

print(
    "Ventas sin información regional:",
    cantidad_sin_region
)
```

Tenemos dos controles distintos: conservar las ventas y comprobar cuántas pudieron enriquecerse.

## 5. Etapa de transformación

Cree `nivel_venta`:

| Monto | Nivel |
|---:|---|
| `< 100000` | `BAJA` |
| `>= 100000` y `< 300000` | `MEDIA` |
| `>= 300000` | `ALTA` |

```python
df_transformado = df_integrado.withColumn(
    "nivel_venta",
    when(col("monto") < 100000, "BAJA")
    .when(
        (col("monto") >= 100000) &
        (col("monto") < 300000),
        "MEDIA"
    )
    .otherwise("ALTA")
)
```

## 6. Examine el resultado

```python
print("\n=== DATOS TRANSFORMADOS ===")

df_transformado.select(
    "id_venta",
    "ciudad",
    "region",
    "categoria",
    "monto",
    "nivel_venta"
).show(20, False)
```

## 7. Etapa de agregación

Responderemos:

> **¿Cómo se distribuyen las ventas según región y nivel de venta?**

```python
df_resultado = df_transformado \
    .groupBy(
        "region",
        "nivel_venta"
    ) \
    .agg(
        count("*").alias("cantidad_ventas"),
        round(
            sum("monto"),
            2
        ).alias("monto_total"),
        round(
            avg("monto"),
            2
        ).alias("monto_promedio")
    )

df_resultado = df_resultado.orderBy(
    "region",
    "nivel_venta"
)
```

## 8. Observe cómo cambió la unidad de análisis

Antes de la agregación cada fila representa **una venta**. Después de `groupBy("region", "nivel_venta")`, cada fila representa **una combinación región + nivel de venta**.

```text
100.000 registros transaccionales
              │
              ▼
          groupBy()
              │
              ▼
      resultado agregado
```

## 9. Examine el producto analítico

```python
print("\n=== RESULTADO ANALÍTICO ===")

df_resultado.show(100, False)

cantidad_resultados = df_resultado.count()

print(
    "Filas del resultado analítico:",
    cantidad_resultados
)
```

## 10. Identifique las etapas del pipeline

```text
fuente A       fuente B
    │              │
    └──────┬───────┘
           ▼
       LEFT JOIN
           │
           ▼
     df_integrado
           │
           ▼
    withColumn()
           │
           ▼
   nivel_venta
           │
           ▼
   df_transformado
           │
           ▼
      groupBy()
           │
           ▼
         agg()
           │
           ▼
     df_resultado
```

## 11. Ejecute el pipeline ampliado

Mantenga al final:

```python
spark.stop()
```

Ejecute:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  pipeline_ventas.py
```

## 12. ¿Qué ocurre con las ventas sin región?

Al utilizar `left`, las ventas sin correspondencia permanecen con `region = NULL`. Al agrupar, esos registros pueden aparecer bajo un valor nulo.

Esto plantea una decisión:

```text
registro sin región
        │
        ├── eliminarlo
        ├── asignar "DESCONOCIDA"
        ├── corregir fuente
        └── mantener NULL
```

En este ejercicio **no corregiremos automáticamente el problema**. Primero debemos detectarlo y comprenderlo.

## 13. Analice

Responda mediante comentarios:

a. ¿Por qué utilizamos un `left join` en lugar de un `inner join`?

b. ¿Por qué verificamos la cantidad de registros inmediatamente después del `join`?

c. ¿Qué diferencia existe entre comprobar que se conservaron las 100.000 ventas y comprobar que todas poseen información regional?

d. ¿Qué función cumple `nivel_venta`? ¿Es una variable original o derivada?

e. ¿Qué representa una fila de `df_transformado`?

f. ¿Qué representa una fila de `df_resultado`?

g. ¿Por qué `df_resultado` debería tener considerablemente menos filas que las ventas originales?

h. Si aparecen registros con `region = NULL`, ¿por qué no sería apropiado eliminarlos sin analizar primero la causa?

## 14. Concepto clave

Las operaciones `join()`, `withColumn()`, `groupBy()` y `agg()` ahora forman una secuencia:

```text
INTEGRAR
   ↓
TRANSFORMAR
   ↓
AGREGAR
```

Pero `df_resultado` todavía existe solamente durante la ejecución de Spark. El siguiente ejercicio lo convertirá en un producto persistente.

---

# Ejercicio 13 — Persistir el producto analítico del pipeline en HDFS

Ahora incorporaremos la etapa de **persistencia**. El objetivo será transformar `df_resultado` en un producto de datos almacenado en HDFS mediante **Parquet**.

## 1. Continúe sobre el mismo pipeline

```bash
cd /tmp/curso_spark/nivel3
vi pipeline_ventas.py
```

Antes de `spark.stop()` incorporaremos la persistencia.

## 2. Defina la salida

```python
ruta_salida = (
    "hdfs://namenode:8020/"
    "curso/spark/guia3/pipeline/"
    "ventas_por_region_nivel"
)
```

## 3. ¿Por qué Parquet?

Utilizaremos Parquet porque mantiene información del esquema, utiliza almacenamiento columnar, puede ser leído directamente por Spark y resulta apropiado para reutilizar productos analíticos.

## 4. Escriba el resultado en HDFS

```python
print("\n=== PERSISTENCIA DEL RESULTADO ===")

df_resultado.write \
    .mode("overwrite") \
    .parquet(ruta_salida)

print(
    "Resultado almacenado correctamente en:",
    ruta_salida
)
```

## 5. Comprenda `overwrite`

`mode("overwrite")` permite volver a ejecutar el pipeline reemplazando el resultado anterior en esa ruta.

> Utilice `overwrite` únicamente sobre la ruta de trabajo definida para el ejercicio. En un entorno real, la política de reemplazo debe responder a los requisitos del proceso.

## 6. Ejecute nuevamente el pipeline completo

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  pipeline_ventas.py
```

Ahora la aplicación recorre desde la lectura de las fuentes hasta la persistencia del producto analítico.

## 7. Verifique físicamente la salida desde HDFS

Desde `namenode`:

```bash
sudo docker exec -it namenode bash

hdfs dfs -ls /curso/spark/guia3/pipeline/

hdfs dfs -ls \
  /curso/spark/guia3/pipeline/ventas_por_region_nivel/
```

Debería observar archivos `part-....parquet` y `_SUCCESS`.

## 8. Compruebe el tamaño

```bash
hdfs dfs -du -h \
  /curso/spark/guia3/pipeline/ventas_por_region_nivel

hdfs dfs -du -s -h \
  /curso/spark/guia3/pipeline/ventas_por_region_nivel
```

## 9. La escritura no es suficiente: recupere el producto

Vuelva a `spark-master`:

```bash
sudo docker exec -it spark-master bash

export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

cd /spark/bin
./pyspark --master spark://spark-master:7077
```

```python
ruta_resultado = (
    "hdfs://namenode:8020/"
    "curso/spark/guia3/pipeline/"
    "ventas_por_region_nivel"
)

df_recuperado = spark.read.parquet(
    ruta_resultado
)
```

## 10. Examine el producto recuperado

```python
df_recuperado.printSchema()
df_recuperado.show(100, False)

print(
    "Cantidad de filas recuperadas:",
    df_recuperado.count()
)
```

El producto sobrevive a la aplicación que lo creó.

## 11. Diferencie dos conceptos de persistencia

`cache()` / `persist()` facilitan la reutilización temporal durante el procesamiento Spark.

`write.parquet()` crea un producto persistente en HDFS que puede ser recuperado por otra aplicación.

```text
cache / persist
       ≠
persistencia permanente en HDFS
```

## 12. Valide el resultado desde el propio pipeline

Después de escribir:

```python
df_validacion = spark.read.parquet(
    ruta_salida
)

cantidad_original_resultado = df_resultado.count()
cantidad_resultado_persistido = df_validacion.count()

print("\n=== VALIDACIÓN DE SALIDA ===")
print(
    "Filas antes de persistir:",
    cantidad_original_resultado
)
print(
    "Filas recuperadas desde HDFS:",
    cantidad_resultado_persistido
)

if (
    cantidad_original_resultado
    != cantidad_resultado_persistido
):
    raise ValueError(
        "Validación fallida: el resultado recuperado "
        "no contiene la cantidad esperada de filas."
    )
```

## 13. Observe la evolución del pipeline

```text
              HDFS
               │
      ┌────────┴────────┐
      ▼                 ▼
   ventas            ciudades
      │                 │
      ▼                 ▼
   lectura           lectura
      │                 │
      └────────┬────────┘
               ▼
         validación
               │
               ▼
            join
               │
               ▼
       transformación
               │
               ▼
          agregación
               │
               ▼
        df_resultado
               │
               ▼
           Parquet
               │
               ▼
              HDFS
               │
               ▼
           relectura
               │
               ▼
         validación
```

## 14. ¿Cuál es ahora nuestro producto de datos?

`ventas_hive.csv` representa datos transaccionales. `ventas_por_region_nivel` representa un **producto analítico derivado** con cantidad de ventas, monto total y monto promedio por región y nivel.

## 15. Analice

a. ¿Por qué `df_resultado` por sí solo no constituye un producto persistente?

b. ¿Por qué Parquet resulta apropiado para este producto?

c. ¿Qué función cumple `.mode("overwrite")`?

d. ¿Por qué la salida puede contener varios archivos `part-*`?

e. ¿Cuál es la diferencia entre `cache()`/`persist()` y escribir Parquet en HDFS?

f. ¿Por qué volvemos a leer el resultado después de escribirlo?

g. ¿Qué demuestra que el producto pueda recuperarse desde una nueva sesión de Spark?

h. ¿Por qué comparar la cantidad de filas antes y después de persistir es útil, pero no suficiente para garantizar que todos los datos sean correctos?

## 16. Concepto clave

El pipeline ya transforma datos de entrada en un producto persistente y reutilizable:

```text
HDFS
 ↓
lectura
 ↓
validación
 ↓
integración
 ↓
transformación
 ↓
agregación
 ↓
Parquet
 ↓
HDFS
```

---

# Ejercicio 14 — Ejecutar y validar el pipeline batch completo

Ahora no incorporaremos una nueva tecnología ni una transformación relevante.

El objetivo será:

> **Ejecutar el pipeline como una unidad completa, verificar sus etapas y comprender qué tipo de procesamiento hemos construido.**

Al finalizar podremos clasificar explícitamente nuestro proceso como un **pipeline batch**.

## 1. Observe el pipeline antes de ejecutarlo

```text
                        HDFS
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
       ventas_hive.csv         ciudades.csv
              │                     │
              ▼                     ▼
          df_ventas            df_ciudades
              │                     │
              └──────────┬──────────┘
                         ▼
                    validación
                         │
                         ▼
                     LEFT JOIN
                         │
                         ▼
                   df_integrado
                         │
                         ▼
                  nivel_venta
                         │
                         ▼
                  df_transformado
                         │
                         ▼
                     groupBy
                         │
                         ▼
                   df_resultado
                         │
                         ▼
                      Parquet
                         │
                         ▼
                        HDFS
                         │
                         ▼
                     relectura
                         │
                         ▼
                  validación final
```

## 2. Identifique entradas y salida

Entradas:

```text
hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv
hdfs://namenode:8020/curso/spark/guia3/fuentes/ciudades.csv
```

Salida:

```text
hdfs://namenode:8020/curso/spark/guia3/pipeline/ventas_por_region_nivel
```

## 3. Verifique el estado inicial en HDFS

Desde `namenode`:

```bash
sudo docker exec -it namenode bash

hdfs dfs -ls /curso/hive/datos_ventas/
hdfs dfs -ls /curso/spark/guia3/fuentes/

exit
```

Compruebe que las fuentes **ya existen en HDFS antes de iniciar el pipeline**.

## 4. Ejecute el pipeline como aplicación completa

```bash
sudo docker exec -it spark-master bash

cd /tmp/curso_spark/nivel3

export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  pipeline_ventas.py
```

## 5. Registre las etapas ejecutadas

Puede incorporar mensajes:

```python
print("\n=== ETAPA 1: CARGA DE FUENTES ===")
print("\n=== ETAPA 2: VALIDACIÓN DE ENTRADAS ===")
print("\n=== ETAPA 3: INTEGRACIÓN ===")
print("\n=== ETAPA 4: TRANSFORMACIÓN ===")
print("\n=== ETAPA 5: AGREGACIÓN ===")
print("\n=== ETAPA 6: PERSISTENCIA ===")
print("\n=== ETAPA 7: VALIDACIÓN FINAL ===")
print("\n=== PIPELINE FINALIZADO CORRECTAMENTE ===")
```

## 6. Compruebe las validaciones

El pipeline controla:

- si las entradas contienen registros;
- si se conservaron las ventas después del `left join`;
- si existen ventas cuya región quedó en `NULL`;
- si el resultado persistido puede recuperarse;
- si la cantidad de filas recuperadas coincide con la esperada.

La validación ocurre durante todo el proceso:

```text
entrada
   ↓
VALIDAR
   ↓
procesar
   ↓
VALIDAR
   ↓
procesar
   ↓
VALIDAR
   ↓
salida
```

## 7. Verifique el producto final desde HDFS

Desde `namenode`:

```bash
sudo docker exec -it namenode bash

hdfs dfs -ls /curso/spark/guia3/pipeline/

hdfs dfs -ls \
  /curso/spark/guia3/pipeline/ventas_por_region_nivel/
```

## 8. Compruebe que el resultado no depende de la aplicación

`pipeline_ventas.py` finaliza, pero el producto permanece disponible en HDFS. Por ello puede convertirse posteriormente en entrada de otro proceso.

## 9. Identifique cuándo comienza realmente el procesamiento

Primero `ventas_hive.csv` y `ciudades.csv` están completamente almacenados en HDFS. **Después** ejecutamos `spark-submit`.

```text
datos disponibles
       ↓
datos almacenados
       ↓
ejecución del proceso
       ↓
procesamiento
       ↓
resultado
```

Spark está procesando un conjunto de datos que ya se encuentra disponible.

## 10. Introduzca el concepto de procesamiento batch

En el procesamiento **batch** se procesa un conjunto de datos acumulado como una unidad de trabajo.

Nuestro caso:

```text
100.000 ventas
      ↓
almacenadas en HDFS
      ↓
ejecutamos Spark
      ↓
procesamos el conjunto
      ↓
generamos resultado
```

Esta arquitectura es válida para muchos problemas. Por ejemplo, podríamos ejecutar el pipeline una vez al día cuando ya estén disponibles todas las ventas de la jornada.

## 11. Simule conceptualmente una segunda ejecución

```text
nuevo archivo
     ↓
almacenar en HDFS
     ↓
ejecutar nuevamente
pipeline_ventas.py
     ↓
procesar lote
     ↓
nuevo resultado
```

El pipeline puede ejecutarse repetidamente, pero cada ejecución procesa los datos disponibles para esa ejecución.

## 12. Reconozca la principal suposición de nuestra arquitectura

> **Los datos que queremos procesar ya se encuentran disponibles en HDFS cuando comienza la aplicación.**

Hasta ahora trabajamos con ventas ya generadas, almacenadas y posteriormente procesadas.

## 13. Analice

a. ¿Cuáles son las dos fuentes de entrada del pipeline?

b. ¿Cuál es el producto persistente generado?

c. ¿Qué etapas principales recorre una venta desde que Spark lee la fuente hasta que forma parte del producto analítico?

d. ¿Por qué las validaciones se realizan en diferentes etapas?

e. ¿Qué diferencia existe entre la aplicación `pipeline_ventas.py` y el producto Parquet generado?

f. ¿Por qué podemos afirmar que nuestro pipeline realiza procesamiento batch?

g. ¿Qué condición deben cumplir actualmente los datos antes de que `pipeline_ventas.py` pueda procesarlos?

h. Si el pipeline se ejecutara una vez cada noche con las ventas acumuladas durante el día, ¿seguiría correspondiendo a procesamiento batch? Fundamente.

## 14. Concepto clave

```text
DATOS ACUMULADOS
       ↓
PROCESAMIENTO
       ↓
RESULTADO
```

Esto es **batch**.

## 15. Prepare el cambio de problema

Imagine que las ventas ya no aparecen como un archivo terminado, sino individualmente:

```text
12:00:01 → venta 1
12:00:03 → venta 2
12:00:04 → venta 3
12:00:09 → venta 4
...
```

Ahora tenemos:

```text
EVENTO → EVENTO → EVENTO → EVENTO → ...
```

Nuestro pipeline espera:

```text
archivo → HDFS → Spark
```

pero el nuevo escenario plantea:

```text
evento → ?
evento → ?
evento → ?
```

El ejercicio siguiente identificará qué le falta a nuestra arquitectura.

---

# Ejercicio 15 — Del procesamiento batch al procesamiento continuo: ¿qué le falta a nuestra arquitectura?

En este último ejercicio no agregaremos código a `pipeline_ventas.py` ni instalaremos una nueva herramienta.

El objetivo será **cambiar el problema** y razonar qué componente necesita nuestra arquitectura cuando los datos comienzan a generarse continuamente.

## 1. Nuestro escenario actual

```text
ventas acumuladas
       ↓
ventas_hive.csv
       ↓
      HDFS
       ↓
pipeline_ventas.py
       ↓
   procesamiento
       ↓
    resultado
```

Este modelo funciona cuando podemos esperar a que los datos se acumulen antes de procesarlos.

## 2. Cambie ahora el problema

Suponga que las ventas son generadas individualmente por diferentes puntos de venta:

```text
12:00:01  →  venta 10001
12:00:03  →  venta 10002
12:00:04  →  venta 10003
12:00:09  →  venta 10004
12:00:15  →  venta 10005
...
```

Ya no tenemos inicialmente un archivo completo. Tenemos:

```text
venta → venta → venta → venta → venta → ...
```

## 3. Introduzca el concepto de evento

> **Un evento es un dato generado como consecuencia de algo que ocurre en un sistema.**

Por ejemplo:

```text
se realiza una venta
        ↓
se genera un evento
```

Un evento podría contener `id_venta`, `fecha`, `cliente`, `ciudad`, `categoria` y `monto`.

## 4. Compare ambos escenarios

Escenario trabajado:

```text
venta
venta
venta
venta
  │
  │ acumulación
  ▼
archivo
  │
  ▼
HDFS
  │
  ▼
Spark
```

Nuevo escenario:

```text
venta → evento
venta → evento
venta → evento
venta → evento
...
```

En algunos problemas podemos esperar a reunir los datos. En otros necesitamos que estén disponibles para otros sistemas mucho antes.

## 5. Analice la limitación del pipeline actual

Nuestro pipeline comienza leyendo datos que ya están disponibles en HDFS. Ahora necesitamos intermediar un flujo continuo:

```text
SISTEMA QUE GENERA
LAS VENTAS
      │
      │ genera eventos
      ▼
      ?
      │
      ▼
SISTEMA QUE NECESITA
LOS DATOS
```

## 6. Primer nuevo concepto: Productor

> **Productor:** sistema o aplicación que publica eventos.

Puede ser una aplicación, sensor, sitio web, sistema transaccional o servicio.

```text
PRODUCTOR
    │
    ├── evento 1
    ├── evento 2
    ├── evento 3
    └── ...
```

## 7. Segundo nuevo concepto: Topic

> **Topic:** canal lógico en el que se publican eventos relacionados.

Por ejemplo, un topic llamado `ventas`:

```text
PRODUCTOR
    │
    │ publica
    ▼
┌─────────────────────────┐
│      TOPIC: ventas      │
│ evento                  │
│ evento                  │
│ evento                  │
│ ...                     │
└─────────────────────────┘
```

## 8. Tercer nuevo concepto: Consumidor

> **Consumidor:** sistema o aplicación que recibe y procesa eventos publicados.

```text
PRODUCTOR
    │
    │ publica
    ▼
  TOPIC
    │
    │ entrega eventos
    ▼
CONSUMIDOR
```

## 9. Reúna los cuatro conceptos

```text
EVENTO
PRODUCTOR
TOPIC
CONSUMIDOR
```

```text
      ┌───────────┐
      │ PRODUCTOR │
      └─────┬─────┘
            │ publica
            ▼
      ┌───────────┐
      │   TOPIC   │
      │  "ventas" │
      └─────┬─────┘
            │
            ▼
      ┌───────────┐
      │CONSUMIDOR │
      └───────────┘
```

Los datos que circulan son **eventos**.

## 10. ¿Dónde aparece Apache Kafka?

La arquitectura planteada nos conduce a **Apache Kafka**.

En la próxima unidad utilizaremos Kafka para estudiar:

```text
PRODUCTOR → TOPIC → CONSUMIDOR
```

Nuestro primer objetivo será comprender cómo publica un productor, dónde publica y cómo recibe un consumidor.

## 11. No confunda Kafka con Spark

Kafka no reemplaza a Spark.

En el contexto del curso:

```text
HDFS
  └── almacenamiento distribuido

Spark
  └── procesamiento distribuido

Kafka
  └── publicación y consumo de eventos
```

Estas tecnologías pueden formar parte de una misma arquitectura.

## 12. Observe la evolución arquitectónica del curso

Antes:

```text
HDFS
  ↓
Spark
  ↓
resultado
```

Nuevo problema:

```text
sistema que genera eventos
          │
          ▼
          ?
          │
          ▼
sistema que consume eventos
```

Nueva unidad:

```text
PRODUCTOR
    │
    ▼
  KAFKA
    │
  TOPIC
    │
    ▼
CONSUMIDOR
```

## 13. Desafío arquitectónico

Considere:

> Una cadena de tiendas posee múltiples sucursales. Cada vez que se realiza una venta, el sistema genera inmediatamente un registro con el identificador de la venta, fecha, ciudad, categoría y monto. La organización desea que otros sistemas puedan acceder a estos eventos sin esperar a que termine el día y se genere un archivo consolidado.

Represente conceptualmente una solución utilizando exclusivamente:

```text
EVENTO
PRODUCTOR
TOPIC
CONSUMIDOR
```

Complete:

```text
____________________
      PRODUCTOR
          │
          │ publica
          ▼
____________________
        TOPIC
          │
          │ recibe
          ▼
____________________
      CONSUMIDOR
```

Además, indique:

a. ¿Qué representa el evento?

b. ¿Qué sistema podría actuar como productor?

c. ¿Qué nombre asignaría al topic?

d. ¿Qué sistema podría actuar como consumidor?

## 14. Compare batch y el nuevo escenario

| Característica | Pipeline trabajado con Spark | Nuevo escenario |
|---|---|---|
| Llegada de datos | Datos acumulados | Datos generados continuamente |
| Unidad observada | Lote de datos | Evento |
| Inicio del procesamiento trabajado | Datos previamente disponibles | Los eventos aparecen a medida que ocurren |
| Fuente utilizada en la guía | HDFS | Productor |
| Intermediación de eventos | No requerida en nuestro ejercicio batch | Necesaria |
| Nueva tecnología a estudiar | — | Apache Kafka |

Esta comparación se refiere específicamente al pipeline batch construido durante la guía; no pretende afirmar que Spark solo pueda trabajar de una única forma.

## 15. Preguntas finales de análisis

a. ¿Qué característica permite clasificar el pipeline desarrollado en los ejercicios 11–14 como procesamiento batch?

b. ¿Qué cambia cuando las ventas dejan de llegar como un archivo terminado y comienzan a generarse individualmente?

c. ¿Qué entendemos por evento?

d. ¿Qué función cumple un productor?

e. ¿Qué función cumple un topic?

f. ¿Qué función cumple un consumidor?

g. ¿Por qué Kafka no debe entenderse simplemente como un reemplazo de Spark?

h. Si una empresa puede esperar hasta el final del día para procesar todas sus ventas, ¿es necesariamente incorrecto utilizar un pipeline batch? Fundamente.

i. Si otra empresa necesita que cada nueva venta esté disponible para otros sistemas prácticamente cuando ocurre, ¿qué limitación presenta el pipeline que construimos?

---

