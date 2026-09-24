# Libro SEM · Tren de Guadalajara

Encuesta de satisfacción de **306 usuarios** del Sistema de Tren Eléctrico Urbano (SITEUR) de
Guadalajara, Jalisco (Palacios & Vargas, 2009). Las entrevistas fueron directas, en estaciones
seleccionadas de las líneas 1 y 2, en distintos horarios y los siete días de la semana.

Base de trabajo: `data/imsctren2006.dta` (Stata). Como marca el `.gitignore` del repositorio, **no se
versiona**: cópiala manualmente a `Tren_de_Guadalajara/data/imsctren2006.dta` antes de correr los scripts.

Se trabaja solo con el `.dta`. El Excel `imsctren2006.xlsx` trae los mismos 12 ítems (idénticos, caso por
caso) y además `P1`–`P3` y `P9`–`P20`. Ninguna fuente dice qué miden esas columnas, así que no se usan.

## Glosario de variables

Todos los ítems usan una escala de **1 a 10** (mayor = más satisfecho). La redacción viene del PDF
*SEM02_Ejemplo_AFE-AFC* (lámina 3), porque el `.dta` no trae etiquetas.

| Variable | Concepto | Factor | N | Media | D.E. |
|---|---|---|---|---|---|
| `id` | Identificador del usuario (`1BBCC`: 17 bloques de 18 entrevistas) | — | 306 | | |
| `p4` | Información de la entrada a la estación | Acceso | 303 | 8.07 | 1.78 |
| `p5` | Evaluación de los torniquetes de entrada | Acceso | 306 | 7.73 | 2.08 |
| `p61` | Información para adquirir el pase para abordar el tren | Acceso | 293 | 7.54 | 1.91 |
| `p62` | Información para usar la máquina de fichas | Acceso | 305 | 7.28 | 2.08 |
| `p63` | Información para adquirir o recargar la tarjeta inteligente | Tarjeta | 199 | 7.27 | 2.25 |
| `p64` | Máquinas para compra y recarga de tarjetas inteligentes | Tarjeta | 178 | 7.40 | 1.92 |
| `p71` | Seguridad de puertas | Confort | 305 | 8.71 | 1.26 |
| `p72` | Tiempo de traslado | *(se elimina en el AFE)* | 306 | 9.20 | 1.01 |
| `p73` | Seguridad del tren | Confort | 306 | 8.79 | 1.11 |
| `p74` | Temperatura agradable | Confort | 306 | 8.06 | 1.77 |
| `p75` | Limpieza en el interior de los trenes | Confort | 306 | 8.36 | 1.70 |
| `p8` | Tiempo de espera en las estaciones | *(se elimina en el AFE)* | 306 | 8.19 | 1.43 |

**Factores:** *Acceso* (facilidad de acceso), *Tarjeta* (manejo de la tarjeta inteligente) y
*Confort* (confort y seguridad del viaje). Solo **170** usuarios responden los 12 ítems, casi todos los
faltantes están en la tarjeta.

## Estructura

| Carpeta | Ejercicio | Muestra | Referencia |
|---|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | — | — |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 170 completos | `AFE_CFA.R`, PDF |
| [`02_AFC/`](02_AFC/) | Análisis factorial confirmatorio | 170 completos | `AFE_CFA.R`, `.inp` |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | 170 completos | `CFA_2doOrden.inp` |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | Alfa, confiabilidad compuesta, AVE, Fornell-Larcker | 170 completos | `AFE_CFA.R`, PDF (+ validez) |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes centrados, en escala original y por media ponderada | 306 (FIML) | `CFA_Tren.inp`, `tren.inp`, PDF |
| [`06_FIML/`](06_FIML/) | Datos faltantes: listwise vs FIML | 306 | `AFE_CFA.R`, `.inp`, PDF |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los
resultados. Las tablas y gráficas se guardan en su `output/`, que no se versiona.

### ¿Por qué no hay Invarianza Factorial?

La invarianza factorial es un AFC multigrupo: pide una **variable de grupo** con sentido teórico (sexo,
línea, edad…) y suficientes casos en cada grupo (alrededor de 100 o más). Ni las referencias ni el `.dta`
la traen:

- El PDF describe la muestra (59% hombres, líneas 1 y 2), pero el `.dta` no incluye sexo, línea ni
  estación.
- Los 17 bloques del `id` no tienen documentación, y con 18 casos cada uno son demasiado pequeños.
- La única agrupación que se puede sacar del `.dta` es "respondió o no la tarjeta" (194 vs 94). Obliga a
  quitar el factor Tarjeta, deja un grupo con menos de 100 casos y su modelo configural ya ajusta mal
  (CFI .89, RMSEA .15). Una invarianza así no tendría interpretación válida.

Por eso se omite. Para hacerla haría falta la base original con una variable de grupo documentada.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `Tren_de_Guadalajara/data/` y en una
terminal de R corre:

```r
source("Tren_de_Guadalajara/00_setup_paquetes.R")
source("Tren_de_Guadalajara/01_AFE/AFE.R")
source("Tren_de_Guadalajara/02_AFC/AFC.R")
source("Tren_de_Guadalajara/03_AFC_2do_Orden/AFC_2do_Orden.R")
source("Tren_de_Guadalajara/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
source("Tren_de_Guadalajara/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
source("Tren_de_Guadalajara/06_FIML/FIML.R")
```

También puedes abrir cada script y correrlo sección por sección con `Ctrl+Enter`. Cada script es
independiente.

## Referencias

- Palacios Blanco, J. L., & Vargas Chanes, D. (2009). *Medición efectiva de la calidad*. Trillas.
- Brown, T. A. (2006). *Confirmatory factor analysis for applied research*. Guilford Press.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables
  and measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis.
  *Structural Equation Modeling, 6*(1), 1–55.
