# Guía práctica 1. Publicación y consumo de eventos con Apache Kafka

**Asignatura:** Big Data · **Duración estimada:** 60 minutos · **Dificultad:** intermedia · **Modalidad:** trabajo individual o en parejas

## Propósito

Aplicar los conceptos de tópicos, productores, consumidores, claves, particiones y offsets mediante operaciones verificables en el entorno Docker del curso.

## Antes de comenzar

**Entorno:** instancia AWS del curso, con Docker accesible sin `sudo`, Kafka 3.9.0 en modo ZooKeeper y los servicios del repositorio ya desplegados.

**Requisitos previos:** haber completado la [Guía 0](Guia_0_Preparacion_Entorno_Kafka_Spark.md); Kafka y ZooKeeper iniciados; acceso a Docker; lectura de los apartados 2.1–2.5 del [libro](Apache_Kafka_Obra_Consolidada_Revision.md). Los comandos se ejecutan **dentro del contenedor Kafka**, salvo indicación contraria. Según la imagen Docker, las utilidades pueden llevar el sufijo `.sh` (por ejemplo, `kafka-topics.sh`). El broker `localhost:9092` de los ejemplos se refiere al interior del contenedor Kafka, no necesariamente al equipo anfitrión.

## Ejercicio 1 — Verificar el broker y crear el tópico (10 min)
En el equipo anfitrión:
```bash
docker ps
docker exec -it kafka bash
```
Dentro del contenedor:
```bash
kafka-topics --bootstrap-server localhost:9092 --list
kafka-topics --bootstrap-server localhost:9092 --create --if-not-exists --topic ventas --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server localhost:9092 --describe --topic ventas
```
**Consigna:** identifique el número de particiones y explique por qué el factor de replicación es 1 en un laboratorio de broker único. Si `ventas` ya existía, no modifique su configuración: registre sus particiones reales.

## Ejercicio 2 — Publicar mensajes desde consola (10 min)
En una terminal del contenedor:
```bash
kafka-console-producer --bootstrap-server localhost:9092 --topic ventas
```
Ingrese tres líneas, por ejemplo `venta V001 12000`, `venta V002 18000` y `venta V003 9500`. Finalice con Ctrl+C.

**Consigna:** explique qué representa cada línea y por qué el texto libre resulta menos conveniente que JSON para un consumidor automatizado.

## Ejercicio 3 — Consumir eventos y reconocer offsets (10 min)
En otra terminal del contenedor:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ventas --from-beginning --property print.partition=true --property print.offset=true
```
Detenga con Ctrl+C tras observar los mensajes. **Consigna:** anote dos pares partición/offset y explique por qué los offsets no constituyen una secuencia global única para todo el tópico.

## Ejercicio 4 — Publicar JSON con claves (15 min)
Ejecute:
```bash
kafka-console-producer --bootstrap-server localhost:9092 --topic ventas --property parse.key=true --property key.separator=:
```
Publique estas tres líneas **sin espacios antes ni después de los dos puntos separadores**:
```text
C-025:{"id_venta":"V004","id_cliente":"C-025","monto_total":12000,"moneda":"CLP"}
C-025:{"id_venta":"V005","id_cliente":"C-025","monto_total":16000,"moneda":"CLP"}
C-031:{"id_venta":"V006","id_cliente":"C-031","monto_total":9000,"moneda":"CLP"}
```
En otra terminal, observe claves y valores:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ventas --from-beginning --property print.key=true --property key.separator=" | "
```
**Consigna:** identifique clave y valor; explique qué ventaja tiene utilizar `id_cliente` como clave. No suponga que el orden entre particiones es global.

## Ejercicio 5 — Comparar grupos de consumidores (15 min)
Abra dos terminales del contenedor y ejecute en cada una:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ventas --group equipo-analitica
```
Publique dos mensajes nuevos desde un tercer terminal. Observe cómo se reparten los registros; después, ejecute un consumidor con otro grupo:
```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic ventas --group equipo-auditoria --from-beginning
```
**Consigna:** compare consumidores del mismo grupo y de grupos distintos. Explique por qué no todos los consumidores del mismo grupo reciben necesariamente todos los mensajes.

## Evidencias de entrega

Un único archivo PDF o Markdown breve con: (1) salida de descripción del tópico; (2) dos pares partición/offset; (3) un ejemplo JSON con clave; (4) respuestas a las consignas de los ejercicios 4 y 5. **No se requiere informe extenso.**

**Criterio de logro:** el estudiante publica y consume eventos y justifica correctamente el papel de las particiones, claves, offsets y grupos. Los resultados exactos pueden variar según el estado previo del tópico y la distribución de particiones.
