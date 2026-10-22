# Libro SEM · Violencia Veracruz

Encuesta a **1,088 mujeres** (base `BASE_ACLnew.dta`, "ACL" = análisis de clases latentes) con **24 ítems Sí/No sobre violencia** en seis ámbitos:
**infancia, familia, pareja, trabajo, comunidad y escuela**. Además trae 9 variables sociodemográficas y `c`, la **clase latente** (3 clases) que salió de un
análisis de clases latentes en Mplus con esos mismos ítems.

Base de trabajo: `data/BASE_ACLnew.dta` (Stata 13). Como marca el `.gitignore` del repositorio, **no se versiona** (son microdatos de una encuesta
sobre violencia): cópiala manualmente a `Violencia_Veracruz/data/BASE_ACLnew.dta` antes de correr los scripts.

**La única referencia es `Scripts.do`**: recodifica la clase (`c_r`), corre una regresión logística ordinal contra las sociodemográficas y exporta los 24 ítems a
Mplus. **No hay cuestionario, ni documento de validez, ni el código de Mplus, y así se trabaja:** todo lo que se sabe de los ítems sale de sus etiquetas (cortadas a 80
caracteres, se usan tal cual) y de los propios datos, y los scripts siguen los de los otros proyectos (EMOVI, para ítems 0/1, como plantilla). Ver [`00_Diagnostico`](00_Diagnostico/).

## ¿Qué análisis se pueden hacer con esta base?

Se pueden hacer **los 7**, con matices en la invarianza, la validez de criterio y el FIML:

| Análisis | ¿Se puede? | Modelo y muestra | Resultado principal | Carpeta |
|---|---|---|---|---|
| **AFE** | Sí | 24 ítems, 1,088 (WLSMV, parejas disponibles) | 5 factores claros (CFI .988): infancia, **familia y trabajo juntos**, pareja, comunidad y escuela; con 6, trabajo no sale solo y con 7 hay caso Heywood | [`01_AFE`](01_AFE/) |
| **AFC** | Sí | 6 ámbitos, 1,088 (WLSMV) | CFI .987, TLI .985, RMSEA .019, **SRMR .110**; cargas de .47 a .96; mejor que 5 factores (Δχ² p = .007) | [`02_AFC`](02_AFC/) |
| **AFC de 2.º orden** | Sí, y **contrastable** | VIO sobre los 6 ámbitos | Mismo ajuste (ΔCFI = 0, Δχ² p = .051, 9 gl); cargas de .56 a .78 | [`03_AFC_2do_Orden`](03_AFC_2do_Orden/) |
| **Confiabilidad y validez** | Sí, **sin validez de criterio independiente** | 6 ámbitos | CR .78–.94, KR-20 .49–.80, AVE de .60 a .82 salvo comunidad (.49), HTMT máximo .61, ω jerárquico .79 | [`04_Confiabilidad_y_Validez`](04_Confiabilidad_y_Validez/) |
| **Puntajes factoriales** | Sí | 6 ámbitos + VIO, 1,088 | Determinación .90–.98; r = .955 con el conteo de hechos; 35 % sin ningún hecho | [`05_Puntajes_Factoriales`](05_Puntajes_Factoriales/) |
| **Invarianza factorial** | **Parcial**: edad y escolaridad, sin trabajo | 5 ámbitos (20 ítems): 665 contra 421 y 449 contra 618 | Umbrales y cargas invariantes en ambos (ΔCFI = 0; p = .51 y .37) | [`06_Invarianza_Factorial`](06_Invarianza_Factorial/) |
| **FIML** | Sí, y **necesario**, con ítems como continuos | 505 contra 1,088 (MLR) | Ajuste mejor (CFI .903 → .949) y errores estándar ~32 % menores; **los faltantes no son MCAR** | [`07_FIML`](07_FIML/) |

- **Por qué la estructura es tan clara:** los 24 ítems vienen en bloques del cuestionario. Los ítems de un ámbito correlacionan de .43 a .79 entre sí
  y de .22 a .37 con los demás (policóricas), y el AFE los recupera casi sin que se le diga cuáles son.
- **Faltantes:** son **saltos de pregunta** (313 mujeres sin pareja, 249 sin trabajo, 57 sin escuela), no datos perdidos al azar.
- **Eventos raros:** 8 de los 24 ítems los reporta menos del 5 % (`p184`: 16 mujeres). Eso vuelve inestables las tetracóricas y explica el SRMR alto.
- **Invarianza:** con los cuatro ítems de trabajo el modelo de seis ámbitos se vuelve inadmisible en uno de los grupos; se prueba el de cinco. No hay sexo ni región.
- **Validez de criterio:** requiere un criterio externo que no salga de los mismos ítems. `c_r` sale de ellos.

## Glosario de variables

Los ámbitos salen de la redacción de las etiquetas y de las letras de los reactivos (14 a–d, 16 a/b/e, 17 a/b/c/e/f, 18 c–f, 19 a–d, 20 a–d), y los confirman el AFE
y el AFC. Todos los ítems son **0 = No, 1 = Sí**. La redacción es la de las etiquetas del `.dta` **tal cual (cortadas a 80 caracteres)**. **Faltan reactivos de la serie**
(`p163`, `p164`, `p174`, `p181`, `p182`): la base trae una selección del cuestionario.

| Factor | Qué mide | Periodo de referencia (según la etiqueta) | Ítems |
|---|---|---|---|
| `INF` | Violencia en la infancia | "Cuando era niña" | `p141`–`p144` |
| `FAM` | Violencia de familiares, sin considerar a la pareja | "En el último año" | `p161`, `p162`, `p165` |
| `PAR` | Violencia de la pareja | "En el último año" | `p171`–`p173`, `p175`, `p176` |
| `TRA` | Violencia en el trabajo | "Actualmente o alguna vez" | `p183`–`p186` |
| `COM` | Violencia en la comunidad (la calle) | "En el lugar donde usted vive" | `p191`–`p194` |
| `ESC` | Violencia en la escuela | "Cuando asiste o asistió" | `p201`–`p204` |
| `VIO` | **Violencia contra las mujeres** (segundo orden) | Mezcla los periodos anteriores | los 6 factores |

| Variable | Qué mide (etiqueta del .dta, cortada) | Factor | N | % Sí |
|---|---|---|---|---|
| `p141` | a) ¿Cuando era niña, recuerda si entre las personas con las que vivía, había gol | INF | 1,088 | 33.9 |
| `p142` | b) ¿Cuando era niña, recuerda si las personas con las que vivía, la insultaban o | INF | 1,084 | 26.6 |
| `p143` | c) ¿Cuando era niña, recuerda si las personas con las que vivía, le pegaban? | INF | 1,083 | 34.3 |
| `p144` | d) ¿Cuando era niña, recuerda si alguna de las personas con las que vivía, la ob | INF | 1,082 | 4.6 |
| `p161` | a) ¿En el último año algún miembro de la familia, sin considerar a su pareja, la | FAM | 1,083 | 10.9 |
| `p162` | b) ¿En el último año algún miembro de la familia, sin considerar a su pareja, la | FAM | 1,082 | 6.1 |
| `p165` | e) ¿En el último año algún miembro de la familia, sin considerar a su pareja, le | FAM | 1,078 | 2.5 |
| `p171` | a) ¿En el último año su pareja, la ignoró, no la toma en cuenta, la humilló, la | PAR | 774 | 15.9 |
| `p172` | b) ¿En el último año su pareja, la empujó, la pateó, la golpeó, le aventó algún | PAR | 771 | 8.6 |
| `p173` | c) ¿En el último año su pareja, Le ha exigido tener relaciones sexuales sin su c | PAR | 770 | 4.8 |
| `p175` | e) ¿En el último año su pareja, No le ha dado dinero para el gasto del hogar, po | PAR | 774 | 11.4 |
| `p176` | f) ¿En el último año su pareja, La cela, le prohíbe salir a solas, la encierra p | PAR | 772 | 10.1 |
| `p183` | c) ¿Dentro de su trabajo actualmente o alguna vez Le han dicho que usted no vale | TRA | 838 | 3.2 |
| `p184` | d) ¿Dentro de su trabajo actualmente o alguna vez Por embarazarse no le han cont | TRA | 838 | 1.9 |
| `p185` | e) ¿Dentro de su trabajo actualmente o alguna vez Le han acosado u hostigado sex | TRA | 837 | 2.2 |
| `p186` | f) ¿Dentro de su trabajo actualmente o alguna vez Le han pagado menos que a un h | TRA | 836 | 3.5 |
| `p191` | a) ¿En el lugar donde usted vive, cuando camina por la calle,le han dicho palabr | COM | 1,081 | 11.9 |
| `p192` | b) ¿En el lugar donde usted vive, cuando camina por la calle,la han empujado, ce | COM | 1,079 | 5.1 |
| `p193` | c) ¿En el lugar donde usted vive, cuando camina por la calle, la han tocado, man | COM | 1,079 | 8.3 |
| `p194` | d) ¿En el lugar donde usted vive, cuando camina por la calle, ha sido despojada, | COM | 1,075 | 6.3 |
| `p201` | a) ¿Cuando asiste o asistió a la escuela, La insultaban, ofendían, humillaban, l | ESC | 1,026 | 22 |
| `p202` | b) ¿Cuando asiste o asistió a la escuela, La empujaban, le jalaban el cabello, l | ESC | 1,029 | 16.6 |
| `p203` | c) ¿Cuando asiste o asistió a la escuela, La tocaban, manoseaban, le dijeron pir | ESC | 1,029 | 4 |
| `p204` | d) ¿Cuando asiste o asistió a la escuela, Le quitaban su dinero, le escondían, l | ESC | 1,028 | 13.6 |

**Otras variables.** `id` (único, de 3 a 1,355, con 267 huecos en la serie), `c` (clase latente de Mplus: 1 = 152 mujeres, 2 = 256, 3 = 680) y `c_r = 4 − c` (**3 = más violencia**; ver abajo),
`_merge` (3 en 1,088 renglones; el 2 es el `id` 907, sin ítems, que se quita) y las sociodemográficas:

| Variable | Pregunta | Códigos (n entre las 1,088) |
|---|---|---|
| `p1` | ¿Usted se considera indígena? | 0 No (1,060), 1 Sí (28) |
| `p2` | ¿Cuántos años cumplidos tiene? | 1 = 18–24 (119), 2 = 25–34 (254), 3 = 35–44 (292), 4 = 45–54 (235), 5 = 55–64 (186); la categoría 6 (65 o más) no aparece; 2 sin dato |
| `p3` | ¿Sabe leer y escribir? | 0 No (125), 1 Sí (961) |
| `p4` | ¿Cuál es su último grado de estudio completo? | 1 Ninguna (156), 2 Primaria (293), 3 Secundaria (246), 4 Preparatoria (243), 5 Universidad (129), 6 Otro (5); 16 sin dato |
| `p5` | ¿Cuál es su ocupación? | 15 categorías; 2 = ama de casa (532); 8 = trabajadora por su cuenta (106); 13 = comerciante (108) |
| `p7` | ¿Recibe dinero de alguna persona/programa? | 0 No (755), 1 Sí (285); 48 sin dato |
| `p9` | ¿Actualmente usted…? | 1 Soltera (186), 2 Separada (74), 3 Divorciada (29), 4 Viuda (63), 5 Unión libre (238), 6 Casada (495) |
| `p13` | ¿A qué edad tuvo su primer embarazo? | 1 menos de 15 (18), 2 = 15–19 (375), 3 = 20–24 (313), 4 = 25–29 (120), 5 = 30–34 (41), 6 = 35 o más (9); 212 sin dato |
| `p62` | ¿Ha escuchado hablar de los derechos de las mujeres? | 0 No (281), 1 Sí (794) |

**La clase `c_r`** (ver [`00_Diagnostico`](00_Diagnostico/)): 1 = poca violencia (680 mujeres), 2 = violencia sobre todo **en la infancia** (256), 3 = violencia **en varios ámbitos** (152).
No es una escala monótona (los ítems de infancia son más altos en la clase 2 que en la 3) y no es independiente de los ítems.

## Estructura

| Carpeta | Ejercicio | Muestra | Referencia |
|---|---|---|---|
| `00_setup_paquetes.R` | Instala los paquetes | — | — |
| [`00_Diagnostico/`](00_Diagnostico/) | Qué trae la base y qué análisis admite; réplica de `Scripts.do` | 1,088 | `Scripts.do` |
| [`01_AFE/`](01_AFE/) | Análisis factorial exploratorio | 1,088 (parejas disponibles) | *Sin referencia* |
| [`02_AFC/`](02_AFC/) | Análisis factorial confirmatorio (6 ámbitos) | 1,088 (WLSMV) | *Sin referencia* |
| [`03_AFC_2do_Orden/`](03_AFC_2do_Orden/) | AFC de segundo orden (violencia contra las mujeres) | 1,088 (WLSMV) | *Sin referencia* |
| [`04_Confiabilidad_y_Validez/`](04_Confiabilidad_y_Validez/) | KR-20, CR, AVE, HTMT, omega, validez | 1,088 | *Sin referencia* |
| [`05_Puntajes_Factoriales/`](05_Puntajes_Factoriales/) | Puntajes EBM, determinación, comparación con el conteo | 1,088 (WLSMV) | *Sin referencia* |
| [`06_Invarianza_Factorial/`](06_Invarianza_Factorial/) | AFC multigrupo: edad y escolaridad (5 ámbitos) | 665/421 y 449/618 | *Sin referencia* |
| [`07_FIML/`](07_FIML/) | Datos faltantes: listwise contra FIML | 505 contra 1,088 | *Sin referencia* |

Cada carpeta trae su script de R, comentado paso a paso, y un `README.md` con la explicación y los resultados. Las tablas se guardan en su `output/`, que no se versiona.
**Cada script es independiente.**

## Decisiones que se tomaron

Conviene revisarlas:

| Tema | Decisión |
|---|---|
| Muestra | **1,088 mujeres**: se quita el `id` 907 (viene solo del otro archivo del `merge`, sin ningún ítem) |
| Ítems | Los **24**, sin criterio 90-10: en violencia el evento raro es el objeto de estudio. Ocho ítems tienen menos del 5 % de "Sí" |
| Estructura | **Seis ámbitos** del cuestionario, no los cinco del AFE (familia y trabajo juntos): ajustan mejor (Δχ² p = .007) y trabajo correlaciona .60 con familia, no 1 |
| Estimador | Ítems 0/1 como **ordinales (WLSMV)** con `missing = "pairwise"`; rotación **oblimin** en el AFE |
| FIML | Aparte, con los ítems **como continuos** (MLR): `lavaan` no tiene FIML con ordinales |
| Matriz de correlación | KMO, Bartlett y análisis paralelo con **phi** (la tetracórica no es definida positiva) |
| Modelo | No se elimina ningún ítem ni se modifica con los índices de modificación |
| Criterio | `c_r` **no** se usa como criterio independiente (sale de los mismos ítems); las sociodemográficas se reportan como correlatos |
| Puntajes | **EBM**; `NA` en el puntaje de un ámbito si la mujer no contestó ningún ítem de él |
| Invarianza | **Edad** (18–44 contra 45+) y **escolaridad** (hasta primaria contra secundaria o más), con el modelo de **5 ámbitos** (sin trabajo); umbrales y cargas juntos |
| Diseño muestral | **Sin ponderador** (la base no trae ponderador, UPM ni estrato) |

## Lo que conviene tener presente

- **El AFC confirma con los mismos datos del AFE.** Con ítems tan raros no se partió la muestra: la estructura no es una prueba independiente.
- **SRMR alto (.110).** Los demás índices son muy buenos, pero el SRMR queda arriba de .08 incluso sin las 65 parejas de ítems casi vacías (.092).
- **Trabajo y comunidad son los ámbitos débiles:** `p184`, `p185`, `p183` y `p186` tienen entre 16 y 29 mujeres con "Sí" y errores estándar grandes; `p193` y `p194` cargan .47
  (la AVE de comunidad es .487, y el KR-20, .49).
- **Los faltantes son saltos de pregunta, no se pueden "imputar".** Quien no tiene pareja no tiene violencia de pareja que reportar: sus puntajes en `PAR`, `TRA` y `ESC` son `NA` y no cero. Y
  los faltantes de trabajo **no son MCAR** (quien nunca trabajó reporta más violencia).
- **Los ámbitos tienen periodos de referencia distintos** (infancia, último año, "alguna vez"): el factor general `VIO` mezcla cosas que no son comparables en el tiempo.
- **Segundo orden en el límite:** Δχ² p = .051; el criterio de Chen sí se cumple con holgura.
- **Invarianza sin trabajo y sin sexo:** solo para 20 ítems y los dos cortes disponibles; las medias latentes no se comparan (no están bien identificadas).
- **Lo que no se hizo:** reproducir el **análisis de clases latentes** de Mplus (no está su código) ni compararlo con los modelos factoriales; ni el `ologit` ajustado por todas las covariables a la vez.

## Limitaciones que se aceptan

No hay más documentos ni más bases que `BASE_ACLnew.dta` y `Scripts.do`, y el proyecto sigue con lo que hay:

- **Etiquetas cortadas a 80 caracteres.** Se usan tal cual. La redacción de `p144` ("la ob…"), `p161`, `p162` y `p165` queda incompleta, y no se sabe por qué faltan los reactivos
  `p163`, `p164`, `p174`, `p181` y `p182`. Los ámbitos se infieren de las etiquetas y de las letras de los reactivos, y los confirma el AFE.
- **Sin el código de Mplus.** `c` se toma como viene (3 clases): no se sabe si el análisis de clases latentes usó los 24 ítems ni cómo se eligieron las clases. No se reproduce.
- **Sin criterio externo.** La validez de criterio se deja así: `c_r` (no independiente) y las sociodemográficas como correlatos, sin pretender más.
- **Sin sexo, región, municipio ni diseño muestral:** la invarianza es por edad y escolaridad, y todo va sin ponderar.
- **Sin explicación del `merge`:** el `id` 907 (sin ítems) se quita y los 267 huecos en la serie de `id` se aceptan. La categoría "65 o más" de `p2` no aparece.

## Cómo correrlo en VSCode

Abre la **raíz del repositorio** (`Libro-SEM`), copia la base a `Violencia_Veracruz/data/` y en una terminal de R corre (los tiempos son aproximados):

```r
source("Violencia_Veracruz/00_setup_paquetes.R")
source("Violencia_Veracruz/00_Diagnostico/Diagnostico.R")                          # ~10 s
source("Violencia_Veracruz/01_AFE/AFE.R")                                          # ~30 s
source("Violencia_Veracruz/02_AFC/AFC.R")                                          # ~6 s
source("Violencia_Veracruz/03_AFC_2do_Orden/AFC_2do_Orden.R")                      # ~5 s
source("Violencia_Veracruz/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")  # ~45 s
source("Violencia_Veracruz/05_Puntajes_Factoriales/Puntajes_Factoriales.R")        # ~45 s
source("Violencia_Veracruz/06_Invarianza_Factorial/Invarianza_Factorial.R")        # ~70 s
source("Violencia_Veracruz/07_FIML/FIML.R")                                        # ~30 s
```

También puedes abrir cada script y correrlo sección por sección con `Ctrl+Enter`. Cada script es independiente.

## Referencias

- Chen, F. F. (2007). Sensitivity of goodness of fit indexes to lack of measurement invariance. *Structural Equation Modeling, 14*(3), 464–504.
- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables and measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity in variance-based structural equation modeling. *Journal of the Academy of
  Marketing Science, 43*(1), 115–135.
- Horn, J. L. (1965). A rationale and test for the number of factors in factor analysis. *Psychometrika, 30*(2), 179–185.
- Hu, L., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis. *Structural Equation Modeling, 6*(1), 1–55.
- Little, R. J. A. (1988). A test of missing completely at random for multivariate data with missing values. *Journal of the American Statistical Association, 83*(404), 1198–1202
  (se explica por qué no se usa con ítems 0/1).
- Millsap, R. E., & Tein, J.-Y. (2004). Assessing factorial invariance in ordered-categorical measures. *Multivariate Behavioral Research, 39*(3), 479–515.
- Satorra, A. (2000). Scaled and adjusted restricted tests in multi-sample analysis of moment structures. En R. D. H. Heijmans, D. S. G. Pollock y A. Satorra (Eds.), *Innovations in
  multivariate statistical analysis* (pp. 233–247). Kluwer.
