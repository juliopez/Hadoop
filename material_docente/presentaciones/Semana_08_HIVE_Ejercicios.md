# Semana 8 — Ejercicios progresivos con Apache Hive

## Bloque 1 — Preparación del conjunto de datos

## 1. Propósito de la actividad

En la guía anterior aprendimos los principales comandos necesarios para trabajar con Apache Hive y comprendimos su relación con HDFS.

En esta segunda guía cambiaremos el enfoque.

Ya no avanzaremos comando por comando.

Trabajaremos con una serie de ejercicios organizados en **cuatro niveles de dificultad**, desde el nivel 0 hasta el nivel 3.

```text
NIVEL 0
Fundamentos
    ↓
NIVEL 1
Filtrado y transformación
    ↓
NIVEL 2
Análisis
    ↓
NIVEL 3
Resolución de problemas
````

Cada nivel contendrá cuatro ejercicios.

A medida que avancemos:

* disminuirá la cantidad de código proporcionado;
* aumentará la cantidad de decisiones que deberá tomar;
* las consultas requerirán combinar progresivamente diferentes operaciones de HiveQL.

Al finalizar encontrará además **tres desafíos sin código de apoyo**.

En ellos deberá determinar por sí mismo cómo transformar un problema analítico en una consulta HiveQL, utilizando como referencia esta guía y la guía de comandos de Apache Hive.

---

## 2. Un único conjunto de datos

Durante toda la actividad utilizaremos **el mismo conjunto de datos**.

Esto es importante.

No queremos que cada nuevo ejercicio implique comprender un archivo diferente.

Queremos concentrarnos en aprender a consultar y analizar progresivamente los mismos datos.

Trabajaremos con información ficticia de ventas que tendrá seis variables:

| Variable    | Descripción                       | Ejemplo        |
| ----------- | --------------------------------- | -------------- |
| `id_venta`  | Identificador único de la venta   | `15432`        |
| `fecha`     | Fecha en que se realizó la venta  | `2026-05-17`   |
| `cliente`   | Identificador del cliente         | `Cliente_0245` |
| `ciudad`    | Ciudad donde se registra la venta | `Valparaiso`   |
| `categoria` | Categoría del producto vendido    | `Tecnologia`   |
| `monto`     | Monto total de la venta           | `185990`       |

El archivo contendrá:

```text
100.000 registros
```

y será almacenado en formato:

```text
CSV
```

El objetivo no es simular un verdadero escenario de Big Data mediante solamente 100.000 registros.

Utilizaremos este volumen porque resulta suficientemente grande para realizar diferentes consultas y análisis durante el laboratorio, pero continúa siendo manejable dentro de nuestro entorno académico.

---

## 3. ¿Por qué utilizaremos CSV?

Apache Hive puede trabajar con diferentes formatos de almacenamiento.

En esta actividad utilizaremos CSV porque nos permite observar directamente los datos.

Por ejemplo:

```text
1,2026-01-15,Cliente_0352,Santiago,Tecnologia,245900
2,2026-03-22,Cliente_0108,Valparaiso,Hogar,85990
3,2026-06-04,Cliente_0741,Concepcion,Deportes,129990
```

Podemos identificar fácilmente:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

Esto nos permitirá concentrarnos en Hive y HiveQL.

En actividades posteriores podremos trabajar con formatos especialmente diseñados para procesamiento analítico distribuido.

---

# 4. Generar los datos con Python

En lugar de descargar un dataset, lo generaremos mediante Python.

Esto tiene una ventaja adicional:

> **Podemos controlar exactamente la estructura y características de los datos con los que trabajaremos.**

Cree un archivo denominado:

```text
generar_ventas.py
```

e incorpore el siguiente código:

```python
import csv
import random
from datetime import datetime, timedelta

# --------------------------------------------------
# CONFIGURACIÓN
# --------------------------------------------------

CANTIDAD_REGISTROS = 100_000
ARCHIVO_SALIDA = "ventas_hive.csv"

# Utilizamos una semilla fija para que todos los
# estudiantes generen el mismo conjunto de datos.
random.seed(2026)

# --------------------------------------------------
# VALORES POSIBLES
# --------------------------------------------------

ciudades = [
    "Santiago",
    "Valparaiso",
    "Concepcion",
    "La_Serena",
    "Antofagasta",
    "Temuco",
    "Puerto_Montt",
    "Rancagua"
]

categorias = [
    "Tecnologia",
    "Hogar",
    "Deportes",
    "Vestuario",
    "Alimentos"
]

fecha_inicio = datetime(2024, 1, 1)
fecha_fin = datetime(2026, 12, 31)

dias_disponibles = (fecha_fin - fecha_inicio).days

# --------------------------------------------------
# GENERACIÓN DEL ARCHIVO
# --------------------------------------------------

with open(ARCHIVO_SALIDA, "w", newline="", encoding="utf-8") as archivo:

    escritor = csv.writer(archivo)

    for id_venta in range(1, CANTIDAD_REGISTROS + 1):

        fecha = fecha_inicio + timedelta(
            days=random.randint(0, dias_disponibles)
        )

        cliente = f"Cliente_{random.randint(1, 2000):04d}"

        ciudad = random.choice(ciudades)

        categoria = random.choice(categorias)

        monto = round(random.uniform(5000, 1500000), 2)

        escritor.writerow([
            id_venta,
            fecha.strftime("%Y-%m-%d"),
            cliente,
            ciudad,
            categoria,
            monto
        ])

print(f"Archivo generado: {ARCHIVO_SALIDA}")
print(f"Registros generados: {CANTIDAD_REGISTROS:,}")
```

---

# 5. Ejecutar el programa

Ejecute:

```bash
python3 generar_ventas.py
```

Debería obtener un mensaje similar a:

```text
Archivo generado: ventas_hive.csv
Registros generados: 100,000
```

Ahora compruebe que el archivo existe:

```bash
ls -lh ventas_hive.csv
```

---

# 6. Inspeccionar antes de cargar

Nunca deberíamos cargar un archivo sin conocer mínimamente su contenido.

Observe sus primeras filas:

```bash
head ventas_hive.csv
```

Debería encontrar registros con una estructura similar a:

```text
1,2025-08-14,Cliente_0187,Santiago,Tecnologia,584320.45
2,2024-11-03,Cliente_1241,Concepcion,Hogar,156890.22
3,2026-02-21,Cliente_0782,Valparaiso,Deportes,921450.18
```

Los valores exactos dependerán del proceso de generación, pero la estructura será:

```text
id_venta,fecha,cliente,ciudad,categoria,monto
```

Compruebe también la cantidad de registros:

```bash
wc -l ventas_hive.csv
```

El resultado esperado es:

```text
100000 ventas_hive.csv
```

---

# 7. Una observación importante: el archivo todavía no está en HDFS

En este momento tenemos:

```text
ventas_hive.csv
```

pero debemos distinguir cuidadosamente:

```text
SISTEMA DE ARCHIVOS LOCAL
        │
        └── ventas_hive.csv
```

de:

```text
HDFS
        │
        └── ?
```

Generar el archivo mediante Python **no significa que los datos estén almacenados en HDFS**.

Este punto será fundamental durante toda la actividad.

Nuestro recorrido será:

```text
PYTHON
   │
   ▼
ventas_hive.csv
   │
   │ archivo local
   ▼
hdfs dfs -put
   │
   ▼
HDFS
   │
   ▼
/curso/hive/datos_ventas/
   │
   ▼
ventas_hive.csv
```

Solamente después de realizar esta operación consideraremos que el dataset está disponible para nuestro trabajo con Hive.

---

# 8. Regla de trabajo para toda la guía

A partir del siguiente bloque adoptaremos una regla:

> **Los datos utilizados por nuestros ejercicios estarán almacenados en HDFS.**

Hive proporcionará la estructura lógica que nos permitirá interpretarlos y consultarlos.

Por tanto, debemos mantener claramente separados dos conceptos:

```text
HDFS
¿Dónde están almacenados los datos?

             +

HIVE
¿Cómo están estructurados y cómo puedo consultarlos?
```

En el siguiente bloque realizaremos precisamente esta conexión:

```text
ventas_hive.csv
        ↓
      HDFS
        ↓
CREATE EXTERNAL TABLE
        ↓
      HIVE
        ↓
      HiveQL
```

---

## Bloque 2 — De HDFS a Hive: preparación del entorno de trabajo

En el bloque anterior generamos mediante Python un único conjunto de datos:

```text
ventas_hive.csv
````

El archivo contiene:

```text
100.000 registros
6 variables
```

y representa ventas realizadas entre los años 2024 y 2026.

Hasta este momento el archivo existe en el **sistema de archivos local** del entorno donde ejecutamos Python.

Ahora realizaremos el paso fundamental:

> **almacenar los datos en HDFS y crear en Hive una tabla externa que permita interpretarlos y consultarlos.**

Este procedimiento será realizado una sola vez.

Todos los ejercicios posteriores utilizarán **los mismos datos almacenados en HDFS y la misma tabla de Hive**.

---

# 1. Nuestro objetivo

Queremos construir el siguiente recorrido:

```text
ventas_hive.csv
      │
      │ archivo local
      ▼
hdfs dfs -put
      │
      ▼
HDFS
      │
      ▼
/curso/hive/datos_ventas/
      │
      └── ventas_hive.csv
              │
              │ LOCATION
              ▼
        ventas_hive
              │
              ▼
           HiveQL
```

Observe que los datos no serán trasladados desde HDFS hacia Hive.

Hive simplemente utilizará una estructura lógica que le permitirá interpretar los archivos almacenados en HDFS.

---

# 2. Verificar dónde estamos trabajando

Antes de continuar, recuerde la arquitectura utilizada en nuestro laboratorio:

```text
COMPUTADOR PERSONAL
        │
        │ SSH
        ▼
AWS EC2
        │
        │ Docker
        ▼
CONTENEDOR hive-server
        │
        ├── Hive
        │
        └── acceso a HDFS
```

Desde EC2 podemos comprobar los contenedores disponibles mediante:

```bash
sudo docker ps
```

Debemos encontrar, entre otros:

```text
namenode
datanode
hive-server
hive-metastore
hive-metastore-postgresql
```

Para esta actividad trabajaremos principalmente desde:

```text
hive-server
```

---

# 3. Ingresar al contenedor de Hive

Desde EC2 ejecute:

```bash
sudo docker exec -it hive-server bash
```

Compruebe el cambio de contexto:

```bash
hostname
```

y:

```bash
pwd
```

A partir de este momento estamos trabajando dentro del contenedor:

```text
hive-server
```

---

# 4. Verificar que el archivo está disponible

Antes de intentar cargar los datos en HDFS, compruebe que el archivo generado en el bloque anterior se encuentra disponible en el entorno desde el cual realizará la operación.

Ejecute:

```bash
ls -lh ventas_hive.csv
```

Luego:

```bash
head ventas_hive.csv
```

Finalmente:

```bash
wc -l ventas_hive.csv
```

Debemos comprobar tres cosas:

```text
¿Existe el archivo?
        ↓
¿Tiene la estructura esperada?
        ↓
¿Contiene 100.000 registros?
```

No continúe hasta haber verificado estos tres elementos.

---

# 5. Crear el directorio de trabajo en HDFS

Crearemos una ubicación específica para nuestro dataset:

```bash
hdfs dfs -mkdir -p /curso/hive/datos_ventas
```

Ahora compruebe:

```bash
hdfs dfs -ls /curso/hive
```

Debería aparecer:

```text
/curso/hive/datos_ventas
```

Hasta este momento hemos creado solamente el directorio.

Todavía no hemos incorporado el archivo.

---

# 6. Cargar el dataset en HDFS

Ejecute:

```bash
hdfs dfs -put ventas_hive.csv /curso/hive/datos_ventas/
```

Ahora los datos deben encontrarse en:

```text
HDFS
│
└── /curso
      └── hive
           └── datos_ventas
                 └── ventas_hive.csv
```

---

# 7. Verificar la carga

No debemos asumir que una operación fue exitosa simplemente porque no observamos un mensaje de error.

Ejecute:

```bash
hdfs dfs -ls /curso/hive/datos_ventas/
```

Debería aparecer:

```text
ventas_hive.csv
```

También podemos comprobar el tamaño:

```bash
hdfs dfs -du -h /curso/hive/datos_ventas/
```

Y observar algunas filas directamente desde HDFS:

```bash
hdfs dfs -cat /curso/hive/datos_ventas/ventas_hive.csv | head
```

Ahora sí podemos afirmar:

> **El dataset está almacenado en HDFS.**

---

# 8. Primera frontera conceptual

Compare las siguientes instrucciones:

```bash
ls ventas_hive.csv
```

y:

```bash
hdfs dfs -ls /curso/hive/datos_ventas/
```

La primera observa el:

```text
sistema de archivos local
```

La segunda observa:

```text
HDFS
```

Aunque encontremos un archivo denominado `ventas_hive.csv` en ambos lugares, no estamos consultando el mismo sistema de almacenamiento.

Esta distinción será importante durante todo el laboratorio.

---

# 9. Iniciar Hive

Dentro de `hive-server`, diríjase al directorio:

```bash
cd /opt/hive/bin
```

Ejecute:

```bash
./hive
```

Después de iniciar Hive, compruebe su funcionamiento:

```sql
SHOW DATABASES;
```

A partir de este momento debemos recordar que estamos utilizando:

```text
HiveQL
```

y no comandos Linux o HDFS.

---

# 10. Crear nuestra base de datos

Crearemos una base de datos específica para los ejercicios:

```sql
CREATE DATABASE IF NOT EXISTS curso_bigdata;
```

Compruebe:

```sql
SHOW DATABASES;
```

Luego selecciónela:

```sql
USE curso_bigdata;
```

A partir de este momento las tablas que creemos durante la actividad pertenecerán a:

```text
curso_bigdata
```

---

# 11. Crear una tabla que referencia los datos almacenados en HDFS

Los datos ya existen en:

```text
/curso/hive/datos_ventas/
```

Ahora crearemos una **tabla externa** que permita a Hive interpretarlos.

Ejecute:

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS ventas_hive (
    id_venta INT,
    fecha STRING,
    cliente STRING,
    ciudad STRING,
    categoria STRING,
    monto DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/curso/hive/datos_ventas/';
```

Observe especialmente:

```sql
CREATE EXTERNAL TABLE
```

y:

```sql
LOCATION '/curso/hive/datos_ventas/'
```

---

# 12. ¿Qué acaba de ocurrir?

Hive no necesitó volver a cargar los 100.000 registros.

Los datos ya estaban almacenados en HDFS.

La instrucción anterior creó una estructura lógica:

```text
HIVE
│
└── ventas_hive
       │
       ├── id_venta
       ├── fecha
       ├── cliente
       ├── ciudad
       ├── categoria
       └── monto
              │
              │ LOCATION
              ▼
HDFS
│
└── /curso/hive/datos_ventas/
           │
           └── ventas_hive.csv
```

Por tanto:

```text
DATOS
↓
HDFS

ESTRUCTURA LÓGICA
↓
HIVE
```

Esta separación es una de las ideas fundamentales de toda la actividad.

---

# 13. Verificar que Hive conoce la tabla

Ejecute:

```sql
SHOW TABLES;
```

Debería aparecer:

```text
ventas_hive
```

Ahora consulte su estructura:

```sql
DESCRIBE ventas_hive;
```

Debería reconocer las seis variables:

```text
id_venta     int
fecha        string
cliente      string
ciudad       string
categoria    string
monto        double
```

---

# 14. Investigar la ubicación de la tabla

Ejecute:

```sql
DESCRIBE FORMATTED ventas_hive;
```

Busque particularmente:

```text
Location
```

La ubicación debe corresponder a los datos que previamente almacenamos en HDFS.

Conceptualmente:

```text
ventas_hive
     │
     │ Location
     ▼
/curso/hive/datos_ventas/
```

Esta comprobación es importante porque permite relacionar directamente:

```text
TABLA HIVE
     ↕
DIRECTORIO HDFS
```

---

# 15. Verificar desde las dos perspectivas

Tenemos ahora dos formas de observar nuestro entorno.

### Desde Hive

```sql
SHOW TABLES;
```

```sql
DESCRIBE FORMATTED ventas_hive;
```

### Desde HDFS

Para ejecutar nuevamente comandos HDFS, puede utilizar otra sesión conectada al contenedor o salir temporalmente del cliente Hive.

```bash
hdfs dfs -ls /curso/hive/datos_ventas/
```

Las dos perspectivas responden preguntas diferentes:

```text
HIVE

¿Cómo están estructurados
e interpretados los datos?

        ↕

HDFS

¿Dónde están almacenados
los archivos?
```

---

# 16. Primera consulta

Regrese al cliente Hive y ejecute:

```sql
SELECT *
FROM ventas_hive
LIMIT 10;
```

Hive utiliza la estructura definida en la tabla para interpretar los registros almacenados en el archivo CSV.

Ya no observamos:

```text
1,2026-05-17,Cliente_0245,Valparaiso,Tecnologia,185990
```

simplemente como una línea de texto.

Hive puede interpretarla conceptualmente como:

| id_venta | fecha      | cliente      | ciudad     | categoria  |  monto |
| -------: | ---------- | ------------ | ---------- | ---------- | -----: |
|        1 | 2026-05-17 | Cliente_0245 | Valparaiso | Tecnologia | 185990 |

---

# 17. Recordatorio de `WHERE`

Antes de comenzar los ejercicios progresivos realizaremos una última consulta guiada.

Supongamos que queremos conocer las ventas de la categoría:

```text
Tecnologia
```

cuyo monto sea superior a:

```text
1.000.000
```

Podemos escribir:

```sql
SELECT
    id_venta,
    fecha,
    cliente,
    ciudad,
    categoria,
    monto
FROM ventas_hive
WHERE categoria = 'Tecnologia'
AND monto > 1000000
LIMIT 20;
```

La lógica es:

```text
ventas_hive
     ↓
categoria = Tecnologia
     ↓
monto > 1.000.000
     ↓
máximo 20 resultados
```

---

# 18. Interpretar antes de continuar

Antes de pasar a los ejercicios, asegúrese de poder explicar qué representa cada elemento:

```sql
SELECT
```

¿Qué información queremos recuperar?

```sql
FROM ventas_hive
```

¿Qué estructura lógica estamos consultando?

```sql
WHERE
```

¿Qué registros queremos conservar?

```sql
AND
```

¿Qué segunda condición deben cumplir?

```sql
LIMIT 20
```

¿Cuántos resultados queremos visualizar como máximo?

El objetivo no es memorizar la consulta.

El objetivo es comprender cómo una pregunta puede transformarse progresivamente en HiveQL.

---

# 19. El entorno queda preparado

Desde este punto **no generaremos nuevos datasets**.

Tampoco crearemos un archivo diferente para cada ejercicio.

Todos los niveles trabajarán con:

```text
BASE DE DATOS
curso_bigdata

TABLA
ventas_hive

DATOS
100.000 registros

UBICACIÓN HDFS
/curso/hive/datos_ventas/

ARCHIVO
ventas_hive.csv
```

Nuestro laboratorio queda conceptualmente así:

```text
                  HIVE
                    │
                    │ HiveQL
                    ▼
              ventas_hive
                    │
                    │ metadatos
                    ▼
             Hive Metastore
                    │
                    │ LOCATION
                    ▼
                  HDFS
                    │
                    ▼
      /curso/hive/datos_ventas/
                    │
                    ▼
           ventas_hive.csv
```

---

# 20. A partir de ahora comienza el desafío

Hasta este punto hemos trabajado de manera completamente guiada.

Hemos realizado el recorrido:

```text
GENERAR
   ↓
ALMACENAR EN HDFS
   ↓
CREAR ESTRUCTURA HIVE
   ↓
VERIFICAR
   ↓
CONSULTAR
```

A partir del siguiente bloque comenzaremos los ejercicios progresivos.

La cantidad de ayuda irá disminuyendo:

```text
NIVEL 0
mucho apoyo
     ↓
NIVEL 1
apoyo moderado
     ↓
NIVEL 2
pocas pistas
     ↓
NIVEL 3
problemas complejos
     ↓
DESAFÍOS FINALES
sin código de apoyo
```

Durante todos ellos deberá mantener una pregunta fundamental:

> **¿Qué quiero saber de los datos y cómo puedo expresarlo mediante HiveQL?**

---

## Bloque 3 — Nivel 0: Fundamentos

En los bloques anteriores preparamos nuestro entorno de trabajo.

Disponemos de:

```text
BASE DE DATOS
curso_bigdata

TABLA
ventas_hive

REGISTROS
100.000

VARIABLES
id_venta
fecha
cliente
ciudad
categoria
monto

UBICACIÓN HDFS
/curso/hive/datos_ventas/
````

A partir de este momento comenzaremos a trabajar directamente con los datos.

---

# 1. Nivel 0 — ¿Qué buscamos?

El **Nivel 0** tiene como propósito familiarizarnos con la consulta de nuestra tabla.

Trabajaremos principalmente con:

```text
SELECT
FROM
WHERE
LIMIT
```

La dificultad todavía será baja.

En cada ejercicio encontrará:

1. un problema;
2. una explicación de lo que queremos obtener;
3. una consulta HiveQL parcialmente construida o un ejemplo similar;
4. una actividad de verificación.

La estrategia continúa siendo:

> **Ejecutar → Verificar → Interpretar**

No se limite a ejecutar el código.

Observe siempre el resultado y compruebe que responde realmente a lo solicitado.

---

# 2. Antes de comenzar

Compruebe que está utilizando la base de datos correcta:

```sql
USE curso_bigdata;
```

Verifique que nuestra tabla continúa disponible:

```sql
SHOW TABLES;
```

Debería encontrar:

```text
ventas_hive
```

Podemos comprobar rápidamente que los datos son accesibles:

```sql
SELECT *
FROM ventas_hive
LIMIT 5;
```

Si obtiene resultados, estamos preparados para comenzar.

---

# Ejercicio 0.1 — Seleccionar solamente la información necesaria

## Problema

Un analista necesita realizar una primera inspección de las ventas.

Sin embargo, no necesita observar las seis variables disponibles.

Solamente requiere conocer:

```text
fecha
cliente
monto
```

y desea visualizar únicamente los primeros **15 registros**.

---

## Paso 1 — Identificar la tabla

Nuestros datos se encuentran representados mediante:

```text
ventas_hive
```

Por tanto:

```sql
FROM ventas_hive
```

---

## Paso 2 — Seleccionar las columnas

No necesitamos utilizar:

```sql
SELECT *
```

porque no queremos recuperar todas las columnas.

Podemos indicar explícitamente las variables:

```sql
SELECT
    fecha,
    cliente,
    monto
```

---

## Paso 3 — Limitar la cantidad de resultados

Queremos observar como máximo:

```text
15 registros
```

Complete y ejecute la consulta:

```sql
SELECT
    fecha,
    cliente,
    monto
FROM ventas_hive
LIMIT _____;
```

---

## Verificación

Compruebe:

* ¿aparecen solamente tres columnas?
* ¿son `fecha`, `cliente` y `monto`?
* ¿se muestran como máximo 15 registros?

---

## Interpretación

Responda:

**¿Qué ventaja tiene seleccionar solamente las columnas necesarias en lugar de utilizar siempre `SELECT *`?**

---

# Ejercicio 0.2 — Filtrar por una categoría

## Problema

El área comercial necesita revisar exclusivamente las ventas correspondientes a:

```text
Tecnologia
```

Queremos visualizar:

```text
id_venta
fecha
cliente
categoria
monto
```

y limitar inicialmente la salida a **20 registros**.

---

## Recordatorio

Para filtrar registros utilizamos:

```sql
WHERE
```

Por ejemplo:

```sql
SELECT *
FROM ventas_hive
WHERE ciudad = 'Santiago'
LIMIT 10;
```

Observe que los valores de texto aparecen entre comillas simples.

---

## Actividad

Complete la consulta:

```sql
SELECT
    id_venta,
    fecha,
    cliente,
    categoria,
    monto
FROM ventas_hive
WHERE categoria = '____________'
LIMIT 20;
```

---

## Verificación

Observe la columna:

```text
categoria
```

Todos los registros mostrados deberían corresponder a:

```text
Tecnologia
```

---

## Interpretación

Explique qué operación realiza:

```sql
WHERE categoria = 'Tecnologia'
```

¿Modifica los datos almacenados en HDFS?

¿O solamente determina qué registros serán incluidos en el resultado de la consulta?

---

# Ejercicio 0.3 — Filtrar utilizando valores numéricos

## Problema

Ahora queremos identificar ventas cuyo monto sea superior a:

```text
1.200.000
```

Necesitamos observar:

```text
id_venta
fecha
cliente
ciudad
monto
```

Muestre solamente **20 registros**.

---

## Recordatorio

Podemos utilizar operadores de comparación:

```text
=
>
<
>=
<=
<>
```

Por ejemplo:

```sql
WHERE monto > 500000
```

significa:

> conservar solamente aquellos registros cuyo monto sea superior a 500.000.

---

## Actividad

Complete:

```sql
SELECT
    id_venta,
    fecha,
    cliente,
    ciudad,
    monto
FROM ventas_hive
WHERE monto _____ 1200000
LIMIT 20;
```

---

## Verificación

Revise manualmente algunos resultados.

Pregúntese:

```text
¿Existe algún monto menor
o igual a 1.200.000?
```

Si aparece alguno, revise su consulta.

---

## Segunda comprobación

Podemos pedir a Hive que cuente cuántos registros cumplen la condición.

Ejecute:

```sql
SELECT COUNT(*)
FROM ventas_hive
WHERE monto > 1200000;
```

No necesitamos todavía memorizar `COUNT()`.

Por ahora interprételo simplemente como:

> **contar cuántos registros cumplen una determinada condición.**

---

## Interpretación

Compare:

```sql
SELECT *
FROM ventas_hive
WHERE monto > 1200000
LIMIT 20;
```

con:

```sql
SELECT COUNT(*)
FROM ventas_hive
WHERE monto > 1200000;
```

¿Ambas consultas responden la misma pregunta?

Explique la diferencia.

---

# Ejercicio 0.4 — Combinar dos condiciones

## Problema

El área comercial ahora plantea una pregunta ligeramente más específica:

> **¿Qué ventas de la categoría Hogar realizadas en Valparaiso existen en nuestros datos?**

Queremos observar:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

y mostrar inicialmente un máximo de **25 registros**.

---

## Recordatorio

Una condición puede escribirse como:

```sql
WHERE categoria = 'Hogar'
```

Otra condición podría ser:

```sql
ciudad = 'Valparaiso'
```

Cuando queremos que **ambas condiciones se cumplan simultáneamente**, utilizamos:

```sql
AND
```

Conceptualmente:

```text
TODAS LAS VENTAS
       ↓
categoria = Hogar
       ↓
        AND
       ↓
ciudad = Valparaiso
       ↓
RESULTADO
```

---

## Actividad

Complete la consulta:

```sql
SELECT
    id_venta,
    fecha,
    cliente,
    ciudad,
    categoria,
    monto
FROM ventas_hive
WHERE categoria = '__________'
AND ciudad = '__________'
LIMIT _____;
```

---

## Verificación

Cada registro obtenido debe satisfacer simultáneamente:

```text
categoria = Hogar

Y

ciudad = Valparaiso
```

No basta con que se cumpla solamente una de las condiciones.

---

## Interpretación

Explique con sus propias palabras la diferencia entre:

```sql
WHERE categoria = 'Hogar'
```

y:

```sql
WHERE categoria = 'Hogar'
AND ciudad = 'Valparaiso'
```

---

# 3. Comprobación del Nivel 0

Antes de avanzar, debería ser capaz de interpretar las siguientes instrucciones sin consultar su significado:

```sql
SELECT
```

```sql
FROM
```

```sql
WHERE
```

```sql
AND
```

```sql
LIMIT
```

También debería poder reconocer operadores como:

```text
=
>
<
>=
<=
<>
```

---

# 4. Lo importante no es memorizar

Observe cómo aumentó progresivamente la dificultad:

```text
EJERCICIO 0.1

seleccionar columnas
        +
      LIMIT


EJERCICIO 0.2

seleccionar columnas
        +
      WHERE
        +
      LIMIT


EJERCICIO 0.3

seleccionar columnas
        +
condición numérica
        +
      LIMIT


EJERCICIO 0.4

seleccionar columnas
        +
      WHERE
        +
       AND
        +
      LIMIT
```

Hasta ahora las consultas han sido relativamente sencillas y hemos proporcionado gran parte de su estructura.

Esto es intencional.

En los siguientes niveles comenzaremos a retirar progresivamente ese apoyo.

---

# 5. Antes de pasar al Nivel 1

Compruebe que puede resolver una pregunta sencilla sin mirar los ejemplos anteriores.

Piense, por ejemplo:

> **¿Cómo mostraría 10 ventas de la categoría Deportes realizadas en Santiago?**

No es necesario crear nuevos datos.

No es necesario modificar la tabla.

Todo continúa ocurriendo sobre:

```text
ventas_hive
        │
        │ estructura lógica
        ▼
/curso/hive/datos_ventas/
        │
        │ HDFS
        ▼
ventas_hive.csv
```

Los datos utilizados por los cuatro ejercicios continúan siendo exactamente los mismos.

---

# 6. Nivel 0 completado

Si pudo realizar correctamente los cuatro ejercicios, ya puede:

```text
seleccionar
     ↓
limitar
     ↓
filtrar
     ↓
comparar
     ↓
combinar condiciones
```

En el **Nivel 1** aumentaremos la capacidad de filtrado y comenzaremos a trabajar con condiciones que requieren utilizar mecanismos como:

```text
IN
BETWEEN
LIKE
AND / OR
```

pero con una diferencia importante:

> **recibirá menos código de apoyo y deberá comenzar a construir una mayor parte de las consultas por sí mismo.**

---

## Bloque 4 — Nivel 1: Filtrado avanzado

En el Nivel 0 trabajamos con consultas relativamente simples.

Aprendimos a combinar:

```text
SELECT
FROM
WHERE
AND
LIMIT
````

Ahora avanzaremos al **Nivel 1**.

El objetivo será construir filtros más expresivos utilizando:

```text
IN
BETWEEN
LIKE
AND
OR
```

A partir de este nivel encontrará **menos código incompleto para rellenar**.

Deberá comenzar a traducir el problema planteado a HiveQL.

---

# 1. Nivel 1 — ¿Qué buscamos?

Imagine que un analista recibe preguntas como:

> ¿Cuáles son las ventas realizadas en determinadas ciudades?

> ¿Qué ventas se encuentran dentro de un rango de montos?

> ¿Qué clientes cumplen un determinado patrón?

> ¿Cómo puedo combinar diferentes criterios de búsqueda?

Resolver este tipo de preguntas requiere construir condiciones más elaboradas.

Nuestro proceso será:

```text
PREGUNTA
   ↓
identificar variables
   ↓
identificar condiciones
   ↓
seleccionar operador
   ↓
construir HiveQL
   ↓
verificar resultado
```

Continuaremos trabajando exclusivamente con:

```text
curso_bigdata.ventas_hive
```

---

# Ejercicio 1.1 — Filtrar utilizando `IN`

## Problema

El área comercial desea analizar las ventas realizadas en tres ciudades:

```text
Santiago
Concepcion
Antofagasta
```

Necesita visualizar:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

Muestre inicialmente un máximo de **30 registros**.

---

## Una primera alternativa

Podríamos construir una condición utilizando varios `OR`:

```sql
WHERE ciudad = 'Santiago'
   OR ciudad = 'Concepcion'
   OR ciudad = 'Antofagasta'
```

La condición es válida.

Sin embargo, cuando estamos evaluando una misma variable frente a varios valores posibles, HiveQL permite expresarlo de manera más compacta mediante:

```sql
IN
```

Su estructura general es:

```sql
WHERE columna IN ('valor1', 'valor2', 'valor3')
```

---

## Actividad

Construya la consulta necesaria para recuperar las ventas correspondientes a:

```text
Santiago
Concepcion
Antofagasta
```

Utilice:

```sql
IN
```

y limite el resultado a 30 registros.

---

## Verificación

Observe la columna:

```text
ciudad
```

No debería aparecer ninguna ciudad diferente de:

```text
Santiago
Concepcion
Antofagasta
```

---

## Interpretación

Compare conceptualmente:

```sql
WHERE ciudad = 'Santiago'
   OR ciudad = 'Concepcion'
   OR ciudad = 'Antofagasta'
```

con:

```sql
WHERE ciudad IN (...)
```

Responda:

**¿Qué ventaja ofrece `IN` cuando necesitamos comparar una columna con varios valores posibles?**

---

# Ejercicio 1.2 — Trabajar con rangos mediante `BETWEEN`

## Problema

Ahora queremos estudiar las ventas cuyo monto se encuentre entre:

```text
300.000
```

y:

```text
600.000
```

Además, solamente nos interesan las ventas correspondientes a la categoría:

```text
Deportes
```

Muestre:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

y limite la visualización a **30 registros**.

---

## Recordatorio

Un rango podría escribirse mediante:

```sql
monto >= 300000
AND monto <= 600000
```

HiveQL también dispone de:

```sql
BETWEEN
```

Su estructura es:

```sql
columna BETWEEN valor_inferior AND valor_superior
```

Importante:

> `BETWEEN` incluye ambos extremos del rango.

Por tanto:

```sql
monto BETWEEN 300000 AND 600000
```

equivale conceptualmente a:

```sql
monto >= 300000
AND monto <= 600000
```

---

## Actividad

Construya una consulta que combine las dos condiciones:

```text
categoria = Deportes

Y

monto entre 300.000 y 600.000
```

Utilice `BETWEEN` para expresar el rango.

---

## Verificación

Compruebe algunos registros manualmente.

Cada resultado debe cumplir:

```text
categoria = Deportes
```

y simultáneamente:

```text
300.000 <= monto <= 600.000
```

---

## Interpretación

Responda:

**¿Qué ocurriría con una venta cuyo monto fuera exactamente 300.000?**

¿Sería incluida?

¿Y una venta de exactamente 600.000?

---

# Ejercicio 1.3 — Buscar patrones mediante `LIKE`

## Problema

Nuestra tabla contiene clientes identificados mediante valores como:

```text
Cliente_0001
Cliente_0002
Cliente_0003
...
Cliente_2000
```

Ahora queremos localizar registros de clientes cuyo identificador **termine en `25`**.

Por ejemplo:

```text
Cliente_0025
Cliente_0125
Cliente_0225
Cliente_1025
```

No conocemos el identificador completo.

Solamente conocemos un patrón.

---

## Recordatorio

Para buscar patrones de texto podemos utilizar:

```sql
LIKE
```

El símbolo:

```text
%
```

representa una secuencia de cero o más caracteres.

Por ejemplo:

```sql
WHERE cliente LIKE 'Cliente_01%'
```

permite buscar valores que comienzan con:

```text
Cliente_01
```

---

## Actividad

Construya una consulta que muestre:

```text
id_venta
fecha
cliente
ciudad
monto
```

para aquellos clientes cuyo identificador termine en:

```text
25
```

Muestre un máximo de **30 registros**.

### Pista

Piense dónde debería ubicarse `%`:

```text
¿antes de 25?

¿después de 25?

¿en ambos lugares?
```

---

## Verificación

Observe todos los valores de:

```text
cliente
```

mostrados en el resultado.

Deberían terminar en:

```text
25
```

---

## Interpretación

Explique la diferencia entre:

```sql
LIKE '25%'
```

```sql
LIKE '%25'
```

y:

```sql
LIKE '%25%'
```

No ejecute solamente las expresiones.

Intente anticipar qué buscaría cada una antes de comprobarlo en Hive.

---

# Ejercicio 1.4 — Combinar criterios con `AND` y `OR`

## Problema

El área comercial plantea ahora una consulta más específica:

> Se necesitan las ventas realizadas en **Santiago o Valparaiso**, correspondientes a las categorías **Tecnologia o Hogar**, con montos comprendidos entre **500.000 y 1.000.000**.

Necesitamos visualizar:

```text
fecha
cliente
ciudad
categoria
monto
```

Muestre inicialmente un máximo de **40 registros**.

---

## Analizar antes de programar

No escriba inmediatamente la consulta.

Primero descomponga el problema.

### Condición 1 — Ciudad

Los registros pueden pertenecer a:

```text
Santiago
O
Valparaiso
```

Podemos representar esta condición mediante:

```text
ciudad IN (...)
```

### Condición 2 — Categoría

Los registros pueden corresponder a:

```text
Tecnologia
O
Hogar
```

Nuevamente podemos utilizar:

```text
categoria IN (...)
```

### Condición 3 — Monto

El monto debe encontrarse entre:

```text
500.000
y
1.000.000
```

Podemos utilizar:

```text
BETWEEN
```

### Relación entre las tres condiciones

No queremos que se cumpla solamente una de ellas.

Necesitamos:

```text
CIUDAD CORRECTA
       AND
CATEGORÍA CORRECTA
       AND
MONTO EN EL RANGO
```

---

## Actividad

Construya la consulta completa.

Esta vez no se proporciona una plantilla.

Debe decidir:

* qué columnas incorporar en `SELECT`;
* qué tabla utilizar;
* cómo construir cada condición;
* cómo relacionarlas;
* cómo limitar la salida.

---

## Verificación

Seleccione algunos registros del resultado y compruebe:

```text
¿La ciudad es Santiago o Valparaiso?

              Y

¿La categoría es Tecnologia o Hogar?

              Y

¿El monto está entre 500.000 y 1.000.000?
```

Cada registro debe satisfacer **las tres preguntas**.

---

# 2. Una precaución importante con `AND` y `OR`

Considere la siguiente condición:

```sql
WHERE ciudad = 'Santiago'
OR ciudad = 'Valparaiso'
AND categoria = 'Tecnologia'
```

Puede parecer evidente qué queremos expresar.

Sin embargo, cuando combinamos `AND` y `OR`, es conveniente hacer explícita nuestra intención utilizando paréntesis.

Por ejemplo:

```sql
WHERE (ciudad = 'Santiago' OR ciudad = 'Valparaiso')
AND categoria = 'Tecnologia'
```

Ahora nuestra intención resulta mucho más clara:

```text
(Santiago O Valparaiso)
          Y
     Tecnologia
```

Cuando una consulta contiene varias condiciones:

> **No confíe solamente en cómo “se lee” la consulta. Utilice paréntesis para expresar explícitamente la lógica que desea aplicar.**

---

# 3. Comprobación del Nivel 1

Después de completar los cuatro ejercicios debería poder reconocer cuándo utilizar:

| Necesidad                            | Operador  |
| ------------------------------------ | --------- |
| Comparar con un valor                | `=`       |
| Exigir varias condiciones            | `AND`     |
| Aceptar condiciones alternativas     | `OR`      |
| Comparar con varios valores posibles | `IN`      |
| Trabajar con un rango                | `BETWEEN` |
| Buscar patrones de texto             | `LIKE`    |
| Limitar la visualización             | `LIMIT`   |

Pero el objetivo no es seleccionar operadores mecánicamente.

La habilidad que estamos desarrollando es:

```text
PROBLEMA
   ↓
¿Qué información necesito?
   ↓
¿Qué registros cumplen el criterio?
   ↓
¿Cómo expreso ese criterio?
   ↓
HiveQL
```

---

# 4. El apoyo comienza a disminuir

Compare el Nivel 0 con el Nivel 1:

```text
NIVEL 0

problema
   ↓
explicación
   ↓
consulta casi completa
   ↓
completar
   ↓
ejecutar
```

Ahora:

```text
NIVEL 1

problema
   ↓
analizar condiciones
   ↓
elegir operadores
   ↓
construir consulta
   ↓
ejecutar
   ↓
verificar
```

En el último ejercicio ya no recibió una consulta parcialmente construida.

Esta reducción del apoyo continuará.

---

# 5. Antes de avanzar

Hasta ahora hemos utilizado Hive principalmente para **recuperar registros que cumplen determinadas condiciones**.

Pero imagine que ahora nos preguntan:

> ¿Cuánto dinero se vendió en total?

> ¿Cuál es el monto promedio de las ventas?

> ¿Cuántas ventas existen por ciudad?

> ¿Qué categoría concentra el mayor monto de ventas?

En estos casos ya no basta con observar filas individuales.

Necesitamos comenzar a:

```text
CONTAR
   ↓
SUMAR
   ↓
PROMEDIAR
   ↓
AGRUPAR
   ↓
COMPARAR GRUPOS
```

Ese será precisamente el objetivo del **Nivel 2**.

---

## Bloque 5 — Nivel 2: Agregación y análisis

Hasta ahora hemos trabajado principalmente con **registros individuales**.

Por ejemplo:

```sql
SELECT *
FROM ventas_hive
WHERE categoria = 'Tecnologia';
````

Este tipo de consulta permite responder preguntas como:

> ¿Qué ventas corresponden a la categoría Tecnologia?

Pero en un escenario analítico suelen aparecer preguntas diferentes:

> ¿Cuántas ventas existen por ciudad?

> ¿Cuál es el monto promedio vendido por categoría?

> ¿Qué ciudades concentran el mayor monto de ventas?

> ¿Qué grupos cumplen determinadas condiciones?

Para responder estas preguntas debemos dejar de observar únicamente filas individuales y comenzar a **resumir y agrupar los datos**.

---

# 1. Nivel 2 — ¿Qué buscamos?

En este nivel utilizaremos principalmente:

```text
COUNT()
SUM()
AVG()
MIN()
MAX()
GROUP BY
HAVING
ORDER BY
```

La lógica cambia:

```text
NIVELES ANTERIORES

100.000 registros
       ↓
     WHERE
       ↓
registros seleccionados
```

Ahora podremos realizar:

```text
NIVEL 2

100.000 registros
       ↓
     WHERE
       ↓
    GROUP BY
       ↓
funciones de agregación
       ↓
resultados resumidos
```

A partir de este nivel recibirá menos apoyo.

Antes de escribir HiveQL deberá identificar:

1. qué queremos medir;
2. sobre qué grupos queremos calcularlo;
3. si necesitamos filtrar registros;
4. si necesitamos filtrar grupos;
5. cómo queremos presentar el resultado.

---

# 2. Recordatorio: funciones de agregación

Las funciones de agregación permiten resumir múltiples registros en un resultado.

Algunas de las principales son:

| Función   | Pregunta que permite responder |
| --------- | ------------------------------ |
| `COUNT()` | ¿Cuántos registros existen?    |
| `SUM()`   | ¿Cuál es la suma total?        |
| `AVG()`   | ¿Cuál es el promedio?          |
| `MIN()`   | ¿Cuál es el valor mínimo?      |
| `MAX()`   | ¿Cuál es el valor máximo?      |

Por ejemplo:

```sql
SELECT COUNT(*)
FROM ventas_hive;
```

responde:

> ¿Cuántas ventas existen en nuestra tabla?

Mientras que:

```sql
SELECT AVG(monto)
FROM ventas_hive;
```

responde:

> ¿Cuál es el monto promedio considerando todas las ventas?

Pero nuestro objetivo será ir más allá.

Queremos obtener estas medidas **para diferentes grupos de datos**.

---

# Ejercicio 2.1 — Analizar las ventas por ciudad

## Problema

La gerencia desea obtener una visión general del comportamiento comercial de cada ciudad.

Para cada ciudad necesita conocer:

* cantidad de ventas;
* monto total vendido;
* monto promedio de las ventas.

---

## Analizar antes de programar

Tenemos tres medidas:

```text
cantidad de ventas
       ↓
COUNT()

monto total
       ↓
SUM()

monto promedio
       ↓
AVG()
```

Pero no queremos obtenerlas para todo el dataset.

Queremos calcularlas:

```text
POR CADA CIUDAD
```

Por tanto, necesitaremos:

```sql
GROUP BY ciudad
```

---

## Actividad

Construya una consulta que genere un resultado conceptualmente similar a:

| ciudad     | cantidad_ventas | total_vendido | promedio_venta |
| ---------- | --------------: | ------------: | -------------: |
| Santiago   |             ... |           ... |            ... |
| Valparaiso |             ... |           ... |            ... |
| Concepcion |             ... |           ... |            ... |

Utilice alias descriptivos mediante:

```sql
AS
```

Por ejemplo:

```sql
COUNT(*) AS cantidad_ventas
```

No se proporciona la consulta completa.

---

## Verificación

Nuestro dataset contiene ocho ciudades posibles.

Por tanto, pregúntese:

> **¿Cuántas filas debería producir aproximadamente esta consulta?**

Si obtiene decenas de miles de filas, probablemente no está realizando la agrupación esperada.

---

## Interpretación

Responda:

1. ¿Qué ciudad presenta la mayor cantidad de ventas?
2. ¿Qué ciudad presenta el mayor monto total vendido?
3. ¿Es necesariamente la misma ciudad?
4. ¿Qué información adicional aporta el promedio?

No se limite a observar que Hive ejecutó correctamente la consulta.

**Interprete el resultado.**

---

# Ejercicio 2.2 — Analizar categorías y ordenar resultados

## Problema

Ahora queremos comparar el desempeño de las diferentes categorías de productos.

Para cada categoría determine:

```text
cantidad de ventas
monto total vendido
monto promedio de venta
venta mínima
venta máxima
```

Además, queremos que las categorías aparezcan ordenadas desde aquella con **mayor monto total vendido** hasta aquella con menor monto total.

---

## Analizar antes de programar

Identifique primero:

```text
DIMENSIÓN DE ANÁLISIS

categoria
```

Luego:

```text
MEDIDAS

COUNT()
SUM()
AVG()
MIN()
MAX()
```

Finalmente necesitamos ordenar el resultado.

Para ello podemos utilizar:

```sql
ORDER BY
```

y para ordenar de mayor a menor:

```sql
DESC
```

---

## Actividad

Construya la consulta completa.

El resultado debería tener una estructura similar a:

| categoria | cantidad_ventas | total_vendido | promedio_venta | venta_minima | venta_maxima |
| --------- | --------------: | ------------: | -------------: | -----------: | -----------: |
| ...       |             ... |           ... |            ... |          ... |          ... |

Ordene los resultados utilizando:

```text
total_vendido
```

de forma descendente.

---

## Verificación

Pregúntese:

```text
¿Aparecen todas las categorías?

¿Existe una fila por categoría?

¿Los resultados están ordenados
de mayor a menor total vendido?
```

---

## Interpretación

Identifique:

* la categoría con mayor monto total;
* la categoría con mayor monto promedio;
* la categoría con la venta individual más alta;
* la categoría con la venta individual más baja.

Luego responda:

> **¿Por qué "mayor monto total vendido" y "mayor monto promedio" representan indicadores diferentes?**

---

# Ejercicio 2.3 — Filtrar antes de agrupar

## Problema

La gerencia solicita ahora un análisis específico de las ventas correspondientes a:

```text
2026
```

pero solamente para las categorías:

```text
Tecnologia
Hogar
Deportes
```

Para cada una de estas categorías determine:

```text
cantidad de ventas
monto total vendido
monto promedio
```

Ordene el resultado desde la categoría con mayor monto total vendido hasta la de menor monto.

---

## Analizar antes de programar

Este problema incorpora dos operaciones diferentes.

Primero necesitamos seleccionar solamente determinados registros:

```text
AÑO 2026

Y

CATEGORÍAS SELECCIONADAS
```

Después debemos agrupar esos registros.

La secuencia conceptual es:

```text
100.000 ventas
      ↓
    WHERE
      ↓
ventas de 2026
      ↓
Tecnologia / Hogar / Deportes
      ↓
   GROUP BY
      ↓
   categoria
      ↓
COUNT / SUM / AVG
      ↓
   ORDER BY
```

---

## Una pista sobre las fechas

Nuestra variable:

```text
fecha
```

está almacenada como `STRING`, utilizando el formato:

```text
AAAA-MM-DD
```

Por ejemplo:

```text
2026-07-18
```

Por tanto, para este ejercicio puede delimitar el año mediante un rango:

```sql
fecha BETWEEN '2026-01-01' AND '2026-12-31'
```

---

## Actividad

Construya la consulta completa.

No se proporciona código adicional.

Deberá decidir cómo combinar:

```text
WHERE
IN
BETWEEN
GROUP BY
COUNT()
SUM()
AVG()
ORDER BY
```

---

## Verificación

El resultado debería contener solamente:

```text
Tecnologia
Hogar
Deportes
```

y los cálculos deben considerar únicamente registros correspondientes al año:

```text
2026
```

---

## Interpretación

Determine:

1. ¿qué categoría registra más ventas durante 2026?
2. ¿cuál presenta el mayor monto total?
3. ¿cuál tiene el mayor monto promedio?

Luego responda:

> **¿Qué diferencia existe entre filtrar los registros antes de realizar `GROUP BY` y simplemente agrupar todo el dataset?**

---

# Ejercicio 2.4 — Filtrar grupos mediante `HAVING`

## Problema

Ahora queremos analizar el comportamiento de los clientes.

La gerencia no está interesada en todos ellos.

Desea identificar solamente aquellos clientes que hayan realizado:

```text
más de 55 ventas
```

Para cada cliente que cumpla esta condición necesitamos conocer:

```text
cliente
cantidad de ventas
monto total comprado
monto promedio por venta
```

Finalmente, queremos ordenar los resultados desde el cliente con **mayor monto total comprado** hasta el de menor monto total.

---

# 3. Aparece un nuevo problema

Hasta ahora hemos utilizado:

```sql
WHERE
```

para filtrar registros.

Pero observe la condición actual:

> clientes que hayan realizado más de 55 ventas.

La cantidad de ventas de un cliente **no existe como una columna en cada registro**.

Debemos calcularla:

```sql
COUNT(*)
```

después de agrupar:

```sql
GROUP BY cliente
```

Por tanto, necesitamos filtrar el **resultado de la agrupación**.

Para ello utilizamos:

```sql
HAVING
```

---

# 4. `WHERE` y `HAVING` no cumplen la misma función

Observe la diferencia conceptual:

```text
WHERE

filtra registros
ANTES de agrupar
```

mientras que:

```text
HAVING

filtra grupos
DESPUÉS de agrupar
```

Por ejemplo:

```sql
SELECT
    cliente,
    COUNT(*) AS cantidad_ventas
FROM ventas_hive
GROUP BY cliente
HAVING COUNT(*) > 55;
```

Conceptualmente:

```text
100.000 VENTAS
       ↓
GROUP BY cliente
       ↓
2.000 CLIENTES
       ↓
COUNT(*) para cada cliente
       ↓
HAVING COUNT(*) > 55
       ↓
CLIENTES QUE CUMPLEN
LA CONDICIÓN
```

---

## Actividad

Construya una consulta que muestre:

```text
cliente
cantidad_ventas
total_comprado
promedio_venta
```

solamente para aquellos clientes con:

```text
más de 55 ventas
```

Ordene el resultado de mayor a menor según:

```text
total_comprado
```

---

## Verificación

Observe la columna:

```text
cantidad_ventas
```

Ningún cliente mostrado debería tener:

```text
55 ventas o menos
```

Luego compruebe que los resultados estén ordenados de mayor a menor monto total comprado.

---

## Interpretación

Responda:

> ¿Por qué no utilizamos simplemente `WHERE COUNT(*) > 55`?

La respuesta debería considerar **el momento en que existe el valor que estamos intentando filtrar**.

---

# 5. La secuencia lógica comienza a ser importante

En este nivel hemos incorporado varias operaciones.

Una forma útil de comprenderlas es pensar conceptualmente en:

```text
FROM
  ↓
WHERE
  ↓
GROUP BY
  ↓
funciones de agregación
  ↓
HAVING
  ↓
SELECT
  ↓
ORDER BY
  ↓
LIMIT
```

No interprete este esquema simplemente como el orden textual en que escribimos todas las cláusulas.

Utilícelo para comprender qué ocurre con los datos:

```text
¿DE DÓNDE?
      ↓
FROM

¿QUÉ REGISTROS?
      ↓
WHERE

¿CÓMO LOS AGRUPO?
      ↓
GROUP BY

¿QUÉ CALCULO?
      ↓
COUNT / SUM / AVG...

¿QUÉ GRUPOS CONSERVO?
      ↓
HAVING

¿QUÉ MUESTRO?
      ↓
SELECT

¿CÓMO PRESENTO?
      ↓
ORDER BY
```

---

# 6. `WHERE` versus `HAVING`

Esta distinción es fundamental.

| Pregunta                                          | Cláusula |
| ------------------------------------------------- | -------- |
| ¿Qué registros quiero analizar?                   | `WHERE`  |
| ¿Qué grupos quiero conservar después de calcular? | `HAVING` |

Por ejemplo:

```text
Quiero analizar solamente
ventas de Tecnologia
```

corresponde a:

```sql
WHERE categoria = 'Tecnologia'
```

En cambio:

```text
Quiero mostrar solamente
ciudades con más de 10.000 ventas
```

requiere evaluar un resultado agregado:

```sql
HAVING COUNT(*) > 10000
```

La pregunta clave es:

> **¿Estoy filtrando registros originales o resultados obtenidos después de agrupar?**

---

# 7. Comprobación del Nivel 2

Después de completar los cuatro ejercicios debería poder utilizar:

```text
COUNT()
SUM()
AVG()
MIN()
MAX()
GROUP BY
HAVING
ORDER BY
ASC / DESC
```

y combinarlos con lo aprendido anteriormente:

```text
WHERE
AND
OR
IN
BETWEEN
LIKE
```

Ya no estamos simplemente recuperando filas.

Ahora estamos realizando:

```text
DATOS
  ↓
SELECCIÓN
  ↓
AGRUPACIÓN
  ↓
CÁLCULO
  ↓
COMPARACIÓN
  ↓
INTERPRETACIÓN
```

---

# 8. Observe cuánto ha cambiado el problema

En el Nivel 0 resolvíamos preguntas como:

> Muestre 20 ventas de Tecnologia.

En el Nivel 1:

> Muestre ventas de determinadas ciudades y categorías dentro de un rango de montos.

En el Nivel 2:

> Determine qué clientes superan una determinada cantidad de ventas y compare su comportamiento mediante diferentes indicadores.

La consulta ya no está prácticamente escrita en el enunciado.

Debe comenzar a diseñarla.

---

# 9. Antes de pasar al Nivel 3

Hasta ahora los ejercicios han indicado de manera relativamente explícita:

```text
qué analizar
qué calcular
cómo agrupar
cómo presentar
```

En el siguiente nivel eso cambiará.

Recibirá principalmente un **problema analítico**.

Deberá decidir qué operaciones HiveQL necesita combinar para resolverlo.

El proceso será:

```text
PROBLEMA DE NEGOCIO
        ↓
comprender la pregunta
        ↓
identificar variables
        ↓
definir filtros
        ↓
definir agrupaciones
        ↓
seleccionar métricas
        ↓
construir HiveQL
        ↓
validar
        ↓
INTERPRETAR
```

Ese será el propósito del **Nivel 3: Resolución de problemas complejos con Hive**.

---

## Bloque 6 — Nivel 3: Resolución de problemas complejos

Hemos llegado al último nivel de ejercicios guiados.

Hasta ahora la progresión ha sido:

```text
NIVEL 0
Consultar y filtrar
      ↓
NIVEL 1
Combinar condiciones
      ↓
NIVEL 2
Agrupar y analizar
      ↓
NIVEL 3
Resolver problemas
````

En este nivel cambia la forma de trabajo.

Ya no recibirá una explicación indicando qué cláusula debe utilizar en cada parte de la consulta.

Tampoco encontrará código parcialmente construido.

Recibirá un **problema analítico** y deberá diseñar una estrategia para resolverlo utilizando los conocimientos desarrollados hasta ahora.

---

# 1. Antes de escribir HiveQL

Frente a cada problema, siga esta secuencia:

```text
1. COMPRENDER
   ¿Qué pregunta debo responder?

            ↓

2. IDENTIFICAR
   ¿Qué variables necesito?

            ↓

3. FILTRAR
   ¿Necesito trabajar con todos los registros?

            ↓

4. AGRUPAR
   ¿Cuál es la unidad de análisis?

            ↓

5. CALCULAR
   ¿Qué indicadores necesito?

            ↓

6. RESTRINGIR
   ¿Todos los grupos deben aparecer?

            ↓

7. ORDENAR
   ¿Cómo debo presentar el resultado?

            ↓

8. INTERPRETAR
   ¿Qué significa el resultado obtenido?
```

No comience escribiendo:

```sql
SELECT ...
```

hasta tener claro qué resultado necesita producir.

---

# Ejercicio 3.1 — Desempeño comercial por ciudad

## Situación

La gerencia desea conocer cuáles fueron las ciudades con mejor desempeño en la categoría:

```text
Tecnologia
```

durante el año:

```text
2026
```

Para cada ciudad necesita conocer:

* cantidad de ventas;
* monto total vendido;
* monto promedio por venta.

Sin embargo, solamente deben considerarse en el resultado aquellas ciudades que hayan registrado **más de 400 ventas de Tecnologia durante 2026**.

El resultado debe mostrar primero la ciudad con mayor monto total vendido.

---

## Resultado esperado

Su consulta deberá producir una estructura equivalente a:

| ciudad | cantidad_ventas | total_vendido | promedio_venta |
| ------ | --------------: | ------------: | -------------: |
| ...    |             ... |           ... |            ... |

No se proporciona código de apoyo.

---

## Antes de ejecutar

Anote su estrategia.

Complete conceptualmente:

```text
Registros que necesito:
________________________________

Unidad de agrupación:
________________________________

Indicadores:
________________________________

Condición sobre los grupos:
________________________________

Criterio de ordenamiento:
________________________________
```

Ahora construya la consulta HiveQL.

---

## Verificación

Compruebe que:

* todos los registros considerados corresponden a `Tecnologia`;
* solamente se considera el año 2026;
* cada fila representa una ciudad;
* ninguna ciudad posee 400 ventas o menos;
* los resultados aparecen de mayor a menor monto total vendido.

---

## Interpretación

Responda:

1. ¿Qué ciudad lidera el monto total vendido?
2. ¿Es también la ciudad con mayor cantidad de ventas?
3. ¿Qué ciudad presenta el mayor monto promedio?

Explique por qué estos tres indicadores pueden entregar conclusiones diferentes.

---

# Ejercicio 3.2 — Identificar clientes de alto valor

## Situación

El área comercial desea identificar clientes especialmente relevantes para una futura estrategia de fidelización.

Considere exclusivamente las ventas realizadas durante:

```text
2025 y 2026
```

Un cliente será considerado de **alto valor** cuando cumpla simultáneamente las siguientes condiciones:

```text
más de 70 compras

Y

monto total comprado superior a 50.000.000
```

Para cada cliente que cumpla estos criterios muestre:

* identificador del cliente;
* cantidad de compras;
* monto total comprado;
* monto promedio por compra;
* compra de menor monto;
* compra de mayor monto.

Ordene los resultados desde el cliente con mayor monto total comprado hasta el de menor.

---

## Restricción

No basta con aplicar:

```text
una condición
      O
otra condición
```

Un cliente debe cumplir:

```text
CONDICIÓN 1
     +
CONDICIÓN 2
     ↓
AMBAS
```

---

## Actividad

Diseñe y ejecute la consulta completa.

Antes de hacerlo, determine:

```text
¿Qué debe resolverse mediante WHERE?

¿Qué debe resolverse mediante GROUP BY?

¿Qué debe resolverse mediante HAVING?

¿Qué debe resolverse mediante ORDER BY?
```

---

## Verificación

Seleccione algunos clientes del resultado y compruebe manualmente que:

```text
cantidad de compras > 70
```

y:

```text
total comprado > 50.000.000
```

deben cumplirse simultáneamente.

---

## Interpretación

Responda:

> ¿Por qué las condiciones temporales pertenecen conceptualmente a `WHERE`, mientras que las condiciones sobre cantidad de compras y monto total pertenecen a `HAVING`?

Su explicación debe hacer referencia a la diferencia entre:

```text
REGISTROS
```

y:

```text
GRUPOS
```

---

# Ejercicio 3.3 — Combinaciones ciudad–categoría

## Situación

Hasta ahora hemos agrupado principalmente por una sola variable.

Pero una pregunta analítica puede requerir estudiar simultáneamente dos dimensiones.

La gerencia desea analizar las ventas realizadas durante **2026** y determinar el comportamiento de cada combinación:

```text
CIUDAD + CATEGORÍA
```

Por ejemplo:

```text
Santiago + Tecnologia
Santiago + Hogar
Valparaiso + Tecnologia
Valparaiso + Deportes
...
```

Para cada combinación calcule:

* cantidad de ventas;
* monto total vendido;
* monto promedio de venta.

Solamente deben mostrarse combinaciones que cumplan **simultáneamente**:

```text
más de 450 ventas

Y

monto promedio superior a 700.000
```

Ordene los resultados de mayor a menor según el monto total vendido.

---

## Una decisión importante

Hasta ahora utilizábamos agrupaciones como:

```text
POR CIUDAD
```

o:

```text
POR CATEGORÍA
```

Ahora nuestra unidad de análisis es:

```text
CIUDAD
   +
CATEGORÍA
```

Por tanto, cada fila del resultado debe representar una combinación diferente.

---

## Actividad

Construya la consulta sin código de apoyo.

Antes de ejecutarla, responda:

```text
¿Qué registros deben seleccionarse primero?

¿Por cuántas variables debo agrupar?

¿Qué tres indicadores debo calcular?

¿Qué condiciones deben aplicarse después
de realizar los cálculos?

¿Cómo debo ordenar el resultado?
```

---

## Verificación

Una fila como:

```text
Santiago | Tecnologia | ...
```

debe representar exclusivamente las ventas que cumplen simultáneamente:

```text
ciudad = Santiago

Y

categoria = Tecnologia
```

Compruebe además que cada combinación mostrada posee:

```text
cantidad_ventas > 450
```

y:

```text
promedio_venta > 700000
```

---

## Interpretación

Responda:

> ¿Qué información obtenemos agrupando simultáneamente por `ciudad` y `categoria` que perderíamos si agrupáramos solamente por `ciudad`?

---

# Ejercicio 3.4 — Análisis ejecutivo de un segmento

## Situación

La gerencia solicita un análisis para detectar los segmentos comerciales más relevantes durante el período comprendido entre:

```text
2025-01-01
```

y:

```text
2026-12-31
```

El análisis debe considerar solamente las ciudades:

```text
Santiago
Valparaiso
Concepcion
Antofagasta
```

y exclusivamente las categorías:

```text
Tecnologia
Hogar
Deportes
```

Para cada combinación de **ciudad y categoría** determine:

* cantidad de ventas;
* monto total vendido;
* monto promedio;
* venta mínima;
* venta máxima.

Sin embargo, la gerencia solamente desea observar segmentos que cumplan simultáneamente:

```text
más de 800 ventas

monto total vendido superior a 600.000.000

monto promedio superior a 700.000
```

Finalmente, muestre solamente los **10 segmentos con mayor monto total vendido**.

---

# 2. Este ejercicio integra todo el recorrido

Antes de programar, represente el problema como una secuencia.

Complete:

```text
100.000 REGISTROS
        ↓
____________________
seleccionar período
        ↓
____________________
seleccionar ciudades
        ↓
____________________
seleccionar categorías
        ↓
____________________
crear segmentos
ciudad + categoría
        ↓
____________________
calcular indicadores
        ↓
____________________
seleccionar segmentos
que cumplen los criterios
        ↓
____________________
ordenar
        ↓
____________________
conservar los primeros 10
```

Solo después de completar este esquema escriba la consulta.

---

## Actividad

Construya una **única consulta HiveQL** capaz de responder el problema.

No se proporciona código.

Puede consultar la guía de comandos Apache Hive y los ejercicios anteriores.

---

## Verificación

Su resultado debe cumplir simultáneamente todas estas condiciones:

```text
PERÍODO
2025-01-01 a 2026-12-31

        +

CIUDADES
Santiago
Valparaiso
Concepcion
Antofagasta

        +

CATEGORÍAS
Tecnologia
Hogar
Deportes

        +

CANTIDAD
> 800

        +

TOTAL VENDIDO
> 600.000.000

        +

PROMEDIO
> 700.000

        +

ORDEN
mayor → menor total vendido

        +

RESULTADOS
máximo 10
```

Si alguna de estas condiciones no se cumple, la consulta todavía no responde completamente al problema.

---

## Interpretación

Una vez obtenidos los resultados, responda:

1. ¿Qué segmento ciudad–categoría ocupa la primera posición?
2. ¿Es el segmento con más ventas o simplemente el de mayor monto total?
3. ¿Qué diferencias observa entre los montos promedio de los segmentos?
4. ¿Qué segmento presenta la mayor venta individual?
5. Si usted fuera responsable comercial, ¿qué conclusión inicial extraería del resultado?

---

# 3. Una consulta correcta no es suficiente

En los primeros niveles verificábamos principalmente:

```text
¿FUNCIONÓ LA CONSULTA?
```

En este nivel debemos formular una pregunta adicional:

```text
¿LA CONSULTA RESPONDE
REALMENTE AL PROBLEMA?
```

Hive puede ejecutar correctamente una consulta que no represente correctamente la pregunta de negocio.

Por ejemplo, una consulta puede:

```text
ejecutarse sin errores
        ↓
entregar resultados
        ↓
parecer razonable
```

y aun así:

```text
usar un período incorrecto
        ↓
aplicar OR en lugar de AND
        ↓
agrupar por una variable equivocada
        ↓
filtrar antes cuando debía filtrar después
        ↓
ordenar por un indicador diferente
```

Por tanto:

> **Que una consulta se ejecute correctamente no demuestra que la solución sea correcta.**

---

# 4. Estrategia de validación

Para problemas complejos utilice tres niveles de comprobación.

## Nivel 1 — Validación sintáctica

```text
¿Hive ejecuta la consulta?
```

Si no lo hace, existe un problema de sintaxis o estructura.

---

## Nivel 2 — Validación lógica

```text
¿La consulta implementa
todas las condiciones solicitadas?
```

Revise una por una:

```text
período
ciudades
categorías
agrupación
indicadores
condiciones
ordenamiento
límite
```

---

## Nivel 3 — Validación analítica

```text
¿El resultado tiene sentido?
```

Pregúntese:

```text
¿Las magnitudes parecen razonables?

¿Cada fila representa realmente
la unidad de análisis solicitada?

¿Puedo explicar qué significa
cada indicador?

¿Puedo obtener una conclusión
a partir del resultado?
```

---

# 5. Comprobación del Nivel 3

Al completar los cuatro ejercicios debería poder combinar, según el problema:

```text
SELECT
FROM
WHERE
AND
OR
IN
BETWEEN
LIKE
GROUP BY
HAVING
ORDER BY
LIMIT
```

junto con:

```text
COUNT()
SUM()
AVG()
MIN()
MAX()
```

Pero el aprendizaje central del nivel no consiste en recordar esta lista.

Consiste en poder realizar la transformación:

```text
PREGUNTA DE NEGOCIO
        ↓
LÓGICA DEL PROBLEMA
        ↓
OPERACIONES SOBRE LOS DATOS
        ↓
CONSULTA HIVEQL
        ↓
RESULTADO
        ↓
INTERPRETACIÓN
```

---

# 6. Hemos llegado al final de los niveles

La progresión completa ha sido:

```text
NIVEL 0
¿Qué registros quiero observar?
        ↓

NIVEL 1
¿Qué condiciones deben cumplir?
        ↓

NIVEL 2
¿Cómo puedo resumir y comparar los datos?
        ↓

NIVEL 3
¿Cómo diseño una consulta para
resolver un problema analítico?
```

Hasta ahora todos los ejercicios han entregado algún grado de orientación.

Eso termina aquí.

En los **desafíos finales** recibirá solamente el problema.

No se indicará:

```text
qué cláusula utilizar

qué función utilizar

cómo agrupar

cómo filtrar

cómo ordenar
```

Deberá decidirlo utilizando lo aprendido en esta guía y en la **Guía de comandos Apache Hive**.

El objetivo final ya no será demostrar que conoce un determinado comando.

Será demostrar que puede:

> **transformar autónomamente una necesidad de información en una solución utilizando HiveQL.**

---

## Bloque 7 — Desafíos finales: resolución autónoma

Ha completado los cuatro niveles de trabajo progresivo con Apache Hive.

Durante este recorrido pasó desde consultas simples hasta problemas que requerían combinar múltiples operaciones:

```text
NIVEL 0
Consultar y filtrar
        ↓
NIVEL 1
Construir condiciones
        ↓
NIVEL 2
Agrupar y analizar
        ↓
NIVEL 3
Resolver problemas complejos
        ↓
DESAFÍOS FINALES
Resolver autónomamente
````

Ahora enfrentará tres problemas finales.

---

# 1. Cambian las reglas

En esta sección:

> **No se proporciona código de apoyo.**

Tampoco se indicará qué comandos, cláusulas o funciones debe utilizar.

Para resolver los problemas puede consultar:

* la **Guía de comandos Apache Hive**;
* los ejercicios realizados en esta guía;
* sus propias consultas desarrolladas durante los niveles anteriores.

Continúe trabajando exclusivamente con:

```text
BASE DE DATOS
curso_bigdata

TABLA
ventas_hive

DATOS
100.000 registros
```

No debe crear nuevos archivos ni nuevas tablas.

---

# 2. ¿Qué se espera de usted?

Para cada desafío deberá:

```text
1. Analizar el problema

2. Diseñar una estrategia

3. Construir la consulta HiveQL

4. Ejecutarla

5. Verificar el resultado

6. Interpretar los resultados
```

Una consulta que se ejecuta sin errores **no necesariamente constituye una solución correcta**.

La consulta debe responder exactamente la pregunta planteada.

---

# Desafío final 1 — Comportamiento comercial durante 2026

## Situación

La gerencia desea conocer el comportamiento de las ventas realizadas durante **2026** en las ciudades de:

```text
Santiago
Valparaiso
Concepcion
Antofagasta
```

Se requiere construir un reporte que permita comparar el desempeño de cada ciudad y categoría de producto.

Para cada combinación **ciudad–categoría** determine:

* cantidad de ventas;
* monto total vendido;
* monto promedio por venta;
* venta de menor monto;
* venta de mayor monto.

El reporte deberá considerar solamente aquellos segmentos que hayan registrado **más de 450 ventas durante 2026**.

Los resultados deben aparecer ordenados desde el segmento con **mayor monto total vendido** hasta el de menor.

Muestre solamente los **10 primeros resultados**.

---

## Entrega del desafío

Registre:

### Consulta HiveQL

Escriba la consulta utilizada para resolver el problema.

### Resultado

Registre los resultados obtenidos.

### Interpretación

Responda:

1. ¿Qué combinación ciudad–categoría ocupa la primera posición?
2. ¿Cuál presenta el mayor monto promedio?
3. ¿Existe alguna diferencia entre el segmento con mayor cantidad de ventas y aquel con mayor monto total?
4. ¿Qué conclusión comercial puede obtener a partir del resultado?

---

# Desafío final 2 — Clientes relevantes para una campaña comercial

## Situación

Una empresa desea preparar una campaña especial para sus clientes con mayor actividad.

Para ello analizará exclusivamente las ventas correspondientes a las categorías:

```text
Tecnologia
Hogar
Deportes
```

realizadas durante el período:

```text
2025-01-01
a
2026-12-31
```

Un cliente será considerado relevante para la campaña solamente cuando cumpla simultáneamente estas condiciones:

```text
más de 45 compras

monto total comprado superior a 30.000.000

monto promedio por compra superior a 700.000
```

Para cada cliente seleccionado, el reporte debe mostrar:

* identificador del cliente;
* cantidad de compras;
* monto total comprado;
* monto promedio por compra;
* compra de menor monto;
* compra de mayor monto.

Los clientes deben aparecer ordenados desde el **mayor monto total comprado** hasta el menor.

Muestre solamente los **15 primeros clientes**.

---

## Entrega del desafío

Registre:

### Consulta HiveQL

Escriba la consulta utilizada.

### Resultado

Registre los resultados obtenidos.

### Interpretación

Responda:

1. ¿Qué cliente ocupa la primera posición?
2. ¿Cuántas compras realizó?
3. ¿Cuál fue su monto total comprado?
4. ¿Es también el cliente con mayor monto promedio?
5. ¿Por qué estos clientes podrían resultar especialmente interesantes para una campaña comercial?

---

# Desafío final 3 — Informe ejecutivo de ventas

## Situación

La gerencia solicita un informe ejecutivo para identificar los segmentos comerciales más importantes del dataset.

Se analizarán exclusivamente las ventas realizadas entre:

```text
2024-07-01
```

y:

```text
2026-06-30
```

El análisis debe considerar las ciudades:

```text
Santiago
Valparaiso
Concepcion
Antofagasta
La_Serena
```

y las categorías:

```text
Tecnologia
Hogar
Deportes
Vestuario
```

Para cada combinación **ciudad–categoría** determine:

* cantidad de ventas;
* monto total vendido;
* monto promedio;
* venta mínima;
* venta máxima.

Sin embargo, el informe ejecutivo debe incluir solamente segmentos que cumplan simultáneamente:

```text
más de 500 ventas

monto total vendido superior a 350.000.000

monto promedio superior a 700.000
```

Los resultados deben aparecer ordenados desde el segmento con **mayor monto total vendido** hasta el de menor.

Muestre solamente los **10 segmentos principales**.

---

## Entrega del desafío

Registre:

### Consulta HiveQL

Escriba la consulta completa utilizada para resolver el problema.

### Resultado

Registre los resultados obtenidos.

### Interpretación

A partir exclusivamente de sus resultados, responda:

1. ¿Cuál es el segmento ciudad–categoría con mayor monto total vendido?
2. ¿Cuál presenta la mayor cantidad de ventas?
3. ¿Cuál presenta el mayor monto promedio?
4. ¿Cuál registra la venta individual más alta?
5. ¿Los cuatro indicadores anteriores identifican necesariamente al mismo segmento?
6. Si tuviera que recomendar un segmento comercial prioritario, ¿cuál seleccionaría y qué evidencia utilizaría para justificar su decisión?

---

# 3. Antes de considerar terminado cada desafío

Utilice la siguiente lista de comprobación:

| Comprobación                                 | Estado |
| -------------------------------------------- | :----: |
| Comprendí exactamente el problema            |    ☐   |
| Identifiqué correctamente el período         |    ☐   |
| Utilicé solamente las ciudades solicitadas   |    ☐   |
| Utilicé solamente las categorías solicitadas |    ☐   |
| Definí correctamente la unidad de análisis   |    ☐   |
| Calculé todos los indicadores solicitados    |    ☐   |
| Apliqué correctamente las condiciones        |    ☐   |
| Ordené los resultados según lo solicitado    |    ☐   |
| Respeté la cantidad máxima de resultados     |    ☐   |
| Revisé los resultados obtenidos              |    ☐   |
| Puedo explicar qué significa cada fila       |    ☐   |
| Elaboré una interpretación de los resultados |    ☐   |

No considere terminado el desafío solamente porque Hive haya mostrado:

```text
OK
```

---

# 4. ¿Cómo saber si su solución es correcta?

Realice tres comprobaciones.

## Comprobación 1 — Sintaxis

Pregúntese:

> ¿Hive puede ejecutar mi consulta?

Un error en esta etapa indica normalmente un problema en la construcción de HiveQL.

---

## Comprobación 2 — Lógica

Pregúntese:

> ¿Mi consulta implementa exactamente todas las condiciones solicitadas?

Revise el enunciado y contraste cada requisito con su consulta.

Por ejemplo:

```text
REQUISITO DEL PROBLEMA
          ↕
ELEMENTO DE LA CONSULTA
```

Ningún requisito debería quedar sin representación.

---

## Comprobación 3 — Resultado

Finalmente:

> ¿Los resultados obtenidos tienen sentido?

No confíe ciegamente en el resultado producido por Hive.

Observe los valores.

Compare las magnitudes.

Compruebe las condiciones.

Interprete cada fila.

---

# 5. El objetivo final

Durante esta actividad no hemos trabajado con diferentes datasets para cada comando.

Hemos mantenido deliberadamente:

```text
UN DATASET
    +
UNA TABLA
    +
DIFERENTES PREGUNTAS
```

Lo que ha cambiado progresivamente no son los datos.

Ha cambiado la **complejidad de las preguntas que formulamos sobre ellos**.

```text
ventas_hive
     │
     ├── pregunta simple
     │
     ├── filtro
     │
     ├── múltiples condiciones
     │
     ├── agregación
     │
     ├── análisis por grupos
     │
     ├── restricciones sobre grupos
     │
     └── problema analítico
```

Esta es una idea importante en el trabajo con datos:

> **El valor no proviene solamente de almacenar grandes volúmenes de información, sino de nuestra capacidad para formular preguntas relevantes y transformar los datos en información útil.**

---

# 6. Cierre de los desafíos

Al terminar los tres desafíos debería ser capaz de enfrentar una pregunta nueva y determinar autónomamente:

```text
¿Qué datos necesito?
        ↓
¿Qué registros debo considerar?
        ↓
¿Cuál es mi unidad de análisis?
        ↓
¿Qué debo calcular?
        ↓
¿Qué resultados debo conservar?
        ↓
¿Cómo debo ordenarlos?
        ↓
¿Qué significa el resultado?
```

En otras palabras, el objetivo ya no es recordar cómo se escribe un determinado comando de Hive.

El objetivo es ser capaz de realizar el recorrido completo:

```text
PROBLEMA
   ↓
DATOS
   ↓
LÓGICA
   ↓
HIVEQL
   ↓
RESULTADO
   ↓
INTERPRETACIÓN
   ↓
INFORMACIÓN PARA LA TOMA DE DECISIONES
```

---

## Bloque 8 — Síntesis y cierre del laboratorio

Ha llegado al final de la actividad práctica con Apache Hive.

Durante toda la guía trabajamos deliberadamente con:

```text
UN DATASET
     ↓
100.000 registros
     ↓
UN ARCHIVO CSV
     ↓
HDFS
     ↓
UNA TABLA EXTERNA
     ↓
HIVE
     ↓
MÚLTIPLES PREGUNTAS
````

El objetivo no fue aprender una colección aislada de comandos.

El propósito fue comprender cómo utilizar Hive para transformar datos almacenados en HDFS en información que permita responder preguntas analíticas.

---

# 1. El recorrido completo

Al comienzo de la actividad generamos mediante Python:

```text
ventas_hive.csv
```

Posteriormente realizamos el recorrido:

```text id="qzqkx9"
PYTHON
   │
   ▼
ventas_hive.csv
   │
   │ archivo local
   ▼
hdfs dfs -put
   │
   ▼
HDFS
   │
   ▼
/curso/hive/datos_ventas/
   │
   ▼
ventas_hive.csv
   │
   │ LOCATION
   ▼
HIVE
   │
   ▼
ventas_hive
   │
   ▼
HiveQL
   │
   ▼
RESULTADOS
   │
   ▼
INTERPRETACIÓN
```

Cada elemento cumple una función diferente.

---

# 2. ¿Dónde están realmente los datos?

Esta pregunta debería poder responderla con claridad.

Los registros utilizados durante los ejercicios están almacenados en:

```text id="5x4wxe"
HDFS
```

específicamente en:

```text id="m7a4qb"
/curso/hive/datos_ventas/
```

donde se encuentra:

```text id="vqhkhd"
ventas_hive.csv
```

Podemos comprobarlo mediante:

```bash id="o22uyd"
hdfs dfs -ls /curso/hive/datos_ventas/
```

Por tanto:

> **Hive no reemplaza a HDFS como sistema de almacenamiento distribuido.**

En nuestro laboratorio, HDFS continúa siendo el lugar donde están almacenados los datos.

---

# 3. Entonces, ¿qué aporta Hive?

El archivo almacenado en HDFS contiene líneas como:

```text id="6ylq79"
15432,2026-05-17,Cliente_0245,Valparaiso,Tecnologia,185990.0
```

Por sí sola, esta línea es simplemente una secuencia de valores separados por comas.

Hive permite asociar una estructura lógica:

```text id="1fr73u"
15432
   ↓
id_venta

2026-05-17
   ↓
fecha

Cliente_0245
   ↓
cliente

Valparaiso
   ↓
ciudad

Tecnologia
   ↓
categoria

185990.0
   ↓
monto
```

Gracias a esta estructura podemos formular consultas utilizando HiveQL.

Por ejemplo:

```sql id="agcpg4"
SELECT
    ciudad,
    COUNT(*) AS cantidad_ventas,
    SUM(monto) AS total_vendido
FROM ventas_hive
GROUP BY ciudad
ORDER BY total_vendido DESC;
```

---

# 4. La tabla no es el archivo

Durante el laboratorio creamos:

```text id="07ug9p"
ventas_hive
```

mediante:

```sql id="e6em86"
CREATE EXTERNAL TABLE
```

y establecimos:

```sql id="8jfg2v"
LOCATION '/curso/hive/datos_ventas/';
```

Debemos evitar interpretar esto como:

```text id="6s9ktg"
ventas_hive = ventas_hive.csv
```

La relación correcta es:

```text id="4rzh8j"
TABLA HIVE
ventas_hive
     │
     │ describe cómo
     │ interpretar
     ▼
DATOS EN HDFS
/curso/hive/datos_ventas/
     │
     └── ventas_hive.csv
```

La tabla representa una **estructura lógica sobre los datos**.

---

# 5. ¿Dónde se almacena la información sobre la tabla?

Hive necesita recordar información como:

```text id="u8a91n"
nombre de la tabla

columnas

tipos de datos

formato

ubicación

propiedades
```

Esta información corresponde a:

```text id="hqx2hu"
METADATOS
```

y es gestionada mediante:

```text id="hcvwzw"
Hive Metastore
```

En la arquitectura de nuestro laboratorio:

```text id="mzv2nb"
                HIVE
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
 Hive Metastore            HDFS
        │                   │
        ▼                   ▼
   METADATOS               DATOS
```

Esta distinción es fundamental:

```text id="4ypcjf"
HDFS
↓
almacena los datos

Hive Metastore
↓
mantiene los metadatos

Hive
↓
permite estructurar y consultar
```

---

# 6. NameNode y Hive Metastore no son lo mismo

Otro concepto importante es diferenciar:

```text id="45nvfe"
NAMENODE
```

de:

```text id="4z4jpo"
HIVE METASTORE
```

El NameNode administra metadatos relacionados con HDFS.

Por ejemplo:

```text id="l73n5q"
archivos
directorios
bloques
ubicaciones dentro de HDFS
```

El Hive Metastore administra información relacionada con Hive.

Por ejemplo:

```text id="grs2co"
bases de datos
tablas
columnas
tipos
particiones
ubicaciones asociadas a tablas
```

Conceptualmente:

```text id="mffl4e"
                 ECOSISTEMA
                     │
          ┌──────────┴──────────┐
          │                     │
         HDFS                  HIVE
          │                     │
          ▼                     ▼
      NameNode            Hive Metastore
          │                     │
          ▼                     ▼
metadatos del sistema     metadatos de
de archivos               tablas y esquemas
```

---

# 7. La arquitectura que hemos utilizado

Nuestro laboratorio utiliza contenedores Docker separados para los principales componentes.

De forma simplificada:

```text id="wuh9vh"
                  hive-server
                      │
                      │ HiveQL
                      │
          ┌───────────┴───────────┐
          │                       │
          ▼                       ▼
   hive-metastore               HDFS
          │                       │
          ▼                 ┌─────┴─────┐
     PostgreSQL             │           │
     metadatos          namenode    datanode
                           │           │
                           │           ▼
                           │         DATOS
                           ▼
                       METADATOS
                         HDFS
```

Por tanto, cuando ejecutamos una consulta HiveQL estamos utilizando varios componentes del ecosistema, aunque desde nuestra perspectiva interactuemos principalmente con Hive.

---

# 8. El modelo mental que debe conservar

Si después de este laboratorio tuviera que recordar solamente un esquema, debería ser:

```text id="ptq7gp"
ARCHIVO
   ↓
HDFS
   ↓
DATOS DISTRIBUIDOS
   ↓
HIVE
   ↓
ESTRUCTURA LÓGICA
   ↓
HIVEQL
   ↓
CONSULTA
   ↓
RESULTADO
   ↓
INTERPRETACIÓN
```

Y paralelamente:

```text id="ytd6gv"
                 HIVE
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
    METASTORE                HDFS
        │                     │
        ▼                     ▼
   METADATOS                 DATOS
```

---

# 9. De una pregunta a HiveQL

Durante los ejercicios aprendimos que una consulta debería comenzar con una pregunta.

Por ejemplo:

> ¿Cuáles son las ciudades con mayor monto total vendido durante 2026?

Antes de programar podemos descomponerla:

```text id="nbq1ef"
¿QUÉ PERÍODO?
2026
     ↓
WHERE

¿QUÉ QUIERO COMPARAR?
ciudades
     ↓
GROUP BY

¿QUÉ QUIERO MEDIR?
monto total
     ↓
SUM()

¿CÓMO QUIERO VERLO?
mayor → menor
     ↓
ORDER BY
```

Finalmente construimos HiveQL.

El proceso correcto es:

```text id="e7o3mb"
PREGUNTA
   ↓
LÓGICA
   ↓
HIVEQL
```

y no:

```text id="y7z7a3"
COMANDO
   ↓
¿qué pregunta podría resolver?
```

---

# 10. Herramientas que debería dominar

Después de completar esta actividad debería comprender y utilizar correctamente las siguientes operaciones.

## Explorar el entorno

```sql id="qzsyxf"
SHOW DATABASES;
```

```sql id="av3e8s"
SHOW TABLES;
```

```sql id="isrdb3"
DESCRIBE ventas_hive;
```

```sql id="v2vwy7"
DESCRIBE FORMATTED ventas_hive;
```

---

## Recuperar información

```text id="sf8b38"
SELECT
FROM
LIMIT
```

---

## Filtrar registros

```text id="iq9ey3"
WHERE
AND
OR
IN
BETWEEN
LIKE
```

---

## Comparar valores

```text id="ps0z1u"
=
>
<
>=
<=
<>
```

---

## Resumir información

```text id="4anqvu"
COUNT()
SUM()
AVG()
MIN()
MAX()
```

---

## Analizar grupos

```text id="g3w4k5"
GROUP BY
HAVING
```

---

## Presentar resultados

```text id="ndz4e7"
ORDER BY
ASC
DESC
LIMIT
```

El objetivo no es memorizar esta lista.

Debe ser capaz de decidir **cuándo necesita cada herramienta**.

---

# 11. Una distinción especialmente importante

Compruebe que puede explicar la diferencia entre:

```text id="swqsw5"
WHERE
```

y:

```text id="u0xkue"
HAVING
```

Recuerde:

```text id="owvxqu"
DATOS ORIGINALES
      ↓
    WHERE
      ↓
REGISTROS SELECCIONADOS
      ↓
   GROUP BY
      ↓
GRUPOS + CÁLCULOS
      ↓
    HAVING
      ↓
GRUPOS SELECCIONADOS
```

Por tanto:

```text id="k6xuhj"
WHERE
↓
filtra registros
```

mientras que:

```text id="zstlxr"
HAVING
↓
filtra resultados agrupados
```

Esta diferencia será importante en muchas herramientas de análisis basadas en SQL.

---

# 12. Autoevaluación final

Antes de finalizar, evalúe su nivel de autonomía.

Utilice la siguiente escala:

```text id="3rv6jt"
1 = Todavía necesito ayuda
2 = Puedo hacerlo con una guía
3 = Puedo hacerlo autónomamente
```

| Competencia                              |  1  |  2  |  3  |
| ---------------------------------------- | :-: | :-: | :-: |
| Diferencio el sistema local de HDFS      |  ☐  |  ☐  |  ☐  |
| Puedo cargar un archivo en HDFS          |  ☐  |  ☐  |  ☐  |
| Comprendo qué representa una tabla Hive  |  ☐  |  ☐  |  ☐  |
| Comprendo qué significa `LOCATION`       |  ☐  |  ☐  |  ☐  |
| Diferencio datos de metadatos            |  ☐  |  ☐  |  ☐  |
| Diferencio NameNode de Hive Metastore    |  ☐  |  ☐  |  ☐  |
| Puedo construir una consulta `SELECT`    |  ☐  |  ☐  |  ☐  |
| Puedo aplicar diferentes filtros         |  ☐  |  ☐  |  ☐  |
| Puedo utilizar funciones de agregación   |  ☐  |  ☐  |  ☐  |
| Puedo utilizar `GROUP BY`                |  ☐  |  ☐  |  ☐  |
| Diferencio `WHERE` de `HAVING`           |  ☐  |  ☐  |  ☐  |
| Puedo ordenar y limitar resultados       |  ☐  |  ☐  |  ☐  |
| Puedo combinar varias condiciones        |  ☐  |  ☐  |  ☐  |
| Puedo transformar una pregunta en HiveQL |  ☐  |  ☐  |  ☐  |
| Puedo interpretar el resultado obtenido  |  ☐  |  ☐  |  ☐  |

Observe especialmente los elementos donde marcó:

```text id="kl47i5"
1
```

o:

```text id="t2tqzv"
2
```

Estos indican los contenidos que debería revisar antes de continuar avanzando en el curso.

---

# 13. ¿Qué debería ser capaz de explicar sin ejecutar código?

Al finalizar esta actividad debería poder responder con sus propias palabras:

### Pregunta 1

**¿Qué problema resuelve Apache Hive dentro del ecosistema Hadoop?**

### Pregunta 2

**¿Cuál es la relación entre Hive y HDFS?**

### Pregunta 3

**¿Qué representa una tabla externa de Hive?**

### Pregunta 4

**¿Qué función cumple `LOCATION`?**

### Pregunta 5

**¿Dónde están almacenados los datos y dónde se mantienen sus metadatos?**

### Pregunta 6

**¿Cuál es la diferencia entre NameNode y Hive Metastore?**

### Pregunta 7

**¿Cuál es la diferencia entre `WHERE` y `HAVING`?**

### Pregunta 8

**¿Por qué `GROUP BY` resulta fundamental para realizar análisis sobre los datos?**

### Pregunta 9

**¿Por qué una consulta que se ejecuta sin errores puede entregar una respuesta analíticamente incorrecta?**

### Pregunta 10

**¿Cómo transformaría una pregunta de negocio en una consulta HiveQL?**

Si puede responder estas preguntas sin recurrir inmediatamente al código, habrá comprendido no solamente **cómo utilizar Hive**, sino también **qué función cumple dentro de una arquitectura Big Data**.

---

# 14. Resultado del laboratorio

Durante esta actividad completamos:

```text id="mz03b8"
1 dataset
      ↓
100.000 registros
      ↓
1 archivo en HDFS
      ↓
1 tabla externa
      ↓
4 niveles
      ↓
16 ejercicios progresivos
      ↓
3 desafíos autónomos
```

En total:

```text id="dpsvag"
19 problemas de análisis
```

trabajando siempre sobre los mismos datos.

Esto nos permitió concentrarnos progresivamente en:

```text id="br66o9"
SINTAXIS
   ↓
LÓGICA
   ↓
ANÁLISIS
   ↓
AUTONOMÍA
```

---

# 15. Cierre

Apache Hive incorpora una capa que permite trabajar con datos almacenados en el ecosistema Hadoop utilizando una lógica declarativa similar a SQL.

Durante este laboratorio comprobamos que el proceso no consiste simplemente en ejecutar consultas.

El recorrido completo es:

```text id="g35o7v"
DATOS
  ↓
ALMACENAMIENTO
  ↓
ESTRUCTURA
  ↓
CONSULTA
  ↓
ANÁLISIS
  ↓
INTERPRETACIÓN
```

La competencia que buscamos desarrollar no es solamente:

> **"sé escribir HiveQL".**

El objetivo es avanzar hacia:

> **"puedo utilizar datos almacenados en HDFS, estructurarlos mediante Hive y construir consultas que permitan responder preguntas analíticas".**

Ese es el aprendizaje central de esta actividad.


