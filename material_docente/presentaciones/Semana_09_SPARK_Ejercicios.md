# Guía Práctica 1 — Fundamentos de Apache Spark
## RDD, Scala, PySpark e integración con HDFS

### Tiempo estimado
90 minutos.

### Modalidad
Trabajo práctico individual.

### Propósito de la guía

Aplicar los fundamentos de Apache Spark mediante Scala y PySpark, comprendiendo la relación entre RDD, particiones, transformaciones, acciones y ejecución distribuida.

Durante la guía se retomará la infraestructura Big Data utilizada anteriormente en el curso. Los datos almacenados en **HDFS** y utilizados mediante **Apache Hive** serán posteriormente procesados con **Apache Spark**, permitiendo observar cómo diferentes tecnologías pueden trabajar sobre una misma capa de almacenamiento.

---

## Antes de comenzar

Durante esta guía utilizaremos tres componentes de nuestra infraestructura:

| Tecnología | Contenedor | Función durante la guía |
|---|---|---|
| HDFS | `namenode` | Administrar y verificar archivos almacenados en HDFS |
| Apache Hive | `hive-server` | Consultar datos estructurados mediante HiveQL |
| Apache Spark | `spark-master` | Ejecutar aplicaciones Spark mediante Scala y PySpark |

> **Importante:** cada tecnología será utilizada desde el contenedor destinado a esa función. Esto permite relacionar las instrucciones ejecutadas con los componentes de la arquitectura estudiados durante el curso.

La arquitectura que utilizaremos puede representarse inicialmente como:

```text
                 HDFS
                  │
                  ▼
          ventas_hive.csv
                  │
          ┌───────┴───────┐
          ▼               ▼
        Hive             Spark
          │               │
          ▼               ▼
       HiveQL       Scala / PySpark
```

---

# Nivel 1 — Básico

Los primeros cinco ejercicios permitirán reconocer el entorno Spark y aplicar las operaciones fundamentales sobre RDD.

---

## Ejercicio 1 — Iniciar Spark y reconocer el clúster

### Objetivo

Ingresar al entorno de Apache Spark e identificar los componentes básicos de la aplicación que utilizaremos durante la guía.

### Paso 1. Ingresar al contenedor Spark

Desde la terminal de Ubuntu:

```bash
sudo docker exec -it spark-master bash
```

Una vez dentro del contenedor:

```bash
cd /spark/bin
```

### Paso 2. Iniciar Spark utilizando Scala

Ejecute:

```bash
./spark-shell --master spark://spark-master:7077
```

Espere hasta visualizar:

```text
scala>
```

Observe también la información inicial entregada por Spark.

### Paso 3. Comprobar el Master utilizado

Ejecute:

```scala
sc.master
```

Debería obtener:

```text
spark://spark-master:7077
```

Ahora consulte la versión:

```scala
sc.version
```

### Paso 4. Observe el clúster

Sin cerrar `spark-shell`, abra en su navegador:

```text
http://localhost:8080
```
> Recuerde: si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la `IP pública` de su instancia.

Localice la aplicación que acaba de iniciar.

### Verifique

Identifique en la interfaz:

* el Worker disponible;
* la aplicación Spark actualmente activa;
* los recursos disponibles;
* el identificador de la aplicación.

### Interprete

**Pregunta:** ¿por qué es importante utilizar:

```bash
--master spark://spark-master:7077
```

en lugar de iniciar Spark simplemente con `./spark-shell`?

> **Idea clave:** estamos indicando que nuestra aplicación debe utilizar el clúster Spark Standalone y no ejecutarse solamente en modo local.

---

## Ejercicio 2 — Crear nuestro primer RDD

### Objetivo

Crear un RDD y reconocer el concepto de partición.

En el mismo `spark-shell`, ejecute:

```scala
val datos = sc.parallelize(1 to 100, 4)
```

Hemos solicitado a Spark distribuir la colección utilizando **4 particiones**.

Compruébelo:

```scala
datos.getNumPartitions
```

Resultado esperado:

```text
4
```

Ahora ejecute:

```scala
datos.count()
```

Resultado esperado:

```text
100
```

Finalmente:

```scala
datos.sum()
```

Resultado esperado:

```text
5050.0
```

### ¿Qué ocurrió?

Podemos representar nuestro RDD conceptualmente como:

```text
RDD: números del 1 al 100
          │
          ▼
 ┌────────┬────────┬────────┬────────┐
 │ Part.1 │ Part.2 │ Part.3 │ Part.4 │
 └────────┴────────┴────────┴────────┘
```

Estas particiones constituyen **divisiones lógicas utilizadas por Spark para organizar el procesamiento**.

### Interprete

Responda:

1. ¿Cuántas particiones posee el RDD?
2. ¿Cuántos elementos contiene?
3. ¿Tener cuatro particiones significa que nuestro clúster posee cuatro Workers?

> **Recuerde:** `Partición ≠ Worker`. Un único Worker puede procesar múltiples particiones.

---

## Ejercicio 3 — Aplicar una transformación con `map`

### Objetivo

Aplicar una transformación sobre un RDD y comprobar que los RDD son inmutables.

Utilice el RDD creado anteriormente:

```scala
datos
```

Ahora genere un nuevo RDD multiplicando cada elemento por 2:

```scala
val datosDobles = datos.map(x => x * 2)
```

Observe algunos resultados:

```scala
datosDobles.take(10)
```

Debería obtener valores equivalentes a:

```text
2, 4, 6, 8, 10, ...
```

Compruebe ahora el RDD original:

```scala
datos.take(10)
```

### Interprete

Observe:

```text
datos
  │
  │ map(x => x * 2)
  ▼
datosDobles
```

`map` no modificó el RDD original.

Creó un **nuevo RDD**.

Responda:

1. ¿Qué ocurrió con `datos`?
2. ¿Qué contiene `datosDobles`?
3. ¿Qué característica de los RDD estamos observando?

> **Idea clave:** los RDD son inmutables. Las transformaciones generan nuevos RDD en lugar de modificar directamente los existentes.

---

## Ejercicio 4 — Transformaciones y acciones

### Objetivo

Distinguir una transformación de una acción.

A partir de `datos`, seleccione solamente los números pares:

```scala
val pares = datos.filter(x => x % 2 == 0)
```

Observe algunos elementos:

```scala
pares.take(10)
```

Ahora determine cuántos números cumplen la condición:

```scala
pares.count()
```

Resultado esperado:

```text
50
```

Observe la secuencia:

```text
datos
  │
  │ filter
  ▼
pares
  │
  │ count
  ▼
 50
```

Clasifique las siguientes operaciones:

| Operación | ¿Transformación o acción? |
| --------- | ------------------------- |
| `filter`  | ?                         |
| `take`    | ?                         |
| `count`   | ?                         |

### Interprete

La instrucción:

```scala
val pares = datos.filter(x => x % 2 == 0)
```

define una transformación.

Spark no necesita ejecutar inmediatamente todo el procesamiento para registrar esta operación.

En cambio:

```scala
pares.count()
```

solicita un resultado concreto.

Por ello se considera una **acción**.

Esta diferencia será fundamental para comprender posteriormente la **evaluación perezosa (*lazy evaluation*)** de Spark.

---

## Ejercicio 5 — Realizar operaciones equivalentes utilizando PySpark

### Objetivo

Comprobar que los conceptos fundamentales de Spark permanecen aunque cambiemos de Scala a Python.

### Paso 1. Salir de Scala

Ejecute:

```scala
:quit
```

Ahora volverá a la terminal del contenedor `spark-master`.

### Paso 2. Configurar Python 3

Nuestra imagen Spark utiliza una versión antigua en la cual Python 3 no se encuentra configurado como intérprete predeterminado de PySpark.

Para esta sesión ejecute:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3
```

> Estas variables se aplican a la sesión actual y permiten utilizar Python 3 tanto para el Driver como para los procesos Python utilizados por Spark.

### Paso 3. Iniciar PySpark

Ejecute:

```bash
./pyspark --master spark://spark-master:7077
```

Espere hasta visualizar:

```text
>>>
```

Compruebe el Master:

```python
sc.master
```

### Paso 4. Crear un RDD

Ejecute:

```python
datos = sc.parallelize(range(1, 101), 4)
```

Compruebe sus particiones:

```python
datos.getNumPartitions()
```

Resultado esperado:

```text
4
```

### Paso 5. Aplicar una transformación

Seleccione los números mayores que 50:

```python
mayores_50 = datos.filter(lambda x: x > 50)
```

Observe algunos resultados:

```python
mayores_50.take(10)
```

Finalmente:

```python
mayores_50.count()
```

Resultado esperado:

```text
50
```

---

## Comparación Scala y PySpark

Observe las dos expresiones:

### Scala

```scala
datos.filter(x => x > 50)
```

### PySpark

```python
datos.filter(lambda x: x > 50)
```

La sintaxis es diferente, pero conceptualmente ambas expresiones representan:

```text
RDD
 │
 │ filter
 ▼
Nuevo RDD
```

En ambos casos seguimos trabajando con:

```text
RDD
 ↓
Particiones
 ↓
Transformaciones
 ↓
Acciones
 ↓
Procesamiento distribuido
```

### Reflexión del Nivel 1

Antes de continuar, responda brevemente:

1. ¿Qué es un RDD?
2. ¿Qué representa una partición?
3. ¿Cuál es la diferencia entre una transformación y una acción?
4. ¿Por qué cuatro particiones no significan cuatro Workers?
5. ¿Qué cambia al pasar de Scala a PySpark y qué elementos de Spark permanecen iguales?

---

## Resultado esperado del Nivel 1

Al completar estos cinco ejercicios debería poder interpretar el siguiente esquema:

```text
              Scala / PySpark
                    │
                    ▼
                   RDD
                    │
              ┌─────┼─────┐
              ▼     ▼     ▼
         Partición Partición ...
                    │
                    ▼
             Transformaciones
                    │
                    ▼
                 Acciones
                    │
                    ▼
                   Job
                    │
                    ▼
          Procesamiento Spark
```

---

# Nivel 2 — Intermedio

En este nivel profundizaremos en la forma en que Spark organiza y ejecuta el procesamiento distribuido.

Trabajaremos con:

- evaluación perezosa (*lazy evaluation*);
- transformaciones y acciones;
- particiones;
- operaciones de agregación;
- observación del clúster;
- lectura de datos almacenados en HDFS.

Al finalizar el nivel conectaremos por primera vez dos componentes estudiados durante el curso:

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
RDD
```

---

## Ejercicio 6 — Comprobar la evaluación perezosa de Spark

### Objetivo

Reconocer que Spark no ejecuta necesariamente una transformación en el momento en que esta es declarada y comprobar el papel que desempeñan las acciones.

Continuaremos trabajando en **PySpark** desde el contenedor `spark-master`.

Si cerró la sesión anterior, recuerde iniciar PySpark utilizando Python 3:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3
./pyspark --master spark://spark-master:7077
```

### Paso 1. Crear un RDD

Ejecute:

```python
numeros = sc.parallelize(range(1, 100001), 4)
```

Compruebe:

```python
numeros.getNumPartitions()
```

### Paso 2. Definir varias transformaciones

Ejecute:

```python
pares = numeros.filter(lambda x: x % 2 == 0)
```

Luego:

```python
cuadrados = pares.map(lambda x: x * x)
```

Hasta este momento hemos definido:

```text
numeros
   │
   │ filter
   ▼
 pares
   │
   │ map
   ▼
cuadrados
```

Observe ahora la interfaz Spark Master:

```text
http://localhost:8080
```

> Recuerde: si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la `IP pública` de su instancia.

Las transformaciones han definido cómo deben procesarse los datos, pero todavía no hemos solicitado un resultado final.

### Paso 3. Ejecutar una acción

Ahora ejecute:

```python
cuadrados.count()
```

### Interprete

Identifique:

* las transformaciones utilizadas;
* la acción utilizada;
* el momento en que Spark necesitó calcular un resultado.

Complete conceptualmente:

```text
filter
   ↓
¿Transformación o acción?

map
   ↓
¿Transformación o acción?

count
   ↓
¿Transformación o acción?
```

> **Idea clave:** Spark utiliza *lazy evaluation*. Las transformaciones permiten construir un plan de procesamiento y una acción provoca la ejecución necesaria para obtener un resultado.

---

## Ejercicio 7 — Particiones y paralelismo

### Objetivo

Analizar la relación entre particiones y procesamiento distribuido.

Cree tres RDD utilizando los mismos datos:

```python
rdd2 = sc.parallelize(range(1, 100001), 2)
rdd4 = sc.parallelize(range(1, 100001), 4)
rdd8 = sc.parallelize(range(1, 100001), 8)
```

Compruebe el número de particiones:

```python
rdd2.getNumPartitions()
rdd4.getNumPartitions()
rdd8.getNumPartitions()
```

Debería obtener:

```text
2
4
8
```

Ejecute ahora una acción sobre cada RDD:

```python
rdd2.count()
rdd4.count()
rdd8.count()
```

### Analice

Los tres RDD contienen exactamente:

```text
100.000 elementos
```

pero Spark ha organizado los datos utilizando diferentes cantidades de particiones.

Conceptualmente:

```text
RDD A

┌─────────────┬─────────────┐
│ Partición 1 │ Partición 2 │
└─────────────┴─────────────┘


RDD B

┌──────┬──────┬──────┬──────┐
│ P1   │ P2   │ P3   │ P4   │
└──────┴──────┴──────┴──────┘


RDD C

┌────┬────┬────┬────┬────┬────┬────┬────┐
│ P1 │ P2 │ P3 │ P4 │ P5 │ P6 │ P7 │ P8 │
└────┴────┴────┴────┴────┴────┴────┴────┘
```

Responda:

1. ¿Cambió la cantidad total de elementos?
2. ¿Qué característica sí cambió?
3. ¿Ocho particiones implican necesariamente ocho Workers?
4. Si existen menos recursos de ejecución que particiones, ¿pueden las Tasks ejecutarse en diferentes momentos?

Recuerde la relación:

```text
Partición
    │
    ▼
  Task
    │
    ▼
Executor
    │
    ▼
 Worker
```

> Una partición es una división lógica de los datos. No representa un computador ni un Worker.

---

## Ejercicio 8 — Aplicar transformaciones y una agregación

### Objetivo

Construir una pequeña secuencia de procesamiento utilizando varias operaciones Spark.

Utilice el siguiente RDD:

```python
datos = sc.parallelize(range(1, 101), 4)
```

A partir de este RDD:

1. seleccione solamente los números pares;
2. multiplique cada número seleccionado por 10;
3. calcule la suma de los valores resultantes.

Utilice las operaciones:

```text
filter
map
reduce
```

Construya usted mismo las instrucciones necesarias.

### Compruebe

Su procesamiento debería seguir esta estructura:

```text
1 ... 100
    │
    │ filter
    ▼
números pares
    │
    │ map
    ▼
multiplicar × 10
    │
    │ reduce
    ▼
resultado
```

Una vez obtenido el resultado, identifique:

| Operación | Tipo       |
| --------- | ---------- |
| `filter`  | __________ |
| `map`     | __________ |
| `reduce`  | __________ |

### Reflexione

¿Cuántas transformaciones se definieron antes de solicitar el resultado?

¿Qué operación provocó finalmente que Spark tuviera que calcular el resultado?

---

## Ejercicio 9 — Volver a HDFS y localizar nuestros datos

### Objetivo

Comprobar que el conjunto de datos que utilizaremos con Spark se encuentra almacenado en HDFS.

Hasta ahora hemos trabajado con datos creados directamente desde Spark.

Ahora utilizaremos datos persistentes.

### Paso 1. Salir de PySpark

Ejecute:

```python
exit()
```

Luego salga del contenedor:

```bash
exit
```

### Paso 2. Ingresar al contenedor de HDFS

Desde Ubuntu:

```bash
sudo docker exec -it namenode bash
```

Recuerde:

```text
HDFS  → namenode
Hive  → hive-server
Spark → spark-master
```

### Paso 3. Localizar el archivo

Ejecute:

```bash
hdfs dfs -ls -h /curso/hive/datos_ventas/
```

Debería encontrar:

```text
ventas_hive.csv
```

Observe su tamaño.

### Paso 4. Visualizar una muestra

Ejecute:

```bash
hdfs dfs -cat /curso/hive/datos_ventas/ventas_hive.csv | head -5
```

Observe los registros.

Cada línea posee la siguiente estructura:

```text
id_venta,fecha,cliente,ciudad,categoria,monto
```

Por ejemplo, conceptualmente:

```text
1,2025-...,CLIENTE_....,Santiago,Tecnologia,....
```

### Interprete

Hasta este momento:

```text
             HDFS
               │
               ▼
      ventas_hive.csv
               │
               ▼
        100.000 ventas
```

El archivo está almacenado en HDFS independientemente de Spark.

Spark será ahora el motor encargado de **procesar esos datos**.

---

## Ejercicio 10 — Leer datos de HDFS utilizando Spark

### Objetivo

Construir un RDD Spark utilizando como fuente un archivo almacenado en HDFS.

### Paso 1. Salir del contenedor HDFS

Ejecute:

```bash
exit
```

### Paso 2. Ingresar nuevamente a Spark

Desde Ubuntu:

```bash
sudo docker exec -it spark-master bash
```

Luego:

```bash
cd /spark/bin
```

Inicie `spark-shell`:

```bash
./spark-shell --master spark://spark-master:7077
```

### Paso 3. Crear un RDD desde HDFS

Ejecute:

```scala
val ventas = sc.textFile(
  "hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv"
)
```

Observe la respuesta entregada por Spark.

La variable `ventas` corresponde ahora a un:

```text
RDD[String]
```

Conceptualmente:

```text
HDFS
 │
 ▼
ventas_hive.csv
 │
 │ sc.textFile(...)
 ▼
Spark
 │
 ▼
RDD[String]
```

### Paso 4. Comprobar la cantidad de registros

Ejecute:

```scala
ventas.count()
```

Resultado esperado:

```text
100000
```

### Paso 5. Visualizar algunos registros

Ejecute:

```scala
ventas.take(5).foreach(println)
```

Compare estos registros con los observados anteriormente desde HDFS.

### Paso 6. Consultar las particiones

Ejecute:

```scala
ventas.getNumPartitions
```

Registre el resultado obtenido.

> **Importante:** no asuma que la cantidad de particiones debe coincidir con la cantidad de Workers o DataNodes.

---

## ¿Qué acabamos de hacer?

Por primera vez en esta guía hemos conectado directamente dos tecnologías:

```text
              HDFS
               │
               ▼
      ventas_hive.csv
               │
               │ lectura
               ▼
             Spark
               │
               ▼
          RDD[String]
               │
               ▼
       Procesamiento
        distribuido
```

Observe que Spark **no trasladó conceptualmente el archivo a una nueva base de datos**.

HDFS continúa cumpliendo su función:

```text
HDFS
  ↓
almacenamiento distribuido
```

mientras Spark cumple otra:

```text
Spark
  ↓
procesamiento distribuido
```

---

# Reflexión del Nivel 2

Responda brevemente:

1. ¿Qué diferencia existe entre crear un RDD mediante `parallelize` y crearlo mediante `textFile`?
2. ¿Qué característica de Spark explica que `filter` y `map` no necesiten producir inmediatamente un resultado?
3. ¿Qué operación provoca normalmente la ejecución efectiva del procesamiento?
4. ¿Por qué una partición Spark no debe confundirse con un bloque HDFS?
5. En el Ejercicio 10, ¿qué tecnología almacena `ventas_hive.csv` y qué tecnología lo procesa?

---

## Resultado esperado del Nivel 2

Al finalizar estos ejercicios debería comprender el siguiente recorrido:

```text
                  HDFS
                    │
                    ▼
            ventas_hive.csv
                    │
                    ▼
             sc.textFile(...)
                    │
                    ▼
                   RDD
                    │
              ┌─────┴─────┐
              ▼           ▼
       Transformaciones  Particiones
              │           │
              └─────┬─────┘
                    ▼
                  Acción
                    │
                    ▼
                   Job
                    │
                    ▼
                  Tasks
                    │
                    ▼
                Executors
```

Hasta este punto hemos aprendido a **leer** desde HDFS.

En el Nivel 3 utilizaremos las 100.000 ventas para realizar procesamiento real con Spark y finalmente compararemos el tratamiento del mismo conjunto de datos mediante:

```text
                  HDFS
                    │
            ventas_hive.csv
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
        Hive                Spark
          │                   │
       HiveQL             RDD / API
          │                   │
          └─────────┬─────────┘
                    ▼
              Comparación
```

De esta manera conectaremos explícitamente **HDFS + Hive + Spark** dentro de una misma arquitectura Big Data.

---

# Nivel 3 — Avanzado

En este nivel utilizaremos las **100.000 ventas almacenadas en HDFS** para construir pequeños procesos de análisis distribuido.

A diferencia de los niveles anteriores, algunas instrucciones ya no se entregarán completamente construidas. Deberá identificar las operaciones Spark necesarias y relacionarlas con los conceptos estudiados.

Trabajaremos sobre:

```text
/curso/hive/datos_ventas/ventas_hive.csv
```

cuya estructura es:

```text
id_venta,fecha,cliente,ciudad,categoria,monto
```

Recuerde que el archivo **no posee encabezado**, por lo que cada línea corresponde directamente a una venta.

---

## Ejercicio 11 — Transformar texto en datos estructurados

### Objetivo

Transformar las líneas de texto provenientes de HDFS en registros cuyos campos puedan ser procesados individualmente.

Comenzaremos utilizando **PySpark**.

### Paso 1. Cambiar de Scala a PySpark

Si continúa dentro de `spark-shell`, salga utilizando:

```scala
:quit
```

En `spark-master`, configure Python 3:

```bash
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3
```

Inicie PySpark:

```bash
./pyspark --master spark://spark-master:7077
```

---

### Paso 2. Leer nuevamente el archivo desde HDFS

Ejecute:

```python
ventas = sc.textFile(
    "hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv"
)
```

Observe algunos registros:

```python
ventas.take(3)
```

Cada elemento del RDD corresponde actualmente a una línea completa del archivo.

Conceptualmente:

```text
RDD[String]

"1,2025-...,CLIENTE_...,Santiago,Tecnologia,150000.0"
"2,2025-...,CLIENTE_...,Temuco,Hogar,85000.0"
...
```

---

### Paso 3. Separar los campos

Utilice:

```python
campos = ventas.map(lambda linea: linea.split(","))
```

Observe:

```python
campos.take(3)
```

Ahora cada registro posee una estructura similar a:

```text
[
 id_venta,
 fecha,
 cliente,
 ciudad,
 categoria,
 monto
]
```

Compruebe cuántos campos posee un registro:

```python
len(campos.first())
```

Resultado esperado:

```text
6
```

---

### Interprete

Compare:

```text
ANTES

"1,2025-...,CLIENTE_...,Santiago,Tecnologia,150000"

                    │
                    │ split(",")
                    ▼

DESPUÉS

["1",
 "2025-...",
 "CLIENTE_...",
 "Santiago",
 "Tecnologia",
 "150000"]
```

Responda:

1. ¿Qué tipo de elemento contenía inicialmente el RDD?
2. ¿Qué transformación utilizamos?
3. ¿Se modificó el RDD `ventas` original?
4. ¿Por qué `campos` constituye un nuevo RDD?

> **Importante:** todavía estamos trabajando con RDD. Separar los campos no convierte automáticamente los datos en un DataFrame.

---

# Ejercicio 12 — Filtrar ventas según su monto

### Objetivo

Aplicar transformaciones sobre los datos provenientes de HDFS y obtener un resultado analítico simple.

Utilice el RDD `campos` creado anteriormente.

Recordemos las posiciones:

```text
0 → id_venta
1 → fecha
2 → cliente
3 → ciudad
4 → categoria
5 → monto
```

Queremos responder:

> **¿Cuántas ventas poseen un monto superior a $400.000?**

Para realizar la comparación deberá convertir el campo `monto` a un valor numérico.

Construya una solución utilizando:

```text
filter
count
```

Puede utilizar como referencia la condición:

```python
float(x[5]) > 400000
```

---

### Verifique una muestra

Antes de contar todos los registros, compruebe algunos resultados utilizando:

```python
.take(5)
```

Observe que los registros obtenidos efectivamente posean un monto superior a $400.000.

Posteriormente determine la cantidad total.

---

### Analice el procesamiento

Complete:

```text
HDFS
  │
  ▼
ventas_hive.csv
  │
  ▼
RDD[String]
  │
  │ split
  ▼
RDD con campos
  │
  │ filter
  ▼
Ventas > $400.000
  │
  │ count
  ▼
Resultado
```

Identifique:

| Operación                    | Tipo       |
| ---------------------------- | ---------- |
| `map` utilizado para `split` | __________ |
| `filter`                     | __________ |
| `count`                      | __________ |

### Pregunta

¿En qué momento Spark necesita ejecutar realmente el procesamiento necesario para obtener la cantidad total?

Relacione su respuesta con el concepto de **lazy evaluation**.

---

# Ejercicio 13 — Agregar información por categoría

### Objetivo

Utilizar RDD de pares clave-valor para realizar una agregación distribuida.

En este ejercicio utilizaremos **Scala**.

Salga de PySpark:

```python
exit()
```

Inicie nuevamente:

```bash
./spark-shell --master spark://spark-master:7077
```

Cargue el archivo:

```scala
val ventas = sc.textFile(
  "hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv"
)
```

Separe sus campos:

```scala
val campos = ventas.map(linea => linea.split(","))
```

---

### Problema

Queremos responder:

> **¿Cuál es el monto total vendido por cada categoría?**

Para ello construiremos pares:

```text
(clave, valor)
```

utilizando:

```text
categoria → clave
monto     → valor
```

Conceptualmente:

```text
Tecnologia,150000
Hogar,85000
Tecnologia,200000
Deportes,90000
Hogar,120000
```

se transforma en:

```text
("Tecnologia",150000)
("Hogar",85000)
("Tecnologia",200000)
("Deportes",90000)
("Hogar",120000)
```

---

### Construya los pares

Complete la transformación utilizando las posiciones correspondientes:

```scala
val ventasCategoria = campos.map(x => (__________, __________))
```

Recuerde convertir `monto` a `Double`.

---

### Agregue los valores

Utilice:

```scala
reduceByKey
```

para sumar los montos pertenecientes a una misma categoría.

Finalmente visualice los resultados.

---

### Interprete

El procesamiento realizado puede representarse como:

```text
Registros
   │
   ▼
(categoria, monto)
   │
   ▼
reduceByKey
   │
   ├── Tecnologia → total
   ├── Hogar      → total
   ├── Vestuario  → total
   ├── Alimentos  → total
   └── Deportes   → total
```

Responda:

1. ¿Por qué `categoria` resulta apropiada como clave?
2. ¿Qué hace `reduceByKey` con los registros que poseen la misma clave?
3. ¿Qué diferencia existe entre este procesamiento y simplemente utilizar `count()`?
4. ¿Qué transformación puede provocar redistribución de información entre particiones?

> **Pista:** recuerde el concepto de **shuffle** estudiado en la guía teórica.

---

# Ejercicio 14 — Resolver la misma pregunta con Hive y Spark

### Objetivo

Comparar dos formas de procesar los **mismos datos almacenados en HDFS**.

Utilizaremos:

```text
Pregunta analítica:

¿Cuál es el monto total vendido por categoría?
```

La resolveremos primero mediante **HiveQL** y posteriormente mediante **Spark**.

---

## Parte A — Resolver mediante Hive

Salga de Spark y del contenedor `spark-master`.

Ingrese al contenedor correspondiente:

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

Debería encontrar:

```text
ventas_hive
```

Ahora construya una consulta HiveQL que:

* utilice `categoria`;
* calcule la suma de `monto`;
* agrupe los registros por categoría.

No se entrega la consulta completa. Utilice lo aprendido anteriormente en las actividades de Hive.

Registre los resultados.

---

## Parte B — Resolver mediante Spark

La misma pregunta ya fue abordada en el ejercicio anterior:

```text
¿Cuál es el monto total vendido por categoría?
```

Compare los resultados obtenidos.

Deberían corresponder, ya que ambos motores están trabajando sobre los mismos datos.

---

## ¿Qué está ocurriendo realmente?

La arquitectura utilizada es:

```text
                       HDFS
                         │
                         ▼
                 ventas_hive.csv
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
           Hive                    Spark
             │                       │
             ▼                       ▼
      tabla ventas_hive             RDD
             │                       │
             ▼                       ▼
          HiveQL               Scala / PySpark
             │                       │
             ▼                       ▼
        SUM + GROUP             reduceByKey
             │                       │
             └───────────┬───────────┘
                         ▼
                  mismo resultado
```

### Importante

En nuestra infraestructura actual:

```text
Spark ──X──> Hive Metastore
```

Spark no está consultando directamente la tabla:

```text
curso_bigdata.ventas_hive
```

Hive y Spark están accediendo por caminos diferentes a los **mismos datos almacenados en HDFS**.

Por lo tanto:

```text
Hive
  ↓
utiliza los metadatos de ventas_hive
  ↓
lee los datos de HDFS
```

mientras:

```text
Spark
  ↓
lee directamente ventas_hive.csv
  ↓
desde HDFS
```

Esta diferencia es fundamental para interpretar correctamente nuestra arquitectura.

---

### Compare

Complete la siguiente tabla:

| Elemento                       | Hive       | Spark      |
| ------------------------------ | ---------- | ---------- |
| Fuente física de datos         | __________ | __________ |
| Forma de representar los datos | Tabla Hive | __________ |
| Lenguaje/API utilizado         | __________ | Scala      |
| Operación de agrupación        | `GROUP BY` | __________ |
| Operación de suma              | `SUM()`    | __________ |

### Reflexione

Si Hive y Spark entregan el mismo resultado, ¿significa esto que realizan internamente el procesamiento exactamente de la misma forma?

Justifique brevemente.

---

# Ejercicio 15 — Desafío integrador

### Objetivo

Construir de manera autónoma un pequeño proceso de análisis distribuido utilizando los conocimientos desarrollados durante la guía.

Trabajará nuevamente con:

```text
hdfs://namenode:8020/curso/hive/datos_ventas/ventas_hive.csv
```

Puede utilizar **Scala o PySpark**.

---

## Desafío

Responda la siguiente pregunta:

> **¿Cuál es el monto total vendido en cada ciudad considerando solamente las ventas superiores a $300.000?**

Su solución deberá incluir obligatoriamente:

1. lectura de los datos desde HDFS;
2. separación de los campos del archivo;
3. filtrado de ventas superiores a $300.000;
4. construcción de pares `(ciudad, monto)`;
5. agregación de los montos por ciudad;
6. obtención y visualización del resultado.

No se entrega el código completo.

Diseñe la secuencia de operaciones necesaria.

---

## Planifique antes de programar

Complete primero:

```text
ventas_hive.csv
       │
       ▼
____________________
       │
       ▼
separar campos
       │
       ▼
____________________
       │
       ▼
filtrar monto > 300000
       │
       ▼
____________________
       │
       ▼
(ciudad, monto)
       │
       ▼
____________________
       │
       ▼
resultado
```

Luego implemente su solución.

---

## Observe la ejecución

Mientras ejecuta la acción final, observe:

```text
http://localhost:8080
```

> Recuerde: si está trabajando con la infraestructura desplegada en AWS, reemplace `localhost` por la `IP pública` de su instancia.

Identifique su aplicación Spark.

Relacione conceptualmente:

```text
Código Scala / PySpark
          │
          ▼
       Driver
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

Recuerde que nuestra arquitectura posee un único Worker. Esto **no impide que Spark divida el procesamiento en múltiples particiones y Tasks**.

---

## Evidencia final

Registre:

* lenguaje utilizado;
* número de particiones del RDD inicial;
* resultado obtenido;
* transformaciones utilizadas;
* acciones utilizadas.

Clasifique las operaciones utilizadas en su solución:

| Operación                                     | Transformación / Acción |
| --------------------------------------------- | ----------------------- |
| `textFile`                                    | __________              |
| `map`                                         | __________              |
| `filter`                                      | __________              |
| `reduceByKey`                                 | __________              |
| operación utilizada para obtener el resultado | __________              |

---

# Cierre de la guía

Durante estos 15 ejercicios hemos avanzado desde una colección creada directamente en Spark hasta el procesamiento de un conjunto de **100.000 registros almacenados en HDFS**.

El recorrido completo fue:

```text
                 Apache Spark
                       │
                       ▼
                      RDD
                       │
                       ▼
                  Particiones
                       │
                       ▼
                Transformaciones
                       │
                       ▼
                Lazy Evaluation
                       │
                       ▼
                    Acción
                       │
                       ▼
                     Job
                       │
                       ▼
                Procesamiento
                 distribuido
```

Posteriormente incorporamos HDFS:

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
RDD
  │
  ▼
Procesamiento
```

y finalmente conectamos conceptualmente las tres tecnologías estudiadas:

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
               ▼                       ▼
            HiveQL              Scala / PySpark
               │                       │
               └───────────┬───────────┘
                           ▼
                    Análisis de datos
```

## Ideas fundamentales

Al finalizar esta guía debe poder explicar que:

* **HDFS almacena los datos de manera distribuida.**
* **Hive permite estructurar y consultar los datos mediante tablas y HiveQL.**
* **Spark permite procesar los datos de manera distribuida.**
* Un **RDD** es una colección distribuida dividida en particiones.
* Una **partición Spark no es un Worker ni un DataNode**.
* Las **transformaciones** generan nuevos RDD y son evaluadas de manera perezosa.
* Las **acciones** solicitan resultados y desencadenan el procesamiento necesario.
* Scala y PySpark permiten utilizar diferentes sintaxis sobre el mismo motor Spark.
* Diferentes motores pueden trabajar sobre los **mismos datos almacenados en HDFS**.

---




