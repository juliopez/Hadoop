# Diccionario de datos

Catálogos CSV sintéticos para actividades de procesamiento e integración de datos.

## ciudades.csv

Una fila por ciudad; 7 registros. Clave: `ciudad`.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `ciudad` | Texto | Nombre de ciudad utilizado como clave de integración |
| `region` | Texto | Región asociada |
| `zona` | Texto | Clasificación geográfica sintética: Norte, Centro o Sur |

## zonas_comerciales.csv

Una fila por ciudad; 7 registros. Clave: `ciudad`.

| Campo | Tipo | Descripción |
| --- | --- | --- |
| `ciudad` | Texto | Nombre de ciudad utilizado como clave de integración |
| `zona_comercial` | Texto | Agrupación comercial sintética: Norte, Centro o Sur |
| `prioridad` | Texto | Clasificación comercial sintética: Alta o Media |

## Formato y observaciones

- CSV UTF-8, delimitado por comas y con encabezados.
- Los nombres de ciudades se escriben sin tildes.
- Los valores son ficticios o simplificados para fines didácticos; no constituyen una clasificación oficial.
- La correspondencia de `ciudad` con fuentes externas debe comprobarse antes de realizar uniones.
