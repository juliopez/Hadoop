# Guía práctica 2. Flujo Near Real-Time con API REST, Kafka y Spark

**Asignatura:** Big Data · **Duración:** 60 minutos · **Dificultad:** intermedia-alta · **Modalidad:** trabajo en parejas

## Propósito
Verificar un flujo de adquisición y procesamiento de eventos: **API REST → productor Python → tópico Kafka → Spark Structured Streaming**.

**Requisitos previos:** haber completado la Guía 1; Kafka y ZooKeeper activos; Python con `requests` y `kafka-python`; API local y scripts de ejemplo del apartado 2.7 del [libro](Apache_Kafka_Obra_Consolidada_Revision.md); Spark disponible con conector Kafka compatible. Para Spark 2.4.0 / Scala 2.11, el libro identifica `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`. **No se presupone que el laboratorio esté ya configurado**: verificar las versiones y listeners antes de comenzar. El docente debe facilitar los scripts `api_demo.py` y `productor.py` desarrollados en el libro, así como el siguiente archivo `stream_ventas.py`; el tiempo de 60 minutos contempla su ejecución y análisis, no su escritura desde cero.

## Ejercicio 1 — Comprobar la fuente y la infraestructura (10 min)
En el anfitrión, verifique `docker ps` y ejecute en un terminal:
```bash
python api_demo.py
```
En otro terminal:
```bash
curl http://127.0.0.1:5000/api/ventas
```
**Consigna:** compruebe que la API responde JSON y localice el arreglo `ventas`. Identifique dos atributos de una venta. Si el servicio utiliza otra dirección o puerto, registre el valor real.

## Ejercicio 2 — Publicar eventos desde la API (15 min)
Con la API disponible, ejecute:
```bash
python productor.py
```
Use el productor del apartado 2.7, que transforma cada venta en un evento y publica en el tópico `ventas`. **Consigna:** registre la cantidad de publicaciones confirmadas y un par partición/offset. Explique la diferencia entre consultar una API y publicar un evento. Si se vuelve a ejecutar el productor con los mismos registros, explique el riesgo de duplicación.

## Ejercicio 3 — Validar el flujo en Kafka (10 min)
Dentro del contenedor Kafka:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ventas --from-beginning --max-messages 5
```
**Consigna:** identifique al menos un evento JSON procedente del productor Python. Si el tópico contiene datos de ejercicios anteriores, distinga sus formatos; no atribuya al productor registros que no se hayan verificado.

## Ejercicio 4 — Analizar eventos con Spark Structured Streaming (15 min)
El docente facilitará `stream_ventas.py` con este código base. Ajuste `KAFKA_BOOTSTRAP` a un listener accesible **desde el proceso Spark** y `CHECKPOINT` a una carpeta persistente y escribible.
```python
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json
from pyspark.sql.types import StructType, StructField, StringType, LongType

spark = SparkSession.builder.appName("GuiaKafkaVentas").getOrCreate()
bootstrap = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
checkpoint = os.getenv("CHECKPOINT", "/tmp/checkpoint-guia-kafka-ventas")

datos = StructType([
    StructField("id_venta", StringType()),
    StructField("id_cliente", StringType()),
    StructField("monto_total", LongType()),
    StructField("moneda", StringType()),
    StructField("estado", StringType())
])
evento = StructType([
    StructField("id_evento", StringType()),
    StructField("tipo_evento", StringType()),
    StructField("version", StringType()),
    StructField("fecha_evento", StringType()),
    StructField("datos", datos)
])

entrada = (spark.readStream.format("kafka")
    .option("kafka.bootstrap.servers", bootstrap)
    .option("subscribe", "ventas")
    .option("startingOffsets", "earliest")
    .load())
ventas = (entrada.select(from_json(col("value").cast("string"), evento).alias("e"))
    .select("e.id_evento", "e.datos.id_venta", "e.datos.monto_total")
    .where(col("id_venta").isNotNull()))
consulta = (ventas.writeStream.format("console")
    .outputMode("append")
    .option("checkpointLocation", checkpoint)
    .start())
consulta.awaitTermination()
```
Ejecute con `spark-submit` y el conector adecuado. Ejemplo **solo para Spark 2.4.0 / Scala 2.11**:
```bash
spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0 stream_ventas.py
```
**Consigna:** identifique `id_venta` y `monto_total` en la salida. El esquema corresponde al productor del libro; mensajes de texto libre y otros JSON pueden ser descartados por el filtro. El proceso continuará hasta detenerlo con Ctrl+C.

## Ejercicio 5 — Observar checkpoints y recuperación (10 min)
Detenga Spark con Ctrl+C, compruebe que la carpeta de checkpoint se haya creado y reinicie **con el mismo directorio**. Publique nuevamente desde el productor y observe los registros procesados.

**Consigna:** explique qué función cumple el checkpoint y por qué `startingOffsets="earliest"` no obliga a releer todos los registros cuando existe un checkpoint válido. Distinga recuperación del progreso de consumo de deduplicación: **el checkpoint no elimina por sí solo eventos duplicados publicados por el productor**.

## Evidencias de entrega
Un único archivo breve con: (1) respuesta de la API; (2) confirmación de publicación; (3) registro observado en Kafka; (4) salida de Spark con una venta; (5) explicación de checkpoint y duplicados. **No se requiere informe extenso.**

**Criterio de logro:** el estudiante verifica el flujo de extremo a extremo, interpreta sus resultados y distingue el avance del consumidor de la unicidad de los eventos.

**Nota docente:** la guía requiere una preparación previa del entorno y dependencias. Si Spark no dispone del conector o la red entre contenedores no permite alcanzar Kafka, no debe atribuirse ese problema a la comprensión conceptual del estudiante.
