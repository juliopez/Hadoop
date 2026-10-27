# Datasets de evaluación Spark 2026

Caso: Comercializadora Andes. Los archivos CSV deben descargarse al equipo del estudiante y cargarse en su propio HDFS antes de procesarlos con PySpark.

## Esquemas
- ventas_evaluacion.csv: id_venta,fecha,cliente,ciudad,categoria,monto (100000 transacciones sintéticas)
- ciudades.csv: ciudad,region,zona (Forma A)
- zonas_comerciales.csv: ciudad,zona_comercial,prioridad (Forma B)
- clientes.csv: cliente,segmento,antiguedad (Forma C)

## Entornos admitidos
- AWS + Docker (requiere transferencia remota, p. ej. scp)
- Docker local
- Docker dentro de máquina virtual local

La evidencia de preparación debe reflejar la ruta efectivamente utilizada. No se exige scp a estudiantes que trabajan localmente. Todos deben verificar que los CSV llegaron al contenedor y a HDFS.

## Estado de publicación
Los CSV grandes se prepararon y validaron localmente, pero **aún no se han incorporado a GitHub**. No publicar enlaces raw hasta completar su carga. Los datos de control y la pauta docente deben mantenerse fuera del repositorio público.
