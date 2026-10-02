# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R`. **Sin referencia propia:** se calculan los mismos tres tipos de puntaje del
Tren (centrados, en escala original y por media ponderada), su determinación (`FSDETERMINACY`) y los pesos
de Bartlett, más un puntaje del factor general **G**.

**Objetivo:** dar a cada persona su puntaje en los 12 factores (y en G) para usarlo en otros análisis.

**Muestra:** como Mplus, las **294** personas con MLR y FIML (`missing = "fiml"`): casi todas reciben puntaje
aunque les falte algún ítem (ver [`07_FIML`](../07_FIML/)).

## Paso a paso

1. **Marcadores y puntajes en `NA`.** El marcador da escala al factor (carga = 1); en la escala original, el
   factor queda en los puntos de 1 a 10 de ese ítem. Se elige el **ítem de mayor carga estandarizada** de cada
   factor (ver [`02_AFC`](../02_AFC/)); la sintaxis de lavaan se arma desde esa lista (`NA*` libera la carga
   del primer ítem y `1*` fija la del marcador, como `p4*` y `p5@1` en Mplus).

   **Regla de `NA`:** quien **no contestó ningún ítem** de un factor queda con `NA` en ese factor. La
   regresión le asignaría un puntaje apoyado solo en los otros factores, y no tendría información propia.
   Son 71 personas en pareja, 10 en familia, 5 en trabajo, 3 en riesgo, libertad y desempeño, 2 en
   cohesión, y 1 en economía, confianza e inseguridad.
2. **Puntajes centrados** (`fs_`). `lavPredict(method = "regression")`, el método de Mplus. Tienen media ≈ 0
   (|media| ≤ .023): la unidad es un punto del ítem marcador.
3. **Determinación.** Correlación entre el puntaje y el factor: √[diag(ΦΛ'Σ⁻¹ΛΦ) / diag(Φ)], para quien
   contestó todos los ítems. **Todas ≥ .90**, así que los puntajes son confiables:

   | Factor | Marcador (carga) | Determinación |
   |---|---|---|
   | pareja | a2 (.91) | .957 |
   | familia | a5 (.91) | .955 |
   | economia | a11 (.91) | .967 |
   | social | a16 (.82) | .945 |
   | personal | a18 (.89) | .958 |
   | trabajo | a22 (.84) | .944 |
   | cohesion | b2 (.85) | .957 |
   | confianza | b12 (.92) | .970 |
   | inseguridad | c7 (.79) | .932 |
   | riesgo | c12 (.94) | .953 |
   | libertad | c19 (.88) | .909 |
   | desempeno | f4 (.89) | .951 |
4. **Bartlett y pesos.** `lavPredict(method = "Bartlett", fsm = TRUE)` da los pesos de cada ítem en el puntaje;
   por ejemplo, pareja: `a2` .463, `a4` .299, `a3` .173, `a1` .112; familia: `a5` .480, `a8` .229, `a7`
   .182, `a6` .131. Bartlett usa solo los ítems observados del factor: a quien no contestó ninguno, lavaan le
   deja `NA` o un 0 (la media del factor), y ninguno de los dos tiene información, así que se enmascara
   igual. Bartlett y regresión ordenan casi igual: **r = .991 a .999** por factor.
5. **Escala original** (`fs2_`). En el `.inp` del Tren se fijaban en 0 los interceptos de todos los ítems.
   Aquí se fija en 0 **solo el intercepto del marcador** y se **liberan las medias de los factores**
   (`factor ~ 1`); los demás interceptos quedan libres y el ajuste es el mismo que en el paso 2. La media
   estimada de cada factor coincide con la media observada de su marcador (diferencias de hasta .03).
6. **Media ponderada** (`fs3_`, cálculo manual de SEM02). Media ponderada = Σ(λ·media del ítem) / Σλ, con λ
   estandarizadas, y `fs3 = puntaje centrado + media ponderada`:

   | Factor | pareja | familia | economia | social | personal | trabajo |
   |---|---|---|---|---|---|---|
   | Media ponderada | 8.507 | 8.467 | 7.180 | 6.752 | 8.291 | 8.253 |

   | Factor | cohesion | confianza | inseguridad | riesgo | libertad | desempeno |
   |---|---|---|---|---|---|---|
   | Media ponderada | 6.146 | 3.493 | 7.021 | 5.623 | 6.477 | 3.134 |
7. **Factor general G** (`fs_G`). Se predice con el modelo de segundo orden de los 24 ítems de satisfacción
   ([`03_AFC_2do_Orden`](../03_AFC_2do_Orden/)) y se estandariza (media 0, D.E. 1). La tienen las 294
   personas: quien no tiene pareja queda medido por los otros cinco dominios.
8. **Descriptivos y archivo.** Los puntajes en escala original:

   | Factor | N | Media | D.E. | Mín. | Máx. | r con el promedio de ítems |
   |---|---|---|---|---|---|---|
   | pareja | 223 | 8.60 | 1.68 | 1.15 | 10.12 | .985 |
   | familia | 284 | 8.68 | 1.50 | 1.38 | 10.12 | .988 |
   | economia | 293 | 7.33 | 1.92 | 0.81 | 10.18 | .995 |
   | social | 294 | 7.40 | 1.78 | 2.44 | 10.21 | .991 |
   | personal | 294 | 8.14 | 1.72 | 0.38 | 10.12 | .993 |
   | trabajo | 289 | 8.34 | 1.31 | 3.07 | 9.99 | .988 |
   | cohesion | 292 | 6.57 | 1.99 | 1.76 | 10.13 | .997 |
   | confianza | 293 | 3.12 | 2.13 | 0.71 | 8.66 | .994 |
   | inseguridad | 293 | 7.82 | 2.03 | 2.36 | 10.55 | .986 |
   | riesgo | 291 | 6.33 | 2.72 | 1.09 | 10.33 | .946 |
   | libertad | 291 | 7.09 | 2.17 | 1.97 | 10.19 | .972 |
   | desempeno | 291 | 3.01 | 1.89 | 0.91 | 8.12 | .995 |

   Como ya se veía en los ítems ([`00_Exploracion`](../00_Exploracion/)), la satisfacción con la pareja,
   la familia y el trabajo es la mejor evaluada (8.3–8.7) y la **confianza en las autoridades** (3.1) y el
   **desempeño del gobierno** (3.0) son las peor evaluadas. Los puntajes en regresión no están acotados:
   algunos pasan de 10.

   **Las tres versiones de un mismo factor son el mismo puntaje desplazado** (`fs2 = fs + media del
   factor`, `fs3 = fs + media ponderada`): su correlación es **1** y tienen la misma D.E. A diferencia del
   Tren (donde `fs2` salía de un modelo con otra restricción), aquí solo cambia el punto de partida.

## Qué agregan los puntajes al promedio simple

El puntaje en escala original correlaciona **.95 a .99** con el promedio simple de los ítems del factor (el
más bajo es riesgo, .946, porque `c12` pesa mucho: λ = .94). Para describir o ordenar personas, el promedio
sirve casi igual. La ventaja de los puntajes es que ponderan cada ítem según su carga y **manejan los datos
faltantes** (FIML). Ojo: los puntajes tienen error de medida, así que para estimar relaciones entre factores
conviene un modelo estructural y no una regresión con puntajes.

Salidas en `output/`: `puntajes_guerrero.csv` (un renglón por persona: `fila`, `folio`, `sin_pareja` y las 37
columnas `fs_*`, `fs2_*`, `fs3_*` y `fs_G`), `descriptivos_puntajes.csv`, `determinacion_puntajes.csv` y
`boxplot_puntajes_originales.png`. Se incluye `fila` porque el **folio no es único**.
