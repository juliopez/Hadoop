# Semana 9 — Guía de Estudio: Apache Spark

## 1. Apache Spark: origen e historia

Apache Spark es un **motor de procesamiento distribuido de datos** diseñado para ejecutar operaciones sobre grandes volúmenes de información utilizando los recursos de múltiples computadores de manera coordinada.

Para comprender por qué Spark se convirtió en una de las tecnologías más relevantes dentro del ecosistema Big Data, es necesario revisar primero el contexto tecnológico en el que apareció.

---

### 1.1 Antes de Spark: Hadoop y MapReduce

Durante los primeros años del desarrollo de Big Data, **Apache Hadoop** se consolidó como una de las principales plataformas para almacenar y procesar grandes volúmenes de datos utilizando clústeres de computadores.

Dos componentes fueron fundamentales en este modelo:

- **HDFS (Hadoop Distributed File System):** encargado del almacenamiento distribuido.
- **MapReduce:** modelo utilizado para procesar los datos almacenados en el clúster.

El funcionamiento general podía representarse de la siguiente manera:

```text
Grandes volúmenes de datos
          │
          ▼
         HDFS
          │
          ▼
      MapReduce
          │
     ┌────┴────┐
     │         │
    Map      Reduce
     │         │
     └────┬────┘
          │
          ▼
      Resultado
```

Este enfoque permitió distribuir el procesamiento entre diferentes nodos y ejecutar tareas que anteriormente requerían computadores de gran capacidad.

Sin embargo, MapReduce presentaba una característica importante: durante la ejecución de trabajos complejos, los resultados intermedios eran frecuentemente escritos y posteriormente recuperados desde el sistema de almacenamiento.

De manera simplificada:

```text
HDFS
 │
 ▼
Map
 │
 ▼
Disco
 │
 ▼
Reduce
 │
 ▼
HDFS
```

Cuando un análisis requería varias etapas consecutivas, este ciclo podía repetirse numerosas veces.

El modelo era robusto y adecuado para muchos procesos **batch**, pero podía resultar poco eficiente para algoritmos que necesitaban reutilizar repetidamente los mismos datos.

---

### 1.2 El problema del procesamiento iterativo

Imagine un algoritmo que necesita realizar varias operaciones sucesivas sobre un mismo conjunto de datos.

Conceptualmente podría ocurrir algo similar a lo siguiente:

```text
Datos
  │
  ▼
Proceso 1
  │
  ▼
Resultado intermedio
  │
  ▼
Proceso 2
  │
  ▼
Resultado intermedio
  │
  ▼
Proceso 3
  │
  ▼
Resultado
```

Si cada resultado intermedio debe escribirse y posteriormente recuperarse desde almacenamiento, aumenta la cantidad de operaciones de entrada y salida (**I/O**).

Este problema resulta especialmente relevante en cargas de trabajo como:

* algoritmos iterativos;
* análisis interactivo;
* procesamiento repetitivo de conjuntos de datos;
* determinados algoritmos de Machine Learning;
* procesamiento compuesto por múltiples transformaciones.

Era necesario un modelo que permitiera mantener y reutilizar información de manera más eficiente durante el procesamiento.

---

### 1.3 El nacimiento de Apache Spark

Spark comenzó a desarrollarse en **2009** en el **AMPLab de la Universidad de California, Berkeley**.

Uno de sus principales objetivos era proporcionar un modelo de procesamiento distribuido más flexible para determinadas cargas de trabajo que resultaban costosas utilizando exclusivamente el paradigma MapReduce.

Una de las ideas fundamentales fue permitir que los datos pudieran mantenerse y reutilizarse **en memoria** cuando las condiciones y recursos disponibles lo permitieran.

El cambio conceptual puede representarse de manera simplificada así:

```text
Modelo basado fuertemente en disco

Proceso
   │
   ▼
 Disco
   │
   ▼
Proceso
   │
   ▼
 Disco
```

frente a:

```text
Procesamiento con Spark

        Memoria
           │
     ┌─────┴─────┐
     ▼           ▼
 Proceso 1 → Proceso 2 → Proceso 3
```

Esto no significa que Spark procese siempre todos los datos exclusivamente en memoria.

Spark también utiliza almacenamiento persistente y puede escribir datos en disco. La diferencia fundamental es que su arquitectura permite **reutilizar eficientemente datos intermedios**, incluyendo la posibilidad de mantenerlos en memoria cuando resulta conveniente.

---

### 1.4 De proyecto universitario a Apache Spark

El proyecto continuó evolucionando y posteriormente fue liberado como software de código abierto.

En **2013**, Spark ingresó a la Apache Software Foundation y, en **2014**, pasó a convertirse en un proyecto de nivel superior (*Top-Level Project*).

A partir de entonces comenzó a consolidarse como una plataforma de procesamiento distribuido utilizada tanto en investigación como en entornos empresariales.

Su evolución también amplió considerablemente sus capacidades.

Spark dejó de estar asociado solamente al procesamiento de colecciones distribuidas y comenzó a integrar diferentes formas de procesamiento de datos.

```text
                 Apache Spark
                      │
       ┌──────────────┼──────────────┐
       │              │              │
       ▼              ▼              ▼
      RDD        Spark SQL      Streaming
       │              │              │
       └──────────────┼──────────────┘
                      │
                      ▼
                     ML
```

Actualmente, el ecosistema Spark permite trabajar con datos estructurados y no estructurados, procesamiento distribuido, consultas SQL, flujos de datos y algoritmos de Machine Learning, entre otras posibilidades.

---

### 1.5 Spark no reemplaza a HDFS

Un error frecuente cuando se comienza a estudiar Spark consiste en pensar que esta tecnología reemplaza completamente a Hadoop.

Esto no es correcto.

Spark es fundamentalmente un **motor de procesamiento**, mientras que HDFS es un **sistema de archivos distribuido**.

Por lo tanto, ambas tecnologías pueden trabajar conjuntamente.

```text
             HDFS
              │
              │ datos
              ▼
        Apache Spark
              │
              │ procesamiento
              ▼
          Resultado
```

Spark puede leer datos almacenados en HDFS, procesarlos de manera distribuida y posteriormente almacenar los resultados nuevamente en HDFS u otros sistemas.

Esta relación será especialmente importante en nuestro curso.

Hasta ahora hemos trabajado principalmente con:

```text
Datos
  │
  ▼
 HDFS
  │
  ▼
 Hive
```

Ahora incorporaremos una nueva capa de procesamiento:

```text
                HDFS
                  │
          ┌───────┴───────┐
          │               │
          ▼               ▼
        Hive            Spark
          │               │
          ▼               ▼
     Consulta SQL     Procesamiento
```

Esto permitirá observar que las tecnologías estudiadas durante el curso **no constituyen herramientas aisladas**, sino componentes que pueden integrarse dentro de una arquitectura Big Data.

---

### 1.6 Spark tampoco es un lenguaje de programación

Otra distinción importante es que **Apache Spark no es un lenguaje de programación**.

Spark proporciona un motor y diferentes API que permiten interactuar con él utilizando distintos lenguajes.

Entre ellos se encuentran:

* Scala;
* Python;
* Java;
* R;
* SQL.

En este curso nos concentraremos principalmente en dos:

```text
                   Apache Spark
                        │
               ┌────────┴────────┐
               │                 │
               ▼                 ▼
             Scala             Python
               │                 │
               │              PySpark
               │                 │
               └────────┬────────┘
                        ▼
                  Motor Spark
```

**Scala** posee una relación histórica muy estrecha con Spark y permite comprender con claridad varias de sus abstracciones fundamentales.

**PySpark**, por otra parte, permite utilizar Spark desde Python, lenguaje ampliamente utilizado actualmente en análisis de datos, ciencia de datos y Machine Learning.

Por esta razón, durante el curso trabajaremos de manera equilibrada con ambos.

---

### 1.7 De MapReduce a Spark: una evolución conceptual

Spark no debe entenderse simplemente como una versión más rápida de MapReduce.

Existe también una evolución en la forma de construir procesos distribuidos.

En MapReduce, el procesamiento se estructura principalmente alrededor de las operaciones:

```text
MAP
 │
 ▼
SHUFFLE
 │
 ▼
REDUCE
```

Spark permite construir cadenas más flexibles de transformaciones:

```text
Datos
  │
  ▼
Transformación
  │
  ▼
Transformación
  │
  ▼
Transformación
  │
  ▼
Acción
```

Spark analiza estas operaciones y construye internamente un **plan de ejecución**.

Este concepto será fundamental más adelante cuando estudiemos:

* transformaciones;
* acciones;
* evaluación perezosa (*lazy evaluation*);
* particiones;
* DAG (*Directed Acyclic Graph*);
* tareas y etapas de ejecución.

---

### 1.8 Un cambio importante en nuestro recorrido

Hasta este momento hemos estudiado principalmente cómo **almacenar, distribuir, consultar y organizar datos**.

Con Spark comenzamos a concentrarnos de manera más profunda en el **procesamiento distribuido**.

Nuestro recorrido puede resumirse así:

```text
HDFS
 │
 │ ¿Cómo almacenamos datos
 │ de manera distribuida?
 ▼
Hive
 │
 │ ¿Cómo estructuramos y
 │ consultamos esos datos?
 ▼
Spark
 │
 │ ¿Cómo los procesamos
 │ de manera distribuida?
 ▼
Análisis de datos
```

Por lo tanto, Spark no constituye un tema aislado dentro del curso.

Representa una nueva etapa dentro de la misma arquitectura Big Data que hemos venido construyendo.

---

## Idea fundamental del apartado

Apache Spark surgió para proporcionar un modelo de procesamiento distribuido más flexible y eficiente para determinadas cargas de trabajo que el paradigma tradicional de MapReduce.

La idea que debemos conservar es:

> **HDFS almacena los datos de manera distribuida; Spark permite procesarlos de manera distribuida.**

En los siguientes apartados estudiaremos qué ocurre internamente cuando Spark recibe un trabajo y cómo logra distribuir su ejecución entre diferentes recursos computacionales.

---

## 2. ¿Qué problema intenta resolver Apache Spark?

En el apartado anterior observamos que Apache Spark surgió en un contexto donde Hadoop y MapReduce ya habían demostrado que era posible **procesar grandes volúmenes de datos utilizando múltiples computadores**.

Por lo tanto, Spark no aparece porque el procesamiento distribuido no existiera.

El problema era diferente:

> **¿Cómo ejecutar procesos distribuidos complejos de una manera más flexible, reutilizando eficientemente los datos y evitando operaciones de entrada y salida innecesarias?**

Para comprender esta pregunta debemos observar con mayor detalle cómo se comportan diferentes tipos de procesamiento.

---

### 2.1 El procesamiento por lotes

Una gran parte de los primeros sistemas Big Data estaba orientada al procesamiento por lotes o **batch processing**.

En este modelo se dispone de un conjunto de datos y se ejecuta un proceso completo sobre ellos.

Por ejemplo:

```text
Archivo de ventas
       │
       ▼
 Procesamiento
       │
       ▼
Ventas por ciudad
```

Este enfoque funciona correctamente cuando el proceso puede ejecutarse como una secuencia relativamente simple:

```text
Entrada → Procesamiento → Resultado
```

MapReduce fue especialmente adecuado para este tipo de trabajos.

Sin embargo, no todos los problemas de análisis de datos tienen esta estructura.

---

### 2.2 Cuando un proceso necesita varias etapas

Supongamos ahora que necesitamos realizar diferentes operaciones sobre el mismo conjunto de datos:

```text
Datos
  │
  ▼
Filtrar registros
  │
  ▼
Agrupar información
  │
  ▼
Calcular estadísticas
  │
  ▼
Ordenar resultados
  │
  ▼
Generar resultado
```

En un modelo donde cada etapa necesita almacenar y recuperar resultados intermedios, el procesamiento puede requerir múltiples operaciones de lectura y escritura.

Conceptualmente:

```text
Datos
  │
  ▼
Proceso 1
  │
  ▼
Disco
  │
  ▼
Proceso 2
  │
  ▼
Disco
  │
  ▼
Proceso 3
  │
  ▼
Resultado
```

Estas operaciones de entrada y salida pueden convertirse en una parte importante del tiempo total de ejecución.

Spark fue diseñado para permitir que varias operaciones puedan organizarse como parte de un mismo flujo de procesamiento y que determinados datos puedan **reutilizarse sin necesidad de escribirlos persistentemente después de cada transformación**.

---

### 2.3 El problema se vuelve mayor con los algoritmos iterativos

Existen procesos que necesitan trabajar repetidamente sobre los mismos datos.

Este comportamiento aparece, por ejemplo, en determinados algoritmos de:

* Machine Learning;
* análisis de grafos;
* optimización;
* procesamiento estadístico;
* análisis iterativo.

Imagine un algoritmo que necesita realizar diez iteraciones sobre un mismo conjunto de datos.

Un modelo basado intensivamente en almacenamiento podría comportarse conceptualmente así:

```text
Datos
  │
  ▼
Iteración 1
  │
  ▼
Disco
  │
  ▼
Iteración 2
  │
  ▼
Disco
  │
  ▼
Iteración 3
  │
  ▼
 ...
  │
  ▼
Iteración 10
```

Si cada iteración requiere volver a recuperar información desde almacenamiento, el costo de entrada y salida aumenta.

Spark introduce la posibilidad de **mantener conjuntos de datos reutilizables en memoria** cuando existen recursos suficientes.

```text
             Memoria
                │
        ┌───────┴───────┐
        │               │
        ▼               │
   Iteración 1           │
        │               │
        ▼               │
   Iteración 2           │
        │               │
        ▼               │
   Iteración 3           │
        │               │
        └───────────────┘
```

Esta característica resulta especialmente útil cuando los mismos datos deben utilizarse repetidamente.

---

### 2.4 Procesamiento en memoria no significa eliminar el disco

Una interpretación incorrecta bastante frecuente es afirmar:

> “Spark es rápido porque procesa todo en memoria y no utiliza disco”.

Esta afirmación es demasiado simplificada.

Spark **puede utilizar memoria y disco**.

El comportamiento dependerá de factores como:

* tamaño de los datos;
* memoria disponible;
* tipo de operación;
* configuración utilizada;
* necesidad de reutilizar información;
* operaciones de intercambio de datos entre particiones.

La ventaja de Spark consiste en proporcionar mecanismos que permiten **evitar operaciones innecesarias de lectura y escritura persistente** y reutilizar datos de manera eficiente cuando resulta conveniente.

Por lo tanto:

```text
Spark ≠ solamente memoria
```

Una representación más adecuada sería:

```text
             Apache Spark
                  │
          ┌───────┴───────┐
          │               │
          ▼               ▼
       Memoria           Disco
          │               │
          └───────┬───────┘
                  │
                  ▼
             Procesamiento
```

---

### 2.5 Otro problema: expresar procesos complejos

Spark no intenta resolver únicamente un problema de rendimiento.

También busca proporcionar una forma más flexible de expresar procesos de análisis.

El modelo MapReduce organiza el procesamiento principalmente alrededor de dos operaciones fundamentales:

```text
Map → Shuffle → Reduce
```

Para ciertos problemas esto resulta suficiente.

Sin embargo, un análisis moderno puede requerir una secuencia como:

```text
Leer
  ↓
Filtrar
  ↓
Transformar
  ↓
Agrupar
  ↓
Combinar
  ↓
Ordenar
  ↓
Calcular
  ↓
Guardar
```

Spark permite expresar estas operaciones mediante una secuencia de **transformaciones y acciones**.

Conceptualmente:

```text
Datos
  │
  ▼
Transformación A
  │
  ▼
Transformación B
  │
  ▼
Transformación C
  │
  ▼
Acción
```

Spark analiza esta secuencia antes de ejecutar el procesamiento.

Más adelante veremos que este comportamiento está relacionado con conceptos fundamentales como:

* evaluación perezosa (*lazy evaluation*);
* DAG (*Directed Acyclic Graph*);
* Jobs;
* Stages;
* Tasks.

---

### 2.6 Procesamiento interactivo

Otro escenario importante corresponde al **análisis interactivo**.

Imagine que un analista está explorando un conjunto de datos.

Primero quiere conocer la cantidad de registros.

Después desea filtrar una ciudad.

Luego quiere agrupar los datos por categoría.

Finalmente decide calcular el promedio de una variable.

```text
Datos
  │
  ├── ¿Cuántos registros existen?
  │
  ├── ¿Cuántos corresponden a Santiago?
  │
  ├── ¿Cómo se distribuyen por categoría?
  │
  └── ¿Cuál es el promedio?
```

En este escenario el usuario realiza diferentes operaciones sucesivas sobre los mismos datos.

La capacidad de mantener información disponible para reutilizarla puede facilitar este tipo de análisis.

Spark fue diseñado para soportar tanto procesos batch como cargas de trabajo más interactivas e iterativas.

---

### 2.7 Un motor de propósito general

Otra característica importante es que Spark fue concebido como un motor de procesamiento de **propósito general**.

Esto significa que una misma plataforma puede utilizarse para diferentes tipos de problemas.

```text
                    Apache Spark
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       Batch        Consultas        Streaming
                         │
             ┌───────────┴───────────┐
             ▼                       ▼
       Machine Learning          Otros análisis
```

Esta integración reduce la necesidad de utilizar un motor completamente diferente para cada tipo de procesamiento.

No significa que Spark sea siempre la mejor herramienta para cualquier problema, sino que proporciona un conjunto amplio de capacidades bajo un mismo modelo de ejecución.

---

### 2.8 Spark no distribuye automáticamente cualquier programa

También debemos evitar otra interpretación equivocada.

Utilizar Spark no significa que cualquier programa escrito en Scala o Python se convierta automáticamente en un programa distribuido.

Por ejemplo:

```text
Programa Python
      ≠
Procesamiento distribuido
```

o:

```text
Programa Scala
      ≠
Procesamiento distribuido
```

Para utilizar procesamiento distribuido debemos trabajar con las **abstracciones y operaciones proporcionadas por Spark**.

Conceptualmente:

```text
Código Scala / Python
          │
          ▼
      API de Spark
          │
          ▼
    Motor de Spark
          │
          ▼
Procesamiento distribuido
```

Este punto será especialmente importante en nuestro curso, porque utilizaremos tanto Scala como PySpark.

El lenguaje permite expresar las instrucciones, pero es **Spark quien organiza y coordina su ejecución distribuida**.

---

### 2.9 ¿Spark siempre será más rápido?

Tampoco es correcto concluir que:

> “Spark siempre es más rápido que MapReduce”.

El rendimiento depende de múltiples factores:

* volumen de datos;
* tipo de algoritmo;
* número de nodos;
* cantidad de memoria;
* número y tamaño de particiones;
* movimiento de datos entre nodos;
* almacenamiento utilizado;
* configuración del clúster;
* características de la aplicación.

Spark presenta ventajas importantes en determinados escenarios, especialmente cuando existen **múltiples transformaciones, reutilización de datos o procesamiento iterativo**.

Sin embargo, el objetivo principal de estudiar Spark no consiste simplemente en afirmar que una tecnología es “más rápida” que otra.

Lo relevante es comprender **qué modelo de procesamiento utiliza y por qué puede resultar más apropiado para determinados problemas**.

---

### 2.10 El cambio fundamental

Podemos resumir el problema que Spark intenta abordar mediante la siguiente comparación conceptual:

```text
Procesamiento tradicional basado en etapas

Datos
  ↓
Proceso
  ↓
Almacenamiento
  ↓
Proceso
  ↓
Almacenamiento
  ↓
Proceso
  ↓
Resultado
```

Spark permite construir un flujo de procesamiento más integrado:

```text
Datos
  │
  ▼
┌─────────────────────────────┐
│        Apache Spark         │
│                             │
│ Transformar                 │
│      ↓                      │
│ Filtrar                     │
│      ↓                      │
│ Agrupar                     │
│      ↓                      │
│ Calcular                    │
│      ↓                      │
│ Ejecutar                    │
└─────────────────────────────┘
              │
              ▼
          Resultado
```

Para conseguirlo, Spark necesita coordinar diferentes computadores, distribuir los datos, organizar las operaciones y decidir cómo ejecutar cada parte del trabajo.

Precisamente por ello, el siguiente paso consiste en estudiar su **arquitectura interna**.

---

## Idea fundamental del apartado

Apache Spark intenta proporcionar un modelo flexible y eficiente para construir procesos distribuidos, especialmente cuando existen múltiples transformaciones, reutilización de datos o procesamiento iterativo.

No debemos reducir su funcionamiento a la frase **“Spark trabaja en memoria”**.

La idea más importante es:

> **Spark organiza un conjunto de operaciones como un flujo de procesamiento distribuido y puede reutilizar eficientemente los datos durante su ejecución.**

Para comprender cómo consigue hacerlo, debemos conocer los componentes que participan en una aplicación Spark.

---

## 3. Arquitectura de Apache Spark

Hasta ahora hemos estudiado por qué surge Spark y qué tipo de problemas intenta resolver. El siguiente paso es comprender **cómo organiza internamente el procesamiento distribuido**.

Cuando ejecutamos una aplicación Spark, no existe un único programa realizando todo el trabajo. Diferentes componentes colaboran para coordinar recursos, distribuir tareas y procesar los datos.

Los principales componentes que debemos comprender son:

- **Driver**
- **SparkSession / SparkContext**
- **Cluster Manager**
- **Worker**
- **Executor**

Una representación inicial de la arquitectura es:

```text
                    Aplicación Spark
                           │
                           ▼
                        Driver
                           │
                    SparkContext
                           │
                           ▼
                    Cluster Manager
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
            Worker                    Worker
              │                         │
              ▼                         ▼
           Executor                  Executor
          ┌───┴───┐                 ┌───┴───┐
          ▼       ▼                 ▼       ▼
        Tasks    Tasks             Tasks    Tasks
```

Cada componente cumple una función diferente.

---

### 3.1 La aplicación Spark

Todo comienza con una **aplicación Spark**.

Una aplicación corresponde al programa que queremos ejecutar utilizando el motor Spark.

Este programa puede estar escrito, entre otros lenguajes, en:

* Scala;
* Python;
* Java;
* R.

Por ejemplo, una aplicación podría tener como objetivo:

```text
Leer datos
    ↓
Filtrar ventas
    ↓
Agrupar por ciudad
    ↓
Calcular totales
    ↓
Guardar resultado
```

Sin embargo, estas operaciones no necesariamente son ejecutadas directamente por el computador desde el cual escribimos las instrucciones.

Spark debe determinar **dónde y cómo ejecutar el procesamiento**.

Para ello aparece el primer componente fundamental: el **Driver**.

---

### 3.2 Driver: el coordinador de la aplicación

El **Driver** es el proceso encargado de coordinar una aplicación Spark.

Podemos imaginarlo como el componente que mantiene la visión general del trabajo que debe realizarse.

Entre sus responsabilidades se encuentran:

* ejecutar el programa principal;
* crear el contexto de ejecución de Spark;
* analizar las operaciones solicitadas;
* coordinar la ejecución del trabajo;
* distribuir tareas;
* mantener información sobre el estado de la aplicación;
* recibir resultados cuando corresponde.

Conceptualmente:

```text
                   DRIVER
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
   Programa       Planifica      Coordina
   principal      ejecución      tareas
```

El Driver **coordina**, pero no necesariamente realiza por sí mismo todo el procesamiento de los datos.

El trabajo distribuido será realizado principalmente por los **Executors**.

---

### 3.3 SparkContext y SparkSession

Para comunicarse con Spark, una aplicación necesita un punto de entrada.

Históricamente, uno de los componentes fundamentales ha sido **SparkContext**.

SparkContext representa la conexión de la aplicación con el entorno de ejecución de Spark.

Conceptualmente:

```text
Programa
   │
   ▼
SparkContext
   │
   ▼
Cluster
```

SparkContext permite, entre otras cosas:

* conectarse con el clúster;
* crear estructuras distribuidas;
* solicitar recursos;
* coordinar la ejecución distribuida.

Cuando posteriormente trabajemos con Spark encontraremos frecuentemente una variable denominada:

```text
sc
```

Esta variable normalmente representa el **SparkContext**.

---

Con la evolución de Spark apareció una interfaz de nivel superior denominada **SparkSession**.

SparkSession se convirtió en el principal punto de entrada para trabajar con las APIs estructuradas de Spark.

Conceptualmente:

```text
                 SparkSession
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
     DataFrames    Spark SQL   SparkContext
```

En muchos entornos encontraremos una variable llamada:

```text
spark
```

que representa una SparkSession.

Por lo tanto, durante nuestros ejercicios encontraremos frecuentemente dos objetos:

```text
sc      → SparkContext

spark   → SparkSession
```

No es necesario utilizar comandos todavía. Por ahora, lo importante es comprender **qué representan estos objetos dentro de la arquitectura**.

---

### 3.4 Cluster Manager: el administrador de recursos

Una aplicación Spark necesita recursos computacionales para ejecutar su trabajo.

Por ejemplo:

* CPU;
* memoria;
* computadores disponibles dentro del clúster.

El componente encargado de administrar estos recursos es el **Cluster Manager**.

La relación general es:

```text
Driver
   │
   │ solicita recursos
   ▼
Cluster Manager
   │
   │ asigna recursos
   ▼
Workers
```

Spark puede trabajar con diferentes administradores de clúster.

Entre ellos se encuentran:

* Spark Standalone;
* Hadoop YARN;
* Kubernetes.

En nuestro curso trabajaremos posteriormente con **Spark Standalone**, pero su configuración y utilización práctica serán estudiadas en las guías de ejercicios.

Lo importante en este momento es comprender que:

> El Cluster Manager administra los recursos disponibles para ejecutar las aplicaciones Spark.

---

### 3.5 Worker: el nodo que aporta recursos

Los **Workers** son los nodos del clúster que proporcionan recursos computacionales para ejecutar aplicaciones.

Un Worker puede aportar, por ejemplo:

```text
Worker
  │
  ├── CPU
  │
  └── Memoria
```

El Worker no debe confundirse con el Driver.

Podemos establecer una primera diferencia:

| Componente | Función principal                                |
| ---------- | ------------------------------------------------ |
| Driver     | Coordina la aplicación                           |
| Worker     | Proporciona recursos para ejecutar procesamiento |

Cuando existen varios Workers, Spark puede distribuir el procesamiento entre ellos.

```text
                  Cluster Manager
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
       Worker 1      Worker 2      Worker 3
```

Esto permite aprovechar los recursos de diferentes computadores.

---

### 3.6 Executor: donde se realiza el procesamiento

Dentro de los Workers se ejecutan procesos denominados **Executors**.

Los Executors son responsables de ejecutar las tareas asociadas a una aplicación Spark.

También pueden mantener datos en memoria o disco durante el procesamiento.

Conceptualmente:

```text
Worker
  │
  ▼
Executor
  │
  ├── ejecuta tareas
  ├── procesa datos
  └── puede almacenar datos temporalmente
```

El Driver envía trabajo a los Executors:

```text
                   Driver
                     │
           ┌─────────┴─────────┐
           │                   │
           ▼                   ▼
       Executor 1          Executor 2
           │                   │
       ┌───┴───┐           ┌───┴───┐
       ▼       ▼           ▼       ▼
     Task    Task         Task    Task
```

Esta separación entre coordinación y ejecución es fundamental para comprender Spark.

Podemos resumirla de manera sencilla:

```text
Driver     → coordina

Executor   → ejecuta
```

---

### 3.7 Worker y Executor no son lo mismo

Esta distinción suele producir confusión cuando se comienza a estudiar Spark.

Un **Worker** representa un nodo que aporta recursos al clúster.

Un **Executor**, en cambio, es un proceso que utiliza parte de esos recursos para ejecutar tareas correspondientes a una aplicación.

Por ejemplo:

```text
                 WORKER
        ┌───────────────────────┐
        │                       │
        │      CPU + RAM        │
        │                       │
        │    ┌─────────────┐    │
        │    │  Executor   │    │
        │    │             │    │
        │    │ Task  Task  │    │
        │    └─────────────┘    │
        │                       │
        └───────────────────────┘
```

Por lo tanto:

> **Worker = nodo que aporta recursos.**
> **Executor = proceso que utiliza esos recursos para ejecutar tareas.**

Esta diferencia será observable posteriormente cuando trabajemos con las interfaces de administración de Spark.

---

### 3.8 ¿Qué es una Task?

La **Task** es una unidad concreta de trabajo que Spark envía a un Executor.

Supongamos que tenemos un conjunto de datos dividido en cuatro partes:

```text
Datos
 │
 ├── Parte 1
 ├── Parte 2
 ├── Parte 3
 └── Parte 4
```

Spark puede generar tareas para procesar estas partes:

```text
Parte 1 → Task 1
Parte 2 → Task 2
Parte 3 → Task 3
Parte 4 → Task 4
```

Posteriormente, los Executors realizan esas tareas utilizando los recursos disponibles.

```text
                  Driver
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
      Executor A          Executor B
          │                   │
      ┌───┴───┐           ┌───┴───┐
      ▼       ▼           ▼       ▼
    Task 1  Task 2      Task 3  Task 4
```

Esta idea será fundamental cuando estudiemos las **particiones**.

---

### 3.9 No confundir los componentes de Spark con los de HDFS

Como ya hemos estudiado HDFS, es importante evitar una confusión.

En HDFS trabajamos con conceptos como:

* NameNode;
* DataNode;
* bloques.

En Spark encontraremos:

* Driver;
* Cluster Manager;
* Worker;
* Executor;
* Task.

Son arquitecturas relacionadas dentro de un ecosistema Big Data, pero cumplen funciones diferentes.

```text
           HDFS                         SPARK

        NameNode                       Driver
           │                              │
           ▼                              ▼
        DataNodes                  Cluster Manager
           │                              │
           ▼                              ▼
         Bloques                       Workers
                                          │
                                          ▼
                                      Executors
                                          │
                                          ▼
                                        Tasks
```

HDFS responde principalmente a la pregunta:

> **¿Dónde están almacenados los datos?**

Spark responde principalmente a:

> **¿Cómo distribuimos su procesamiento?**

Ambas arquitecturas pueden trabajar conjuntamente.

---

### 3.10 Una visión completa de la arquitectura

Podemos reunir ahora los conceptos estudiados.

```text
                         APLICACIÓN
                             │
                             ▼
                           DRIVER
                             │
                    SparkSession
                    SparkContext
                             │
                             ▼
                     CLUSTER MANAGER
                             │
               ┌─────────────┴─────────────┐
               │                           │
               ▼                           ▼
            WORKER                      WORKER
               │                           │
               ▼                           ▼
           EXECUTOR                    EXECUTOR
          ┌────┴────┐                 ┌────┴────┐
          ▼         ▼                 ▼         ▼
        TASK      TASK              TASK      TASK
```

El flujo conceptual puede resumirse de la siguiente manera:

```text
1. El usuario inicia una aplicación Spark
                    ↓
2. El Driver coordina la aplicación
                    ↓
3. Se solicitan recursos al Cluster Manager
                    ↓
4. Los Workers proporcionan recursos
                    ↓
5. Los Executors ejecutan las tareas
                    ↓
6. Las Tasks procesan partes de los datos
```

Sin embargo, todavía falta responder una pregunta importante:

**¿Cómo transforma Spark un programa escrito por el usuario en todas esas tareas distribuidas?**

Para comprenderlo debemos estudiar cómo funciona una aplicación Spark dentro del clúster y, posteriormente, cómo aparecen conceptos como **Job, Stage y Task**.

---

## Idea fundamental del apartado

La arquitectura de Spark separa claramente la **coordinación** de la **ejecución distribuida**.

La relación fundamental que debemos recordar es:

```text
Driver
   │
   ▼
Cluster Manager
   │
   ▼
Workers
   │
   ▼
Executors
   │
   ▼
Tasks
```

En términos simples:

> **El Driver coordina la aplicación, el Cluster Manager administra recursos, los Workers aportan esos recursos y los Executors realizan las tareas de procesamiento.**

Esta arquitectura constituye la base para comprender cómo Spark transforma un conjunto de instrucciones en procesamiento distribuido.

---

## 4. Spark en un clúster: de la aplicación a la ejecución distribuida

En el apartado anterior identificamos los principales componentes de la arquitectura de Spark: **Driver, Cluster Manager, Workers, Executors y Tasks**.

Ahora debemos comprender cómo estos componentes colaboran cuando ejecutamos una aplicación.

La pregunta central es:

> **¿Cómo transforma Spark las instrucciones escritas por el usuario en trabajo distribuido dentro de un clúster?**

Para responderla debemos seguir el recorrido de una aplicación desde que comienza hasta que sus tareas son ejecutadas.

---

### 4.1 Todo comienza con una aplicación

Supongamos que queremos analizar un conjunto de datos de ventas.

Nuestro programa podría indicar conceptualmente:

```text
Leer datos de ventas
        ↓
Filtrar ventas válidas
        ↓
Agrupar por ciudad
        ↓
Calcular total vendido
        ↓
Obtener resultado
```

Desde el punto de vista del usuario, observamos una secuencia relativamente sencilla.

Sin embargo, Spark debe transformar estas instrucciones en trabajo que pueda distribuirse entre los recursos disponibles.

```text
Programa del usuario
        │
        ▼
      Spark
        │
        ▼
Plan de ejecución
        │
        ▼
Trabajo distribuido
```

Esta transformación comienza en el **Driver**.

---

### 4.2 El Driver interpreta la aplicación

El Driver ejecuta el programa principal y mantiene la coordinación general de la aplicación.

Cuando encuentra operaciones de Spark, comienza a construir información sobre el procesamiento solicitado.

Por ejemplo:

```text
                    DRIVER
                      │
                      ▼
                Leer datos
                      │
                      ▼
                   Filtrar
                      │
                      ▼
                   Agrupar
                      │
                      ▼
                   Calcular
```

Pero esto no significa que el Driver procese directamente todos los registros.

Su función principal es **organizar y coordinar la ejecución**.

Para ejecutar el procesamiento necesita recursos.

---

### 4.3 Solicitud de recursos

El Driver se comunica con el **Cluster Manager**.

El Cluster Manager conoce los recursos disponibles dentro del clúster.

Por ejemplo:

```text
                    Cluster Manager
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
          Worker 1      Worker 2      Worker 3
          CPU/RAM       CPU/RAM       CPU/RAM
```

El Driver solicita recursos para ejecutar su aplicación.

```text
Driver
   │
   │ Solicitud de recursos
   ▼
Cluster Manager
```

El Cluster Manager determina qué recursos pueden utilizarse.

Dependiendo de la infraestructura, estos recursos podrán encontrarse en uno o varios Workers.

---

### 4.4 Creación de Executors

Una vez asignados los recursos, se utilizan **Executors** para ejecutar el trabajo correspondiente a la aplicación.

Podemos representar el proceso de forma simplificada:

```text
Driver
   │
   ▼
Cluster Manager
   │
   ├───────────────┐
   ▼               ▼
Worker 1         Worker 2
   │               │
   ▼               ▼
Executor         Executor
```

Los Executors permanecen asociados a la aplicación mientras esta se encuentra activa, de acuerdo con el modo de despliegue y configuración utilizados.

El Driver puede enviarles tareas y recibir información sobre su ejecución.

---

### 4.5 Del código a un Job

Existe una diferencia importante entre escribir operaciones y provocar su ejecución.

Supongamos conceptualmente que definimos:

```text
Datos
  ↓
Filtrar
  ↓
Transformar
  ↓
Agrupar
```

Spark puede registrar estas operaciones sin ejecutarlas inmediatamente.

Cuando aparece una operación que necesita producir efectivamente un resultado, Spark debe comenzar la ejecución.

En ese momento puede generarse un **Job**.

Un Job representa un conjunto de trabajo que Spark debe ejecutar para producir el resultado solicitado por una acción.

Conceptualmente:

```text
Transformaciones
       │
       │
       ▼
     Acción
       │
       ▼
      JOB
```

Esta característica está directamente relacionada con la **evaluación perezosa**, que estudiaremos posteriormente con mayor profundidad.

---

### 4.6 Un Job puede dividirse en Stages

Un Job no necesariamente se ejecuta como una única unidad.

Spark analiza las dependencias existentes entre las operaciones y puede dividir el Job en diferentes **Stages**.

```text
JOB
 │
 ├── Stage 1
 │
 ├── Stage 2
 │
 └── Stage 3
```

Un Stage representa un conjunto de operaciones que Spark puede organizar como una etapa de ejecución.

Por ejemplo:

```text
                JOB
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
     Stage 1           Stage 2
        │                 │
        ▼                 ▼
Procesamiento        Procesamiento
```

¿Por qué Spark necesita crear diferentes Stages?

Porque algunas operaciones pueden ejecutarse directamente sobre las particiones existentes, mientras que otras requieren **redistribuir datos entre diferentes particiones o Executors**.

Esta redistribución recibe el nombre de **Shuffle**.

---

### 4.7 El Shuffle

El **Shuffle** es un proceso mediante el cual Spark redistribuye datos para poder realizar determinadas operaciones.

Supongamos que tenemos ventas distribuidas entre varias particiones:

```text
Partición 1
Santiago
Valparaíso
Santiago

Partición 2
Concepción
Santiago
Valparaíso
```

Si queremos calcular:

```text
TOTAL DE VENTAS POR CIUDAD
```

los registros pertenecientes a una misma ciudad pueden encontrarse inicialmente en diferentes particiones.

Spark puede necesitar reorganizarlos:

```text
Datos distribuidos
       │
       ▼
     SHUFFLE
       │
       ├── Santiago
       ├── Valparaíso
       └── Concepción
```

Este movimiento de datos tiene un costo computacional.

Puede implicar:

* transferencia de información;
* utilización de red;
* memoria;
* escritura temporal en disco;
* nuevas etapas de ejecución.

Por esta razón, el Shuffle es un concepto importante cuando posteriormente estudiemos rendimiento y optimización en Spark.

---

### 4.8 De los Stages a las Tasks

Cada Stage se divide finalmente en **Tasks**.

```text
Job
 │
 ├── Stage 1
 │      │
 │      ├── Task 1
 │      ├── Task 2
 │      └── Task 3
 │
 └── Stage 2
        │
        ├── Task 4
        ├── Task 5
        └── Task 6
```

Las Tasks son las unidades concretas de trabajo que los Executors ejecutan.

Aquí aparece una relación fundamental con las **particiones** de los datos.

De manera simplificada, durante un Stage:

> **cada Task procesa una partición.**

Por ejemplo:

```text
Partición 1 ───► Task 1

Partición 2 ───► Task 2

Partición 3 ───► Task 3

Partición 4 ───► Task 4
```

Si existen cuatro particiones, un Stage puede requerir cuatro Tasks para procesarlas.

---

### 4.9 Particiones no significa computadores

Esta distinción es fundamental.

Supongamos que tenemos:

```text
4 particiones
```

Esto **no significa** que necesitemos cuatro computadores.

Podríamos tener:

```text
1 Worker
4 particiones
```

y Spark podría ejecutar las tareas utilizando los recursos disponibles en ese único Worker.

Por ejemplo:

```text
                    WORKER
          ┌─────────────────────┐
          │                     │
          │      EXECUTOR       │
          │                     │
          │ Task 1 → Partición 1│
          │ Task 2 → Partición 2│
          │ Task 3 → Partición 3│
          │ Task 4 → Partición 4│
          │                     │
          └─────────────────────┘
```

Las tareas podrían ejecutarse simultáneamente o por turnos dependiendo de los recursos disponibles.

Por ejemplo, si el Executor puede ejecutar dos tareas simultáneamente:

```text
Tiempo ─────────────────────────────►

Task 1  ███████
Task 2  ███████

Task 3          ███████
Task 4          ███████
```

Por lo tanto:

```text
Partición ≠ Worker
```

y también:

```text
Task ≠ Worker
```

---

### 4.10 Tampoco debemos confundir una partición Spark con un bloque HDFS

Como anteriormente estudiamos HDFS, debemos realizar otra distinción.

HDFS divide archivos en **bloques** para almacenarlos de manera distribuida.

Spark divide el procesamiento en **particiones**.

Son conceptos relacionados cuando Spark lee información desde HDFS, pero no representan exactamente lo mismo.

```text
HDFS                         SPARK

Archivo                      Dataset
  │                             │
  ▼                             ▼
Bloques                     Particiones
  │                             │
  ▼                             ▼
DataNodes                    Tasks
```

Por lo tanto:

```text
Bloque HDFS ≠ Partición Spark
```

Un bloque pertenece al modelo de **almacenamiento distribuido de HDFS**.

Una partición pertenece al modelo de **procesamiento distribuido de Spark**.

Esta diferencia será particularmente importante cuando trabajemos posteriormente con Spark leyendo archivos almacenados en HDFS.

---

### 4.11 La jerarquía de ejecución

Ahora podemos establecer una jerarquía fundamental dentro de Spark:

```text
Aplicación Spark
       │
       ▼
      Job
       │
       ▼
     Stage
       │
       ▼
      Task
       │
       ▼
   Partición
```

Podemos interpretarla así:

| Concepto   | Representa                                                            |
| ---------- | --------------------------------------------------------------------- |
| Aplicación | Programa completo ejecutado mediante Spark                            |
| Job        | Trabajo generado para producir el resultado solicitado por una acción |
| Stage      | Etapa del Job determinada por las dependencias entre operaciones      |
| Task       | Unidad concreta de trabajo enviada a un Executor                      |
| Partición  | Porción lógica de los datos procesada por una Task durante un Stage   |

Esta jerarquía será una de las estructuras conceptuales más importantes durante el estudio de Spark.

---

### 4.12 Ejemplo conceptual completo

Supongamos que tenemos un conjunto de ventas distribuido en cuatro particiones:

```text
                DATOS DE VENTAS
                      │
       ┌──────────────┼──────────────┐
       │              │              │
       ▼              ▼              ▼
  Partición 1    Partición 2    Partición 3
                                      │
                                      ▼
                                 Partición 4
```

Queremos:

1. filtrar ventas superiores a cierto monto;
2. agruparlas por ciudad;
3. calcular el total vendido.

Spark podría organizar conceptualmente la ejecución:

```text
                        JOB
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
           STAGE 1               STAGE 2
              │                     │
      Filtrar registros       Agrupar ciudad
              │                     │
      ┌───────┼───────┐           │
      ▼       ▼       ▼           │
    Task    Task    Task ...      │
              │                     │
              └──── SHUFFLE ────────┘
                                    │
                                    ▼
                                Resultado
```

El usuario solamente escribió las operaciones.

Spark se encargó de determinar cómo transformarlas en trabajo distribuido.

---

### 4.13 Del programa al procesamiento distribuido

Podemos representar finalmente el recorrido completo:

```text
Código Scala / Python
          │
          ▼
        Driver
          │
          ▼
Operaciones de Spark
          │
          ▼
        Acción
          │
          ▼
          Job
          │
          ▼
        Stages
          │
          ▼
         Tasks
          │
          ▼
       Executors
          │
          ▼
      Particiones
          │
          ▼
       Resultado
```

Este proceso constituye una de las principales funciones del motor Spark:

> **transformar operaciones de alto nivel escritas por el usuario en unidades de trabajo que puedan ejecutarse de manera distribuida.**

---

## Idea fundamental del apartado

Una aplicación Spark no se distribuye simplemente porque esté escrita en Scala o Python.

Spark analiza las operaciones solicitadas y organiza su ejecución mediante una jerarquía:

```text
Aplicación
    ↓
   Job
    ↓
  Stage
    ↓
   Task
    ↓
Partición
```

Las Tasks son ejecutadas por Executors utilizando los recursos proporcionados por los Workers.

La relación que debemos conservar es:

> **El usuario define qué procesamiento necesita; Spark determina cómo organizar y distribuir su ejecución.**

En el siguiente apartado estudiaremos la abstracción que permitió originalmente representar y procesar colecciones distribuidas dentro de Spark: los **RDD**.

---

## 5. RDD: la abstracción fundacional de Apache Spark

Hasta ahora hemos estudiado cómo Spark organiza una aplicación y distribuye su ejecución mediante **Jobs, Stages y Tasks**.

Sin embargo, todavía debemos responder una pregunta fundamental:

> **¿Cómo representa Spark un conjunto de datos que debe ser procesado de manera distribuida?**

Una de las respuestas originales de Spark a este problema fue el **RDD**, sigla de:

**Resilient Distributed Dataset**

o, en español:

**Conjunto de Datos Distribuido Resiliente**.

Los RDD constituyen una de las ideas fundamentales sobre las cuales fue construido Apache Spark.

---

### 5.1 ¿Qué es un RDD?

Un RDD es una **colección distribuida de elementos** que puede ser procesada en paralelo por Spark.

Supongamos que tenemos los siguientes datos:

```text
1  2  3  4  5  6  7  8
```

En un programa tradicional podríamos imaginar estos datos almacenados como una única colección dentro de un computador.

Spark, en cambio, puede dividir lógicamente esta colección en diferentes **particiones**:

```text
                RDD
                 │
      ┌──────────┼──────────┐
      │          │          │
      ▼          ▼          ▼
Partición 1  Partición 2  Partición 3

  1 2 3        4 5 6          7 8
```

Estas particiones pueden ser procesadas mediante Tasks.

```text
Partición 1 ───► Task 1

Partición 2 ───► Task 2

Partición 3 ───► Task 3
```

Por lo tanto, la partición constituye una pieza fundamental del procesamiento distribuido.

---

### 5.2 Las tres ideas contenidas en el nombre RDD

El propio nombre permite comprender sus principales características.

```text
R  → Resilient
D  → Distributed
D  → Dataset
```

Analicemos cada concepto.

---

#### Dataset: conjunto de datos

Un RDD representa una colección de elementos.

Estos elementos pueden corresponder, por ejemplo, a:

* números;
* textos;
* registros;
* pares clave-valor;
* objetos.

Conceptualmente:

```text
RDD
 │
 ├── elemento
 ├── elemento
 ├── elemento
 ├── elemento
 └── elemento
```

---

#### Distributed: distribuido

Los datos de un RDD se organizan en **particiones**.

```text
                    RDD
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   Partición 1  Partición 2  Partición 3
```

Gracias a esta división, Spark puede procesar diferentes particiones utilizando los recursos disponibles.

Por ejemplo:

```text
                  RDD
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   Partición 1           Partición 2
        │                     │
        ▼                     ▼
      Task 1                Task 2
        │                     │
        ▼                     ▼
    Executor              Executor
```

Si existen suficientes recursos, algunas de estas tareas pueden ejecutarse en paralelo.

---

#### Resilient: resiliente

La palabra **resiliente** se relaciona con la capacidad de Spark para recuperarse frente a determinadas fallas.

Un RDD mantiene información sobre **cómo fue construido**.

Por ejemplo:

```text
Datos originales
       │
       ▼
    Filtrar
       │
       ▼
  Transformar
       │
       ▼
      RDD
```

Spark conserva información sobre esta secuencia de transformaciones.

Esta información recibe el nombre de:

**Lineage**

o **linaje**.

---

### 5.3 El concepto de Lineage

Supongamos que comenzamos con un conjunto de datos denominado:

```text
RDD_A
```

Luego aplicamos diferentes transformaciones:

```text
RDD_A
  │
  │ filtrar
  ▼
RDD_B
  │
  │ transformar
  ▼
RDD_C
```

Spark conoce la relación existente entre ellos.

Podemos imaginar el lineage como:

```text
RDD_A
  │
  └── filter
         │
         ▼
       RDD_B
         │
         └── map
                │
                ▼
              RDD_C
```

Esta información resulta fundamental para la tolerancia a fallos.

---

### 5.4 ¿Qué ocurre si se pierde una partición?

Supongamos que un RDD contiene cuatro particiones:

```text
RDD
 │
 ├── Partición 1
 ├── Partición 2
 ├── Partición 3
 └── Partición 4
```

Durante la ejecución ocurre una falla y se pierde la Partición 3.

Una alternativa podría consistir en mantener permanentemente múltiples copias de cada resultado intermedio.

Spark puede utilizar otra estrategia: **recalcular la partición perdida utilizando su lineage**, cuando ello sea posible.

Conceptualmente:

```text
Datos originales
       │
       ▼
Transformación A
       │
       ▼
Transformación B
       │
       ├── Partición 1
       ├── Partición 2
       ├── Partición 3  ← perdida
       └── Partición 4
```

Spark conoce las operaciones necesarias para reconstruirla:

```text
Datos originales
       │
       ▼
Transformación A
       │
       ▼
Transformación B
       │
       ▼
Reconstruir Partición 3
```

Esta capacidad contribuye a explicar el término **Resilient**.

---

### 5.5 Un RDD es inmutable

Otra característica fundamental es que los RDD son **inmutables**.

Esto significa que una vez creado un RDD, sus datos no se modifican directamente.

Supongamos que tenemos:

```text
RDD_A
```

y queremos filtrar algunos elementos.

Spark no modifica directamente `RDD_A`.

Conceptualmente crea una nueva representación:

```text
RDD_A
  │
  │ filter
  ▼
RDD_B
```

Si posteriormente realizamos otra transformación:

```text
RDD_A
  │
  │ filter
  ▼
RDD_B
  │
  │ map
  ▼
RDD_C
```

Cada RDD representa una etapa lógica diferente dentro del procesamiento.

---

### 5.6 ¿Por qué es importante la inmutabilidad?

En un sistema distribuido, modificar simultáneamente los mismos datos desde diferentes procesos puede generar problemas de coordinación.

La inmutabilidad simplifica este escenario.

En lugar de modificar una estructura existente:

```text
RDD_A
  │
  ✕ modificar directamente
```

se construye una nueva:

```text
RDD_A
  │
  │ transformación
  ▼
RDD_B
```

Esta característica también facilita mantener el lineage necesario para reconstruir información.

Podemos relacionar ambos conceptos:

```text
Inmutabilidad
     │
     ▼
Nuevos RDD
     │
     ▼
Lineage
     │
     ▼
Posibilidad de recuperación
```

---

### 5.7 Las particiones permiten el paralelismo

Uno de los conceptos más importantes de los RDD es su división en particiones.

Supongamos que tenemos un RDD con cuatro particiones:

```text
                  RDD
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
     P1           P2           P3
                                │
                                ▼
                               P4
```

Durante un Stage, Spark puede crear una Task para procesar cada partición:

```text
P1 → Task 1
P2 → Task 2
P3 → Task 3
P4 → Task 4
```

Ahora imaginemos que existen recursos para ejecutar cuatro Tasks simultáneamente:

```text
Task 1  ██████████
Task 2  ██████████
Task 3  ██████████
Task 4  ██████████
```

Las cuatro particiones podrían procesarse en paralelo.

Pero si solamente existen recursos para ejecutar dos Tasks simultáneamente:

```text
Tiempo ───────────────────────────►

Task 1  ██████████
Task 2  ██████████

Task 3            ██████████
Task 4            ██████████
```

Las particiones siguen siendo cuatro.

Lo que cambia es el nivel de paralelismo disponible.

Por lo tanto:

> **El número de particiones y el número de computadores no tienen que ser iguales.**

---

### 5.8 Partición, Task, Executor y Worker

Ahora podemos relacionar varios conceptos estudiados anteriormente:

```text
                  RDD
                   │
              Particiones
                   │
                   ▼
                 Tasks
                   │
                   ▼
               Executors
                   │
                   ▼
                Workers
```

Sin embargo, debemos interpretar correctamente esta relación.

Una representación más precisa sería:

```text
RDD
 │
 ├── Partición 1 → Task 1 ┐
 ├── Partición 2 → Task 2 ├──► Executor
 ├── Partición 3 → Task 3 ┤
 └── Partición 4 → Task 4 ┘
                              │
                              ▼
                            Worker
```

Un único Executor puede procesar múltiples Tasks.

Un único Worker puede proporcionar recursos para ejecutar estas tareas.

Por ello:

```text
Partición ≠ Task ≠ Executor ≠ Worker
```

Son conceptos relacionados, pero representan elementos diferentes de la arquitectura.

---

### 5.9 RDD y HDFS

Los RDD también permiten comprender mejor cómo Spark puede trabajar con HDFS.

Supongamos que tenemos un archivo almacenado en HDFS:

```text
HDFS
 │
 ▼
ventas.csv
```

Spark puede leer estos datos y construir una representación distribuida para procesarlos.

Conceptualmente:

```text
             HDFS
              │
              ▼
         ventas.csv
              │
              ▼
            Spark
              │
              ▼
             RDD
              │
      ┌───────┼───────┐
      ▼       ▼       ▼
     P1      P2      P3
```

A partir de ese momento, Spark puede ejecutar transformaciones distribuidas sobre las diferentes particiones.

Este punto será especialmente importante en las guías prácticas, donde volveremos a trabajar con datos que ya conocemos de nuestros ejercicios anteriores.

---

### 5.10 Un RDD no es lo mismo que un archivo

También debemos evitar pensar que un RDD corresponde simplemente a un archivo almacenado en memoria.

Un RDD es una **abstracción de procesamiento distribuido**.

Puede originarse desde diferentes fuentes.

Por ejemplo:

```text
Colección local ──────┐
                      │
Archivo HDFS ─────────┼──► RDD
                      │
Otros datos ──────────┘
```

Además, un RDD puede originarse a partir de otro RDD:

```text
RDD_A
  │
  │ transformación
  ▼
RDD_B
  │
  │ transformación
  ▼
RDD_C
```

Por ello, un RDD no debe entenderse solamente como “datos almacenados”, sino también como una representación de **cómo obtener y procesar esos datos de manera distribuida**.

---

### 5.11 RDD y procesamiento en memoria

En los apartados anteriores señalamos que Spark puede reutilizar datos durante el procesamiento.

Los RDD desempeñaron un papel fundamental en este modelo.

Spark permite indicar que determinados datos deben conservarse para reutilizarlos posteriormente.

Conceptualmente:

```text
Datos
  │
  ▼
RDD
  │
  ├── Proceso A
  │
  ├── Proceso B
  │
  └── Proceso C
```

Si el mismo RDD será utilizado repetidamente, Spark puede mantener sus particiones utilizando mecanismos de persistencia.

```text
             RDD
              │
        ┌─────┴─────┐
        │  CACHE /  │
        │ PERSIST   │
        └─────┬─────┘
              │
      ┌───────┼───────┐
      ▼       ▼       ▼
  Proceso A Proceso B Proceso C
```

Esto puede evitar recalcular continuamente la misma información.

Sin embargo, nuevamente debemos evitar una simplificación:

> Un RDD no significa automáticamente que todos sus datos estén almacenados permanentemente en memoria.

La persistencia debe entenderse como una capacidad que Spark puede utilizar según las operaciones y configuración de la aplicación.

---

### 5.12 ¿Siguen siendo importantes los RDD?

Spark ha evolucionado considerablemente desde sus primeras versiones.

Actualmente existen abstracciones de mayor nivel, especialmente:

* DataFrames;
* Datasets;
* Spark SQL.

En muchas aplicaciones modernas estas APIs estructuradas son preferidas porque permiten a Spark realizar optimizaciones adicionales.

Podemos observar esta evolución:

```text
Primeras APIs de Spark
        │
        ▼
       RDD
        │
        ▼
   DataFrames
        │
        ▼
 APIs estructuradas
```

Sin embargo, estudiar los RDD continúa siendo importante porque permiten comprender conceptos fundamentales de Spark:

* particiones;
* procesamiento distribuido;
* transformaciones;
* acciones;
* lineage;
* tolerancia a fallos;
* evaluación perezosa;
* paralelismo.

Por esta razón, en nuestro curso comenzaremos trabajando con RDD antes de avanzar hacia DataFrames y Spark SQL.

---

### 5.13 El modelo mental que debemos conservar

Podemos resumir un RDD mediante cuatro características principales:

```text
                     RDD
                      │
       ┌──────────────┼──────────────┐
       │              │              │
       ▼              ▼              ▼
   Distribuido     Inmutable     Resiliente
       │              │              │
       ▼              ▼              ▼
  Particiones     Nuevos RDD       Lineage
       │                             │
       ▼                             ▼
  Paralelismo                  Recuperación
```

Estas características permiten que Spark represente y procese grandes colecciones de datos utilizando recursos distribuidos.

---

## Idea fundamental del apartado

Un **RDD (Resilient Distributed Dataset)** es una colección distribuida e inmutable, organizada en particiones y capaz de mantener información sobre las transformaciones que permitieron construirla.

Las cuatro ideas que debemos recordar son:

```text
RDD
 │
 ├── Distribuido → se divide en particiones
 │
 ├── Inmutable   → las transformaciones generan nuevos RDD
 │
 ├── Resiliente  → puede reconstruir información mediante lineage
 │
 └── Paralelo    → sus particiones pueden procesarse mediante Tasks
```

Sin embargo, hasta ahora hemos mencionado repetidamente que un RDD puede ser **transformado** y que algunas operaciones provocan finalmente su **ejecución**.

Esta diferencia es esencial para comprender el funcionamiento de Spark.

---

## 6. Transformaciones, acciones y evaluación perezosa

En el apartado anterior estudiamos los **RDD** como colecciones distribuidas organizadas en particiones.

También observamos que un RDD puede dar origen a nuevos RDD mediante diferentes operaciones.

Ahora debemos comprender una característica fundamental del modelo de programación de Spark:

> **No todas las operaciones producen una ejecución inmediata.**

Spark distingue principalmente entre dos tipos de operaciones:

- **Transformaciones**
- **Acciones**

Esta diferencia permite comprender uno de los mecanismos más importantes de Spark: la **evaluación perezosa** (*lazy evaluation*).

---

### 6.1 Dos tipos fundamentales de operaciones

Supongamos que tenemos un RDD con datos de ventas.

Queremos:

1. seleccionar determinadas ventas;
2. transformar algunos valores;
3. agrupar información;
4. obtener un resultado.

Conceptualmente:

```text
RDD original
     │
     ▼
   Filtrar
     │
     ▼
 Transformar
     │
     ▼
   Agrupar
     │
     ▼
  Resultado
```

Aunque para nosotros todas parecen operaciones similares, Spark distingue aquellas que **construyen una nueva representación de los datos** de aquellas que **solicitan obtener efectivamente un resultado**.

```text
              Operaciones Spark
                     │
             ┌───────┴───────┐
             │               │
             ▼               ▼
      Transformaciones     Acciones
             │               │
             ▼               ▼
       Nuevos RDD       Resultado /
                        ejecución
```

Esta diferencia es fundamental.

---

### 6.2 ¿Qué es una transformación?

Una **transformación** es una operación que toma un RDD y produce lógicamente un nuevo RDD.

Por ejemplo:

```text
RDD_A
  │
  │ transformación
  ▼
RDD_B
```

Algunas transformaciones habituales son:

* `map`
* `filter`
* `flatMap`
* `distinct`
* `union`
* `reduceByKey`

No necesitamos conocer todavía su sintaxis. Lo importante es comprender qué tipo de operación representan.

Por ejemplo, `filter` permite seleccionar elementos que cumplen una condición:

```text
RDD original

10  25  40  12  80
          │
          │ filter: valores > 20
          ▼
Nuevo RDD

25  40  80
```

De manera similar, `map` permite aplicar una operación a cada elemento:

```text
RDD original

1  2  3  4
    │
    │ map: multiplicar por 10
    ▼
Nuevo RDD

10  20  30  40
```

Debemos recordar que los RDD son inmutables.

Por ello, una transformación no modifica directamente el RDD original:

```text
RDD_A
  │
  │ map
  ▼
RDD_B
```

`RDD_A` continúa existiendo conceptualmente y `RDD_B` representa una nueva transformación.

---

### 6.3 Encadenamiento de transformaciones

Una de las características más útiles de Spark es la posibilidad de construir secuencias de transformaciones.

Por ejemplo:

```text
RDD_A
  │
  │ filter
  ▼
RDD_B
  │
  │ map
  ▼
RDD_C
  │
  │ distinct
  ▼
RDD_D
```

Podemos imaginar este proceso como una receta:

```text
Datos originales
      ↓
Conservar registros válidos
      ↓
Transformar información
      ↓
Eliminar duplicados
      ↓
Datos preparados
```

Sin embargo, existe una característica sorprendente:

> **Spark normalmente no ejecuta inmediatamente estas transformaciones cuando son definidas.**

Aquí aparece el concepto de evaluación perezosa.

---

### 6.4 ¿Qué significa evaluación perezosa?

La **evaluación perezosa** (*lazy evaluation*) significa que Spark puede registrar las transformaciones solicitadas sin ejecutarlas inmediatamente.

Supongamos que definimos:

```text
RDD_A
  │
  │ filter
  ▼
RDD_B
  │
  │ map
  ▼
RDD_C
```

Una interpretación intuitiva podría ser:

```text
Ejecutar filter
      ↓
terminar
      ↓
Ejecutar map
      ↓
terminar
```

Pero Spark puede comportarse conceptualmente de otra manera:

```text
filter
   │
   ▼
registrar operación

map
   │
   ▼
registrar operación
```

Spark conoce las transformaciones que deben realizarse, pero puede **posponer su ejecución** hasta que realmente sea necesario obtener un resultado.

---

### 6.5 ¿Por qué Spark espera?

Esta estrategia permite que Spark observe una cadena completa de operaciones antes de ejecutarla.

Imagine que solicitamos:

```text
Datos
  ↓
filter
  ↓
map
  ↓
filter
  ↓
map
  ↓
resultado
```

Si Spark ejecutara inmediatamente cada instrucción de manera independiente, tendría menos posibilidades de organizar eficientemente el trabajo.

Al disponer de información sobre el flujo de operaciones, puede construir un **plan de ejecución**.

```text
Transformaciones solicitadas
           │
           ▼
      Spark analiza
           │
           ▼
   Plan de ejecución
           │
           ▼
Procesamiento distribuido
```

Esta característica es una de las razones por las cuales la evaluación perezosa es tan importante dentro de Spark.

---

### 6.6 ¿Qué provoca entonces la ejecución?

Para que Spark comience efectivamente a realizar el procesamiento necesitamos una operación que solicite un resultado.

Estas operaciones se denominan **acciones**.

Algunas acciones habituales son:

* `count`
* `collect`
* `take`
* `first`
* `reduce`
* `saveAsTextFile`

Por ejemplo:

```text
RDD_A
  │
  │ filter
  ▼
RDD_B
  │
  │ map
  ▼
RDD_C
  │
  │ count
  ▼
Resultado
```

Las primeras operaciones son transformaciones.

`count`, en cambio, necesita conocer cuántos elementos contiene el resultado.

Para responder, Spark debe realizar el procesamiento necesario.

---

### 6.7 Transformaciones frente a acciones

Podemos establecer la siguiente diferencia:

| Transformación                            | Acción                                                |
| ----------------------------------------- | ----------------------------------------------------- |
| Produce lógicamente un nuevo RDD          | Solicita un resultado o efecto                        |
| Generalmente se evalúa de manera perezosa | Puede desencadenar la ejecución                       |
| Forma parte del lineage                   | Provoca que Spark procese las dependencias necesarias |
| Ejemplos: `map`, `filter`, `flatMap`      | Ejemplos: `count`, `collect`, `reduce`                |

Una representación sencilla sería:

```text
Transformación
     │
     ▼
"Define qué hacer"

Acción
     │
     ▼
"Necesito el resultado"
```

---

### 6.8 Ejemplo conceptual

Supongamos que tenemos:

```text
ventas
```

y queremos seleccionar solamente aquellas superiores a $100.000.

Primero definimos una transformación:

```text
ventas
   │
   │ filter
   ▼
ventas_altas
```

En este momento Spark conoce la transformación.

Pero todavía puede no haber procesado todas las ventas.

Luego solicitamos:

```text
¿Cuántas ventas altas existen?
```

Esto puede representarse mediante una acción:

```text
ventas
   │
   │ filter
   ▼
ventas_altas
   │
   │ count
   ▼
Resultado
```

Ahora Spark necesita producir una respuesta.

Por ello comienza la ejecución.

---

### 6.9 De una acción a un Job

En el apartado anterior estudiamos el concepto de **Job**.

Ahora podemos comprender mejor cuándo aparece.

Conceptualmente:

```text
Transformación
      │
      ▼
Transformación
      │
      ▼
Transformación
      │
      ▼
    Acción
      │
      ▼
     JOB
```

Una acción puede provocar que Spark genere un Job para calcular el resultado requerido.

Ese Job podrá posteriormente dividirse en:

```text
Job
 │
 ├── Stage
 │     ├── Task
 │     └── Task
 │
 └── Stage
       ├── Task
       └── Task
```

Ahora comienzan a conectarse los diferentes conceptos estudiados.

---

### 6.10 El DAG: Directed Acyclic Graph

Para representar las dependencias existentes entre las operaciones, Spark utiliza estructuras que pueden entenderse como un **grafo dirigido acíclico**, conocido por sus siglas:

**DAG — Directed Acyclic Graph**

Un DAG representa las relaciones existentes entre diferentes operaciones.

Por ejemplo:

```text
      RDD_A
        │
        ▼
      filter
        │
        ▼
      RDD_B
        │
        ▼
       map
        │
        ▼
      RDD_C
        │
        ▼
      count
```

Podemos interpretarlo como un mapa de dependencias:

```text
RDD_C depende de RDD_B
RDD_B depende de RDD_A
```

Esta información permite a Spark comprender qué operaciones deben realizarse para obtener un determinado resultado.

---

### 6.11 ¿Por qué "acíclico"?

La palabra **acíclico** significa que el grafo no contiene ciclos que hagan volver una dependencia sobre sí misma.

Conceptualmente, esto sería una dependencia válida:

```text
A → B → C → D
```

Mientras que una estructura como:

```text
A → B → C
↑       │
└───────┘
```

contendría un ciclo.

Las dependencias que Spark construye para representar el procesamiento forman un flujo dirigido hacia los resultados que deben calcularse.

---

### 6.12 El DAG y el Lineage están relacionados

Anteriormente estudiamos el concepto de **lineage**.

El lineage permite conocer cómo un RDD fue construido a partir de otros RDD.

Por ejemplo:

```text
RDD_A
  │
  ▼
RDD_B
  │
  ▼
RDD_C
```

El DAG representa las dependencias y operaciones involucradas en el procesamiento.

Ambos conceptos están estrechamente relacionados.

Podemos pensarlo así:

```text
Transformaciones
      │
      ▼
Dependencias entre RDD
      │
      ▼
Lineage / DAG
      │
      ▼
Planificación de ejecución
```

Además de contribuir a la planificación, estas dependencias permiten reconstruir determinadas particiones cuando ocurre una falla.

---

### 6.13 Transformaciones estrechas y amplias

No todas las transformaciones tienen el mismo costo.

Una distinción conceptual importante es entre:

* **transformaciones estrechas** (*narrow transformations*);
* **transformaciones amplias** (*wide transformations*).

En una transformación estrecha, una partición de salida depende de un número reducido de particiones de entrada.

Por ejemplo:

```text
Partición 1 ──► filter ──► Partición 1

Partición 2 ──► filter ──► Partición 2

Partición 3 ──► filter ──► Partición 3
```

Operaciones como `map` y `filter` suelen presentar este comportamiento.

---

En una transformación amplia, los datos pueden necesitar redistribuirse entre particiones.

Por ejemplo:

```text 
P1 ─────┬────────► P1'
        │
P2 ─────┼────────► P2'
        │
P3 ─────┴────────► P3'
```

Esto puede producir un **Shuffle**.

Un ejemplo habitual aparece al agrupar datos por una clave.

```text
Datos distribuidos
       │
       ▼
   Agrupar por ciudad
       │
       ▼
     Shuffle
       │
       ▼
Datos reorganizados
```

El Shuffle puede provocar la separación del procesamiento en diferentes Stages.

---

### 6.14 Ahora podemos conectar todos los conceptos

Supongamos que tenemos:

```text
RDD
 │
 │ filter
 ▼
RDD
 │
 │ map
 ▼
RDD
 │
 │ reduceByKey
 ▼
RDD
 │
 │ collect
 ▼
Resultado
```

Spark puede analizar las dependencias:

```text
filter
  │
  ▼
 map
  │
  ▼
reduceByKey
  │
  ▼
collect
```

La operación `reduceByKey` puede requerir un Shuffle.

Por lo tanto, conceptualmente podríamos obtener:

```text
                 JOB
                  │
         ┌────────┴────────┐
         │                 │
         ▼                 ▼
      Stage 1           Stage 2
         │                 │
      filter           reduceByKey
         │                 │
        map                │
         │                 │
         └─── SHUFFLE ─────┘
```

Y cada Stage tendrá sus correspondientes Tasks:

```text
Stage
 │
 ├── Task → Partición 1
 ├── Task → Partición 2
 ├── Task → Partición 3
 └── Task → Partición 4
```

De esta forma se conectan:

```text
Transformaciones
      ↓
Lazy Evaluation
      ↓
Acción
      ↓
Job
      ↓
DAG
      ↓
Stages
      ↓
Tasks
      ↓
Particiones
```

Este es uno de los modelos mentales más importantes para comprender Apache Spark.

---

### 6.15 Cuidado con `collect`

Existe una acción que merece especial atención: `collect`.

Esta operación recupera los elementos del conjunto distribuido y los envía al **Driver**.

Conceptualmente:

```text
Executor 1 ──┐
             │
Executor 2 ──┼──► Driver
             │
Executor 3 ──┘
```

Esto puede resultar útil cuando trabajamos con conjuntos pequeños.

Sin embargo, si intentáramos recuperar un volumen de datos muy grande:

```text
Muchos datos distribuidos
          │
          ▼
       collect
          │
          ▼
        Driver
```

podríamos consumir una cantidad excesiva de memoria en el Driver.

Por esta razón, en procesamiento distribuido no basta con que una instrucción sea técnicamente válida.

También debemos preguntarnos:

> **¿Dónde se ejecuta la operación y dónde terminarán los datos?**

Esta pregunta será recurrente durante nuestros ejercicios con Spark.

---

### 6.16 El modelo mental que debemos conservar

Cuando trabajemos posteriormente con Scala y PySpark veremos instrucciones concretas.

Sin embargo, detrás de ellas continuará ocurriendo el mismo proceso:

```text
Código del estudiante
        │
        ▼
Transformaciones
        │
        ▼
Spark registra dependencias
        │
        ▼
     Acción
        │
        ▼
Spark planifica ejecución
        │
        ▼
Job → Stages → Tasks
        │
        ▼
     Executors
        │
        ▼
      Resultado
```

Por ello, comprender transformaciones y acciones es más importante que memorizar instrucciones individuales.

---

## Idea fundamental del apartado

Spark utiliza **evaluación perezosa** para construir un plan de procesamiento antes de ejecutar las operaciones necesarias.

La relación fundamental es:

```text
Transformación
      ↓
Transformación
      ↓
Transformación
      ↓
    Acción
      ↓
   Ejecución
```

Las transformaciones describen **qué queremos hacer** con los datos.

Las acciones hacen que Spark necesite **producir un resultado**, desencadenando el procesamiento correspondiente.

Finalmente, Spark utiliza las dependencias entre operaciones para organizar la ejecución mediante:

```text
DAG
 ↓
Job
 ↓
Stages
 ↓
Tasks
```

En el siguiente apartado avanzaremos desde los RDD hacia las abstracciones estructuradas que actualmente ocupan un lugar central en Spark: **DataFrames, Datasets y Spark SQL**.

---

## 7. DataFrames, Datasets y Spark SQL

Los RDD fueron la abstracción fundamental sobre la cual se construyeron las primeras versiones de Apache Spark.

Sin embargo, trabajar directamente con RDD implica que Spark dispone de información limitada sobre la **estructura y el significado de los datos**.

Con la evolución de Spark surgieron abstracciones de mayor nivel que permiten trabajar con información estructurada de una forma más cercana a una tabla.

Las principales son:

- **DataFrame**
- **Dataset**
- **Spark SQL**

Estas abstracciones no eliminan los principios de procesamiento distribuido estudiados anteriormente. Por el contrario, los utilizan internamente y permiten que Spark disponga de mayor información para organizar y optimizar la ejecución.

---

### 7.1 Del RDD al DataFrame

Supongamos que tenemos información de ventas.

Mediante un RDD podríamos representar registros como:

```text
(1, "Santiago", "Tecnología", 150000)
(2, "Valparaíso", "Hogar", 85000)
(3, "Santiago", "Hogar", 120000)
```

Para Spark, estos elementos pueden ser simplemente objetos distribuidos.

Conceptualmente:

```text
RDD
 │
 ├── elemento
 ├── elemento
 └── elemento
```

Sin embargo, nosotros sabemos que cada posición tiene un significado:

```text
1             → id_venta
"Santiago"    → ciudad
"Tecnología"  → categoria
150000        → monto
```

Un **DataFrame** permite representar explícitamente esta estructura.

```text
+----------+------------+------------+--------+
| id_venta | ciudad     | categoria  | monto  |
+----------+------------+------------+--------+
| 1        | Santiago   | Tecnología | 150000 |
| 2        | Valparaíso | Hogar      |  85000 |
| 3        | Santiago   | Hogar      | 120000 |
+----------+------------+------------+--------+
```

Ahora Spark no solamente dispone de los datos.

También conoce su **estructura**.

---

### 7.2 ¿Qué es un DataFrame?

Un DataFrame es una colección distribuida de datos organizada en **columnas con nombres y tipos definidos mediante un esquema**.

Conceptualmente:

```text
                 DataFrame
                     │
          ┌──────────┼──────────┐
          │          │          │
          ▼          ▼          ▼
       Columnas     Tipos      Filas
          │
          ▼
        Schema
```

Por ejemplo:

```text
id_venta   → Integer
ciudad     → String
categoria  → String
monto      → Double
```

Esta información constituye el **schema** o esquema del DataFrame.

Podemos imaginarlo como:

```text
ventas
 │
 ├── id_venta   : Integer
 ├── ciudad     : String
 ├── categoria  : String
 └── monto      : Double
```

Esta estructura resulta familiar porque se aproxima al modelo tabular que ya conocemos de las bases de datos y de Hive.

---

### 7.3 Datos distribuidos aunque parezcan una tabla

La apariencia tabular de un DataFrame puede llevarnos a pensar que todos los datos se encuentran almacenados en un único lugar.

Esto no es necesariamente así.

Un DataFrame continúa siendo una estructura **distribuida**.

```text
                    DataFrame
                        │
                ventas_hive
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
     Partición 1   Partición 2   Partición 3
```

Por lo tanto, seguimos trabajando con conceptos ya estudiados:

```text
DataFrame
    ↓
Particiones
    ↓
Tasks
    ↓
Executors
```

La diferencia principal es que ahora Spark conoce además la estructura de los datos.

---

### 7.4 RDD y DataFrame

Podemos establecer una primera comparación conceptual:

| RDD                                         | DataFrame                                       |
| ------------------------------------------- | ----------------------------------------------- |
| Colección distribuida de objetos            | Datos distribuidos organizados en columnas      |
| Estructura menos explícita para el motor    | Posee un esquema conocido                       |
| API de menor nivel                          | API de mayor nivel                              |
| Mayor control sobre operaciones específicas | Facilita operaciones estructuradas              |
| Fundamental para comprender Spark           | Muy utilizado en procesamiento moderno de datos |

No debemos interpretar esta comparación como:

```text
RDD malo
DataFrame bueno
```

Ambos tienen propósitos diferentes.

En nuestro curso utilizaremos inicialmente RDD porque permiten observar con claridad conceptos como:

* particiones;
* transformaciones;
* acciones;
* paralelismo;
* lineage.

Posteriormente utilizaremos DataFrames para trabajar con datos estructurados.

---

### 7.5 El esquema permite optimizar

La existencia de un esquema proporciona información adicional a Spark.

Supongamos que tenemos:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

y solamente queremos analizar:

```text
ciudad
monto
```

Al conocer la estructura de los datos, Spark puede analizar qué columnas y operaciones son necesarias para responder a una consulta.

Conceptualmente:

```text
Consulta del usuario
        │
        ▼
Spark conoce el schema
        │
        ▼
Analiza las operaciones
        │
        ▼
Optimiza el plan
        │
        ▼
Ejecuta
```

Esta capacidad es una diferencia importante respecto de trabajar exclusivamente con colecciones de objetos sin información estructural adicional.

---

### 7.6 Catalyst Optimizer

Spark SQL incorpora un componente denominado **Catalyst Optimizer**.

Su función es analizar y optimizar consultas y operaciones estructuradas antes de su ejecución.

De manera simplificada:

```text
Operación solicitada
        │
        ▼
   Plan lógico
        │
        ▼
     Catalyst
        │
        ▼
Plan optimizado
        │
        ▼
 Plan físico
        │
        ▼
   Ejecución
```

Esto significa que el usuario puede expresar **qué resultado necesita**, mientras Spark analiza diferentes aspectos de cómo ejecutar las operaciones.

Esta idea se aproxima al funcionamiento de los motores de bases de datos.

---

### 7.7 Spark SQL

Una consecuencia natural de trabajar con datos estructurados es la posibilidad de utilizar **SQL**.

Spark SQL es el módulo de Spark orientado al procesamiento de datos estructurados.

Por ejemplo, conceptualmente podríamos realizar una consulta como:

```sql
SELECT ciudad, SUM(monto)
FROM ventas
GROUP BY ciudad;
```

Spark puede transformar esta consulta en un plan de procesamiento distribuido.

```text
SQL
 │
 ▼
Spark SQL
 │
 ▼
Plan de ejecución
 │
 ▼
Stages
 │
 ▼
Tasks
 │
 ▼
Executors
```

Por lo tanto, escribir SQL no significa abandonar el procesamiento distribuido.

Spark continúa realizando internamente el trabajo necesario para ejecutar la consulta utilizando los recursos del clúster.

---

### 7.8 Dos formas de expresar una operación similar

Una característica interesante de Spark es que podemos trabajar con datos estructurados utilizando diferentes interfaces.

Por ejemplo, conceptualmente podríamos indicar:

```text
DataFrame API

ventas
   ↓
agrupar por ciudad
   ↓
sumar monto
```

o utilizar SQL:

```sql
SELECT ciudad, SUM(monto)
FROM ventas
GROUP BY ciudad;
```

Ambas expresiones pueden terminar siendo procesadas por el motor de Spark SQL.

Conceptualmente:

```text
DataFrame API ──────┐
                    │
                    ▼
                Spark SQL
                    │
                    ▼
              Optimización
                    │
                    ▼
                 Ejecución
                    ▲
                    │
SQL ────────────────┘
```

Esto proporciona flexibilidad al usuario.

---

### 7.9 La relación con Hive

Aquí aparece una conexión especialmente importante con lo que ya hemos estudiado.

En Hive trabajamos con una estructura como:

```text
              HDFS
                │
                ▼
             Datos
                ▲
                │
              Hive
                │
                ▼
        Tablas + Metadatos
                │
                ▼
             HiveQL
```

Spark también puede trabajar con datos almacenados en sistemas como HDFS y puede integrarse con información estructurada del ecosistema Hive cuando el entorno está configurado para ello.

Conceptualmente:

```text
                    HDFS
                      │
                      ▼
                    Datos
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
         Hive                  Spark
           │                     │
           ▼                     ▼
        HiveQL              DataFrames
                                 │
                                 ▼
                             Spark SQL
```

Esto demuestra nuevamente que Spark no necesariamente reemplaza las tecnologías anteriores.

Puede **integrarse con ellas**.

---

### 7.10 Un mismo conjunto de datos, diferentes herramientas

Durante nuestros ejercicios anteriores hemos trabajado con datos de ventas almacenados en HDFS.

Conceptualmente:

```text
ventas_hive.csv
       │
       ▼
      HDFS
       │
       ▼
      Hive
       │
       ▼
     HiveQL
```

Posteriormente podremos utilizar Spark sobre esos mismos datos:

```text
ventas_hive.csv
       │
       ▼
      HDFS
       │
       ▼
     Spark
       │
       ▼
   DataFrame
       │
       ▼
   Spark SQL
```

El conjunto de datos puede ser el mismo.

Lo que cambia es el motor y la forma en que realizamos el procesamiento.

Esta continuidad será importante en las actividades prácticas del curso.

---

### 7.11 ¿Qué es un Dataset?

Spark también proporciona una abstracción denominada **Dataset**.

Un Dataset combina características de los RDD con las optimizaciones de las APIs estructuradas.

Conceptualmente:

```text
                   Dataset
                      │
          ┌───────────┴───────────┐
          │                       │
          ▼                       ▼
      Tipado fuerte        Optimización SQL
```

Los Datasets tienen especial relevancia en lenguajes como **Scala y Java**, donde pueden aprovechar información de tipos en tiempo de compilación.

Podemos representar conceptualmente la relación:

```text
RDD
 │
 │ evolución hacia APIs estructuradas
 ▼
Dataset
 │
 ▼
DataFrame
```

En Spark, un DataFrame puede entenderse conceptualmente como un Dataset de filas estructuradas.

---

### 7.12 ¿Por qué en PySpark hablamos principalmente de DataFrames?

Cuando trabajemos con Python utilizaremos principalmente la API de **DataFrames**.

La API tipada de Dataset está asociada principalmente a Scala y Java.

Por esta razón, en nuestros ejercicios encontraremos una diferencia práctica:

```text
Scala
 │
 ├── RDD
 ├── DataFrame
 └── Dataset

Python / PySpark
 │
 ├── RDD
 └── DataFrame
```

Esto no significa que PySpark tenga capacidades inferiores para el análisis estructurado.

Los DataFrames constituyen precisamente una de las principales interfaces utilizadas actualmente para trabajar con Spark desde Python.

---

### 7.13 RDD y DataFrame representan distintos niveles de abstracción

Podemos observar una evolución desde operaciones de menor nivel hacia interfaces más declarativas:

```text
Mayor control sobre
el procesamiento
       ▲
       │
      RDD
       │
       ▼
   DataFrame
       │
       ▼
   Spark SQL
       │
       ▼
Mayor abstracción
```

Con un RDD pensamos frecuentemente en operaciones como:

```text
elemento
   ↓
transformar
   ↓
filtrar
   ↓
reducir
```

Con un DataFrame pensamos más naturalmente en:

```text
columnas
   ↓
filtrar
   ↓
agrupar
   ↓
agregar
```

Y con SQL podemos expresar directamente:

```text
SELECT
FROM
WHERE
GROUP BY
```

Las tres aproximaciones terminan utilizando el motor distribuido de Spark.

---

### 7.14 Spark continúa utilizando evaluación perezosa

El uso de DataFrames no elimina el concepto de **lazy evaluation** estudiado anteriormente.

Podemos definir varias operaciones:

```text
DataFrame
    │
    ▼
  filter
    │
    ▼
 select
    │
    ▼
 groupBy
```

Spark puede construir un plan lógico sin ejecutar inmediatamente todas las operaciones.

Cuando solicitamos un resultado:

```text
DataFrame
    │
    ▼
Transformaciones
    │
    ▼
  Acción
    │
    ▼
Ejecución
```

Por lo tanto, los principios fundamentales estudiados con RDD continúan siendo relevantes.

---

### 7.15 Una visión integrada

Podemos reunir ahora las principales abstracciones estudiadas:

```text
                    Apache Spark
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
           RDD                 APIs estructuradas
                                      │
                           ┌──────────┴──────────┐
                           │                     │
                           ▼                     ▼
                       DataFrame              Dataset
                           │
                           ▼
                       Spark SQL
```

Todas ellas utilizan finalmente la infraestructura de ejecución de Spark:

```text
API utilizada
     │
     ▼
Motor Spark
     │
     ▼
Jobs
     │
     ▼
Stages
     │
     ▼
Tasks
     │
     ▼
Executors
```

La abstracción utilizada puede cambiar.

El principio de procesamiento distribuido permanece.

---

## Idea fundamental del apartado

Los **RDD** permiten trabajar con colecciones distribuidas de objetos, mientras que los **DataFrames** incorporan una estructura tabular y un esquema que Spark puede utilizar para analizar y optimizar el procesamiento.

Spark SQL permite además expresar operaciones mediante consultas SQL sin abandonar el procesamiento distribuido.

Podemos resumirlo así:

```text
RDD
 │
 │ datos distribuidos
 ▼
DataFrame
 │
 │ datos distribuidos + estructura
 ▼
Spark SQL
 │
 │ consultas sobre datos estructurados
 ▼
Procesamiento distribuido
```

Esto permitirá conectar directamente Spark con conocimientos que ya hemos desarrollado durante el estudio de **HDFS y Hive**.

En el siguiente apartado ampliaremos nuestra visión para comprender que Spark no está limitado a RDD y consultas SQL, sino que forma parte de un ecosistema que incorpora diferentes capacidades de procesamiento de datos.

---

## 8. El ecosistema Apache Spark

Hasta ahora hemos estudiado Spark principalmente desde dos perspectivas:

- los **RDD**, que permiten comprender los fundamentos del procesamiento distribuido;
- los **DataFrames y Spark SQL**, que proporcionan herramientas de mayor nivel para trabajar con datos estructurados.

Sin embargo, Apache Spark fue diseñado como un motor de procesamiento de **propósito general**.

Esto significa que sobre un mismo motor pueden desarrollarse diferentes tipos de procesamiento de datos.

Conceptualmente:

```text
                         Apache Spark
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
     Spark SQL         Structured Streaming     MLlib
          │
          │
          ▼
     DataFrames
          
               + APIs fundamentales
                       RDD
```

Históricamente, el ecosistema también ha incluido componentes como **GraphX** y el modelo original de **Spark Streaming**.

La característica fundamental es que estas capacidades comparten la infraestructura y el modelo de ejecución de Spark.

---

### 8.1 Spark Core: el núcleo

En la base del ecosistema se encuentra **Spark Core**.

Spark Core proporciona las funcionalidades fundamentales necesarias para el procesamiento distribuido.

Entre ellas se encuentran:

* administración de tareas;
* planificación de ejecución;
* comunicación con el clúster;
* manejo de memoria;
* tolerancia a fallos;
* operaciones sobre RDD;
* interacción con sistemas de almacenamiento.

Podemos imaginarlo como la base sobre la cual se construyen las demás capacidades:

```text
              Componentes de Spark
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
    Spark SQL     Streaming       MLlib
        │             │             │
        └─────────────┼─────────────┘
                      ▼
                 SPARK CORE
                      │
                      ▼
            Ejecución distribuida
```

Por lo tanto, cuando utilizamos una API de mayor nivel, seguimos utilizando finalmente el motor de ejecución de Spark.

---

### 8.2 Spark SQL: datos estructurados

**Spark SQL** permite trabajar con información estructurada y semiestructurada.

Sus principales herramientas incluyen:

* DataFrames;
* consultas SQL;
* esquemas;
* funciones de agregación;
* integración con diferentes fuentes de datos.

Por ejemplo, un conjunto de ventas puede representarse mediante:

```text
+----------+------------+------------+---------+
| id_venta | ciudad     | categoria  | monto   |
+----------+------------+------------+---------+
| 1        | Santiago   | Tecnología | 150000  |
| 2        | Valparaíso | Hogar      |  85000  |
| 3        | Santiago   | Hogar      | 120000  |
+----------+------------+------------+---------+
```

Sobre estos datos podríamos realizar operaciones como:

```text
Seleccionar columnas
        ↓
Filtrar registros
        ↓
Agrupar
        ↓
Calcular agregaciones
        ↓
Obtener resultados
```

También podemos utilizar SQL:

```sql id="52x0py"
SELECT ciudad, SUM(monto)
FROM ventas
GROUP BY ciudad;
```

Spark transforma estas operaciones en procesamiento distribuido.

---

### 8.3 Structured Streaming: procesamiento continuo de datos

Hasta ahora hemos imaginado conjuntos de datos que ya existen antes de comenzar el procesamiento.

Por ejemplo:

```text
ventas.csv
    │
    ▼
  Spark
    │
    ▼
Resultado
```

Pero existen escenarios donde los datos se generan continuamente.

Por ejemplo:

* sensores;
* dispositivos IoT;
* transacciones;
* registros de aplicaciones;
* eventos de plataformas digitales;
* sistemas de mensajería.

Conceptualmente:

```text
Evento
  ↓
Evento
  ↓
Evento
  ↓
Evento
  ↓
Evento
  ↓
...
```

En estos casos podemos hablar de un **flujo de datos** o *stream*.

Spark proporciona **Structured Streaming** para trabajar con este tipo de procesamiento utilizando las APIs estructuradas.

---

### 8.4 Una tabla que nunca termina

Una forma útil de comprender Structured Streaming es imaginar un flujo como una tabla a la cual continuamente llegan nuevas filas.

```text
Tiempo 1

+---------+------------+-------+
| venta   | ciudad     | monto |
+---------+------------+-------+
| 1       | Santiago   | 50000 |
+---------+------------+-------+
```

Después llega otro evento:

```text
Tiempo 2

+---------+------------+-------+
| venta   | ciudad     | monto |
+---------+------------+-------+
| 1       | Santiago   | 50000 |
| 2       | Valparaíso | 70000 |
+---------+------------+-------+
```

Luego otro:

```text
Tiempo 3

+---------+------------+-------+
| venta   | ciudad     | monto |
+---------+------------+-------+
| 1       | Santiago   | 50000 |
| 2       | Valparaíso | 70000 |
| 3       | Santiago   | 40000 |
+---------+------------+-------+
```

Los datos continúan llegando mientras Spark los procesa.

Esta abstracción permite utilizar operaciones similares a las empleadas con DataFrames.

---

### 8.5 Batch y Streaming

Podemos distinguir conceptualmente dos escenarios:

```text
BATCH

Datos existentes
      │
      ▼
 Procesamiento
      │
      ▼
  Resultado
```

frente a:

```text
STREAMING

Datos → Datos → Datos → Datos → ...
          │
          ▼
     Procesamiento
          │
          ▼
Resultados actualizados
```

Spark puede participar en ambos tipos de procesamiento.

Esto contribuyó a convertirlo en una plataforma flexible para diferentes arquitecturas de datos.

---

### 8.6 Spark y sistemas de eventos

Los datos utilizados en streaming pueden provenir de diferentes sistemas.

Un ejemplo habitual dentro de arquitecturas Big Data es **Apache Kafka**.

Conceptualmente:

```text
Aplicaciones
Sensores
Sistemas
    │
    ▼
  Kafka
    │
    ▼
  Spark
    │
    ▼
Procesamiento
    │
    ▼
Resultados
```

Kafka puede actuar como plataforma de eventos, mientras Spark realiza procesamiento sobre esos datos.

Esta relación permite observar nuevamente un principio importante:

> Las tecnologías Big Data suelen especializarse en diferentes funciones y posteriormente integrarse dentro de una arquitectura.

---

### 8.7 MLlib: Machine Learning distribuido

Spark también incorpora capacidades orientadas al **Machine Learning** mediante **MLlib**.

Machine Learning utiliza algoritmos capaces de identificar patrones en los datos para realizar tareas como:

* clasificación;
* regresión;
* agrupamiento;
* recomendación;
* transformación de características.

Conceptualmente:

```text
Datos
  │
  ▼
Preparación
  │
  ▼
Algoritmo ML
  │
  ▼
Modelo
  │
  ▼
Predicción
```

Cuando los conjuntos de datos son grandes, Spark permite distribuir parte de este procesamiento utilizando los recursos del clúster.

---

### 8.8 ¿Por qué Spark resulta útil para Machine Learning?

Muchos procesos de Machine Learning requieren varias etapas.

Por ejemplo:

```text 
Datos originales
      │
      ▼
Limpieza
      │
      ▼
Transformación
      │
      ▼
Construcción de variables
      │
      ▼
Entrenamiento
      │
      ▼
Evaluación
      │
      ▼
Modelo
```

Además, determinados algoritmos pueden necesitar realizar múltiples iteraciones sobre los datos.

Recordemos uno de los problemas que motivaron originalmente el desarrollo de Spark:

```text
Mismos datos
    │
    ├── Iteración 1
    ├── Iteración 2
    ├── Iteración 3
    └── ...
```

La posibilidad de reutilizar eficientemente datos durante el procesamiento resulta especialmente relevante en este escenario.

---

### 8.9 Pipelines de Machine Learning

MLlib permite organizar diferentes etapas mediante **pipelines**.

Un pipeline representa una secuencia de operaciones.

Por ejemplo:

```text
Datos
  │
  ▼
Preparación
  │
  ▼
Transformación
  │
  ▼
Entrenamiento
  │
  ▼
Predicción
```

Este concepto es importante porque refleja una característica que hemos observado repetidamente en Spark:

> El procesamiento de datos suele expresarse como una secuencia de transformaciones conectadas entre sí.

---

### 8.10 GraphX: procesamiento de grafos

Otro componente histórico del ecosistema Spark es **GraphX**, orientado al procesamiento de grafos utilizando Scala y Java.

Un grafo representa información mediante:

* **vértices**;
* **aristas**.

Por ejemplo, una red social podría representarse así:

```text
      Ana
     /   \
    /     \
 Pedro --- María
    \
     \
     Juan
```

Los vértices podrían representar personas y las aristas representar relaciones entre ellas.

Los grafos pueden utilizarse para analizar problemas como:

* redes sociales;
* rutas;
* relaciones entre entidades;
* sistemas de recomendación;
* estructuras de conexiones.

GraphX muestra nuevamente la amplitud histórica del ecosistema Spark, aunque actualmente el trabajo cotidiano con Spark suele concentrarse especialmente en las APIs estructuradas.

---

### 8.11 Spark Streaming y Structured Streaming

Es importante distinguir dos generaciones de procesamiento de streaming dentro de Spark.

Históricamente existió **Spark Streaming**, basado en el concepto de pequeños lotes o *micro-batches* y estrechamente relacionado con RDD.

Conceptualmente:

```text
Flujo continuo
      │
      ▼
┌─────┬─────┬─────┬─────┐
│ L1  │ L2  │ L3  │ L4  │
└─────┴─────┴─────┴─────┘
      │
      ▼
 Procesamiento
```

Posteriormente apareció **Structured Streaming**, integrado con DataFrames y las APIs estructuradas.

```text
Flujo de datos
      │
      ▼
Structured Streaming
      │
      ▼
DataFrames
      │
      ▼
Motor Spark SQL
```

Para comprender el Spark moderno, Structured Streaming constituye la referencia más importante.

---

### 8.12 Un mismo motor, diferentes cargas de trabajo

Ahora podemos observar una característica fundamental del ecosistema Spark.

```text
                        DATOS
                          │
                          ▼
                   APACHE SPARK
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
      Batch           Streaming       Machine Learning
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                          ▼
                 Motor distribuido
```

En lugar de utilizar necesariamente un motor completamente diferente para cada tipo de procesamiento, Spark proporciona varias capacidades que comparten una infraestructura común.

---

### 8.13 El ecosistema no significa que Spark haga todo

Debemos evitar una interpretación incorrecta.

Que Spark posea múltiples capacidades no significa que sustituya a todas las tecnologías de una arquitectura Big Data.

Por ejemplo:

```text
HDFS       → almacenamiento distribuido

Hive       → metadatos y consulta de datos

Kafka      → plataforma de eventos

Spark      → procesamiento distribuido
```

Estas tecnologías pueden trabajar conjuntamente:

```text
                   Fuentes de datos
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
           HDFS                     Kafka
            │                         │
            └────────────┬────────────┘
                         ▼
                       Spark
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
             SQL        ML       Streaming
```

Por lo tanto, una arquitectura Big Data se construye normalmente mediante la **integración de diferentes componentes especializados**.

---

### 8.14 Nuestro recorrido dentro del ecosistema

No necesitamos estudiar en profundidad todos los componentes de Spark al mismo tiempo.

Nuestro recorrido será progresivo.

```text
RDD
 │
 ▼
Transformaciones y acciones
 │
 ▼
DataFrames
 │
 ▼
Spark SQL
 │
 ▼
Integración con HDFS / Hive
```

Otros componentes, como Machine Learning y Streaming, permiten comprender el alcance de Spark y podrán ser profundizados posteriormente según los objetivos de análisis.

De esta manera evitamos confundir:

```text
Conocer el ecosistema
        ≠
Dominar todos sus componentes
```

El objetivo inicial consiste en comprender correctamente **cómo funciona el motor de procesamiento distribuido**.

---

## Idea fundamental del apartado

Apache Spark constituye un ecosistema de procesamiento de datos construido sobre un motor distribuido común.

Sus principales capacidades pueden resumirse así:

```text
                    Apache Spark
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
       ▼                 ▼                 ▼
   Spark SQL       Structured         MLlib
                   Streaming
       │                 │                 │
       └─────────────────┼─────────────────┘
                         ▼
                     Spark Core
                         │
                         ▼
               Procesamiento distribuido
```

La idea fundamental no consiste en memorizar todos los componentes.

Debemos comprender que:

> **Spark permite aplicar un mismo modelo de procesamiento distribuido a diferentes tipos de cargas de trabajo y puede integrarse con otras tecnologías del ecosistema Big Data.**

Esta capacidad de integración nos permite volver ahora sobre las tecnologías que ya conocemos —especialmente HDFS y Hive— y comprender cuál es el lugar que ocupa Spark dentro de una arquitectura Big Data.

---

## 9. Spark dentro del ecosistema Hadoop: relación con HDFS y Hive

A lo largo del curso hemos incorporado diferentes tecnologías del ecosistema Big Data.

Primero estudiamos **HDFS**, posteriormente utilizamos **Hive** y ahora incorporamos **Apache Spark**.

Estas tecnologías no deben comprenderse como herramientas aisladas ni necesariamente como reemplazos unas de otras.

Cada una responde principalmente a un problema diferente:

```text
HDFS  → ¿Dónde y cómo almacenamos grandes volúmenes de datos?

Hive  → ¿Cómo estructuramos y consultamos esos datos?

Spark → ¿Cómo procesamos esos datos de manera distribuida?
```

Comprender esta separación de responsabilidades permite interpretar correctamente una arquitectura Big Data.

---

### 9.1 Tres tecnologías, tres responsabilidades

Podemos comenzar estableciendo una comparación general:

| Tecnología | Función principal                                   |
| ---------- | --------------------------------------------------- |
| HDFS       | Almacenamiento distribuido                          |
| Hive       | Organización mediante tablas, metadatos y consultas |
| Spark      | Procesamiento distribuido                           |

Esta clasificación es deliberadamente simplificada, pero proporciona un modelo mental útil.

Podemos representarlo así:

```text
                    Ecosistema Big Data
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
        HDFS             Hive             Spark
          │                │                │
          ▼                ▼                ▼
   Almacenamiento      Estructura      Procesamiento
    distribuido        y consulta       distribuido
```

La potencia de una arquitectura Big Data aparece cuando estos componentes pueden colaborar.

---

### 9.2 HDFS como capa de almacenamiento

Ya conocemos el propósito fundamental de HDFS.

Un archivo grande puede dividirse en bloques y almacenarse utilizando los DataNodes disponibles en un clúster.

Conceptualmente:

```text
                    Archivo
                       │
                       ▼
                      HDFS
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
        Bloque        Bloque        Bloque
          │            │            │
          ▼            ▼            ▼
       DataNode      DataNode      DataNode
```

HDFS se preocupa principalmente de aspectos como:

* almacenamiento distribuido;
* localización de bloques;
* replicación;
* disponibilidad de los datos;
* acceso a archivos distribuidos.

Sin embargo, HDFS por sí mismo no proporciona una experiencia equivalente a consultar una base de datos mediante SQL.

Para ello incorporamos Hive.

---

### 9.3 Hive agrega estructura sobre los datos

Hive permite definir estructuras similares a tablas sobre datos almacenados en sistemas como HDFS.

Por ejemplo, un archivo:

```text
ventas_hive.csv
```

puede encontrarse almacenado en:

```text
HDFS
 │
 ▼
/curso/hive/datos_ventas/
```

Sobre esos datos podemos definir una tabla con una estructura como:

```text
ventas_hive
 │
 ├── id_venta
 ├── fecha
 ├── cliente
 ├── ciudad
 ├── categoria
 └── monto
```

Hive proporciona entonces una capa lógica:

```text 
              Tabla Hive
                  │
                  ▼
              Metadatos
                  │
                  ▼
            Datos en HDFS
```

Esta separación fue uno de los conceptos importantes estudiados anteriormente:

> **La tabla y sus metadatos no son lo mismo que los archivos que contienen físicamente los datos.**

---

### 9.4 ¿Dónde aparece Spark?

Spark puede utilizar datos almacenados en HDFS como entrada para sus procesos.

Conceptualmente:

```text 
                 HDFS
                   │
                   ▼
             Archivo de datos
                   │
                   ▼
                 Spark
                   │
            ┌──────┴──────┐
            ▼             ▼
           RDD         DataFrame
            │             │
            └──────┬──────┘
                   ▼
             Procesamiento
```

Esto significa que no necesitamos copiar necesariamente los datos desde HDFS hacia otro sistema para comenzar a procesarlos.

Spark puede acceder al almacenamiento distribuido y construir sus propias estructuras de procesamiento.

---

### 9.5 HDFS y Spark: almacenamiento frente a procesamiento

Aquí debemos distinguir nuevamente dos conceptos que pueden parecer similares.

HDFS puede dividir un archivo en:

```text 
BLOQUES
```

mientras Spark trabaja con:

```text 
PARTICIONES
```

No son equivalentes.

```text 
HDFS                           SPARK

Archivo                        Dataset
  │                               │
  ▼                               ▼
Bloques                        Particiones
  │                               │
  ▼                               ▼
DataNodes                       Tasks
```

El bloque HDFS responde a una necesidad de **almacenamiento**.

La partición Spark responde principalmente a una necesidad de **procesamiento**.

Por ello:

```text 
Bloque HDFS ≠ Partición Spark
```

Aunque la forma en que Spark lee una fuente de datos puede influir en la creación de particiones, no debemos considerar ambos conceptos como sinónimos.

---

### 9.6 DataNode y Worker tampoco son equivalentes

Existe otra distinción importante.

En HDFS encontramos:

```text 
DataNode
```

y en Spark:

```text
Worker
```

Ambos pueden existir dentro de una misma infraestructura, pero tienen responsabilidades diferentes.

```text 
DataNode
   │
   ▼
Almacena bloques HDFS


Worker
   │
   ▼
Proporciona recursos
para ejecutar procesamiento Spark
```

Por lo tanto:

```text 
DataNode ≠ Worker
```

Un nodo físico podría ejecutar diferentes servicios, pero conceptualmente sus funciones siguen siendo distintas.

---

### 9.7 Spark puede leer directamente desde HDFS

Supongamos que tenemos:

```text 
ventas_hive.csv
```

almacenado en HDFS.

Hasta ahora podríamos haber utilizado Hive:

```text 
ventas_hive.csv
       │
       ▼
      HDFS
       │
       ▼
      Hive
       │
       ▼
     HiveQL
```

Pero Spark también puede utilizar directamente el archivo:

```text 
ventas_hive.csv
       │
       ▼
      HDFS
       │
       ▼
     Spark
       │
       ▼
RDD / DataFrame
       │
       ▼
Procesamiento
```

Esto será una de las integraciones que posteriormente observaremos en las actividades prácticas.

---

### 9.8 Un mismo dato puede ser utilizado de distintas maneras

Esta situación permite comprender un principio importante de las arquitecturas de datos.

El mismo conjunto de datos puede ser utilizado por diferentes motores.

Por ejemplo:

```text 
                  ventas_hive.csv
                         │
                         ▼
                        HDFS
                         │
               ┌─────────┴─────────┐
               │                   │
               ▼                   ▼
             Hive                Spark
               │                   │
               ▼                   ▼
            HiveQL           Scala / Python
```

Los datos no necesariamente pertenecen exclusivamente a Hive o a Spark.

Están almacenados en una capa que puede ser utilizada por diferentes herramientas.

---

### 9.9 ¿Y qué ocurre con las tablas Hive?

Aquí aparece una segunda forma de integración.

Hive no solamente permite acceder a archivos.

También mantiene información acerca de las tablas mediante su **Metastore**.

Conceptualmente:

```text 
                  HIVE
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
      Metastore            HDFS
          │                 │
     estructura            datos
     de tablas             físicos
```

El Metastore puede contener información como:

* nombres de tablas;
* columnas;
* tipos de datos;
* ubicación de los archivos;
* particiones de tablas;
* otras propiedades.

Spark puede integrarse con el ecosistema Hive y, cuando el entorno se encuentra configurado para ello, utilizar esta información.

---

### 9.10 Spark + Hive

Conceptualmente, la integración puede representarse así:

```text 
                  Spark
                    │
                    ▼
               Spark SQL
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
    Hive Metastore           HDFS
          │                   │
          ▼                   ▼
      Metadatos              Datos
```

De esta forma Spark puede trabajar con información estructurada utilizando conceptos que ya conocemos de Hive.

Esto permite que una arquitectura evolucione sin necesariamente abandonar los datos y estructuras previamente construidos.

---

### 9.11 Dos formas diferentes de llegar a los mismos datos

Supongamos que tenemos los datos utilizados durante nuestras actividades de Hive.

Una primera posibilidad es acceder directamente al archivo:

```text 
HDFS
 │
 ▼
ventas_hive.csv
 │
 ▼
Spark
 │
 ▼
DataFrame
```

Otra posibilidad, cuando existe integración con Hive, es utilizar la estructura definida mediante una tabla:

```text 
             Tabla Hive
                 │
        ┌────────┴────────┐
        ▼                 ▼
    Metadatos            HDFS
                            │
                            ▼
                          Datos
        │
        └──────────┐
                   ▼
                 Spark
```

La diferencia conceptual es importante.

En el primer caso Spark conoce directamente una **fuente de datos**.

En el segundo puede aprovechar además información estructural administrada mediante Hive.

---

### 9.12 Entonces, ¿para qué necesitamos Spark si ya tenemos Hive?

Esta pregunta es especialmente importante.

Hive permite realizar consultas y análisis utilizando un modelo similar a SQL.

Por ejemplo:

```sql id="l2b87e"
SELECT ciudad, SUM(monto)
FROM ventas_hive
GROUP BY ciudad;
```

Para numerosos problemas analíticos, este modelo resulta muy conveniente.

Spark, sin embargo, proporciona un motor de procesamiento de propósito más general.

Podemos trabajar mediante:

```text
Spark
 │
 ├── RDD
 ├── DataFrames
 ├── SQL
 ├── Machine Learning
 └── Streaming
```

Por lo tanto, la diferencia no consiste simplemente en:

```text 
Hive = lento
Spark = rápido
```

Esta comparación sería excesivamente simplificada.

Una distinción conceptual más apropiada es:

```text 
Hive
  │
  ▼
Abstracción orientada históricamente
al análisis de datos mediante tablas y SQL


Spark
  │
  ▼
Motor general de procesamiento
distribuido con múltiples APIs
```

Ambos pueden formar parte de una misma arquitectura.

---

### 9.13 Una arquitectura por capas

Podemos representar lo estudiado hasta ahora mediante diferentes capas.

```text 
┌─────────────────────────────────────┐
│          ANÁLISIS / USUARIO         │
│                                     │
│      SQL      Scala      Python     │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│           PROCESAMIENTO             │
│                                     │
│          Hive       Spark           │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│           ALMACENAMIENTO            │
│                                     │
│                 HDFS                │
└─────────────────────────────────────┘
```

Este esquema es simplificado, pero permite observar que diferentes herramientas pueden actuar sobre una misma capa de almacenamiento.

---

### 9.14 Separar almacenamiento y procesamiento

Esta arquitectura también permite comprender una idea importante de los sistemas de datos modernos:

> **Los datos pueden persistir independientemente del motor utilizado para procesarlos.**

Por ejemplo:

```text
               HDFS
                 │
       datos persistentes
                 │
       ┌─────────┼─────────┐
       ▼         ▼         ▼
     Hive      Spark      otro
     motor     motor      motor
```

Esta separación proporciona flexibilidad.

Podemos cambiar o incorporar herramientas de procesamiento sin necesariamente mover todos los datos a un nuevo sistema.

---

### 9.15 ¿Dónde ocurre realmente el procesamiento?

Supongamos que Spark lee datos almacenados en HDFS.

Podríamos representar el proceso así:

```text
HDFS
 │
 │ lectura
 ▼
Spark
 │
 ▼
Particiones
 │
 ▼
Tasks
 │
 ▼
Executors
 │
 ▼
Resultado
```

HDFS proporciona los datos.

Spark organiza su procesamiento.

Si posteriormente necesitamos almacenar el resultado:

```text 
Spark
 │
 ▼
Resultado
 │
 ▼
HDFS
```

obtenemos un ciclo completo:

```text
             HDFS
              │
              │ lectura
              ▼
            Spark
              │
              │ procesamiento
              ▼
          Resultado
              │
              │ escritura
              ▼
             HDFS
```

Esto refleja claramente la separación entre **persistencia** y **procesamiento**.

---

### 9.16 Nuestro caso de estudio

Esta integración no será solamente conceptual.

En las actividades prácticas volveremos a utilizar un conjunto de datos que ya conocemos:

```text 
ventas_hive.csv
```

con una estructura similar a:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

y almacenado en HDFS.

El recorrido pedagógico será:

```text
             ventas_hive.csv
                    │
                    ▼
                   HDFS
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
        Hive                Spark
          │                   │
          ▼                   ▼
       HiveQL            RDD / DataFrame
                              │
                              ▼
                          Spark SQL
```

Esto permitirá analizar los **mismos datos desde diferentes tecnologías**.

La ventaja pedagógica es que el estudiante no necesita aprender simultáneamente un nuevo dataset y un nuevo motor de procesamiento.

El elemento nuevo será Spark.

---

### 9.17 Una precisión importante sobre nuestra arquitectura

Aunque Spark puede integrarse con Hive, esta integración depende de la **configuración concreta de la infraestructura**.

Por ello debemos distinguir:

```text 
Capacidad de Spark
        │
        ▼
Integrarse con Hive


              ≠


Integración configurada
automáticamente en cualquier clúster
```

En nuestras actividades prácticas comprobaremos qué mecanismos de integración están disponibles en la arquitectura utilizada durante el curso.

En particular, verificaremos por separado:

1. acceso de Spark a datos almacenados en HDFS;
2. acceso de Spark a estructuras administradas mediante Hive.

Esta distinción evita asumir que dos servicios instalados dentro de una misma infraestructura se encuentran automáticamente integrados.

---

### 9.18 El modelo completo que debemos conservar

Después de estudiar HDFS, Hive y Spark, podemos construir finalmente una visión integrada:

```text 
                        USUARIO
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
             SQL         Scala        Python
              │            │            │
              └────────────┼────────────┘
                           ▼
                    PROCESAMIENTO
                           │
                ┌──────────┴──────────┐
                ▼                     ▼
               Hive                 Spark
                │                     │
                └──────────┬──────────┘
                           ▼
                          HDFS
                           │
                           ▼
                  DATOS PERSISTENTES
```

Cada tecnología responde a una responsabilidad diferente, pero todas pueden colaborar dentro de una misma solución.

---

## Idea fundamental del apartado

HDFS, Hive y Spark no deben estudiarse como tres tecnologías aisladas.

Podemos comprender su relación mediante tres conceptos:

```text 
HDFS
  ↓
ALMACENAR

Hive
  ↓
ESTRUCTURAR Y CONSULTAR

Spark
  ↓
PROCESAR
```

Spark puede leer datos almacenados en HDFS, procesarlos de manera distribuida y volver a escribir resultados.

Además, cuando existe una integración correctamente configurada, Spark puede aprovechar estructuras y metadatos asociados a Hive.

La idea central es:

> **Los datos pueden permanecer en una capa de almacenamiento distribuido mientras diferentes motores los utilizan según las necesidades del procesamiento.**

Con esta integración ya disponemos de una visión general del funcionamiento de Spark. Solo resta comprender cómo interactuaremos con este motor mediante los dos lenguajes que utilizaremos durante el curso: **Scala y Python**.

---

## 10. Scala y Python en Apache Spark

Hasta ahora hemos estudiado Spark desde la perspectiva de su arquitectura y de su modelo de procesamiento distribuido.

Hemos revisado conceptos como:

- Driver;
- Workers;
- Executors;
- RDD;
- particiones;
- transformaciones y acciones;
- evaluación perezosa;
- DataFrames;
- Spark SQL;
- integración con HDFS y Hive.

Sin embargo, para utilizar estas capacidades necesitamos una forma de comunicarnos con Spark.

Apache Spark proporciona APIs para diferentes lenguajes de programación.

Entre ellas destacan:

- **Scala**
- **Python**
- Java
- R
- SQL

En nuestro curso utilizaremos principalmente **Scala y Python**, con el propósito de comprender Spark desde ambas perspectivas.

---

### 10.1 Spark no es un lenguaje de programación

Antes de continuar debemos evitar una confusión frecuente.

Spark **no es un lenguaje de programación**.

Spark es un motor de procesamiento distribuido que proporciona APIs para diferentes lenguajes.

Conceptualmente:

```text
                 Apache Spark
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
     Scala          Python          Java
       │              │              │
       └──────────────┼──────────────┘
                      ▼
                 Motor Spark
                      │
                      ▼
            Procesamiento distribuido
```

Esto significa que podemos expresar operaciones utilizando diferentes lenguajes y solicitar a Spark que realice el procesamiento correspondiente.

---

### 10.2 ¿Por qué Scala tiene una relación especial con Spark?

Apache Spark fue desarrollado originalmente utilizando **Scala**.

Scala es un lenguaje que se ejecuta sobre la **Java Virtual Machine (JVM)**.

Podemos representar esta relación de manera simplificada:

```text
Código Scala
     │
     ▼
    JVM
     │
     ▼
Apache Spark
```

Por esta razón, Scala ha mantenido históricamente una relación especialmente estrecha con el desarrollo y las APIs de Spark.

Además, muchas explicaciones técnicas y ejemplos clásicos de Spark utilizan Scala.

---

### 10.3 Scala combina diferentes paradigmas

Scala permite utilizar características de diferentes paradigmas de programación.

Entre ellas destacan:

* programación orientada a objetos;
* programación funcional.

La programación funcional resulta especialmente interesante en Spark porque muchas operaciones pueden expresarse como transformaciones aplicadas sobre conjuntos de datos.

Por ejemplo, conceptualmente:

```text
Datos
  │
  ▼
Función
  │
  ▼
Nuevos datos
```

Esta idea se relaciona directamente con operaciones como:

```text 
map
filter
reduce
```

que hemos estudiado conceptualmente al revisar los RDD.

---

### 10.4 Python y PySpark

Python es actualmente uno de los lenguajes más utilizados en ámbitos como:

* análisis de datos;
* ciencia de datos;
* Machine Learning;
* automatización;
* inteligencia artificial.

Spark proporciona una API para Python denominada:

**PySpark**

Conceptualmente:

```text
Python
  │
  ▼
PySpark
  │
  ▼
Apache Spark
  │
  ▼
Procesamiento distribuido
```

PySpark permite utilizar gran parte de las capacidades de Spark desde código Python.

---

### 10.5 PySpark no significa "Spark escrito en Python"

Esta distinción es importante.

Cuando utilizamos PySpark estamos utilizando una **interfaz de Python para trabajar con Spark**.

No debemos interpretar que todo el motor de Spark haya sido reimplementado completamente en Python.

Conceptualmente:

```text 
Código Python
     │
     ▼
   PySpark
     │
     ▼
Motor de Spark
     │
     ▼
   Clúster
```

Por ello, muchos conceptos permanecen exactamente iguales independientemente del lenguaje utilizado.

---

### 10.6 El lenguaje cambia, los conceptos permanecen

Supongamos que queremos realizar el siguiente procesamiento:

```text 
Datos
  │
  ▼
Filtrar
  │
  ▼
Transformar
  │
  ▼
Contar
```

Podemos expresarlo utilizando Scala o Python.

Pero conceptualmente Spark continúa realizando:

```text 
Transformaciones
      │
      ▼
Lazy Evaluation
      │
      ▼
Acción
      │
      ▼
Job
      │
      ▼
Stages
      │
      ▼
Tasks
      │
      ▼
Executors
```

Por lo tanto:

> **Scala y Python son interfaces diferentes para interactuar con el mismo motor distribuido.**

---

### 10.7 Un ejemplo conceptual en Scala y Python

Consideremos una colección de números:

```text
1 2 3 4 5
```

Queremos conservar solamente los números mayores que 2.

En Scala la idea podría expresarse como:

```scala id="0q3yfw"
filter(x => x > 2)
```

Mientras que en Python podríamos encontrar una expresión como:

```python id="r10cck"
filter(lambda x: x > 2)
```

El estilo sintáctico cambia.

La operación conceptual es la misma:

```text 
1 2 3 4 5
    │
    │ filtrar > 2
    ▼
    3 4 5
```

Esta será una estrategia importante durante el curso: observar cómo una misma operación Spark puede expresarse mediante ambos lenguajes.

---

### 10.8 RDD en Scala y PySpark

Los conceptos fundamentales de los RDD pueden utilizarse desde ambos lenguajes.

Conceptualmente:

```text 
                  RDD
                   │
          ┌────────┴────────┐
          ▼                 ▼
        Scala             PySpark
          │                 │
          └────────┬────────┘
                   ▼
             Motor Spark
```

Podremos estudiar operaciones equivalentes como:

```text
map
filter
flatMap
reduce
count
collect
```

Esto permitirá concentrarnos primero en **qué hace Spark** y posteriormente observar las diferencias sintácticas entre los lenguajes.

---

### 10.9 DataFrames en Scala y PySpark

La misma lógica se aplica a los DataFrames.

Supongamos que tenemos:

```text 
+----------+------------+--------+
| id_venta | ciudad     | monto  |
+----------+------------+--------+
| 1        | Santiago   | 150000 |
| 2        | Valparaíso |  85000 |
+----------+------------+--------+
```

Podemos manipular este DataFrame utilizando Scala o PySpark.

```text 
                    DataFrame
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
          Scala API          PySpark API
              │                   │
              └─────────┬─────────┘
                        ▼
                    Spark SQL
                        │
                        ▼
                   Motor Spark
```

Esta arquitectura permite que diferentes usuarios trabajen con el mismo motor utilizando el lenguaje más apropiado para sus necesidades.

---

### 10.10 Spark SQL proporciona un lenguaje común

Existe además otra posibilidad.

Independientemente de que estemos trabajando desde Scala o Python, podemos utilizar consultas SQL sobre datos estructurados.

Por ejemplo:

```sql id="fnycb3"
SELECT ciudad, SUM(monto)
FROM ventas
GROUP BY ciudad;
```

Conceptualmente:

```text 
Scala ───────┐
             │
             ▼
          Spark SQL
             ▲
             │
Python ──────┘
```

Esto resulta especialmente útil cuando los usuarios ya poseen experiencia trabajando con SQL.

En nuestro caso, esta transición será natural porque anteriormente hemos utilizado HiveQL.

---

### 10.11 Scala y Python no compiten necesariamente

Una pregunta habitual es:

> ¿Qué lenguaje es mejor para trabajar con Spark?

No existe una respuesta universal.

La elección depende de factores como:

* características del proyecto;
* conocimientos del equipo;
* ecosistema tecnológico;
* bibliotecas necesarias;
* integración con otras aplicaciones;
* tipo de procesamiento.

Scala tiene una relación nativa con el ecosistema JVM y con el desarrollo histórico de Spark.

Python, mediante PySpark, proporciona una integración especialmente conveniente con el amplio ecosistema actual de análisis de datos y Machine Learning.

Por ello, en lugar de presentar ambos lenguajes como alternativas excluyentes, los estudiaremos como **dos formas de interactuar con Spark**.

---

### 10.12 Nuestra estrategia durante el curso

En las actividades prácticas utilizaremos ambos lenguajes de manera equilibrada.

La secuencia general será:

```text
Concepto Spark
      │
      ▼
Implementación Scala
      │
      ▼
Observar resultado
      │
      ▼
Implementación PySpark
      │
      ▼
Comparar
```

Por ejemplo:

```text 
RDD
 │
 ├── Scala
 │
 └── PySpark

Transformaciones
 │
 ├── Scala
 │
 └── PySpark

Acciones
 │
 ├── Scala
 │
 └── PySpark

DataFrames
 │
 ├── Scala
 │
 └── PySpark
```

El objetivo no será duplicar mecánicamente cada ejercicio.

La comparación debe permitir comprender qué elementos pertenecen al **lenguaje** y cuáles pertenecen realmente a **Spark**.

---

### 10.13 Del computador del estudiante al clúster

Cuando escribimos una instrucción Spark, el código que observamos constituye solamente el comienzo del proceso.

Conceptualmente:

```text 
Código Scala / Python
         │
         ▼
       Driver
         │
         ▼
     SparkContext
         │
         ▼
   Cluster Manager
         │
         ▼
      Workers
         │
         ▼
     Executors
         │
         ▼
       Tasks
```

Por ello, escribir unas pocas líneas de Scala o Python puede provocar múltiples operaciones distribuidas dentro del clúster.

Esta diferencia es fundamental respecto de un programa tradicional ejecutado exclusivamente en un computador.

---

### 10.14 No todo código Python o Scala se vuelve distribuido

Existe una idea que debemos dejar especialmente clara.

El hecho de ejecutar Python o Scala dentro de un entorno Spark **no significa que cualquier instrucción se distribuya automáticamente por el clúster**.

Por ejemplo:

```text 
Programa Python / Scala
         │
         ├── Código normal del lenguaje
         │
         └── Operaciones Spark
                    │
                    ▼
             Procesamiento
              distribuido
```

Para aprovechar el procesamiento distribuido debemos utilizar las abstracciones y APIs proporcionadas por Spark.

Por ejemplo:

* RDD;
* DataFrames;
* Spark SQL;
* APIs específicas del ecosistema Spark.

Por ello:

> **Spark no convierte automáticamente un programa tradicional en un programa distribuido.**

El desarrollador debe expresar el procesamiento utilizando las abstracciones que Spark puede distribuir.

---

### 10.15 Pensar primero en Spark y después en el lenguaje

Cuando comencemos las actividades prácticas será tentador concentrarnos inmediatamente en la sintaxis.

Por ejemplo:

```text 
¿Dónde van los paréntesis?

¿Cómo se escribe una función?

¿Cuál es la instrucción correcta?
```

Estas preguntas son necesarias, pero no deben ocultar las preguntas más importantes:

```text 
¿Estoy creando una transformación?

¿Estoy ejecutando una acción?

¿Cuántas particiones existen?

¿Se está generando un Job?

¿Dónde se ejecutan las Tasks?

¿Los datos están en HDFS?

¿El resultado vuelve al Driver?
```

Estas preguntas permiten comprender Spark más allá de memorizar comandos.

---

### 10.16 De la teoría a la práctica

Con los conceptos estudiados en esta guía ya podemos interpretar el flujo completo de una aplicación Spark.

```text
               DATOS
                 │
                 ▼
           HDFS / otras fuentes
                 │
                 ▼
        RDD / DataFrame
                 │
                 ▼
          Transformaciones
                 │
                 ▼
          Lazy Evaluation
                 │
                 ▼
              Acción
                 │
                 ▼
                Job
                 │
                 ▼
               Stages
                 │
                 ▼
               Tasks
                 │
                 ▼
             Executors
                 │
                 ▼
             Resultado
```

Scala y Python serán los lenguajes mediante los cuales comenzaremos a experimentar con este modelo.

En las guías prácticas no nos limitaremos a observar el resultado de una instrucción.

También relacionaremos nuestras operaciones con lo que ocurre dentro del clúster.

---

## Idea fundamental del apartado

Scala y Python permiten interactuar con Apache Spark utilizando sintaxis y ecosistemas diferentes.

Sin embargo, detrás de ambos lenguajes permanece el mismo motor:

```text 
         Scala                 Python
           │                     │
           │                  PySpark
           │                     │
           └──────────┬──────────┘
                      ▼
                 Apache Spark
                      │
                      ▼
          Procesamiento distribuido
```

Por esta razón, durante el curso utilizaremos ambos lenguajes de manera equilibrada.

La meta no consiste solamente en aprender instrucciones de Scala o PySpark.

La meta es comprender qué ocurre cuando esas instrucciones llegan a Spark:

```text 
Código
  ↓
Transformaciones
  ↓
Acciones
  ↓
Jobs
  ↓
Stages
  ↓
Tasks
  ↓
Executors
  ↓
Procesamiento distribuido
```

---

# Cierre de la guía

A lo largo de esta lectura hemos recorrido los fundamentos teóricos necesarios para comenzar a trabajar con Apache Spark:

```text 
Origen de Spark
      ↓
Problema que intenta resolver
      ↓
Arquitectura
      ↓
Ejecución en clúster
      ↓
RDD
      ↓
Transformaciones y acciones
      ↓
DataFrames y Spark SQL
      ↓
Ecosistema Spark
      ↓
HDFS + Hive + Spark
      ↓
Scala + PySpark
```

Este recorrido también completa una progresión más amplia desarrollada durante el curso:

```text
HDFS
 │
 │ almacenamiento distribuido
 ▼
Hive
 │
 │ estructura y consulta
 ▼
Spark
 │
 │ procesamiento distribuido
 ▼
Análisis de datos a escala
```











