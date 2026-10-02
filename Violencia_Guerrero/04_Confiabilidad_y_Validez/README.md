# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R`. **Sin referencia propia:** se sigue el esquema del módulo del Tren
(SEM06): alfa de Cronbach a mano y por ítem, alfa con la covarianza del modelo, confiabilidad compuesta de
Dillon-Goldstein, KR-20 y los tres tipos de validez (contenido, criterio y constructo).

> **Complementos que en el Tren no se usaron** (se agregan aquí porque la base tiene 12 factores): la
> razón **HTMT** (validez discriminante), la revisión de **validez nomológica** y la confiabilidad del
> factor de segundo orden **G**. Igual que en el Tren, la AVE y Fornell-Larcker son apoyo cuantitativo a
> la validez de constructo.

**Datos:** el alfa usa las 294 personas con covarianzas por pares (como el `alpha` de Stata). La
confiabilidad compuesta y la validez usan el AFC de 12 factores de [`02_AFC`](../02_AFC/) (MLR + FIML,
294 personas).

## Confiabilidad: paso a paso

1. **Alfa a mano** (SEM06). Con la matriz de covarianzas de cada factor:
   α = k/(k−1) · (1 − Σ varianzas / Σ de todos los elementos).

   | Factor | k | Σ varianzas | Σ covarianzas | α |
   |---|---|---|---|---|
   | pareja | 4 | 16.06 | 31.67 | **.885** |
   | familia | 4 | 14.39 | 28.07 | **.881** |
   | economia | 4 | 18.52 | 42.09 | **.926** |
   | social | 4 | 26.90 | 51.81 | **.878** |
   | personal | 4 | 14.29 | 29.55 | **.899** |
   | trabajo | 4 | 12.83 | 23.55 | **.863** |
   | cohesion | 5 | 32.66 | 87.38 | **.910** |
   | confianza | 4 | 25.87 | 57.80 | **.921** |
   | inseguridad | 5 | 44.39 | 93.72 | **.848** |
   | riesgo | 3 | 28.76 | 32.86 | **.800** |
   | libertad | 2 | 15.97 | 10.19 | **.779** |
   | desempeno | 3 | 16.27 | 24.18 | **.897** |

   Los 12 son mayores que .70 (Nunnally y Bernstein, 1994). Los más bajos son los de los factores con
   menos ítems: libertad (2, equivale a Spearman-Brown) y riesgo (3).
2. **Alfa por ítem** (equivale a `alpha ..., d item` de Stata; `output/alfa_por_item.csv`, 46 renglones).
   Las correlaciones ítem-resto van de **.57** (`c11`) a **.87** (`b12`). Las más bajas: `c11` (.57),
   `c8` (.58), `c13` (.62), `c4` (.62), `a1` (.65) y `a23` (.69). Quitar cualquier ítem baja el alfa,
   **salvo `a1` y `c11`**: sin ellos el alfa sube apenas .003 (.888 contra .885 y .803 contra .800), así
   que ninguno resta consistencia de forma relevante. En libertad (2 ítems) el "alfa sin el ítem" no
   aplica.
3. **Alfa con la covarianza del modelo** (`fitted(fit)$cov`): .885, .885, .926, .876, .899, .874 (los
   seis dominios de satisfacción) y .910, .924, .850, .799, .778, .896 (cohesión, confianza, inseguridad,
   riesgo, libertad y desempeño). Casi idénticos a los del paso 1.
4. **Confiabilidad compuesta de Dillon-Goldstein.** Ω = (Σλ)² / [(Σλ)² + Σ var(e)], con var(e) = 1 − λ².
   Las 46 cargas y sus residuales están en `output/confiabilidad_compuesta.csv`.

   | Factor | Cargas (λ) | Ω |
   |---|---|---|
   | pareja | .69 – .91 | **.890** |
   | familia | .76 – .91 | **.894** |
   | economia | .81 – .91 | **.927** |
   | social | .79 – .82 | **.880** |
   | personal | .75 – .89 | **.902** |
   | trabajo | .76 – .84 | **.878** |
   | cohesion | .78 – .85 | **.911** |
   | confianza | .81 – .92 | **.927** |
   | inseguridad | .64 – .79 | **.855** |
   | riesgo | .64 – .94 | **.812** |
   | libertad | .73 – .88 | **.787** |
   | desempeno | .84 – .89 | **.898** |

   *Verificación:* `semTools::compRelSEM()` calcula Ω con las cargas sin estandarizar y difiere como
   máximo **.006** de estos valores.
5. **KR-20: no aplica.** Es para ítems dicotómicos (0/1) y aquí son escalas de 1 a 10 (8 a 10 valores
   distintos). La medida adecuada es el alfa.

## Validez: paso a paso (tipos de SEM06)

6. **De contenido: se argumenta, no se calcula.** Cada ítem debe pertenecer al dominio de su factor (ver
   el glosario del [README del proyecto](../README.md)). Los 12 dominios tienen sentido por su
   redacción, y el AFE ubicó a cada ítem en el factor de su bloque. Dos puntos a confirmar con quien
   tenga el cuestionario original (no se tiene, solo las etiquetas):
   - **`c11`** ("Detenido por grupos armados en 12 meses") no dice si es experiencia pasada o
     expectativa, a diferencia de `c12` y `c13` ("... - futuro"). Es el ítem más débil de `riesgo`
     (λ = .64, comunalidad .44, ítem-resto .57), lo que sería coherente con un significado distinto.
   - **`a24`** ("Situación económica en general") está en el bloque de trabajo y no en el de economía. El
     AFE la ubica en trabajo (carga .59, segunda carga .16), así que debe referirse a la situación
     económica del trabajo.
7. **De criterio: no es posible con esta base.** Requiere un criterio externo que mida lo mismo (otro
   instrumento, un indicador objetivo como denuncias o delitos en la localidad...). El `.dta` solo trae
   los ítems de los instrumentos.
8. **De constructo** (A. teoría, B. correlaciones, C. interpretación empírica):
   - **A. Teoría:** seis dominios de satisfacción con la vida y seis percepciones sobre vecinos,
     autoridades, seguridad y gobierno.
   - **B. Correlaciones:** los ítems de un mismo factor correlacionan mucho más entre sí que con los de
     otros factores (r media dentro de .53 a .76; fuera, de −.03 a .22; ver
     [`00_Exploracion`](../00_Exploracion/)).
   - **C. Interpretación empírica:** el AFE recupera los 12 factores sin cargas cruzadas y el AFC
     confirma cargas de .64 a .94, todas significativas.
9. **Convergente: AVE** (promedio de λ², debe ser ≥ .50). Las 12 la cumplen; la más baja es
   inseguridad (**.542**) y la más alta economía y confianza (**.760**).
10. **Discriminante.**
    - **Fornell-Larcker:** √AVE debe ser mayor que la correlación con los demás factores. **Se cumple
      en los 12.** La correlación más alta entre factores es personal–trabajo (.650), contra una √AVE de
      .835 y .801.
    - **HTMT** (Henseler, Ringle y Sarstedt, 2015; se espera < .85): el máximo es **.652**
      (personal–trabajo), seguido de economía–social (.593), social–personal (.580), economía–personal
      (.573) e inseguridad–riesgo (.571). Muy por debajo del criterio.

    *Verificación:* `semTools::htmt(..., htmt2 = FALSE)` da exactamente los mismos HTMT (diferencia 0).
    Ojo: por defecto `semTools` calcula HTMT2 (medias geométricas), que da valores distintos.
11. **Nomológica** (`output/validez_nomologica.csv`). Se revisa si 25 correlaciones entre factores tienen
    el signo esperado por el contenido: 19 positivas (los 15 pares de dominios de satisfacción; cohesión
    con confianza y con vida social; confianza con desempeño; inseguridad con riesgo) y 6 negativas
    (inseguridad y riesgo con confianza, desempeño y cohesión). **Se cumplen las 25.** Las más débiles son
    riesgo–cohesión (−.09), riesgo–confianza (−.16) y pareja–social (.17).

    > Estas expectativas salen del contenido de los factores y se formularon con la base ya explorada: es
    > una revisión de consistencia, **no una prueba independiente**.
12. **Factor de segundo orden G** (misma fórmula de Ω con las 6 cargas de G, ver
    [`03_AFC_2do_Orden`](../03_AFC_2do_Orden/)): **Ω(G) = .817** y **AVE(G) = .441**. G es confiable,
    pero su AVE queda por debajo de .50 porque pareja y familia cargan poco en G (.39 y .45).
    *Verificación:* `semTools::reliabilityL2()` da ωL2 = .821, y la misma fórmula con las cargas sin
    estandarizar da exactamente .821.

## Resumen

| Factor | k | α | α modelo | Ω (CC) | AVE | √AVE | Máx. correlación | Máx. HTMT |
|---|---|---|---|---|---|---|---|---|
| pareja | 4 | .885 | .885 | .890 | .672 | .820 | .399 | .437 |
| familia | 4 | .881 | .885 | .894 | .679 | .824 | .399 | .437 |
| economia | 4 | .926 | .926 | .927 | .760 | .872 | .593 | .593 |
| social | 4 | .878 | .876 | .880 | .646 | .804 | .593 | .593 |
| personal | 4 | .899 | .899 | .902 | .697 | .835 | .650 | .652 |
| trabajo | 4 | .863 | .874 | .878 | .642 | .801 | .650 | .652 |
| cohesion | 5 | .910 | .910 | .911 | .671 | .819 | .389 | .402 |
| confianza | 4 | .921 | .924 | .927 | .760 | .872 | .519 | .520 |
| inseguridad | 5 | .848 | .850 | .855 | .542 | .736 | .523 | .571 |
| riesgo | 3 | .800 | .799 | .812 | .597 | .772 | .523 | .571 |
| libertad | 2 | .779 | .778 | .787 | .651 | .807 | .384 | .393 |
| desempeno | 3 | .897 | .896 | .898 | .746 | .864 | .519 | .520 |

- Las 12 escalas son **confiables**: α y Ω van de .78 a .93. La más baja es libertad (2 ítems, α = .779,
  Ω = .787); las demás tienen α y Ω de .80 o más.
- La **validez de constructo** se sostiene: correlaciones dentro de cada factor mayores que entre factores,
  AVE ≥ .50, √AVE mayor que las correlaciones, HTMT máximo de .65 y 25 de 25 signos esperados.
- La **validez de contenido** se argumenta con las etiquetas; quedan dos ítems por confirmar (`c11` y
  `a24`).
- La **validez de criterio** no se puede evaluar con este `.dta`.

> **Alcance.** En cada bloque todos los ítems van en el mismo sentido (no hay ítems invertidos). Un estilo
> de respuesta, por ejemplo contestar siempre alto o siempre el mismo punto, puede inflar las
> correlaciones dentro del bloque y con ellas el alfa y Ω; con esta base no se puede separar. En sentido
> contrario, tratar las escalas como continuas subestima un poco las cargas (con el tratamiento ordinal
> suben .02 a .03 en promedio, ver [`02_AFC`](../02_AFC/)).

Salidas en `output/`: `alfa_por_item.csv`, `confiabilidad_compuesta.csv`, `confiabilidad_validez.csv`,
`fornell_larcker.csv`, `htmt.csv` y `validez_nomologica.csv`.

## Referencias

- Fornell, C., & Larcker, D. F. (1981). Evaluating structural equation models with unobservable variables
  and measurement error. *Journal of Marketing Research, 18*(1), 39–50.
- Henseler, J., Ringle, C. M., & Sarstedt, M. (2015). A new criterion for assessing discriminant validity
  in variance-based structural equation modeling. *Journal of the Academy of Marketing Science, 43*(1),
  115–135.
- Nunnally, J. C., & Bernstein, I. H. (1994). *Psychometric theory*. McGraw Hill.
