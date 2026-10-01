# Libro SEM · PREP

Base de trabajo: `data/PREP.dta` (Stata): **8,242 respondientes** y **59 variables** sobre espacios públicos
y sus colonias, en **276 espacios**, **169 municipios** y **32 estados** (unos 30 respondientes por espacio).
Como marca el `.gitignore` del repositorio, **no se versiona**: cópiala manualmente a
`PREP/data/PREP.dta` antes de correr los scripts.

## Estado: diagnóstico hecho, scripts pendientes

Se revisó qué traen los archivos de referencia y si la base permite los 7 ejercicios (se corrió cada uno
con `lavaan` sobre `PREP.dta`). Detalle, cifras y lo que falta en [`00_Diagnostico/`](00_Diagnostico/).

> **Todos los archivos de referencia son del piloto** (`Datos_Piloto_MPLus*.dat`, `datos Piloto
> PREP_Final.dta`; N de 75 a 100, variables `B13`–`G3`). `PREP.dta` es el estudio final, con otra
> numeración y otro número de ítems por escala. Los modelos no se pueden correr tal cual: hace falta una
> tabla de equivalencias (propuesta en el diagnóstico, por confirmar).

| Carpeta | Ejercicio | En los archivos | Con la base |
|---|---|---|---|
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | ✅ `AFE.do`, `EFA_Hogares.inp`, Lab 2 | ✅ |
| [`02_AFC/`](02_AFC/) | Análisis factorial confirmatorio | ✅ dos `.inp`, PDF, Labs 2 y 5 | ✅ |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | ⚠️ solo la técnica (Lab 3, otras bases) | ✅ en lo técnico |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | Alfa, confiabilidad compuesta y validez | ⚠️ confiabilidad (Lab 2); **sin validez** | ✅ |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes factoriales | ✅ `SAVE = FS`, Labs 2 y 5 | ✅ (sin `id` ni `parque`) |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo | ❌ **no viene** | ✅ en lo técnico; **sin variable de grupo** |
| [`07_FIML/`](07_FIML/) | Datos faltantes: listwise vs FIML | ✅ Mplus (PDF), Labs 4 y 5 | ✅ |

`00_Diagnostico/` no forma parte del libro: es el diagnóstico (script + README) y se puede borrar cuando
termine esta etapa.

## Variables (según las etiquetas del `.dta`)

Todas son escalas de **1 a 10** con "Ns/Nc" = 99.

| Bloque | Variables | Contenido |
|---|---|---|
| Identificación | `espacio`, `ID_MPIO` | Número del espacio público y clave INEGI del municipio (estado = `ID_MPIO %/% 1000`) |
| B. Espacio público | `b11`–`b13` | Calificación de instalaciones, iluminación y aspecto físico |
| | `b14`–`b18` | Alcohol, miedo, robos, lastimados y droga (1 = totalmente cierto, 10 = totalmente falso). `b14Recod`–`b18Recod` están invertidas |
| | `b21`, `b22`, `b26` | Actividades: número, variedad para todas las edades y satisfacción |
| C. Seguridad en la colonia | `c01`–`c06` | Pandillas, borrachos, miedo a asaltos, robos, droga y agresiones a mujeres |
| | `c07`–`c09` | Calificación de la vigilancia y de la seguridad de día y de noche |
| D. Cohesión vecinal | `d01`–`d09` | Ayuda, convivencia, confianza, valores, participación y organización entre vecinos |
| E. Aspecto físico de la colonia | `e01`–`e05` | Limpieza, pavimento, banquetas, iluminación y aspecto general |
| F. Satisfacción | `f01`, `f02` | Satisfacción con la colonia y comparación con la colonia ideal |
| G. Participación y civismo | `g01`–`g04` | Reunión, participación, actividades y mantenimiento del espacio |
| | `g05`–`g08` | Acuerdo con conductas incívicas (con versión `Recod`) |
| | `g09`–`g12` | Qué haría ante ellas |

**Antes de analizar:** en los bloques C a F el "99 = Ns/Nc" viene como un valor, no como faltante (en B y G
ya es `NA`). Hay que recodificarlo a `NA`; si no, la media de `c05` sale en 17.

## Estructura

Es la misma que la de [`Tren_de_Guadalajara/`](../Tren_de_Guadalajara/). Cada carpeta trae su script de R,
un `README.md` y su `output/`, que no se versiona.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `PREP/data/` y en una terminal de R:

```r
source("PREP/00_setup_paquetes.R")
source("PREP/00_Diagnostico/Diagnostico.R")   # unos 7 minutos
```
