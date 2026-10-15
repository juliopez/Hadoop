# Portal educativo Hadoop y Big Data

Esta carpeta contiene el portal público estático. El repositorio conserva su infraestructura Docker y los materiales originales.

## Despliegue

Para publicar desde GitHub Pages, configurar **Settings → Pages → Build and deployment → Deploy from a branch**, rama `master`, carpeta `/docs`, después de integrar el pull request. Alternativamente se puede utilizar un workflow compatible. La rama del PR no publica automáticamente el dominio principal.

## Contenido

- `index.html`: portada
- `libro.html`, `tecnologias.html`, `laboratorios.html`, `simuladores.html`, `infraestructura.html`, `recursos.html`: secciones temáticas
- `simulador_hdfs.html`, `simulador_mapreduce.html`: copias de publicación de las herramientas originales
- `assets/css/styles.css`, `assets/js/main.js`: diseño y menú compartidos

Los capítulos y guías enlazan a su ubicación permanente en GitHub. Se conservan las rutas existentes. Si se renombra la rama principal, actualizar los enlaces absolutos a `master`.

## Limitaciones y pendientes

- Revisar PDFs de 2 bytes: `Semana_01_ppt.pdf` y `Semana_02_ppt.pdf`.
- Revisar referencias editoriales al capítulo 8 y a un PDF consolidado aún inexistentes.
- Verificar DOI y metadatos de citación, que actualmente difieren entre lugares.
- Validar visualmente el despliegue público tras fusionar y configurar Pages.

No incluir credenciales reales o archivos con secretos en las páginas.
