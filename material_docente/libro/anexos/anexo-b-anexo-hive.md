# Anexo B. Principales comandos de Apache Hive

Apache Hive incorpora el lenguaje **Hive Query Language (HiveQL)**, el cual permite administrar bases de datos, tablas y consultar grandes volúmenes de información almacenados en HDFS utilizando una sintaxis muy similar a SQL.

Este anexo reúne las instrucciones más utilizadas durante los laboratorios del curso y constituye una guía de referencia rápida para el estudiante.

---

## B.1 Administración de bases de datos

| Operación | Comando |
|-----------|----------|
| Mostrar bases de datos | `SHOW DATABASES;` |
| Crear una base de datos | `CREATE DATABASE nombre_bd;` |
| Seleccionar una base de datos | `USE nombre_bd;` |
| Describir una base de datos | `DESCRIBE DATABASE nombre_bd;` |
| Eliminar una base de datos vacía | `DROP DATABASE nombre_bd;` |
| Eliminar una base de datos con todo su contenido | `DROP DATABASE nombre_bd CASCADE;` |

---

## B.2 Administración de tablas

| Operación | Comando |
|-----------|----------|
| Mostrar tablas | `SHOW TABLES;` |
| Describir una tabla | `DESCRIBE nombre_tabla;` |
| Mostrar descripción extendida | `DESCRIBE FORMATTED nombre_tabla;` |
| Crear una tabla | `CREATE TABLE nombre_tabla (...);` |
| Crear una tabla externa | `CREATE EXTERNAL TABLE nombre_tabla (...);` |
| Eliminar una tabla | `DROP TABLE nombre_tabla;` |
| Cambiar el nombre de una tabla | `ALTER TABLE tabla RENAME TO nueva_tabla;` |
| Agregar una columna | `ALTER TABLE tabla ADD COLUMNS (...);` |

---

## B.3 Carga y manipulación de datos

| Operación | Comando |
|-----------|----------|
| Cargar datos desde HDFS | `LOAD DATA INPATH '/ruta/archivo.csv' INTO TABLE tabla;` |
| Cargar datos sobrescribiendo la tabla | `LOAD DATA INPATH '/ruta/archivo.csv' OVERWRITE INTO TABLE tabla;` |
| Insertar resultados de una consulta | `INSERT INTO TABLE tabla SELECT ...;` |
| Sobrescribir una tabla con una consulta | `INSERT OVERWRITE TABLE tabla SELECT ...;` |

---

## B.4 Consultas HiveQL

| Operación | Comando |
|-----------|----------|
| Consultar todos los registros | `SELECT * FROM tabla;` |
| Seleccionar columnas específicas | `SELECT columna1, columna2 FROM tabla;` |
| Filtrar registros | `SELECT * FROM tabla WHERE condicion;` |
| Ordenar resultados | `SELECT * FROM tabla ORDER BY columna;` |
| Agrupar registros | `SELECT columna, COUNT(*) FROM tabla GROUP BY columna;` |
| Filtrar grupos | `HAVING` |
| Limitar resultados | `LIMIT 10;` |
| Eliminar duplicados | `SELECT DISTINCT columna FROM tabla;` |
| Realizar un JOIN | `SELECT ... FROM tabla1 JOIN tabla2 ON ...;` |

---

## B.5 Particiones

| Operación | Comando |
|-----------|----------|
| Mostrar particiones | `SHOW PARTITIONS tabla;` |
| Agregar una partición | `ALTER TABLE tabla ADD PARTITION (...);` |
| Eliminar una partición | `ALTER TABLE tabla DROP PARTITION (...);` |
| Reparar particiones | `MSCK REPAIR TABLE tabla;` |

---

## B.6 Vistas

| Operación | Comando |
|-----------|----------|
| Crear una vista | `CREATE VIEW vista AS SELECT ...;` |
| Mostrar vistas | `SHOW TABLES;` |
| Eliminar una vista | `DROP VIEW vista;` |

---

## B.7 Funciones de agregación

| Función | Descripción |
|----------|-------------|
| `COUNT()` | Cuenta registros. |
| `SUM()` | Suma valores. |
| `AVG()` | Calcula el promedio. |
| `MIN()` | Obtiene el valor mínimo. |
| `MAX()` | Obtiene el valor máximo. |

---

## B.8 Funciones de fecha

| Función | Descripción |
|----------|-------------|
| `CURRENT_DATE` | Fecha actual. |
| `CURRENT_TIMESTAMP` | Fecha y hora actuales. |
| `YEAR()` | Obtiene el año. |
| `MONTH()` | Obtiene el mes. |
| `DAY()` | Obtiene el día. |
| `DATEDIFF()` | Diferencia entre fechas. |

---

## B.9 Comandos de utilidad

| Operación | Comando |
|-----------|----------|
| Mostrar configuración | `SET;` |
| Mostrar una propiedad | `SET propiedad;` |
| Salir de Hive | `EXIT;` o `QUIT;` |
| Mostrar ayuda | `HELP;` |

---

## B.10 Recomendaciones

Antes de ejecutar consultas en Apache Hive, se recomienda verificar que:

- El servicio HDFS se encuentre operativo.
- El Metastore esté disponible y correctamente configurado.
- La base de datos seleccionada sea la adecuada (`USE nombre_bd;`).
- Las tablas se encuentren correctamente registradas en el Metastore.
- Los archivos de datos estén disponibles en HDFS y posean los permisos correspondientes.
- Se utilicen particiones y formatos columnares (como ORC o Parquet) cuando se trabaje con grandes volúmenes de información, ya que mejoran significativamente el rendimiento de las consultas.

A lo largo de los siguientes capítulos, estos comandos serán utilizados para preparar conjuntos de datos que posteriormente serán procesados mediante **Apache Spark**, integrados con **Apache Kafka** o automatizados utilizando **Apache NiFi**, consolidando así el flujo de procesamiento dentro del ecosistema Hadoop.
