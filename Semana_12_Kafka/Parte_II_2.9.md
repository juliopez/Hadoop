# 2.9. Integración de Kafka con Apache Spark Structured Streaming

## 2.9.1. De la distribución de eventos al procesamiento distribuido

En los apartados anteriores construimos progresivamente una arquitectura de integración de datos basada en Apache Kafka.

Primero estudiamos la publicación y el consumo de eventos. Posteriormente, incorporamos fuentes externas mediante APIs REST y desarrollamos un productor Python capaz de transformar registros comerciales y publicarlos en un tópico. Finalmente, examinamos los mecanismos necesarios para evolucionar hacia una integración Near Real-Time, considerando latencia, duplicados, puntos de control y recuperación ante fallos.

Sin embargo, hasta ahora nuestros consumidores se han limitado principalmente a recuperar y mostrar los mensajes recibidos.

En una plataforma de Big Data, el objetivo suele ser más amplio: necesitamos **transformar, filtrar, agregar y analizar grandes volúmenes de eventos de manera continua**.

Por ejemplo, una empresa podría necesitar conocer el monto de las ventas confirmadas, identificar transacciones rechazadas o calcular indicadores comerciales a partir de los eventos publicados en Kafka.

Para desarrollar estas operaciones incorporaremos Apache Spark.

Spark es un motor de procesamiento distribuido que permite ejecutar transformaciones y análisis sobre conjuntos de datos. Mediante Structured Streaming, podemos utilizar la API de DataFrames para procesar información que llega continuamente desde fuentes compatibles.

La integración de ambas tecnologías establece una separación de responsabilidades:

**Kafka transporta y conserva los eventos; Spark los interpreta y procesa.**

Esta distinción es fundamental. Kafka no reemplaza al motor analítico y Spark no reemplaza necesariamente a la plataforma de distribución de eventos.

## 2.9.2. ¿Qué es Apache Spark Structured Streaming?

Structured Streaming es un componente de Apache Spark que permite expresar operaciones sobre flujos de datos utilizando abstracciones estructuradas, especialmente DataFrames.

Desde la perspectiva del desarrollador, muchas transformaciones se parecen a las que aplicaríamos sobre datos estáticos.

Por ejemplo, podemos seleccionar columnas, filtrar registros y realizar agrupaciones.

La diferencia es que, en lugar de trabajar exclusivamente con un conjunto de datos cerrado, la consulta puede ejecutarse continuamente mientras se incorporan nuevos registros.

En Spark 2.4, versión de referencia de nuestro laboratorio, Structured Streaming utiliza principalmente un modelo de ejecución basado en **micro-batches**.

Esto significa que el motor organiza los registros disponibles en pequeños lotes sucesivos y aplica sobre ellos las transformaciones definidas.

No debemos confundir este mecanismo con el procesamiento estrictamente individual e inmediato de cada evento.

![Figura 67. Relación entre Kafka, Structured Streaming y los resultados analíticos](imagenes/figura_67.svg)

*Figura 67. Kafka recibe eventos desde el productor y Spark ejecuta las transformaciones analíticas.*

Structured Streaming no obliga a escribir manualmente un ciclo que consulte Kafka cada cierto número de segundos.

El motor administra la ejecución de la consulta, la obtención de registros y el progreso del procesamiento, de acuerdo con la configuración utilizada.

## 2.9.3. Procesamiento por micro-batches

Para comprender el funcionamiento de Spark 2.4, consideremos que nuestro tópico `ventas` recibe eventos continuamente.

Structured Streaming puede procesar los registros disponibles mediante una secuencia de micro-batches.

| Micro-batch | Registros recibidos | Operación |
|---|---|---|
| 1 | V-1048, V-1049 | Transformar y filtrar |
| 2 | V-1050 | Transformar y filtrar |
| 3 | V-1051, V-1052, V-1053 | Transformar y filtrar |
| 4 | Sin registros nuevos | Esperar o ejecutar ciclo sin nuevos datos, según configuración |

Los lotes no necesariamente contienen la misma cantidad de eventos.

Su composición depende de la disponibilidad de datos, del intervalo de activación, del progreso de la consulta y de otros parámetros de ejecución.

![Figura 68. Procesamiento continuo mediante micro-batches](imagenes/figura_68.svg)

*Figura 68. Representación conceptual. Los tamaños de lote y su periodicidad dependen de la ejecución real.*

El modelo permite aprovechar las capacidades de procesamiento distribuido de Spark sin exigir que el estudiante implemente directamente la administración de cada lote.

No obstante, introduce una consideración importante: la latencia depende también de la frecuencia de activación y del tiempo que Spark necesita para completar las operaciones.

## 2.9.4. Compatibilidad entre Kafka y Spark en nuestro laboratorio

Antes de escribir código, debemos examinar un aspecto técnico fundamental.

Nuestro laboratorio utiliza una infraestructura Docker con Kafka y una instalación de Spark 2.4.0 como referencia.

En esta versión, Structured Streaming dispone de integración con Kafka, pero requiere el conector correspondiente.

No basta con importar `pyspark` y asumir que cualquier instalación puede leer tópicos Kafka.

El conector se distribuye mediante un artefacto compatible con la versión de Spark y con la versión de Scala utilizada en su compilación.

Para una distribución estándar de Spark 2.4.0 compilada con Scala 2.11, el artefacto de referencia es:

```text
org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0
```

La parte `_2.11` corresponde a la versión binaria de Scala y `2.4.0` a la versión del conector Spark.

Este identificador no debe copiarse indiscriminadamente a cualquier instalación.

Antes de utilizarlo debemos comprobar:

- La versión efectiva de Spark.
- La versión binaria de Scala utilizada.
- La disponibilidad del conector.
- El acceso a las dependencias necesarias.
- La conectividad entre Spark y Kafka.

En una distribución estándar de Spark 2.4.0 con Scala 2.11, podemos intentar iniciar PySpark mediante:

```bash
pyspark \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0
```

El comando requiere que las dependencias puedan resolverse y que la distribución admita esa configuración.

Si el entorno no dispone de acceso a repositorios de paquetes, podría ser necesario proporcionar los archivos JAR mediante otro procedimiento.

Por tanto, este comando representa una configuración de referencia y no una ejecución verificada en los contenedores del laboratorio.

## 2.9.5. Arquitectura de ejecución: driver, ejecutores y Kafka

Cuando Spark ejecuta una consulta distribuida, debemos distinguir entre el proceso conductor (*driver*) y los ejecutores (*executors*).

El driver coordina la aplicación y la ejecución de la consulta.

Los ejecutores realizan tareas distribuidas según la configuración del entorno.

Kafka, por su parte, almacena los eventos en particiones.

La lectura de un tópico permite que Spark organice tareas de procesamiento sobre los registros disponibles.

![Figura 69. Relación conceptual entre particiones Kafka y ejecución distribuida Spark](imagenes/figura_69.svg)

*Figura 69. Representación didáctica simplificada. La planificación real de tareas depende de Spark y de su configuración.*

No debemos interpretar la figura como una garantía de que cada partición se asignará permanentemente a un ejecutor exclusivo.

La planificación de tareas depende del motor de ejecución.

Asimismo, el número de particiones influye en las posibilidades de paralelismo, pero no determina por sí solo el rendimiento final.

## 2.9.6. Lectura de un tópico Kafka mediante Structured Streaming

Comenzaremos construyendo una consulta que lea eventos desde el tópico `ventas`.

El siguiente código representa el punto de partida:

```python
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("KafkaVentasStreaming")
    .getOrCreate()
)

eventos_kafka = (
    spark.readStream
    .format("kafka")
    .option(
        "kafka.bootstrap.servers",
        "localhost:9092"
    )
    .option(
        "subscribe",
        "ventas"
    )
    .option(
        "startingOffsets",
        "earliest"
    )
    .load()
)
```

Analicemos las instrucciones.

`SparkSession` proporciona el punto de entrada a las funcionalidades estructuradas de Spark.

`readStream` indica que deseamos construir una fuente de datos de streaming.

`format("kafka")` identifica el conector.

`kafka.bootstrap.servers` establece las direcciones iniciales para comunicarse con Kafka.

`subscribe` indica el tópico que deseamos consumir.

`startingOffsets` permite definir el comportamiento inicial cuando la consulta no dispone de un estado de recuperación previo.

En este ejemplo utilizamos `earliest` para facilitar la observación de eventos históricos todavía disponibles.

Sin embargo, **esta configuración no obliga a releer todos los eventos cada vez que reiniciamos una consulta que ya dispone de un checkpoint válido**.

Cuando Spark recupera el estado de una consulta, utiliza la información correspondiente para determinar su progreso.

La dirección `localhost:9092` es solamente un ejemplo. Debe sustituirse por un listener accesible desde el proceso Spark.

## 2.9.7. Estructura de los registros recibidos desde Kafka

Cuando Structured Streaming lee un tópico Kafka, no recibe automáticamente las columnas comerciales que definimos en el productor.

En su lugar, obtiene un DataFrame con información propia del registro Kafka.

Entre los campos habituales se encuentran:

| Campo | Tipo conceptual | Significado |
|---|---|---|
| `key` | Binario | Clave del registro |
| `value` | Binario | Contenido del mensaje |
| `topic` | Texto | Tópico de origen |
| `partition` | Entero | Partición |
| `offset` | Entero largo | Posición del registro |
| `timestamp` | Marca temporal | Timestamp del registro Kafka |
| `timestampType` | Entero | Tipo de timestamp |

La información comercial está contenida en `value`, que inicialmente se presenta como dato binario.

Por tanto, necesitamos transformar ese contenido en texto y posteriormente interpretar el JSON.

Este paso es importante porque **Kafka no impone automáticamente a Spark el esquema de negocio de nuestros mensajes**.

## 2.9.8. Conversión del contenido binario a texto

Para inspeccionar el mensaje podemos seleccionar algunas columnas y convertir el valor binario a cadena.

```python
from pyspark.sql.functions import col

mensajes_texto = eventos_kafka.select(
    col("topic"),
    col("partition"),
    col("offset"),
    col("timestamp"),
    col("key").cast("string").alias(
        "clave"
    ),
    col("value").cast("string").alias(
        "mensaje_json"
    )
)
```

La operación `cast("string")` permite interpretar los bytes como texto en el formato esperado por nuestro productor.

Recordemos que en el apartado 2.7 serializamos los eventos mediante JSON y codificación UTF-8.

Por tanto, la transformación es coherente con el contrato de publicación.

El resultado conceptual sería:

| topic | partition | offset | clave | mensaje_json |
|---|---:|---:|---|---|
| ventas | 0 | 15 | C-025 | `{"id_evento":...}` |
| ventas | 1 | 21 | C-103 | `{"id_evento":...}` |

Los valores de partición y offset son ilustrativos.

En esta etapa todavía no hemos extraído las propiedades internas del JSON.

## 2.9.9. Definición explícita del esquema JSON

Structured Streaming puede trabajar con datos estructurados, pero debemos proporcionar un esquema que represente los eventos recibidos.

Nuestro productor genera mensajes con metadatos y un objeto anidado `datos`.

Podemos definir el esquema mediante los tipos de PySpark:

```python
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    IntegerType,
    LongType
)

esquema_venta = StructType([
    StructField(
        "id_evento",
        StringType(),
        True
    ),
    StructField(
        "tipo_evento",
        StringType(),
        True
    ),
    StructField(
        "version",
        IntegerType(),
        True
    ),
    StructField(
        "fecha_evento",
        StringType(),
        True
    ),
    StructField(
        "datos",
        StructType([
            StructField(
                "id_venta",
                StringType(),
                True
            ),
            StructField(
                "id_cliente",
                StringType(),
                True
            ),
            StructField(
                "monto_total",
                LongType(),
                True
            ),
            StructField(
                "moneda",
                StringType(),
                True
            ),
            StructField(
                "estado",
                StringType(),
                True
            )
        ]),
        True
    )
])
```

El esquema describe la estructura esperada del JSON.

Utilizamos `LongType` para el monto, considerando que los valores monetarios enteros podrían superar el rango de un entero de 32 bits.

Esto no significa que `LongType` sea siempre la representación más adecuada para información financiera.

En sistemas que requieren decimales exactos, debe evaluarse el uso de tipos decimales y reglas explícitas de precisión.

La elección del tipo depende del significado de los datos y del contrato de origen.

## 2.9.10. Interpretación del JSON mediante from_json

Una vez definido el esquema, podemos utilizar la función `from_json` para transformar el texto del mensaje en una estructura accesible mediante columnas.

```python
from pyspark.sql.functions import (
    col,
    from_json
)

eventos_estructurados = (
    mensajes_texto
    .withColumn(
        "evento",
        from_json(
            col("mensaje_json"),
            esquema_venta
        )
    )
)
```

La columna `evento` contendrá una estructura con los atributos definidos.

Podemos seleccionar los campos comerciales:

```python
ventas = eventos_estructurados.select(
    col("evento.id_evento").alias(
        "id_evento"
    ),
    col("evento.tipo_evento").alias(
        "tipo_evento"
    ),
    col("evento.fecha_evento").alias(
        "fecha_evento"
    ),
    col("evento.datos.id_venta").alias(
        "id_venta"
    ),
    col("evento.datos.id_cliente").alias(
        "id_cliente"
    ),
    col("evento.datos.monto_total").alias(
        "monto_total"
    ),
    col("evento.datos.moneda").alias(
        "moneda"
    ),
    col("evento.datos.estado").alias(
        "estado"
    )
)
```

De esta manera, los eventos Kafka se transforman en registros tabulares.

![Figura 70. Transformación de JSON a columnas estructuradas](imagenes/figura_70.svg)

*Figura 70. Conversión del valor binario Kafka en texto JSON y columnas de DataFrame mediante un esquema explícito.*

Debemos recordar que un mensaje JSON inválido o incompatible con el esquema puede producir campos nulos o registros que requieren tratamiento especial, según el modo de análisis configurado.

Por tanto, en una aplicación productiva es recomendable conservar información del registro original para diagnosticar problemas de transformación.

## 2.9.11. Filtrado de eventos mediante DataFrames

Una vez que disponemos de columnas estructuradas, podemos aplicar operaciones analíticas.

Por ejemplo, seleccionar únicamente las ventas confirmadas:

```python
ventas_confirmadas = ventas.filter(
    col("estado") == "confirmada"
)
```

Esta transformación se aplicará a los registros procesados por la consulta.

También podemos seleccionar transacciones cuyo monto sea superior a un determinado umbral:

```python
ventas_mayores = ventas_confirmadas.filter(
    col("monto_total") >= 50000
)
```

Las operaciones son similares a las utilizadas sobre DataFrames estáticos.

Sin embargo, en Structured Streaming se ejecutan dentro de una consulta continua y están sujetas a las restricciones del motor.

No todas las operaciones disponibles sobre DataFrames batch pueden aplicarse de la misma manera sobre un DataFrame de streaming.

## 2.9.12. Agregaciones sobre eventos de ventas

Supongamos que deseamos calcular el monto total de las ventas confirmadas por cliente.

Podemos expresar la operación mediante:

```python
from pyspark.sql.functions import sum as spark_sum

ventas_por_cliente = (
    ventas_confirmadas
    .groupBy("id_cliente")
    .agg(
        spark_sum("monto_total").alias(
            "total_ventas"
        )
    )
)
```

Esta operación es una agregación con estado.

A diferencia de un filtro, que puede procesar cada registro de manera independiente, una agregación debe mantener información acumulada entre micro-batches.

Por ejemplo, si el cliente `C-025` registra tres ventas confirmadas de $45.990, $20.000 y $34.000, el resultado acumulado será:

```text
45.990 + 20.000 + 34.000 = 99.990
```

Sin embargo, el resultado dependerá de los registros efectivamente procesados.

Si la fuente publica duplicados y no incorporamos una estrategia de deduplicación, los montos podrían contarse más de una vez.

Por ello, las garantías de entrega y la calidad de los datos afectan directamente a los indicadores analíticos.

## 2.9.13. Modos de salida de Structured Streaming

Structured Streaming permite definir cómo se entregan los resultados de una consulta.

En Spark 2.4, los modos principales son:

| Modo | Comportamiento general |
|---|---|
| Append | Entrega filas nuevas que se consideran definitivas según la operación |
| Update | Entrega filas que se actualizaron en el ciclo |
| Complete | Entrega la tabla completa de resultados en cada activación |

Estos modos no son intercambiables para todas las consultas.

Por ejemplo, una agregación acumulada por cliente puede utilizar `complete` con una salida compatible, mientras que `append` no resulta apropiado para una agregación global cuyo resultado continúa cambiando.

Además, cada destino o *sink* admite determinados modos.

Para fines docentes, utilizaremos la consola con `complete` al mostrar una agregación acumulada.

## 2.9.14. Visualización de resultados en la consola

Podemos iniciar una consulta que muestre el resultado de `ventas_por_cliente`:

```python
consulta = (
    ventas_por_cliente.writeStream
    .format("console")
    .outputMode("complete")
    .option("truncate", "false")
    .start()
)

consulta.awaitTermination()
```

La llamada `writeStream` define la salida.

`format("console")` indica que deseamos visualizar los resultados en la consola del proceso.

`outputMode("complete")` entrega la tabla completa de la agregación.

`start()` inicia la consulta.

`awaitTermination()` mantiene el programa esperando mientras la consulta continúa activa.

Una salida ilustrativa podría contener:

```text
+----------+------------+
|id_cliente|total_ventas|
+----------+------------+
|C-025     |99990       |
|C-103     |52990       |
+----------+------------+
```

Esta salida no corresponde a una ejecución verificada en el laboratorio.

El destino de consola es apropiado para aprendizaje y depuración, pero no constituye una solución de almacenamiento analítico persistente.

## 2.9.15. Checkpoints y recuperación de consultas Spark

En el apartado 2.8 estudiamos la importancia de conservar puntos de control.

Structured Streaming también utiliza checkpoints para registrar información necesaria para recuperar el progreso de determinadas consultas.

Podemos configurar una ubicación de checkpoint:

```python
consulta = (
    ventas_por_cliente.writeStream
    .format("console")
    .outputMode("complete")
    .option(
        "checkpointLocation",
        "/tmp/checkpoints/ventas_por_cliente"
    )
    .option(
        "truncate",
        "false"
    )
    .start()
)

consulta.awaitTermination()
```

En un entorno Docker, la ruta debe evaluarse cuidadosamente.

Una carpeta dentro del contenedor puede perderse si el contenedor se elimina y no existe un volumen persistente.

Además, una ruta local puede resultar inadecuada para determinados despliegues distribuidos si los componentes no comparten un almacenamiento compatible.

Por ello, en una arquitectura real debemos seleccionar una ubicación de almacenamiento confiable y accesible conforme al modo de despliegue.

También debemos considerar que no cualquier modificación a una consulta permite reutilizar su checkpoint anterior.

Cambiar esquemas, operaciones con estado o configuraciones fundamentales puede requerir una nueva consulta y un nuevo punto de control.

## 2.9.16. Ventanas temporales y análisis de eventos

Una de las capacidades relevantes de Structured Streaming consiste en realizar agregaciones por ventanas temporales.

En lugar de calcular únicamente un total acumulado, podríamos necesitar conocer las ventas registradas en intervalos de cinco minutos.

Para ello debemos transformar la fecha del evento en un tipo temporal.

```python
from pyspark.sql.functions import (
    col,
    to_timestamp
)

ventas_con_tiempo = ventas.withColumn(
    "tiempo_evento",
    to_timestamp(
        col("fecha_evento")
    )
)
```

Posteriormente podemos definir una agregación por ventana:

```python
from pyspark.sql.functions import (
    window,
    sum as spark_sum
)

ventas_por_ventana = (
    ventas_con_tiempo
    .filter(
        col("estado") == "confirmada"
    )
    .groupBy(
        window(
            col("tiempo_evento"),
            "5 minutes"
        )
    )
    .agg(
        spark_sum("monto_total").alias(
            "total_ventas"
        )
    )
)
```

Esta consulta agrupa las ventas confirmadas según ventanas de cinco minutos.

Debemos recordar que `fecha_evento` representa el momento declarado por el productor, no necesariamente el momento en que Spark recibió el registro.

La interpretación correcta de las marcas temporales es fundamental cuando analizamos eventos que pueden llegar con retraso.

Además, el tratamiento de zonas horarias debe revisarse cuidadosamente: Spark interpreta y presenta timestamps según la configuración de la sesión y las funciones utilizadas.

## 2.9.17. Watermarks y eventos atrasados

En sistemas distribuidos, los eventos no siempre llegan en el mismo orden en que ocurrieron.

Una transacción realizada a las 11:00 podría llegar a Kafka después de otra registrada a las 11:02.

Las causas pueden incluir interrupciones de conectividad, reintentos o demoras en la fuente.

Structured Streaming permite utilizar *watermarks* para administrar el estado de determinadas operaciones temporales y establecer una tolerancia a datos atrasados.

Por ejemplo:

```python
ventas_con_watermark = (
    ventas_con_tiempo
    .withWatermark(
        "tiempo_evento",
        "10 minutes"
    )
)
```

La configuración expresa una tolerancia de diez minutos respecto del progreso temporal observado por la consulta.

No significa que Spark espere exactamente diez minutos antes de procesar cada evento.

Tampoco significa que todos los registros que lleguen dentro de ese intervalo estén garantizados bajo cualquier circunstancia.

El comportamiento depende de la operación y del avance del watermark.

![Figura 71. Ventanas temporales y llegada tardía de eventos](imagenes/figura_71.svg)

*Figura 71. La figura ilustra la llegada tardía; el comportamiento de descarte depende del watermark y de la consulta.*

Los watermarks resultan especialmente relevantes cuando se utilizan ventanas y agregaciones que deben administrar su estado a lo largo del tiempo.

## 2.9.18. Consideraciones de rendimiento y paralelismo

La integración entre Kafka y Spark ofrece oportunidades de procesamiento distribuido, pero requiere una configuración coherente.

Entre los factores relevantes encontramos:

**Número de particiones Kafka.** Influye en las unidades de trabajo disponibles para la lectura.

**Recursos de Spark.** La cantidad de ejecutores, núcleos y memoria condiciona la capacidad de procesamiento.

**Complejidad de las transformaciones.** Un filtro simple no tiene el mismo costo que una agregación con estado.

**Volumen de eventos.** Las tasas de llegada pueden superar la capacidad de procesamiento.

**Frecuencia de micro-batches.** Una activación muy frecuente puede aumentar la sobrecarga operativa; una activación más espaciada puede incrementar la latencia.

**Estado acumulado.** Las consultas con agrupaciones y ventanas pueden necesitar conservar información entre lotes.

Estos factores deben analizarse conjuntamente.

Aumentar el número de particiones no garantiza automáticamente un mayor rendimiento.

De manera similar, incorporar más ejecutores no elimina los problemas de una fuente lenta o de una transformación ineficiente.

## 2.9.19. Validación de la integración en el laboratorio

Para comprobar el funcionamiento de la arquitectura proponemos una secuencia de validación.

Primero, verificaremos que Kafka se encuentre disponible y que el tópico `ventas` exista.

Luego ejecutaremos el productor Python desarrollado en el apartado 2.7.

Posteriormente iniciaremos la aplicación Spark Structured Streaming y comprobaremos que puede leer los eventos.

Finalmente, evaluaremos las transformaciones y los resultados analíticos.

| Validación | Evidencia esperada |
|---|---|
| Kafka disponible | Broker accesible |
| Tópico existente | `ventas` disponible |
| Productor operativo | Eventos publicados |
| Conector Spark-Kafka | Fuente de streaming creada sin errores |
| Lectura de mensajes | Registros Kafka recibidos |
| Interpretación JSON | Campos comerciales extraídos |
| Filtrado | Ventas confirmadas seleccionadas |
| Agregación | Total por cliente actualizado |
| Checkpoint | Estado de consulta registrado |

La validación debe realizarse progresivamente.

Si Spark no logra conectarse a Kafka, debemos revisar la conectividad y las dependencias antes de atribuir el error a la transformación JSON.

Si la lectura funciona, pero los campos aparecen nulos, debemos revisar el esquema y el contenido real de los mensajes.

Esta separación facilita el diagnóstico.

## 2.9.20. Actividad práctica: procesamiento de ventas en streaming

La actividad propuesta consiste en integrar el productor Python del apartado 2.7 con Spark Structured Streaming.

El estudiante deberá implementar una consulta que lea el tópico `ventas`, interprete el contenido JSON y seleccione las transacciones confirmadas.

Posteriormente calculará el monto acumulado por cliente y visualizará los resultados mediante la consola.

Como extensión, podrá incorporar una agregación por ventanas de cinco minutos y analizar el efecto de las marcas temporales.

| Etapa | Desarrollo | Evidencia |
|---|---|---|
| 1 | Conectar Spark con Kafka | Fuente de streaming operativa |
| 2 | Interpretar JSON | Esquema aplicado correctamente |
| 3 | Filtrar ventas | Registros confirmados |
| 4 | Agregar por cliente | Totales acumulados |
| 5 | Configurar checkpoint | Ruta de recuperación |
| 6 | Analizar ventanas | Resultados agrupados temporalmente |

La actividad debe acompañarse de una reflexión técnica.

Los estudiantes deberán explicar por qué Kafka y Spark cumplen funciones diferentes, cómo Structured Streaming organiza el procesamiento y qué limitaciones presenta una agregación cuando los eventos pueden llegar duplicados o atrasados.

## 2.9.21. Síntesis del apartado

En este apartado incorporamos Apache Spark Structured Streaming a la arquitectura de integración basada en Kafka.

Explicamos cómo Spark permite transformar y analizar eventos mediante DataFrames, utilizando un modelo de micro-batches en la versión 2.4 del laboratorio.

Analizamos la compatibilidad del conector Spark-Kafka, la estructura de los registros recibidos, la conversión del contenido binario a texto y la interpretación de mensajes JSON mediante esquemas explícitos.

Posteriormente estudiamos filtros, agregaciones, modos de salida y checkpoints.

También introdujimos las ventanas temporales, los watermarks y las consideraciones de rendimiento asociadas al procesamiento distribuido.

Finalmente, propusimos una actividad práctica que integra el productor Python, Kafka y Spark Structured Streaming.

En el siguiente apartado, **2.10. Validación, monitoreo y tratamiento básico de errores**, consolidaremos los procedimientos necesarios para verificar el funcionamiento de toda la arquitectura, identificar problemas operacionales y documentar evidencias de ejecución.

---

**Observación técnica:** los ejemplos toman como referencia Spark 2.4.0 y su conector Kafka 0.10, pero no han sido ejecutados contra los contenedores reales del laboratorio. La compatibilidad de Scala, las dependencias y los listeners Kafka deberá comprobarse durante la validación práctica.
