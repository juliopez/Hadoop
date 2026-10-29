# Apache Kafka

## Tabla de Contenidos

### Parte I. Fundamentos, contexto y arquitectura de Apache Kafka

1.1. Del procesamiento batch al procesamiento de eventos\
\
&#x20;   1.2. Historia, origen y evolución de Apache Kafka\
\
&#x20;   1.3. ¿Qué es Apache Kafka y qué problemas resuelve?\
\
&#x20;   1.4. Conceptos fundamentales: eventos, productores, consumidores, tópicos y brokers\
\
&#x20;   1.5. Arquitectura distribuida de Kafka: particiones, offsets, replicación y grupos de consumidores\
\
&#x20;   1.6. Tiempo real, Near Real-Time y procesamiento batch: diferencias y aplicaciones\
\
&#x20;   1.7. Kafka en el ecosistema Big Data: relaciones con Hadoop, Spark, APIs y otros servicios\
\
&#x20;   1.8. Casos de uso: transacciones comerciales, IoT, monitoreo, registros y eventos de aplicaciones

### Parte II. Operación, integración e implementación de Apache Kafka

2.1. Preparación y verificación de Kafka en el entorno Docker\
\
&#x20;   2.2. Administración de tópicos, particiones y configuración básica\
\
&#x20;   2.3. Publicación de eventos mediante productores\
\
&#x20;   2.4. Consumo de eventos y funcionamiento de los grupos de consumidores\
\
&#x20;   2.5. Estructuración de mensajes: texto, JSON, claves y marcas temporales\
\
&#x20;   2.6. Integración con fuentes externas: archivos, bases de datos y APIs REST\
\
&#x20;   2.7. Construcción de un productor que consulta una API y publica eventos en Kafka\
\
&#x20;   2.8. Implementación de flujos en tiempo real y Near Real-Time\
\
&#x20;   2.9. Integración de Kafka con Apache Spark Structured Streaming\
\
&#x20;   2.10. Validación, monitoreo y tratamiento básico de errores

## 1.1. Del procesamiento batch al procesamiento de eventos

### 1.1.1. El punto de partida: lo que ya conocemos

Durante las semanas anteriores hemos trabajado con tecnologías que permiten almacenar, organizar, consultar y procesar grandes volúmenes de información. En particular, hemos utilizado HDFS, Apache Hive y Apache Spark dentro de una infraestructura desplegada mediante Docker.

Cada una de estas tecnologías cumple una función específica:

- HDFS permite almacenar archivos de manera distribuida.
- Apache Hive proporciona mecanismos para organizar y consultar datos estructurados mediante SQL.
- Apache Spark permite ejecutar operaciones de transformación y análisis sobre grandes conjuntos de datos.

En las actividades realizadas hasta ahora, los datos generalmente se encontraban disponibles antes de comenzar su procesamiento. Por ejemplo, disponíamos de un archivo CSV con registros de ventas, lo almacenábamos en HDFS y posteriormente utilizábamos Spark para analizarlo.

Este enfoque corresponde al procesamiento por lotes, conocido habitualmente como batch processing.

Figura 1. Flujo de procesamiento batch conocido por los estudiantes

![Figura 1: Flujo de procesamiento batch conocido por los estudiantes](kafka_figuras/svg/figura_01.svg)

En este modelo, Spark puede leer el archivo, aplicar filtros, agrupar registros, calcular indicadores y almacenar los resultados nuevamente en HDFS, por ejemplo, utilizando Parquet.

El procesamiento batch continúa siendo fundamental en las organizaciones. Se utiliza para generar informes periódicos, consolidar información histórica, ejecutar procesos de transformación y analizar grandes volúmenes de datos.

Sin embargo, no todas las necesidades de información pueden resolverse esperando a que se complete un archivo o a que se ejecute un proceso programado.

### 1.1.2. ¿Qué ocurre cuando los datos se generan continuamente?

Consideremos una empresa comercializadora que registra las ventas de sus sucursales.

En nuestro trabajo anterior, el análisis comenzaba con un archivo que contenía las transacciones registradas durante un período determinado.

Ahora imaginemos una situación diferente: cada vez que una sucursal realiza una venta, su sistema genera inmediatamente un nuevo registro.

Las transacciones podrían producirse de la siguiente manera:

| Hora     | Ciudad     | Categoría  | Monto    |
| -------- | ---------- | ---------- | -------- |
| 10:00:01 | Santiago   | Tecnología | $245.000 |
| 10:00:03 | Valparaíso | Hogar      | $89.000  |
| 10:00:04 | Concepción | Tecnología | $410.000 |
| 10:00:07 | Santiago   | Vestuario  | $56.000  |

Estos registros ya no representan necesariamente un archivo terminado. Constituyen una secuencia de acontecimientos que ocurren a lo largo del tiempo.

La empresa podría necesitar responder preguntas como: ¿cuántas ventas se están realizando en este momento?, ¿qué sucursal registra un aumento inesperado de transacciones?, ¿se están produciendo operaciones que requieren revisión?

Si la organización espera hasta el final del día para consolidar y procesar todos los registros, sus respuestas llegarán demasiado tarde para determinadas decisiones operativas.

Surge así una nueva necesidad: recibir y utilizar los datos mientras se generan, sin esperar a que finalice un período de recopilación.

### 1.1.3. Del registro almacenado al evento

Para comprender esta transición necesitamos introducir un concepto fundamental: el evento.

Un evento representa un hecho que ha ocurrido en un sistema y que puede resultar relevante para otras aplicaciones o procesos.

Por ejemplo:

- Se registró una venta.
- Un cliente realizó una compra.
- Un sensor informó una temperatura.
- Un usuario inició sesión.
- Una aplicación detectó un error.

En el caso de nuestra comercializadora, una venta puede representarse mediante un mensaje estructurado:

```
{
  "id_venta": "V10025",
  "fecha": "2026-10-28T10:00:01",
  "ciudad": "Santiago",
  "categoria": "Tecnologia",
  "monto": 245000
}
```

Este mensaje contiene información sobre un acontecimiento específico. El formato JSON permite representar los datos mediante pares de clave y valor, y es habitual en la comunicación entre aplicaciones y servicios.

Observemos una diferencia importante:

En el procesamiento batch, normalmente trabajamos con un conjunto de registros que ya se encuentra disponible.

En el procesamiento de eventos, los registros pueden llegar individualmente y de manera continua, a medida que ocurren los acontecimientos que representan.

Esto no significa que los datos dejen de almacenarse. Significa que ahora podemos incorporarlos a un flujo de información antes de consolidarlos en archivos o tablas históricas.

### 1.1.4. ¿Por qué necesitamos una nueva arquitectura?

Supongamos que la empresa comercializadora cuenta con tres sistemas interesados en recibir las nuevas transacciones:

1. Un sistema de monitoreo que necesita actualizar sus indicadores.
2. Un sistema de detección de operaciones anómalas.
3. Un sistema de almacenamiento que conserva las transacciones para análisis históricos.

Una alternativa sería conectar directamente el sistema de ventas con cada una de estas aplicaciones.

Sin embargo, a medida que aumenta la cantidad de sistemas, también crece la complejidad de sus conexiones. Una interrupción en una aplicación receptora podría afectar la comunicación, dependiendo de cómo se haya implementado la integración.

Una arquitectura orientada a eventos introduce un componente intermediario que permite desacoplar la generación de información de su consumo.

Figura 2. Distribución de eventos hacia múltiples sistemas

![Figura 2: Distribución de eventos hacia múltiples sistemas](kafka_figuras/svg/figura_02.svg)

Representación conceptual de una arquitectura orientada a eventos. La plataforma permite distribuir información a distintos consumidores.

En esta arquitectura, el sistema de ventas produce eventos y los publica en una plataforma común. Los sistemas interesados pueden consumirlos de acuerdo con sus propias necesidades.

Este mecanismo facilita el desacoplamiento: el productor no necesita conocer directamente todos los sistemas que utilizarán los eventos, y cada consumidor puede desarrollar su lógica de procesamiento de manera independiente.

Apache Kafka es una tecnología diseñada precisamente para apoyar este tipo de arquitectura.

### 1.1.5. ¿El procesamiento de eventos reemplaza al procesamiento batch?

No. Ambos enfoques responden a necesidades diferentes y pueden complementarse.

| Aspecto               | Procesamiento batch                | Procesamiento de eventos               |
| --------------------- | ---------------------------------- | -------------------------------------- |
| Entrada               | Conjunto de datos disponible       | Eventos que llegan progresivamente     |
| Ejecución             | Por lotes o programación periódica | Continua o activada por nuevos eventos |
| Propósito habitual    | Consolidación y análisis histórico | Reacción y actualización oportuna      |
| Ejemplo               | Ventas totales del mes             | Nuevas ventas conforme se registran    |
| Tecnologías del curso | HDFS, Hive y Spark                 | Kafka, integrado con otros componentes |

Es importante señalar que Spark también puede trabajar con datos en streaming. Por lo tanto, la diferencia no consiste en que Spark sea exclusivamente batch y Kafka exclusivamente tiempo real.

Kafka permite transportar, almacenar temporalmente según políticas de retención y distribuir eventos; Spark puede encargarse de procesarlos y analizarlos.

Por ejemplo, una arquitectura integrada podría recibir transacciones mediante Kafka, procesarlas utilizando Spark y almacenar resultados en HDFS para su posterior consulta.

De esta manera, las tecnologías que ya conocemos no desaparecen: adquieren nuevas posibilidades de integración.

### 1.1.6. Síntesis del apartado

Hasta ahora hemos aprendido a trabajar con información que se encuentra almacenada. HDFS, Hive y Spark nos han permitido construir procesos de consulta, transformación y análisis de datos.

Sin embargo, muchas organizaciones necesitan incorporar información que se produce continuamente, como transacciones comerciales, eventos de aplicaciones, registros de sensores o interacciones de usuarios.

El procesamiento orientado a eventos responde a esta necesidad mediante arquitecturas capaces de recibir y distribuir información a medida que se genera.

Apache Kafka será la tecnología que estudiaremos para comprender cómo se implementa esta nueva forma de trabajar con los datos y cómo puede integrarse con la infraestructura Big Data que ya conocemos.

## 1.2. Historia, origen y evolución de Apache Kafka

### 1.2.1. El contexto tecnológico que dio origen a Kafka

Para comprender el surgimiento de Apache Kafka debemos situarnos a finales de la década de 2000, cuando las grandes plataformas digitales comenzaron a experimentar un crecimiento acelerado en la cantidad de información generada por sus usuarios.

Durante ese período, servicios como redes sociales, plataformas de comercio electrónico y aplicaciones web producían continuamente registros de actividad. Cada interacción podía generar información: una búsqueda, una visita a una página, un inicio de sesión, una compra o un mensaje enviado.

Esta situación planteó un desafío importante para las arquitecturas tradicionales de procesamiento de datos.

Los sistemas informáticos necesitaban gestionar simultáneamente dos necesidades:

- Almacenar y analizar información histórica, para elaborar informes, identificar tendencias y apoyar decisiones.
- Capturar y distribuir información reciente, para alimentar aplicaciones que necesitaban conocer los acontecimientos sin esperar a que finalizara un proceso de recopilación.

El problema no era únicamente el volumen de datos. También importaban la velocidad con que se generaban y la necesidad de distribuirlos entre diferentes aplicaciones.

Por ejemplo, una plataforma digital podía necesitar enviar los registros de actividad de sus usuarios hacia sistemas de monitoreo, motores de recomendación, herramientas analíticas y repositorios históricos.

Si cada sistema debía conectarse directamente con todos los demás, la arquitectura aumentaba progresivamente su complejidad.

Este contexto favoreció el desarrollo de tecnologías especializadas en el transporte y distribución de flujos de información.

### 1.2.2. El nacimiento de Kafka en LinkedIn

[The Scaling Journey of LinkedIn - ByteByteGo Newsletter](https://images.openai.com/static-rsc-4/zYscGS-6qGAc2oi__XRnPbJ62QBauRN-jnVvqgumqlaABLKCL-zHUr42y-J9y_i6uZeiOndkKlzj6sW0VIk4J7owjBPaIxGhlKuGAz622jkU4qrGOimCdyU_tcAKqfGgbtZemQyKwnh_QQCqGcWFDjuyKSTJdyBQz6fxLz7qxPM?purpose=inline)

Apache Kafka surgió en LinkedIn, la red social orientada al ámbito profesional.

Alrededor de 2010, sus ingenieros necesitaban una infraestructura capaz de recopilar y distribuir grandes cantidades de eventos generados por la actividad de los usuarios y los sistemas internos.

LinkedIn utilizaba diferentes aplicaciones, bases de datos y sistemas de análisis. Cada uno producía información que podía resultar útil para otros componentes de la plataforma.

Sin embargo, integrar estos sistemas mediante conexiones individuales generaba dificultades de mantenimiento, escalabilidad y confiabilidad.

El equipo de ingeniería buscaba construir un mecanismo que permitiera recibir continuamente información desde múltiples fuentes y ponerla a disposición de diferentes consumidores.

La solución debía cumplir varios requisitos:

1. Alto rendimiento: admitir grandes cantidades de mensajes sin convertirse en un cuello de botella.
2. Escalabilidad horizontal: aumentar la capacidad incorporando nuevos servidores.
3. Persistencia: conservar los eventos durante un período determinado para permitir su recuperación.
4. Desacoplamiento: evitar que los sistemas productores dependieran directamente de cada aplicación consumidora.
5. Procesamiento distribuido: aprovechar varios nodos para gestionar grandes flujos de información.

El resultado fue Apache Kafka, desarrollado inicialmente por Jay Kreps, Neha Narkhede y Jun Rao.

Kafka fue publicado como proyecto de código abierto en 2011 y posteriormente pasó a formar parte del ecosistema de la Apache Software Foundation.

Su nombre proviene del escritor Franz Kafka. La elección respondió principalmente a una preferencia por un nombre breve y distintivo, no a una relación técnica con la literatura.

### 1.2.3. De un sistema interno a una plataforma de código abierto

El desarrollo inicial de Kafka respondía a necesidades concretas de LinkedIn. Sin embargo, los problemas que intentaba resolver no eran exclusivos de esa organización.

Otras empresas también necesitaban conectar aplicaciones, recopilar registros, distribuir eventos y alimentar sistemas de análisis.

La publicación de Kafka como software de código abierto permitió que diferentes organizaciones comenzaran a utilizarlo y contribuir a su evolución.

Figura 3. Principales hitos de la evolución de Apache Kafka

![Figura 3: Principales hitos de la evolución de Apache Kafka](kafka_figuras/svg/figura_03.svg)

1. 2010 — Desarrollo en LinkedIn

   Nace como solución para gestionar flujos de actividad y registros entre sistemas.
2. 2011 — Publicación como código abierto

   Kafka comienza a desarrollarse dentro del ecosistema Apache.
3. 2012 — Proyecto de nivel superior de Apache

   Se consolida como proyecto independiente bajo la Apache Software Foundation.
4. 2016 — Kafka Streams

   Se amplían las capacidades para desarrollar aplicaciones que procesan flujos de eventos.
5. 2017 — Kafka Connect y ecosistema de integración consolidado

   Kafka amplía su adopción como plataforma de integración de datos y eventos.
6. 2023 — Maduración de KRaft

   Kafka incorpora una arquitectura de administración de metadatos que permite operar sin ZooKeeper.
7. 2025 — Kafka 4.0

   ZooKeeper deja de formar parte de la arquitectura soportada y KRaft se convierte en el mecanismo de administración del clúster.

La evolución de Kafka muestra un cambio importante: dejó de ser principalmente una herramienta para transportar registros entre sistemas y pasó a convertirse en una plataforma central para arquitecturas orientadas a eventos.

Actualmente puede utilizarse para integrar aplicaciones, alimentar sistemas analíticos, distribuir transacciones y construir soluciones de procesamiento continuo.

### 1.2.4. La evolución del concepto de mensajería

Antes de Kafka ya existían sistemas de mensajería que permitían comunicar aplicaciones. Entre ellos se encontraban tecnologías basadas en colas de mensajes, donde una aplicación enviaba información y otra la recuperaba.

Kafka incorporó un enfoque particularmente útil para los sistemas de datos: el registro distribuido de eventos, conocido como distributed event log.

Para comprender esta diferencia, imaginemos un sistema de ventas que genera tres transacciones consecutivas.

En un modelo tradicional de cola, un mensaje puede retirarse de la cola después de ser procesado, según el funcionamiento y la configuración del sistema.

En Kafka, los eventos se incorporan a un registro ordenado dentro de cada partición y permanecen almacenados según una política de retención, independientemente de que un consumidor ya los haya leído.

Figura 4. Registro de eventos y lectura mediante offsets

![Figura 4: Registro de eventos y lectura mediante offsets](kafka_figuras/svg/figura_04.svg)

Esta característica permite que distintos consumidores procesen los mismos eventos de manera independiente.

Por ejemplo, un sistema de monitoreo puede consumir las transacciones recientes, mientras otro sistema analiza las mismas transacciones para detectar patrones de comportamiento.

También es posible volver a leer eventos anteriores, siempre que continúen disponibles según la configuración de retención.

Este mecanismo constituye una de las principales diferencias conceptuales entre Kafka y muchos sistemas tradicionales de mensajería.

### 1.2.5. ZooKeeper y la evolución hacia KRaft

Durante buena parte de su historia, Kafka utilizó Apache ZooKeeper para coordinar determinados aspectos del funcionamiento del clúster.

ZooKeeper era responsable de tareas relacionadas con la coordinación y administración de metadatos, como la información de los brokers y determinados procesos de elección de controladores.

Esto significaba que una instalación tradicional de Kafka requería dos componentes diferenciados:

- Los servidores Kafka, encargados de almacenar y distribuir eventos.
- ZooKeeper, utilizado para determinadas funciones de coordinación.

Con el tiempo, esta dependencia comenzó a representar una complejidad adicional para la administración de las instalaciones.

Para resolverla, Kafka desarrolló KRaft (Kafka Raft), un mecanismo que permite administrar los metadatos del clúster sin depender de ZooKeeper.

Arquitectura tradicional

ZooKeeper

Coordinación

Kafka Brokers

Eventos y particiones

Arquitectura KRaft

Controladores KRaft

Metadatos del clúster

Kafka Brokers

Eventos y particiones

La transición hacia KRaft es relevante porque simplifica la arquitectura y reduce la dependencia de componentes externos para la administración del clúster.

Sin embargo, existe un aspecto importante para nuestro curso.

Nuestra infraestructura Docker actual todavía utiliza Kafka con ZooKeeper.

En el repositorio `juliopez/Hadoop`, el archivo `docker-compose.yml` define ambos servicios, incluyendo la conexión de Kafka con ZooKeeper mediante:

```
KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
```

Por lo tanto, aunque estudiaremos la evolución hacia KRaft, los ejemplos operativos deberán considerar inicialmente la infraestructura disponible.

Esto permitirá comprender tanto la arquitectura tradicional que utilizamos en el laboratorio como el modelo moderno que caracteriza a las versiones recientes de Kafka.

### 1.2.6. Kafka y la evolución de las arquitecturas Big Data

El surgimiento de Kafka también puede entenderse como parte de una transformación más amplia de las arquitecturas de datos.

Durante muchos años, las organizaciones concentraron sus esfuerzos en almacenar grandes volúmenes de información y procesarlos posteriormente.

Tecnologías como Hadoop y HDFS permitieron desarrollar soluciones distribuidas para almacenar información a gran escala.

Posteriormente, herramientas como Hive y Spark facilitaron su consulta y procesamiento.

Kafka agregó una capacidad complementaria: incorporar continuamente los eventos generados por los sistemas operacionales.

En una arquitectura integrada, estas tecnologías pueden desempeñar funciones diferentes:

| Componente | Función principal                                        |
| ---------- | -------------------------------------------------------- |
| Kafka      | Recibir, almacenar según retención y distribuir eventos  |
| Spark      | Procesar y transformar datos, tanto batch como streaming |
| HDFS       | Almacenar conjuntos de datos de manera distribuida       |
| Hive       | Organizar y consultar datos estructurados                |

Por ejemplo, una empresa podría utilizar Kafka para recibir nuevas transacciones comerciales y Spark para procesarlas. Posteriormente, los resultados podrían almacenarse en HDFS y consultarse mediante Hive.

De esta manera, Kafka no reemplaza las tecnologías anteriores, sino que contribuye a conectar los sistemas que producen información con aquellos que la procesan y almacenan.

### 1.2.7. Síntesis del apartado

Apache Kafka surgió como respuesta a los desafíos que enfrentaban las grandes plataformas digitales al necesitar capturar y distribuir información generada continuamente.

Su desarrollo en LinkedIn permitió construir una infraestructura de eventos distribuida, escalable y capaz de atender múltiples consumidores.

Desde su publicación como software de código abierto, Kafka evolucionó hacia una plataforma ampliamente utilizada en arquitecturas orientadas a eventos, incorporando nuevas capacidades y modernizando su funcionamiento interno.

Para nuestro curso, comprender esta evolución resulta importante porque permite identificar el lugar que ocupa Kafka dentro del ecosistema Big Data y su relación con las tecnologías ya estudiadas.

El siguiente paso será analizar qué es exactamente Apache Kafka, cuáles son sus capacidades y qué problemas concretos permite resolver.

## 1.3. ¿Qué es Apache Kafka y qué problemas resuelve?

### 1.3.1. Definición de Apache Kafka

Apache Kafka es una plataforma distribuida de transmisión de eventos (event streaming) que permite publicar, almacenar y consumir flujos de información de manera continua.

Para comprender esta definición, debemos examinar tres de sus características fundamentales.

Es una plataforma distribuida: puede utilizar varios servidores que trabajan coordinadamente para almacenar y distribuir eventos. Esto permite aumentar su capacidad y disponibilidad a medida que crecen las necesidades de una organización.

Está orientada a eventos: trabaja con mensajes que representan acontecimientos producidos en aplicaciones, dispositivos o sistemas informáticos. Por ejemplo, una compra realizada, una temperatura registrada o una operación bancaria.

Permite transmitir información continuamente: los sistemas productores pueden publicar eventos a medida que ocurren, mientras que los sistemas consumidores pueden recuperarlos y utilizarlos sin esperar a que se genere un archivo completo.

Esta última característica introduce una diferencia importante respecto del procesamiento batch que hemos estudiado durante las semanas anteriores.

Cuando utilizábamos Spark para procesar un archivo CSV almacenado en HDFS, normalmente trabajábamos con un conjunto de registros previamente disponible. Con Kafka podemos construir una arquitectura en la que los nuevos registros se incorporan continuamente al sistema.

Sin embargo, Kafka no sustituye a Spark, HDFS ni Hive. Su función principal es facilitar el flujo de eventos entre los sistemas que generan información y aquellos que necesitan utilizarla.

### 1.3.2. ¿Qué significa transmitir eventos?

En informática, un evento representa un hecho ocurrido en un momento determinado.

Por ejemplo, imaginemos que una empresa comercializadora utiliza un sistema de ventas conectado a sus distintas sucursales.

Cada vez que se realiza una transacción, el sistema genera información sobre la operación:

```
{
  "id_venta": "V10026",
  "fecha": "2026-10-28T10:15:32",
  "sucursal": "Santiago Centro",
  "producto": "Notebook",
  "cantidad": 1,
  "monto": 650000
}
```

Este mensaje representa un acontecimiento: la realización de una venta.

En una arquitectura tradicional, estos registros podrían almacenarse en una base de datos y exportarse posteriormente a un archivo para su procesamiento.

En una arquitectura basada en Kafka, el sistema de ventas puede publicar el evento inmediatamente después de producirse.

Otros sistemas pueden entonces consumir esa información para diferentes propósitos.

Figura 5. Transmisión de un evento comercial

![Figura 5: Transmisión de un evento comercial](kafka_figuras/svg/figura_05.svg)

Un mismo evento puede ser utilizado por distintos sistemas, sin que el productor deba establecer una conexión específica con cada uno.

En este ejemplo, el sistema de monitoreo podría actualizar un indicador de ventas, Spark podría ejecutar transformaciones sobre los eventos y otro consumidor podría conservar la información para análisis históricos.

La ventaja es que cada sistema puede utilizar los eventos de acuerdo con sus necesidades.

Es importante comprender que Kafka no realiza automáticamente todos estos análisis. Kafka permite que los eventos estén disponibles; las aplicaciones consumidoras se encargan de interpretarlos y procesarlos.

### 1.3.3. Primer problema: la integración entre múltiples sistemas

Uno de los principales desafíos que resuelve Kafka es la comunicación entre aplicaciones.

Supongamos que una organización dispone de cuatro sistemas que generan información:

- Un sistema de ventas.
- Una plataforma de comercio electrónico.
- Una aplicación de inventario.
- Un sistema de atención al cliente.

Además, dispone de varias aplicaciones que necesitan utilizar esos datos: monitoreo, análisis, almacenamiento y generación de alertas.

Si cada productor debe comunicarse directamente con cada consumidor, el número de conexiones puede crecer rápidamente.

Figura 6. Integración mediante conexiones directas

![Figura 6: Integración mediante conexiones directas](kafka_figuras/svg/figura_06.svg)

Ejemplo conceptual: múltiples integraciones punto a punto entre productores y consumidores.

Figura 7. Integración mediante Apache Kafka

![Figura 7: Integración mediante Apache Kafka](kafka_figuras/svg/figura_07.svg)

Los sistemas intercambian eventos mediante una plataforma común, reduciendo las dependencias directas.

Kafka permite reducir este acoplamiento porque los productores publican eventos en tópicos y los consumidores los recuperan desde esos tópicos.

Un tópico puede entenderse inicialmente como una categoría o flujo identificado por un nombre. Por ejemplo, podríamos tener un tópico llamado `ventas`, donde se publican las transacciones comerciales.

En el apartado 1.4 estudiaremos con mayor profundidad este concepto.

### 1.3.4. Segundo problema: el crecimiento del volumen de información

Las organizaciones no generan siempre la misma cantidad de eventos.

Una empresa comercializadora podría registrar cientos de transacciones por hora durante un día normal, pero experimentar un aumento considerable durante una campaña de descuentos.

En ese escenario, los sistemas deben ser capaces de recibir y distribuir una mayor cantidad de mensajes.

Kafka fue diseñado para trabajar con grandes flujos de eventos y permitir el crecimiento de la infraestructura mediante la incorporación de servidores.

Este enfoque se denomina escalabilidad horizontal.

A diferencia de la escalabilidad vertical, que consiste en aumentar los recursos de un único servidor, la escalabilidad horizontal distribuye el trabajo entre varios servidores.

| Escalabilidad vertical                        | Escalabilidad horizontal                                |
| --------------------------------------------- | ------------------------------------------------------- |
| Aumentar memoria RAM o CPU de un servidor     | Incorporar servidores adicionales                       |
| Depende de la capacidad máxima de una máquina | Permite distribuir la carga                             |
| Puede ser suficiente para sistemas pequeños   | Resulta útil para sistemas distribuidos de mayor escala |

Kafka utiliza mecanismos como las particiones para distribuir los datos y facilitar su procesamiento paralelo.

No obstante, agregar servidores no garantiza por sí solo un aumento automático del rendimiento. La distribución de particiones, la configuración y las características de los productores y consumidores también influyen en la capacidad efectiva.

### 1.3.5. Tercer problema: conservar los eventos para diferentes consumidores

Una característica especialmente importante de Kafka es que los eventos publicados pueden permanecer almacenados durante un período configurable.

Esto permite que un consumidor recupere información aunque no haya estado conectado exactamente en el momento en que se produjo el evento.

Volvamos al caso de las ventas.

Supongamos que a las 10:00 se registra una transacción, pero la aplicación encargada de generar indicadores se encuentra temporalmente detenida.

Si el evento permanece disponible en Kafka, la aplicación podrá recuperarlo posteriormente, de acuerdo con su posición de lectura y las políticas de retención configuradas.

Además, diferentes consumidores pueden leer los mismos eventos de forma independiente.

Por ejemplo:

- Un consumidor actualiza indicadores comerciales.
- Otro identifica transacciones sospechosas.
- Un tercero envía los registros hacia un sistema de almacenamiento histórico.

Esto no significa que Kafka conserve indefinidamente todos los mensajes. La duración y las condiciones de almacenamiento dependen de su configuración.

Tampoco significa que Kafka reemplace a HDFS como repositorio histórico. Ambas tecnologías tienen propósitos diferentes y pueden utilizarse conjuntamente.

### 1.3.6. Cuarto problema: la necesidad de información oportuna

En determinados procesos, disponer de información varias horas después de que se produce puede ser insuficiente.

Consideremos los siguientes ejemplos:

| Situación                                            | Necesidad de información                    |
| ---------------------------------------------------- | ------------------------------------------- |
| Informe mensual de ventas                            | Procesamiento periódico                     |
| Actualización de ventas durante una jornada          | Información cada pocos segundos             |
| Detección de operaciones potencialmente fraudulentas | Respuesta con muy baja latencia             |
| Monitoreo de temperatura industrial                  | Recepción continua de mediciones            |
| Análisis histórico de clientes                       | Consolidación de grandes volúmenes de datos |

Kafka permite construir sistemas en los que los eventos se transmiten continuamente, pero debemos distinguir entre la velocidad con que se transportan y el tiempo total que tarda una aplicación en producir una respuesta.

Este último depende de toda la arquitectura: la fuente de datos, el productor, Kafka, el consumidor, el procesamiento y el sistema que presenta o almacena los resultados.

Por tanto, utilizar Kafka no garantiza automáticamente que una solución funcione en tiempo real estricto.

Esta distinción será especialmente importante cuando estudiemos las implementaciones real-time y Near Real-Time en el apartado 1.6.

### 1.3.7. ¿Qué puede hacer Kafka y qué no hace por sí solo?

Para evitar confusiones, resulta conveniente identificar sus capacidades y limitaciones.

| Kafka permite                                  | Kafka no realiza automáticamente                                 |
| ---------------------------------------------- | ---------------------------------------------------------------- |
| Recibir eventos desde aplicaciones productoras | Consultar cualquier API REST sin un componente de integración    |
| Publicar y distribuir eventos mediante tópicos | Ejecutar consultas SQL como Hive                                 |
| Almacenar eventos según políticas de retención | Reemplazar un repositorio histórico como HDFS                    |
| Permitir múltiples consumidores independientes | Construir dashboards o visualizaciones                           |
| Facilitar arquitecturas de streaming           | Ejecutar todos los análisis y transformaciones que realiza Spark |

Existen herramientas complementarias dentro del ecosistema Kafka, como Kafka Connect y Kafka Streams, que amplían las posibilidades de integración y procesamiento.

Sin embargo, debemos distinguir la función del broker Kafka de las capacidades de esos componentes adicionales.

Por ejemplo, para consumir datos de una API REST podríamos desarrollar una aplicación Python que consulte periódicamente el servicio y publique los resultados en Kafka.

También podríamos utilizar una herramienta de integración como Apache NiFi, que ya forma parte de nuestra infraestructura Docker.

En ambos casos, Kafka recibe los eventos publicados por un componente externo; no es el broker quien realiza directamente la solicitud HTTP a la API.

### 1.3.8. Kafka dentro de nuestra infraestructura Big Data

En el repositorio [juliopez/Hadoop](https://github.com/juliopez/Hadoop) disponemos de una arquitectura que integra Hadoop/HDFS, Hive, Spark, Kafka y otros servicios.

Hasta ahora hemos utilizado principalmente HDFS, Hive y Spark para trabajar con información almacenada.

La incorporación de Kafka permite extender esa arquitectura hacia el tratamiento de eventos.

Figura 8. Ejemplo conceptual de integración con las tecnologías del curso

![Figura 8: Ejemplo conceptual de integración con las tecnologías del curso](kafka_figuras/svg/figura_08.svg)

Esquema ilustrativo de integración. No implica que todas estas conexiones estén actualmente implementadas en el entorno Docker.

Esta arquitectura puede ampliarse para almacenar resultados en HDFS y posteriormente consultarlos con Hive.

La ventaja pedagógica es que no necesitamos abandonar lo aprendido: utilizaremos Kafka para incorporar una nueva etapa al flujo de datos.

Antes teníamos principalmente:

Archivos → HDFS → Spark → Resultados.

Ahora podremos estudiar una arquitectura más amplia:

Fuentes de eventos → Kafka → Procesamiento → Almacenamiento y análisis.

Ambos modelos pueden coexistir dentro de una misma organización.

### 1.3.9. Síntesis del apartado

Apache Kafka es una plataforma distribuida orientada a la transmisión de eventos que facilita la comunicación entre sistemas productores y consumidores de información.

Su utilización responde a necesidades como la integración de aplicaciones, el manejo de grandes volúmenes de eventos, la disponibilidad de mensajes para diferentes consumidores y la construcción de sistemas que requieren información oportuna.

Su principal aporte consiste en permitir que los acontecimientos generados por diferentes fuentes puedan publicarse, almacenarse durante un período configurable y consumirse de manera independiente.

En nuestro curso, Kafka complementará las capacidades de HDFS, Hive y Spark, permitiéndonos comprender cómo evolucionar desde procesos basados principalmente en archivos hacia arquitecturas que incorporan flujos continuos de información.

## 1.4. Conceptos fundamentales: eventos, productores, consumidores, tópicos y brokers

En el apartado anterior comprendimos qué es Apache Kafka y cuáles son los problemas que permite resolver. Ahora necesitamos conocer los componentes que hacen posible su funcionamiento.

Para ello, utilizaremos un ejemplo que nos acompañará durante el resto del material: una empresa comercializadora que registra ventas en diferentes sucursales y necesita distribuir esa información hacia varios sistemas.

El propósito de este apartado es comprender cómo se comunican los componentes de Kafka y qué función cumple cada uno, antes de estudiar su arquitectura distribuida en mayor profundidad.

### 1.4.1. Una primera aproximación al funcionamiento de Kafka

Imaginemos que una empresa dispone de un sistema informático que registra las transacciones comerciales.

Cada vez que se realiza una venta, el sistema genera información sobre el producto, la sucursal, el monto y la fecha de la operación.

La empresa necesita que esta información esté disponible para diferentes aplicaciones: una plataforma de monitoreo comercial, un sistema de detección de anomalías y un proceso de almacenamiento histórico.

Kafka permite organizar esta comunicación mediante una arquitectura compuesta por tres elementos principales:

- Productores (producers): aplicaciones que envían eventos a Kafka.
- Kafka: plataforma que recibe y almacena los eventos, organizándolos en tópicos.
- Consumidores (consumers): aplicaciones que recuperan los eventos para utilizarlos.

Figura 9. Flujo básico de información en Apache Kafka

![Figura 9: Flujo básico de información en Apache Kafka](kafka_figuras/svg/figura_09.svg)

Esquema simplificado del intercambio de eventos. Kafka actúa como intermediario entre las aplicaciones productoras y consumidoras.

Aunque el esquema parece sencillo, cada componente tiene responsabilidades específicas. Comprenderlas será fundamental para interpretar correctamente los ejemplos y las guías prácticas.

### 1.4.2. Evento: la unidad básica de información

Un evento es un registro que representa un acontecimiento ocurrido en un sistema.

Por ejemplo, cuando una persona compra un producto, el sistema comercial puede generar un evento denominado `venta_realizada`.

Este evento contiene información que describe lo ocurrido:

```
{
  "id_venta": "V10027",
  "fecha": "2026-10-28T11:05:30",
  "sucursal": "Valparaiso",
  "producto": "Monitor",
  "cantidad": 2,
  "monto_total": 320000
}
```

En este ejemplo, podemos identificar los siguientes datos:

| Campo         | Significado                     |
| ------------- | ------------------------------- |
| `id_venta`    | Identificador de la transacción |
| `fecha`       | Momento en que ocurrió la venta |
| `sucursal`    | Lugar donde se registró         |
| `producto`    | Producto comercializado         |
| `cantidad`    | Unidades vendidas               |
| `monto_total` | Valor total de la operación     |

Este contenido se denomina habitualmente payload, es decir, la información transportada por el mensaje.

Sin embargo, un registro de Kafka puede incluir otros elementos además de su contenido: una clave, una marca temporal y encabezados opcionales.

Estos elementos permiten organizar e interpretar los eventos, aunque no siempre es necesario utilizarlos todos.

Un aspecto importante: Kafka no exige que los eventos estén escritos en JSON. Los mensajes se transmiten como datos binarios, y las aplicaciones pueden utilizar diferentes formatos para representar su contenido.

En nuestro curso utilizaremos principalmente JSON porque facilita la lectura y comprensión de los ejemplos.

### 1.4.3. Productor: la aplicación que publica eventos

Un productor (producer) es una aplicación que envía registros a Kafka.

En nuestro caso, el productor podría ser el sistema de ventas de la comercializadora.

Cada vez que se registra una nueva transacción, el productor prepara un mensaje y lo publica en un tópico de Kafka.

La aplicación productora no necesita conocer todos los sistemas que posteriormente utilizarán esa información.

Su responsabilidad principal consiste en publicar correctamente el evento en el destino correspondiente.

Figura 10. Publicación de eventos por un productor

![Figura 10: Publicación de eventos por un productor](kafka_figuras/svg/figura_10.svg)

Un productor puede ser desarrollado utilizando diferentes lenguajes de programación, entre ellos Java, Python, Go o JavaScript.

También puede utilizarse una herramienta de integración de datos para actuar como productor.

Por ejemplo, dentro de nuestra infraestructura Docker disponemos de Apache NiFi, que puede participar en flujos de adquisición y publicación de información.

Más adelante estudiaremos cómo una aplicación Python puede consultar una API REST y publicar sus resultados en Kafka.

#### Ejemplo conceptual de un productor Python

El siguiente fragmento ilustra la lógica de publicación de un evento. No corresponde todavía a una implementación completa ni a un ejercicio de laboratorio.

```
evento = {    "id_venta": "V10027",    "sucursal": "Valparaiso",    "monto_total": 320000}productor.send(    "ventas",    value=evento)
```

La instrucción representa la intención de enviar un evento al tópico `ventas`.

Para que este código funcione realmente, se necesita configurar un cliente Kafka, establecer la conexión con el broker y definir cómo se serializa el mensaje. Estos aspectos se abordarán en la segunda parte del documento.

Lo importante, por ahora, es comprender la relación:

El productor genera o recibe información y la publica en Kafka.

### 1.4.4. Tópico: la organización de los eventos

Un tópico (topic) es una categoría identificada por un nombre en la que Kafka organiza los registros publicados.

Podemos imaginarlo inicialmente como un flujo de información asociado a un propósito determinado.

Por ejemplo, una organización podría disponer de los siguientes tópicos:

| Tópico                 | Información publicada                   |
| ---------------------- | --------------------------------------- |
| `ventas`               | Transacciones comerciales               |
| `inventario`           | Cambios en las existencias de productos |
| `clientes`             | Altas o modificaciones de clientes      |
| `alertas`              | Eventos que requieren atención          |
| `sensores_temperatura` | Mediciones de dispositivos              |

Cuando un productor publica un evento, debe indicar el tópico al que desea enviarlo.

De esta manera, las aplicaciones consumidoras pueden seleccionar los flujos de información que necesitan.

Es importante aclarar que un tópico no es exactamente lo mismo que una tabla de Hive ni un archivo almacenado en HDFS.

Una tabla de Hive permite organizar datos estructurados para consultarlos mediante SQL. Un archivo en HDFS representa información almacenada en un sistema de archivos distribuido.

Un tópico Kafka, en cambio, organiza un registro de eventos que puede recibir nuevas publicaciones continuamente.

Además, un tópico puede dividirse en particiones, que constituyen una característica fundamental de su arquitectura distribuida.

Estudiaremos las particiones con mayor profundidad en el apartado 1.5.

### 1.4.5. Broker: el servidor que almacena y entrega eventos

Un broker es un servidor Kafka encargado de recibir, almacenar y servir registros a los clientes.

Cuando un productor publica un evento, este es enviado a un broker que aloja la partición correspondiente.

Los consumidores se conectan a los brokers para recuperar los registros que necesitan procesar.

Una instalación Kafka puede disponer de un solo broker o de varios brokers trabajando como parte de un clúster.

Un clúster es un conjunto de servidores que colaboran para ofrecer un servicio distribuido.

Figura 11. Representación conceptual de un clúster Kafka

![Figura 11: Representación conceptual de un clúster Kafka](kafka_figuras/svg/figura_11.svg)

Esquema ilustrativo de un clúster de tres brokers. La distribución real depende de las particiones, réplicas y configuración.

En nuestra infraestructura docente, el archivo `docker-compose.yml` define un servicio denominado `kafka`, asociado a un contenedor con el mismo nombre.

Por lo tanto, cuando utilicemos comandos como:

```
docker exec -it kafka bash
```

estaremos ingresando al contenedor donde se ejecuta el servicio Kafka de nuestro laboratorio.

Conviene distinguir dos conceptos: el contenedor Docker es el entorno donde se ejecuta el software; el broker Kafka es el proceso servidor que proporciona el servicio de almacenamiento y distribución de eventos.

En nuestra configuración educativa, el servicio utiliza una imagen que integra herramientas adicionales. Por eso no debemos asumir que todos los archivos o comandos estarán ubicados en las mismas rutas que en otras distribuciones de Kafka.

### 1.4.6. Consumidor: la aplicación que recupera eventos

Un consumidor (consumer) es una aplicación que lee registros desde uno o varios tópicos Kafka.

En nuestro ejemplo, un consumidor podría ser un sistema que necesita calcular las ventas acumuladas durante la jornada.

Otro consumidor podría analizar las transacciones para detectar operaciones anómalas.

Un tercero podría transferir los registros hacia un repositorio histórico.

Todos ellos pueden utilizar eventos publicados en el mismo tópico, siempre que su configuración de consumo lo permita.

Figura 12. Un tópico y múltiples aplicaciones consumidoras

![Figura 12: Un tópico y múltiples aplicaciones consumidoras](kafka_figuras/svg/figura_12.svg)

Una característica relevante es que el consumidor mantiene una posición de lectura respecto de las particiones del tópico.

Esta posición permite identificar hasta qué registro ha avanzado el procesamiento.

Kafka utiliza para ello un identificador denominado offset, que estudiaremos en el siguiente apartado.

Por ahora, basta con comprender que los consumidores no necesitan recibir exclusivamente los eventos en el instante exacto en que son publicados.

Pueden recuperar registros disponibles en Kafka según su configuración y las políticas de retención.

### 1.4.7. ¿Qué ocurre cuando existen varios consumidores?

Consideremos dos situaciones diferentes.

Primera situación: aplicaciones independientes.

El sistema de monitoreo y el sistema de detección de anomalías necesitan analizar todas las ventas.

Cada aplicación puede consumir los eventos de manera independiente utilizando grupos de consumidores diferentes.

Segunda situación: varios procesos de una misma aplicación.

Supongamos que el sistema de monitoreo necesita procesar una gran cantidad de transacciones.

Podría utilizar varios consumidores pertenecientes a un mismo grupo, distribuyendo entre ellos las particiones disponibles.

Esta característica permite organizar el procesamiento paralelo.

Sin embargo, hay una condición importante: dentro de un mismo grupo de consumidores, una partición se asigna normalmente a un solo consumidor activo a la vez.

Por tanto, la cantidad de particiones influye en el paralelismo que puede alcanzarse.

No profundizaremos todavía en estos mecanismos, porque corresponden al apartado 1.5, dedicado a la arquitectura distribuida.

### 1.4.8. Relación entre los componentes de Kafka y las tecnologías conocidas

Para facilitar la comprensión, podemos establecer algunas relaciones con las herramientas estudiadas anteriormente.

| Concepto Kafka | Relación con conocimientos previos                                            |
| -------------- | ----------------------------------------------------------------------------- |
| Evento         | Puede contener datos semejantes a una fila de un archivo CSV                  |
| Productor      | Aplicación que genera o incorpora nuevos registros                            |
| Tópico         | Organiza un flujo de registros, pero no equivale a una tabla Hive             |
| Broker         | Servidor que almacena y entrega registros Kafka                               |
| Consumidor     | Aplicación que recupera información para utilizarla o procesarla              |
| Spark          | Puede actuar como consumidor y procesar eventos recibidos desde Kafka         |
| HDFS           | Puede almacenar datos derivados de eventos mediante un proceso de integración |

Estas relaciones son útiles como punto de partida, pero no deben interpretarse como equivalencias exactas.

Por ejemplo, aunque un evento pueda contener los mismos campos que una fila CSV, su significado dentro de una arquitectura orientada a eventos es diferente: representa un acontecimiento que puede publicarse y consumirse conforme ocurre.

### 1.4.9. Ejemplo integrador: una venta desde su origen hasta su consumo

Reunamos ahora los conceptos estudiados.

Una empresa comercializadora registra una nueva venta de un computador por $650.000.

El sistema comercial genera un evento con los antecedentes de la transacción.

Un productor publica ese evento en el tópico `ventas`.

Kafka recibe el registro mediante el broker que corresponde y lo almacena en la partición seleccionada.

Posteriormente, dos aplicaciones consumidoras utilizan la información.

La primera actualiza un indicador comercial. La segunda conserva el registro para su posterior análisis.

Figura 13. Recorrido de una transacción comercial

![Figura 13: Recorrido de una transacción comercial](kafka_figuras/svg/figura_13.svg)

1. Se produce el acontecimiento.

   Una sucursal registra una venta de $650.000.
2. El productor prepara y publica el evento.

   El sistema comercial envía los datos al tópico `ventas`.
3. Kafka almacena el registro.

   El broker responsable recibe el mensaje en una partición del tópico.
4. Los consumidores recuperan el evento.

   Una aplicación actualiza indicadores y otra prepara su almacenamiento histórico.
5. Los datos pueden integrarse con otras tecnologías.

   Los resultados pueden procesarse mediante Spark y almacenarse en HDFS para posteriores consultas con Hive.

Este ejemplo muestra cómo Kafka se incorpora a una arquitectura Big Data sin reemplazar las herramientas previamente estudiadas.

También permite comprender que la transmisión de eventos constituye una etapa distinta del análisis y almacenamiento de la información.

### 1.4.10. Síntesis del apartado

El funcionamiento de Apache Kafka se comprende inicialmente mediante cinco conceptos fundamentales:

| Concepto   | Función esencial                       |
| ---------- | -------------------------------------- |
| Evento     | Representa un acontecimiento           |
| Productor  | Publica eventos en Kafka               |
| Tópico     | Organiza los registros publicados      |
| Broker     | Recibe, almacena y sirve los registros |
| Consumidor | Recupera eventos para utilizarlos      |

Estos componentes permiten construir sistemas en los que diferentes aplicaciones intercambian información sin establecer conexiones directas entre todos los productores y consumidores.

En nuestro curso utilizaremos estos conceptos para comprender cómo una transacción comercial puede generarse en una aplicación, publicarse en Kafka y posteriormente procesarse o almacenarse mediante otras tecnologías de nuestra infraestructura.

En el siguiente apartado profundizaremos en la arquitectura distribuida de Kafka, incorporando conceptos como particiones, offsets, replicación y grupos de consumidores.

## 1.5. Arquitectura distribuida de Kafka: particiones, offsets, replicación y grupos de consumidores

En el apartado anterior estudiamos los cinco conceptos fundamentales de Apache Kafka: eventos, productores, tópicos, brokers y consumidores. Comprendimos cómo una aplicación puede publicar una transacción comercial y cómo otras aplicaciones pueden recuperar esa información para distintos propósitos.

Sin embargo, todavía debemos responder algunas preguntas importantes:

¿Cómo organiza Kafka miles o millones de eventos? ¿Cómo sabe un consumidor cuáles registros ha leído? ¿Qué sucede si un servidor deja de funcionar? ¿Cómo pueden varios consumidores trabajar simultáneamente?

Para responderlas, necesitamos comprender cuatro mecanismos de su arquitectura distribuida: particiones, offsets, replicación y grupos de consumidores.

Continuaremos utilizando el caso de nuestra empresa comercializadora y estableceremos relaciones con HDFS y Spark, tecnologías que ya conocemos.

### 1.5.1. ¿Por qué Kafka utiliza una arquitectura distribuida?

Imaginemos que nuestra empresa comercializadora comienza con una sola sucursal que genera aproximadamente 100 transacciones diarias.

Un servidor podría recibir y almacenar esos registros sin mayores dificultades.

Ahora supongamos que la empresa crece hasta disponer de 200 sucursales, una plataforma de comercio electrónico y miles de transacciones por minuto.

La cantidad de información aumenta, pero también lo hacen las necesidades de disponibilidad y procesamiento.

Una arquitectura basada exclusivamente en un servidor presenta limitaciones: existe una capacidad máxima de almacenamiento, procesamiento y transferencia de información, además de una dependencia importante respecto de la disponibilidad de esa máquina.

Kafka permite distribuir los registros entre varios servidores, denominados brokers, que trabajan como parte de un clúster.

Este enfoque nos resulta familiar porque HDFS también utiliza una arquitectura distribuida. No obstante, sus mecanismos y objetivos específicos son diferentes.

| Aspecto                | HDFS                                   | Apache Kafka                             |
| ---------------------- | -------------------------------------- | ---------------------------------------- |
| Unidad de organización | Archivos y bloques                     | Tópicos, particiones y registros         |
| Distribución           | Bloques entre DataNodes                | Particiones entre brokers                |
| Replicación            | Copias de bloques                      | Réplicas de particiones                  |
| Propósito principal    | Almacenamiento distribuido de archivos | Almacenamiento y distribución de eventos |
| Acceso habitual        | Lectura y escritura de archivos        | Publicación y consumo de registros       |

La comparación nos ayuda a comprender la idea general de distribución, pero una partición Kafka no equivale a un bloque HDFS. Sus mecanismos de lectura, escritura y organización son distintos.

### 1.5.2. Particiones: cómo se organiza un tópico

En el apartado anterior definimos un tópico como un flujo de registros identificado por un nombre.

Ahora debemos agregar una característica esencial: cada tópico se divide en una o más particiones.

Una partición es una secuencia ordenada de registros que Kafka almacena de manera incremental.

Por ejemplo, el tópico `ventas` podría estar dividido en tres particiones.

Figura 14. Tópico `ventas` organizado en tres particiones

![Figura 14: Tópico `ventas` organizado en tres particiones](kafka_figuras/svg/figura_14.svg)

Representación simplificada. Los eventos de una partición mantienen su propio orden; no existe necesariamente un orden global entre todas las particiones.

En la figura, cada partición contiene cuatro eventos.

La partición 0 almacena los eventos E1 a E4; la partición 1 contiene E5 a E8; y la partición 2 almacena E9 a E12.

Los identificadores E1 a E12 son únicamente ilustrativos. No representan el orden temporal global en que se produjeron todas las ventas.

Esta distinción es importante: Kafka garantiza el orden de los registros dentro de cada partición, pero no establece automáticamente un orden total entre las diferentes particiones de un tópico.

#### ¿Para qué sirven las particiones?

Las particiones cumplen principalmente dos funciones.

Distribuir la información. Un tópico puede tener sus particiones alojadas en diferentes brokers, evitando que toda su carga dependa de un único servidor.

Facilitar el procesamiento paralelo. Distintos consumidores pertenecientes a un mismo grupo pueden procesar particiones diferentes de manera simultánea.

Esto permite aumentar la capacidad de una aplicación cuando crece el volumen de eventos.

Sin embargo, aumentar la cantidad de particiones también introduce costos de administración y puede modificar las características de distribución y orden de los registros.

Por eso, la cantidad de particiones debe responder a las necesidades del sistema y no elegirse simplemente buscando el número más alto posible.

### 1.5.3. ¿Cómo decide Kafka a qué partición enviar un evento?

Cuando un productor publica un registro, Kafka necesita determinar la partición de destino.

Una posibilidad es que el productor indique explícitamente la partición.

Otra consiste en utilizar una clave (key), que permite asociar determinados eventos con una misma partición.

Volvamos a nuestra empresa comercializadora.

Supongamos que necesitamos conservar el orden de las operaciones realizadas en cada sucursal.

Podríamos utilizar el identificador de sucursal como clave:

```
{
  "id_venta": "V10028",
  "id_sucursal": "SUC-015",
  "producto": "Teclado",
  "monto": 45000
}
```

Si utilizamos `SUC-015` como clave y mantenemos una estrategia de particionamiento estable, los registros con esa misma clave se dirigirán normalmente a la misma partición.

Esto permite conservar el orden de los eventos asociados a esa sucursal dentro de dicha partición.

Figura 15. Distribución ilustrativa mediante claves

![Figura 15: Distribución ilustrativa mediante claves](kafka_figuras/svg/figura_15.svg)

No debemos interpretar que Kafka asigna automáticamente una partición distinta a cada sucursal. Diferentes claves pueden terminar en una misma partición, y la distribución depende de la estrategia de particionamiento utilizada.

Además, cambiar la cantidad de particiones puede modificar el destino de nuevos registros asociados a una misma clave.

Cuando un productor no proporciona una clave, el cliente Kafka utiliza su estrategia de particionamiento correspondiente, que puede variar según la versión y la biblioteca empleada.

### 1.5.4. Offset: la posición de un registro dentro de una partición

Cada registro almacenado en una partición recibe un identificador numérico denominado offset.

El offset representa la posición del registro dentro de esa partición.

Por ejemplo:

| Partición | Offset | Evento       |
| --------- | ------ | ------------ |
| 0         | 0      | Venta V10028 |
| 0         | 1      | Venta V10029 |
| 0         | 2      | Venta V10030 |
| 1         | 0      | Venta V10031 |
| 1         | 1      | Venta V10032 |

Observemos que los offsets de la partición 0 y la partición 1 comienzan independientemente.

Por lo tanto, un offset no identifica por sí solo un evento dentro de todo Kafka. Para localizar un registro es necesario considerar, como mínimo, su tópico, partición y offset.

Figura 16. Offsets dentro de una partición

![Figura 16: Offsets dentro de una partición](kafka_figuras/svg/figura_16.svg)

#### ¿Por qué son importantes los offsets?

Los offsets permiten que los consumidores administren su avance de lectura.

Supongamos que una aplicación ha procesado los primeros 100 registros de una partición y posteriormente se detiene.

Al reiniciarse, puede utilizar la posición registrada para continuar desde el punto correspondiente, sin necesidad de comenzar siempre desde el primer evento.

También puede configurarse para leer registros anteriores, siempre que estos continúen disponibles según la política de retención.

Debemos distinguir dos conceptos:

- Offset del registro: posición asignada por Kafka a un evento dentro de una partición.
- Offset confirmado (committed offset): posición que un grupo de consumidores registra para indicar desde dónde deberá reanudar su consumo.

Esta distinción es importante porque leer un mensaje no implica necesariamente que su procesamiento haya finalizado correctamente.

El momento en que se confirma el offset influye en el comportamiento del sistema frente a fallos y posibles reprocesamientos.

### 1.5.5. Replicación: protección frente a fallos

Hasta ahora hemos explicado cómo Kafka distribuye los registros entre particiones.

Pero surge otra pregunta: ¿qué ocurre si el broker que almacena una partición deja de funcionar?

Kafka incorpora un mecanismo denominado replicación, que permite mantener copias de una partición en distintos brokers.

Cada partición tiene una réplica líder y puede disponer de réplicas adicionales.

La réplica líder es responsable de atender las operaciones ordinarias de lectura y escritura de esa partición. Las réplicas seguidoras mantienen copias de sus registros.

Figura 17. Replicación de una partición entre tres brokers

![Figura 17: Replicación de una partición entre tres brokers](kafka_figuras/svg/figura_17.svg)

Ejemplo con factor de replicación 3. La cantidad de réplicas debe ser compatible con los brokers disponibles.

El número de copias configuradas se denomina factor de replicación.

Por ejemplo:

| Factor de replicación | Significado                      |
| --------------------- | -------------------------------- |
| 1                     | Una sola copia de cada partición |
| 2                     | Dos copias de cada partición     |
| 3                     | Tres copias de cada partición    |

Si un broker deja de estar disponible, Kafka puede elegir una réplica elegible para asumir el liderazgo y continuar atendiendo las operaciones.

No obstante, la disponibilidad y la protección frente a pérdida de datos dependen de aspectos como la sincronización de las réplicas, las confirmaciones exigidas al productor y la configuración del clúster.

Por ello, la replicación reduce riesgos, pero no constituye por sí sola una garantía absoluta contra toda pérdida de información.

#### Relación con HDFS

Este mecanismo presenta una semejanza conceptual con HDFS.

En HDFS estudiamos que los bloques de un archivo pueden replicarse entre diferentes DataNodes para aumentar la tolerancia a fallos.

Kafka utiliza también la replicación, pero la aplica a las particiones de sus tópicos.

La finalidad general es semejante: evitar que la falla de una máquina implique necesariamente la pérdida o indisponibilidad de la información.

Sin embargo, las unidades de almacenamiento y los mecanismos internos son distintos.

### 1.5.6. Grupos de consumidores: procesamiento colaborativo

Un grupo de consumidores (consumer group) es un conjunto de consumidores que colaboran para leer y procesar los registros de uno o varios tópicos.

Cada grupo se identifica mediante un nombre o identificador denominado `group.id`.

Para comprender su funcionamiento, imaginemos que nuestra empresa registra miles de ventas por minuto y necesita calcular indicadores comerciales.

Un único consumidor podría no disponer de suficiente capacidad para procesar todos los eventos a la velocidad requerida.

Una alternativa consiste en utilizar varios consumidores pertenecientes al mismo grupo.

Kafka distribuye las particiones del tópico entre los miembros del grupo, de modo que cada partición sea procesada por un solo consumidor activo del grupo en un momento determinado.

Figura 18. Distribución de particiones dentro de un grupo de consumidores

![Figura 18: Distribución de particiones dentro de un grupo de consumidores](kafka_figuras/svg/figura_18.svg)

Ejemplo con tres particiones y tres consumidores pertenecientes al mismo grupo.

En este escenario, cada consumidor procesa una partición.

Pero ¿qué sucede si agregamos un cuarto consumidor?

Como el tópico solamente dispone de tres particiones, el cuarto consumidor no tendrá una partición asignada para ese tópico mientras se mantenga esa distribución.

Esto permite comprender una regla fundamental:

Dentro de un mismo grupo, el paralelismo efectivo de consumo de un tópico está limitado por su cantidad de particiones.

Por ejemplo:

| Particiones | Consumidores del grupo | Resultado habitual                          |
| ----------- | ---------------------- | ------------------------------------------- |
| 3           | 1                      | Un consumidor atiende las tres particiones  |
| 3           | 2                      | Las particiones se distribuyen entre ambos  |
| 3           | 3                      | Cada consumidor puede atender una partición |
| 3           | 4                      | Un consumidor queda sin partición asignada  |

La asignación puede variar según la estrategia utilizada y los demás tópicos a los que esté suscrito el grupo.

### 1.5.7. ¿Qué ocurre si existen varios grupos de consumidores?

Hasta ahora hemos estudiado varios consumidores colaborando dentro de un mismo grupo.

Sin embargo, Kafka también permite que diferentes grupos consuman los mismos eventos de manera independiente.

Por ejemplo, nuestra empresa podría disponer de tres grupos:

- `monitoreo_ventas`: actualiza indicadores comerciales.
- `deteccion_anomalias`: analiza operaciones sospechosas.
- `almacenamiento_historico`: prepara registros para su persistencia.

Cada grupo mantiene su propia posición de consumo y puede procesar los eventos a su propio ritmo.

Figura 19. Diferentes grupos consumiendo un mismo tópico

![Figura 19: Diferentes grupos consumiendo un mismo tópico](kafka_figuras/svg/figura_19.svg)

Esto representa una diferencia importante respecto de distribuir el trabajo entre consumidores de un mismo grupo.

Dentro de un grupo, los consumidores colaboran y se reparten las particiones.

Entre grupos diferentes, cada grupo puede leer independientemente los registros del tópico.

Por lo tanto, una misma venta puede ser utilizada por varios sistemas sin que uno de ellos impida el acceso de los demás.

### 1.5.8. Rebalanceo: adaptación a cambios en los consumidores

Los grupos de consumidores no permanecen necesariamente con la misma cantidad de integrantes.

Un consumidor puede detenerse, fallar o incorporarse al grupo.

Cuando se producen determinados cambios, Kafka debe revisar la distribución de particiones entre los consumidores disponibles.

Este proceso se denomina rebalanceo (rebalance).

Por ejemplo, supongamos que tenemos tres particiones distribuidas entre tres consumidores.

Si uno de los consumidores deja de funcionar, las particiones que tenía asignadas deben redistribuirse entre los consumidores restantes.

De esta manera, el grupo puede continuar procesando los eventos.

El rebalanceo contribuye a la continuidad operativa, aunque puede provocar pausas o cambios temporales en el procesamiento, según la estrategia de asignación y la configuración utilizada.

Por eso, en sistemas productivos resulta importante monitorear la estabilidad de los grupos de consumidores.

### 1.5.9. ¿Qué sucede si los consumidores procesan más lentamente que los productores?

Consideremos nuevamente nuestra empresa comercializadora.

Supongamos que el sistema de ventas publica 1.000 eventos por minuto, pero una aplicación consumidora solamente alcanza a procesar 600 eventos durante ese mismo período.

En este escenario, la cantidad de eventos pendientes de consumo aumentará.

Kafka permite medir esta diferencia mediante un indicador conocido como consumer lag.

El lag representa el retraso del consumidor respecto de los registros disponibles en una partición, habitualmente expresado como una diferencia entre offsets.

Figura 20. Ejemplo conceptual de retraso de consumo

![Figura 20: Ejemplo conceptual de retraso de consumo](kafka_figuras/svg/figura_20.svg)

El consumer lag es especialmente importante en arquitecturas de procesamiento Near Real-Time.

Si el retraso aumenta continuamente, la aplicación puede dejar de entregar información con la oportunidad requerida, aunque Kafka continúe recibiendo correctamente los eventos.

Por tanto, no basta con comprobar que los mensajes llegan a Kafka. También debemos verificar que los consumidores sean capaces de procesarlos con una velocidad adecuada.

### 1.5.10. Nuestra infraestructura Docker: un entorno educativo de un broker

Hasta ahora hemos presentado ejemplos de clústeres con varios brokers y particiones distribuidas.

Sin embargo, debemos distinguir esas arquitecturas conceptuales de la infraestructura que utilizamos actualmente en el curso.

En nuestro repositorio `juliopez/Hadoop`, el archivo `docker-compose.yml` define un servicio Kafka con el nombre de contenedor `kafka`, conectado al servicio `zookeeper`.

La configuración contempla un único servicio Kafka en Docker Compose.

Esto significa que nuestro laboratorio no dispone actualmente de un clúster de varios brokers Kafka independientes.

Podemos estudiar y utilizar tópicos, particiones, productores, consumidores y grupos de consumidores dentro de ese entorno.

No obstante, la replicación entre brokers requiere incorporar servidores Kafka adicionales.

Por ejemplo, un tópico con factor de replicación 3 necesita disponer de al menos tres brokers para alojar sus tres réplicas.

Esta distinción evita que los estudiantes confundan la arquitectura distribuida que Kafka puede implementar con la configuración específica disponible en nuestro laboratorio.

Además, nuestra infraestructura utiliza ZooKeeper, mientras que las versiones modernas de Kafka emplean KRaft.

Por eso, cuando abordemos la operación de Kafka en la segunda parte del material, verificaremos las herramientas y comandos compatibles con la imagen Docker utilizada.

### 1.5.11. Ejemplo integrador: procesamiento de ventas con varios consumidores

Reunamos los conceptos estudiados mediante un escenario completo.

Nuestra empresa comercializadora dispone de varias sucursales que generan eventos de ventas.

Los productores publican esos eventos en el tópico `ventas`, configurado con tres particiones.

Kafka distribuye los registros entre las particiones según la estrategia de particionamiento utilizada.

Cada registro recibe un offset dentro de su partición.

Un grupo de consumidores denominado `monitoreo_ventas` utiliza tres procesos para distribuir el trabajo.

Otro grupo, denominado `almacenamiento_historico`, consume los mismos registros para conservarlos mediante un proceso de integración.

Si uno de los consumidores del primer grupo deja de funcionar, Kafka puede redistribuir sus particiones entre los consumidores restantes.

Si los consumidores comienzan a procesar más lentamente que los productores, aumentará su retraso de consumo.

Finalmente, si el sistema necesita tolerar la falla de brokers, deberá utilizar una arquitectura con múltiples servidores y replicación configurada apropiadamente.

Este ejemplo permite comprender que los mecanismos de Kafka no funcionan de manera aislada: particiones, offsets, grupos de consumidores y replicación colaboran para distribuir, organizar y mantener disponible el flujo de eventos.

### 1.5.12. Síntesis del apartado

En este apartado estudiamos los principales mecanismos que sustentan la arquitectura distribuida de Apache Kafka.

| Concepto              | Función principal                                                                  |
| --------------------- | ---------------------------------------------------------------------------------- |
| Partición             | Divide un tópico en secuencias ordenadas de registros                              |
| Offset                | Identifica la posición de un registro dentro de una partición                      |
| Replicación           | Mantiene copias de particiones en distintos brokers                                |
| Grupo de consumidores | Permite distribuir el procesamiento entre consumidores                             |
| Rebalanceo            | Reasigna particiones cuando cambia la composición del grupo                        |
| Consumer lag          | Permite observar el retraso de un consumidor respecto de los registros disponibles |

Estos mecanismos explican cómo Kafka puede atender flujos de información de gran volumen, distribuir el trabajo entre aplicaciones y ofrecer mecanismos de continuidad operativa.

También comprendimos una diferencia importante entre la arquitectura general de Kafka y nuestro entorno docente: aunque Kafka puede utilizar múltiples brokers y replicación, nuestra instalación actual dispone de un único servicio Kafka.

En el siguiente apartado estudiaremos una cuestión central para el curso: qué significa realmente procesar información en tiempo real, en Near Real-Time y mediante batch, y cómo se relacionan estos enfoques con Kafka y Spark.

## 1.6. Tiempo real, Near Real-Time y procesamiento batch: diferencias y aplicaciones

En los apartados anteriores estudiamos cómo Apache Kafka permite recibir, almacenar y distribuir eventos mediante productores, tópicos, brokers y consumidores. También comprendimos cómo las particiones y los grupos de consumidores facilitan el procesamiento paralelo.

Ahora debemos responder una pregunta fundamental: ¿qué significa que un sistema procese información en tiempo real?

La respuesta requiere distinguir tres enfoques: procesamiento por lotes (batch), procesamiento cercano al tiempo real (Near Real-Time o NRT) y procesamiento en tiempo real (real-time).

Esta distinción es especialmente importante porque utilizar Kafka no convierte automáticamente una aplicación en un sistema de tiempo real.

### 1.6.1. El tiempo como dimensión del procesamiento de datos

Hasta ahora hemos trabajado principalmente con conjuntos de datos almacenados en HDFS, que posteriormente procesamos mediante Apache Spark.

Por ejemplo, nuestra empresa comercializadora podría generar un archivo CSV con todas las ventas realizadas durante una jornada.

Una vez disponible el archivo, ejecutamos un programa PySpark para calcular indicadores como las ventas totales, los productos más vendidos o los ingresos por sucursal.

En este escenario, el procesamiento comienza cuando los datos ya se encuentran disponibles.

Pero imaginemos que la gerencia necesita conocer el comportamiento de las ventas durante la jornada, sin esperar al cierre diario.

La necesidad ya no consiste únicamente en procesar correctamente los datos. También importa cuánto tiempo transcurre entre la generación de una transacción y la disponibilidad de información útil para tomar decisiones.

Este intervalo se relaciona con el concepto de latencia.

En términos generales, la latencia representa el tiempo que transcurre entre dos momentos de un proceso. En sistemas de datos, podemos distinguir la latencia de transmisión, la latencia de procesamiento y la latencia total de extremo a extremo.

Para nuestro curso, utilizaremos principalmente esta última perspectiva:

\\[ \text{Latencia total} = \text{Tiempo de disponibilidad del resultado} - \text{Tiempo de generación del evento} \\]

Por ejemplo, si una venta ocurre a las 10:00:00 y aparece en un indicador a las 10:00:05, la latencia total observada es de cinco segundos.

Esto no significa necesariamente que el sistema sea de tiempo real estricto. Para determinarlo necesitamos conocer los requisitos temporales de la aplicación.

### 1.6.2. Procesamiento batch: trabajar con conjuntos de datos

El procesamiento por lotes o batch processing consiste en ejecutar operaciones sobre un conjunto de datos disponible para una tarea determinada.

Este enfoque es el que hemos utilizado principalmente durante las semanas anteriores.

Figura 21. Procesamiento batch de transacciones comerciales

![Figura 21: Procesamiento batch de transacciones comerciales](kafka_figuras/svg/figura_21.svg)

Supongamos que el sistema comercial genera un archivo con 100.000 transacciones.

El programa PySpark puede leerlo desde HDFS, aplicar transformaciones, realizar agrupaciones y escribir los resultados.

Este modelo ofrece varias ventajas. Permite procesar grandes volúmenes de información, ejecutar cálculos complejos y trabajar con datos históricos consolidados.

Por ello, continúa siendo apropiado para informes diarios, cierres contables, análisis históricos, procesos de transformación de datos y construcción de conjuntos de información para análisis posteriores.

Su principal limitación aparece cuando necesitamos resultados actualizados con una frecuencia mayor que la del proceso programado.

Si un informe se genera una vez al día, una transacción registrada inmediatamente después de su ejecución podría no aparecer hasta el siguiente ciclo.

Sin embargo, debemos evitar una confusión: batch no significa necesariamente procesamiento lento. Un trabajo batch puede ejecutarse en pocos segundos. Lo que caracteriza al enfoque es su organización en ejecuciones sobre conjuntos de datos, no una duración mínima obligatoria.

### 1.6.3. Near Real-Time: información con un pequeño retraso

El procesamiento Near Real-Time (NRT) busca que la información esté disponible poco después de producirse, aceptando una latencia limitada que resulta adecuada para la necesidad del negocio.

No existe un umbral universal que determine que una aplicación es NRT por procesar datos cada cinco, diez o treinta segundos.

La clasificación depende de los requisitos operacionales.

Por ejemplo, para una empresa comercializadora podría resultar suficiente actualizar sus indicadores cada diez segundos.

En ese escenario, la organización no necesita necesariamente que cada venta aparezca en el dashboard en el mismo instante en que ocurre, pero tampoco puede esperar hasta el cierre del día.

Una implementación NRT podría funcionar de la siguiente manera:

1. El sistema comercial registra nuevas transacciones.
2. Una aplicación consulta periódicamente una API REST.
3. Los registros nuevos se publican en Kafka.
4. Un consumidor recupera los eventos.
5. Los resultados se actualizan con una frecuencia definida.

Figura 22. Ejemplo de una arquitectura Near Real-Time

![Figura 22: Ejemplo de una arquitectura Near Real-Time](kafka_figuras/svg/figura_22.svg)

Los diez segundos son una frecuencia ilustrativa de consulta, no una garantía de latencia total.

Este ejemplo introduce un concepto importante: el polling.

Polling significa consultar periódicamente un sistema para comprobar si existe información nueva.

Por ejemplo, una aplicación Python podría consultar una API cada diez segundos para recuperar nuevas transacciones.

La API es una interfaz que permite que una aplicación solicite información o utilice funciones proporcionadas por otro sistema. Cuando hablamos de una API REST, normalmente nos referimos a servicios accesibles mediante solicitudes HTTP.

En nuestro caso, una aplicación podría consultar una API, transformar la respuesta JSON en eventos y publicarlos en Kafka.

Debemos considerar que la frecuencia de consulta no equivale automáticamente a la latencia total.

Si consultamos cada diez segundos, un evento podría permanecer varios segundos sin ser detectado. A ello se suma el tiempo de respuesta de la API, la publicación en Kafka, el procesamiento del consumidor y la actualización del sistema de destino.

Por lo tanto, una arquitectura NRT debe evaluarse considerando el recorrido completo de la información.

### 1.6.4. Procesamiento en tiempo real: responder dentro de un plazo definido

El concepto de tiempo real (real-time) suele utilizarse de manera amplia en la industria tecnológica.

En ocasiones se emplea para describir aplicaciones que procesan eventos continuamente y entregan resultados con baja latencia.

Sin embargo, desde una perspectiva técnica más estricta, un sistema de tiempo real debe cumplir determinados requisitos temporales.

Esto significa que no basta con obtener un resultado correcto: también debe estar disponible dentro del plazo requerido.

Por ejemplo, imaginemos un sistema industrial que necesita detener una máquina cuando un sensor detecta una condición peligrosa.

Si la respuesta llega demasiado tarde, aunque el cálculo sea correcto, podría no cumplir su propósito.

En sistemas de tiempo real estricto, la capacidad de cumplir los plazos establecidos es una propiedad fundamental.

Kafka puede formar parte de arquitecturas de baja latencia y transmisión continua de eventos, pero no debe considerarse por sí solo una plataforma que garantice tiempos máximos de respuesta para aplicaciones críticas de tiempo real estricto.

En este curso, cuando hablemos de Kafka y real-time streaming, nos referiremos principalmente a flujos continuos de eventos y a sistemas diseñados para responder con baja latencia, distinguiéndolos de aquellos que requieren garantías temporales estrictas.

### 1.6.5. Comparación entre batch, Near Real-Time y real-time

Los tres enfoques pueden utilizarse dentro de una misma organización.

La elección depende de la necesidad de información, los requisitos de latencia, los costos y la complejidad de implementación.

| Característica               | Batch                                             | Near Real-Time                                     | Real-time                                                   |
| ---------------------------- | ------------------------------------------------- | -------------------------------------------------- | ----------------------------------------------------------- |
| Procesamiento                | Por lotes                                         | Frecuente o continuo                               | Continuo, con requisitos temporales                         |
| Disponibilidad de resultados | Según ejecución programada                        | Con retraso acotado para el caso de uso            | Dentro del plazo requerido                                  |
| Latencia                     | Variable; puede ser elevada entre actualizaciones | Habitualmente segundos o minutos, según aplicación | Según requisitos específicos                                |
| Ejemplo comercial            | Informe de ventas diario                          | Dashboard actualizado cada 10 segundos             | Autorización de una operación con plazo exigente            |
| Tecnologías posibles         | HDFS, Hive, Spark                                 | Kafka, consumidores, Spark Streaming               | Arquitecturas especializadas según las garantías necesarias |

Esta tabla debe interpretarse como una comparación conceptual, no como una clasificación universal basada únicamente en segundos.

Por ejemplo, un sistema que actualiza información cada segundo podría considerarse NRT si no ofrece garantías de cumplimiento de plazos. Del mismo modo, un sistema de tiempo real puede tener un plazo mayor, siempre que ese plazo esté claramente definido y garantizado bajo las condiciones requeridas.

### 1.6.6. Streaming continuo y microbatch: dos formas de procesar eventos

Hasta ahora hemos utilizado los términos streaming y NRT, pero necesitamos distinguirlos.

Streaming describe el tratamiento de datos que llegan como un flujo, en lugar de depender exclusivamente de conjuntos de datos cerrados.

Existen distintas formas de implementar ese procesamiento.

Una aplicación puede procesar los registros conforme los recibe, sin esperar a formar lotes de tamaño considerable.

Otra alternativa consiste en agrupar los eventos que llegan durante intervalos breves y procesarlos mediante pequeñas ejecuciones sucesivas.

Esta segunda estrategia se denomina microbatch.

Figura 23. Procesamiento continuo y mediante microbatches

![Figura 23: Procesamiento continuo y mediante microbatches](kafka_figuras/svg/figura_23.svg)

Este concepto resulta especialmente relevante porque ya conocemos Apache Spark.

Spark Structured Streaming permite construir aplicaciones de procesamiento de flujos utilizando operaciones semejantes a las que hemos empleado con DataFrames.

Su motor utiliza habitualmente microbatches para ejecutar consultas de streaming.

Esto significa que podemos aprovechar conocimientos previos como selección de columnas, filtros, agrupaciones y transformaciones para procesar información que llega continuamente.

La diferencia es que, en lugar de trabajar solamente con un DataFrame obtenido desde un archivo cerrado, la aplicación puede operar sobre una fuente de datos que incorpora nuevos registros.

### 1.6.7. Kafka y Spark: funciones diferentes dentro de una misma arquitectura

Es importante comprender que Kafka y Spark no realizan exactamente el mismo trabajo.

Kafka permite publicar, conservar según retención y distribuir eventos.

Spark puede leer esos eventos y ejecutar operaciones de procesamiento sobre ellos.

Por ejemplo, imaginemos que cada sucursal publica sus ventas en Kafka.

Una aplicación Spark Structured Streaming podría consumir los registros y calcular indicadores de ventas por sucursal.

Posteriormente, los resultados podrían almacenarse en un repositorio o enviarse a otra aplicación.

Figura 24. Integración conceptual de Kafka y Spark

![Figura 24: Integración conceptual de Kafka y Spark](kafka_figuras/svg/figura_24.svg)

Arquitectura conceptual; la conexión concreta con Spark depende de la versión y de las bibliotecas disponibles.

Esta integración permite comprender que el procesamiento batch y el streaming no son necesariamente alternativas excluyentes.

Una organización puede utilizar Kafka y Spark Streaming para obtener información reciente, mientras conserva HDFS, Hive y los procesos batch para análisis históricos y consolidaciones periódicas.

En nuestro laboratorio, la infraestructura actual utiliza Spark 2.4.0. Por ello, antes de implementar la conexión entre Kafka y Spark Structured Streaming, será necesario verificar la compatibilidad de los conectores y dependencias correspondientes.

### 1.6.8. Un mismo problema empresarial resuelto mediante tres enfoques

Para comparar los modelos, utilizaremos una misma pregunta:

¿Cuánto está vendiendo nuestra empresa comercializadora?

Escenario A. Informe diario mediante batch

Al finalizar la jornada, la empresa consolida las transacciones en un archivo. Spark procesa los datos almacenados en HDFS y genera un informe de ventas.

Es apropiado para cierres diarios, conciliaciones y análisis históricos.

Escenario B. Dashboard Near Real-Time

Una aplicación consulta una API comercial cada diez segundos, identifica nuevas transacciones y las publica en Kafka. Un consumidor procesa los eventos y actualiza los indicadores.

Es apropiado para seguimiento operacional, siempre que la latencia obtenida cumpla los requisitos del negocio.

Escenario C. Detección de operaciones con respuesta inmediata

Cada transacción genera un evento que debe analizarse dentro de un plazo definido para permitir o rechazar una operación.

En este escenario, Kafka podría formar parte de la arquitectura, pero el cumplimiento de los plazos exige diseñar y verificar el sistema completo.

Los tres escenarios utilizan información comercial, pero responden a necesidades distintas.

El primero prioriza el procesamiento de información consolidada. El segundo busca mantener indicadores actualizados con una latencia aceptable. El tercero incorpora requisitos temporales que pueden ser críticos para la operación.

La decisión tecnológica debe comenzar por la necesidad del negocio y no por la elección anticipada de una herramienta.

### 1.6.9. ¿Qué determina la latencia de una arquitectura Kafka?

Supongamos que implementamos una solución NRT utilizando una API REST, un productor Python, Kafka y un consumidor.

La latencia total dependerá de varias etapas.

| Etapa                 | Posible contribución a la latencia                               |
| --------------------- | ---------------------------------------------------------------- |
| Generación del evento | Tiempo hasta que el sistema de origen registra el acontecimiento |
| Consulta de la API    | Espera hasta la próxima consulta y tiempo de respuesta           |
| Publicación en Kafka  | Serialización, comunicación y confirmación del mensaje           |
| Consumo               | Frecuencia de lectura y disponibilidad del consumidor            |
| Procesamiento         | Transformaciones y cálculos realizados                           |
| Presentación          | Escritura de resultados y actualización del indicador            |

Por ejemplo, si una aplicación consulta una API cada diez segundos, no podemos afirmar que el dashboard se actualizará exactamente diez segundos después de cada transacción.

Podría tardar más debido al tiempo de respuesta de la API, el procesamiento o la actualización del destino.

También podría tardar menos si el evento ocurre inmediatamente antes de la siguiente consulta.

Por ello, al evaluar una solución NRT debemos medir la latencia real y no asumirla a partir de un único parámetro de configuración.

Otro indicador importante es el consumer lag, estudiado en el apartado anterior.

Si los consumidores procesan menos eventos de los que reciben, el retraso puede aumentar y afectar la oportunidad de los resultados.

### 1.6.10. ¿Cuándo conviene utilizar cada enfoque?

No todas las aplicaciones necesitan procesamiento continuo.

Implementar una arquitectura de streaming introduce componentes adicionales que deben configurarse, supervisarse y mantenerse.

Por ejemplo, si una institución necesita generar un informe estadístico mensual, un proceso batch podría resolver adecuadamente la necesidad sin incorporar Kafka.

En cambio, si una plataforma comercial necesita monitorear continuamente sus operaciones, una arquitectura basada en eventos puede aportar beneficios importantes.

La selección debe considerar el volumen de información, la frecuencia con que cambian los datos, los requisitos de latencia, la disponibilidad necesaria y los recursos técnicos de la organización.

El objetivo no es reemplazar todos los procesos batch por streaming, sino utilizar cada enfoque cuando aporta valor.

Esta idea será fundamental para comprender las arquitecturas integradas que estudiaremos posteriormente.

### 1.6.11. Síntesis del apartado

El procesamiento batch, Near Real-Time y real-time representan enfoques diferentes para gestionar la relación entre los datos y el tiempo.

El procesamiento batch trabaja con conjuntos de información y resulta especialmente apropiado para consolidaciones y análisis históricos.

Near Real-Time busca ofrecer resultados con un retraso limitado y aceptable para una necesidad específica.

El procesamiento en tiempo real incorpora requisitos temporales que deben cumplirse, especialmente cuando una respuesta tardía puede afectar el funcionamiento del sistema.

Apache Kafka permite construir arquitecturas que reciben y distribuyen eventos continuamente, pero la latencia total depende de todos los componentes involucrados.

En nuestro curso, esta distinción nos permitirá comprender cómo ampliar la infraestructura basada en HDFS, Hive y Spark para incorporar nuevas fuentes de información y desarrollar soluciones de procesamiento cercano al tiempo real.

## 1.7. Kafka en el ecosistema Big Data: relaciones con Hadoop, Spark, APIs y otros servicios

En los apartados anteriores hemos estudiado qué es Apache Kafka, cómo funciona su arquitectura distribuida y cuáles son las diferencias entre procesamiento batch, Near Real-Time y tiempo real.

Ahora corresponde situar Kafka dentro de una arquitectura Big Data más amplia.

Este apartado tiene especial importancia para nuestro curso, porque no estamos comenzando desde cero. Ya conocemos Hadoop, HDFS, Hive y Spark, y hemos utilizado estas tecnologías para almacenar, transformar y analizar información.

La incorporación de Kafka nos permitirá comprender cómo conectar esos procesos con sistemas que generan datos continuamente.

### 1.7.1. Del ecosistema de almacenamiento al ecosistema de eventos

Durante las semanas anteriores hemos trabajado con una arquitectura centrada principalmente en datos almacenados.

Por ejemplo, un sistema comercial genera un archivo CSV, que posteriormente cargamos en HDFS. Mediante Spark realizamos transformaciones y cálculos, mientras que Hive permite organizar y consultar información estructurada.

Este enfoque continúa siendo válido para numerosos problemas.

Sin embargo, las organizaciones también necesitan incorporar datos provenientes de aplicaciones web, sensores, plataformas transaccionales, servicios externos y bases de datos que cambian continuamente.

En estos escenarios aparece una necesidad adicional: transportar información desde los sistemas que la producen hacia los sistemas que la procesan y almacenan.

Kafka puede cumplir esa función dentro del ecosistema Big Data.

Figura 25. Evolución de una arquitectura Big Data hacia la incorporación de eventos

![Figura 25: Evolución de una arquitectura Big Data hacia la incorporación de eventos](kafka_figuras/svg/figura_25.svg)

Ambas arquitecturas pueden coexistir. Kafka incorpora una etapa de transmisión de eventos, mientras Spark, HDFS y Hive mantienen sus funciones de procesamiento, almacenamiento y consulta.

La diferencia fundamental no consiste en abandonar los archivos o las bases de datos, sino en disponer de mecanismos para incorporar nueva información a medida que se genera.

### 1.7.2. Relación entre Kafka y Hadoop/HDFS

Apache Hadoop proporciona un ecosistema de tecnologías orientadas al almacenamiento y procesamiento distribuido de grandes volúmenes de información.

Dentro de ese ecosistema, HDFS permite almacenar archivos distribuyéndolos entre diferentes nodos.

Kafka, por su parte, está diseñado para gestionar registros de eventos que pueden publicarse y consumirse continuamente.

Aunque ambas tecnologías almacenan información, lo hacen con propósitos diferentes.

| Característica       | Kafka                                                   | HDFS                                                      |
| -------------------- | ------------------------------------------------------- | --------------------------------------------------------- |
| Organización         | Tópicos y particiones                                   | Directorios, archivos y bloques                           |
| Información habitual | Registros de eventos                                    | Archivos y conjuntos de datos                             |
| Escritura            | Incorporación de registros a particiones                | Escritura de archivos                                     |
| Lectura              | Consumo mediante offsets                                | Acceso a archivos                                         |
| Retención            | Configurable por tiempo o tamaño, entre otras políticas | Los archivos permanecen hasta que se eliminan o gestionan |
| Uso principal        | Transmisión y distribución de eventos                   | Almacenamiento distribuido                                |

Imaginemos que nuestra empresa comercializadora registra 50.000 transacciones durante una jornada.

Kafka podría recibir esos eventos conforme se producen.

Posteriormente, un proceso consumidor podría agruparlos y almacenarlos en HDFS, por ejemplo, como archivos Parquet organizados por fecha.

De esta manera, Kafka permite incorporar información reciente y HDFS proporciona un repositorio para su conservación y análisis histórico.

Kafka no reemplaza a HDFS como sistema de almacenamiento histórico, aunque pueda conservar eventos durante períodos prolongados cuando su configuración y capacidad lo permiten.

La decisión de almacenar permanentemente los datos en HDFS responde a necesidades de consulta, conservación, gobierno de datos y análisis posteriores.

### 1.7.3. Relación entre Kafka y Apache Hive

Apache Hive permite trabajar con datos estructurados mediante consultas similares a SQL.

Durante el curso hemos utilizado Hive para organizar y consultar información almacenada en el ecosistema Hadoop.

Kafka no proporciona las mismas capacidades de consulta analítica que Hive.

Por ejemplo, si queremos obtener el total de ventas por sucursal durante el último semestre, podemos utilizar una tabla Hive que contenga las transacciones históricas.

Una consulta ilustrativa podría ser:

```
SELECT
    sucursal,
    SUM(monto_total) AS total_ventas
FROM ventas_historicas
GROUP BY sucursal;
```

Kafka puede participar en una etapa anterior de esa arquitectura, recibiendo los eventos que posteriormente se almacenarán en las tablas o archivos consultados por Hive.

Figura 26. Kafka como fuente de datos para análisis históricos

![Figura 26: Kafka como fuente de datos para análisis históricos](kafka_figuras/svg/figura_26.svg)

En este escenario, Kafka facilita la disponibilidad de los eventos, mientras Hive proporciona capacidades de consulta sobre los datos almacenados.

### 1.7.4. Relación entre Kafka y Apache Spark

La integración entre Kafka y Spark es especialmente relevante para nuestro curso.

Ya conocemos Spark como motor de procesamiento distribuido y hemos trabajado con PySpark para leer archivos, transformar DataFrames y generar resultados.

Sin embargo, Spark también dispone de capacidades de procesamiento de flujos mediante Structured Streaming.

Esta funcionalidad permite desarrollar aplicaciones que leen continuamente información desde fuentes compatibles, entre ellas Kafka, siempre que se disponga del conector correspondiente.

Podemos distinguir sus responsabilidades:

Kafka recibe y distribuye los eventos. Mantiene los registros disponibles para que las aplicaciones consumidoras puedan recuperarlos.

Spark procesa los eventos. Puede filtrar registros, transformar columnas, calcular agregaciones y escribir resultados hacia otros sistemas.

Por ejemplo, imaginemos que recibimos eventos con la siguiente estructura:

```
{
  "id_venta": "V10029",
  "sucursal": "Renca",
  "producto": "Mouse",
  "cantidad": 3,
  "monto_total": 45000
}
```

Una aplicación Spark Structured Streaming podría procesar esos registros para calcular las ventas por sucursal.

Conceptualmente, el procesamiento podría incluir operaciones como:

```
ventas_por_sucursal = (    ventas    .groupBy("sucursal")    .sum("monto_total"))
```

Este fragmento muestra una transformación conocida de PySpark. No constituye por sí solo una aplicación de streaming completa.

Para utilizarlo con Kafka sería necesario definir la fuente de streaming, interpretar el contenido de los mensajes, configurar el procesamiento y establecer un destino para los resultados.

Estos aspectos se abordarán en el apartado 2.9.

#### Una consideración importante sobre nuestro laboratorio

Nuestra infraestructura utiliza una imagen de Spark 2.4.0.

Por tanto, no debemos copiar indiscriminadamente ejemplos desarrollados para versiones modernas de Spark, porque algunas funciones, dependencias o configuraciones pueden ser diferentes.

Cuando implementemos la integración, tendremos que utilizar conectores compatibles con la versión instalada o evaluar explícitamente una actualización del entorno.

### 1.7.5. Relación entre Kafka y las APIs REST

Hasta ahora hemos utilizado ejemplos en los que una aplicación genera eventos y los publica directamente en Kafka.

Sin embargo, muchas organizaciones obtienen información desde servicios externos mediante APIs REST.

Una API REST permite que una aplicación interactúe con un servicio mediante solicitudes HTTP.

Por ejemplo, un sistema podría consultar una API para recuperar información sobre ventas, productos, pedidos o condiciones meteorológicas.

Una respuesta podría contener datos estructurados en JSON:

```
{
  "pedido": "P1025",
  "estado": "despachado",
  "fecha_actualizacion": "2026-10-28T12:30:00"
}
```

Ahora bien, Kafka no consulta automáticamente una API REST.

Para incorporar esa información necesitamos un componente que realice la consulta y publique los resultados.

Ese componente podría ser una aplicación Python.

Figura 27. Integración entre una API REST y Kafka

![Figura 27: Integración entre una API REST y Kafka](kafka_figuras/svg/figura_27.svg)

La aplicación Python puede utilizar una biblioteca HTTP para consultar la API y un cliente Kafka para publicar los eventos.

Un ejemplo conceptual sería:

```
# Obtener información desde una APIrespuesta = consultar_api()# Preparar los registros obtenidoseventos = transformar_respuesta(respuesta)# Publicar cada evento en Kafkafor evento in eventos:    publicar_en_kafka("pedidos", evento)
```

Las funciones utilizadas son ilustrativas; no corresponden a una implementación ejecutable.

En la segunda parte del material desarrollaremos los componentes necesarios para construir un productor real.

También debemos considerar que no todas las APIs permiten recuperar información nueva mediante el mismo mecanismo.

Algunas entregan registros paginados, otras permiten consultar modificaciones desde una fecha determinada y otras proporcionan notificaciones mediante webhooks.

Por lo tanto, el diseño de la integración dependerá de las características del servicio externo.

### 1.7.6. Relación entre Kafka y Apache NiFi

Nuestra infraestructura Docker también incluye Apache NiFi.

NiFi es una plataforma orientada a automatizar el movimiento y la transformación de datos entre sistemas.

Permite construir flujos de integración mediante componentes configurables, denominados processors, que realizan operaciones como recibir información, transformarla, dirigirla hacia diferentes destinos y gestionar determinadas condiciones de error.

Por ejemplo, podríamos utilizar NiFi para consultar una API REST, transformar su respuesta y publicar los registros en Kafka.

Figura 28. Integración conceptual mediante Apache NiFi

![Figura 28: Integración conceptual mediante Apache NiFi](kafka_figuras/svg/figura_28.svg)

Esta alternativa resulta interesante porque permite desarrollar integraciones mediante una interfaz visual.

No obstante, debemos comprender que NiFi y Kafka cumplen funciones diferentes.

NiFi se orienta a la construcción y administración de flujos de datos entre sistemas.

Kafka proporciona una plataforma distribuida para publicar, conservar y consumir eventos.

Pueden utilizarse conjuntamente, pero ninguno reemplaza automáticamente todas las capacidades del otro.

En nuestro curso priorizaremos comprender primero los productores y consumidores Kafka. Posteriormente podremos relacionar estos mecanismos con herramientas de integración como NiFi.

### 1.7.7. Kafka Connect: integración mediante conectores

Kafka dispone de un componente denominado Kafka Connect, diseñado para facilitar la transferencia de datos entre Kafka y otros sistemas.

Kafka Connect utiliza conectores que pueden realizar dos funciones principales.

Un source connector obtiene información desde un sistema externo y la incorpora a tópicos Kafka.

Un sink connector consume registros desde Kafka y los envía hacia un sistema de destino.

Figura 29. Funciones de Kafka Connect

![Figura 29: Funciones de Kafka Connect](kafka_figuras/svg/figura_29.svg)

Por ejemplo, una organización podría utilizar un conector de origen para incorporar registros desde una base de datos y un conector de destino para almacenarlos en otro sistema.

Sin embargo, no debemos suponer que cualquier integración se encuentra disponible de manera predeterminada.

Cada conector tiene requisitos específicos, y algunos deben instalarse o configurarse por separado.

En particular, la integración con APIs REST puede requerir conectores adicionales o el desarrollo de una aplicación personalizada.

Por ello, para nuestras primeras implementaciones utilizaremos productores y consumidores que permitan observar directamente cómo se publican y recuperan los eventos.

### 1.7.8. Relación con las bases de datos tradicionales

Hasta ahora hemos mencionado archivos, APIs y sistemas de procesamiento. Sin embargo, gran parte de la información empresarial se encuentra originalmente en bases de datos.

Por ejemplo, una empresa puede utilizar MySQL para almacenar ventas, productos, clientes y pedidos.

Kafka puede incorporarse para distribuir información relacionada con los cambios producidos en esos sistemas.

Una posibilidad consiste en que la propia aplicación publique un evento cada vez que registra una operación.

Otra alternativa es utilizar mecanismos de captura de cambios en bases de datos, conocidos como Change Data Capture (CDC).

CDC permite identificar operaciones como inserciones, actualizaciones o eliminaciones y transmitir información sobre esos cambios hacia otros sistemas.

Por ejemplo, cuando una venta se incorpora a una base de datos, una solución CDC puede detectar la modificación y publicar un evento en Kafka.

Esto facilita que otras aplicaciones reciban información sobre cambios recientes sin consultar continuamente todas las tablas.

No obstante, CDC requiere herramientas y configuraciones específicas. Kafka, por sí solo, no inspecciona automáticamente las modificaciones de una base de datos.

### 1.7.9. Arquitectura integrada: de una API REST al análisis histórico

Reunamos ahora las tecnologías estudiadas mediante un ejemplo completo.

Nuestra empresa comercializadora dispone de una API REST que permite consultar las transacciones registradas en sus sucursales.

La organización necesita dos resultados:

Primero, disponer de indicadores actualizados durante la jornada.

Segundo, conservar las transacciones para realizar análisis históricos.

Una arquitectura conceptual podría incluir las siguientes etapas:

Figura 30. Arquitectura integrada de adquisición, procesamiento y almacenamiento

![Figura 30: Arquitectura integrada de adquisición, procesamiento y almacenamiento](kafka_figuras/svg/figura_30.svg)

Arquitectura conceptual de referencia. Las integraciones representadas deben implementarse y validarse; no corresponden necesariamente a servicios ya conectados en nuestro laboratorio.

En esta arquitectura, la aplicación Python actúa como productor y Kafka distribuye los eventos.

Spark Structured Streaming puede consumir las transacciones para calcular indicadores recientes.

En paralelo, otro consumidor puede preparar los registros para su almacenamiento histórico en HDFS.

Posteriormente, Hive permite consultar los datos consolidados.

Este ejemplo muestra que una arquitectura Big Data puede combinar componentes de streaming con tecnologías de almacenamiento y procesamiento batch.

También nos permite anticipar el trabajo que desarrollaremos en la segunda parte del documento, especialmente cuando construyamos un productor que consulte una API REST y publique eventos en Kafka.

### 1.7.10. Consideraciones para nuestra infraestructura Docker

Nuestro repositorio [juliopez/Hadoop](https://github.com/juliopez/Hadoop) reúne diversas tecnologías que permiten estudiar el ecosistema Big Data de manera integrada.

Entre los servicios definidos se encuentran HDFS, Hive, Spark, Kafka, ZooKeeper, NiFi y MySQL.

Sin embargo, debemos distinguir entre disponer de los servicios instalados y tener implementados los flujos de integración entre ellos.

La presencia de Kafka y Spark dentro del mismo archivo Docker Compose no significa que exista automáticamente una aplicación que transmita eventos entre ambos.

Del mismo modo, disponer de NiFi no implica que ya esté configurado un flujo que consulte una API REST y publique registros en Kafka.

Cada integración requiere definir conexiones, formatos de datos, credenciales cuando correspondan, tratamiento de errores y mecanismos de verificación.

Por ello, nuestras futuras guías prácticas avanzarán progresivamente desde la operación básica de Kafka hasta su integración con fuentes externas y Spark.

### 1.7.11. Síntesis del apartado

Apache Kafka ocupa un lugar importante dentro del ecosistema Big Data porque facilita la transmisión de eventos entre sistemas que generan, procesan y almacenan información.

Su relación con las tecnologías estudiadas puede resumirse de la siguiente manera:

| Tecnología     | Función dentro de una arquitectura integrada                                   |
| -------------- | ------------------------------------------------------------------------------ |
| Kafka          | Publicación, almacenamiento temporal según retención y distribución de eventos |
| HDFS           | Almacenamiento distribuido de archivos y datos históricos                      |
| Hive           | Organización y consulta de datos estructurados                                 |
| Spark          | Procesamiento distribuido batch y streaming                                    |
| APIs REST      | Acceso a información y funciones de sistemas externos                          |
| Python         | Desarrollo de aplicaciones productoras, consumidoras y de integración          |
| NiFi           | Automatización de flujos de adquisición, transformación y transferencia        |
| Kafka Connect  | Integración mediante conectores de origen y destino                            |
| Bases de datos | Almacenamiento operacional y posible fuente de cambios o eventos               |

La principal conclusión es que Kafka no reemplaza a las demás tecnologías del ecosistema, sino que permite conectarlas mediante flujos de eventos.

En nuestro curso, esta integración representa la transición desde una arquitectura centrada principalmente en archivos y procesamiento batch hacia otra capaz de incorporar información generada continuamente.

En el siguiente apartado examinaremos aplicaciones concretas de Kafka en distintos sectores, incluyendo transacciones comerciales, Internet de las Cosas, monitoreo, registros de aplicaciones y otros escenarios de procesamiento de eventos.

## 1.8. Casos de uso: transacciones comerciales, IoT, monitoreo, registros y eventos de aplicaciones

En los apartados anteriores estudiamos los fundamentos de Apache Kafka, su arquitectura distribuida y su relación con tecnologías como Hadoop, Hive, Spark y las APIs REST.

Ahora corresponde examinar cómo estos conceptos se aplican a situaciones reales.

Kafka puede utilizarse en organizaciones de distintos sectores, como comercio, industria, servicios financieros, telecomunicaciones, transporte y plataformas digitales. Aunque sus necesidades son diferentes, comparten una característica: generan información continuamente y necesitan distribuirla hacia sistemas que la utilizan con distintos propósitos.

En este apartado revisaremos cinco escenarios de aplicación, identificando el problema que enfrentan las organizaciones, el papel que desempeña Kafka y las tecnologías que pueden complementarlo.

### 1.8.1. Transacciones comerciales: seguimiento continuo de ventas

Comenzaremos con el caso que hemos utilizado a lo largo del documento: una empresa comercializadora que registra transacciones en distintas sucursales.

Supongamos que la organización dispone de 50 establecimientos y una plataforma de comercio electrónico.

Cada venta genera información sobre el producto, la sucursal, el monto, la cantidad y el momento de la transacción.

Tradicionalmente, estos datos podrían consolidarse al finalizar la jornada y procesarse mediante un trabajo batch.

Sin embargo, la empresa necesita conocer durante el día el comportamiento de las ventas, identificar sucursales con mayor actividad y detectar cambios inesperados en la demanda.

#### ¿Cómo puede intervenir Kafka?

Cada sistema comercial puede publicar los eventos de venta en un tópico denominado `ventas`.

Por ejemplo:

```
{
  "id_venta": "V10030",
  "fecha": "2026-10-28T14:35:20",
  "sucursal": "Renca",
  "producto": "Notebook",
  "cantidad": 1,
  "monto_total": 720000
}
```

Distintos consumidores pueden utilizar estos eventos de manera independiente.

Figura 31. Arquitectura de eventos para transacciones comerciales

![Figura 31: Arquitectura de eventos para transacciones comerciales](kafka_figuras/svg/figura_31.svg)

Un consumidor puede alimentar un sistema de indicadores operacionales, otro puede identificar patrones inusuales y un tercero puede preparar los registros para su almacenamiento histórico.

Esta arquitectura permite que las aplicaciones utilicen las mismas transacciones sin establecer conexiones directas entre todos los sistemas.

#### ¿Qué aporta Kafka?

Su principal aporte es facilitar la distribución de eventos comerciales hacia diferentes aplicaciones, permitiendo que cada una procese la información según sus necesidades.

La detección de anomalías, el cálculo de indicadores y la construcción de dashboards requieren componentes adicionales. Kafka proporciona el flujo de eventos que esas aplicaciones necesitan.

Este caso será especialmente relevante para nuestras futuras actividades prácticas, porque permite relacionar Kafka con el procesamiento de datos comerciales que ya hemos desarrollado mediante PySpark.

### 1.8.2. Internet de las Cosas (IoT): recepción de datos desde sensores

El segundo escenario corresponde al Internet de las Cosas (Internet of Things, IoT).

IoT hace referencia a dispositivos físicos que incorporan sensores, conectividad y capacidades para generar o intercambiar información.

Estos dispositivos pueden encontrarse en instalaciones industriales, vehículos, sistemas agrícolas, edificios inteligentes o redes de monitoreo ambiental.

Imaginemos una empresa que dispone de sensores de temperatura instalados en cámaras de refrigeración.

Cada dispositivo registra periódicamente la temperatura de su entorno.

Un evento podría tener la siguiente estructura:

```
{
  "sensor_id": "TEMP-025",
  "ubicacion": "Camara_03",
  "fecha": "2026-10-28T14:36:00",
  "temperatura": 5.8,
  "unidad": "C"
}
```

La organización necesita almacenar las mediciones, observar su evolución y generar alertas cuando la temperatura supera los límites establecidos.

#### ¿Cómo puede intervenir Kafka?

Los dispositivos pueden enviar sus mediciones hacia una plataforma de adquisición que las publique en Kafka.

Un consumidor puede analizar los valores y generar alertas, mientras otro conserva las mediciones para análisis históricos.

Figura 32. Flujo de información desde sensores IoT

![Figura 32: Flujo de información desde sensores IoT](kafka_figuras/svg/figura_32.svg)

En este escenario, Kafka facilita la recepción y distribución de grandes cantidades de mediciones.

Sin embargo, debemos distinguir entre monitoreo y control industrial crítico.

Kafka puede participar en sistemas que generan alertas operacionales, pero no debe asumirse que proporciona las garantías temporales necesarias para ejecutar directamente mecanismos de seguridad industrial.

Los sistemas de control con requisitos estrictos de respuesta deben diseñarse utilizando tecnologías y mecanismos apropiados para esas condiciones.

### 1.8.3. Monitoreo de sistemas: observación continua del funcionamiento de aplicaciones

Las organizaciones utilizan numerosas aplicaciones, servidores y servicios que deben funcionar de manera coordinada.

Para administrarlos, necesitan conocer aspectos como la disponibilidad, el rendimiento, los errores y el comportamiento de sus componentes.

Por ejemplo, una plataforma de comercio electrónico podría necesitar monitorear:

- Cantidad de solicitudes recibidas.
- Tiempo de respuesta de sus servicios.
- Errores producidos durante las operaciones.
- Estado de los servidores.
- Número de transacciones procesadas.

Estos datos pueden generarse continuamente y provenir de diferentes fuentes.

#### ¿Cómo puede intervenir Kafka?

Los sistemas pueden publicar eventos de monitoreo en tópicos específicos.

Por ejemplo:

```
{
  "servicio": "procesamiento_pedidos",
  "fecha": "2026-10-28T14:40:15",
  "tipo_evento": "error",
  "codigo": 503,
  "descripcion": "Servicio temporalmente no disponible"
}
```

Un consumidor podría identificar un aumento en la frecuencia de errores y generar una alerta.

Otro podría almacenar los registros para analizar tendencias de rendimiento.

Kafka permite centralizar la distribución de estos eventos y desacoplar los sistemas que los generan de las herramientas que los analizan.

No obstante, la visualización de métricas, la generación de alertas y la administración de incidentes corresponden a aplicaciones especializadas.

Kafka puede formar parte de la arquitectura de observabilidad, pero no constituye por sí mismo una plataforma completa de monitoreo.

### 1.8.4. Registros de aplicaciones: recopilación y análisis de logs

Los sistemas informáticos generan continuamente registros de funcionamiento, conocidos como logs.

Un log puede informar que un usuario inició sesión, que una aplicación procesó una solicitud o que se produjo un error.

Por ejemplo:

```
2026-10-28 14:42:10 INFO  Usuario autenticado
2026-10-28 14:42:11 INFO  Pedido P1025 registrado
2026-10-28 14:42:12 ERROR Fallo en servicio de pago
```

Estos registros son importantes para diagnosticar problemas, auditar operaciones y comprender el comportamiento de las aplicaciones.

Sin embargo, cuando una organización utiliza numerosos servidores, recopilar y analizar todos sus logs puede convertirse en una tarea compleja.

Kafka puede actuar como plataforma intermedia para recibir registros desde múltiples sistemas y distribuirlos hacia herramientas de almacenamiento, búsqueda y análisis.

Figura 33. Centralización de registros de aplicaciones

![Figura 33: Centralización de registros de aplicaciones](kafka_figuras/svg/figura_33.svg)

Esta arquitectura permite que los registros de diferentes aplicaciones estén disponibles para múltiples consumidores.

Debemos considerar que los logs pueden contener información sensible, como identificadores de usuarios o detalles internos de los sistemas. Por ello, su publicación y conservación requieren controles adecuados de acceso, protección de datos y políticas de retención.

### 1.8.5. Eventos de aplicaciones: comunicación entre servicios

Otro caso importante corresponde a las aplicaciones construidas mediante múltiples servicios.

Imaginemos una plataforma de comercio electrónico que dispone de componentes independientes para administrar pedidos, inventario, pagos y notificaciones.

Cuando un cliente realiza una compra, deben producirse varias operaciones.

El sistema de pedidos registra la transacción, el inventario necesita conocer los productos vendidos y el servicio de notificaciones debe informar al cliente.

Una alternativa consiste en establecer conexiones directas entre todos los servicios.

Otra posibilidad es utilizar eventos.

Por ejemplo, cuando se registra un pedido, el sistema correspondiente publica un evento:

```
{
  "tipo_evento": "pedido_creado",
  "id_pedido": "P1026",
  "cliente_id": "C305",
  "fecha": "2026-10-28T14:45:00",
  "monto_total": 185000
}
```

El servicio de inventario puede consumir ese evento para actualizar sus registros.

El servicio de notificaciones puede utilizarlo para iniciar el envío de una confirmación.

Otro sistema puede conservar la información para análisis comercial.

Figura 34. Comunicación entre servicios mediante eventos

![Figura 34: Comunicación entre servicios mediante eventos](kafka_figuras/svg/figura_34.svg)

Este enfoque se relaciona con las arquitecturas orientadas a eventos (Event-Driven Architecture, EDA).

En una arquitectura orientada a eventos, las aplicaciones pueden reaccionar ante acontecimientos publicados por otros componentes, reduciendo ciertas dependencias directas entre servicios.

Sin embargo, esta estrategia también introduce desafíos.

Por ejemplo, un servicio puede procesar un evento más de una vez en determinadas condiciones, o recibirlo después de que otros componentes hayan avanzado en sus operaciones.

Por ello, las aplicaciones deben diseñarse considerando aspectos como la idempotencia, el tratamiento de errores y la consistencia de los datos.

La idempotencia significa, de manera simplificada, que repetir una operación no debe producir efectos adicionales no deseados.

Por ejemplo, procesar dos veces un evento `pedido_creado` no debería provocar que se descuente dos veces el mismo inventario.

Estos aspectos son especialmente importantes cuando Kafka participa en procesos empresariales que modifican información operacional.

### 1.8.6. Comparación de los principales casos de uso

Los escenarios anteriores muestran que Kafka puede participar en soluciones con propósitos diferentes.

| Caso de uso               | Evento principal       | Necesidad empresarial          | Posibles consumidores                  |
| ------------------------- | ---------------------- | ------------------------------ | -------------------------------------- |
| Transacciones comerciales | Venta registrada       | Seguimiento de operaciones     | Indicadores, analítica, almacenamiento |
| IoT                       | Medición de sensor     | Supervisión de condiciones     | Alertas, análisis de series temporales |
| Monitoreo                 | Métrica o incidente    | Observación del funcionamiento | Sistemas de monitoreo y alertas        |
| Logs                      | Registro de aplicación | Diagnóstico y auditoría        | Búsqueda, análisis y almacenamiento    |
| Eventos de aplicaciones   | Pedido creado          | Coordinación entre servicios   | Inventario, notificaciones, analítica  |

Aunque estos escenarios pertenecen a ámbitos diferentes, todos comparten una estructura general:

Un sistema produce un acontecimiento, Kafka permite distribuirlo y una o más aplicaciones lo utilizan.

La forma específica de implementar cada solución dependerá de las necesidades de la organización, el volumen de información, la latencia requerida y los sistemas involucrados.

### 1.8.7. ¿Cuándo Kafka aporta valor y cuándo podría no ser necesario?

Hasta ahora hemos revisado diferentes aplicaciones de Kafka, pero es importante evitar la idea de que toda solución de datos necesita incorporar esta tecnología.

Kafka resulta especialmente útil cuando una organización debe gestionar flujos continuos de eventos, distribuir información entre múltiples consumidores o desacoplar sistemas que producen y utilizan datos.

También puede ser apropiado cuando se necesita conservar temporalmente los eventos para permitir su consumo posterior o su reprocesamiento.

Sin embargo, su incorporación implica administrar brokers, tópicos, particiones, configuraciones, consumidores y mecanismos de monitoreo.

Por ejemplo, si una pequeña organización necesita procesar un archivo de ventas una vez al mes, probablemente pueda resolver el problema mediante una base de datos o un proceso batch, sin necesidad de introducir Kafka.

Del mismo modo, una integración sencilla entre dos aplicaciones puede resolverse mediante una API REST sin incorporar necesariamente una plataforma de eventos.

La decisión debe responder a los requisitos del sistema.

Criterios orientativos para evaluar Kafka

| ¿Los datos se generan continuamente?                   | Kafka puede facilitar su distribución.                       |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| ¿Varias aplicaciones necesitan los mismos eventos?     | Kafka permite consumidores independientes.                   |
| ¿Se necesita recuperar o reprocesar eventos recientes? | La retención y los offsets pueden resultar útiles.           |
| ¿Solo se procesa un archivo mensual?                   | Un proceso batch puede ser suficiente.                       |
| ¿Se necesita una consulta puntual a un servicio?       | Una integración directa mediante API puede ser más sencilla. |

Esta evaluación permite comprender que Kafka no es una solución universal, sino una tecnología especializada que debe incorporarse cuando sus capacidades justifican la complejidad adicional.

### 1.8.8. El caso que utilizaremos como referencia en nuestro curso

Para mantener la continuidad entre los fundamentos teóricos y las futuras actividades prácticas, utilizaremos principalmente el escenario de transacciones comerciales.

La idea general será disponer de una fuente de información que genere o entregue registros de ventas, publicarlos en Kafka y recuperarlos mediante aplicaciones consumidoras.

Posteriormente, estudiaremos cómo integrar esos eventos con Spark Structured Streaming.

Figura 35. Arquitectura de referencia para la segunda parte del curso

![Figura 35: Arquitectura de referencia para la segunda parte del curso](kafka_figuras/svg/figura_35.svg)

Flujo conceptual que servirá como referencia para comprender las implementaciones posteriores.

Este escenario tiene varias ventajas pedagógicas.

Primero, utiliza información familiar: ventas, productos, cantidades, montos y fechas.

Segundo, permite trabajar con estructuras JSON sencillas.

Tercero, facilita comprender las funciones de productores, tópicos y consumidores sin introducir simultáneamente demasiados conceptos nuevos.

Finalmente, permite establecer una relación directa con las transformaciones y agregaciones que ya conocemos de PySpark.

Debemos recordar que este documento corresponde al material teórico del curso. La implementación detallada se desarrollará posteriormente en dos guías prácticas independientes, una para cada sesión destinada al trabajo con Kafka.

### 1.8.9. Síntesis del apartado

Apache Kafka puede utilizarse en diferentes contextos donde las organizaciones necesitan recibir y distribuir información generada continuamente.

Entre sus aplicaciones se encuentran el seguimiento de transacciones comerciales, la adquisición de mediciones IoT, el monitoreo de sistemas, la recopilación de logs y la comunicación entre servicios mediante eventos.

En todos estos casos, Kafka desempeña una función central: proporcionar una plataforma que permita publicar, conservar durante un período configurable y consumir registros de eventos.

Sin embargo, las operaciones de análisis, visualización, control o almacenamiento histórico requieren aplicaciones y tecnologías complementarias.

La incorporación de Kafka debe justificarse a partir de las necesidades del sistema y no únicamente por su capacidad tecnológica.

## Cierre de la Parte I

Con este apartado completamos la primera parte del documento: Fundamentos, contexto y arquitectura de Apache Kafka.

A lo largo de sus ocho apartados estudiamos la transición desde el procesamiento batch hacia los eventos, el origen y evolución de Kafka, sus principales componentes, su arquitectura distribuida, las diferencias entre enfoques temporales de procesamiento, su integración con el ecosistema Big Data y sus aplicaciones empresariales.

Ya contamos con la base conceptual necesaria para avanzar hacia la operación de Kafka dentro de nuestra infraestructura Docker.

La segunda parte estará orientada a comprender cómo se administran los tópicos, cómo se publican y consumen eventos, cómo se integran fuentes externas y cómo se relaciona Kafka con Spark Structured Streaming.


