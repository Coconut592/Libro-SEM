# Libro SEM · EMOVI

Movilidad social con la **ESRU-EMOVI 2023** (Encuesta ESRU de Movilidad Social en México, CEEY), solo la
**Ciudad de México**. La referencia es la tesis de Sánchez Flores (UNAM, 2019), que modela con SEM, al estilo de
Blau y Duncan, cómo el **origen social** llega al **logro ocupacional** a través de la **educación** y la
**primera ocupación** (ESRU-EMOVI 2017, CDMX, n = 3,117, Mplus).

Base de trabajo: `data/entrevistado_2023_CDMX.dta` (Stata): **740 entrevistados** de 25 a 64 años de la CDMX
(`entidad` = 9) y 296 columnas. Es el Entrevistado 2023 completo (17,843 filas, 39 MB) recortado con
[`00_Diagnostico/Recortar_Entrevistado.R`](00_Diagnostico/Recortar_Entrevistado.R). Como marca el `.gitignore`
del repositorio, **no se versiona**: cópiala a `EMOVI/data/` antes de correr los scripts.

## Qué se hizo

> **Una sola escala para los ejercicios: la riqueza del hogar de origen** (a los 14 años): `p26`, `p29`, `p31` y
> `p32`, 42 ítems Sí/No, de los que **29** pasan el criterio 90-10 de la tesis. Es el índice de riqueza de la
> tesis (Anexo 2), pero con tres dimensiones que salen del AFE. El FIML va aparte, en el AFC de **Origen social**.

| Carpeta | Ejercicio | Resultado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué traían los archivos y qué faltaba | El Entrevistado no cabía como adjunto: se recortó a la CDMX |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 3 factores: espacios, servicios y bienes básicos, tecnología (CFI .985) |
| [`02_AFC/`](02_AFC/) | AFC de primer orden | CFI .975, TLI .973, RMSEA .039; cargas de .42 a .96 |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | Cargas .84, .97 y .83; justo identificado (mismo ajuste que el 1.er orden) |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | KR-20, CR, AVE, HTMT, criterio | KR-20 .75–.85, CR .90–.96; HTMT bajo .85, pero ESP y BAS no pasan Fornell-Larcker; criterio ρ .26–.52 |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes factoriales | 740 puntajes; r = .98 con el índice simple y con el PCA (la tesis: .93) |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo | Sexo: invarianza. Edad: ΔCFI −.002, pero la χ² rechaza (p = .001) |
| [`07_FIML/`](07_FIML/) | Listwise contra FIML | 195 → 740 casos; errores estándar 37 % menores; ajuste mediocre (RMSEA .098) |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los resultados.
Las tablas se guardan en su `output/`, que no se versiona. **Cada script es independiente.**

## Decisiones que se tomaron

Conviene revisarlas:

| Tema | Decisión |
|---|---|
| Muestra | Solo la **Ciudad de México** (`entidad` = 9), como la tesis |
| Ocupación | Las **6 clases ocupacionales** de la base (`clase`, `clasep`, `clasem`, `clase1`), no el ISEI |
| Diseño muestral | **Sin ponderador** (`factor`, `upm_muestra`, `est`), como la tesis, que no lo menciona |
| Ítems binarios | Ordinales (**WLSMV**), con `missing = "pairwise"`; criterio 90-10 de la tesis |
| Número de factores | 3, por el ajuste del AFE de `lavaan` (el análisis paralelo y Kaiser dan 6, pero sobrestiman con ítems 0/1) |
| Invarianza | Por sexo y por 25–40 contra 41–64, los grupos de la tesis; umbrales y cargas juntos |
| FIML | AFC de Origen social con indicadores **continuos** (clases como numéricas) y MLR, porque `lavaan` no tiene FIML con ítems ordinales |

## Lo que conviene tener presente

- **El AFC confirma con los mismos datos del AFE.** Con 740 casos no se partió la muestra: la estructura de tres
  factores no es una prueba independiente.
- **Validez discriminante mixta:** los tres factores correlacionan de .69 a .81; HTMT queda bajo .85, pero ESP
  (AVE .48) y BAS (.56) no pasan Fornell-Larcker. Por eso el segundo orden tiene sentido.
- **El bloque de activos financieros (`p32`) casi desaparece en la CDMX** (11 de 15 ítems con menos de 10 %): la
  tesis trabajó con todo el país (n = 17,665), donde sí varían.
- **Sin ISEI**, Origen social (07) es menos fina que la de la tesis.
- **Lo que no se hizo:** el SEM completo de la tesis (Origen → Educación → Primera ocupación → Logro) no es parte
  de los 7 ejercicios; ni la comparación 14 años contra hoy.
- **Ingreso:** el Entrevistado 2023 trae su propia `ingc_pc`; `ingreso_2017.dta` es de la EMOVI 2017 y no se usa.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia `entrevistado_2023_CDMX.dta` a `EMOVI/data/` y en una
terminal de R (los tiempos son aproximados):

```r
source("EMOVI/00_setup_paquetes.R")
source("EMOVI/01_AFE/AFE.R")                                          # ~20 s
source("EMOVI/02_AFC/AFC.R")                                          # ~20 s
source("EMOVI/03_AFC_2do_Orden/AFC_2do_Orden.R")                      # ~20 s
source("EMOVI/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~20 s
source("EMOVI/05_Puntajes_Factoriales/Puntajes_Factoriales.R")        # ~20 s
source("EMOVI/06_Invarianza_Factorial/Invarianza_Factorial.R")        # ~40 s
source("EMOVI/07_FIML/FIML.R")                                        # ~20 s
```

Para volver a recortar el Entrevistado completo a la CDMX (si no, ya está hecho): copia el `.dta` completo a
`EMOVI/data/` y corre `source("EMOVI/00_Diagnostico/Recortar_Entrevistado.R")` (o la versión en Python que se usó,
con `pandas`). El diagnóstico previo (qué traían los archivos) corre con `source("EMOVI/00_Diagnostico/Diagnostico.R")`.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance. *Structural
  Equation Modeling, 14*(3), 464–504.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables and
  measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in
  variance-based structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1), 115–135.
- Millsap, R. E., & Tein, J.-Y. (2004). Assessing factorial invariance in ordered-categorical measures.
  *Multivariate Behavioral Research, 39*(3), 479–515.
- Sánchez Flores, J. N. (2019). *La movilidad social en la Ciudad de México: una aproximación desde el modelado
  estructural* [Tesis de licenciatura]. Facultad de Economía, UNAM.
