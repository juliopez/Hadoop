# 2.7. Construcción de un productor que consulta una API y publica eventos en Kafka

## 2.7.1. Del estudio de las integraciones a la construcción de una aplicación

En el apartado 2.6 examinamos archivos, bases de datos, CDC, Kafka Connect, NiFi y APIs REST. Ahora desarrollaremos una aplicación que reúna esos conceptos en un procedimiento operativo: **un productor Python capaz de consultar una API REST, recuperar JSON, transformarlo en eventos y publicarlo en un tópico Kafka**.

La solución relaciona una fuente HTTP, una aplicación que obtiene y transforma los datos, y un broker Kafka que recibe los eventos. Además de ejecutar el programa, estudiaremos las decisiones de diseño y las limitaciones que diferencian una demostración de un sistema de producción.

## 2.7.2. Escenario de trabajo y objetivos

Continuaremos con el caso transversal de transacciones comerciales. Supongamos que una API devuelve:

```json
{
  "ventas": [
    {
      "id_venta": "V-1048",
      "id_cliente": "C-025",
      "monto": 45990,
      "moneda": "CLP",
      "estado": "confirmada",
      "fecha": "2026-10-29T11:35:00-03:00"
    },
    {
      "id_venta": "V-1049",
      "id_cliente": "C-103",
      "monto": 52990,
      "moneda": "CLP",
      "estado": "confirmada",
      "fecha": "2026-10-29T11:36:00-03:00"
    }
  ]
}
```

La aplicación debe recuperar estas ventas y publicar cada una como registro independiente en `ventas`. Los objetivos son obtener datos por HTTP, validarlos y transformarlos, publicarlos con un productor Kafka y comprobar su disponibilidad para consumidores.

Para no depender inicialmente de servicios externos, construiremos una API local de demostración, que posteriormente podrá sustituirse por una API real.

## 2.7.3. Arquitectura de la solución

La arquitectura contempla cuatro componentes: **API REST** (fuente JSON), **productor Python** (consulta, valida y publica), **broker Kafka** (almacena eventos en `ventas`) y **consumidor de verificación** (observa registros).

![Figura 59. Arquitectura del productor Python integrado con API REST](imagenes/figura_59.svg)

*Figura 59. Arquitectura del productor Python integrado con una API REST.*

La API no se comunica directamente con Kafka. Python establece ambas conexiones; los errores HTTP, la transformación y las confirmaciones Kafka requieren tratamiento diferenciado.

## 2.7.4. Condiciones previas del laboratorio

Comprobaremos el estado del entorno Docker:

```bash
docker ps
docker logs --tail 50 kafka
```

La existencia del contenedor no garantiza que el broker sea accesible desde el entorno de Python. La dirección depende de dónde se ejecuta el cliente:

| Ubicación del productor | Dirección que debe evaluarse |
|---|---|
| Contenedor Kafka | `localhost:9092` |
| Otro contenedor de la red Docker | Nombre del servicio y listener accesible |
| Sistema anfitrión | Puerto publicado y dirección anunciada accesible |
| Equipo externo | Dirección de red y listener accesibles |

La configuración histórica incluye `172.27.1.16` como dirección anunciada, que debe verificarse. Utilizaremos `localhost:9092` como **valor inicial configurable, no garantía de conectividad**.

Necesitaremos Python y las bibliotecas `requests` y `kafka-python`:

```bash
python -m pip install requests kafka-python
```

La compatibilidad debe comprobarse contra las versiones instaladas.

## 2.7.5. Organización del proyecto

```text
productor-api-kafka/
├── api_demo.py
├── productor.py
├── verificar_eventos.py
└── requirements.txt
```

| Archivo | Responsabilidad |
|---|---|
| `api_demo.py` | API REST local de demostración |
| `productor.py` | Consulta y publicación |
| `verificar_eventos.py` | Consumo de comprobación |
| `requirements.txt` | Dependencias |

Separar la fuente de la aplicación permite sustituir la API local sin rediseñar necesariamente la publicación.

## 2.7.6. Construcción de una API REST de demostración

El archivo `requirements.txt` contendrá:

```text
Flask
requests
kafka-python
```

Instalamos:

```bash
python -m pip install -r requirements.txt
```

Archivo `api_demo.py`:

```python
from flask import Flask, jsonify

app = Flask(__name__)

VENTAS = [
    {
        "id_venta": "V-1048",
        "id_cliente": "C-025",
        "monto": 45990,
        "moneda": "CLP",
        "estado": "confirmada",
        "fecha": "2026-10-29T11:35:00-03:00"
    },
    {
        "id_venta": "V-1049",
        "id_cliente": "C-103",
        "monto": 52990,
        "moneda": "CLP",
        "estado": "confirmada",
        "fecha": "2026-10-29T11:36:00-03:00"
    },
    {
        "id_venta": "V-1050",
        "id_cliente": "C-207",
        "monto": 18990,
        "moneda": "CLP",
        "estado": "rechazada",
        "fecha": "2026-10-29T11:37:00-03:00"
    }
]

@app.get("/api/ventas")
def obtener_ventas():
    return jsonify({"ventas": VENTAS})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
```

Iniciamos el servicio:

```bash
python api_demo.py
```

Y desde otro terminal del mismo entorno:

```bash
curl http://127.0.0.1:5000/api/ventas
```

El servicio devuelve las tres ventas en JSON. Es una demostración con datos estáticos, sin autenticación ni persistencia. Si el productor se ejecuta en otro contenedor, `127.0.0.1` no apuntará automáticamente a la API; deberá adaptarse la conectividad.

## 2.7.7. Diseño del evento publicado en Kafka

Mantendremos el diseño del apartado 2.5, separando metadatos y datos de negocio:

```json
{
  "id_evento": "venta-V-1048-confirmada",
  "tipo_evento": "venta_confirmada",
  "version": 1,
  "fecha_evento": "2026-10-29T11:35:00-03:00",
  "datos": {
    "id_venta": "V-1048",
    "id_cliente": "C-025",
    "monto_total": 45990,
    "moneda": "CLP",
    "estado": "confirmada"
  }
}
```

El identificador del evento se deriva de venta y estado para que sea estable en consultas repetidas. Esto es didáctico: si una venta regresa a un estado anterior, podría repetirse el identificador. En producción convendría utilizar un identificador de cambio o versión provisto por la fuente.

La clave Kafka será `id_cliente`, por ejemplo `C-025`. Esto asocia ventas del mismo cliente, pero puede desequilibrar la distribución si ciertos clientes concentran muchas transacciones.

## 2.7.8. Transformación y validación de registros

Antes de publicar debemos comprobar los campos requeridos y su consistencia:

```python
def transformar_venta(venta):
    campos_requeridos = [
        "id_venta", "id_cliente", "monto",
        "moneda", "estado", "fecha"
    ]

    for campo in campos_requeridos:
        if campo not in venta:
            raise ValueError(
                f"Falta el campo obligatorio: {campo}"
            )

    monto = int(venta["monto"])

    if monto < 0:
        raise ValueError("El monto no puede ser negativo")

    return {
        "id_evento": (
            f"venta-{venta['id_venta']}-{venta['estado']}"
        ),
        "tipo_evento": f"venta_{venta['estado']}",
        "version": 1,
        "fecha_evento": venta["fecha"],
        "datos": {
            "id_venta": venta["id_venta"],
            "id_cliente": venta["id_cliente"],
            "monto_total": monto,
            "moneda": venta["moneda"],
            "estado": venta["estado"]
        }
    }
```

La validación es básica: una aplicación productiva también comprobaría fechas, tipos, estados permitidos y reglas comerciales. **No debemos publicar automáticamente cualquier dato recibido sin verificar su estructura y consistencia.**

## 2.7.9. Implementación del productor Kafka en Python

Archivo `productor.py`:

```python
import json
import os
import requests

from kafka import KafkaProducer

API_URL = os.getenv(
    "API_URL",
    "http://127.0.0.1:5000/api/ventas"
)

KAFKA_BOOTSTRAP_SERVERS = os.getenv(
    "KAFKA_BOOTSTRAP_SERVERS",
    "localhost:9092"
)

TOPICO = "ventas"


def transformar_venta(venta):
    campos_requeridos = [
        "id_venta",
        "id_cliente",
        "monto",
        "moneda",
        "estado",
        "fecha"
    ]

    for campo in campos_requeridos:
        if campo not in venta:
            raise ValueError(
                f"Falta el campo obligatorio: {campo}"
            )

    monto = int(venta["monto"])

    if monto < 0:
        raise ValueError(
            "El monto no puede ser negativo"
        )

    return {
        "id_evento": (
            f"venta-{venta['id_venta']}-"
            f"{venta['estado']}"
        ),
        "tipo_evento": f"venta_{venta['estado']}",
        "version": 1,
        "fecha_evento": venta["fecha"],
        "datos": {
            "id_venta": venta["id_venta"],
            "id_cliente": venta["id_cliente"],
            "monto_total": monto,
            "moneda": venta["moneda"],
            "estado": venta["estado"]
        }
    }


def consultar_api():
    respuesta = requests.get(
        API_URL,
        timeout=10
    )

    respuesta.raise_for_status()

    datos = respuesta.json()

    ventas = datos.get("ventas")

    if not isinstance(ventas, list):
        raise ValueError(
            "La API no entregó una lista de ventas"
        )

    return ventas


def crear_productor():
    return KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        key_serializer=lambda clave: clave.encode(
            "utf-8"
        ),
        value_serializer=lambda valor: json.dumps(
            valor,
            ensure_ascii=False
        ).encode("utf-8"),
        acks="all",
        retries=3
    )


def publicar_ventas():
    ventas = consultar_api()

    productor = crear_productor()

    publicados = 0

    try:
        for venta in ventas:
            try:
                evento = transformar_venta(venta)

                clave = venta["id_cliente"]

                resultado = productor.send(
                    TOPICO,
                    key=clave,
                    value=evento
                )

                metadatos = resultado.get(
                    timeout=15
                )

                publicados += 1

                print(
                    f"Evento publicado: "
                    f"{evento['id_evento']} | "
                    f"partición={metadatos.partition} | "
                    f"offset={metadatos.offset}"
                )

            except (ValueError, TypeError) as error:
                print(
                    f"Registro inválido: {error}"
                )

    finally:
        productor.close()

    print(
        f"Total de eventos publicados: {publicados}"
    )


if __name__ == "__main__":
    publicar_ventas()
```

Esta implementación utiliza `kafka-python`, cuya compatibilidad debe comprobarse con la versión del laboratorio. Es una aplicación docente, no una integración empresarial terminada.

## 2.7.10. Análisis de los componentes del productor

**Variables de entorno:** permiten adaptar las direcciones sin editar el código:

```bash
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export API_URL=http://127.0.0.1:5000/api/ventas
```

**Timeout HTTP:** `timeout=10` evita una espera indefinida. **Validación:** se comprueba que `ventas` sea una lista. **Serialización:** clave UTF-8 y valor JSON. **Confirmación:** `resultado.get(timeout=15)` espera la operación y devuelve partición y offset. **Cierre:** `finally` procura cerrar el productor ante errores.

`acks="all"` solicita confirmación según las réplicas sincronizadas y configuración del tópico. En el broker único docente no proporciona redundancia física. `retries=3` habilita ciertos reintentos, pero no garantiza ausencia de duplicados ni recuperación ante cualquier fallo.

## 2.7.11. Secuencia completa de ejecución

1. Verificar Kafka: `docker ps`.
2. Comprobar que el tópico `ventas` existe; preferir creación explícita como en 2.2.
3. Iniciar API: `python api_demo.py`.
4. Comprobar HTTP: `curl http://127.0.0.1:5000/api/ventas`.
5. Ejecutar productor desde otro terminal: `python productor.py`.
6. Consumir registros para verificar recepción.

![Figura 60. Secuencia operativa del productor](imagenes/figura_60.svg)

*Figura 60. Secuencia operativa de ejecución y verificación.*

Una salida **ilustrativa, no verificada en el laboratorio**, sería:

```text
Evento publicado: venta-V-1048-confirmada | partición=1 | offset=0
Evento publicado: venta-V-1049-confirmada | partición=2 | offset=0
Evento publicado: venta-V-1050-rechazada | partición=0 | offset=0
Total de eventos publicados: 3
```

Las particiones y offsets reales dependen del tópico, su historial y el particionador. Verificar por etapas permite separar errores de API, Kafka y transformación.

## 2.7.12. Verificación de eventos publicados

Archivo `verificar_eventos.py`:

```python
import json
import os

from kafka import KafkaConsumer

SERVIDOR = os.getenv(
    "KAFKA_BOOTSTRAP_SERVERS",
    "localhost:9092"
)

consumidor = KafkaConsumer(
    "ventas",
    bootstrap_servers=SERVIDOR,
    auto_offset_reset="earliest",
    group_id="verificacion-ventas",
    value_deserializer=lambda valor: json.loads(
        valor.decode("utf-8")
    )
)

try:
    for mensaje in consumidor:
        print(
            f"Partición: {mensaje.partition} | "
            f"Offset: {mensaje.offset}"
        )

        print(
            json.dumps(
                mensaje.value,
                ensure_ascii=False,
                indent=2
            )
        )

finally:
    consumidor.close()
```

El consumidor muestra registros disponibles y permanece esperando eventos nuevos. `auto_offset_reset="earliest"` no fuerza reiniciar desde cero si el grupo ya tiene offsets confirmados válidos; para repetir la prueba puede requerirse un grupo nuevo o administrar offsets.

## 2.7.13. Diferencia entre envío, confirmación y procesamiento

Debemos distinguir: el productor **invoca el envío**; Kafka **confirma la publicación** según configuración; un consumidor **procesa posteriormente** el registro.

![Figura 61. Envío, confirmación y procesamiento](imagenes/figura_61.svg)

*Figura 61. Diferencia entre envío del productor, confirmación del broker y procesamiento del consumidor.*

Que `resultado.get()` devuelva metadatos no demuestra que una aplicación analítica haya terminado su trabajo. Para comprobar procesamiento se debe observar el consumidor o sistema de destino.

## 2.7.14. Limitaciones de la implementación inicial

La aplicación consulta una sola vez; no incorpora ejecución periódica. Publica todas las ventas obtenidas y, si se ejecuta dos veces, puede repetir registros. La gestión de errores es simplificada y no conserva puntos de control entre ejecuciones. La API es estática, no una fuente que produzca transacciones continuamente.

Estas limitaciones permiten reconocer la diferencia entre demostración y operación permanente.

## 2.7.15. Hacia un productor periódico con control de duplicados

Una evolución sería consultar cada 30 segundos, pero **agregar una espera no resuelve la duplicación**. Debemos identificar registros ya publicados y mantener estado de extracción.

Un conjunto de identificadores en memoria se pierde al reiniciar. Persistirlos en un archivo o base de datos mejora la recuperación, aunque subsiste un problema: el productor puede publicar correctamente y fallar antes de registrar el identificador como procesado. Al reiniciar, podría volver a publicarlo.

Por ello, la deduplicación y recuperación robustas pueden requerir identificadores estables, operaciones idempotentes y coordinación entre confirmación de Kafka y estado de extracción.

## 2.7.16. Actividad práctica propuesta

El estudiante ejecutará la API, verificará su respuesta HTTP, publicará ventas en Kafka y utilizará un consumidor para comprobar los eventos. Luego incorporará una venta, ejecutará nuevamente el productor y analizará los duplicados.

| Desafío | Evidencia esperada |
|---|---|
| Verificar API | Respuesta JSON por HTTP |
| Publicar | Confirmaciones con partición y offset |
| Consumir | Eventos visualizados |
| Agregar venta | Nuevo registro disponible |
| Ejecutar dos veces | Explicación de duplicados |
| Simular error | Análisis del comportamiento |

La finalidad no es solo ejecutar comandos: se espera explicar el recorrido de la información y reconocer las limitaciones del sistema.

## 2.7.17. Síntesis del apartado

Construimos una integración docente entre API REST y Kafka mediante Python: organización de archivos, API local Flask, estructura de eventos, validación, serialización, productor y consumidor de verificación. Diferenciamos envío, confirmación y procesamiento, y analizamos los límites de una solución sin periodicidad ni estado persistente.

El apartado **2.8. Implementación de flujos en tiempo real y Near Real-Time** profundizará en ejecución continua, frecuencia, latencia y recuperación.
