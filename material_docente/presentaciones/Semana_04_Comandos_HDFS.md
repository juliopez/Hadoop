# Semana 4 — Guía de comandos HDFS

## 1. Introducción

HDFS (*Hadoop Distributed File System*) permite almacenar y administrar archivos dentro de un sistema distribuido. Durante esta sesión utilizaremos la línea de comandos para interactuar directamente con HDFS y realizar operaciones similares a las que habitualmente ejecutamos sobre un sistema de archivos tradicional.

El objetivo no es memorizar todos los comandos. Lo importante es comprender **qué operación estamos realizando, dónde se encuentran los datos y cómo podemos administrarlos dentro de HDFS**.

La mayoría de las operaciones que utilizaremos siguen esta estructura:

```bash
hdfs dfs <comando> <argumentos>
```

Por ejemplo:

```bash
hdfs dfs -ls /
```

Este comando solicita a HDFS listar el contenido de su directorio raíz.

---

# 2. Antes de comenzar: Linux y HDFS no son lo mismo

Uno de los aspectos más importantes al comenzar a trabajar con Hadoop es distinguir entre:

* el **sistema de archivos local** de Linux;
* el **sistema de archivos distribuido HDFS**.

Cuando estamos conectados a nuestro servidor mediante una terminal, podemos trabajar simultáneamente con ambos.

Por ejemplo:

```bash
ls
```

muestra archivos y directorios del **sistema de archivos local**.

En cambio:

```bash
hdfs dfs -ls /
```

muestra archivos y directorios almacenados en **HDFS**.

Por tanto:

```text
Linux local                         HDFS
-------------------------------------------------------
ls                                  hdfs dfs -ls /
mkdir datos                         hdfs dfs -mkdir /datos
rm archivo.txt                      hdfs dfs -rm /archivo.txt
```

Aunque las operaciones pueden parecer similares, **estamos trabajando sobre sistemas de archivos diferentes**.

Esta distinción será fundamental durante toda la práctica.

---

# 3. Consultar la ayuda de HDFS

Antes de memorizar comandos, debemos saber cómo consultar la documentación disponible desde la propia terminal.

Podemos utilizar:

```bash
hdfs dfs -help
```

Esto muestra los comandos disponibles.

También podemos solicitar ayuda sobre una operación específica:

```bash
hdfs dfs -help ls
```

o:

```bash
hdfs dfs -help put
```

Esta práctica es importante: en un entorno real no es necesario recordar cada parámetro de memoria. Es más importante **comprender qué necesitamos hacer y saber consultar la sintaxis correspondiente**.

---

# 4. Listar archivos y directorios: `-ls`

Uno de los primeros comandos que utilizaremos será:

```bash
hdfs dfs -ls /
```

`-ls` permite listar el contenido de un directorio en HDFS.

Por ejemplo:

```bash
hdfs dfs -ls /datos
```

muestra los archivos y subdirectorios existentes dentro de `/datos`.

También podemos utilizar la opción recursiva:

```bash
hdfs dfs -ls -R /datos
```

De esta manera se muestra el contenido del directorio y de sus subdirectorios.

### ¿Cuándo utilizaremos `-ls`?

Constantemente.

Después de crear un directorio:

```bash
hdfs dfs -ls /
```

Después de cargar un archivo:

```bash
hdfs dfs -ls /datos
```

Después de moverlo:

```bash
hdfs dfs -ls /destino
```

`-ls` será uno de nuestros principales mecanismos de **verificación**.

---

# 5. Crear directorios: `-mkdir`

Para crear un directorio en HDFS utilizamos:

```bash
hdfs dfs -mkdir /datos
```

Ahora podemos comprobar su existencia:

```bash
hdfs dfs -ls /
```

También podemos crear una estructura completa utilizando `-p`:

```bash
hdfs dfs -mkdir -p /curso/bigdata/hdfs
```

La opción `-p` permite crear los directorios intermedios necesarios.

Por ejemplo, aunque `/curso` y `/curso/bigdata` todavía no existan:

```bash
hdfs dfs -mkdir -p /curso/bigdata/hdfs
```

creará toda la estructura.

---

# 6. Preparar un archivo en Linux

Antes de enviar información hacia HDFS necesitamos disponer de algún archivo local.

Podemos crear uno sencillo desde Linux:

```bash
echo "Primera práctica con HDFS" > ejemplo.txt
```

Comprobamos:

```bash
ls
```

y observamos su contenido:

```bash
cat ejemplo.txt
```

Hasta este momento:

```text
ejemplo.txt
     ↓
Sistema de archivos LOCAL
```

El archivo **todavía no está almacenado en HDFS**.

---

# 7. Cargar archivos hacia HDFS: `-put`

Para enviar un archivo desde el sistema local hacia HDFS utilizamos:

```bash
hdfs dfs -put ejemplo.txt /datos/
```

Conceptualmente:

```text
Sistema local                         HDFS

ejemplo.txt   ───────────────────→   /datos/ejemplo.txt
                       -put
```

Ahora verificamos:

```bash
hdfs dfs -ls /datos
```

Deberíamos encontrar `ejemplo.txt`.

Este comando representa una de las operaciones fundamentales que realizaremos:

> **Mover datos desde nuestro entorno local hacia el almacenamiento distribuido de Hadoop.**

Es importante observar que `-put` no significa simplemente cambiar de directorio. Estamos transfiriendo información **entre dos sistemas de archivos distintos**.

---

# 8. `-copyFromLocal`

HDFS también proporciona:

```bash
hdfs dfs -copyFromLocal ejemplo.txt /datos/
```

Su propósito es copiar un archivo desde el sistema de archivos local hacia HDFS.

Para nuestros primeros ejercicios, podemos entender:

```bash
hdfs dfs -put
```

y:

```bash
hdfs dfs -copyFromLocal
```

como operaciones equivalentes para cargar archivos locales hacia HDFS.

Usaremos principalmente `-put` por su sintaxis más breve.

---

# 9. Visualizar un archivo: `-cat`

Una vez que el archivo se encuentra en HDFS podemos consultar su contenido:

```bash
hdfs dfs -cat /datos/ejemplo.txt
```

Esto muestra el contenido en la terminal.

Es importante volver a observar la diferencia:

```bash
cat ejemplo.txt
```

lee el archivo **local**.

Mientras que:

```bash
hdfs dfs -cat /datos/ejemplo.txt
```

lee el archivo almacenado en **HDFS**.

---

# 10. Visualizar el inicio de un archivo: `-head`

Cuando trabajamos con archivos grandes puede no ser conveniente mostrar todo su contenido.

Podemos consultar solamente el comienzo:

```bash
hdfs dfs -head /datos/ejemplo.txt
```

Esto resulta especialmente útil cuando queremos comprobar rápidamente el contenido o estructura de un archivo antes de procesarlo.

Por ejemplo, frente a un archivo de datos podemos utilizar:

```bash
hdfs dfs -head /datos/ventas.csv
```

para realizar una primera inspección.

---

# 11. Visualizar el final de un archivo: `-tail`

También podemos observar la parte final:

```bash
hdfs dfs -tail /datos/ejemplo.txt
```

Esto puede resultar útil para inspeccionar archivos extensos, registros o datos que se van incorporando secuencialmente.

---

# 12. Descargar archivos desde HDFS: `-get`

Si `-put` permite realizar:

```text
LOCAL → HDFS
```

`-get` realiza la operación contraria:

```text
HDFS → LOCAL
```

Por ejemplo:

```bash
hdfs dfs -get /datos/ejemplo.txt ejemplo_descargado.txt
```

Ahora:

```bash
ls
```

permitirá comprobar que existe:

```text
ejemplo_descargado.txt
```

en el sistema local.

Podemos verificar su contenido:

```bash
cat ejemplo_descargado.txt
```

---

# 13. `-copyToLocal`

Existe también:

```bash
hdfs dfs -copyToLocal /datos/ejemplo.txt ejemplo2.txt
```

Conceptualmente cumple una función equivalente a `-get`: copiar información desde HDFS hacia el sistema de archivos local.

Por tanto, podemos recordar:

```text
LOCAL → HDFS       -put / -copyFromLocal

HDFS → LOCAL       -get / -copyToLocal
```

---

# 14. Copiar archivos dentro de HDFS: `-cp`

Hasta ahora hemos transferido archivos entre Linux y HDFS.

Pero también podemos realizar operaciones **dentro de HDFS**.

Primero creamos otro directorio:

```bash
hdfs dfs -mkdir /respaldo
```

Después copiamos:

```bash
hdfs dfs -cp /datos/ejemplo.txt /respaldo/
```

Comprobamos:

```bash
hdfs dfs -ls /respaldo
```

Ahora existen dos archivos dentro de HDFS:

```text
/datos/ejemplo.txt

/respaldo/ejemplo.txt
```

El original permanece en `/datos`.

---

# 15. Mover o renombrar archivos: `-mv`

Podemos mover un archivo:

```bash
hdfs dfs -mv /datos/ejemplo.txt /respaldo/
```

También podemos utilizar `-mv` para cambiar su nombre:

```bash
hdfs dfs -mv /respaldo/ejemplo.txt /respaldo/ejemplo_hdfs.txt
```

Comprobamos:

```bash
hdfs dfs -ls /respaldo
```

La diferencia fundamental entre copiar y mover es:

```text
-cp → conserva el original.

-mv → cambia la ubicación o el nombre del elemento.
```

---

# 16. Eliminar archivos: `-rm`

Para eliminar un archivo:

```bash
hdfs dfs -rm /respaldo/ejemplo_hdfs.txt
```

Siempre es conveniente verificar posteriormente:

```bash
hdfs dfs -ls /respaldo
```

También existe eliminación recursiva:

```bash
hdfs dfs -rm -r /directorio
```

Esta operación debe utilizarse con precaución porque puede eliminar un directorio junto con todo su contenido.

---

# 17. Eliminar directorios vacíos: `-rmdir`

Si tenemos un directorio vacío:

```bash
hdfs dfs -rmdir /respaldo
```

podemos eliminarlo con `-rmdir`.

Si contiene archivos, el comando no debería eliminarlo directamente.

Esto introduce una diferencia útil:

```text
-rm       → archivos

-rmdir    → directorios vacíos

-rm -r    → directorios y su contenido
```

---

# 18. Consultar el espacio utilizado: `-du`

Podemos conocer cuánto espacio ocupan archivos y directorios:

```bash
hdfs dfs -du /datos
```

Para obtener una salida más fácil de leer:

```bash
hdfs dfs -du -h /datos
```

La opción `-h` presenta los tamaños utilizando unidades más comprensibles, como KB, MB o GB.

Este comando comienza a ser especialmente interesante cuando dejamos de trabajar con pequeños archivos de demostración y utilizamos conjuntos de datos mayores.

---

# 19. Consultar capacidad disponible: `-df`

Para consultar información sobre la capacidad del sistema:

```bash
hdfs dfs -df
```

También podemos utilizar:

```bash
hdfs dfs -df -h
```

La información permite observar aspectos relacionados con:

* capacidad total;
* espacio utilizado;
* espacio disponible.

Esto nos conecta nuevamente con uno de los problemas fundamentales estudiados en las primeras semanas: **la capacidad de almacenamiento**.

---

# 20. Contar directorios, archivos y tamaño: `-count`

Podemos obtener un resumen de un directorio mediante:

```bash
hdfs dfs -count /datos
```

Este comando permite conocer información como la cantidad de directorios, archivos y espacio asociado a una ruta.

Para una salida más legible podemos consultar la ayuda correspondiente:

```bash
hdfs dfs -help count
```

y revisar las opciones disponibles en nuestra instalación.

---

# 21. Consultar el factor de replicación: `-stat`

Durante la parte teórica vimos que HDFS puede mantener varias copias de los bloques.

Podemos consultar información específica de un archivo mediante `-stat`.

Por ejemplo:

```bash
hdfs dfs -stat %r /datos/ventas.csv
```

`%r` permite consultar el **factor de replicación** asociado al archivo.

Si obtenemos:

```text
3
```

significa que el factor de replicación configurado para ese archivo es 3.

Esto permite conectar directamente un comando con uno de los conceptos estudiados:

```text
Teoría                         Práctica
------------------------------------------------
Replicación          →         hdfs dfs -stat %r
```

---

# 22. Modificar el factor de replicación: `-setrep`

También podemos solicitar un determinado factor de replicación:

```bash
hdfs dfs -setrep 2 /datos/ventas.csv
```

Si queremos esperar hasta que el cambio alcance el estado solicitado:

```bash
hdfs dfs -setrep -w 2 /datos/ventas.csv
```

La opción `-w` indica que el comando espere a que la operación se complete.

Este comando es especialmente interesante porque permite observar que la replicación estudiada en la teoría **es una característica administrable del sistema**.

> Importante: el número efectivo de réplicas posibles depende de la configuración y cantidad de DataNodes disponibles en el clúster.

---

# 23. Consultar información de bloques

Los comandos `hdfs dfs` están orientados principalmente a operaciones sobre archivos y directorios.

Para inspeccionar información más relacionada con la estructura interna de HDFS podemos utilizar otras herramientas de Hadoop.

Por ejemplo:

```bash
hdfs fsck /datos/ventas.csv -files -blocks
```

Esto permite consultar información sobre los bloques asociados al archivo.

Dependiendo de la configuración del entorno, podemos ampliar la consulta:

```bash
hdfs fsck /datos/ventas.csv -files -blocks -locations
```

Esto permite relacionar la teoría con la infraestructura:

```text
Archivo
   ↓
Bloques
   ↓
Ubicación en los nodos
```

No necesitamos memorizar toda la salida de `fsck`. Nuestro objetivo inicial será **reconocer que el archivo que vemos como una unidad lógica puede estar compuesto internamente por bloques administrados por HDFS**.

---

# 24. Permisos: `-chmod`

Al igual que otros sistemas de archivos, HDFS dispone de permisos.

Podemos modificarlos mediante:

```bash
hdfs dfs -chmod 755 /datos
```

También podemos utilizar notación simbólica:

```bash
hdfs dfs -chmod u+rwx /datos
```

En esta etapa del curso no necesitamos profundizar todavía en administración de seguridad. Lo importante es reconocer que **los archivos y directorios de HDFS poseen permisos que pueden condicionar las operaciones que los usuarios pueden realizar**.

---

# 25. Propietario y grupo: `-chown`

Podemos modificar el propietario o grupo de un elemento mediante:

```bash
hdfs dfs -chown usuario:grupo /datos
```

Este tipo de operación normalmente requiere los permisos correspondientes.

Nuevamente, nuestro objetivo inicial es reconocer su existencia más que profundizar en administración de usuarios.

---

# 26. Un flujo completo de trabajo

Podemos reunir los comandos fundamentales en una secuencia.

### Paso 1 — Crear un archivo local

```bash
echo "id,nombre,valor" > datos.csv
echo "1,Ana,150" >> datos.csv
echo "2,Pedro,230" >> datos.csv
echo "3,Carolina,180" >> datos.csv
```

Comprobamos:

```bash
cat datos.csv
```

### Paso 2 — Crear un directorio en HDFS

```bash
hdfs dfs -mkdir -p /curso/datos
```

### Paso 3 — Cargar el archivo

```bash
hdfs dfs -put datos.csv /curso/datos/
```

### Paso 4 — Verificar

```bash
hdfs dfs -ls /curso/datos
```

### Paso 5 — Consultar el contenido

```bash
hdfs dfs -cat /curso/datos/datos.csv
```

### Paso 6 — Consultar espacio

```bash
hdfs dfs -du -h /curso/datos
```

### Paso 7 — Consultar replicación

```bash
hdfs dfs -stat %r /curso/datos/datos.csv
```

### Paso 8 — Consultar bloques

```bash
hdfs fsck /curso/datos/datos.csv -files -blocks -locations
```

### Paso 9 — Descargar nuevamente el archivo

```bash
hdfs dfs -get /curso/datos/datos.csv datos_recuperados.csv
```

### Paso 10 — Verificar localmente

```bash
cat datos_recuperados.csv
```

Este flujo representa buena parte del ciclo básico que utilizaremos durante nuestras primeras prácticas:

```text
CREAR DATOS LOCALMENTE
          ↓
CREAR ESTRUCTURA HDFS
          ↓
CARGAR
          ↓
VERIFICAR
          ↓
CONSULTAR
          ↓
INSPECCIONAR
          ↓
RECUPERAR
```

---

# 27. Errores frecuentes

## Error 1: confundir Linux con HDFS

```bash
ls /datos
```

no es equivalente a:

```bash
hdfs dfs -ls /datos
```

El primero consulta el sistema local; el segundo consulta HDFS.

---

## Error 2: cargar dos veces el mismo archivo

Si ejecutamos:

```bash
hdfs dfs -put datos.csv /curso/datos/
```

y el archivo ya existe en el destino, HDFS puede rechazar la operación.

Una posibilidad es eliminar previamente el archivo:

```bash
hdfs dfs -rm /curso/datos/datos.csv
```

y volver a cargarlo.

También existen opciones para sobrescritura en determinados comandos; conviene consultar:

```bash
hdfs dfs -help put
```

antes de utilizarlas.

---

## Error 3: utilizar una ruta que no existe

Antes de cargar:

```bash
hdfs dfs -put datos.csv /curso/datos/
```

debemos comprobar que el directorio exista:

```bash
hdfs dfs -ls /curso
```

Si no existe:

```bash
hdfs dfs -mkdir -p /curso/datos
```

---

## Error 4: eliminar recursivamente sin revisar

El comando:

```bash
hdfs dfs -rm -r /curso
```

puede eliminar todo el contenido existente bajo esa ruta.

Antes de utilizar una eliminación recursiva es recomendable comprobar:

```bash
hdfs dfs -ls -R /curso
```

---

# 28. Una estrategia para trabajar con HDFS

Durante los ejercicios utilizaremos repetidamente una secuencia sencilla:

> **Ejecutar → verificar → interpretar.**

Por ejemplo:

```bash
hdfs dfs -mkdir /datos
```

No deberíamos continuar inmediatamente.

Primero:

```bash
hdfs dfs -ls /
```

y comprobamos qué ocurrió.

Después:

```bash
hdfs dfs -put ventas.csv /datos/
```

Verificamos:

```bash
hdfs dfs -ls /datos
```

Y posteriormente interpretamos:

**¿Dónde estaba inicialmente el archivo? ¿Dónde está ahora? ¿Qué operación realizó HDFS?**

El objetivo no es ejecutar veinte comandos rápidamente. El objetivo es **comprender el efecto de cada operación sobre el sistema de archivos distribuido**.

---

# 29. Tabla rápida de comandos HDFS

| Objetivo                        | Comando                                             |
| ------------------------------- | --------------------------------------------------- |
| Consultar ayuda                 | `hdfs dfs -help`                                    |
| Listar archivos                 | `hdfs dfs -ls /ruta`                                |
| Listar recursivamente           | `hdfs dfs -ls -R /ruta`                             |
| Crear directorio                | `hdfs dfs -mkdir /ruta`                             |
| Crear estructura de directorios | `hdfs dfs -mkdir -p /ruta`                          |
| Subir archivo                   | `hdfs dfs -put archivo /ruta/`                      |
| Subir desde local               | `hdfs dfs -copyFromLocal archivo /ruta/`            |
| Mostrar contenido               | `hdfs dfs -cat /ruta/archivo`                       |
| Mostrar inicio                  | `hdfs dfs -head /ruta/archivo`                      |
| Mostrar final                   | `hdfs dfs -tail /ruta/archivo`                      |
| Descargar archivo               | `hdfs dfs -get /ruta/archivo .`                     |
| Descargar a local               | `hdfs dfs -copyToLocal /ruta/archivo .`             |
| Copiar en HDFS                  | `hdfs dfs -cp origen destino`                       |
| Mover/renombrar                 | `hdfs dfs -mv origen destino`                       |
| Eliminar archivo                | `hdfs dfs -rm /ruta/archivo`                        |
| Eliminar directorio vacío       | `hdfs dfs -rmdir /ruta`                             |
| Eliminar recursivamente         | `hdfs dfs -rm -r /ruta`                             |
| Consultar espacio utilizado     | `hdfs dfs -du -h /ruta`                             |
| Consultar capacidad             | `hdfs dfs -df -h`                                   |
| Contar elementos                | `hdfs dfs -count /ruta`                             |
| Consultar replicación           | `hdfs dfs -stat %r /ruta/archivo`                   |
| Modificar replicación           | `hdfs dfs -setrep -w N /ruta/archivo`               |
| Consultar bloques               | `hdfs fsck /ruta/archivo -files -blocks -locations` |
| Modificar permisos              | `hdfs dfs -chmod permisos /ruta`                    |
| Cambiar propietario             | `hdfs dfs -chown usuario:grupo /ruta`               |

---



