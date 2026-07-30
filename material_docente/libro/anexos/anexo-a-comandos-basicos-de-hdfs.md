# Anexo A. Comandos básicos de HDFS

A lo largo de este libro se utilizará la interfaz de línea de comandos de HDFS para administrar el sistema de archivos distribuido. La siguiente tabla reúne los comandos más utilizados durante los laboratorios y constituye una guía de consulta rápida para el estudiante.

## A.1 Comandos de administración de archivos

| Operación | Comando |
|-----------|----------|
| Mostrar directorio actual | `hdfs dfs -pwd` |
| Listar contenido de un directorio | `hdfs dfs -ls /` |
| Listar directorios de forma recursiva | `hdfs dfs -ls -R /` |
| Crear un directorio | `hdfs dfs -mkdir /datos` |
| Crear directorios anidados | `hdfs dfs -mkdir -p /datos/ventas/2026` |
| Copiar un archivo local hacia HDFS | `hdfs dfs -put ventas.csv /datos/ventas` |
| Copiar múltiples archivos | `hdfs dfs -put *.csv /datos/ventas` |
| Descargar un archivo desde HDFS | `hdfs dfs -get /datos/ventas/ventas.csv` |
| Descargar un directorio completo | `hdfs dfs -get /datos/ventas ./ventas` |
| Copiar un archivo dentro de HDFS | `hdfs dfs -cp /datos/A.csv /backup/A.csv` |
| Mover o renombrar un archivo | `hdfs dfs -mv archivo.csv archivo_respaldo.csv` |
| Mover un archivo a otro directorio | `hdfs dfs -mv archivo.csv /historico/` |
| Mostrar el contenido de un archivo | `hdfs dfs -cat archivo.csv` |
| Mostrar las primeras líneas | `hdfs dfs -head archivo.csv` |
| Mostrar las últimas líneas | `hdfs dfs -tail archivo.csv` |
| Mostrar tamaño de archivos y directorios | `hdfs dfs -du -h /datos` |
| Mostrar espacio disponible del clúster | `hdfs dfs -df -h` |
| Contar archivos, directorios y tamaño | `hdfs dfs -count /datos` |
| Cambiar permisos | `hdfs dfs -chmod 755 archivo.csv` |
| Cambiar propietario | `hdfs dfs -chown usuario:grupo archivo.csv` |
| Eliminar un archivo | `hdfs dfs -rm archivo.csv` |
| Eliminar un directorio | `hdfs dfs -rm -r /datos` |
| Vaciar la papelera de reciclaje | `hdfs dfs -expunge` |

---

## A.2 Comandos de administración del clúster

| Operación | Comando |
|-----------|----------|
| Iniciar HDFS | `start-dfs.sh` |
| Detener HDFS | `stop-dfs.sh` |
| Mostrar procesos Hadoop activos | `jps` |
| Obtener el estado del clúster | `hdfs dfsadmin -report` |
| Consultar el modo seguro | `hdfs dfsadmin -safemode get` |
| Activar el modo seguro | `hdfs dfsadmin -safemode enter` |
| Desactivar el modo seguro | `hdfs dfsadmin -safemode leave` |
| Balancear el almacenamiento entre DataNodes | `hdfs balancer` |
| Verificar la integridad del sistema de archivos | `hdfs fsck /` |

---

## A.3 Recomendaciones

Antes de ejecutar cualquiera de los comandos anteriores, verifique que:

- El servicio HDFS se encuentre iniciado correctamente.
- El NameNode y los DataNodes estén operativos.
- El usuario tenga permisos suficientes sobre los archivos y directorios involucrados.
- Los comandos se ejecuten desde un nodo que tenga instalado Hadoop y acceso al clúster.

Durante los laboratorios de este libro se utilizarán estos comandos de manera progresiva, incorporando nuevos ejemplos a medida que se estudien herramientas como Apache Hive, Apache Spark, Apache Kafka y Apache NiFi.
