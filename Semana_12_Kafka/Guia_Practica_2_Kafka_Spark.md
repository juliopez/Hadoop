# Guía práctica 2 — Procesamiento Near Real-Time de sismos con USGS, Apache Kafka y Spark

**Tema:** Kafka y Spark Structured Streaming · **Dificultad:** intermedia-alta · **Caso:** datos reales de sismos del USGS.

## Propósito y resultados de aprendizaje

Construir, ejecutar e interpretar un flujo de eventos cercano al tiempo real (**Near Real-Time, NRT**):

**API REST USGS → productor Python → tópico Kafka `sismos_usgs` → Spark Structured Streaming → resultados filtrados.**

Al finalizar, se podrá explicar la diferencia entre consultar una API y transmitir eventos; reconocer tópico, partición y offset; interpretar micro-lotes de Spark; aplicar un esquema explícito y un filtro de magnitud; y describir qué información conserva un checkpoint y qué limitaciones tiene.

> **Importante:** USGS publica información que cambia con el tiempo. La cantidad de eventos, sus identificadores, magnitudes y offsets no tienen por qué coincidir con los ejemplos mostrados. Un micro-lote vacío no significa necesariamente un error.

## Antes de comenzar

La práctica utiliza como referencia la infraestructura Docker Compose de este repositorio, que puede ejecutarse localmente o en un servidor remoto. Los comandos Docker requieren permisos adecuados; la necesidad de `sudo` depende de cada instalación. Antes de comenzar, completar la [Guía 0](Guia_0_Preparacion_Entorno_Kafka_Spark.md). Las siguientes condiciones deben estar disponibles antes de comenzar:

- Kafka 3.9.0 en modo ZooKeeper en el despliegue de referencia, accesible desde Python del anfitrión y desde Spark; tópico `sismos_usgs` existente, con **3 particiones**. En esta configuración, Spark utiliza `kafka:9092`; la conexión desde el anfitrión debe utilizar una dirección anunciada por el broker y accesible desde ese equipo.
- Contenedor Docker `spark-master` con `/spark/bin/spark-submit`, **Spark 2.4.0, Scala 2.11 y Java 8**. Conector requerido: `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`. Sus dependencias deben estar precargadas o disponibles desde Maven Central.
- Python del anfitrión con `requests` y `kafka-python`, preferiblemente en un entorno virtual. En la configuración de referencia, el productor se ejecuta en el anfitrión Linux y el script Spark dentro del contenedor.
- Se utilizan los archivos `productor_usgs.py` y `sismos_checkpoint.py`, cuyos códigos se incluyen en esta guía. Pueden entregarse preparados para concentrar el trabajo en su ejecución e interpretación.
- **Checkpoint:** `/tmp/checkpoint_sismos_usgs` dentro de `spark-master` sirve para la demostración y persiste entre ejecuciones mientras el contenedor y su sistema de archivos se conserven. **No es durable ante la recreación del contenedor**. Para conservar el checkpoint entre recreaciones del contenedor, es necesario utilizar un volumen persistente.
- Si varias personas trabajan simultáneamente en un broker compartido, cada instancia de trabajo debe utilizar un tópico y un checkpoint independientes, según la configuración elegida.

## Ejercicio 1 — Consultar la API real del USGS

**Objetivo:** reconocer el origen REST y el formato GeoJSON antes de transmitir eventos.

En el equipo anfitrión, ejecutar:

```bash
python - <<'PY'
import requests

url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
respuesta = requests.get(url, timeout=20)
respuesta.raise_for_status()
datos = respuesta.json()
eventos = datos.get("features", [])

print("HTTP:", respuesta.status_code)
print("Sismos disponibles:", len(eventos))
for e in eventos[:3]:
    p = e.get("properties") or {}
    print("ID:", e.get("id"), "| Magnitud:", p.get("mag"),
          "| Ubicación:", p.get("place"))
PY
```

**Consignas:** (a) registrar el código HTTP y la cantidad de eventos; (b) identificar la función de `features`, `properties` y `geometry`; (c) explicar por qué una respuesta REST es una **instantánea** y no, por sí misma, un flujo de eventos. Si el feed contiene cero sismos, registrar ese resultado: es válido y no se deben inventar eventos.

## Ejercicio 2 — Publicar eventos sísmicos en Kafka

**Objetivo:** transformar registros GeoJSON en mensajes JSON y observar la confirmación de publicación.

Guardar el siguiente código como `productor_usgs.py` en el anfitrión, o utilizar el archivo facilitado para la actividad:

```python
import json
import os
import requests
from kafka import KafkaProducer

URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
BROKER = os.getenv("KAFKA_BOOTSTRAP_HOST", "localhost:9092")
TOPICO = os.getenv("KAFKA_TOPIC", "sismos_usgs")

def main():
    respuesta = requests.get(URL, timeout=20)
    respuesta.raise_for_status()
    eventos = respuesta.json().get("features", [])
    print("Sismos obtenidos desde USGS:", len(eventos))

    productor = KafkaProducer(
        bootstrap_servers=BROKER,
        key_serializer=lambda clave: clave.encode("utf-8"),
        value_serializer=lambda valor: json.dumps(
            valor, ensure_ascii=False
        ).encode("utf-8"),
        acks="all"
    )
    publicados = 0
    try:
        for item in eventos:
            propiedades = item.get("properties") or {}
            coordenadas = (item.get("geometry") or {}).get("coordinates") or []
            identificador = item.get("id")
            if not identificador or len(coordenadas) < 3:
                continue
            magnitud = propiedades.get("mag")
            if magnitud is None:
                continue
            registro = {
                "id_evento": str(identificador),
                "magnitud": float(magnitud),
                "ubicacion": propiedades.get("place"),
                "fecha_evento": propiedades.get("time"),
                "longitud": coordenadas[0],
                "latitud": coordenadas[1],
                "profundidad_km": coordenadas[2]
            }
            confirmacion = productor.send(
                TOPICO, key=registro["id_evento"], value=registro
            ).get(timeout=20)
            publicados += 1
            print(
                "Publicado:", registro["id_evento"],
                "| magnitud=", registro["magnitud"],
                "| particion=", confirmacion.partition,
                "| offset=", confirmacion.offset
            )
    finally:
        productor.flush()
        productor.close()
    print("Publicación finalizada. Total:", publicados)

if __name__ == "__main__":
    main()
```

Ejecutar desde el entorno Python preparado:

```bash
python productor_usgs.py
```

**Consignas:** (a) registrar la cantidad de eventos publicados y un par **partición/offset**; (b) explicar qué significa que Kafka confirme una publicación; (c) explicar por qué volver a ejecutar el productor con el mismo feed puede producir **mensajes repetidos**, aunque cada mensaje conserve el mismo `id_evento`.

> El ID se utiliza como clave Kafka; esto ayuda a mantener la afinidad de una clave con una partición, pero **no deduplica automáticamente** mensajes. La cantidad publicada puede ser inferior al número de elementos del feed cuando faltan campos esenciales.

## Ejercicio 3 — Verificar mensajes y offsets en Kafka

**Objetivo:** comprobar que los eventos existen en el tópico independientemente del productor.

Desde el equipo anfitrión, ejecutar:

```bash
docker exec kafka bash -lc '
kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic sismos_usgs \
  --from-beginning \
  --max-messages 5
'
```

El comando supone que el contenedor se llama `kafka` y dispone de `kafka-console-consumer` en el PATH. Adaptar los nombres y rutas a cada instalación.

**Consignas:** (a) localizar al menos un mensaje con `id_evento`, `magnitud` y `ubicacion`; (b) contrastar su ID con el productor; (c) explicar por qué los offsets son **por partición** y no un contador global del tópico. Para identificar partición y offset utilizar la confirmación impresa en el ejercicio 2; el consumidor de consola mostrado aquí imprime el contenido, no esos metadatos.

## Ejercicio 4 — Transformar y filtrar sismos con Spark Structured Streaming

**Objetivo:** interpretar el JSON con un esquema explícito y visualizar eventos de **magnitud ≥ 2.0**.

El siguiente código corresponde al archivo `sismos_checkpoint.py`, disponible en el contenedor `spark-master`:

```python
import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json
from pyspark.sql.types import (
    StructType, StructField, StringType, DoubleType, LongType
)

BROKER = os.getenv("KAFKA_BOOTSTRAP_SPARK", "kafka:9092")
TOPICO = os.getenv("KAFKA_TOPIC", "sismos_usgs")
CHECKPOINT = os.getenv(
    "SPARK_CHECKPOINT", "/tmp/checkpoint_sismos_usgs"
)

spark = (SparkSession.builder
    .master("local[1]")
    .appName("USGS_Procesamiento_NRT")
    .getOrCreate())
spark.sparkContext.setLogLevel("ERROR")

esquema = StructType([
    StructField("id_evento", StringType()),
    StructField("magnitud", DoubleType()),
    StructField("ubicacion", StringType()),
    StructField("fecha_evento", LongType()),
    StructField("longitud", DoubleType()),
    StructField("latitud", DoubleType()),
    StructField("profundidad_km", DoubleType())
])

entrada = (spark.readStream
    .format("kafka")
    .option("kafka.bootstrap.servers", BROKER)
    .option("subscribe", TOPICO)
    .option("startingOffsets", "earliest")
    .load())

sismos = (entrada
    .select(from_json(col("value").cast("string"), esquema).alias("sismo"))
    .select("sismo.*"))

filtrados = sismos.filter(col("magnitud") >= 2.0)

consulta = (filtrados.writeStream
    .format("console")
    .outputMode("append")
    .option("truncate", "false")
    .option("checkpointLocation", CHECKPOINT)
    .start())

try:
    consulta.awaitTermination()
finally:
    if consulta.isActive:
        consulta.stop()
    spark.stop()
```

Ejecutar desde el equipo anfitrión:

```bash
docker exec spark-master bash -lc '
/spark/bin/spark-submit \
  --master "local[1]" \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0 \
  /tmp/sismos_checkpoint.py
'
```

Mientras Spark continúa ejecutándose, volver a ejecutar el productor del ejercicio 2 en **otra terminal**. Observar las tablas `Batch: 0`, `Batch: 1`, etc. Detener Spark con **Ctrl+C** al terminar la observación.

**Consignas:** (a) identificar dos eventos que cumplan `magnitud >= 2.0`, si existen; (b) explicar la función de `from_json` y del esquema; (c) interpretar por qué algunos micro-lotes están vacíos; (d) justificar por qué el flujo es NRT y no una respuesta REST aislada.

> La API USGS puede devolver los mismos sismos en consultas sucesivas. La aparición de un mensaje en un micro-lote nuevo **no implica necesariamente un terremoto recién ocurrido**: puede ser una nueva publicación Kafka de un evento ya conocido.

## Ejercicio 5 — Checkpoints, continuidad y límites de recuperación

**Objetivo:** observar el registro de progreso y distinguirlo de la deduplicación.

Tras ejecutar Spark, inspeccionar dentro del contenedor:

```bash
docker exec spark-master bash -lc '
echo "=== CHECKPOINT ==="
ls -lah /tmp/checkpoint_sismos_usgs
echo "=== OFFSETS ==="
ls -lah /tmp/checkpoint_sismos_usgs/offsets
echo "=== COMMITS ==="
ls -lah /tmp/checkpoint_sismos_usgs/commits
'
```

**Consignas:** (a) identificar los directorios `offsets` y `commits` y describir su propósito; (b) explicar por qué, cuando se reinicia una consulta compatible con **el mismo checkpoint válido**, Spark utiliza el progreso guardado en lugar de aplicar `startingOffsets="earliest"` como si fuera la primera ejecución; (c) distinguir **recuperación de offsets** de **eliminación de eventos duplicados**; (d) explicar qué ocurriría si el checkpoint estuviera solamente en `/tmp` de un contenedor que luego se recrea.

**Actividad de profundización (opcional):** reiniciar el mismo script con el mismo checkpoint, publicar nuevos mensajes y comparar los micro-lotes observados. Registrar el resultado efectivo de la ejecución, sin asumir de antemano que todos los eventos serán únicos.

## Evidencias de entrega

Entregar **un único archivo breve**, con cinco evidencias numeradas:

1. Código HTTP, cantidad de eventos y explicación de la estructura GeoJSON.
2. Total publicado y un ejemplo de partición/offset.
3. Un mensaje JSON observado en Kafka y explicación del offset por partición.
4. Una salida de micro-lote de Spark, interpretación del filtro y de un lote vacío.
5. Evidencia de los directorios de checkpoint y explicación de recuperación versus duplicados.

Si el feed no contiene eventos de magnitud ≥ 2.0 durante la sesión, registrar la ausencia y explicar qué condición impidió observarlos. El análisis debe basarse en los resultados efectivamente observados.

**Criterio de logro:** se interpreta correctamente el flujo API → Kafka → Spark, identifica sus metadatos y reconoce las limitaciones de la entrega NRT y del checkpoint.
