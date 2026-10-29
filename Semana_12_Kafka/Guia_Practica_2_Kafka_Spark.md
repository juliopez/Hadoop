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


---

## Registro de validación docente — 29 de octubre de 2026 (en desarrollo)

> **Estado:** pruebas en entorno Hadoop del docente; esta sección documenta hallazgos y no sustituye todavía los cinco ejercicios de la versión publicada. El flujo USGS es un caso real alternativo al caso de ventas, pendiente de integración editorial definitiva.

**Validado:** consulta a la API pública USGS (feed `all_hour.geojson`); creación del tópico `sismos_usgs` con tres particiones y factor de replicación 1; publicación desde Python de cuatro eventos sísmicos JSON, con confirmación de partición y offset; lectura de los mismos cuatro eventos desde `KafkaConsumer`, con recuperación de ID, magnitud, partición y offset. La cantidad de eventos depende del momento de consulta. Se verificó que el orden global de lectura puede diferir entre particiones.

**Incidencia de conectividad resuelta solo en el entorno docente:** el broker Kafka anunció `505b7c6c3bcb:9092` (ID 101). Aunque el puerto 9092 era accesible por TCP, el cliente Python no podía resolver ese nombre al consultar metadatos. Una entrada local en `/etc/hosts` que vinculó ese nombre con `172.27.1.16` permitió recuperar 93 tópicos y publicar/consumir eventos. **No utilizar esta entrada como instrucción para estudiantes:** IP y nombre del contenedor son variables; se requiere una configuración reproducible de `advertised.listeners` y DNS/listeners adecuados antes de distribuir la guía.

**Entorno Python:** `kafka-python` se instaló en un entorno virtual independiente `~/kafka_usgs/.venv`, fuera de la carpeta del repositorio Hadoop por restricciones locales de permisos. El productor y consumidor funcionaron, aunque aparecieron advertencias `DeprecationWarning` relacionadas con `key_serializer`, `value_serializer` y `value_deserializer`. Revisar versión de biblioteca y serialización antes de cerrar la guía; no confundir estas advertencias con errores de publicación.

**Spark pendiente:** contenedores `spark-master` y `spark-worker` activos; `spark-submit` localizado en `/spark/bin/spark-submit` (no en el `PATH` de la sesión de prueba). Se confirmó Spark **2.4.0**, Scala **2.11.12** y Java **8**. No se encontró `spark-sql-kafka-0-10` ni `kafka-clients` en `/spark/jars`. Candidato de conector compatible: `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`; aún no instalado ni probado. La prueba de conectividad a Maven Central **no se ejecutó** porque el `python` del contenedor rechazó `import urllib.request` (`ImportError: No module named request`), compatible con un intérprete Python 2; comprobar la versión antes de repetirla. **No se ha validado aún Spark Structured Streaming ni checkpoints.**

**Criterio editorial:** mantener cinco ejercicios y 60 minutos. Antes de cerrar la versión para estudiantes, decidir si se reemplaza el ejemplo local de ventas por USGS; entregar scripts listos para ejecutar y preconfigurar conectores y listeners, sin trasladar la depuración de infraestructura al estudiante.

**Decisión editorial posterior (29-10-2026):** el docente confirma que la versión final de los cinco ejercicios debe utilizar la API real de sismos USGS para un flujo NRT, no la API ficticia de ventas. La sustitución completa de las consignas y scripts está pendiente de la validación Spark–Kafka. La prueba `spark-submit --packages ... --version` solo confirmó versiones, y la búsqueda de JARs del conector en `/root/.ivy2` y `/root/.m2` no encontró archivos.
