# Libro SEM · Habilidades Políticas

Validación del **Inventario de Habilidades Políticas** de Ferris et al. (2005; PSI, *Political Skill
Inventory*) con una muestra de **356 estudiantes mexicanos** de licenciatura y posgrado (López-Lemus y
Zavala; edad promedio 24.8 años; 161 hombres y 195 mujeres). El PSI mide la habilidad política en cuatro
dimensiones, y el capítulo la valida con un **AFC de segundo orden** (Mplus v.7).

Base de trabajo: `data/Cap6_AFC_2orden.dta` (Stata). Como marca el `.gitignore` del repositorio, **no se
versiona**: cópiala manualmente a `Habilidades_Politicas/data/Cap6_AFC_2orden.dta` antes de correr los
scripts.

## Qué había y qué se hizo

Se tienen **tres archivos**: el capítulo (PDF), su presentación (PPTX) y la base. Cubren el **AFC de primer y
segundo orden**; el resto de los ejercicios se agregaron con el esquema de los otros proyectos.

> **Antes de usar los números del capítulo, ver [`00_Diagnostico`](00_Diagnostico/).** El modelo final se
> reproduce (sus 19 cargas coinciden al milésimo), pero **el ajuste que publica incluye a `Genero` como
> variable adicional** y la Tabla 5 tiene tres cargas con la etiqueta cambiada. Los valores correctos del
> ajuste son χ²(86) = 246.6, CFI .931, TLI .915, RMSEA .072, SRMR .048.

| Carpeta | Ejercicio | Muestra | Referencia |
|---|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | — | — |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué trae cada archivo, qué se reproduce del capítulo y qué falta | 356 | Capítulo, PPTX |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 356 | *Sin referencia* |
| [`02_AFC/`](02_AFC/) | AFC de primer orden (4 factores) | 356 | Tabla 5, Anexo 2, PPTX láms. 16–19 |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden (Habilidad Política) | 356 | Figura 1, Tabla 5, Anexo 2 |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | Alfa, confiabilidad compuesta, omega, AVE, HTMT, validez | 356 | Capítulo, PPTX lám. 16 |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes centrados, en escala original y por media ponderada | 356 | *Sin referencia* |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo: hombres contra mujeres | 161 y 195 | *Sin referencia* |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los
resultados. Las tablas y gráficas se guardan en su `output/`, que no se versiona. **Cada script es
independiente.**

## ¿Qué análisis se pueden hacer con esta base?

Se pueden hacer **6 de los 7**:

| Análisis | ¿Se puede? | Modelo y muestra | Resultado principal |
|---|---|---|---|
| **AFE** | Sí | 15 ítems, 356 | KMO .92; el análisis paralelo recomienda **3 factores**: HR e II salen claros, SA y AS se mezclan |
| **AFC** | Sí, solo con 15 ítems | 4 factores, 356 (ML) | χ²(84) = 246.5, CFI .930, TLI .912, RMSEA .074, SRMR .048; cargas de .63 a .81 |
| **AFC de 2.º orden** | Sí, y **contrastable** (2 gl) | HP sobre HR, SA, AS, II | χ²(86) = 246.6, CFI .931, RMSEA .072; cargas de .81 a .95; igual de bueno que el primer orden (Δχ² = 0.14, p = .93) |
| **Confiabilidad y validez** | Sí, **salvo validez de criterio** | 4 factores | α .74–.83 (total .91); ω jerárquico .85; AVE .44–.61; **validez discriminante débil** |
| **Puntajes factoriales** | Sí | 4 dimensiones + HP | Determinación ≥ .92; el promedio simple correlaciona .94–.99 con ellos |
| **Invarianza factorial** | Sí, **por género** | 161 contra 195 | Se sostiene hasta la estricta (MLR); matiz en las cargas de segundo orden; ajuste de partida mediocre |
| **FIML** | **No** | — | La base no tiene datos faltantes |

- **Qué no se pudo:** el FIML (no hay faltantes), la validez de criterio (no hay criterio externo) y el AFC de
  18 ítems.
- **Qué se perdió del capítulo:** la base solo trae los **15 ítems** de la versión final. El primer modelo
  (18 reactivos, χ² = 500.2) no se puede reproducir.
- **La estructura de los datos:** hay un **factor general muy fuerte** (primer eigenvalor 6.7 de 15; omega
  jerárquico .85) y dos dimensiones, Sinceridad aparente y Astucia social, que se parecen tanto
  (correlación .89, HTMT .90) que casi no se distinguen. Es lo que el AFC de segundo orden hace visible.
- **Validez de criterio:** requiere un criterio externo. El `.dta` solo trae `Genero` y los ítems.

## Glosario

El PSI tiene **18 reactivos** de 1 a 7 (1 = muy en desacuerdo, 7 = muy de acuerdo). La base trae **15**:

| Factor | Sigla | Ítems en la base | Eliminados por el capítulo |
|---|---|---|---|
| Habilidad en redes | `HR` | `HR1`–`HR4`, `HR6` (5) | `HR5` |
| Sinceridad aparente | `SA` | `SA7`–`SA9` (3) | — |
| Astucia social | `AS` | `AS10`, `AS11`, `AS13`, `AS14` (4) | `AS12` |
| Influencia interpersonal | `II` | `II16`–`II18` (3) | `II15` |
| **Habilidad política** (segundo orden) | `HP` | los 15 | — |

**Redacción de los reactivos** (lámina 11 de la presentación; incluye los tres eliminados). La presentación
da las frases por factor pero **no indica el número de ítem de cada una**, así que no se asignan:

- **Habilidad en redes:** *Dedico mucho tiempo y esfuerzo al trabajo en red con otros. · Soy bueno para
  entablar relaciones con personas influyentes en el trabajo. · He desarrollado una gran red de colegas y
  asociados en el trabajo a quienes puedo recurrir para obtener apoyo cuando realmente necesito hacer las
  cosas. · En el trabajo, conozco a mucha gente importante y estoy bien conectado. · Paso mucho tiempo en
  el trabajo desarrollando conexiones con los demás. · Soy bueno usando mis conexiones y mi red para hacer
  que las cosas sucedan en el trabajo.*
- **Influencia interpersonal:** *Puedo hacer que la mayoría de las personas se sientan cómodas y tranquilas
  a mi alrededor. · Puedo comunicarme fácil y eficazmente con los demás. · Es fácil para mí desarrollar una
  buena relación con la mayoría de las personas. · Soy bueno para gustarle a la gente.*
- **Astucia social:** *Entiendo muy bien a la gente. · Soy particularmente bueno detectando las
  motivaciones y las agendas ocultas de los demás. · Tengo buena intuición o conocimiento sobre cómo
  presentarme a los demás. · Siempre parezco saber instintivamente las cosas correctas que debo decir o
  hacer para influir en los demás. · Presto mucha atención a las expresiones faciales de las personas.*
- **Sinceridad aparente:** *Cuando me comunico con los demás, trato de ser genuino en lo que digo y hago.
  · Es importante que la gente crea que soy sincero en lo que digo y hago. · Intento mostrar un interés
  genuino por otras personas.*

| Variable | Factor | N | Media | D.E. |
|---|---|---|---|---|
| `HR1` | HR | 356 | 5.13 | 1.37 |
| `HR2` | HR | 356 | 5.21 | 1.36 |
| `HR3` | HR | 356 | 5.21 | 1.47 |
| `HR4` | HR | 356 | 4.93 | 1.50 |
| `HR6` | HR | 356 | 5.09 | 1.43 |
| `SA7` | SA | 356 | 5.85 | 1.36 |
| `SA8` | SA | 356 | 5.76 | 1.35 |
| `SA9` | SA | 356 | 5.44 | 1.37 |
| `AS10` | AS | 356 | 5.00 | 1.34 |
| `AS11` | AS | 356 | 5.32 | 1.35 |
| `AS13` | AS | 356 | 5.39 | 1.40 |
| `AS14` | AS | 356 | 5.19 | 1.29 |
| `II16` | II | 356 | 5.40 | 1.35 |
| `II17` | II | 356 | 5.27 | 1.39 |
| `II18` | II | 356 | 5.49 | 1.34 |

`Genero`: 1 (n = 161) y 2 (n = 195), sin etiqueta en el `.dta`. Por las frecuencias del capítulo, 1 =
hombre y 2 = mujer. La base **no trae** identificador, edad ni faltantes. Las columnas están en otro orden
que el del cuestionario (`AS11 AS13 AS10 AS14 II16 ... HR6 SA7 SA8 SA9`).

## Decisiones que se tomaron

Conviene revisarlas:

1. **ML como estimador principal**, igual que el capítulo (`ESTIMATOR=ML`). Los ítems no son normales
   (Mardia p < .001), así que se verifica con **MLR** y con un tratamiento **ordinal** (WLSMV): misma
   estructura; ver [`02_AFC`](02_AFC/). La invarianza usa MLR.
2. **El modelo final es el de 15 ítems.** No se eliminan más ítems ni se modifica con los índices de
   modificación (los mayores son de ~19 y dentro del mismo factor).
3. **Los números publicados del ajuste no se toman como referencia** (incluyen a `Genero`); se usan los de
   `lavaan` sin ella, que coinciden con la lámina 19 del PPTX.
4. **Rotación oblimin** en el AFE, no varimax: los factores correlacionan de .45 a .60.
5. **Marcadores de la escala original de los puntajes:** `HR3`, `SA8`, `AS11` e `II17`, los del Anexo 2.
6. **Invarianza por género** con 1 = hombre y 2 = mujer (deducido de las frecuencias). El modelo ajusta
   regular dentro de cada grupo y en los hombres SA y AS correlacionan 1.05 (solución inadmisible), por lo
   que las conclusiones de invarianza son más débiles.
## Qué conviene confirmar con las autoras

- **¿El archivo de Mplus (`HP15R.dta.dat`) incluye `Genero`?** Explicaría el ajuste publicado (101 gl).
- **Las etiquetas de `AS10`, `AS11` y `AS13`** en la Tabla 5 (o el orden de las columnas de la base).
- **La base de 18 ítems**, para reproducir la Tabla 3 y el criterio con el que se eliminaron `HR5`, `AS12` e
  `II15`.
- Qué significan **1 y 2** en `Genero` y **qué ítem es cada frase** del PSI.
- Una **variable criterio**, si se quiere validez de criterio.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `Habilidades_Politicas/data/` y en una
terminal de R corre (los tiempos son aproximados):

```r
source("Habilidades_Politicas/00_setup_paquetes.R")
source("Habilidades_Politicas/00_Diagnostico/Diagnostico.R")                        # ~5 s
source("Habilidades_Politicas/01_AFE/AFE.R")                                        # ~10 s
source("Habilidades_Politicas/02_AFC/AFC.R")                                        # ~10 s
source("Habilidades_Politicas/03_AFC_2do_Orden/AFC_2do_Orden.R")                    # ~10 s
source("Habilidades_Politicas/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~5 s
source("Habilidades_Politicas/05_Puntajes_Factoriales/Puntajes_Factoriales.R")      # ~5 s
source("Habilidades_Politicas/06_Invarianza_Factorial/Invarianza_Factorial.R")      # ~15 s
```

También puedes abrir cada script y correrlo sección por sección con `Ctrl+Enter`. Cada script es
independiente.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance.
  *Structural Equation Modeling, 14*(3), 464–504.
- Chen, F. F., Sousa, K. H., & West, S. G. (2005). Testing measurement invariance of second-order factor
  models. *Structural Equation Modeling, 12*(3), 471–492.
- Ferris, G. R., Treadway, D. C., Kolodinsky, R. W., Hochwarter, W. A., Kacmar, C. J., Douglas, C., &
  Frink, D. D. (2005). Development and validation of the Political Skill Inventory. *Journal of
  Management, 31*(1), 125–152 (páginas como las cita el capítulo).
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables
  and measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity
  in variance-based structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1),
  115–135.
- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis.
  *Structural Equation Modeling, 6*(1), 1–55.
- López-Lemus, J. A., & Zavala Berbena, M. A. *Validación del inventario de habilidades políticas de
  Ferris mediante análisis factorial de segundo orden* (capítulo 6).
- Meredith, W. (1993). Measurement invariance, factor analysis and factorial invariance. *Psychometrika,
  58*(4), 525–543.
- Nunnally, J. C. (1987). *Teoría psicométrica*. Trillas.
- Vandenberg, R. J., & Lance, C. E. (2000). A review and synthesis of the measurement invariance
  literature. *Organizational Research Methods, 3*(1), 4–70.
