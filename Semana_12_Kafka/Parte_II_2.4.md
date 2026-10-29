# 2.4. Consumo de eventos y funcionamiento de los grupos de consumidores

## 2.4.1. Del productor al consumidor: completar el flujo de eventos

En el apartado 2.3 estudiamos cómo las aplicaciones productoras construyen registros, los serializan y los publican en los tópicos de Kafka. El valor de una arquitectura orientada a eventos depende también de la capacidad de otras aplicaciones para recuperar y utilizar esa información.

Un **consumidor (*consumer*)** es una aplicación que se suscribe a uno o varios tópicos y recupera registros de sus particiones. Por ejemplo, a partir de una venta publicada en `ventas`, distintas aplicaciones pueden actualizar indicadores, detectar operaciones anómalas o alimentar un sistema analítico. El consumidor no necesita consultar directamente al sistema que registró la venta: recupera el evento desde Kafka.

## 2.4.2. Arquitectura básica del consumo de eventos

Una empresa puede publicar ventas en Kafka y permitir que varias aplicaciones independientes las procesen.

![Figura 46. Distribución de eventos hacia consumidores](imagenes/figura_46.svg)

*Figura 46. Distribución de eventos desde Kafka hacia distintos consumidores.*

Una aplicación calcula ingresos acumulados, otra evalúa patrones inusuales y otra incorpora datos a un repositorio analítico. Ninguna necesita esperar a que las otras terminen. **La lectura de un evento no lo elimina del tópico**, de modo que grupos independientes pueden consumirlo.

## 2.4.3. El modelo de consumo mediante polling

Kafka utiliza un modelo en que los consumidores solicitan datos mediante consultas (*polling*). El proceso general consiste en establecer conexión, suscribirse a tópicos, obtener particiones asignadas, solicitar registros, procesarlos y repetir la consulta.

En la API Java, una operación representativa es `poll()`. Una consulta puede devolver múltiples registros. Aunque se recuperen pequeños lotes, esto no equivale al procesamiento batch tradicional de grandes conjuntos históricos: los eventos pueden generarse continuamente.

## 2.4.4. Los offsets desde la perspectiva del consumidor

Cada registro tiene un offset dentro de su partición.

| Offset | Evento |
|---:|---|
| 0 | Venta V-1001 |
| 1 | Venta V-1002 |
| 2 | Venta V-1003 |
| 3 | Venta V-1004 |
| 4 | Venta V-1005 |

Debemos distinguir entre la posición actual de lectura y los offsets confirmados (*committed offsets*) del grupo. Un offset confirmado normalmente representa **la siguiente posición desde la cual se debe reanudar el consumo**. Si se procesaron los registros hasta el offset 2, confirmar el offset 3 indica que la siguiente posición pendiente es 3.

## 2.4.5. Confirmación automática y manual de offsets

| Modalidad | Característica | Consideración |
|---|---|---|
| Automática | El cliente confirma posiciones periódicamente | Simplifica el desarrollo, pero no asegura que cada evento haya terminado de procesarse |
| Manual | La aplicación decide cuándo confirmar | Permite coordinar el avance con la finalización de tareas |

Si una aplicación falla durante el procesamiento, la relación entre avance real y offsets confirmados determina si ciertos eventos podrían repetirse u omitirse. La estrategia debe responder a los requisitos de confiabilidad.

## 2.4.6. ¿Qué es un grupo de consumidores?

Un **grupo de consumidores (*consumer group*)** es un conjunto de instancias que colaboran para procesar registros. Cada grupo tiene un identificador `group.id`.

Dentro de un grupo, una partición se asigna normalmente a una sola instancia a la vez. Así se distribuye el trabajo sin que todas las instancias procesen los mismos registros de esa partición.

![Figura 47. Tres particiones y tres consumidores](imagenes/figura_47.svg)

*Figura 47. Distribución ilustrativa de tres particiones entre tres consumidores del mismo grupo.*

## 2.4.7. Relación entre particiones y paralelismo

| Consumidores en el grupo | Distribución posible para tres particiones |
|---:|---|
| 1 | Un consumidor procesa las tres |
| 2 | Uno procesa dos y otro una |
| 3 | Cada uno procesa una |
| 4 | Al menos uno queda sin particiones asignadas |

**Agregar consumidores no siempre aumenta el paralelismo**. Si existen más consumidores que particiones, algunos quedarán sin asignación de ese tópico. Aumentar particiones también puede afectar el orden de eventos asociados con claves.

## 2.4.8. Diferentes grupos pueden consumir los mismos eventos

Los consumidores de un grupo colaboran; **los grupos diferentes mantienen posiciones independientes**.

Por ejemplo, los grupos `indicadores`, `fraudes` e `historico` pueden leer el mismo tópico `ventas` y procesarlo con finalidades diferentes.

![Figura 48. Grupos independientes](imagenes/figura_48.svg)

*Figura 48. Grupos independientes que consumen un mismo tópico.*

Un grupo puede procesar casi inmediatamente mientras otro mantiene retraso, sin bloquearse entre sí. Sin embargo, todos están sujetos a la retención del tópico.

## 2.4.9. Rebalanceo de grupos de consumidores

Cuando cambia la composición de un grupo, Kafka puede redistribuir particiones mediante un **rebalanceo (*rebalance*)**. Esto puede ocurrir cuando se incorpora un consumidor, otro deja de funcionar, alguien abandona el grupo, cambian particiones o se incumplen ciertos intervalos de actividad.

![Figura 49. Rebalanceo de consumidores](imagenes/figura_49.svg)

*Figura 49. Redistribución ilustrativa de particiones después de incorporar un consumidor.*

Durante el rebalanceo puede verse temporalmente afectado el procesamiento. El comportamiento depende de la versión, del protocolo y de la estrategia de asignación.

## 2.4.10. Recuperación después de un fallo

Si un consumidor se detiene, puede reanudar a partir de los offsets confirmados. Dos situaciones son importantes:

**A.** El evento fue procesado, pero su offset no se confirmó. Tras reiniciar, podría procesarse nuevamente.

**B.** El offset fue confirmado antes de completar el procesamiento. Tras un fallo, podría omitirse un evento cuya operación de negocio no terminó.

Por ello, la confirmación de offsets es una decisión central de confiabilidad.

## 2.4.11. Semánticas de procesamiento y entrega

| Semántica | Interpretación |
|---|---|
| *At-most-once* | Un registro puede procesarse como máximo una vez, pero puede perderse ante fallos |
| *At-least-once* | Se busca evitar pérdidas mediante reintentos, aunque pueden aparecer duplicados |
| *Exactly-once* | El efecto se materializa una sola vez dentro de un alcance transaccional definido |

Estas garantías dependen de Kafka, del consumidor, del momento de confirmación y de los sistemas externos. Una actualización en una base de datos externa no se vuelve automáticamente *exactly-once* por utilizar Kafka.

## 2.4.12. Consumo mediante la consola de Kafka

```bash
kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic ventas \
  --from-beginning
```

`--from-beginning` permite comenzar desde los primeros registros **todavía disponibles** cuando no existe una posición previa aplicable; no recupera datos eliminados por retención.

```bash
kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic ventas \
  --group analitica
```

La sintaxis y opciones deben comprobarse en la imagen real del laboratorio, que utiliza una distribución anterior.

## 2.4.13. Implementación conceptual de un consumidor en Python

```python
from kafka import KafkaConsumer
import json

consumidor = KafkaConsumer(
    "ventas",
    bootstrap_servers="localhost:9092",
    group_id="indicadores",
    auto_offset_reset="earliest",
    enable_auto_commit=False,
    value_deserializer=lambda valor: json.loads(
        valor.decode("utf-8")
    )
)

try:
    for mensaje in consumidor:
        venta = mensaje.value

        print(
            f"Venta: {venta['id_venta']} | "
            f"Monto: {venta['monto']}"
        )

        # Confirmar después de completar el procesamiento.
        consumidor.commit()

finally:
    consumidor.close()
```

El consumidor se suscribe a `ventas`, participa en `indicadores`, deserializa JSON y confirma manualmente. `auto_offset_reset="earliest"` se aplica cuando el grupo no dispone de una posición válida; no reinicia el consumo en cada ejecución.

En producción, `commit()` debe ejecutarse después de completar las operaciones de negocio y deben gestionarse excepciones. Este ejemplo es didáctico y aún no está validado contra la distribución específica del laboratorio.

## 2.4.14. El retraso del consumidor o consumer lag

El **consumer lag** expresa la diferencia entre la posición final del registro y la posición confirmada por el grupo, según la herramienta y métrica utilizadas.

Si la siguiente posición del registro es 1000 y el grupo confirmó 850:

```text
Lag = 1000 - 850 = 150
```

![Figura 50. Consumer lag](imagenes/figura_50.svg)

*Figura 50. Representación conceptual del retraso de un consumidor.*

Un lag elevado puede señalar que se publican eventos más rápido de lo que se procesan, aunque no todo lag distinto de cero implica una falla. El lag mide posiciones, no directamente tiempo.

## 2.4.15. Aplicación al caso de transacciones comerciales

La empresa publica ventas en un tópico con tres particiones y establece tres grupos independientes.

| Grupo | Propósito | Procesamiento posible |
|---|---|---|
| `indicadores` | Métricas comerciales | Total de ventas y montos |
| `fraudes` | Detección de anomalías | Reglas de riesgo |
| `historico` | Repositorio analítico | Incorporación de registros |

Cada grupo puede tener varias instancias, con el límite de paralelismo determinado por las particiones. Los requisitos de confirmación pueden variar según la criticidad de cada aplicación.

## 2.4.16. Síntesis del apartado

Estudiamos cómo los consumidores recuperan eventos mediante *polling*, administran offsets y confirman su avance. Los grupos permiten distribuir particiones entre instancias; grupos diferentes procesan independientemente los mismos eventos. Analizamos rebalanceo, recuperación, semánticas de procesamiento y *consumer lag*. En el apartado **2.5. Estructuración de mensajes: texto, JSON, claves y marcas temporales** profundizaremos en la representación de registros.
