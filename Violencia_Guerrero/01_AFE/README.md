# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R`. **Sin referencias propias:** sigue la secuencia del AFE del proyecto del Tren (KMO y
Bartlett → eigenvalores → análisis paralelo → AFE por máxima verosimilitud).

**Objetivo:** descubrir con los datos cuántos factores hay en los **46 ítems** y qué ítems forman cada
uno, **sin suponer** los 12 bloques de contenido de [`00_Exploracion`](../00_Exploracion/). Si el AFE
los recupera solos, la estructura está en los datos y no solo en mi lectura de las etiquetas.

## Dos cambios respecto al Tren

1. **Muestra.** En el Tren se usaron solo los registros completos. Aquí serían **160 de 294** (54%), así
   que la matriz de correlaciones se estima con **FIML** (`lavCor(missing = "fiml")`) y el AFE usa a las
   **294** personas. Esa matriz casi no difiere de la de pares (diferencia media .009; la mayor, .09,
   involucra a los ítems de pareja).
2. **Rotación.** El Tren usó varimax (ortogonal) porque lo pedía la referencia. Aquí se usa **oblimin**
   (oblicua): los factores correlacionan hasta .49 y una rotación ortogonal forzaría esas correlaciones
   a cero y distorsionaría las cargas.

## Paso a paso

1. **Datos.** 294 personas × 46 ítems (escalas de 1 a 10).
2. **¿Tiene sentido factorizar?** `KMO()` da **KMO = 0.86** (buena adecuación). Los MSA individuales
   más bajos son `c20` (.69), `c13` (.72), `c11` (.73), `c12` (.73) y `c19` (.74): solo `c20` queda por
   debajo de .70. `cortest.bartlett()`: χ² = 9,592, gl = 1,035, p < .001.
3. **Componentes principales.** Los eigenvalores son 10.63, 5.13, 3.37, 3.13, 2.60, 1.95, 1.86, 1.49,
   1.44, 1.36, 1.21, 1.17 y luego 0.73. **Doce son mayores que 1** (criterio de Kaiser) y juntos
   explican el 77% de la varianza.
4. **Análisis paralelo** (`fa.parallel()`, 100 réplicas, percentil 95; `output/grafica_codo.png`):

   | | Eigenvalor 11 | 12 | 13 | Retiene |
   |---|---|---|---|---|
   | **Factores comunes** observado / simulado | .43 / .38 | .36 / .35 | .03 / .31 | **12** |
   | **Componentes** observado / simulado | 1.21 / 1.36 | 1.17 / 1.33 | 0.73 / 1.29 | 8 |

   - El de **factores comunes** es el que corresponde a un AFE: pide **12**. El 13.º queda muy por
     debajo del azar; el 12.º apenas lo supera (.36 contra .35).
   - El de **componentes** pide 8, pero no es estable: el 8.º eigenvalor supera al umbral por .002
     (1.486 contra 1.484) y el 9.º se queda .008 por debajo (1.435 contra 1.443); con otras simulaciones
     sale entre 7 y 9. Mezcla varianza común y única, y los bloques de 2 y 3 ítems (libertad, riesgo,
     desempeño) quedan cerca del azar.
   - `fa.parallel` simula en varios núcleos y entonces ignora `set.seed()`: el script fija
     `options(mc.cores = 1)` para que el resultado se repita.
5. **¿Cuántos factores?** Se compara el AFE (ML, oblimin) de 8 a 13 factores:

   | Factores | RMSEA [IC 90%] | TLI | SRMR | BIC | Comunalidad mín. | Ítems con h² < .30 | Factores vacíos |
   |---|---|---|---|---|---|---|---|
   | 10 | .065 [.061, .070] | .845 | .033 | −2132 | .13 | 4 | 0 |
   | 11 | .058 [.053, .063] | .877 | .027 | **−2158** | .13 | 2 | 0 |
   | **12** | **.052 [.047, .057]** | **.901** | **.019** | −2138 | **.44** | **0** | 0 |
   | 13 | .046 [.041, .052] | .921 | .018 | −2087 | .44 | 0 | 1 |

   El RMSEA y el TLI mejoran con cada factor y el BIC es mínimo con 11, pero **con 11 los ítems de
   libertad (`c19`, `c20`) no forman factor** (comunalidades bajas). Con **12** aparece el factor de
   libertad y todos los ítems quedan explicados. Con 13 el factor adicional está **vacío**: ningún ítem
   carga en él ≥ .30 (el máximo es .26). Con Kaiser (12) y el análisis paralelo de factores (12), se
   elige **12**.
6. **AFE final:** `fa(fm = "ml", nfactors = 12, rotate = "oblimin")`. χ² = 982.0 (549 gl), **RMSEA =
   .052 [.047, .057], TLI = .901, SRMR = .019**.
7. **Interpretación.** Los 12 factores coinciden **uno a uno** con los 12 bloques de contenido. Cargas
   del patrón (`output/cargas_AFE.csv`, `output/mapa_cargas.png`) y comunalidades:

   | Factor | Ítems (carga) | Comunalidad |
   |---|---|---|
   | pareja | a1 .59, a2 .91, a3 .72, a4 .88 | .49–.85 |
   | familia | a5 .93, a6 .74, a7 .76, a8 .77 | .60–.90 |
   | economia | a9 .71, a10 .86, a11 .88, a12 .84 | .65–.84 |
   | social | a13 .60, a14 .58, a15 .74, a16 .79 | .59–.77 |
   | personal | a17 .73, a18 .94, a19 .63, a20 .66 | .57–.88 |
   | trabajo | a21 .81, a22 .76, a23 .68, a24 .59 | .59–.76 |
   | cohesion | b1 .80, b2 .83, b3 .83, b4 .77, b9 .77 | .64–.75 |
   | confianza | b10 .72, b11 .92, b12 .92, b13 .73 | .65–.88 |
   | inseguridad | c4 .70, c5 .81, c6 .74, c7 .74, c8 .51 | .46–.65 |
   | riesgo | c11 .63, c12 .89, c13 .72 | .44–.83 |
   | libertad | c19 .77, c20 .76 | .61–.66 |
   | desempeno | f2 .84, f3 .83, f4 .88 | .71–.82 |

   - Todos los ítems cargan **≥ .51** en el factor de su bloque. **Ninguno** carga ≥ .30 en otro factor
     (la segunda carga más alta es .21, `a14`).
   - La comunalidad mínima es .44 (`c11`), seguida de `c8` (.46) y `a1` (.49): los ítems más débiles,
     pero aceptables.
   - **No se elimina ningún ítem.** El AFC ([`02_AFC`](../02_AFC/)) se hace con los 46.
8. **Correlaciones entre factores** (`output/correlaciones_factores_AFE.csv`). Las más altas:
   personal–trabajo .49, economía–personal .46, **confianza–desempeño .46**, **inseguridad–riesgo .45**,
   economía–social .43, economía–trabajo .40 y social–personal .40. Las negativas más claras son de
   inseguridad y riesgo con desempeño (−.20, −.21) y de inseguridad con cohesión y confianza (−.15,
   −.14). Todo esto avala la rotación oblicua y apunta a un factor general entre los seis dominios de
   satisfacción (ver [`03_AFC_2do_Orden`](../03_AFC_2do_Orden/)).

> **Aviso.** El AFE y el AFC se hacen con la **misma muestra**: el AFC no es una confirmación
> independiente. Con 294 personas no hay para dividir la muestra en dos, pero se probó de todos modos
> (opcional, [`02_AFC/Validacion_cruzada.R`](../02_AFC/Validacion_cruzada.R)): con tres divisiones al azar
> en mitades de 147, el AFE de una mitad ubica **44, 46 y 46 de los 46 ítems** en el factor dominante de
> su bloque (con 12, 11 y 12 factores distintos como dominantes). La estructura se replica.

Salidas en `output/`: `grafica_codo.png`, `comparacion_numero_factores.csv`, `cargas_AFE.csv`,
`correlaciones_factores_AFE.csv` y `mapa_cargas.png`.

## Referencias

- Horn, J. L. (1965). A rationale and test for the number of factors in factor analysis.
  *Psychometrika, 30*(2), 179–185.
