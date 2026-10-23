# Libro SEM · ENBIARE

Bienestar subjetivo con la **ENBIARE 2021** (Encuesta Nacional de Bienestar Autorreportado, INEGI): el
**Cuestionario de Bienestar Autorreportado**. Es una encuesta a una persona seleccionada por hogar, con satisfacción con la
vida y con 17 aspectos específicos, afecto del día anterior, confianza, salud mental, vida social, trabajo, eventos de vida y
discriminación.

Base de trabajo: `data/conjunto_de_datos_tenbiare_enbiare_2021.csv` (**31,166 personas** y **284 variables**) y su
diccionario, `data/diccionario_datos_tenbiare_enbiare_2021.csv`. Como marca el `.gitignore` del repositorio, **no se
versionan**: cópialos a `ENBIARE/data/` antes de correr los scripts. La base viene en **latin1** y con los nombres en
MAYÚSCULAS; los scripts lo resuelven al leerla.

> **No hay documento de referencia** (tesis, capítulo, `.inp`): no existe un modelo publicado que reproducir. Las estructuras
> salen de un AFE sobre la base y del contenido de los ítems.

## Qué se hizo

> **Dos escalas para los ejercicios:**
> - **Satisfacción con la vida** (principal): los 17 aspectos de `pa3_01`–`pa3_17`, con **5 factores** (nivel de vida y
>   logros, relaciones, autonomía y actividad, hogar y vecindario, ciudad y país) y un factor general de segundo orden.
> - **Confianza** (segunda): 11 de los 12 ítems de `pb1` (sin `pb1_03`, medios), con **5 factores** (interpersonal, policías,
>   fuerzas armadas, justicia y política) y un factor de **confianza institucional** de segundo orden.
>
> El afecto, la depresión, la ansiedad, `pa1` y `pa5` se usan solo como **criterio externo** de la validez (04). **El FIML se
> omite:** las escalas no tienen faltantes (ver 00).

| Carpeta | Ejercicio | Resultado |
|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué trae la base y si alcanza | Alcanza para 6 de los 7; el FIML no aplica |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 5 factores en las dos escalas (RMSEA .035 y .021); estable en dos mitades (congruencia ≥ .99) |
| [`02_AFC/`](02_AFC/) | AFC de primer orden | SAT CFI .952, RMSEA .047; CONF CFI .968, RMSEA .088 (.062 con una carga cruzada); validado en una mitad independiente |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden | CONF ΔCFI −.006 (cargas .82–.93); SAT −.014 (cargas .60–.91), mejor con dos generales (personal y entorno) |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | α, ω, CR, AVE, HTMT, criterio | CONF cumple todo; **SAT: AVE .41–.45** (.49–.54 con WLSMV) pero criterio sólido (r = .60 con `pa1`) |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes factoriales | 31,166 puntajes; determinación .84–.97; confianza institucional más baja en localidades grandes (4.3 contra 5.2) |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo (`tloc`, 4 grupos) | CONF hasta la estricta; SAT hasta la escalar **justo en el límite** (parcial: sí); la estricta no |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los resultados. Las tablas se
guardan en su `output/`, que no se versiona. **Cada script es independiente.**

## Decisiones que se tomaron

Conviene revisarlas:

| Tema | Decisión |
|---|---|
| Escalas | **Satisfacción (`pa3`)** como principal y **confianza (`pb1`)** como segunda; lo propuesto en el diagnóstico |
| `pb1_03` | **Fuera** (medios de comunicación): no pertenece a ningún factor (cargas de .19 a .30) |
| Número de factores | **5** en las dos. En satisfacción el análisis paralelo da 5 o 6 según la semilla (es un caso límite); se escoge por el ajuste del AFE (RMSEA .035) y porque los factores se pueden nombrar |
| Estimador | **MLR**, con las escalas 0-10 como continuas (11 categorías, asimetría hasta −2.5); **WLSMV** como sensibilidad en 02, 03 y 04 |
| Diseño muestral | **Sin ponderador ni conglomerado** en los modelos: el conglomerado por UPM no cambia nada (error estándar ×1.01) y ponderar mueve las cargas hasta .05. **Con ponderador** solo las medias poblacionales (05) |
| Segundo orden de satisfacción | **Un general único** (ΔCFI −.014, algo más que el .010 de Chen), con la variante de **dos generales** (personal y entorno, r = .75) que ajusta casi como el primer orden. Para confianza, el general cubre los 4 factores institucionales y `INT` queda aparte (su carga en el general sería .46) |
| Invarianza | Por **tamaño de localidad** (`tloc`, 4 grupos), porque la base no trae sexo ni edad |
| AFE y AFC en la misma muestra | Con las 31,166 personas, más una **validación cruzada** (AFE en una mitad y AFC en la otra) en 02 |
| FIML | **Omitido**: las escalas no tienen faltantes, y simularlos no se hace (como en Habilidades Políticas) |

## Lo que conviene tener presente

- **La validez convergente de satisfacción es el punto débil:** AVE de .41 a .45 en los cinco factores con MLR (ninguno pasa
  Fornell-Larcker, aunque HTMT queda bajo .85); con WLSMV sube a .49–.54. Su validez de criterio, en cambio, es buena.
- **Satisfacción es invariante por localidad solo por un pelo** (escalar, ΔCFI −.010) y la estricta no. Las diferencias
  entre localidades, en particular las de ciudad y país, se leen con cautela.
- **El RMSEA de confianza (.088) es alto aunque el CFI es de .968:** viene de una carga cruzada de `pb1_10` (cámaras) en
  justicia; con ella, RMSEA .062. Se deja la estructura simple como principal.
- **Sin sexo ni edad:** la invarianza se probó por `tloc`; cuando llegue la tabla sociodemográfica (se une por `folio`,
  `viv_sel`, `hogar` y `n_ren`), se agregan sexo y edad con los mismos scripts.
- **Faltan las etiquetas de valor** del diccionario: el significado de `tloc` (se supone 1 = más de 100 mil habitantes ...
  4 = menos de 2,500) y las direcciones de las escalas se infirieron y hay que confirmarlas con el cuestionario.
- **Los errores estándar de las medias por localidad y entidad (05) no incorporan el diseño muestral** (haría falta
  `survey` con estrato y UPM): las diferencias de décimas entre entidades no deben leerse como significativas.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base y el diccionario a `ENBIARE/data/` y en una terminal de R (los
tiempos son aproximados):

```r
source("ENBIARE/00_setup_paquetes.R")
source("ENBIARE/00_Diagnostico/Diagnostico.R")                          # ~4 min (opcional)
source("ENBIARE/01_AFE/AFE.R")                                          # ~1 min
source("ENBIARE/02_AFC/AFC.R")                                          # ~1 min
source("ENBIARE/03_AFC_2do_Orden/AFC_2do_Orden.R")                      # ~1 min
source("ENBIARE/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~50 s
source("ENBIARE/05_Puntajes_Factoriales/Puntajes_Factoriales.R")        # ~10 s
source("ENBIARE/06_Invarianza_Factorial/Invarianza_Factorial.R")        # ~2 min
```

En una sesión sin UTF-8 (p. ej. Linux con locale `C`), arranca R con `LC_ALL=C.UTF-8` para que la base (latin1) y el
diccionario (UTF-8) se lean bien.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance. *Structural Equation
  Modeling, 14*(3), 464–504.
- Chen, F. F., Sousa, K. H., & West, S. G. (2005). Testing measurement invariance of second-order factor models.
  *Structural Equation Modeling, 12*(3), 471–492.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables and measurement
  error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based
  structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1), 115–135.
- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis. *Structural Equation
  Modeling, 6*(1), 1–55.
- Meredith, W. (1993). Measurement invariance, factor analysis and factorial invariance. *Psychometrika, 58*(4), 525–543.
- Vandenberg, R. J., & Lance, C. E. (2000). A review and synthesis of the measurement invariance literature. *Organizational
  Research Methods, 3*(1), 4–70.
