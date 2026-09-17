# Semana 7  — Guía de Ejercicios - Radiografía de Hive y HDFS
## Datos, metadatos y persistencia

# Paso 1 de 5 — ¿Dónde estamos realmente?

## 1. El problema que queremos comprender

Durante las actividades anteriores hemos trabajado con comandos como:

```bash
hdfs dfs -mkdir
hdfs dfs -put
hdfs dfs -ls
````

También hemos utilizado Hive:

```sql
SHOW TABLES;
DESCRIBE FORMATTED ventas_hive;
SELECT * FROM ventas_hive;
```

Sin embargo, puede surgir una pregunta muy importante:

> **¿Dónde están ocurriendo realmente todas estas operaciones?**

Incluso puede aparecer una situación aparentemente contradictoria:

> **Si almacené un archivo en HDFS, ¿por qué podría dejar de encontrarlo después de reiniciar, detener o recrear parte de mi infraestructura?**

Para responder correctamente esta pregunta debemos comprender primero las diferentes capas que forman nuestro laboratorio.

---

# 2. Una infraestructura formada por capas

Nuestro entorno no está compuesto solamente por Hive o HDFS.

Cuando trabajamos desde nuestro computador seguimos aproximadamente este recorrido:

```text
COMPUTADOR PERSONAL
        │
        │ SSH
        ▼
INSTANCIA AWS EC2
        │
        │ ejecuta Docker
        ▼
CONTENEDORES
        │
        ├── namenode
        ├── datanode
        ├── hive-server
        ├── hive-metastore
        └── hive-metastore-postgresql
```

Cada elemento cumple una función diferente.

Por tanto, una primera regla será:

> **No debemos confundir la infraestructura que ejecuta un servicio con el servicio mismo.**

---

# 3. Capa 1 — Nuestro computador

Antes de conectarnos a AWS estamos trabajando en nuestro propio computador.

Por ejemplo:

```bash
pwd
```

```bash
hostname
```

```bash
ls
```

Estos comandos permiten observar el entorno local.

Podemos representarlo como:

```text
┌──────────────────────────┐
│   COMPUTADOR PERSONAL    │
│                          │
│ archivos locales         │
│ cliente SSH              │
└──────────────────────────┘
```

En este momento todavía no estamos dentro de la instancia EC2, de Docker, de HDFS ni de Hive.

---

# 4. Capa 2 — La instancia AWS EC2

Nos conectamos mediante SSH:

```bash
ssh -i archivo.pem usuario@DNS_PUBLICO
```

Después de conectarnos vuelva a ejecutar:

```bash
hostname
```

```bash
pwd
```

```bash
ls
```

Compare los resultados con los obtenidos anteriormente.

Nuestro contexto ahora es:

```text
COMPUTADOR PERSONAL
        │
        │ SSH
        ▼
┌──────────────────────────┐
│        AWS EC2           │
│                          │
│ sistema operativo Linux  │
│ Docker                   │
│ archivos del host        │
└──────────────────────────┘
```

Estamos trabajando en otro computador: una máquina virtual ejecutada en la infraestructura de AWS.

---

# 5. Primera comprobación

Desde EC2 cree un pequeño archivo:

```bash
echo "Estoy en EC2" > prueba_ec2.txt
```

Compruebe:

```bash
cat prueba_ec2.txt
```

y:

```bash
ls -lh prueba_ec2.txt
```

Pregúntese:

> **¿Este archivo está almacenado en HDFS?**

La respuesta es:

```text
NO
```

Hasta este momento solamente hemos creado un archivo en el sistema de archivos Linux de la instancia EC2.

Conceptualmente:

```text
EC2
 │
 └── prueba_ec2.txt

HDFS
 │
 └── ?
```

---

# 6. Capa 3 — Docker

Nuestra instancia EC2 ejecuta Docker.

Compruébelo:

```bash
sudo docker ps
```

Observe los contenedores disponibles.

Para nuestro trabajo con Hive y HDFS resultan especialmente importantes:

```text
namenode

datanode

hive-server

hive-metastore

hive-metastore-postgresql
```

Podemos ampliar nuestro modelo:

```text
AWS EC2
   │
   │ Docker
   ▼
┌─────────────────────────────────┐
│          CONTENEDORES           │
│                                 │
│ namenode                        │
│ datanode                        │
│ hive-server                     │
│ hive-metastore                  │
│ hive-metastore-postgresql       │
└─────────────────────────────────┘
```

---

# 7. No todos los contenedores hacen lo mismo

Aunque todos aparecen mediante:

```bash
sudo docker ps
```

cumplen funciones diferentes.

| Contenedor                  | Función principal                                                   |
| --------------------------- | ------------------------------------------------------------------- |
| `namenode`                  | Coordina el sistema de archivos HDFS y mantiene sus metadatos       |
| `datanode`                  | Almacena bloques de datos de HDFS                                   |
| `hive-server`               | Proporciona el entorno desde el cual trabajamos con Hive            |
| `hive-metastore`            | Proporciona el servicio de metadatos utilizado por Hive             |
| `hive-metastore-postgresql` | Almacena persistentemente la información utilizada por el Metastore |

Por ahora no necesitamos comprender todos sus detalles internos.

Lo importante es reconocer que:

```text
HDFS
≠
Hive
≠
Metastore
≠
PostgreSQL
```

aunque todos formen parte de la misma infraestructura de laboratorio.

---

# 8. Investigar un contenedor

Ingresaremos al contenedor:

```text
hive-server
```

Ejecute desde EC2:

```bash
sudo docker exec -it hive-server bash
```

Ahora vuelva a comprobar:

```bash
hostname
```

```bash
pwd
```

```bash
ls
```

Observe nuevamente el cambio.

Conceptualmente hemos realizado:

```text
COMPUTADOR
     ↓
    SSH
     ↓
AWS EC2
     ↓
docker exec
     ↓
hive-server
```

---

# 9. Una segunda comprobación

Dentro de `hive-server`, intente:

```bash
ls -lh prueba_ec2.txt
```

¿Qué ocurre?

El archivo que creamos anteriormente pertenecía al sistema de archivos del host EC2.

Entrar a un contenedor significa ingresar a **otro entorno de sistema de archivos**.

Por tanto, no debemos asumir:

```text
archivo en EC2
        =
archivo dentro del contenedor
```

Esta distinción será especialmente importante cuando posteriormente trabajemos con archivos que deseamos incorporar a HDFS.

---

# 10. Crear un archivo dentro del contenedor

Ahora, dentro de `hive-server`, ejecute:

```bash
echo "Estoy dentro de hive-server" > /tmp/prueba_hive_server.txt
```

Compruebe:

```bash
cat /tmp/prueba_hive_server.txt
```

Tenemos ahora dos archivos conceptualmente diferentes:

```text
AWS EC2
│
└── prueba_ec2.txt


CONTENEDOR hive-server
│
└── /tmp/prueba_hive_server.txt
```

Ninguno de ellos ha sido incorporado todavía a HDFS.

---

# 11. Capa 4 — HDFS

Desde `hive-server` podemos consultar HDFS mediante:

```bash
hdfs dfs -ls /
```

Observe cuidadosamente que ahora utilizamos:

```text
hdfs dfs
```

Esto significa que ya no estamos preguntando al sistema de archivos Linux:

```bash
ls /
```

sino al sistema de archivos distribuido:

```bash
hdfs dfs -ls /
```

Compare:

```text
LINUX
ls /

        ≠

HDFS
hdfs dfs -ls /
```

---

# 12. Tres lugares diferentes

En este momento ya podemos distinguir:

```text
1. SISTEMA DE ARCHIVOS DE EC2

prueba_ec2.txt


2. SISTEMA DE ARCHIVOS DEL CONTENEDOR

/tmp/prueba_hive_server.txt


3. HDFS

hdfs dfs -ls /
```

Que un archivo exista en uno de estos lugares **no significa que exista automáticamente en los otros**.

Esta es una de las ideas centrales de esta guía.

---

# 13. Capa 5 — Hive

Todavía dentro de `hive-server`, podemos iniciar Hive:

```bash
cd /opt/hive/bin
```

```bash
./hive
```

Ahora ejecute:

```sql
SHOW DATABASES;
```

y, si ya realizó las actividades anteriores:

```sql
USE curso_bigdata;
```

```sql
SHOW TABLES;
```

Observe que hemos cambiado nuevamente de contexto.

Ahora estamos consultando:

```text
HIVE
```

No estamos listando archivos Linux ni archivos HDFS.

---

# 14. Cuatro preguntas diferentes

Compare:

### Linux en EC2

```bash
ls
```

Pregunta:

> ¿Qué archivos existen en este directorio del host EC2?

---

### Linux dentro de `hive-server`

```bash
ls
```

Pregunta:

> ¿Qué archivos existen en este directorio dentro del contenedor?

---

### HDFS

```bash
hdfs dfs -ls /
```

Pregunta:

> ¿Qué archivos o directorios existen en HDFS?

---

### Hive

```sql
SHOW TABLES;
```

Pregunta:

> ¿Qué tablas conoce Hive en la base de datos seleccionada?

Los cuatro comandos pueden mostrar “cosas que existen”, pero están consultando **sistemas diferentes**.

---

# 15. Construir nuestro primer mapa

Hasta este momento podemos representar el laboratorio así:

```text
┌────────────────────────────┐
│    COMPUTADOR PERSONAL     │
└─────────────┬──────────────┘
              │
             SSH
              │
              ▼
┌────────────────────────────┐
│          AWS EC2           │
│                            │
│ sistema de archivos Linux  │
│ Docker                     │
└─────────────┬──────────────┘
              │
             Docker
              │
              ▼
┌───────────────────────────────────────────┐
│               CONTENEDORES                │
│                                           │
│  namenode      datanode                   │
│                                           │
│  hive-server   hive-metastore             │
│                                           │
│  hive-metastore-postgresql                │
└───────────────────────────────────────────┘
```

Sobre estos contenedores funcionan diferentes servicios:

```text
CONTENEDORES
     │
     ├── HDFS
     │     ├── NameNode
     │     └── DataNode
     │
     └── HIVE
           ├── hive-server
           ├── Hive Metastore
           └── PostgreSQL
```

---

# 16. Una distinción fundamental

A partir de ahora debemos evitar expresiones ambiguas como:

> “Guardé el archivo en AWS.”

Técnicamente esa frase no nos entrega suficiente información.

Deberíamos poder precisar:

```text
¿En el sistema de archivos de EC2?

¿Dentro de un contenedor?

¿En HDFS?

¿En qué contenedor?

¿Como datos?

¿Como metadatos?
```

La ubicación importa porque cada capa posee un comportamiento diferente.

---

# 17. Primer indicio sobre la persistencia

Ahora podemos comenzar a comprender por qué la pregunta:

> **¿Por qué desaparecieron mis datos después de reiniciar?**

no puede responderse solamente diciendo:

```text
"porque estaba en AWS"
```

o:

```text
"porque estaba en Docker"
```

Primero necesitamos saber:

```text
¿DÓNDE ESTABAN?
       ↓
EC2
contenedor
HDFS
Hive
       ↓
¿CÓMO ESTABA CONFIGURADO
EL ALMACENAMIENTO?
```

Durante los próximos pasos investigaremos precisamente esta pregunta.

---

# 18. Verificación del Paso 1

Antes de continuar, complete mentalmente el siguiente mapa:

```text
COMPUTADOR
    ↓
__________
    ↓
AWS EC2
    ↓
__________
    ↓
CONTENEDORES
    ↓
┌───────────────┬───────────────┐
│               │               │
HDFS           HIVE         METASTORE
│               │               │
▼               ▼               ▼
__________   hive-server    __________
│
▼
__________
```

Debería poder identificar:

```text
SSH
Docker
NameNode
DataNode
PostgreSQL
```

y explicar qué función general cumple cada uno.

---

# 19. Autoevaluación

Sin ejecutar comandos, intente responder:

1. ¿Es lo mismo crear un archivo en EC2 que almacenarlo en HDFS?
2. ¿Es lo mismo el sistema de archivos de `hive-server` que el sistema de archivos de EC2?
3. ¿Qué diferencia existe entre `ls` y `hdfs dfs -ls`?
4. ¿Qué diferencia existe entre `hdfs dfs -ls` y `SHOW TABLES;`?
5. ¿Qué componente administra HDFS?
6. ¿Qué componente utilizamos para trabajar con Hive?
7. ¿Dónde interviene el Hive Metastore?
8. ¿Por qué decir simplemente “mis datos están en AWS” resulta insuficiente?

Si alguna de estas preguntas todavía genera dudas, revise nuevamente el mapa de capas antes de continuar.

---

# 20. Resultado del Paso 1

Hemos descubierto que nuestro laboratorio no es:

```text
AWS
 ↓
Hive
```

sino una infraestructura formada por diferentes capas:

```text
COMPUTADOR PERSONAL
        ↓
       SSH
        ↓
      AWS EC2
        ↓
      DOCKER
        ↓
   CONTENEDORES
        ↓
 ┌──────┴──────────────┐
 │                     │
HDFS                  HIVE
 │                     │
 ├── NameNode          ├── hive-server
 │                     │
 └── DataNode          └── Hive Metastore
                              │
                              ▼
                          PostgreSQL
```

Y hemos aprendido una primera regla fundamental:

> **Antes de preguntarnos por qué un dato persiste o desaparece, debemos identificar exactamente dónde estaba almacenado.**

En el **Paso 2** utilizaremos esta arquitectura para responder una pregunta más específica:

> **¿Dónde están realmente los datos que almacenamos en HDFS?**

Investigaremos la relación entre:

```text
ARCHIVO
   ↓
HDFS
   ↓
NAMENODE
   ↓
BLOQUES
   ↓
DATANODE
```

y comenzaremos a distinguir entre **los datos que ve el usuario mediante HDFS y la infraestructura que hace posible su almacenamiento**.

---

# Paso 2 de 5 — ¿Dónde están realmente los datos de HDFS?

## 1. El problema que queremos comprender

En el Paso 1 identificamos diferentes capas de nuestro laboratorio:

```text
COMPUTADOR PERSONAL
        ↓
       SSH
        ↓
      AWS EC2
        ↓
      DOCKER
        ↓
   CONTENEDORES
        ↓
 ┌──────┴──────────────┐
 │                     │
HDFS                  HIVE
````

También comprobamos que no es lo mismo almacenar un archivo:

```text
en EC2
```

que:

```text
dentro de un contenedor
```

o:

```text
en HDFS
```

Ahora investigaremos una pregunta más específica:

> **Cuando ejecutamos `hdfs dfs -put`, ¿dónde quedan realmente almacenados los datos?**

Para responderla debemos mirar HDFS desde dos perspectivas:

```text
PERSPECTIVA DEL USUARIO
        ↓
archivos y directorios

        +

PERSPECTIVA DE LA INFRAESTRUCTURA
        ↓
NameNode + DataNode + bloques
```

---

# 2. Recordemos la arquitectura de HDFS

En nuestro laboratorio tenemos dos contenedores especialmente importantes:

```text
namenode

datanode
```

Ambos participan en HDFS, pero cumplen funciones diferentes.

Conceptualmente:

```text
                    HDFS
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
       NameNode               DataNode
           │                     │
           ▼                     ▼
     METADATOS                  DATOS
```

Esta distinción será el centro de este paso.

---

# 3. Crear un archivo exclusivo para esta guía

No utilizaremos el dataset de 100.000 registros de la actividad anterior.

Queremos estudiar la infraestructura sin modificar los datos utilizados en otros ejercicios.

Desde el contenedor `hive-server`, cree:

```bash
cat > /tmp/radiografia_hdfs.txt <<EOF
Registro 1 - Apache Hadoop
Registro 2 - HDFS
Registro 3 - Apache Hive
Registro 4 - NameNode
Registro 5 - DataNode
EOF
```

Compruebe:

```bash
cat /tmp/radiografia_hdfs.txt
```

Luego:

```bash
ls -lh /tmp/radiografia_hdfs.txt
```

En este momento tenemos:

```text
hive-server
      │
      └── /tmp/radiografia_hdfs.txt
```

Todavía **no está almacenado en HDFS**.

---

# 4. Comprobar que HDFS no conoce todavía el archivo

Ejecute:

```bash
hdfs dfs -ls /curso/radiografia
```

Si el directorio todavía no existe, HDFS indicará que no puede encontrarlo.

Esto es importante.

El hecho de que podamos ejecutar:

```bash
cat /tmp/radiografia_hdfs.txt
```

no significa que podamos ejecutar:

```bash
hdfs dfs -cat /curso/radiografia/radiografia_hdfs.txt
```

Son sistemas de archivos diferentes.

---

# 5. Crear una ubicación en HDFS

Ejecute:

```bash
hdfs dfs -mkdir -p /curso/radiografia
```

Verifique:

```bash
hdfs dfs -ls /curso
```

Ahora existe:

```text
/curso/radiografia
```

pero todavía no contiene nuestro archivo.

Compruébelo:

```bash
hdfs dfs -ls /curso/radiografia
```

---

# 6. Incorporar el archivo a HDFS

Ahora ejecute:

```bash
hdfs dfs -put /tmp/radiografia_hdfs.txt /curso/radiografia/
```

Verifique inmediatamente:

```bash
hdfs dfs -ls /curso/radiografia/
```

Debería encontrar:

```text
radiografia_hdfs.txt
```

También podemos recuperar su contenido:

```bash
hdfs dfs -cat /curso/radiografia/radiografia_hdfs.txt
```

Ahora tenemos dos representaciones:

```text
SISTEMA LOCAL DEL CONTENEDOR

/tmp/radiografia_hdfs.txt

            │
            │ hdfs dfs -put
            ▼

HDFS

/curso/radiografia/radiografia_hdfs.txt
```

---

# 7. Una pregunta importante

Después de ejecutar:

```bash
hdfs dfs -put
```

podría parecer que HDFS simplemente creó otra carpeta denominada:

```text
/curso/radiografia
```

en algún disco.

Pero HDFS funciona de una manera diferente.

Lo que nosotros observamos es una **visión lógica**:

```text
/
└── curso
    └── radiografia
        └── radiografia_hdfs.txt
```

Debajo de esta representación intervienen diferentes componentes.

---

# 8. Preguntar a HDFS por el archivo

Podemos solicitar información más detallada mediante:

```bash
hdfs fsck /curso/radiografia/radiografia_hdfs.txt -files -blocks -locations
```

Observe cuidadosamente la salida.

No es necesario comprender todavía cada línea.

Busque información relacionada con:

```text
archivo

tamaño

bloques

ubicaciones
```

Esta operación nos permite comenzar a observar el archivo desde la perspectiva interna de HDFS.

---

# 9. Archivo lógico versus bloques

Desde nuestra perspectiva tenemos:

```text
radiografia_hdfs.txt
```

Pero HDFS administra los archivos mediante bloques.

Conceptualmente:

```text
ARCHIVO HDFS
radiografia_hdfs.txt
        │
        ▼
      BLOQUE
        │
        ▼
     DATANODE
```

Nuestro archivo es extremadamente pequeño, por lo que normalmente requerirá solamente un bloque.

Sin embargo, imagine un archivo mucho mayor:

```text
archivo_grande.csv
        │
        ├── bloque 1
        ├── bloque 2
        ├── bloque 3
        └── bloque 4
```

Los bloques son la unidad con la que HDFS organiza físicamente los datos.

---

# 10. ¿Qué sabe el NameNode?

El NameNode no debe interpretarse como el lugar donde almacenamos normalmente el contenido de nuestros archivos.

Su función principal consiste en mantener información acerca del sistema de archivos.

Conceptualmente puede responder preguntas como:

```text
¿Qué archivos existen?

¿En qué directorios están?

¿Qué bloques pertenecen a cada archivo?

¿En qué DataNode se encuentra cada bloque?
```

Podemos representarlo como:

```text
NAMENODE

/curso/radiografia/radiografia_hdfs.txt
                │
                ▼
            bloque X
                │
                ▼
            DataNode
```

Es decir:

> **El NameNode mantiene el mapa necesario para localizar los datos.**

---

# 11. ¿Qué hace el DataNode?

El DataNode cumple otra función.

Allí se almacenan los bloques que contienen los datos.

Conceptualmente:

```text
NAMENODE
   │
   │ sabe dónde
   ▼
BLOQUE X
   │
   │ está almacenado en
   ▼
DATANODE
```

Por tanto:

```text
NameNode
↓
metadatos de HDFS

DataNode
↓
bloques de datos
```

---

# 12. Observar nuestros contenedores

Abra otra conexión SSH hacia EC2 o salga temporalmente del contenedor.

Desde EC2 ejecute:

```bash
sudo docker ps
```

Localice:

```text
namenode
```

y:

```text
datanode
```

Ahora podemos relacionar lo que acabamos de estudiar con componentes reales de nuestra infraestructura:

```text
AWS EC2
   │
   ▼
Docker
   │
   ├── namenode
   │      ↓
   │   metadatos HDFS
   │
   └── datanode
          ↓
       bloques
```

No estamos hablando solamente de conceptos teóricos.

En nuestro laboratorio existen contenedores diferentes que desempeñan estas funciones.

---

# 13. Observar el NameNode

Desde EC2 podemos ingresar al contenedor:

```bash
sudo docker exec -it namenode bash
```

Compruebe:

```bash
hostname
```

La salida debería permitir reconocer que estamos dentro del contenedor correspondiente al NameNode.

No modificaremos archivos internos.

Nuestro objetivo es simplemente comprobar que:

```text
namenode
```

es un componente independiente de:

```text
hive-server
```

Salga del contenedor:

```bash
exit
```

---

# 14. Observar el DataNode

Ahora ingrese:

```bash
sudo docker exec -it datanode bash
```

Compruebe:

```bash
hostname
```

Nuevamente, no modificaremos archivos internos.

Estamos verificando que el DataNode también posee su propio entorno.

Salga:

```bash
exit
```

Nuestro mapa comienza a ser más concreto:

```text
EC2
 │
 └── Docker
      │
      ├── namenode
      │
      │     metadatos HDFS
      │
      └── datanode
            bloques de datos
```

---

# 15. No buscar el archivo por su nombre dentro del DataNode

Aquí aparece una idea importante.

No deberíamos esperar encontrar dentro del DataNode algo tan simple como:

```text
/curso/radiografia/radiografia_hdfs.txt
```

La ruta:

```text
/curso/radiografia/radiografia_hdfs.txt
```

pertenece a la **representación lógica de HDFS**.

Internamente HDFS administra:

```text
bloques
identificadores
metadatos
ubicaciones
```

Por eso utilizamos:

```bash
hdfs dfs -ls
```

para explorar la estructura lógica de HDFS.

No utilizamos el sistema de archivos interno del DataNode como mecanismo habitual para buscar nuestros archivos.

---

# 16. Una analogía útil

Podemos pensar en el NameNode como un catálogo:

```text
ARCHIVO
radiografia_hdfs.txt

RUTA
/curso/radiografia/

BLOQUE
blk_...

UBICACIÓN
DataNode ...
```

Mientras que el DataNode contiene:

```text
blk_...
```

El usuario ve:

```text
/curso/radiografia/radiografia_hdfs.txt
```

HDFS se encarga de traducir esa representación lógica hacia la infraestructura que almacena los bloques.

---

# 17. Comprobar que el archivo local y el archivo HDFS son independientes

Regrese a `hive-server`:

```bash
sudo docker exec -it hive-server bash
```

Compruebe:

```bash
ls -lh /tmp/radiografia_hdfs.txt
```

y:

```bash
hdfs dfs -ls /curso/radiografia/
```

Tenemos:

```text
CONTENEDOR

/tmp/radiografia_hdfs.txt

        +

HDFS

/curso/radiografia/radiografia_hdfs.txt
```

Ahora eliminaremos **solamente la copia local del contenedor**:

```bash
rm /tmp/radiografia_hdfs.txt
```

Compruebe:

```bash
ls -lh /tmp/radiografia_hdfs.txt
```

El archivo local ya no debería existir.

---

# 18. ¿Qué ocurrió con HDFS?

Ejecute:

```bash
hdfs dfs -ls /curso/radiografia/
```

Luego:

```bash
hdfs dfs -cat /curso/radiografia/radiografia_hdfs.txt
```

El archivo almacenado en HDFS debería continuar disponible.

Por tanto:

```text
ELIMINAMOS

/tmp/radiografia_hdfs.txt
       ↓
archivo local


NO ELIMINAMOS

/curso/radiografia/radiografia_hdfs.txt
       ↓
archivo HDFS
```

Esto demuestra experimentalmente que:

> **La copia local y la copia almacenada en HDFS son objetos diferentes.**

---

# 19. Entonces, ¿dónde está nuestro archivo?

La respuesta tiene dos niveles.

## Desde la perspectiva del usuario

Está en:

```text
/curso/radiografia/radiografia_hdfs.txt
```

dentro de HDFS.

## Desde la perspectiva de la infraestructura

HDFS mantiene:

```text
NAMENODE
   ↓
metadatos que describen el archivo
y permiten localizar sus bloques

        +

DATANODE
   ↓
bloques que contienen los datos
```

Podemos representarlo como:

```text
USUARIO

/curso/radiografia/radiografia_hdfs.txt
                  │
                  ▼
                HDFS
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
    NAMENODE             DATANODE
        │                   │
        ▼                   ▼
   METADATOS              BLOQUES
```

---

# 20. Pero aparece una nueva pregunta

Hasta ahora hemos comprobado que eliminar:

```text
/tmp/radiografia_hdfs.txt
```

no elimina:

```text
/curso/radiografia/radiografia_hdfs.txt
```

Podríamos concluir apresuradamente:

> “Entonces, si está en HDFS, nunca se pierde.”

Esa conclusión sería incorrecta.

Debemos formular una pregunta adicional:

> **¿Dónde están almacenados físicamente los datos y metadatos utilizados por los contenedores `namenode` y `datanode`?**

Recordemos:

```text
HDFS
   ↓
NameNode + DataNode
   ↓
contenedores Docker
   ↓
AWS EC2
```

Por tanto, todavía debemos investigar:

```text
¿Qué ocurre con la información
cuando un contenedor se reinicia?

¿Qué ocurre si se elimina?

¿Qué ocurre si la instancia EC2
se detiene o se recrea?
```

Estas preguntas serán abordadas más adelante.

---

# 21. Una distinción fundamental

Después de este experimento podemos afirmar:

```text
ARCHIVO LOCAL
≠
ARCHIVO HDFS
```

Pero todavía **no** podemos afirmar:

```text
ARCHIVO HDFS
=
ARCHIVO PERMANENTE PARA SIEMPRE
```

La persistencia depende también de cómo está configurada la infraestructura que soporta HDFS.

Este punto será fundamental en los pasos siguientes.

---

# 22. Verificación del Paso 2

Compruebe que puede explicar el siguiente recorrido:

```text
/tmp/radiografia_hdfs.txt
        │
        │ hdfs dfs -put
        ▼
       HDFS
        │
        ▼
/curso/radiografia/radiografia_hdfs.txt
        │
        ▼
      BLOQUES
        │
        ▼
     DATANODE
```

Mientras:

```text
NAMENODE
    │
    ▼
mantiene la información necesaria
para conocer la estructura de HDFS
y localizar los bloques
```

---

# 23. Autoevaluación

Sin ejecutar nuevos comandos, responda:

1. ¿Es lo mismo `/tmp/radiografia_hdfs.txt` que `/curso/radiografia/radiografia_hdfs.txt`?
2. ¿Qué operación utilizamos para incorporar el archivo a HDFS?
3. ¿Qué representa la ruta `/curso/radiografia/`?
4. ¿Qué información mantiene el NameNode?
5. ¿Dónde se almacenan los bloques de datos?
6. ¿Por qué no debemos buscar normalmente nuestros archivos por nombre dentro del DataNode?
7. ¿Qué demuestra eliminar el archivo local y continuar accediendo a su copia HDFS?
8. ¿Podemos concluir que un archivo en HDFS será permanente independientemente de lo que ocurra con Docker o EC2?

La respuesta a la última pregunta debe ser:

```text
NO
```

Todavía necesitamos comprender cómo persiste la infraestructura que sostiene HDFS.

---

# 24. Resultado del Paso 2

Ahora nuestro mapa es más preciso:

```text
                    AWS EC2
                       │
                     Docker
                       │
             ┌─────────┴─────────┐
             │                   │
         NAMENODE             DATANODE
             │                   │
             ▼                   ▼
      METADATOS HDFS         BLOQUES
             │                   │
             └─────────┬─────────┘
                       │
                       ▼
                      HDFS
                       │
                       ▼
 /curso/radiografia/radiografia_hdfs.txt
```

Desde la perspectiva del estudiante:

```text
ARCHIVO
   ↓
hdfs dfs -put
   ↓
HDFS
```

Desde la perspectiva de la infraestructura:

```text
HDFS
   ↓
┌───────────────┬───────────────┐
│                               │
NameNode                      DataNode
│                               │
metadatos                      bloques
```

La idea central de este paso es:

> **HDFS nos presenta archivos y directorios como una estructura lógica, pero esa estructura es posible gracias a la coordinación entre los metadatos administrados por el NameNode y los bloques almacenados por los DataNodes.**

---

# 25. Próximo paso

Ya sabemos dónde están los **datos**.

Ahora aparece otra pregunta.

Cuando en Hive ejecutamos:

```sql
CREATE EXTERNAL TABLE ...
```

Hive conoce:

```text
nombre de la tabla
columnas
tipos de datos
formato
LOCATION
```

Pero esa información:

> **¿dónde está almacenada?**

En el **Paso 3** seguiremos el recorrido:

```text
HIVE
  ↓
TABLA
  ↓
METADATOS
  ↓
HIVE METASTORE
  ↓
POSTGRESQL
```

y comprobaremos que los metadatos de Hive y los datos almacenados en HDFS son dos elementos diferentes de nuestra infraestructura.

---

# Paso 3 de 5 — ¿Dónde están realmente los metadatos de Hive?

## 1. El problema que queremos comprender

En el Paso 2 comprobamos que cuando almacenamos un archivo en HDFS intervienen dos componentes fundamentales:

```text
HDFS
 │
 ├── NameNode
 │      ↓
 │   metadatos HDFS
 │
 └── DataNode
        ↓
     bloques de datos
````

Ahora cambiaremos nuestra atención hacia Hive.

Cuando ejecutamos una instrucción como:

```sql
CREATE EXTERNAL TABLE ventas_hive (
    id_venta INT,
    fecha STRING,
    cliente STRING,
    ciudad STRING,
    categoria STRING,
    monto DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '/curso/hive/datos_ventas/';
```

Hive necesita recordar información como:

```text
nombre de la tabla

base de datos

columnas

tipos de datos

formato

ubicación en HDFS
```

La pregunta que investigaremos es:

> **¿Dónde se almacena toda esta información?**

Nuestro recorrido será:

```text
HIVE
  ↓
TABLA
  ↓
METADATOS
  ↓
HIVE METASTORE
  ↓
POSTGRESQL
```

---

# 2. Datos y metadatos no son lo mismo

Recordemos nuestra tabla:

```text
ventas_hive
```

Los registros se encuentran en:

```text
HDFS
/curso/hive/datos_ventas/
```

Pero Hive necesita información adicional para poder interpretarlos.

Por ejemplo:

```text
TABLA
ventas_hive

COLUMNAS
id_venta
fecha
cliente
ciudad
categoria
monto

TIPOS
INT
STRING
STRING
STRING
STRING
DOUBLE

LOCATION
/curso/hive/datos_ventas/
```

Podemos separar:

```text
DATOS
  ↓
HDFS

       ≠

METADATOS
  ↓
Hive Metastore
```

Esta diferencia será el centro de nuestro experimento.

---

# 3. Consultar los metadatos desde Hive

Ingrese desde EC2 al contenedor:

```bash
sudo docker exec -it hive-server bash
```

Luego:

```bash
cd /opt/hive/bin
```

```bash
./hive
```

Seleccione:

```sql
USE curso_bigdata;
```

Compruebe:

```sql
SHOW TABLES;
```

Debería encontrar:

```text
ventas_hive
```

Ahora ejecute:

```sql
DESCRIBE ventas_hive;
```

Hive debería mostrar las columnas y sus tipos.

Finalmente:

```sql
DESCRIBE FORMATTED ventas_hive;
```

Busque especialmente información relacionada con:

```text
Database
Table
Table Type
Location
InputFormat
OutputFormat
```

Estamos consultando:

```text
METADATOS
```

y no directamente el contenido del archivo CSV.

---

# 4. Una pregunta importante

¿Cómo puede Hive recordar esta información?

Si salimos del cliente:

```text
./hive
```

y posteriormente volvemos a entrar, la tabla continúa existiendo.

Incluso si diferentes clientes Hive necesitan acceder a la misma tabla, todos deben disponer de una descripción común.

Por eso Hive utiliza un componente específico:

```text
HIVE METASTORE
```

Conceptualmente:

```text
hive-server
     │
     │ consulta
     ▼
Hive Metastore
     │
     ▼
metadatos
```

---

# 5. Observar la infraestructura real

Salga del cliente Hive:

```sql
quit;
```

Luego salga del contenedor si es necesario:

```bash
exit
```

Desde EC2 ejecute:

```bash
sudo docker ps
```

Busque:

```text
hive-server
hive-metastore
hive-metastore-postgresql
```

Observe que se trata de contenedores diferentes.

Nuestro entorno implementa conceptualmente:

```text
hive-server
      │
      ▼
hive-metastore
      │
      ▼
hive-metastore-postgresql
```

Esto nos permite observar físicamente componentes que normalmente podrían permanecer ocultos para el usuario.

---

# 6. Hive Metastore y PostgreSQL tampoco son lo mismo

Debemos introducir una nueva distinción.

```text
HIVE METASTORE
```

es el servicio que administra y proporciona acceso a los metadatos de Hive.

En nuestra infraestructura utiliza:

```text
POSTGRESQL
```

para almacenarlos.

Conceptualmente:

```text
HIVE
 │
 ▼
HIVE METASTORE
 │
 │ administra
 ▼
POSTGRESQL
 │
 ▼
METADATOS
```

Por tanto:

```text
Hive Metastore
≠
PostgreSQL
```

Uno proporciona el **servicio de metadatos**.

El otro proporciona el **almacenamiento de esos metadatos**.

---

# 7. Ingresar al contenedor PostgreSQL

Desde EC2 ejecute:

```bash
sudo docker exec -it hive-metastore-postgresql bash
```

Compruebe:

```bash
hostname
```

Ahora estamos dentro de otro contenedor.

Nuestro recorrido ha sido:

```text
COMPUTADOR
    ↓
   SSH
    ↓
  AWS EC2
    ↓
docker exec
    ↓
hive-metastore-postgresql
```

No estamos dentro de:

```text
hive-server
```

ni de:

```text
namenode
```

ni de:

```text
datanode
```

Estamos observando el componente que almacena los metadatos utilizados por Hive.

---

# 8. Acceder a PostgreSQL

Dentro del contenedor ejecute:

```bash
psql -U hive
```

Si la infraestructura solicita explícitamente la base de datos, utilice:

```bash
psql -U hive -d metastore
```

Al ingresar debería aparecer un prompt de PostgreSQL similar a:

```text
metastore=#
```

Importante:

> **No modificaremos ninguna tabla de PostgreSQL.**

Durante este laboratorio realizaremos exclusivamente operaciones de consulta.

No utilice:

```text
DELETE
UPDATE
INSERT
DROP
ALTER
```

sobre las tablas internas del Metastore.

---

# 9. Observar las bases de datos

Dentro de PostgreSQL ejecute:

```text
\l
```

Este comando permite listar las bases de datos.

Observe si aparece:

```text
metastore
```

Si todavía no está conectado a ella:

```text
\c metastore
```

Ahora estamos observando la base de datos utilizada para almacenar los metadatos de Hive.

---

# 10. Observar las tablas internas

Ejecute:

```text
\dt
```

Debería aparecer un conjunto importante de tablas.

No necesitamos comprenderlas todas.

Busque especialmente nombres relacionados con:

```text
DBS

TBLS

SDS

COLUMNS_V2
```

Estas tablas forman parte del esquema interno utilizado por el Hive Metastore.

Conceptualmente podemos relacionarlas con:

```text
DBS
 ↓
bases de datos Hive

TBLS
 ↓
tablas Hive

SDS
 ↓
información de almacenamiento

COLUMNS_V2
 ↓
columnas y tipos
```

No memorice estos nombres.

El objetivo es comprobar que aquello que vemos desde Hive como:

```text
curso_bigdata
ventas_hive
id_venta
fecha
cliente
...
```

posee una representación almacenada en PostgreSQL.

---

# 11. Buscar nuestra base de datos

Ejecute:

```sql
SELECT "DB_ID", "NAME"
FROM "DBS";
```

Busque:

```text
curso_bigdata
```

Si aparece, hemos encontrado en PostgreSQL una representación de la base de datos que anteriormente consultábamos desde Hive mediante:

```sql
SHOW DATABASES;
```

Compare:

```text
HIVE

SHOW DATABASES;
       ↓
curso_bigdata
```

con:

```text
POSTGRESQL

DBS
 ↓
curso_bigdata
```

Estamos observando el mismo concepto desde dos niveles diferentes.

---

# 12. Buscar nuestra tabla

Ahora ejecute:

```sql
SELECT "TBL_ID", "TBL_NAME", "DB_ID", "SD_ID"
FROM "TBLS"
WHERE "TBL_NAME" = 'ventas_hive';
```

Debería aparecer un registro correspondiente a:

```text
ventas_hive
```

Observe especialmente los identificadores:

```text
TBL_ID

DB_ID

SD_ID
```

No necesitamos memorizar sus valores.

Lo importante es comprender que PostgreSQL mantiene relaciones que permiten al Metastore representar nuestra tabla.

---

# 13. Relacionar la tabla con la base de datos

Podemos consultar ambas estructuras:

```sql
SELECT
    t."TBL_NAME",
    d."NAME" AS database_name
FROM "TBLS" t
JOIN "DBS" d
    ON t."DB_ID" = d."DB_ID"
WHERE t."TBL_NAME" = 'ventas_hive';
```

Deberíamos obtener conceptualmente:

```text
ventas_hive | curso_bigdata
```

Compare con lo que hacemos normalmente en Hive:

```sql
USE curso_bigdata;

SHOW TABLES;
```

Ahora estamos viendo cómo esa relación se encuentra representada internamente.

---

# 14. ¿Dónde está registrada la ubicación HDFS?

Recuerde que desde Hive podemos ejecutar:

```sql
DESCRIBE FORMATTED ventas_hive;
```

y encontrar:

```text
Location
```

Por ejemplo:

```text
hdfs://.../curso/hive/datos_ventas
```

¿Dónde obtiene Hive esa información?

La tabla:

```text
TBLS
```

mantiene una referencia denominada:

```text
SD_ID
```

hacia información de almacenamiento.

Podemos seguir esa relación.

Ejecute:

```sql
SELECT
    t."TBL_NAME",
    s."LOCATION"
FROM "TBLS" t
JOIN "SDS" s
    ON t."SD_ID" = s."SD_ID"
WHERE t."TBL_NAME" = 'ventas_hive';
```

Busque:

```text
/curso/hive/datos_ventas/
```

o su URI HDFS equivalente.

---

# 15. Acabamos de conectar PostgreSQL con HDFS

Este resultado es especialmente importante.

Desde Hive observamos:

```text
ventas_hive
     │
     │ LOCATION
     ▼
/curso/hive/datos_ventas/
```

Ahora comprobamos que esa relación está representada en los metadatos almacenados por PostgreSQL:

```text
POSTGRESQL
   │
   ├── TBLS
   │      ↓
   │   ventas_hive
   │
   └── SDS
          ↓
       LOCATION
          ↓
       HDFS
```

Por tanto, PostgreSQL **no contiene las 100.000 ventas**.

Contiene información que permite a Hive saber dónde encontrarlas y cómo interpretarlas.

---

# 16. Buscar las columnas

Ahora investigaremos las columnas.

Primero necesitamos identificar el descriptor de columnas asociado a nuestra tabla.

Ejecute:

```sql
SELECT
    t."TBL_NAME",
    s."CD_ID"
FROM "TBLS" t
JOIN "SDS" s
    ON t."SD_ID" = s."SD_ID"
WHERE t."TBL_NAME" = 'ventas_hive';
```

Observe el valor:

```text
CD_ID
```

Ahora podemos relacionarlo con:

```text
COLUMNS_V2
```

mediante:

```sql
SELECT
    c."INTEGER_IDX",
    c."COLUMN_NAME",
    c."TYPE_NAME"
FROM "TBLS" t
JOIN "SDS" s
    ON t."SD_ID" = s."SD_ID"
JOIN "COLUMNS_V2" c
    ON s."CD_ID" = c."CD_ID"
WHERE t."TBL_NAME" = 'ventas_hive'
ORDER BY c."INTEGER_IDX";
```

Deberíamos encontrar conceptualmente:

```text
id_venta     int
fecha        string
cliente      string
ciudad       string
categoria    string
monto        double
```

---

# 17. Compare con Hive

Desde Hive utilizábamos:

```sql
DESCRIBE ventas_hive;
```

y obteníamos:

```text
id_venta
fecha
cliente
ciudad
categoria
monto
```

Ahora hemos encontrado esa información en:

```text
COLUMNS_V2
```

dentro de PostgreSQL.

Podemos representar:

```text
HIVE

DESCRIBE ventas_hive;
        │
        ▼
Hive Metastore
        │
        ▼
PostgreSQL
        │
        ▼
COLUMNS_V2
```

Esto demuestra que la estructura de la tabla no está almacenada dentro del archivo CSV.

---

# 18. Una comprobación especialmente importante

Recordemos dónde están los registros:

```bash
hdfs dfs -ls /curso/hive/datos_ventas/
```

Allí encontramos:

```text
ventas_hive.csv
```

En PostgreSQL encontramos:

```text
ventas_hive
curso_bigdata
columnas
tipos
LOCATION
```

Por tanto:

```text
HDFS
│
└── ventas_hive.csv
      ↓
     DATOS


POSTGRESQL
│
├── curso_bigdata
├── ventas_hive
├── columnas
├── tipos
└── LOCATION
      ↓
   METADATOS
```

---

# 19. Dos tipos de metadatos diferentes

Aquí debemos evitar una nueva confusión.

En el Paso 2 dijimos:

```text
NameNode
↓
metadatos HDFS
```

Ahora decimos:

```text
Hive Metastore
↓
metadatos Hive
```

Ambas afirmaciones son correctas.

Pero **no se trata de los mismos metadatos**.

### NameNode

Conoce aspectos como:

```text
archivo
directorio
bloques
ubicación de bloques
```

### Hive Metastore

Conoce aspectos como:

```text
base de datos
tabla
columnas
tipos
formato
LOCATION
```

Conceptualmente:

```text
                    METADATOS

              ┌─────────┴─────────┐
              │                   │
              ▼                   ▼
       METADATOS HDFS       METADATOS HIVE
              │                   │
              ▼                   ▼
          NameNode          Hive Metastore
                                  │
                                  ▼
                              PostgreSQL
```

---

# 20. PostgreSQL no reemplaza al Metastore

También debemos evitar interpretar:

```text
Hive Metastore = PostgreSQL
```

La relación correcta es:

```text
HIVE
  │
  ▼
HIVE METASTORE
  │
  │ servicio
  ▼
POSTGRESQL
  │
  │ almacenamiento
  ▼
METADATOS
```

El Metastore proporciona el servicio que Hive utiliza para consultar y administrar metadatos.

PostgreSQL permite persistir esa información.

---

# 21. Salir de PostgreSQL

Cuando termine la exploración:

```text
\q
```

Luego:

```bash
exit
```

Regresará a EC2.

No hemos modificado ningún dato ni metadato.

Solamente observamos la arquitectura.

---

# 22. El mapa completo comienza a aparecer

Ahora podemos conectar lo aprendido en los pasos 2 y 3:

```text
                         HIVE
                           │
                           ▼
                      ventas_hive
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       HIVE METASTORE                  HDFS
              │                         │
              ▼                ┌────────┴────────┐
         PostgreSQL            │                 │
              │                ▼                 ▼
              ▼            NameNode          DataNode
          METADATOS            │                 │
              │                ▼                 ▼
              │         metadatos HDFS        bloques
              │                                  │
              └──────── LOCATION ────────────────┘
```

De forma más simple:

```text
POSTGRESQL
    ↓
¿cómo interpretar los datos?

HDFS
    ↓
¿dónde están los datos?
```

---

# 23. Una consecuencia importante

Supongamos que tenemos:

```text
HDFS
/curso/hive/datos_ventas/
└── ventas_hive.csv
```

pero eliminamos la definición de:

```text
ventas_hive
```

del Metastore.

Los datos y los metadatos son elementos diferentes.

También podríamos imaginar la situación inversa:

```text
Metastore
↓
ventas_hive existe

pero

HDFS
↓
el archivo esperado no existe
```

En ambos casos la infraestructura queda inconsistente desde la perspectiva del análisis.

Por eso Hive necesita ambas partes:

```text
METADATOS
     +
DATOS
     ↓
CONSULTA
```

---

# 24. Verificación del Paso 3

Compruebe que puede explicar el siguiente recorrido:

```text
SELECT *
FROM ventas_hive;
       │
       ▼
     HIVE
       │
       ├───────────────┐
       │               │
       ▼               ▼
  METASTORE           HDFS
       │               │
       ▼               ▼
 PostgreSQL      ventas_hive.csv
       │
       ▼
nombre
columnas
tipos
LOCATION
```

Hive necesita:

```text
METASTORE
↓
para saber qué representa la tabla
y cómo interpretar sus datos
```

y:

```text
HDFS
↓
para acceder a los datos
```

---

# 25. Autoevaluación

Sin ejecutar comandos adicionales, responda:

1. ¿Dónde están almacenados los registros de `ventas_hive`?
2. ¿Dónde se almacena la definición de la tabla?
3. ¿Qué función cumple Hive Metastore?
4. ¿Qué función cumple PostgreSQL en nuestra infraestructura?
5. ¿PostgreSQL contiene las 100.000 ventas?
6. ¿Qué información representa `TBLS`?
7. ¿Qué información podemos encontrar mediante `COLUMNS_V2`?
8. ¿Qué relación existe entre `TBLS`, `SDS` y `LOCATION`?
9. ¿Son iguales los metadatos del NameNode y los metadatos del Hive Metastore?
10. ¿Por qué Hive necesita simultáneamente Metastore y HDFS?

---

# 26. Resultado del Paso 3

Ahora podemos responder dos preguntas fundamentales.

### ¿Dónde están los datos?

```text
HDFS
  │
  ▼
DataNode
  │
  ▼
bloques
```

### ¿Dónde están los metadatos de Hive?

```text
Hive Metastore
      │
      ▼
PostgreSQL
      │
      ▼
bases de datos
tablas
columnas
tipos
ubicaciones
```

Nuestro mapa queda:

```text
                    AWS EC2
                       │
                     Docker
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
        HIVE                       HDFS
          │                         │
          ▼                 ┌───────┴───────┐
    Hive Metastore          │               │
          │                 ▼               ▼
          ▼             NameNode         DataNode
     PostgreSQL              │               │
          │                  ▼               ▼
          ▼             metadatos          bloques
   metadatos Hive            HDFS             │
          │                                    │
          └────── LOCATION ────────────────────┘
```

La idea central es:

> **Una tabla Hive no contiene necesariamente los datos. Hive mantiene metadatos que describen cómo interpretar datos almacenados en otra capa, como HDFS.**

---

# 27. Pero todavía falta responder nuestra pregunta original

Ya sabemos que:

```text
DATOS
↓
HDFS
↓
NameNode + DataNode
```

y:

```text
METADATOS HIVE
↓
Hive Metastore
↓
PostgreSQL
```

Pero todos estos componentes están ejecutándose dentro de:

```text
CONTENEDORES DOCKER
```

Entonces aparece la siguiente pregunta:

> **¿Qué ocurre con nuestros datos y metadatos si reiniciamos uno de estos contenedores?**

En el **Paso 4** realizaremos nuestro primer experimento de persistencia:

```text
CREAR / VERIFICAR
        ↓
REINICIAR
        ↓
VOLVER A VERIFICAR
        ↓
COMPARAR
        ↓
EXPLICAR
```

Comprobaremos experimentalmente si reiniciar:

```text
hive-server
```

afecta:

```text
la tabla Hive

los metadatos

los archivos HDFS
```

y comenzaremos a comprender una diferencia fundamental:

> **reiniciar un servicio no es lo mismo que eliminar el almacenamiento que utiliza ese servicio.**

---

# Paso 4 de 5 — ¿Qué persiste y qué puede desaparecer?

Hasta ahora hemos distinguido tres espacios diferentes:

```text
1. Filesystem Linux del contenedor
2. HDFS
3. Metadatos de Hive
```

También comprobamos que Hive utiliza dos sistemas distintos para conservar su información:

```text
Hive
│
├── datos
│      ↓
│     HDFS
│
└── metadatos
       ↓
Hive Metastore
       ↓
PostgreSQL
```

Ahora responderemos una pregunta fundamental:

> **¿Qué ocurre con esta información cuando un contenedor se detiene, se elimina o se vuelve a crear?**

---

## 4.1 El contenedor no es el almacenamiento persistente

Un contenedor Docker puede entenderse como una instancia temporal de ejecución de un servicio.

Por ejemplo:

```text
contenedor namenode
        ↓
ejecuta el servicio NameNode
```

pero eso no significa que los metadatos de HDFS deban quedar almacenados exclusivamente dentro del contenedor.

En nuestra infraestructura actual:

```text
NameNode
   │
   ▼
/hadoop/dfs/name
   │
   ▼
volumen Docker
namenode_data
```

De forma similar:

```text
DataNode
   │
   ▼
/hadoop/dfs/data
   │
   ▼
volumen Docker
datanode_data
```

Por tanto:

```text
Contenedor = ejecuta el servicio
Volumen    = conserva el estado
```

Esta separación es esencial para comprender Docker.

---

## 4.2 Revisar los volúmenes existentes

Desde la máquina Ubuntu o EC2 ejecute:

```bash
sudo docker volume ls
```

Deberían aparecer volúmenes asociados a la infraestructura, entre ellos:

```text
namenode_data
datanode_data
hive_metastore_data
zeppelin_notebooks
hue_mysql_data
kafka_data
streamsets_data
```

Dependiendo del nombre del directorio desde donde se ejecutó Docker Compose, Docker puede agregar un prefijo.

Por ejemplo:

```text
2026-2_namenode_data
2026-2_datanode_data
```

Esto no cambia su función.

### Interpretación

Estos volúmenes existen independientemente del contenedor que los utiliza.

Por tanto:

```text
contenedor eliminado
        ≠
volumen eliminado
```

---

## 4.3 Crear un dato de prueba en HDFS

Comprobaremos esta idea experimentalmente.

Cree un directorio en HDFS:

```bash
sudo docker exec namenode \
  hdfs dfs -mkdir -p /prueba_persistencia
```

Ahora cree un pequeño archivo dentro del contenedor:

```bash
sudo docker exec namenode \
  sh -c 'echo "Este archivo debe sobrevivir a la recreacion de los contenedores" > /tmp/persistencia.txt'
```

Suba el archivo a HDFS:

```bash
sudo docker exec namenode \
  hdfs dfs -put /tmp/persistencia.txt /prueba_persistencia/
```

Compruebe:

```bash
sudo docker exec namenode \
  hdfs dfs -ls /prueba_persistencia
```

y luego:

```bash
sudo docker exec namenode \
  hdfs dfs -cat /prueba_persistencia/persistencia.txt
```

El resultado esperado es:

```text
Este archivo debe sobrevivir a la recreacion de los contenedores
```

Hasta aquí solo hemos comprobado que el archivo existe en HDFS.

Ahora realizaremos la parte realmente importante del experimento.

---

## 4.4 Eliminar los contenedores

Desde el directorio de la infraestructura ejecute:

```bash
sudo docker compose \
  -f docker-compose.yml \
  --env-file hadoop-hive.env \
  down
```

Docker eliminará:

```text
contenedores
red de Docker
```

pero **no eliminará los volúmenes**.

Compruébelo:

```bash
sudo docker volume ls
```

Los volúmenes:

```text
namenode_data
datanode_data
```

deben continuar existiendo.

### Atención

No utilice:

```bash
docker compose down -v
```

La opción:

```text
-v
```

indica expresamente a Docker que también elimine los volúmenes.

En ese caso sí podría perderse la información persistente.

---

## 4.5 Recrear los contenedores

Ahora vuelva a levantar la infraestructura:

```bash
sudo docker compose \
  -f docker-compose.yml \
  --env-file hadoop-hive.env \
  up -d
```

Espere hasta que NameNode y DataNode estén disponibles.

Puede comprobarlo con:

```bash
sudo docker ps
```

Ahora vuelva a consultar el archivo:

```bash
sudo docker exec namenode \
  hdfs dfs -cat /prueba_persistencia/persistencia.txt
```

Si aparece nuevamente:

```text
Este archivo debe sobrevivir a la recreacion de los contenedores
```

hemos demostrado experimentalmente:

```text
crear archivo en HDFS
        ↓
eliminar NameNode y DataNode
        ↓
conservar volúmenes
        ↓
recrear NameNode y DataNode
        ↓
recuperar el mismo archivo
```

---

## 4.6 ¿Qué ocurrió realmente?

El archivo no sobrevivió porque el contenedor fuera permanente.

De hecho, los contenedores anteriores fueron eliminados.

Lo que permaneció fueron:

```text
namenode_data
datanode_data
```

Al crear nuevos contenedores, Docker volvió a conectar esos mismos volúmenes:

```text
nuevo NameNode
      ↓
namenode_data anterior

nuevo DataNode
      ↓
datanode_data anterior
```

Por eso HDFS pudo reconstruir su estado anterior.

---

## 4.7 El mismo principio se aplica a Hive

Hive tiene dos componentes persistentes diferentes.

### Datos

Los datos se encuentran en:

```text
HDFS
```

y dependen de:

```text
namenode_data
datanode_data
```

### Metadatos

Las definiciones de Hive se encuentran en:

```text
Hive Metastore
      ↓
PostgreSQL
      ↓
hive_metastore_data
```

Por ejemplo, si ejecutamos:

```sql
CREATE DATABASE prueba_persistencia;
```

y luego:

```sql
CREATE TABLE prueba_hive (
    id INT,
    mensaje STRING
);
```

la definición de esa tabla se conserva en PostgreSQL.

Si además insertamos:

```sql
INSERT INTO prueba_hive
VALUES (1, 'Registro persistente');
```

ocurren dos cosas diferentes:

```text
Definición de la tabla
        ↓
Hive Metastore
        ↓
PostgreSQL

Datos de la tabla
        ↓
HDFS
```

Por eso, para recuperar completamente una tabla Hive necesitamos conservar **ambos sistemas**.

---

## 4.8 Un experimento mental importante

Imagine que conservamos HDFS, pero perdemos PostgreSQL.

Los archivos podrían seguir existiendo físicamente en HDFS:

```text
/user/hive/warehouse/...
```

pero Hive podría haber perdido información como:

```text
nombre de la tabla
columnas
tipos de datos
formato
LOCATION
base de datos
```

Ahora imagine lo contrario:

```text
Metastore disponible
HDFS perdido
```

Hive podría recordar que existe una tabla, pero sus datos físicos ya no estarían disponibles.

Por tanto:

```text
Hive completo
=
Metastore persistente
+
HDFS persistente
```

---

## 4.9 ¿Qué ocurre con archivos creados dentro del contenedor?

Existe una diferencia importante.

Suponga que entra a:

```bash
sudo docker exec -it hive-server bash
```

y crea:

```bash
echo "archivo temporal" > /tmp/ejemplo.txt
```

Ese archivo está dentro del filesystem de `hive-server`.

Si el contenedor es eliminado y recreado, ese archivo puede desaparecer.

Esto es correcto y esperado.

Por eso el flujo adecuado es:

```text
archivo temporal del contenedor
           ↓
      hdfs dfs -put
           ↓
          HDFS
           ↓
 volumen persistente
```

---

## 4.10 Reiniciar no es lo mismo que recrear

Debemos distinguir varias operaciones:

```text
docker restart
docker compose down / up
reiniciar Ubuntu
detener/iniciar EC2
terminar EC2
```

No producen exactamente el mismo efecto.

En nuestra infraestructura hemos comprobado que los datos persisten frente a:

```text
docker compose down
        +
docker compose up -d
```

y también frente a:

```text
reinicio completo de Ubuntu
```

porque los volúmenes Docker continúan existiendo en el host.

Pero existe una capa superior:

```text
Docker volumes
      ↓
filesystem Ubuntu
      ↓
disco de la máquina
      ↓
EC2 / almacenamiento AWS
```

Por tanto, la persistencia Docker **no significa almacenamiento eterno**.

---

## 4.11 Modelo mental del paso

El estudiante debería poder explicar ahora:

```text
CONTENEDOR
Ejecuta el servicio
Puede ser eliminado y recreado

        ↓

VOLUMEN DOCKER
Conserva el estado del servicio

        ↓

HOST
Almacena físicamente los volúmenes

        ↓

INFRAESTRUCTURA
Determina finalmente si ese almacenamiento continúa existiendo
```

---

## 4.12 Pregunta de reflexión

Suponga que ejecuta:

```bash
docker compose down
```

y posteriormente:

```bash
docker compose up -d
```

La tabla Hive continúa disponible.

¿Significa eso que el contenedor `hive-server` conservó la tabla?

**No.**

La tabla pudo recuperarse porque:

```text
sus metadatos
→ permanecieron en PostgreSQL

sus datos
→ permanecieron en HDFS

los volúmenes
→ sobrevivieron a la eliminación de los contenedores
```

---

### Idea central del Paso 4

> **La persistencia no depende de que un contenedor permanezca vivo. Depende de que el estado relevante se almacene fuera del filesystem efímero del contenedor y de que ese almacenamiento persistente continúe existiendo.**

---

# Paso 5 de 5 — ¿Qué ocurre al detener, reiniciar o recrear AWS?

En el paso anterior comprobamos experimentalmente que los datos almacenados en HDFS pueden sobrevivir incluso cuando eliminamos y recreamos los contenedores.

También comprobamos que sobreviven al reinicio de Ubuntu.

Sin embargo, todavía queda una pregunta:

> **Si los datos están en volúmenes Docker, ¿significa que siempre estarán disponibles aunque apaguemos o eliminemos nuestra instancia AWS?**

La respuesta es **no necesariamente**.

Para entenderlo debemos observar una última capa de la arquitectura.

---

## 5.1 Hasta ahora observábamos Docker

Nuestro modelo era:

```text
Aplicaciones
     │
     ▼
Contenedores Docker
     │
     ▼
Volúmenes Docker
```

Pero los volúmenes Docker también tienen que almacenarse físicamente en algún lugar.

En nuestro escenario:

```text
Hive / HDFS / NiFi / Zeppelin / etc.
                │
                ▼
        Contenedores Docker
                │
                ▼
         Volúmenes Docker
                │
                ▼
             Ubuntu
                │
                ▼
           Instancia EC2
                │
                ▼
      Almacenamiento de AWS
```

Por tanto, hemos llegado a una idea fundamental:

> **Un volumen Docker es persistente respecto del ciclo de vida del contenedor, pero sigue dependiendo del almacenamiento de la máquina que ejecuta Docker.**

---

## 5.2 Cuatro acciones que no significan lo mismo

En el trabajo cotidiano podemos realizar operaciones muy diferentes:

| Acción                          | ¿Qué ocurre?                                    | Riesgo para nuestros datos                                            |
| ------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| Reiniciar Ubuntu                | Se reinicia el sistema operativo                | Bajo                                                                  |
| `docker compose down` / `up -d` | Se recrean contenedores                         | Bajo si conservamos los volúmenes                                     |
| Detener e iniciar EC2           | Se detiene y posteriormente inicia la instancia | Normalmente se conserva el almacenamiento persistente de la instancia |
| Terminar/eliminar EC2           | Se destruye la instancia                        | Los datos pueden perderse según la configuración del almacenamiento   |

Esta diferencia explica muchos casos en los que un estudiante señala:

> “Reinicié AWS y desaparecieron mis datos”.

Antes de diagnosticar el problema debemos preguntar:

**¿Qué significa exactamente “reinicié AWS”?**

---

# 5.3 Caso A — Reiniciar Ubuntu

Podemos ejecutar:

```bash
sudo reboot
```

El sistema operativo se reinicia.

Después del reinicio podemos comprobar:

```bash
sudo docker ps -a
```

En nuestra infraestructura los servicios están configurados con una política de reinicio, por lo que deberían volver a levantarse automáticamente.

Podemos verificar HDFS:

```bash
sudo docker exec namenode \
  hdfs dfs -cat /prueba_persistencia/persistencia.txt
```

Si obtenemos:

```text
Este archivo debe sobrevivir a la recreacion de los contenedores
```

entonces tenemos:

```text
reinicio Ubuntu
      ↓
Docker vuelve a ejecutarse
      ↓
contenedores vuelven a ejecutarse
      ↓
volúmenes siguen disponibles
      ↓
HDFS recupera sus datos
```

Este experimento ya fue comprobado en nuestra infraestructura.

---

## 5.4 Caso B — Eliminar y recrear los contenedores

También comprobamos:

```bash
docker compose down
```

seguido de:

```bash
docker compose up -d
```

Aquí ocurre algo más profundo que un simple reinicio.

Los contenedores anteriores son eliminados.

Sin embargo:

```text
Contenedores
    ✕ eliminados

Volúmenes
    ✓ conservados
```

Los nuevos contenedores vuelven a utilizar los mismos volúmenes.

Por eso HDFS recupera su estado.

Este comportamiento también fue comprobado experimentalmente en nuestra infraestructura.

---

## 5.5 Caso C — Detener e iniciar la instancia EC2

Desde AWS también podemos detener una instancia:

```text
EC2
↓
Stop instance
```

y posteriormente:

```text
Start instance
```

Esto no equivale a eliminarla.

Conceptualmente:

```text
EC2 funcionando
      ↓
     STOP
      ↓
EC2 detenida
      ↓
     START
      ↓
EC2 funcionando nuevamente
```

Si el almacenamiento persistente asociado a la instancia se conserva, Ubuntu, Docker y sus volúmenes seguirán disponibles después del inicio.

Por tanto:

```text
STOP / START EC2
        ↓
almacenamiento conservado
        ↓
volúmenes Docker conservados
        ↓
HDFS conservado
        ↓
Hive conservado
```

### Importante

Al detener e iniciar una instancia EC2, su **dirección IP pública puede cambiar** si no se utiliza una dirección IP estática.

Esto no significa que los datos hayan desaparecido.

Significa simplemente que puede haber cambiado la dirección utilizada para conectarnos.

Por ejemplo, puede ser necesario actualizar parámetros dependientes de la IP pública, como la configuración de acceso externo de NiFi.

---

# 5.6 Caso D — Terminar o eliminar la instancia EC2

Ahora tenemos una situación completamente diferente:

```text
Terminate instance
```

Terminar una instancia no significa detenerla temporalmente.

Significa eliminarla.

Si además desaparece el almacenamiento donde Docker mantenía sus volúmenes:

```text
EC2 eliminada
      ↓
almacenamiento eliminado
      ↓
volúmenes Docker eliminados
      ↓
HDFS perdido
      ↓
Metastore perdido
```

Aunque nuestra configuración Docker tenga:

```text
namenode_data
datanode_data
hive_metastore_data
```

estos volúmenes siguen estando físicamente almacenados sobre la infraestructura que ejecutaba Docker.

Por eso:

> **La persistencia Docker no constituye por sí misma una estrategia de respaldo.**

---

# 5.7 Entonces, ¿dónde estaba realmente nuestro archivo?

Volvamos al archivo:

```text
/prueba_persistencia/persistencia.txt
```

Desde la perspectiva del usuario está en:

```text
HDFS
```

Desde la arquitectura Hadoop:

```text
HDFS
│
├── NameNode
│      └── metadatos
│
└── DataNode
       └── bloques
```

Desde Docker:

```text
NameNode
    ↓
namenode_data

DataNode
    ↓
datanode_data
```

Y desde una perspectiva de infraestructura:

```text
Volúmenes Docker
       ↓
almacenamiento del host
       ↓
Ubuntu
       ↓
EC2
       ↓
infraestructura AWS
```

Ahora podemos responder con mayor precisión a:

> **¿Dónde está mi archivo?**

No existe una única respuesta.

Depende del nivel de abstracción desde el cual observemos el sistema.

---

# 5.8 Una analogía útil

Podemos pensar en estas capas como una biblioteca:

```text
Hive
→ catálogo de la biblioteca

HDFS
→ sistema que organiza los libros

Docker
→ edificio donde funcionan los servicios

Volúmenes
→ estanterías donde permanece el contenido

EC2
→ terreno donde se encuentra el edificio
```

Cambiar al bibliotecario no destruye los libros.

Reiniciar un servicio tampoco debería destruirlos.

Reemplazar un contenedor tampoco debería destruirlos si las estanterías siguen existiendo.

Pero si eliminamos toda la infraestructura donde estaban almacenadas esas estanterías, la situación cambia completamente.

---

# 5.9 El error conceptual que debemos evitar

Después de trabajar con HDFS podría aparecer esta conclusión:

> “Si guardo algo en HDFS, entonces queda guardado permanentemente”.

Esa afirmación es incorrecta.

La formulación adecuada es:

> **HDFS proporciona almacenamiento distribuido y persistente dentro de la infraestructura donde está desplegado, pero la supervivencia final de los datos depende también de la persistencia de dicha infraestructura.**

Esto significa que debemos distinguir:

```text
persistencia lógica
        ≠
persistencia física
        ≠
respaldo
```

---

# 5.10 El modelo completo de la infraestructura

Ahora podemos construir el mapa que integra toda la guía:

```text
                    USUARIO
                       │
                       ▼
                     HIVE
                       │
            ┌──────────┴──────────┐
            │                     │
            ▼                     ▼
          DATOS               METADATOS
            │                     │
            ▼                     ▼
           HDFS            Hive Metastore
            │                     │
     ┌──────┴──────┐              ▼
     │             │          PostgreSQL
     ▼             ▼               │
 NameNode       DataNode            │
     │             │               │
     ▼             ▼               ▼
namenode_data datanode_data hive_metastore_data
     └─────────────┬───────────────┘
                   │
                   ▼
            VOLÚMENES DOCKER
                   │
                   ▼
                 UBUNTU
                   │
                   ▼
               AWS EC2
                   │
                   ▼
             ALMACENAMIENTO
```

Este esquema permite explicar prácticamente todo lo observado durante los cinco pasos.

---

# 5.11 ¿Qué sobrevive a qué?

Como síntesis:

| Situación                                         |    Contenedor    | Volumen Docker |       Datos HDFS      |
| ------------------------------------------------- | :--------------: | :------------: | :-------------------: |
| Reiniciar servicio                                |         ✓        |        ✓       |           ✓           |
| Reiniciar Ubuntu                                  | vuelve a iniciar |        ✓       |           ✓           |
| `docker compose down`                             |         ✕        |        ✓       |           ✓           |
| `docker compose up -d`                            |       nuevo      |        ✓       |           ✓           |
| `docker compose down -v`                          |         ✕        |        ✕       | **riesgo de pérdida** |
| Eliminar/recrear EC2 sin conservar almacenamiento |         ✕        |        ✕       |      **pérdida**      |

Esta tabla es probablemente uno de los elementos más importantes de toda la guía.

---

# 5.12 Pregunta final

Un estudiante ejecuta:

```bash
docker compose down
```

Luego vuelve a levantar la infraestructura:

```bash
docker compose up -d
```

y descubre que su tabla Hive continúa disponible.

Otro estudiante elimina completamente su infraestructura y crea una nueva desde cero. Su tabla ya no existe.

**¿Existe una contradicción?**

No.

En el primer caso:

```text
contenedores eliminados
        ↓
volúmenes conservados
        ↓
HDFS conservado
        ↓
Metastore conservado
        ↓
tabla recuperada
```

En el segundo:

```text
infraestructura eliminada
        ↓
almacenamiento anterior no disponible
        ↓
volúmenes anteriores no disponibles
        ↓
HDFS y Metastore anteriores no disponibles
        ↓
tabla no recuperable desde esa infraestructura
```

---

# Cierre de la guía

Después de estos cinco pasos podemos responder la pregunta :

> **Cuando trabajo con Hive y HDFS, ¿dónde están realmente mis datos y metadatos, y por qué algunas cosas pueden desaparecer cuando reinicio o recreo mi infraestructura?**

La respuesta puede resumirse así:

```text
Hive no almacena todo en un único lugar.

Datos
  → HDFS
  → NameNode + DataNode
  → volúmenes Docker

Metadatos Hive
  → Hive Metastore
  → PostgreSQL
  → volumen Docker

Volúmenes Docker
  → almacenamiento del host

Host
  → infraestructura donde Docker está desplegado
```

Por eso, la pregunta correcta no es solamente:

> **“¿Guardé el archivo?”**

sino:

> **“¿En qué capa lo guardé y qué infraestructura debe sobrevivir para poder recuperarlo?”**



