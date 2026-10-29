# Estado de continuidad — Semana 12 Apache Kafka (INACAP)

**Última actualización:** 29 de octubre de 2026. **Repositorio:** juliopez/Hadoop. **Rama de trabajo:** documentacion-kafka-parte-ii. **Directorio:** Semana_12_Kafka/.

## Objetivo y reglas de continuidad

Preparar un libro teórico unificado sobre Apache Kafka y dos guías prácticas independientes para Big Data. **No resumir ni eliminar material original.** Los 11 documentos fuente deben permanecer intactos. No confundir la validación técnica en el equipo docente con la versión publicable para estudiantes. Mantener las guías separadas del libro y registrar cada resultado antes de avanzar. Evitar repetir verificaciones ya aprobadas; proporcionar instrucciones de terminal acotadas, una por vez.

## Archivos importantes

- `Apache_Kafka_Obra_Consolidada_Revision.md`: libro unificado de 11 fuentes (Parte I + Parte II), 18 apartados (1.1–1.8 y 2.1–2.10), 75 figuras SVG. Jerarquía de títulos y anchura de imágenes normalizadas. Revisión visual aprobada por el docente. Pendiente maquetación editorial final si se solicita.
- `AUDITORIA_EDITORIAL_KAFKA.md`: auditoría de consolidación.
- `Guia_Practica_1_Kafka.md`: cinco ejercicios de Kafka; el docente aprobó los ejercicios 1, 2, 3, 4 y 5 en pruebas de terminal.
- `Guia_Practica_2_Kafka_Spark.md`: cinco ejercicios propuestos, 60 minutos, inicialmente basados en API local de ventas; se añadió al final un registro de validación docente USGS–Kafka y diagnóstico de Spark. **No sustituir el caso de ventas sin decidirlo explícitamente.**
- `Semana_12_KAFKA_con_figuras.md` y `Parte_II_2.1.md`…`Parte_II_2.10.md`: originales, preservar.

## Pruebas prácticas aprobadas (29-10-2026)

1. Se consultó la API real del USGS: `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson`, con respuesta GeoJSON válida y eventos variables por hora.
2. Kafka en Docker: tópico `sismos_usgs`, 3 particiones, factor de replicación 1. El broker estaba operativo.
3. Python en Ubuntu: proyecto de prueba `~/kafka_usgs`, entorno virtual `~/kafka_usgs/.venv`, archivo `productor_usgs.py`, biblioteca `kafka-python`.
4. Inicialmente hubo `KafkaTimeoutError` / `DNS Resolution failure` aunque la conexión TCP a 9092 funcionaba. Diagnóstico: broker anunciaba `505b7c6c3bcb:9092` (ID 101), no resoluble desde el anfitrión. En el equipo docente se habilitó temporalmente resolución mediante `/etc/hosts` hacia `172.27.1.16`; **no es una solución reproducible para los estudiantes**. Revisar `advertised.listeners` y conectividad entre contenedores.
5. Publicación desde Python a `sismos_usgs` confirmada: cuatro sismos JSON con ID, magnitud, partición y offset. Ejemplos: partición 0 offsets 0, 1, 2; partición 1 offset 0. Aparecieron advertencias de deprecación de serializadores, no errores de publicación.
6. Lectura desde `KafkaConsumer` confirmada: los cuatro eventos, con magnitud, partición y offset; orden de lectura entre particiones no necesariamente igual al orden de publicación.
7. Spark: contenedor `spark-master`, binario `/spark/bin/spark-submit`, Spark 2.4.0, Scala 2.11.12, Java 8. `SPARK_HOME` no estaba definido en la shell y `spark-submit` no estaba en el PATH. No se encontraron jars Kafka SQL en `/spark/jars`.
8. Conector candidato: `org.apache.spark:spark-sql-kafka-0-10_2.11:2.4.0`. Una prueba inicial de conectividad con `python` dentro del contenedor falló con `ImportError: No module named request` al intentar `urllib.request` (posible Python 2). **La prueba siguiente con curl/wget devolvió HTTP 200 para el POM del conector en Maven Central** (resultado comunicado por el docente). Esto valida el acceso al POM, **no** la descarga de dependencias ni la ejecución del conector.

## Estado actual y próximo paso único

**Pendiente inmediato:** comprobar que `/spark/bin/spark-submit` puede resolver el paquete Kafka de Spark 2.4.0 / Scala 2.11 y sus dependencias desde Maven Central. Luego verificar que el contenedor Spark pueda conectarse al listener Kafka accesible desde su propia red, iniciar un stream desde `sismos_usgs` y observar resultados. Finalmente validar checkpoints y recuperación.

**No validado:** integración Spark Structured Streaming con USGS/Kafka, descarga efectiva del conector, checkpoints, y versión definitiva de la Guía 2 para estudiantes. Evitar presentarlos como completados.

## Consideraciones pedagógicas

La Guía 1 está aprobada. La Guía 2 debe ser de dificultad intermedia-alta, duración aproximada 60 minutos, cinco ejercicios, con scripts facilitados y entorno preparado previamente. El caso real USGS se ha validado hasta Kafka y puede sustituir el caso ficticio de ventas si se decide. Mantener el libro teórico sin cambios salvo necesidad académica justificada; registrar soluciones técnicas en la guía docente o este documento, no sobrecargar el texto para estudiantes.

## Prompt de reanudación sugerido

> Continúa el proyecto INACAP Big Data / Semana 12 Apache Kafka en el repositorio `juliopez/Hadoop`, rama `documentacion-kafka-parte-ii`. Lee primero `Semana_12_Kafka/ESTADO_CONTINUIDAD_KAFKA.md` y `Semana_12_Kafka/Guia_Practica_2_Kafka_Spark.md`. Respeta los ejercicios ya aprobados y las fuentes originales. Estamos validando la integración Spark 2.4.0 / Scala 2.11 con el tópico `sismos_usgs` alimentado por la API real USGS. Maven Central respondió HTTP 200 para el POM del conector; falta verificar descarga y ejecución. Propón una sola comprobación por turno, interpreta la salida y actualiza el registro en GitHub conforme avancemos.
