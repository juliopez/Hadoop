# Semana 5 — HDFS

## Guía 2: Administración y resolución de problemas en HDFS

### Propósito

En esta segunda actividad práctica profundizaremos en la utilización de **HDFS (Hadoop Distributed File System)**.

A diferencia de la guía anterior, en esta oportunidad **no se entregarán secuencias de comandos para resolver las actividades**. Se espera que cada estudiante sea capaz de identificar el problema, seleccionar las operaciones HDFS apropiadas, ejecutarlas, verificar sus resultados e interpretar técnicamente lo observado.

La actividad se desarrollará bajo el siguiente principio:

> **Problema → Decisión → Ejecución → Evidencia → Interpretación**

El objetivo ya no es aprender a utilizar comandos aislados, sino emplear HDFS para **organizar datos, diagnosticar situaciones, administrar almacenamiento y resolver requerimientos**.

### Prerrequisitos

Antes de comenzar, el estudiante debe ser capaz de:

* acceder a su instancia AWS EC2;
* comprobar que la infraestructura Docker está funcionando;
* ingresar al contenedor `namenode`;
* comprobar que HDFS está operativo;
* distinguir entre el sistema de archivos del contenedor y HDFS;
* crear, copiar, mover, eliminar, cargar y recuperar archivos;
* consultar información sobre almacenamiento, bloques y replicación.

Estos procedimientos fueron desarrollados en la Guía 1. 

Puede utilizar durante toda la actividad:

* Guía 1 de HDFS;
* Guía de comandos HDFS;
* ayuda proporcionada por los propios comandos.

**No es necesario memorizar sintaxis.**

---

# 1. Diagnóstico inicial del entorno

Su primera tarea consiste en determinar si el entorno se encuentra en condiciones de comenzar a trabajar.

Sin recibir una secuencia de comandos, obtenga evidencia que permita demostrar:

1. que se encuentra conectado a la instancia Linux correspondiente;
2. que Docker está operativo;
3. que el contenedor `namenode` está disponible;
4. que puede acceder al contenedor;
5. que HDFS responde correctamente;
6. cuántos DataNodes se encuentran actualmente disponibles;
7. cuál es la capacidad total, utilizada y disponible reportada por HDFS.

Complete:

| Elemento diagnosticado | Resultado | Evidencia/comando utilizado |
| ---------------------- | --------- | --------------------------- |
| Docker operativo       |           |                             |
| NameNode disponible    |           |                             |
| HDFS operativo         |           |                             |
| DataNodes disponibles  |           |                             |
| Capacidad total        |           |                             |
| Capacidad utilizada    |           |                             |
| Capacidad disponible   |           |                             |

### Análisis

**¿Considera que HDFS se encuentra en condiciones de realizar la actividad? Fundamente utilizando la evidencia obtenida.**

> **Importante:** no continúe si HDFS no se encuentra operativo. Identifique primero en qué capa se presenta el problema.

---

# 2. Problemas de administración HDFS

A continuación se presentan cuatro situaciones independientes.

En cada una deberá aplicar:

**Diagnosticar → solucionar → verificar.**

## Situación A — El archivo que “desapareció”

Un integrante del equipo afirma que el archivo:

```text
/empresa/clientes/clientes.csv
```

ha desaparecido porque ejecutó:

```bash
ls /empresa/clientes
```

y recibió un mensaje indicando que la ruta no existe.

Determine si esta evidencia es suficiente para concluir que el archivo fue eliminado.

### Entregue

* diagnóstico;
* operación utilizada para comprobarlo;
* evidencia;
* conclusión técnica.

---

## Situación B — Archivo duplicado

Se intenta incorporar nuevamente a HDFS un archivo utilizando exactamente una ruta y nombre que ya existen.

HDFS rechaza la operación.

Investigue el problema y determine **al menos dos estrategias diferentes** que permitirían resolverlo dependiendo del requerimiento de la organización.

No se solicita simplemente eliminar el archivo.

Explique qué consecuencia tendría cada alternativa sobre la información existente.

---

## Situación C — Archivo en ubicación incorrecta

Un archivo correspondiente a ventas fue almacenado accidentalmente en:

```text
/empresa/clientes/ventas_abril.csv
```

pero debe encontrarse en:

```text
/empresa/ventas/2026/abril/
```

Corrija el problema **sin volver a cargar el archivo desde el sistema local**.

Al finalizar debe demostrar:

* que ya no se encuentra en la ubicación incorrecta;
* que está disponible en la ubicación correcta;
* que su contenido se mantiene accesible.

---

## Situación D — Recuperación accidental

Un usuario necesita obtener una copia local de un archivo HDFS para trabajar con ella, pero el archivo original debe permanecer intacto.

Determine qué operación utilizaría y demuestre experimentalmente que el archivo continúa disponible en HDFS después de recuperar la copia.

### Explique

¿Por qué esta operación es conceptualmente diferente de mover un archivo dentro de HDFS?

---

# 3. Diseño de una estructura de almacenamiento

Una empresa de transporte comienza a centralizar información en HDFS.

Actualmente recibe:

```text
viajes_2026_01.csv
viajes_2026_02.csv
viajes_2026_03.csv

vehiculos.csv

sensores_2026_01.log
sensores_2026_02.log
sensores_2026_03.log
```

La organización necesita conservar:

* datos originales recibidos;
* información preparada para futuros procesos;
* respaldos;
* separación por tipo de fuente;
* organización temporal cuando corresponda.

## Su tarea

**Diseñe primero la estructura HDFS. No ejecute comandos todavía.**

Represente su propuesta mediante un árbol similar a:

```text
/
└── ...
    ├── ...
    └── ...
```

No existe una única estructura correcta.

Sin embargo, su propuesta debe ser:

* coherente;
* comprensible;
* escalable ante la llegada de nuevos meses;
* capaz de distinguir los distintos estados de los datos.

### Antes de implementarla, responda

**¿Qué criterio utilizó para organizar los directorios?**

**¿Dónde almacenaría los datos originales?**

**¿Cómo incorporaría información correspondiente a abril de 2026 sin rediseñar completamente la estructura?**

Una vez definida y justificada la propuesta, **impleméntela en HDFS y demuestre que coincide con su diseño**.

---

# 4. Gestión del ciclo de vida de los datos

La organización establece ahora el siguiente ciclo:

```text
FUENTE
   ↓
INGESTA
   ↓
RAW
   ↓
PROCESSED
   ↓
ARCHIVE
```

Interprete cada estado como:

**RAW:** información original recibida, sin modificaciones.

**PROCESSED:** información que ha sido preparada para usos posteriores.

**ARCHIVE:** información que debe conservarse, pero que ya no corresponde al conjunto activo de trabajo.

## Requerimiento

Utilizando los archivos de la actividad anterior:

1. determine cuáles deberían incorporarse inicialmente a `RAW`;
2. organícelos de acuerdo con su diseño;
3. seleccione al menos un archivo y genere una copia que represente su paso hacia `PROCESSED`;
4. traslade uno de los archivos más antiguos hacia `ARCHIVE`;
5. demuestre el estado final del almacenamiento.

### Importante

En esta actividad **no estamos procesando datos**. El propósito es representar mediante HDFS diferentes estados del ciclo de vida de la información.

### Análisis

Explique la diferencia entre:

```text
RAW → PROCESSED
```

y:

```text
RAW → ARCHIVE
```

desde el punto de vista de la gestión de los archivos.

---

# 5. Gestión del almacenamiento y archivos pequeños

Considere dos escenarios hipotéticos:

### Escenario A

```text
1 archivo de 500 MB
```

### Escenario B

```text
10.000 archivos de 50 KB
```

Ambos representan información almacenada, pero su comportamiento dentro de HDFS no necesariamente será equivalente.

A partir de lo estudiado sobre **archivos, bloques, NameNode y metadatos**, responda:

1. ¿Qué diferencias identifica entre ambos escenarios?
2. ¿Cuál implica administrar una mayor cantidad de archivos?
3. ¿Qué componente de HDFS debe mantener la información asociada a esos archivos?
4. ¿Por qué una gran cantidad de archivos pequeños puede representar un escenario diferente de almacenar pocos archivos grandes?

### Decisión

Si una organización pudiera almacenar miles de registros relacionados como:

**A.** miles de pequeños archivos independientes; o
**B.** un conjunto menor de archivos de mayor tamaño;

¿qué alternativa consideraría más coherente con la lógica de HDFS?

**Fundamente.**

---

# 6. Generación de archivos de gran tamaño con apoyo de IA generativa

Hasta este punto hemos trabajado principalmente con archivos pequeños. Sin embargo, HDFS fue diseñado para almacenar grandes volúmenes de información y dividir los archivos en **bloques**.

En esta actividad utilizaremos una herramienta de **IA generativa** para diseñar un procedimiento que permita crear archivos de mayor tamaño dentro de la instancia Linux.

El objetivo no es que la IA “resuelva” el ejercicio, sino que actúe como apoyo para generar archivos sintéticos de diferentes tamaños que posteriormente podamos analizar en HDFS

## Actividad

Solicite a una herramienta de IA generativa que le proponga un script en Python capaz de generar un archivo CSV sintético con información similar a:

```text
timestamp,id_sensor,temperatura,humedad,latitud,longitud
```

El archivo debe:

* contener datos sintéticos;
* incluir una cabecera;
* generar registros aleatorios o simulados;
* permitir controlar la cantidad de filas;
* permitir generar archivos de distintos tamaños, incluyendo al menos uno cuyo tamaño sea suficiente para utilizar varios bloques HDFS.

> El script debe permitir configurar mediante variables el **nombre del archivo de salida** y la **cantidad de registros**, de manera que pueda ejecutarse varias veces para generar archivos de diferentes tamaños.

### Prompt sugerido

```text
Genera un script en Python que permita crear archivos CSV sintéticos.

El script debe permitir configurar mediante variables:
- el nombre del archivo de salida;
- la cantidad de filas que se generarán.

El archivo debe contener las columnas:
timestamp, id_sensor, temperatura, humedad, latitud y longitud.

El script debe generar datos sintéticos y permitir crear archivos de diferentes
tamaños, incluyendo archivos de varios cientos de MB, para experimentar
posteriormente con bloques en HDFS.

El script debe:
- utilizar únicamente librerías estándar de Python;
- escribir los datos progresivamente para no mantener todo el dataset en memoria;
- mostrar al finalizar la cantidad de filas generadas y el tamaño aproximado del archivo;
- incluir comentarios que permitan comprender el código.
```

## Importante

No ejecute automáticamente cualquier código generado por IA.

Antes de utilizarlo:

1. lea el script;
2. identifique qué archivo generará;
3. revise dónde será almacenado;
4. compruebe que no elimina ni modifica archivos existentes;
5. determine aproximadamente cuántas filas necesita generar.

La IA es una herramienta de apoyo. **La responsabilidad de revisar y ejecutar el código continúa siendo del estudiante.**

## Generar diferentes tamaños

Genere al menos **tres archivos**:

```text
sensores_pequeno.csv
sensores_mediano.csv
sensores_grande.csv
```

La idea es producir tamaños distintos, por ejemplo:

```text
Archivo pequeño   → claramente menor que un bloque HDFS
Archivo mediano   → suficientemente grande para superar un bloque
Archivo grande    → suficientemente grande para utilizar varios bloques
```

No es necesario que todos los estudiantes generen exactamente el mismo tamaño.

Después de generar cada archivo, obtenga su tamaño en Linux:

```bash
ls -lh
```

o:

```bash
du -h sensores_grande.csv
```

Registre:

| Archivo                | Tamaño observado |
| ---------------------- | ---------------: |
| `sensores_pequeno.csv` |                  |
| `sensores_mediano.csv` |                  |
| `sensores_grande.csv`  |                  |

---

# 7. Bloques: predecir, almacenar y observar

En la actividad anterior generó tres archivos de distinto tamaño con apoyo de IA generativa. Ahora utilizaremos esos archivos para analizar experimentalmente cómo HDFS distribuye la información en bloques.

La secuencia de trabajo será:

```text
CONOCER EL TAMAÑO DEL BLOQUE
            ↓
CONOCER EL TAMAÑO DEL ARCHIVO
            ↓
PREDECIR
            ↓
CARGAR EN HDFS
            ↓
OBSERVAR
            ↓
COMPARAR
            ↓
INTERPRETAR
```

> **Importante:** realice sus predicciones **antes de cargar los archivos a HDFS**. El objetivo de esta actividad no es acertar necesariamente, sino formular una hipótesis y posteriormente contrastarla con evidencia.

## Etapa 1 — Determinar el tamaño de bloque de HDFS

Antes de realizar cualquier predicción, investigue cuál es el **tamaño de bloque configurado en el HDFS del laboratorio**.

Registre:

```text
Tamaño de bloque configurado: __________________
```

Indique además cómo obtuvo esta información:

```text
Evidencia/comando utilizado: ___________________
```

---

## Etapa 2 — Recuperar los tamaños de los archivos generados

Utilice los tres archivos creados en la actividad anterior:

```text
sensores_pequeno.csv
sensores_mediano.csv
sensores_grande.csv
```

Compruebe nuevamente sus tamaños en el sistema de archivos Linux.

Registre:

| Archivo                | Tamaño observado |
| ---------------------- | ---------------: |
| `sensores_pequeno.csv` |                  |
| `sensores_mediano.csv` |                  |
| `sensores_grande.csv`  |                  |

---

## Etapa 3 — Predecir

Ahora relacione:

**tamaño del archivo ↔ tamaño de bloque HDFS**

Antes de incorporar los archivos a HDFS, prediga cuántos bloques espera que utilice cada uno.

| Archivo                | Tamaño | Bloques que espero | Justificación |
| ---------------------- | -----: | -----------------: | ------------- |
| `sensores_pequeno.csv` |        |                    |               |
| `sensores_mediano.csv` |        |                    |               |
| `sensores_grande.csv`  |        |                    |               |

No consulte todavía los bloques reales.

### Antes de continuar

Explique brevemente:

**¿Qué relación utilizó para realizar sus predicciones?**

---

## Etapa 4 — Incorporar los archivos a HDFS

Cree una ubicación apropiada dentro de HDFS para realizar el experimento e incorpore:

```text
sensores_pequeno.csv
sensores_mediano.csv
sensores_grande.csv
```

La selección de la ruta y de las operaciones necesarias corresponde al estudiante.

Una vez realizada la carga, **demuestre que los tres archivos se encuentran efectivamente almacenados en HDFS**.

---

## Etapa 5 — Observar los bloques

Ahora investigue cómo HDFS almacenó realmente cada archivo.

Puede utilizar las herramientas estudiadas anteriormente para inspeccionar archivos, bloques y ubicaciones.

Entre ellas:

```bash
hdfs fsck /ruta/archivo -files -blocks -locations
```

Registre los resultados:

| Archivo                | Bloques predichos | Bloques observados | ¿Coincide? |
| ---------------------- | ----------------: | -----------------: | ---------- |
| `sensores_pequeno.csv` |                   |                    |            |
| `sensores_mediano.csv` |                   |                    |            |
| `sensores_grande.csv`  |                   |                    |            |

> Si alguna predicción no coincide con lo observado, **no modifique su predicción original**. La diferencia forma parte del análisis.

---

## Etapa 6 — Observar HDFS mediante la interfaz web

Hasta ahora hemos inspeccionado HDFS principalmente mediante la línea de comandos.

Ahora acceda a la **interfaz web del NameNode**, disponible en el entorno del laboratorio mediante el puerto **50070**.

Explore la interfaz e identifique qué información puede observar relacionada con:

* estado general de HDFS;
* NameNode;
* DataNode disponible;
* capacidad de almacenamiento;
* archivos y directorios;
* bloques, cuando la interfaz permita visualizarlos.

No se limite a observar la interfaz. Intente relacionar la información presentada gráficamente con los resultados obtenidos anteriormente mediante los comandos HDFS.

---

## Etapa 7 — Comparar e interpretar

Utilizando las evidencias obtenidas mediante:

```text
tamaño del archivo
        +
predicción
        +
HDFS
        +
fsck
        +
interfaz web
```

responda:

1. ¿Cuál de los tres archivos fue dividido en mayor cantidad de bloques?
2. ¿Qué relación observa entre el tamaño del archivo, el tamaño de bloque configurado y la cantidad de bloques utilizados?
3. ¿Sus predicciones coincidieron con lo observado? Si alguna no coincidió, explique la diferencia.
4. ¿Qué información aporta fsck que resulta útil para comprender cómo HDFS distribuye y administra internamente los bloques de un archivo?
5. ¿Qué información resulta más sencilla de interpretar mediante la interfaz web del NameNode?
6. ¿Qué diferencia existe entre observar `sensores_grande.csv` como **un único archivo lógico** y observar los **bloques utilizados internamente por HDFS**?

### Conclusión

A partir del experimento, explique con sus propias palabras la siguiente idea:

> **Para el usuario, HDFS presenta un archivo como una unidad; internamente, ese archivo puede encontrarse dividido y administrado mediante múltiples bloques.**

---

# 8. Replicación y límites de la infraestructura

Esta actividad debe realizarse considerando la arquitectura real del laboratorio.

El `docker-compose` utilizado actualmente implementa **un NameNode y un único DataNode**. 

Seleccione `sensores_grande.csv`, generado y utilizado en la actividad anterior.

## Primero: observe

Determine:

* factor de replicación actual;
* DataNodes disponibles;
* estado general del archivo.

## Después: formule una hipótesis

La organización solicita:

> “Configure este archivo con factor de replicación 3 para disponer de tres copias de sus bloques.”

**Antes de ejecutar cualquier modificación, prediga qué ocurrirá.**

Registre su hipótesis.

## Ahora experimente

Solicite el nuevo factor de replicación y observe cuidadosamente el resultado.

Investigue nuevamente:

* factor solicitado;
* estado del archivo;
* bloques;
* DataNodes disponibles;
* cualquier información relevante que reporte HDFS.

### Responda

1. ¿Puede HDFS registrar una solicitud de replicación 3?
2. ¿Puede nuestra infraestructura almacenar físicamente tres réplicas en DataNodes diferentes?
3. ¿Por qué?
4. ¿Qué modificación de infraestructura sería necesaria para que la replicación 3 pudiera materializarse correctamente?

### Conclusión

Explique con sus propias palabras la afirmación:

> **Una configuración lógica no puede crear recursos físicos inexistentes.**

---

# 9. Diagnóstico y recuperación ante errores

En esta sección no debe eliminar toda la estructura y comenzar nuevamente.

El objetivo es **diagnosticar y corregir**.

## Error 1

Un integrante creó accidentalmente:

```text
/datos/2026/ventas/clientes
```

cuando la estructura acordada era:

```text
/datos/2026/clientes
```

Corrija la estructura preservando los archivos existentes.

---

## Error 2

Un archivo fue almacenado con el nombre:

```text
viajes_2026_03_ERROR.csv
```

pero debe conservarse como:

```text
viajes_2026_03.csv
```

Corrija la situación sin volver a cargar el archivo.

---

## Error 3

Un integrante afirma:

> “No encuentro `vehiculos.csv` y no recuerdo dónde lo almacenamos.”

Localice el archivo dentro de la estructura HDFS existente sin asumir previamente su ubicación.

---

## Error 4

Otro integrante ejecutó una operación y ahora existen dos copias del mismo archivo en directorios donde solo debería existir una.

Determine:

* cuál debe conservarse;
* cuál debe eliminarse;
* cómo verificará que eliminó exclusivamente la copia incorrecta.

### Regla de esta sección

> **Antes de corregir, obtenga evidencia del problema. Después de corregir, obtenga evidencia de la solución.**

---

# 10. Caso integrador — TransportData

La empresa **TransportData** administra información generada por su operación diaria.

Cada mes recibe:

* registros de viajes en formato CSV;
* información actualizada de vehículos en CSV;
* registros de sensores en formato LOG.

Actualmente dispone de:

```text
viajes_2026_01.csv
viajes_2026_02.csv
viajes_2026_03.csv
vehiculos.csv
sensores_2026_01.log
sensores_2026_02.log
sensores_2026_03.log
```

La organización ha decidido utilizar HDFS como plataforma de almacenamiento.

## Requerimientos

Usted deberá diseñar e implementar una solución que permita:

* conservar los archivos originales;
* distinguir información activa, preparada y archivada;
* separar las diferentes fuentes;
* mantener una organización temporal;
* incorporar nuevos meses sin rediseñar la estructura;
* identificar fácilmente la ubicación de cada archivo;
* recuperar información cuando sea necesario;
* conocer el espacio utilizado;
* inspeccionar cómo HDFS almacena los archivos;
* conocer el estado de replicación;
* mantener una estructura comprensible para otro administrador;
* incorporar al menos uno de los archivos de gran tamaño generados durante la actividad experimental;
* determinar su tamaño, cantidad de bloques y factor de replicación;
* utilizar esta evidencia para explicar cómo HDFS administra internamente el archivo.

## Restricciones

No se proporciona:

* estructura de directorios;
* secuencia de operaciones;
* comandos;
* nombres de directorios obligatorios, salvo aquellos que usted justifique como parte de su diseño.

## Etapa A — Diseño

Antes de utilizar HDFS entregue:

```text
Arquitectura propuesta
```

mediante un árbol de directorios.

Junto al diseño explique brevemente **por qué organizó los datos de esa manera**.

## Etapa B — Implementación

Implemente la solución.

## Etapa C — Verificación

Obtenga evidencia suficiente para demostrar que:

* la estructura coincide con el diseño;
* los archivos se encuentran donde corresponde;
* los datos pueden ser consultados;
* conoce el espacio utilizado;
* puede inspeccionar bloques y replicación;
* puede recuperar un archivo sin afectar el original;
* demostrar, para el archivo de gran tamaño seleccionado, su tamaño, cantidad de bloques y factor de replicación.

## Etapa D — Incidente

Una vez terminada la implementación ocurre lo siguiente:

> `sensores_2026_02.log` aparece dentro del directorio correspondiente a viajes.

**No reconstruya la solución.**

Diagnostique y corrija el incidente.

## Etapa E — Nuevo requerimiento

La empresa recibe:

```text
viajes_2026_04.csv
sensores_2026_04.log
```

Explique dónde deberían incorporarse **antes de hacerlo**.

Posteriormente incorpórelos y demuestre que el diseño original permitió agregar abril sin reorganizar completamente HDFS.

---

# 11. Reflexión técnica final


### 1.

¿Cuál es la diferencia entre **saber ejecutar comandos HDFS** y **administrar información utilizando HDFS**?

### 2.

¿Qué criterio utilizó para diseñar su estructura de almacenamiento?

### 3.

¿Qué información administra el NameNode y qué información almacena el DataNode?

### 4.

¿Por qué conocer el tamaño de los bloques resulta relevante para comprender cómo HDFS almacena archivos?

### 5.

¿Qué aprendió el experimento de replicación considerando que nuestro laboratorio dispone actualmente de un único DataNode?

### 6.

Ante un error en HDFS, ¿por qué es preferible diagnosticar antes de eliminar o reconstruir una estructura?

### 7.

Si recibiera mañana un nuevo conjunto de datos, ¿qué decisiones debería tomar **antes** de incorporarlo a HDFS?

---

## Resultado esperado de la Guía 2

Al finalizar esta actividad, el estudiante debería haber avanzado desde:

> **“Sé utilizar comandos de HDFS.”**

hacia:

> **“Puedo analizar un requerimiento de almacenamiento, diseñar una estructura en HDFS, seleccionar las operaciones necesarias, verificar su funcionamiento, interpretar bloques y replicación, diagnosticar errores y justificar técnicamente las decisiones adoptadas.”**


