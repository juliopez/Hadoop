# 2.2. Administración de tópicos, particiones y configuración básica

## 2.2.1. De la disponibilidad del broker a la organización de los eventos

En el apartado anterior estudiamos cómo identificar y verificar los servicios Kafka y ZooKeeper dentro de nuestra infraestructura Docker. Comprendimos que la ejecución de un contenedor no garantiza, por sí sola, la disponibilidad funcional del broker y que es necesario comprobar tanto su estado como la conectividad de los clientes.

Una vez establecido ese entorno, el siguiente paso consiste en comprender cómo se organizan y administran los eventos que circulan por Kafka. Kafka no funciona como una base de datos relacional tradicional. Los productores publican registros en flujos de eventos, mientras que los consumidores recuperan esos registros de acuerdo con sus necesidades y posiciones de lectura.

Para organizar estos flujos, Kafka utiliza **tópicos (*topics*)**, que representan categorías lógicas de eventos. Una empresa comercial podría generar eventos relacionados con ventas, pagos, inventario, despachos y devoluciones. En nuestro curso utilizaremos como ejemplo transversal una empresa que registra transacciones comerciales en tiempo real.

## 2.2.2. El tópico como unidad lógica de organización

Un tópico es una categoría identificada mediante un nombre, en la cual los productores publican eventos y desde la cual los consumidores pueden recuperarlos.

| Tópico | Eventos que representa |
|---|---|
| `ventas` | Ventas realizadas |
| `pagos` | Pagos autorizados o rechazados |
| `inventario` | Cambios en las existencias |
| `despachos` | Preparación y envío de pedidos |
| `devoluciones` | Productos devueltos por clientes |

Un tópico no es simplemente una carpeta que contiene archivos: Kafka administra sus registros mediante particiones, offsets y políticas de conservación. Un mismo tópico puede recibir eventos de múltiples productores y ser leído por diferentes aplicaciones consumidoras.

![Figura 38. Organización de eventos comerciales mediante tópicos Kafka](imagenes/figura_38.svg)

*Figura 38. Organización de eventos comerciales mediante tópicos Kafka.*

## 2.2.3. Las particiones y su función en la arquitectura de Kafka

Kafka almacena los eventos de cada tópico en una o varias **particiones (*partitions*)**. Cada partición es un registro ordenado y de solo anexado (*append-only log*). Supongamos que `ventas` dispone de tres particiones. Los eventos se distribuyen entre ellas según la configuración y el comportamiento del productor.

![Figura 39. Tópico ventas dividido en tres particiones](imagenes/figura_39.svg)

*Figura 39. Tópico `ventas` dividido en tres particiones.*

**Kafka garantiza el orden de los registros dentro de cada partición, pero no un orden total entre todas las particiones de un tópico.** Si una empresa necesita preservar el orden de las operaciones de un cliente, puede utilizar su identificador como clave de particionamiento. Bajo una estrategia consistente, los eventos asociados con esa clave se dirigirán a la misma partición. Modificar la cantidad de particiones puede alterar esa asignación para los eventos futuros.

## 2.2.4. Los offsets: identificación de la posición de los eventos

Dentro de cada partición, Kafka asigna a los registros un identificador de posición denominado **offset**.

| Partición | Offset | Evento |
|---|---:|---|
| 0 | 0 | Venta A |
| 0 | 1 | Venta B |
| 0 | 2 | Venta C |
| 1 | 0 | Venta D |
| 1 | 1 | Venta E |
| 2 | 0 | Venta F |

El offset 0 aparece en las tres particiones sin que exista duplicación de identificadores, porque cada offset pertenece a una partición diferente. Para identificar la posición de un evento se consideran tópico, partición y offset. Los consumidores mantienen posiciones de lectura independientes. Leer un evento no lo elimina: su permanencia depende de las políticas de conservación. Retención y compactación pueden provocar que algunos offsets antiguos ya no correspondan a registros recuperables.

## 2.2.5. Creación de tópicos y parámetros básicos

Kafka proporciona herramientas para crear, describir, modificar y eliminar tópicos. Una operación de referencia es:

```bash
kafka-topics --bootstrap-server localhost:9092 \
  --create \
  --topic ventas \
  --partitions 3 \
  --replication-factor 1
```

| Parámetro | Función |
|---|---|
| `--bootstrap-server localhost:9092` | Dirección inicial para conectarse al broker |
| `--create` | Solicita la creación de un tópico |
| `--topic ventas` | Define el nombre |
| `--partitions 3` | Establece tres particiones |
| `--replication-factor 1` | Establece una réplica por partición |

El factor de replicación 1 es coherente con el laboratorio de un único broker. No se pueden distribuir tres réplicas de una misma partición entre brokers distintos si solo existe uno.

**Compatibilidad:** la sintaxis basada en `--bootstrap-server` debe verificarse contra las herramientas efectivamente disponibles en la imagen `landoop/fast-data-dev:latest`. Algunas versiones antiguas utilizan parámetros asociados con ZooKeeper.

## 2.2.6. Consulta y descripción de tópicos

```bash
kafka-topics --bootstrap-server localhost:9092 --list
```

```bash
kafka-topics --bootstrap-server localhost:9092 \
  --describe \
  --topic ventas
```

La descripción permite consultar cantidad de particiones, factor de replicación, líderes y réplicas asignadas. En nuestro laboratorio la distribución será sencilla; en entornos de producción, estos datos permiten analizar la distribución entre múltiples brokers.

## 2.2.7. Replicación, liderazgo y tolerancia a fallos

Cada partición dispone de una réplica líder y puede disponer de réplicas adicionales. El líder atiende las escrituras y lecturas ordinarias; las réplicas seguidoras mantienen copias sincronizadas del registro.

![Figura 40. Partición sin redundancia frente a partición replicada](imagenes/figura_40.svg)

*Figura 40. Diferencia entre una partición sin redundancia y una partición replicada.*

El particionamiento distribuye registros entre secuencias de almacenamiento; la replicación mantiene copias de una misma partición. En un único broker con factor de replicación 1, la falla del broker interrumpe la disponibilidad de las particiones alojadas en él. La infraestructura docente no representa una arquitectura de alta disponibilidad.

## 2.2.8. Configuración de retención y conservación de eventos

Kafka no elimina automáticamente los eventos después de su lectura. Las políticas de retención temporal y por tamaño determinan qué registros pueden conservarse.

- `retention.ms`: período de retención temporal expresado en milisegundos.
- `retention.bytes`: límite de retención por tamaño aplicado por partición.

La eliminación no necesariamente ocurre exactamente cuando se alcanza el límite: intervienen los segmentos y los procesos de limpieza. Kafka también ofrece **compactación del registro (*log compaction*)**, orientada a conservar registros recientes asociados con claves, útil para representar el último estado conocido de una entidad.

## 2.2.9. Modificación de particiones y administración del ciclo de vida

Kafka permite aumentar la cantidad de particiones de un tópico, por ejemplo, de tres a seis. Esto puede ampliar el paralelismo del consumo, pero también alterar la asignación de claves a particiones futuras. **Aumentar las particiones no redistribuye automáticamente los registros históricos**. Eliminar un tópico puede implicar pérdida de datos y exige procedimientos controlados en producción.

## 2.2.10. Criterios para diseñar tópicos en un sistema de transacciones comerciales

Separar `ventas`, `pagos` e `inventario` facilita la delimitación de responsabilidades, aunque crear demasiados tópicos también aumenta la complejidad.

| Criterio | Pregunta de diseño |
|---|---|
| Propósito | ¿Qué proceso representa el evento? |
| Productores | ¿Qué sistemas generan registros? |
| Consumidores | ¿Quiénes necesitan leerlos? |
| Ordenamiento | ¿Qué eventos deben mantener secuencia? |
| Volumen | ¿Cuántos eventos se publicarán? |
| Paralelismo | ¿Cuántas particiones son necesarias? |
| Conservación | ¿Durante cuánto tiempo se requieren los datos? |
| Disponibilidad | ¿Qué tolerancia a fallos se necesita? |

![Figura 41. Decisiones de diseño de un tópico de transacciones](imagenes/figura_41.svg)

*Figura 41. Decisiones de diseño para un tópico de transacciones comerciales.*

## 2.2.11. Síntesis del apartado

La administración de tópicos combina operaciones técnicas y decisiones arquitectónicas. Los tópicos organizan los flujos; las particiones almacenan secuencias de registros; los offsets identifican posiciones; la replicación aporta redundancia; y la retención determina la conservación. En el apartado **2.3** estudiaremos cómo los productores publican eventos en estos tópicos.
