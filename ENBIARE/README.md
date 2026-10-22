# Libro SEM · ENBIARE

Bienestar subjetivo con la **ENBIARE 2021** (Encuesta Nacional de Bienestar Autorreportado, INEGI): el
**Cuestionario de Bienestar Autorreportado**. Es una encuesta a una persona seleccionada por hogar, con
satisfacción con la vida y con 17 aspectos específicos, afecto del día anterior, confianza, salud mental,
vida social, trabajo, eventos de vida y discriminación.

Base de trabajo: `data/conjunto_de_datos_tenbiare_enbiare_2021.csv` (**31,166 personas** y **284 variables**) y su
diccionario, `data/diccionario_datos_tenbiare_enbiare_2021.csv`. Como marca el `.gitignore` del repositorio, **no se
versionan**: cópialos a `ENBIARE/data/` antes de correr los scripts. La base viene en **latin1** y con los nombres en
MAYÚSCULAS; los scripts lo resuelven al leerla.

> **No hay documento de referencia** (tesis, capítulo, `.inp`): no existe un modelo publicado que reproducir. Las
> estructuras salen de un AFE sobre la base y del contenido de los ítems.

## Estado: diagnóstico hecho, falta decidir qué escala(s) se trabajan

| Carpeta | Contenido | Estado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | ✅ |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué trae la base, qué bloques de ítems sirven y cada ejercicio probado con los datos reales | ✅ |
| `01_AFE/` a `07_FIML/` | Los 7 ejercicios, con la estructura de los demás proyectos | ⏳ Esperan la elección de la(s) escala(s) |

> **La base alcanza para 6 de los 7 ejercicios, con datos reales.** Está limpia (ningún valor fuera del rango del
> diccionario) y las escalas de bienestar no tienen faltantes. El **FIML** es la excepción: ahí no hay qué imputar, y
> el único bloque con faltantes parciales es el de `ph1_*`/`ph2_*` (14 %). Detalle y cifras en
> [`00_Diagnostico/`](00_Diagnostico/).

## ¿Qué análisis se pueden hacer?

| Análisis | ¿Se puede? | Mejor candidato y resultado |
|---|---|---|
| **AFE** | ✅ Sí | Satisfacción (17 ítems) en **5 factores**, confianza (12) en **5**, afecto (10) en **2**, salud mental (9) en **2** |
| **AFC** | ✅ Sí | Confianza CFI .968 · Satisfacción .952 · Afecto .943 · Salud mental .995 (WLSMV) |
| **AFC de 2.º orden** | ✅ Sí, en 4 bloques | Confianza institucional (CFI .962) · Satisfacción con la vida (.938) · Bienestar subjetivo (3 factores, justo identificado) · Reuniones sociales |
| **Confiabilidad y validez** | ✅ Sí, **con criterio externo dentro de la base** | Confianza y afecto cumplen CR y Fornell-Larcker (AVE ≥ .49); **Satisfacción no llega a AVE .50** (depende del estimador) |
| **Puntajes factoriales** | ✅ Sí | Los 31,166 reciben puntaje; determinación .86–.97 |
| **Invarianza factorial** | ⚠️ Sí, **pero no por sexo ni edad** | La base no trae sexo ni edad; se probó por **tamaño de localidad** (4 grupos): pasa hasta la escalar en confianza y afecto; en satisfacción justo en el límite |
| **FIML** | ❌ No en las escalas de bienestar | No tienen faltantes. Solo `ph1_4`/`ph2_4` (14 %), con ítems Sí/No tratados como continuos |

## Qué falta

1. **Sexo y edad** (e idealmente escolaridad): la base no trae ninguna variable del encuestado. Las cuatro primeras
   columnas (`folio`, `viv_sel`, `hogar`, `n_ren`) son la llave para unir la tabla sociodemográfica de la encuesta,
   que no se subió. Sin ella, la invarianza se queda en `tloc` o `ent`.
2. **Las etiquetas de valor** (catálogos): el diccionario trae la columna `catálogo`, pero vacía o repitiendo el nombre
   de la variable. Las direcciones de las escalas se infirieron (1 = sí / 2 = no; 1 = nunca a 5 = diario en `pc2`/`pc3`;
   1 = sin dificultad en `pd1`) y hay que confirmarlas con el cuestionario.
3. **Decisiones** (con propuesta, en [`00_Diagnostico/`](00_Diagnostico/)): qué escala(s) se trabajan, ponderador,
   grupo de la invarianza y qué hacer con el FIML.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base y el diccionario a `ENBIARE/data/` y en una terminal
de R:

```r
source("ENBIARE/00_setup_paquetes.R")
source("ENBIARE/00_Diagnostico/Diagnostico.R")     # ~4 min
```

Por ahora solo hay diagnóstico; los 7 ejercicios se agregan cuando se elija la escala.
