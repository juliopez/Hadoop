# Diccionario de datos

Conjuntos de datos sintéticos para ejercicios de integración, procesamiento y análisis de información comercial. Los datos no representan transacciones ni personas reales.

## Archivos disponibles en este directorio

### `ciudades.csv`
7 filas; clave única `ciudad`.

| Campo | Tipo lógico | Descripción |
|---|---|---|
| `ciudad` | Texto | Nombre de la ciudad, clave de integración |
| `region` | Texto | Región asociada |
| `zona` | Texto | Clasificación geográfica sintética |

### `zonas_comerciales.csv`
7 filas; clave única `ciudad`.

| Campo | Tipo lógico | Descripción |
|---|---|---|
| `ciudad` | Texto | Nombre de la ciudad, clave de integración |
| `zona_comercial` | Texto | Agrupación comercial sintética |
| `prioridad` | Texto | Clasificación comercial sintética |

## Otros archivos disponibles

Los siguientes archivos CSV sintéticos también están disponibles en este directorio.

### `ventas_evaluacion.csv`
100.000 filas; clave única `id_venta`.

| Campo | Tipo lógico | Descripción |
|---|---|---|
| `id_venta` | Texto | Identificador único de transacción |
| `fecha` | Fecha ISO (AAAA-MM-DD) | Fecha de venta |
| `cliente` | Texto | Identificador de cliente, relacionado con `clientes.csv` |
| `ciudad` | Texto | Ciudad de la transacción; puede no figurar en los catálogos |
| `categoria` | Texto | Categoría comercial |
| `monto` | Entero | Importe de venta; puede contener valores no positivos para validación |

### `clientes.csv`
5.000 filas; clave única `cliente`.

| Campo | Tipo lógico | Descripción |
|---|---|---|
| `cliente` | Texto | Identificador único de cliente |
| `segmento` | Texto | Segmentación comercial sintética |
| `antiguedad` | Entero | Antigüedad sintética expresada en años |

## Convenciones

- Archivos CSV codificados en UTF-8, separados por comas y con encabezado.
- Los nombres de ciudades no utilizan tildes.
- Las categorías territoriales y comerciales son sintéticas, no clasificaciones oficiales.
- Las relaciones entre tablas se realizan mediante coincidencia exacta de `ciudad` o `cliente`, según corresponda.
- La existencia de registros sin correspondencia o montos no positivos permite practicar controles de calidad de datos.
