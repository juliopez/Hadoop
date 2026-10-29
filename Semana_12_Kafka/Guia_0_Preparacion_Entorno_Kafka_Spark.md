# Guía 0 — Habilitación de Apache Kafka e integración con Spark en AWS

**Asignatura:** Big Data · **Modalidad:** preparación autónoma previa a las prácticas · **Entorno de referencia:** instancia AWS utilizada durante el semestre para HDFS, Hive y Apache Spark.

## Propósito

**Aprovechar la instancia AWS y los servicios Hadoop/Spark utilizados en las semanas anteriores** para habilitar únicamente los componentes adicionales requeridos por Kafka y la integración con Spark. Preparar y verificar el entorno necesario para realizar, sin interrupciones por dependencias, la [Guía práctica 1 — Kafka](Guia_Practica_1_Kafka.md) y la [Guía práctica 2 — USGS, Kafka y Spark](Guia_Practica_2_Kafka_Spark.md).

**Esta guía se realiza antes de comenzar las prácticas.** No requiere repetir los ejercicios anteriores de HDFS, Hive o Spark ni reinstalar sus servicios. Su producto es la habilitación de Kafka, sus dependencias y una lista de comprobación completada.

**Punto de partida:** cada estudiante continúa trabajando en su instancia AWS habitual, accediendo mediante el procedimiento del curso. No crear otra instancia ni reconstruir Hadoop o Spark. La instancia puede contener servicios Docker ya desplegados; comprobarlo antes de instalar nada. Los nombres `kafka` y `spark-master` corresponden al laboratorio de referencia y deben ajustarse si la instancia del estudiante utiliza otros nombres.

## Arquitectura de integración sobre la instancia AWS existente

```text
Instancia AWS del estudiante (Ubuntu / entorno del curso)
├── Docker
│   ├── contenedor kafka       → broker Kafka, tópicos ventas y sismos_usgs
│   └── contenedor spark-master → Spark 2.4.0 / Scala 2.11 / Java 8
└── Python 3 + entorno virtual
    ├── requests               → consulta HTTP a USGS
    └── kafka-python           → productor de eventos JSON

Guía 1: consola Kafka → tópico ventas → consumidores
Guía 2: USGS → Python → tópico sismos_usgs → Spark Structured Streaming
```

**Se reutiliza el entorno académico existente.** HDFS, Hive y Spark no forman parte de la instalación de esta guía. El repositorio del curso incluye Kafka y ZooKeeper en Docker Compose; verificar que esos servicios están activos en la instancia AWS. Si Kafka no está activo, utilizar el Compose ya empleado en el semestre y evitar acciones que afecten HDFS, Hive y Spark. No ejecutar `docker compose down -v`.

## 1. Reconocer los servicios existentes en la instancia AWS

Conectarse a la instancia AWS habitual y abrir una terminal. Primero identificar los servicios existentes:

```bash
docker --version
docker compose version
docker ps
```

**Interpretación:** Docker debe responder si el laboratorio usa contenedores. Identificar si existen `kafka` y `spark-master` (u otros nombres equivalentes). La existencia de Spark como servicio o instalación previa del semestre **no implica** que se llame `spark-master` ni que funcione en Docker; verificar antes de utilizar los comandos de ejemplo.

**Permisos del laboratorio:** los estudiantes ejecutan Docker sin `sudo` en sus instancias AWS. Si aparece un error de permisos, consultar la configuración de acceso entregada por el curso; no modificar permisos del socket Docker.

**Solo si los contenedores ya existen y están detenidos**, pueden iniciarse:

```bash
docker start kafka spark-master
docker ps
```

Si el nombre de los contenedores difiere, usar los nombres indicados en `docker ps` y reemplazarlos en los comandos posteriores.

**Criterio de avance:** Kafka y Spark están identificados y accesibles mediante la modalidad real del laboratorio. El repositorio del curso ya incluye Kafka y ZooKeeper en Docker Compose; si faltan los contenedores, comprobar el despliegue existente y las instrucciones del README antes de actuar. No reinstalar Spark ni modificar HDFS/Hive.

## 2. Habilitar Kafka y preparar los tópicos de las prácticas

Los siguientes comandos son para el caso en que Kafka está instalado **en un contenedor llamado `kafka`**. Si Kafka está instalado directamente en la instancia AWS o el contenedor tiene otro nombre, utilizar la ruta y el servicio correspondientes. Antes de crear los tópicos, confirmar que el broker funciona.

```bash
docker exec kafka bash -lc 'kafka-topics --bootstrap-server localhost:9092 --list'
```

**Resultado esperado:** lista de tópicos o una lista vacía sin errores de conexión.

Crear los dos tópicos requeridos por las prácticas:

```bash
docker exec kafka bash -lc 'kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic ventas --partitions 3 --replication-factor 1'
docker exec kafka bash -lc 'kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic sismos_usgs --partitions 3 --replication-factor 1'
```

Comprobar su configuración:

```bash
docker exec kafka bash -lc 'kafka-topics --bootstrap-server localhost:9092 --describe --topic ventas'
docker exec kafka bash -lc 'kafka-topics --bootstrap-server localhost:9092 --describe --topic sismos_usgs'
```

**Resultado esperado:** ambos tópicos existen. En un laboratorio de broker único, el factor de replicación es 1. Si un tópico ya existía con otro número de particiones, no modificarlo sin instrucciones del curso.

**Compatibilidad de comandos:** algunas imágenes utilizan `kafka-topics.sh` en lugar de `kafka-topics`. Utilizar la variante disponible en la imagen institucional.

## 3. Verificar la conectividad en la instancia AWS

**No confundir estas direcciones:**

| Origen de la conexión | Broker de referencia |
|---|---|
| Herramientas dentro del contenedor Kafka | `localhost:9092` |
| Python ejecutado en Ubuntu | `localhost:9092` **solo si** el puerto está publicado y el broker anuncia una dirección resoluble desde Ubuntu |
| Spark ejecutado dentro de `spark-master` | `kafka:9092` **solo si** ambos contenedores comparten red Docker y el broker anuncia una dirección accesible |

Comprobar los puertos publicados:

```bash
docker port kafka
```

Inspeccionar la configuración de listeners y red sin modificarla:

```bash
docker exec kafka bash -lc 'env | grep -E "KAFKA_.*LISTENER|ADVERTISED" || true'
docker inspect kafka --format '{{json .NetworkSettings.Networks}}'
docker inspect spark-master --format '{{json .NetworkSettings.Networks}}'
```

**Punto crítico de la infraestructura actual:** el archivo `docker-compose.yml` del repositorio fija `KAFKA_ADVERTISED_HOST_NAME: 172.27.1.16`. Es una dirección específica del despliegue y no se debe asumir válida en AWS. En las instancias AWS se debe utilizar la configuración de red suministrada por el curso; no copiar la IP observada en otro equipo. Un puerto TCP abierto no garantiza que el cliente Kafka funcione. Kafka devuelve metadatos con el host y puerto de `advertised.listeners`. Si anuncia un nombre que Ubuntu no puede resolver, Python puede fallar con `KafkaTimeoutError` o `DNS Resolution failure`, aunque el puerto 9092 responda.

**Si aparece un error de conectividad:** comprobar que los listeners anunciados sean resolubles desde cada red cliente y que Spark y Kafka compartan una red Docker adecuada. La configuración exacta depende del despliegue del curso. **No copiar IP internas ni añadir nombres efímeros a `/etc/hosts` como solución general.**

Para probar la resolución desde Spark:

```bash
docker exec spark-master bash -lc 'getent hosts kafka'
```

**Resultado esperado:** se resuelve el nombre `kafka`. Esto verifica DNS, no por sí solo toda la conexión Kafka.

## 4. Preparar dependencias Python en la instancia AWS

Usar Python 3 de la instancia AWS, sin modificar el intérprete utilizado por Spark. Comprobar que está disponible:

```bash
python3 --version
python3 -m venv --help
```

Crear un directorio de trabajo y un entorno virtual:

```bash
mkdir -p ~/kafka_usgs
cd ~/kafka_usgs
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install requests kafka-python
```

Comprobar las dependencias:

```bash
python -c 'import requests; import kafka; print("Dependencias Python disponibles")'
```

**Resultado esperado:** aparece `Dependencias Python disponibles` sin `ModuleNotFoundError`.

Si falla `python3 -m venv`, puede faltar el paquete `python3-venv` de Ubuntu. Instalarlo mediante el gestor de paquetes de la distribución y repetir la creación del entorno virtual. Mantener el entorno activado al ejecutar el productor de la Guía 2.

## 5. Verificar el acceso a la API USGS

Con el entorno virtual activado:

```bash
python - <<'PY'
import requests
url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
r = requests.get(url, timeout=20)
r.raise_for_status()
datos = r.json()
print("HTTP:", r.status_code)
print("Formato:", datos.get("type"))
print("Eventos disponibles:", len(datos.get("features", [])))
PY
```

**Resultado esperado:** HTTP 200, formato `FeatureCollection` y una cantidad de eventos que puede variar, incluso ser cero. Si hay error HTTP, DNS o TLS, verificar la conectividad a Internet antes de avanzar.

## 6. Reutilizar Spark existente y verificar el conector Kafka

**No reinstalar Spark.** Primero consultar la versión de la instalación ya utilizada en el curso:

```bash
spark-submit --version
```

Si Spark se ejecuta dentro de un contenedor llamado `spark-master`, usar en su lugar:

```bash
docker exec spark-master bash -lc '/spark/bin/spark-submit --version'
```

Si el ejecutable no está en el PATH, utilizar la ruta de Spark que se haya empleado durante las prácticas anteriores.

**Versiones del laboratorio de referencia:** Kafka 3.9.0 con ZooKeeper 3.8; Spark 2.4.0, Scala 2.11.12 y Java 8.

**Versiones Spark:** Las instancias del curso utilizan la infraestructura del repositorio; si alguna presenta otra versión, **no asumir que el conector siguiente sirve para cualquier Spark**: comprobar la versión real y seleccionar el artefacto compatible con Spark/Scala antes de ejecutar la Guía 2.

Conector correspondiente **únicamente al entorno de referencia Spark 2.4.0 / Scala 2.11**:

```text
org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0
```

La primera ejecución de `spark-submit --packages` puede descargar el conector y sus dependencias desde Maven Central. El laboratorio estudiantil debe contar con acceso a Maven o con las dependencias precargadas.

**Importante:** `spark-submit --version` comprueba la versión de Spark, **no** descarga el conector. La descarga efectiva ocurre al ejecutar una aplicación con `--packages`, como se hace en la Guía 2.

El contenedor de referencia usa una instalación antigua de Spark/PySpark y puede disponer de Python 2.7. **No actualizar Python dentro del contenedor ni instalar PySpark moderno** sin una evaluación de compatibilidad: el productor Python 3 se ejecuta en Ubuntu y el proceso Spark se ejecuta con el entorno proporcionado.

## 7. Preparar los archivos en la instancia AWS

La Guía 2 incluye el código de estos dos archivos:

| Archivo | Ubicación de ejecución |
|---|---|
| `productor_usgs.py` | Ubuntu, en `~/kafka_usgs/` |
| `sismos_checkpoint.py` | Contenedor `spark-master`, en `/tmp/` |

Guardar `productor_usgs.py` en `~/kafka_usgs/` utilizando el código completo del **Ejercicio 2 de la Guía 2**. Guardar `sismos_checkpoint.py` en Ubuntu con el código completo del **Ejercicio 4 de la Guía 2**.

**Si Spark se ejecuta en el contenedor `spark-master`**, transferir el segundo archivo:

```bash
docker cp ~/kafka_usgs/sismos_checkpoint.py spark-master:/tmp/sismos_checkpoint.py
```

Verificar que existe:

```bash
docker exec spark-master bash -lc 'ls -lh /tmp/sismos_checkpoint.py'
```

**Resultado esperado:** el archivo aparece en `/tmp/`. Si Spark se ejecuta directamente en AWS, no utilizar `docker cp`: guardar el script en la ruta de trabajo y adaptar el comando `spark-submit` de la Guía 2. No es necesario ejecutar todavía el procesamiento de eventos; eso corresponde a la Guía 2.

**Checkpoint:** el script utiliza `/tmp/checkpoint_sismos_usgs` dentro de Spark. Para un laboratorio temporal es suficiente si se conserva el mismo contenedor. Si se necesita recuperar el estado después de recrearlo, se requiere un volumen Docker persistente. No borrar ni compartir un mismo checkpoint entre consultas independientes.

## 8. Preparación para trabajo simultáneo

Si todo el curso comparte un único broker, **los tópicos y checkpoints comunes pueden producir interferencias** entre participantes. La configuración mínima del laboratorio es:

```text
Tópico Guía 1: ventas
Tópico Guía 2: sismos_usgs
Checkpoint Spark: /tmp/checkpoint_sismos_usgs
```

Si varias personas comparten el broker, asignar identificadores por instancia de trabajo (por ejemplo, `ventas_g01`, `sismos_usgs_g01` y `/tmp/checkpoint_sismos_usgs_g01`). Cada participante debe actualizar los nombres correspondientes en los comandos y las variables `KAFKA_TOPIC` y `SPARK_CHECKPOINT` de los scripts. En la Guía 1, sustituir `ventas` por el tópico asignado.

**Advertencia de compatibilidad:** los nombres del tópico deben coincidir entre productor y consumidor, y el checkpoint debe ser exclusivo de una consulta. El docente debe comunicar previamente si se utilizarán tópicos compartidos o independientes.

## 9. Lista de comprobación de habilitación sobre AWS

Marcar cada condición:

- [ ] Se accede correctamente a la instancia AWS habitual y los servicios HDFS, Hive y Spark existentes no se han alterado.
- [ ] Se identificó cómo se ejecutan Kafka y Spark (Docker o instalación directa) y ambos están disponibles.
- [ ] Kafka responde a la consulta de tópicos.
- [ ] Existen los tópicos `ventas` y `sismos_usgs` (o los nombres asignados).
- [ ] Ubuntu y Spark disponen de rutas de conexión a Kafka configuradas para sus respectivas redes.
- [ ] El entorno virtual Python 3 funciona y dispone de `requests` y `kafka-python`.
- [ ] USGS responde con un GeoJSON válido.
- [ ] Spark informa la versión esperada y el conector Kafka está disponible o puede descargarse.
- [ ] `productor_usgs.py` está guardado en Ubuntu.
- [ ] `sismos_checkpoint.py` está disponible dentro de `spark-master`.
- [ ] Se definió una política de tópicos y checkpoints para evitar interferencias entre instancias de trabajo.

**Criterio de preparación:** si se cumplen los puntos, el laboratorio está listo para comenzar las prácticas. La ejecución completa del flujo y la observación de micro-lotes forman parte de la Guía 2, no de esta preparación.

## 10. Diagnóstico breve de incidencias frecuentes

| Síntoma | Causa probable | Acción |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker detenido o permisos insuficientes | Comprobar el servicio Docker y los permisos del usuario |
| `No such container` | Nombre diferente o contenedor no creado | Revisar `docker ps -a` y el despliegue del curso |
| `kafka-topics: command not found` | Utilidad con otra ruta o sufijo `.sh` | Localizar la utilidad dentro de la imagen Kafka |
| `KafkaTimeoutError` o error DNS | `advertised.listeners` inaccesible | Corregir listeners y resolución de red, no fijar IP efímeras |
| `No module named requests` o `kafka` | Entorno virtual no activado o dependencia ausente | Activar `.venv` e instalar dependencias |
| Error HTTP al consultar USGS | Sin Internet, DNS o problema temporal de API | Revisar conectividad y volver a consultar |
| `Failed to find data source: kafka` | Conector Spark–Kafka ausente o incompatible | Usar `--packages` con versión correspondiente a Spark/Scala |
| Spark no resuelve `kafka` | Contenedores en redes distintas | Revisar red Docker y nombre de servicio |
| Archivo Spark no encontrado | Script no copiado al contenedor | Repetir `docker cp` y comprobar la ruta |
| Checkpoint inaccesible | Ruta sin permisos o estado compartido | Usar una ruta escribible y exclusiva para la consulta |

## Continuación del trabajo

Una vez completada esta preparación, desarrollar en orden:

1. [Guía práctica 1 — Publicación y consumo de eventos con Apache Kafka](Guia_Practica_1_Kafka.md).
2. [Guía práctica 2 — Procesamiento Near Real-Time de sismos con USGS, Kafka y Spark](Guia_Practica_2_Kafka_Spark.md).

**Alcance:** la guía habilita Kafka y su integración con el Spark existente en AWS. Los comandos Docker reflejan una modalidad concreta del laboratorio; no deben ejecutarse ciegamente en instancias que usan servicios nativos. Kafka y ZooKeeper están definidos en el Compose del repositorio; la preparación consiste en comprobarlos y resolver la conectividad, no en crear un clúster nuevo. No se requiere volver a desplegar HDFS, Hive ni Spark.
