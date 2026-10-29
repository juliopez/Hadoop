# Auditoría editorial preliminar — Apache Kafka

**Rama:** `documentacion-kafka-parte-ii`  
**Fuentes:** `Semana_12_KAFKA_con_figuras.md` y `Parte_II_2.1.md` a `Parte_II_2.10.md` (11 archivos).  
**Documento de revisión:** `Apache_Kafka_Obra_Consolidada_Revision.md`.

## Resultados comprobados

- Se localizaron y recuperaron los once documentos.
- Los documentos originales suman aproximadamente 282.709 caracteres.
- Se identificaron 75 referencias a figuras SVG, numeradas consecutivamente del 1 al 75.
- El árbol de GitHub confirma 75 archivos `Semana_12_Kafka/imagenes/figura_N.svg`.
- En la versión consolidada, las 75 referencias de imágenes resuelven a rutas existentes.
- Los bloques de código Markdown de la versión consolidada tienen delimitadores equilibrados.
- Se mantienen los ocho apartados de la Parte I y los diez apartados de la Parte II.

## Correcciones aplicadas solo a la versión consolidada

1. Reconstrucción limpia del índice de ambas partes, eliminando secuencias de exportación `&#x20;` y saltos de línea escapados.
2. Actualización de 35 rutas de figuras en la Parte I: de `kafka_figuras/svg/figura_NN.svg` a `imagenes/figura_NN.svg`.
3. Restauración de los saltos de línea y la indentación del ejemplo conceptual de API REST en 1.7.5.
4. Incorporación de un título separador de Parte II y eliminación de un encabezado duplicado de volumen en el apartado 2.10.
5. Concatenación íntegra de los once textos de origen, salvo las correcciones anteriores de formato.

## Aspectos pendientes de auditoría sustantiva

**Prioridad alta — integridad editorial:** los apartados 2.2 a 2.8 podrían ser versiones abreviadas respecto de los borradores aprobados en conversación. La comparación literal requiere disponer de esas versiones originales; no se ha reconstruido texto faltante ni se ha declarado equivalencia textual sin evidencia.

**Prioridad alta — validación práctica:** comprobar comandos, nombres de contenedores, listeners, versión de Kafka, compatibilidad Spark 2.4 / Scala 2.11, dependencias y scripts reales contra el laboratorio Docker. No se han ejecutado los ejercicios.

**Prioridad media — coherencia técnica:** revisar transversalmente esquema JSON, claves de evento, control de duplicados, offsets, grupos de consumidores, checkpoints y semántica de procesamiento Near Real-Time.

**Prioridad media — edición:** revisar estilo de figuras, pies, referencias bibliográficas, la referencia externa a una imagen de LinkedIn/ByteByteGo y el sistema de títulos del libro. El archivo consolidado es un borrador editorial, no la edición final.

## Criterio de preservación

Los once documentos fuente permanecen sin modificar. La versión consolidada es independiente y se debe usar como base de revisión hasta concluir las verificaciones pendientes.
