# 2.3. Publicación de eventos mediante productores

## 2.3.1. Del tópico al flujo de eventos

Los tópicos organizan los eventos, pero necesitan aplicaciones capaces de generarlos y publicarlos: los **productores (*producers*)**. Un productor construye registros y los envía a un tópico Kafka. Puede ser una aplicación empresarial, servicio web, proceso automatizado, dispositivo IoT o programa de integración. En una venta comercial, el sistema de origen registra la operación, el productor construye y transmite el evento y el broker recibe y almacena el registro.

## 2.3.2. Arquitectura básica de publicación

El productor necesita una dirección inicial de conexión y el tópico de destino. No necesita conocer las aplicaciones que consumirán posteriormente los eventos: este desacoplamiento facilita incorporar nuevos consumidores.

![Figura 42. Flujo de publicación de una transacción comercial](imagenes/figura_42.svg)

*Figura 42. Flujo de publicación de una transacción comercial en Kafka.*

## 2.3.3. Estructura de un registro publicado

| Componente | Descripción |
|---|---|
| Tópico | Destino lógico |
| Clave (*key*) | Identificador opcional que puede intervenir en el particionamiento |
| Valor (*value*) | Contenido principal |
| Marca temporal (*timestamp*) | Tiempo asociado al registro |
| Cabeceras (*headers*) | Metadatos opcionales |
| Partición | Destino explícito o automático |

```json
{
  "id_venta": "V-1048",
  "id_cliente": "C-025",
  "fecha": "2026-10-29T11:35:00-03:00",
  "monto": 45990,
  "medio_pago": "tarjeta",
  "estado": "confirmada"
}
```

Kafka no interpreta automáticamente el JSON: el productor debe serializar el contenido en bytes. La fecha del JSON es distinta de la marca temporal propia del registro Kafka. Estos formatos se profundizarán en el apartado 2.5.

## 2.3.4. Configuración mínima de un productor

El parámetro `bootstrap.servers` proporciona direcciones iniciales para descubrir brokers:

```properties
bootstrap.servers=localhost:9092
```

La dirección adecuada depende de dónde se ejecuta el cliente. En Java pueden declararse serializadores:

```properties
key.serializer=org.apache.kafka.common.serialization.StringSerializer
value.serializer=org.apache.kafka.common.serialization.StringSerializer
```

Otras bibliotecas, como las de Python, pueden utilizar mecanismos diferentes.

## 2.3.5. Publicación mediante la consola

```bash
kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic ventas
```

```text
Venta V-1048 confirmada
Venta V-1049 confirmada
Venta V-1050 rechazada
```

Normalmente cada línea representa un registro. Esta herramienta permite comprobar el mecanismo de publicación sin desarrollar una aplicación. **La sintaxis y la ruta del ejecutable deben verificarse contra la imagen real del laboratorio**, que utiliza una distribución anterior.

## 2.3.6. Productores programáticos: publicación desde aplicaciones

Ejemplo ilustrativo con `kafka-python`:

```python
from kafka import KafkaProducer
import json

productor = KafkaProducer(
    bootstrap_servers="localhost:9092",
    value_serializer=lambda valor: json.dumps(
        valor
    ).encode("utf-8")
)

venta = {
    "id_venta": "V-1048",
    "id_cliente": "C-025",
    "monto": 45990,
    "estado": "confirmada"
}

resultado = productor.send("ventas", value=venta)
metadata = resultado.get(timeout=10)

print(
    f"Evento publicado en "
    f"partición {metadata.partition}, "
    f"offset {metadata.offset}"
)

productor.close()
```

El programa crea un productor, serializa el objeto a JSON UTF-8, solicita el envío y espera el resultado para conocer partición y offset. Los errores y tiempos de espera deben gestionarse en aplicaciones reales. **Este ejemplo no ha sido validado todavía en el contenedor docente**: requiere biblioteca compatible y conectividad.

## 2.3.7. Publicación asíncrona y confirmación

La publicación puede ser asíncrona. Debemos distinguir entre solicitar el envío, transmitir el registro y obtener confirmación del broker. Que `send()` retorne no demuestra por sí solo almacenamiento exitoso.

![Figura 43. Secuencia de publicación y confirmación](imagenes/figura_43.svg)

*Figura 43. Secuencia simplificada de publicación y confirmación.*

## 2.3.8. Garantías de entrega y parámetro acks

| Valor | Comportamiento | Consideración |
|---|---|---|
| `acks=0` | No espera confirmación del broker | Menor garantía |
| `acks=1` | Confirma el líder después de escribir en su log | Puede existir pérdida ante ciertos fallos |
| `acks=all` | Espera las confirmaciones requeridas de réplicas sincronizadas | Mayor protección con replicación adecuada |

`acks=all` no es una garantía absoluta. Depende del factor de replicación y las réplicas sincronizadas. En nuestro laboratorio de broker único no existen copias independientes entre servidores.

## 2.3.9. Reintentos, duplicados e idempotencia

Los reintentos ayudan ante fallos temporales, pero pueden duplicar publicaciones si el broker almacenó un registro y la confirmación se perdió. Kafka ofrece idempotencia del productor:

```properties
enable.idempotence=true
```

La idempotencia evita determinados duplicados de reintentos dentro de sus garantías, pero no deduplica automáticamente dos eventos de negocio generados de forma independiente. El comportamiento exacto depende de versión y configuración.

## 2.3.10. Particionamiento: claves y distribución

El productor puede elegir una partición explícitamente, utilizar una clave o dejar que el cliente distribuya registros sin clave. Usar el identificador del cliente como clave puede preservar el orden de eventos de ese cliente dentro de una partición, mientras no cambien las condiciones relevantes del particionamiento.

![Figura 44. Distribución de eventos mediante claves](imagenes/figura_44.svg)

*Figura 44. Distribución ilustrativa de eventos comerciales mediante claves.*

Una clave muy frecuente puede concentrar carga en una partición (*data skew*). La elección de claves debe equilibrar ordenamiento y distribución.

## 2.3.11. Agrupación de mensajes, latencia y rendimiento

El productor puede agrupar registros destinados a una partición antes de enviarlos (*batching*). Entre los parámetros relacionados están `batch.size`, `linger.ms` y `compression.type`. Lotes mayores pueden reducir solicitudes y mejorar rendimiento, pero añadir espera puede incrementar latencia.

![Figura 45. Publicación individual frente a agrupada](imagenes/figura_45.svg)

*Figura 45. Publicación individual frente a publicación agrupada.*

## 2.3.12. Errores frecuentes

| Situación | Posible causa | Verificación |
|---|---|---|
| No hay conexión | Dirección incorrecta | Conectividad y advertised listeners |
| Tópico inexistente | Nombre o configuración | Consultar tópicos |
| Error de serialización | Datos incompatibles | Revisar conversión a bytes |
| Tiempo de espera | Comunicación o broker | Registros y configuración |
| Duplicados | Reintentos o eventos repetidos | Idempotencia e identificadores |
| Carga desequilibrada | Claves concentradas | Particionamiento |
| Pérdida | Garantías insuficientes | Confirmaciones y replicación |

Conviene distinguir fallos transitorios recuperables de errores permanentes que requieren intervención.

## 2.3.13. Aplicación al caso comercial

La empresa registra una venta, construye el evento, lo serializa y publica en `ventas`. Kafka lo almacena en una partición y posteriormente los consumidores pueden recuperarlo. Surge un problema adicional: si la base de datos confirma la venta, pero falla la publicación, ambos sistemas pueden quedar desincronizados. El patrón **Transactional Outbox** es una alternativa arquitectónica para abordar esa consistencia, mediante una tabla de eventos pendientes y publicación posterior.

## 2.3.14. Síntesis del apartado

Los productores publican eventos, serializan registros, seleccionan particiones y gestionan confirmaciones. Estudiamos `acks`, reintentos, idempotencia, agrupación y errores de publicación. En el apartado **2.4** examinaremos cómo los consumidores recuperan esos registros y coordinan el procesamiento.
