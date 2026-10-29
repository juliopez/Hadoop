# 2.1. Preparación y verificación de Kafka en el entorno Docker

## 2.1.1. Del conocimiento conceptual al entorno de trabajo

En la Parte I estudiamos los fundamentos de Apache Kafka, su arquitectura distribuida y su relación con Hadoop, HDFS, Hive y Spark. Comprendimos cómo los productores publican eventos en tópicos, cómo los brokers almacenan registros y cómo los consumidores recuperan información.

Ahora relacionaremos estos conceptos con la infraestructura del curso de Big Data. Nuestro laboratorio utiliza **Docker** para ejecutar diferentes servicios en contenedores. Esta decisión facilita disponer de un entorno relativamente reproducible, donde tecnologías con distintas dependencias pueden operar coordinadamente.

En las semanas anteriores utilizamos esta infraestructura con HDFS, Hive y Spark. Ahora incorporamos Kafka a nuestros procedimientos de operación e integración. El primer objetivo no es publicar eventos inmediatamente, sino **comprobar que el servicio está disponible y comprender cómo acceder a él**.

## 2.1.2. Kafka dentro de nuestra infraestructura Docker

El entorno docente se define en el repositorio [juliopez/Hadoop](https://github.com/juliopez/Hadoop), mediante `docker-compose.yml`. Entre los servicios disponibles se encuentran HDFS, Hive, Spark, Kafka, ZooKeeper, NiFi y MySQL.

**Que dos servicios estén disponibles dentro de Docker no significa que exista una integración funcional entre ellos.** Por ejemplo, aunque Kafka y Spark estén ejecutándose, todavía necesitaremos una aplicación y dependencias compatibles para consumir eventos con Spark Structured Streaming.

Kafka utiliza el servicio `kafka` y ZooKeeper el servicio `zookeeper`. Nuestra instalación educativa corresponde a un broker único coordinado mediante ZooKeeper.

![Figura 36. Kafka y ZooKeeper dentro del entorno Docker](imagenes/figura_36.svg)

*Figura 36. Kafka y ZooKeeper dentro del entorno Docker del curso. Esquema conceptual: no representa integración automática con los otros servicios.*

Esta configuración difiere de las arquitecturas modernas basadas en KRaft. Los procedimientos deben corresponder a la versión realmente instalada y no simplemente a la documentación más reciente.

## 2.1.3. Identificación de los componentes configurados

| Componente | Configuración del laboratorio |
|---|---|
| Servicio Kafka | `kafka` |
| Contenedor Kafka | `kafka` |
| Imagen Kafka | `landoop/fast-data-dev:latest` |
| Puerto del broker | `9092` |
| Interfaz web de la distribución | `3030` |
| Servicio ZooKeeper | `zookeeper` |
| Imagen ZooKeeper | `zookeeper:3.8.7` |
| Puerto ZooKeeper | `2181` |
| Conexión Kafka–ZooKeeper | `zookeeper:2181` |

El parámetro `KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181` indica la dirección que Kafka utiliza para comunicarse con ZooKeeper. El nombre `zookeeper` identifica el servicio dentro de Docker y `2181` su puerto.

Kafka también debe anunciar a los clientes cómo conectarse a los brokers. Una configuración incorrecta de las direcciones anunciadas puede producir errores incluso cuando el servicio está en ejecución.

La configuración documentada del laboratorio contiene:

```yaml
KAFKA_ADVERTISED_HOST_NAME: 172.27.1.16
```

Esta dirección debe verificarse en el entorno donde efectivamente se ejecutan los contenedores.

## 2.1.4. Verificación de los contenedores

```bash
docker ps
```

Este comando muestra los contenedores actualmente ejecutándose, con información como nombre, imagen, estado y puertos. Nos interesa comprobar la presencia de `kafka` y `zookeeper`.

```bash
docker ps -a
```

La opción `-a` muestra también los contenedores detenidos. `Exited` significa que el contenedor no está funcionando; `Up` indica que está en ejecución, pero no garantiza por sí solo el correcto funcionamiento interno del broker.

Debemos distinguir entre **existencia del contenedor**, **ejecución del contenedor** y **disponibilidad funcional del servicio Kafka**.

## 2.1.5. Acceso al contenedor Kafka

```bash
docker exec -it kafka bash
```

| Elemento | Significado |
|---|---|
| `docker exec` | Ejecuta un comando dentro de un contenedor existente |
| `-i` | Mantiene la entrada interactiva |
| `-t` | Asigna una terminal |
| `kafka` | Nombre del contenedor |
| `bash` | Intérprete de comandos |

**Ingresar al contenedor no equivale a conectarse al broker mediante el protocolo Kafka.** Estamos accediendo al entorno del sistema donde se ejecutan los procesos y herramientas. Las rutas y utilidades pueden variar según la distribución instalada; debemos comprobar las disponibles en `landoop/fast-data-dev:latest`.

## 2.1.6. Verificación de los registros del servicio

```bash
docker logs kafka
docker logs --tail 50 kafka
docker logs -f kafka
```

Estos comandos permiten consultar los registros completos, las últimas cincuenta líneas o seguir los mensajes conforme aparecen. Pueden ayudar a detectar errores de conexión con ZooKeeper, configuración o puertos.

Una advertencia no significa necesariamente que Kafka haya dejado de funcionar; asimismo, la ausencia de errores evidentes no demuestra disponibilidad funcional. La lectura de registros debe complementarse con una prueba de comunicación.

## 2.1.7. Comprobación de la disponibilidad del broker

Una operación administrativa de referencia es:

```bash
kafka-topics --bootstrap-server localhost:9092 --list
```

Según la distribución, el ejecutable puede denominarse `kafka-topics.sh` o ubicarse en otra ruta. Algunas versiones anteriores utilizan parámetros diferentes. **La compatibilidad de este comando debe verificarse contra la imagen real del laboratorio**.

`--bootstrap-server` identifica la dirección inicial del broker. `localhost:9092` supone que el cliente se ejecuta en un entorno donde el broker está accesible mediante esa dirección. Desde otro contenedor o máquina, puede ser necesario utilizar otra.

Una lista vacía de tópicos no implica necesariamente un error: podría indicar que todavía no existen tópicos de usuario.

## 2.1.8. La interfaz web de Kafka

La distribución del laboratorio expone el puerto `3030` para una interfaz web. Según la publicación de puertos y la conectividad, puede accederse mediante:

```text
http://localhost:3030
```

La disponibilidad depende de la configuración de red y del estado del contenedor. La interfaz facilita la observación, pero no reemplaza la comprensión de los comandos administrativos ni de los mecanismos de publicación y consumo.

## 2.1.9. Problemas frecuentes de disponibilidad y conectividad

| Situación | Posible explicación | Primera verificación |
|---|---|---|
| Kafka no aparece en `docker ps` | Contenedor detenido o no iniciado | `docker ps -a` |
| Kafka no inicia | Configuración o dependencia | `docker logs kafka` |
| No conecta con ZooKeeper | Servicio o dirección incorrecta | Estado de `zookeeper` y registros |
| El cliente no accede al broker | Dirección o puerto incorrectos | Configuración de conectividad |
| La interfaz web no responde | Puerto o servicio inaccesible | Estado y puertos |
| No aparecen tópicos | Aún no se han creado | Consulta administrativa |

No todos los problemas de conexión se originan en el broker. En Docker, `localhost` se refiere al entorno desde el que se ejecuta la aplicación: dentro de otro contenedor no identifica necesariamente al broker Kafka.

## 2.1.10. Secuencia de verificación recomendada

![Figura 37. Secuencia de verificación del entorno Kafka](imagenes/figura_37.svg)

*Figura 37. Secuencia de verificación del entorno Kafka.*

El procedimiento recomendado comienza con la revisión de Docker Compose, continúa con el estado de los contenedores y sus registros, y termina con la comprobación funcional del broker y de la interfaz web. Esta progresión permite reducir errores de diagnóstico.

## 2.1.11. Síntesis del apartado

Relacionamos los fundamentos de Kafka con nuestra infraestructura Docker, identificamos el broker único coordinado mediante ZooKeeper y distinguimos los niveles de verificación: contenedor, servicio y conectividad del cliente. Docker facilita el despliegue, pero no elimina la necesidad de revisar configuraciones, dependencias y direcciones de conexión.

En el apartado **2.2. Administración de tópicos, particiones y configuración básica**, estudiaremos cómo Kafka organiza y administra los recursos que almacenan los eventos.
