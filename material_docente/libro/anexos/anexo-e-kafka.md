# ANEXO E

# Guía rápida de comandos de Apache Kafka

## Introducción

Durante el desarrollo de aplicaciones basadas en Apache Kafka es habitual utilizar comandos de administración para crear *Topics*, iniciar productores y consumidores, inspeccionar el estado del clúster y gestionar grupos de consumidores. Este anexo reúne los comandos más utilizados, organizados por categorías, con el propósito de servir como material de consulta rápida durante el desarrollo de laboratorios y proyectos.

> **Nota:** Los ejemplos consideran una instalación local de Apache Kafka utilizando el modo **KRaft**, disponible en las versiones recientes de la plataforma. Dependiendo del sistema operativo o del método de instalación (Docker, Linux nativo o Windows), las rutas y nombres de los archivos pueden variar ligeramente.

---

# E.1 Administración del servicio

## Iniciar Apache Kafka

```bash
bin/kafka-server-start.sh config/server.properties
```

En Windows:

```cmd
bin\windows\kafka-server-start.bat config\server.properties
```

---

## Detener Apache Kafka

Presionar:

```text
CTRL + C
```

sobre la consola donde se encuentra ejecutándose el servidor.

---

# E.2 Administración de Topics

## Crear un Topic

```bash
bin/kafka-topics.sh \
--create \
--topic transporte \
--bootstrap-server localhost:9092 \
--partitions 3 \
--replication-factor 1
```

---

## Listar Topics

```bash
bin/kafka-topics.sh \
--list \
--bootstrap-server localhost:9092
```

---

## Describir un Topic

```bash
bin/kafka-topics.sh \
--describe \
--topic transporte \
--bootstrap-server localhost:9092
```

El comando muestra información como:

- Número de particiones.
- Réplicas.
- Leader.
- ISR.
- Offsets.

---

## Eliminar un Topic

```bash
bin/kafka-topics.sh \
--delete \
--topic transporte \
--bootstrap-server localhost:9092
```

---

# E.3 Productores

## Ejecutar un Producer desde consola

```bash
bin/kafka-console-producer.sh \
--topic transporte \
--bootstrap-server localhost:9092
```

Posteriormente basta escribir mensajes:

```text
Primer evento

Segundo evento

Tercer evento
```

Cada línea enviada representa un nuevo evento publicado en Kafka.

---

# E.4 Consumidores

## Ejecutar un Consumer

```bash
bin/kafka-console-consumer.sh \
--topic transporte \
--bootstrap-server localhost:9092
```

---

## Leer todos los mensajes desde el inicio

```bash
bin/kafka-console-consumer.sh \
--topic transporte \
--from-beginning \
--bootstrap-server localhost:9092
```

Este comando resulta especialmente útil durante actividades de prueba.

---

## Consumidor perteneciente a un Consumer Group

```bash
bin/kafka-console-consumer.sh \
--topic transporte \
--group grupo1 \
--bootstrap-server localhost:9092
```

---

# E.5 Administración de Consumer Groups

## Listar Consumer Groups

```bash
bin/kafka-consumer-groups.sh \
--list \
--bootstrap-server localhost:9092
```

---

## Describir un Consumer Group

```bash
bin/kafka-consumer-groups.sh \
--describe \
--group grupo1 \
--bootstrap-server localhost:9092
```

Se mostrará información relacionada con:

- Offset actual.
- Offset final.
- Retraso (*Lag*).
- Particiones asignadas.
- Estado del grupo.

---

## Reiniciar Offsets

```bash
bin/kafka-consumer-groups.sh \
--group grupo1 \
--topic transporte \
--reset-offsets \
--to-earliest \
--execute \
--bootstrap-server localhost:9092
```

---

# E.6 Información del clúster

## Ver información del Broker

```bash
bin/kafka-broker-api-versions.sh \
--bootstrap-server localhost:9092
```

---

## Ver configuración del Broker

```bash
bin/kafka-configs.sh \
--bootstrap-server localhost:9092 \
--entity-type brokers \
--describe
```

---

# E.7 Comandos útiles para pruebas

## Crear rápidamente un Topic de prueba

```bash
bin/kafka-topics.sh \
--create \
--topic pruebas \
--partitions 1 \
--replication-factor 1 \
--bootstrap-server localhost:9092
```

---

## Publicar mensajes manualmente

```bash
bin/kafka-console-producer.sh \
--topic pruebas \
--bootstrap-server localhost:9092
```

---

## Leer todos los mensajes publicados

```bash
bin/kafka-console-consumer.sh \
--topic pruebas \
--from-beginning \
--bootstrap-server localhost:9092
```

---

## Eliminar el Topic de prueba

```bash
bin/kafka-topics.sh \
--delete \
--topic pruebas \
--bootstrap-server localhost:9092
```

---

# E.8 Comandos Docker

Cuando Apache Kafka se ejecuta mediante Docker, la mayoría de las operaciones se realizan desde el interior del contenedor.

## Listar contenedores

```bash
docker ps
```

---

## Acceder al contenedor

```bash
docker exec -it kafka bash
```

---

## Detener el contenedor

```bash
docker stop kafka
```

---

## Iniciar nuevamente el contenedor

```bash
docker start kafka
```

---

# E.9 Instalación de la biblioteca para Python

La biblioteca más utilizada para desarrollar aplicaciones cliente en Python es **kafka-python**.

Instalación:

```bash
pip install kafka-python
```

Verificación:

```bash
pip show kafka-python
```

Actualizar a la última versión disponible:

```bash
pip install --upgrade kafka-python
```

---

# E.10 Resumen de comandos más utilizados

| Acción | Comando principal |
|---------|-------------------|
| Iniciar Kafka | `kafka-server-start.sh` |
| Crear Topic | `kafka-topics.sh --create` |
| Listar Topics | `kafka-topics.sh --list` |
| Describir Topic | `kafka-topics.sh --describe` |
| Eliminar Topic | `kafka-topics.sh --delete` |
| Ejecutar Producer | `kafka-console-producer.sh` |
| Ejecutar Consumer | `kafka-console-consumer.sh` |
| Leer desde el inicio | `--from-beginning` |
| Listar Consumer Groups | `kafka-consumer-groups.sh --list` |
| Describir Consumer Group | `kafka-consumer-groups.sh --describe` |
| Reiniciar Offsets | `--reset-offsets` |
| Acceder al contenedor Docker | `docker exec -it kafka bash` |
| Instalar biblioteca Python | `pip install kafka-python` |

---

## Conclusión

Los comandos presentados en este anexo corresponden a las operaciones administrativas y de desarrollo más utilizadas durante la implementación de soluciones basadas en Apache Kafka. Su dominio permitirá crear y administrar *Topics*, publicar y consumir eventos, supervisar grupos de consumidores y verificar el estado del clúster, constituyendo una base práctica para el desarrollo de aplicaciones de procesamiento de eventos en tiempo real y su integración con tecnologías como Apache Spark Structured Streaming.
