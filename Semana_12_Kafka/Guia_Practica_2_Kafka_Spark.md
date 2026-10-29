# Guía práctica 2 — Procesamiento Near Real-Time de sismos con USGS, Apache Kafka y Spark

**Asignatura:** Big Data · **Duración estimada:** 60 minutos · **Dificultad:** intermedia-alta · **Modalidad:** parejas · **Caso:** datos reales de sismos del USGS.

## Propósito y resultados de aprendizaje

Construir, ejecutar e interpretar un flujo de eventos cercano al tiempo real (**Near Real-Time, NRT**):

**API REST USGS → productor Python → tópico Kafka `sismos_usgs` → Spark Structured Streaming → resultados filtrados.**

Al terminar, cada pareja podrá explicar la diferencia entre consultar una API y transmitir eventos; reconocer tópico, partición y offset; interpretar micro-lotes de Spark; aplicar un esquema explícito y un filtro de magnitud; y describir qué información conserva un checkpoint y qué limitaciones tiene.

> **Importante:** USGS publica información que cambia con el tiempo. La cantidad de eventos, sus identificadores, magnitudes y offsets no tienen por qué coincidir con las capturas del docente. Un micro-lote vacío no significa necesariamente un error.

## Preparación del laboratorio — responsabilidad docente, antes de los 60 minutos

El docente debe entregar un entorno operativo, sin exigir que los estudiantes resuelvan problemas de DNS, listeners o descarga de dependencias durante la actividad.

- Kafka accesible desde Python del anfitrión y desde Spark; tópico `sismos_usgs` existente, con **3 particiones**. En el entorno probado, Spark utiliza `kafka:9092`; la dirección accesible desde Ubuntu debe ser configurada por el docente, sin copiar direcciones IP o nombres efímeros de contenedores.
- Contenedor Docker `spark-master` con `/spark/bin/spark-submit`, **Spark 2.4.0, Scala 2.11 y Java 8**. Conector comprobado: `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`. Sus dependencias deben estar precargadas o disponibles desde Maven Central.
- Python del anfitrión con `requests` y `kafka-python`, preferiblemente en un entorno virtual. El productor se ejecuta en Ubuntu; el script Spark se ejecuta dentro del contenedor.
- Los archivos `productor_usgs.py` y `sismos_checkpoint.py` deben distribuirse ya preparados. Se incluyen sus versiones de referencia más abajo; no se espera que el estudiante escriba ambos desde cero.
- **Checkpoint:** `/tmp/checkpoint_sismos_usgs` dentro de `spark-master` sirve para la demostración y persiste entre ejecuciones mientras el contenedor y su sistema de archivos se conserven. **No es durable ante la recreación del contenedor**. Para un laboratorio reproducible de varios días, montar un volumen persistente y definir una ruta por pareja.
- Para evitar interferencias entre parejas, cada grupo debe disponer de un tópico y checkpoint propios, o realizar la actividad por turnos. Si se usan nombres distintos, actualizar la configuración de ambos scripts.

## Ejercicio 1 — Consultar la API real del USGS (10 minutos)

**Objetivo:** reconocer el origen REST y el formato GeoJSON antes de transmitir eventos.

En Ubuntu, ejecutar:

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

## Ejercicio 2 — Publicar eventos sísmicos en Kafka (15 minutos)

**Objetivo:** transformar registros GeoJSON en mensajes JSON y observar la confirmación de publicación.

Guardar como `productor_usgs.py` en Ubuntu, o utilizar el archivo previamente entregado por el docente:

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

## Ejercicio 3 — Verificar mensajes y offsets en Kafka (10 minutos)

**Objetivo:** comprobar que los eventos existen en el tópico independientemente del productor.

Desde Ubuntu, ejecutar (ajustar el nombre del contenedor Kafka si es distinto):

```bash
sudo docker exec kafka bash -lc '
kafka-console-consumer   --bootstrap-server kafka:9092   --topic sismos_usgs   --from-beginning   --max-messages 5
'
```

**Si el ejecutable no está en el PATH**, el docente facilitará su ruta real dentro del contenedor. El nombre `kafka` del ejemplo es una referencia de laboratorio y debe corresponder al contenedor efectivo.

**Consignas:** (a) localizar al menos un mensaje con `id_evento`, `magnitud` y `ubicacion`; (b) contrastar su ID con el productor; (c) explicar por qué los offsets son **por partición** y no un contador global del tópico. Para identificar partición y offset utilizar la confirmación impresa en el ejercicio 2; el consumidor de consola mostrado aquí imprime el contenido, no esos metadatos.

## Ejercicio 4 — Transformar y filtrar sismos con Spark Structured Streaming (15 minutos)

**Objetivo:** interpretar el JSON con un esquema explícito y visualizar eventos de **magnitud ≥ 2.0**.

El docente entrega el siguiente archivo `sismos_checkpoint.py` dentro del contenedor `spark-master`:

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

Ejecutar desde Ubuntu:

```bash
sudo docker exec spark-master bash -lc '
/spark/bin/spark-submit   --master "local[1]"   --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0   /tmp/sismos_checkpoint.py
'
```

Mientras Spark continúa ejecutándose, volver a ejecutar el productor del ejercicio 2 en **otra terminal**. Observar las tablas `Batch: 0`, `Batch: 1`, etc. Detener Spark con **Ctrl+C** al terminar la observación.

**Consignas:** (a) identificar dos eventos que cumplan `magnitud >= 2.0`, si existen; (b) explicar la función de `from_json` y del esquema; (c) interpretar por qué algunos micro-lotes están vacíos; (d) justificar por qué el flujo es NRT y no una respuesta REST aislada.

> La API USGS puede devolver los mismos sismos en consultas sucesivas. La aparición de un mensaje en un micro-lote nuevo **no implica necesariamente un terremoto recién ocurrido**: puede ser una nueva publicación Kafka de un evento ya conocido.

## Ejercicio 5 — Checkpoints, continuidad y límites de recuperación (10 minutos)

**Objetivo:** observar el registro de progreso y distinguirlo de la deduplicación.

Tras ejecutar Spark, inspeccionar dentro del contenedor:

```bash
sudo docker exec spark-master bash -lc '
echo "=== CHECKPOINT ==="
ls -lah /tmp/checkpoint_sismos_usgs
echo "=== OFFSETS ==="
ls -lah /tmp/checkpoint_sismos_usgs/offsets
echo "=== COMMITS ==="
ls -lah /tmp/checkpoint_sismos_usgs/commits
'
```

**Consignas:** (a) identificar los directorios `offsets` y `commits` y describir su propósito; (b) explicar por qué, cuando se reinicia una consulta compatible con **el mismo checkpoint válido**, Spark utiliza el progreso guardado en lugar de aplicar `startingOffsets="earliest"` como si fuera la primera ejecución; (c) distinguir **recuperación de offsets** de **eliminación de eventos duplicados**; (d) explicar qué ocurriría si el checkpoint estuviera solamente en `/tmp` de un contenedor que luego se recrea.

**Actividad opcional, solo si el docente dispone de tiempo:** reiniciar el mismo script con el mismo checkpoint, publicar nuevos mensajes y observar su avance. Esta recuperación tras reinicio **no forma parte de las pruebas docentes previamente confirmadas** y no debe presentarse como un resultado ya observado.

## Evidencias de entrega

Entregar **un único archivo breve**, con cinco evidencias numeradas:

1. Código HTTP, cantidad de eventos y explicación de la estructura GeoJSON.
2. Total publicado y un ejemplo de partición/offset.
3. Un mensaje JSON observado en Kafka y explicación del offset por partición.
4. Una salida de micro-lote de Spark, interpretación del filtro y de un lote vacío.
5. Evidencia de los directorios de checkpoint y explicación de recuperación versus duplicados.

Si el feed no contiene eventos de magnitud ≥ 2.0 durante la sesión, registrar la ausencia y explicar qué condición impidió observarlos. **No fabricar datos ni modificar resultados para simular una prueba exitosa.**

**Criterio de logro:** el estudiante interpreta correctamente el flujo API → Kafka → Spark, identifica sus metadatos y reconoce las limitaciones de la entrega NRT y del checkpoint.

## Nota de implementación y trazabilidad docente

Esta guía sustituye el caso ficticio de ventas por el caso **USGS**, aprobado por el docente el 29-10-2026. Las pruebas ya efectuadas confirman: acceso HTTP a USGS; publicación y consumo Kafka; resolución del conector Spark 2.4.0; lectura Structured Streaming; deserialización JSON; filtro por magnitud; micro-lotes continuos; y generación de directorios de checkpoint con archivos `offsets` y `commits`. **No se ha confirmado experimentalmente la recuperación tras reiniciar la consulta.** Las advertencias de deprecación de `kafka-python` observadas con el productor anterior no impidieron publicar mensajes. El código de referencia aquí presentado es una consolidación pedagógica basada en dichas pruebas, **no una nueva ejecución certificada de cada archivo**.

Para el historial detallado y decisiones de continuidad consultar [ESTADO_CONTINUIDAD_KAFKA.md](ESTADO_CONTINUIDAD_KAFKA.md). El material teórico original permanece separado y sin modificaciones.

---

<details>
<summary>Archivo histórico — registro docente previo a la actualización USGS</summary>

## Registro de validación docente — 29 de octubre de 2026 (en desarrollo)

> **Estado:** pruebas en entorno Hadoop del docente; esta sección documenta hallazgos y no sustituye todavía los cinco ejercicios de la versión publicada. El flujo USGS es un caso real alternativo al caso de ventas, pendiente de integración editorial definitiva.

**Validado:** consulta a la API pública USGS (feed `all_hour.geojson`); creación del tópico `sismos_usgs` con tres particiones y factor de replicación 1; publicación desde Python de cuatro eventos sísmicos JSON, con confirmación de partición y offset; lectura de los mismos cuatro eventos desde `KafkaConsumer`, con recuperación de ID, magnitud, partición y offset. La cantidad de eventos depende del momento de consulta. Se verificó que el orden global de lectura puede diferir entre particiones.

**Incidencia de conectividad resuelta solo en el entorno docente:** el broker Kafka anunció `505b7c6c3bcb:9092` (ID 101). Aunque el puerto 9092 era accesible por TCP, el cliente Python no podía resolver ese nombre al consultar metadatos. Una entrada local en `/etc/hosts` que vinculó ese nombre con `172.27.1.16` permitió recuperar 93 tópicos y publicar/consumir eventos. **No utilizar esta entrada como instrucción para estudiantes:** IP y nombre del contenedor son variables; se requiere una configuración reproducible de `advertised.listeners` y DNS/listeners adecuados antes de distribuir la guía.

**Entorno Python:** `kafka-python` se instaló en un entorno virtual independiente `~/kafka_usgs/.venv`, fuera de la carpeta del repositorio Hadoop por restricciones locales de permisos. El productor y consumidor funcionaron, aunque aparecieron advertencias `DeprecationWarning` relacionadas con `key_serializer`, `value_serializer` y `value_deserializer`. Revisar versión de biblioteca y serialización antes de cerrar la guía; no confundir estas advertencias con errores de publicación.

**Spark pendiente:** contenedores `spark-master` y `spark-worker` activos; `spark-submit` localizado en `/spark/bin/spark-submit` (no en el `PATH` de la sesión de prueba). Se confirmó Spark **2.4.0**, Scala **2.11.12** y Java **8**. No se encontró `spark-sql-kafka-0-10` ni `kafka-clients` en `/spark/jars`. Candidato de conector compatible: `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`; aún no instalado ni probado. La prueba de conectividad a Maven Central **no se ejecutó** porque el `python` del contenedor rechazó `import urllib.request` (`ImportError: No module named request`), compatible con un intérprete Python 2; comprobar la versión antes de repetirla. **No se ha validado aún Spark Structured Streaming ni checkpoints.**

**Criterio editorial:** mantener cinco ejercicios y 60 minutos. Antes de cerrar la versión para estudiantes, decidir si se reemplaza el ejemplo local de ventas por USGS; entregar scripts listos para ejecutar y preconfigurar conectores y listeners, sin trasladar la depuración de infraestructura al estudiante.

**Decisión editorial posterior (29-10-2026):** el docente confirma que la versión final de los cinco ejercicios debe utilizar la API real de sismos USGS para un flujo NRT, no la API ficticia de ventas. La sustitución completa de las consignas y scripts está pendiente de la validación Spark–Kafka. La prueba `spark-submit --packages ... --version` solo confirmó versiones, y la búsqueda de JARs del conector en `/root/.ivy2` y `/root/.m2` no encontró archivos.


### Validación adicional del caso USGS — 29-10-2026 (pruebas aprobadas)

1. **Dependencias:** la ejecución real de `spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0` resolvió y descargó el conector y dependencias de Maven Central; el script de prueba imprimió `Prueba de dependencias Spark-Kafka`.
2. **Fuente Kafka en Spark:** PySpark creó correctamente `readStream.format('kafka')` sobre `kafka:9092` y el tópico `sismos_usgs`, mostrando el esquema con `key`, `value`, `topic`, `partition`, `offset`, `timestamp` y `timestampType`.
3. **Lectura efectiva:** `writeStream.format('console').outputMode('append').trigger(once=True)` imprimió el `Batch: 0` con cuatro sismos USGS en JSON: partición 1 offset 0 y partición 0 offsets 0–2. Campos observados: `id_evento`, `magnitud`, `ubicacion`, `fecha_evento`, `longitud`, `latitud`, `profundidad_km`. No hubo excepción visible. **La integración API USGS → productor Python → Kafka → Spark Structured Streaming está validada para lectura puntual.**
4. **Pendiente de validación:** `from_json` con esquema explícito, filtrado y agregación de magnitudes, lectura continua, directorio de checkpoint persistente y reinicio con recuperación de offsets. `trigger(once=True)` no equivale a una sesión NRT continua.

**Decisión vigente:** reemplazar los cinco ejercicios de ventas por cinco ejercicios USGS NRT en la versión definitiva. Este bloque es un registro de laboratorio docente; las consignas anteriores de ventas aún deben reescribirse y no se consideran aprobadas para publicación. Evitar exigir al estudiante resolver DNS, versiones de Spark o descarga de conectores durante los 60 minutos.


### Prueba validada 29-10-2026 17:29 — JSON tipado y filtro Spark

En el contenedor `spark-master`, se ejecutó `/tmp/procesar_sismos.py` con `/spark/bin/spark-submit --master 'local[1]' --packages org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`. Se leyó `sismos_usgs` con Structured Streaming, se convirtió `value` de JSON a un esquema explícito (`id_evento`, `magnitud`, `ubicacion`, `fecha_evento`, `longitud`, `latitud`, `profundidad_km`) usando `from_json`, y se aplicó `filter(col('magnitud') >= 2.0)`. El resultado de `Batch: 0` presentó exactamente dos registros: `aka2026vlkyrn`, magnitud 2.5, Alaska; y `nm60628806`, magnitud 2.31, Tennessee. La ejecución volvió al prompt sin error visible. **Aprobado: deserialización, tipado y filtrado.** El modo usado fue `trigger(once=True)`; **pendiente**: streaming continuo, checkpoints persistentes y recuperación. Próxima prueba: lectura continua con un nuevo evento y detención controlada.


</details>
