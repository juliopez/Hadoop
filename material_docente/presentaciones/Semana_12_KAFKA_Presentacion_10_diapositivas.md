# Apache Kafka — Guion de presentación (10 diapositivas)

> Material derivado de [Semana_12_KAFKA.md](Semana_12_KAFKA.md). Guion sintético que acompaña el archivo PowerPoint editable. No reemplaza el material teórico completo.

| N.º | Diapositiva | Idea esencial | Apartado de origen |
| --- | --- | --- | --- |
| 1 | Apache Kafka: del batch a los eventos | Los datos pueden procesarse después de acumularse o circular como eventos durante la operación. | 1.1 |
| 2 | ¿Por qué aparece Kafka? | Distribución a múltiples sistemas, desacoplamiento y conservación de eventos según retención. | 1.3 |
| 3 | Casos de uso | Comercio electrónico, telemetría IoT y monitoreo de eventos. | 1.8 |
| 4 | Arquitectura básica | Productores publican; brokers organizan por tópicos; consumidores leen. | 1.4 |
| 5 | Particiones y offsets | Los eventos tienen orden y offsets dentro de una partición, no un offset global. | 1.5 |
| 6 | Replicación y grupos de consumidores | Réplicas contribuyen a disponibilidad; grupos distribuyen trabajo entre consumidores. | 1.5 |
| 7 | Batch, Near Real-Time y tiempo real | Kafka no garantiza por sí solo restricciones estrictas de latencia. | 1.6 |
| 8 | Mensajes con estructura | Datos JSON, claves y marcas temporales facilitan interpretación e integración. | 2.5 |
| 9 | API REST → Python → Kafka → Spark | El productor obtiene y publica; Kafka distribuye; Spark procesa, con checkpoints. | 2.6–2.9 |
| 10 | Kafka en el ecosistema Big Data | Kafka transporta eventos; Spark procesa; HDFS/Hive almacenan y permiten consultar. | 1.7 y 2.9 |

## Criterio de uso

La presentación se propone como apoyo visual para una exposición breve de fundamentos. El estudiante debe profundizar en el documento teórico, practicar con las guías y experimentar con el simulador.

La presentación ha sido preparada en formato PowerPoint y PDF en esta conversación; el archivo binario debe incorporarse a este directorio con el nombre `Semana_12_KAFKA_ppt.pptx` cuando esté disponible la carga de binarios.
