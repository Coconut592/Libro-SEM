# Libro SEM · PREP

Base de trabajo: `data/PREP.dta` (Stata): **8,242 registros** y **59 variables** sobre espacios públicos y
sus colonias. Como marca el `.gitignore` del repositorio, **no se versiona**: cópiala manualmente a
`PREP/data/PREP.dta` antes de correr los scripts.

## Variables (según las etiquetas del `.dta`)

| Bloque | Variables | Contenido |
|---|---|---|
| Identificación | `espacio`, `ID_MPIO` | Número del espacio público y municipio |
| B. Espacio público | `b11`–`b13`, `b14`–`b18`, `b21`, `b22`, `b26` | Calificación de instalaciones, iluminación y aspecto físico; percepción de alcohol, miedo, robos, lesionados y drogas; actividades. `b14Recod`–`b18Recod` son las versiones recodificadas |
| C. Seguridad en la colonia | `c01`–`c09` | Pandillas, borrachos, miedo a asaltos, robos, droga, agresiones a mujeres, vigilancia y seguridad de día y de noche |
| D. Cohesión vecinal | `d01`–`d09` | Ayuda, convivencia, confianza, valores, participación y organización entre vecinos |
| E. Aspecto físico de la colonia | `e01`–`e05` | Limpieza, pavimento, banquetas, iluminación y aspecto general |
| F. Satisfacción | `f01`, `f02` | Satisfacción con la colonia y comparación con la colonia ideal |
| G. Participación y civismo | `g01`–`g12` | Reunión y mantenimiento del espacio, acuerdo con conductas (`g05`–`g08`, con versión `Recod`) y qué haría ante ellas (`g09`–`g12`) |

El glosario completo (redacción de cada ítem, escalas, N y medias) se agregará cuando se compartan los
trabajos previos con el PREP.

## Estructura

Es la misma que la de [`Tren_de_Guadalajara/`](../Tren_de_Guadalajara/).

| Carpeta | Ejercicio | Estado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | ✅ |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | ⏳ pendiente |
| [`02_AFC/`](02_AFC/) | Análisis factorial confirmatorio | ⏳ pendiente |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | ⏳ pendiente |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | Alfa, confiabilidad compuesta y validez | ⏳ pendiente |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes factoriales | ⏳ pendiente |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo | ⏳ pendiente |
| [`07_FIML/`](07_FIML/) | Datos faltantes: listwise vs FIML | ⏳ pendiente |

Cada carpeta trae su script de R, un `README.md` y su `output/`, que no se versiona.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `PREP/data/` y en una terminal de R:

```r
source("PREP/00_setup_paquetes.R")
```
