# Diccionario de datos — Catálogos geográficos y comerciales

Este directorio contiene archivos CSV sintéticos de referencia para ejercicios de integración, clasificación y análisis de datos. No contienen información personal real.

## Archivos disponibles

### `dataset/ciudades.csv`

Catálogo de ciudades y su clasificación geográfica. **Granularidad:** una fila por ciudad. **Registros:** 7. **Clave:** `ciudad`.

| Campo | Tipo lógico | Descripción |
| --- | --- | --- |
| `ciudad` | Texto | Nombre de la ciudad; identificador de unión con datos transaccionales |
| `region` | Texto | Región administrativa asociada a la ciudad |
| `zona` | Texto | Macrozonificación descriptiva: Norte, Centro o Sur |

### `dataset/zonas_comerciales.csv`

Catálogo de clasificación comercial por ciudad. **Granularidad:** una fila por ciudad. **Registros:** 7. **Clave:** `ciudad`.

| Campo | Tipo lógico | Descripción |
| --- | --- | --- |
| `ciudad` | Texto | Nombre de la ciudad; identificador de unión con datos transaccionales |
| `zona_comercial` | Texto | Agrupación comercial: Norte, Centro o Sur |
| `prioridad` | Texto | Clasificación comercial sintética: Alta o Media |

## Convenciones y uso

- Formato: CSV con separador coma, encabezados en la primera fila y codificación UTF-8.
- Los nombres de ciudades se mantienen sin tildes para facilitar la correspondencia textual con otras fuentes.
- Cada catálogo contiene una única fila por ciudad; la correspondencia con datos externos depende de que los valores de `ciudad` coincidan exactamente.
- Las clasificaciones `zona`, `zona_comercial` y `prioridad` son categorías sintéticas de demostración, no clasificaciones oficiales.
- La integridad referencial debe verificarse al integrar estos catálogos con fuentes de transacciones; no se garantiza cobertura de todas las ciudades de un archivo externo.

## Procedencia

Datos de ejemplo elaborados para prácticas de procesamiento e integración de fuentes.