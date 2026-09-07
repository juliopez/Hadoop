# Hadoop / Docker Compose by @juliopez

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18968437.svg)](https://doi.org/10.5281/zenodo.18968437)

![License](https://img.shields.io/badge/license-GPL--2.0-blue)
![Status](https://img.shields.io/badge/status-active-green)

Infraestructura educativa para experimentación con **Big Data** basada
en Docker Compose.

Este repositorio proporciona un entorno reproducible que integra
**Hadoop/HDFS, Spark, Hive, Hue, Zeppelin, Kafka, ZooKeeper, NiFi y
StreamSets**, orientado al aprendizaje, laboratorios y demostraciones
técnicas.

> **Versión 2.0.0 (2026):** incorpora persistencia explícita para los
> componentes que almacenan estado y una configuración actualizada de
> Apache NiFi 2.11.0.

📺 **Video de instalación y configuración:**\
https://youtu.be/qjjBWUUJq3s

⭐ Si este repositorio te resulta útil para estudiar o practicar,
considera darle una estrella.

------------------------------------------------------------------------

## Principales mejoras de la versión 2.0.0

La versión 2.0.0 mantiene la arquitectura docente original, pero corrige un
problema importante: en la versión anterior parte de la información
podía quedar almacenada únicamente dentro del filesystem de los
contenedores.

La nueva configuración incorpora almacenamiento persistente para los
componentes que lo requieren, entre ellos:

-   **HDFS:** persistencia de NameNode y DataNode.
-   **Hive:** persistencia del Hive Metastore mediante PostgreSQL.
-   **NiFi:** persistencia de configuración, estado y repositorios.
-   **Kafka y ZooKeeper:** persistencia de sus datos.
-   **Zeppelin:** persistencia de notebooks.
-   **StreamSets:** persistencia de datos.
-   **MySQL:** persistencia de la base de datos utilizada por el
    entorno.

Esto permite detener y recrear los contenedores mediante Docker Compose
sin perder los datos persistentes, siempre que **no se eliminen
expresamente los volúmenes**.

> `docker compose down` elimina los contenedores y la red, pero conserva
> los volúmenes.\
> **No utilice `docker compose down -v` si desea conservar los datos.**

------------------------------------------------------------------------

## Requisitos

Antes de comenzar debe disponer de:

-   Docker Engine.
-   Docker Compose v2.
-   Git, si desea clonar el repositorio.
-   Puertos necesarios disponibles en el equipo o instancia.
-   En AWS EC2, reglas del Security Group habilitadas únicamente para
    los servicios que necesite exponer.

------------------------------------------------------------------------

## Archivos principales

La infraestructura actual utiliza:

``` text
docker-compose.yml
hadoop-hive.env
```

El archivo `.env` concentra los parámetros que pueden variar entre
instalaciones.

Para Apache NiFi, revise especialmente:

``` text
NIFI_PROXY_HOST=REEMPLAZAR_POR_IP_PUBLICA_EC2:9999
NIFI_USERNAME=admin
NIFI_PASSWORD=NifiLab2026!Secure
```

Para una instalación exclusivamente local puede utilizar:

``` text
NIFI_PROXY_HOST=localhost:9999
```

En AWS EC2 reemplace el valor por la **IP pública o DNS público de la
instancia**, seguido de `:9999`.

------------------------------------------------------------------------

## Puesta en marcha

Clone o descargue este repositorio y sitúese en el directorio que
contiene los archivos de la infraestructura.

Levante el entorno con:

``` bash
sudo docker compose \
  -f docker-compose.yml \
  --env-file hadoop-hive.env \
  up -d
```

Compruebe los servicios:

``` bash
sudo docker ps \
  --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Los contenedores `namenode` y `datanode` deberían terminar mostrando
estado `healthy`.

------------------------------------------------------------------------

## Detener y volver a iniciar la infraestructura

Para detener y eliminar los contenedores conservando los volúmenes:

``` bash
sudo docker compose \
  -f docker-compose.yml \
  --env-file hadoop-hive.env \
  down
```

Para volver a crearlos:

``` bash
sudo docker compose \
  -f docker-compose.yml \
  --env-file hadoop-hive.env \
  up -d
```

### Importante sobre persistencia

Los datos persistentes están desacoplados del ciclo de vida de los
contenedores mediante volúmenes Docker.

Por ello:

``` text
docker compose down
        ↓
se eliminan los contenedores
        ↓
los volúmenes permanecen
        ↓
docker compose up -d
        ↓
se recrean los contenedores
        ↓
los datos vuelven a estar disponibles
```

Esto no significa que los datos sean independientes del equipo
anfitrión. Si se elimina la máquina, la instancia EC2 o el
almacenamiento físico que contiene los volúmenes Docker, los datos
también pueden desaparecer.

------------------------------------------------------------------------

## Interfaces web

En un navegador utilice `localhost` para una instalación local o la
IP/DNS de la instancia cuando trabaje en AWS.

  Servicio                       Puerto Ejemplo local
  ---------------------------- -------- --------------------------------
  Hadoop NameNode                 50070 `http://localhost:50070`
  Spark Master                     8080 `http://localhost:8080`
  Spark Worker                     8081 `http://localhost:8081`
  Hue                              8888 `http://localhost:8888`
  Apache NiFi                      9999 `https://localhost:9999/nifi/`
  Kafka UI/servicio expuesto       3030 `http://localhost:3030`
  StreamSets                      18630 `http://localhost:18630`
  Zeppelin                        19090 `http://localhost:19090`

### Credenciales

**NiFi**

``` text
Usuario: admin
Contraseña: NifiLab2026!Secure
```

Las credenciales pueden modificarse en `hadoop-hive.env`.

**Hue**

En el primer acceso puede solicitar la creación de una cuenta. Para el
laboratorio puede utilizar `admin`.

**StreamSets**

``` text
Usuario: admin
Contraseña: admin
```

------------------------------------------------------------------------

## Apache NiFi 2.11.0

Esta versión utiliza HTTPS. Docker publica el puerto `9999` del host
hacia el puerto HTTPS `8443` del contenedor.

La configuración utiliza:

``` text
NIFI_WEB_HTTPS_HOST=0.0.0.0
NIFI_WEB_PROXY_HOST=${NIFI_PROXY_HOST}
```

Puede comprobar el acceso local mediante:

``` bash
curl -k -I https://localhost:9999/nifi/
```

Una configuración correcta debería responder con:

``` text
HTTP/2 200
```

El navegador puede advertir que el certificado no es de confianza debido
al certificado autofirmado utilizado en el entorno de laboratorio.

------------------------------------------------------------------------

## Uso de HDFS

Puede ejecutar comandos HDFS desde el NameNode:

``` bash
sudo docker exec -it namenode bash
```

Ejemplos:

``` bash
hdfs dfs -ls /
hdfs dfs -mkdir -p /curso/datos
hdfs dfs -ls /curso
```

Recuerde que el filesystem Linux del contenedor y HDFS son espacios
diferentes:

``` text
ls /
```

consulta el filesystem Linux, mientras que:

``` text
hdfs dfs -ls /
```

consulta HDFS.

------------------------------------------------------------------------

## Uso de Hive

Ingrese al contenedor:

``` bash
sudo docker exec -it hive-server bash
```

Luego:

``` bash
cd /opt/hive/bin
./hive
```

Ejemplos:

``` sql
SHOW DATABASES;
SHOW TABLES;
```

Hive utiliza HDFS para almacenar los datos y el **Hive Metastore** para
conservar la definición de bases de datos, tablas, columnas, tipos y
ubicaciones.

En esta versión el Metastore utiliza PostgreSQL con almacenamiento
persistente.

------------------------------------------------------------------------

## Uso de MySQL

Ingrese al contenedor:

``` bash
sudo docker exec -it database bash
```

Luego:

``` bash
mysql -h localhost -u root -p
```

Contraseña:

``` text
secret
```

------------------------------------------------------------------------

## Uso de Spark con Scala

Ingrese al Spark Master:

``` bash
sudo docker exec -it spark-master bash
```

Luego:

``` bash
cd /spark/bin
./spark-shell
```

------------------------------------------------------------------------

## Uso de PySpark

Ingrese al Spark Master:

``` bash
sudo docker exec -it spark-master bash
```

Luego:

``` bash
cd /spark/bin
./pyspark
```

------------------------------------------------------------------------

## Uso de Kafka

Ingrese al contenedor:

``` bash
sudo docker exec -it kafka bash
```

Luego:

``` bash
cd /usr/local/bin
```

Ejemplos básicos del entorno:

``` bash
./kafka-topics --create --zookeeper zookeeper:2181 \
  --replication-factor 1 --partitions 1 --topic EJEMPLO

./kafka-topics --list --zookeeper zookeeper:2181

./kafka-console-producer \
  --broker-list localhost:9092 \
  --topic EJEMPLO

./kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --from-beginning \
  --topic EJEMPLO
```

------------------------------------------------------------------------

## Persistencia: comprobación rápida

Puede crear un archivo de prueba en HDFS:

``` bash
sudo docker exec namenode \
  hdfs dfs -mkdir -p /prueba_persistencia

sudo docker exec namenode \
  sh -c 'echo "Este archivo debe sobrevivir a la recreación de los contenedores" > /tmp/persistencia.txt'

sudo docker exec namenode \
  hdfs dfs -put /tmp/persistencia.txt /prueba_persistencia/
```

Compruébelo:

``` bash
sudo docker exec namenode \
  hdfs dfs -cat /prueba_persistencia/persistencia.txt
```

Después de ejecutar `docker compose down` y posteriormente `up -d`, el
archivo debería continuar disponible mientras los volúmenes persistentes
se conserven.

------------------------------------------------------------------------

## Consideraciones para AWS EC2

Al desplegar esta infraestructura en AWS:

1.  Configure `NIFI_PROXY_HOST` con la IP pública o DNS de la instancia.
2.  Habilite en el Security Group únicamente los puertos necesarios.
3.  Evite exponer indiscriminadamente todos los servicios a Internet.
4.  Recuerde que los volúmenes Docker siguen residiendo sobre el
    almacenamiento de la instancia.
5.  Detener/iniciar una instancia no equivale a terminarla y recrearla.

La persistencia de Docker no sustituye una estrategia de respaldo.

------------------------------------------------------------------------

## Solución de problemas

### Ver estado de los contenedores

``` bash
sudo docker ps -a
```

### Revisar logs

Ejemplo para NiFi:

``` bash
sudo docker logs nifi --tail 50
```

Ejemplo para Hive:

``` bash
sudo docker logs hive-server --tail 50
```

### Ver volúmenes

``` bash
sudo docker volume ls
```

### Problemas con Hue

Video de apoyo:

https://youtu.be/Ck4sRPa0o24

### Trabajo con Sqoop

Material complementario:

https://youtu.be/hLJFzOAbY8Q

------------------------------------------------------------------------

## Arquitectura conceptual

``` text
                         Docker Compose
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
   Hadoop/HDFS              Hive                  Spark
       │                      │
 ┌─────┴─────┐        ┌──────┴─────────┐
 │           │        │                │
NameNode  DataNode  HiveServer2    Hive Metastore
                                      │
                                  PostgreSQL

       ┌──────────────────────┬──────────────────────┐
       │                      │                      │
     Kafka                ZooKeeper                NiFi

       ┌──────────────────────┬──────────────────────┐
       │                      │                      │
      Hue                  Zeppelin             StreamSets
```

------------------------------------------------------------------------

## How to cite this repository

If you use this infrastructure in research or technical work, please
cite:

López-Núñez, J. (2026).\
*Hadoop Infrastructure for Big Data using Docker Compose* (Version
2.0.0) \[Software\].\
Zenodo. https://doi.org/10.5281/zenodo.22645069

For the repository as a whole and all versions, use the conceptual DOI:
https://doi.org/10.5281/zenodo.18968437

------------------------------------------------------------------------

## License

This project is distributed under the **GPL-2.0** license.

------------------------------------------------------------------------

## Additional information

Blog de Julio López-Núñez:\
https://juliopezblog.wordpress.com/
