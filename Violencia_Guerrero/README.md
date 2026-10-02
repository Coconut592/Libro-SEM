# Libro SEM · Violencia Guerrero

Encuesta a **294 personas** de Guerrero (base `cap4_GRO.dta`, "capítulo 4") con **46 ítems en escala de 1 a 10**:
satisfacción con la vida por dominios, cohesión vecinal, confianza en las autoridades, percepción de
inseguridad y de riesgo de ser víctima, libertad de opinión política y evaluación del desempeño del gobierno.

Base de trabajo: `data/cap4_GRO.dta` (Stata 13). Como marca el `.gitignore` del repositorio, **no se
versiona** (son microdatos de una encuesta sobre violencia): cópiala manualmente a
`Violencia_Guerrero/data/cap4_GRO.dta` antes de correr los scripts.

**No hay código, presentaciones, PDFs ni diccionario de este tema.** Todo lo que se sabe de las variables sale
de sus etiquetas y de los propios datos, y se usó la estructura del proyecto del Tren como plantilla. La base no
trae etiquetas de valor (no se sabe qué significan el 1 ni el 10) ni variables de grupo (sexo, edad, municipio).

## ¿Qué análisis se pueden hacer con esta base?

Se pueden hacer **todos**. Con matices en la invarianza y en la validez de criterio:

| Análisis | ¿Se puede? | Modelo y muestra | Resultado principal | Carpeta |
|---|---|---|---|---|
| **AFE** | Sí | 46 ítems, 294 (matriz FIML) | Recupera **12 factores** = los 12 bloques de contenido; ningún ítem con carga cruzada ≥ .30; RMSEA .052 | [`01_AFE`](01_AFE/) |
| **AFC** | Sí | 12 factores, 294 (MLR + FIML) | CFI .950, TLI .944, RMSEA .040, SRMR .043; cargas de .64 a .94 | [`02_AFC`](02_AFC/) |
| **AFC de 2.º orden** | Sí, y **contrastable** | G = Satisfacción con la vida sobre 6 dominios | ΔCFI = −.007 (aceptable) pero Δχ² p < .001; pareja y familia cargan poco en G | [`03_AFC_2do_Orden`](03_AFC_2do_Orden/) |
| **Confiabilidad y validez** | Sí, **salvo validez de criterio** | 12 factores | α y Ω de .78 a .93; AVE ≥ .54; HTMT máximo .65 | [`04_Confiabilidad_y_Validez`](04_Confiabilidad_y_Validez/) |
| **Puntajes factoriales** | Sí | 12 factores + G, 294 | Determinación ≥ .91 | [`05_Puntajes_Factoriales`](05_Puntajes_Factoriales/) |
| **Invarianza factorial** | **Parcial**: solo con/sin pareja | 2 modelos (20 y 12 ítems), 223 contra 71 | Institucional: estricta; satisfacción: escalar | [`06_Invarianza_Factorial`](06_Invarianza_Factorial/) |
| **FIML** | Sí, y **necesario** | 294 contra 160 completos | MCAR se rechaza (p < .001); FIML: mejor ajuste y errores estándar 15% menores | [`07_FIML`](07_FIML/) |

- **Por qué la estructura es tan clara:** la base parece una selección de ítems de una encuesta más grande (los
  números saltan: `b5`–`b8`, `c9`–`c10`...). Los 12 bloques tienen correlaciones medias de .53 a .76 dentro y de −.03 a .22
  con los demás ítems, y el AFE los recupera sin que se le diga cuáles son.
- **Invarianza:** la base no trae ninguna variable de grupo. La única agrupación que se puede construir es
  **con/sin pareja** (quien no contesta `a1`–`a4`), y el grupo pequeño tiene solo 71 personas: con ellas el modelo
  de los 6 factores de violencia y clima da una solución inadmisible, así que se prueban dos modelos más
  pequeños. Si se consigue una variable de grupo sustantiva (sexo, municipio...), basta con cambiar una línea
  del script.
- **Validez de criterio:** requiere un criterio externo que mida lo mismo. El `.dta` solo trae los ítems de los
  instrumentos.

## Glosario de variables

Los nombres de los factores y su composición salen de la redacción de las etiquetas (el `.dta` no trae ficha
técnica) y los confirma el AFE. Todos los ítems usan una escala de **1 a 10**; se asume que mayor = más
(satisfacción, acuerdo, miedo, probabilidad o buena evaluación). La redacción es la de las etiquetas del `.dta`
tal cual (con sus erratas: "económico", "trabajado").

| Factor | Qué mide | Ítems |
|---|---|---|
| `pareja` | Satisfacción con la pareja | `a1`–`a4` |
| `familia` | Satisfacción con la familia | `a5`–`a8` |
| `economia` | Satisfacción con la economía familiar | `a9`–`a12` |
| `social` | Satisfacción con la vida social | `a13`–`a16` |
| `personal` | Satisfacción con el bienestar personal (obligaciones, planes de vida, salud) | `a17`–`a20` |
| `trabajo` | Satisfacción con el trabajo | `a21`–`a24` |
| `cohesion` | Cohesión social vecinal | `b1`–`b4`, `b9` |
| `confianza` | Confianza en las autoridades | `b10`–`b13` |
| `inseguridad` | Inseguridad percibida en la comunidad | `c4`–`c8` |
| `riesgo` | Riesgo percibido de ser víctima | `c11`–`c13` |
| `libertad` | Libertad para opinar de política | `c19`, `c20` |
| `desempeno` | Evaluación del trabajo del gobierno contra la violencia y por la justicia | `f2`–`f4` |

| Variable | Qué mide (etiqueta del .dta) | Factor | N | Media | D.E. |
|---|---|---|---|---|---|
| `a1` | El afecto que se tienen | pareja | 223 | 8.52 | 1.95 |
| `a2` | La comunicación entre pareja | pareja | 222 | 8.60 | 1.94 |
| `a3` | Las actividades que hacen juntos | pareja | 220 | 8.24 | 2.20 |
| `a4` | La satisfacción general con la pareja | pareja | 220 | 8.65 | 1.91 |
| `a5` | El afecto y comprensión en su familia | familia | 284 | 8.68 | 1.73 |
| `a6` | Las actividades que hacen en familia | familia | 282 | 8.16 | 2.11 |
| `a7` | Resolución de conflictos en familia | familia | 282 | 8.21 | 2.11 |
| `a8` | La satisfacción general con la familia | familia | 283 | 8.78 | 1.59 |
| `a9` | Llevar la vida deseada | economia | 293 | 7.15 | 2.11 |
| `a10` | Cubrir sus necesidades | economia | 293 | 7.23 | 2.11 |
| `a11` | Completar el gasto de la casa | economia | 292 | 7.32 | 2.20 |
| `a12` | Su situación económico en general | economia | 292 | 7.01 | 2.20 |
| `a13` | La frecuencia con qué sale y se divierte | social | 293 | 6.43 | 2.72 |
| `a14` | La diversidad de actividades sociales | social | 292 | 6.01 | 2.88 |
| `a15` | El tipo de personas en su medio social | social | 292 | 7.16 | 2.42 |
| `a16` | Su vida social en general | social | 293 | 7.40 | 2.31 |
| `a17` | Cuidar y cumplir sus obligaciones | personal | 294 | 8.48 | 1.70 |
| `a18` | Mantener sus planes de vida | personal | 294 | 8.14 | 2.02 |
| `a19` | Vivir y sentirse bien | personal | 294 | 8.35 | 2.00 |
| `a20` | Estado de salud en general | personal | 294 | 8.19 | 1.83 |
| `a21` | El respeto social que da su trabajo | trabajo | 289 | 8.14 | 1.84 |
| `a22` | El tipo de tareas y responsabilidades | trabajo | 288 | 8.35 | 1.65 |
| `a23` | oportunidades para ser creativo | trabajo | 283 | 7.99 | 1.98 |
| `a24` | Situación económico en general | trabajo | 288 | 8.52 | 1.68 |
| `b1` | Vecinos están dispuestos a ayudarse | cohesion | 286 | 6.29 | 2.51 |
| `b2` | Vecinos se llevan bien en general | cohesion | 287 | 6.60 | 2.46 |
| `b3` | Se puede confiar en los vecinos | cohesion | 291 | 5.98 | 2.72 |
| `b4` | Vecinos comparten los mismos valores que Ud. | cohesion | 283 | 5.49 | 2.49 |
| `b9` | La relación entre vecinos es buena | cohesion | 288 | 6.38 | 2.59 |
| `b10` | Estoy representado por autoridades locales | confianza | 293 | 3.91 | 2.56 |
| `b11` | Confío en el trabajo de los alcaldes | confianza | 292 | 3.51 | 2.60 |
| `b12` | Confío en el municipio para impartir justicia | confianza | 292 | 3.13 | 2.39 |
| `b13` | Confío en el Gobierno estatal | confianza | 293 | 3.48 | 2.62 |
| `c4` | Miedo a ser molestado | inseguridad | 288 | 7.98 | 2.53 |
| `c5` | Robos en calles y casas | inseguridad | 288 | 6.70 | 3.12 |
| `c6` | Consumo o venta de droga | inseguridad | 256 | 6.68 | 3.30 |
| `c7` | Miedo a asaltos | inseguridad | 290 | 7.83 | 2.76 |
| `c8` | Agresiones frecuentes a mujeres | inseguridad | 271 | 5.77 | 3.12 |
| `c11` | Detenido por grupos armados en 12 meses | riesgo | 283 | 5.68 | 3.05 |
| `c12` | Ataque violento - futuro | riesgo | 287 | 6.32 | 3.04 |
| `c13` | Víctima de ataque sexual - futuro | riesgo | 278 | 4.63 | 3.19 |
| `c19` | Libertad: opiniones políticas con amistades | libertad | 291 | 7.09 | 2.72 |
| `c20` | Libertad: opiniones políticas en público | libertad | 285 | 5.74 | 2.93 |
| `f2` | Buen trabajado para disminuir la violencia | desempeno | 291 | 2.96 | 2.26 |
| `f3` | Buen trabajado para disminuir violencia de género | desempeno | 287 | 3.45 | 2.49 |
| `f4` | Buen trabajado para procurar justicia | desempeno | 289 | 3.01 | 2.23 |

`folio` es el folio de la encuesta (1–325, **no único**: 3 se repiten; ver
[`00_Exploracion`](00_Exploracion/)). Los ítems de pareja (`a1`–`a4`) los dejan en blanco 71 personas (casi
seguro no tienen pareja); casi todos los demás faltantes son esporádicos.

## Estructura

| Carpeta | Ejercicio | Muestra | Referencia |
|---|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | — | — |
| [`00_Exploracion/`](00_Exploracion/) | Qué trae la base y qué análisis admite | 294 | *Sin referencia* |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 294 (FIML) | *Sin referencia* |
| [`02_AFC/`](02_AFC/) | Análisis factorial confirmatorio (12 factores) | 294 (FIML) | *Sin referencia* |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden (satisfacción con la vida) | 294 (FIML) | *Sin referencia* |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | Alfa, confiabilidad compuesta, AVE, HTMT, validez | 294 | *Sin referencia* |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes centrados, en escala original y por media ponderada | 294 (FIML) | *Sin referencia* |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo: con pareja contra sin pareja | 223 y 71 (FIML) | *Sin referencia* |
| [`07_FIML/`](07_FIML/) | Datos faltantes: listwise contra FIML, prueba MCAR de Little (y su validación) | 294 | *Sin referencia* |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los resultados.
Las tablas y gráficas se guardan en su `output/`, que no se versiona. **Cada script es independiente.**

## Decisiones que se tomaron sin documentación

Como no hay referencia, estas decisiones son del análisis y conviene revisarlas:

1. **Los 12 bloques** se infieren de las etiquetas. El AFE (que no los conoce) los recupera uno a uno.
2. **FIML con las 294 personas** en todo el proyecto, en lugar de partir de los 160 casos completos como en
   el Tren (ver [`07_FIML`](07_FIML/)).
3. **Ítems continuos con MLR.** Son escalas de 10 puntos con efecto techo y suelo. Se verifica con un
   tratamiento ordinal (WLSMV): misma estructura y cargas .02–.03 mayores ([`02_AFC`](02_AFC/)).
4. **Rotación oblicua (oblimin)** en el AFE, no varimax: los factores correlacionan hasta .49.
5. **No se elimina ningún ítem ni se modifica el modelo** con los índices de modificación. Lo más notable es
   que `social` se parte en dos pares de ítems (`a13`–`a14` y `a15`–`a16`).
6. **Se conservan los 294 renglones**, aunque el folio 292 aparece dos veces con 39 de 41 respuestas
   idénticas (casi seguro una doble captura): quitar uno cambia las cargas menos de .005.
7. **Marcadores de los puntajes:** el ítem de mayor carga de cada factor. Quien no contestó ningún ítem de
   un factor queda con `NA` en su puntaje.
8. **Invarianza con/sin pareja**, la única agrupación disponible (ver arriba).

## Qué conviene confirmar con la fuente

- Qué significan el **1 y el 10** de cada escala (la base no trae etiquetas de valor).
- Qué codifica el **folio**: 12 de 46 ítems se relacionan con él y no es único. Si fuera municipio o localidad,
  serviría como variable de grupo para la invarianza.
- **`c11`** ("Detenido por grupos armados en 12 meses"): ¿experiencia o expectativa? Es el ítem más débil de su
  factor. Y **`a24`** ("Situación económica en general"), que está en el bloque de trabajo.
- Si existe una **variable de grupo** (sexo, edad, municipio) o más variables del cuestionario original.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `Violencia_Guerrero/data/` y en una terminal de
R corre (los tiempos son aproximados):

```r
source("Violencia_Guerrero/00_setup_paquetes.R")
source("Violencia_Guerrero/00_Exploracion/Exploracion.R")                        # ~15 s
source("Violencia_Guerrero/01_AFE/AFE.R")                                        # ~5 s
source("Violencia_Guerrero/02_AFC/AFC.R")                                        # ~5 min
source("Violencia_Guerrero/03_AFC_2do_Orden/AFC_2do_Orden.R")                    # ~30 s
source("Violencia_Guerrero/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~1 min
source("Violencia_Guerrero/05_Puntajes_Factoriales/Puntajes_Factoriales.R")      # ~2 min
source("Violencia_Guerrero/06_Invarianza_Factorial/Invarianza_Factorial.R")      # ~1 min
source("Violencia_Guerrero/07_FIML/FIML.R")                                      # ~4 min
source("Violencia_Guerrero/07_FIML/Validacion_Little.R")                         # opcional, ~1 min
```

También puedes abrir cada script y correrlo sección por sección con `Ctrl+Enter`. Cada script es
independiente. Los modelos de 12 factores con FIML tardan: calcular sus medidas de ajuste robustas lleva más de
2 minutos cada vez (los scripts las calculan una sola vez).

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance.
  *Structural Equation Modeling, 14*(3), 464–504.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables and
  measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in
  variance-based structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1), 115–135.
- Horn, J. L. (1965). A rationale and test for the number of factors in factor analysis. *Psychometrika, 30*(2),
  179–185.
- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis.
  *Structural Equation Modeling, 6*(1), 1–55.
- Little, R. J. A. (1988). A test of missing completely at random for multivariate data with missing values.
  *Journal of the American Statistical Association, 83*(404), 1198–1202.
- Meredith, W. (1993). Measurement invariance, factor analysis and factorial invariance. *Psychometrika, 58*(4),
  525–543.
- Nunnally, J. C., & Bernstein, I. H. (1994). *Psychometric theory*. McGraw Hill.
- Vandenberg, R. J., & Lance, C. E. (2000). A review and synthesis of the measurement invariance literature.
  *Organizational Research Methods, 3*(1), 4–70.
